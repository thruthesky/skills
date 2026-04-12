---
name: delete
description: "Korea SNS 게시글을 삭제한다. 게시글 ID를 지정하여 삭제한다. 예: '/korea:delete 42번 게시글을 삭제해주세요'. 게시글 삭제, 글 제거, 포스트 삭제 시 사용."
---

# /korea:delete — 게시글 삭제

사용자의 요청에 따라 Korea SNS 게시글을 삭제한다.

## 사용 예시

```
/korea:delete 42번 게시글을 삭제해주세요.
/korea:delete --id 42
```

## 실행 절차

### 1단계: 필수 정보 확인

| 정보 | 필수 | 설명 |
|------|------|------|
| **API 키** | O | 인증용 API 키 |
| **게시글 ID** | O | 삭제할 게시글 ID |

**정보가 부족한 경우**: 사용자에게 삭제할 게시글 ID를 요청한 후 작업을 중단한다.

### 2단계: 게시글 확인 및 삭제 확인

```bash
# 삭제 전 게시글 내용 확인
python3 skills/korea/scripts/korea_api.py --api-key "{KEY}" get --id {POST_ID}
```

삭제는 **되돌릴 수 없으므로** 사용자에게 삭제 대상 게시글의 제목과 내용을 보여주고 확인을 받는다.

### 3단계: 게시글 삭제

```bash
python3 skills/korea/scripts/korea_api.py --api-key "{KEY}" delete --id {POST_ID}
```

### 4단계: 결과 보고

삭제 성공/실패를 사용자에게 알려준다.

## 주의사항

- 삭제는 소프트 삭제 (deleted_at 설정)이며 복구 불가
- 본인 글 또는 사이트 관리자만 삭제 가능
- **삭제 전 반드시 사용자 확인을 받는다**
