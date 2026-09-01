# 데스크톱 빌드 — macOS · Windows · Linux (Steam)

데스크톱 3종의 테스트 실행과 Steam 배포용 릴리즈.
템플릿 개념과 필요 파일 판정표는 [export-build.md](export-build.md) 를 먼저 볼 것.

## 목차

1. [플랫폼별 필요 템플릿 (실측)](#1-플랫폼별-필요-템플릿-실측)
2. [테스트 실행 — 템플릿 없이](#2-테스트-실행--템플릿-없이)
3. [macOS](#3-macos)
4. [Windows](#4-windows)
5. [Linux · Steam Deck](#5-linux--steam-deck)
6. [공통 preset 옵션](#6-공통-preset-옵션)
7. [렌더러 선택](#7-렌더러-선택)
8. [Steam 통합](#8-steam-통합)
9. [크로스 플랫폼 빌드 스크립트](#9-크로스-플랫폼-빌드-스크립트)
10. [자주 막히는 지점](#10-자주-막히는-지점)

---

## 1. 플랫폼별 필요 템플릿 (실측)

**모드(debug/release)마다 파일이 다르다.** macOS 만 예외로 하나를 공유한다.

| 플랫폼 | debug | release |
|---|---|---|
| **macOS** | `macos.zip` | `macos.zip` (같은 파일) |
| **Windows** | `windows_debug_x86_64.exe` | `windows_release_x86_64.exe` |
| **Linux** | `linux_debug.x86_64` | `linux_release.x86_64` |

> 템플릿이 하나도 없을 때 오류는 debug·release 를 **둘 다 나열**하지만, **지금 쓰는 모드의
> 파일 하나만 있으면 된다.** Windows 로 실측 확인 — `windows_debug_x86_64.exe` 하나만 두고
> `--export-debug` 를 돌리자 **완주해서 `.exe` 와 `.pck` 를 만들어냈다.**

### 어디서 어디로 빌드할 수 있나

| 만들 것 | macOS 에서 | Windows 에서 | Linux 에서 |
|---|---|---|---|
| Windows `.exe` | ✅ | ✅ | ✅ |
| Linux 바이너리 | ✅ | ✅ | ✅ |
| macOS `.app` | ✅ | ⚠️ 서명·공증 불가 | ⚠️ 서명·공증 불가 |

**실행 검증은 그 OS 에서 해야 한다.** 크로스 빌드는 파일을 만들 뿐 동작을 보장하지 않는다.

---

## 2. 테스트 실행 — 템플릿 없이

개발 중 반복 확인에는 **export 자체가 필요 없다.** 에디터 바이너리가 곧 엔진이다.

```bash
PROJECT="/Users/thruthesky/apps/game/laryen3d"

# 게임 창 실행
godot --path "$PROJECT"

# 특정 씬만
godot --path "$PROJECT" res://scenes/test_arena.tscn

# 창 없이 로드 검사 (2초 후 종료)
godot --headless --path "$PROJECT" --quit-after 2

# 데이터만 패키징 (템플릿 불필요 — 실측 확인)
godot --headless --path "$PROJECT" --export-pack "Windows Desktop" build/game.pck
```

**패키징된 실행 파일이 필요할 때만** §3~§5 로 간다. 대표적으로 배포 전 최종 확인,
`OS.has_feature()` 로 갈리는 코드 검증, 실제 시작 시간·메모리 측정이다.

---

## 3. macOS

### 필요한 것

`macos.zip` 하나. debug·release 가 같은 파일을 쓴다.

### preset

`Project > Export > Add > macOS` (🧑 사람이 에디터에서)

```ini
[preset.0]

name="macOS"
platform="macOS"
runnable=true
export_path="builds/macos/Laryen3D.zip"

[preset.0.options]

binary_format/architecture="universal"      ; universal / x86_64 / arm64
application/bundle_identifier="com.회사명.laryen3d"
application/short_version="1.0.0"
application/version="1.0.0"
codesign/codesign=1                         ; 0=없음 1=rcodesign 2=Xcode codesign
notarization/notarization=0                 ; 배포 시 필요
```

| `binary_format/architecture` | 대상 |
|---|---|
| `universal` | Intel + Apple Silicon 모두 (권장, 용량 2배) |
| `arm64` | Apple Silicon 전용 |
| `x86_64` | Intel 전용 |

### 빌드

```bash
mkdir -p "$PROJECT/builds/macos"

godot --headless --path "$PROJECT" \
  --export-debug "macOS" builds/macos/Laryen3D.zip \
  --log-file artifacts/logs/build-macos-debug.log
echo "EXIT=$?"
```

출력 확장자에 따라 산출물이 갈린다:

| `export_path` 확장자 | 산출물 |
|---|---|
| `.zip` | `.app` 을 담은 zip (CI·배포에 안전) |
| `.app` | `.app` 번들 그대로 |
| `.dmg` | 디스크 이미지 (macOS 에서 빌드할 때만) |

### 실행

```bash
cd "$PROJECT/builds/macos"
unzip -o Laryen3D.zip
open Laryen3D.app

# 터미널에서 직접 실행하면 로그가 보인다
./Laryen3D.app/Contents/MacOS/Laryen3D
```

### 서명 없는 빌드가 안 열릴 때

Gatekeeper 가 막으면 격리 속성을 제거한다 (**본인이 만든 빌드에만** 쓴다):

```bash
xattr -dr com.apple.quarantine Laryen3D.app
```

### 릴리즈 — 서명과 공증

배포하려면 Apple Developer 계정과 **공증(notarization)** 이 필요하다. 공증 없이 배포하면
사용자 쪽에서 "손상되었습니다" 라며 열리지 않는다.

```bash
# 1) 서명 (preset 의 codesign 옵션으로도 가능)
codesign --deep --force --timestamp --options runtime \
  --sign "Developer ID Application: 이름 (TEAMID)" Laryen3D.app

# 2) 공증용 zip
ditto -c -k --keepParent Laryen3D.app Laryen3D-notarize.zip

# 3) 제출 (App Store Connect API 키 또는 앱 암호)
xcrun notarytool submit Laryen3D-notarize.zip \
  --apple-id "you@example.com" --team-id ABCDE12XYZ \
  --password "app-specific-password" --wait

# 4) 티켓 첨부
xcrun stapler staple Laryen3D.app
```

Steam 배포는 Steam 이 자체 런처로 실행하므로 공증 요구가 다르다 — Steamworks 문서 확인.

---

## 4. Windows

### 필요한 것

**모드마다 파일이 다르다.**

- 테스트: `windows_debug_x86_64.exe`
- 릴리즈: `windows_release_x86_64.exe`

macOS·Linux 에서도 만들 수 있지만 **실행 검증은 Windows PC 에서** 해야 한다.

### preset

```ini
[preset.0]

name="Windows Desktop"      ; --export-* 에 이 이름을 그대로 (공백 포함, 따옴표 필수)
platform="Windows Desktop"
runnable=true
export_path="builds/windows/Laryen3D.exe"

[preset.0.options]

binary_format/architecture="x86_64"
binary_format/embed_pck=true               ; 단일 exe
application/icon="res://ui/icon.ico"
application/file_version="1.0.0.0"
application/product_version="1.0.0.0"
application/product_name="Laryen3D"
application/company_name="회사명"
codesign/enable=false                      ; 배포 시 코드 서명
```

### 빌드

```bash
mkdir -p "$PROJECT/builds/windows"

# 테스트
godot --headless --path "$PROJECT" \
  --export-debug "Windows Desktop" builds/windows/Laryen3D-debug.exe

# 릴리즈
godot --headless --path "$PROJECT" \
  --export-release "Windows Desktop" builds/windows/Laryen3D.exe \
  --log-file artifacts/logs/build-windows-release.log
echo "EXIT=$?"
```

`embed_pck=false` 면 `.exe` 옆에 `.pck` 가 함께 생기며 **둘 다 배포해야 한다.**
`true` 면 단일 파일이라 배포가 간단하다.

### 실행 (Windows PC 에서)

```bat
Laryen3D.exe

REM 콘솔 로그를 보려면
Laryen3D.console.exe

REM 상세 로그
Laryen3D.exe --verbose > log.txt 2>&1
```

Godot 은 `.exe` 와 함께 `.console.exe` 를 만든다. 콘솔 창에서 `print()` 를 보려면 이쪽을 쓴다.

### 코드 서명

서명하지 않으면 SmartScreen 경고가 뜬다. EV 인증서가 있으면 preset 의 `codesign/*` 를 채우거나
`signtool` 로 서명한다. Steam 배포는 Steam 클라이언트가 실행하므로 경고가 덜하다.

---

## 5. Linux · Steam Deck

### 필요한 것

`linux_debug.x86_64` (테스트) / `linux_release.x86_64` (릴리즈)

### 빌드

```bash
mkdir -p "$PROJECT/builds/linux"

godot --headless --path "$PROJECT" \
  --export-release "Linux" builds/linux/Laryen3D.x86_64 \
  --log-file artifacts/logs/build-linux-release.log
```

### 실행

```bash
chmod +x Laryen3D.x86_64      # 실행 권한이 없으면 안 돈다
./Laryen3D.x86_64
```

### Steam Deck

Steam Deck 은 Arch 기반 Linux 이며 **Proton 없이 네이티브 Linux 빌드가 그대로 돈다.**

| 항목 | 권장 |
|---|---|
| 해상도 | 1280×800 (16:10) 대응 확인 |
| 렌더러 | **Mobile 렌더러가 유리** — 배터리·발열 |
| 입력 | 게임패드 기본 지원 필수. 터치도 있음 |
| 텍스트 크기 | 7인치 화면 기준으로 UI 스케일 확인 |

라리엔 3D 는 Mobile 렌더러를 쓰므로 Steam Deck 적합성이 좋다(§7).

---

## 6. 공통 preset 옵션

| 항목 | 값 | 의미 |
|---|---|---|
| **Binary Format/Embed PCK** | On | 단일 실행 파일. 배포가 간단해진다 |
| **Binary Format/Architecture** | `x86_64` / `universal`(macOS) | 대상 CPU |
| **Application/Icon** | `.ico`(Win) / `.icns`(mac) | 실행 파일 아이콘 |
| **Application/Product Name·Version** | 문자열 | 파일 속성 메타데이터 |
| **Codesign** | 배포 시 On | macOS 는 공증까지 필요 |
| **Export Filter** | `all_resources` | 무엇을 포함할지 |
| **Exclude Filter** | `artifacts/*, builds/*` | **빌드 산출물이 자기 자신에 들어가지 않게** |

`exclude_filter` 를 비워 두면 이전 빌드가 새 빌드에 통째로 들어가 용량이 눈덩이처럼 커진다.

---

## 7. 렌더러 선택

라리엔 3D 의 `project.godot` 에는 Windows 용 드라이버가 지정돼 있다:

```ini
rendering_device/driver.windows="d3d12"
```

Direct3D 12 를 써서 Vulkan 드라이버 문제를 회피한다.

**Mobile 렌더러로 데스크톱에 내보내도 문제없다.** 오히려 저사양 PC 에서 프레임이 잘 나오고
Steam Deck 에서도 유리하다. 고사양 PC 의 그래픽 품질이 아쉬우면 나중에 Forward+ 전환을
검토한다 — 다만 모바일과 렌더러가 갈리면 머티리얼·조명을 두 번 검증해야 한다.

플랫폼별 설정 분기는 기능 태그를 쓴다:

```ini
; project.godot — 설정 이름 뒤에 .태그
[rendering]

renderer/rendering_method="mobile"
renderer/rendering_method.windows="mobile"
```

---

## 8. Steam 통합

**Godot 자체에는 Steamworks 연동이 없다.** GDExtension 플러그인을 쓴다.

- **GodotSteam** (GDExtension) — 업적, 클라우드 세이브, 리더보드, 오버레이
- Asset Store 또는 GitHub 에서 설치
- 설치 후 **에디터 재시작**이 필요하고, 빌드 시 플러그인 바이너리가 함께 나가는지 확인한다

Steam 빌드 체크리스트:

- [ ] `embed_pck=true` 로 단일 실행 파일
- [ ] 게임패드 입력 동작 (Steam Deck·컨트롤러 사용자)
- [ ] 알트탭 시 게임패드 포커스 처리 (4.7 의 "게임패드 미포커스 무시" 옵션)
- [ ] 클라우드 세이브 대상 경로가 `user://` 인가
- [ ] Steam 오버레이와 충돌하지 않는가

---

## 9. 크로스 플랫폼 빌드 스크립트

```bash
#!/usr/bin/env bash
set -euo pipefail

PROJECT="/Users/thruthesky/apps/game/laryen3d"
OUT="$PROJECT/builds"
GODOT="godot"
T="$HOME/Library/Application Support/Godot/export_templates/4.7.2.stable"

# 필요한 템플릿만 확인 — 6개를 전부 볼 이유가 없다
for f in windows_release_x86_64.exe linux_release.x86_64 macos.zip; do
  [ -f "$T/$f" ] || { echo "템플릿 없음: $f"; exit 1; }
done

mkdir -p "$OUT"/{windows,linux,macos} "$PROJECT/artifacts/logs"

echo "== 임포트 =="
"$GODOT" --headless --path "$PROJECT" --import --quit || true

echo "== Windows =="
"$GODOT" --headless --path "$PROJECT" \
  --export-release "Windows Desktop" "builds/windows/Laryen3D.exe" \
  --log-file "artifacts/logs/build-windows.log"

echo "== Linux =="
"$GODOT" --headless --path "$PROJECT" \
  --export-release "Linux" "builds/linux/Laryen3D.x86_64" \
  --log-file "artifacts/logs/build-linux.log"

echo "== macOS =="
"$GODOT" --headless --path "$PROJECT" \
  --export-release "macOS" "builds/macos/Laryen3D.zip" \
  --log-file "artifacts/logs/build-macos.log"

echo "완료: $OUT"
ls -lh "$OUT"/*/*
```

> `set -e` 를 쓰면 export 실패(exit 1) 시 스크립트가 멈춘다. 로그는 `--log-file` 로 받고
> 파이프로 `$?` 를 가리지 않는다.

---

## 10. 자주 막히는 지점

| 증상 | 원인 | 해결 |
|---|---|---|
| `No export template found … windows_debug_x86_64.exe` | debug 모드인데 debug 템플릿이 없다 | 모드에 맞는 파일 설치 (§1) |
| 오류에 debug·release 가 둘 다 뜬다 | **나열일 뿐 둘 다 필수가 아니다** | 쓰는 모드 하나만 있으면 된다 |
| `Preset "Windows" not found` | preset 이름 불일치 | `export_presets.cfg` 의 `name=` 과 정확히 일치. `"Windows Desktop"` |
| 출력 파일이 안 생김 | 출력 디렉터리 없음 | `mkdir -p` 먼저 |
| macOS `.app` 이 "손상되었습니다" | 서명·공증 없음 | `xattr -dr com.apple.quarantine` (본인 빌드) 또는 공증 |
| Linux 바이너리가 실행 안 됨 | 실행 권한 없음 | `chmod +x` |
| Windows 에서 `print()` 가 안 보임 | 콘솔 없는 `.exe` 실행 | `Laryen3D.console.exe` 사용 |
| 빌드 용량이 계속 커짐 | `exclude_filter` 에 `builds/*` 없음 | 산출물 폴더를 제외 |
| `.exe` 만 복사했더니 실행 안 됨 | `embed_pck=false` 라 `.pck` 가 따로 있다 | 둘 다 배포하거나 `embed_pck=true` |
| macOS 에서 만든 `.exe` 가 Windows 에서 문제 | 크로스 빌드는 동작을 보장하지 않는다 | Windows PC 에서 검증 |

---

## 관련 문서

- [export-build.md](export-build.md) — 템플릿 개념, 필요 파일 판정표, CLI 전체
- [export-build-android.md](export-build-android.md) — Android
- [export-build-ios.md](export-build-ios.md) — iOS
- [performance-mobile.md](performance-mobile.md) — 최적화, 기능 태그 오버라이드
- [project-config.md](project-config.md) — `project.godot` 포맷, CI 예시
