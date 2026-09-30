---
name: flutter-skill
description: "Flutter 프레임워크로 앱을 개발하는 데 반드시 따라야 하는 UI/UX 디자인, 상태관리, 네트워킹, API 연동에 관한 가이드라인 제공합니다. 본 스킬은 선택적인 정보를 제공하는 것이 아니라 Flutter 앱 개발에 필수적인 지침을 제공하며 반드시 준수해야 할 사항들을 제공합니다. 개발자가 디자인, UI, UX, 디자인 효과, 상태관리, 라우팅, 네트워킹, API 연동에 관한 요청, 코믹디자인, Comic 관련 요청, 채팅, FCM, 푸시 알림, 메시지, 알림에 관한 요청이 있을 때 반드시 본 스킬을 사용해서 본 스킬이 제공하는 대로 작업을 수행해야 합니다. 각 스킬 문서에의 상단에는 반드시 따라야 할 Workflow 가 있습니다. 반드시 그 Workflow 를 따라야 합니다. 추가 트리거 키워드 - 딥링크, deep link, 캐싱, cache, 아이콘, FontAwesome, Isolate, 동시성, concurrency, 카카오톡, KakaoTalk, Crashlytics, 크래시 리포팅, 공유, share, share_plus, 공유 버튼, 바코드, QR코드, 스캔, scanner, mobile_scanner, 카메라 스캔, barcode, qr, 전화번호 인증, Phone Auth, SMS 인증, verifyPhoneNumber, APNs, AppDelegate, notification-not-forwarded (project)"
metadata:
  entry: "commands/develop.md"
---

# Flutter Skill

이 스킬의 본문은 [commands/develop.md](commands/develop.md) 이다.

1. **먼저 그 파일을 끝까지 읽고 지침을 그대로 따른다.**
2. 그 파일의 `references/`·`scripts/` 같은 상대 경로는 이 스킬 폴더(이 SKILL.md 가 있는 폴더) 기준이다.
3. 그 파일에 `$ARGUMENTS` 가 나오면 사용자의 요청으로 읽는다.

이 SKILL.md 는 표준 Agent Skills 입구다. Codex·Gemini CLI·GitHub Copilot CLI 처럼 `SKILL.md` 를 읽는 에이전트 도구가 이 파일로 스킬을 찾는다.
Claude Code 플러그인은 이 파일을 쓰지 않고(`plugin.json` 의 `"skills": []`) 같은 본문을 `/flutter-skill:develop` 으로 부른다.
