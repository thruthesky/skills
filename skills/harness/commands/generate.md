---
name: harness
description: "리포지토리 안에 Harness 방식의 문서 세트를 만들거나 갱신한다. AGENTS.md와 docs/를 짧은 진입점과 구조화된 시스템 오브 레코드로 정리해야 할 때 사용한다. 짧은 AGENTS.md, docs/ 중심의 지식 구조, progressive disclosure, 아키텍처 문서, 제품 명세, 실행 계획, 품질 문서를 만드는 작업에 사용한다. 제품 구현이 아니라 문서 구조 설계와 문서 작성 자체에만 사용한다."
---

# Harness 문서 생성 스킬

이 스킬은 OpenAI 공식 글 **"Harness engineering: leveraging Codex in an agent-first world"** (By Ryan Lopopolo, Member of the Technical Staff)의 핵심 원칙을 바탕으로, 리포지토리 안에 **에이전트 친화적인 문서 구조**를 만든다.

이 스킬의 목적은 공식 글을 번역하는 것이 아니라, 그 원칙을 실제 리포지토리에 적용해 `AGENTS.md`와 `docs/`를 설계하고 작성하는 것이다.

---

## 0. 필수 입력: ARGUMENTS

**이 스킬을 사용하려면 반드시 사용자가 ARGUMENTS를 제공해야 한다.**

ARGUMENTS가 없으면 문서를 만들 수 없다. 사용자에게 다음을 요청하라:

```
이 스킬을 사용하려면 다음 정보를 프롬프트에 포함해 주세요:

필수:
  - 대상 리포지토리 또는 프로젝트에 대한 설명
    (무엇을 만드는 프로젝트인지, 기술 스택, 주요 기능 등)

선택 (있으면 더 정확한 문서를 만들 수 있음):
  - 현재 리포지토리 상태 (빈 저장소 / 코드만 있음 / 문서가 이미 있음)
  - 원하는 작업 모드 (신규 생성 / 개편 / 증설 / 정리)
  - 특별히 강조할 문서 영역 (아키텍처 / 보안 / 프론트엔드 등)
```

**ARGUMENTS가 없이 이 스킬이 트리거되면:**
1. 위 안내 메시지를 사용자에게 보여준다.
2. 사용자의 응답을 받은 뒤에야 문서 생성을 시작한다.
3. 절대 추측으로 문서를 만들지 않는다.

ARGUMENTS 예시:

```
예시 1: "Laravel + Vue.js로 만드는 커뮤니티 사이트. 게시판, 회원관리, 관리자 기능이 있다."
예시 2: "기존 Next.js 프로젝트인데 AGENTS.md가 300줄이라 줄이고 싶다."
예시 3: "새로 시작하는 Flutter 앱. 아직 코드가 없다. 목표 아키텍처 중심으로 문서를 만들어줘."
```

---

## 1. Harness란 무엇인가

### 1.1 정의

Harness는 **"에이전트가 일을 잘하도록 만드는 리포지토리 운영 방식"**이다.

OpenAI 공식 정의에서 가장 중요한 문장:

> "Give Codex a map, not a 1,000-page instruction manual."
> (에이전트에게 지도를 줘라, 1000페이지짜리 설명서를 주지 마라.)

> "From the agent's point of view, anything it can't access in-context while running effectively doesn't exist."
> (에이전트 관점에서, 실행 중 접근할 수 없는 정보는 사실상 존재하지 않는다.)

### 1.2 핵심 발상

- 사람 머릿속, 채팅, 외부 문서에 있는 지식을 **리포지토리 안으로** 가져온다.
- `AGENTS.md`는 전체 규칙집이 아니라 에이전트의 **진입 지도(table of contents)** 역할을 한다.
- 실제 지식은 `docs/` 아래에 구조적으로 저장한다.
- 에이전트는 작은 진입점에서 시작해서 필요한 문서만 따라가며 읽는다.
- 계획, 의사결정, 아키텍처, 품질 상태를 모두 리포지토리 안에 남긴다.

### 1.3 Harness의 실제 성과 (OpenAI 공식 사례)

OpenAI는 이 방식으로 다음 성과를 냈다:

- **3명의 엔지니어**가 5개월 동안 **약 100만 줄**의 코드를 생성
- **1,500개 이상의 PR** 병합
- 엔지니어당 하루 평균 **3.5개의 PR**
- 수작업 대비 **약 1/10의 시간**으로 구축
- 팀이 7명으로 늘어나자 **오히려 처리량이 증가**
- 사람이 직접 쓴 코드는 **0줄** (모든 코드를 에이전트가 작성)

이 성과의 핵심 비결이 바로 Harness 문서 구조다.

### 1.4 왜 Harness 문서가 필요한가

Harness 문서는 "문서 예쁘게 쓰기"가 목적이 아니다.

목적:
- 에이전트가 리포지토리의 목적과 구조를 **빠르게** 이해하게 한다.
- 구현 제약과 제품 요구사항을 **문서로 명시**한다.
- 작업 중 필요한 문맥을 채팅이 아니라 **리포지토리 내부에서** 찾게 한다.
- 큰 작업을 **계획 문서로 분해**해서 반복 실행 가능하게 만든다.
- 코드와 문서의 **드리프트를 줄인다**.
- Slack, Google Docs, 사람 머릿속에만 있던 지식을 **에이전트가 접근 가능한 형태**로 만든다.

### 1.5 거대한 AGENTS.md가 실패하는 이유 (공식 근거)

OpenAI는 "하나의 거대한 AGENTS.md" 방식을 시도했고, 다음 4가지 이유로 실패했다:

1. **컨텍스트는 희소 자원이다**: 거대한 지시 파일이 실제 작업, 코드, 관련 문서를 밀어낸다. 에이전트가 핵심 제약을 놓치거나 잘못된 것에 최적화한다.

2. **과도한 가이드는 가이드가 아니다**: 모든 것이 "중요"하면 아무것도 중요하지 않다. 에이전트가 의도적으로 탐색하는 대신 로컬 패턴 매칭에 빠진다.

3. **즉시 부패한다**: 거대한 매뉴얼은 오래된 규칙의 무덤이 된다. 에이전트는 무엇이 여전히 유효한지 알 수 없고, 사람도 유지보수를 포기한다.

4. **검증이 어렵다**: 하나의 덩어리는 기계적 검사(커버리지, 신선도, 소유권, 크로스링크)에 적합하지 않아 드리프트가 불가피하다.

**그래서 AGENTS.md를 백과사전이 아니라 목차(table of contents)로 취급한다.**

---

## 2. 이 스킬의 범위

이 스킬은 **문서를 만든다**. 제품 코드를 구현하지 않는다.

이 스킬이 담당하는 일:
- `AGENTS.md` 작성 또는 개편
- `docs/` 구조 설계
- 인덱스 문서 작성
- 아키텍처 문서 작성
- 제품 명세 문서 작성
- 실행 계획 문서 작성
- 품질 상태 문서 작성
- 설계 철학(core-beliefs) 문서 작성
- 필요 시 보안, 신뢰성, 프론트엔드, 디자인 관련 문서 추가

이 스킬이 하지 말아야 할 일:
- 기능 구현
- 서버 배포
- 테스트 코드 구현
- 실제 비즈니스 로직 작성
- 공식 글의 문장 복붙

### 2.1 이 스킬이 트리거되어야 하는 사용자 요청

다음과 같은 요청이 들어오면 이 스킬을 사용한다.

직접적인 요청 예:
- "하네스 방식으로 AGENTS.md를 만들어줘"
- "docs 폴더를 Harness 스타일로 정리해줘"
- "에이전트가 읽기 좋은 문서 구조를 만들어줘"
- "제품 구현 전에 문서부터 체계화해줘"
- "실행 계획 문서와 제품 명세 문서를 먼저 만들어줘"

간접적인 요청 예:
- 리포지토리에 문서가 거의 없어서 에이전트가 어디서부터 읽어야 할지 모르는 상태
- `AGENTS.md`가 너무 길거나 뒤죽박죽인 상태
- 제품 요구사항이 채팅에는 있지만 리포지토리 안에는 없는 상태
- 구현은 진행됐지만 아키텍처/품질/계획 문서가 비어 있는 상태

이 스킬을 굳이 쓰지 않아도 되는 경우:
- 단순 README 수정만 필요한 경우
- 이미 문서 구조가 잘 잡혀 있고 특정 문서 한두 개만 소폭 수정하면 되는 경우
- 코드 구현이 주 작업이고 문서는 부차적인 경우

### 2.2 이 스킬의 작업 모드

이 스킬은 리포지토리 상태에 따라 네 가지 모드로 동작한다.

#### A. 신규 생성 모드

사용 시점:
- 리포지토리에 `AGENTS.md`와 `docs/`가 거의 없을 때

목표:
- 최소 Harness 뼈대를 한 번에 만든다

보통 만드는 파일:
- `AGENTS.md`
- `docs/index.md`
- `docs/ARCHITECTURE.md`
- `docs/design-docs/core-beliefs.md`
- `docs/product-specs/index.md`
- 대표 제품 명세 1개
- 활성 실행 계획 1개
- `docs/QUALITY_SCORE.md`

#### B. 개편 모드

사용 시점:
- 문서는 있지만 구조가 엉켜 있고 중복이 심할 때

목표:
- 기존 문서를 살리되 구조를 정리한다

핵심 작업:
- 너무 긴 `AGENTS.md`를 축약
- `docs/index.md`를 문서 허브로 재구성
- 중복 문서를 통합
- 소스 오브 트루스 위치를 명확히 재지정

#### C. 증설 모드

사용 시점:
- 기본 구조는 있지만 제품 영역이 늘어나서 새 문서가 필요할 때

목표:
- 새 제품 명세, 새 실행 계획, 새 참조 문서를 기존 구조에 자연스럽게 추가한다

#### D. 정리 모드

사용 시점:
- 문서 드리프트가 누적되어 무엇이 현재 기준인지 모를 때

목표:
- 상태 표기 정리
- obsolete 내용 제거
- broken link 및 잘못된 진술 수정
- 현재 상태/목표 상태 재구분

---

## 3. 공식 글에서 반드시 반영할 핵심 원칙

### 3.1 `AGENTS.md`는 짧아야 한다 — 지도(map)여야 한다

`AGENTS.md`는 백과사전이 아니라 **목차(table of contents)**다.

OpenAI 공식 기준:
- **약 100줄** 안팎
- 에이전트의 **진입 지도** 역할만 한다
- 깊은 내용은 `docs/`의 구체적 문서로 포인터를 건다

역할:
- 리포지토리 정체성 소개 (무엇을 만드는가)
- 가장 중요한 제약 몇 가지 정리
- 어디 문서를 먼저 읽어야 하는지 안내

`AGENTS.md`에 모든 규칙을 몰아넣지 마라.

### 3.2 `docs/`가 시스템 오브 레코드(System of Record)다

> "The repository's knowledge base lives in a structured docs/ directory treated as the system of record."

실제 지식은 `docs/`에 둔다:
- 아키텍처
- 제품 요구사항
- 설계 원칙 (core beliefs)
- 활성 작업 계획
- 완료된 계획
- 기술 부채 추적
- 품질 평가
- 참조 문서 (외부 라이브러리, 디자인 시스템 등)

**채팅이나 프롬프트에만 있던 지식을 문서로 옮겨야 한다.**

실전 판단 기준:
- Slack에서 합의한 아키텍처 패턴 → `docs/ARCHITECTURE.md`에 기록
- 구두로 정한 제품 요구사항 → `docs/product-specs/`에 기록
- PR 리뷰에서 반복되는 피드백 → `docs/design-docs/core-beliefs.md`에 원칙으로 승격

### 3.3 Progressive Disclosure를 적용한다

> "Agents start with a small, stable entry point and are taught where to look next, rather than being overwhelmed up front."

에이전트가 처음부터 모든 문서를 읽게 만들지 마라.

좋은 구조 (3단계 탐색):
```
1단계: AGENTS.md        → 저장소 정체성, 핵심 제약, 문서 지도
2단계: docs/index.md    → 문서 그룹별 포털, 읽기 순서 안내
3단계: docs/구체문서.md  → 아키텍처, 제품 명세, 실행 계획 등 상세 내용
```

즉, **작은 진입점 → 관련 문서 → 세부 문서** 순으로 읽히게 만든다.

### 3.4 에이전트 가시성 원칙 (Agent Legibility)

> "From the agent's point of view, anything it can't access in-context while running effectively doesn't exist."

에이전트가 볼 수 없는 정보는 존재하지 않는 것과 같다.

| 에이전트가 볼 수 있는 것 | 에이전트가 볼 수 없는 것 |
|---|---|
| 리포지토리 안의 마크다운 문서 | Google Docs |
| 코드, 스키마, 설정 파일 | Slack 대화 |
| 버전 관리된 실행 계획 | 사람 머릿속의 암묵지 |
| docs/ 안의 참조 문서 | 외부 위키, Notion |

따라서 Harness 문서를 만들 때는:
- 사람이 알고 있지만 문서에 없는 것을 **찾아내서 문서로 만든다**.
- 에이전트가 **리포지토리만 읽고도** 제품과 아키텍처를 이해할 수 있어야 한다.
- 외부 참조가 필요하면 `docs/references/`에 요약본을 넣는다.

### 3.5 문서는 에이전트가 읽기 쉽게 작성한다

사람에게만 보기 좋은 문서가 아니라, 에이전트가 빠르게 파싱할 수 있는 문서를 쓴다.

선호:
- 짧은 섹션
- 명확한 제목 (## 레벨 제목)
- 평평한 목록 (- 불릿)
- 구체적인 파일 경로
- 현재 상태와 목표 상태의 명확한 구분
- 크로스링크 (`[ARCHITECTURE.md](./ARCHITECTURE.md)`)

비선호:
- 추상적인 소개만 긴 문서
- 산문 위주의 장문
- 링크 없는 설명
- 어디가 소스 오브 트루스인지 모호한 문서
- 같은 정보를 여러 문서에 복붙

### 3.6 계획 문서를 1급 산출물(first-class artifact)로 취급한다

> "Plans are treated as first-class artifacts."

OpenAI는 계획 문서를 다음과 같이 운영했다:
- **경량 계획**: 작은 변경에 대한 임시 계획
- **실행 계획 (exec-plans)**: 복잡한 작업의 진행 상황과 의사결정 로그를 리포지토리에 체크인
- **활성 계획, 완료된 계획, 기술 부채**를 모두 버전 관리하고 한 곳에 모음

계획 문서는 다음을 포함해야 한다:
- 목표
- 범위
- 단계
- 검증 방법
- 리스크
- 완료 기준

### 3.7 문서 드리프트를 줄인다

Harness 문서는 "많이 만드는 것"보다 "정확하게 연결하는 것"이 중요하다.

반드시 지켜라:
- 한 규칙은 한 문서에 두고 다른 문서에서는 **링크만** 건다.
- 구현되지 않은 것은 구현된 것처럼 쓰지 않는다.
- 오래된 내용을 그대로 남기지 않는다.

OpenAI의 기계적 강제 방법:
- 전용 린터와 CI 작업으로 문서가 최신인지, 크로스링크가 정확한지, 구조가 올바른지 검증
- 반복 실행되는 **"doc-gardening" 에이전트**가 오래되거나 폐기된 문서를 스캔하고 수정 PR을 생성

### 3.8 엔트로피와 가비지 컬렉션

에이전트가 자율적으로 일하면 리포지토리에 불일치(drift)가 쌓인다. OpenAI는 이를 **"가비지 컬렉션"**으로 해결했다.

Golden Principles (황금 원칙):
- 공유 유틸리티 패키지를 선호하여 불변성을 중앙화한다.
- 데이터를 추측하지 않는다 — 경계에서 검증하거나 타입이 있는 SDK에 의존한다.

운영 방법:
- 정기적으로 백그라운드 작업이 코드베이스를 스캔
- 편차를 찾아 품질 등급을 업데이트
- 타겟 리팩토링 PR을 자동 생성

> "Technical debt is like a high-interest loan: it's almost always better to pay it down continuously in small increments."

문서에도 같은 원칙을 적용한다:
- 문서를 주기적으로 검토하여 현재 코드와 맞는지 확인
- 틀린 문서는 즉시 수정하거나 `Deprecated` 표시

---

## 4. 이 스킬이 만들어야 하는 기본 문서 구조

모든 리포지토리에 똑같이 적용하지 말고, 아래 구조를 기본 골격으로 삼아 **사용자의 ARGUMENTS에 맞게 필요한 것만** 만든다.

### 4.1 OpenAI 공식 구조 (참고 기준)

```text
AGENTS.md                          ← 짧은 진입 지도 (~100줄)
ARCHITECTURE.md                    ← 시스템 전체 지도
docs/
├── index.md                       ← 문서 포털
├── design-docs/
│   ├── index.md
│   ├── core-beliefs.md            ← 에이전트 우선 운영 원칙
│   └── ...
├── exec-plans/
│   ├── active/                    ← 현재 진행 중인 계획
│   │   └── <plan>.md
│   ├── completed/                 ← 완료된 계획 아카이브
│   └── tech-debt-tracker.md       ← 기술 부채 추적
├── generated/
│   └── db-schema.md               ← 자동 생성 문서
├── product-specs/
│   ├── index.md
│   ├── new-user-onboarding.md
│   └── ...
├── references/
│   ├── design-system-reference-llms.txt
│   ├── nixpacks-llms.txt
│   └── ...
├── DESIGN.md
├── FRONTEND.md
├── PLANS.md
├── PRODUCT_SENSE.md
├── QUALITY_SCORE.md
├── RELIABILITY.md
└── SECURITY.md
```

### 4.2 실전 권장 최소 구조

모든 프로젝트에 위 전체를 만들 필요는 없다. 실전 최소 구조:

```text
AGENTS.md                          ← 필수
docs/
├── index.md                       ← 필수
├── ARCHITECTURE.md                ← 필수
├── design-docs/
│   └── core-beliefs.md            ← 권장
├── product-specs/
│   ├── index.md                   ← 권장
│   └── <주요기능>.md              ← 최소 1개
├── exec-plans/
│   └── active/
│       └── <현재계획>.md          ← 최소 1개
└── QUALITY_SCORE.md               ← 권장
```

### 4.3 필요에 따라 추가하는 문서

다음 질문으로 추가 여부를 결정한다:

| 추가 문서 | 추가 기준 |
|---|---|
| `docs/SECURITY.md` | 인증/인가, 개인정보, 결제, 관리자 권한, 비밀값 관리가 중요한 경우 |
| `docs/RELIABILITY.md` | 장애 허용성, 복구, 백업, 모니터링, 외부 연동이 있는 경우 |
| `docs/FRONTEND.md` | 화면 구조, 디자인 시스템, 상태 관리, 라우팅 규칙이 복잡한 경우 |
| `docs/DESIGN.md` | 브랜드/스타일 가이드가 별도 문서로 필요한 경우 |
| `docs/PLANS.md` | 전체 로드맵이나 마일스톤 관리가 필요한 경우 |
| `docs/PRODUCT_SENSE.md` | 제품 감각과 UX 원칙을 별도로 문서화해야 하는 경우 |
| `docs/references/` | 외부 API 규격, DB 스키마, 라이브러리 참조, llms.txt 등 |
| `docs/generated/` | 자동 생성 문서 (DB 스키마, API 문서 등) |
| `docs/exec-plans/tech-debt-tracker.md` | 기술 부채를 체계적으로 추적할 때 |

---

## 5. 이 스킬을 사용할 때의 작업 순서

아래 순서를 기본 워크플로로 사용한다.

### 5.1 현재 리포지토리를 먼저 읽어라

문서를 쓰기 전에 반드시 현재 저장소를 파악한다.

먼저 읽을 후보:
- `README.md`
- 기존 `AGENTS.md`
- 기존 `docs/`
- 진입점 파일
- 런타임/배포 설정 파일
- 프레임워크나 앱 구조를 드러내는 파일

파악할 항목:
- 이 리포지토리가 만드는 제품은 무엇인가
- 실제 기술 스택은 무엇인가
- 엔트리포인트는 무엇인가
- 배포 방식은 무엇인가
- 현재 구현 상태는 어느 정도인가
- 무엇이 이미 문서화되어 있고 무엇이 비어 있는가

중요:
- 리포지토리가 비어 있으면 **목표 상태** 중심으로 문서를 쓴다.
- 리포지토리가 이미 구현되어 있으면 **현재 상태**를 기준으로 문서를 쓴다.
- 현재 상태와 목표 상태가 다르면 **둘을 분리해서** 기록한다.

#### 5.1.1 실전 조사 체크리스트

문서를 쓰기 전에 최소한 아래 질문에 답할 수 있어야 한다.

- 사용자는 무엇을 만들고 싶어 하는가 (ARGUMENTS에서 확인)
- 저장소에 이미 구현된 것은 무엇인가
- 실제 런타임 진입점은 무엇인가
- 웹/API/CLI/worker 등 실행 표면이 몇 개인가
- 배포 파일은 어디에 있는가
- 로컬 개발 환경은 어떤 도구로 올라가는가
- 저장소에 이미 있는 문서 중 살릴 수 있는 것은 무엇인가
- 오래되었거나 거짓인 문서는 무엇인가

#### 5.1.2 실전 조사 방법

조사할 때는 빠르게 저장소 지도를 만든다.

권장 접근:
- 파일 목록으로 구조 파악
- 엔트리포인트 파일 확인
- 환경설정/배포 파일 확인
- 기존 문서 확인
- 필요 시 테스트, 마이그레이션, 스크립트 위치 확인

실무적으로 자주 읽는 파일:
- `README.md`
- `AGENTS.md` / `CLAUDE.md`
- `docs/index.md`
- 앱 진입점 (`index.php`, `main.py`, `server.js`, `app.ts`, `lib/main.dart` 등)
- 라우터 또는 서버 부트스트랩 파일
- `docker-compose.yml`, `Dockerfile`, 배포 디렉터리
- CI 파일 (`.github/workflows/`, `Jenkinsfile` 등)
- `package.json`, `composer.json`, `pubspec.yaml`, `pyproject.toml` 등

#### 5.1.3 리포지토리 상태별 문서화 전략

**거의 빈 저장소:**
- 문서 방향: 목표 상태 중심
- `Planned`와 `Target` 표기를 적극 사용
- 강조할 문서: 제품 명세, 초기 아키텍처, 초기 실행 계획

**코드만 있고 문서가 없는 저장소:**
- 문서 방향: 현재 구현 상태 먼저 정리, 이후 목표 상태를 분리해서 추가
- 강조할 문서: `AGENTS.md`, `docs/index.md`, `docs/ARCHITECTURE.md`, `docs/QUALITY_SCORE.md`

**문서는 많은데 구조가 나쁜 저장소:**
- 문서 방향: 통합과 재배치, 중복 축소, 링크 중심 재조직
- 강조할 문서: `AGENTS.md`, `docs/index.md`, 기술 부채/품질 문서

### 5.2 최소 문서 세트를 결정하라

무조건 문서를 많이 만들지 마라.

최소 권장 세트:
- `AGENTS.md`
- `docs/index.md`
- `docs/ARCHITECTURE.md`
- `docs/design-docs/core-beliefs.md`
- 제품 명세 1개 이상
- 활성 실행 계획 1개 이상

더 필요한 경우에만 추가:
- 품질 문서
- 보안 문서
- 신뢰성 문서
- 프론트엔드 문서
- 참조 문서

### 5.3 `AGENTS.md`를 먼저 설계하라

`AGENTS.md`는 요약 지도다.

포함할 내용:
- 이 리포지토리가 무엇을 만드는지
- 실제 사용 스택
- 주요 엔트리포인트
- 작업 시 반드시 지켜야 할 핵심 제약
- `docs/` 안 어디를 읽어야 하는지

포함하지 말 것:
- 모든 제품 요구사항
- 모든 아키텍처 세부사항
- 모든 운영 규칙
- 긴 개념 설명

`AGENTS.md`는 다음 질문에 답해야 한다:
- 이 저장소는 무엇인가
- 무엇부터 읽어야 하는가
- 어디가 아키텍처 소스 오브 트루스인가
- 어디가 제품 요구사항 소스 오브 트루스인가
- 지금 활성 계획은 어디에 있는가

### 5.4 `docs/index.md`를 허브로 만들어라

`docs/index.md`는 문서 포털이다.

반드시 포함:
- 문서 구조 설명
- 각 문서 그룹 링크
- 어떤 문서를 언제 읽어야 하는지 간단한 설명

### 5.5 아키텍처 문서를 작성하라

`docs/ARCHITECTURE.md`는 시스템 지도를 담당한다.

반드시 다룰 내용:
- 요청 흐름
- 주요 계층 또는 패키지
- 데이터 저장 구조
- API / 웹 / 백그라운드 작업 경계
- 배포 구조
- 모듈 책임

### 5.6 설계 철학 문서를 작성하라

`docs/design-docs/core-beliefs.md`는 리포지토리의 안정적인 설계 철학을 적는다.

이 문서에는 변하기 쉬운 구현 디테일보다 **오래 유지될 원칙**을 적는다.

### 5.7 제품 명세 문서를 작성하라

`docs/product-specs/` 아래에는 사용자 관점의 요구사항을 적는다.

### 5.8 실행 계획 문서를 작성하라

`docs/exec-plans/active/`에는 지금 진행할 일을 구체적으로 적는다.

실행 계획 문서를 반드시 만들어야 하는 조건 (둘 이상 해당 시):
- 구현 단계가 3단계 이상이다
- 제품/아키텍처/배포가 동시에 바뀐다
- 검증 방법을 따로 정리해야 한다
- 여러 기능이 얽혀 있다
- 작업을 한 번에 끝내기 어렵다
- 나중에 다른 에이전트가 이어받을 가능성이 높다

### 5.9 품질 문서를 작성하라

`docs/QUALITY_SCORE.md`는 상태 점검 문서다.

---

## 6. 파일별 작성 가이드와 실전 예시

아래 가이드는 템플릿처럼 사용하되, 리포지토리 상황에 맞게 줄이거나 바꿔도 된다.

### 6.1 `AGENTS.md`

#### 권장 구조

```md
# AGENTS

## Repo Identity
- 이 저장소가 만드는 제품
- 핵심 스택

## Entry Points
- 주요 실행 파일
- 주요 설정 파일

## Hard Constraints
- 반드시 지켜야 하는 규칙

## Docs Map
- docs/index.md
- docs/ARCHITECTURE.md
- docs/design-docs/core-beliefs.md
- docs/product-specs/index.md
- docs/exec-plans/active/<...>.md
```

#### 작성 규칙

- **100줄 안팎**을 목표로 한다 (OpenAI 공식 기준).
- 경로를 직접 적는다.
- "자세한 내용은 어디로 가라"를 분명히 적는다.
- 기술 스택은 사실만 적는다.
- "Favor X" 같은 애매한 권장 표현보다 실제 제약을 적는다.
- 배포 방식, 진입점, 테스트 진입점은 있으면 꼭 적는다.

#### 실전 예시: Laravel + Vue.js 커뮤니티 사이트

```md
# AGENTS

## Repo Identity
- 한국어 커뮤니티 사이트 (게시판, 회원관리, 관리자 기능)
- Laravel 11 + Vue 3 + Inertia.js + MySQL 8 + Redis
- Tailwind CSS + Headless UI

## Entry Points
- 웹 진입점: `public/index.php`
- 라우트 정의: `routes/web.php`, `routes/api.php`
- 프론트엔드 진입점: `resources/js/app.ts`
- 큐 워커: `app/Jobs/`

## Hard Constraints
- PHP 8.3 이상, Node 20 이상
- 모든 DB 접근은 Eloquent ORM 사용
- API 응답은 Laravel Resource로 변환
- 프론트엔드 상태는 Inertia shared data 사용
- 배포: Dokploy (Docker Compose)

## Docs Map
- 전체 문서 포털: [docs/index.md](docs/index.md)
- 아키텍처: [docs/ARCHITECTURE.md](docs/ARCHITECTURE.md)
- 설계 철학: [docs/design-docs/core-beliefs.md](docs/design-docs/core-beliefs.md)
- 제품 명세: [docs/product-specs/index.md](docs/product-specs/index.md)
- 활성 계획: [docs/exec-plans/active/](docs/exec-plans/active/)
- 품질 상태: [docs/QUALITY_SCORE.md](docs/QUALITY_SCORE.md)
```

#### 실전 예시: Flutter 모바일 앱 (새 프로젝트)

```md
# AGENTS

## Repo Identity
- 소셜 피트니스 트래킹 앱 (운동 기록, 친구 피드, 챌린지)
- Flutter 3.x + Dart + Firebase (Auth, Firestore, Storage, FCM)
- Riverpod 상태관리 + GoRouter 라우팅

## Entry Points
- 앱 진입점: `lib/main.dart`
- 라우트 정의: `lib/router/app_router.dart`
- Firebase 설정: `firebase.json`, `lib/firebase_options.dart`

## Hard Constraints
- Dart 3.x, Flutter 3.x
- 상태관리는 Riverpod만 사용
- Firestore 스키마 변경 시 반드시 마이그레이션 문서 작성
- iOS/Android 동시 지원, 웹은 Target

## Docs Map
- 전체 문서 포털: [docs/index.md](docs/index.md)
- 아키텍처: [docs/ARCHITECTURE.md](docs/ARCHITECTURE.md)
- 설계 철학: [docs/design-docs/core-beliefs.md](docs/design-docs/core-beliefs.md)
- 제품 명세: [docs/product-specs/index.md](docs/product-specs/index.md)
- 활성 계획: [docs/exec-plans/active/](docs/exec-plans/active/)
```

### 6.2 `docs/index.md`

#### 권장 구조

```md
# Docs Index

이 문서는 전체 문서의 포털이다. 목적별로 분류된 링크를 따라가라.

## Architecture
- [ARCHITECTURE.md](./ARCHITECTURE.md) — 시스템 구조, 요청 흐름, 계층, 배포

## Design Philosophy
- [design-docs/core-beliefs.md](./design-docs/core-beliefs.md) — 변하지 않는 설계 원칙

## Product Specs
- [product-specs/index.md](./product-specs/index.md) — 제품 기능별 요구사항 목록

## Execution Plans
- [exec-plans/active/](./exec-plans/active/) — 현재 진행 중인 작업 계획
- [exec-plans/completed/](./exec-plans/completed/) — 완료된 계획 아카이브

## Quality
- [QUALITY_SCORE.md](./QUALITY_SCORE.md) — 영역별 품질 평가와 갭 분석
```

#### 작성 규칙

- 문서들을 **목적별**로 묶는다.
- 링크만 던지지 말고 **"언제 읽는지"** 짧게 설명한다.
- 가장 자주 읽을 문서를 위로 올린다.
- 파일이 많아지면 섹션별 인덱스를 둔다.
- 문서가 아직 없으면 링크를 만들기보다 **`Planned`**로 적는 편이 낫다.

#### 실전 팁: 읽기 순서 안내

좋은 `docs/index.md`는 에이전트에게 **읽기 순서**를 알려준다:

```md
## 처음 읽는 사람을 위한 순서
1. [ARCHITECTURE.md](./ARCHITECTURE.md) — 전체 그림 파악
2. [design-docs/core-beliefs.md](./design-docs/core-beliefs.md) — 설계 원칙 이해
3. [product-specs/index.md](./product-specs/index.md) — 제품 요구사항 확인
4. [exec-plans/active/](./exec-plans/active/) — 현재 진행 작업 확인
```

### 6.3 `docs/ARCHITECTURE.md`

#### 권장 구조

```md
# Architecture

## System Summary
- 한 문단으로 시스템 설명

## Runtime Entry Points
- 주요 실행 파일과 역할

## Request Flow
- 사용자 요청이 어디서 시작해 어디서 끝나는지

## Major Layers
- 계층 구조와 각 계층의 책임

## Data and Storage
- 데이터베이스, 파일 저장소, 캐시

## Boundaries
- API / 웹 / 백그라운드 작업 경계

## Deployment Shape
- 배포 구조와 인프라

## Directory Structure
- 주요 디렉터리와 역할

## Open Questions
- 미결정 사항
```

#### 작성 규칙

- 계층과 책임을 분명히 적는다.
- 디렉터리 설명보다 **"왜 이렇게 나뉘는지"**를 적는다.
- 구현 안 된 것은 `Planned` 또는 `Target`으로 표시한다.

#### 실전 예시: Request Flow

```md
## Request Flow

### 웹 요청 흐름 (Current)
1. 브라우저 → Nginx 리버스 프록시 (`:443`)
2. Nginx → Laravel (`public/index.php`)
3. 미들웨어 체인: `auth`, `verified`, `throttle`
4. 라우트 → Controller → Service → Repository → Eloquent → MySQL
5. 응답: Controller → Inertia::render() → Vue 컴포넌트 → HTML

### API 요청 흐름 (Current)
1. 클라이언트 → Nginx → Laravel (`routes/api.php`)
2. 미들웨어: `auth:sanctum`, `throttle:api`
3. Controller → Service → Repository → MySQL
4. 응답: JSON Resource

### 백그라운드 작업 흐름 (Current)
1. Service → dispatch(Job)
2. Redis Queue → Worker (`php artisan queue:work`)
3. Job → Service → 외부 API / DB
```

#### 실전 예시: Major Layers (아키텍처 강제 참고)

OpenAI는 각 비즈니스 도메인을 다음 고정 계층으로 나누고 의존성 방향을 **기계적으로 강제**했다:

```
Types → Config → Repo → Service → Runtime → UI
```

이 패턴을 참고하여 해당 리포지토리에 맞게 계층을 정의한다:

```md
## Major Layers

| 계층 | 책임 | 의존 방향 |
|---|---|---|
| Models (Types) | 데이터 구조 정의 | 없음 (최하위) |
| Repositories | DB 접근 추상화 | Models |
| Services | 비즈니스 로직 | Models, Repositories |
| Controllers | HTTP 요청 처리 | Services |
| Views (UI) | 화면 렌더링 | Controllers에서 전달받은 데이터 |

규칙: 상위 계층이 하위 계층에 의존한다. 역방향 의존은 금지한다.
```

### 6.4 `docs/design-docs/core-beliefs.md`

#### 권장 구조

```md
# Core Beliefs

이 문서는 자주 바뀌는 기능 명세가 아니라 **운영 철학**이다.

## Repo-Local Truth
- 리포지토리 안 문서를 진실의 원천으로 둔다.
- 채팅, 외부 문서에만 있는 지식은 리포지토리로 옮긴다.

## Explicit Entry Points
- 숨은 규칙보다 명시적 진입점을 선호한다.
- 에이전트가 찾아야 하는 정보는 경로로 안내한다.

## Current vs Target State
- 구현 상태와 목표 상태를 분리한다.
- 구현되지 않은 것을 구현된 것처럼 쓰지 않는다.

## Simplicity Over Cleverness
- 과한 추상화보다 읽기 쉬운 구조를 선호한다.
- "boring" 기술이 에이전트에게는 더 다루기 쉽다.

## Cross-Linked Docs
- 중복 대신 링크를 사용한다.
- 한 규칙은 한 문서에 두고 다른 문서에서는 참조한다.

## Mechanical Enforcement
- 문서화만으로는 일관성을 유지할 수 없다.
- 가능하면 린터, CI, 구조 테스트로 기계적으로 강제한다.
```

#### 작성 규칙

- 짧고 단단한 원칙 문장 위주로 쓴다.
- 팀이 반복해서 말하는 기준을 문장으로 승격시켜라.
- 구현 디테일 대신 **의사결정 기준**을 남겨라.

### 6.5 `docs/product-specs/index.md`

#### 권장 구조

```md
# Product Specs

## Core Product
- [site-overview.md](./site-overview.md) — 사이트 전체 명세

## User Management
- [user-auth.md](./user-auth.md) — 회원가입, 로그인, 프로필

## Community
- [board.md](./board.md) — 게시판 기능 명세

## Admin
- [admin-dashboard.md](./admin-dashboard.md) — 관리자 기능 명세
```

#### 작성 규칙

- 제품 명세 문서가 여러 개면 **역할별**로 묶어라.
- 어떤 문서가 전체 명세이고 어떤 문서가 하위 기능 명세인지 명시하라.

### 6.6 `docs/product-specs/<name>.md`

#### 권장 구조

```md
# <Feature or Product Name>

## Objective
- 이 기능이 해결하는 문제

## Users and Roles
- 관련 사용자 유형과 역할

## Scope
- 이 명세가 다루는 범위

## Key Flows
- 주요 사용자 흐름 (단계별)

## Screens
- 관련 화면 목록과 설명

## Entities
- 관련 데이터 엔티티

## Acceptance Criteria
- 완료 기준 (체크리스트 형태)

## Out of Scope
- 이 명세에서 제외하는 것
```

#### 작성 규칙

- **"사용자가 무엇을 할 수 있어야 하는가"** 문장으로 시작하라.
- 데이터 엔티티와 화면 흐름을 같이 적으면 좋다.
- 구현 기술 세부사항은 아키텍처 문서로 보내라.
- 관리자 기능은 일반 사용자 흐름과 분리해서 적는 편이 읽기 쉽다.

#### 실전 예시: 게시판 기능

```md
# Board (게시판)

## Objective
사용자가 글을 작성하고, 댓글로 소통하며, 카테고리별로 콘텐츠를 탐색할 수 있다.

## Users and Roles
- 비회원: 글 목록 조회, 글 읽기
- 회원: 글 작성, 댓글 작성, 좋아요, 북마크
- 관리자: 글 삭제, 사용자 차단, 카테고리 관리

## Key Flows

### 글 작성 흐름
1. 회원이 카테고리를 선택한다
2. 제목, 본문을 입력한다 (마크다운 지원)
3. 이미지를 첨부할 수 있다 (최대 10장, 각 5MB)
4. "게시" 버튼을 누른다
5. 글 목록에 새 글이 노출된다

### 댓글 흐름
1. 글 하단에서 댓글을 입력한다
2. 대댓글을 달 수 있다 (1depth까지)
3. 본인 댓글을 수정/삭제할 수 있다

## Entities
- `Post`: id, title, body, category_id, user_id, created_at, updated_at
- `Comment`: id, post_id, parent_id, user_id, body, created_at
- `Category`: id, name, slug, sort_order
- `PostLike`: post_id, user_id
- `Bookmark`: post_id, user_id

## Acceptance Criteria
- [ ] 비회원은 글 목록과 글 내용을 볼 수 있다
- [ ] 회원은 글을 작성/수정/삭제할 수 있다
- [ ] 이미지 업로드가 동작한다
- [ ] 댓글과 대댓글이 동작한다
- [ ] 카테고리별 필터링이 동작한다
- [ ] 좋아요와 북마크가 동작한다
- [ ] 관리자가 글을 삭제할 수 있다

## Out of Scope
- 실시간 알림 (별도 명세)
- 검색 기능 (별도 명세)
```

### 6.7 `docs/exec-plans/active/<plan>.md`

#### 권장 구조

```md
# <Plan Name>

상태: Active
시작일: YYYY-MM-DD
예상 완료: YYYY-MM-DD

## Objective
- 이 계획의 목표

## Scope
- 포함하는 작업 범위

## Non-Goals
- 이 계획에서 제외하는 것

## Assumptions
- 전제 조건

## Work Phases

### Phase 1: <이름>
- 작업 내용
- 산출물
- 검증 방법

### Phase 2: <이름>
- 작업 내용
- 산출물
- 검증 방법

## Validation Plan
- 각 단계별 검증 방법

## Deployment Considerations
- 배포 관련 주의사항

## Risks
- 리스크와 대응 방안

## Decision Log
| 일자 | 결정 | 근거 |
|---|---|---|

## Definition of Done
- [ ] 완료 기준 체크리스트
```

#### 작성 규칙

- 추상적 일정표가 아니라 **실행 가능한 단계**로 적는다.
- 검증 방법을 반드시 포함한다.
- 단계마다 **산출물**을 적어라.
- "구현"만 적지 말고 **"무엇을 확인해야 끝나는가"**를 적어라.
- 배포가 있는 작업이면 배포 검증 단계를 따로 적어라.
- **의사결정 로그**(Decision Log)를 포함하여 왜 그 선택을 했는지 추적한다.
- 완료되면 `exec-plans/completed/`로 이동한다.

### 6.8 `docs/QUALITY_SCORE.md`

#### 권장 구조

```md
# Quality Score

마지막 업데이트: YYYY-MM-DD

## Scoring Method
- 각 영역을 A/B/C/D/F로 평가
- A: 탄탄함, B: 양호, C: 부분적 부족, D: 심각한 갭, F: 미구현

## Product Quality

| 영역 | 등급 | 근거 |
|---|---|---|
| 회원관리 | B | 기본 인증 완료, 소셜 로그인 미구현 |
| 게시판 | C | CRUD 완료, 이미지 업로드 미구현 |
| 관리자 | D | 대시보드만 존재, 상세 관리 기능 없음 |

## Architecture Quality

| 영역 | 등급 | 근거 |
|---|---|---|
| 계층 분리 | B | Service-Repository 분리 완료 |
| API 설계 | C | RESTful 미완, 일부 엔드포인트 비표준 |
| DB 스키마 | B | 정규화 양호, 인덱스 일부 누락 |

## Test and Validation Quality

| 영역 | 등급 | 근거 |
|---|---|---|
| 단위 테스트 | D | 커버리지 15% |
| E2E 테스트 | F | 미구현 |
| CI 파이프라인 | C | 기본 lint만 실행 |

## Deployment / Ops Quality

| 영역 | 등급 | 근거 |
|---|---|---|
| 배포 자동화 | B | Docker Compose + Dokploy |
| 모니터링 | F | 미구현 |
| 백업 | D | DB 수동 백업만 |

## Top Gaps
1. E2E 테스트 전무 — 회귀 방지 불가
2. 모니터링 미구현 — 장애 감지 불가
3. 이미지 업로드 미구현 — 핵심 사용자 흐름 차단
4. 관리자 기능 부족 — 운영 불가

## Next Priorities
1. E2E 테스트 프레임워크 도입
2. 이미지 업로드 구현
3. 기본 모니터링 설정
```

#### 작성 규칙

- 점수 또는 등급만 적지 말고 **근거**를 적는다.
- 다음 개선 **우선순위**를 명시한다.
- 제품 품질과 코드 품질을 섞지 마라.
- "테스트 부족", "배포 리스크", "문서 부정확" 같은 문제를 **직접적으로** 적어라.

### 6.9 `docs/references/`를 쓸 때의 기준

`references/`는 핵심 문서에 넣기엔 너무 상세하지만 반복적으로 필요한 내용을 둔다.

예:
- DB 스키마 설명
- 외부 API 규격
- 배포 플랫폼 세부 규칙
- 운영 체크리스트
- 외부 라이브러리 참조 (llms.txt 형태)
- 디자인 시스템 참조 문서

규칙:
- 핵심 의사결정은 `references/`가 아니라 본문 문서에 둔다.
- `references/`는 링크 대상이어야지, 시작점이 되어서는 안 된다.

---

## 7. 문서 작성 결과의 출력 순서

이 스킬을 실제로 사용할 때는 보통 다음 순서로 결과를 만든다.

1. `AGENTS.md` 초안
2. `docs/index.md`
3. `docs/ARCHITECTURE.md`
4. `docs/design-docs/core-beliefs.md`
5. `docs/product-specs/index.md`
6. 대표 제품 명세
7. 활성 실행 계획
8. 품질 문서

이 순서가 좋은 이유:
- 먼저 **길잡이**를 만든다
- 그 다음 **문서 허브**를 만든다
- 그 다음 **구조와 요구사항**을 채운다
- 마지막에 **상태 평가 문서**를 붙인다

---

## 8. 프로젝트 유형별 적용 가이드

### 8.1 웹앱 (Laravel, Next.js, Django 등)

강조할 문서:
- `ARCHITECTURE.md` — Request Flow가 핵심
- `product-specs/` — 화면별 사용자 흐름
- `FRONTEND.md` — 프론트엔드 규칙 (SPA/SSR/MPA 경계)
- `SECURITY.md` — 인증/인가, CSRF, XSS

AGENTS.md에 반드시 넣을 것:
- 웹 진입점, API 진입점
- 프론트엔드/백엔드 경계
- 배포 방식

### 8.2 모바일 앱 (Flutter, React Native 등)

강조할 문서:
- `ARCHITECTURE.md` — 상태관리 패턴, 네비게이션 구조
- `product-specs/` — 화면 흐름 중심
- `DESIGN.md` — UI/UX 가이드라인
- `RELIABILITY.md` — 오프라인 지원, 에러 핸들링

AGENTS.md에 반드시 넣을 것:
- 앱 진입점 (`lib/main.dart`, `App.tsx`)
- 라우팅 구조
- 백엔드 연결 방식 (Firebase, REST API 등)
- 플랫폼별 제약 (iOS/Android)

### 8.3 API 서버 (Express, FastAPI, Go 등)

강조할 문서:
- `ARCHITECTURE.md` — 엔드포인트 목록, 미들웨어 체인
- `SECURITY.md` — 인증, Rate Limiting, 입력 검증
- `references/` — API 스키마, OpenAPI 스펙
- `RELIABILITY.md` — 에러 처리, 재시도, 타임아웃

AGENTS.md에 반드시 넣을 것:
- 서버 진입점
- 라우트 정의 위치
- 미들웨어 목록
- DB 연결 정보 위치

### 8.4 모노레포

강조할 문서:
- 루트 `AGENTS.md` — 전체 지도
- 각 패키지/앱별 `docs/` 또는 하위 `AGENTS.md`
- `ARCHITECTURE.md` — 패키지 간 의존성 방향

AGENTS.md에 반드시 넣을 것:
- 각 패키지의 위치와 역할
- 패키지 간 의존성 규칙
- 공유 코드 위치

---

## 9. 상태 표기 규칙

Harness 문서를 만들 때는 상태를 명확히 구분해야 한다.

추천 표기:

| 표기 | 의미 | 사용 시점 |
|---|---|---|
| `Current` | 현재 구현되었거나 확인된 상태 | 실제 코드와 일치하는 내용 |
| `Target` | 목표 구조 또는 목표 동작 | 아직 미구현이지만 지향하는 상태 |
| `Planned` | 아직 구현되지 않았지만 계획된 상태 | 실행 계획에 포함된 것 |
| `Pending` | 결정 또는 구현이 남아 있는 상태 | 논의가 필요한 것 |
| `Deprecated` | 더 이상 기준이 아닌 상태 | 폐기된 규칙이나 구조 |

이 구분이 없으면 **문서가 빠르게 거짓말을 시작한다.**

사용 예:

```md
## Data and Storage

### MySQL 8 (Current)
- 주 데이터 저장소
- posts, users, comments 테이블

### Redis (Current)
- 세션, 캐시, 큐

### Elasticsearch (Target)
- 전문 검색 — 현재 MySQL LIKE 검색 사용 중
- 게시글 인덱싱 예정
```

---

## 10. 피해야 할 안티패턴

1. **거대한 `AGENTS.md`**
   모든 내용을 한 파일에 몰아넣지 마라. 100줄 안팎이 목표다.

2. **빈 문서 양산**
   제목만 있고 실질 정보가 없는 문서를 만들지 마라.

3. **구현되지 않은 기능을 구현된 것처럼 쓰기**
   가장 흔한 문서 부패 원인이다. 반드시 `Target`/`Planned` 표기.

4. **같은 규칙을 여러 문서에 복붙하기**
   나중에 반드시 드리프트가 생긴다. 링크를 쓰라.

5. **공식 글 구조를 그대로 베끼기**
   리포지토리에 **필요한 구조만** 만든다. 커뮤니티 사이트에 `RELIABILITY.md`가 꼭 필요한가?

6. **방법론 설명만 많은 문서**
   "Harness란 무엇인가"만 길게 적고 실제 리포지토리 지도가 없는 문서는 실패다.

7. **링크 없는 산문**
   긴 설명을 쓰면서 파일 경로나 문서 링크가 없으면 에이전트가 따라갈 수 없다.

8. **현재 상태와 목표 상태를 섞기**
   에이전트가 무엇이 구현됐고 무엇이 아닌지 구분할 수 없다.

---

## 11. 문서를 만들 때의 판단 기준

새 문서를 만들지, 기존 문서를 수정할지 결정할 때 다음 기준을 사용한다.

새 문서를 만드는 편이 좋은 경우:
- 주제가 명확히 분리된다.
- 문서 길이가 과도해진다.
- 독립적인 소스 오브 트루스가 필요하다.
- 실행 계획처럼 수명이 분명한 문서다.

기존 문서를 수정하는 편이 좋은 경우:
- 같은 규칙의 최신판을 덮어써야 한다.
- 이미 같은 목적의 문서가 있다.
- 새 문서를 만들면 중복이 생긴다.

---

## 12. 출력 품질 기준

이 스킬로 만든 결과는 다음 수준이어야 한다.

다른 에이전트가 `AGENTS.md` 하나만 먼저 읽고도:
- 이 리포지토리가 무엇을 만드는지 이해하고
- 어디에서 아키텍처를 읽어야 하는지 알고
- 어디에서 제품 명세를 읽어야 하는지 알고
- 어떤 계획 문서가 현재 활성 상태인지 찾고
- 현재 품질 상태와 부족한 부분을 파악할 수 있어야 한다

이 수준에 도달하지 못하면 Harness 문서가 완성된 것이 아니다.

---

## 13. 실제 작성 시 최종 체크리스트

문서 작업을 끝내기 전에 반드시 확인한다.

- [ ] `AGENTS.md`가 100줄 안팎이고 길잡이 역할만 하는가
- [ ] `docs/index.md`가 문서 허브 역할을 하는가
- [ ] 아키텍처 문서가 실제 구조를 설명하는가
- [ ] 제품 명세가 사용자 흐름 중심으로 정리되어 있는가
- [ ] 실행 계획 문서가 실행 가능한 수준인가
- [ ] 품질 문서가 솔직한 현재 상태를 반영하는가
- [ ] 현재 상태와 목표 상태가 구분되는가 (Current/Target/Planned)
- [ ] 중복 설명 대신 링크가 사용되는가
- [ ] 문서만 읽어도 다음 작업이 가능할 정도로 구조가 명확한가
- [ ] 에이전트가 접근할 수 없는 정보(채팅, 외부 문서)가 문서로 옮겨졌는가
- [ ] 모든 문서 간 크로스링크가 유효한가

---

## 14. 이 스킬을 사용할 때의 출력 기대값

이 스킬이 성공적으로 사용되면 결과물은 다음과 같아야 한다.

- `AGENTS.md`는 짧고(~100줄) 정확하다.
- `docs/`는 구조화되어 있다.
- 문서들은 **링크로 연결**되어 있다.
- 세부 지식은 `docs/`에 있고 진입 안내는 `AGENTS.md`에 있다.
- 복잡한 작업은 **실행 계획 문서**로 관리된다.
- 현재 상태와 목표 상태가 명확히 구분된다.
- 다른 에이전트가 리포지토리 내부 문서만으로 일할 수 있다.

이것이 Harness 방식 문서화의 완료 기준이다.
