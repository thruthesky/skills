# 빌드와 내보내기 — export template · CLI · 플랫폼 공통

Godot 에서 프로젝트를 **실행 가능한 앱으로 만드는** 모든 절차를 다룬다.
플랫폼별 상세는 §8 의 서브 문서로 갈라진다.

> 이 문서의 판정표(§2)와 오류 해석(§5)은 **Godot 4.7.2.stable 로 직접 실측해 확정한 것**이다.
> 공식 문서에도 명시되지 않은 동작이 포함돼 있으므로 추측으로 고쳐 쓰지 말 것.
> 실측 근거: `.cowork/export-template-necessity/final-report.md`

## 목차

1. [핵심 개념 — export 와 실행은 다르다](#1-핵심-개념--export-와-실행은-다르다)
2. [작업별 최소 필요 템플릿 파일 (실측 확정)](#2-작업별-최소-필요-템플릿-파일-실측-확정)
3. [export template 설치](#3-export-template-설치)
4. [CLI 명령 전체](#4-cli-명령-전체)
5. [실패 진단 — 오류 메시지 읽는 법](#5-실패-진단--오류-메시지-읽는-법)
6. [export_presets.cfg 포맷](#6-export_presetscfg-포맷)
7. [패치 배포와 델타 인코딩 (Patch PCK)](#7-패치-배포와-델타-인코딩-patch-pck)
8. [이 프로젝트의 작업 규칙](#8-이-프로젝트의-작업-규칙)
9. [플랫폼별 상세 문서](#9-플랫폼별-상세-문서)

---

## 1. 핵심 개념 — export 와 실행은 다르다

**export template 은 "미리 컴파일된 Godot 엔진 실행 파일"이다.** 게임이 아니다.
Godot 은 이 빈 껍데기에 게임 데이터(PCK)를 붙여 최종 앱을 만든다.

```text
android_debug.apk (엔진만 든 빈 APK)  +  게임 PCK  +  앱 설정·서명
        ↓ Godot 이 합침
Laryen3D-debug.apk  ← 기기에 설치하는 것
```

따라서 **`android_release.apk` 는 남의 게임이 아니라 재료다.** 절대 그 자체를 설치하지 않는다.

### 실행에는 템플릿이 필요 없다 (실측)

개발 중 반복하는 루프는 템플릿 **0개**로 돌아간다. 에디터 바이너리 자체가 엔진이기 때문이다.

| 하는 일 | 템플릿 | 실측 결과 |
|---|---|---|
| `godot --path .` 데스크톱 창 실행 | 불필요 | exit 0 |
| `godot --headless --path . --quit-after 2` 검사 | 불필요 | exit 0 |
| `--export-pack` (PCK/ZIP 만 생성) | **불필요** | exit 0, `.pck` 생성 확인 |
| `--export-debug` / `--export-release` | **필요** | 없으면 exit 1 |

**설계 의도**: 코드가 도는지 확인하는 데 수 GB 다운로드를 요구하지 않는다.
템플릿은 "배포 가능한 패키지를 만들 때" 처음 필요해진다.

---

## 2. 작업별 최소 필요 템플릿 파일 (실측 확정)

**필요한 것은 "지금 export 하는 플랫폼의, 지금 쓰는 모드 파일"뿐이다.**
Android APK 를 만들 때 `ios.zip`·`macos.zip`·`windows*.exe` 는 **한 번도 열리지 않는다.**

설치 경로 (버전 폴더명은 `4.7.2.stable` 처럼 엔진 버전과 **정확히** 일치해야 한다):

| OS | 경로 |
|---|---|
| macOS | `~/Library/Application Support/Godot/export_templates/4.7.2.stable/` |
| Linux | `~/.local/share/godot/export_templates/4.7.2.stable/` |
| Windows | `%APPDATA%\Godot\export_templates\4.7.2.stable\` |

### 판정표

| 작업 | 실제로 필요한 파일 |
|---|---|
| **Android 테스트 APK** (`--export-debug`, gradle off) | `android_debug.apk` |
| Android 릴리즈 APK (`--export-release`, gradle off) | `android_release.apk` |
| **Android Gradle 빌드** (`use_gradle_build=true`, APK/AAB 무관) | `android_source.zip` **만** |
| iOS Xcode 프로젝트 | `ios.zip` |
| macOS `.app`/`.zip` | `macos.zip` |
| Windows debug `.exe` | `windows_debug_x86_64.exe` |
| Windows release `.exe` | `windows_release_x86_64.exe` |
| Linux debug / release | `linux_debug.x86_64` / `linux_release.x86_64` |
| PCK·ZIP 패치 (`--export-pack`) | **없음** |

### 반드시 알아야 할 두 가지 함정

**함정 1 — 오류 목록 ≠ 필수 목록.**
템플릿이 하나도 없을 때 `--export-debug "Android"` 를 돌리면 오류가
`android_debug.apk` **와** `android_release.apk` 를 **둘 다** 나열한다. 이걸 "둘 다 필수"로
읽으면 안 된다. 실측하면 `android_debug.apk` **하나만** 놓아도 템플릿 오류가 **전부 사라진다.**
Godot 은 *없는 파일을 전부 나열할 뿐*이다.

Windows 로 확증했다 — `windows_debug_x86_64.exe` 하나만 두고 `--export-debug` 를 돌리자
**실제로 완주**해 `.exe` 와 `.pck` 를 만들어냈다.

**함정 2 — Android 검증은 `debug ‖ release` 다.**
Android 는 둘 중 **아무거나 하나**만 있으면 설정 검증을 통과한다. `android_release.apk` 만
두고 `--export-debug` 를 돌려도 템플릿 오류가 나지 않는다. 다만 실제 패키징 단계에서는
모드에 맞는 파일을 쓰므로, **테스트 APK 를 만들려면 `android_debug.apk` 를 갖춰야 한다.**

**함정 3 — `use_gradle_build` 가 요구 파일을 통째로 바꾼다.**
같은 preset 에서 이 값만 `true` 로 바꾸면 요구 파일이
`android_debug/release.apk` → `android_source.zip` 으로 **완전히 갈린다**(실측).
판정 축은 "APK냐 AAB냐"가 **아니라** 이 값 하나다.

---

## 3. export template 설치

### 방법 A — 에디터 (권장, 4.7 신기능)

`Editor > Manage Export Templates` → 버전 `4.7.2.stable` 선택 →
**필요한 플랫폼·아키텍처만 체크** → `Install Selected Templates`

공식 문서가 전체 TPZ 에 대해 못 박은 문장:

> *"There is no inherent advantage to using the TPZ file for all platforms… it will take up
> more space compared to only selecting what you need."*

라리엔 3D 타깃은 Android + Steam(Windows) 이므로 **Android + Windows 만** 받으면 된다.

> ⚠️ **ICU Data 항목을 함께 확인할 것.** 선택 설치 목록에 ICU Data 가 있고 공식 문서가
> 한국어를 ICU 필요 언어로 든다. 라리엔은 전 UI 가 한글이므로 **ICU 를 빼면 글자가 깨질 수
> 있다.** (미검증 — 에디터에서 실물 확인 필요)

### 방법 B — CLI (에디터를 못 쓸 때)

**CLI 로 개별 플랫폼 파일만 받는 공식 절차는 4.7 에 없다.** 선택 설치는 에디터 UI 기능이다.
따라서 CLI 에서는 전체 TPZ 를 받는다 — **받는 파일이 많을 뿐, 쓰는 파일은 §2 표대로 하나다.**

```bash
GODOT_TEMPLATE_VERSION="4.7.2.stable"
GODOT_TEMPLATE_WORK_DIR="$(mktemp -d)"
GODOT_TEMPLATE_INSTALL_DIR="$HOME/Library/Application Support/Godot/export_templates/$GODOT_TEMPLATE_VERSION"

curl -fL \
  'https://downloads.godotengine.org/?flavor=stable&platform=templates&slug=export_templates.tpz&version=4.7.2' \
  -o "$GODOT_TEMPLATE_WORK_DIR/export_templates.tpz"

mkdir -p "$GODOT_TEMPLATE_WORK_DIR/unpacked"
ditto -x -k "$GODOT_TEMPLATE_WORK_DIR/export_templates.tpz" "$GODOT_TEMPLATE_WORK_DIR/unpacked"

mkdir -p "$GODOT_TEMPLATE_INSTALL_DIR"
cp -R "$GODOT_TEMPLATE_WORK_DIR/unpacked/templates/." "$GODOT_TEMPLATE_INSTALL_DIR/"
```

**버전은 엔진과 정확히 같아야 한다.** 확인:

```bash
godot --version        # 예: 4.7.2.stable.official.ed1daf0bf
ls "$HOME/Library/Application Support/Godot/export_templates/"
```

엔진을 4.7.3 으로 올리면 템플릿도 다시 받아야 한다.

### 설치 확인은 "쓸 파일만"

6개 파일을 전부 `ls` 하지 않는다. **지금 만들 것 하나만** 확인한다.

```bash
T="$HOME/Library/Application Support/Godot/export_templates/4.7.2.stable"
ls -lh "$T/android_debug.apk"     # Android 테스트 APK 를 만들 때
```

`No such file or directory` 는 프로젝트 오류가 아니라 **그 템플릿이 아직 없다**는 뜻이다.
`export_templates/` 디렉터리 자체가 없는 것도 정상 초기 상태다.

---

## 4. CLI 명령 전체

**`godot` 는 반드시 에디터 바이너리여야 한다.** export template 바이너리로는 export 할 수 없다
(`--export-*` 는 에디터 빌드 전용 플래그다).

| 명령 | 하는 일 | 템플릿 |
|---|---|---|
| `--export-release <preset> <path>` | 릴리즈 모드로 export | 필요 |
| `--export-debug <preset> <path>` | 디버그 모드로 export (원격 디버그·로그 활성) | 필요 |
| `--export-pack <preset> <path>` | **게임 데이터만** PCK/ZIP 으로 | **불필요** |
| `--export-patch <preset> <path>` | 변경 파일만 담은 패치 팩 (`--patches` 와 함께) | 불필요 |
| `--install-android-build-template` | Gradle 프로젝트를 `res://android/build/` 에 설치. `--export-*` 와 **함께** 쓴다 | `android_source.zip` |

### 공통 규칙

```bash
godot --headless --path ./app \
  --export-debug "Android" builds/android/Laryen3D-debug.apk \
  --log-file artifacts/logs/build-android-debug.log
echo "EXIT=$?"
```

- **`<path>` 는 `--path` 로 지정한 프로젝트 기준 상대경로**다. 위 예시의 실제 출력은
  `./app/builds/android/Laryen3D-debug.apk`.
- **출력 디렉터리는 미리 존재해야 한다.** `mkdir -p` 를 먼저 돌린다.
- **preset 이름은 `export_presets.cfg` 의 `name=` 과 정확히 일치**해야 한다.
  `"Windows Desktop"` 처럼 공백이 있으면 따옴표 필수.
- **첫 실행은 `--import` 를 먼저 돌린다.** 임포트 캐시가 없으면 리소스가 빠질 수 있다.
  ```bash
  godot --headless --path ./app --import --quit || true   # 첫 임포트는 에러 코드를 낼 수 있다
  ```
- **종료 코드로 판정한다.** export 실패 시 **exit 1**(실측 확인). 파이프(`| tail`)로 감싸면
  `$?` 가 파이프 끝 명령의 코드가 되므로 판정이 망가진다 — 로그는 리다이렉트로 받는다.

---

## 5. 실패 진단 — 오류 메시지 읽는 법

```text
ERROR: Cannot export project with preset "Android" due to configuration errors:
No export template found at the expected path:
/Users/.../export_templates/4.7.2.stable/android_debug.apk
No export template found at the expected path:
/Users/.../export_templates/4.7.2.stable/android_release.apk
A valid Java SDK path is required in Editor Settings.
```

| 메시지 | 원인 | 해결 |
|---|---|---|
| `No export template found at the expected path` | 그 경로에 파일이 없음. **나열된 전부가 필수인 것은 아니다**(§2 함정 1) | §2 표의 해당 파일만 설치 |
| `A valid Java SDK path is required in Editor Settings.` | `export/android/java_sdk_path` 가 비어 있음 | 🧑 `Editor Settings > Export > Android > Java SDK Path` 에 JDK 17 경로 |
| `Android build template not installed in the project.` | `use_gradle_build=true` 인데 `res://android/build/` 없음 | `--install-android-build-template` 을 `--export-*` 와 함께 |
| `Cannot export project with preset "iOS" due to configuration errors:` **(메시지 본문이 빔)** | iOS 는 헤드리스에서 오류 본문이 비어 나오는 경우가 있다(실측) | 아이콘·Team ID·bundle identifier 를 에디터에서 점검 |
| 종료 코드 0 인데 파일이 없음 | 파이프로 `$?` 가 가려짐 | 리다이렉트로 로그를 받고 `$?` 를 직접 확인 |

버전 불일치 확인:

```bash
godot --version
ls "$HOME/Library/Application Support/Godot/export_templates"
```

---

## 6. export_presets.cfg 포맷

프로젝트 루트에 두는 텍스트 파일이다. `[preset.N]` 과 `[preset.N.options]` 가 한 쌍이며
N 은 0 부터 순서대로다.

```ini
[preset.0]

name="Android"                          ; --export-* 에 적을 이름과 정확히 일치
platform="Android"                      ; Android / iOS / macOS / Windows Desktop / Linux
runnable=true                           ; 에디터 원클릭 배포 대상으로 삼음
advanced_options=false
dedicated_server=false
custom_features=""
export_filter="all_resources"
include_filter=""
exclude_filter="artifacts/*, builds/*"  ; 빌드 산출물이 자기 자신에 들어가지 않게
export_path="builds/android/Laryen3D.apk"
patches=PackedStringArray()

[preset.0.options]

gradle_build/use_gradle_build=false     ; ← 요구 템플릿을 가르는 값 (§2 함정 3)
architectures/arm64-v8a=true
package/unique_name="com.회사명.laryen3d"
version/code=1
version/name="1.0.0"
```

`platform` 문자열과 `--export-*` 인자의 대응:

| `--export-release` 인자 | `platform=` |
|---|---|
| `"Android"` | `Android` |
| `"iOS"` | `iOS` |
| `"macOS"` | `macOS` |
| `"Windows Desktop"` | `Windows Desktop` |
| `"Linux"` | `Linux` |

**필요한 플랫폼의 preset 만 있으면 된다.** 4개를 전부 적을 의무는 없다.

---

## 7. 패치 배포와 델타 인코딩 (Patch PCK)

게임을 자주 업데이트한다면 매번 전체 빌드를 내려받게 하지 않는다.
**바뀐 리소스만 담은 패치 PCK**를 만들어 배포하면 다운로드 용량이 크게 줄어든다.
라리엔처럼 라이브 운영하며 밸런스·텍스트·에셋을 자주 고치는 게임에 직접적인 이득이다.

### 델타 인코딩 — 4.6에서 추가된 핵심

패치 PCK 자체는 이전부터 있었지만, **바뀐 파일은 통째로** 들어갔다.
4.6부터 **델타 인코딩**을 지원해 파일 전체가 아니라 **이전 파일과의 차이만** 담는다.

에디터 설명 원문: *"If checked, any change to a file already present in the base packs
will be exported as the difference between the old file and the new file."*

큰 에셋의 일부만 고쳤을 때, 또는 번역 파일에 언어 한 줄을 추가했을 때
패치 크기가 극적으로 줄어든다.

### 에디터 설정 — Patching 탭

경로: `Project > Export... > 프리셋 선택 > Patching` 탭

| 항목 | 의미 |
|---|---|
| `Base Packs` | **기준이 되는 팩 목록.** 여기 담긴 리소스는 패치에서 제외된다 |
| `Export As Patch` | 켜면 변경분만 내보낸다 |
| `Enable Delta Encoding` | 파일 전체 대신 **차이만** 담는다 |
| `Delta Encoding Compression Level` | 압축 레벨. 기본 `19`(권장 최대). 높일수록 내보내기가 느려진다 |
| `Delta Encoding Minimum Size Reduction` | 이 비율만큼 줄지 않으면 델타를 **포기하고 파일 통째로** 넣는다 |
| `Delta Encoding Include Filters` / `Exclude Filters` | 델타를 적용할/제외할 파일 패턴 |

내보내기 로그에 파일별 결과가 찍힌다. 델타가 실제로 먹었는지 여기서 확인한다.

```
Used delta encoding for patch of "res://...", resulting in a patch of N bytes,
which reduced the size by 87.3% (M bytes) compared to the actual file.

Skipped delta encoding for patch of "res://...", as it resulted in a patch of N bytes,
which only reduced the size by 2.1% (M bytes) compared to the actual file.
```

### CLI로 패치 내보내기

```bash
# 1) 원본 릴리스 팩 (v1.0)
godot --headless --path . --export-pack "Android" build/v1.0/game.pck

# 2) 코드·에셋 수정 후, v1.0 을 기준으로 패치 생성
godot --headless --path . \
  --patches build/v1.0/game.pck \
  --export-patch "Android" build/v1.1/patch1.pck

# 3) 다음 패치는 원본과 이전 패치를 모두 기준으로 삼는다 (콤마 구분, 순서 중요)
godot --headless --path . \
  --patches build/v1.0/game.pck,build/v1.1/patch1.pck \
  --export-patch "Android" build/v1.2/patch2.pck
```

| 옵션 | 의미 |
|---|---|
| `--export-patch <프리셋> <경로>` | 변경된 파일만 담은 팩을 내보낸다 |
| `--patches <경로들>` | 기준 팩 목록. **콤마로 구분**하며 순서가 의미를 갖는다 |

`patch1.pck`를 기준에 넣었기 때문에 `patch2.pck`에는 patch1에 이미 들어간 리소스가
중복되지 않는다.

### 런타임에서 패치 로드

```gdscript
# 실행 중에 패치를 얹는다. 같은 경로의 리소스가 교체된다
var ok := ProjectSettings.load_resource_pack("user://patches/patch1.pck")
if not ok:
    push_error("패치 로드 실패")
```

`load_resource_pack(pack: String, replace_files: bool = true, offset: int = 0)`

- `replace_files`가 `true`(기본)면 **같은 경로의 기존 리소스를 덮어쓴다.**
  `false`를 주면 기존 파일이 우선이라 패치가 적용되지 않는다.
- 이미 로드된 리소스는 교체되지 않는다. **패치는 해당 씬을 열기 전에** 얹는다.

```gdscript
# 부팅 시 패치를 순서대로 전부 얹는 예
func _apply_patches() -> void:
    var dir := DirAccess.open("user://patches")
    if dir == null:
        return
    var files := dir.get_files()
    files.sort()                                   # patch1, patch2, ... 순서 보장
    for f in files:
        if f.ends_with(".pck"):
            ProjectSettings.load_resource_pack("user://patches/".path_join(f))
```

### 반드시 지켜야 할 규칙

**1. `Base Packs` 목록 = 런타임 로드 목록 (파일도 순서도 동일해야 한다)**

델타 인코딩은 "이전 파일이 정확히 무엇인지"를 전제로 차이를 계산한다.
내보낼 때 기준으로 삼은 팩과 게임이 실제로 로드하는 팩이 **같은 파일, 같은 순서**가
아니면 복원이 깨진다. 이것이 가장 중요한 제약이다.

**2. 패치가 쌓이면 로드 시간이 누적된다**

패치를 겹칠수록 델타 복원 비용이 더해진다. 패치가 여러 개 쌓이면
전체 팩을 새로 배포해 기준을 리셋하는 편이 낫다.

**3. 예전 버전을 다시 내보내 기준으로 쓰지 않는다**

Godot의 내보내기 과정은 완전히 결정론적이지 않다. 같은 소스로 다시 내보내도
바이트가 미세하게 달라질 수 있어 델타가 어긋난다.
**릴리스한 PCK 파일 자체를 보관**했다가 그것을 기준으로 쓴다.

```
build/
├─ v1.0/game.pck      ← 보관 필수. 재생성하지 않는다
├─ v1.1/patch1.pck    ← 보관 필수
└─ v1.2/patch2.pck
```

**4. 스토어 배포와는 별개다**

Play 스토어·Steam은 자체 차등 업데이트를 제공한다. 패치 PCK는 스토어를 거치지 않고
**게임이 직접 내려받아 얹는** 경우(핫픽스, 이벤트 데이터)에 값어치가 있다.
Android는 실행 파일을 교체할 수 없으므로 **PCK로 배포 가능한 것은 리소스와 스크립트뿐**이다.
엔진 버전이나 네이티브 플러그인이 바뀌면 스토어 업데이트가 필요하다.

---

## 8. 이 프로젝트의 작업 규칙

`CLAUDE.md` 상 **Claude 가 고칠 수 있는 것은 소스코드와 문서뿐**이다.
빌드 관련 파일 대부분이 Claude 수정 금지 대상이다.

| 대상 | 누가 |
|---|---|
| `export_presets.cfg` | 🧑 **사람** — Claude 는 최종 텍스트를 제시만 하고 파일을 만들지 않는다 |
| `editor_settings-4.7.tres` (SDK·JDK·keystore 경로) | 🧑 **사람** — 에디터 UI 에서 |
| `project.godot` | 🧑 **사람** |
| 빌드 셸 스크립트 · 이 문서 | ✅ Claude |
| keystore 생성·비밀번호 | 🧑 **사람** — 분실 시 앱 업데이트 불가 |

Claude 가 설정 변경이 필요하다고 판단하면 **에디터 UI 경로와 최종 값**을 알려주고 멈춘다.

---

## 9. 플랫폼별 상세 문서

### Android → [export-build-android.md](export-build-android.md)

Android 테스트 APK 를 만들어 실기기에 설치·실행하고 Play 스토어용 릴리즈까지 내보내는
전 과정을 다룬다. 사전 준비(JDK 17·Android SDK·에디터 경로 설정)부터 시작해,
`--export-debug` 로 debug APK 를 만들고 `adb install -r` 로 설치한 뒤 `adb logcat -s godot`
으로 로그를 보는 반복 루프를 설명한다. **debug keystore 는 Godot 이 자동 생성하므로
`keytool` 이 불필요**하다는 점, 다른 키로 서명된 동명 패키지가 있으면 설치가 실패하므로
`adb uninstall` 이 필요하다는 함정을 포함한다. 릴리즈에서는 keystore 생성,
`GODOT_ANDROID_KEYSTORE_*` 환경변수로 비밀번호를 넘기는 방법, `use_gradle_build` 와
`export_format` 조합으로 APK/AAB 를 가르는 규칙, `--install-android-build-template` 을 쓰는
Gradle(GABE) 경로, 권한 최소화, 네이티브 스플래시와 부트 스플래시의 이중 구조를 다룬다.

### iOS → [export-build-ios.md](export-build-ios.md)

iOS 는 Godot 이 `.ipa` 를 직접 완성하지 않고 **Xcode 프로젝트를 담은 `.zip` 을 내보내면
Xcode 가 서명·아카이브·배포를 맡는** 2단계 구조라는 점을 먼저 세운다. macOS 에서만 빌드
가능하며 `ios.zip` 템플릿·Xcode·Apple Team ID·프로비저닝 프로파일이 필요하다.
`application/export_project_only` 값에 따라 산출물이 Xcode 프로젝트인지 빌드 결과인지
갈리는 규칙, `xcodebuild` 로 시뮬레이터·실기기에 올리는 명령, `ios-deploy`/Xcode Devices 로
설치하고 Console.app 으로 로그를 보는 절차를 다룬다. 헤드리스에서 **설정 오류 메시지가 빈
문자열로 나오는 실측 현상**과 그때 점검할 항목(아이콘·Team ID·bundle identifier), TestFlight
배포 흐름을 포함한다.

### macOS · Windows · Linux (Steam) → [export-build-desktop.md](export-build-desktop.md)

데스크톱 3종의 테스트 실행과 Steam 배포용 릴리즈를 다룬다. macOS 는 `macos.zip` 하나만
필요하고 `.app`/`.zip`/`.dmg` 를 고를 수 있으며, 배포하려면 Apple 서명과 공증(notarization)
이 필요하다는 점, 서명 없는 빌드를 로컬에서 열 때 Gatekeeper 를 통과시키는
`xattr -dr com.apple.quarantine` 를 설명한다. Windows 는 **debug 와 release 가 서로 다른
템플릿 파일을 쓰므로 모드에 맞는 것을 설치해야 한다**는 실측 규칙과 macOS 에서 크로스
빌드가 가능하다는 점, `Embed PCK` 로 단일 실행 파일을 만드는 옵션을 다룬다. Linux 는
`linux_debug.x86_64`/`linux_release.x86_64` 를 쓰며 Steam Deck 대응과 실행 권한 부여를
포함한다. 세 플랫폼 공통 빌드 스크립트와 렌더러 선택(d3d12·Mobile)도 여기 있다.

---

## 관련 문서

- [performance-mobile.md](performance-mobile.md) — 모바일 최적화, 기기 등급 감지, 기능 태그 오버라이드
- [project-config.md](project-config.md) — `project.godot` 포맷, CLI 전체 옵션, CI 예시
- [whats-new.md](whats-new.md) — 선택적 템플릿 다운로드, GABE 등 4.7 신기능
- `docs/godot/에디터 없이 작업.md` — 에디터 없이 프로젝트를 처음부터 만드는 학습 문서.
  §13 이 4개 플랫폼의 테스트 빌드 → 설치 → 확인 → 릴리즈를 `./app` 예제로 처음부터 따라가므로,
  **절차를 단계별로 밟아 보고 싶을 때** 참고한다. 템플릿 판정은 이 문서 §2 와 같은 실측
  결과로 맞춰져 있다. 이 문서는 라리엔 3D 기준 규범이고 그쪽은 일반 학습용이므로,
  **어긋나면 이 문서가 맞다.**
