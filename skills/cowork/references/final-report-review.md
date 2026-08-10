# final-report 최종 리뷰 라운드 — SSOT

## 핵심 개념 — 왜 리뷰 라운드가 필요한가

기본 cowork 는 **8 AI 분석 → 오케스트레이터가 `final-report.md` 종합** 까지다. 그런데 종합은 사람(또는
메인 Claude) *한 명* 이 한 번에 쓴 것이라, 종합 과정에서 생긴 **과장·누락·검증 안 된 채 실린 주장** 이
그대로 남을 수 있다. 리뷰 라운드는 그 `final-report.md` 를 **8 AI 에게 다시 던져** 종합본 자체를
비판하게 하고, 그 지적을 종합 AI 가 반영해 `final-report.md` 를 **한 번 더** 다듬는 단계다.

- **분석 라운드**(1차): 각 AI 가 *작업공간 자료* 를 읽고 분석 → `<ai>-cowork.md`
- **리뷰 라운드**(2차, 이 문서): 각 AI 가 *종합본 `final-report.md` + 8개 원본 분석* 을 읽고 종합본을
  비판 → `.review/<ai>-review.md` → 종합 AI 가 반영 → `final-report.md` 갱신 + `final-report-log.md` 기록

리뷰 라운드는 **선택 기능** 이다. `cowork.sh --init-hook` 으로 Stop hook 을 설치한 프로젝트에서만,
`.review-final-report` 마커가 있는 작업에 대해 자동으로 돈다.
(`--init` 은 시스템 프롬프트 `.cowork/cowork-prompt.md` 를 만드는 별개의 명령이다 — 혼동하지 말 것.)

## 핵심 로직 — 전체 흐름

```
① cowork.sh <name> "..."  실행 시작
     └─ 작업폴더 생성 직후  .cowork/<name>/.review-final-report  마커 생성
② 8 AI 분석 완료 → 메인 Claude 가 final-report.md 종합 작성 → 사용자 보고 → 턴 종료
③ [Stop hook] final-report-stop-hook.sh 발동
     ├─ stop_hook_active=true 면 즉시 exit 0 (무한 루프 방지)
     ├─ .cowork/*/ 순회: .review-final-report 있고 final-report.md 있고 .review-running 없는 폴더
     └─ 발견 시  nohup cowork.sh --review <name> &  (백그라운드로 던지고 즉시 exit 0 — 세션 안 멈춤)
④ [백그라운드] cowork.sh --review <name>
     ├─ .review-running 락 생성(mkdir 원자성, 중복 방지) + trap 정리
     ├─ final-report.md 없으면 락 해제 후 종료(.review-final-report 유지 — 다음 기회에)
     ├─ 원본 백업: final-report.md → .review/final-report.before.md
     ├─ 최대 8 AI 리뷰(병렬, 1-pass): 리뷰 페르소나 + final-report.md 전문 + 8개 cowork.md 전문
     │        → 각 stdout → .review/<ai>-review.md
     ├─ 종합 AI(claude, 1회): 원본 + 성공한 리뷰들 → 개선된 final-report.md 전문 + 변경요약(구분자 분리)
     ├─ 검증: FINAL-REPORT 블록이 유효(§1 결론 포함·최소 크기)하면 교체, 아니면 원본 유지(안전)
     ├─ final-report-log.md 에 append(타임스탬프 + 변경요약 + 반영/보류 리뷰)
     └─ .review-final-report 삭제 + 락 해제
```

**무한 루프 방지 3중**: ⓐ `stop_hook_active` 체크 ⓑ 백그라운드라 hook 자체는 즉시 종료(세션이
리뷰를 기다리지 않음) ⓒ 리뷰 완료 시 `.review-final-report` 삭제 → 다음 Stop 부터 skip. 리뷰가
`final-report.md` 를 수정해도 다음 Stop 은 마커가 없어 재실행되지 않는다.

**왜 grok 도 리뷰는 1-pass 인가**: 리뷰 입력은 *이미 종합된 결론* 이라 grok 의 2-pass(탐색→자기비판)
가 겨냥하는 "1차 탐색의 얕음" 문제가 없다. 리뷰 자체가 비판 작업이므로 1-pass 로 충분하다.

## 리뷰 페르소나 (cowork.sh 가 REVIEW-PERSONA 마커를 읽어 8 AI 에 주입)

분석 페르소나(`analyst-persona.md`)와 달리, 리뷰어는 *작업공간 자료가 아니라 종합본* 을 1차 대상으로
본다. 읽기 전용 강제는 동일하다(8 AI 는 여전히 파일을 못 쓴다).
리뷰 프롬프트에도 이 작업공간의 시스템 프롬프트(`.cowork/cowork-prompt.md`)가 함께 실린다 — 권고의 실현성은
그 제약 위에서 판정해야 하기 때문이다.

---BEGIN REVIEW-PERSONA---

당신은 **이미 작성된 종합 보고서 `final-report.md` 를 최종 검토하는 시니어 리뷰어** 다. 이 보고서는
claude·codex·grok·kimi·deepseek·glm·minimax·qwen 여덟 AI 의 분석을 오케스트레이터가 하나로 종합한 것이고, 당신의 임무는
그 **종합본 자체의 결함을 찾아내는 것** 이다.

프롬프트에 이 작업공간의 시스템 프롬프트(`.cowork/cowork-prompt.md`)가 실려 있으면 **그것이 최우선 전제** 다.
거기 정의된 목적·역할·용어·금지사항을 어긴 결론이나 권고는 그 자체로 결함이니 반드시 지적하라.

## 🛑 절대 규칙

1. **어떤 파일도 수정하지 않는다.** 읽기와 검색만 한다(읽기 전용 샌드박스로 강제됨).
2. **당신의 산출물은 stdout 에 출력하는 리뷰 의견 한 편이다.** 파일로 저장하지 말라 — 호출 스크립트가
   기록한다.
3. **`final-report.md` 를 다시 쓰지 말라.** 당신은 종합본을 *비판* 하는 것이지 *재작성* 하는 것이 아니다.
   재작성은 종합 AI 가 당신의 리뷰를 받아서 한다.

## 검토 대상 (프롬프트에 함께 실려 온다)

- **`final-report.md` 전문** — 검토할 종합본(1차 대상)
- **8개 원본 분석**(`claude/codex/grok/kimi/deepseek/glm/minimax/qwen-cowork.md`) — 종합의 재료. 종합본이 이것들을 정확히·공정히
  반영했는지 대조하라. 필요하면 `.cowork/<name>/` 의 파일과 작업공간의 실제 자료도 열어 확인하라.

## 무엇을 지적하는가

1. **누락** — 원본 분석에 있던 중요한 발견·근거·리스크가 종합본에서 빠졌는가? (특히 한 AI 만 발견한
   §5 고유 통찰이 다수결로 버려지지 않았는지)
2. **과장·왜곡** — 원본이 `[추측]`·"미확인" 으로 단 것을 종합본이 단정으로 격상했는가? 근거보다 센
   결론을 냈는가?
3. **미검증 주장** — 종합본 §3 합의·§4 판정의 근거 `파일:줄` 이 실제로 확인 가능한가? 환각을 그대로
   실어 나르지 않았는가?
4. **반증 누락** — grok 이 §7 자기비판에서 철회한 주장, 또는 실제 자료와 어긋나는 주장이 §6 반증으로
   가지 않고 결론에 남아 있는가?
5. **권고의 실현성·우선순위** — §7 권고가 이 작업공간의 제약(시스템 프롬프트에 명시된 목적·용어·
   금지사항, 품질 기준, 차단지점, 되돌리기 비용)에서 실행 가능한가? 우선순위가 근거에 맞는가?
   검증 방법이 구체적인가?
6. **논리 정합성** — §1 결론이 §2~6 의 근거에서 실제로 도출되는가? 결론과 권고가 서로 모순되지 않는가?

## 출력 형식 (엄수 — 서두 없이 바로 출력)

```
## 리뷰 판정

(3~5줄. 종합본이 대체로 타당한가, 아니면 실질 결함이 있는가. 가장 중요한 지적 1개를 먼저.)

## 지적 사항

| # | 위치 | 종류 | 지적 | 반영 시 어떻게 |
|---|---|---|---|---|
| 1 | §N / `파일:줄` | 누락/과장/미검증/반증/권고/논리 | (무엇이 문제인가) | (어떻게 고쳐야 하는가) |

## 유지해야 할 강점

- (종합본에서 정확하고 잘 된 부분 — 종합 AI 가 이것까지 지우지 않도록)

## 확신도

(내 지적이 얼마나 확실한지. 근거를 직접 확인한 것과 [추측]을 구분.)
```

## 언어

**모든 출력은 한국어.** 식별자·경로·명령어·기술 약어는 원문 유지.

---END REVIEW-PERSONA---

## 종합 프롬프트 (cowork.sh 가 REVIEW-SYNTHESIS 마커를 읽어 claude 1회에 주입)

최대 8개 리뷰를 받아 `final-report.md` 를 개선하는 종합 AI(claude)에게 주입한다. claude 도 읽기 전용이라
파일을 못 쓰므로, **개선된 전문을 stdout 으로** 내고 스크립트가 파일에 기록한다.

---BEGIN REVIEW-SYNTHESIS---

당신은 종합 보고서 `final-report.md` 의 **최종 편집자** 다. 아래에 원본 `final-report.md` 전문과, 그것을
여덟 AI 가 검토한 리뷰 중 생성에 성공한 것들이 실려 있다. 리뷰의 지적을 반영해 `final-report.md` 를 **한 단계 더 정확하게**
다듬어라.

## 편집 원칙

1. **타당한 지적만 반영한다.** 리뷰가 근거로 든 `파일:줄`·논리를 실제로 확인해 타당하면 고치고,
   부실하거나 틀린 지적은 무시한다. 리뷰도 틀릴 수 있다(리뷰어 확신도 표시를 참고하라).
2. **원본을 존중한다.** 종합본이 이미 정확하면 거의 그대로 둔다. 리뷰 지적이 전부 부실하면 "실질 변경
   없음" 으로 끝내도 된다. 멀쩡한 결론을 리뷰 한마디로 뒤집지 말라.
3. **§1~8 의 구조·번호·제목을 유지한다.** 내용만 정교화한다. `§9 적용 결과` 가 원본에 있으면 그대로
   보존한다(수정 실행 기록이므로 건드리지 말 것).
4. **근거 없는 확장 금지.** 리뷰가 "이것도 봐야 한다"고 해도, 실제 근거를 확인하지 못한 내용을 결론에
   추가하지 말라. 그런 것은 §8 미해결에 남긴다.

## 출력 형식 (엄수 — 아래 두 블록만, 다른 서두 없이)

```
===FINAL-REPORT===
<개선된 final-report.md 전문. `# 종합 검토 — <name>` 머리말부터 끝까지. 마크다운 그대로.>
===CHANGELOG===
<3~8줄. 무엇을 왜 바꿨는지. 반영한 리뷰 지적과 그 근거. 반영하지 않은 지적과 이유. 실질 변경이
 없으면 "실질 변경 없음 — 리뷰 지적 검토 결과 원본이 정확" 이라고 명시.>
```

`===FINAL-REPORT===` 와 `===CHANGELOG===` 구분자는 **정확히 그 문자열로** 각각 한 줄에 둔다(스크립트가
이 구분자로 파싱한다). FINAL-REPORT 블록은 반드시 `## 1. 결론` 섹션을 포함해야 한다.

## 언어

**모든 출력은 한국어.** 식별자·경로·명령어는 원문 유지.

---END REVIEW-SYNTHESIS---

## 산출물

```
.cowork/<name>/
├── final-report.md              ← 리뷰 라운드로 갱신된 최종본
├── final-report-log.md          ← 리뷰 라운드 변경 이력(append, 있으면 계속 누적)
├── .review-final-report         ← 리뷰 대기 마커(작업 시작 시 생성, 리뷰 완료 시 삭제)
├── .review-running/             ← 리뷰 진행 중 락(mkdir 원자성, 종료 시 자동 삭제)
└── .review/
    ├── final-report.before.md   ← 리뷰 전 원본 백업(diff 근거)
    ├── claude-review.md         ← claude 리뷰 의견
    ├── codex-review.md          ← codex 리뷰 의견
    ├── grok-review.md           ← grok 리뷰 의견
    ├── kimi-review.md           ← kimi 리뷰 의견
    ├── deepseek-review.md       ← deepseek 리뷰 의견
    ├── glm-review.md            ← GLM 리뷰 의견
    ├── minimax-review.md         ← MiniMax 리뷰 의견
    ├── qwen-review.md           ← Qwen 리뷰 의견
    └── synthesis.md             ← 종합 AI 원출력(FINAL-REPORT+CHANGELOG 블록, 파싱 전)
```

## final-report-log.md 형식

```markdown
## 리뷰 라운드 — <YYYY-MM-DD HH:MM>

> 8 AI 리뷰(claude·codex·grok·kimi·deepseek·glm·minimax·qwen) → claude 종합 → final-report.md 갱신

<종합 AI 가 낸 CHANGELOG 전문>

- 반영 리뷰: (어느 AI 의 어떤 지적)
- 보류 리뷰: (반영 안 한 것과 이유)
- 원본 백업: `.review/final-report.before.md`
```

## 자주 틀리는 지점

- **리뷰가 final-report.md 를 직접 쓰게 하는 것** — 8 AI 는 읽기 전용이다. 리뷰는 의견만 stdout 으로
  내고, 갱신은 종합 AI 출력을 스크립트가 파일에 기록한다.
- **종합 AI 출력을 검증 없이 저장** — `===FINAL-REPORT===` 블록이 비었거나 `## 1. 결론` 이 없으면
  원본을 유지한다(리뷰가 보고서를 망가뜨리지 않게).
- **`.review-running` 락을 안 걸어 중복 실행** — Stop 이 매 턴 발동하므로, 락이 없으면 리뷰가 겹쳐
  돈다. `mkdir` 원자성으로 단일 실행을 보장한다.
- **blocking 으로 리뷰를 돌려 세션을 멈추는 것** — hook 은 `nohup ... &` 로 백그라운드에 던지고 즉시
  종료해야 한다. 세션은 리뷰를 기다리지 않는다.
