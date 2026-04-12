---
name: update-comment
description: "Korea SNS 댓글을 수정한다. 댓글 ID와 새 내용을 지정한다. 예: '/korea:update-comment 100번 댓글을 수정해주세요'. 댓글 수정, 코멘트 편집 시 사용."
---

# /korea:update-comment — 댓글 수정

사용자의 요청에 따라 Korea SNS 댓글을 수정한다.

## 사용 예시

```
/korea:update-comment 100번 댓글을 "수정된 내용"으로 변경해주세요.
/korea:update-comment --comment-id 100 --content "수정된 내용"
```

## 실행 절차

### 1단계: 필수 정보 확인

| 정보 | 필수 | 설명 |
|------|------|------|
| **API 키** | O | 인증용 API 키 |
| **댓글 ID** | O | 수정할 댓글 ID |
| **수정 내용** | O | 새 댓글 내용 |

**정보가 부족한 경우**: 사용자에게 부족한 정보를 알려주고 입력을 요청한 후 작업을 중단한다.

### 2단계: 댓글 수정

```bash
python3 skills/korea/scripts/korea_api.py --api-key "{KEY}" comment-update \
  --comment-id {COMMENT_ID} --content "수정된 내용"
```

### 3단계: 결과 보고

수정 성공/실패를 사용자에게 알려준다.

## 주의사항

- 본인 댓글 또는 사이트 관리자만 수정 가능
