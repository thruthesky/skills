---
name: create
description: "Korea SNS에 게시글을 생성한다. 필수로 사이트 이름/도메인과 프롬프트를 입력해야 한다. 예: '/korea:create bangphil.com 자유게시판에 마닐라 BGC 일상 경험담을 올려주세요'. 게시글 작성, 글쓰기, 글 등록, 포스트 생성 시 사용."
---

# /korea:create — 게시글 생성

사용자의 자연어 요청을 분석하여 Korea SNS에 게시글을 생성한다.

## 명령어 형식

```
/korea:create <사이트 이름 또는 도메인> <프롬프트>
```

**첫 번째 파라미터(사이트 이름 또는 도메인)는 필수이다.** 입력하지 않으면 작업을 중단하고 사용자에게 안내한다.

## 사용 예시

```
/korea:create bangphil.com 자유게시판에 마닐라 BGC 일상적인 경험담을 올려주세요.
/korea:create withcenter.com 공지사항에 "시스템 점검 안내" 글을 작성해주세요. 내용은 4월 15일 오전 2시부터 6시까지 점검합니다.
/korea:create bangphil.com 맛집 카테고리에 보니파시오 맛집 추천 글을 써주세요.
```

## 실행 절차

### 1단계: 필수 파라미터 확인

ARGUMENTS에서 다음 정보를 추출한다:

| 정보 | 필수 | 설명 |
|------|------|------|
| **사이트 이름/도메인** | **필수** | 첫 번째 단어. 도메인명 또는 사이트 이름 (예: `bangphil.com`, `withcenter.com`) |
| **프롬프트** | **필수** | 나머지 텍스트. 카테고리, 제목, 내용에 대한 지시 |

**필수 파라미터가 없는 경우 즉시 작업을 중단하고 다음을 안내한다:**

사이트가 없는 경우:
```
사이트 이름 또는 도메인을 입력해주세요.
사용법: /korea:create <사이트 이름 또는 도메인> <프롬프트>
예시: /korea:create bangphil.com 자유게시판에 일상 이야기를 올려주세요.
```

프롬프트가 없는 경우:
```
어떤 내용의 게시글을 작성할지 알려주세요.
사용법: /korea:create <사이트 이름 또는 도메인> <프롬프트>
예시: /korea:create bangphil.com 자유게시판에 마닐라 BGC 일상 경험담을 올려주세요.
```

### 2단계: API 키 확인

사용자가 API 키를 이전에 제공했거나 로그인한 적이 있는지 확인한다.
API 키가 없으면 사용자에게 로그인 정보(이메일/비밀번호)를 요청하고 작업을 중단한다.

```
API 키가 필요합니다. 이메일과 비밀번호를 알려주시면 로그인하여 API 키를 획득할 수 있습니다.
```

### 3단계: 사이트 ID 확인

사이트 목록에서 입력된 이름/도메인과 일치하는 사이트를 찾는다.

```bash
python3 skills/korea/scripts/korea_api.py --api-key "{KEY}" sites
```

일치하는 사이트가 없으면 사용 가능한 사이트 목록을 보여주고 작업을 중단한다.

### 4단계: 카테고리 확인

프롬프트에서 카테고리 정보를 추출한다 (예: "자유게시판", "공지사항", "맛집").

```bash
python3 skills/korea/scripts/korea_api.py --api-key "{KEY}" categories --site-id {SITE_ID}
```

- 카테고리가 명시되어 있으면 → 해당 카테고리 ID를 찾는다
- 카테고리를 찾을 수 없으면 → 사용 가능한 카테고리 목록을 보여주고 선택을 요청한다
- 카테고리가 명시되지 않았으면 → 카테고리 없이 진행하거나 사용자에게 선택을 요청한다

### 5단계: 제목/내용 생성

프롬프트에서 제목과 내용을 추출하거나, 프롬프트의 주제를 기반으로 AI가 적절한 제목과 내용을 생성한다.

### 6단계: 게시글 생성

```bash
python3 skills/korea/scripts/korea_api.py --api-key "{KEY}" create \
  --title "제목" --content "내용" --category-id {CAT_ID} --site-id {SITE_ID}
```

### 7단계: 결과 보고

성공 시 생성된 게시글 ID, 제목을 사용자에게 알려준다.
실패 시 에러 메시지를 사용자에게 전달한다.

## 이미지 첨부 게시글

사용자가 이미지 첨부를 요청하면:

```bash
# 1. 파일 업로드
python3 skills/korea/scripts/korea_api.py --api-key "{KEY}" upload --file "/path/to/image.jpg"

# 2. 게시글 생성 시 upload_ids 전달
python3 skills/korea/scripts/korea_api.py --api-key "{KEY}" create \
  --title "제목" --content "내용" --upload-ids "10,11" --site-id {SITE_ID}
```

## 주의사항

- **사이트 이름/도메인은 반드시 첫 번째 파라미터로 입력해야 한다**
- API 키가 없으면 먼저 로그인을 안내한다
- 카테고리를 찾을 수 없으면 사용 가능한 목록을 보여준다
- 제목이나 내용이 명시되지 않은 경우, 프롬프트의 주제로 AI가 생성한다
