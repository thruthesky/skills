# 콘텐츠 파이프라인 — 조사·만들기·가공·분석·문서화·배포

api-skill 로 정보 콘텐츠를 만들거나 고칠 때의 규격이다. 여행지 추가·수정(ph-travel-api)과 같은 형태의 새 정보 API(blueprint) 모두에 적용된다.
이 문서의 명령에서 `<스킬>` 은 스킬 폴더(이 문서의 상위 폴더)다. 저장소 명령은 데이터 저장소 뿌리에서 실행한다.

## 목차

1. 반드시 지킬 다섯 가지
2. 흐름과 산출물
3. 조사 — 여러 출처를 비교한다
4. 사진 — 정보와 맞는 정확한 사진
5. 번역 — 8개 언어
6. meta.json 규격과 data_version
7. 배포 — Cloudflare R2
8. 분석과 문서화
9. 끝났다는 기준

## 1. 반드시 지킬 다섯 가지

| # | 규칙 | 왜 | 무엇이 막나 |
|---|------|----|-------------|
| 1 | **인터넷 검색을 넉넉히 하고, 같은 사실을 여러 출처에서 비교해 가공한다** | 출처 하나는 낡았거나 틀리기 쉽다. 200곳을 다시 확인했을 때 좌표 34곳·사진 3장·노선 여러 개가 틀려 있었다 | 근거 기록 `sources/*.json` (§3) |
| 2 | **항목마다 사진을 10장 이상 모으고, 사진은 모두 정보와 맞는 정확한 사진이어야 한다** | 사진 3장으로는 그곳의 전경·명소·활동·계절을 보여 주지 못한다. 다른 장소의 사진 한 장은 글 전체의 신뢰를 깎는다 | `content.mjs check`(10장 미만이면 배포 거부)·`photos`·`fetch`·`images` + 눈으로 확인 (§4) |
| 3 | **8개 언어로 번역한다 — ar·en·ja·ko·ru·th·vi·zh** | 웹·앱이 8개 언어로 보여 준다. 하나라도 빠지면 그 언어 사용자에게는 대체 언어(en)가 보인다 | `content.mjs check`, `r2.mjs` 가 배포를 거부 (§5) |
| 4 | **`meta.json` 의 모든 형식을 따르고, `meta.json` 에 가공한 UTC 시각을 `data_version` 으로 적는다** | 규격 밖의 노드는 화면이 그리지 못한다. 정보 기준 시각은 웹·앱이 "정보 기준일"로 보여 준다 | `build.mjs`, `content.mjs check` (§6) |
| 5 | **배포는 Cloudflare R2 로 한다** | 웹·앱이 공개 주소에서 곧바로 받는다 | `r2.mjs deploy`·`verify` (§7) |

- 다섯 가지는 콘텐츠를 **새로 만들 때도, 고칠 때도, 기존 자료를 가공할 때도** 같다.
- 배포(5)는 운영 반영이라 사용자가 배포를 요청했을 때만 한다. 요청에 "배포"가 없으면 커밋까지 하고 배포 명령을 알려 준다.

## 2. 흐름과 산출물

| 단계 | 할 일 | 산출물 | 근거 |
|------|-------|--------|------|
| 0. 판별 | 작업 종류와 맞는 정보인지 본다 | — | SKILL.md §3, [blueprint.md](blueprint.md) §1 |
| 1. 조사 | 검색하고 출처를 비교한다 | `sources/<id>-<slug>.json` | §3 |
| 2. 만들기·가공 | 원본 언어(ko)로 쓴다. 기존 자료는 일회성 스크립트로 바꾼다 | `data/ko/<id>-<slug>.json` | 저장소 `data/README.md`, [blueprint.md](blueprint.md) §7 |
| 3. 사진 | 10장 이상 찾고, 보고, 줄이고, 출처를 적는다 | `data/images/<id>-<slug>[-2 … -10].webp` | §4 |
| 4. 번역 | 7개 언어를 맞춘다 | `data/<언어>/<id>-<slug>.json` | §5 |
| 5. 버전 | `data_version` 을 찍는다 | `data/meta.json` | §6.2 |
| 6. 검사·분석 | 빌드 → 배포 규격 검사 → 조회 도구로 질문에 답해 본다 | `_site/v2/` | §8 |
| 7. 문서화·커밋 | 결정·남은 일을 적고 한글로 커밋한다 | `history.md`, 커밋 | §8 |
| 8. 배포 | (요청이 있을 때) R2 에 올리고 공개 주소로 확인한다 | 공개 주소 | §7 |

```bash
# 저장소 뿌리에서 — 5~6단계와 8단계
node <스킬>/scripts/content.mjs stamp data/meta.json          # data_version = 지금 UTC 시각
node scripts/build.mjs                                         # 규격 검사 + _site/v2/
node <스킬>/scripts/content.mjs check --dir _site/v2           # 8개 언어·data_version·항목마다 사진 10장·credit
node <스킬>/scripts/content.mjs images --dir _site/v2 --ids 201,202   # 새·바뀐 항목의 사진을 Commons 정보와 대조
node <스킬>/scripts/travel.mjs --base _site/v2 search <새 항목 이름>     # 분석 — 질문에 답이 나오는지
node <스킬>/scripts/r2.mjs deploy --dir _site/v2 --country ph --dry-run  # 배포 계획
node <스킬>/scripts/r2.mjs deploy --dir _site/v2 --country ph            # 배포 + 공개 주소 확인
```

## 3. 조사 — 여러 출처를 비교한다

### 3.1 출처 등급

| 등급 | 출처 | 쓰임 |
|------|------|------|
| A | 운영 주체·정부·공식 — 관광부(DOT)·지방정부(LGU)·공원 관리소, 항공사·선사·버스 회사 공식 사이트, 외교부 해외안전여행 | 요금·규정·운항의 기준 |
| B | 공신력 있는 2차 — 주요 언론 기사, 위키백과(출처가 달린 문장), OSM·Google 지도, 가이드북 출판사 | A 를 뒷받침하거나 A 가 없을 때 |
| C | 개인 — 블로그·후기·포럼·SNS | 최근 현지 사정의 단서. **혼자서는 근거가 되지 못한다** |

### 3.2 사실마다 필요한 출처

| 사실 | 최소 기준 | 쓰는 법 |
|------|-----------|---------|
| 요금·운임·입장료·운영 시간·시간표 | 서로 다른 출처 2곳 이상, 그중 하나는 A 이거나 12개월 안의 B | "약"·범위, `costs` 단락의 "2026년 기준 대략치" |
| 규정·허가·환경세·예약제·폐쇄·재해·여행금지 | A 1곳 + 최근 기사 1곳 | "최신 공지를 확인" 을 붙인다 |
| 교통 노선(항공·배·버스) | 운영사 공식 + 1곳, 운항 중단 여부는 최근 기사로 | 출발지·소요 시간·요금을 함께 |
| 좌표 | 지도 2곳(OSM·Google 지도·위키백과 좌표)이 같은 곳을 가리킨다 | 소수 4자리 |
| 역사·지리 수치(연도·높이·면적) | 2곳 | 위키백과는 그 문장의 출처까지 본다 |
| 업소·숙소 이름 | 2곳 + 최근 12개월 안의 영업 흔적 | 오래 운영된 유명 업소만 |
| 분위기·특징 같은 서술 | 1곳 이상 | 단정적인 수치를 넣지 않는다 |

### 3.3 검색하는 법

- **사실 하나에 질의 여러 개.** 이름을 바꿔(영문·현지어(타갈로그·세부아노 …)·한국어 표기·옛 이름), 연도를 붙여(`2026`, `2025`), 운영사 이름을 붙여 찾는다.
- **WebSearch 로 후보를 찾고 WebFetch 로 본문을 연다.** 검색 결과의 요약·스니펫이나 AI 요약만 보고 쓰지 않는다.
- **날짜를 본다.** 게시·수정일이 없는 요금표는 C 로 본다. 2년 넘은 글의 요금은 쓰지 않는다.
- **같은 사실을 다른 언어로도 찾는다.** 현지 언론(영어), 한국 여행자 정보(한국어) 등.
- WebSearch 한도가 차면 WebFetch 로 공식 사이트·위키백과를 직접 연다(101~200번을 쓸 때 이렇게 했다 — [history.md](history.md)).
- 여러 항목에 걸친 사실(공항 이전·노선 종료·요금 인상·재해)은 찾은 뒤 **모든 항목을 교차 점검**해 맞춘다.

### 3.4 출처가 어긋날 때

1. 더 공식적이고 더 최근인 것을 쓴다.
2. 그래도 갈리면 범위로 쓰고 "약"·"최신 공지를 확인" 을 붙인다.
3. 폐쇄·운항 중단이 확인되면 본문에서 뺀다. 항목 전체가 성립하지 않으면 항목을 뺀다(번호는 다시 쓰지 않는다).
4. 근거 기록의 `decision` 에 이유를 적는다.

### 3.5 근거 기록 — `sources/<id 3자리>-<slug>.json`

- **위치:** 데이터 저장소 뿌리의 `sources/`. git 에 넣고, 배포하지 않는다.
  - `data/` 안에 두지 않는다 — `build.mjs` 는 `data/` 에 모르는 폴더가 있으면 실패한다.
  - git 밖에 두지 않는다 — 200곳을 다시 확인할 때 쓴 근거(`_i18n/tools/changes/`)는 git 밖에 있다가 사라졌다.
- **언제:** 항목을 만들거나 사실을 고칠 때마다 함께 쓴다. 언어와 무관하므로 항목마다 파일 하나다.
- **무엇을:** 바뀌는 값(§3.2 위쪽 다섯 줄)은 모두, 서술은 중요한 것만. 사진도 적는다.

```json
{
  "id": 30,
  "slug": "vigan",
  "checked_at": "2026-10-01T05:12:33Z",
  "facts": [
    {
      "where": "getting_there",
      "fact": "마닐라–비간 버스 요금",
      "value": "₱900~1,200",
      "sources": [
        { "url": "https://…", "grade": "A", "date": "2026-08-12", "says": "₱950 (일반 에어컨)" },
        { "url": "https://…", "grade": "B", "date": "2026-05-03", "says": "₱1,150 (디럭스)" }
      ],
      "decision": "버스 등급마다 달라 범위로 씀"
    }
  ],
  "images": [
    { "file": "030-vigan.webp", "source": "https://commons.wikimedia.org/wiki/File:…", "check": "비간 대성당 정면 — Commons 분류 Vigan Metropolitan Cathedral, overview 의 성당 설명과 같다" }
  ]
}
```

## 4. 사진 — 정보와 맞는 정확한 사진

### 4.1 몇 장 — 항목마다 10장 이상

- **항목마다 사진을 10장 이상 모은다 — 대표 사진(`image`) 1장 + `gallery` 9장 이상.** 2026-10-02 에 3장에서 10장으로 올렸다. 사진 3장으로는 그곳이 어떤 곳인지 보여 주지 못해서다.
- `content.mjs check` 는 10장이 안 되는 항목이 하나라도 있으면 오류로 끝나고, `r2.mjs deploy` 도 같은 검사로 배포를 막는다.
  - 2026-10-02 지금 198곳 모두 3장이다(모자란 사진 1,408장). 옛 항목을 채우는 동안 다른 고침을 내보내야 하면 `--allow-few-images` 를 붙인다. 이때도 모자란 항목 수가 알림으로 나온다.
  - **새 항목과 고치는 항목은 이 옵션 없이 10장을 채운다.** 항목을 고칠 때는 그 항목의 사진부터 10장으로 채운다.
- 10장은 같은 사진을 여러 장 넣는 것이 아니라 **그곳을 여러 면에서 보여 주는 것**이다. 아래 종류를 고루 섞는다.

  | 종류 | 예 (비간) | 장수 |
  |------|-----------|------|
  | 대표 전경 — 그곳을 한눈에 알 수 있는 사진 | 칼레 크리솔로고 거리 전경 | 1 (대표 사진) |
  | 다른 각도·시간의 전경 | 밤의 칼레 크리솔로고, 하늘에서 본 구시가 | 2~3 |
  | 본문 `highlights` 의 명소·볼거리 | 비간 대성당, 바타이 탑, 살세도 광장 분수, 부르나이 도자기 공방 | 3~4 |
  | 활동·체험 | 칼레사(마차) 타기, 도자기 빚기 | 1~2 |
  | 음식·생활·축제 — 그곳의 것이 분명할 때만 | 비간 롱가니사 축제 거리 공연 | 0~2 |

- 대표 사진은 장소가 보이는 사진이다. 생물·음식·활동 사진은 gallery 에 둔다(§4.4 의 파밀라칸 섬 예).
- 거의 같은 구도의 사진, 같은 작가가 같은 날 연달아 찍은 사진은 한 장만 고른다.
- 정확한 사진을 10장 구할 수 없으면 그 항목을 넣지 않거나 다른 항목으로 바꾼다. 맞지 않는 사진으로 장수를 채우지 않는다. Commons 에 사진이 없는 단후간 섬·카파르칸 폭포를 다른 곳으로 바꾼 것이 그 예다.

### 4.2 고르는 순서

1. **찾는다** — `content.mjs photos --dir _site/v2 --id <번호>` 가 후보를 모아 준다. 그곳 이름의 분류(`Category:<영문 이름>`), 이름 검색, 좌표 주변(`--km`, 기본 3km)에서 찾고, 이미 쓴 사진·가로 1080px 미만·쓸 수 없는 라이선스(NC·ND·출처 불명)는 뺀다.
   - 모자라면 직접 찾는다 — Commons 에서 `"<영문 이름>" <지역>`, 하위 분류(`Category:<명소 이름>`), 그 장소 위키백과 문서에 실린 사진.
2. **파일 페이지를 읽는다** — 제목·설명·분류·촬영 위치(Location)·촬영일·라이선스.
3. **받는다** — `content.mjs fetch --title "File:….jpg" --out data/images/<id>-<slug>-<n>.webp --alt <이름>`.
   - Commons 가 가로 1080px 로 줄인 사진을 받아 WebP(`cwebp -q 80`, 없으면 `magick`)로 저장한다.
   - 데이터에 넣을 image 노드(`credit` = `작가 / 라이선스 / Wikimedia Commons`, `source` = 파일 페이지 주소)를 출력하고, 받은 원본 JPEG 의 경로를 알린다.
   - 손으로 할 때는 `cwebp -q 80 -resize 1080 0 원본.jpg -o data/images/<id>-<slug>-<n>.webp` 다.
4. **직접 본다** — fetch 가 알려 준 JPEG(또는 `sips -s format jpeg x.webp --out x.jpg` 로 바꾼 파일)를 Read 로 열어 본다. §4.3 의 기준을 하나라도 못 넘으면 지운다.
5. **넣는다** — 원본(`data/ko/`)의 `gallery.items` 에 image 노드를 넣고 `alt` 를 그 사진의 내용으로 쓴다(예: `비간 대성당`). 근거 기록 `images` 에 무엇을 보고 맞다고 판단했는지 적는다.
6. **번역한다** — gallery 가 늘면 번역본과 모양이 달라진다. `alt` 는 번역하는 글이라 `i18n.mjs export` → 번역 → `check` → `import` 로 7개 언어를 맞춘다(§5).

### 4.3 맞는 사진의 기준

| 기준 | 통과 | 떨어짐 |
|------|------|--------|
| 대상 | Commons 설명·분류에 그 장소 이름이 있다 | 이름이 없다. 비슷한 다른 곳(이웃 섬·같은 이름의 다른 지역)이다 |
| 위치 | 촬영 위치가 항목 좌표에서 15km 안이다. 넓은 섬·주·산은 멀리서 찍은 전경이 본문 설명과 맞을 때만 더 멀어도 된다 | 다른 섬·다른 도시에서 찍었다 |
| 내용 | 본문이 말하는 모습 그대로다(초콜릿 힐스는 원뿔 언덕 무리, 폭포 항목은 그 폭포) | 음식·실내·사람만 보여 장소를 알 수 없다 |
| 시기 | 재해·폐쇄·재건으로 모습이 바뀐 곳은 바뀐 뒤의 사진이다 | 무너지기 전 모습만 있다 |
| 권리 | CC BY·CC BY-SA·CC0·퍼블릭 도메인이고 credit·source 를 채울 수 있다 | 출처 불명·스톡·SNS 사진·AI 생성 그림 |
| 품질 | 워터마크·로고·큰 글자가 없고 사람 얼굴이 주제가 아니다. 원본 가로 1080px 이상 | 흐리거나 작다 |

### 4.4 검사 도구 — `content.mjs images`

```bash
node <스킬>/scripts/content.mjs images --dir _site/v2 [--ids 30,62] [--km 15] [--json]
```

사진마다 Commons API 로 촬영 위치·라이선스·작가·설명·분류를 받아 항목과 대조한다. 판정은 넷이다.

| 판정 | 뜻 | 할 일 |
|------|----|-------|
| 고칠 것 | Commons 에 없는 파일, credit 의 라이선스가 Commons 와 다르다 | 고친다. 하나라도 있으면 exit 1 |
| 먼저 볼 것 | 촬영 위치가 `--km`(기본 15km)보다 멀다 | 사진을 열어 본다. 넓은 섬·주라면 두고, 다른 곳이면 바꾼다 |
| 눈으로 볼 것 | 위치 정보가 없다, 작가 이름이 credit 과 다르다 | 출력된 설명·분류를 보고 사진을 열어 본다 |
| 맞음 | 위치 15km 안, 라이선스·작가 일치 | — |

- 실측(2026-10-01, 572장): 맞음 149 · 위치 정보 없음 413 · 먼 촬영 위치 8 · Commons 가 아닌 출처 1.
  - 먼 8장 중 6장은 넓은 섬·주의 다른 쪽에서 찍은 같은 곳이었다(기마라스의 타클롱 섬, 마린두케의 마니와야 섬 등).
  - 2장은 장소가 아니라 그곳의 생물을 찍었다. 077 타르시어 보호구역의 안경원숭이(보홀의 다른 곳에서 찍음)는 주제와 맞는다. 178 파밀라칸 섬의 대표 사진은 팡라오 앞바다의 돌고래라서 섬이 보이지 않는다 — 대표 사진은 장소가 보이는 사진으로 고르고, 생물·활동 사진은 gallery 에 둔다.
- Commons 사진의 약 70% 는 위치 정보가 없다(구조화 데이터 좌표를 더해도 8장만 늘었다). 도구는 눈으로 볼 사진을 줄여 줄 뿐, 보는 일을 대신하지 않는다.

## 5. 번역 — 8개 언어

| 코드 | 언어 | 비고 |
|------|------|------|
| `ko` | 한국어 | 원본 언어. 먼저 고친다 |
| `en` | 영어 | 대체 언어 — 없는 언어 대신 보인다 |
| `zh` | 중국어 | 간체(`zh-Hans`)·중국 대륙 표기 |
| `ja` | 일본어 | |
| `th` | 태국어 | 띄어쓰기 없는 언어 — 검색 확인 때 2~4글자로 띄운다 |
| `vi` | 베트남어 | |
| `ru` | 러시아어 | |
| `ar` | 아랍어 | 오른쪽→왼쪽(`dir: rtl`) |

- 원본(`data/ko/`)을 고친 뒤 `scripts/i18n.mjs` 로 맞춘다 — `sync`(숫자·코드·사진 옮기기) → `export` → 번역 → `check <언어>` → `import <언어>`. 명령은 저장소 `data/README.md` §7.
- **바뀐 글만 다시 번역한다.** 원본을 고치기 전의 번역 줄을 남겨 두고, 원문이 같은 줄은 옛 번역을 채운다.
- 지명·분류·태그는 언어별 어휘집 표기를 따른다(`i18n/glossary/<언어>.json` — 지금은 git 밖 `_i18n/glossary/` 에 있다, [history.md](history.md) 남은 일).
- 금액·숫자·시각은 원문과 같은 값이다. 한국 독자에게만 맞는 문장("인천에서 출발하면")은 그 언어 독자에 맞게 옮긴다.
- **끝 기준:** 원본 외 7개 언어 폴더에 모든 항목이 있고, `build.mjs`(모양 비교·한글 잔존·길이 비율)와 `content.mjs check`(8개 언어)가 통과한다.
- 새 API 는 서너 건으로 파이프라인을 뚫을 때 ko·en 만으로 돌려도 된다. 배포 전에는 8개 언어가 모두 있어야 한다.

## 6. meta.json 규격과 data_version

### 6.1 규격을 따른다

- 모든 노드의 `type` 은 `meta.display.types` 의 48개 중 하나이고, 키는 그 type 의 `props` 규격대로다. 모르는 키를 쓰지 않는다.
- 속성은 `meta.fields` 의 키·순서·type, 본문은 `meta.sections` 의 key·순서·제목·아이콘을 따른다.
- 분류·지역 같은 값은 `meta.json` 목록의 key 로 쓴다. 새 값은 `meta.json` 에 8개 언어 이름과 함께 먼저 넣는다.
- 새 type 이 필요하면 추가만 한다([maintain.md](maintain.md) §6.3). 있는 type 의 뜻·키는 바꾸지 않는다.
- `build.mjs` 가 이 규격을 모두 검사한다. 통과하지 못하면 아무것도 쓰지 않고 exit 1 이다.

### 6.2 data_version — 정보를 가공한 UTC 시각

| 키 | 누가 쓰나 | 형식 | 뜻 | 쓰임 |
|----|-----------|------|----|------|
| `version` | `build.mjs` (자동) | 내용 해시 12자리 | 내용이 바뀌었는지 | 클라이언트가 다시 받을지 정한다 |
| `data_version` | 가공한 사람 (`content.mjs stamp`) | `YYYY-MM-DDTHH:MM:SSZ` (UTC) | 정보를 마지막으로 가공한 시각 | 화면의 "정보 기준일", 배포 기록 |

- **자리:** 원본 `data/meta.json` 의 최상위 첫 키. 빌드가 출력 `meta.json` 에 그대로 싣는다(`{ schema, version, data_version, title, … }`). `travel-db.mjs` 가 DB `meta` 표에 `data_version` 으로 넣고, `travel.mjs info` 가 "정보 기준"으로 보여 준다.
- **언제 찍나:** 원본·번역·사진을 바꾼 커밋마다, 커밋 직전에 찍고 다시 빌드한다. 문서만 바꾼 커밋은 찍지 않는다 — 그래야 version 이 그대로다.
- **왜 키 이름이 `version` 이 아닌가:** `build.mjs` 는 출력 meta 를 `{ ...head, ...meta }` 순서로 쓴다. 원본에 `version` 을 넣으면 내용 해시를 덮어써서 `meta.version ≠ manifest.version` 이 되고, 받는 쪽 검사(`checkBundle`)가 실패한다.
- **왜 초까지, 왜 UTC 인가:** 하루에 여러 번 가공해도 순서가 갈린다. 날짜로 시작해 글자 순서가 곧 시간 순서다. 작업자의 시간대와 무관하다.
- 새 API 의 `build.mjs` 에는 `data_version` 형식 검사를 넣는다([blueprint.md](blueprint.md) §5.1). ph-travel-api 의 `build.mjs` 는 아직 검사하지 않고, `content.mjs check` 와 `r2.mjs` 가 막는다.

`stamp` 의 핵심 — 파일의 다른 줄(한 줄로 쓴 짧은 객체 등)을 건드리지 않는다:

```js
const now = new Date().toISOString().replace(/\.\d{3}Z$/, 'Z');           // 2026-10-01T05:12:33Z
const line = `"data_version": "${now}"`;
const out = /"data_version"\s*:\s*"[^"]*"/.test(text)
  ? text.replace(/"data_version"\s*:\s*"[^"]*"/, line)                     // 있으면 값만 바꾼다
  : text.replace(/^\{\s*\n([ \t]*)/, (_, i) => `{\n${i}${line},\n${i}`);   // 없으면 첫 키로 넣는다
if (JSON.parse(out).data_version !== now) throw new Error('쓰지 못함');
```

## 7. 배포 — Cloudflare R2

### 7.1 키 파일과 비밀

- **R2 업로드 정보:** `/Users/thruthesky/Documents/Keys/Cloudflare/r2/admin-permissions-all-r2.txt` — 2026-10-01 에 옛 위치(`~/Documents/Keys/Cloudflare/files.withcenter.com/files.withcenter.com-r2.txt`)에서 옮겼다.
  - `r2.mjs` 의 기본값이다. 새 위치에 없으면 옛 위치를 찾는다. 다른 곳이면 `R2_KEYS=<경로>`.
  - 형식은 Cloudflare 대시보드가 보여 준 그대로, 「이름:」 줄 다음 줄에 값이 있다 — `Custom Domain`(files.withcenter.com) · `Buckets`(files) · `Access Key ID` · `Secret Access Key` · S3 endpoint. 값 앞의 목록 기호(`- `)와 「이름:」으로 끝나지 않는 설명 줄은 `r2.mjs` 가 무시한다.
  - CI 처럼 파일이 없는 곳은 환경 변수 `R2_ACCESS_KEY_ID` · `R2_SECRET_ACCESS_KEY` · `R2_ENDPOINT` · `R2_BUCKET` · `R2_PUBLIC_URL` 을 쓴다.
  - **권한(2026-10-01 확인): R2 관리(Admin Read & Write).** 사용자가 대시보드에서 권한을 올리고 키 파일을 지금 위치로 옮겼다.
    - 계정의 **R2 버킷 6개 모두**(`cadeplay-assets`·`cadeplay-uploads`·`files`·`laryen-assets`·`pes-models`·`philgo-assets`)의 객체와 설정을 읽고 바꿀 수 있다. Admin 권한은 버킷을 좁힐 수 없다.
    - 도메인(Zone)은 하나도 보이지 않는다 — DNS·캐시·규칙은 바꿀 수 없다. Pages·KV·D1·Queues·Images·Stream·Turnstile·AI 등도 권한이 없다.
    - 그래서 `r2.mjs` 는 키 파일의 버킷(`files`)만 쓰고, 그 안에서도 `<이름>/v<숫자>/` prefix 밖은 올리거나 지우지 않는다. 다른 버킷은 다루지 않는다.
- **비밀 값은 출력·대화·커밋·문서에 쓰지 않는다.** 이 스킬 저장소는 공개다. 키 파일을 `cat` 하지 말고 `r2.mjs` 가 읽게 한다. `r2.mjs check` 는 키를 앞 4자만 보여 준다.

### 7.2 공개 주소

- `https://files.withcenter.com/<prefix>` — prefix 는 `<저장소 이름>/v<SCHEMA>/`.
  - 여행 정보: `ph-travel-api/v2/` → `https://files.withcenter.com/ph-travel-api/v2/manifest.json`
  - 나라별 prefix 는 `scripts/apis.json` 의 `r2_prefix` 다(`--country ph`).
- 버킷 `files` 는 다른 프로젝트와 함께 쓴다. 그래서 `r2.mjs` 는 `<이름>/v<숫자>/` 모양의 prefix 아래에만 올리고 지운다. 버킷 뿌리는 거부한다.

### 7.3 순서

```bash
node scripts/build.mjs                                               # 1. 빌드 (규격 검사)
node <스킬>/scripts/content.mjs check --dir _site/v2                  # 2. 배포 규격 검사
node <스킬>/scripts/r2.mjs deploy --dir _site/v2 --country ph --dry-run   # 3. 무엇이 올라갈지
node <스킬>/scripts/r2.mjs deploy --dir _site/v2 --country ph             # 4. 올리기 — 끝나면 verify 를 스스로 돈다
node <스킬>/scripts/r2.mjs verify --dir _site/v2 --country ph             # 다시 확인만 할 때
```

- **커밋한 내용만 올린다.** 커밋 → R2 배포 순서다. 고치던 작업 트리를 올리지 않는다.
- **데이터 저장소(ph-travel-api 등)는 GitHub 에 push 하지 않는다 — 배포는 오직 R2 다**(2026-10-02 사용자 결정). 필고 저장소의 서브모듈 포인터도 커밋하지 않는다.
- 배포는 운영 반영이다. 사용자가 배포를 요청했을 때만 한다.

### 7.4 r2.mjs 가 하는 일

1. **배포 규격 검사** — `content.mjs` 의 `checkBuild`. 8개 언어, `data_version` 형식, manifest·meta·언어 파일의 version·count 일치, 모든 항목의 대표 사진과 항목마다 사진 10장 이상, 모든 사진의 파일·`alt`·`credit`·`source`. 하나라도 어기면 아무것도 올리지 않는다. 옛 항목의 사진을 채우는 중에는 `--allow-few-images` 로 장수 검사만 알림으로 낮출 수 있다(§4.1).
2. **바뀐 파일만** — 버킷 목록의 ETag(R2 는 MD5)와 로컬 MD5 를 비교한다. 다시 실행하면 이어서 올린다.
3. **순서가 안전장치다** — 사진·기타 → 언어별 항목 파일 → `meta.json` → `manifest.json`. 클라이언트는 manifest 를 보고 나머지를 받으므로, 중간에 멈춰도 옛 manifest 가 옛 파일을 가리켜 그대로 동작한다.
4. **지우기(`--prune`)** — 버킷에만 있는 파일을 manifest 를 바꾼 **뒤에** 지운다. 옛 manifest 를 받은 클라이언트가 아직 옛 사진을 가리킬 수 있어서다.
5. **확인(`verify`)** — 공개 주소로 manifest·meta 의 version, 모든 항목 파일·사진의 ETag·content-type, CORS 를 본다.

| 파일 | Content-Type | Cache-Control | 이유 |
|------|--------------|---------------|------|
| `*.json` | `application/json; charset=utf-8` | `no-cache` | 주소가 그대로라 받을 때마다 ETag 로 확인한다(안 바뀌면 304). 배포가 곧바로 보인다 |
| 사진 | `image/webp` 등 | `public, max-age=31536000, immutable` | JSON 이 `?v=<해시>` 로 가리켜, 사진이 바뀌면 주소가 바뀐다 |
| 그 밖 | 확장자별 | `public, max-age=3600` | |

핵심 코드 — S3 호환 요청을 SigV4 로 서명한다(외부 패키지 없음, region `auto`, path-style `/<버킷>/<키>`):

```js
const amzDate = new Date().toISOString().replace(/[-:]|\.\d{3}/g, '');   // 20261001T051233Z
const payloadHash = sha256(body ?? '');
const h = { host, 'x-amz-content-sha256': payloadHash, 'x-amz-date': amzDate, ...소문자로_바꾼_헤더 };
const names = Object.keys(h).sort();
const canonical = [method, path, sortedQuery, names.map((k) => `${k}:${h[k]}\n`).join(''), names.join(';'), payloadHash].join('\n');
const scope = `${amzDate.slice(0, 8)}/auto/s3/aws4_request`;
const toSign = ['AWS4-HMAC-SHA256', amzDate, scope, sha256(canonical)].join('\n');
const key = hmac(hmac(hmac(hmac(`AWS4${secret}`, amzDate.slice(0, 8)), 'auto'), 's3'), 'aws4_request');
headers.authorization = `AWS4-HMAC-SHA256 Credential=${accessKeyId}/${scope}, SignedHeaders=${names.join(';')}, Signature=${hmacHex(key, toSign)}`;
```

- 경로와 쿼리는 RFC 3986 으로 인코딩한다(`encodeURIComponent` 가 남기는 `!'()*` 도 바꾼다). 서명한 쿼리 문자열을 주소에도 그대로 쓴다.
- 공개 주소로 HEAD 할 때는 `accept-encoding: identity` 를 보낸다. 압축해서 보내면 Cloudflare 가 ETag 를 `W/"…"` 로 바꾸고 길이를 빼기 때문이다.

### 7.5 CORS

- **버킷 `files` 의 CORS (2026-10-01 설정):** origin `*` · method `GET`·`HEAD` · header `*` · expose `ETag` · max-age 86400초.
  - 공개 응답에 `Access-Control-Allow-Origin: *` 가 붙고, 브라우저의 사전 요청(OPTIONS)에 204 로 답한다. 다른 도메인의 웹 페이지도 JSON·사진을 바로 받는다.
  - 공개 읽기 전용 데이터라 GET·HEAD 만 연다. 쓰기는 S3 서명이 있어야 하므로 CORS 와 무관하다.
- **명령** — 키에 R2 관리(Admin Read & Write) 권한이 있어야 한다:

```bash
node <스킬>/scripts/r2.mjs cors                                   # 지금 규칙 보기
node <스킬>/scripts/r2.mjs cors --set                             # 위 규칙으로 (이미 같으면 바꾸지 않는다)
node <스킬>/scripts/r2.mjs cors --set --origins https://philgo.com,https://www.philgo.com   # 도메인을 좁힐 때
```

- 버킷 전체에 걸리는 설정이다. 다른 규칙이 이미 있으면 `--force` 없이는 바꾸지 않는다(PutBucketCors 는 규칙을 통째로 바꿔서 기존 규칙이 사라진다).
- 권한이 없는 키면 `AccessDenied` 가 난다. 그때는 대시보드 R2 > 버킷 > Settings > CORS Policy 에서 같은 규칙을 넣는다.
- 핵심 코드 — S3 PutBucketCors 는 `?cors` 쿼리에 XML 을 PUT 하고, `Content-MD5`(본문 MD5 의 base64)를 서명할 헤더에 넣어야 한다:

```js
const xml = `<CORSConfiguration xmlns="http://s3.amazonaws.com/doc/2006-03-01/"><CORSRule><AllowedOrigin>*</AllowedOrigin>`
  + '<AllowedMethod>GET</AllowedMethod><AllowedMethod>HEAD</AllowedMethod><AllowedHeader>*</AllowedHeader>'
  + '<ExposeHeader>ETag</ExposeHeader><MaxAgeSeconds>86400</MaxAgeSeconds></CORSRule></CORSConfiguration>';
const body = Buffer.from(xml);
await r2Request(cfg, 'PUT', '', { query: { cors: '' }, body,
  headers: { 'content-type': 'application/xml', 'content-md5': createHash('md5').update(body).digest('base64') } });
```

### 7.6 실패하면

- 중간에 멈췄으면 다시 실행한다. 바뀐 것만 이어서 올리고, manifest 는 마지막에 바뀐다.
- 되돌리기: 이전 커밋을 체크아웃 → `build.mjs` → `r2.mjs deploy`. R2 는 옛 판을 보관하지 않는다.
- `HTTP 403 SignatureDoesNotMatch`·`AccessDenied`: 키 파일과 토큰 권한을 확인한다. 배포에는 객체 읽기·쓰기·목록, `cors` 에는 R2 관리 권한이 필요하다.
- `verify` 의 "내용이 다르다": 다른 사람이 같은 prefix 에 올렸거나 배포 중이다. `deploy` 를 다시 실행한다.

## 8. 분석과 문서화

- **분석 — 조회 도구로 질문에 답해 본다.** `travel.mjs --base _site/v2` 로 새·바뀐 항목이 `list`·`search`·`show` 에 나오는지, 8개 언어에서 이름으로 찾아지는지(ko·en 과 th·ar 중 하나) 본다. 새 API 는 설계 때 적은 질문 열 개를 모두 답한다([blueprint.md](blueprint.md) §4-2). 답이 안 나오면 속성·단락 설계로 돌아간다.
- **문서화 — 무엇을 어디에:**

| 무엇 | 어디에 |
|------|--------|
| 사실의 출처·판단 | 데이터 저장소 `sources/<id>-<slug>.json` (§3.5) |
| 작성 규격(속성·단락·블록·품질) | 데이터 저장소 `data/README.md` |
| 값 목록·속성·단락·type 의 기계 규격, 정보 기준 시각 | 데이터 저장소 `data/meta.json` |
| 결정·현재 상태·남은 일 | 이 스킬의 [history.md](history.md) — 날짜(YYYY-MM-DD)·무엇·왜·수치 |
| 번역 지침·어휘집 | 데이터 저장소 `i18n/GUIDE.md`·`i18n/glossary/<언어>.json` |
| 커밋 메시지 | 한글. 바뀐 항목, 확인한 출처 수, `data_version` |

- 규격을 바꾸면 함께 고칠 곳은 [maintain.md](maintain.md) §5-8 이다.

## 9. 끝났다는 기준

- [ ] 바뀐 사실마다 `sources/` 에 출처가 2곳 이상 있다(요금·규정은 A 등급 포함)
- [ ] 새 항목과 고친 항목은 사진이 10장 이상이고(대표 1 + gallery 9), 전경·명소·활동을 고루 담았다. `content.mjs images` 의 "고칠 것"이 0이고, "먼저 볼 것"·새 사진은 모두 눈으로 확인했다
- [ ] 8개 언어가 모두 있고 `i18n.mjs check` 가 통과한다
- [ ] `data_version` 을 찍고 다시 빌드했다. `build.mjs` 가 exit 0 이다
- [ ] `content.mjs check` 가 통과한다
- [ ] 조회 도구로 질문에 답해 봤다
- [ ] `history.md` 를 고치고 한글로 커밋했다
- [ ] (배포를 요청받았으면) `r2.mjs deploy` 가 끝까지 돌고 `verify` 가 통과했다
