# thruthesky/skills — AI 에이전트 스킬 모음

- **저장소:** https://github.com/thruthesky/skills
- **Git 주소:** `https://github.com/thruthesky/skills.git`
- **스킬 폴더:** `https://github.com/thruthesky/skills/tree/main/skills/<스킬 이름>`

이 저장소의 스킬 12개는 모두 **표준 Agent Skills** 형식이다. 그래서 Claude Code 에 국한하지 않고, Codex·Gemini CLI·GitHub Copilot CLI 처럼 Agent Skills 를 읽는 **모든 에이전트 도구**에 설치할 수 있다. Claude Code 에서는 플러그인 마켓플레이스 `thruthesky-skills` 로도 설치할 수 있어 업데이트가 쉽다.

**가장 쉬운 설치:** §4 에서 원하는 스킬의 글 상자를 복사해(코드 상자 오른쪽 위 복사 단추) 에이전트 도구의 대화창에 붙여 넣고 전송한다. 에이전트가 자기 도구에 맞게 설치하고 결과를 알려 준다.

## 1. 표준 에이전트 스킬(Agent Skills)이란

에이전트에게 새 일을 가르치는 **열린 표준**이다(명세: https://agentskills.io/specification). 스킬 하나는 **폴더 하나**이고, 그 안에 `SKILL.md` 가 반드시 있다.

```
<스킬 이름>/
├─ SKILL.md        ← 필수. YAML 앞머리(name·description) + 지침 본문
├─ scripts/        ← 선택. 에이전트가 실행하는 코드
├─ references/     ← 선택. 필요할 때 읽는 문서
└─ assets/         ← 선택. 템플릿·스키마 같은 자료
```

| 앞머리 | 규칙 |
|--------|------|
| `name` | 필수. 소문자·숫자·하이픈, 64자 이내. **폴더 이름과 같아야 한다** |
| `description` | 필수. 1024자 이내. 무엇을 하는지와 언제 쓰는지. 에이전트는 이 글을 보고 스킬을 고른다 |
| `license` · `compatibility` · `metadata` · `allowed-tools` | 선택 |

- **점진적으로 읽힌다.** 에이전트는 시작할 때 모든 스킬의 `name`·`description` 만 읽는다. 일이 맞으면 `SKILL.md` 본문을 읽고, 필요할 때만 `references/`·`scripts/` 를 연다. 스킬을 많이 설치해도 대화가 무거워지지 않는다.
- **설치는 폴더를 복사하는 것뿐이다.** 도구가 읽는 스킬 폴더에 스킬 폴더를 통째로 넣으면 된다. 파일 안의 경로는 스킬 폴더 기준 상대 경로라서 어디에 넣어도 동작한다.

| 도구 | 사용자 스킬 폴더 (모든 프로젝트) | 프로젝트 스킬 폴더 | 설치 뒤 반영 |
|------|------|------|------|
| Claude Code | `~/.claude/skills` (플러그인 설치도 된다 — §2.2) | `.claude/skills` | 바로 잡힌다. 대화를 시작할 때 폴더가 없었으면 `/reload-skills` |
| Codex | `~/.agents/skills` | `.agents/skills` | 자동으로 잡힌다. 안 보이면 다시 시작 |
| Gemini CLI | `~/.agents/skills` (또는 `~/.gemini/skills`) | `.agents/skills` (또는 `.gemini/skills`) | `/skills reload` |
| GitHub Copilot CLI | `~/.agents/skills` (또는 `~/.copilot/skills`) | `.agents/skills` (또는 `.github/skills`) | `/skills reload` |
| 그 밖의 도구 | 그 도구가 안내하는 스킬 폴더 (`~/.agents/skills` 를 읽는 도구가 많다) | 그 도구의 프로젝트 스킬 폴더 | 그 도구의 안내를 따른다 |

`~/.agents/skills` 는 여러 도구가 함께 읽는 공용 폴더다. Claude Code 만 이 폴더를 읽지 않는다.

**이 저장소의 약속:**

- `skills/<스킬 이름>/` 폴더 하나가 스킬 하나다. `SKILL.md` 는 그 폴더 바로 아래에 있고, `name` 은 폴더 이름과 같다.
- `commands/*.md` 는 Claude Code 전용 명령이다. 다른 도구는 `SKILL.md` 를 읽는다.
  - 명령만 있던 8개 스킬(currency-skill·data-skill·dokploy-skill·flutter-skill·harness·open-meteo-skill·skill-creator·waf)은 `SKILL.md` 가 본문인 `commands/<명령>.md` 를 읽으라고 안내한다.
- `.claude-plugin/plugin.json` 은 Claude Code 플러그인 정보다. 다른 도구는 무시한다.

## 2. 설치 방법

### 2.1 에이전트에게 맡기기 (권장)

§4 의 스킬별 글 상자를 복사해 에이전트 도구에 붙여 넣고 전송한다.

- Claude Code 면 플러그인으로 설치한다.
- 그 밖의 도구면 스킬 폴더로 받는다.
- 이미 설치돼 있으면 최신으로 바꾼다.

### 2.2 Claude Code — 플러그인

대화창에서 실행한다. `<플러그인>` 은 §3 표의 플러그인 이름이다.

```text
/plugin marketplace add thruthesky/skills
/plugin install <플러그인>@thruthesky-skills
```

터미널에서는 `claude plugin marketplace add thruthesky/skills` → `claude plugin install <플러그인>@thruthesky-skills` 다. 설치한 뒤 Claude Code 를 다시 시작하면 잡힌다.

### 2.3 모든 도구 — 스킬 폴더로 직접

`SKILL` 에 스킬 이름(§3 표의 폴더 이름), `DIR` 에 도구의 스킬 폴더(§1 표)를 넣고 실행한다. 저장소 묶음(1MB 미만)을 받아 그 스킬 폴더만 푼다.

```bash
SKILL=api-skill; DIR=~/.agents/skills
mkdir -p "$DIR" && rm -rf "$DIR/$SKILL" && curl -fsSL https://codeload.github.com/thruthesky/skills/tar.gz/refs/heads/main | tar -xz -C "$DIR" --strip-components=2 "skills-main/skills/$SKILL"
```

git 으로 받으려면:

```bash
git clone --depth 1 https://github.com/thruthesky/skills.git /tmp/thruthesky-skills && cp -R /tmp/thruthesky-skills/skills/$SKILL "$DIR/"
```

Windows PowerShell:

```powershell
$SKILL = "api-skill"; $DIR = "$HOME\.agents\skills"
New-Item -ItemType Directory -Force $DIR | Out-Null
curl.exe -fsSL https://codeload.github.com/thruthesky/skills/tar.gz/refs/heads/main -o "$env:TEMP\skills.tar.gz"
Remove-Item -Recurse -Force "$DIR\$SKILL" -ErrorAction SilentlyContinue
tar -xzf "$env:TEMP\skills.tar.gz" -C $DIR --strip-components=2 "skills-main/skills/$SKILL"
```

### 2.4 한 프로젝트에서만 쓰기

- Claude Code: `marketplace add` 와 `install` 에 `--scope project` 를 붙인다. 프로젝트의 `.claude/settings.json` 에 기록돼, 그 저장소를 여는 사람에게도 설치를 권한다.
- 그 밖의 도구: `DIR` 을 프로젝트의 스킬 폴더(`.agents/skills` 등, §1 표)로 바꾼다.

## 3. 스킬 목록

| 스킬 (폴더 · GitHub 경로) | 하는 일 | Claude Code 플러그인 · 부르기 |
|------|------|------|
| [`api-skill`](https://github.com/thruthesky/skills/tree/main/skills/api-skill) | 필리핀 여행 정보 API(198곳·8개 언어) — 여행 질문 답하기, 웹·앱에 넣기(SQLite·PHP·Flutter·렌더러), 여행지 추가·번역·배포 | `api-skill@thruthesky-skills` · `/api-skill:api-skill` |
| [`cowork`](https://github.com/thruthesky/skills/tree/main/skills/cowork) | 여러 AI(claude·codex·kimi·Copilot CLI·agy) 교차 분석 — "cowork" 라고 직접 부를 때만 동작 | `cowork@thruthesky-skills` · `/cowork:cowork` · `/cowork:init` |
| [`currency-skill`](https://github.com/thruthesky/skills/tree/main/skills/currency-skill) | Frankfurter API 로 환율 조회·통화 변환 (ECB 데이터, API 키 불필요) | `currency-skill@thruthesky-skills` · `/currency-skill:exchange` |
| [`data-skill`](https://github.com/thruthesky/skills/tree/main/skills/data-skill) | 대한민국 공공데이터포털(data.go.kr) API 사용 | `data-skill@thruthesky-skills` · `/data-skill:query` |
| [`dev`](https://github.com/thruthesky/skills/tree/main/skills/dev) | 명세(`.dev/`) 기반 개발 — copy·plan·execute·list·refactor·review | `dev@thruthesky-skills` · `/dev:dev` · `/dev:plan` 등 |
| [`dokploy-skill`](https://github.com/thruthesky/skills/tree/main/skills/dokploy-skill) | Dokploy 셀프호스팅 PaaS 관리 — 앱 배포·Docker Compose·DB·Traefik·SSL·백업 | `dokploy-skills@thruthesky-skills` · `/dokploy-skills:manage` |
| [`flutter-skill`](https://github.com/thruthesky/skills/tree/main/skills/flutter-skill) | Flutter 앱 개발 지침 — UI/UX·상태관리·네트워킹·API 연동 | `flutter-skill@thruthesky-skills` · `/flutter-skill:develop` |
| [`harness`](https://github.com/thruthesky/skills/tree/main/skills/harness) | Harness 방식 에이전트 문서 세트(짧은 AGENTS.md + docs/) 만들기 | `harness-skill@thruthesky-skills` · `/harness-skill:generate` |
| [`open-meteo-skill`](https://github.com/thruthesky/skills/tree/main/skills/open-meteo-skill) | Open-Meteo 날씨·대기질·해양·위치 검색 API (API 키 불필요) | `open-meteo-skill@thruthesky-skills` · `/open-meteo-skill:weather` |
| [`skill-creator`](https://github.com/thruthesky/skills/tree/main/skills/skill-creator) | 스킬 만들기·고치기·평가·설명 최적화 | `skill-creator@thruthesky-skills` · `/skill-creator:create` |
| [`team`](https://github.com/thruthesky/skills/tree/main/skills/team) | 여러 세션 협업 — 브라우저 MCP 상호 배타 잠금·git·팀 로그 | `team@thruthesky-skills` · `/team:team` · `/team:work` 등 |
| [`waf`](https://github.com/thruthesky/skills/tree/main/skills/waf) | Cloudflare WAF 로 막힌 사이트의 브라우저 자동화 (PHP PEST + ChromeDriver) | `waf-skill@thruthesky-skills` · `/waf-skill:bypass` |

Codex 에서는 `$<스킬 이름>` 으로 부른다. 그 밖의 도구는 스킬 이름을 적거나 할 일을 말하면 에이전트가 `description` 을 보고 고른다.

## 4. 스킬별 설치 — 복사해서 에이전트에 붙여 넣기

각 글 상자를 통째로 복사해 에이전트 도구(Claude Code·Codex·Gemini CLI·Copilot CLI 등)의 대화창에 붙여 넣고 전송한다. 한 프로젝트에서만 쓰려면 §2.4 처럼 두 곳을 바꾼다.

### 4.1 api-skill

필리핀 여행 정보 API(198곳·8개 언어) — 여행 질문 답하기, 웹·앱에 넣기(SQLite·PHP·Flutter·렌더러), 여행지 추가·번역·배포

- 경로: https://github.com/thruthesky/skills/tree/main/skills/api-skill
- SKILL.md: https://github.com/thruthesky/skills/blob/main/skills/api-skill/SKILL.md
- 부르기: Claude Code `/api-skill:api-skill` · Codex `$api-skill` · 그 밖의 도구는 스킬 이름을 적거나 할 일을 말하면 에이전트가 고른다

```text
thruthesky/skills 저장소의 api-skill 스킬을 설치해 줘.
스킬 경로: https://github.com/thruthesky/skills/tree/main/skills/api-skill — 표준 Agent Skills 형식(폴더 안에 SKILL.md)이다.

1. 네가 Claude Code 면 플러그인으로 설치한다. 터미널에서 차례로 실행한다.
   claude plugin marketplace add thruthesky/skills
   claude plugin marketplace update thruthesky-skills
   claude plugin install api-skill@thruthesky-skills
   - 이미 설치돼 있으면 마지막 줄 대신 claude plugin update api-skill@thruthesky-skills 를 실행한다.
2. 그 밖의 에이전트 도구면 네 도구의 사용자 스킬 폴더를 DIR 로 정한다.
   - Codex·Gemini CLI·GitHub Copilot CLI 는 DIR=~/.agents/skills 다. 다른 도구면 그 도구가 SKILL.md 를 읽는 스킬 폴더를 쓴다.
   - 아래 명령으로 받는다. 이미 있던 api-skill 폴더는 지우고 새로 받는다.
   mkdir -p DIR && rm -rf DIR/api-skill && curl -fsSL https://codeload.github.com/thruthesky/skills/tar.gz/refs/heads/main | tar -xz -C DIR --strip-components=2 skills-main/skills/api-skill
   - Windows PowerShell 이면 curl.exe 로 임시 파일에 받은 뒤 tar -xzf 로 같은 경로만 DIR 에 푼다.
3. 설치를 확인한다. Claude Code 는 claude plugin list 에서 api-skill@thruthesky-skills 를, 그 밖의 도구는 DIR/api-skill/SKILL.md 의 앞머리 name 이 api-skill 인지 본다.
4. 스킬의 조회 도구는 Node 24 가 필요하다(내장 SQLite 의 FTS5). node -v 로 확인하고, 낮으면 알려만 준다.
5. 설치 방법·경로·버전을 보고하고, 이 도구에서 스킬을 쓰는 방법(부르는 이름, 다시 시작이나 다시 읽기)을 알려 준다.
```

### 4.2 cowork

여러 AI(claude·codex·kimi·Copilot CLI·agy) 교차 분석 — "cowork" 라고 직접 부를 때만 동작

- 경로: https://github.com/thruthesky/skills/tree/main/skills/cowork
- SKILL.md: https://github.com/thruthesky/skills/blob/main/skills/cowork/SKILL.md
- 부르기: Claude Code `/cowork:cowork` · `/cowork:init` · Codex `$cowork` · 그 밖의 도구는 스킬 이름을 적거나 할 일을 말하면 에이전트가 고른다

```text
thruthesky/skills 저장소의 cowork 스킬을 설치해 줘.
스킬 경로: https://github.com/thruthesky/skills/tree/main/skills/cowork — 표준 Agent Skills 형식(폴더 안에 SKILL.md)이다.

1. 네가 Claude Code 면 플러그인으로 설치한다. 터미널에서 차례로 실행한다.
   claude plugin marketplace add thruthesky/skills
   claude plugin marketplace update thruthesky-skills
   claude plugin install cowork@thruthesky-skills
   - 이미 설치돼 있으면 마지막 줄 대신 claude plugin update cowork@thruthesky-skills 를 실행한다.
2. 그 밖의 에이전트 도구면 네 도구의 사용자 스킬 폴더를 DIR 로 정한다.
   - Codex·Gemini CLI·GitHub Copilot CLI 는 DIR=~/.agents/skills 다. 다른 도구면 그 도구가 SKILL.md 를 읽는 스킬 폴더를 쓴다.
   - 아래 명령으로 받는다. 이미 있던 cowork 폴더는 지우고 새로 받는다.
   mkdir -p DIR && rm -rf DIR/cowork && curl -fsSL https://codeload.github.com/thruthesky/skills/tar.gz/refs/heads/main | tar -xz -C DIR --strip-components=2 skills-main/skills/cowork
   - Windows PowerShell 이면 curl.exe 로 임시 파일에 받은 뒤 tar -xzf 로 같은 경로만 DIR 에 푼다.
3. 설치를 확인한다. Claude Code 는 claude plugin list 에서 cowork@thruthesky-skills 를, 그 밖의 도구는 DIR/cowork/SKILL.md 의 앞머리 name 이 cowork 인지 본다.
4. 이 스킬은 claude·codex·kimi·copilot·agy CLI 를 불러 쓴다. 각 명령이 설치돼 있는지 확인하고, 없는 것을 알려 준다.
5. 설치 방법·경로·버전을 보고하고, 이 도구에서 스킬을 쓰는 방법(부르는 이름, 다시 시작이나 다시 읽기)을 알려 준다.
```

### 4.3 currency-skill

Frankfurter API 로 환율 조회·통화 변환 (ECB 데이터, API 키 불필요)

- 경로: https://github.com/thruthesky/skills/tree/main/skills/currency-skill
- SKILL.md: https://github.com/thruthesky/skills/blob/main/skills/currency-skill/SKILL.md
- 부르기: Claude Code `/currency-skill:exchange` · Codex `$currency-skill` · 그 밖의 도구는 스킬 이름을 적거나 할 일을 말하면 에이전트가 고른다

```text
thruthesky/skills 저장소의 currency-skill 스킬을 설치해 줘.
스킬 경로: https://github.com/thruthesky/skills/tree/main/skills/currency-skill — 표준 Agent Skills 형식(폴더 안에 SKILL.md)이다.

1. 네가 Claude Code 면 플러그인으로 설치한다. 터미널에서 차례로 실행한다.
   claude plugin marketplace add thruthesky/skills
   claude plugin marketplace update thruthesky-skills
   claude plugin install currency-skill@thruthesky-skills
   - 이미 설치돼 있으면 마지막 줄 대신 claude plugin update currency-skill@thruthesky-skills 를 실행한다.
2. 그 밖의 에이전트 도구면 네 도구의 사용자 스킬 폴더를 DIR 로 정한다.
   - Codex·Gemini CLI·GitHub Copilot CLI 는 DIR=~/.agents/skills 다. 다른 도구면 그 도구가 SKILL.md 를 읽는 스킬 폴더를 쓴다.
   - 아래 명령으로 받는다. 이미 있던 currency-skill 폴더는 지우고 새로 받는다.
   mkdir -p DIR && rm -rf DIR/currency-skill && curl -fsSL https://codeload.github.com/thruthesky/skills/tar.gz/refs/heads/main | tar -xz -C DIR --strip-components=2 skills-main/skills/currency-skill
   - Windows PowerShell 이면 curl.exe 로 임시 파일에 받은 뒤 tar -xzf 로 같은 경로만 DIR 에 푼다.
3. 설치를 확인한다. Claude Code 는 claude plugin list 에서 currency-skill@thruthesky-skills 를, 그 밖의 도구는 DIR/currency-skill/SKILL.md 의 앞머리 name 이 currency-skill 인지 본다.
4. 설치 방법·경로·버전을 보고하고, 이 도구에서 스킬을 쓰는 방법(부르는 이름, 다시 시작이나 다시 읽기)을 알려 준다.
```

### 4.4 data-skill

대한민국 공공데이터포털(data.go.kr) API 사용

- 경로: https://github.com/thruthesky/skills/tree/main/skills/data-skill
- SKILL.md: https://github.com/thruthesky/skills/blob/main/skills/data-skill/SKILL.md
- 부르기: Claude Code `/data-skill:query` · Codex `$data-skill` · 그 밖의 도구는 스킬 이름을 적거나 할 일을 말하면 에이전트가 고른다

```text
thruthesky/skills 저장소의 data-skill 스킬을 설치해 줘.
스킬 경로: https://github.com/thruthesky/skills/tree/main/skills/data-skill — 표준 Agent Skills 형식(폴더 안에 SKILL.md)이다.

1. 네가 Claude Code 면 플러그인으로 설치한다. 터미널에서 차례로 실행한다.
   claude plugin marketplace add thruthesky/skills
   claude plugin marketplace update thruthesky-skills
   claude plugin install data-skill@thruthesky-skills
   - 이미 설치돼 있으면 마지막 줄 대신 claude plugin update data-skill@thruthesky-skills 를 실행한다.
2. 그 밖의 에이전트 도구면 네 도구의 사용자 스킬 폴더를 DIR 로 정한다.
   - Codex·Gemini CLI·GitHub Copilot CLI 는 DIR=~/.agents/skills 다. 다른 도구면 그 도구가 SKILL.md 를 읽는 스킬 폴더를 쓴다.
   - 아래 명령으로 받는다. 이미 있던 data-skill 폴더는 지우고 새로 받는다.
   mkdir -p DIR && rm -rf DIR/data-skill && curl -fsSL https://codeload.github.com/thruthesky/skills/tar.gz/refs/heads/main | tar -xz -C DIR --strip-components=2 skills-main/skills/data-skill
   - Windows PowerShell 이면 curl.exe 로 임시 파일에 받은 뒤 tar -xzf 로 같은 경로만 DIR 에 푼다.
3. 설치를 확인한다. Claude Code 는 claude plugin list 에서 data-skill@thruthesky-skills 를, 그 밖의 도구는 DIR/data-skill/SKILL.md 의 앞머리 name 이 data-skill 인지 본다.
4. 설치 방법·경로·버전을 보고하고, 이 도구에서 스킬을 쓰는 방법(부르는 이름, 다시 시작이나 다시 읽기)을 알려 준다.
```

### 4.5 dev

명세(`.dev/`) 기반 개발 — copy·plan·execute·list·refactor·review

- 경로: https://github.com/thruthesky/skills/tree/main/skills/dev
- SKILL.md: https://github.com/thruthesky/skills/blob/main/skills/dev/SKILL.md
- 부르기: Claude Code `/dev:dev` · `/dev:plan` 등 · Codex `$dev` · 그 밖의 도구는 스킬 이름을 적거나 할 일을 말하면 에이전트가 고른다

```text
thruthesky/skills 저장소의 dev 스킬을 설치해 줘.
스킬 경로: https://github.com/thruthesky/skills/tree/main/skills/dev — 표준 Agent Skills 형식(폴더 안에 SKILL.md)이다.

1. 네가 Claude Code 면 플러그인으로 설치한다. 터미널에서 차례로 실행한다.
   claude plugin marketplace add thruthesky/skills
   claude plugin marketplace update thruthesky-skills
   claude plugin install dev@thruthesky-skills
   - 이미 설치돼 있으면 마지막 줄 대신 claude plugin update dev@thruthesky-skills 를 실행한다.
2. 그 밖의 에이전트 도구면 네 도구의 사용자 스킬 폴더를 DIR 로 정한다.
   - Codex·Gemini CLI·GitHub Copilot CLI 는 DIR=~/.agents/skills 다. 다른 도구면 그 도구가 SKILL.md 를 읽는 스킬 폴더를 쓴다.
   - 아래 명령으로 받는다. 이미 있던 dev 폴더는 지우고 새로 받는다.
   mkdir -p DIR && rm -rf DIR/dev && curl -fsSL https://codeload.github.com/thruthesky/skills/tar.gz/refs/heads/main | tar -xz -C DIR --strip-components=2 skills-main/skills/dev
   - Windows PowerShell 이면 curl.exe 로 임시 파일에 받은 뒤 tar -xzf 로 같은 경로만 DIR 에 푼다.
3. 설치를 확인한다. Claude Code 는 claude plugin list 에서 dev@thruthesky-skills 를, 그 밖의 도구는 DIR/dev/SKILL.md 의 앞머리 name 이 dev 인지 본다.
4. 설치 방법·경로·버전을 보고하고, 이 도구에서 스킬을 쓰는 방법(부르는 이름, 다시 시작이나 다시 읽기)을 알려 준다.
```

### 4.6 dokploy-skill

Dokploy 셀프호스팅 PaaS 관리 — 앱 배포·Docker Compose·DB·Traefik·SSL·백업

- 경로: https://github.com/thruthesky/skills/tree/main/skills/dokploy-skill
- SKILL.md: https://github.com/thruthesky/skills/blob/main/skills/dokploy-skill/SKILL.md
- 부르기: Claude Code `/dokploy-skills:manage` · Codex `$dokploy-skill` · 그 밖의 도구는 스킬 이름을 적거나 할 일을 말하면 에이전트가 고른다

```text
thruthesky/skills 저장소의 dokploy-skill 스킬을 설치해 줘.
스킬 경로: https://github.com/thruthesky/skills/tree/main/skills/dokploy-skill — 표준 Agent Skills 형식(폴더 안에 SKILL.md)이다.

1. 네가 Claude Code 면 플러그인으로 설치한다. 터미널에서 차례로 실행한다.
   claude plugin marketplace add thruthesky/skills
   claude plugin marketplace update thruthesky-skills
   claude plugin install dokploy-skills@thruthesky-skills
   - 이미 설치돼 있으면 마지막 줄 대신 claude plugin update dokploy-skills@thruthesky-skills 를 실행한다.
2. 그 밖의 에이전트 도구면 네 도구의 사용자 스킬 폴더를 DIR 로 정한다.
   - Codex·Gemini CLI·GitHub Copilot CLI 는 DIR=~/.agents/skills 다. 다른 도구면 그 도구가 SKILL.md 를 읽는 스킬 폴더를 쓴다.
   - 아래 명령으로 받는다. 이미 있던 dokploy-skill 폴더는 지우고 새로 받는다.
   mkdir -p DIR && rm -rf DIR/dokploy-skill && curl -fsSL https://codeload.github.com/thruthesky/skills/tar.gz/refs/heads/main | tar -xz -C DIR --strip-components=2 skills-main/skills/dokploy-skill
   - Windows PowerShell 이면 curl.exe 로 임시 파일에 받은 뒤 tar -xzf 로 같은 경로만 DIR 에 푼다.
3. 설치를 확인한다. Claude Code 는 claude plugin list 에서 dokploy-skills@thruthesky-skills 를, 그 밖의 도구는 DIR/dokploy-skill/SKILL.md 의 앞머리 name 이 dokploy-skill 인지 본다.
4. 설치 방법·경로·버전을 보고하고, 이 도구에서 스킬을 쓰는 방법(부르는 이름, 다시 시작이나 다시 읽기)을 알려 준다.
```

### 4.7 flutter-skill

Flutter 앱 개발 지침 — UI/UX·상태관리·네트워킹·API 연동

- 경로: https://github.com/thruthesky/skills/tree/main/skills/flutter-skill
- SKILL.md: https://github.com/thruthesky/skills/blob/main/skills/flutter-skill/SKILL.md
- 부르기: Claude Code `/flutter-skill:develop` · Codex `$flutter-skill` · 그 밖의 도구는 스킬 이름을 적거나 할 일을 말하면 에이전트가 고른다

```text
thruthesky/skills 저장소의 flutter-skill 스킬을 설치해 줘.
스킬 경로: https://github.com/thruthesky/skills/tree/main/skills/flutter-skill — 표준 Agent Skills 형식(폴더 안에 SKILL.md)이다.

1. 네가 Claude Code 면 플러그인으로 설치한다. 터미널에서 차례로 실행한다.
   claude plugin marketplace add thruthesky/skills
   claude plugin marketplace update thruthesky-skills
   claude plugin install flutter-skill@thruthesky-skills
   - 이미 설치돼 있으면 마지막 줄 대신 claude plugin update flutter-skill@thruthesky-skills 를 실행한다.
2. 그 밖의 에이전트 도구면 네 도구의 사용자 스킬 폴더를 DIR 로 정한다.
   - Codex·Gemini CLI·GitHub Copilot CLI 는 DIR=~/.agents/skills 다. 다른 도구면 그 도구가 SKILL.md 를 읽는 스킬 폴더를 쓴다.
   - 아래 명령으로 받는다. 이미 있던 flutter-skill 폴더는 지우고 새로 받는다.
   mkdir -p DIR && rm -rf DIR/flutter-skill && curl -fsSL https://codeload.github.com/thruthesky/skills/tar.gz/refs/heads/main | tar -xz -C DIR --strip-components=2 skills-main/skills/flutter-skill
   - Windows PowerShell 이면 curl.exe 로 임시 파일에 받은 뒤 tar -xzf 로 같은 경로만 DIR 에 푼다.
3. 설치를 확인한다. Claude Code 는 claude plugin list 에서 flutter-skill@thruthesky-skills 를, 그 밖의 도구는 DIR/flutter-skill/SKILL.md 의 앞머리 name 이 flutter-skill 인지 본다.
4. 설치 방법·경로·버전을 보고하고, 이 도구에서 스킬을 쓰는 방법(부르는 이름, 다시 시작이나 다시 읽기)을 알려 준다.
```

### 4.8 harness

Harness 방식 에이전트 문서 세트(짧은 AGENTS.md + docs/) 만들기

- 경로: https://github.com/thruthesky/skills/tree/main/skills/harness
- SKILL.md: https://github.com/thruthesky/skills/blob/main/skills/harness/SKILL.md
- 부르기: Claude Code `/harness-skill:generate` · Codex `$harness` · 그 밖의 도구는 스킬 이름을 적거나 할 일을 말하면 에이전트가 고른다

```text
thruthesky/skills 저장소의 harness 스킬을 설치해 줘.
스킬 경로: https://github.com/thruthesky/skills/tree/main/skills/harness — 표준 Agent Skills 형식(폴더 안에 SKILL.md)이다.

1. 네가 Claude Code 면 플러그인으로 설치한다. 터미널에서 차례로 실행한다.
   claude plugin marketplace add thruthesky/skills
   claude plugin marketplace update thruthesky-skills
   claude plugin install harness-skill@thruthesky-skills
   - 이미 설치돼 있으면 마지막 줄 대신 claude plugin update harness-skill@thruthesky-skills 를 실행한다.
2. 그 밖의 에이전트 도구면 네 도구의 사용자 스킬 폴더를 DIR 로 정한다.
   - Codex·Gemini CLI·GitHub Copilot CLI 는 DIR=~/.agents/skills 다. 다른 도구면 그 도구가 SKILL.md 를 읽는 스킬 폴더를 쓴다.
   - 아래 명령으로 받는다. 이미 있던 harness 폴더는 지우고 새로 받는다.
   mkdir -p DIR && rm -rf DIR/harness && curl -fsSL https://codeload.github.com/thruthesky/skills/tar.gz/refs/heads/main | tar -xz -C DIR --strip-components=2 skills-main/skills/harness
   - Windows PowerShell 이면 curl.exe 로 임시 파일에 받은 뒤 tar -xzf 로 같은 경로만 DIR 에 푼다.
3. 설치를 확인한다. Claude Code 는 claude plugin list 에서 harness-skill@thruthesky-skills 를, 그 밖의 도구는 DIR/harness/SKILL.md 의 앞머리 name 이 harness 인지 본다.
4. 설치 방법·경로·버전을 보고하고, 이 도구에서 스킬을 쓰는 방법(부르는 이름, 다시 시작이나 다시 읽기)을 알려 준다.
```

### 4.9 open-meteo-skill

Open-Meteo 날씨·대기질·해양·위치 검색 API (API 키 불필요)

- 경로: https://github.com/thruthesky/skills/tree/main/skills/open-meteo-skill
- SKILL.md: https://github.com/thruthesky/skills/blob/main/skills/open-meteo-skill/SKILL.md
- 부르기: Claude Code `/open-meteo-skill:weather` · Codex `$open-meteo-skill` · 그 밖의 도구는 스킬 이름을 적거나 할 일을 말하면 에이전트가 고른다

```text
thruthesky/skills 저장소의 open-meteo-skill 스킬을 설치해 줘.
스킬 경로: https://github.com/thruthesky/skills/tree/main/skills/open-meteo-skill — 표준 Agent Skills 형식(폴더 안에 SKILL.md)이다.

1. 네가 Claude Code 면 플러그인으로 설치한다. 터미널에서 차례로 실행한다.
   claude plugin marketplace add thruthesky/skills
   claude plugin marketplace update thruthesky-skills
   claude plugin install open-meteo-skill@thruthesky-skills
   - 이미 설치돼 있으면 마지막 줄 대신 claude plugin update open-meteo-skill@thruthesky-skills 를 실행한다.
2. 그 밖의 에이전트 도구면 네 도구의 사용자 스킬 폴더를 DIR 로 정한다.
   - Codex·Gemini CLI·GitHub Copilot CLI 는 DIR=~/.agents/skills 다. 다른 도구면 그 도구가 SKILL.md 를 읽는 스킬 폴더를 쓴다.
   - 아래 명령으로 받는다. 이미 있던 open-meteo-skill 폴더는 지우고 새로 받는다.
   mkdir -p DIR && rm -rf DIR/open-meteo-skill && curl -fsSL https://codeload.github.com/thruthesky/skills/tar.gz/refs/heads/main | tar -xz -C DIR --strip-components=2 skills-main/skills/open-meteo-skill
   - Windows PowerShell 이면 curl.exe 로 임시 파일에 받은 뒤 tar -xzf 로 같은 경로만 DIR 에 푼다.
3. 설치를 확인한다. Claude Code 는 claude plugin list 에서 open-meteo-skill@thruthesky-skills 를, 그 밖의 도구는 DIR/open-meteo-skill/SKILL.md 의 앞머리 name 이 open-meteo-skill 인지 본다.
4. 설치 방법·경로·버전을 보고하고, 이 도구에서 스킬을 쓰는 방법(부르는 이름, 다시 시작이나 다시 읽기)을 알려 준다.
```

### 4.10 skill-creator

스킬 만들기·고치기·평가·설명 최적화

- 경로: https://github.com/thruthesky/skills/tree/main/skills/skill-creator
- SKILL.md: https://github.com/thruthesky/skills/blob/main/skills/skill-creator/SKILL.md
- 부르기: Claude Code `/skill-creator:create` · Codex `$skill-creator` · 그 밖의 도구는 스킬 이름을 적거나 할 일을 말하면 에이전트가 고른다

```text
thruthesky/skills 저장소의 skill-creator 스킬을 설치해 줘.
스킬 경로: https://github.com/thruthesky/skills/tree/main/skills/skill-creator — 표준 Agent Skills 형식(폴더 안에 SKILL.md)이다.

1. 네가 Claude Code 면 플러그인으로 설치한다. 터미널에서 차례로 실행한다.
   claude plugin marketplace add thruthesky/skills
   claude plugin marketplace update thruthesky-skills
   claude plugin install skill-creator@thruthesky-skills
   - 이미 설치돼 있으면 마지막 줄 대신 claude plugin update skill-creator@thruthesky-skills 를 실행한다.
2. 그 밖의 에이전트 도구면 네 도구의 사용자 스킬 폴더를 DIR 로 정한다.
   - Codex·Gemini CLI·GitHub Copilot CLI 는 DIR=~/.agents/skills 다. 다른 도구면 그 도구가 SKILL.md 를 읽는 스킬 폴더를 쓴다.
   - 아래 명령으로 받는다. 이미 있던 skill-creator 폴더는 지우고 새로 받는다.
   mkdir -p DIR && rm -rf DIR/skill-creator && curl -fsSL https://codeload.github.com/thruthesky/skills/tar.gz/refs/heads/main | tar -xz -C DIR --strip-components=2 skills-main/skills/skill-creator
   - Windows PowerShell 이면 curl.exe 로 임시 파일에 받은 뒤 tar -xzf 로 같은 경로만 DIR 에 푼다.
3. 설치를 확인한다. Claude Code 는 claude plugin list 에서 skill-creator@thruthesky-skills 를, 그 밖의 도구는 DIR/skill-creator/SKILL.md 의 앞머리 name 이 skill-creator 인지 본다.
4. 설치 방법·경로·버전을 보고하고, 이 도구에서 스킬을 쓰는 방법(부르는 이름, 다시 시작이나 다시 읽기)을 알려 준다.
```

### 4.11 team

여러 세션 협업 — 브라우저 MCP 상호 배타 잠금·git·팀 로그

- 경로: https://github.com/thruthesky/skills/tree/main/skills/team
- SKILL.md: https://github.com/thruthesky/skills/blob/main/skills/team/SKILL.md
- 부르기: Claude Code `/team:team` · `/team:work` 등 · Codex `$team` · 그 밖의 도구는 스킬 이름을 적거나 할 일을 말하면 에이전트가 고른다

```text
thruthesky/skills 저장소의 team 스킬을 설치해 줘.
스킬 경로: https://github.com/thruthesky/skills/tree/main/skills/team — 표준 Agent Skills 형식(폴더 안에 SKILL.md)이다.

1. 네가 Claude Code 면 플러그인으로 설치한다. 터미널에서 차례로 실행한다.
   claude plugin marketplace add thruthesky/skills
   claude plugin marketplace update thruthesky-skills
   claude plugin install team@thruthesky-skills
   - 이미 설치돼 있으면 마지막 줄 대신 claude plugin update team@thruthesky-skills 를 실행한다.
2. 그 밖의 에이전트 도구면 네 도구의 사용자 스킬 폴더를 DIR 로 정한다.
   - Codex·Gemini CLI·GitHub Copilot CLI 는 DIR=~/.agents/skills 다. 다른 도구면 그 도구가 SKILL.md 를 읽는 스킬 폴더를 쓴다.
   - 아래 명령으로 받는다. 이미 있던 team 폴더는 지우고 새로 받는다.
   mkdir -p DIR && rm -rf DIR/team && curl -fsSL https://codeload.github.com/thruthesky/skills/tar.gz/refs/heads/main | tar -xz -C DIR --strip-components=2 skills-main/skills/team
   - Windows PowerShell 이면 curl.exe 로 임시 파일에 받은 뒤 tar -xzf 로 같은 경로만 DIR 에 푼다.
3. 설치를 확인한다. Claude Code 는 claude plugin list 에서 team@thruthesky-skills 를, 그 밖의 도구는 DIR/team/SKILL.md 의 앞머리 name 이 team 인지 본다.
4. 설치 방법·경로·버전을 보고하고, 이 도구에서 스킬을 쓰는 방법(부르는 이름, 다시 시작이나 다시 읽기)을 알려 준다.
```

### 4.12 waf

Cloudflare WAF 로 막힌 사이트의 브라우저 자동화 (PHP PEST + ChromeDriver)

- 경로: https://github.com/thruthesky/skills/tree/main/skills/waf
- SKILL.md: https://github.com/thruthesky/skills/blob/main/skills/waf/SKILL.md
- 부르기: Claude Code `/waf-skill:bypass` · Codex `$waf` · 그 밖의 도구는 스킬 이름을 적거나 할 일을 말하면 에이전트가 고른다

```text
thruthesky/skills 저장소의 waf 스킬을 설치해 줘.
스킬 경로: https://github.com/thruthesky/skills/tree/main/skills/waf — 표준 Agent Skills 형식(폴더 안에 SKILL.md)이다.

1. 네가 Claude Code 면 플러그인으로 설치한다. 터미널에서 차례로 실행한다.
   claude plugin marketplace add thruthesky/skills
   claude plugin marketplace update thruthesky-skills
   claude plugin install waf-skill@thruthesky-skills
   - 이미 설치돼 있으면 마지막 줄 대신 claude plugin update waf-skill@thruthesky-skills 를 실행한다.
2. 그 밖의 에이전트 도구면 네 도구의 사용자 스킬 폴더를 DIR 로 정한다.
   - Codex·Gemini CLI·GitHub Copilot CLI 는 DIR=~/.agents/skills 다. 다른 도구면 그 도구가 SKILL.md 를 읽는 스킬 폴더를 쓴다.
   - 아래 명령으로 받는다. 이미 있던 waf 폴더는 지우고 새로 받는다.
   mkdir -p DIR && rm -rf DIR/waf && curl -fsSL https://codeload.github.com/thruthesky/skills/tar.gz/refs/heads/main | tar -xz -C DIR --strip-components=2 skills-main/skills/waf
   - Windows PowerShell 이면 curl.exe 로 임시 파일에 받은 뒤 tar -xzf 로 같은 경로만 DIR 에 푼다.
3. 설치를 확인한다. Claude Code 는 claude plugin list 에서 waf-skill@thruthesky-skills 를, 그 밖의 도구는 DIR/waf/SKILL.md 의 앞머리 name 이 waf 인지 본다.
4. 설치 방법·경로·버전을 보고하고, 이 도구에서 스킬을 쓰는 방법(부르는 이름, 다시 시작이나 다시 읽기)을 알려 준다.
```

## 5. 업데이트와 삭제

| 설치 방법 | 업데이트 | 삭제 |
|------|------|------|
| Claude Code 플러그인 | `claude plugin marketplace update thruthesky-skills` → `claude plugin update <플러그인>@thruthesky-skills` → 다시 시작 | `claude plugin uninstall <플러그인>@thruthesky-skills` |
| 스킬 폴더 | §4 의 글을 다시 붙여 넣거나 §2.3 명령을 다시 실행한다(폴더를 지우고 새로 받는다) | `rm -rf <스킬 폴더>/<스킬 이름>` |

`api-skill` 은 스킬을 `update` 인자로 부르면(`bash <스킬 폴더>/scripts/update.sh`) 스스로 최신으로 바꾼다.

## 6. 스킬을 더하거나 고칠 때 (관리자)

- 스킬 하나는 `skills/<이름>/` 폴더 하나다. 표준을 지킨다.
  - `SKILL.md` 를 폴더 바로 아래에 두고, `name` 은 폴더 이름과 같게, `description` 은 1024자 이내로 쓴다.
  - 파일 경로는 스킬 폴더 기준 상대 경로로 쓴다.
- Claude Code 플러그인 정보는 `.claude-plugin/plugin.json` 이다. `.claude-plugin/marketplace.json` 의 `plugins` 에 항목을 더한다.
  - Claude Code 명령(`commands/*.md`)만 쓰는 스킬은 `plugin.json` 에 `"skills": []` 를 넣는다. 그래야 Claude Code 가 `SKILL.md` 와 명령을 두 번 불러오지 않는다.
- **고칠 때마다 version 을 올린다.** Claude Code 는 version 이 바뀌어야 새 판을 받는다.
  - `plugin.json` 과 마켓플레이스 항목의 version 을 같게 올린다. `api-skill` 은 `SKILL.md` 의 `metadata.version` 도 함께 올린다.
- 검사: `claude plugin validate skills/<이름>` 과 `claude plugin validate .`. 표준 검사는 `skills-ref validate skills/<이름>`([agentskills/skills-ref](https://github.com/agentskills/agentskills/tree/main/skills-ref)).
- `main` 에 push 하면 배포된다. 사용자는 §5 의 방법으로 받는다.
