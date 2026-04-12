---
name: korea
description: "Korea SNS(withcenter.com) REST API를 통한 완전한 콘텐츠 관리. API 키 기반 인증(Authorization: Bearer). 회원가입/로그인/프로필 수정, 게시글 CRUD, 댓글 CRUD, 파일(이미지) 업로드, 사이트/카테고리 조회 및 관리, 좋아요/북마크/리액션, 알림, 검색을 지원한다. 외부 프로그램·AI·소프트웨어에서 Korea SNS에 콘텐츠를 생성·수정·삭제하기 위한 완전한 API 가이드. Claude가 다음 작업 수행 시 사용: (1) Korea SNS 회원가입/로그인/API 키 획득 (2) 사용자 프로필 수정/아바타 업로드 (3) 게시글 생성/수정/삭제/목록 조회 (4) 댓글 생성/수정/삭제 (5) 이미지·파일 업로드 후 게시글/댓글에 첨부 (6) 사이트 목록/카테고리 트리 조회 (7) 좋아요/북마크/리액션 토글 (8) 알림 조회/검색 (9) withcenter.com API 호출 (10) API 문서 자동 검색(GET /docs). 키워드: Korea SNS, withcenter, 게시글, 포스트, 글쓰기, 글 등록, 글 수정, 글 삭제, 댓글, 코멘트, 회원가입, 로그인, 프로필, 아바타, 파일 업로드, 이미지, 카테고리, 사이트, 좋아요, 북마크, 리액션, 알림, 검색, API, api_key"
---

# Korea SNS — 완전한 콘텐츠 관리 스킬

Korea SNS(withcenter.com) REST API를 통해 회원 관리, 게시글/댓글 CRUD, 파일 업로드, 사이트/카테고리 관리 등 모든 콘텐츠 작업을 수행하는 스킬.

## API 기본 정보

| 항목 | 값 |
|------|-----|
| **Base URL** | `https://withcenter.com/api/v1` |
| **인증** | `Authorization: Bearer {API_KEY}` 헤더 |
| **API 키 형식** | `{회원번호}-{md5해시}` (예: `4-a1b2c3d4e5f6...`) |
| **요청 형식** | JSON: `Content-Type: application/json`, 파일: `multipart/form-data` |
| **성공 응답** | 단건: `{ "data": {...} }`, 목록: `{ "data": [...], "meta": {...} }` |
| **에러 응답** | `{ "message": "에러 메시지" }` |
| **User-Agent** | Cloudflare WAF 차단 방지를 위해 `User-Agent: KoreaSNS-CLI/1.0` 필수 |

API 키 전달 방법 3가지 (우선순위 순):
1. **Authorization 헤더** (권장): `Authorization: Bearer {API_KEY}`
2. **api_key 쿠키**: `Cookie: api_key={API_KEY}`
3. **쿼리 파라미터**: `?api_key={API_KEY}`

## API 문서 자동 검색

어떤 API가 사용 가능한지 모를 때, 다음 엔드포인트를 호출하여 API 목록을 확인한다:

```bash
# 전체 API 문서 조회
curl -s https://withcenter.com/api/v1/docs \
  -H "User-Agent: KoreaSNS-CLI/1.0"

# 카테고리별 필터링 (auth, user, post, comment, file, site, category, notification, search)
curl -s "https://withcenter.com/api/v1/docs?category=post" \
  -H "User-Agent: KoreaSNS-CLI/1.0"
```

**항상 작업 전에 API 문서를 확인하여 사용 가능한 엔드포인트를 파악한다.**

## 워크플로우

### 1단계: API 키 확보

사용자가 API 키를 직접 제공하면 그것을 사용한다.
API 키가 없고 이메일/비밀번호가 있으면 로그인하여 API 키를 획득한다.
계정이 없으면 회원가입 후 자동으로 API 키를 획득한다.

**중요: 서브사이트(예: apple.withcenter.com)에서 작업할 때는 반드시 `--base-url`을 해당 서브사이트 URL로 지정한다.**

```bash
# 회원가입 (서브사이트에서 — 메인 사이트에서는 가입 불가)
python3 skills/korea/scripts/korea_api.py --api-key "" \
  --base-url "https://apple.withcenter.com/api/v1" \
  register --email "user@example.com" --password "pass123" --display-name "새사용자"

# 로그인
python3 skills/korea/scripts/korea_api.py --api-key "" \
  --base-url "https://apple.withcenter.com/api/v1" \
  login --email "user@example.com" --password "pass"
```

### 2단계: 사이트/카테고리 확인

게시글 작성 전에 대상 사이트와 카테고리를 확인한다.

```bash
# 사이트 목록 조회
python3 skills/korea/scripts/korea_api.py --api-key "{KEY}" sites

# 카테고리 트리 조회 (사이트 ID 필요)
python3 skills/korea/scripts/korea_api.py --api-key "{KEY}" categories --site-id 1
```

### 3단계: 콘텐츠 작업 실행

모든 명령어에 `--base-url "https://<도메인>/api/v1"`을 포함한다.
아래 예시에서 `{BASE}`는 `https://apple.withcenter.com/api/v1` 같은 서브사이트 URL이다.

```bash
# 게시글 CRUD
python3 skills/korea/scripts/korea_api.py --api-key "{KEY}" --base-url "{BASE}" create --title "제목" --content "내용" [--category-id 3]
python3 skills/korea/scripts/korea_api.py --api-key "{KEY}" --base-url "{BASE}" update --id {ID} --title "새제목" --content "새내용"
python3 skills/korea/scripts/korea_api.py --api-key "{KEY}" --base-url "{BASE}" delete --id {ID}
python3 skills/korea/scripts/korea_api.py --api-key "{KEY}" --base-url "{BASE}" get --id {ID}
python3 skills/korea/scripts/korea_api.py --api-key "{KEY}" --base-url "{BASE}" list [--page 1] [--per-page 10] [--category free]

# 댓글 CRUD
python3 skills/korea/scripts/korea_api.py --api-key "{KEY}" --base-url "{BASE}" comment-create --post-id {ID} --content "댓글"
python3 skills/korea/scripts/korea_api.py --api-key "{KEY}" --base-url "{BASE}" comment-update --comment-id {ID} --content "수정"
python3 skills/korea/scripts/korea_api.py --api-key "{KEY}" --base-url "{BASE}" comment-delete --comment-id {ID}

# 파일 업로드 후 게시글에 첨부
python3 skills/korea/scripts/korea_api.py --api-key "{KEY}" --base-url "{BASE}" upload --file "/path/to/image.jpg"
# → 반환된 upload ID를 게시글/댓글 생성 시 --upload-ids로 전달
python3 skills/korea/scripts/korea_api.py --api-key "{KEY}" --base-url "{BASE}" create --title "사진 게시글" --content "내용" --upload-ids "10,11"

# 프로필 수정
python3 skills/korea/scripts/korea_api.py --api-key "{KEY}" --base-url "{BASE}" update-profile --display-name "새이름" --bio "자기소개"

# 아바타 업로드
python3 skills/korea/scripts/korea_api.py --api-key "{KEY}" --base-url "{BASE}" upload-avatar --file "/path/to/avatar.jpg"
```

### curl 직접 사용 (대안)

Cloudflare WAF 차단 방지를 위해 `User-Agent` 헤더를 반드시 포함한다.

```bash
# 게시글 생성
curl -s -X POST https://withcenter.com/api/v1/posts \
  -H "Content-Type: application/json" \
  -H "Authorization: Bearer {API_KEY}" \
  -H "User-Agent: KoreaSNS-CLI/1.0" \
  -d '{"title": "제목", "content": "내용", "category_id": 3}'

# 파일 업로드
curl -s -X POST https://withcenter.com/api/v1/files/upload \
  -H "Authorization: Bearer {API_KEY}" \
  -H "User-Agent: KoreaSNS-CLI/1.0" \
  -F "file=@/path/to/image.jpg"

# 업로드된 파일을 게시글에 첨부
curl -s -X POST https://withcenter.com/api/v1/posts \
  -H "Content-Type: application/json" \
  -H "Authorization: Bearer {API_KEY}" \
  -H "User-Agent: KoreaSNS-CLI/1.0" \
  -d '{"title": "사진 게시글", "content": "내용", "upload_ids": [10, 11]}'
```

## 주의사항

1. **User-Agent 필수**: Cloudflare WAF가 User-Agent 없는 요청을 차단한다. curl 사용 시 `-H "User-Agent: KoreaSNS-CLI/1.0"` 필수.
2. **API 키 보안**: API 키를 로그, 파일, 출력에 노출하지 않는다.
3. **에러 처리**: 응답에 `message` 필드가 있으면 에러. 사용자에게 전달한다.
4. **권한**: 수정/삭제는 본인 글 또는 사이트 관리자만 가능.
5. **파일 업로드 순서**: 파일을 먼저 업로드(POST /files/upload)하여 ID를 받고, 게시글/댓글 생성 시 `upload_ids` 배열로 연결한다.
6. **멀티테넌트**: 서브사이트에서 작업할 때는 `--base-url "https://<도메인>/api/v1"` 옵션으로 해당 서브사이트 URL을 지정한다. 메인 사이트(withcenter.com)에서는 회원가입/글쓰기가 불가하다.
7. **API 문서 확인**: 작업 방법을 모르면 `GET /docs`를 호출하여 사용 가능한 API를 확인한다.

## 전체 API 라우트 빠른 참조

```
GET    /docs                           — API 문서 (JSON, ?category= 필터링)

POST   /auth/register                  — 회원가입
POST   /auth/login                     — 로그인
POST   /auth/logout                    — 로그아웃

GET    /me                             — 내 정보 조회
PATCH  /me                             — 내 정보 수정
POST   /me/avatar                      — 아바타 업로드
POST   /me/cover                       — 커버 이미지 업로드

GET    /posts                          — 게시글 목록
POST   /posts                          — 게시글 생성
GET    /posts/{id}                     — 게시글 상세
PUT    /posts/{id}                     — 게시글 수정
DELETE /posts/{id}                     — 게시글 삭제

GET    /posts/{id}/comments            — 댓글 목록
POST   /posts/{id}/comments            — 댓글 생성
PATCH  /comments/{id}                  — 댓글 수정
DELETE /comments/{id}                  — 댓글 삭제

POST   /files/upload                   — 파일 업로드 (multipart/form-data)
DELETE /files/{id}                     — 파일 삭제

GET    /sites                          — 사이트 목록
GET    /sites/{id}/categories/tree     — 카테고리 트리

POST   /posts/{id}/like                — 게시글 좋아요 토글
POST   /comments/{id}/like             — 댓글 좋아요 토글
POST   /posts/{id}/bookmark            — 북마크 토글
POST   /posts/{id}/reactions           — 리액션 토글

GET    /notifications                  — 알림 목록
GET    /search                         — 전문 검색
```

## 상세 API 문서

- **인증/사용자 API** (회원가입, 로그인, 프로필 수정, 아바타, 차단): [references/api-auth.md](references/api-auth.md)
- **콘텐츠 API** (게시글, 댓글, 좋아요, 북마크, 리액션): [references/api-content.md](references/api-content.md)
- **시스템 API** (파일 업로드, 사이트, 카테고리, 알림, 검색, 신고): [references/api-system.md](references/api-system.md)
