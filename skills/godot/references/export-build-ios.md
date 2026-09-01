# iOS 빌드 — 테스트 빌드 · 설치 · 실행 · 릴리즈

Godot 은 iOS 에서 **`.ipa` 를 직접 완성하지 않는다.** 템플릿 개념은
[export-build.md](export-build.md) 를 먼저 볼 것.

## 목차

1. [핵심 구조 — 2단계 빌드](#1-핵심-구조--2단계-빌드)
2. [사전 준비](#2-사전-준비)
3. [preset 설정](#3-preset-설정)
4. [테스트 빌드 — Xcode 프로젝트 내보내기](#4-테스트-빌드--xcode-프로젝트-내보내기)
5. [시뮬레이터에서 실행](#5-시뮬레이터에서-실행)
6. [실기기 설치와 실행](#6-실기기-설치와-실행)
7. [로그 보기](#7-로그-보기)
8. [릴리즈 — TestFlight · App Store](#8-릴리즈--testflight--app-store)
9. [자주 막히는 지점](#9-자주-막히는-지점)

---

## 1. 핵심 구조 — 2단계 빌드

**Android 는 Godot 이 APK 까지 끝내지만, iOS 는 Godot 이 Xcode 프로젝트까지만 만든다.**
코드 서명·아카이브·배포 패키징은 Apple 도구가 맡는다.

```text
Godot 프로젝트 + ios.zip 템플릿
        ↓ godot --export-debug/release "iOS"
Xcode 프로젝트 (.xcodeproj 를 담은 폴더/zip)
        ↓ xcodebuild / Xcode.app
.app (시뮬레이터·실기기)  또는  .xcarchive → .ipa
        ↓ Transporter / xcrun altool
TestFlight · App Store
```

이 구조 때문에 **iOS 는 macOS 에서만 빌드할 수 있다.** Windows·Linux 에서는 불가능하다.

---

## 2. 사전 준비

| 항목 | 확인 |
|---|---|
| **`ios.zip` 템플릿** | `ls "$HOME/Library/Application Support/Godot/export_templates/4.7.2.stable/ios.zip"` |
| **Xcode** | `xcodebuild -version` (이 머신: **Xcode 26.6**) |
| **Command Line Tools** | `xcode-select -p` |
| **Apple Developer 계정** | 실기기 설치·배포에 필요. 시뮬레이터는 불필요 |
| **Team ID** | [developer.apple.com](https://developer.apple.com) → Membership |
| **프로비저닝 프로파일** | 실기기·배포용. Xcode 의 자동 관리 권장 |

첫 실행 시 라이선스 동의가 필요할 수 있다:

```bash
sudo xcodebuild -license accept
xcodebuild -runFirstLaunch
```

---

## 3. preset 설정

`Project > Export > Add > iOS` (🧑 사람이 에디터에서). 텍스트 형태는 참고용이다:

```ini
[preset.0]

name="iOS"
platform="iOS"
runnable=true
export_filter="all_resources"
exclude_filter="artifacts/*, builds/*"
export_path="builds/ios/Laryen3D.zip"

[preset.0.options]

architectures/arm64=true
application/app_store_team_id="ABCDE12XYZ"          ; 필수
application/bundle_identifier="com.회사명.laryen3d"  ; 필수, 스토어 등록 후 변경 불가
application/short_version="1.0.0"
application/version="1.0.0"
application/export_project_only=true                 ; 아래 표 참고
application/signature=""
application/icon_interpolation=4
```

### `export_project_only` 가 산출물을 가른다

| 값 | Godot 이 하는 일 | 언제 |
|---|---|---|
| `true` | **Xcode 프로젝트만** 만들고 멈춘다 | Xcode 로 열어 서명·빌드를 직접 조정할 때 |
| `false` | Godot 이 Xcode 를 호출해 **archive → `.ipa` 까지** 끝낸다 | **실기기 설치·에디터 Remote Deploy · CI** |

**실기기에서 실행하는 것이 목적이면 `false` 다.** `true` 로 두면 빌드도 설치도 일어나지
않으므로 Remote Deploy 아이콘도, `install.sh` 도 동작하지 않는다.

`false` 로 두고 헤드리스에서 `.ipa` 까지 나오는 것을 실측으로 확인했다(Godot 4.7.2 ·
Xcode 26.6). 필요한 값은 `app_store_team_id`(인증서 `OU` 값) 와
`code_sign_identity_debug="Apple Development"` 두 개이며, 프로비저닝 프로파일은
Xcode 자동 관리(`iOS Team Provisioning Profile: *`)로 통과한다.

```text
** ARCHIVE SUCCEEDED **
** EXPORT SUCCEEDED **
builds/ios/Laryen3D.ipa
```

### 아이콘

iOS 는 아이콘 누락이 **설정 오류로 export 자체를 막는다.** preset 의 `icons/*` 항목 또는
`project.godot` 의 `application/config/icon` 을 채운다.

---

## 4. 테스트 빌드 — Xcode 프로젝트 내보내기

필요한 템플릿은 **`ios.zip` 하나**다. `android_*`·`macos.zip`·`windows*.exe` 는 쓰이지 않는다.

```bash
PROJECT="/Users/thruthesky/apps/game/laryen3d"
mkdir -p "$PROJECT/builds/ios" "$PROJECT/artifacts/logs"

godot --headless --path "$PROJECT" --import --quit || true

godot --headless --path "$PROJECT" \
  --export-debug "iOS" builds/ios/Laryen3D.zip \
  --log-file artifacts/logs/build-ios-debug.log
echo "EXIT=$?"
```

압축을 풀면 Xcode 프로젝트가 나온다:

```bash
cd "$PROJECT/builds/ios"
unzip -o Laryen3D.zip -d Laryen3D-xcode
ls Laryen3D-xcode          # Laryen3D.xcodeproj, godot 라이브러리, 리소스
open Laryen3D-xcode/*.xcodeproj
```

### 실측 주의 — 오류 본문이 비어 나온다

설정이 불완전하면 헤드리스에서 이런 오류가 뜨는데 **본문이 비어 있다**(Godot 4.7.2 실측):

```text
ERROR: Cannot export project with preset "iOS" due to configuration errors:

   at: _fs_changed (editor/editor_node.cpp:1401)
ERROR: Project export for preset "iOS" failed.
```

무엇이 문제인지 알려주지 않으므로 **에디터에서 같은 preset 을 열어 경고를 확인한다.**
점검 순서: ① 아이콘 ② `app_store_team_id` ③ `bundle_identifier` ④ `ios.zip` 템플릿.

---

## 5. 시뮬레이터에서 실행

시뮬레이터는 **Apple Developer 계정 없이도** 된다. 로직·UI 확인에 가장 빠르다.

```bash
# 사용 가능한 시뮬레이터 목록
xcrun simctl list devices available

# Xcode 로 빌드 (시뮬레이터용)
cd "$PROJECT/builds/ios/Laryen3D-xcode"
xcodebuild -project Laryen3D.xcodeproj \
  -scheme Laryen3D \
  -sdk iphonesimulator \
  -configuration Debug \
  -derivedDataPath ./build

# 시뮬레이터 부팅 → 설치 → 실행
xcrun simctl boot "iPhone 16 Pro"
open -a Simulator
xcrun simctl install booted ./build/Build/Products/Debug-iphonesimulator/Laryen3D.app
xcrun simctl launch booted com.회사명.laryen3d
```

> ⚠️ **preset 의 `architectures/arm64` 는 실기기용이다.** Apple Silicon Mac 의 시뮬레이터도
> arm64 라 대개 동작하지만, 시뮬레이터에서만 나는 문제는 실기기에서 재현되지 않을 수 있다.
> 터치 입력·성능·GPU 드라이버 확인은 반드시 실기기로 한다.

---

## 6. 실기기 설치와 실행

### 가장 빠른 방법 — `install.sh`

`export_project_only=false` 로 두었다면 아래 한 줄이 빌드·설치·실행을 모두 끝낸다.
기기 ID 는 `devicectl` 의 UUID 와 하드웨어 UDID 둘 다 받는다.

```bash
.claude/skills/godot/scripts/install.sh                       # 연결된 기기 목록
.claude/skills/godot/scripts/install.sh 00008140-001C24C9…    # 빌드 → 설치 → 실행
.claude/skills/godot/scripts/install.sh <id> --console        # 로그를 터미널에 붙인다
.claude/skills/godot/scripts/install.sh <id> --skip-build     # 설치·실행만
```

상세는 [headless-workflow.md](headless-workflow.md) §3. 아래는 이 스크립트가 내부에서
하는 일을 손으로 하는 방법이다.

### 서명 설정 (Xcode 에서)

1. `Laryen3D.xcodeproj` 를 Xcode 로 연다
2. 타깃 선택 → `Signing & Capabilities`
3. **`Automatically manage signing`** 체크
4. `Team` 에 자기 팀 선택 → Xcode 가 프로파일을 자동 생성

### 설치

가장 단순한 방법은 Xcode 에서 기기를 고르고 ▶︎ 를 누르는 것이다. CLI 로는:

```bash
# 연결된 기기 확인 (Xcode 15+)
xcrun devicectl list devices

# 기기용 빌드
xcodebuild -project Laryen3D.xcodeproj -scheme Laryen3D \
  -sdk iphoneos -configuration Debug \
  -derivedDataPath ./build \
  DEVELOPMENT_TEAM=ABCDE12XYZ

# 설치
xcrun devicectl device install app \
  --device <DEVICE-UDID> \
  ./build/Build/Products/Debug-iphoneos/Laryen3D.app

# 실행
xcrun devicectl device process launch \
  --device <DEVICE-UDID> com.회사명.laryen3d
```

### 기기 신뢰 설정

무료 개발자 계정으로 설치하면 기기에서 한 번 승인해야 한다:
`설정 > 일반 > VPN 및 기기 관리 > 개발자 앱 > 신뢰`

무료 계정 프로파일은 **7일 후 만료**된다. 유료 계정은 1년이다.

---

## 7. 로그 보기

```bash
# 실시간 (Godot 로그만)
xcrun devicectl device console --device <UDID> | grep -i godot

# 시뮬레이터
xcrun simctl spawn booted log stream --predicate 'process == "Laryen3D"'
```

GUI 로는 **Console.app** 에서 왼쪽 기기를 선택하고 프로세스명으로 필터한다.
Xcode 로 실행 중이면 하단 디버그 콘솔에 `print()` 가 그대로 나온다.

원격 디버그(에디터 디버거 연결)는 preset 의 `Runnable` 을 켜고 에디터 원클릭 배포를 쓴다.

---

## 8. 릴리즈 — TestFlight · App Store

```bash
# 1) 릴리즈 모드로 Xcode 프로젝트 생성
godot --headless --path "$PROJECT" \
  --export-release "iOS" builds/ios/Laryen3D-release.zip \
  --log-file artifacts/logs/build-ios-release.log

# 2) 아카이브
cd builds/ios/Laryen3D-release-xcode
xcodebuild -project Laryen3D.xcodeproj -scheme Laryen3D \
  -sdk iphoneos -configuration Release \
  -archivePath ./Laryen3D.xcarchive archive

# 3) .ipa 내보내기 (ExportOptions.plist 필요)
xcodebuild -exportArchive \
  -archivePath ./Laryen3D.xcarchive \
  -exportOptionsPlist ExportOptions.plist \
  -exportPath ./ipa
```

`ExportOptions.plist` 예시:

```xml
<?xml version="1.0" encoding="UTF-8"?>
<!DOCTYPE plist PUBLIC "-//Apple//DTD PLIST 1.0//EN" "http://www.apple.com/DTDs/PropertyList-1.0.dtd">
<plist version="1.0">
<dict>
    <key>method</key>          <string>app-store-connect</string>
    <key>teamID</key>          <string>ABCDE12XYZ</string>
    <key>uploadSymbols</key>   <true/>
</dict>
</plist>
```

업로드:

```bash
xcrun altool --upload-app -f ./ipa/Laryen3D.ipa -t ios \
  --apiKey <KEY_ID> --apiIssuer <ISSUER_ID>
```

또는 **Transporter.app** 에 `.ipa` 를 끌어다 놓는다.

### 릴리즈 체크리스트

- [ ] `bundle_identifier` 가 App Store Connect 의 앱 ID 와 일치
- [ ] `version` / `short_version` 을 이전 빌드보다 올렸는가
- [ ] 배포용 프로비저닝 프로파일로 서명됐는가
- [ ] 아이콘·런치스크린이 모든 필수 크기로 들어갔는가
- [ ] 사용하지 않는 권한 설명(`NSCameraUsageDescription` 등)을 넣지 않았는가
- [ ] Export Compliance(암호화 사용 여부) 답변 준비

---

## 9. 자주 막히는 지점

| 증상 | 원인 | 해결 |
|---|---|---|
| 오류 본문이 빈 `configuration errors` | iOS 검증이 헤드리스에서 메시지를 안 낸다(실측) | 에디터에서 preset 을 열어 경고 확인. 아이콘·Team ID·bundle id 순으로 점검 |
| `No export template found … ios.zip` | 템플릿 미설치 | [export-build.md §3](export-build.md#3-export-template-설치) |
| `Signing for … requires a development team` | Team 미지정 | Xcode `Signing & Capabilities` 에서 Team 선택 |
| `No profiles for 'com.…' were found` | 프로파일 없음 | `Automatically manage signing` 켜기 |
| 기기에서 "신뢰할 수 없는 개발자" | 기기 승인 안 함 | `설정 > 일반 > VPN 및 기기 관리 > 신뢰` |
| 7일 뒤 앱이 안 열림 | 무료 계정 프로파일 만료 | 재설치 또는 유료 계정 |
| 시뮬레이터는 되는데 기기에서 크래시 | 아키텍처·GPU 드라이버 차이 | 반드시 실기기로 최종 확인 |
| Windows·Linux 에서 빌드 시도 | iOS 는 macOS 전용 | macOS 에서 빌드 |
| 한글이 깨짐 | 선택 설치에서 ICU Data 누락 가능성 | 템플릿 관리자에서 ICU 확인 (미검증) |

---

## 관련 문서

- [export-build.md](export-build.md) — 템플릿 개념, 필요 파일 판정표, CLI 전체
- [export-build-android.md](export-build-android.md) — Android
- [export-build-desktop.md](export-build-desktop.md) — macOS·Windows·Linux
- [performance-mobile.md](performance-mobile.md) — 모바일 최적화와 기기 등급 감지
