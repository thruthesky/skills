# 평가 상세 프로세스

이 문서는 스킬 테스트 실행, 채점, 벤치마크의 상세 프로세스를 설명합니다.

## 목차

1. [테스트 케이스 작성](#테스트-케이스-작성)
2. [테스트 실행](#테스트-실행)
3. [채점 및 벤치마크](#채점-및-벤치마크)
4. [Eval Viewer 사용](#eval-viewer-사용)
5. [피드백 처리](#피드백-처리)
6. [블라인드 비교](#블라인드-비교)
7. [설명 최적화 상세](#설명-최적화-상세)
8. [환경별 지침](#환경별-지침)

---

## 테스트 케이스 작성

스킬 초안 작성 후, 2-3개의 현실적인 테스트 프롬프트를 작성합니다. 실제 사용자가 말할 법한 내용이어야 합니다.

`evals/evals.json`에 저장합니다. 처음에는 assertions 없이 프롬프트만 작성하고, 실행 중에 assertions를 추가합니다.

```json
{
  "skill_name": "example-skill",
  "evals": [
    {
      "id": 1,
      "prompt": "User's task prompt",
      "expected_output": "Description of expected result",
      "files": []
    }
  ]
}
```

전체 스키마는 [schemas.md](schemas.md) 참조.

---

## 테스트 실행

결과를 `<skill-name>-workspace/` 디렉토리에 저장합니다. 반복별로 `iteration-1/`, `iteration-2/` 등으로 구성합니다.

### 병렬 실행 (with-skill + baseline)

각 테스트 케이스에 대해 **같은 턴에** 두 개의 서브에이전트를 실행합니다:

**With-skill 실행:**
```
- Skill path: <path-to-skill>
- Task: <eval prompt>
- Input files: <eval files if any>
- Save outputs to: <workspace>/iteration-N/eval-ID/with_skill/outputs/
```

**Baseline 실행:**
- 새 스킬 생성 시: 스킬 없이 같은 프롬프트 실행 → `without_skill/outputs/`에 저장
- 기존 스킬 개선 시: 이전 버전 스킬 사용 → `old_skill/outputs/`에 저장

각 eval 디렉토리에 `eval_metadata.json`을 작성합니다:

```json
{
  "eval_id": 0,
  "eval_name": "descriptive-name-here",
  "prompt": "The user's task prompt",
  "assertions": []
}
```

### 실행 중 assertions 작성

실행을 기다리는 동안 정량적 assertions를 작성합니다. 좋은 assertions는:
- 객관적으로 검증 가능
- 설명적인 이름을 가짐 (벤치마크 뷰어에서 명확히 읽힘)
- 주관적 스킬(문체, 디자인)에는 강제하지 않음

### 타이밍 데이터 캡처

서브에이전트 완료 시 알림에 포함된 `total_tokens`와 `duration_ms`를 즉시 `timing.json`으로 저장합니다. 이 데이터는 알림에서만 얻을 수 있으며 다른 곳에 저장되지 않습니다.

---

## 채점 및 벤치마크

### 채점

각 실행에 대해 채점 에이전트([agents/grader.md](../agents/grader.md))를 실행합니다. 프로그래밍 방식으로 검증 가능한 assertions는 스크립트로 처리하세요.

결과를 각 실행 디렉토리의 `grading.json`에 저장합니다.

### 벤치마크 집계

```bash
python -m scripts.aggregate_benchmark <workspace>/iteration-N --skill-name <name>
```

`benchmark.json`과 `benchmark.md`를 생성하며, 각 구성별 pass_rate, time, tokens의 mean ± stddev와 delta를 포함합니다. with_skill을 baseline보다 앞에 배치합니다.

### 분석

[agents/analyzer.md](../agents/analyzer.md)의 "Analyzing Benchmark Results" 섹션을 참고하여 패턴 분석:
- 양쪽 모두 항상 통과하는 assertions (차별화 불가)
- 높은 분산의 evals (불안정할 수 있음)
- 시간/토큰 트레이드오프

---

## Eval Viewer 사용

모든 테스트 실행 후 반드시 eval viewer를 생성합니다:

```bash
nohup python <skill-creator-path>/eval-viewer/generate_review.py \
  <workspace>/iteration-N \
  --skill-name "my-skill" \
  --benchmark <workspace>/iteration-N/benchmark.json \
  > /dev/null 2>&1 &
VIEWER_PID=$!
```

반복 2회차부터는 `--previous-workspace <workspace>/iteration-<N-1>`을 추가합니다.

**헤드리스 환경:** `--static <output_path>`로 독립 실행형 HTML 파일을 생성합니다.

### Viewer 구성

**Outputs 탭:** 테스트 케이스별로 프롬프트, 출력, 이전 출력(2회차+), 채점 결과, 피드백 입력란 표시.

**Benchmark 탭:** pass rates, timing, token usage의 통계 요약, per-eval 분석.

화살표 키 또는 prev/next 버튼으로 탐색. "Submit All Reviews" 클릭 시 `feedback.json` 저장.

---

## 피드백 처리

사용자가 리뷰 완료 시 `feedback.json`을 읽습니다:

```json
{
  "reviews": [
    {"run_id": "eval-0-with_skill", "feedback": "차트에 축 라벨이 없음", "timestamp": "..."},
    {"run_id": "eval-1-with_skill", "feedback": "", "timestamp": "..."}
  ],
  "status": "complete"
}
```

빈 피드백은 사용자가 괜찮다고 판단한 것입니다. 구체적 불만이 있는 테스트 케이스에 개선을 집중합니다.

완료 후 viewer 서버를 종료합니다: `kill $VIEWER_PID 2>/dev/null`

---

## 블라인드 비교

두 버전의 스킬을 더 엄격하게 비교하려면 블라인드 비교 시스템을 사용합니다:

1. 두 출력을 독립 에이전트에게 A/B로 제시 (어느 것이 어느 스킬인지 모름)
2. [agents/comparator.md](../agents/comparator.md)로 품질 판정
3. [agents/analyzer.md](../agents/analyzer.md)로 승리 이유 분석

이것은 선택 사항이며 대부분의 경우 인간 리뷰 루프로 충분합니다.

---

## 설명 최적화 상세

### 트리거 평가 쿼리 작성 가이드

20개의 평가 쿼리를 작성합니다 (should-trigger 8-10개, should-not-trigger 8-10개).

**쿼리 품질 기준:**
- 현실적이고 구체적 (파일 경로, 개인 컨텍스트, 회사 이름, URL 포함)
- 다양한 길이, 캐주얼/포멀 혼합, 약어/오타 포함
- 에지 케이스에 집중 (명확한 것보다 모호한 경우)

**나쁜 예:** `"Format this data"`, `"Extract text from PDF"`

**좋은 예:** `"ok so my boss just sent me this xlsx file (its in my downloads, called something like 'Q4 sales final FINAL v2.xlsx') and she wants me to add a column that shows the profit margin as a percentage. The revenue is in column C and costs are in column D i think"`

**should-not-trigger 쿼리:** 가장 유용한 것은 키워드가 겹치지만 실제로는 다른 작업이 필요한 "근접 실패" 사례입니다. 명백히 무관한 쿼리는 아무것도 테스트하지 않습니다.

### 최적화 루프

```bash
python -m scripts.run_loop \
  --eval-set <path-to-trigger-eval.json> \
  --skill-path <path-to-skill> \
  --model <model-id> \
  --max-iterations 5 \
  --verbose
```

60% train / 40% test로 분할, 각 쿼리 3회 실행하여 안정적인 trigger rate 측정. test score 기준으로 최적 description 선택 (과적합 방지).

---

## 환경별 지침

### Claude.ai

- 서브에이전트 없음: 테스트를 순차 실행, 베이스라인 생략
- 브라우저 없으면 eval viewer 생략 → 대화 내에서 직접 결과 제시
- 정량적 벤치마크 생략 (베이스라인 비교 불가)
- 설명 최적화 생략 (`claude -p` CLI 필요)
- 패키징은 Python + 파일시스템만 있으면 가능

### Cowork

- 서브에이전트 사용 가능: 전체 워크플로우 작동
- 브라우저/디스플레이 없음: `--static <output_path>`로 HTML 파일 생성
- "Submit All Reviews" 시 `feedback.json`이 다운로드 파일로 제공됨
- 설명 최적화는 `claude -p` 사용하므로 정상 작동

### 기존 스킬 업데이트 시

- 원래 이름 유지 (디렉토리명, frontmatter `name` 필드)
- 읽기 전용 경로일 수 있으므로 `/tmp/skill-name/`에 복사 후 편집
- 패키징 시 `/tmp/`에 스테이징 후 출력 디렉토리로 복사
