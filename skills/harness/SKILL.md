---
name: harness
description: "리포지토리 안에 Harness 방식의 문서 세트를 만들거나 갱신한다. AGENTS.md와 docs/를 짧은 진입점과 구조화된 시스템 오브 레코드로 정리해야 할 때 사용한다. 짧은 AGENTS.md, docs/ 중심의 지식 구조, progressive disclosure, 아키텍처 문서, 제품 명세, 실행 계획, 품질 문서를 만드는 작업에 사용한다. 제품 구현이 아니라 문서 구조 설계와 문서 작성 자체에만 사용한다."
metadata:
  entry: "commands/generate.md"
---

# Harness 문서 생성 스킬

이 스킬의 본문은 [commands/generate.md](commands/generate.md) 이다.

1. **먼저 그 파일을 끝까지 읽고 지침을 그대로 따른다.**
2. 그 파일의 `references/`·`scripts/` 같은 상대 경로는 이 스킬 폴더(이 SKILL.md 가 있는 폴더) 기준이다.
3. 그 파일에 `$ARGUMENTS` 가 나오면 사용자의 요청으로 읽는다.

이 SKILL.md 는 표준 Agent Skills 입구다. Codex·Gemini CLI·GitHub Copilot CLI 처럼 `SKILL.md` 를 읽는 에이전트 도구가 이 파일로 스킬을 찾는다.
Claude Code 플러그인은 이 파일을 쓰지 않고(`plugin.json` 의 `"skills": []`) 같은 본문을 `/harness-skill:generate` 으로 부른다.
