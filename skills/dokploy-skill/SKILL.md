---
name: dokploy-skill
description: "Dokploy 셀프호스팅 PaaS 전체 관리. SSH/API 서버 관리, 앱 배포, Docker Compose/Swarm, DB(PostgreSQL/MySQL/MongoDB/Redis), Traefik, SSL, 도메인, 볼륨 백업, 모니터링, 디버깅 지원. 'Dokploy' 언급, 배포/재배포, Docker Compose, 도메인/SSL/HTTPS, Traefik/502에러, DB관리, 볼륨백업/S3, 컨테이너로그, 서버유지보수, 빌드타입선택, 와일드카드서브도메인라우팅, pgAdmin4 작업 시 사용."
metadata:
  entry: "commands/manage.md"
---

# Dokploy 서버 관리 스킬

이 스킬의 본문은 [commands/manage.md](commands/manage.md) 이다.

1. **먼저 그 파일을 끝까지 읽고 지침을 그대로 따른다.**
2. 그 파일의 `references/`·`scripts/` 같은 상대 경로는 이 스킬 폴더(이 SKILL.md 가 있는 폴더) 기준이다.
3. 그 파일에 `$ARGUMENTS` 가 나오면 사용자의 요청으로 읽는다.

이 SKILL.md 는 표준 Agent Skills 입구다. Codex·Gemini CLI·GitHub Copilot CLI 처럼 `SKILL.md` 를 읽는 에이전트 도구가 이 파일로 스킬을 찾는다.
Claude Code 플러그인은 이 파일을 쓰지 않고(`plugin.json` 의 `"skills": []`) 같은 본문을 `/dokploy-skills:manage` 으로 부른다.
