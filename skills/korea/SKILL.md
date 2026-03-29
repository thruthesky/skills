---
name: korea
description: "Korea SNS API를 통한 게시글/댓글 CRUD 관리. API 키 기반 인증(Authorization: Bearer). 사용자가 API 키를 제공하면 게시글을 직접 생성, 수정, 삭제할 수 있다. 이메일/비밀번호로 로그인하여 API 키를 획득하는 것도 지원. Claude가 다음 작업 수행 시 사용: (1) Korea SNS에 게시글 등록/작성 (2) 게시글 수정/편집 (3) 게시글 삭제 (4) 게시글 목록 조회 (5) 댓글 작성/수정/삭제 (6) withcenter.com API 호출 (7) Korea SNS 로그인/API 키 획득. 키워드: Korea SNS, withcenter, 게시글, 포스트, 글쓰기, 글 등록, 글 수정, 글 삭제, 댓글, API, api_key"
---

# Korea SNS — 게시글 관리 스킬

Korea SNS(withcenter.com) API를 통해 게시글과 댓글을 관리하는 스킬.

## API 기본 정보

| 항목 | 값 |
|------|-----|
| **Base URL** | `https://withcenter.com/api/v1` |
| **인증** | `Authorization: Bearer {API_KEY}` 헤더 |
| **API 키 형식** | `{회원번호}-{md5해시}` (예: `4-a1b2c3d4e5f6...`) |
| **요청 형식** | `Content-Type: application/json` |
| **응답** | 성공: `{ "data": {...} }`, 에러: `{ "message": "..." }` |

API 키 전달 방법 3가지 (우선순위 순):
1. **Authorization 헤더** (권장): `Authorization: Bearer {API_KEY}`
2. **api_key 쿠키**: `Cookie: api_key={API_KEY}`
3. **쿼리 파라미터**: `?api_key={API_KEY}`

## 워크플로우

### 1단계: API 키 확인

사용자가 API 키를 직접 제공하면 그것을 사용한다.
API 키가 없고 이메일/비밀번호가 있으면 로그인하여 API 키를 획득한다.

### 2단계: 스크립트로 작업 실행

스크립트 경로: `skills/korea/scripts/korea_api.py`

```bash
# 로그인으로 API 키 획득 (API 키가 없을 때)
python3 skills/korea/scripts/korea_api.py --api-key "" login --email "user@example.com" --password "pass"

# 게시글 CRUD
python3 skills/korea/scripts/korea_api.py --api-key "{KEY}" create --title "제목" --content "내용" [--category-id 3]
python3 skills/korea/scripts/korea_api.py --api-key "{KEY}" update --id {ID} --title "새제목" --content "새내용"
python3 skills/korea/scripts/korea_api.py --api-key "{KEY}" delete --id {ID}
python3 skills/korea/scripts/korea_api.py --api-key "{KEY}" get --id {ID}
python3 skills/korea/scripts/korea_api.py --api-key "{KEY}" list [--page 1] [--per-page 10]

# 댓글
python3 skills/korea/scripts/korea_api.py --api-key "{KEY}" comment-create --post-id {ID} --content "댓글"
python3 skills/korea/scripts/korea_api.py --api-key "{KEY}" comment-update --comment-id {ID} --content "수정"
python3 skills/korea/scripts/korea_api.py --api-key "{KEY}" comment-delete --comment-id {ID}
```

### curl 직접 사용 (대안)

Cloudflare WAF 차단 방지를 위해 `User-Agent` 헤더를 반드시 포함한다.

```bash
curl -s -X POST https://withcenter.com/api/v1/posts \
  -H "Content-Type: application/json" \
  -H "Authorization: Bearer {API_KEY}" \
  -H "User-Agent: KoreaSNS-CLI/1.0" \
  -d '{"title": "제목", "content": "내용"}'
```

## 주의사항

1. **User-Agent 필수**: Cloudflare WAF가 User-Agent 없는 요청을 차단한다. curl 사용 시 `-H "User-Agent: KoreaSNS-CLI/1.0"` 필수.
2. **API 키 보안**: API 키를 로그, 파일, 출력에 노출하지 않는다.
3. **에러 처리**: 응답에 `message` 필드가 있으면 에러. 사용자에게 전달한다.
4. **권한**: 수정/삭제는 본인 글 또는 사이트 관리자만 가능.

## 상세 API 문서

- **인증 API** (로그인/가입/API키 전달 방법): [references/api-auth.md](references/api-auth.md)
- **게시글/댓글 CRUD API**: [references/api-posts.md](references/api-posts.md)
