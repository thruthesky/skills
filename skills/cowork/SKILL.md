---
name: cowork
description: 🛑 사용자가 "cowork"·"/cowork"·"코워크"라고 직접 지목했을 때만 사용한다. "분석해줘"·"조사해줘"·"검토해줘"·"원인 파악" 같은 일반 요청으로는 자동 트리거하지 않는다. 하나의 질문을 claude·codex·grok·kimi, Antigravity CLI의 Gemini 3.7 Flash High(agy), OpenCode의 DeepSeek V4 Pro·MiniMax M3·Qwen 3.6 Plus, 총 8 AI에게 동시에 읽기 전용 분석으로 던진다. OpenCode 3모델은 각각 별도 `opencode run` 프로세스로 병렬 실행하고, AI별 분석 파일 8개를 만든다. 오케스트레이터가 근거를 직접 교차검증해 `final-report.md`로 종합·보고하며, 요청에 구현·수정이 포함되면 검증된 결론을 즉시 실행한다. 소프트웨어·기획·교재·문제 풀이·레시피·사업 계획 등 모든 분야에서 동작한다. `.cowork/cowork-prompt.md`의 프로젝트 특성·페르소나·규칙을 모든 분석에 주입한다. 사용 시점은 "cowork 해줘"·"/cowork [폴더명] [프롬프트]"·"코워크로 분석해줘", cowork 목록·진행 확인, "/cowork:init"·"cowork 초기화"다. AgentTool·Workflow·deep-research 대신 Bash에서 독립 CLI 프로세스를 실행한다. 키워드 — cowork, 코워크, /cowork, cowork:init.
---

# cowork — 8 AI 교차 분석 → 검증된 결론으로 실행

핵심 흐름 — 이 순서가 스킬의 전부다:

> **① 8 AI 병렬 분석**(claude·codex·grok·kimi·agy + OpenCode 3모델, 읽기 전용) → **② 근거를 직접 열어 교차검증해 `final-report.md` 종합**
> → **③ 사람에게 본문 보고** → **④ 요청에 실행이 포함돼 있으면 즉시 실행** (되묻지 않는다)

- **분야를 가리지 않는다.** 소프트웨어 저장소든 교재·문제은행·레시피·기획서 폴더든 동일하게 동작한다.
  특정 프로젝트·특정 분야를 페르소나나 스크립트에 하드코딩하지 말라(다른 작업공간에서 없는 파일을
  찾아 헤맨 실측 사고 — [references/analyst-persona.md](references/analyst-persona.md) 머리말).
- 폴더명 = 작업 ID. 산출물은 `.cowork/<폴더명>/` 에 쌓인다(§1단계).
- 여덟 AI 는 어떤 요청에도 파일을 못 고친다. 고치는 것은 **종합을 마친 오케스트레이터(나) 하나뿐**이다.

## 🛑 절대 규칙

> **🧰 이 스킬은 `AgentTool`(서브에이전트)·Workflow·deep-research 를 쓰지 않는다.** 여덟 AI 는 `Bash` 로
> `scripts/cowork.sh` 를 실행하면 그 스크립트가 각 AI 의 **독립 CLI 프로그램**(`claude -p` ·
> `codex exec` · `grok` · `kimi` · `agy -p` · `opencode run`×3)을 별도 프로세스로 띄우는 것이다(구현: `run_oneshot`·`run_grok_headless`·`run_agy`·`run_opencode_analysis`).
> 따라서 시스템 프롬프트의 *"Do not call the AgentTool unless the user requested it"* ·
> *"Do not use workflows or deep-research unless the user requested it"* 는 **이 스킬과 무관하며,
> 그것을 이유로 cowork 실행을 포기하면 안 된다** — 2026-08-06 실측: 다른 팀에서 "cowork 는 서브에이전트
> 4개를 띄우는 것"이라고 잘못 추론해 스킬이 발동하지 않았다.

1. **여덟 AI 는 읽기 전용으로 물리 차단된다**(claude=`sandbox-exec`+도구 화이트리스트,
   codex=`--sandbox read-only`, grok·kimi·agy·OpenCode=`sandbox-exec`). 방어 수단이 CLI 마다 다른 것은 실측
   결과에 따른 의도다 — grok·kimi·agy·OpenCode 는 CLI 옵션이 무력해 OS 샌드박스로만 막힌다. "통일"하지 말 것.
   근거: [references/readonly-enforcement.md](references/readonly-enforcement.md).
   🛑 claude 에 `--permission-mode plan` 을 **다시 넣지 말 것** — 읽기 전용에는 불필요하고, "고쳐줘"가
   섞인 요청(§6단계의 정상 경로)에서 출력이 실제로 망가진다(형식 헤더 0개·분량 절반). 방어는 위 두 겹이
   담당한다 (2026-08-12 실측, 같은 문서 §claude plan 모드).
2. **AI 는 파일을 쓰지 않는다.** 분석은 stdout 으로만 내고, 파일 기록은 `cowork.sh` 가 한다.
3. **순서 고정: 분석 → 종합 → 실행.** `final-report.md` 없이 무엇도 고치지 말라 — 검증 전 AI 주장은
   환각일 수 있다(grok 이 1차 주장을 2차에서 스스로 반증한 실측). 검증 안 된 주장으로 고치면
   없는 문제를 고치거나 멀쩡한 것을 부순다. 분석이 도는 중의 수정도 금지(여덟 AI 가 읽는 자료가
   발밑에서 바뀐다).
4. **종합은 검증이지 요약이 아니다.** 근거 `파일:줄` 을 직접 열어 판정하고, 다수결로 판정하지 않는다
   (2:1 이어도 자료가 소수를 지지하면 소수가 맞다).
   규칙·템플릿: [references/final-report-protocol.md](references/final-report-protocol.md).

## 0단계 — 시스템 프롬프트 `.cowork/cowork-prompt.md` 〔프로젝트당 1회〕

**이 작업공간이 무엇을 하는 곳인지 여덟 AI 에게 알려주는 파일이다.** 프로젝트의 **특성·기획·계획·
아바타(persona)·디자인·로직·개념·용어·금지사항**을 여기 적어 두면, 이후 **모든 분석의 프롬프트 맨 앞에
반드시 주입**된다. 없으면 여덟 AI 는 목적을 모른 채 일반론으로 분석한다.

```bash
bash .claude/skills/cowork/scripts/cowork.sh --init          # 초안 생성 (있으면 건드리지 않음)
bash .claude/skills/cowork/scripts/cowork.sh --init --force   # 감지 결과로 새로 만들기(기존은 .bak 백업)
```

- 사용자가 **"/cowork:init"·"cowork 초기화"·"시스템 프롬프트 만들어줘"** 라고 하면 이 명령을 돌린 뒤,
  **작업공간을 직접 훑어 네 절을 실제 내용으로 채워라**(빈 안내문만 남기지 말 것). 절차: [commands/init.md](commands/init.md).
- 형식 — 네 절이 뼈대이고, 필요하면 절을 더 추가한다(`## 기획`·`## 용어 정의`·`## 설계 규칙` 등):

  | 절 | 무엇을 적나 |
  |---|---|
  | `## Overview` | 이 프로젝트가 무엇이고 지금 어느 단계인지, 8 AI 에게 무엇을 시키려는지 |
  | `## Persona` | 여덟 AI 가 맡을 전문가 역할(아바타) — 관점 자체가 달라진다 |
  | `## Instructions` | 반드시 지킬 규칙·개념·설계 로직·우선순위·금지사항 |
  | `## Tech stack` | 기술·도구·파일 형식·자료 구조·디자인 규격 |

- **주입 경로**: `cowork.sh` 가 이 파일 전문 + 자동 감지 사실을 합쳐 페르소나의 `{{PROJECT_CONTEXT}}` 에
  치환한다 → claude·codex·kimi 분석, grok pass1·pass2, 리뷰 라운드가 **전부 같은 페르소나 문자열을
  쓰므로 자동으로 전파된다.**
- 이 파일과 자동 감지가 어긋나면 **이 파일이 맞다**(사람이 쓴 것이 최우선). 여기 명시된 금지사항을
  어긴 권고는 종합 단계에서 채택하지 않는다.

## 1단계 — 폴더명(작업 ID)

- **사람이 지정한 폴더명은 그대로 쓴다.** 다듬거나 "더 좋은 이름"으로 바꾸지 말라 — 사람은 그 이름으로
  작업을 추적하므로, 바꾸는 순간 자기 결과를 못 찾는다. 오타처럼 보여도 그대로(형식 위반은 스크립트가
  거절한다).
- **판별**: 첫 토큰이 소문자·숫자·하이픈만이고, 그것을 빼도 요청문이 온전하면 폴더명이다.

| 입력 | 폴더명 | 프롬프트 |
|---|---|---|
| `/cowork login-timeout 로그인이 가끔 끊긴다` | `login-timeout` | 로그인이 가끔 끊긴다 |
| `/cowork 3학년 분수 단원 난이도가 적절한가` | *(자동 생성)* | 전체 |
| `/cowork autopilot 이 왜 멈추나` | *(자동 생성)* | 전체 — `autopilot` 을 빼면 문장이 깨진다. 폴더명이 아니라 주어다 |

- **없으면 자동 생성**: 주제를 영문 kebab-case 2~4단어로(예: `fraction-difficulty`). 자동 생성했으면
  보고 시 한 줄로 알린다 — "폴더명을 지정하지 않아 `X` 로 지었습니다. 직접 정하려면 `/cowork <폴더명> <프롬프트>`."
- **같은 폴더명 재실행 = 이전 결과 덮어쓰기**(스크립트가 경고). 남기려면 다른 이름(`X-2`). 사람이 준
  이름이면 바꾸지 말고 덮어쓴다는 사실만 보고한다.
- **진행 중 목록**: `bash .claude/skills/cowork/scripts/cowork.sh --list` — 상태(분석중/종합대기/
  종합완료/실패)·요청 원문. "그 분석 어떻게 됐나"는 이걸로 답한다.

## 2단계 — 8 AI 병렬 분석

```bash
bash .claude/skills/cowork/scripts/cowork.sh <폴더명> "<분석 요청 프롬프트 원문>"
```

- **반드시 `run_in_background: true`** — 각 AI 가 수 분씩 걸려 Bash 10분 제한을 넘긴다. 완료 알림이
  오면 3단계로.
- 프롬프트는 **사용자 원문 그대로**(여덟 AI 가 같은 질문을 받아야 대조가 성립). 모호하면 대상 파일·증상
  같은 맥락을 덧붙이는 것은 좋지만 질문 자체를 바꾸지 말 것.
- 페르소나는 `cowork.sh` 가 [references/analyst-persona.md](references/analyst-persona.md) 에서 읽어
  주입하고, 프로젝트 맥락은 `.cowork/cowork-prompt.md`(§0단계)에서 주입한다 — 프롬프트에 직접 쓰지 말 것.
- **grok 만 2-pass**(심층 탐색 → 적대적 자기 비판 → 재분석, 다른 AI 들의 유휴 시간을 쓰므로 전체 시간
  불변). 지침: [references/grok-deep-protocol.md](references/grok-deep-protocol.md).
  → `grok-cowork.md` 의 `## 7. 자기 비판으로 바로잡은 것` 을 종합 때 반드시 보라 — grok 이 철회한
  주장은 다른 AI 가 같은 말을 해도 의심하라.

- **모델은 항상 최신/최고 등급으로 고정된다**(2026-07-21 사용자 지시 — 낮추지 말 것):
  claude=`claude-opus-5`(Opus 5 고정)+`--effort xhigh` · codex=config 최신 모델+`model_reasoning_effort=xhigh`(config
  기본 low 를 강제 override, **모델 거절 시 `gpt-5.6-terra` 로 1회 fallback**) · grok=grok-4.5+`--reasoning-effort high`(xhigh 없음 → high 폴백, 실측)
  · OpenCode 세 모델=`opencode-go/deepseek-v4-pro`·`opencode-go/minimax-m3`·`opencode-go/qwen3.6-plus` 명시 고정 — **각각 별도 `opencode run` 프로세스 세 개로 동시에** 부른다. 🛑 접두어 주의: `opencode-go/`(구독)와 `opencode/`(Zen 종량제)는 다른 경로다. 인증 키는 **① `<작업공간>/.cowork/opencode-go-api.key` → ② `~/.config/cowork/opencode-go-api.key` 순으로 찾아** 먼저 실재하는 쪽을 `OPENCODE_API_KEY` 로 주입한다(①은 분석 대상 폴더 안이라 8 AI 가 읽을 수 있다 — 지원은 하되 실행마다 경고한다. 노출이 곤란하면 ②를 써라).
  · kimi=`kimi-code/k3-256k` 명시 고정 — K3 계열은 k3(1M)·k3-256k(256K) 두 가지인데 **반드시 256K 를 쓴다**(같은 K3 성능에 context quota 약 2배 절약, 2026-08-08 사용자 지시). K3 자체가 always_thinking 최고 모델이라 High/XHigh 별도 변형은 없다.
  실행 전에 **세 가지를 자동 점검**한다(2026-08-12 보강): ① `COWORK_KIMI_MODEL` 이 정책값 `kimi-code/k3-256k` 인지 ② `~/.kimi-code/config.toml` 에 그 별칭이 등록됐는지 ③ 🛑 **그 별칭 절의 `model`·`max_context_size` 가 정말 256K 를 가리키는지** — ③ 이 없으면 이름만 `k3-256k` 이고 내부가 `model = "k3"` 인 설정이 조용히 통과해 1M 를 호출한다(사각지대 재현 확인). 어긋나면 경고하되 실행은 막지 않는다(개인 설정 파일을 스크립트가 임의로 고치지 않는다).
  · agy=`gemini-3.7-flash-high`+`--effort high` 명시 고정 — Antigravity CLI(`agy -p`)로 부르는 **cowork 의 유일한 Gemini 계열 두뇌**다(2026-08-14 사용자 지시). 모델 ID 의 `-high` 접미어 자체가 추론 등급이지만 CLI 가 `--effort` 도 받으므로 둘 다 최고로 맞춘다(grok 처럼 xhigh 없음 → high 가 최고). 실행 전에 `agy models` 에 그 ID 가 **실재하는지** 점검한다 — v2.5.0 의 gemini 사고(구독에 없는 모델을 박아 두어 그 하나만 매번 3초 만에 죽음)를 반복하지 않기 위한 방어다.
  claude 는 별칭 `opus`(=최신 opus 추종)가 아니라 전체 ID 로 5 를 못 박는다(2026-07-26 사용자 지시).
  기본값·근거는 `cowork.sh` 상단 "모델·추론 등급 정책" 블록이 SSOT.

환경변수: `COWORK_TIMEOUT`(AI 당 제한 초, 기본 900) · `COWORK_ONLY`(일부만 재실행, 기본 claude,codex,grok,kimi,deepseek,minimax,qwen,agy)
· `COWORK_CLAUDE_MODEL`/`COWORK_CLAUDE_EFFORT`(claude-opus-5/xhigh) · `COWORK_CODEX_MODEL`/`COWORK_CODEX_EFFORT`(config 상속/xhigh) · `COWORK_CODEX_FALLBACK_MODEL`(gpt-5.6-terra — 1차가 모델 거절로 실패할 때만 1회 재시도)
· `COWORK_GROK_EFFORT`(high; xhigh 등 미지원 → high 폴백) · `COWORK_GROK_RETRIES`(빈응답 재시도, 기본 3)
· `COWORK_KIMI_MODEL`(kimi-code/k3-256k) · `COWORK_OPENCODE_DEEPSEEK_MODEL`(opencode-go/deepseek-v4-pro; 예전 `COWORK_OPENCODE_MODEL`은 하위 호환 별칭) · `COWORK_OPENCODE_MINIMAX_MODEL`(opencode-go/minimax-m3) · `COWORK_OPENCODE_QWEN_MODEL`(opencode-go/qwen3.6-plus) · `COWORK_OPENCODE_KEYFILE`(미지정 시 `.cowork/opencode-go-api.key` → `~/.config/cowork/opencode-go-api.key` 순 탐색)
· `COWORK_AGY_MODEL`(gemini-3.7-flash-high) · `COWORK_AGY_EFFORT`(high; low\|medium\|high 만 지원 → 그 외는 high 폴백)
  — grok 는 headless 시 부모 Grok 세션과 leader 소켓 충돌로 `permission_cancelled`→빈응답(exit 99)이
  날 수 있어, 호출마다 고유 `--leader-socket`·`--always-approve`·`env -u GROK_AGENT`·재시도를 쓴다
  (2026-07-21 실측, `references/readonly-enforcement.md` §grok 빈 응답).
  — agy 는 `--dangerously-skip-permissions` 없이는 **도구가 전부 자동 거부돼 빈 응답**이 난다(headless 에는
  승인할 사람이 없다). 그래서 승인은 열고 쓰기 차단은 전적으로 `sandbox-exec` 가 맡는다
  (2026-08-14 실측, 같은 문서 §agy).

## 3단계 — 결과 확인

`STATUS: 성공=N 실패=M` 으로 판정한다.

- **일부 실패**: 로그(`.cowork/<폴더명>/.logs/<ai>.log`)로 원인 확인 후 한 번만 재시도
  (`COWORK_ONLY=<실패AI> bash ... <폴더명> "<같은 프롬프트>"`). 재실패면 그 AI 를 빼고 진행하고
  final-report.md 에 제외를 명시한다. 사용자를 기다리게 하지 말라.
  🛑 **실패 파일에 `진단: 사용량 한도 초과` 가 있으면 재시도하지 말라** — 한도가 회복되기 전에는 같은
  실패가 반복될 뿐이다(과거 실패의 상당수가 이것이었다). 그 AI 를 빼고 곧바로 종합으로 간다.
- **전부 실패**(exit 1): 로그의 실제 원인(로그인 만료·네트워크·CLI 미설치)을 보고하고 멈춘다.

## 4단계 — 종합 → final-report.md 〔필수 — 빠뜨리면 cowork 실패〕

8 AI 분석은 재료일 뿐, 사람이 원하는 산출물은 `final-report.md` 하나다. **완료 알림이 오면 하던 일을
멈추고 종합부터 끝낸다** — 알림은 한 번뿐이고, cowork 두 건을 겹쳐 돌리다 먼저 끝난 쪽의 종합이 통째로
누락된 실제 사고가 있다(2026-07-16). 새 cowork 를 시작하기 전에 `--list` 로 `⏳ 종합대기` 가 없는지
확인한다.

1. 여덟 파일(`claude-cowork.md`·`codex-cowork.md`·`grok-cowork.md`·`kimi-cowork.md`·`deepseek-cowork.md`·`minimax-cowork.md`·`qwen-cowork.md`·`agy-cowork.md`)을 모두 읽는다.
2. 쟁점을 합의 / 이견 / 고유 통찰 / 반증으로 분류한다.
3. **결론을 좌우하는 근거 `파일:줄` 을 직접 열어 검증한다.** 이 검증이 cowork 의 유일한 가치다.
4. `.cowork/cowork-prompt.md` 의 목적·용어·금지사항과 어긋나는 권고는 채택하지 않는다(어긋난 사실을 §6 에 적는다).
5. `.cowork/<폴더명>/final-report.md` 를
   [references/final-report-protocol.md](references/final-report-protocol.md) 템플릿으로 작성한다.

## 5단계 — 사용자 보고

결론을 **본문으로 요약**한다(파일 경로만 던지지 말 것):

- 질문에 대한 최종 답 1~3줄
- 여덟 AI 가 갈렸던 지점과 자료로 내린 판정 · 반증된 주장(있으면)
- 권고 1~3순위와 각각의 범위·리스크
- 파일 위치 `.cowork/<폴더명>/final-report.md` (자동 생성 폴더명이면 그 사실도)

**요청에 실행이 포함돼 있었으면 여기서 멈추지 말고 곧바로 6단계로 간다** — "진행할까요?" 라고 묻지
않는다. 분석만 요청받았으면 "수정은 하지 않았다"를 남기고 종료한다.

## 6단계 — 리뷰 후 즉시 실행 〔요청에 실행이 포함된 경우〕

| 사용자 요청 | 어디까지 |
|---|---|
| "고쳐줘"·"수정까지"·"구현해줘"·"만들어줘"·"분석하고 적용해" | 6단계 — 보고 직후 **즉시 실행** |
| "분석해줘"·"왜 이런지 파봐"·"검토만 해줘"·"고치지 말고" | 5단계에서 종료 |
| 애매하면 | 5단계에서 종료 — 사용자가 지시하면 그때 실행 |

#### 🛑 실행 전에 최종 리뷰 라운드를 *먼저* 돌린다 (리뷰 후 실행)

실행은 **리뷰 라운드로 갱신된 최종 `final-report.md`** 를 근거로 해야 한다. 그런데 Stop hook 의 리뷰는
turn 종료 *후* 백그라운드로 도므로, 그냥 두면 실행이 리뷰보다 먼저 일어난다. 그래서 실행 요청일 때는
hook 을 기다리지 말고 **메인 오케스트레이터가 리뷰를 동기로 먼저 돌린다**:

1. 5단계 보고 직후, 곧바로 `bash .claude/skills/cowork/scripts/cowork.sh --review <폴더명>` 을
   `run_in_background: true` 로 실행한다. 리뷰가 8 AI 재검토 → claude 종합으로 `final-report.md` 를
   갱신하고 마커를 지운다(~15분).
2. 완료 알림을 받으면 **갱신된** `final-report.md` 로 6단계 실행을 진행한다(리뷰 전 버전이 아니라 최종본).
3. 리뷰 진행 중 turn 이 끝나도 Stop hook 은 `.review-running` 락 때문에 skip → 중복 리뷰 없음.
4. **예외**: 사용자가 "리뷰 없이 고쳐"·"바로 고쳐" 라고 하거나, 그 프로젝트에 리뷰 hook 이 설치되지
   않았고 사용자가 리뷰를 원치 않으면, 이 단계를 건너뛰고 현재 `final-report.md` 로 실행한다.

실행 규칙:

1. **(리뷰로 갱신된) `final-report.md` §7 최종 권고가 작업 지시서다** — 우선순위대로 적용한다.
2. **§6 반증된 주장 기반 수정 금지. 권고에 없는 임의 수정 금지**(필요해지면 보고에 왜인지 밝힌다).
3. **그 작업공간의 차단지점·검증 규칙을 따른다** — 무엇이 차단지점이고 어떻게 검증하는지는
   `.cowork/cowork-prompt.md` 와 지침 문서(`CLAUDE.md` 등)가 정한다. 검증 없이 "완료" 금지.
4. 검증 통과 후 **커밋**(git 저장소면. 메시지에 cowork 폴더명을 남겨 근거를 추적 가능하게).
5. `final-report.md` 끝에 **`## 9. 적용 결과` 를 덧붙인다**(§1~8 은 수정 전 사실의 기록이므로 보존)
   — 적용/보류 내역, 커밋 해시, 검증 결과.

보고: 무엇을 했나(파일) · 어떻게 검증했나 · 커밋 해시 · 보류한 권고와 이유 · 후속 조치 필요 여부.

## 선택 — final-report 최종 리뷰 라운드 (Stop hook)

`final-report.md` 를 **8 AI 에게 한 번 더 던져** 종합본 자체를 비판하게 하고, 그 지적을 반영해
`final-report.md` 를 다듬는 자동 후처리다. **설치한 프로젝트에서만** 돈다.

- **설치**(1회): `bash .claude/skills/cowork/scripts/cowork.sh --init-hook` — 이 프로젝트
  `.claude/settings.json` 의 Stop hook 에 `final-report-stop-hook.sh` 를 멱등 등록한다(기존 hook 보존).
  사용자가 "리뷰 hook 설치" 라고 하면 이 명령을 실행한다.
  ⚠️ `--init`(시스템 프롬프트 생성)과 **다른 명령**이다. 혼동하지 말 것.
- **동작**: cowork 분석이 시작되면 작업폴더에 `.review-final-report` 마커가 생긴다. 메인 Claude 가
  `final-report.md` 를 쓰고 턴을 끝내면 Stop hook 이 발동해, 마커가 있는 작업의 리뷰를 **백그라운드로
  던지고 즉시 종료**한다(세션은 안 멈춘다). 백그라운드에서 `cowork.sh --review <폴더명>` 이 돌며:
  8 AI 가 `final-report.md` + 8개 원본 분석을 재검토(1-pass) → claude 가 지적을 반영해
  `final-report.md` 갱신 → 변경을 `final-report-log.md` 에 기록 → 마커 삭제.
  단 **실행까지 요청받았으면** hook 의 백그라운드 리뷰를 기다리지 말고, 오케스트레이터가 `--review` 를
  동기로 먼저 돌린 뒤 그 최종본으로 실행한다(§6단계 — "리뷰 후 실행").
- **무한 루프 없음**: 리뷰 완료 시 마커가 사라져 다음 Stop 부터 skip. 진행 중엔 `.review-running`
  락으로 중복 실행을 막는다.
- 리뷰 페르소나·종합 프롬프트·검증 규칙 SSOT: [references/final-report-review.md](references/final-report-review.md).
- **리뷰는 몇 분 뒤 조용히 final-report.md 를 바꾼다** — 사용자가 이미 보고받은 결론이 갱신될 수 있으니,
  hook 설치 프로젝트에서는 "리뷰 라운드가 백그라운드에서 돌고 있고 `final-report-log.md` 에 기록된다"고
  한 줄 알린다.

## 산출물

```
.cowork/
├── cowork-prompt.md   ← 이 프로젝트의 시스템 프롬프트 (§0단계 — 모든 분석에 주입, 사람이 관리)
└── <폴더명>/
    ├── claude-cowork.md   ← claude 분석 (단일 pass)
    ├── codex-cowork.md    ← codex 분석 (단일 pass)
    ├── grok-cowork.md     ← grok 분석 (2-pass 최종, §7 자기 비판 포함)
    ├── kimi-cowork.md     ← kimi 분석 (단일 pass, Kimi K3 256K)
    ├── deepseek-cowork.md ← DeepSeek V4 Pro 분석 (단일 pass · 독립 opencode CLI)
    ├── minimax-cowork.md  ← MiniMax M3 분석 (단일 pass · 독립 opencode CLI)
    ├── qwen-cowork.md     ← Qwen 3.6 Plus 분석 (단일 pass · 독립 opencode CLI)
    ├── agy-cowork.md      ← Gemini 3.7 Flash High 분석 (단일 pass · Antigravity CLI)
    ├── final-report.md    ← 최종 종합·결론 (오케스트레이터 작성 — 사람이 원하는 산출물)
    ├── final-report-log.md ← 리뷰 라운드 변경 이력 (hook 설치 시, append)
    ├── .grok-pass1.md     ← grok 1차 원본 (pass2 와 비교하면 무엇이 뒤집혔는지 보인다)
    ├── .prompt.md         ← 실제 주입된 프롬프트 (재현용 — cowork-prompt.md 가 여기 실렸는지 확인 가능)
    ├── .review/           ← 리뷰 라운드 산출물 (8개 리뷰·종합 원출력·원본 백업)
    └── .logs/*.log        ← 각 CLI 원시 로그 (실패 진단용)
```

## 자주 틀리는 지점

- **`.cowork/cowork-prompt.md` 를 안 만들고 쓰는 것** — 여덟 AI 가 프로젝트 목적을 모른 채 일반론을 쓴다.
  새 프로젝트에서 처음 cowork 를 쓰면 `--init` 부터 권하라.
- **`--init` 과 `--init-hook` 을 헷갈리는 것** — 앞은 시스템 프롬프트 생성, 뒤는 리뷰 hook 설치다.
- **특정 분야를 페르소나·스크립트에 하드코딩하는 것** — 이 스킬은 모든 분야에서 돈다. 프로젝트 고유
  내용은 전부 `.cowork/cowork-prompt.md` 로 간다.
- **사람이 준 폴더명을 바꾸는 것** — 작업 ID 가 깨진다. 준 대로 쓴다.
- **폴더명을 프롬프트로 삼키는 것**(또는 반대) — §1단계 판별표를 볼 것.
- **완료 알림을 흘려보내는 것** — 알림은 한 번뿐. 놓치면 final-report.md 가 영영 안 생긴다(실제 사고).
- **실행 요청인데 보고 후 멈추는 것** — "고쳐줘"를 받았으면 되묻지 말고 즉시 6단계로 간다.
- **순서를 뒤집는 것** — 실행 요청이어도 분석 → 종합 → 실행이다. final-report.md 가 먼저다.
- **종합을 요약으로 대체하는 것** — 근거 검증 없는 종합은 네 배로 그럴듯한 환각이다.
- **다수결 판정** — 실제 자료가 판정한다, 표수가 아니라.
- **foreground 실행** — Bash 10분 제한에 분석이 날아간다. `run_in_background: true`.
- **AI 에게 파일 저장을 시키는 것** — 샌드박스가 막는다. stdout → `cowork.sh` 가 기록한다.
