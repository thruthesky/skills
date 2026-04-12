# 콘텐츠 API (게시글, 댓글, 좋아요, 북마크, 리액션)

> 상위 문서: [SKILL.md](../SKILL.md) — 인증 방식은 [api-auth.md](api-auth.md) 참조

## 핵심 개념

Korea SNS의 콘텐츠 API. 게시글(posts)과 댓글(comments)의 생성/조회/수정/삭제, 좋아요, 북마크, 리액션을 제공한다.
모든 쓰기 작업은 `Authorization: Bearer {API_KEY}` 헤더로 인증 필수.

## 핵심 로직

- 게시글: `title`과 `content` 필수. `category_id`로 카테고리 지정 가능.
- 수정/삭제: 본인 글 또는 사이트 관리자만 가능.
- 삭제: 소프트 삭제 (`deleted_at` 설정, 복구 불가).
- 댓글: 대댓글 최대 6단계. 게시글/부모 댓글 작성자에게 자동 알림.
- 파일 첨부: 파일을 먼저 업로드(POST /files/upload)한 후, 반환된 `id`를 `upload_ids` 배열로 전달.

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
| `upload_ids` | array | X | 업로드 ID 배열 (파일 업로드 후 반환된 ID) |

**핵심 소스코드**:

```bash
curl -s -X POST https://withcenter.com/api/v1/posts \
  -H "Content-Type: application/json" \
  -H "Authorization: Bearer {API_KEY}" \
  -H "User-Agent: KoreaSNS-CLI/1.0" \
  -d '{"title": "새 게시글", "content": "내용입니다.", "category_id": 3}'
```

**파일 첨부 게시글 생성** (2단계):

```bash
# 1단계: 파일 업로드
curl -s -X POST https://withcenter.com/api/v1/files/upload \
  -H "Authorization: Bearer {API_KEY}" \
  -H "User-Agent: KoreaSNS-CLI/1.0" \
  -F "file=@/path/to/image.jpg"
# → 응답: { "data": { "id": 10, ... } }

# 2단계: 업로드 ID로 게시글 생성
curl -s -X POST https://withcenter.com/api/v1/posts \
  -H "Content-Type: application/json" \
  -H "Authorization: Bearer {API_KEY}" \
  -H "User-Agent: KoreaSNS-CLI/1.0" \
  -d '{"title": "사진 게시글", "content": "내용", "upload_ids": [10]}'
```

**성공 응답 (201)**:

```json
{
  "data": {
    "id": 42,
    "uuid": "d76f60f1-2586-4229-82cc-bf4c98b12cdb",
    "site_id": 0,
    "category_id": 3,
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

**에러 (422)**:
- `"제목을 입력해주세요."`
- `"존재하지 않는 카테고리입니다."`

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
curl -s "https://withcenter.com/api/v1/posts?category=free&page=1&per_page=10" \
  -H "Authorization: Bearer {API_KEY}" \
  -H "User-Agent: KoreaSNS-CLI/1.0"
```

**성공 응답 (200)**:

```json
{
  "data": [
    {
      "id": 42,
      "site_id": 1,
      "category_id": 3,
      "user_id": 5,
      "title": "안녕하세요",
      "content": "첫 번째 게시글입니다.",
      "urls": [],
      "is_pinned": false,
      "is_blind": false,
      "view_count": 15,
      "like_count": 3,
      "comment_count": 2,
      "created_at": "2025-03-29T10:00:00Z",
      "user": {
        "id": 5,
        "display_name": "홍길동",
        "photo_url": "/uploads/5/avatar.jpg"
      },
      "category": {
        "id": 3,
        "name": "자유게시판"
      }
    }
  ],
  "meta": { "current_page": 1, "per_page": 10, "total": 42, "last_page": 5 }
}
```

---

### GET /posts/{id} — 게시글 상세

**인증**: 불필요

```bash
curl -s https://withcenter.com/api/v1/posts/42 \
  -H "Authorization: Bearer {API_KEY}" \
  -H "User-Agent: KoreaSNS-CLI/1.0"
```

조회 시 `views_count` 자동 1 증가. 응답에 `files` 배열과 `user`, `category` 필드 포함.

**성공 응답 (200)**:

```json
{
  "data": {
    "id": 42,
    "title": "안녕하세요",
    "content": "첫 번째 게시글입니다.",
    "view_count": 16,
    "user": { "id": 5, "display_name": "홍길동", "photo_url": "..." },
    "category": { "id": 3, "name": "자유게시판" },
    "files": [
      {
        "id": 10,
        "url": "/uploads/5/image1.jpg",
        "original_name": "photo.jpg",
        "mime_type": "image/jpeg",
        "size": 102400,
        "is_image": true,
        "width": 1920,
        "height": 1080
      }
    ]
  }
}
```

---

### PUT /posts/{id} — 게시글 수정

**인증**: 필수 (본인 또는 사이트 관리자)

| 필드 | 타입 | 필수 | 설명 |
|------|------|------|------|
| `title` | string | X | 제목 |
| `content` | string | X | 내용 |
| `category_id` | int | X | 카테고리 ID |
| `urls` | array | X | 첨부 URL 배열 |
| `upload_ids` | array | X | 새로 연결할 업로드 ID 배열 |

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

**비즈니스 규칙**: 소프트 삭제 (deleted_at 설정)

---

### POST /posts/{id}/pin — 게시글 고정

**인증**: 사이트 관리자 필수

```bash
curl -s -X POST https://withcenter.com/api/v1/posts/42/pin \
  -H "Authorization: Bearer {API_KEY}" \
  -H "User-Agent: KoreaSNS-CLI/1.0"
```

### DELETE /posts/{id}/pin — 게시글 고정 해제

**인증**: 사이트 관리자 필수

```bash
curl -s -X DELETE https://withcenter.com/api/v1/posts/42/pin \
  -H "Authorization: Bearer {API_KEY}" \
  -H "User-Agent: KoreaSNS-CLI/1.0"
```

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

**대댓글 생성**:

```bash
curl -s -X POST https://withcenter.com/api/v1/posts/42/comments \
  -H "Content-Type: application/json" \
  -H "Authorization: Bearer {API_KEY}" \
  -H "User-Agent: KoreaSNS-CLI/1.0" \
  -d '{"content": "답글입니다.", "parent_id": 100}'
```

**에러 (422)**:
- `"댓글 내용을 입력해주세요."`
- `"게시글을 찾을 수 없습니다."`
- `"부모 댓글을 찾을 수 없습니다."`
- `"최대 대댓글 깊이를 초과했습니다."`

**비즈니스 규칙**:
- 대댓글 최대 깊이: 6단계
- 게시글 작성자에게 자동 알림
- 부모/조상 댓글 작성자에게 자동 알림 (최대 10단계)

---

### GET /posts/{id}/comments — 댓글 목록

**인증**: 불필요 (로그인 시 차단 사용자 필터링)

```bash
curl -s https://withcenter.com/api/v1/posts/42/comments \
  -H "User-Agent: KoreaSNS-CLI/1.0"
```

**성공 응답 (200)**:

```json
{
  "data": {
    "data": [
      {
        "id": 100,
        "post_id": 42,
        "user_id": 5,
        "parent_id": null,
        "content": "좋은 글이네요!",
        "urls": [],
        "like_count": 2,
        "created_at": "2025-03-29T11:00:00Z",
        "user": {
          "id": 5,
          "display_name": "홍길동",
          "photo_url": "/uploads/5/avatar.jpg"
        },
        "files": []
      }
    ],
    "total": 5
  }
}
```

---

### PATCH /comments/{id} — 댓글 수정

**인증**: 필수 (본인 또는 관리자)

| 필드 | 타입 | 필수 | 설명 |
|------|------|------|------|
| `content` | string | O | 수정할 내용 |
| `urls` | array | X | 첨부 URL 배열 |
| `upload_ids` | array | X | 새로 연결할 업로드 ID 배열 |

```bash
curl -s -X PATCH https://withcenter.com/api/v1/comments/100 \
  -H "Content-Type: application/json" \
  -H "Authorization: Bearer {API_KEY}" \
  -H "User-Agent: KoreaSNS-CLI/1.0" \
  -d '{"content": "수정된 댓글"}'
```

---

### DELETE /comments/{id} — 댓글 삭제

**인증**: 필수 (본인 또는 관리자)

```bash
curl -s -X DELETE https://withcenter.com/api/v1/comments/100 \
  -H "Authorization: Bearer {API_KEY}" \
  -H "User-Agent: KoreaSNS-CLI/1.0"
```

**성공 (200)**: `{ "data": { "message": "댓글이 삭제되었습니다." } }`

---

## 3. 좋아요 API

### POST /posts/{id}/like — 게시글 좋아요 토글

좋아요가 없으면 추가, 있으면 제거 (토글).

**인증**: 필수

```bash
curl -s -X POST https://withcenter.com/api/v1/posts/42/like \
  -H "Authorization: Bearer {API_KEY}" \
  -H "User-Agent: KoreaSNS-CLI/1.0"
```

**성공 응답 (200)**:

```json
{ "data": { "action": "liked", "like_count": 4 } }
// 또는
{ "data": { "action": "unliked", "like_count": 3 } }
```

**비즈니스 규칙**: 좋아요 추가 시 게시글 작성자에게 알림 (본인 글 제외)

---

### POST /comments/{id}/like — 댓글 좋아요 토글

**인증**: 필수

```bash
curl -s -X POST https://withcenter.com/api/v1/comments/100/like \
  -H "Authorization: Bearer {API_KEY}" \
  -H "User-Agent: KoreaSNS-CLI/1.0"
```

---

## 4. 북마크 API

### POST /posts/{id}/bookmark — 북마크 토글

**인증**: 필수

| 필드 | 타입 | 필수 | 기본값 | 설명 |
|------|------|------|--------|------|
| `target_type` | string | X | `post` | `post` 또는 `comment` |

```bash
curl -s -X POST https://withcenter.com/api/v1/posts/42/bookmark \
  -H "Content-Type: application/json" \
  -H "Authorization: Bearer {API_KEY}" \
  -H "User-Agent: KoreaSNS-CLI/1.0" \
  -d '{"target_type": "post"}'
```

**성공 (200)**: `{ "data": { "action": "bookmarked", "target_type": "post", "target_id": 42 } }`

---

### DELETE /posts/{id}/bookmark — 북마크 삭제

**인증**: 필수

```bash
curl -s -X DELETE https://withcenter.com/api/v1/posts/42/bookmark \
  -H "Authorization: Bearer {API_KEY}" \
  -H "User-Agent: KoreaSNS-CLI/1.0"
```

**성공 (200)**: `{ "data": { "message": "북마크가 삭제되었습니다." } }`

---

## 5. 리액션 API

### POST /posts/{id}/reactions — 게시글 리액션 토글

**인증**: 필수

| 필드 | 타입 | 필수 | 기본값 | 허용 값 |
|------|------|------|--------|---------|
| `reaction_type` | string | X | `like` | `like`, `love`, `haha`, `wow`, `sad`, `angry` |

```bash
curl -s -X POST https://withcenter.com/api/v1/posts/42/reactions \
  -H "Content-Type: application/json" \
  -H "Authorization: Bearer {API_KEY}" \
  -H "User-Agent: KoreaSNS-CLI/1.0" \
  -d '{"reaction_type": "love"}'
```

**성공 (200)**:

```json
{ "data": { "action": "reacted", "target_type": "post", "target_id": 42 } }
// 또는 (이미 반응한 경우)
{ "data": { "action": "unreacted", "target_type": "post", "target_id": 42 } }
```

---

### POST /comments/{id}/reactions — 댓글 리액션 토글

게시글 리액션과 동일한 방식. target_type이 자동으로 `comment`로 설정.

```bash
curl -s -X POST https://withcenter.com/api/v1/comments/100/reactions \
  -H "Content-Type: application/json" \
  -H "Authorization: Bearer {API_KEY}" \
  -H "User-Agent: KoreaSNS-CLI/1.0" \
  -d '{"reaction_type": "haha"}'
```
