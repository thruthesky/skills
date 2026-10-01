# 현재 상태와 결정 기록

왜 지금 모양이 되었는지와 남은 일이다. 구조를 크게 바꾸기 전에 읽는다.

## 1. 현재 상태 (2026-10-01)

- **완료:**
  - 자료 이전, 빌드 스크립트, Pages 배포(v1, version `68cef818ff36`).
    - Pages 는 `gh api -X POST repos/thruthesky/ph-travel-api/pages -f build_type=workflow` 로 켰다.
    - 공개 주소에서 JSON 과 사진 293장 응답을 검증했다.
  - 마크다운 → 블록 JSON 변환, 표시 방법 목록, v2 빌드.
    - 변환은 일회성 스크립트로 했다.
    - 원문 1,000개 단락의 보이는 글자(마크다운 기호·공백 제외)가 순서까지 JSON 과 일치함을 확인했다. 앞머리 25개 키도 모두 일치했다.
    - 031~040 번 끝에 섞여 있던 도구 태그 줄(`</content>`, `</invoke>`)은 이때 지웠다.
  - AI 스킬 `travel-api-skill` — 2026-09-30 에 `api-skill` 로 이름을 바꾸고 thruthesky/skills 로 옮겼다(§4.1)
    - AGENTS.md 의 안내를 이 스킬로 옮겼다.
    - 조회 도구(`scripts/travel.mjs`), 자체 업데이트(`scripts/update.sh`), 웹·Flutter 참고 렌더러(`assets/`)를 넣었다.
  - (2026-09-28) 8개 언어 번역과 `meta.json`. 계약은 [api.md](api.md) §1~5 에 있다.
    - 원본 ko, 번역 en·zh·ja·th·vi·ru·ar
    - 출력 `v2/` 바로 아래 `places.<lang>.json` 8개 + `meta.json`. `content_display_type.json` 은 `meta.display` 로 합쳤다
  - (2026-09-28) 스킬 — 넣어 쓰기(임베딩)와 SQLite
    - `travel-db.mjs`(sync·build·export), `assets/travel-schema.sql`
    - 조회 구현 `TravelDb.php`·`travel_db.dart`, 예시 페이지 `travel-page.php`
    - `travel.mjs` 는 SQLite 캐시 DB 로 답하도록 바꿨다(`--lang`, `sql` 명령)
  - (2026-09-28) 스킬 보강 — 실제 번역(en·zh)과 서브에이전트 실사용 시험(영어 가족 여행, 중국어 고래상어, PHP 사이트 넣기)으로 찾은 것
    - 검색(세 구현 같게): 구절(`"life vest"`)·중국어 문장부호로 나누기, 요약까지 직접 찾기, 대소문자 무시, 제목 → 대표 태그 → 점수 → id 순서, 거르기와 함께 쓰기, trigram 을 모르는 서버 SQLite 대비
    - 조회 도구: 캐시 DB 에 모든 언어(어느 언어 이름으로도 찾기), `--tag` 여러 번, `--month 3月·Dec`, `--lang zh-CN`, 전각 괄호 예산 기준, 결과 언어의 표 머리, 옛 형식·404 API 는 한 줄 안내
    - PHP 예시: 8개 언어 화면 글, 공개 주소 설정(Host 헤더 불신), Accept-Language, 대체 언어 안내, 빈 결과 문구, noindex, 사진 `ImageObject`
    - 서버에 올리는 순서와 검사·되돌리기(embedding.md §3.2), 서버 요건(SQLite 3.34+)
    - Flutter: 긴 번역(`Moderate`)이 좁은 칸에서 넘치던 것
  - (2026-09-29) 여행지 100곳 → 200곳 (101~200번 추가)
    - 인터넷에 널리 알려진 관광지 가운데 기존 100곳과 겹치지 않는 곳을 골랐다. 한국어 원본·사진(Wikimedia Commons 274장)·번역 6개 언어(en·zh·ja·th·vi·ru). ar 은 아직 폴더가 없어 배포에서 빠진다.
    - 지역 3개를 더했다: `bulacan`·`nueva-ecija`·`marinduque`.
    - 삼보앙가 반도 4곳(삼보앙가 시티·그레이트 산타크루스 섬·메를로켓 폭포·다피탄)은 한국 외교부 여행금지 지역이라 빼고 판딘 호수·부카리 소나무 숲·시코곤 섬·맘부칼로 바꿨다. Commons 에 사진이 없는 단후간 섬·카파르칸 폭포도 다우인·부카리 소나무 숲으로 바꿨다.
    - `scripts/i18n.mjs` 가 본문의 `link`·`place_link` 조각(url·slug)을 뽑지 못해 번역이 막혔다. 언어와 무관한 키는 번역 줄에 넣지 않고 원본에서 옮기도록 고쳤다(`carryFixed`). 그 전에 쓴 새 원본 17곳의 `place_link` 는 일반 글로 바꿨다.
    - 기존·새 원본의 nearby 카드 24개에 `place` 링크를 붙였고, 표기 흔들림(바치오→바초이, 판싯 합미→합합, 말라타판→말라타파이 등)과 zh 지명 표기(拉瓦格·卡巴延·黎牙实比·安蒂波洛 등)를 200곳 전체에서 맞췄다.
    - 새 사진은 평균 약 120KB 로 기존(약 80KB)보다 커서 사진 폴더가 23MB → 56MB 가 됐다.
  - (2026-09-29) 200곳 전체 보완 — 2026년 기준 사실 확인·최신화
    - 여행지마다 좌표·교통편·요금·운영 시간·폐쇄·재해를 위키백과·OSM·관광청·선사·항공사·최근 기사로 확인해 고쳤다. 근거와 옛 값·새 값은 작업 폴더의 여행지별 변경 기록에 남겼다(git 밖 `_i18n/tools/changes/`).
    - 반영한 큰 변화: 2025-03·2026-03 마닐라 공항 프로펠러기 클락 이전(엘니도·코론·나가·시아르가오 등 직항 변화), PAL 마닐라–바스코 종료, 필트랑코 운행 중단, 2026-09-28 교통 요금 인상, 푸에르토 프린세사 이라완 터미널, 2025-09 세부 북부 지진, 2025-10 다바오 오리엔탈 지진, 2026-06 민다나오 규모 7.8 지진, 칸라온·마욘·불루산 경보, 2025-11 태풍 티노, 시코곤 리조트 폐쇄 등.
    - 좌표 34곳(초콜릿 힐스·모알보알·인챈티드 리버 등)을 바로잡았고, 다른 장소가 찍힌 사진 3장을 바꿨다. 공식 사이트 링크가 4곳 → 59곳이 됐다.
    - 여러 파일에 걸친 사실은 교차 점검으로 200곳 전체에 맞췄다.
    - `best_time` 단락 끝에 "시기별 한눈에 보기" `table`(시기·날씨·여행 포인트)을 200곳 모두 넣었다(`data/README.md` §3).
    - 번역은 바뀐 글만 다시 했다(언어마다 약 3,400줄). 원본을 고치기 전 번역 줄을 스냅샷으로 남기고, 원문이 같은 줄은 옛 번역을 그대로 채우는 방식이다.
    - 한국어 표기를 외래어 표기법·다수 표기로 맞췄다(타가이타이·타알·클락·막탄-세부 국제공항 등).
  - (2026-09-29) 112 마쿨롯 산(2020년부터 입산 금지)·199 시코곤 섬(2026년 6월 리조트 영구 폐쇄·섬 공항 운항 중단)을 뺐다 → 198곳. 번호는 비워 두고 다시 채우지 않는다. 두 곳을 가리키던 nearby 카드(059·107·109)도 모든 언어에서 뺐다.
  - (2026-09-29) 다른 작업에서 올린 아랍어(ar) 100곳 번역(8720e5e, 보완 전 원본 기준)을 합쳤다. 001~100 은 바뀐 줄만, 101~200 의 98곳은 새로 번역해 **198곳 × 8개 언어**를 채웠다. 같은 커밋의 러시아어 어휘집 수정 8곳도 보완본 위에 다시 적용했다.
  - (2026-09-30) 청사진 [blueprint.md](blueprint.md) — 다른 정보(첫 대상은 밤문화 `ph-night-api`)를 이 저장소와 같은 형태로 만들 때의 설계·파일별 고칠 곳·순서·검증을 적었다. SKILL.md §7 이 입구다.
    - 198곳 × 8개 언어로 DB 크기를 쟀다(Node 24): en 15.8MB · ko+en 31.0MB · 8개 언어 150.1MB · 전문 검색 없이 99.7MB. [database.md](database.md) §2 표를 채웠다.
  - (2026-10-01) 콘텐츠 규격과 R2 배포 — 사용자 요청으로 콘텐츠를 만들 때 지킬 다섯 가지를 정했다(§8). 입구는 SKILL.md §8, 절차는 [pipeline.md](pipeline.md).
    - 도구 둘을 더했다. `scripts/content.mjs`(stamp·check·images)와 `scripts/r2.mjs`(check·ls·deploy·verify). 둘 다 외부 패키지가 없다.
    - R2 시험: 여행지 1곳 × 8개 언어 묶음(13개 파일)을 `api-skill-test/v1/` 에 올리고 확인했다. 확인한 것은 공개 주소 응답, 바뀐 것만 다시 올리기, `--prune`, 사진 누락·언어 누락·잘못된 prefix 차단이다. 시험이 끝난 뒤 모두 지웠다(버킷 `files` 는 시험 전후 모두 비어 있었다).
    - 198곳 빌드에 `--country ph --dry-run` 을 돌리면 582개(94MB)를 올리는 계획이 나온다. 지금 저장소 빌드는 `data_version` 이 없어 배포가 거부된다.
    - 사진 572장을 `content.mjs images` 로 대조했다: 맞음 149 · 위치 정보 없음 413 · 15km 넘게 떨어져 찍음 8 · Commons 가 아닌 출처 1. 먼 8장 중 6장은 넓은 섬·주의 같은 곳이었다. 2장은 생물 사진이었다 — 077 안경원숭이는 주제와 맞고, 178 파밀라칸 섬의 대표 사진(팡라오 앞바다의 돌고래)은 섬이 보이지 않는다.
    - `update` 인자: Claude Code 플러그인이면 안내만 하던 것을, 설치된 범위마다 `claude plugin update` 를 실행하도록 바꿨다. 원본 저장소는 깨끗할 때 `git pull --ff-only` 한다. 옛 `~/.claude/skills/travel-api-skill` 이 남아 있으면 알린다. 세 경로 모두 시험했다.
  - (2026-10-01) **R2 첫 배포와 주소 전환** — 공개 주소가 `https://files.withcenter.com/ph-travel-api/v2/` 가 됐다.
    - ph-travel-api `data/meta.json` 에 `data_version` `2026-09-29T07:26:02Z` 를 넣었다(`5d2cf06`). 값은 오늘이 아니라 data/ 의 JSON·사진을 마지막으로 바꾼 커밋(`9587fe6`, 아랍어 198곳 완성)의 시각이다.
    - `r2.mjs deploy --country ph` 로 582개(94MB)를 40초에 올렸다. `verify` 가 통과했고(언어 파일 8개·사진 572장의 ETag·content-type), 조회 도구가 R2 주소에서 받아 DB 를 만들고 검색하는 것까지 확인했다. version `4516764917f8`.
    - README 를 R2 기준으로 고쳐 push 했다(`547fc06`). 옛 주소(Pages)도 같은 version 을 내보낸다 — 옛 앱을 위해 당분간 둔다.
    - 스킬: `apis.json` 의 `base`, 예시 주소(api.md·database.md·rendering.md·embedding.md, `assets/` 의 주석·기본값)를 R2 로 바꿨다(2026.10.01.2).
    - 필고 앱: `TravelService.defaultBaseUrl`·`tool/build_travel_db.dart` 를 R2 로 바꾸고, 앱 DB 빌더에 `data_version` 을 넣었다. 번들 DB(`assets/travel.db.gz`)를 R2 에서 다시 만들었다(`base` R2, version `4516764917f8`). `flutter test test/travel` 26개가 통과했다.
  - (2026-10-01) **CORS 설정** — 사용자가 키의 권한을 R2 관리(Admin Read & Write)로 올렸다. `r2.mjs cors` 명령을 더하고 버킷 `files` 에 origin `*`·GET·HEAD 규칙을 넣었다. 공개 응답의 `Access-Control-Allow-Origin: *` 와 사전 요청 204 를 확인했다.
    - 읽기 요청으로 키의 권한을 확인했다: R2 버킷 6개 모두 객체·설정을 읽을 수 있다. 도메인(Zone)은 0개가 보이고, Pages·KV·D1·Queues·Images·Stream·Turnstile·AI·결제·구성원은 막힌다. 계정 정보·Workers 스크립트·Tunnel·Access 목록 읽기는 성공했다(쓰기는 시험하지 않았다).
- **남은 일:**
  - ph-travel-api 의 Pages workflow(`.github/workflows/deploy.yml`)를 언제 끌지 사용자와 정한다. 옛 앱(옛 번들·옛 기본 주소)이 남아 있는 동안은 둔다.
  - ph-travel-api `build.mjs` 에 `data_version` 형식 검사를 넣는다. 지금은 `content.mjs check`·`r2.mjs` 만 막는다.
  - 근거 기록 `sources/`: 기존 198곳에는 없다. 항목을 고칠 때마다 채운다.
  - 사진: 178 파밀라칸 섬 대표 사진을 섬이 보이는 사진으로 바꾼다. gallery 가 2장이 안 되는 16곳(0장 6곳·1장 10곳)을 채운다. 위치 정보가 없는 413장은 고칠 때마다 눈으로 확인한다.
  - 문서가 가리키는 번역 지침·어휘집(`i18n/GUIDE.md`·`i18n/glossary/<언어>.json`)이 저장소에 없다. 번역 지침과 이름 표는 git 밖 작업 폴더(`_i18n/tools/`)에만 있다. 정리해 git 에 넣는다.
  - Node 22.14 의 내장 SQLite 에는 FTS5 가 없어 `travel.mjs`·`travel-db.mjs` 가 `no such module: fts5` 로 멈춘다. `--no-fts` 도 스키마를 통째로 실행한 뒤 색인 표를 지우는 순서라 같이 멈춘다. FTS5 가 없으면 색인 없이 만들도록 고친다.
  - 낡은 숫자: [rendering.md](rendering.md) §3 의 "지금 쓰이는 type 30개"는 33개다(`table`·`link`·`place_link` 가 쓰인다).
  - 101~200번 원본은 WebSearch 한도가 찬 뒤 WebFetch(위키백과·관광 사이트)로 확인해 썼다. 요금·배편·운영 시간은 "약"·범위와 "최신 공지 확인"으로 적었지만, 현지 사정을 아는 사람이 한 번 훑어보면 좋다.
  - 스킬의 SQLite·조회 구현·렌더러는 두 가지로 검증했다.
    - 다국어 계약 모양의 시험 데이터
    - 저장소 빌드 스크립트가 만든 8개 언어 출력. 번역본은 자리 표시 글자였다.
  - 8개 언어 번역이 모두 들어왔으니 세 조회 구현의 결과를 다시 비교한다(ko·en·zh 는 실제 번역으로 끝냈다).
  - 데이터 쪽 후속 결정(스킬 밖): 영어 번역 속 한국 독자 기준 문장(21곳)을 현지화할지, 예산 기준(1일·투어 1회)을 `budget.basis` 같은 언어 공통 key 로 둘지. 지금은 기준이 글 괄호에만 있어 `--sort budget` 이 기준이 다른 곳을 섞는다.
  - 필고 웹사이트에 여행 정보를 넣는다 — `travel.db` + `export` 폴더 + `TravelDb.php`([embedding.md](embedding.md) §3).
- **필고 Flutter 앱(`apps/travel`) — 끝냄(2026-09-30):**
  - v2 로 바꿨다. `travel_db.dart`·`travel_blocks.dart` 를 옮긴 코드는 필고 공용 라이브러리 `apps/lib/src/travel/` 에 있고, 옛 마크다운 사본·`fromMarkdown` 은 없다.
  - 오프라인 첫 실행 — 스냅샷 하나를 번들에 넣기로 정했다. 형식은 `places.json` 이 아니라 SQLite 다.
    - 앱의 `tool/build_travel_db.dart` 가 앱 언어(en·zh·ja·ko)로 전문 검색 색인까지 넣은 DB 를 만든다. `assets/travel.db.gz`(약 24MB) + 버전 파일 `assets/travel.db.json` 이다.
    - 기기 DB 가 없을 때, 또는 번들이 내용이 다르고(`version`) 더 새것일 때(`generated_at`)만 번들을 푼다. 서버에서 받아 둔 더 새 데이터를 앱 업데이트가 되돌리지 않게 한다.
    - 켤 때 한 번 `manifest.json` 으로 확인해 version 이 다르면 뒤에서 조용히 받는다(§6.2 그대로).

## 2. 왜 GitHub Pages 인가 — 2026-10-01 에 Cloudflare R2 로 바꿨다(§2.1)

- **요구 사항:** git push 만으로 배포, 읽기 전용 정적 데이터, 웹·앱이 받아 저장하고 업데이트 확인.
- **비교한 방법:**
  - Cloudflare Workers Static Assets + Workers Builds: 무료이고 요청 수 무제한이다. 계정 연결과 Worker 설정이 필요하다.
  - Cloudflare R2 + GitHub Actions: 비밀 키 관리가 필요하고, 캐시 무효화를 직접 설계해야 한다.
  - GitHub Pages: 모든 것이 GitHub 안에서 끝나서 가장 간단하다. → **선택.**
- **GitHub Pages 의 한계:**
  - 응답 헤더를 바꿀 수 없다. `Cache-Control: max-age=600` 이 고정이라, push 후 클라이언트에 보이기까지 최대 10분 걸린다.
  - 사이트는 1GB 까지다. 전송량은 월 100GB 권장 한도다.
  - 배포는 10분 안에 끝나야 한다.
- **옮겨야 할 때:** 한계를 넘거나 헤더를 제어해야 하면 옮긴다.
  - 1순위는 Cloudflare Workers Static Assets 다(무료 20,000 파일, 파일당 25MiB).
  - 사진만 매우 커지면 사진만 R2 로 옮긴다.
  - JSON 의 사진 url 이 상대 경로이므로, 계약([api.md](api.md) §4)을 지키면 클라이언트 코드를 거의 고치지 않고 옮길 수 있다.

## 2.1 왜 Cloudflare R2 로 바꾸나 (2026-10-01)

- **사용자 결정:** 배포는 반드시 Cloudflare R2 로 해서, 웹·앱이 공개 주소에서 곧바로 받게 한다.
  - R2 업로드 정보는 처음에 `/Users/thruthesky/Documents/Keys/Cloudflare/files.withcenter.com/files.withcenter.com-r2.txt` 에 있었고, 같은 날 사용자가 권한을 R2 관리로 올리며 `/Users/thruthesky/Documents/Keys/Cloudflare/r2/admin-permissions-all-r2.txt` 로 옮겼다. 버킷은 `files`, 공개 도메인은 `files.withcenter.com` 이다.
- **Pages 와 비교해 나아지는 것:** 응답 헤더를 정할 수 있다 — JSON 은 `no-cache` 라서 배포가 곧바로 보이고, Pages 처럼 10분을 기다리지 않는다. 사진은 1년 `immutable` 이다. 1GB·월 100GB 권장 한도에도 매이지 않는다.
- **올리는 방법 — 외부 패키지 없는 SigV4 서명(`r2.mjs`):**
  - 개발 컴퓨터에 aws CLI·wrangler·rclone 이 없다. 이 저장소들은 외부 패키지를 쓰지 않는다는 원칙도 있다.
  - 그래서 S3 호환 API 를 `node:crypto` 로 직접 서명한다. ListObjectsV2·PutObject·DeleteObject 만 쓴다.
- **안전장치:**
  - 공유 버킷이라 `<이름>/v<숫자>/` prefix 아래에만 올리고 지운다.
  - 사진 → 언어 파일 → meta → manifest 순서로 올리고, 지우기는 manifest 뒤에 한다. 중간에 멈춰도 클라이언트는 옛 데이터를 그대로 받는다.
  - 올리기 전에 배포 규격 검사(`checkBuild`)를 한다. ETag(MD5)를 비교해 바뀐 파일만 올린다.
- **CORS:** 처음에는 키 권한이 모자라 넣지 못했다. 사용자가 권한을 올린 뒤 `r2.mjs cors --set` 으로 origin `*`·GET·HEAD 를 열었다(2026-10-01). 공개 읽기 전용 데이터라 모든 도메인에 열어도 된다고 판단했다.
- **옮긴 날:** 2026-10-01 에 첫 배포를 확인하고 공개 주소를 R2 로 바꿨다(§1). 옛 주소(Pages)는 `main` push 로 계속 배포되며, 끌 때는 사용자와 정한다.

## 3. 왜 블록 JSON 인가 (2026-09-27)

- **요구 사항:** 웹·앱이 속성·문단·낱말마다 다른 디자인을 입힐 수 있어야 한다. 표시 방법(content_display_type)을 미리 정해 JSON 과 함께 내려야 한다.
- **비교한 방법:**
  - Quill Delta(`insert` + `attributes`): 글 꾸밈에는 가볍지만 탭·카드·표 같은 구조를 담기 어렵다.
  - Draft.js 식 offset 스타일: 글자 위치로 꾸밈을 적는다. Dart(UTF-16)·JS·서버의 글자 세기가 달라 어긋나기 쉽다.
  - Editor.js 식 블록 + Slate 식 조각: 문단·위젯은 블록, 글 안의 꾸밈은 조각 배열로 쓴다. → **선택.**
- **선택한 모양:**
  - 블록은 `type` + 데이터다. 블록 안의 블록은 `blocks`, 글은 `children` 조각 배열에 담는다.
  - 조각은 `{ text, type?, bold? … }` 다. 이어 붙이면 원문이 되므로 검색·복사·음성 읽기가 쉽다.
  - 속성마다 type 을 붙였다. 목록 거르기용 값(`months`·`min`·`max`·`code`·`value`)은 같은 노드 안에 둔다.
- **표시 방법 목록을 데이터로 둔 이유:**
  - 목록의 `props` 가 곧 검사 규격이라서 문서와 검사가 어긋날 수 없다.
  - 클라이언트도 같은 파일로 무엇을 구현할지(`used`) 안다.
- **v1 을 없앤 이유:**
  - v1 은 같은 날 처음 배포됐다. 필고 앱은 아직 번들 md 를 읽고 있어서 v1 을 받는 클라이언트가 없었다.
  - 마크다운 원본이 사라지므로 v1 을 유지하려면 JSON → 마크다운 역변환이 필요하다. 쓰는 곳이 없어서 만들지 않았다.
- **문장 단위는 나누지 않았다.** 단락은 블록, 낱말·표현은 조각이다. 문장까지 나누면 JSON 이 커지고 렌더러가 복잡해진다. 그에 비해 쓰임이 적다.

## 4. 왜 스킬로 옮기고 Pages 로 나눠 주는가 (2026-09-27)

> 스킬의 위치·이름·배포 방법은 2026-09-30 에 바뀌었다(§4.1). 아래는 그 전의 결정이다.

- **AGENTS.md 를 스킬로 옮긴 이유:**
  - 이 저장소 밖(필고 앱, 다른 웹 프로젝트)에서 API 를 쓰는 AI 도 같은 지식이 필요하다.
  - AGENTS.md 는 저장소 안에서만 읽힌다. 스킬은 어디에나 설치해 `/travel-api-skill` 로 부를 수 있다.
  - AGENTS.md 에는 스킬을 가리키는 안내와 절대 규칙만 남겼다.
- **원본은 `skills/travel-api-skill/`, 입구는 `.claude/skills/travel-api-skill/SKILL.md`:**
  - 설치용 폴더와 이 저장소의 Claude Code 가 읽는 폴더를 나눴다.
  - 입구 SKILL.md 가 원본을 읽으라고 안내한다. 디렉터리 심볼릭 링크를 쓰지 않은 이유는 두 가지다. 도구마다 심볼릭 링크를 따라가는 동작이 달라서다. 그리고 참조 경로가 설치 위치에서도 그대로 맞아야 해서다.
- **스킬 묶음을 Pages 로 나눠 주는 이유:**
  - GitHub 의 저장소 tarball 은 사진(23MB)까지 받는다.
  - 빌드가 스킬 폴더만 tar.gz 로 묶어 Pages 에 올리면 설치·`update` 가 수십 KB 로 끝난다. 명령도 `curl … | tar -xz` 한 줄이다.
- **나라가 늘어날 것에 대비:**
  - 스킬 이름에 나라를 넣지 않았다(`travel-api-skill`).
  - 나라 목록을 `scripts/apis.json` 으로 뺐다. 새 나라는 같은 구조의 저장소 + 한 줄 추가로 끝난다.

## 4.1 왜 thruthesky/skills 로 옮기고 api-skill 로 이름을 바꿨나 (2026-09-30)

- **사용자 결정:** 스킬을 ph-travel-api 저장소에서 스킬 마켓플레이스 저장소 [thruthesky/skills](https://github.com/thruthesky/skills) 의 `skills/api-skill/` 로 옮기고, 이름을 `travel-api-skill` → `api-skill` 로 바꿨다.
- **Claude Code 는 플러그인으로 받는다.**
  - `claude plugin marketplace add thruthesky/skills` → `claude plugin install api-skill@thruthesky-skills`.
  - 플러그인 폴더 바로 아래에 `SKILL.md` 만 두면 단일 스킬로 불러온다. 부르는 이름은 `/api-skill:api-skill` 이다.
  - 업데이트는 `version` 으로 나간다. 그래서 `SKILL.md`·`plugin.json`·마켓플레이스 세 곳의 version 을 함께 올린다.
- **다른 도구(Codex·Gemini CLI·Copilot CLI)는 폴더로 받는다.**
  - GitHub 의 thruthesky/skills 저장소 묶음(사진이 없어 1MB 미만)을 받아 `skills/api-skill` 만 `~/.agents/skills/api-skill` 에 푼다.
  - §4 에서 Pages 묶음을 따로 만든 이유(ph-travel-api 저장소 묶음에 사진 23MB 가 들어감)는 이 저장소에는 해당하지 않는다.
- **ph-travel-api 는 스킬 파일을 갖지 않는다.**
  - `.claude/settings.json` 으로 이 프로젝트에서 플러그인을 켠다(`--scope project`). 저장소를 연 Claude Code 는 처음에 마켓플레이스 추가·설치를 묻는다.
  - 빌드의 스킬 검사와 스킬 묶음(`_site/skills/travel-api-skill.tar.gz`)을 없앴다. 옛 묶음 주소는 그다음 배포부터 404 다.
  - 옛 입구 `.claude/skills/travel-api-skill/` 과 원본 `skills/travel-api-skill/` 을 지웠다. 스킬 원본이 두 저장소에 나뉘어 어긋나는 일을 막기 위해서다.
- **캐시 폴더**도 `~/.cache/travel-api-skill/` → `~/.cache/api-skill/` 로 바꿨다. 옛 캐시는 쓰지 않으니 지워도 된다.
- **새 분야:** 이름이 분야 없는 `api-skill` 이 됐다. 그래서 새 분야(밤문화 등)를 이 스킬에 더할지, 스킬을 따로 만들지는 사용자에게 먼저 확인한다([blueprint.md](blueprint.md) §3).

## 5. 왜 8개 언어를 파일 이름으로 나누는가 (2026-09-28)

- 언어 폴더(`v2/ko/places.json`) 대신 파일 이름(`v2/places.ko.json`)으로 나눴다.
  - 사진 url `images/…` 가 어느 언어 파일에서나 같은 폴더 기준으로 맞는다.
  - 사진을 언어마다 복사하지 않는다.
- version 은 전체에 하나다(meta + 모든 언어 places). 클라이언트는 manifest 하나만 보고 무엇이 바뀌었는지 안다.
- 언어 무관 값(좌표·예산 숫자·사진·링크 …)은 파일마다 반복된다. 빌드가 원본(ko)과 같은지 검사한다. 그래서 어느 언어 파일 하나만 받아도 완전하다 — 앱은 필요한 언어만 넣으면 된다.
- 분류·권역·지역 노드에 언어 공통 key(`value`)를 넣었다. 언어가 바뀌어도 거르기·링크·DB 키가 같다.

## 6. 왜 넣어 쓰기(임베딩)와 SQLite 인가 (2026-09-28)

- **요구 사항:**
  - 웹·앱은 원격 API 를 실행 중에 부르지 않고, 데이터를 받아 제품에 넣어 쓴다.
  - 8개 언어의 본문을 언어별로 검색할 수 있어야 한다.
  - 필고 웹은 로컬에서 만든 DB 파일을 서버에 올려 PHP 로 조회한다.
- **넣어 쓰는 이유:** 오프라인·첫 화면 속도, Pages 전송량 한도와 무관, 데이터 버전 고정, 방문 기록이 외부에 남지 않음([embedding.md](embedding.md) §1).
- **SQLite 를 고른 이유:**
  - 파일 하나라 올리기·넣기가 쉽다.
  - PHP·Dart·Node·Python 이 모두 읽는다.
  - FTS5·인덱스가 있다.
  - 비교한 것: 언어별 JSON 을 메모리에서 훑기는 정적 웹·단순 앱에 충분하다(embedding.md §5). 하지만 서버 검색·다국어 전문 검색에는 색인이 낫다.
- **FTS5 trigram 을 고른 이유:**
  - `unicode61` 토크나이저는 띄어쓰기로 낱말을 자른다. 그래서 중국어·일본어·태국어는 문장 전체가 한 낱말이 되고, 한국어는 조사 때문에 "엘니도"로 "엘니도에서"를 못 찾는다.
  - trigram 은 3글자 단위 부분 문자열이라 모든 언어에서 동작한다.
  - 대가 두 가지: 3글자 미만을 못 찾아서 글에서 직접 찾아 보완한다. 색인이 커서 언어당 약 1.4MB 다.
- **외부 콘텐츠 FTS · 일반(rowid) 표:**
  - 처음 스키마(WITHOUT ROWID + FTS 가 글 복사)는 3개 언어에 20.7MB 였다.
  - 바꾼 뒤 15.1MB 가 됐다.
- **DB 를 API 로 배포하지 않은 이유:**
  - API 는 JSON 만 내고, DB 는 쓰는 쪽이 스킬 도구로 만든다.
  - 언어·FTS 여부를 제품마다 고르고, 스키마를 스킬과 함께 바꿀 수 있다.
  - 모든 언어 DB 를 Pages 에 올리면 한 파일이 40MB 안팎이 된다.
  - 필요해지면 빌드에 `travel-db.mjs build` 를 더해 `_site/v2/travel.db` 로 낼 수 있다.
- **Node 도구가 내장 `node:sqlite` 를 쓰는 이유:** 외부 패키지 금지 원칙을 지킨다. Node 22.13+ 가 필요하다(Actions·개발 환경은 24).

## 7. 왜 data_version 을 따로 두나 (2026-10-01)

- **사용자 결정:** `meta.json` 에 정보를 가공한 UTC 날짜를 버전으로 적는다.
- **키 이름 `data_version`:** 원본 `meta.json` 에 `version` 을 넣으면 `build.mjs` 가 출력 meta 를 `{ ...head, ...meta }` 로 쓰면서 내용 해시를 덮는다. 그러면 `meta.version ≠ manifest.version` 이 되어 받는 쪽 검사(`checkBundle`)가 실패한다. 그래서 다른 이름을 쓴다.
- **`version` 은 그대로 둔다:** 내용 해시라서 사람이 찍기를 잊어도 바뀐 내용을 놓치지 않는다. 다시 받을지는 `version` 으로 정하고, `data_version` 은 "정보 기준일"을 보여 줄 때 쓴다.
- **형식 `YYYY-MM-DDTHH:MM:SSZ`:** 하루에 여러 번 가공해도 순서가 갈린다. 날짜로 시작해 글자 순서가 시간 순서다. UTC 라서 작업자의 시간대와 무관하다.
- **찍는 법:** `content.mjs stamp` 는 값만 바꾸거나 첫 키로 넣는다. 파일의 다른 줄은 그대로 둔다. 빌드는 모르는 최상위 키를 막지 않으므로 지금 `build.mjs` 그대로 통과한다(198곳 빌드로 확인했다).

## 8. 왜 콘텐츠 다섯 가지인가 (2026-10-01)

- **사용자 결정:** 콘텐츠를 만들거나 가공할 때 다음을 반드시 지킨다.
  1. 인터넷 검색을 넉넉히 하고 같은 정보를 여러 출처에서 비교한다.
  2. 정보와 맞는 정확한 사진을 넣는다.
  3. 8개 언어로 번역한다.
  4. `meta.json` 형식을 따르고 `data_version` 을 적는다.
  5. R2 로 배포한다.
- **근거를 git 에 두는 이유:** 200곳을 보완할 때의 근거(`_i18n/tools/changes/`)를 git 밖에 두었다가 잃었다. 그래서 `sources/<id>-<slug>.json` 을 데이터 저장소에 둔다. `data/` 안에는 두지 않는다 — `build.mjs` 가 모르는 폴더를 막는다.
- **사진 검사를 도구로 만든 이유:** 200곳 보완 때 다른 장소가 찍힌 사진 3장을 찾았다. Commons 의 촬영 위치·라이선스·작가를 자동으로 대조하면 눈으로 볼 사진이 줄어든다. 다만 위치 정보는 사진의 약 27% 에만 있어서 눈으로 확인하는 일은 남는다.
- **8개 언어를 배포 조건으로 둔 이유:** 빌드는 번역 폴더가 없는 언어를 배포에서 빼고 통과한다. 그래서 배포 도구가 8개 언어를 따로 확인한다.
