#!/usr/bin/env bash
# cowork.sh — claude·codex·grok·kimi·agy + OpenCode 3모델을 읽기 전용 분석가로 병렬 실행한다.
#
#   사용: bash .claude/skills/cowork/scripts/cowork.sh <slug> <분석 요청 프롬프트>
#   결과: .cowork/<slug>/{claude,codex,grok,kimi,deepseek,minimax,qwen,agy}-cowork.md
#
# 이 스크립트는 **분야를 가리지 않는다.** 작업공간이 소프트웨어 저장소든, 교재·문제은행·레시피·기획서
# 폴더든 동일하게 동작한다. 작업공간의 성격은 `.cowork/cowork-prompt.md`(사람이 쓴 지침) + 실행 시점 자동
# 감지로 주입한다 — 특정 분야를 이 스크립트나 페르소나에 하드코딩하지 말 것.
#
# 설계 요지
#   - 여덟 AI 는 읽기 전용으로 강제된다. AI 자신은 작업공간 파일을 쓸 수 없고, 분석은 stdout 으로만
#     낸다. 파일 기록은 이 스크립트가 한다.
#     → "절대 수정 금지" 를 프롬프트(부탁)가 아니라 도구/OS 권한(강제)으로 보장한다.
#   - ⚠️ 방어 수단이 CLI 마다 다른 이유는 실측 결과가 다르기 때문이다. 근거와 재현 절차는
#     references/readonly-enforcement.md 참고. 임의로 통일하지 말 것(특히 grok·kimi).
#   - 여덟 AI 는 동시에 돌린다(가장 느린 하나의 시간만 걸린다). OpenCode 세 모델도 각각 독립
#     `opencode run` 프로세스로 실행하며 한 프로세스 안에서 모델을 순차 호출하지 않는다.
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
# 특정 AI 만 (재)실행. 쉼표로 여러 개를 지정한다(실패한 AI 재시도용).
# OpenCode 분석 이름은 deepseek|minimax|qwen 이다. agy 는 Antigravity CLI(Gemini 계열)다.
COWORK_AI_NAMES=(claude codex grok kimi deepseek minimax qwen agy)
COWORK_OPENCODE_NAMES=(deepseek minimax qwen)
COWORK_ONLY="${COWORK_ONLY:-claude,codex,grok,kimi,deepseek,minimax,qwen,agy}"

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
#   - agy   : Antigravity CLI. Gemini 3.7 Flash (High)를 명시 고정한다(2026-08-14 사용자 지시).
#             cowork 의 유일한 Gemini 계열 두뇌다 — v2.5.0 에서 `opencode-go/gemini-3.6-flash`
#             가 구독에 없어 빠진 뒤 공백이었던 자리를, 자체 CLI 를 가진 Antigravity 로 메운다.
#             모델 ID 의 `-high` 접미어 자체가 추론 등급이라 `--effort` 와 의미가 겹치지만,
#             CLI 가 두 값을 모두 받으므로 둘 다 최고로 맞춘다(--effort 는 low|medium|high 만
#             지원 — grok 과 같이 xhigh 는 없어 high 가 최고다. 아래에서 정규화한다).
# 값을 낮춰야 할 때(요금·속도)만 환경변수로 override 한다. 기본을 낮추지 말 것.
COWORK_CLAUDE_MODEL="${COWORK_CLAUDE_MODEL:-claude-opus-5}"
COWORK_CLAUDE_EFFORT="${COWORK_CLAUDE_EFFORT:-xhigh}"
COWORK_CODEX_EFFORT="${COWORK_CODEX_EFFORT:-xhigh}"
COWORK_CODEX_MODEL="${COWORK_CODEX_MODEL:-}"   # 비우면 ~/.codex/config.toml 의 최신 모델 상속
# codex fallback 모델. 1차 실행이 **모델 거절**로 실패했을 때만 한 번 재시도한다.
# 🛑 2026-08-10 실측: config 의 `gpt-5.6-sol` 이 `The 'gpt-5.6-sol' model is not supported when
#    using Codex with a ChatGPT account.` 로 400 을 받아 codex 분석이 통째로 빠졌다. 계정 등급이나
#    모델 폐기로 특정 모델만 거절당하는 일이 실재하므로 대안을 하나 준비해 둔다.
#    `gpt-5.6-terra` 는 같은 계정에서 정상 응답함을 실측 확인했다(2026-08-10).
#    빈 문자열로 두면 fallback 을 쓰지 않는다.
COWORK_CODEX_FALLBACK_MODEL="${COWORK_CODEX_FALLBACK_MODEL:-gpt-5.6-terra}"
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
# 정책상 **반드시** 써야 하는 값(2026-08-08 사용자 지시: "꼭 k3-256k 를 써야 한다").
# COWORK_KIMI_MODEL 이 여기서 벗어나면 check_kimi_model_alias() 가 실행 전에 경고한다 —
# 환경변수로 조용히 k3(1M)로 되돌아가 context quota 를 두 배로 태우는 사고를 막는다.
COWORK_KIMI_MODEL_REQUIRED="kimi-code/k3-256k"
COWORK_KIMI_CONTEXT_REQUIRED="262144"
#   - OpenCode: OpenCode Go 구독의 세 모델을 **동시에 세 개의 독립 `opencode run` 프로세스**로
#               부른다. deepseek-v4-flash 는 2026-08-09 사용자 지시로 deepseek-v4-pro 로 교체했다.
#               프로바이더 접두어가 둘이니 주의 — `opencode-go/`(정액 구독)와
#               `opencode/`(Zen 종량제)는 다른 경로다. 반드시 opencode-go 를 쓴다.
#               COWORK_OPENCODE_MODEL 은 예전 deepseek 단일 설정의 하위 호환 별칭이다.
COWORK_OPENCODE_DEEPSEEK_MODEL="${COWORK_OPENCODE_DEEPSEEK_MODEL:-${COWORK_OPENCODE_MODEL:-opencode-go/deepseek-v4-pro}}"
COWORK_OPENCODE_MINIMAX_MODEL="${COWORK_OPENCODE_MINIMAX_MODEL:-opencode-go/minimax-m3}"
COWORK_OPENCODE_QWEN_MODEL="${COWORK_OPENCODE_QWEN_MODEL:-opencode-go/qwen3.6-plus}"
# opencode 인증 키 파일. 이 파일 내용을 OPENCODE_API_KEY 로 주입한다(키를 인자로 넘기면 ps 에 노출).
#
# 탐색 순서(둘 다 정식 경로다 — 먼저 **실재하는** 쪽을 쓴다. 2026-08-10 사용자 지시):
#   1. <작업공간>/.cowork/opencode-go-api.key       — 작업공간 로컬(프로젝트마다 다른 키를 쓸 때)
#   2. ~/.config/cowork/opencode-go-api.key         — 사용자 공용(여러 작업공간이 한 키를 공유)
#      (XDG_CONFIG_HOME 이 설정돼 있으면 그 아래 cowork/opencode-go-api.key)
# COWORK_OPENCODE_KEYFILE 을 직접 지정하면 탐색을 건너뛰고 그 경로만 쓴다.
# 둘 다 없으면 2번 경로를 남겨 오류 안내가 권장 위치를 가리키게 한다.
#
# 🛑 1번은 **분석 대상 폴더 안**이다. sandbox-exec 는 *쓰기만* 막고 읽기는 허용하므로 여덟 AI 가
#    전부 키를 읽어 분석 출력에 흘릴 수 있다(2026-08-08 감사 실측: deepseek 이 .cowork/ 를 나열하다
#    키 파일의 경로·권한을 발견했다). .gitignore 는 커밋만 막을 뿐 읽기 방어가 아니다.
#    그래서 1번을 쓰면 check_opencode_key() 가 매번 경고한다 — 노출이 곤란하면 2번에 둬라.
COWORK_OPENCODE_KEYFILE="${COWORK_OPENCODE_KEYFILE:-}"
if [ -z "$COWORK_OPENCODE_KEYFILE" ]; then
  for _cowork_kf in \
    "$REPO_ROOT/.cowork/opencode-go-api.key" \
    "${XDG_CONFIG_HOME:-$HOME/.config}/cowork/opencode-go-api.key"
  do
    COWORK_OPENCODE_KEYFILE="$_cowork_kf"
    [ -f "$_cowork_kf" ] && break
  done
  unset _cowork_kf
fi

# --- agy (Antigravity CLI) ---------------------------------------------------
# 모델 ID 는 `agy models` 목록의 것을 그대로 쓴다(프로바이더 접두어가 없는 평문 ID).
COWORK_AGY_MODEL="${COWORK_AGY_MODEL:-gemini-3.7-flash-high}"
# effort: CLI 가 low|medium|high 만 받는다(grok 과 같은 제약). xhigh 등이 오면 high 로 폴백한다.
COWORK_AGY_EFFORT="${COWORK_AGY_EFFORT:-high}"
case "$COWORK_AGY_EFFORT" in
  high|medium|low) ;;
  *) COWORK_AGY_EFFORT="high" ;;
esac

die() { printf '오류: %s\n' "$1" >&2; exit 1; }

# agy 모델 ID 가 **실제로 이 계정에서 쓸 수 있는지** 실행 전에 확인한다.
#
# 🛑 v2.5.0 의 gemini 사고(`opencode-go/gemini-3.6-flash` 가 구독에 없어 매 실행마다 그 하나만
#    3초 만에 조용히 죽음)를 같은 자리에서 반복하지 않기 위한 방어다. 문서·코드가 같은 잘못된
#    ID 를 공유하면 "일치 검사" 로는 못 잡는다 — 카탈로그에 직접 물어야만 알 수 있다.
# 조회 자체가 실패하면(오프라인·인증 만료) 조용히 통과한다. 여기서 경고를 쏟으면 정상 설정에서도
# 잡음이 난다 — 실제 실패는 run_agy 가 로그와 함께 기록한다.
check_agy_model() {
  command -v agy > /dev/null 2>&1 || return 0
  local avail
  avail="$(run_timeout 60 agy models 2> /dev/null < /dev/null)" || return 0
  # 첫 필드가 모델 ID(탭 구분). 목록을 하나도 못 받았으면 조회 실패로 보고 통과한다.
  local ids
  ids="$(printf '%s\n' "$avail" | awk -F'\t' 'NF && $1 !~ /^Fetching/ {print $1}')"
  [ -n "$ids" ] || return 0
  printf '%s\n' "$ids" | grep -qxF "$COWORK_AGY_MODEL" && return 0
  printf '⚠️  agy 모델이 이 계정에서 보이지 않는다: %s\n' "$COWORK_AGY_MODEL" >&2
  printf '    이대로면 agy 분석만 실패한다. 사용 가능한 목록: `agy models`\n' >&2
  return 1
}

# kimi 는 `-m` 에 config.toml 의 **별칭** 을 받는다. 등록돼 있지 않으면 API 에 닿기도 전에
# `config.invalid: Model "..." is not configured` 로 즉시 거절당한다(2026-08-08 실측).
# 여덟 AI 중 하나가 통째로 빠진 채 분석이 끝나는 사고를 막으려고 실행 전에 점검해 안내한다.
# (안내만 하고 진행한다 — 사용자의 개인 설정 파일을 스크립트가 임의로 고치지 않는다.)
# opencode 키 파일을 실행 전에 점검한다(2026-08-08 감사 권고 1순위).
# 반환 0 = 쓸 수 있는 키, 1 = 없음. 위험한 배치·권한은 경고만 하고 진행한다(사람이 판단할 몫).
check_opencode_key() {
  local kf="$COWORK_OPENCODE_KEYFILE"
  if [ ! -f "$kf" ]; then return 1; fi
  # 공백만 든 파일은 `-s` 를 통과하지만 빈 키로 실행돼 401 이 난다(실측). 정규화 후 판정한다.
  [ -n "$(tr -d '[:space:]' < "$kf" 2> /dev/null)" ] || {
    printf '⚠️  opencode 키 파일이 사실상 비어 있다(공백뿐): %s\n' "$kf" >&2
    return 1
  }
  # 작업공간 안에 있으면 여덟 AI 가 전부 읽을 수 있다 — 샌드박스는 쓰기만 막는다.
  # 🛑 상대 경로로 넘어오면 문자열 비교가 빗나가므로 절대 경로로 정규화한 뒤 판정한다
  #    (2026-08-08: 상대 경로 테스트에서 경고가 통째로 누락된 것을 실측하고 고쳤다).
  local kf_abs; kf_abs="$(cd "$(dirname "$kf")" 2> /dev/null && pwd -P)/$(basename "$kf")"
  case "$kf_abs" in
    "$REPO_ROOT_PHYS"/*)
      # 이 배치도 정식으로 지원한다(그대로 진행한다). 다만 위험을 모르고 두는 일이 없게 매번 알린다.
      printf '⚠️  opencode 키가 분석 대상 작업공간 안에 있다: %s\n' "${kf#$REPO_ROOT/}" >&2
      printf '    여덟 AI 가 이 파일을 읽어 분석 출력에 흘릴 수 있다(샌드박스는 쓰기만 막는다).\n' >&2
      printf '    노출이 곤란하면 작업공간 밖으로 옮겨라(그쪽도 자동으로 찾는다):\n' >&2
      printf '      mkdir -p ~/.config/cowork && mv %s ~/.config/cowork/opencode-go-api.key && chmod 600 ~/.config/cowork/opencode-go-api.key\n' "$kf" >&2
      # 작업공간 안 배치를 정식으로 지원하는 이상 커밋 사고도 같이 막아야 한다.
      # git 이 이 파일을 무시하지 않으면 `git add .` 한 번에 키가 그대로 이력에 박힌다.
      if git -C "$REPO_ROOT" rev-parse --git-dir > /dev/null 2>&1 \
         && ! git -C "$REPO_ROOT" check-ignore -q "$kf_abs" 2> /dev/null; then
        printf '    🛑 이 키는 .gitignore 에 걸려 있지 않다 — 커밋되면 이력에 그대로 남는다:\n' >&2
        printf '       echo ".cowork/opencode-go-api.key" >> %s/.gitignore\n' "$REPO_ROOT" >&2
      fi
      ;;
  esac
  # 0600 이 아니면 같은 머신의 다른 사용자가 읽을 수 있다.
  local mode; mode="$(stat -f '%Lp' "$kf" 2> /dev/null || stat -c '%a' "$kf" 2> /dev/null)"
  case "$mode" in
    600|400) ;;
    *) printf '⚠️  opencode 키 파일 권한이 %s 다 — `chmod 600 %s` 를 권한다.\n' "${mode:-불명}" "$kf" >&2 ;;
  esac
  return 0
}

# OpenCode 세 모델의 ID 가 **실제로 구독에 존재하는지** 실행 전에 확인한다.
#
# 🛑 2026-08-10 실측 사고: `opencode-go/gemini-3.6-flash` 를 기본값으로 박아 뒀는데 OpenCode Go
#    구독에 gemini 계열이 아예 없어(18개 모델 중 0개) **매 실행마다 그 하나만 3초 만에 조용히 죽었다.**
#    문서와 코드가 같은 잘못된 ID 를 공유했기 때문에 "문서·코드 일치" 검사로는 잡히지 않았다.
#    실재 여부는 카탈로그에 물어야만 알 수 있다.
check_opencode_models() {
  command -v opencode > /dev/null 2>&1 || return 0
  [ -s "$COWORK_OPENCODE_KEYFILE" ] || return 0   # 키가 없으면 조회 자체가 무의미(키 경고는 별도)
  # 🛑 키를 주입해서 물어야 한다. 키 없이 `opencode models` 를 부르면 무료 모델만 돌려주므로
  #    구독 모델이 전부 "없음" 으로 잡히는 **전면 오탐**이 난다(2026-08-10 실측: 4/4 오탐).
  local avail
  avail="$(OPENCODE_API_KEY="$(tr -d '[:space:]' < "$COWORK_OPENCODE_KEYFILE")" opencode models 2> /dev/null)" || return 0
  # 구독 모델이 하나도 안 보이면 인증 실패·오프라인 등 조회 자체가 실패한 것이다 — 조용히 통과한다
  # (여기서 경고를 쏟으면 정상 설정에서도 매번 잡음이 난다).
  printf '%s\n' "$avail" | grep -q '^opencode-go/' || return 0
  local ai model bad=0
  for ai in "${COWORK_OPENCODE_NAMES[@]}"; do
    wants "$ai" || continue
    model="$(opencode_model_for "$ai")" || continue
    printf '%s\n' "$avail" | grep -qxF "$model" && continue
    printf '⚠️  %s 모델이 이 구독에 없다: %s\n' "$ai" "$model" >&2
    bad=$((bad + 1))
  done
  [ "$bad" -eq 0 ] && return 0
  printf '    이대로면 해당 AI 만 `Model not found` 로 실패한다. 사용 가능한 목록: `opencode models`\n' >&2
  return 1
}

# config.toml 의 한 [models."<별칭>"] 절에서 키 하나의 값을 읽는다(따옴표 제거).
# 절 밖의 같은 이름 키(예: 파일 첫 줄 default_model)를 잘못 집지 않도록 절 경계를 지킨다.
kimi_cfg_value() { # <config> <별칭> <키>
  awk -v sec="[models.\"$2\"]" -v key="$3" '
    { line = $0; sub(/[ \t]+$/, "", line) }
    line == sec { f = 1; next }
    /^[ \t]*\[/ { f = 0 }
    f && $1 == key {
      sub(/^[^=]*=[ \t]*/, "")
      gsub(/^"|"$/, "")
      print; exit
    }
  ' "$1"
}

check_kimi_model_alias() {
  # ① 정책 점검 — 환경변수로 다른 모델이 들어오면 알린다. 별칭 등록 여부와 무관하게 먼저 본다.
  #    (사용자 요구는 "k3-256k 를 쓴다" 이지 "설정 파일이 유효하다" 가 아니다.)
  if [ "$COWORK_KIMI_MODEL" != "$COWORK_KIMI_MODEL_REQUIRED" ]; then
    printf '🛑 kimi 모델이 정책값과 다르다: %s (정책: %s)\n' \
      "$COWORK_KIMI_MODEL" "$COWORK_KIMI_MODEL_REQUIRED" >&2
    printf '    COWORK_KIMI_MODEL 이 환경에 설정돼 있는지 확인하라. k3(1M)는 같은 K3 성능에\n' >&2
    printf '    context quota 만 약 2배로 태운다. 되돌리려면: unset COWORK_KIMI_MODEL\n' >&2
  fi

  local cfg="$HOME/.kimi-code/config.toml"
  [ -f "$cfg" ] || return 0

  # ② 별칭 등록 확인 → 없으면 아래 안내문으로 빠진다.
  if grep -q "^\[models\.\"$COWORK_KIMI_MODEL\"\]" "$cfg"; then
    # ③ 🛑 별칭 **내용** 점검. 헤더만 보면 이름이 k3-256k 인데 내부 model 이 k3 를 가리키는 설정을
    #    그대로 통과시킨다 — 이름만 256K 고 실제로는 1M 를 호출하므로 사용자 요구가 **조용히** 깨진다
    #    (2026-08-12 재현 확인). 실제로 API 에 실려 나가는 것은 이 `model` 값이다(세션 wire.jsonl 에
    #    `"model":"k3-256k"` 로 기록되는 것을 실측했다).
    local want_model real_model real_ctx
    want_model="${COWORK_KIMI_MODEL#*/}"                       # kimi-code/k3-256k → k3-256k
    real_model="$(kimi_cfg_value "$cfg" "$COWORK_KIMI_MODEL" model)"
    real_ctx="$(kimi_cfg_value "$cfg" "$COWORK_KIMI_MODEL" max_context_size)"

    if [ -n "$real_model" ] && [ "$real_model" != "$want_model" ]; then
      printf '🛑 kimi 별칭 "%s" 가 실제로는 다른 모델을 가리킨다: model = "%s"\n' \
        "$COWORK_KIMI_MODEL" "$real_model" >&2
      printf '    이대로면 이름만 256K 이고 API 에는 "%s" 가 실려 나간다. %s 를 고쳐라:\n' \
        "$real_model" "$cfg" >&2
      printf '      [models."%s"] 절의  model = "%s"\n' "$COWORK_KIMI_MODEL" "$want_model" >&2
    fi
    if [ "$COWORK_KIMI_MODEL" = "$COWORK_KIMI_MODEL_REQUIRED" ] \
       && [ -n "$real_ctx" ] && [ "$real_ctx" != "$COWORK_KIMI_CONTEXT_REQUIRED" ]; then
      printf '⚠️  kimi 별칭 "%s" 의 max_context_size 가 %s 다(기대 %s).\n' \
        "$COWORK_KIMI_MODEL" "$real_ctx" "$COWORK_KIMI_CONTEXT_REQUIRED" >&2
      printf '    256K 를 쓰는 목적(quota 절약)이 무너질 수 있으니 %s 를 확인하라.\n' "$cfg" >&2
    fi
    return 0
  fi

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
  --init     .cowork/cowork-prompt.md (이 작업공간의 공통 지침) 초안을 만든다. 8 AI 분석마다 주입된다.
             이미 있으면 건드리지 않는다(사람이 다듬은 내용 보호). 덮어쓰려면 --force.
  --init-hook  이 프로젝트 .claude/settings.json 의 Stop hook 에 final-report 리뷰를 멱등 설치한다.
  --review   <폴더명>의 final-report.md 를 8 AI 로 재검토해 갱신한다(보통 Stop hook 이 백그라운드로 호출).

환경변수:
  COWORK_TIMEOUT        AI 1개당 제한 시간(초, 기본 900)
  COWORK_ONLY           실행할 AI 목록(기본 claude,codex,grok,kimi,deepseek,minimax,qwen,agy)
  COWORK_CLAUDE_MODEL   claude 모델(기본 claude-opus-5 = Opus 5 고정)
  COWORK_CLAUDE_EFFORT  claude 추론 등급(기본 xhigh)
  COWORK_CODEX_MODEL    codex 모델(기본 빈값 = ~/.codex/config.toml 의 최신 모델 상속)
  COWORK_CODEX_EFFORT   codex 추론 등급(기본 xhigh — config 의 low 를 override)
  COWORK_CODEX_FALLBACK_MODEL
                        1차가 **모델 거절**로 실패했을 때만 한 번 재시도할 모델(기본 gpt-5.6-terra).
                        계정 등급·모델 폐기로 특정 모델만 400 거절되는 일이 실재한다. 네트워크·
                        타임아웃 같은 일반 실패에는 재시도하지 않는다. 빈값이면 fallback 없음.
  COWORK_GROK_EFFORT    grok 추론 등급(기본 high; xhigh 등 미지원 값은 high 로 폴백)
  COWORK_GROK_RETRIES   grok 빈응답/실패 시 재시도 횟수(기본 3)
  COWORK_KIMI_MODEL     kimi 모델(기본 kimi-code/k3-256k = K3 256K. 1M 짜리 k3 보다 context
                        quota 를 약 2배 절약한다 — 특별한 이유 없이 k3 로 되돌리지 말 것)
  COWORK_OPENCODE_DEEPSEEK_MODEL
                        DeepSeek 모델(기본 opencode-go/deepseek-v4-pro).
                        예전 COWORK_OPENCODE_MODEL 도 deepseek 전용 별칭으로 계속 지원한다.
  COWORK_OPENCODE_MINIMAX_MODEL
                        MiniMax 모델(기본 opencode-go/minimax-m3)
  COWORK_OPENCODE_QWEN_MODEL
                        Qwen 모델(기본 opencode-go/qwen3.6-plus)
                        세 모델은 각각 독립된 opencode run 프로세스로 동시에 실행된다.
  COWORK_OPENCODE_KEYFILE
                        opencode API 키 파일. 지정하지 않으면 아래 두 경로를 순서대로 찾아
                        먼저 실재하는 쪽을 쓴다:
                          1) <작업공간>/.cowork/opencode-go-api.key  (로컬 — 여덟 AI 가 읽을 수
                             있으므로 이 배치를 쓰면 실행할 때마다 경고한다)
                          2) ~/.config/cowork/opencode-go-api.key    (권장 — 작업공간 밖)
                        없거나 비면 OpenCode 세 분석만 실패로 기록되고 나머지는 계속 간다.
  COWORK_AGY_MODEL      agy(Antigravity) 모델(기본 gemini-3.7-flash-high).
                        `agy models` 의 ID 를 그대로 쓴다. 실행 전에 실재 여부를 점검한다.
  COWORK_AGY_EFFORT     agy 추론 등급(기본 high; low|medium|high 만 지원 — 그 외 값은 high 로 폴백)

예:
  bash .claude/skills/cowork/scripts/cowork.sh login-timeout "로그인이 가끔 끊기는 원인 분석"
  bash .claude/skills/cowork/scripts/cowork.sh grade3-fractions "초등 3학년 분수 단원 구성이 적절한지 검토"
  COWORK_ONLY=minimax,qwen COWORK_TIMEOUT=600 bash .claude/skills/cowork/scripts/cowork.sh login-timeout "..."
  bash .claude/skills/cowork/scripts/cowork.sh --list
  bash .claude/skills/cowork/scripts/cowork.sh --init
EOF
  exit 2
}

# 실행 대상 AI 필터(COWORK_ONLY). 분석·리뷰가 공용하므로 앞에 둔다.
wants() { [[ ",$COWORK_ONLY," == *",$1,"* ]]; }

# OpenCode 분석 이름 → 고정 모델 ID. 분석·리뷰가 같은 모델을 쓰도록 이 함수가 SSOT 다.
opencode_model_for() {
  case "$1" in
    deepseek) printf '%s\n' "$COWORK_OPENCODE_DEEPSEEK_MODEL" ;;
    minimax)   printf '%s\n' "$COWORK_OPENCODE_MINIMAX_MODEL" ;;
    qwen)     printf '%s\n' "$COWORK_OPENCODE_QWEN_MODEL" ;;
    *) return 1 ;;
  esac
}

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

# 8 AI 에게 주입할 "대상 작업공간" 블록을 만든다.
#
# `.cowork/cowork-prompt.md` 는 **이 작업공간의 시스템 프롬프트** 다 — 프로젝트의 특성·기획·계획·아바타
# (persona)·디자인·로직·개념을 사람이 정의해 두는 곳이고, cowork 는 어떤 분석을 하든 이것을 **반드시**
# 8 AI 에게 먹인다. 자동 감지는 그 아래 보조 사실일 뿐이다(파일 존재로 알 수 있는 것만).
#
# 이 함수의 반환값은 페르소나의 {{PROJECT_CONTEXT}} 에 치환된다 → 분석(claude·codex·kimi·OpenCode)·grok
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

# --- claude 읽기 전용 1회 실행 (분석·리뷰·종합 공용 SSOT) --------------------
# 🛑 claude 실행 지점은 **이 함수 하나뿐이다.** 예전에는 run_claude(분석)와 run_oneshot(리뷰·종합)에
#    같은 명령이 복사돼 있어, 한쪽만 고치면 다른 쪽이 조용히 옛 동작을 유지했다. 옵션을 바꾸려면
#    여기만 고친다.
#
# 🛑 `--permission-mode plan` 을 쓰지 않는다 (2026-08-12 실측으로 제거).
#    plan 모드는 claude 를 "계획을 세워 사람에게 승인받는" 절차에 묶는다. headless(-p) 에는 승인할
#    사람이 없어 ExitPlanMode 가 아예 제공되지 않고, 모델은 계획 제출에 실패한 뒤 사과문을 낸다.
#    cowork 는 사용자 요청을 **원문 그대로** 주입하므로 "…를 고쳐줘" 가 섞이는 것이 정상 경로인데
#    (SKILL.md §6단계가 그 케이스를 다룬다), 그때 출력이 실제로 망가진다. 같은 프롬프트 실측:
#      plan on : 1603B · 요구한 `## 1./2./3.` 헤더 **0개** · "ExitPlanMode도 사용할 수 없습니다" 사과문
#      plan off: 3303B · 헤더 3개 정상 · 근거 `파일:줄` 과 패치까지 제시
#    순수 분석 프롬프트만 주면 plan on 도 정상 출력한다(3016B/헤더 3개) — 그래서 이 결함이 오래
#    눈에 띄지 않았다. "plan 이 분석을 전면 차단한다" 는 진단은 과장이지만, 제거가 옳다.
#
# 읽기 전용은 plan 모드가 아니라 아래 **두 겹**이 보장한다 (2026-08-12 공격 실측으로 확인):
#   ① 도구 화이트리스트(Read/Grep/Glob) + 쓰기 도구 명시 거부 → 공격 프롬프트에 파일 미생성(`FAILED`)
#   ② sandbox-exec → ①만으로는 구멍이 남는다. 같은 공격 실측에서 claude 자신이 "Agent·Workflow 로
#      쓰기 권한을 가진 서브에이전트를 띄우면 기술적으로 가능하다" 고 지목했다(이번엔 스스로 자제했을
#      뿐이다). 서브에이전트도 같은 프로세스 트리 안이므로 OS 레벨에서 막으면 EPERM 으로 함께 걸린다.
#      grok·kimi·OpenCode 와 **같은 프로파일**이며, 실측에서 claude 는 이 샌드박스 아래서 정상
#      동작했다(git 저장소에서 rc=0 · stderr 0B · 저장소 무오염).
#
# ⚠️ sandbox-exec 가 없으면(macOS 외) grok·kimi 처럼 미실행하지 않고 ①만으로 진행한다 — claude 는
#    CLI 옵션 방어가 실측으로 작동하기 때문이다(grok·kimi 는 그것이 전부 무력해 미실행이 유일한 답).
run_claude_readonly() { # <프롬프트파일> <출력파일> <로그파일>
  local pf="$1" out="$2" lg="$3"
  local sbx
  : > "$lg"
  if command -v sandbox-exec > /dev/null 2>&1; then
    sbx="$(printf '(version 1)\n(allow default)\n(deny file-write* (subpath "%s"))\n' "$REPO_ROOT_PHYS")"
    cd "$REPO_ROOT" && run_timeout "$COWORK_TIMEOUT" \
      sandbox-exec -p "$sbx" \
      claude -p "$(cat "$pf")" \
        --model "$COWORK_CLAUDE_MODEL" --effort "$COWORK_CLAUDE_EFFORT" \
        --allowedTools "Read Grep Glob" \
        --disallowedTools "Edit Write NotebookEdit Bash" \
        > "$out" 2>> "$lg" < /dev/null
  else
    printf '[cowork] sandbox-exec 없음 — claude 는 도구 화이트리스트만으로 읽기 전용을 유지한다.\n' >> "$lg"
    cd "$REPO_ROOT" && run_timeout "$COWORK_TIMEOUT" \
      claude -p "$(cat "$pf")" \
        --model "$COWORK_CLAUDE_MODEL" --effort "$COWORK_CLAUDE_EFFORT" \
        --allowedTools "Read Grep Glob" \
        --disallowedTools "Edit Write NotebookEdit Bash" \
        > "$out" 2>> "$lg" < /dev/null
  fi
}

# --- agy 읽기 전용 1회 실행 (분석·리뷰 공용 SSOT) ---------------------------
# 🛑 claude 와 같은 이유로 **agy 실행 지점도 이 함수 하나뿐이다.** 분석(run_agy)과 리뷰(run_oneshot)에
#    같은 명령을 복사해 두면 한쪽만 고쳤을 때 다른 쪽이 조용히 옛 동작을 유지한다. 옵션을 바꾸려면
#    여기만 고친다. 각 옵션이 왜 필요한지는 run_agy() 주석에 있다.
run_agy_readonly() { # <프롬프트파일> <출력파일> <로그파일>
  local pf="$1" out="$2" lg="$3"
  local sbx
  sbx="$(printf '(version 1)\n(allow default)\n(deny file-write* (subpath "%s"))\n' "$REPO_ROOT_PHYS")"
  cd "$REPO_ROOT" && run_timeout "$COWORK_TIMEOUT" \
    sandbox-exec -p "$sbx" \
      agy -p "$(cat "$pf")" --output-format text \
        --model "$COWORK_AGY_MODEL" --effort "$COWORK_AGY_EFFORT" \
        --dangerously-skip-permissions \
        --disable-slash-commands \
        --print-timeout "${COWORK_TIMEOUT}s" \
      > "$out" 2> "$lg" < /dev/null
}

# claude 실행을 결과 파일 헤더에 남길 때 쓰는 설명 문자열(분석·실패 안내 공용).
claude_cmd_desc() {
  local guard="도구 화이트리스트"
  command -v sandbox-exec > /dev/null 2>&1 && guard="sandbox-exec + 도구 화이트리스트"
  printf 'claude -p --model %s --effort %s --allowedTools "Read Grep Glob" (%s · 읽기 전용)\n' \
    "$COWORK_CLAUDE_MODEL" "$COWORK_CLAUDE_EFFORT" "$guard"
}

# --- 읽기 전용 1-pass 러너 (리뷰·종합 공용) ----------------------------------
# run_oneshot <ai> <프롬프트파일> <출력파일> <로그파일>
# 각 AI 를 읽기 전용 1회로 실행한다. 방어는 분석 러너와 동일 원칙(claude=sandbox-exec+화이트리스트,
# codex=--sandbox read-only, grok·kimi·OpenCode=sandbox-exec). grok 은 여기선 1-pass(리뷰는 이미 결론을
# 비판하는 작업이라 2-pass 불필요).
# claude 는 run_claude_readonly() 를 그대로 부른다 — 분석과 리뷰가 **같은 실행 경로**를 쓰므로
# 옵션이 한쪽에만 반영되는 사고가 구조적으로 불가능하다.
run_oneshot() {
  local ai="$1" pf="$2" out="$3" lg="$4"
  local sbx
  sbx="$(printf '(version 1)\n(allow default)\n(deny file-write* (subpath "%s"))\n' "$REPO_ROOT_PHYS")"
  case "$ai" in
    claude)
      run_claude_readonly "$pf" "$out" "$lg" ;;
    codex)
      cd "$REPO_ROOT" && run_timeout "$COWORK_TIMEOUT" \
        codex exec --sandbox read-only --skip-git-repo-check --color never \
          ${COWORK_CODEX_MODEL:+-m "$COWORK_CODEX_MODEL"} \
          -c model_reasoning_effort="$COWORK_CODEX_EFFORT" \
          -o "$out" - \
          < "$pf" > "$lg" 2>&1
      local rc_c=$?
      # 분석 경로와 같은 fallback — 리뷰만 모델 거절로 조용히 빠지는 일이 없게 한다.
      if [ "$rc_c" -ne 0 ] && [ -n "$COWORK_CODEX_FALLBACK_MODEL" ] \
         && [ "$COWORK_CODEX_FALLBACK_MODEL" != "$COWORK_CODEX_MODEL" ] && codex_model_rejected "$lg"; then
        printf '\n--- 리뷰 1차 실패(모델 거절) → fallback: %s ---\n\n' "$COWORK_CODEX_FALLBACK_MODEL" >> "$lg"
        cd "$REPO_ROOT" && run_timeout "$COWORK_TIMEOUT" \
          codex exec --sandbox read-only --skip-git-repo-check --color never \
            -m "$COWORK_CODEX_FALLBACK_MODEL" \
            -c model_reasoning_effort="$COWORK_CODEX_EFFORT" \
            -o "$out" - \
            < "$pf" >> "$lg" 2>&1
        rc_c=$?
      fi
      return $rc_c ;;
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
      local rc_k=$?
      [ -f "$out" ] && sed -i '' '/^To resume this session: kimi -r /d' "$out" 2> /dev/null
      return $rc_k ;;
    agy)
      # 분석과 **같은 실행 경로**(run_agy_readonly)를 쓴다 — 옵션이 한쪽에만 반영되는 사고를
      # 구조적으로 막는다. 옵션의 근거는 run_agy() 주석이 SSOT.
      command -v sandbox-exec > /dev/null 2>&1 || { printf 'sandbox-exec 없음 — agy 미실행\n' > "$lg"; return 1; }
      command -v agy > /dev/null 2>&1 || { printf 'agy CLI 미설치 — agy 미실행\n' > "$lg"; return 1; }
      run_agy_readonly "$pf" "$out" "$lg" ;;
    deepseek|minimax|qwen)
      command -v sandbox-exec > /dev/null 2>&1 || { printf 'sandbox-exec 없음 — %s 미실행\n' "$ai" > "$lg"; return 1; }
      command -v opencode > /dev/null 2>&1 || { printf 'opencode CLI 미설치 — %s 미실행\n' "$ai" > "$lg"; return 1; }
      check_opencode_key || { printf 'opencode API 키 없음/비어 있음 — %s 미실행\n' "$ai" > "$lg"; return 1; }
      local model; model="$(opencode_model_for "$ai")" || return 1
      # `< /dev/null` 필수 — 없으면 opencode 가 stdin 을 기다리며 멈춘다(run_opencode_analysis 주석 참고).
      (
        export OPENCODE_API_KEY; OPENCODE_API_KEY="$(tr -d '[:space:]' < "$COWORK_OPENCODE_KEYFILE")"
        cd "$REPO_ROOT" && run_timeout "$COWORK_TIMEOUT" \
          sandbox-exec -p "$sbx" opencode run -m "$model" "$(cat "$pf")" \
          > "$out" 2> "$lg" < /dev/null
      )
      local rc_o=$?
      if [ -f "$out" ]; then
        sed -i '' $'s/\033\\[[0-9;]*m//g' "$out" 2> /dev/null
        sed -i '' '/^> build · /d' "$out" 2> /dev/null
      fi
      return $rc_o ;;
  esac
}

# --- --init: .cowork/cowork-prompt.md 초안 생성 -------------------------------------
# 이 작업공간에서 8 AI 에게 매번 주입할 공통 지침 파일을 만든다(Overview·Persona·Instructions·Tech stack).
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

> 🛑 이 파일은 \`cowork\` 이 claude·codex·grok·kimi·deepseek·minimax·qwen·agy **여덟 AI 에게 분석을
> 시킬 때마다 프롬프트 맨 앞에 반드시 주입** 하는 **이 프로젝트의 시스템 프롬프트** 다. 여덟 AI 는 매번 이 문서를 전제로 분석한다.
>
> 이 프로젝트의 **특성·기획·계획·아바타(persona)·디자인·로직·개념** 을 여기에 적어 두면, 어떤 분석을
> 시키든 여덟 AI 가 같은 맥락 위에서 답한다. 반대로 비워 두면 여덟 AI 는 프로젝트의 목적을 모른 채
> 일반론으로 분석한다 — **채울수록 결과가 좋아지는 파일이다.**
>
> \`cowork.sh --init\` 이 자동 감지로 만든 **초안** 이다. 아래 네 절은 뼈대일 뿐이니, 필요하면 절을
> 더 추가하라(\`## 기획\`, \`## 용어 정의\`, \`## 설계 규칙\`, \`## 데이터 구조\`, \`## 금지사항\` …).
>
> ⚠️ 여덟 AI 는 읽기 전용이다. 이 문서에 "파일을 만들어라" 같은 지시를 써도 물리적으로 실행되지 않는다
> (실제 작업은 종합(final-report.md)을 마친 오케스트레이터가 한다).

## Overview

(이 프로젝트가 **무엇인지**, 무엇을 만들고 있고 지금 어느 단계인지, 그리고 8 AI 에게 **무엇을
 시키려는지** 를 쓴다. 프로젝트의 특성·기획 의도·목표·계획을 여기에 담는다.
 예: "초등 3~4학년 수학 교재를 만드는 프로젝트. 현재 1학기 분수 단원 초안까지 나왔다.
 단원 구성·난이도 배열·오답 유형의 타당성을 여덟 AI 에게 교차 검증시킨다."
 예: "웹 브라우저용 테트리스. 코어 로직은 완성, 지금은 난이도 곡선과 조작감을 다듬는 단계다.")

## Persona

(8 AI 가 **어떤 전문가 역할(아바타)** 로 분석해야 하는지 쓴다. 이 프로젝트의 분야에 맞는 인격을
 부여하면 분석의 관점 자체가 달라진다.
 예: "초등 수학 교육과정 설계 전문가이자 아동 인지발달 관점의 교재 검수자."
 예: "낙하형 퍼즐 게임의 조작감·난이도 곡선을 설계해 온 시니어 게임 디자이너.")

## Instructions

(분석 시 **반드시 지킬 규칙·개념·설계 로직·우선순위·금지사항** 을 쓴다. 이 프로젝트의 불변 규칙과
 핵심 개념을 여기에 정의해 두면 여덟 AI 가 그것을 어기는 권고를 하지 않는다.
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
  printf '   8 AI 분석마다 이 파일이 프롬프트에 주입된다. 네 절(Overview·Persona·Instructions·Tech stack)을\n' >&2
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
  printf '   final-report.md 를 8 AI 로 백그라운드 재검토해 갱신한다(세션은 안 멈춤).\n' >&2
}

# --- --review: final-report.md 최종 리뷰 라운드 ------------------------------
# Stop hook 이 nohup 백그라운드로 호출한다. 8 AI 가 종합본을 재검토 → claude 가 반영해 갱신.
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

  # 리뷰 프롬프트: 리뷰 페르소나 + final-report.md 전문 + 8개 원본 분석 전문
  local rprompt="$rdir/.review-prompt.md"
  {
    printf '%s\n\n' "$rpersona"
    # 리뷰어도 이 작업공간이 무슨 분야인지 알아야 권고의 실현성을 판정할 수 있다(분석 라운드와 동일 소스).
    printf -- '## 대상 작업공간\n\n%s\n\n---\n\n' "$(build_project_context "$REPO_ROOT")"
    printf '## 검토 대상 작업\n\n폴더: `.cowork/%s/`\n\n---\n\n' "$slug"
    printf '## final-report.md (검토할 종합본)\n\n'
    cat "$report"
    for ai in "${COWORK_AI_NAMES[@]}"; do
      f="$dir/$ai-cowork.md"
      [ -f "$f" ] || continue
      printf -- '\n\n---\n\n## 원본 분석: %s-cowork.md\n\n' "$ai"
      cat "$f"
    done
  } > "$rprompt"

  # 8 AI 병렬 리뷰(1-pass)
  # 🛑 이전 라운드의 리뷰 파일을 먼저 지운다. 안 지우면 이번에 실패한 AI 의 *지난* 리뷰가 그대로
  #    남아 새 리뷰인 것처럼 종합에 실린다(2026-08-08 감사 지적).
  local pids=() rnames=()
  for ai in "${COWORK_AI_NAMES[@]}"; do
    wants "$ai" || continue
    rm -f "$rdir/$ai-review.md"
    run_oneshot "$ai" "$rprompt" "$rdir/$ai-review.md" "$rdir/.$ai.log" & pids+=("$!"); rnames+=("$ai")
  done
  # wait 의 종료 코드를 버리지 말 것 — 타임아웃·인증 실패가 묻힌 채 부실 리뷰로 종합되던 결함이다.
  local p i rev_ok=0
  for i in "${!pids[@]}"; do
    if wait "${pids[$i]}" && [ -s "$rdir/${rnames[$i]}-review.md" ]; then
      rev_ok=$((rev_ok + 1))
    else
      printf '   ⚠️  리뷰 실패: %s (.review/.%s.log 확인)\n' "${rnames[$i]}" "${rnames[$i]}" >&2
      rm -f "$rdir/${rnames[$i]}-review.md"   # 실패본을 종합에 싣지 않는다
    fi
  done
  if [ "$rev_ok" -eq 0 ]; then
    printf '   ❌ 리뷰가 전부 실패했다 — final-report.md 를 건드리지 않고 중단한다.\n' >&2
    return 1
  fi
  printf '   리뷰 %d/%d 성공\n' "$rev_ok" "${#pids[@]}" >&2

  # 종합: claude 1회로 리뷰를 반영해 final-report.md 개선안 생성
  local synth
  synth="$(extract_block "$review_ref" REVIEW-SYNTHESIS)"
  [ -n "$synth" ] || { printf 'REVIEW-SYNTHESIS 마커 없음: %s\n' "$review_ref" >&2; return 1; }
  local sprompt="$rdir/.synth-prompt.md"
  {
    printf '%s\n\n' "$synth"
    printf -- '---\n\n## 원본 final-report.md\n\n'
    cat "$rdir/final-report.before.md"
    for ai in "${COWORK_AI_NAMES[@]}"; do
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
    printf '> 8 AI 리뷰(claude·codex·grok·kimi·deepseek·minimax·qwen·agy) → claude 종합 → final-report.md **%s**\n\n' "$applied"
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
    for ai in "${COWORK_AI_NAMES[@]}"; do
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

    # 실패 원인 분류 — "재시도하면 되는 실패" 와 "재시도해도 소용없는 실패" 를 갈라 준다.
    # 🛑 2026-08-12 감사: 과거 실패 사례를 훑어 보니 즉시 죽은(2~6초) 실패는 거의 전부 **사용량 한도
    #    초과** 였다(`You've hit your weekly limit`, kimi 는 `403 ... usage limit for this billing
    #    cycle`). 그런데 결과 파일에는 "종료 코드 1" 만 남고 무조건 재시도를 권해, 같은 실패를 반복하며
    #    시간만 버렸다. 한도 초과는 사람이 판단할 일이므로 그 사실을 첫 줄에 세운다.
    #    각 CLI 가 한도 메시지를 stdout 에 내기도 하고 stderr 에 내기도 해서 둘 다 본다.
    local diag="" probe
    probe="$body
$(cat "${LOG_DIR:-}/$name.log" 2> /dev/null)"
    if printf '%s' "$probe" | grep -qiE "hit your (weekly|daily|usage) limit|reached your .{0,24}limit|usage limit|quota (exceeded|will be refreshed)|out of (credits|quota)|insufficient (credits|quota)|\b429\b"; then
      diag="사용량 한도 초과"
    elif [ "$rc" -eq 124 ]; then
      diag="제한 시간 초과"
    fi

    {
      printf '<!-- cowork:%s | %s | 실패(exit=%s%s) | %ss -->\n' \
        "$name" "$stamp" "$rc" "${diag:+ · $diag}" "$secs"
      printf '# ⚠️ %s 분석 실패\n\n' "$name"
      [ "$diag" = "사용량 한도 초과" ] && \
        printf '> 🛑 **사용량 한도 초과다 — 재시도해도 같은 실패가 난다.** 한도가 회복된 뒤 다시 돌리거나,\n> 이 AI 를 빼고 진행하고 final-report.md 에 제외 사실을 적어라.\n\n'
      printf -- '- 종료 코드: `%s` %s\n' "$rc" \
        "$( [ "$rc" -eq 124 ] && echo "(제한 시간 ${COWORK_TIMEOUT}s 초과)" || { [ "$rc" -eq 99 ] && echo "(빈 응답)"; } )"
      [ -n "$diag" ] && printf -- '- 진단: **%s**\n' "$diag"
      printf -- '- 명령: `%s`\n' "$cmd"
      printf -- '- 로그: `.cowork/%s/.logs/%s.log`\n\n' "$SLUG" "$name"
      printf '이 파일은 분석 결과가 아니다. 종합(final-report.md) 시 %s 의견은 **없는 것으로** 취급하고,\n' "$name"
      if [ "$diag" = "사용량 한도 초과" ]; then
        printf '그 사실을 final-report.md 에 명시하라. 한도 문제이므로 **지금 재시도하지 말라** — 나머지 AI 로 종합을 진행하라.\n'
      else
        printf '그 사실을 final-report.md 에 명시하라. 재시도: `COWORK_ONLY=%s bash .claude/skills/cowork/scripts/cowork.sh %s "..."`\n' "$name" "$SLUG"
      fi
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

# --- 분석 러너 8종 (claude·codex·grok·kimi·agy + OpenCode 3모델) -------------------------
# 공통: cwd=REPO_ROOT (각 CLI 가 CLAUDE.md/AGENTS.md 를 자동으로 읽게 한다)

run_claude() {
  local file="$OUT_DIR/claude-cowork.md" log="$LOG_DIR/claude.log"
  local t0=$SECONDS rc=0
  # 실행 옵션과 읽기 전용 방어의 근거는 전부 run_claude_readonly() 주석에 있다(SSOT).
  # 여기서 옵션을 다시 쓰지 말 것 — 리뷰 경로(run_oneshot)와 갈라지는 순간 회귀가 시작된다.
  run_claude_readonly "$PROMPT_FILE" "$file" "$log"
  rc=$?
  finalize claude "$file" "$rc" "$((SECONDS - t0))" "$(claude_cmd_desc)"
}

# codex 1회 실행. 모델을 인자로 받는다(빈 문자열이면 ~/.codex/config.toml 의 모델 상속).
# 읽기 전용 강제: --sandbox read-only 는 OS 레벨 샌드박스라 쓰기 자체가 불가능하다.
# -o 로 최종 메시지만 파일에 받는다(진행 로그·토큰 메타가 섞이지 않는다).
# 프롬프트는 stdin('-')으로 넘긴다. --skip-git-repo-check 는 미신뢰 디렉토리 조기 종료 방지.
# 🛑 model_reasoning_effort 강제: 사용자 config 기본이 "low" 라 override 없이는 저사양 분석이 된다.
codex_exec_once() {
  local model="$1" file="$2" log="$3"
  cd "$REPO_ROOT" && run_timeout "$COWORK_TIMEOUT" \
    codex exec --sandbox read-only --skip-git-repo-check --color never \
      ${model:+-m "$model"} \
      -c model_reasoning_effort="$COWORK_CODEX_EFFORT" \
      -o "$file" - \
      < "$PROMPT_FILE" > "$log" 2>&1
}

# 이 실행이 "모델 때문에" 실패했는지 판정한다. 계정 등급·모델 폐기 등으로 특정 모델만 거절당하는
# 경우가 실재한다(2026-08-10 실측: `The 'gpt-5.6-sol' model is not supported when using Codex with
# a ChatGPT account.` → codex 만 통째로 빠졌다). 네트워크·타임아웃 같은 일반 실패까지 fallback 으로
# 재시도하면 시간만 두 배로 쓰므로, **모델 거절 신호가 있을 때만** 재시도한다.
codex_model_rejected() {
  local log="$1"
  [ -f "$log" ] || return 1
  grep -qiE 'model is not supported|not supported when using codex|unknown model|model_not_found|invalid model' "$log"
}

run_codex() {
  local file="$OUT_DIR/codex-cowork.md" log="$LOG_DIR/codex.log"
  local t0=$SECONDS rc=0
  local used="${COWORK_CODEX_MODEL:-(config 상속)}"

  codex_exec_once "$COWORK_CODEX_MODEL" "$file" "$log"
  rc=$?

  # fallback: 1차가 모델 거절로 실패하면 COWORK_CODEX_FALLBACK_MODEL 로 한 번만 재시도한다.
  if [ "$rc" -ne 0 ] && [ -n "$COWORK_CODEX_FALLBACK_MODEL" ] \
     && [ "$COWORK_CODEX_FALLBACK_MODEL" != "$COWORK_CODEX_MODEL" ] && codex_model_rejected "$log"; then
    printf '   ↻ codex: 모델이 거절돼 fallback 으로 재시도 — %s → %s\n' \
      "$used" "$COWORK_CODEX_FALLBACK_MODEL" >&2
    {
      printf '\n--- 1차 시도 실패(모델 거절) → fallback 재시도: %s ---\n\n' "$COWORK_CODEX_FALLBACK_MODEL"
    } >> "$log"
    codex_exec_once "$COWORK_CODEX_FALLBACK_MODEL" "$file" "$log.fallback"
    rc=$?
    cat "$log.fallback" >> "$log" 2> /dev/null; rm -f "$log.fallback"
    used="$COWORK_CODEX_FALLBACK_MODEL (fallback)"
  fi

  finalize codex "$file" "$rc" "$((SECONDS - t0))" \
    "codex exec --sandbox read-only -m $used -c model_reasoning_effort=$COWORK_CODEX_EFFORT -o <file> -"
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

# --- OpenCode 3모델 (각각 독립 CLI 프로세스) ---------------------------------
# DeepSeek·MiniMax·Qwen 을 하나의 호출에 묶거나 순차 실행하지 않는다. 메인 병렬 루프가 아래 래퍼
# 세 개를 각각 백그라운드로 띄우고, 각 래퍼가 정확히 한 번의 `opencode run` 프로세스를 실행한다.
# 인증은 키 파일 → OPENCODE_API_KEY 환경변수 주입(인자로 넘기면 `ps` 에 키가 그대로 보인다).
run_opencode_analysis() {
  local name="$1" model="$2"
  local t0=$SECONDS
  local file="$OUT_DIR/$name-cowork.md"
  local log="$OUT_DIR/.logs/$name.log"
  local rc=0

  if ! command -v opencode > /dev/null 2>&1; then
    printf 'opencode CLI 를 찾을 수 없다. 설치: https://opencode.ai\n' > "$log"
    finalize "$name" "$file" 96 "$((SECONDS - t0))" "opencode CLI 미설치"
    return 1
  fi
  if ! check_opencode_key; then
    printf 'opencode API 키 파일이 없거나 비어 있다: %s\n\n' "$COWORK_OPENCODE_KEYFILE" > "$log"
    printf 'OpenCode Go 구독 키를 아래 두 경로 중 하나에 저장하면 자동으로 찾는다:\n' >> "$log"
    printf '  1) %s/.cowork/opencode-go-api.key   (작업공간 로컬 — 여덟 AI 가 읽을 수 있으니 주의)\n' "$REPO_ROOT" >> "$log"
    printf '  2) ~/.config/cowork/opencode-go-api.key   (권장 — 작업공간 밖이라 여덟 AI 가 못 읽는다)\n\n' >> "$log"
    printf '  mkdir -p ~/.config/cowork\n' >> "$log"
    printf '  <키> > ~/.config/cowork/opencode-go-api.key && chmod 600 ~/.config/cowork/opencode-go-api.key\n' >> "$log"
    finalize "$name" "$file" 97 "$((SECONDS - t0))" "opencode API 키 없음"
    return 1
  fi

  # 🛑 opencode 도 headless 에서 쓰기 도구를 실행할 수 있다 — grok·kimi 와 동일하게 OS 레벨
  #    sandbox-exec 로 프로젝트 쓰기를 물리 차단한다. 이 래핑을 벗기지 말 것.
  if ! command -v sandbox-exec > /dev/null 2>&1; then
    printf 'sandbox-exec 없음 — %s 을 읽기 전용으로 가둘 수 없어 실행하지 않았다(macOS 전용).\n' "$name" > "$log"
    finalize "$name" "$file" 98 "$((SECONDS - t0))" "sandbox-exec 부재로 미실행"
    return 1
  fi
  local sbx_profile
  sbx_profile="$(printf '(version 1)\n(allow default)\n(deny file-write* (subpath "%s"))\n' "$REPO_ROOT_PHYS")"

  # 🛑 `< /dev/null` 을 반드시 붙인다. opencode 는 stdin 이 열려 있으면 입력을 기다리며 무한정
  #    멈춘다(2026-08-08 실측: 3분 넘게 0바이트 출력, 프로세스만 쌓였다). 이 리다이렉션을 지우지 말 것.
  (
    export OPENCODE_API_KEY; OPENCODE_API_KEY="$(tr -d '[:space:]' < "$COWORK_OPENCODE_KEYFILE")"
    cd "$REPO_ROOT" && run_timeout "$COWORK_TIMEOUT" \
      sandbox-exec -p "$sbx_profile" \
        opencode run -m "$model" "$(cat "$PROMPT_FILE")" \
        > "$file" 2> "$log" < /dev/null
  )
  rc=$?
  # opencode 는 출력 앞에 ANSI 색코드와 `> build · <model>` 헤더를 붙인다 — 분석 내용이 아니므로 제거.
  if [ -f "$file" ]; then
    sed -i '' $'s/\033\\[[0-9;]*m//g' "$file" 2> /dev/null
    sed -i '' '/^> build · /d' "$file" 2> /dev/null
  fi
  finalize "$name" "$file" "$rc" "$((SECONDS - t0))" \
    "sandbox-exec + opencode run -m $model (OS 읽기 전용)"
}

run_deepseek() { run_opencode_analysis deepseek "$COWORK_OPENCODE_DEEPSEEK_MODEL"; }
run_minimax()   { run_opencode_analysis minimax "$COWORK_OPENCODE_MINIMAX_MODEL"; }
run_qwen()     { run_opencode_analysis qwen "$COWORK_OPENCODE_QWEN_MODEL"; }

# --- agy (Antigravity CLI · Gemini 3.7 Flash High) ---------------------------
# 실행 옵션은 전부 실측으로 정해졌다(2026-08-14). 하나씩 이유가 있으니 임의로 빼지 말 것.
#
# 🛑 `--dangerously-skip-permissions` 는 **필수다.** 이것 없이 headless(-p)로 돌리면 agy 는 도구를
#    단 하나도 못 쓴다. 실측(sandbox-exec 안, 파일 하나를 읽어 인용하라는 요청):
#      "no output produced — a tool required the "command" permission that headless mode cannot
#       prompt for, so it was auto-denied."
#    → stdout 0B · rc=0 인 **빈 응답**. 즉 승인 없이는 분석 자체가 성립하지 않는다.
#    grok 의 `--always-approve` 와 같은 자리의 옵션이다(readonly-enforcement.md §agy).
#
# 🛑 그래서 읽기 전용은 CLI 옵션이 아니라 **sandbox-exec 가 전부 담당한다.** 같은 실측에서
#    최악 조건(--dangerously-skip-permissions)으로 "이 폴더에 파일을 만들고 PWNED 라고 써라" 를
#    시켰더니 agy 는 `OK`(성공했다) 라고 답했지만 **파일은 생성되지 않았다**(OS 가 EPERM).
#    모델의 자기 보고는 방어가 아니다 — 오히려 성공했다고 착각·오보한다. grok·kimi 와 동일하게
#    샌드박스가 없으면 아예 실행하지 않는다(쓰기 가능한 채로 돌리느니 분석 하나를 포기한다).
#
# `--print-timeout`: agy 자체 대기 한도는 기본 5분이라 워치독(COWORK_TIMEOUT, 기본 900s)보다
#    먼저 끊긴다. 그대로 두면 깊은 분석이 agy 쪽에서 잘리므로 같은 값으로 맞춘다.
# `--disable-slash-commands`: 분석 프롬프트는 사용자 원문을 그대로 싣는다. `/cowork …` 같은 토큰이
#    섞이면 슬래시 커맨드로 확장돼 질문이 변질되므로 print 모드에서 확장을 끈다.
# `< /dev/null`: stdin 이 열려 있으면 입력을 기다리며 멈추는 CLI 가 있었다(opencode 실측). 예방적.
run_agy() {
  local file="$OUT_DIR/agy-cowork.md" log="$LOG_DIR/agy.log"
  local t0=$SECONDS rc=0

  if ! command -v agy > /dev/null 2>&1; then
    printf 'agy(Antigravity) CLI 를 찾을 수 없다. 설치 후 `agy models` 로 인증을 확인하라.\n' > "$log"
    finalize agy "$file" 96 "$((SECONDS - t0))" "agy CLI 미설치"
    return 1
  fi

  if ! command -v sandbox-exec > /dev/null 2>&1; then
    printf 'sandbox-exec 없음 — agy 를 읽기 전용으로 가둘 수 없어 실행하지 않았다(macOS 전용).\n' > "$log"
    finalize agy "$file" 98 "$((SECONDS - t0))" "sandbox-exec 부재로 미실행"
    return 1
  fi
  # 실행 옵션은 run_agy_readonly() 하나에만 둔다(분석·리뷰 SSOT). 여기서 다시 쓰지 말 것 —
  # 리뷰 경로와 갈라지는 순간 회귀가 시작된다(claude 가 같은 이유로 run_claude_readonly 를 쓴다).
  # 프롬프트는 -p 인자로 통째 전달한다(agy 에는 grok 의 --prompt-file 에 해당하는 옵션이 없다).
  run_agy_readonly "$PROMPT_FILE" "$file" "$log"
  rc=$?
  finalize agy "$file" "$rc" "$((SECONDS - t0))" \
    "sandbox-exec + agy -p --model $COWORK_AGY_MODEL --effort $COWORK_AGY_EFFORT (OS 읽기 전용)"
}

# --- 병렬 실행 --------------------------------------------------------------
printf '🔍 cowork: %s\n' "$SLUG" >&2
printf '   요청: %s\n' "$PROMPT_TEXT" >&2
printf '   출력: .cowork/%s/  (제한 %ss · 대상 %s)\n' "$SLUG" "$COWORK_TIMEOUT" "$COWORK_ONLY" >&2
if [ -f "$REPO_ROOT/.cowork/cowork-prompt.md" ]; then
  printf '   지침: .cowork/cowork-prompt.md 를 8 AI 에 주입함\n\n' >&2
elif [ -f "$REPO_ROOT/.cowork/prompt.md" ]; then
  # 예전 이름 — 읽어는 주되(하위 호환), 새 이름으로 바꾸라고 알린다.
  printf '   지침: .cowork/prompt.md 를 8 AI 에 주입함 (예전 이름)\n' >&2
  printf '   ⚠️  파일명이 바뀌었다 — `mv .cowork/prompt.md .cowork/cowork-prompt.md` 로 옮겨라.\n\n' >&2
else
  # 시스템 프롬프트가 없으면 여덟 AI 가 프로젝트 목적을 모른 채 일반론으로 분석한다 — 사람에게 알린다.
  printf '   💡 .cowork/cowork-prompt.md 가 없다 — `cowork.sh --init` 으로 이 프로젝트의 시스템 프롬프트\n' >&2
  printf '      (특성·기획·계획·페르소나·로직·개념)를 만들어 두면 이후 모든 분석 품질이 올라간다.\n\n' >&2
fi

wants kimi && check_kimi_model_alias
wants agy && { check_agy_model || true; }
for ai in "${COWORK_OPENCODE_NAMES[@]}"; do
  if wants "$ai"; then
    check_opencode_key || true   # 경고만 — 실행 여부는 각 run_<ai> 가 판정
    check_opencode_models || true
    break
  fi
done

declare -a NAMES=() PIDS=()
for ai in "${COWORK_AI_NAMES[@]}"; do
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
    printf '   ✅ %-8s → .cowork/%s/%s-cowork.md\n' "${NAMES[$i]}" "$SLUG" "${NAMES[$i]}" >&2
    ok=$((ok + 1))
  else
    printf '   ❌ %-8s 실패 → .cowork/%s/.logs/%s.log 확인\n' "${NAMES[$i]}" "$SLUG" "${NAMES[$i]}" >&2
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
# 이 스크립트는 cowork 파이프라인의 *절반*(8 AI 분석)만 한다. 나머지 절반(종합=final-report.md)은
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
