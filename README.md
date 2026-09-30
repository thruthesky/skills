# thruthesky/skills — AI 코딩 에이전트 스킬 모음

Claude Code 플러그인 마켓플레이스 **`thruthesky-skills`** 다. 플러그인마다 스킬(`SKILL.md`)이나 명령(`commands/*.md`)이 들어 있다.

- `SKILL.md` 가 있는 플러그인은 Agent Skills 표준이라 Codex·Gemini CLI·GitHub Copilot CLI 에서도 쓸 수 있다(§4 표).
- 여기서는 **api-skill**(필리핀 여행 정보 API)을 예로 설치 방법을 설명한다. 다른 플러그인도 이름만 바꾸면 같다.

## 1. 설치 — 코딩 에이전트에게 맡기기 (가장 쉬움)

아래 글을 **통째로 복사해 코딩 에이전트(Claude Code·Codex·Gemini CLI·Copilot CLI 등)의 대화창에 붙여 넣고 전송**한다. 코드 상자 오른쪽 위의 복사 단추를 누르면 된다.

- Claude Code 면 마켓플레이스를 등록하고 **플러그인**으로 설치한다.
- 그 밖의 도구면 **스킬 폴더**로 설치한다.
- 설치한 뒤 버전을 확인해 보고하고, 스킬을 부르는 방법을 알려 준다. 이미 설치돼 있으면 최신으로 바꾼다.

```text
thruthesky/skills 저장소의 api-skill 스킬(필리핀 여행 정보 API)을 설치해 줘. 아래 순서를 그대로 따라 줘.

1. 네가 Claude Code 면 플러그인으로 설치한다. 터미널에서 차례로 실행한다.
   claude plugin marketplace add thruthesky/skills
   claude plugin marketplace update thruthesky-skills
   claude plugin install api-skill@thruthesky-skills
   - 첫 줄이 이미 추가돼 있다고 하면 그대로 넘어간다.
   - 이미 설치돼 있다고 하면 마지막 줄 대신 claude plugin update api-skill@thruthesky-skills 를 실행한다.
2. 네가 Codex·Gemini CLI·GitHub Copilot CLI 등 그 밖의 도구면 스킬 폴더로 설치한다. DIR=~/.agents/skills
   - DIR/api-skill/SKILL.md 가 이미 있으면 bash DIR/api-skill/scripts/update.sh 를 실행해 최신으로 바꾼다.
   - 없으면 아래 명령을 실행한다. Windows PowerShell 이면 curl.exe 로 임시 파일에 받은 뒤 tar 로 같은 경로만 푼다.
   mkdir -p DIR && curl -fsSL https://codeload.github.com/thruthesky/skills/tar.gz/refs/heads/main | tar -xz -C DIR --strip-components=2 skills-main/skills/api-skill
3. 설치된 버전을 확인한다. Claude Code 는 claude plugin list 에서 api-skill@thruthesky-skills 를, 그 밖의 도구는 DIR/api-skill/SKILL.md 앞머리의 version 을 본다.
4. node -v 로 Node 버전을 본다. 스킬의 조회 도구는 Node 24 가 필요하다(내장 SQLite 의 FTS5). 낮으면 알려만 준다.
5. 설치 방법·경로·version·Node 확인 결과를 보고하고, 이 도구에서 스킬을 쓰려면 무엇을 해야 하는지 알려 준다(다시 시작·다시 읽기 명령, 부르는 이름 — Claude Code /api-skill:api-skill, Codex $api-skill).
```

**한 프로젝트에서만 쓰려면** 붙여 넣은 글에서 두 곳을 바꾼다.

- Claude Code: 1번의 `marketplace add` 와 `install` 뒤에 `--scope project` 를 붙인다. 프로젝트의 `.claude/settings.json` 에 기록돼, 그 저장소를 여는 사람에게도 설치를 권한다.
- 그 밖의 도구: `DIR` 을 프로젝트의 `.agents/skills` 로 바꾼다.

## 2. 설치 — 직접 명령으로

### 2.1 Claude Code — 플러그인

대화창에서 실행한다.

```text
/plugin marketplace add thruthesky/skills
/plugin install api-skill@thruthesky-skills
```

터미널에서는 `claude plugin marketplace add thruthesky/skills` → `claude plugin install api-skill@thruthesky-skills` 다. 프로젝트 범위는 `--scope project` 를 붙인다. 설치한 뒤 Claude Code 를 다시 시작하면 스킬이 잡힌다.

### 2.2 그 밖의 도구 — 스킬 폴더

도구에 맞는 폴더를 `DIR` 에 넣고 터미널에서 실행한다. 저장소 묶음(1MB 미만)을 받아 `skills/api-skill` 만 푼다.

```bash
DIR=~/.agents/skills   # Codex·Gemini CLI·Copilot CLI 공용 폴더
mkdir -p "$DIR" && curl -fsSL https://codeload.github.com/thruthesky/skills/tar.gz/refs/heads/main | tar -xz -C "$DIR" --strip-components=2 skills-main/skills/api-skill
```

| 도구 | 사용자 스킬 폴더 (모든 프로젝트) | 프로젝트 스킬 폴더 | 설치 뒤 스킬 잡기 |
|------|------|------|------|
| Claude Code | 플러그인(§2.1) 권장 · 폴더로 넣으려면 `~/.claude/skills` | `.claude/skills` | 다시 시작 |
| Codex | `~/.agents/skills` | `.agents/skills` | 자동으로 잡힌다. 안 보이면 다시 시작 |
| Gemini CLI | `~/.agents/skills` (또는 `~/.gemini/skills`) | `.agents/skills` (또는 `.gemini/skills`) | `/skills reload` |
| GitHub Copilot CLI | `~/.agents/skills` (또는 `~/.copilot/skills`) | `.agents/skills` (또는 `.github/skills`) | `/skills reload` |

다른 스킬을 폴더로 넣을 때는 명령 끝의 `skills-main/skills/api-skill` 을 `skills-main/skills/<폴더 이름>` 으로 바꾼다. §4 표에서 `SKILL.md` 가 있는 것만 된다.

## 3. 업데이트와 삭제

| 설치 방법 | 업데이트 | 삭제 |
|------|------|------|
| Claude Code 플러그인 | `claude plugin marketplace update thruthesky-skills` → `claude plugin update api-skill@thruthesky-skills` → 다시 시작 | `claude plugin uninstall api-skill@thruthesky-skills` |
| 스킬 폴더 | 스킬을 `update` 인자로 부르거나 `bash ~/.agents/skills/api-skill/scripts/update.sh` | `rm -rf ~/.agents/skills/api-skill` |

`update.sh` 는 설치 방법을 스스로 알아본다. 플러그인이면 위의 플러그인 명령을, 원본 저장소면 `git pull` 을 안내한다.

## 4. 플러그인 목록

| 플러그인 | 하는 일 | Claude Code 에서 부르기 | 다른 도구 (`SKILL.md`) |
|------|------|------|:-:|
| `api-skill` | 필리핀 여행 정보 API(198곳, 8개 언어) — 여행 질문 답하기, 웹·앱에 넣기(SQLite·PHP·Flutter·렌더러), 여행지 추가·번역·배포 | `/api-skill:api-skill` | ✓ |
| `cowork` | 여러 AI 교차 분석 — 직접 지목할 때만 | `/cowork:cowork` · `/cowork:init` | ✓ |
| `dev` | 명세(.dev/) 기반 개발 — copy·plan·execute·list·refactor·review | `/dev:dev` · `/dev:<명령>` | ✓ |
| `team` | 여러 세션 협업 — 브라우저 MCP 잠금·팀 로그 | `/team:team` · `/team:work` … | ✓ |
| `open-meteo-skill` | Open-Meteo 날씨 API | `/open-meteo-skill:weather` | — |
| `currency-skill` | 환율 조회·통화 변환 (Frankfurter) | `/currency-skill:exchange` | — |
| `data-skill` | 공공데이터포털(data.go.kr) API | `/data-skill:query` | — |
| `dokploy-skills` | Dokploy 셀프호스팅 PaaS 관리 | `/dokploy-skills:manage` | — |
| `flutter-skill` | Flutter 개발 지침 | `/flutter-skill:develop` | — |
| `waf-skill` | Cloudflare WAF 사이트 브라우저 자동화 | `/waf-skill:bypass` | — |
| `harness-skill` | 에이전트용 문서 세트(AGENTS.md + docs/) 만들기 | `/harness-skill:generate` | — |
| `skill-creator` | 스킬 만들기·개선 | `/skill-creator:create` | — |

어느 플러그인이든 설치는 `claude plugin install <플러그인>@thruthesky-skills` 다.

## 5. 스킬을 더하거나 고칠 때 (관리자)

- 플러그인은 `skills/<폴더>/` 하나다.
  - `.claude-plugin/plugin.json` — 이름·version·설명.
  - `SKILL.md` 를 폴더 바로 아래에 두면 단일 스킬로 불러온다(다른 도구에서도 쓸 수 있다).
  - `commands/*.md` 는 Claude Code 전용 명령이다.
- `.claude-plugin/marketplace.json` 의 `plugins` 에 항목을 더한다.
- **고칠 때마다 version 을 올린다.** Claude Code 는 version 이 바뀌어야 새 판을 받는다.
  - `api-skill` 은 세 곳을 같은 값으로 올린다: `SKILL.md` 의 `metadata.version`, `plugin.json` 의 `version`, 마켓플레이스 항목의 `version`.
- 검사: `claude plugin validate skills/<폴더>` 와 `claude plugin validate .`
- `main` 에 push 하면 배포된다. 사용자는 §3 의 업데이트 명령으로 받는다.
