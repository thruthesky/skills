---
description: 팀 모니터링 명령 — 한 팀의 팀원(A·B·C·D·E·F)의 업무 로그·Mutual Lock 상태·진행 현황을 한눈에 조회한다. 팀 매니저(팀원 A) 와 사용자가 "지금 누가 뭘 하고 있는가" 를 파악하여 업무 분배·팁·분석·모니터링을 수행할 때 사용한다.
argument-hint: <서브커맨드> [옵션]  —  예: status | logs [팀원] | tail [N] | who | brief [팀원] | lock | stop-loop | cleanup
allowed-tools: Bash, Read, Glob, Grep
---

# /team:update — 팀 모니터링 보조 명령

이 명령은 **한 팀** 에서 팀 매니저(팀원 A) 와 사용자가 팀 전체 현황을 1 초 만에 파악할 수 있도록 돕는 **읽기 전용 상태 조회 도구**다. 팀원들은 이미 `tools/team/log.sh` 로 본인 활동을 `.dev/team/logs/` 에 기록하고 있고, Lock 스크립트는 `.dev/*-mcp.lock` 에 점유 상태를 남기고 있다. 본 명령은 이 파일들을 읽어 요약·필터·타임라인 형태로 보여 준다.

## 🧭 설계 원칙

1. **읽기 전용**. 코드·Lock·로그를 **수정하지 않는다**. Lock force-release, 로그 수정, 커밋 모두 금지.
2. **지시는 사용자 또는 팀 매니저(A) 만**. 이 명령은 팀 매니저 A 의 에이전트가 아니다 — 단지 A 와 사용자가 쓰는 조회 도구이다. 명령 자체가 "팀원에게 지시" 하지 않으며, 결과 해석과 분배·배정 결정은 사람(사용자) 또는 팀 매니저(A) 가 직접 수행한다.
3. **지시서 수정 금지**. `.dev/teams/team-<X>-brief.md` 에 append 하지 않는다 (브리프 갱신은 사용자·매니저 A 의 명시적 지시 시에만 별도 경로로).
4. **한국어 출력** (CLAUDE.md 규칙). 식별자·파일 경로·명령어만 영문 원문.

## 👥 주 사용자 — 팀 매니저(팀원 A) 와 사용자

이 명령의 주 사용자는 **팀 매니저(팀원 A)** 와 **사용자** 입니다.

- **팀 매니저(팀원 A)** 는 `/team:update` 를 상시 활용하여 팀원 B·C·D·E·F 의 작업 패턴·진행 속도·블로커를 관찰하고, "누가 무엇을 잘 하고 있는지" 에 대한 팁·분석을 생산합니다. 분석 결과는 사용자에게 보고하거나 팀원별 로그(`team-<X>.md`) 를 관찰한 뒤 필요 시 NOTE 이벤트로 공유합니다.
- **사용자** 는 특정 팀원에게 업무를 직접 지시할지, 매니저 A 에게 위임할지 결정할 때 본 명령의 출력을 근거로 삼습니다.
- 팀원 B~F 도 본 명령을 조회할 수 있으나, 그 결과로 다른 팀원에게 지시하지 않습니다 (Peer 간 지시 금지).

## 🗣️ 팀원 식별자

사용자가 `Alpha`/`Beta`/`Charlie`/`Delta`/`Echo`/`Foxtrot` 별명을 써도 내부적으로 단일 문자 (`A`/`B`/`C`/`D`/`E`/`F`) 로 정규화한다. 명령 출력·grep 인자는 항상 단일 문자 사용.

---

## 서브커맨드

`$ARGUMENTS` 로 다음 중 하나를 받는다. 없으면 `status` 로 동작.

### ① `status` (기본) — 팀 전체 현황 요약

수행:

1. **Lock 상태** — `tools/lock/chrome-mcp-lock.sh status` 실행 (두 subject)
2. **최근 활동** — `tail -n 15 .dev/team/logs/activity.log` (공용 타임라인)
3. **팀원별 로그 존재 여부** — `ls -la .dev/team/logs/team-*.md`
4. **팀원별 마지막 이벤트** — 각 `team-<X>.md` 의 최하단 `## ` 섹션 1건
5. **현재 블로커** — `grep ' BLOCKER ' .dev/team/logs/activity.log | tail -n 5`
6. **대기 중인 Handoff** — `grep ' HANDOFF ' .dev/team/logs/activity.log | tail -n 5`
7. **변경된 파일** — `git status --short`
8. **브리프 최종 수정 시각** — `ls -la .dev/teams/team-*-brief.md`

출력 형식:

```markdown
## 👥 팀원 현황 (<YYYY-MM-DD HH:MM>)

| 팀원 | 마지막 이벤트 | 시각 | 활성 여부 |
|---|---|---|---|
| A | TASK_DONE A6 | 21:45 | 🟢 방금 |
| B | LOCK_ACQUIRE chrome | 21:42 | 🟢 작업 중 |
| C | — (로그 없음) | — | ⚪ 미시작 |
| D | BLOCKER D3 | 20:12 | 🔴 블로커 |

## 🔒 Mutual Lock
- chrome:     B 보유 중 (21:42~, 경과 N분)
- playwright: FREE

## 🔁 최근 타임라인 (15건)
<tail activity.log>

## ⛔ 블로커 (최근 5건)
<grep BLOCKER>

## 🤝 Handoff 대기 (최근 5건)
<grep HANDOFF>

## 📝 Git 변경 파일
<git status --short>

## 📂 브리프 최종 수정
- team-A-brief.md: 2026-04-17 22:15
- team-B-brief.md: 2026-04-17 21:54
- ...
```

### ② `logs [팀원]` — 개인 로그 전문 또는 전체 팀원 최근 로그

- **인자 없음** → 모든 팀원 로그 파일의 마지막 5 섹션씩 요약 출력
- **`logs A`** (또는 `logs Alpha`) → `cat .dev/team/logs/team-A.md` 전체

### ③ `tail [N]` — 공용 타임라인 꼬리

- `tail` → `tail -n 30 .dev/team/logs/activity.log`
- `tail 50` → `tail -n 50 .dev/team/logs/activity.log`
- `tail -f` 처럼 실시간 팔로우는 사용자가 셸에서 직접 하도록 안내 (본 명령은 1 회 조회)

### ④ `who` — 현재 누가 뭘 하고 있나 (1줄 요약)

수행:

1. 각 팀원별로 `activity.log` 에서 마지막 `TASK_START`~`TASK_DONE` 쌍 분석
2. 현재 `in_progress` 로 추정되는 태스크 추출
3. 현재 Lock 보유자와 매칭

출력:

```markdown
## 👤 현재 활동 팀원

| 팀원 | 현재 태스크 | Lock | 시작 | 경과 |
|---|---|---|---|---|
| A | — (대기) | — | — | — |
| B | B3 NPC AI 틱 | chrome | 21:42 | 8분 |
| C | C1 카메라 튜닝 | — | 21:30 | 20분 |
| D | 🔴 BLOCKER D3 | — | 20:12 | — |
```

### ⑤ `lock` — Mutual Lock 심층 상태 + 최근 Lock 타임라인

수행:

1. `tools/lock/chrome-mcp-lock.sh status` (두 subject)
2. `.dev/chrome-mcp-lock.log` 최근 20줄 (스크립트 자체 로그)
3. `grep -E ' LOCK_' .dev/team/logs/activity.log | tail -n 20` (팀원 로그 측 관점)
4. 보유 시간이 15분 이상인 subject 가 있으면 🚨 **Stale 경고** 와 함께 표시 (단, `force-release` 는 제안만, 자동 실행 금지)

출력에 **"Chrome 과 Playwright 는 독립 subject 이며 동시에 한 팀원만 점유"** 원칙을 상기시키는 짧은 안내 포함.

### ⑥ `brief [팀원]` — 팀원 브리프 전문 출력

- **인자 없음** → `.dev/teams/team-*-brief.md` 파일 목록 + 각 파일 최신 섹션 제목 3개
- **`brief A`** → `cat .dev/teams/team-A-brief.md` 전체 (읽기 전용, 수정 금지)

### ⑦ `stop-loop` — 무한 반복 / Ralph Loop 차단 안내

수행:

1. `.claude/ralph-loop.local.md` 존재 여부 확인
2. `.claude/settings.json` · `.claude/settings.local.json` 의 `hooks.Stop` 점검
3. 진단 결과만 출력 (자동 cancel 실행 금지). 사용자에게 `/ralph-loop:cancel-ralph` 호출 또는 `update-config` 스킬로 hook 조정을 안내

### ⑧ `cleanup` — 오래된 로그 아카이빙 안내 (실행은 사용자 승인 후)

수행:

1. `activity.log` 가 10,000 줄 초과 시 경고
2. `.dev/team/logs/team-<X>.md` 중 48 시간 이상 수정되지 않은 파일 목록
3. 아카이브 제안만 출력 (`mv activity.log archive/activity-<YYYYMMDD>.log` 등). **자동 이동·삭제 금지**. 사용자 승인 후에만 수동 실행

---

## 🔒 본 명령이 절대 하지 않는 것

1. ❌ 코드 수정, Edit/Write 호출
2. ❌ Lock `acquire` / `release` / `force-release`
3. ❌ `activity.log`, `team-<X>.md`, `team-<X>-brief.md` 에 write/append (팀원 본인만 append)
4. ❌ 팀원에게 지시 전달 — 지시는 **사용자 또는 팀 매니저(팀원 A)** 가 개별 팀원에게 직접 내린다. 본 명령은 지시 생성·대리 전달을 하지 않는다
5. ❌ `git commit`, `git push`, PR 조작
6. ❌ Ralph Loop / Stop hook 을 강제 해제 (사용자 승인 후 정식 경로로만)
7. ❌ MCP (`chrome-devtools` / `playwright`) 호출 — Lock 정보는 파일에서만 읽는다

---

## 📝 출력 형식 공통 규칙

- 한국어
- 마크다운 표·섹션 헤더 활용 (사용자가 한눈에 스캔)
- 시각은 `YYYY-MM-DD HH:MM` 또는 `HH:MM` (오늘자)
- 팀원은 **"팀원 A" / "팀원 B"** 호칭 (팀 아님)
- 긴 로그 원문은 ` ``` ` 코드 블록
- 민감 정보가 로그에 섞여 있으면 경고 출력 (단, 자동 삭제는 금지)

---

## 업무 컨텍스트

사용자가 이번 호출에 전달한 인자:

```
$ARGUMENTS
```

위 인자를 파싱하여 해당 서브커맨드를 수행한다. 인자가 비어 있으면 `status` 로 동작한다. 어떤 서브커맨드든 **읽기 전용** 원칙을 지키며, 결과를 한국어로 깔끔하게 출력한 뒤 종료한다. 추가 지시·판단·수정은 하지 않는다 — 해석·분석은 팀 매니저(팀원 A) 가, 지시는 사용자 또는 팀 매니저(A) 가 수행한다.
