# 인증 API

> Korea SNS 백엔드 인증 API. API 키 기반 + PHP 세션 기반 인증 지원.

## Base URL

```
https://withcenter.com/api/v1
```

## 인증 방식

### API 키 인증 (권장)

모든 요청에 `Authorization: Bearer {API_KEY}` 헤더를 포함한다.

```bash
curl -s https://withcenter.com/api/v1/posts \
  -H "Authorization: Bearer {API_KEY}"
```

API 키 형식: `{user_id}-{hex_token}` (예: `4-88594f37e90ca97e4a8d4045fc4e5236`)

### 세션 인증 (대안)

로그인 API로 세션 쿠키를 얻은 뒤, 이후 요청에 쿠키를 포함한다.

```bash
# 로그인하여 쿠키 저장
curl -s -X POST https://withcenter.com/api/v1/auth/login \
  -H "Content-Type: application/json" \
  -c cookies.txt \
  -d '{"email": "user@example.com", "password": "mypassword"}'

# 쿠키로 인증된 요청
curl -s https://withcenter.com/api/v1/me -b cookies.txt
```

---

## POST /auth/login — 로그인

**인증**: 불필요

| 필드 | 타입 | 필수 | 설명 |
|------|------|------|------|
| `email` | string | O | 이메일 |
| `password` | string | O | 비밀번호 |

```bash
curl -s -X POST https://withcenter.com/api/v1/auth/login \
  -H "Content-Type: application/json" \
  -c cookies.txt \
  -d '{"email": "user@example.com", "password": "mypassword"}'
```

**성공 응답 (200)**:

```json
{
  "data": {
    "id": 1,
    "email": "user@example.com",
    "display_name": "홍길동",
    "role": "user"
  }
}
```

**에러 (401)**: `{ "message": "이메일 또는 비밀번호가 올바르지 않습니다." }`

---

## POST /auth/register — 회원가입

**인증**: 불필요

| 필드 | 타입 | 필수 | 설명 |
|------|------|------|------|
| `email` | string | O | 이메일 |
| `password` | string | O | 비밀번호 (최소 6자) |
| `display_name` | string | X | 표시 이름 |

등록 즉시 자동 로그인됨.

**에러 (422)**: `{ "message": "이미 등록된 이메일입니다." }`

---

## POST /auth/logout — 로그아웃

```bash
curl -s -X POST https://withcenter.com/api/v1/auth/logout -b cookies.txt
```

---

## GET /me — 내 정보 조회

**인증**: 필수

```bash
curl -s https://withcenter.com/api/v1/me \
  -H "Authorization: Bearer {API_KEY}"
```

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
| 401 | 인증 필요 |
| 403 | 권한 없음 |
| 404 | 리소스 없음 |
| 422 | 유효성 검증 실패 |
