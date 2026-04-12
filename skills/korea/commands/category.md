---
name: category
description: "Korea SNS 특정 사이트의 카테고리 목록을 조회한다. 사이트 이름 또는 도메인을 지정하여 해당 사이트에 어떤 게시판(카테고리)이 있는지 확인한다. 예: '/korea:category bangphil.com', '/korea:category 방필'. 카테고리 목록, 게시판 목록, 사이트 카테고리 조회 시 사용."
---

# /korea:category — 사이트 카테고리 조회

특정 사이트의 카테고리(게시판) 목록을 트리 형태로 조회한다.

## 명령어 형식

```
/korea:category <사이트 이름 또는 도메인>
```

**첫 번째 파라미터(사이트 이름 또는 도메인)는 필수이다.** 입력하지 않으면 작업을 중단하고 사용자에게 안내한다.

## 사용 예시

```
/korea:category bangphil.com
/korea:category withcenter.com
/korea:category 방필
```

## 실행 절차

### 1단계: 필수 파라미터 확인

ARGUMENTS에서 사이트 이름 또는 도메인을 추출한다.

**파라미터가 없는 경우 즉시 작업을 중단하고 다음을 안내한다:**

```
사이트 이름 또는 도메인을 입력해주세요.
사용법: /korea:category <사이트 이름 또는 도메인>
예시: /korea:category bangphil.com
```

### 2단계: 사이트 ID 확인

사이트 목록에서 입력된 이름/도메인과 일치하는 사이트를 찾는다.

```bash
python3 skills/korea/scripts/korea_api.py --api-key "{KEY}" sites
```

일치하는 사이트가 없으면 사용 가능한 사이트 목록을 보여주고 작업을 중단한다.

### 3단계: 카테고리 트리 조회

```bash
python3 skills/korea/scripts/korea_api.py --api-key "{KEY}" categories --site-id {SITE_ID}
```

### 4단계: 결과를 보기 좋게 표시

카테고리 트리를 계층 구조로 표시한다. 각 카테고리의 ID, 이름, 타입, 아이콘을 포함한다.

출력 예시:
```
📁 bangphil.com 카테고리 목록:

  1. 자유게시판 (ID: 1, type: forum)
     ├── 일상 (ID: 5)
     └── 맛집 (ID: 6)
  2. 공지사항 (ID: 2, type: forum)
  3. 질문답변 (ID: 3, type: forum)
```
