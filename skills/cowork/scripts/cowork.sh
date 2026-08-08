#!/usr/bin/env bash
# cowork.sh — claude·codex·grok·kimi 네 AI 를 "읽기 전용 분석가" 아바타로 병렬 실행한다.
#
#   사용: bash .claude/skills/cowork/scripts/cowork.sh <slug> <분석 요청 프롬프트>
#   결과: .cowork/<slug>/claude-cowork.md, codex-cowork.md, grok-cowork.md, kimi-cowork.md
#
# 이 스크립트는 **분야를 가리지 않는다.** 작업공간이 소프트웨어 저장소든, 교재·문제은행·레시피·기획서
# 폴더든 동일하게 동작한다. 작업공간의 성격은 `.cowork/cowork-prompt.md`(사람이 쓴 지침) + 실행 시점 자동
# 감지로 주입한다 — 특정 분야를 이 스크립트나 페르소나에 하드코딩하지 말 것.
#
# 설계 요지
#   - 네 AI 는 읽기 전용으로 강제된다. AI 자신은 작업공간 파일을 쓸 수 없고, 분석은 stdout 으로만
#     낸다. 파일 기록은 이 스크립트가 한다.
#     → "절대 수정 금지" 를 프롬프트(부탁)가 아니라 도구/OS 권한(강제)으로 보장한다.
#   - ⚠️ 방어 수단이 CLI 마다 다른 이유는 실측 결과가 다르기 때문이다. 근거와 재현 절차는
#     references/readonly-enforcement.md 참고. 임의로 통일하지 말 것(특히 grok·kimi).
#   - 네 AI 는 동시에 돌린다(가장 느린 하나의 시간만 걸린다).
#   - 하나가 실패해도 나머지는 계속 간다. 실패는 마지막 STATUS 요약에 남는다.
#   - macOS 에는 timeout(1) 이 없으므로 perl alarm 워치독을 쓴다.
set -uo pipefail

SKILL_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
PERSONA_FILE="$SKILL_DIR/references/analyst-persona.md"
# grok 전용 2-pass 지침(CoT/ToT → 자기 비판 → 재분석). grok 에만 주입한다.
GROK_PROTOCOL_FILE="$SKILL_DIR/references/grok-deep-protocol.md"
# 프로젝트 루트. git 저장소면 그 최상위를, 아니면 스킬 위치에서 역산한다
# (SKILL_DIR = <루트>/.claude/skills/cowork → 3단계 위가 루트).
# ⚠️ pwd 로 폴백하면 안 된다 — 사용자가 하위 폴더에서 실행하면 .cowork/ 가 엉뚱한 곳에 생긴다.
REPO_ROOT="$(git -C "$SKILL_DIR" rev-parse --show-toplevel 2>/dev/null \
  || (cd "$SKILL_DIR/../../.." && pwd))"
# 심볼릭 링크를 따라간 물리 경로. 샌드박스 규칙은 실경로로 걸어야 우회되지 않는다.
REPO_ROOT_PHYS="$(cd "$REPO_ROOT" && pwd -P)"

# 분석 1건당 제한 시간(초). 깊은 분석은 오래 걸리므로 넉넉히.
COWORK_TIMEOUT="${COWORK_TIMEOUT:-900}"
# 특정 AI 만 (재)실행: COWORK_ONLY=claude|codex|grok|kimi (쉼표로 여러 개). 실패한 AI 재시도용.
COWORK_ONLY="${COWORK_ONLY:-claude,codex,grok,kimi}"

# --- 모델·추론 등급 정책 (2026-07-21 사용자 지시: 반드시 최신/최고 모델의 최고 등급) ---------
# 각 CLI 의 기본값에 맡기지 않고 최고 등급을 명시 고정한다. 근거(실측 2026-07-21):
#   - claude: `--model claude-opus-5`(Opus 5 로 고정) + `--effort xhigh`(low~max 중 Extra High).
#             🛑 2026-07-26 사용자 지시로 claude 분석 모델을 Opus 4.8 에서 Opus 5 로 올려 못 박았다.
#             별칭 `opus` 가 아니라 전체 ID `claude-opus-5` 를 쓰는 이유: 별칭은 "최신 opus" 를
#             가리켜 상위 버전이 나오면 따라가지만, 여기선 5 를 *고정* 해야 하므로 ID 로 핀 고정한다.
#   - codex : 사용자 ~/.codex/config.toml 이 model_reasoning_effort="low" 라서 그대로 두면
#             저사양으로 분석된다(실측). effort 만 xhigh 로 강제 override 하고, 모델은 config 의
#             최신 선택(현재 gpt-5.6-sol)을 상속한다(여기 하드코딩하면 구모델 고정 위험).
#   - grok  : 모델은 grok-4.5 단일(default=최고)이라 미지정이 곧 최신. effort 는 CLI 가
#             high/medium/low 만 지원(xhigh 는 "unknown effort level" 로 거절 — 2026-07-21 실측).
#             정책상 xhigh 급을 쓰되, grok 에 xhigh 가 없으면 그냥 high 로 쓴다(아래 정규화).
#   - kimi  : K3 256K(kimi-code/k3-256k)를 명시 고정. K3 계열은 k3(1M context)와 k3-256k(256K)
#             두 가지인데, **반드시 k3-256k 를 쓴다** — 같은 K3 성능에 context quota 를 약 2배
#             절약한다(2026-08-08 사용자 지시). 분석 1건이 1M 컨텍스트를 쓸 일은 없으므로
#             1M 짜리 k3 는 quota 만 축낸다. K3 자체가 always_thinking 최고 모델이라
#             High/XHigh 별도 변형은 존재하지 않는다.
#             🛑 이 별칭은 사용자 ~/.kimi-code/config.toml 에 [models."kimi-code/k3-256k"]
#                항목이 있어야 동작한다(없으면 kimi 가 config.invalid 로 즉시 거절). 아래
#                check_kimi_model_alias() 가 실행 전에 점검해 안내한다.
# 값을 낮춰야 할 때(요금·속도)만 환경변수로 override 한다. 기본을 낮추지 말 것.
COWORK_CLAUDE_MODEL="${COWORK_CLAUDE_MODEL:-claude-opus-5}"
COWORK_CLAUDE_EFFORT="${COWORK_CLAUDE_EFFORT:-xhigh}"
COWORK_CODEX_EFFORT="${COWORK_CODEX_EFFORT:-xhigh}"
COWORK_CODEX_MODEL="${COWORK_CODEX_MODEL:-}"   # 비우면 ~/.codex/config.toml 의 최신 모델 상속
# grok effort: 기본 high. xhigh/max 등 CLI 미지원 값이 오면 high 로 폴백(거절 방지).
COWORK_GROK_EFFORT="${COWORK_GROK_EFFORT:-high}"
case "$COWORK_GROK_EFFORT" in
  high|medium|low) ;;  # CLI 허용값 그대로
  *)                   # xhigh 없음 → high (실측: --reasoning-effort xhigh 거절)
    COWORK_GROK_EFFORT="high"
    ;;
esac
# grok headless 가 도구 승인 레이스/부모 세션 leader 충돌로 빈 응답(exit 99) 나는 경우 재시도 횟수
# (2026-07-21 실측: permission_cancelled → turn 취소 → stdout 0B). 기본 3회.
COWORK_GROK_RETRIES="${COWORK_GROK_RETRIES:-3}"
COWORK_KIMI_MODEL="${COWORK_KIMI_MODEL:-kimi-code/k3-256k}"

die() { printf '오류: %s\n' "$1" >&2; exit 1; }

# kimi 는 `-m` 에 config.toml 의 **별칭** 을 받는다. 등록돼 있지 않으면 API 에 닿기도 전에
# `config.invalid: Model "..." is not configured` 로 즉시 거절당한다(2026-08-08 실측).
# 네 AI 중 하나가 통째로 빠진 채 분석이 끝나는 사고를 막으려고 실행 전에 점검해 안내한다.
# (안내만 하고 진행한다 — 사용자의 개인 설정 파일을 스크립트가 임의로 고치지 않는다.)
check_kimi_model_alias() {
  local cfg="$HOME/.kimi-code/config.toml"
  [ -f "$cfg" ] || return 0
  grep -q "^\[models\.\"$COWORK_KIMI_MODEL\"\]" "$cfg" && return 0
  printf '⚠️  kimi 모델 별칭이 등록돼 있지 않다: %s\n' "$COWORK_KIMI_MODEL" >&2
  printf '    이대로면 kimi 분석만 실패한다. %s 에 아래를 추가하라:\n\n' "$cfg" >&2
  printf '    [models."%s"]\n' "$COWORK_KIMI_MODEL" >&2
  printf '    provider = "managed:kimi-code"\n' >&2
  printf '    model = "%s"\n' "${COWORK_KIMI_MODEL#*/}" >&2
  printf '    max_context_size = 262144\n' >&2
  printf '    capabilities = [ "thinking", "always_thinking", "image_in", "video_in", "tool_use" ]\n' >&2
  printf '    display_name = "K3 256K"\n' >&2
  printf '    support_efforts = [ "low", "high", "max" ]\n' >&2
  printf '    default_effort = "high"\n\n' >&2
}

usage() {
  cat >&2 <<'EOF'
사용법: cowork.sh <폴더명> <분석 요청 프롬프트>
        cowork.sh --list
        cowork.sh --init [--force]
        cowork.sh --init-hook
        cowork.sh --review <폴더명>

  <폴더명>   .cowork/<폴더명>/ — 작업 ID 역할. 소문자·숫자·하이픈만 (예: tetris-scoring)
             사람이 지정한 이름을 그대로 쓴다(임의로 바꾸지 말 것).
  <프롬프트> 분석 요청 원문. 여러 단어면 따옴표로 감싸거나 그대로 나열.
  --list     .cowork/ 의 작업 목록과 상태를 보여준다(-l). 동시 진행 중인 작업 파악용.
  --init     .cowork/cowork-prompt.md (이 작업공간의 공통 지침) 초안을 만든다. 4 AI 분석마다 주입된다.
             이미 있으면 건드리지 않는다(사람이 다듬은 내용 보호). 덮어쓰려면 --force.
  --init-hook  이 프로젝트 .claude/settings.json 의 Stop hook 에 final-report 리뷰를 멱등 설치한다.
  --review   <폴더명>의 final-report.md 를 4 AI 로 재검토해 갱신한다(보통 Stop hook 이 백그라운드로 호출).

환경변수:
  COWORK_TIMEOUT        AI 1개당 제한 시간(초, 기본 900)
  COWORK_ONLY           실행할 AI 목록(기본 claude,codex,grok,kimi)
  COWORK_CLAUDE_MODEL   claude 모델(기본 claude-opus-5 = Opus 5 고정)
  COWORK_CLAUDE_EFFORT  claude 추론 등급(기본 xhigh)
  COWORK_CODEX_MODEL    codex 모델(기본 빈값 = ~/.codex/config.toml 의 최신 모델 상속)
  COWORK_CODEX_EFFORT   codex 추론 등급(기본 xhigh — config 의 low 를 override)
  COWORK_GROK_EFFORT    grok 추론 등급(기본 high; xhigh 등 미지원 값은 high 로 폴백)
  COWORK_GROK_RETRIES   grok 빈응답/실패 시 재시도 횟수(기본 3)
  COWORK_KIMI_MODEL     kimi 모델(기본 kimi-code/k3-256k = K3 256K. 1M 짜리 k3 보다 context
                        quota 를 약 2배 절약한다 — 특별한 이유 없이 k3 로 되돌리지 말 것)

예:
  bash .claude/skills/cowork/scripts/cowork.sh login-timeout "로그인이 가끔 끊기는 원인 분석"
  bash .claude/skills/cowork/scripts/cowork.sh grade3-fractions "초등 3학년 분수 단원 구성이 적절한지 검토"
  COWORK_ONLY=grok COWORK_TIMEOUT=600 bash .claude/skills/cowork/scripts/cowork.sh login-timeout "..."
  bash .claude/skills/cowork/scripts/cowork.sh --list
  bash .claude/skills/cowork/scripts/cowork.sh --init
EOF
  exit 2
}

# 실행 대상 AI 필터(COWORK_ONLY). 분석·리뷰가 공용하므로 앞에 둔다.
wants() { [[ ",$COWORK_ONLY," == *",$1,"* ]]; }

# --- 지침 블록 추출 ---------------------------------------------------------
# 지침 파일에서 ---BEGIN <TAG>--- ~ ---END <TAG>--- 사이만 뽑는다(문서 설명문은 주입하지 않는다).
# 분석·리뷰·종합이 모두 쓰므로 case 분기보다 앞에 둔다.
extract_block() { # <파일> <태그>
  sed -n "/^---BEGIN $2---$/,/^---END $2---$/p" "$1" | sed '1d;$d'
}

# --- 작업공간 감지 ------------------------------------------------------------
# 이 스킬은 어떤 작업공간에나 복사돼 쓰인다 — 소프트웨어 저장소일 수도, 교재·문제은행·레시피·기획서
# 폴더일 수도 있다. 그래서 "무슨 작업공간인가" 를 페르소나에 하드코딩하지 않고 실행 시점에 감지한다.
#
# 🛑 왜 필요한가 (실측 사고 2026-07-17): 페르소나에 특정 게임 프로젝트 전용 문구가 박혀 있던 탓에
#    전혀 다른 웹 프로젝트에서 돌리자 세 AI 전부가 존재하지 않는 디렉토리를 찾아 헤맸고, 보고서에
#    "실제 저장소는 그 프로젝트가 아니다" 라고 적었다. 분석 1회가 통째로 낭비됐다.
#
# 감지 원칙: 얕게·빠르게. 여기서 작업공간을 완벽히 파악할 필요는 없다 — 각 CLI 는 cwd 의 지침 문서를
# 스스로 읽고, 페르소나가 "지침 문서를 먼저 열어라"고 지시한다. 이 블록은 그 출발점만 준다.
detect_workspace_facts() {
  local root="$1" name docs stack f types
  name="$(basename "$root")"

  # 도구·스택 힌트: 루트의 매니페스트 파일로만 판정한다(파일 존재 = 사실, 추측 아님).
  # 소프트웨어가 아닌 작업공간에서는 하나도 안 걸리는 것이 정상이다 — 그때는 파일 종류로 판단한다.
  stack=""
  [ -f "$root/pubspec.yaml" ]     && stack+="Flutter/Dart(pubspec.yaml), "
  [ -f "$root/package.json" ]     && stack+="Node/JS(package.json), "
  [ -f "$root/go.mod" ]           && stack+="Go(go.mod), "
  [ -f "$root/Cargo.toml" ]       && stack+="Rust(Cargo.toml), "
  [ -f "$root/composer.json" ]    && stack+="PHP(composer.json), "
  [ -f "$root/pom.xml" ]          && stack+="Java/Maven(pom.xml), "
  [ -f "$root/build.gradle" ] || [ -f "$root/build.gradle.kts" ] && stack+="Gradle, "
  [ -f "$root/requirements.txt" ] || [ -f "$root/pyproject.toml" ] && stack+="Python, "
  [ -f "$root/Gemfile" ]          && stack+="Ruby(Gemfile), "
  [ -f "$root/project.godot" ]    && stack+="Godot(project.godot), "
  [ -f "$root/docker-compose.yml" ] || [ -f "$root/docker-compose.yaml" ] && stack+="Docker Compose, "
  stack="${stack%, }"
  [ -n "$stack" ] || stack="(개발 매니페스트 없음 — 코드 프로젝트가 아닐 수 있다. 아래 파일 종류를 보라)"

  # 파일 종류 분포: 분야를 가리지 않는 감지 수단. 코드든 문서든 데이터든 "무엇이 많은가" 를 보여준다.
  # maxdepth 3 · 숨김/의존성 폴더 제외로 큰 작업공간에서도 빠르게 끝낸다.
  types="$(find "$root" -maxdepth 3 -type f \
             -not -path '*/.*' \
             -not -path '*/node_modules/*' -not -path '*/vendor/*' \
             -not -path '*/build/*' -not -path '*/dist/*' 2> /dev/null \
           | sed -n 's/.*\.\([A-Za-z0-9]\{1,8\}\)$/\1/p' \
           | tr 'A-Z' 'a-z' | sort | uniq -c | sort -rn | head -8 \
           | awk '{printf "%s(%s), ", $2, $1}')"
  types="${types%, }"
  [ -n "$types" ] || types="(확장자 있는 파일을 찾지 못함)"

  # 지침 문서: 루트의 .md (CLAUDE.md·AGENTS.md·README.md 등). AI 가 먼저 읽어야 할 것들.
  docs=""
  for f in "$root"/*.md; do
    [ -f "$f" ] || continue
    docs+="$(basename "$f"), "
  done
  docs="${docs%, }"
  [ -n "$docs" ] || docs="(루트에 마크다운 지침 문서 없음)"

  # 하위 디렉토리 개요: 자료가 어디 있는지의 첫 단서(숨김/빌드 산출물 제외).
  local dirs=""
  for f in "$root"/*/; do
    [ -d "$f" ] || continue
    case "$(basename "$f")" in
      node_modules | build | dist | .* | outputs | vendor) continue ;;
    esac
    dirs+="$(basename "$f")/ "
  done
  [ -n "$dirs" ] || dirs="(없음)"

  printf -- '- **작업공간 이름**: `%s`\n' "$name"
  printf -- '- **작업공간 경로**: `%s`\n' "$root"
  printf -- '- **감지된 개발 스택**: %s\n' "$stack"
  printf -- '- **파일 종류 분포**: %s\n' "$types"
  printf -- '- **루트 지침 문서**: %s\n' "$docs"
  printf -- '- **최상위 디렉토리**: %s\n' "$dirs"
}

# 4 AI 에게 주입할 "대상 작업공간" 블록을 만든다.
#
# `.cowork/cowork-prompt.md` 는 **이 작업공간의 시스템 프롬프트** 다 — 프로젝트의 특성·기획·계획·아바타
# (persona)·디자인·로직·개념을 사람이 정의해 두는 곳이고, cowork 는 어떤 분석을 하든 이것을 **반드시**
# 4 AI 에게 먹인다. 자동 감지는 그 아래 보조 사실일 뿐이다(파일 존재로 알 수 있는 것만).
#
# 이 함수의 반환값은 페르소나의 {{PROJECT_CONTEXT}} 에 치환된다 → 분석(claude·codex·kimi)·grok
# pass1·pass2·리뷰 라운드가 **전부 같은 페르소나 문자열을 쓰므로 한 곳만 고치면 모든 경로에 전파된다.**
# 새 실행 경로를 추가할 때도 persona 를 그대로 쓰면 cowork-prompt.md 주입이 자동으로 따라온다.
build_project_context() {
  local root="$1"
  # 🛑 `local root="$1" pf="$root/…"` 처럼 한 줄에 쓰지 말 것. local 의 인자는 local 이 실행되기 *전에*
  #    모두 확장되므로 그 시점에 root 는 아직 없고, `set -u` 가 unbound variable 로 죽인다. 이 함수는
  #    명령 치환($(…)) 안에서 불리므로 죽어도 서브셸만 조용히 끝나 **빈 컨텍스트가 주입된다**
  #    (2026-07-26 실측: 시스템 프롬프트가 통째로 누락됐는데 경고 한 줄 없었다). 반드시 줄을 나눈다.
  local pf="$root/.cowork/cowork-prompt.md"
  # 하위 호환: 예전 이름(`.cowork/prompt.md`)만 있는 프로젝트는 그것을 읽는다. 파일명을 바꾸는 순간
  # 기존 작업공간이 시스템 프롬프트를 **조용히** 잃는 사고를 막는다(경고는 주 실행부에서 낸다).
  [ -f "$pf" ] || pf="$root/.cowork/prompt.md"
  if [ -f "$pf" ]; then
    printf '### 🛑 이 작업공간의 시스템 프롬프트 — `.cowork/%s` (최우선 · 반드시 따르라)\n\n' "$(basename "$pf")"
    printf '아래는 이 작업공간의 담당자가 직접 작성한 지침이다. 이 프로젝트의 **특성·기획·계획·아바타\n'
    printf '(persona)·디자인·로직·개념**이 여기 정의돼 있다. **당신의 분석 전체가 이 내용을 전제로\n'
    printf '이뤄져야 한다** — 여기 적힌 목적·역할·규칙·용어를 그대로 따르라. 아래 자동 감지 사실이나\n'
    printf '당신의 일반 상식과 어긋나면 **이 문서가 맞다.** 여기 명시된 제약을 어긴 권고는 채택되지 않는다.\n\n'
    printf -- '---\n\n'
    cat "$pf"
    printf '\n\n---\n\n'
    printf '### 자동 감지 사실 (보조 — 위 시스템 프롬프트와 어긋나면 위가 맞다)\n\n'
  else
    printf '### 이 작업공간에는 시스템 프롬프트(`.cowork/cowork-prompt.md`)가 없다\n\n'
    printf '작업공간의 목적·역할·규칙이 명시돼 있지 않다. 아래 감지 사실과 실제 자료를 직접 열어\n'
    printf '파악하되, 넘겨짚은 전제는 §6 에 불확실성으로 남겨라.\n\n'
  fi
  detect_workspace_facts "$root"
}

# --- perl 워치독: macOS 에 timeout(1) 이 없다 --------------------------------
# 제한 시간을 넘기면 TERM → KILL 후 124 로 종료. 분석·리뷰가 공용.
run_timeout() {
  local secs="$1"; shift
  perl -e '
    my $s = shift;
    my $pid = fork();
    if ($pid == 0) { exec @ARGV or exit 127 }
    local $SIG{ALRM} = sub { kill "TERM", $pid; sleep 2; kill "KILL", $pid; exit 124 };
    alarm $s;
    waitpid($pid, 0);
    exit($? >> 8);
  ' "$secs" "$@"
}

# --- grok headless 1회 실행 (분석·리뷰 공용) --------------------------------
# 🛑 2026-07-21 실측 실패 모드 (cowork-skill, exit=99 빈 응답, 50s):
#    세션 events.jsonl 끝: permission_resolved(run_terminal_command)=cancelled
#    → turn_ended(cancellation_category=permission_cancelled) → stdout 0B · rc=0.
#    부모 Grok 세션(이 대화) 안에서 자식 grok 를 띄울 때 leader 소켓·권한 상태가 얽히면
#    도구 승인이 간헐적으로 cancel 되고, headless 는 최종 답 없이 조용히 종료한다.
# 방어:
#    1) --leader-socket 을 호출마다 고유 경로로 분리 (부모 ~/.grok/leader.sock 과 격리)
#    2) --always-approve 명시 (config 의존·TUI 프롬프트 경로 차단)
#    3) env -u GROK_AGENT (부모 에이전트 컨텍스트 누수 차단)
#    4) 호출 측에서 빈 응답 시 재시도(COWORK_GROK_RETRIES)
# 읽기 전용은 여전히 sandbox-exec 가 담당(--always-approve 로 쓰기를 허용해도 OS 가 EPERM).
# 사용: run_grok_headless <prompt-file> <stdout-file> <stderr-log> <debug-file>
run_grok_headless() {
  local pf="$1" out="$2" lg="$3" dbg="$4"
  local sbx leader_sock
  sbx="$(printf '(version 1)\n(allow default)\n(deny file-write* (subpath "%s"))\n' "$REPO_ROOT_PHYS")"
  # 프로세스·시각 기반 고유 소켓 — 병렬 pass/재시도가 서로 안 덮어쓰게 함
  leader_sock="${TMPDIR:-/tmp}/cowork-grok-${SLUG:-x}-$$-$(date +%s%N).sock"
  rm -f "$leader_sock" "$dbg" 2> /dev/null
  # shellcheck disable=SC2086
  cd "$REPO_ROOT" && run_timeout "$COWORK_TIMEOUT" \
    env -u GROK_AGENT \
    sandbox-exec -p "$sbx" \
      grok --prompt-file "$pf" --output-format plain --no-alt-screen \
        --always-approve \
        --leader-socket "$leader_sock" \
        --reasoning-effort "$COWORK_GROK_EFFORT" \
        --debug-file "$dbg" \
        > "$out" 2>> "$lg" < /dev/null
  local rc=$?
  rm -f "$leader_sock" 2> /dev/null
  return "$rc"
}

# grok 를 최대 N 회 돌려 빈 응답/비0 종료를 흡수한다.
# run_grok_with_retries <label> <prompt-file> <stdout-file> <stderr-log> <debug-prefix>
# debug 파일은 <debug-prefix>-a1.log, -a2.log … 로 쌓인다. 성공 시 0, 전부 실패 시 마지막 rc.
run_grok_with_retries() {
  local label="$1" pf="$2" out="$3" lg="$4" dbg_prefix="$5"
  local attempts="$COWORK_GROK_RETRIES" attempt=1 rc=0 size=0
  # 정수 가드 (빈/비숫자 → 3)
  case "$attempts" in ''|*[!0-9]*) attempts=3 ;; esac
  [ "$attempts" -lt 1 ] && attempts=1

  while [ "$attempt" -le "$attempts" ]; do
    : > "$out"
    printf '[cowork] grok %s attempt %s/%s 시작\n' "$label" "$attempt" "$attempts" >> "$lg"
    run_grok_headless "$pf" "$out" "$lg" "${dbg_prefix}-a${attempt}.log"
    rc=$?
    size=0
    [ -f "$out" ] && size="$(wc -c < "$out" | tr -d ' ')"
    if [ "$rc" -eq 0 ] && [ "$size" -ge 50 ]; then
      printf '[cowork] grok %s attempt %s 성공 (%sB)\n' "$label" "$attempt" "$size" >> "$lg"
      return 0
    fi
    # 세션 이벤트에 permission_cancelled 흔적이 있으면 로그에 남겨 사후 진단이 쉽게
    if [ -f "${dbg_prefix}-a${attempt}.log" ] && \
         grep -q 'permission_cancelled\|decision.:.cancelled' "${dbg_prefix}-a${attempt}.log" 2>/dev/null; then
      printf '[cowork] grok %s attempt %s: debug 에 permission cancel 흔적\n' "$label" "$attempt" >> "$lg"
    fi
    printf '[cowork] grok %s attempt %s 실패 (rc=%s size=%sB)%s\n' \
      "$label" "$attempt" "$rc" "$size" \
      "$( [ "$attempt" -lt "$attempts" ] && echo ' — 재시도' || echo ' — 포기' )" >> "$lg"
    attempt=$((attempt + 1))
    [ "$attempt" -le "$attempts" ] && sleep 2
  done
  [ "$rc" -eq 0 ] && rc=99
  return "$rc"
}

# --- 읽기 전용 1-pass 러너 (리뷰·종합 공용) ----------------------------------
# run_oneshot <ai> <프롬프트파일> <출력파일> <로그파일>
# 각 AI 를 읽기 전용 1회로 실행한다. 방어는 분석 러너와 동일 원칙(claude=화이트리스트,
# codex=--sandbox read-only, grok·kimi=sandbox-exec). grok 은 여기선 1-pass(리뷰는 이미 결론을
# 비판하는 작업이라 2-pass 불필요). 기존 run_claude/codex/grok/kimi 는 건드리지 않는다(회귀 방지).
run_oneshot() {
  local ai="$1" pf="$2" out="$3" lg="$4"
  local sbx
  sbx="$(printf '(version 1)\n(allow default)\n(deny file-write* (subpath "%s"))\n' "$REPO_ROOT_PHYS")"
  case "$ai" in
    claude)
      cd "$REPO_ROOT" && run_timeout "$COWORK_TIMEOUT" \
        claude -p "$(cat "$pf")" --permission-mode plan \
          --model "$COWORK_CLAUDE_MODEL" --effort "$COWORK_CLAUDE_EFFORT" \
          --allowedTools "Read Grep Glob" --disallowedTools "Edit Write NotebookEdit Bash" \
          > "$out" 2> "$lg" < /dev/null ;;
    codex)
      cd "$REPO_ROOT" && run_timeout "$COWORK_TIMEOUT" \
        codex exec --sandbox read-only --skip-git-repo-check --color never \
          ${COWORK_CODEX_MODEL:+-m "$COWORK_CODEX_MODEL"} \
          -c model_reasoning_effort="$COWORK_CODEX_EFFORT" \
          -o "$out" - \
          < "$pf" > "$lg" 2>&1 ;;
    grok)
      command -v sandbox-exec > /dev/null 2>&1 || { printf 'sandbox-exec 없음 — grok 미실행\n' > "$lg"; return 1; }
      # 리뷰 라운드도 동일 격리·재시도 (빈 리뷰가 종합을 오염시키지 않게)
      run_grok_with_retries "oneshot" "$pf" "$out" "$lg" "${lg%.log}-debug" ;;
    kimi)
      command -v sandbox-exec > /dev/null 2>&1 || { printf 'sandbox-exec 없음 — kimi 미실행\n' > "$lg"; return 1; }
      local kb; kb="$(command -v kimi 2> /dev/null || echo "$HOME/.kimi-code/bin/kimi")"
      cd "$REPO_ROOT" && run_timeout "$COWORK_TIMEOUT" \
        sandbox-exec -p "$sbx" "$kb" -p "$(cat "$pf")" --output-format text \
          -m "$COWORK_KIMI_MODEL" \
          > "$out" 2> "$lg" < /dev/null
      [ -f "$out" ] && sed -i '' '/^To resume this session: kimi -r /d' "$out" 2> /dev/null ;;
  esac
}

# --- --init: .cowork/cowork-prompt.md 초안 생성 -------------------------------------
# 이 작업공간에서 4 AI 에게 매번 주입할 공통 지침 파일을 만든다(Overview·Persona·Instructions·Tech stack).
# 자동 감지로 뼈대와 사실만 채운다 — 나머지는 사람(또는 오케스트레이터)이 채워야 제 값을 한다.
#
# 🛑 이미 있으면 덮어쓰지 않는다. 사람이 다듬은 지침을 재실행 한 번으로 날리면 안 된다(--force 로만 교체).
do_init_prompt() {
  local force="${1:-}"
  local dir="$REPO_ROOT/.cowork"
  local pf="$dir/cowork-prompt.md"

  mkdir -p "$dir" || die "작업 폴더를 만들 수 없다: $dir"

  # 예전 이름(`.cowork/prompt.md`)만 있으면 새 이름으로 옮긴다 — 사람이 쓴 내용을 잃지 않는다.
  if [ ! -f "$pf" ] && [ -f "$dir/prompt.md" ]; then
    mv "$dir/prompt.md" "$pf" \
      && printf '🔁 예전 이름을 새 이름으로 옮겼다: .cowork/prompt.md → .cowork/cowork-prompt.md\n' >&2
  fi

  if [ -f "$pf" ] && [ "$force" != "--force" ]; then
    printf '⏭️  이미 있다 — 건드리지 않았다: .cowork/cowork-prompt.md\n' >&2
    printf '    내용을 보고 직접 다듬어라. 감지 결과로 새로 만들려면: cowork.sh --init --force\n' >&2
    return 0
  fi
  [ -f "$pf" ] && cp "$pf" "$pf.bak" && printf '📦 기존 파일 백업: .cowork/cowork-prompt.md.bak\n' >&2

  local facts; facts="$(detect_workspace_facts "$REPO_ROOT")"
  local wsname; wsname="$(basename "$REPO_ROOT")"

  cat > "$pf" <<EOF
# cowork 시스템 프롬프트 — $wsname

> 🛑 이 파일은 \`cowork\` 이 claude·codex·grok·kimi **네 AI 에게 분석을 시킬 때마다 프롬프트 맨 앞에
> 반드시 주입** 하는 **이 프로젝트의 시스템 프롬프트** 다. 네 AI 는 매번 이 문서를 전제로 분석한다.
>
> 이 프로젝트의 **특성·기획·계획·아바타(persona)·디자인·로직·개념** 을 여기에 적어 두면, 어떤 분석을
> 시키든 네 AI 가 같은 맥락 위에서 답한다. 반대로 비워 두면 네 AI 는 프로젝트의 목적을 모른 채
> 일반론으로 분석한다 — **채울수록 결과가 좋아지는 파일이다.**
>
> \`cowork.sh --init\` 이 자동 감지로 만든 **초안** 이다. 아래 네 절은 뼈대일 뿐이니, 필요하면 절을
> 더 추가하라(\`## 기획\`, \`## 용어 정의\`, \`## 설계 규칙\`, \`## 데이터 구조\`, \`## 금지사항\` …).
>
> ⚠️ 네 AI 는 읽기 전용이다. 이 문서에 "파일을 만들어라" 같은 지시를 써도 물리적으로 실행되지 않는다
> (실제 작업은 종합(final-report.md)을 마친 오케스트레이터가 한다).

## Overview

(이 프로젝트가 **무엇인지**, 무엇을 만들고 있고 지금 어느 단계인지, 그리고 4 AI 에게 **무엇을
 시키려는지** 를 쓴다. 프로젝트의 특성·기획 의도·목표·계획을 여기에 담는다.
 예: "초등 3~4학년 수학 교재를 만드는 프로젝트. 현재 1학기 분수 단원 초안까지 나왔다.
 단원 구성·난이도 배열·오답 유형의 타당성을 네 AI 에게 교차 검증시킨다."
 예: "웹 브라우저용 테트리스. 코어 로직은 완성, 지금은 난이도 곡선과 조작감을 다듬는 단계다.")

## Persona

(4 AI 가 **어떤 전문가 역할(아바타)** 로 분석해야 하는지 쓴다. 이 프로젝트의 분야에 맞는 인격을
 부여하면 분석의 관점 자체가 달라진다.
 예: "초등 수학 교육과정 설계 전문가이자 아동 인지발달 관점의 교재 검수자."
 예: "낙하형 퍼즐 게임의 조작감·난이도 곡선을 설계해 온 시니어 게임 디자이너.")

## Instructions

(분석 시 **반드시 지킬 규칙·개념·설계 로직·우선순위·금지사항** 을 쓴다. 이 프로젝트의 불변 규칙과
 핵심 개념을 여기에 정의해 두면 네 AI 가 그것을 어기는 권고를 하지 않는다.
 예:
 - 모든 주장에는 \`파일:줄\` 근거를 붙이고, 근거 없는 주장은 \`[추측]\` 으로 표시한다.
 - 대상 독자는 만 9~10세다. 그 어휘 수준을 넘는 제안은 하지 않는다.
 - "레벨" 은 낙하 속도 단계를 뜻한다. 점수 구간과 혼동하지 말 것.
 - 기존 단원 번호 체계는 불변이다. 재배열을 전제로 한 권고는 하지 않는다.)

## Tech stack

(이 프로젝트를 구성하는 **기술·도구·파일 형식·자료 구조·디자인 규격** 을 쓴다. 소프트웨어가 아니면
 사용하는 문서 형식·템플릿·산출물 규격을 쓴다. 아래는 자동 감지 결과이니 직접 확인해 고쳐라.)

$facts
EOF

  printf '✅ 생성: .cowork/cowork-prompt.md\n' >&2
  printf '   4 AI 분석마다 이 파일이 프롬프트에 주입된다. 네 절(Overview·Persona·Instructions·Tech stack)을\n' >&2
  printf '   이 작업공간에 맞게 채워라 — 채울수록 분석 품질이 올라간다.\n' >&2
}

# --- --init-hook: Stop hook 멱등 설치 ----------------------------------------
# 이 프로젝트 .claude/settings.json 의 hooks.Stop 에 final-report-stop-hook.sh 를 추가한다.
# 이미 있으면 아무것도 하지 않는다(멱등). 기존 Stop hook 은 보존한다.
do_init_hook() {
  local settings="$REPO_ROOT/.claude/settings.json"
  local hookcmd='bash .claude/skills/cowork/scripts/final-report-stop-hook.sh'
  command -v jq > /dev/null 2>&1 || die "jq 가 필요하다(brew install jq)."
  mkdir -p "$(dirname "$settings")"
  [ -f "$settings" ] || printf '{}\n' > "$settings"

  if jq -e --arg c "$hookcmd" \
      '[.hooks.Stop // [] | .[]?.hooks[]?.command] | any(. == $c)' "$settings" > /dev/null 2>&1; then
    printf '✅ 이미 설치됨 — Stop hook 에 final-report 리뷰가 있다: %s\n' "$settings" >&2
    return 0
  fi

  local tmp; tmp="$(mktemp)"
  jq --arg c "$hookcmd" '
    .hooks = (.hooks // {})
    | .hooks.Stop = ((.hooks.Stop // []) + [{
        "hooks": [{ "type": "command", "command": $c, "timeout": 60 }]
      }])
  ' "$settings" > "$tmp" && mv "$tmp" "$settings" || die "settings.json 갱신 실패: $settings"
  printf '✅ 설치 완료: %s\n' "$settings" >&2
  printf '   이제 cowork 분석이 끝나면 Stop hook 이 .review-final-report 마커를 보고,\n' >&2
  printf '   final-report.md 를 4 AI 로 백그라운드 재검토해 갱신한다(세션은 안 멈춤).\n' >&2
}

# --- --review: final-report.md 최종 리뷰 라운드 ------------------------------
# Stop hook 이 nohup 백그라운드로 호출한다. 4 AI 가 종합본을 재검토 → claude 가 반영해 갱신.
# 상세·페르소나·종합 프롬프트 SSOT: references/final-report-review.md
do_review() {
  local slug="$1"
  [[ "$slug" =~ ^[a-z0-9][a-z0-9-]*$ ]] || { printf '리뷰: 잘못된 폴더명 "%s"\n' "$slug" >&2; return 2; }
  local dir="$REPO_ROOT/.cowork/$slug"
  local marker="$dir/.review-final-report"
  local report="$dir/final-report.md"
  local lock="$dir/.review-running"      # mkdir 원자성 락(중복 실행 방지)
  local rdir="$dir/.review"
  local logf="$dir/final-report-log.md"
  local review_ref="$SKILL_DIR/references/final-report-review.md"

  [ -f "$marker" ] || return 0           # 마커 없으면 할 일 없음
  mkdir "$lock" 2> /dev/null || return 0 # 이미 리뷰 진행 중 → 조용히 종료
  trap 'rm -rf "$lock"' EXIT

  if [ ! -f "$report" ]; then
    # 아직 종합 전 — 마커는 남겨 다음 Stop 에서 재시도한다
    rm -rf "$lock"; trap - EXIT; return 0
  fi

  mkdir -p "$rdir"
  cp "$report" "$rdir/final-report.before.md"

  local rpersona ai f
  rpersona="$(extract_block "$review_ref" REVIEW-PERSONA)"
  [ -n "$rpersona" ] || { printf 'REVIEW-PERSONA 마커 없음: %s\n' "$review_ref" >&2; return 1; }

  # 리뷰 프롬프트: 리뷰 페르소나 + final-report.md 전문 + 4개 원본 분석 전문
  local rprompt="$rdir/.review-prompt.md"
  {
    printf '%s\n\n' "$rpersona"
    # 리뷰어도 이 작업공간이 무슨 분야인지 알아야 권고의 실현성을 판정할 수 있다(분석 라운드와 동일 소스).
    printf -- '## 대상 작업공간\n\n%s\n\n---\n\n' "$(build_project_context "$REPO_ROOT")"
    printf '## 검토 대상 작업\n\n폴더: `.cowork/%s/`\n\n---\n\n' "$slug"
    printf '## final-report.md (검토할 종합본)\n\n'
    cat "$report"
    for ai in claude codex grok kimi; do
      f="$dir/$ai-cowork.md"
      [ -f "$f" ] || continue
      printf -- '\n\n---\n\n## 원본 분석: %s-cowork.md\n\n' "$ai"
      cat "$f"
    done
  } > "$rprompt"

  # 4 AI 병렬 리뷰(1-pass)
  local pids=()
  for ai in claude codex grok kimi; do
    wants "$ai" || continue
    run_oneshot "$ai" "$rprompt" "$rdir/$ai-review.md" "$rdir/.$ai.log" & pids+=("$!")
  done
  local p
  for p in "${pids[@]}"; do wait "$p"; done

  # 종합: claude 1회로 리뷰를 반영해 final-report.md 개선안 생성
  local synth
  synth="$(extract_block "$review_ref" REVIEW-SYNTHESIS)"
  [ -n "$synth" ] || { printf 'REVIEW-SYNTHESIS 마커 없음: %s\n' "$review_ref" >&2; return 1; }
  local sprompt="$rdir/.synth-prompt.md"
  {
    printf '%s\n\n' "$synth"
    printf -- '---\n\n## 원본 final-report.md\n\n'
    cat "$rdir/final-report.before.md"
    for ai in claude codex grok kimi; do
      f="$rdir/$ai-review.md"
      [ -f "$f" ] || continue
      printf -- '\n\n---\n\n## %s 리뷰\n\n' "$ai"
      cat "$f"
    done
  } > "$sprompt"

  run_oneshot claude "$sprompt" "$rdir/synthesis.md" "$rdir/.synth.log"

  # 파싱: ===FINAL-REPORT=== ~ ===CHANGELOG=== 사이가 새 본문, 그 뒤가 변경요약
  local synout="$rdir/synthesis.md" newreport changelog applied
  newreport="$(awk '/^===FINAL-REPORT===$/{f=1;next} /^===CHANGELOG===$/{f=0} f' "$synout" 2> /dev/null)"
  changelog="$(awk '/^===CHANGELOG===$/{f=1;next} f' "$synout" 2> /dev/null)"

  # 검증: §1 결론 포함 + 최소 크기라야 교체(종합 실패가 보고서를 망가뜨리지 않게)
  if printf '%s' "$newreport" | grep -q '^## 1\. 결론' && [ "${#newreport}" -ge 200 ]; then
    printf '%s\n' "$newreport" > "$report"
    applied="갱신"
  else
    applied="원본유지(종합 출력이 유효하지 않아 반영 안 함)"
  fi

  # 변경 이력 append
  local stamp; stamp="$(date '+%Y-%m-%d %H:%M')"
  {
    printf '## 리뷰 라운드 — %s\n\n' "$stamp"
    printf '> 4 AI 리뷰(claude·codex·grok·kimi) → claude 종합 → final-report.md **%s**\n\n' "$applied"
    [ -n "$changelog" ] && printf '%s\n\n' "$changelog"
    printf -- '- 원본 백업: `.review/final-report.before.md`\n\n---\n\n'
  } >> "$logf"

  rm -f "$marker"                        # 리뷰 완료 → 마커 제거(다음 Stop 부터 skip)
  rm -rf "$lock"; trap - EXIT
  return 0
}

# --- 작업 목록 --------------------------------------------------------------
# 여러 작업을 동시에 굴릴 때 "어느 폴더에서 무슨 분석을 하는지" 한눈에 보기 위한 것.
# 상태는 산출물 파일의 존재로 판정한다(별도 상태 파일을 두지 않는다 — 단일 소스).
list_coworks() {
  local cowork_root="$REPO_ROOT/.cowork" d name req status n_ok n_fail mtime
  if [ ! -d "$cowork_root" ]; then
    printf '(.cowork 에 작업이 없다)\n'
    return 0
  fi
  # 표로 정렬하지 않는다 — 한글은 표시 폭이 2칸이라 printf 의 문자수 패딩과 어긋나 오히려 깨진다.
  # 한 줄에 "상태 폴더명 (갱신) — 요청" 으로 쓰면 폭 계산이 필요 없다.
  printf '.cowork 작업 목록\n\n'
  local found=0
  for d in "$cowork_root"/*/; do
    [ -d "$d" ] || continue
    found=1
    name="$(basename "$d")"
    # 요청 원문: .prompt.md 의 "## 분석 요청" 다음 첫 비어있지 않은 줄
    req="$(awk '/^## 분석 요청$/{f=1;next} f&&NF{print;exit}' "$d/.prompt.md" 2>/dev/null)"
    [ -n "$req" ] || req="(요청 불명)"
    n_ok=0; n_fail=0
    for ai in claude codex grok kimi; do
      [ -f "$d/$ai-cowork.md" ] || continue
      if head -1 "$d/$ai-cowork.md" 2>/dev/null | grep -q 'exit=0'; then
        n_ok=$((n_ok + 1))
      else
        n_fail=$((n_fail + 1))
      fi
    done
    if [ -f "$d/final-report.md" ]; then
      status="✅ 종합완료"
    elif [ "$n_ok" -gt 0 ]; then
      status="⏳ 종합대기"
    elif [ "$n_fail" -gt 0 ]; then
      status="❌ 전부실패"
    else
      status="🔄 분석중"
    fi
    [ "$n_fail" -gt 0 ] && [ "$n_ok" -gt 0 ] && status="⚠️ ${n_ok}/$((n_ok + n_fail)) 성공"
    mtime="$(date -r "$d" '+%m-%d %H:%M' 2>/dev/null || echo '-')"
    # 요청은 문자 단위로 자른다(bash 부분문자열). printf '%.44s' 는 *바이트* 기준이라 한글이 깨진다.
    [ "${#req}" -gt 46 ] && req="${req:0:46}…"
    printf '  %s  %s  (%s)\n      %s\n' "$status" "$name" "$mtime" "$req"
  done
  [ "$found" -eq 1 ] || printf '(.cowork 에 작업이 없다)\n'
}

REVIEW_MODE=0
case "${1:-}" in
  --list | -l) list_coworks; exit 0 ;;
  --init) do_init_prompt "${2:-}"; exit 0 ;;
  --init-hook) do_init_hook; exit 0 ;;
  --review) REVIEW_MODE=1; REVIEW_SLUG="${2:-}" ;;
esac

# 리뷰 모드는 분석 준비(SLUG 파싱·프롬프트 조립·러너 정의)를 건너뛰고 스크립트 하단에서 do_review 만 돈다.
if [ "$REVIEW_MODE" = 1 ]; then
  [ -n "${REVIEW_SLUG:-}" ] || die "--review 에는 폴더명이 필요하다. 예: cowork.sh --review login-timeout"
  do_review "$REVIEW_SLUG"
  exit $?
fi

[ $# -ge 2 ] || usage
SLUG="$1"; shift
PROMPT_TEXT="$*"

# 폴더명 = 작업 ID. 사람이 지정한 값을 그대로 쓰되 파일시스템에 안전한 형태만 허용한다.
[[ "$SLUG" =~ ^[a-z0-9][a-z0-9-]*$ ]] \
  || die "폴더명은 소문자·숫자·하이픈만 가능하다(작업 ID): '$SLUG'  예: login-timeout"
[ -n "${PROMPT_TEXT// /}" ] || die "분석 요청 프롬프트가 비어 있다."
[ -f "$PERSONA_FILE" ] || die "아바타 페르소나 파일이 없다: $PERSONA_FILE"

OUT_DIR="$REPO_ROOT/.cowork/$SLUG"
LOG_DIR="$OUT_DIR/.logs"

# 같은 작업 ID 로 다시 돌리면 이전 결과를 덮어쓴다. 조용히 지우지 않고 무엇이 사라지는지 알린다
# (사람이 작업 ID 를 관리하므로, 남겨야 하면 다른 이름을 쓰면 된다).
if [ -d "$OUT_DIR" ]; then
  printf '⚠️  기존 작업 폴더에 덮어쓴다: .cowork/%s\n' "$SLUG" >&2
  [ -f "$OUT_DIR/final-report.md" ] \
    && printf '    (이전 종합 결과 final-report.md 가 사라진다 — 남기려면 다른 폴더명으로 실행)\n' >&2
fi

mkdir -p "$LOG_DIR" || die "출력 폴더를 만들 수 없다: $OUT_DIR"

# 리뷰 대기 마커: 작업 시작 시 남긴다. Stop hook 이 이 마커를 보고 final-report.md 를 최종 재검토한다.
# (Stop hook 미설치 프로젝트에선 무해한 빈 파일일 뿐이다.) 리뷰 완료 시 do_review 가 삭제한다.
printf '%s\n%s\n' "$(date '+%Y-%m-%d %H:%M:%S')" "$PROMPT_TEXT" > "$OUT_DIR/.review-final-report"

# --- 프롬프트 조립: 아바타 페르소나 + 사용자 요청 -----------------------------
persona="$(extract_block "$PERSONA_FILE" PERSONA)"
[ -n "$persona" ] || die "페르소나 마커(---BEGIN PERSONA---)를 찾지 못했다: $PERSONA_FILE"

# --- 대상 작업공간 블록 조립 ---------------------------------------------------
# 사람이 쓴 .cowork/cowork-prompt.md(있으면 최우선) + 자동 감지 사실.
# 함수 정의(detect_workspace_facts·build_project_context)와 그 근거는 이 스크립트 상단에 있다.
project_context="$(build_project_context "$REPO_ROOT")"

# 페르소나의 {{PROJECT_CONTEXT}} 자리를 조립 결과로 치환한다.
# 🛑 bash 자체 치환(${var/pat/rep})만 쓴다. sed 는 치환문의 `/`(경로)·`&` 에 깨지고,
#    awk -v 는 값에 개행이 있으면 "newline in string" 으로 죽는다(둘 다 실측 실패).
#    감지 결과는 여러 줄이고 경로를 포함하므로 bash 치환이 유일하게 안전하다.
if [[ "$persona" == *"{{PROJECT_CONTEXT}}"* ]]; then
  persona="${persona/'{{PROJECT_CONTEXT}}'/$project_context}"
else
  # 마커가 없어도 죽이지는 않는다(분석은 가능하다). 다만 페르소나가 프로젝트를 모른 채 돈다.
  printf '⚠️  페르소나에 {{PROJECT_CONTEXT}} 마커가 없다 — 프로젝트 정보가 주입되지 않는다.\n' >&2
  printf '    references/analyst-persona.md 의 "## 대상 프로젝트" 절을 확인하라.\n' >&2
fi

PROMPT_FILE="$OUT_DIR/.prompt.md"
{
  printf '%s\n\n' "$persona"
  printf '## 분석 요청\n\n%s\n' "$PROMPT_TEXT"
} > "$PROMPT_FILE"

# --- 섹션 헤더 정규화 --------------------------------------------------------
# `## 1. 결론 요약` 같은 섹션 헤더가 줄 중간에 붙어 있으면 앞에 빈 줄을 넣어 진짜 헤더로 만든다.
#
# 🛑 왜 (실측 2026-07-17, skill-selftest): 페르소나가 "서두 없이 바로 출력하라"고 지시했는데도 grok 이
#    "…재검증하고, 놓친 경로를 추가로 찾습니다.## 1. 결론 요약" 처럼 **서두 뒤에 개행 없이** 헤더를
#    이어 붙였다. 마크다운은 이것을 헤더로 보지 않아 §1 이 통째로 본문에 묻히고, 종합 단계에서 섹션을
#    찾지 못한다(`grep '^## '` 에 안 걸린다).
#
# 프롬프트로 "붙이지 말라"고 부탁하는 대신 결정론적으로 고친다 — 모델의 준수에 기대면 다시 깨진다.
# 줄 시작(앞이 개행)인 헤더는 건드리지 않으므로 정상 출력에는 무해하다.
normalize_sections() { # <파일>
  perl -0pi -e 's/(?<!\n)(#{2,3} \d+\. )/\n\n$1/g' "$1" 2> /dev/null || true
}

# 결과 파일 앞에 메타 헤더를 붙인다(누가·언제·얼마나·성공 여부).
finalize() {
  local name="$1" file="$2" rc="$3" secs="$4" cmd="$5"
  local stamp; stamp="$(date '+%Y-%m-%d %H:%M:%S')"
  local body="" size=0
  [ -f "$file" ] && normalize_sections "$file"
  [ -f "$file" ] && { body="$(cat "$file")"; size="$(wc -c <"$file" | tr -d ' ')"; }

  # 빈 응답(50바이트 미만)은 성공 코드라도 실패로 본다.
  if [ "$rc" -ne 0 ] || [ "$size" -lt 50 ]; then
    [ "$rc" -eq 0 ] && rc=99
    {
      printf '<!-- cowork:%s | %s | 실패(exit=%s) | %ss -->\n' "$name" "$stamp" "$rc" "$secs"
      printf '# ⚠️ %s 분석 실패\n\n' "$name"
      printf -- '- 종료 코드: `%s` %s\n' "$rc" \
        "$( [ "$rc" -eq 124 ] && echo "(제한 시간 ${COWORK_TIMEOUT}s 초과)" || { [ "$rc" -eq 99 ] && echo "(빈 응답)"; } )"
      printf -- '- 명령: `%s`\n' "$cmd"
      printf -- '- 로그: `.cowork/%s/.logs/%s.log`\n\n' "$SLUG" "$name"
      printf '이 파일은 분석 결과가 아니다. 종합(final-report.md) 시 %s 의견은 **없는 것으로** 취급하고,\n' "$name"
      printf '그 사실을 final-report.md 에 명시하라. 재시도: `COWORK_ONLY=%s bash .claude/skills/cowork/scripts/cowork.sh %s "..."`\n' "$name" "$SLUG"
      [ -n "$body" ] && { printf '\n<details><summary>부분 출력</summary>\n\n```\n%s\n```\n\n</details>\n' "$body"; }
    } > "$file"
    return 1
  fi

  {
    printf '<!-- cowork:%s | %s | exit=0 | %ss -->\n' "$name" "$stamp" "$secs"
    printf '# %s 분석 — %s\n\n' "$name" "$SLUG"
    printf '> 요청: %s\n> 생성: %s · 소요 %ss · 읽기 전용 분석(작업공간 미수정)\n\n---\n\n' \
      "$PROMPT_TEXT" "$stamp" "$secs"
    printf '%s\n' "$body"
  } > "$file"
  return 0
}

# --- 분석 러너 4종 (claude·codex·grok·kimi) ---------------------------------
# 공통: cwd=REPO_ROOT (각 CLI 가 CLAUDE.md/AGENTS.md 를 자동으로 읽게 한다)

run_claude() {
  local file="$OUT_DIR/claude-cowork.md" log="$LOG_DIR/claude.log"
  local t0=$SECONDS rc=0
  # 읽기 전용 강제: 도구 화이트리스트(Read/Grep/Glob) + 쓰기 도구 명시 거부 + plan 모드.
  # headless(-p) 에서는 화이트리스트 밖 도구가 승인 요청 → 자동 거부되어 수정이 불가능하다.
  cd "$REPO_ROOT" && run_timeout "$COWORK_TIMEOUT" \
    claude -p "$(cat "$PROMPT_FILE")" \
      --permission-mode plan \
      --model "$COWORK_CLAUDE_MODEL" --effort "$COWORK_CLAUDE_EFFORT" \
      --allowedTools "Read Grep Glob" \
      --disallowedTools "Edit Write NotebookEdit Bash" \
      > "$file" 2> "$log" < /dev/null
  rc=$?
  finalize claude "$file" "$rc" "$((SECONDS - t0))" "claude -p --model $COWORK_CLAUDE_MODEL --effort $COWORK_CLAUDE_EFFORT --permission-mode plan --allowedTools 'Read Grep Glob'"
}

run_codex() {
  local file="$OUT_DIR/codex-cowork.md" log="$LOG_DIR/codex.log"
  local t0=$SECONDS rc=0
  # 읽기 전용 강제: --sandbox read-only 는 OS 레벨 샌드박스라 쓰기 자체가 불가능하다.
  # -o 로 최종 메시지만 파일에 받는다(진행 로그·토큰 메타가 섞이지 않는다).
  # 프롬프트는 stdin('-')으로 넘긴다. --skip-git-repo-check 는 미신뢰 디렉토리 조기 종료 방지.
  # 🛑 model_reasoning_effort 강제: 사용자 config 기본이 "low" 라 override 없이는 저사양 분석이 된다.
  cd "$REPO_ROOT" && run_timeout "$COWORK_TIMEOUT" \
    codex exec --sandbox read-only --skip-git-repo-check --color never \
      ${COWORK_CODEX_MODEL:+-m "$COWORK_CODEX_MODEL"} \
      -c model_reasoning_effort="$COWORK_CODEX_EFFORT" \
      -o "$file" - \
      < "$PROMPT_FILE" > "$log" 2>&1
  rc=$?
  finalize codex "$file" "$rc" "$((SECONDS - t0))" "codex exec --sandbox read-only -c model_reasoning_effort=$COWORK_CODEX_EFFORT -o <file> -"
}

run_grok() {
  local file="$OUT_DIR/grok-cowork.md" log="$LOG_DIR/grok.log"
  local t0=$SECONDS rc=0

  # 🛑 grok 은 CLI 의 읽기 전용 옵션이 *전부 무력하다*(2026-07-16 실측):
  #    --sandbox read-only / --permission-mode plan / --tools / --disallowed-tools / --deny
  #    다섯 가지 모두 무시되고 파일이 그대로 생성됐다(--sandbox 는 "프로파일 없음" 경고만 내고 통과).
  #    따라서 grok 은 OS 레벨 sandbox-exec 로 감싸 프로젝트 경로 쓰기를 물리적으로 막는다(kimi 도
  #    같은 이유·같은 프로파일 — run_kimi 참고).
  #    프로젝트 밖(~/.grok 세션·캐시)은 허용해야 grok 이 정상 동작한다 → subpath 만 deny.
  #    상세·재현 절차: references/readonly-enforcement.md. 이 래핑을 벗기지 말 것.
  if ! command -v sandbox-exec > /dev/null 2>&1; then
    # fail-safe: 샌드박스가 없으면 grok 을 아예 돌리지 않는다.
    # (조용히 쓰기 가능한 상태로 실행하느니 분석 하나를 포기하는 편이 안전하다)
    printf 'sandbox-exec 없음 — grok 을 읽기 전용으로 가둘 수 없어 실행하지 않았다(macOS 전용).\n' > "$log"
    finalize grok "$file" 98 "$((SECONDS - t0))" "sandbox-exec 부재로 미실행"
    return 1
  fi

  # 샌드박스 프로파일은 run_grok_headless 가 매 호출마다 조립한다(leader 소켓·재시도와 함께).

  # 🔬 grok 만 2-pass 로 돌린다. grok 은 다른 러너들보다 먼저 끝내고 놀았다(3 AI 시절 실측 132·202s vs
  #    claude 320~399s, codex 573~717s; kimi 는 이후 합류해 237s). 종합은 넷이 다 끝나야 시작되므로
  #    그 유휴 시간은 공짜다 —
  #    깊이 파게 해도 cowork 전체 벽시계는 느려지지 않는다. 근거·지침 SSOT: references/grok-deep-protocol.md
  #    Pass 1: CoT+ToT 로 깊게 탐색 → .grok-pass1.md 로 확정 저장
  #    Pass 2: 그 파일을 입력으로 받아 *남의 글처럼* 적대적으로 비판하고 다시 씀 → grok-cowork.md
  #    (한 번의 호출에 "스스로 비판하라"고 적으면 자기 글을 관대하게 본다. 그래서 두 세션으로 쪼갠다)
  local pass1_out="$OUT_DIR/.grok-pass1.md"
  local p1_prompt="$OUT_DIR/.grok-pass1-prompt.md"
  local p2_prompt="$OUT_DIR/.grok-pass2-prompt.md"
  local deep1 deep2
  deep1="$(extract_block "$GROK_PROTOCOL_FILE" GROK-PASS1)"
  deep2="$(extract_block "$GROK_PROTOCOL_FILE" GROK-PASS2)"
  if [ -z "$deep1" ] || [ -z "$deep2" ]; then
    printf 'grok 심층 지침 마커를 찾지 못했다: %s\n' "$GROK_PROTOCOL_FILE" > "$log"
    finalize grok "$file" 97 "$((SECONDS - t0))" "grok-deep-protocol.md 마커 누락"
    return 1
  fi

  # --- Pass 1: 심층 탐색 (CoT + ToT) ---
  {
    printf '%s\n\n' "$persona"
    printf '%s\n\n' "$deep1"
    printf '## 분석 요청\n\n%s\n' "$PROMPT_TEXT"
  } > "$p1_prompt"

  # 빈 로그로 시작(재시도 흔적을 같은 파일에 append)
  : > "$log"
  run_grok_with_retries "pass1" "$p1_prompt" "$pass1_out" "$log" "$LOG_DIR/grok-pass1-debug"
  rc=$?

  local size1=0
  [ -f "$pass1_out" ] && size1="$(wc -c < "$pass1_out" | tr -d ' ')"
  if [ "$rc" -ne 0 ] || [ "$size1" -lt 50 ]; then
    # Pass 1 이 죽으면 비판할 원본이 없다 → grok 은 실패로 확정(종합에서 제외된다).
    # 재시도까지 소진한 상태 — 부분 출력이 있으면 finalize 가 details 로 보존.
    cp "$pass1_out" "$file" 2> /dev/null
    finalize grok "$file" "$rc" "$((SECONDS - t0))" \
      "grok pass1(심층 탐색) 실패 — ${COWORK_GROK_RETRIES}회 재시도 후 (leader 격리+always-approve)"
    return 1
  fi
  printf '   ▶ grok pass1 완료(%ss) → pass2 자기 비판·재분석 시작\n' "$((SECONDS - t0))" >&2

  # --- Pass 2: 적대적 자기 비판 → 재분석 ---
  # Pass 1 결과 *전문* 을 프롬프트에 실어 준다. 새 세션이라 grok 은 이것을 남의 글로 본다.
  {
    printf '%s\n\n' "$persona"
    printf '%s\n\n' "$deep2"
    printf '## 분석 요청\n\n%s\n\n' "$PROMPT_TEXT"
    printf -- '---\n\n## 1차 분석 결과 (당신이 방금 쓴 것 — 이제 이것을 공격하라)\n\n'
    cat "$pass1_out"
  } > "$p2_prompt"

  # `>` 로 새로 쓴다(`>>` 금지). 앞선 실행이 중간에 죽어 .tmp 가 남아 있으면 append 는 두 보고서를
  # 이어 붙여 종합 단계에 모순된 결론을 먹인다.
  rm -f "$file.tmp"
  run_grok_with_retries "pass2" "$p2_prompt" "$file.tmp" "$log" "$LOG_DIR/grok-pass2-debug"
  rc=$?

  local size2=0
  [ -f "$file.tmp" ] && size2="$(wc -c < "$file.tmp" | tr -d ' ')"
  if [ "$rc" -ne 0 ] || [ "$size2" -lt 50 ]; then
    # Pass 2 만 죽었으면 Pass 1 의 깊은 분석을 버리지 않고 최종으로 승격한다(비판만 못 거친 것).
    printf '\n[cowork] pass2 실패(exit=%s, %sB, retries=%s) — pass1 결과를 최종으로 승격\n' \
      "$rc" "$size2" "$COWORK_GROK_RETRIES" >> "$log"
    rm -f "$file.tmp"
    cp "$pass1_out" "$file"
    finalize grok "$file" 0 "$((SECONDS - t0))" "grok 2-pass (pass2 실패 → pass1 승격, 자기 비판 미적용)"
    return $?
  fi

  mv "$file.tmp" "$file"
  finalize grok "$file" 0 "$((SECONDS - t0))" "grok 2-pass: CoT/ToT 탐색 → 적대적 자기 비판 → 재분석"
}

run_kimi() {
  local file="$OUT_DIR/kimi-cowork.md" log="$LOG_DIR/kimi.log"
  local t0=$SECONDS rc=0

  # kimi 실행 파일: 비대화형 셸에는 ~/.zshrc 의 PATH 확장이 없을 수 있어 공식 설치 경로를 폴백으로 둔다.
  local kimi_bin
  kimi_bin="$(command -v kimi 2> /dev/null || true)"
  [ -n "$kimi_bin" ] || kimi_bin="$HOME/.kimi-code/bin/kimi"
  if [ ! -x "$kimi_bin" ]; then
    printf 'kimi CLI 를 찾을 수 없다(PATH 및 %s). 설치: https://github.com/MoonshotAI/kimi-code\n' \
      "$HOME/.kimi-code/bin/kimi" > "$log"
    finalize kimi "$file" 96 "$((SECONDS - t0))" "kimi CLI 미설치"
    return 1
  fi

  # 🛑 kimi 는 headless(-p)에서 승인 게이트 없이 쓰기 도구까지 실행한다(2026-07-18 실측: -p 만으로
  #    파일 생성 성공). --plan 은 -p 와 조합 불가(CLI 가 거절) → CLI 옵션으로는 읽기 전용을 강제할 수
  #    없다. 그래서 grok 과 동일하게 OS 레벨 sandbox-exec 로 프로젝트 쓰기를 물리 차단한다(같은
  #    프로파일에서 Write 도구가 EPERM 실패, kimi 는 크래시 없이 계속 동작함을 실측 확인).
  #    상세·재현 절차: references/readonly-enforcement.md. 이 래핑을 벗기지 말 것.
  if ! command -v sandbox-exec > /dev/null 2>&1; then
    printf 'sandbox-exec 없음 — kimi 를 읽기 전용으로 가둘 수 없어 실행하지 않았다(macOS 전용).\n' > "$log"
    finalize kimi "$file" 98 "$((SECONDS - t0))" "sandbox-exec 부재로 미실행"
    return 1
  fi
  local sbx_profile
  sbx_profile="$(printf '(version 1)\n(allow default)\n(deny file-write* (subpath "%s"))\n' "$REPO_ROOT_PHYS")"

  # 프롬프트는 -p 인자로 통째 전달한다(kimi 에는 grok 의 --prompt-file 에 해당하는 옵션이 없다).
  # -m 으로 K3 을 명시 고정한다 — config 의 default_model 이 K2.7 로 바뀌어도 cowork 는 K3 을 쓴다.
  cd "$REPO_ROOT" && run_timeout "$COWORK_TIMEOUT" \
    sandbox-exec -p "$sbx_profile" \
      "$kimi_bin" -p "$(cat "$PROMPT_FILE")" --output-format text \
      -m "$COWORK_KIMI_MODEL" \
      > "$file" 2> "$log" < /dev/null
  rc=$?
  # kimi 는 출력 끝에 "To resume this session: ..." 세션 안내를 붙인다 — 분석 내용이 아니므로 제거.
  [ -f "$file" ] && sed -i '' '/^To resume this session: kimi -r /d' "$file" 2> /dev/null
  finalize kimi "$file" "$rc" "$((SECONDS - t0))" "sandbox-exec + kimi -p -m $COWORK_KIMI_MODEL --output-format text (OS 읽기 전용)"
}

# --- 병렬 실행 --------------------------------------------------------------
printf '🔍 cowork: %s\n' "$SLUG" >&2
printf '   요청: %s\n' "$PROMPT_TEXT" >&2
printf '   출력: .cowork/%s/  (제한 %ss · 대상 %s)\n' "$SLUG" "$COWORK_TIMEOUT" "$COWORK_ONLY" >&2
if [ -f "$REPO_ROOT/.cowork/cowork-prompt.md" ]; then
  printf '   지침: .cowork/cowork-prompt.md 를 4 AI 에 주입함\n\n' >&2
elif [ -f "$REPO_ROOT/.cowork/prompt.md" ]; then
  # 예전 이름 — 읽어는 주되(하위 호환), 새 이름으로 바꾸라고 알린다.
  printf '   지침: .cowork/prompt.md 를 4 AI 에 주입함 (예전 이름)\n' >&2
  printf '   ⚠️  파일명이 바뀌었다 — `mv .cowork/prompt.md .cowork/cowork-prompt.md` 로 옮겨라.\n\n' >&2
else
  # 시스템 프롬프트가 없으면 네 AI 가 프로젝트 목적을 모른 채 일반론으로 분석한다 — 사람에게 알린다.
  printf '   💡 .cowork/cowork-prompt.md 가 없다 — `cowork.sh --init` 으로 이 프로젝트의 시스템 프롬프트\n' >&2
  printf '      (특성·기획·계획·페르소나·로직·개념)를 만들어 두면 이후 모든 분석 품질이 올라간다.\n\n' >&2
fi

wants kimi && check_kimi_model_alias

declare -a NAMES=() PIDS=()
for ai in claude codex grok kimi; do
  wants "$ai" || continue
  "run_$ai" & PIDS+=("$!"); NAMES+=("$ai")
  printf '   ▶ %s 분석 시작 (pid %s)\n' "$ai" "$!" >&2
done
[ "${#PIDS[@]}" -gt 0 ] || die "실행할 AI 가 없다. COWORK_ONLY='$COWORK_ONLY' 를 확인하라."

printf '\n   … %d개 AI 가 동시에 작업공간을 읽는 중 (수 분 소요)\n\n' "${#PIDS[@]}" >&2

ok=0; fail=0
declare -a FAILED=()
for i in "${!PIDS[@]}"; do
  if wait "${PIDS[$i]}"; then
    printf '   ✅ %-6s → .cowork/%s/%s-cowork.md\n' "${NAMES[$i]}" "$SLUG" "${NAMES[$i]}" >&2
    ok=$((ok + 1))
  else
    printf '   ❌ %-6s 실패 → .cowork/%s/.logs/%s.log 확인\n' "${NAMES[$i]}" "$SLUG" "${NAMES[$i]}" >&2
    fail=$((fail + 1)); FAILED+=("${NAMES[$i]}")
  fi
done

printf '\nSTATUS: 성공=%d 실패=%d 폴더=.cowork/%s\n' "$ok" "$fail" "$SLUG" >&2
[ "$fail" -gt 0 ] && printf 'FAILED: %s\n' "${FAILED[*]}" >&2

# 하나도 못 얻었으면 종합할 것이 없다. 리뷰 대기 마커도 지워 Stop hook 이 헛돌지 않게 한다.
if [ "$ok" -eq 0 ]; then
  rm -f "$OUT_DIR/.review-final-report"
  exit 1
fi

# --- 배턴 넘기기 (이 블록을 지우지 말 것) -----------------------------------
# 이 스크립트는 cowork 파이프라인의 *절반*(4 AI 분석)만 한다. 나머지 절반(종합=final-report.md)은
# 오케스트레이터(Claude)가 해야 하는데, 그 경계에서 배턴이 떨어지는 사고가 실제로 났다:
#
#   2026-07-16 실측 — cowork 두 건을 겹쳐 돌리자(11:18 product-load-fail, 11:25 billing-code6)
#   먼저 끝난 product-load-fail(11:28 분석 3/3 성공)의 final-report.md 가 통째로 누락됐다.
#   나중에 끝난 billing-code6 만 종합됐다(11:40). 원인: 백그라운드 실행 시 완료 알림에는 이
#   스크립트의 출력만 실려 오는데, 마지막 줄이 "STATUS: 성공=3 실패=0" 뿐이라 Claude 가
#   "스크립트가 잘 끝났다"로만 읽고 종합 단계를 인지하지 못했다. SKILL.md 지침은 여러 턴 전에
#   로드돼 이미 희미해진 뒤였다.
#
# 그래서 다음 단계를 *출력에 실어* 보낸다 — 알림과 함께 도착하므로 몇 턴 뒤에도 놓칠 수 없다.
# 실제로 만들어진 파일만 나열한다(COWORK_ONLY 로 일부만 돌렸을 때 없는 파일을 읽으라고 하면 안 된다).
# 실패한 것도 포함한다 — 실패 사실 자체를 종합에 반영해야 하기 때문(references/final-report-protocol.md §3).
cowork_files=""
for i in "${!NAMES[@]}"; do
  cowork_files+="       .cowork/$SLUG/${NAMES[$i]}-cowork.md"$'\n'
done

cat >&2 <<EOF

════════════════════════════════════════════════════════════════
⏭️  아직 끝나지 않았다 — 종합(final-report.md)이 남았다 [필수]

  1. 아래 분석 파일을 모두 읽어라
$cowork_files  2. 결론을 좌우하는 근거(파일:줄)를 실제로 열어 교차검증하라 (환각 제거 = cowork 의 핵심 가치)
  3. .cowork/$SLUG/final-report.md 를 작성하라
       규칙·템플릿: .claude/skills/cowork/references/final-report-protocol.md
  4. 결론을 사용자에게 본문으로 보고하라 (파일 경로만 던지지 말 것)
  5. 사용자 요청에 구현·수정이 포함돼 있었다면 보고 직후 되묻지 말고 즉시 구현하라
       (final-report.md §7 권고 = 작업 지시서. 분석만 요청받았으면 여기서 멈춘다)

  ⚠️ 종합(final-report.md) 완성 전에는 무엇도 수정하지 말라 — 검증 전 주장은 환각일 수 있다.
  ⚠️ 지금 다른 작업 중이어도 이 종합을 건너뛰지 말라. 먼저 끝내고 하던 일로 돌아가라.
     종합이 안 끝난 작업 확인:  bash .claude/skills/cowork/scripts/cowork.sh --list
════════════════════════════════════════════════════════════════
EOF
exit 0
