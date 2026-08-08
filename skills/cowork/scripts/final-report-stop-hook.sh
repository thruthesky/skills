#!/usr/bin/env bash
# final-report-stop-hook.sh — Claude Code 의 Stop hook.
#
#   설치: bash .claude/skills/cowork/scripts/cowork.sh --init-hook  (settings.json 에 멱등 등록)
#         ⚠️ --init 은 시스템 프롬프트 .cowork/cowork-prompt.md 를 만드는 별개 명령이다(혼동 주의).
#   역할: cowork 분석이 끝나 final-report.md 가 만들어진 작업을 찾아, 그 final-report.md 를 5 AI 로
#         한 번 더 재검토(리뷰 라운드)하도록 백그라운드에 던진다.
#
# 설계 요지
#   - Stop hook 은 blocking 이다(세션이 hook 종료를 기다린다). 그런데 리뷰 라운드는 5 AI + 종합으로
#     15분 안팎 걸리므로, 여기서 동기 실행하면 세션이 그만큼 멈춘다. 그래서 리뷰를 nohup 백그라운드로
#     던지고 hook 은 즉시 종료한다(세션 무정지). 리뷰는 독립적으로 돌며 final-report.md 를 갱신한다.
#   - 대상 판별은 파일 존재로만 한다(마커 .review-final-report + final-report.md 유무). 마커는
#     cowork.sh 가 작업 시작 시 만들고, 리뷰 완료 시 do_review 가 지운다 → 같은 작업이 두 번 리뷰되지
#     않는다.
#   - 무한 루프 방지 3중: ① stop_hook_active 이면 즉시 종료 ② 백그라운드라 hook 은 decision block 을
#     하지 않음(세션이 재트리거되지 않음) ③ 리뷰 완료 시 마커 삭제로 다음 Stop 부터 skip.
set -uo pipefail

# --- stdin 페이로드에서 stop_hook_active 확인(있으면 즉시 종료) --------------
payload=""
[ -t 0 ] || payload="$(cat 2> /dev/null || true)"
if [ -n "$payload" ] && command -v jq > /dev/null 2>&1; then
  active="$(printf '%s' "$payload" | jq -r '.stop_hook_active // false' 2> /dev/null || echo false)"
  [ "$active" = "true" ] && exit 0
fi

# --- 프로젝트 루트: Claude Code 가 CLAUDE_PROJECT_DIR 를 준다(없으면 cwd) ----
root="${CLAUDE_PROJECT_DIR:-$PWD}"
cowork_root="$root/.cowork"
runner="$root/.claude/skills/cowork/scripts/cowork.sh"
[ -d "$cowork_root" ] || exit 0
[ -f "$runner" ] || exit 0

# --- 리뷰 대기 작업을 백그라운드로 던진다 -----------------------------------
# 산출물 파일 존재로만 판정한다(상태 파일을 따로 두지 않는다).
for marker in "$cowork_root"/*/.review-final-report; do
  [ -f "$marker" ] || continue                 # glob 매치 없음(리터럴)도 걸러진다
  dir="$(dirname "$marker")"
  slug="$(basename "$dir")"
  [ -f "$dir/final-report.md" ] || continue     # 아직 종합 전 — 다음 Stop 에서 재시도
  [ -d "$dir/.review-running" ] && continue      # 이미 리뷰 진행 중(락) — 중복 실행 방지
  # nohup 으로 부모(hook) 종료 후에도 살아남게 한다. 세션은 이 리뷰를 기다리지 않는다.
  nohup bash "$runner" --review "$slug" > "$dir/.review-hook.log" 2>&1 &
  disown 2> /dev/null || true
done

exit 0
