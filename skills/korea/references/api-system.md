# 시스템 API (파일 업로드, 사이트, 카테고리, 알림, 검색, 신고)

> 상위 문서: [SKILL.md](../SKILL.md) — 인증 방식은 [api-auth.md](api-auth.md) 참조

---

## 1. 파일 업로드 API

### POST /files/upload — 파일 업로드

**인증**: 필수 | **요청**: `multipart/form-data`

| 필드 | 타입 | 필수 | 설명 |
|------|------|------|------|
| `file` | file | O | 업로드할 파일 |

**허용 MIME 타입**:
- 이미지: `image/jpeg`, `image/png`, `image/gif`, `image/webp`, `image/avif`
- 동영상: `video/mp4`
- 오디오: `audio/mpeg`
- 문서: `application/pdf`, `text/plain`, `application/zip`

**파일 크기 제한**: 최대 50MB

**핵심 소스코드**:

```bash
curl -s -X POST https://withcenter.com/api/v1/files/upload \
  -H "Authorization: Bearer {API_KEY}" \
  -H "User-Agent: KoreaSNS-CLI/1.0" \
  -F "file=@/path/to/image.jpg"
```

**성공 응답 (201)**:

```json
{
  "data": {
    "id": 10,
    "url": "/uploads/1/a1b2c3d4e5f6g7h8.jpg",
    "path": "uploads/1/a1b2c3d4e5f6g7h8.jpg",
    "filename": "a1b2c3d4e5f6g7h8.jpg",
    "original_name": "image.jpg",
    "size": 102400,
    "mime_type": "image/jpeg",
    "is_image": true,
    "is_video": false
  }
}
```

**에러 (422)**:
- `"파일이 없습니다."`
- `"파일 크기가 50MB를 초과합니다."`
- `"허용되지 않는 파일 형식입니다."`

**비즈니스 규칙**:
- 파일은 `/uploads/{user_id}/` 디렉토리에 저장
- 파일명은 랜덤 32자 hex 문자열로 생성
- **게시글/댓글에 연결하려면** 반환된 `id`를 `upload_ids` 배열로 전달:
  ```json
  { "title": "사진 게시글", "content": "내용", "upload_ids": [10, 11] }
  ```

---

### DELETE /files/{id} — 파일 삭제

**인증**: 필수 (본인 파일만)

```bash
curl -s -X DELETE https://withcenter.com/api/v1/files/10 \
  -H "Authorization: Bearer {API_KEY}" \
  -H "User-Agent: KoreaSNS-CLI/1.0"
```

**성공 (200)**: `{ "data": { "message": "파일이 삭제되었습니다." } }`

**에러**: 403 (본인 파일이 아님), 404 (파일 없음)

---

## 2. 사이트 API

### GET /sites — 사이트 목록 조회

**인증**: 불필요

| 파라미터 | 타입 | 필수 | 설명 |
|----------|------|------|------|
| `page` | int | X | 페이지 번호 |
| `per_page` | int | X | 페이지당 수 (기본: 10) |

```bash
curl -s "https://withcenter.com/api/v1/sites?page=1&per_page=10" \
  -H "User-Agent: KoreaSNS-CLI/1.0"
```

---

### POST /sites — 사이트 생성

**인증**: 불필요 (공개 사이트 생성)

| 필드 | 타입 | 필수 | 설명 |
|------|------|------|------|
| `domain` | string | O | 사이트 도메인 |
| `name` 또는 `site_name` | string | O | 사이트 이름 |
| `owner_user_id` | int | X | 소유자 사용자 ID |

```bash
curl -s -X POST https://withcenter.com/api/v1/sites \
  -H "Content-Type: application/json" \
  -H "User-Agent: KoreaSNS-CLI/1.0" \
  -d '{"domain": "newsite", "name": "새 사이트"}'
```

**에러 (422)**:
- `"도메인을 입력해주세요."`
- `"사이트 이름을 입력해주세요."`
- `"이미 등록된 도메인입니다."`

**비즈니스 규칙**: 사이트 생성 시 기본 카테고리 자동 생성

---

### GET /sites/{id} — 사이트 상세 조회

**인증**: 불필요

```bash
curl -s https://withcenter.com/api/v1/sites/1 \
  -H "User-Agent: KoreaSNS-CLI/1.0"
```

---

### PUT /sites/{id} — 사이트 수정

**인증**: 사이트 관리자 필수

| 필드 | 타입 | 필수 | 설명 |
|------|------|------|------|
| `site_name` | string | X | 사이트 이름 |
| `description` | string | X | 사이트 설명 |
| `settings` | object | X | 사이트 설정 |

---

## 3. 카테고리 API

### GET /sites/{id}/categories/tree — 카테고리 트리 조회

계층 구조 카테고리 반환. 게시글 작성 전에 호출하여 카테고리 ID를 확인한다.

**인증**: 불필요

```bash
curl -s https://withcenter.com/api/v1/sites/1/categories/tree \
  -H "User-Agent: KoreaSNS-CLI/1.0"
```

**성공 응답 (200)**:

```json
{
  "data": [
    {
      "id": 1,
      "name": "자유게시판",
      "type": "forum",
      "parent_id": null,
      "depth": 0,
      "sort_order": 0,
      "is_visible": true,
      "icon": "fa-comments",
      "children": [
        {
          "id": 5,
          "name": "일상",
          "parent_id": 1,
          "depth": 1,
          "children": []
        }
      ]
    }
  ]
}
```

---

### GET /sites/{id}/categories — 카테고리 목록 조회

플랫 형태 카테고리 목록.

```bash
curl -s https://withcenter.com/api/v1/sites/1/categories \
  -H "User-Agent: KoreaSNS-CLI/1.0"
```

---

### POST /sites/{id}/categories — 카테고리 생성

**인증**: 사이트 관리자 필수

| 필드 | 타입 | 필수 | 기본값 | 설명 |
|------|------|------|--------|------|
| `name` | string | O | - | 카테고리 이름 |
| `parent_id` | int | X | null | 부모 카테고리 ID |
| `type` | string | X | `forum` | 카테고리 타입 |
| `icon` | string | X | `""` | Font Awesome 아이콘 클래스 |
| `url` | string | X | `""` | URL |
| `is_visible` | bool | X | true | 표시 여부 |

```bash
curl -s -X POST https://withcenter.com/api/v1/sites/1/categories \
  -H "Content-Type: application/json" \
  -H "Authorization: Bearer {API_KEY}" \
  -H "User-Agent: KoreaSNS-CLI/1.0" \
  -d '{"name": "맛집 추천", "parent_id": 1, "type": "forum", "icon": "fa-utensils"}'
```

**제한 사항**:
- 1차 카테고리: 최대 32개
- 2차 카테고리: 1차당 최대 64개
- 최대 깊이: 3단계

---

### PUT /categories/{id} — 카테고리 수정

**인증**: 사이트 관리자 필수

| 필드 | 타입 | 필수 | 설명 |
|------|------|------|------|
| `name` | string | X | 카테고리 이름 |
| `type` | string | X | 카테고리 타입 |
| `icon` | string | X | 아이콘 |
| `url` | string | X | URL |
| `description` | string | X | 설명 |
| `is_visible` | bool | X | 표시 여부 |

```bash
curl -s -X PUT https://withcenter.com/api/v1/categories/5 \
  -H "Content-Type: application/json" \
  -H "Authorization: Bearer {API_KEY}" \
  -H "User-Agent: KoreaSNS-CLI/1.0" \
  -d '{"name": "수정된 카테고리", "icon": "fa-star"}'
```

---

### DELETE /categories/{id} — 카테고리 삭제

**인증**: 사이트 관리자 필수

```bash
curl -s -X DELETE https://withcenter.com/api/v1/categories/5 \
  -H "Authorization: Bearer {API_KEY}" \
  -H "User-Agent: KoreaSNS-CLI/1.0"
```

**비즈니스 규칙**: 하위 카테고리는 상위로 자동 승격

---

### PATCH /categories/{id}/move — 카테고리 이동

**인증**: 사이트 관리자 필수

| 필드 | 타입 | 필수 | 설명 |
|------|------|------|------|
| `parent_id` | int | X | 새 부모 카테고리 ID (null=루트) |
| `sort_order` | int | X | 정렬 순서 |

**에러 (422)**:
- `"자기 자신을 부모로 설정할 수 없습니다."`
- `"순환 참조가 발생합니다."`
- `"최대 카테고리 깊이를 초과합니다."`

---

### POST /categories/reorder — 카테고리 순서 변경

**인증**: 사이트 관리자 필수

| 필드 | 타입 | 필수 | 설명 |
|------|------|------|------|
| `ordered_ids` | int[] | O | 순서대로 정렬된 카테고리 ID 배열 |

```bash
curl -s -X POST https://withcenter.com/api/v1/categories/reorder \
  -H "Content-Type: application/json" \
  -H "Authorization: Bearer {API_KEY}" \
  -H "User-Agent: KoreaSNS-CLI/1.0" \
  -d '{"ordered_ids": [3, 1, 5, 2, 4]}'
```

**성공 (200)**: `{ "data": { "message": "순서가 변경되었습니다." } }`

---

## 4. 알림 API

### GET /notifications — 알림 목록 조회

**인증**: 필수

| 파라미터 | 타입 | 필수 | 설명 |
|----------|------|------|------|
| `page` | int | X | 페이지 번호 |
| `per_page` | int | X | 페이지당 수 |

```bash
curl -s "https://withcenter.com/api/v1/notifications?page=1&per_page=20" \
  -H "Authorization: Bearer {API_KEY}" \
  -H "User-Agent: KoreaSNS-CLI/1.0"
```

**성공 응답 (200)**:

```json
{
  "data": [
    {
      "id": 200,
      "type": "comment_reply",
      "title": "새 댓글",
      "body": "홍길동님이 댓글을 남겼습니다.",
      "actor_user_id": 5,
      "target_type": "post",
      "target_id": 42,
      "read_at": null,
      "created_at": "2025-03-29T12:00:00Z"
    }
  ],
  "meta": { "current_page": 1, "per_page": 20, "total": 5, "last_page": 1 }
}
```

---

### GET /notifications/unread-count — 읽지 않은 알림 수

**인증**: 필수

```bash
curl -s https://withcenter.com/api/v1/notifications/unread-count \
  -H "Authorization: Bearer {API_KEY}" \
  -H "User-Agent: KoreaSNS-CLI/1.0"
```

**성공 (200)**: `{ "data": { "unread_count": 3 } }`

---

### POST /notifications/read-all — 모든 알림 읽음 처리

**인증**: 필수

```bash
curl -s -X POST https://withcenter.com/api/v1/notifications/read-all \
  -H "Authorization: Bearer {API_KEY}" \
  -H "User-Agent: KoreaSNS-CLI/1.0"
```

**성공 (200)**: `{ "data": { "marked_count": 3 } }`

---

### POST /notifications/{id}/read — 단일 알림 읽음 처리

**인증**: 필수

```bash
curl -s -X POST https://withcenter.com/api/v1/notifications/200/read \
  -H "Authorization: Bearer {API_KEY}" \
  -H "User-Agent: KoreaSNS-CLI/1.0"
```

---

## 5. 검색 API

### GET /search — 전문 검색 (MeiliSearch 기반)

**인증**: 불필요

| 파라미터 | 타입 | 필수 | 설명 |
|----------|------|------|------|
| `q` | string | O | 검색어 |
| `site_id` | int | X | 사이트 ID |
| `category_id` | int | X | 카테고리 필터 |
| `page` | int | X | 페이지 번호 |
| `per_page` | int | X | 페이지당 수 (최대: 100) |

```bash
curl -s "https://withcenter.com/api/v1/search?q=한국&category_id=3&page=1" \
  -H "User-Agent: KoreaSNS-CLI/1.0"
```

**성공 응답 (200)**:

```json
{
  "data": [ ... ],
  "total": 15,
  "page": 1,
  "limit": 20,
  "query": "한국"
}
```

---

## 6. 신고 API

### POST /reports — 신고 생성

**인증**: 필수

| 필드 | 타입 | 필수 | 설명 |
|------|------|------|------|
| `target_type` | string | O | `post` 또는 `comment` |
| `target_id` | int | O | 신고 대상 ID |
| `report_type` | string | O | `spam`, `inappropriate`, `harassment`, `misinformation`, `copyright`, `other` |
| `reason` | string | X | 상세 사유 |

```bash
curl -s -X POST https://withcenter.com/api/v1/reports \
  -H "Content-Type: application/json" \
  -H "Authorization: Bearer {API_KEY}" \
  -H "User-Agent: KoreaSNS-CLI/1.0" \
  -d '{"target_type": "post", "target_id": 42, "report_type": "spam", "reason": "광고성 게시글"}'
```

**에러 (422)**:
- `"신고 대상 타입이 올바르지 않습니다."`
- `"자기 자신의 콘텐츠는 신고할 수 없습니다."`
- `"이미 신고한 콘텐츠입니다."`

**비즈니스 규칙**: 게시글의 pending 상태 신고가 3개 이상이면 자동 블라인드 처리

---

## 7. API 문서 조회

### GET /docs — 사용 가능한 API 목록 조회

어떤 API가 있는지 모를 때 이 엔드포인트를 호출한다.

**인증**: 불필요

| 파라미터 | 타입 | 필수 | 설명 |
|----------|------|------|------|
| `category` | string | X | 필터: `auth`, `user`, `post`, `comment`, `file`, `site`, `category`, `notification`, `search` |

```bash
# 전체 API 문서
curl -s https://withcenter.com/api/v1/docs \
  -H "User-Agent: KoreaSNS-CLI/1.0"

# 카테고리별 필터링
curl -s "https://withcenter.com/api/v1/docs?category=post" \
  -H "User-Agent: KoreaSNS-CLI/1.0"
```
