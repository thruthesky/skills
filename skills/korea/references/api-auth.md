# 인증 + 사용자 API

> 상위 문서: [SKILL.md](../SKILL.md)

## 핵심 개념

Korea SNS는 **API 키 기반 인증**을 사용한다 (PHPSESSID 미사용).
API 키는 사용자 정보(회원번호, 이메일, 가입일시)와 서버 비밀키를 조합하여 MD5 해시로 동적 생성한다.

**API 키 형식**: `{회원번호}-{md5해시}` (예: `42-a1b2c3d4e5f6a1b2c3d4e5f6a1b2c3d4`)

## 핵심 로직 — API 키 전달 방법

3가지 방법으로 API 키를 전달할 수 있다 (우선순위 순):

```bash
# 1. Authorization 헤더 (권장 — CLI, Flutter, 외부 앱)
Authorization: Bearer 42-a1b2c3d4e5f6a1b2c3d4e5f6a1b2c3d4

# 2. api_key 쿠키 (웹 브라우저 — 로그인 시 자동 설정)
Cookie: api_key=42-a1b2c3d4e5f6a1b2c3d4e5f6a1b2c3d4

# 3. 쿼리 파라미터 (브라우저 URL 직접 입력)
GET /api/v1/me?api_key=42-a1b2c3d4e5f6a1b2c3d4e5f6a1b2c3d4
```

## Base URL

```
프로덕션: https://withcenter.com/api/v1
개발환경: http://localhost:8080/api/v1
```

---

## 1. 인증 API

### POST /auth/register — 회원가입

새 사용자를 등록하고 자동 로그인한다.

**인증**: 불필요

| 필드 | 타입 | 필수 | 설명 |
|------|------|------|------|
| `email` | string | O | 이메일 주소 |
| `password` | string | O | 비밀번호 (최소 6자) |
| `display_name` | string | X | 표시 이름 |
| `site_id` | int | X | 사이트 ID (기본: 현재 사이트) |

**핵심 소스코드**:

```bash
curl -s -X POST https://withcenter.com/api/v1/auth/register \
  -H "Content-Type: application/json" \
  -H "User-Agent: KoreaSNS-CLI/1.0" \
  -d '{"email": "new@example.com", "password": "pass123", "display_name": "새사용자"}'
```

**성공 응답 (201)**:

```json
{
  "data": {
    "id": 1,
    "firebase_uid": "auto-generated-uid",
    "site_id": 0,
    "email": "user@example.com",
    "display_name": "새사용자",
    "username": null,
    "bio": null,
    "photo_url": null,
    "cover_url": null,
    "status": "active",
    "visibility": "public",
    "role": "user",
    "api_key": "1-a1b2c3d4e5f6a1b2c3d4e5f6a1b2c3d4",
    "created_at": "2025-03-29T12:00:00Z",
    "updated_at": "2025-03-29T12:00:00Z"
  }
}
```

**에러 응답 (422)**:

```json
{ "message": "이메일 주소를 입력해주세요." }
{ "message": "올바른 이메일 형식이 아닙니다." }
{ "message": "비밀번호는 최소 6자 이상이어야 합니다." }
{ "message": "이미 등록된 이메일입니다." }
```

**비즈니스 규칙**:
- 서브사이트의 첫 번째 회원가입자는 자동으로 사이트 소유자(owner)로 지정
- 비밀번호는 bcrypt로 해싱
- Firebase UID 자동 생성
- 등록 즉시 `api_key` 쿠키 설정 (자동 로그인)
- 응답에 `api_key` 필드 포함 — 외부 앱에서 이 값을 저장하여 이후 요청에 사용

---

### POST /auth/login — 로그인

API 키 쿠키 기반 로그인.

**인증**: 불필요

| 필드 | 타입 | 필수 | 설명 |
|------|------|------|------|
| `email` | string | O | 이메일 |
| `password` | string | O | 비밀번호 |
| `site_id` | int | X | 사이트 ID (기본: 현재 사이트) |

**핵심 소스코드**:

```bash
curl -s -X POST https://withcenter.com/api/v1/auth/login \
  -H "Content-Type: application/json" \
  -H "User-Agent: KoreaSNS-CLI/1.0" \
  -d '{"email": "user@example.com", "password": "mypassword"}'
```

**성공 응답 (200)**:

```json
{
  "data": {
    "id": 4,
    "email": "user@example.com",
    "display_name": "홍길동",
    "role": "user",
    "api_key": "4-88594f37e90ca97e4a8d4045fc4e5236",
    "created_at": "2025-03-29T12:00:00Z"
  }
}
```

**에러 응답**:

```json
{ "message": "이메일과 비밀번호를 입력해주세요." }        // 422
{ "message": "이메일 또는 비밀번호가 올바르지 않습니다." }  // 401
{ "message": "탈퇴한 계정입니다." }                      // 401
```

**비즈니스 규칙**:
- Firebase UID가 없으면 자동 생성
- `api_key` 쿠키 설정 (자동 로그인)
- 응답에 `api_key` 필드 포함 — 외부 앱에서 이 값을 저장하여 이후 요청에 사용

---

### POST /auth/logout — 로그아웃

`api_key` 쿠키를 삭제한다.

**인증**: 불필요

```bash
curl -s -X POST https://withcenter.com/api/v1/auth/logout \
  -H "Authorization: Bearer {API_KEY}" \
  -H "User-Agent: KoreaSNS-CLI/1.0"
```

**성공 응답 (200)**: `{ "data": { "message": "로그아웃 되었습니다." } }`

---

## 2. 사용자 API

### GET /me — 내 정보 조회

**인증**: 필수. API 키 유효성 확인에 사용.

```bash
curl -s https://withcenter.com/api/v1/me \
  -H "Authorization: Bearer {API_KEY}" \
  -H "User-Agent: KoreaSNS-CLI/1.0"
```

**성공 응답 (200)**: 사용자 공개 정보 (register 응답과 동일 구조)

---

### PATCH /me — 내 정보 수정

**인증**: 필수

| 필드 | 타입 | 필수 | 설명 |
|------|------|------|------|
| `display_name` | string | X | 표시 이름 |
| `bio` | string | X | 자기 소개 |
| `username` | string | X | 사용자 이름 |

**핵심 소스코드**:

```bash
curl -s -X PATCH https://withcenter.com/api/v1/me \
  -H "Content-Type: application/json" \
  -H "Authorization: Bearer {API_KEY}" \
  -H "User-Agent: KoreaSNS-CLI/1.0" \
  -d '{"display_name": "새이름", "bio": "안녕하세요!"}'
```

**성공 응답 (200)**: 수정된 사용자 공개 정보

**에러 (422)**: `{ "message": "수정할 데이터가 없습니다." }`

---

### PATCH /me/settings — 사용자 설정 수정

**인증**: 필수

| 필드 | 타입 | 필수 | 설명 |
|------|------|------|------|
| `settings` | object | O | 설정 키-값 객체 |

```bash
curl -s -X PATCH https://withcenter.com/api/v1/me/settings \
  -H "Content-Type: application/json" \
  -H "Authorization: Bearer {API_KEY}" \
  -H "User-Agent: KoreaSNS-CLI/1.0" \
  -d '{"settings": {"notification_enabled": true, "theme": "dark"}}'
```

---

### PATCH /me/visibility — 프로필 공개 범위 수정

**인증**: 필수

| 필드 | 타입 | 필수 | 허용 값 |
|------|------|------|---------|
| `visibility` | string | O | `public`, `private`, `friends_only` |

```bash
curl -s -X PATCH https://withcenter.com/api/v1/me/visibility \
  -H "Content-Type: application/json" \
  -H "Authorization: Bearer {API_KEY}" \
  -H "User-Agent: KoreaSNS-CLI/1.0" \
  -d '{"visibility": "private"}'
```

---

### POST /me/avatar — 아바타 업로드

**인증**: 필수 | **요청**: `multipart/form-data`

| 필드 | 타입 | 필수 | 설명 |
|------|------|------|------|
| `file` | file | O | 이미지 파일 |

```bash
curl -s -X POST https://withcenter.com/api/v1/me/avatar \
  -H "Authorization: Bearer {API_KEY}" \
  -H "User-Agent: KoreaSNS-CLI/1.0" \
  -F "file=@/path/to/avatar.jpg"
```

**성공 응답 (200)**:

```json
{
  "data": {
    "photo_url": "/uploads/1/a1b2c3d4.jpg",
    "upload": {
      "id": 10,
      "url": "/uploads/1/a1b2c3d4.jpg",
      "original_name": "avatar.jpg",
      "mime_type": "image/jpeg",
      "size": 52480,
      "is_image": true
    }
  }
}
```

---

### POST /me/cover — 커버 이미지 업로드

**인증**: 필수 | **요청**: `multipart/form-data`

아바타 업로드와 동일한 방식. 응답에 `cover_url` 필드가 포함된다.

```bash
curl -s -X POST https://withcenter.com/api/v1/me/cover \
  -H "Authorization: Bearer {API_KEY}" \
  -H "User-Agent: KoreaSNS-CLI/1.0" \
  -F "file=@/path/to/cover.jpg"
```

---

### GET /me/bookmarks — 내 북마크 목록

**인증**: 필수

| 파라미터 | 타입 | 필수 | 설명 |
|----------|------|------|------|
| `target_type` | string | X | 필터: `post` 또는 `comment` |
| `page` | int | X | 페이지 번호 |
| `per_page` | int | X | 페이지당 항목 수 |

```bash
curl -s "https://withcenter.com/api/v1/me/bookmarks?target_type=post&page=1" \
  -H "Authorization: Bearer {API_KEY}" \
  -H "User-Agent: KoreaSNS-CLI/1.0"
```

---

### GET /me/blocked-users — 내 차단 목록

**인증**: 필수

```bash
curl -s "https://withcenter.com/api/v1/me/blocked-users?page=1" \
  -H "Authorization: Bearer {API_KEY}" \
  -H "User-Agent: KoreaSNS-CLI/1.0"
```

---

## 3. 사용자 조회/검색

### GET /users/search — 사용자 검색

**인증**: 필수

| 파라미터 | 타입 | 필수 | 설명 |
|----------|------|------|------|
| `q` | string | O | 검색어 (최소 1자) |

```bash
curl -s "https://withcenter.com/api/v1/users/search?q=홍길" \
  -H "Authorization: Bearer {API_KEY}" \
  -H "User-Agent: KoreaSNS-CLI/1.0"
```

**성공 응답 (200)**:

```json
{
  "data": [
    {
      "id": 5,
      "display_name": "홍길동",
      "photo_url": "/uploads/5/avatar.jpg",
      "email": "hong@example.com"
    }
  ]
}
```

---

### GET /users/{id} — 사용자 프로필 조회

**인증**: 불필요

```bash
curl -s https://withcenter.com/api/v1/users/5 \
  -H "User-Agent: KoreaSNS-CLI/1.0"
```

---

### GET /users/by-uid — Firebase UID로 조회

**인증**: 불필요

```bash
curl -s "https://withcenter.com/api/v1/users/by-uid?uid=firebase-uid-123" \
  -H "User-Agent: KoreaSNS-CLI/1.0"
```

---

## 4. 차단 API

### POST /users/{id}/block — 사용자 차단

**인증**: 필수

| 필드 | 타입 | 필수 | 설명 |
|------|------|------|------|
| `reason` | string | X | 차단 사유 |

```bash
curl -s -X POST https://withcenter.com/api/v1/users/10/block \
  -H "Content-Type: application/json" \
  -H "Authorization: Bearer {API_KEY}" \
  -H "User-Agent: KoreaSNS-CLI/1.0" \
  -d '{"reason": "스팸 메시지"}'
```

**에러 (422)**:
- `"자기 자신을 차단할 수 없습니다."`
- `"이미 차단한 사용자입니다."`

---

### DELETE /users/{id}/block — 차단 해제

**인증**: 필수

```bash
curl -s -X DELETE https://withcenter.com/api/v1/users/10/block \
  -H "Authorization: Bearer {API_KEY}" \
  -H "User-Agent: KoreaSNS-CLI/1.0"
```

**성공 (200)**: `{ "data": { "message": "차단이 해제되었습니다." } }`

---

## 응답 형식

| 상태 | 구조 |
|------|------|
| 성공 (단건) | `{ "data": { ... } }` |
| 성공 (목록) | `{ "data": [...], "meta": { "current_page", "per_page", "total", "last_page" } }` |
| 에러 | `{ "message": "에러 메시지" }` |

## HTTP 상태 코드

| 코드 | 의미 |
|------|------|
| 200 | 성공 |
| 201 | 생성 성공 |
| 401 | 인증 필요 / 유효하지 않은 API 키 |
| 403 | 권한 없음 |
| 404 | 리소스 없음 |
| 422 | 유효성 검증 실패 |
