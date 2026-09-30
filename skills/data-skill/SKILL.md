---
name: data-skill
description: "대한민국 공공데이터포털(data.go.kr)에서 제공하는 각종 공공데이터 API 사용. 공공데이터 개발 또는 공공 API 개발을 할 때 사용. 키워드: 공공데이터, data.go.kr, 외교부, 공공API, 한국 정부 데이터, serviceKey"
metadata:
  entry: "commands/query.md"
---

# 대한민국 공공데이터포털 API 스킬

이 스킬의 본문은 [commands/query.md](commands/query.md) 이다.

1. **먼저 그 파일을 끝까지 읽고 지침을 그대로 따른다.**
2. 그 파일의 `references/`·`scripts/` 같은 상대 경로는 이 스킬 폴더(이 SKILL.md 가 있는 폴더) 기준이다.
3. 그 파일에 `$ARGUMENTS` 가 나오면 사용자의 요청으로 읽는다.

이 SKILL.md 는 표준 Agent Skills 입구다. Codex·Gemini CLI·GitHub Copilot CLI 처럼 `SKILL.md` 를 읽는 에이전트 도구가 이 파일로 스킬을 찾는다.
Claude Code 플러그인은 이 파일을 쓰지 않고(`plugin.json` 의 `"skills": []`) 같은 본문을 `/data-skill:query` 으로 부른다.
