---
name: korea
description: "Korea SNS API를 통한 게시글/댓글 CRUD 관리. API 키 기반 인증. 사용자가 API 키를 제공하면 게시글을 직접 생성, 수정, 삭제할 수 있다. Claude가 다음 작업 수행 시 사용: (1) Korea SNS에 게시글 등록/작성 (2) 게시글 수정/편집 (3) 게시글 삭제 (4) 게시글 목록 조회 (5) 댓글 작성/수정/삭제 (6) withcenter.com API 호출. 키워드: Korea SNS, withcenter, 게시글, 포스트, 글쓰기, 글 등록, 글 수정, 글 삭제, 댓글, API, api_key"
---

# Korea SNS — 게시글 관리 스킬

Korea SNS(withcenter.com) API를 통해 게시글과 댓글을 관리하는 스킬.
사용자가 API 키를 제공하면 `Authorization: Bearer` 헤더로 인증하여 CRUD 작업을 수행한다.

## API 기본 정보

| 항목 | 값 |
|------|-----|
| **Base URL** | `https://withcenter.com/api/v1` |
| **인증 방식** | `Authorization: Bearer {API_KEY}` 헤더 |
| **요청 형식** | `Content-Type: application/json` |
| **응답 형식** | JSON (`data` 필드에 결과, `message` 필드에 에러) |

## 워크플로우

### 1단계: API 키 확인

사용자에게 API 키를 확인한다. API 키 형식 예시: `4-88594f37e90ca97e4a8d4045fc4e5236`

### 2단계: 스크립트 또는 curl로 작업 실행

#### 방법 1: 번들 스크립트 사용 (권장)

스크립트 경로: `skills/korea/scripts/korea_api.py`

```bash
# 게시글 생성
python3 skills/korea/scripts/korea_api.py --api-key "{KEY}" create --title "제목" --content "내용" [--category-id 3]

# 게시글 수정
python3 skills/korea/scripts/korea_api.py --api-key "{KEY}" update --id {ID} --title "새제목" --content "새내용"

# 게시글 삭제
python3 skills/korea/scripts/korea_api.py --api-key "{KEY}" delete --id {ID}

# 게시글 조회
python3 skills/korea/scripts/korea_api.py --api-key "{KEY}" get --id {ID}

# 게시글 목록
python3 skills/korea/scripts/korea_api.py --api-key "{KEY}" list [--page 1] [--per-page 10] [--category free]

# 댓글 생성
python3 skills/korea/scripts/korea_api.py --api-key "{KEY}" comment-create --post-id {ID} --content "댓글"

# 댓글 수정
python3 skills/korea/scripts/korea_api.py --api-key "{KEY}" comment-update --comment-id {ID} --content "수정"

# 댓글 삭제
python3 skills/korea/scripts/korea_api.py --api-key "{KEY}" comment-delete --comment-id {ID}
```

#### 방법 2: curl 직접 사용

```bash
# 게시글 생성
curl -s -X POST https://withcenter.com/api/v1/posts \
  -H "Content-Type: application/json" \
  -H "Authorization: Bearer {API_KEY}" \
  -d '{"title": "제목", "content": "내용"}'

# 게시글 수정
curl -s -X PUT https://withcenter.com/api/v1/posts/{ID} \
  -H "Content-Type: application/json" \
  -H "Authorization: Bearer {API_KEY}" \
  -d '{"title": "새제목", "content": "새내용"}'

# 게시글 삭제
curl -s -X DELETE https://withcenter.com/api/v1/posts/{ID} \
  -H "Authorization: Bearer {API_KEY}"

# 게시글 목록
curl -s "https://withcenter.com/api/v1/posts?page=1&per_page=10" \
  -H "Authorization: Bearer {API_KEY}"
```

## 주의사항

1. **API 키 보안**: API 키를 로그, 파일, 출력에 절대 노출하지 않는다. 명령어 실행 시에만 사용한다.
2. **에러 처리**: 응답에 `message` 필드가 있으면 에러. 사용자에게 그대로 전달한다.
3. **권한**: 게시글 수정/삭제는 본인 글 또는 사이트 관리자만 가능하다.
4. **소프트 삭제**: 삭제된 게시글은 복구 불가 (deleted_at 설정).

## 상세 API 문서

- **인증 API** (로그인/가입/로그아웃/API키): [references/api-auth.md](references/api-auth.md)
- **게시글/댓글 CRUD API**: [references/api-posts.md](references/api-posts.md)
