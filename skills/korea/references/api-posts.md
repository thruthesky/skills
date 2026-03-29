# 게시글/댓글 CRUD API

> 모든 쓰기 작업(POST/PUT/DELETE)은 인증 필수.
> 인증: `Authorization: Bearer {API_KEY}` 헤더 사용.

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

```bash
curl -s -X POST https://withcenter.com/api/v1/posts \
  -H "Content-Type: application/json" \
  -H "Authorization: Bearer {API_KEY}" \
  -d '{"title": "새 게시글", "content": "내용입니다.", "category_id": 3}'
```

**성공 (201)**:

```json
{
  "data": {
    "id": 42,
    "site_id": 0,
    "category_id": 3,
    "user_id": 4,
    "type": "default",
    "title": "새 게시글",
    "content": "내용입니다.",
    "visibility": "public",
    "status": "published",
    "is_pinned": false,
    "likes_count": 0,
    "comments_count": 0,
    "views_count": 0,
    "created_at": "2026-03-29T10:00:00+00",
    "updated_at": "2026-03-29T10:00:00+00",
    "urls": null,
    "is_blind": false
  }
}
```

**에러 (422)**: `{ "message": "제목을 입력해주세요." }`

---

### GET /posts — 게시글 목록

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
  -H "Authorization: Bearer {API_KEY}"
```

**성공 (200)**:

```json
{
  "data": [{ "id": 42, "title": "...", "content": "...", "author_name": "관리자", ... }],
  "meta": { "current_page": 1, "per_page": 10, "total": 42, "last_page": 5 }
}
```

---

### GET /posts/{id} — 게시글 상세

```bash
curl -s https://withcenter.com/api/v1/posts/42 \
  -H "Authorization: Bearer {API_KEY}"
```

조회 시 views_count 자동 1 증가. 응답에 `files` 배열 포함.

---

### PUT /posts/{id} — 게시글 수정

**인증**: 필수 (본인 또는 사이트 관리자)

| 필드 | 타입 | 필수 | 설명 |
|------|------|------|------|
| `title` | string | X | 제목 |
| `content` | string | X | 내용 |
| `category_id` | int | X | 카테고리 ID |

```bash
curl -s -X PUT https://withcenter.com/api/v1/posts/42 \
  -H "Content-Type: application/json" \
  -H "Authorization: Bearer {API_KEY}" \
  -d '{"title": "수정된 제목", "content": "수정된 내용"}'
```

**에러**: 403 (`"수정 권한이 없습니다."`), 404 (`"게시글을 찾을 수 없습니다."`)

---

### DELETE /posts/{id} — 게시글 삭제

**인증**: 필수 (본인 또는 사이트 관리자)

```bash
curl -s -X DELETE https://withcenter.com/api/v1/posts/42 \
  -H "Authorization: Bearer {API_KEY}"
```

**성공 (200)**: `{ "data": { "message": "게시글이 삭제되었습니다." } }`

소프트 삭제 (deleted_at 설정).

---

## 2. 댓글 API

### POST /posts/{id}/comments — 댓글 생성

**인증**: 필수

| 필드 | 타입 | 필수 | 설명 |
|------|------|------|------|
| `content` | string | O | 댓글 내용 |
| `parent_id` | int | X | 부모 댓글 ID (대댓글, 최대 6단계) |

```bash
curl -s -X POST https://withcenter.com/api/v1/posts/42/comments \
  -H "Content-Type: application/json" \
  -H "Authorization: Bearer {API_KEY}" \
  -d '{"content": "좋은 글이네요!"}'
```

### GET /posts/{id}/comments — 댓글 목록

```bash
curl -s https://withcenter.com/api/v1/posts/42/comments \
  -H "Authorization: Bearer {API_KEY}"
```

### PATCH /comments/{id} — 댓글 수정

**인증**: 필수 (본인 또는 관리자)

```bash
curl -s -X PATCH https://withcenter.com/api/v1/comments/100 \
  -H "Content-Type: application/json" \
  -H "Authorization: Bearer {API_KEY}" \
  -d '{"content": "수정된 댓글"}'
```

### DELETE /comments/{id} — 댓글 삭제

**인증**: 필수 (본인 또는 관리자)

```bash
curl -s -X DELETE https://withcenter.com/api/v1/comments/100 \
  -H "Authorization: Bearer {API_KEY}"
```
