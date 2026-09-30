---
name: skill-creator
description: "새로운 스킬 생성, 기존 스킬 수정/개선, 스킬 성능 측정 및 최적화. 스킬을 처음부터 만들거나, 기존 스킬을 편집/최적화하거나, eval을 실행하여 스킬을 테스트하거나, 분산 분석으로 스킬 성능을 벤치마킹하거나, 더 나은 트리거 정확도를 위해 스킬 설명을 최적화할 때 사용."
metadata:
  entry: "commands/create.md"
---

# 스킬 생성기

이 스킬의 본문은 [commands/create.md](commands/create.md) 이다.

1. **먼저 그 파일을 끝까지 읽고 지침을 그대로 따른다.**
2. 그 파일의 `references/`·`scripts/` 같은 상대 경로는 이 스킬 폴더(이 SKILL.md 가 있는 폴더) 기준이다.
3. 그 파일에 `$ARGUMENTS` 가 나오면 사용자의 요청으로 읽는다.

이 SKILL.md 는 표준 Agent Skills 입구다. Codex·Gemini CLI·GitHub Copilot CLI 처럼 `SKILL.md` 를 읽는 에이전트 도구가 이 파일로 스킬을 찾는다.
Claude Code 플러그인은 이 파일을 쓰지 않고(`plugin.json` 의 `"skills": []`) 같은 본문을 `/skill-creator:create` 으로 부른다.
