---
name: currency-skill
description: "Frankfurter API를 사용한 환율 정보 조회 및 통화 변환. 무료 오픈소스 환율 API로 유럽중앙은행(ECB) 데이터 기반. API 키 불필요, 사용량 제한 없음. 사용 시점: (1) 최신/과거 환율 조회 (2) 통화 변환 계산 (3) 기간별 환율 시계열 데이터 분석 (4) 지원 통화 목록 확인 (5) Flutter/웹 앱에서 환율 기능 구현 (6) 자동화/AI 도구에서 환율 데이터 활용. 키워드: 환율, exchange rate, 통화 변환, currency conversion, ECB, 유럽중앙은행, USD, KRW, EUR, 시계열 데이터, API"
metadata:
  entry: "commands/exchange.md"
---

# Frankfurter Currency Exchange API

이 스킬의 본문은 [commands/exchange.md](commands/exchange.md) 이다.

1. **먼저 그 파일을 끝까지 읽고 지침을 그대로 따른다.**
2. 그 파일의 `references/`·`scripts/` 같은 상대 경로는 이 스킬 폴더(이 SKILL.md 가 있는 폴더) 기준이다.
3. 그 파일에 `$ARGUMENTS` 가 나오면 사용자의 요청으로 읽는다.

이 SKILL.md 는 표준 Agent Skills 입구다. Codex·Gemini CLI·GitHub Copilot CLI 처럼 `SKILL.md` 를 읽는 에이전트 도구가 이 파일로 스킬을 찾는다.
Claude Code 플러그인은 이 파일을 쓰지 않고(`plugin.json` 의 `"skills": []`) 같은 본문을 `/currency-skill:exchange` 으로 부른다.
