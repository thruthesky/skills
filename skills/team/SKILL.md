---
name: team
description: 한 팀에서 여러 팀원(A·B·C·D·E·F 등)이 동시에 작업할 때 필요한 협업 인프라 스킬. ① **Playwright MCP 또는 Chrome DevTools MCP 를 상호 배타적(mutual lock)으로 한 번에 한 팀원만** 사용하도록 파일 기반 잠금(`chrome-mcp.lock`·`playwright-mcp.lock`)을 강제하여 브라우저 프로필·디버깅 포트 충돌을 방지한다. ② 모든 팀원의 작업은 **git commit · `git log` · 팀 로그(`activity.log` 공용 타임라인 + `team-<X>.md` 개인 로그)** 세 가지 채널로 기록·공유되며, 이 세 소스를 교차 분석하여 누가 언제 무엇을 어떻게 작업하고 있는지 완전하게 재구성한다. ③ 팀 매니저는 **식별자가 아닌 별도 역할(Role)** 로, 사용자가 `/team:manage` 를 명시적으로 호출했을 때만 기동되며 분석·분배 제안·모니터링을 수행한다 — 팀원 A 는 더 이상 매니저가 아니며 B·C·D·E·F 와 동등한 실무 팀원이다. 다음과 같은 경우 사용: (1) 여러 Claude 세션이 동일 프로젝트를 병렬로 작업하는 환경, (2) Playwright MCP 또는 Chrome DevTools MCP 를 쓰기 전에 mutual lock 으로 다른 팀원과 충돌을 피하고자 할 때, (3) git commit · git log · 팀 로그를 통해 팀원의 작업 진행·블로커·Handoff 를 타임라인으로 분석·관찰하고자 할 때, (4) `/team:work` 로 팀원 업무를 수행하거나 `/team:update` 로 팀 현황을 조회하거나 `/team:manage` 로 매니저 분석·제안을 요청할 때. 키워드: 팀, team, 팀원, worker, 팀 매니저, manager, manage, Mutual Lock, 상호 배타적 잠금, 배타적 잠금, Playwright MCP, Chrome DevTools MCP, 공유 자원 충돌, git commit, git log, 팀 로그, activity.log, team-A.md, 협업, 업무 분석.
---

# Team 스킬 — 한 팀 다중 팀원 협업 인프라

이 스킬은 **하나의 팀에서 여러 팀원이 동시에 작업**할 때 발생하는 세 가지 핵심 문제를 해결합니다.

## 🎯 스킬의 세 가지 주요 목적

### ① Mutual Lock — Playwright MCP 와 Chrome DevTools MCP 의 상호 배타적 점유

**Playwright MCP 와 Chrome DevTools MCP 는 서로를 포함하여 상호 배타적(mutual lock)으로 사용합니다.** 두 MCP 모두 브라우저 프로필·디버깅 포트를 단일 프로세스가 점유하기 때문에, 같은 MCP 를 두 팀원이 동시에 호출하는 것은 물론이고 한 팀원이 Chrome DevTools MCP 를 쓰는 동안 다른 팀원이 Playwright MCP 를 쓰는 것도 금지됩니다. 위반 시 `The browser is already running for ...` 에러 · 프로필 SingletonLock 충돌 · 프로세스 크래시로 **모두의 작업이 깨집니다**.

따라서 **한 번에 오직 한 팀원, 오직 하나의 MCP** 만 사용할 수 있도록 파일 기반 Mutual Lock(배타적 상호 잠금) 을 강제합니다.

- 잠금 파일: `.dev/chrome-mcp.lock`, `.dev/playwright-mcp.lock`
- 획득·해제 스크립트: `tools/lock/chrome-mcp-lock.sh` (subject=`chrome`/`playwright`)
- 획득은 **`acquire`** 로, 해제는 **`release`** 로. 스크립트가 자동으로 5초 간격 폴링·최대 15분 대기
- **다른 팀원의 Lock 을 힘으로 빼앗거나, status 확인 없이 `pkill`·프로필 삭제 금지** (세부는 `commands/work.md` 의 Mutual Lock 프로토콜 참조)

### ② Git Commit · Git Log · 팀 로그로 서로의 업무를 분석

팀원 간 업무 분석·공유 채널은 다음 **세 가지 축** 으로 구성되며, 각 채널은 서로 다른 시간 해상도·정보 밀도를 가집니다:

1. **git commit / `git log` / `git show` / `git blame`** — 누가 무엇을 최종적으로 바꿨는가 (공식 변경 이력, 코드 단위 감사 추적)
2. **팀 로그 (공용 `activity.log` + 팀원별 `team-<X>.md`)** — 누가 지금 무엇을 왜 하고 있는가, 블로커·Handoff·진행 체크포인트 (실시간 의도·맥락)
3. **Mutual Lock 파일** — 지금 누가 어느 MCP 를 점유 중인가 (스냅샷 상태)

**세 채널을 교차 분석** 하면 매니저 역할(별도 기동 시)과 각 팀원이 서로의 업무 패턴·병목·협업 지점을 완전하게 재구성할 수 있습니다. 예: 팀 로그의 `TASK_START`/`TASK_DONE` 구간을 `git log --author` / `git log --since` 로 확인한 커밋과 정렬하면 "누가 어떤 의도로 시작해 어떤 코드로 마무리했는가" 를 추적할 수 있고, Lock 타임라인과 결합하면 "그 작업 동안 어느 MCP 를 얼마나 점유했는가" 까지 분석할 수 있습니다.

팀 로그는 다음 위치에 기록됩니다.

- **공용 타임라인**: `.dev/team/logs/activity.log` (모든 이벤트가 시간순 append)
- **팀원별 개인 로그**: `.dev/team/logs/team-<X>.md` (A·B·C·D·E·F 각 1 파일)
- **로그 포맷 표준**: `.dev/team/logs/README.md`
- **기록 명령**: `tools/team/log.sh <팀원> <이벤트> [<대상>] [<설명>]`

각 팀원은 **새 태스크 착수**, **Lock 대기 시작**, **Lock 획득**, **Lock 해제**, **진행 중간 체크포인트**, **태스크 완료**, **블로커**, **Handoff**, **관찰 공유** 순간에 반드시 로그를 남깁니다. 로그가 없으면 다른 팀원은 Lock 대기 전략·업무 순서·협업 지점을 판단할 수 없습니다.

`git log`, `git show`, `git blame`, 커밋 메시지 본문, 팀 로그를 **함께** 읽는 것이 이 스킬의 핵심 분석 방법입니다. 매니저 역할이 기동된 세션은 이 교차 분석을 바탕으로 팀원별 작업 패턴·성과·병목을 정리하여 사용자와 팀원에게 인사이트를 제공합니다.

### ③ 매니저는 역할(Role) — 팀원 식별자와 분리

**과거와 달리 팀원 A 는 더 이상 자동으로 팀 매니저가 아닙니다.** 매니저는 **사용자가 `/team:manage` 를 호출한 세션에서만 기동되는 별도 역할** 이며, 팀원 식별자(A·B·C·D·E·F)와 완전히 독립적입니다.

- 팀원 A·B·C·D·E·F 는 **동등한 실무 팀원** 으로, 어떤 식별자도 관리 권한을 자동으로 갖지 않습니다
- **매니저는 기본적으로 존재하지 않습니다** — 사용자가 `/team:manage <요청>` 을 호출하면 그 세션이 매니저 역할을 수행
- 매니저는 **분석·제안·모니터링·규율 감독** 을 수행하되, **팀원에게 직접 지시하지 않습니다** — 제안만 생산하고, 지시·승인은 사용자가 `/team:work` 로 개별 팀원에게 직접 내림
- 자세한 역할 정의는 `references/manager.md` 참조

---

## 👥 팀 구조 — 팀원은 모두 동등한 실무자

**이 스킬이 전제하는 팀 구조**:

- **팀은 단 하나** 뿐입니다. 여러 팀을 운영하지 않습니다
- 팀원은 **A, B, C, D, E, F** 의 단일 문자 식별자로 구분 (필요 시 `G`·`H`· 이상 확장)
- **모든 팀원은 실무 팀원** — 어느 식별자도 매니저 권한을 자동으로 갖지 않음
- **매니저가 필요하면 사용자가 `/team:manage` 로 명시적으로 기동** — 그 세션이 매니저 역할만 수행 (실무 태스크는 팀원에게 위임)

### 팀원 A·B·C·D·E·F 의 공통 역할

- 사용자(또는 사용자의 위임을 받은 매니저 세션) 가 배정한 업무를 직접 수행
- Mutual Lock · 팀 로그 규칙을 예외 없이 준수
- 본인 로그(`team-<X>.md`) 에만 append, 다른 팀원 로그는 수정 금지
- 블로커 발생 시 팀 로그에 `BLOCKER` 이벤트 기록 + 사용자에게 보고
- 다른 팀원에게 **지시 권한 없음** (팀원 A 포함, Peer 간 지시 금지)

### 매니저 역할 (사용자가 `/team:manage` 로 기동한 경우에만 존재)

사용자가 `/team:manage` 를 호출하면 해당 세션은 매니저 역할로 전환되어 다음을 수행:

1. **업무 분배 제안** — 사용자로부터 받은 업무를 분해하여 어느 팀원에게 배정하면 좋을지 **제안**. 실제 분배는 사용자가 `/team:work` 로 직접 수행 (사용자의 명시적 위임 시에만 대행)
2. **업무 모니터링** — 팀 로그·Lock·git 이력을 교차 분석하여 팀 현황 요약
3. **팁과 분석 제공** — 팀원별 작업 패턴·강점을 분석하여 사용자에게 인사이트 제공 (팀원 간 우열 비교 금지, 각자의 강점 발견에 초점)
4. **협업 규율 감독** — Mutual Lock · 팀 로그 규칙 위반·누락 감지 시 사용자에게 보고 (강제 해제·로그 수정은 권한 없음)
5. **인프라 도입 권고** — `tools/team/`, `tools/lock/`, `.dev/team/logs/` 부재 시 단일/다중 세션 환경 확인 후 도입 필요성 권고

매니저는 **사용자와 1:1 대화** 하며, 팀원에게 직접 말을 걸지 않습니다. 자세한 정의는 `references/manager.md`, 기동 절차는 `commands/manage.md` 참조.

---

## 🔧 이 스킬이 제공하는 명령

### `/team:work` — 팀원 에이전트

사용자(또는 사용자의 명시적 위임을 받은 매니저 세션) 가 개별 팀원(A·B·C·D·E·F)에게 업무를 지시할 때 사용합니다. 팀원은:

1. 본인 식별자 확정
2. 업무 분해 + TodoWrite 등록
3. Lock 불필요 태스크는 즉시 실행, Lock 필요 태스크는 Mutual Lock 프로토콜 준수
4. 모든 이벤트(TASK_START / LOCK_WAIT / LOCK_ACQUIRE / LOCK_RELEASE / TASK_PROGRESS / TASK_DONE / BLOCKER / NOTE / HANDOFF) 를 팀 로그에 기록
5. 완료 기준 충족 여부를 검증한 뒤 사용자에게 보고

자세한 절차·금지 사항·에러 대응은 `commands/work.md` 참조.

### `/team:update` — 팀 모니터링 (읽기 전용 상태 조회)

사용자(그리고 기동된 매니저 세션) 가 팀 전체 현황을 빠르게 파악할 때 사용하는 **읽기 전용** 조회 도구입니다. 매니저 세션이 없어도 사용자 본인이 직접 호출 가능합니다. 서브커맨드:

| 서브커맨드 | 용도 |
|---|---|
| `status` (기본) | 팀원별 마지막 이벤트 · Lock 보유 · 블로커 · Handoff · git 변경 요약 |
| `logs [팀원]` | 특정 팀원의 개인 로그 전문 또는 전체 팀원 최근 로그 |
| `tail [N]` | 공용 타임라인 꼬리 |
| `who` | 현재 누가 어떤 태스크를 수행 중인지 1 줄 요약 |
| `lock` | Mutual Lock 심층 상태 + 최근 Lock 타임라인 (Stale 15 분 경고 포함) |
| `brief [팀원]` | 팀원 브리프 전문 |
| `stop-loop` | 무한 반복 / Ralph Loop 차단 안내 (수정은 사용자 승인 후) |
| `cleanup` | 오래된 로그 아카이빙 안내 (수정은 사용자 승인 후) |

이 명령은 **코드·Lock·로그를 수정하지 않습니다**. 수집된 정보의 분석·팁은 매니저 세션(`/team:manage`) 이 생산하거나 사용자가 직접 해석합니다.

자세한 출력 형식·금지 사항은 `commands/update.md` 참조.

### `/team:manage` — 팀 매니저 에이전트 (명시적 기동)

사용자가 **팀 전체 관점에서 분석·분배 제안·모니터링** 이 필요할 때 명시적으로 호출합니다. 이 명령을 호출한 세션은 **매니저 역할** 로 전환되어 다음을 수행:

1. 인프라 존재 여부 점검 및 도입 권고
2. 팀 상태 스냅샷 수집 (읽기 전용)
3. 사용자 요청 유형에 따른 분석: 업무 분배 제안 / 활동 요약 / 팀원 강점 분석 / 규율 점검 / 인프라 권고
4. 표준 보고서 형식으로 사용자에게 제출
5. 지시는 사용자가 내리도록 선택지 제시 (매니저는 자동 실행 금지)

**팀원 A 는 자동으로 매니저가 아니므로**, 사용자가 매니저 기능이 필요한 순간마다 명시적으로 `/team:manage` 를 호출해야 매니저 세션이 열립니다. 그렇지 않으면 팀에는 매니저가 존재하지 않으며 사용자가 개별 팀원에게 직접 지시합니다.

자세한 권한·한계·출력 형식은 `commands/manage.md`, 역할 정의는 `references/manager.md` 참조.

---

## 📐 필수 디렉토리 구조 (프로젝트 루트 기준)

스킬을 적용하는 프로젝트에는 다음 파일·디렉토리가 존재해야 합니다.

```
<project-root>/
├── .dev/
│   ├── chrome-mcp.lock            # Chrome DevTools MCP Lock 파일
│   ├── playwright-mcp.lock        # Playwright MCP Lock 파일
│   ├── chrome-mcp-lock.log        # Lock 스크립트 자체 로그
│   └── team/
│       └── logs/
│           ├── README.md          # 포맷·이벤트 타입 표준
│           ├── activity.log       # 공용 타임라인 (append-only)
│           ├── team-A.md          # 팀원 A 개인 로그 (실무 팀원)
│           ├── team-B.md          # 팀원 B 개인 로그
│           ├── team-C.md
│           ├── team-D.md
│           ├── team-E.md
│           └── team-F.md
├── tools/
│   ├── lock/
│   │   └── chrome-mcp-lock.sh     # acquire / release / status / force-release
│   └── team/
│       └── log.sh                 # 팀 로그 기록 스크립트
└── test-screenshots/
    └── debug/                     # MCP 스크린샷 저장 (팀원·태스크·타임스탬프 포함 파일명)
```

**매니저 전용 로그 파일은 존재하지 않습니다** — 매니저는 역할이지 식별자가 아니므로 `team-manager.md` 같은 파일을 만들지 않습니다.

**스크립트(`tools/lock/chrome-mcp-lock.sh`, `tools/team/log.sh`) 가 존재하지 않는 프로젝트라면**, 스킬을 적용하기 전에 두 스크립트를 먼저 설치해야 합니다. 두 스크립트의 인터페이스는 다음 섹션의 "인터페이스 계약" 을 따릅니다.

---

## 📜 인터페이스 계약 (스크립트 규격)

### `tools/lock/chrome-mcp-lock.sh`

```bash
tools/lock/chrome-mcp-lock.sh status                                 # 두 subject 의 FREE/HELD 상태 출력
tools/lock/chrome-mcp-lock.sh acquire <ME> "<task>" --subject <S>    # 5초 폴링, 최대 15분 대기 후 획득 또는 timeout
tools/lock/chrome-mcp-lock.sh release <ME> --subject <S>             # 본인 소유 Lock 만 해제
tools/lock/chrome-mcp-lock.sh force-release --subject <S>            # 관리자용, 사용자 승인 후에만
```

- `<ME>` : 팀원 식별자 (`A`·`B`·`C`·`D`·`E`·`F`)
- `<S>` : `chrome` 또는 `playwright`
- `acquire` 는 동일 subject 를 이미 다른 팀원이 보유 중이면 자동 폴링 대기. 호출자는 스크립트 종료를 그대로 기다리면 됨

### `tools/team/log.sh`

```bash
tools/team/log.sh <팀원> <이벤트> [<대상>] [<설명>]
```

- `<팀원>` : `A`~`F` (NATO 별명 Alpha/Beta/Charlie/Delta/Echo/Foxtrot 도 자동 정규화)
- `<이벤트>` : `TASK_START` · `TASK_PROGRESS` · `TASK_DONE` · `LOCK_WAIT` · `LOCK_ACQUIRE` · `LOCK_RELEASE` · `BLOCKER` · `NOTE` · `HANDOFF`
- `<대상>` : 태스크 ID · Lock subject · `-` (해당 없음)
- `<설명>` : 한 줄 한국어 요약
- 호출 1 회 → `activity.log` + `team-<X>.md` 양쪽에 동시 append (append-only, 과거 엔트리 수정 금지)

---

## 🚨 이 스킬을 쓸 때 반드시 지켜야 할 원칙 (요약)

1. **한 번에 한 팀원만 Chrome DevTools MCP / Playwright MCP 사용** — Mutual Lock 프로토콜 예외 없이 준수
2. **Lock 획득 전 `status` 확인** — `The browser is already running` 에러에도 첫 행동은 반드시 status 확인. `pkill`·프로필 삭제는 Lock 을 본인이 보유한 상태에서만
3. **모든 팀원은 본인 활동을 로그에 기록** — TASK_START 부터 TASK_DONE 까지, Lock 단계도 포함
4. **다른 팀원 로그·Lock 을 수정·강탈 금지** — 관찰만, 간섭 없음
5. **팀원 A 는 단순 실무 팀원** — B·C·D·E·F 와 동등. 매니저 권한 없음. 다른 팀원에게 지시 금지
6. **매니저는 `/team:manage` 로 명시적 기동 시에만 존재** — 매니저도 팀원에게 직접 지시하지 않고 제안만 생산, 지시는 사용자
7. **Lock 대기 중 idle 금지** — 반드시 Lock 불필요 병행 작업 수행 (코드 리팩터링·타입체크·CLI 검증 등)
8. **한국어 기록** — 파일 경로·명령어·식별자만 영문 원문, 설명은 한국어

---

## 🧭 언제 이 스킬을 사용할 것인가

- 동일 프로젝트를 여러 Claude 세션(팀원 A·B·C·…) 이 병렬로 작업하는 환경
- Chrome DevTools MCP 또는 Playwright MCP 를 호출해야 하지만 다른 세션과 충돌이 우려될 때
- 팀원 간 작업 진행·블로커·Handoff 를 실시간으로 관찰하고자 할 때
- 사용자가 팀 전체 관점에서 **분배 제안·활동 요약·팀원 강점 분석** 을 받고자 매니저 역할을 명시적으로 기동할 때
- 개별 팀원으로서 업무를 수행하며 Mutual Lock 프로토콜을 따라야 할 때

---

## 🧱 스킬 도입 여부 판단 (사용자 결정 사항)

이 스킬이 가정하는 디렉토리·스크립트(`tools/team/`, `tools/lock/`, `.dev/team/logs/`)를 프로젝트에 **정식 구축할지 여부는 사용자의 결정** 입니다. 어떤 Claude 세션(팀원 또는 매니저) 도 사용자 승인 없이 인프라를 자동 설치하지 않습니다.

### 도입이 필요한 경우

- **다중 Claude 세션** 이 동일 프로젝트를 병렬로 작업하는 환경
- Chrome DevTools MCP · Playwright MCP 호출이 빈번하고, 두 세션 이상이 **동시에** 브라우저 자동화를 시도할 가능성이 있을 때
- 팀원 간 작업 이력(git commit + 팀 로그 + Lock 타임라인)을 교차 분석하여 매니저 세션이 팁·인사이트를 지속적으로 제공해야 할 때

### 도입이 **불필요** 할 수 있는 경우

- **단일 Claude 세션** 으로만 개발이 진행되는 환경 (동시 작업자가 본인 한 명뿐)
- MCP 호출이 거의 없거나, 호출하더라도 한 세션에서 순차적으로만 쓰는 경우
- 팀 로그를 적극적으로 교차 분석할 필요가 없고, git commit 만으로 변경 이력 추적이 충분한 경우

### 인프라 점검 의무

`/team:work`, `/team:update`, `/team:manage` 중 어느 명령이든 세션이 시작될 때, 해당 세션은 **먼저 프로젝트에 인프라가 존재하는지** 확인합니다.

```bash
ls tools/team/log.sh tools/lock/chrome-mcp-lock.sh .dev/team/logs/ 2>/dev/null
```

- 인프라 존재 → 정상적으로 Lock · 로그 프로토콜 적용
- 인프라 부재 + 다중 세션 예상 → 사용자에게 **"정식 도입을 원하시는지"** 를 확인하고, 설치는 사용자 승인 시에만 수행
- 인프라 부재 + 단일 세션만 사용 → 현재 환경에서는 본 스킬이 **의무적으로 필요하지는 않다** 는 점을 사용자에게 고지하고, 그럼에도 MCP 여러 개를 병행 호출하는 경우의 충돌 위험만 간단히 안내

---

## 🔗 상세 문서

- `commands/work.md` — `/team:work` 팀원 에이전트 전체 절차, Mutual Lock 프로토콜, 팀 로그 기록 의무, 보고 서식
- `commands/update.md` — `/team:update` 모니터링 명령 서브커맨드 상세, 읽기 전용 원칙, 매니저·사용자 활용법
- `commands/manage.md` — `/team:manage` 매니저 에이전트 기동 절차, 권한·한계, 표준 보고서 형식
- `references/manager.md` — 매니저 역할 정의, 팀원 A 와의 명확한 구분, 매니저 기동 시나리오
