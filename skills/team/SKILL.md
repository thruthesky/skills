---
name: team
description: 한 팀에서 여러 팀원(A·B·C·D·E·F 등)이 동시에 작업할 때 필요한 협업 인프라 스킬. ① **Playwright MCP 또는 Chrome DevTools MCP 를 상호 배타적(mutual lock)으로 한 번에 한 팀원만** 사용하도록 파일 기반 잠금(`chrome-mcp.lock`·`playwright-mcp.lock`)을 강제하여 브라우저 프로필·디버깅 포트 충돌을 방지한다. ② 모든 팀원의 작업은 **git commit · `git log` · 팀 로그(`activity.log` 공용 타임라인 + `team-<X>.md` 개인 로그)** 세 가지 채널로 기록·공유되며, 이 세 소스를 교차 분석하여 누가 언제 무엇을 어떻게 작업하고 있는지 완전하게 재구성한다. 팀원 A 는 항상 팀 매니저로 업무 분배·모니터링·팁·분석을 담당. 다음과 같은 경우 사용: (1) 여러 Claude 세션이 동일 프로젝트를 병렬로 작업하는 환경, (2) Playwright MCP 또는 Chrome DevTools MCP 를 쓰기 전에 mutual lock 으로 다른 팀원과 충돌을 피하고자 할 때, (3) git commit · git log · 팀 로그를 통해 팀원의 작업 진행·블로커·Handoff 를 타임라인으로 분석·관찰하고자 할 때, (4) `/team:worker` 로 팀원 업무를 수행하거나 `/team:update` 로 팀 현황을 조회할 때. 키워드: 팀, team, 팀원, worker, 팀 매니저, Mutual Lock, 상호 배타적 잠금, 배타적 잠금, Playwright MCP, Chrome DevTools MCP, 공유 자원 충돌, git commit, git log, 팀 로그, activity.log, team-A.md, 협업, 업무 분석.
---

# Team 스킬 — 한 팀 다중 팀원 협업 인프라

이 스킬은 **하나의 팀에서 여러 팀원이 동시에 작업**할 때 발생하는 두 가지 핵심 문제를 해결합니다.

## 🎯 스킬의 두 가지 주요 목적

### ① Mutual Lock — Playwright MCP 와 Chrome DevTools MCP 의 상호 배타적 점유

**Playwright MCP 와 Chrome DevTools MCP 는 서로를 포함하여 상호 배타적(mutual lock)으로 사용합니다.** 두 MCP 모두 브라우저 프로필·디버깅 포트를 단일 프로세스가 점유하기 때문에, 같은 MCP 를 두 팀원이 동시에 호출하는 것은 물론이고 한 팀원이 Chrome DevTools MCP 를 쓰는 동안 다른 팀원이 Playwright MCP 를 쓰는 것도 금지됩니다. 위반 시 `The browser is already running for ...` 에러 · 프로필 SingletonLock 충돌 · 프로세스 크래시로 **모두의 작업이 깨집니다**.

따라서 **한 번에 오직 한 팀원, 오직 하나의 MCP** 만 사용할 수 있도록 파일 기반 Mutual Lock(배타적 상호 잠금) 을 강제합니다.

- 잠금 파일: `.dev/chrome-mcp.lock`, `.dev/playwright-mcp.lock`
- 획득·해제 스크립트: `tools/lock/chrome-mcp-lock.sh` (subject=`chrome`/`playwright`)
- 획득은 **`acquire`** 로, 해제는 **`release`** 로. 스크립트가 자동으로 5초 간격 폴링·최대 15분 대기
- **다른 팀원의 Lock 을 힘으로 빼앗거나, status 확인 없이 `pkill`·프로필 삭제 금지** (세부는 `commands/worker.md` 의 Mutual Lock 프로토콜 참조)

### ② Git Commit · Git Log · 팀 로그로 서로의 업무를 분석

팀원 간 업무 분석·공유 채널은 다음 **세 가지 축** 으로 구성되며, 각 채널은 서로 다른 시간 해상도·정보 밀도를 가집니다:

1. **git commit / `git log` / `git show` / `git blame`** — 누가 무엇을 최종적으로 바꿨는가 (공식 변경 이력, 코드 단위 감사 추적)
2. **팀 로그 (공용 `activity.log` + 팀원별 `team-<X>.md`)** — 누가 지금 무엇을 왜 하고 있는가, 블로커·Handoff·진행 체크포인트 (실시간 의도·맥락)
3. **Mutual Lock 파일** — 지금 누가 어느 MCP 를 점유 중인가 (스냅샷 상태)

**세 채널을 교차 분석** 하면 팀원 A(매니저) 와 각 팀원이 서로의 업무 패턴·병목·협업 지점을 완전하게 재구성할 수 있습니다. 예: 팀 로그의 `TASK_START`/`TASK_DONE` 구간을 `git log --author` / `git log --since` 로 확인한 커밋과 정렬하면 "누가 어떤 의도로 시작해 어떤 코드로 마무리했는가" 를 추적할 수 있고, Lock 타임라인과 결합하면 "그 작업 동안 어느 MCP 를 얼마나 점유했는가" 까지 분석할 수 있습니다.

팀 로그는 다음 위치에 기록됩니다.

- **공용 타임라인**: `.dev/team/logs/activity.log` (모든 이벤트가 시간순 append)
- **팀원별 개인 로그**: `.dev/team/logs/team-<X>.md` (A·B·C·D·E·F 각 1 파일)
- **로그 포맷 표준**: `.dev/team/logs/README.md`
- **기록 명령**: `tools/team/log.sh <팀원> <이벤트> [<대상>] [<설명>]`

각 팀원은 **새 태스크 착수**, **Lock 대기 시작**, **Lock 획득**, **Lock 해제**, **진행 중간 체크포인트**, **태스크 완료**, **블로커**, **Handoff**, **관찰 공유** 순간에 반드시 로그를 남깁니다. 로그가 없으면 다른 팀원은 Lock 대기 전략·업무 순서·협업 지점을 판단할 수 없습니다.

`git log`, `git show`, `git blame`, 커밋 메시지 본문, 팀 로그를 **함께** 읽는 것이 이 스킬의 핵심 분석 방법입니다. 팀원 A(매니저) 는 이 교차 분석을 바탕으로 팀원별 작업 패턴·성과·병목을 정리하여 사용자와 팀원에게 인사이트를 제공합니다.

---

## 👥 팀 구조 — 팀원 A 는 팀 매니저

**이 스킬이 전제하는 팀 구조**:

- **팀은 단 하나** 뿐입니다. 여러 팀을 운영하지 않습니다
- 팀원은 **A, B, C, D, E, F** 의 단일 문자 식별자로 구분 (필요 시 `G`·`H`· 이상 확장)
- **팀원 A 는 항상 팀 매니저** 입니다

### 팀 매니저(팀원 A) 의 역할

1. **업무 분배** — 사용자로부터 받은 업무를 분해하여 적절한 팀원(B·C·D·E·F)에게 배정
2. **업무 모니터링** — `/team:update` 로 각 팀원의 로그·Lock·블로커·Handoff 를 상시 관찰
3. **팁과 분석 제공** — 팀원별 작업 패턴·성과·병목을 분석하여 "누가 무엇을 잘 하고 있는지" 에 대한 인사이트를 사용자와 팀원에게 제공
4. **협업 규율 감독** — Mutual Lock 프로토콜과 팀 로그 규칙이 지켜지고 있는지 관찰하고, 위반·누락이 감지되면 사용자에게 보고

팀원 A 도 필요 시 직접 실무(코드 작성·MCP 검증)를 수행할 수 있지만, **주 역할은 관리·분석** 입니다. 따라서 팀원 A 는 Lock 을 장기 점유하기보다 팀 현황을 주기적으로 확인하고, 다른 팀원이 Lock 을 효율적으로 쓸 수 있도록 스케줄을 조정합니다.

### 팀원 B·C·D·E·F 의 역할

- 팀원 A(매니저) 또는 사용자가 배정한 업무를 직접 수행
- Mutual Lock · 팀 로그 규칙을 예외 없이 준수
- 본인 로그(`team-<X>.md`) 에만 append, 다른 팀원 로그는 수정 금지
- 블로커 발생 시 팀 로그에 `BLOCKER` 이벤트 기록 + 사용자(필요 시 매니저 A) 에게 보고

---

## 🔧 이 스킬이 제공하는 명령

### `/team:worker` — 팀원 에이전트

사용자·매니저가 개별 팀원(A·B·C·D·E·F)에게 업무를 지시할 때 사용합니다. 팀원은:

1. 본인 식별자 확정
2. 업무 분해 + TodoWrite 등록
3. Lock 불필요 태스크는 즉시 실행, Lock 필요 태스크는 Mutual Lock 프로토콜 준수
4. 모든 이벤트(TASK_START / LOCK_WAIT / LOCK_ACQUIRE / LOCK_RELEASE / TASK_PROGRESS / TASK_DONE / BLOCKER / NOTE / HANDOFF) 를 팀 로그에 기록
5. 완료 기준 충족 여부를 검증한 뒤 사용자에게 보고 (매니저 A 는 보고를 모니터링 채널로도 흡수)

자세한 절차·금지 사항·에러 대응은 `commands/worker.md` 참조.

### `/team:update` — 팀 모니터링 (팀 매니저 상시 조회용)

팀 매니저(팀원 A) 와 사용자가 팀 전체 현황을 빠르게 파악할 때 사용하는 **읽기 전용** 조회 도구 입니다. 서브커맨드:

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

이 명령은 **코드·Lock·로그를 수정하지 않습니다**. 매니저 A 가 수집한 정보를 바탕으로 분석·팁을 제공하고, 지시는 사용자 또는 매니저 A 가 개별 팀원에게 직접 내립니다.

자세한 출력 형식·금지 사항은 `commands/update.md` 참조.

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
│           ├── team-A.md          # 팀원 A (매니저) 개인 로그
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
5. **팀원 A 는 매니저** — 업무 분배·모니터링·팁·분석을 수행하되, 팀원에 대한 지시 권한은 사용자의 권한을 위임받은 범위 내에서만
6. **Lock 대기 중 idle 금지** — 반드시 Lock 불필요 병행 작업 수행 (코드 리팩터링·타입체크·CLI 검증 등)
7. **한국어 기록** — 파일 경로·명령어·식별자만 영문 원문, 설명은 한국어

---

## 🧭 언제 이 스킬을 사용할 것인가

- 동일 프로젝트를 여러 Claude 세션(팀원 A·B·C·…) 이 병렬로 작업하는 환경
- Chrome DevTools MCP 또는 Playwright MCP 를 호출해야 하지만 다른 세션과 충돌이 우려될 때
- 팀원 간 작업 진행·블로커·Handoff 를 실시간으로 관찰하고자 할 때
- 팀원 A 로서 팀 전체 현황을 모니터링하고 분석·팁을 제공해야 할 때
- 개별 팀원으로서 업무를 수행하며 Mutual Lock 프로토콜을 따라야 할 때

---

## 🔗 상세 문서

- `commands/worker.md` — `/team:worker` 팀원 에이전트 전체 절차, Mutual Lock 프로토콜, 팀 로그 기록 의무, 보고 서식
- `commands/update.md` — `/team:update` 모니터링 명령 서브커맨드 상세, 읽기 전용 원칙, 팀 매니저(A) 활용법
