---
name: waf
description: "Cloudflare WAF로 보호된 사이트에 PHP PEST + ChromeDriver(Remote Debugging Port) 방식으로 접속하여 브라우저 자동화 작업을 수행하는 스킬. Cloudflare WAF, 브라우저 자동화, 웹 스크래핑, ChromeDriver, PHP PEST 관련 작업 시 사용."
metadata:
  entry: "commands/bypass.md"
---

# Cloudflare WAF 통과 브라우저 자동화 스킬

이 스킬의 본문은 [commands/bypass.md](commands/bypass.md) 이다.

1. **먼저 그 파일을 끝까지 읽고 지침을 그대로 따른다.**
2. 그 파일의 `references/`·`scripts/` 같은 상대 경로는 이 스킬 폴더(이 SKILL.md 가 있는 폴더) 기준이다.
3. 그 파일에 `$ARGUMENTS` 가 나오면 사용자의 요청으로 읽는다.

이 SKILL.md 는 표준 Agent Skills 입구다. Codex·Gemini CLI·GitHub Copilot CLI 처럼 `SKILL.md` 를 읽는 에이전트 도구가 이 파일로 스킬을 찾는다.
Claude Code 플러그인은 이 파일을 쓰지 않고(`plugin.json` 의 `"skills": []`) 같은 본문을 `/waf-skill:bypass` 으로 부른다.
