---
name: open-meteo-skill
description: "전세계 날씨 데이터를 제공하는 무료 오픈소스 Open-Meteo API 통합. 16일 예보, 80년 역사 데이터, 대기질, 해양 날씨, 위치 검색, 고도 조회를 지원하며, Flutter 앱에서 시간대별 날씨 표시와 캐시 기반 실시간 아이콘 표시 기능을 구현하는 가이드를 포함합니다. Claude가 다음 작업을 수행해야 할 때 사용: (1) Open-Meteo API로 날씨/대기질/해양 데이터 조회, (2) Flutter 앱에 날씨 기능 구현 (WeatherService, 이중 캐시, FutureBuilder 패턴, WMO 코드 매핑), (3) Geocoding API로 도시명→좌표 변환, (4) 과거 날씨 데이터 분석, (5) MCP 서버를 통한 Claude Desktop 날씨 통합."
metadata:
  entry: "commands/weather.md"
---

# Open-Meteo API 스킬

이 스킬의 본문은 [commands/weather.md](commands/weather.md) 이다.

1. **먼저 그 파일을 끝까지 읽고 지침을 그대로 따른다.**
2. 그 파일의 `references/`·`scripts/` 같은 상대 경로는 이 스킬 폴더(이 SKILL.md 가 있는 폴더) 기준이다.
3. 그 파일에 `$ARGUMENTS` 가 나오면 사용자의 요청으로 읽는다.

이 SKILL.md 는 표준 Agent Skills 입구다. Codex·Gemini CLI·GitHub Copilot CLI 처럼 `SKILL.md` 를 읽는 에이전트 도구가 이 파일로 스킬을 찾는다.
Claude Code 플러그인은 이 파일을 쓰지 않고(`plugin.json` 의 `"skills": []`) 같은 본문을 `/open-meteo-skill:weather` 으로 부른다.
