# Android 빌드 — 테스트 APK · 설치 · 실행 · 릴리즈

Android 앱을 만들어 실기기에 올리고 Play 스토어까지 내보내는 전 과정.
템플릿 개념과 작업별 필요 파일은 [export-build.md](export-build.md) 를 먼저 볼 것.

## 목차

1. [사전 준비](#1-사전-준비)
2. [테스트 빌드 — debug APK](#2-테스트-빌드--debug-apk)
3. [설치와 실행](#3-설치와-실행)
4. [디버깅 — 로그와 원격 디버그](#4-디버깅--로그와-원격-디버그)
5. [릴리즈 빌드 — APK](#5-릴리즈-빌드--apk)
6. [릴리즈 빌드 — AAB (Play 스토어)](#6-릴리즈-빌드--aab-play-스토어)
7. [Gradle 빌드(GABE)](#7-gradle-빌드gabe)
8. [preset 옵션 전체](#8-preset-옵션-전체)
9. [권한 최소화](#9-권한-최소화)
10. [스플래시 화면 — 두 종류](#10-스플래시-화면--두-종류)
11. [자주 막히는 지점](#11-자주-막히는-지점)

---

## 1. 사전 준비

| 항목 | 필요 이유 | 확인 방법 |
|---|---|---|
| **`android_debug.apk` 템플릿** | debug APK 의 재료 | `ls "$HOME/Library/Application Support/Godot/export_templates/4.7.2.stable/android_debug.apk"` |
| **JDK 17** | Godot 이 APK 를 서명·패키징할 때 사용 | `/usr/libexec/java_home -V` |
| **Android SDK** | build-tools·platform-tools(adb) | `ls ~/Library/Android/sdk` |
| **에디터 설정 2개** | Godot 이 위 둘을 찾는 경로 | 아래 |
| **debug keystore** | debug 서명 — **자동 생성됨** | 아래 |

### 에디터 설정 (🧑 사람이 UI 에서)

`Editor > Editor Settings > Export > Android`

| 항목 | 값 |
|---|---|
| `Java SDK Path` | JDK 17 홈 (예: `/Library/Java/JavaVirtualMachines/temurin-17.jdk/Contents/Home`) |
| `Android SDK Path` | `~/Library/Android/sdk` |
| `Debug Keystore` | 비워 두면 Godot 이 자동 생성 |

실제 저장 위치는 `~/Library/Application Support/Godot/editor_settings-4.7.tres` 다.
값이 제대로 들어갔는지는 이렇게 본다 (**Claude 는 이 파일을 수정하지 않는다**):

```bash
grep -n "java_sdk_path\|android_sdk_path\|debug_keystore" \
  "$HOME/Library/Application Support/Godot/editor_settings-4.7.tres"
```

```ini
export/android/debug_keystore = "/Users/…/Godot/keystores/debug.keystore"
export/android/debug_keystore_pass = "android"
export/android/java_sdk_path = ""                    ← 비어 있으면 export 가 막힌다
export/android/android_sdk_path = "/Users/…/Library/Android/sdk"
```

`java_sdk_path` 가 빈 문자열이면 템플릿이 다 있어도 이 오류로 실패한다(실측):

```text
A valid Java SDK path is required in Editor Settings.
```

> ⚠️ **경로가 비어 있는 이유가 "설정을 안 해서"가 아니라 "JDK 가 없어서"일 수 있다.**
> 이 머신을 확인한 결과 `/usr/libexec/java_home -V` 가 `Unable to locate a Java Runtime`
> 을 반환했다 — JDK 자체가 설치돼 있지 않다. 이때는 에디터 설정에 경로를 적어 넣을 수도
> 없으므로 **설치가 먼저다**: `brew install --cask temurin@17`

### debug keystore 는 직접 만들지 않는다

Godot 이 `~/Library/Application Support/Godot/keystores/debug.keystore` 를 자동 생성하고
비밀번호 `android` 를 에디터 설정에 채워 둔다. **테스트 APK 에 `keytool` 은 불필요하다.**
`keytool` 이 필요한 건 §5 릴리즈뿐이다.

---

## 2. 테스트 빌드 — debug APK

### 필요한 것은 `android_debug.apk` 하나

`ios.zip`·`macos.zip`·`windows*.exe`·`android_source.zip` 은 **쓰이지 않는다**
([export-build.md §2](export-build.md#2-작업별-최소-필요-템플릿-파일-실측-확정)).

### preset (🧑 사람이 에디터에서 생성)

`Project > Export > Add > Android`, 그리고 **`Runnable` 을 켠다**(원클릭 배포에 필요).
텍스트로는 이렇게 저장된다 — **참고용, Claude 는 이 파일을 만들지 않는다**:

```ini
[preset.0]

name="Android"
platform="Android"
runnable=true
export_filter="all_resources"
exclude_filter="artifacts/*, builds/*"
export_path="builds/android/Laryen3D.apk"

[preset.0.options]

gradle_build/use_gradle_build=false     ; 테스트는 false 가 빠르다
gradle_build/export_format=0            ; 0=APK, 1=AAB
architectures/arm64-v8a=true
architectures/armeabi-v7a=false
package/unique_name="com.회사명.laryen3d"
package/name="라리엔"
package/signed=true
version/code=1
version/name="1.0.0"
screen/immersive_mode=true
```

### 빌드

```bash
PROJECT="/Users/thruthesky/apps/game/laryen3d"
mkdir -p "$PROJECT/builds/android" "$PROJECT/artifacts/logs"

godot --headless --path "$PROJECT" --import --quit || true    # 첫 실행만

godot --headless --path "$PROJECT" \
  --export-debug "Android" builds/android/Laryen3D-debug.apk \
  --log-file artifacts/logs/build-android-debug.log
EXIT=$?
echo "EXIT=$EXIT"
ls -lh "$PROJECT/builds/android/Laryen3D-debug.apk"
```

- **출력 경로는 `--path` 기준 상대경로**다. 실제 산출물은 `$PROJECT/builds/android/…` 에 생긴다.
- **출력 디렉터리를 먼저 만들어야 한다.**
- **`$?` 를 파이프로 가리지 말 것** — 실패 시 exit 1 이다(실측).

### debug 빌드가 release 와 다른 점

| | debug | release |
|---|---|---|
| 템플릿 | `android_debug.apk` | `android_release.apk` |
| 서명 | debug keystore (자동) | 릴리즈 keystore (직접 생성) |
| 원격 디버거 | 붙는다 | 안 붙는다 |
| `print()` 로그 | `adb logcat` 에 나온다 | 대부분 제거 |
| 배포 | ❌ 스토어 업로드 불가 | ✅ |

---

## 3. 설치와 실행

### 가장 빠른 방법 — `install.sh`

빌드·설치·실행을 한 줄로 끝낸다. `adb devices` 의 시리얼을 그대로 넘기면 된다.

```bash
.claude/skills/godot/scripts/install.sh                    # 연결된 기기 목록
.claude/skills/godot/scripts/install.sh R58X609XXYV        # 빌드 → 설치 → 실행
.claude/skills/godot/scripts/install.sh <시리얼> --console  # logcat 을 붙인다
.claude/skills/godot/scripts/install.sh <시리얼> --skip-build
```

preset 이름·`package/unique_name`·`export_path` 는 `export_presets.cfg` 에서 직접 읽는다.
상세는 [headless-workflow.md](headless-workflow.md) §3. 아래는 같은 일을 손으로 하는 방법이다.

### 기기 준비

1. 기기에서 `설정 > 휴대전화 정보 > 빌드 번호` 를 7번 탭 → 개발자 옵션 활성화
2. `개발자 옵션 > USB 디버깅` 켜기
3. USB 연결 후 기기 화면의 **"USB 디버깅을 허용하시겠습니까?"** 를 허용

```bash
adb devices
# List of devices attached
# R3CN90XXXXX	device        ← "device" 여야 한다. "unauthorized" 면 위 3번 미승인
```

`adb` 가 없으면 `~/Library/Android/sdk/platform-tools/adb` 를 PATH 에 넣는다.

### 설치

```bash
adb install -r builds/android/Laryen3D-debug.apk
```

| 플래그 | 의미 |
|---|---|
| `-r` | 기존 앱 유지한 채 재설치(데이터 보존) |
| `-d` | 다운그레이드 허용 (versionCode 가 낮을 때) |
| `-t` | 테스트 전용 APK 허용 |

**서명이 다르면 `-r` 로도 실패한다.** 에디터로 설치한 빌드와 CLI 빌드는 서명이 다를 수 있다:

```text
INSTALL_FAILED_UPDATE_INCOMPATIBLE: Existing package signatures do not match
```

이때는 지우고 다시 깐다 — **앱 데이터도 함께 지워진다**:

```bash
adb uninstall com.회사명.laryen3d
adb install builds/android/Laryen3D-debug.apk
```

세이브를 보존하며 반복 테스트하려면 **debug 전용 패키지명**(`…laryen3d.debug`)을 별도 preset
으로 두는 편이 안전하다.

### 실행

```bash
# 패키지명으로 바로 실행
adb shell monkey -p com.회사명.laryen3d -c android.intent.category.LAUNCHER 1

# 또는 액티비티 지정
adb shell am start -n com.회사명.laryen3d/com.godot.game.GodotApp
```

### 원클릭 배포 (에디터가 있을 때 가장 빠름)

preset 의 `Runnable` 이 켜져 있고 기기가 연결돼 있으면, 에디터 우상단의 **Android 기기
아이콘**을 누르는 것만으로 debug export → 설치 → 실행이 한 번에 돈다. 반복 테스트에는
CLI 보다 이쪽이 빠르다.

---

## 4. 디버깅 — 로그와 원격 디버그

```bash
# Godot 로그만
adb logcat -s godot

# 여러 태그 (크래시 추적)
adb logcat -s godot:V GodotEngine:V AndroidRuntime:E DEBUG:V

# 기존 로그 지우고 처음부터
adb logcat -c && adb logcat -s godot

# 파일로 저장
adb logcat -s godot > artifacts/logs/device.log
```

GDScript 의 `print()` 는 `godot` 태그로 나온다.

### 원격 디버그

에디터에서 `Debug > Deploy with Remote Debug` 를 켜고 원클릭 배포하면, 기기에서 도는 게임이
에디터 디버거에 붙는다. 중단점·변수 검사·프로파일러가 실기기에서 그대로 동작한다.
**debug 빌드에서만 된다.**

무선 디버깅(Android 11+):

```bash
adb pair 192.168.0.10:37000      # 기기의 무선 디버깅 화면에 뜬 페어링 코드 입력
adb connect 192.168.0.10:5555
```

### 성능 프로파일링

4.7 은 **Perfetto** 를 기본 추적 도구로 채택했다. Android Studio 프로파일러와 연동해
프레임 단위 분석이 가능하다. 자세한 최적화 지표는
[performance-mobile.md](performance-mobile.md) 참고.

---

## 5. 릴리즈 빌드 — APK

기기에 직접 설치하거나 스토어 밖에서 배포할 때 쓴다. Play 스토어 신규 등록은 §6 의 AAB 다.

### 릴리즈 keystore 생성 (🧑 사람, 최초 1회)

```bash
keytool -v -genkeypair \
  -keystore laryen3d-release.keystore \
  -alias laryen3d \
  -keyalg RSA -keysize 2048 -validity 10000
```

> 🛑 **keystore 와 비밀번호를 잃으면 그 앱을 영원히 업데이트할 수 없다.**
> 안전한 곳에 백업하고 `.gitignore` 에 반드시 추가한다.
> Godot Android export 는 **keystore 비밀번호와 key 비밀번호가 같아야 한다.**
> `keytool` 이 key 비밀번호를 물으면 keystore 와 같은 값을 쓴다.

### 비밀번호는 환경변수로

`export_presets.cfg` 에 비밀번호를 적으면 Git 에 올라간다. 환경변수로 넘긴다:

```bash
export GODOT_ANDROID_KEYSTORE_RELEASE_PATH="$PWD/laryen3d-release.keystore"
export GODOT_ANDROID_KEYSTORE_RELEASE_USER="laryen3d"

printf 'Keystore password: '
read -s GODOT_ANDROID_KEYSTORE_RELEASE_PASSWORD
printf '\n'
export GODOT_ANDROID_KEYSTORE_RELEASE_PASSWORD
```

### 빌드

```bash
godot --headless --path "$PROJECT" \
  --export-release "Android" builds/android/Laryen3D.apk \
  --log-file artifacts/logs/build-android-release.log
echo "EXIT=$?"
```

필요한 템플릿은 `android_release.apk` 다(gradle off 기준).

### 검증

build-tools 의 버전 폴더명은 환경마다 다르므로 설치된 것 중 최신을 고른다.

```bash
BT="$(ls -d "$HOME/Library/Android/sdk/build-tools"/* | sort -V | tail -1)"

# 서명 확인
"$BT/apksigner" verify --print-certs builds/android/Laryen3D.apk

# 패키지명·버전 확인
"$BT/aapt2" dump badging builds/android/Laryen3D.apk | head -5
```

---

## 6. 릴리즈 빌드 — AAB (Play 스토어)

2021년 8월 이후 Play 스토어 **신규 앱은 AAB 필수**다. APK 는 업로드할 수 없다.

```text
Godot 프로젝트 + android_source.zip(Gradle 템플릿) + 네이티브 라이브러리 + 업로드 키
        ↓ Godot 이 Gradle 을 호출해 빌드
Laryen3D.aab
        ↓ Play Console 업로드
Google Play 가 기기별 APK 를 생성·서명·배포 (Play App Signing)
```

### preset 옵션

```ini
gradle_build/use_gradle_build=true
gradle_build/export_format=1        ; 1 = AAB
```

이 순간 **필요한 템플릿이 `android_source.zip` 하나로 바뀐다**
— `android_debug.apk`·`android_release.apk` 는 요구되지 않는다(실측).

### 빌드

```bash
godot --headless --path "$PROJECT" \
  --install-android-build-template \
  --export-release "Android" builds/android/Laryen3D.aab \
  --log-file artifacts/logs/build-android-aab.log
echo "EXIT=$?"
```

`--install-android-build-template` 은 `android_source.zip` 을 풀어 Gradle 프로젝트를
`res://android/build/` 에 만든다. 게임 씬을 두는 폴더와 다른 **빌드 템플릿 폴더**다:

```text
laryen3d/
├── scenes/            ← 게임 씬
├── android/build/     ← Gradle Android 빌드 템플릿 (엔진 버전과 묶임)
└── builds/android/    ← 산출물 Laryen3D.aab
```

> ⚠️ **엔진을 업그레이드하면 `android/build/` 를 다시 설치해야 한다.** 이 폴더는 엔진 버전에
> 고정된다. 4.7.3 으로 올리면 지우고 `--install-android-build-template` 을 다시 돌린다.

### 업로드 키와 Play App Signing

AAB 는 **업로드 키**로 서명해 Play Console 에 올린다. Play App Signing 을 쓰면 Google 이
사용자에게 줄 APK 를 **앱 서명 키**로 다시 서명한다. 업로드 키를 잃어도 Google 지원으로
교체가 가능하지만, 앱 서명 키는 교체할 수 없다.

---

## 7. Gradle 빌드(GABE)

4.7 에서 안정화된 Gradle 기반 내보내기다. **출력이 APK 든 AAB 든** `use_gradle_build=true`
면 Gradle 경로를 탄다.

### 언제 켜야 하나

| 상황 | Gradle |
|---|---|
| 단순 테스트 APK | ❌ off — 빌드가 빠르다 |
| Play 스토어 AAB | ✅ on (필수) |
| Android 플러그인 (AdMob, 결제, Nakama 네이티브 등) | ✅ on |
| GDExtension 안드로이드 바이너리 | ✅ on |
| 커스텀 `AndroidManifest.xml` 수정 | ✅ on |

### 판정 축을 혼동하지 말 것

**"APK 냐 AAB 냐"가 아니라 `use_gradle_build` 값 하나가 필요 템플릿을 가른다**(실측).

| `use_gradle_build` | `export_format` | 필요 템플릿 |
|---|---|---|
| `false` | 0 (APK) | `android_debug.apk` 또는 `android_release.apk` |
| `true` | 0 (APK) | **`android_source.zip`** |
| `true` | 1 (AAB) | **`android_source.zip`** |

`use_gradle_build=true` 면 APK 를 뽑아도 prebuilt 템플릿 APK 를 쓰지 않는다.

---

## 8. preset 옵션 전체

`Project > Export > Android` (🧑 사람이 UI 에서 설정)

| 항목 | 값·주의 |
|---|---|
| **Package/Unique Name** | `com.회사명.laryen3d` — **스토어 등록 후 변경 불가.** 신중히 |
| **Package/Name** | 앱 표시 이름 |
| **Package/Signed** | On |
| **Version/Code** | 정수. 업데이트마다 **반드시 증가** |
| **Version/Name** | `1.0.0` — 사용자에게 보이는 버전 |
| **Architectures/arm64-v8a** | ✅ 필수 (현행 기기 전부) |
| **Architectures/armeabi-v7a** | 구형 32bit 지원용. 용량이 늘어난다 |
| **Architectures/x86_64** | 에뮬레이터용. 스토어 업로드 시 용량만 늘림 |
| **Gradle Build/Use Gradle Build** | §7 판정표 |
| **Gradle Build/Export Format** | 0=APK, 1=AAB |
| **Keystore/Release** | 릴리즈 keystore 경로 (환경변수 권장) |
| **Screen/Immersive Mode** | On — 전체화면 |
| **Screen/Orientation** | 라리엔은 `Landscape` 또는 `Portrait` 중 게임 설계에 맞게 |
| **XR Features/XR Mode** | `Regular` (VR 아님) |
| **Permissions** | §9 — 필요한 것만 |
| **Graphics/OpenGL Debug** | Off (릴리즈) |
| **Splash Screen/** | §10 |

---

## 9. 권한 최소화

기본으로 켜진 권한이 남아 있으면 스토어 심사에서 문제가 된다. **실제로 쓰는 것만 켠다.**

| 게임 성격 | 필요한 권한 |
|---|---|
| 오프라인 싱글플레이 | 거의 없음 |
| **온라인 (라리엔)** | `INTERNET` |
| 외부 저장소 세이브 | `READ/WRITE_EXTERNAL_STORAGE` — **권장하지 않는다.** `user://` 를 쓴다 |

라리엔 3D 는 Zone 서버(UDP)·Nakama 와 통신하므로 `INTERNET` 이 필요하다.
그 외에는 켜지 않는다.

---

## 10. 스플래시 화면 — 두 종류

앱을 켜면 **두 개의 스플래시가 순서대로** 지나간다. 설정 위치가 다르다.

| 순서 | 이름 | 설정 위치 | 표시 시점 |
|---|---|---|---|
| 1 | 안드로이드 **네이티브** 스플래시 | export preset 의 `splash_screen/*` | 아이콘 탭 직후. **엔진이 뜨기 전** |
| 2 | Godot **부트** 스플래시 | `project.godot` 의 `boot_splash/*` | 엔진 초기화 후, 첫 씬 로딩 전 |

### 1번 — 네이티브 (4.7 신기능)

이전에는 Gradle 커스텀 빌드를 켜고 네이티브 리소스를 직접 넣어야 했지만, 4.7 부터
**preset 옵션만으로** 된다. 경로: `Project > Export > Android > Options > Splash Screen`

| 옵션 | 타입 | 의미 |
|---|---|---|
| `splash_screen/icon` | 이미지 | 중앙 아이콘 |
| `splash_screen/branding_image` | 이미지 | 하단 브랜딩 로고 |
| `splash_screen/background_color` | `Color` | 배경색 |
| `splash_screen/disable_godot_boot_splash` | `bool` | 2번을 끈다 |

```ini
splash_screen/icon="res://ui/splash/icon_512.png"
splash_screen/branding_image="res://ui/splash/laryen_logo.png"
splash_screen/background_color=Color(0.05, 0.05, 0.08, 1)
splash_screen/disable_godot_boot_splash=true
```

### 2번 — Godot 부트

```ini
; project.godot  (🧑 사람이 수정)
[application]

boot_splash/image="res://ui/splash/boot.png"
boot_splash/bg_color=Color(0.05, 0.05, 0.08, 1)
boot_splash/fullsize=true
```

### 두 개를 맞추지 않으면 두 번 깜빡인다

**배경색을 반드시 같게 한다.** 같은 그림을 두 번 보여줄 이유가 없으면
`disable_godot_boot_splash=true` 로 2번을 꺼서 네이티브 → 첫 씬으로 한 번에 넘긴다.

단 **로딩이 긴 게임이면 2번을 살리는 편이 낫다.** 네이티브 스플래시는 엔진 초기화가 끝나면
사라지므로, 그 뒤 씬 로딩 동안 검은 화면이 보이기 때문이다.

---

## 11. 자주 막히는 지점

| 증상 | 원인 | 해결 |
|---|---|---|
| `No export template found … android_debug.apk` | 템플릿 미설치 | [export-build.md §3](export-build.md#3-export-template-설치) |
| 오류에 `android_release.apk` 도 뜬다 | **나열일 뿐 둘 다 필수가 아니다** | debug 만 있으면 debug 빌드는 된다 |
| `A valid Java SDK path is required` | `java_sdk_path` 빈 문자열 | 🧑 `Editor Settings > Export > Android > Java SDK Path` |
| `Android build template not installed` | `use_gradle_build=true` 인데 `res://android/build/` 없음 | `--install-android-build-template` 을 `--export-*` 와 함께 |
| `INSTALL_FAILED_UPDATE_INCOMPATIBLE` | 서명이 다른 동명 패키지 존재 | `adb uninstall <package>` 후 재설치 |
| `INSTALL_FAILED_VERSION_DOWNGRADE` | versionCode 가 더 낮음 | `adb install -d` 또는 code 증가 |
| `adb devices` 에 `unauthorized` | 기기에서 USB 디버깅 미승인 | 기기 화면의 허용 팝업 확인 |
| exit 0 인데 APK 가 없음 | 파이프로 `$?` 가 가려짐 | 로그는 리다이렉트, `$?` 는 직접 확인 |
| 출력 경로에 파일이 안 생김 | 출력 디렉터리 없음 / 경로가 `--path` 기준 상대경로 | `mkdir -p` 먼저 |
| 한글이 깨짐 | 선택 설치에서 ICU Data 누락 가능성 | 템플릿 관리자에서 ICU 확인 (미검증) |
| 엔진 업그레이드 후 Gradle 빌드 실패 | `android/build/` 가 구버전 | 폴더 삭제 후 재설치 |

---

## 관련 문서

- [export-build.md](export-build.md) — 템플릿 개념, 필요 파일 판정표, CLI 전체
- [performance-mobile.md](performance-mobile.md) — 모바일 최적화, 기기 등급 감지, 렌더링 설정
- [export-build-desktop.md](export-build-desktop.md) — Steam(Windows/macOS/Linux)
- [whats-new.md](whats-new.md) — GABE, Perfetto, Java 인터페이스 등 4.7 Android 신기능
