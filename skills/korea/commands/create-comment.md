---
name: create-comment
description: "Korea SNS 게시글에 댓글을 생성한다. 자연어로 게시글과 댓글 내용을 지정한다. 예: '/korea:create-comment 42번 게시글에 좋은 글이네요 댓글을 달아주세요'. 댓글 작성, 코멘트 생성, 대댓글 작성 시 사용."
---

# /korea:create-comment — 댓글 생성

사용자의 자연어 요청을 분석하여 Korea SNS 게시글에 댓글을 생성한다.

## 사용 예시

```
/korea:create-comment 42번 게시글에 "좋은 글이네요!" 댓글을 달아주세요.
/korea:create-comment --post-id 42 --content "좋은 글이네요!"
/korea:create-comment 42번 글의 100번 댓글에 대댓글을 달아주세요. 내용: "동의합니다"
```

## 실행 절차

### 1단계: 필수 정보 확인

| 정보 | 필수 | 설명 |
|------|------|------|
| **API 키** | O | 인증용 API 키 |
| **게시글 ID** | O | 댓글을 달 게시글 ID |
| **댓글 내용** | O | 댓글 내용 |
| **부모 댓글 ID** | X | 대댓글인 경우 부모 댓글 ID |

**정보가 부족한 경우**: 사용자에게 부족한 정보를 알려주고 입력을 요청한 후 작업을 중단한다.

부족 정보 안내 예시:
```
댓글을 생성하려면 다음 정보가 필요합니다:
- 게시글 ID: 어떤 게시글에 댓글을 달까요?
- 댓글 내용: 어떤 내용의 댓글을 작성할까요?
```

### 2단계: 댓글 생성

```bash
# 일반 댓글
python3 skills/korea/scripts/korea_api.py --api-key "{KEY}" comment-create \
  --post-id {POST_ID} --content "댓글 내용"

# 대댓글 (부모 댓글 ID 지정)
python3 skills/korea/scripts/korea_api.py --api-key "{KEY}" comment-create \
  --post-id {POST_ID} --content "대댓글 내용" --parent-id {PARENT_ID}
```

### 3단계: 결과 보고

성공 시 생성된 댓글 ID를 사용자에게 알려준다.

## 이미지 첨부 댓글

```bash
# 1. 파일 업로드
python3 skills/korea/scripts/korea_api.py --api-key "{KEY}" upload --file "/path/to/image.jpg"

# 2. 댓글 생성 시 upload_ids 전달
python3 skills/korea/scripts/korea_api.py --api-key "{KEY}" comment-create \
  --post-id {POST_ID} --content "사진 첨부 댓글" --upload-ids "10"
```

## 주의사항

- 대댓글은 최대 6단계까지 가능
- 게시글 작성자와 부모 댓글 작성자에게 자동 알림 발송
