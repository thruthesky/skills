# 인증 API

> Korea SNS 백엔드 인증 API.
> 상위 문서: [SKILL.md](../SKILL.md)

## 핵심 개념

Korea SNS는 **API 키 기반 인증**을 사용한다 (PHPSESSID 미사용).
API 키는 사용자 정보(회원번호, 이메일, 가입일시)와 서버 비밀키를 조합하여 MD5 해시로 동적 생성한다.

**API 키 형식**: `{회원번호}-{md5해시}` (예: `42-a1b2c3d4e5f6a1b2c3d4e5f6a1b2c3d4`)

## 핵심 로직 — API 키 전달 방법

3가지 방법으로 API 키를 전달할 수 있다 (우선순위 순):

```bash
# 1. Authorization 헤더 (권장 — CLI, Flutter, 포스트맨)
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

## POST /auth/login — 로그인

로그인 성공 시 응답에 `api_key` 필드가 포함되며, `api_key` 쿠키도 자동 설정된다.

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

**에러 (401)**: `{ "message": "이메일 또는 비밀번호가 올바르지 않습니다." }`

**비즈니스 규칙**:
- Firebase UID가 없으면 자동 생성
- `api_key` 쿠키 설정
- 응답에 `api_key` 필드 포함 (외부 앱에서 이 값을 저장하여 사용)

---

## POST /auth/register — 회원가입

**인증**: 불필요

| 필드 | 타입 | 필수 | 설명 |
|------|------|------|------|
| `email` | string | O | 이메일 |
| `password` | string | O | 비밀번호 (최소 6자) |
| `display_name` | string | X | 표시 이름 |
| `site_id` | int | X | 사이트 ID |

```bash
curl -s -X POST https://withcenter.com/api/v1/auth/register \
  -H "Content-Type: application/json" \
  -H "User-Agent: KoreaSNS-CLI/1.0" \
  -d '{"email": "new@example.com", "password": "pass123", "display_name": "새사용자"}'
```

**성공 (201)**: 사용자 정보 + `api_key` 필드 포함. 등록 즉시 자동 로그인.

**비즈니스 규칙**:
- 서브사이트 첫 가입자 = 자동 사이트 소유자
- bcrypt 해싱
- Firebase UID 자동 생성
- 응답에 `api_key` 필드 포함

**에러 (422)**:
- `"이미 등록된 이메일입니다."`
- `"비밀번호는 최소 6자 이상이어야 합니다."`

---

## POST /auth/logout — 로그아웃

`api_key` 쿠키를 삭제한다.

```bash
curl -s -X POST https://withcenter.com/api/v1/auth/logout \
  -H "Authorization: Bearer {API_KEY}" \
  -H "User-Agent: KoreaSNS-CLI/1.0"
```

**성공 (200)**: `{ "data": { "message": "로그아웃 되었습니다." } }`

---

## GET /me — 내 정보 조회

**인증**: 필수. API 키 유효성 확인에 사용.

```bash
curl -s https://withcenter.com/api/v1/me \
  -H "Authorization: Bearer {API_KEY}" \
  -H "User-Agent: KoreaSNS-CLI/1.0"
```

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

## 소스코드 파일 경로

| 파일 | 설명 |
|------|------|
| `src/Controllers/AuthController.php` | 인증 API (로그인/가입/로그아웃) |
| `src/Controllers/UserController.php` | 사용자 API (프로필/설정) |
| `src/Controllers/BaseController.php` | API 키 검증, 인증/권한 검사 베이스 |
