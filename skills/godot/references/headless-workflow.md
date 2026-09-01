# 에디터 없이 작업하기 — 터미널만으로 도는 개발 루프

Godot 에디터 GUI 를 열지 않고 **코드 작성 → 검증 → 실행 → 실기기 확인**까지 끝내는 방법이다.
Claude 가 이 프로젝트에서 작업할 때의 **기본 작업 방식**이며, CI 에서도 같은 명령을 쓴다.

빌드 자체의 개념(export template·preset·서명)은 [export-build.md](export-build.md) 와
플랫폼별 문서에 있다. 이 문서는 **루프를 어떻게 도는가**를 다룬다.

## 목차

1. [개발 루프 한 장](#1-개발-루프-한-장)
2. [기본 명령 6가지](#2-기본-명령-6가지)
3. [실기기 설치 — `install.sh`](#3-실기기-설치--installsh)
4. [iOS 실기기가 되게 하는 preset 설정](#4-ios-실기기가-되게-하는-preset-설정)
5. [에디터 Remote Deploy 와의 관계](#5-에디터-remote-deploy-와의-관계)
6. [자주 막히는 지점](#6-자주-막히는-지점)

---

## 1. 개발 루프 한 장

```text
GDScript 작성·수정
        ↓
LSP 정적 검증          python3 scripts/gdscript_lsp.py diagnose --changed   ← 필수
        ↓
창 없이 짧게 실행       godot --headless --quit-after 2
        ↓
데스크톱에서 눈으로     godot --path .
        ↓
실기기에서 최종 확인    scripts/install.sh <device-id>
```

**데스크톱 실행은 실기기 확인을 대체하지 못한다.** 터치·성능·GPU 드라이버·발열은
기기에서만 드러난다. 특히 렌더러가 `mobile`(Metal/Vulkan)이면 데스크톱과 기기의
드라이버 경로가 아예 다르다.

---

## 2. 기본 명령 6가지

`GODOT_BIN` 을 정해 두면 모든 명령이 짧아진다. Homebrew 설치면 `godot` 만으로도 된다.

```bash
GODOT_BIN="${GODOT_BIN:-$(command -v godot)}"      # 또는 /Applications/Godot.app/Contents/MacOS/Godot
```

| 목적 | 명령 |
|---|---|
| **문법·부팅 검사** (창 없음) | `godot --headless --path . --quit-after 2 --log-file artifacts/logs/check.log` |
| **임포트만 수행** | `godot --headless --path . --import --quit` |
| **실제 게임 창 실행** | `godot --path .` (프로젝트 폴더 안이면 `godot`) |
| **정적 진단** (에디터 실행 중) | `python3 .claude/skills/godot/scripts/gdscript_lsp.py diagnose --changed` |
| **빌드** | `godot --headless --path . --export-debug "<preset>" <출력경로>` |
| **실기기 설치·실행** | `.claude/skills/godot/scripts/install.sh <device-id>` |

`--quit-after N` 은 **N 프레임 뒤 종료**다. 초가 아니다. 부팅 시 오류를 잡는 용도이며,
게임 로직을 검증하지는 못한다.

화면 확인이 필요하면 게임 코드에서 직접 PNG 로 저장한다. `RenderingServer.frame_post_draw`
를 기다리지 않고 뷰포트를 읽으면 검은 화면이 저장된다.

```gdscript
await RenderingServer.frame_post_draw
var image: Image = get_viewport().get_texture().get_image()
image.save_png("user://shot.png")
print("[CAPTURE] ", ProjectSettings.globalize_path("user://shot.png"))
```

저장 위치를 추측하지 말고 **로그에 절대 경로를 찍어 확인한다.**

---

## 3. 빌드·설치·실행 — `install.sh`

```bash
.claude/skills/godot/scripts/install.sh [선택] [옵션]
```

**그냥 실행하면 지금 쓸 수 있는 장치를 번호로 보여주고, 고른 번호가 플랫폼을 정한다.**
macOS·iOS·Android 가 한 입구로 들어온다. preset 이름·패키지 ID·산출물 경로는
`export_presets.cfg` 에서 직접 읽으므로 프로젝트마다 고쳐 쓸 필요가 없다.

```
$ .claude/skills/godot/scripts/install.sh

사용 가능한 장치:

  1)  macOS     이 맥에서 실행 (arm64)
  2)  iOS       JaeHo16 — iPhone 16 Pro Max (iPhone17,2)
                67BD02AA-6E29-53D7-A5CE-A1619F9CF934

  (Android 기기 없음 — USB 디버깅을 켜고 연결한다)

번호 선택 [1]:
```

### 목록에 오르는 기준

**플랫폼마다 다르다.** 여기서 안 보이면 설치도 안 된다.

| 플랫폼 | 조회 | 오르는 조건 |
|---|---|---|
| **macOS** | `uname` | 이 맥이라 **항상 1번**. 연결이라는 개념이 없다 |
| **iOS** | `xcrun devicectl list devices` | 상태가 **`available`** 인 것만. 신뢰하지 않았거나 잠긴 기기는 `unavailable` 이라 빠진다 |
| **Android** | `adb devices -l` | 상태가 **`device`** 인 것만. `unauthorized`·`offline` 은 빠진다 |

**연결이 없는 플랫폼은 목록에서 빠지는 대신 왜 없는지를 한 줄로 알려 준다.**
"기기가 안 보인다" 에서 "무엇을 하면 보이는가" 로 바로 넘어가기 위해서다.

이전 판은 `xctrace` 도 훑어 `Devices Offline` 기기까지 잡았지만, **설치가 안 되는 기기를
목록에 올리는 것은 도움이 안 되므로** `devicectl` 의 `available` 판정 하나로 좁혔다.

### 번호 대신 직접 지정

스크립트·CI 에서는 번호가 흔들린다(기기를 뽑으면 순서가 바뀐다). 그때는 ID 를 준다.

```bash
install.sh macos                                  # 이 맥
install.sh R58X609XXYV                            # Android — adb 시리얼
install.sh 67BD02AA-6E29-53D7-A5CE-A1619F9CF934   # iOS — CoreDevice UUID
install.sh 1                                      # 목록 1번
```

**stdin 이 터미널이 아니면 묻지 않는다.** 목록만 찍고 끝나므로 CI 에서 멈추지 않는다.

| 옵션 | 동작 |
|---|---|
| `--console` | 실행 후 게임 로그를 터미널에 붙인다. iOS 는 `devicectl --console`, Android 는 `adb logcat -s godot`, macOS 는 바이너리를 직접 실행 |
| `--skip-build` | 빌드를 건너뛰고 설치·실행만. 코드 변경이 없을 때 수 초 |
| `--release` | 릴리즈 빌드 (기본은 디버그) |
| `--no-launch` | 설치만 하고 실행하지 않는다 |
| `--path <dir>` | 프로젝트 경로 지정 (기본: 현재 폴더에서 위로 `project.godot` 탐색) |
| `--list` | 목록만 출력하고 끝 |

### 스크립트가 하는 일

```text
장치 수집 (macOS + devicectl + adb)
      ↓
번호·ID 로 하나 확정 → 플랫폼이 정해진다
      ↓
project.godot 을 위로 탐색해 프로젝트 루트 확정
      ↓
export_presets.cfg 파싱 — preset 이름 / 패키지 ID / export_path
      ↓
godot --headless --export-debug "<preset>" <출력경로>
      ↓
macOS:   (.zip 이면 풀어서) xattr 로 격리 해제 → open
Android: adb install -r → adb shell monkey 로 실행
iOS:     devicectl install app → devicectl process launch
```

**macOS 만 설치라는 단계가 없다.** `.app` 을 만들면 그게 곧 설치된 앱이라,
서명 없는 자기 빌드가 Gatekeeper 에 막히지 않도록 `com.apple.quarantine` 을
지우고 여는 것이 그 자리를 대신한다.

iOS preset 이 `export_project_only=true` 면 `.ipa` 가 만들어지지 않으므로
**빌드 전에 멈추고 그 사실을 알린다.**
---

## 4. iOS 실기기가 되게 하는 preset 설정

`.ipa` 까지 한 번에 나오게 하는 값은 다섯 개다.

```ini
[preset.1]

name="iOS"
platform="iOS"
runnable=true                                   ; ① 에디터 Remote Deploy 아이콘 조건
export_path="builds/ios/Laryen3D.zip"

[preset.1.options]

architectures/arm64=true
application/app_store_team_id="AX352BQR6K"      ; ② 인증서의 OU 값
application/bundle_identifier="com.회사명.laryen3d"
application/code_sign_identity_debug="Apple Development"   ; ③
application/export_method_debug=1               ; ④ 1 = Development
application/export_project_only=false           ; ⑤ true 면 Xcode 프로젝트만 만들고 멈춘다
application/min_ios_version="14.0"
application/targeted_device_family=2            ; 2 = iPhone + iPad
```

| 항목 | 틀렸을 때 |
|---|---|
| ① `runnable` | 에디터에 Remote Deploy 아이콘이 나타나지 않는다 |
| ② `app_store_team_id` | `requires a development team` 으로 Xcode 빌드가 멈춘다 |
| ③ `code_sign_identity_debug` | 서명 실패로 `.ipa` 가 안 나온다 |
| ④ `export_method_debug` | App Store 용(`0`)으로 서명되어 기기에 설치되지 않는다 |
| ⑤ `export_project_only` | **가장 흔한 원인.** 빌드도 설치도 일어나지 않는다 |

### 함정 — Team ID 는 인증서 이름의 괄호 안 값이 아니다

```bash
security find-certificate -c "Apple Development" -p | openssl x509 -noout -subject
```

```text
subject=UID=…, CN=Apple Development: JAEHO SONG (A76BVJ94Y8), OU=AX352BQR6K, …
                                                  ↑ 개인 식별자      ↑ 이 OU 가 Team ID
```

`app_store_team_id` 에는 **`OU=` 뒤의 값**을 넣는다. 괄호 안 값을 넣으면 서명이 실패한다.

### `export_path` 에 `.zip` 을 써도 `.ipa` 가 나온다

`export_project_only=false` 일 때 Godot 은 지정 경로의 **폴더**를 작업 폴더로 삼아
Xcode 프로젝트·아카이브·`.ipa` 를 모두 그 안에 만든다.

```text
builds/ios/
├── Laryen3D.ipa            ← 설치에 쓰는 파일
├── Laryen3D.xcodeproj/
├── Laryen3D.xcarchive/
└── MoltenVK.xcframework/   ← mobile 렌더러(Vulkan)를 Metal 위에서 돌린다
```

---

## 5. 에디터 Remote Deploy 와의 관계

에디터를 함께 쓸 때 반드시 구분해야 한다.

| 조작 | 어디서 실행되나 |
|---|---|
| ▶ · `F5` · macOS `Cmd+B` (`Run Project`) | **에디터가 켜진 그 PC**. 기기와 무관하다 |
| `Cmd+R` (`Run Current Scene`) | 역시 그 PC |
| **Remote Deploy** (우측 상단 기기 아이콘) | 연결된 실기기 |

실행 버튼을 기기로 향하게 하는 설정은 **없다.** 아이콘이 안 보이면 조건이 안 맞은 것이다.

| 조건 | 확인 |
|---|---|
| preset `runnable=true` + 위 ②③④⑤ | `export_presets.cfg` |
| Xcode 설치·라이선스 | `xcodebuild -version` |
| Apple 계정 로그인 | Xcode `Settings > Accounts` |
| 기기 페어링 | `xcrun devicectl list devices` 에 `available (paired)` |
| 기기 개발자 모드 | iPhone `설정 > 개인정보 보호 및 보안 > 개발자 모드` |
| **화면 잠금 해제** | 잠기면 감지되지 않는다 |
| **에디터가 preset 을 읽은 상태** | preset 을 고쳤으면 **에디터 재시작** |

마지막 항목이 특히 잘 걸린다. 에디터가 켜진 채 `export_presets.cfg` 를 텍스트로 고치면
에디터는 옛 값을 쓰고, 종료할 때 파일을 덮어쓸 수도 있다.

Remote Deploy 와 `install.sh` 는 결과가 같다. 에디터를 띄우지 않는 작업에서는 `install.sh` 를 쓴다.

---

## 6. 자주 막히는 지점

| 증상 | 원인 | 해결 |
|---|---|---|
| 실행 버튼을 눌렀는데 데스크톱 창이 뜬다 | 정상 동작이다 | Remote Deploy 또는 `install.sh` 를 쓴다 |
| Remote Deploy 아이콘이 없다 | preset 또는 기기 조건 미충족 | §5 표를 위에서부터 점검. 고친 뒤 **에디터 재시작** |
| `kAMDMobileImageMounterDeviceLocked` | iPhone 화면이 잠김 | 잠금 해제 후 재실행 |
| iOS export 오류 본문이 비어 있다 | 헤드리스에서 iOS 검증이 메시지를 안 낸다(실측) | 아이콘 → Team ID → bundle id → `ios.zip` 순 점검 |
| `.ipa` 가 안 생긴다 | `export_project_only=true` | `false` 로 바꾼다 |
| `res://build/...` PNG 임포트 오류가 쏟아진다 | Xcode 가 만든 `CgBI` PNG 를 Godot 이 못 읽는다 | 빌드 폴더에 빈 `.gdignore` 를 둔다 |
| 빌드가 시뮬레이터용 패치본을 지운다 | `delete_old_export_files_unconditionally=true` | `false` 로 두고 출력 폴더를 분리한다 |
| Android APK 서명 실패 | Android SDK build-tools 의 `apksigner` 경로 미설정 | 에디터 설정 `Export > Android` 에서 SDK 경로 지정 |

### `.gdignore` 와 `exclude_filter` 는 다른 문제다

| | 뜻 |
|---|---|
| `exclude_filter="builds/*"` | 게임 패키지에 **포함하지 않는다** |
| `builds/.gdignore` (빈 파일) | Godot 이 그 폴더를 **임포트조차 하지 않는다** |

빌드 산출물이 `res://` 안에 있으면 **둘 다** 해 둔다.

---

## 관련 문서

- [export-build.md](export-build.md) — 템플릿 개념, 필요 파일 판정표, CLI 전체
- [export-build-ios.md](export-build-ios.md) — iOS 서명·Xcode·TestFlight
- [export-build-android.md](export-build-android.md) — Android APK·AAB·adb
- [lsp.md](lsp.md) — LSP 정적 검증 (코드 작성 직후 필수)
- `docs/godot/에디터 없이 작업.md` §13 — 사람이 읽는 전 과정 예제
