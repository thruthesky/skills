---
name: register
description: "Korea SNS에 회원가입한다. 이메일, 비밀번호, 표시이름을 입력하여 새 계정을 생성하고 API 키를 획득한다. 예: '/korea:register user@example.com pass123 홍길동'. 회원가입, 계정 생성, 가입, 신규 등록 시 사용."
---

# /korea:register — 회원가입

Korea SNS에 새 계정을 생성하고 API 키를 획득한다.

## 명령어 형식

```
/korea:register <이메일> <비밀번호> <display_name>
```

**세 개의 파라미터 모두 필수이다.** 하나라도 빠지면 작업을 중단하고 사용자에게 안내한다.

## 사용 예시

```
/korea:register user@example.com mypass123 홍길동
/korea:register test@bangphil.com secure456 마닐라사람
```

## 실행 절차

### 1단계: 필수 파라미터 확인

ARGUMENTS에서 다음 3개의 파라미터를 순서대로 추출한다:

| 순서 | 파라미터 | 필수 | 설명 |
|------|----------|------|------|
| 1 | **이메일** | **필수** | 유효한 이메일 주소 |
| 2 | **비밀번호** | **필수** | 최소 6자 이상 |
| 3 | **display_name** | **필수** | 표시 이름 (닉네임) |

**파라미터가 부족한 경우 즉시 작업을 중단하고 다음을 안내한다:**

```
회원가입에 필요한 정보가 부족합니다.
사용법: /korea:register <이메일> <비밀번호> <display_name>
예시: /korea:register user@example.com mypass123 홍길동

필수 항목:
  - 이메일: 유효한 이메일 주소
  - 비밀번호: 최소 6자 이상
  - display_name: 표시 이름 (닉네임)
```

### 2단계: 회원가입 실행

```bash
python3 skills/korea/scripts/korea_api.py --api-key "" register \
  --email "{EMAIL}" --password "{PASSWORD}" --display-name "{DISPLAY_NAME}"
```

### 3단계: 결과 보고

**성공 시**:
- 생성된 계정 정보 (ID, 이메일, 표시이름)를 안내한다
- 발급된 **API 키**를 안내한다
- 이후 다른 명령어에서 이 API 키를 사용할 수 있음을 알려준다

**실패 시** 에러 메시지를 사용자에게 전달한다:
- `"이미 등록된 이메일입니다."` → 다른 이메일 사용 또는 로그인 안내
- `"비밀번호는 최소 6자 이상이어야 합니다."` → 비밀번호 변경 안내
- `"올바른 이메일 형식이 아닙니다."` → 이메일 형식 확인 안내

## 주의사항

- 비밀번호는 최소 6자 이상이어야 한다
- 이미 등록된 이메일로는 가입할 수 없다
- 가입 즉시 자동 로그인되며 API 키가 발급된다
- **API 키는 안전하게 보관해야 한다** — 로그나 공개 장소에 노출하지 않는다
- 서브사이트의 첫 번째 가입자는 자동으로 사이트 소유자(관리자)로 지정된다
