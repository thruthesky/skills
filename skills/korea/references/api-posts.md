# 게시글/댓글 CRUD API

> 상위 문서: [SKILL.md](../SKILL.md) — 인증 방식은 [api-auth.md](api-auth.md) 참조

## 핵심 개념

Korea SNS의 콘텐츠 API. 게시글(posts)과 댓글(comments)의 생성/조회/수정/삭제를 제공한다.
모든 쓰기 작업은 `Authorization: Bearer {API_KEY}` 헤더로 인증 필수.

## 핵심 로직

- 게시글: `title`과 `content` 필수. `category_id`로 카테고리 지정 가능.
- 수정/삭제: 본인 글 또는 사이트 관리자만 가능.
- 삭제: 소프트 삭제 (`deleted_at` 설정, 복구 불가).
- 댓글: 대댓글 최대 6단계. 게시글/부모 댓글 작성자에게 자동 알림.

## Base URL

```
https://withcenter.com/api/v1
```

---

## 1. 게시글 API

### POST /posts — 게시글 생성

**인증**: 필수

| 필드 | 타입 | 필수 | 설명 |
|------|------|------|------|
| `title` | string | O | 제목 |
| `content` | string | O | 내용 |
| `category_id` | int | X | 카테고리 ID |
| `site_id` | int | X | 사이트 ID (기본: 현재 사이트) |
| `urls` | array | X | 첨부 URL 배열 |
| `upload_ids` | array | X | 업로드 ID 배열 |

**핵심 소스코드**:

```bash
curl -s -X POST https://withcenter.com/api/v1/posts \
  -H "Content-Type: application/json" \
  -H "Authorization: Bearer {API_KEY}" \
  -H "User-Agent: KoreaSNS-CLI/1.0" \
  -d '{"title": "새 게시글", "content": "내용입니다.", "category_id": 3}'
```

**성공 (201)**:

```json
{
  "data": {
    "id": 42,
    "uuid": "d76f60f1-2586-4229-82cc-bf4c98b12cdb",
    "site_id": 0,
    "category_id": null,
    "user_id": 4,
    "type": "default",
    "title": "새 게시글",
    "content": "내용입니다.",
    "visibility": "public",
    "status": "published",
    "is_pinned": false,
    "published_at": null,
    "likes_count": 0,
    "comments_count": 0,
    "views_count": 0,
    "created_at": "2026-03-29T12:01:08+00",
    "updated_at": "2026-03-29T12:01:08+00",
    "deleted_at": null,
    "urls": null,
    "is_blind": false
  }
}
```

**에러 (422)**: `{ "message": "제목을 입력해주세요." }`, `{ "message": "존재하지 않는 카테고리입니다." }`

---

### GET /posts — 게시글 목록

**인증**: 불필요 (로그인 시 차단 사용자 필터링)

| 파라미터 | 타입 | 필수 | 설명 |
|----------|------|------|------|
| `site_id` | int | X | 사이트 ID |
| `category` | string | X | 카테고리 슬러그 또는 ID |
| `page` | int | X | 페이지 (기본: 1) |
| `per_page` | int | X | 페이지당 수 (기본: 20, 최대: 100) |
| `order_by` | string | X | 정렬: `created_at`, `view_count`, `comment_count`, `like_count` |
| `order` | string | X | 방향: `asc`, `desc` (기본: desc) |

```bash
curl -s "https://withcenter.com/api/v1/posts?page=1&per_page=10" \
  -H "Authorization: Bearer {API_KEY}" \
  -H "User-Agent: KoreaSNS-CLI/1.0"
```

**성공 (200)**:

```json
{
  "data": [
    {
      "id": 42, "title": "...", "content": "...",
      "author_name": "관리자", "author_photo": null, "author_firebase_uid": null
    }
  ],
  "meta": { "current_page": 1, "per_page": 10, "total": 42, "last_page": 5 }
}
```

---

### GET /posts/{id} — 게시글 상세

```bash
curl -s https://withcenter.com/api/v1/posts/42 \
  -H "Authorization: Bearer {API_KEY}" \
  -H "User-Agent: KoreaSNS-CLI/1.0"
```

조회 시 `views_count` 자동 1 증가. 응답에 `files` 배열과 `author_*` 필드 포함.

---

### PUT /posts/{id} — 게시글 수정

**인증**: 필수 (본인 또는 사이트 관리자)

| 필드 | 타입 | 필수 | 설명 |
|------|------|------|------|
| `title` | string | X | 제목 |
| `content` | string | X | 내용 |
| `category_id` | int | X | 카테고리 ID |
| `urls` | array | X | 첨부 URL 배열 |
| `upload_ids` | array | X | 업로드 ID 배열 |

```bash
curl -s -X PUT https://withcenter.com/api/v1/posts/42 \
  -H "Content-Type: application/json" \
  -H "Authorization: Bearer {API_KEY}" \
  -H "User-Agent: KoreaSNS-CLI/1.0" \
  -d '{"title": "수정된 제목", "content": "수정된 내용"}'
```

**에러**: 403 (`"수정 권한이 없습니다."`), 404 (`"게시글을 찾을 수 없습니다."`)

---

### DELETE /posts/{id} — 게시글 삭제

**인증**: 필수 (본인 또는 사이트 관리자)

```bash
curl -s -X DELETE https://withcenter.com/api/v1/posts/42 \
  -H "Authorization: Bearer {API_KEY}" \
  -H "User-Agent: KoreaSNS-CLI/1.0"
```

**성공 (200)**: `{ "data": { "message": "게시글이 삭제되었습니다." } }`

---

## 2. 댓글 API

### POST /posts/{id}/comments — 댓글 생성

**인증**: 필수

| 필드 | 타입 | 필수 | 설명 |
|------|------|------|------|
| `content` | string | O | 댓글 내용 |
| `parent_id` | int | X | 부모 댓글 ID (대댓글, 최대 6단계) |
| `urls` | array | X | 첨부 URL 배열 |
| `upload_ids` | array | X | 업로드 ID 배열 |

```bash
curl -s -X POST https://withcenter.com/api/v1/posts/42/comments \
  -H "Content-Type: application/json" \
  -H "Authorization: Bearer {API_KEY}" \
  -H "User-Agent: KoreaSNS-CLI/1.0" \
  -d '{"content": "좋은 글이네요!"}'
```

### GET /posts/{id}/comments — 댓글 목록

```bash
curl -s https://withcenter.com/api/v1/posts/42/comments \
  -H "Authorization: Bearer {API_KEY}" \
  -H "User-Agent: KoreaSNS-CLI/1.0"
```

### PATCH /comments/{id} — 댓글 수정

**인증**: 필수 (본인 또는 관리자)

```bash
curl -s -X PATCH https://withcenter.com/api/v1/comments/100 \
  -H "Content-Type: application/json" \
  -H "Authorization: Bearer {API_KEY}" \
  -H "User-Agent: KoreaSNS-CLI/1.0" \
  -d '{"content": "수정된 댓글"}'
```

### DELETE /comments/{id} — 댓글 삭제

**인증**: 필수 (본인 또는 관리자)

```bash
curl -s -X DELETE https://withcenter.com/api/v1/comments/100 \
  -H "Authorization: Bearer {API_KEY}" \
  -H "User-Agent: KoreaSNS-CLI/1.0"
```

---

## 소스코드 파일 경로

| 파일 | 설명 |
|------|------|
| `src/Controllers/PostController.php` | 게시글 CRUD API |
| `src/Controllers/CommentController.php` | 댓글 CRUD API |
| `src/Controllers/LikeController.php` | 좋아요 토글 API |
| `src/Controllers/BookmarkController.php` | 북마크 API |
| `src/Controllers/ReactionController.php` | 리액션 API |
| `src/Controllers/FileController.php` | 파일 업로드 API |
