---
description: 팀 모니터링 명령 — 한 팀의 팀원(A·B·C·D·E·F)의 업무 로그·Mutual Lock 상태·진행 현황을 한눈에 조회한다. 사용자(그리고 사용자가 `/team:manage` 로 기동한 매니저 세션)가 "지금 누가 뭘 하고 있는가" 를 파악하는 **읽기 전용** 조회 도구다. 팀원 A 는 더 이상 매니저가 아니므로, 본 명령이 자동으로 매니저 역할을 수행하지 않으며 단순 상태 덤프만 제공한다. 분석·제안·분배는 사용자 또는 `/team:manage` 매니저 세션이 별도로 수행한다.
argument-hint: <서브커맨드> [옵션]  —  예: status | logs [팀원] | tail [N] | who | brief [팀원] | lock | stop-loop | cleanup
allowed-tools: Bash, Read, Glob, Grep
---

# /team:update — 팀 모니터링 보조 명령

이 명령은 **한 팀** 에서 사용자(그리고 기동된 매니저 세션) 가 팀 전체 현황을 1 초 만에 파악할 수 있도록 돕는 **읽기 전용 상태 조회 도구**다. 팀원들은 이미 `tools/team/log.sh` 로 본인 활동을 `.dev/team/logs/` 에 기록하고 있고, Lock 스크립트는 `.dev/*-mcp.lock` 에 점유 상태를 남기고 있다. 본 명령은 이 파일들을 읽어 요약·필터·타임라인 형태로 보여 준다.

## 🧭 설계 원칙

1. **읽기 전용**. 코드·Lock·로그를 **수정하지 않는다**. Lock force-release, 로그 수정, 커밋 모두 금지.
2. **지시는 사용자만**. 이 명령은 어떤 팀원의 에이전트도 아니다 — 단지 사용자가 쓰는 조회 도구이다. 명령 자체가 "팀원에게 지시" 하지 않으며, 결과 해석과 분배·배정 결정은 사용자가 직접 수행한다 (사용자가 `/team:manage` 로 매니저 세션을 기동한 경우 그 세션이 해석·제안을 생산하되, 지시는 여전히 사용자).
3. **지시서 수정 금지**. `.dev/teams/team-<X>-brief.md` 에 append 하지 않는다 (브리프 갱신은 사용자의 명시적 지시 시에만 별도 경로로).
4. **한국어 출력** (CLAUDE.md 규칙). 식별자·파일 경로·명령어만 영문 원문.

## 👥 주 사용자 — 사용자와 매니저 세션 (선택적)

이 명령의 주 사용자는 **사용자** 이며, 사용자가 `/team:manage` 로 기동한 **매니저 세션** 도 내부 분석용으로 본 명령을 활용할 수 있습니다.

- **사용자** 는 `/team:update` 로 팀 현황을 확인하여 특정 팀원에게 업무를 직접 지시할지, `/team:manage` 로 매니저 세션을 열어 분배 제안을 받을지 결정합니다.
- **매니저 세션** (`/team:manage` 로 기동된 경우) 은 `/team:update` 와 동일한 정보원을 읽어 분석·제안을 생산합니다. 단, 분석 로직은 매니저 세션의 책임이며 `/team:update` 는 **원본 데이터 덤프** 에 머뭅니다.
- **모든 팀원(A·B·C·D·E·F)** 도 본 명령을 조회할 수 있으나, 그 결과로 다른 팀원에게 지시하지 않습니다 (Peer 간 지시 금지). 팀원 A 도 여기에 포함됩니다 — 더 이상 매니저가 아닙니다.

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

## 💡 관찰된 이슈 (있으면)
<아래 "관찰된 이슈 섹션 작성 규칙" 을 따라 관찰된 맥락에 맞는 간단한 알림 0~N개>
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
4. ❌ 팀원에게 지시 전달 — 지시는 **사용자** 만 개별 팀원에게 직접 내린다 (사용자가 `/team:manage` 로 기동한 매니저 세션이 사용자의 명시적 위임을 받은 경우에만 대행 가능). 본 명령은 지시 생성·대리 전달을 하지 않는다
5. ❌ 분석·제안·판단 — 본 명령은 원본 데이터 덤프에 한정. 분석·제안이 필요하면 사용자가 `/team:manage` 를 별도로 호출
6. ❌ `git commit`, `git push`, PR 조작
7. ❌ Ralph Loop / Stop hook 을 강제 해제 (사용자 승인 후 정식 경로로만)
8. ❌ MCP (`chrome-devtools` / `playwright`) 호출 — Lock 정보는 파일에서만 읽는다

---

## 📝 출력 형식 공통 규칙

- 한국어
- 마크다운 표·섹션 헤더 활용 (사용자가 한눈에 스캔)
- 시각은 `YYYY-MM-DD HH:MM` 또는 `HH:MM` (오늘자)
- 팀원은 **"팀원 A" / "팀원 B"** 호칭 (팀 아님)
- 긴 로그 원문은 ` ``` ` 코드 블록
- 민감 정보가 로그에 섞여 있으면 경고 출력 (단, 자동 삭제는 금지)

---

## 💡 관찰된 이슈 섹션 작성 규칙

`status` · `who` · `lock` 서브커맨드 결과 말미에는 **관찰된 이슈** 섹션을 포함한다. 이 섹션은 **원본 로그·파일에서 기계적으로 감지 가능한 이슈** 를 나열하는 것이며, **심층 분석·전략적 제안·업무 분배 제안은 생산하지 않는다** (그런 해석은 `/team:manage` 매니저 세션 또는 사용자 본인의 몫).

### 포함해야 할 이슈 카테고리 (실제 감지된 경우에만)

1. **인프라 부재** — `tools/team/`, `tools/lock/`, `.dev/team/logs/` 중 하나라도 없으면 한 줄로 알림. 도입 여부 결정은 사용자에게 일임
   - 예: "팀 협업 인프라(`tools/team/`, `tools/lock/`, `.dev/team/logs/`) 일부/전부 부재. 도입 여부는 사용자 결정 사항."

2. **블로커 이벤트 존재** — `BLOCKER` 이벤트가 최근 기록되어 있으면 해당 팀원·태스크 ID 를 그대로 표시
   - 예: "팀원 D 가 D3 태스크에서 BLOCKER 이벤트 기록 (20:12). 내용 확인 필요."

3. **미커밋 변경 존재** — `git status --short` 에 변경 파일이 있으면 파일 목록만 나열 (맥락 관련성 판단은 하지 않음)
   - 예: "미커밋 변경 3개: `pages/recent-posts.php`, `lib/auth.ts`, `tests/login.spec.ts`. 커밋/discard 판단은 사용자."

4. **Lock 장기 보유 경고** — 특정 subject 를 15 분 이상 동일 팀원이 보유 중이면 사실만 보고. force-release 여부는 사용자 결정
   - 예: "chrome Lock: 팀원 B 가 28 분째 보유 중 (stale 임계 15분 초과). force-release 여부는 사용자 결정."

5. **로그 누락 감지** — `LOCK_ACQUIRE` 에 대응하는 `LOCK_RELEASE` 가 없거나, `TASK_START` 만 있고 60 분 넘게 `TASK_PROGRESS`/`TASK_DONE` 이 없는 경우 감지만 보고
   - 예: "팀원 C: LOCK_ACQUIRE chrome (21:10) 후 LOCK_RELEASE 없음 (경과 48분). 본인 확인 필요."

### 작성 원칙

- 이슈 수는 **0 ~ N 개**. 감지된 것이 없으면 "관찰된 이슈 없음" 으로 표시
- 한 이슈 = **한 문장**. 사실(fact) 기반, 해석·조언 최소화
- 이슈 끝에 **결정 주체가 사용자임** 을 명시 (`… 판단은 사용자`, `… 결정은 사용자`)
- 자동 실행·지시 금지 (본 명령의 읽기 전용 원칙 유지)
- **심층 분석·분배 제안·팁 생산은 하지 않음** — 그런 해석이 필요하면 사용자가 `/team:manage` 를 별도 호출하도록 안내

### 출력 예시

```markdown
## 💡 관찰된 이슈
- **인프라 부재**: 팀 협업 인프라(`tools/team/`, `tools/lock/`, `.dev/team/logs/`) 일부 부재. 도입 여부는 사용자 결정 사항.
- **블로커**: 팀원 D 가 D3 태스크에서 BLOCKER 이벤트 기록 (20:12). 내용 확인 필요.
- **미커밋 변경**: `pages/recent-posts.php` 수정. 커밋/discard 판단은 사용자.

_심층 분석·분배 제안이 필요하면 `/team:manage` 를 호출하세요._
```

---

## 업무 컨텍스트

사용자가 이번 호출에 전달한 인자:

```
$ARGUMENTS
```

위 인자를 파싱하여 해당 서브커맨드를 수행한다. 인자가 비어 있으면 `status` 로 동작한다. 어떤 서브커맨드든 **읽기 전용** 원칙을 지키며, 결과를 한국어로 깔끔하게 출력한 뒤 종료한다. 추가 지시·판단·수정은 하지 않는다 — 해석·분석은 사용자가 직접 수행하거나 `/team:manage` 매니저 세션이 별도로 생산하며, 지시는 오직 사용자가 내린다. 팀원 A 는 더 이상 매니저가 아니므로, 본 명령이 "매니저 관점의 팁" 을 자동 생산하지 않는다.
