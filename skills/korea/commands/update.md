---
name: update
description: "Korea SNS 게시글을 수정한다. 게시글 ID 또는 자연어로 수정 대상과 내용을 지정한다. 예: '/korea:update 42번 게시글 제목을 수정해주세요'. 게시글 수정, 글 편집, 포스트 업데이트 시 사용."
---

# /korea:update — 게시글 수정

사용자의 자연어 요청을 분석하여 Korea SNS 게시글을 수정한다.

## 사용 예시

```
/korea:update 42번 게시글 제목을 "수정된 제목"으로 변경해주세요.
/korea:update --id 42 --title "새 제목" --content "새 내용"
/korea:update bangphil.com의 최근 게시글 내용을 수정해주세요.
```

## 실행 절차

### 1단계: 필수 정보 확인

| 정보 | 필수 | 설명 |
|------|------|------|
| **API 키** | O | 인증용 API 키 |
| **게시글 ID** | O | 수정 대상 게시글 ID |
| **수정 내용** | O | 제목, 내용, 카테고리 중 하나 이상 |

**정보가 부족한 경우**: 사용자에게 부족한 정보를 알려주고 입력을 요청한 후 작업을 중단한다.

부족 정보 안내 예시:
```
게시글을 수정하려면 다음 정보가 필요합니다:
- 게시글 ID: 수정할 게시글의 ID를 알려주세요.
- 수정할 내용: 제목, 내용, 카테고리 중 무엇을 수정할까요?
```

### 2단계: 기존 게시글 확인

```bash
python3 skills/korea/scripts/korea_api.py --api-key "{KEY}" get --id {POST_ID}
```

게시글이 존재하지 않거나 권한이 없으면 사용자에게 알린다.

### 3단계: 게시글 수정

```bash
python3 skills/korea/scripts/korea_api.py --api-key "{KEY}" update \
  --id {POST_ID} --title "새 제목" --content "새 내용"
```

### 4단계: 결과 보고

수정 전후 변경 사항을 사용자에게 알려준다.

## 주의사항

- 본인 글 또는 사이트 관리자만 수정 가능
- 수정할 내용이 없으면 사용자에게 무엇을 수정할지 확인
