# 최신 버전 신기능과 마이그레이션

**최신 Godot에서 새로 쓸 수 있게 된 것**을 영역별로 모은 문서다.
기능마다 **어느 버전에서 들어왔는지** 표기하므로, 쓰기 전에 대상 버전을 확인한다.

현재 정리 범위:

| 버전 | 비고 |
|---|---|
| **4.7** (코드네임 *"Lights, Camera, Action!"*) | 이 문서의 1~10장. 패치 4.7.1·4.7.2는 유지보수 릴리스이며 새 기능은 4.7-stable에서 도입 |
| **4.6** | 11장 — 4.7 릴리스 노트만 보면 놓치기 쉬운 것 |
| **4.5** | 스텐실 버퍼 등. 해당 주제 문서에 표기 |

> 새 버전이 나오면 이 문서에 장을 추가하고, 상세는 각 주제 문서에 반영한다.
> 문서 본문의 `(4.5+)`, `(4.6 신규)`, `(4.7 신규)` 표기가 도입 버전을 뜻한다.

## 목차

1. [3D 렌더링](#1-3d-렌더링)
2. [물리](#2-물리)
3. [애니메이션](#3-애니메이션)
4. [GUI와 UI](#4-gui와-ui)
5. [에디터](#5-에디터)
6. [스크립팅](#6-스크립팅)
7. [Android와 모바일](#7-android와-모바일)
8. [XR](#8-xr)
9. [입력](#9-입력)
10. [내보내기와 에셋](#10-내보내기와-에셋)
11. [4.6에서 들어온 것 중 놓치기 쉬운 것](#11-46에서-들어온-것-중-놓치기-쉬운-것)
12. [이 프로젝트에 당장 쓸 수 있는 것](#12-이-프로젝트에-당장-쓸-수-있는-것)
13. [마이그레이션 체크리스트](#13-마이그레이션-체크리스트)

---

## 1. 3D 렌더링

### AreaLight3D — 직사각형 면 광원 (신규 노드)

3D 공간의 사각형에서 나오는 빛을 실시간으로 렌더링한다.
이전에는 발광 머티리얼 + 전역 조명(GI)을 조합해 흉내내야 했다.

```gdscript
var area_light := AreaLight3D.new()
area_light.size = Vector2(2.0, 1.2)      # 사각형 크기
area_light.two_sided = false
area_light.light_energy = 3.0
area_light.light_color = Color(0.7, 0.85, 1.0)
add_child(area_light)
```

**용도**: TV 화면, 광고판, 창문에서 들어오는 부드러운 빛, 스튜디오 조명.

**비용**: **가장 비싼 실시간 광원 타입이다.** Mobile 렌더러에서 동작하지만
소수만 쓴다. 정적인 것은 `LightmapGI`로 굽는 편이 낫다.

### SSR(화면공간 반사) 대개편

화면공간 반사가 전면 재작성되었다. 거칠기 처리가 정확해져 금속·물·유리가 훨씬
사실적이고, 시간에 따른 깜빡임이 줄고, 속도도 빨라졌다. 해상도를 고를 수 있어
**절반 해상도로도 쓸 만한 품질**이 나온다.

```gdscript
env.ssr_enabled = true          # 기본 false
env.ssr_max_steps = 64          # 32~512
env.ssr_fade_in = 0.15
env.ssr_fade_out = 2.0
env.ssr_depth_tolerance = 0.5
```

해상도는 프로젝트 설정이다: `rendering/environment/screen_space_reflection/half_size`
(기본 `true` = 절반 해상도).

> **이 프로젝트에서는 쓸 수 없다 — SSR은 Forward+ 전용이다.**
> Mobile 렌더러에서는 켜도 아무 일도 일어나지 않는다. 반사는 `ReflectionProbe`로
> 얻는다. → [rendering-3d.md](rendering-3d.md)

### HDR 출력

Windows, macOS, iOS, visionOS, Linux(Wayland)에서 HDR 디스플레이로 출력한다.
극도로 밝은 하이라이트와 넓은 색역을 표현할 수 있다.

```ini
[display]

window/hdr/enabled=true
```

SDR 디스플레이에서는 자동으로 톤매핑되므로 켜두어도 문제없다.

### Clearcoat 개선

Disney PBR 모델에 더 가까워졌다. 자동차 도장, 래커 칠한 나무,
코팅된 플라스틱의 표현이 향상되었다.

```gdscript
var mat := StandardMaterial3D.new()
mat.clearcoat = 1.0
mat.clearcoat_roughness = 0.05
```

### 파티클 3D 스케일·회전

`ParticleProcessMaterial`에 **축별 스케일(스트레치·스쿼시)과 진짜 3D 회전**이
추가되었다. 이전에는 균등 스케일(float)과 화면을 향한 평면 회전만 가능했다.

```gdscript
var mat := ParticleProcessMaterial.new()
mat.use_scale_3d = true                                   # 기본 false — 켜야 적용된다
mat.scale_3d_min = Vector3(0.6, 1.8, 0.6)                 # 세로로 늘어난 불꽃
mat.scale_3d_max = Vector3(1.0, 2.6, 1.0)

mat.use_rotation_3d = true                                # 기본 false
mat.rotation_3d_max = Vector3(TAU, TAU, TAU)              # 3축 랜덤 초기 회전

mat.use_rotation_velocity_3d = true                       # 기본 false
mat.rotation_velocity_3d_min = Vector3(-6, -6, -6)        # 라디안/초
mat.rotation_velocity_3d_max = Vector3( 6,  6,  6)
```

**`use_*` 플래그 3개가 모두 기본 `false`다.** 켜지 않으면 Vector3 값이 무시된다.
빌보드(`QuadMesh`)에서는 3D 회전이 잘 안 보이므로 **입체 메시일 때** 값어치가 나온다.
파편, 잔해 표현에 쓴다. → [rendering-3d.md](rendering-3d.md)의 파티클 섹션

### 포비티드 렌더링 최적화

Vulkan Mobile 렌더러의 포비티드 렌더링 성능이 대폭 향상되었다.
렌더링된 타일을 축소 해상도로 저장하고 샘플링 시 보간하는 방식으로 바뀌었다.
Vulkan 서브샘플 이미지를 활용한다.

VR/XR 프로젝트에 직접적인 성능 이득이 있다.

---

## 2. 물리

### Jolt Physics가 기본 물리 엔진이 되었다

4.4에서 **실험적 옵션**으로 들어왔던 Jolt가 4.7에서 실험 딱지를 떼고
**새 3D 프로젝트의 기본 물리 엔진**이 되었다.

**기존 프로젝트는 자동으로 바뀌지 않는다.** 4.7로 올려도 `project.godot`의
물리 엔진 설정이 그대로 유지된다.

```ini
[physics]

3d/physics_engine="Jolt Physics"    ; DEFAULT / Jolt Physics / GodotPhysics3D / Dummy
```

> **이 프로젝트는 이미 `"Jolt Physics"`로 명시되어 있다.** 확인만 하고 바꾸지 않는다.
> Jolt 고유 동작(조인트 소프트 리미트 미지원, 접촉 임펄스가 추정치, `face_index`
> 기본 `-1` 등)과 `physics/jolt_physics_3d/*` 설정 전체는
> → [physics-3d.md](physics-3d.md)의 "Jolt 고유 사항"

### 방향 기반 일방향 충돌

`CollisionShape2D`의 일방향 충돌이 로컬 방향 기준으로 동작하게 바뀌어,
**모든 방향으로 일방향 충돌을 설정할 수 있다.** 이전에는 위/아래만 가능했다.

3D에서도 관련 개선이 있었으나 주 대상은 2D다.

### Path3D 콜라이더 스냅

3D 에디터에서 Path3D의 점을 배치할 때, 기본 카메라 평면 대신
**콜라이더 표면에 스냅**할 수 있는 옵션이 추가되었다.

지형을 따라가는 순찰 경로, 레일, 카메라 경로를 만들 때 훨씬 정확하다.

---

## 3. 애니메이션

### Tween.tween_await()

트윈 시퀀스 중간에 시그널을 기다린다.
이전에는 `tween_callback` + 별도 코루틴으로 우회해야 했다.

```gdscript
func play_cutscene() -> void:
    var tween := create_tween()
    tween.tween_property(camera, "position", target_pos, 1.2)
    tween.tween_await(dialogue_box.finished)      # 대사가 끝날 때까지 대기
    tween.tween_property(camera, "position", next_pos, 0.8)
    tween.tween_await(animation_player.animation_finished)
    tween.tween_callback(_end_cutscene)
```

컷신·연출 시퀀스를 하나의 트윈 체인으로 표현할 수 있게 되었다.

### AnimationPlayer 트랙 집계

여러 노드를 추적하는 애니메이션에서 불필요한 노드를 접으면
**집계된 형태로 표시**된다. 수십 개 본을 다루는 캐릭터 애니메이션의
트랙 목록을 훨씬 읽기 쉬워졌다.

---

## 4. GUI와 UI

### Control 오프셋 변환

마우스 입력 판정에 영향을 주지 않는 **순수 시각적 변환**을 적용할 수 있다.

버튼을 흔들거나 살짝 밀어내는 연출을 하면서도 클릭 영역은 원위치에 유지된다.
이전에는 시각 효과와 입력 판정이 함께 움직여 조작이 어긋났다.

### DrawableTexture2D (신규)

텍스처에 직접 그리는 API가 대폭 단순화되었다.
이전의 `Image` + `ImageTexture` 조합보다 훨씬 간단하다.

미니맵, 페인팅, 절차적 텍스처, 안개 효과(fog of war)에 쓴다.

### GradientTexture2D 원뿔형 그래디언트

CSS의 conic-gradient에 해당하는 원뿔형 그래디언트를 만들 수 있다.
원형 진행도 표시, 쿨다운 UI, 방사형 효과에 쓴다.

### RichTextLabel 이미지 스케일 — `em` 단위

이미지 크기를 **폰트 크기에 상대적으로** 지정할 수 있다. 이전에는 픽셀로 박아야 해서
폰트 크기를 바꾸면 아이콘만 그대로 남아 어긋났다.

```
[font_size=40]골드: [img height=1em]res://ui/icons/gold.png[/img] 1,250[/font_size]
```

`1em` = 주변 폰트 크기와 같은 픽셀값. 위에서 아이콘은 40px로 그려지고,
`font_size`를 16으로 바꾸면 아이콘도 16px가 된다. **손댈 곳이 한 군데로 줄어든다.**

단위는 3종이다 — 숫자만(픽셀), `em`(폰트 크기 기준), `%`(**Control의 폭** 기준).
`em`과 `%`는 **BBCode 전용**이라 `add_image()` 같은 코드 API에는 못 쓴다(픽셀만 받는다).
→ [input-ui.md](input-ui.md)의 "RichTextLabel과 BBCode"

### PopupMenu 검색

터치스크린에서 어려웠던 항목 검색이 개선되었다.

---

## 5. 에디터

### 3D 뷰포트

| 기능 | 설명 |
|------|------|
| **정점 스냅** | `B` 키로 메시 정점끼리 정렬 |
| **서브기즈모 정점 스냅** | 서브기즈모 점에도 정점 스냅 적용 |
| **트랙볼 회전** | `U` 키로 진짜 트랙볼처럼 직관적인 3D 회전 |
| **카메라 추종** | `F` 두 번으로 움직이는 오브젝트를 자동 추종 |
| **룰러 축별 길이** | `Shift+드래그`로 각 축의 길이를 동시에 표시 |
| **변형 통합** | 게임 임베딩 시 에디터 단축키·관성 지원 |

### 2D 씬 페인터

`B` 키로 장식물, 적, 수집품을 빠르게 배치한다.

### MeshLibrary 전용 에디터

GridMap용 타일을 편집하는 전용 UI가 추가되었다.
이전에는 씬을 만들어 변환하는 우회 절차가 필요했다.

### CSG Autosmooth

`Autosmooth` 속성으로 각도에 따라 면을 자동으로 부드럽게/각지게 설정한다.
프로토타이핑 결과물의 외형이 훨씬 나아진다.

### 인스펙터

| 기능 | 설명 |
|------|------|
| 복사/붙여넣기 | 카테고리별로 프로퍼티 값을 일괄 관리 |
| Remote Inspector 그룹 접기 | 로컬 인스펙터와 동일한 접기 |
| Remote Tree 열거형 이름 | export하지 않은 enum 변수의 이름 표시 |
| 노드/리소스 생성 필터 | 커스텀 필터로 빠른 검색 |

### 기타

- **텍스트 셰이더 인라인 미리보기** — 셰이더를 입력하는 동안 실시간 결과 확인
- **GDExtension 목록** — 프로젝트 설정에서 로드된 확장 표시
- **모노스페이스 폰트** — 메서드/시그널/프로퍼티 이름을 코드 폰트로 통일
- **스크립트 목록 더블클릭** — 현재 스크립트를 목록에서 표시
- **Project Manager 버전 표시** — 업그레이드/다운그레이드 필요 여부를 아이콘으로
- **가장 가까운 이웃 스케일** — 저해상도 레트로 게임용 필터
- **AtlasTexture 타일링** — TextureRect에서 나인패치 타일링
- **Tree 드래그 앤 드롭** — 재정렬 위치 표시기 개선
- **접근성 랜드마크** — 화면 읽기 도구용 맥락 정보

---

## 6. 스크립팅

4.7 자체의 GDScript 문법 변경은 크지 않다. 4.5에서 들어온 것들이
이제 안정화되었다고 보면 된다.

| 기능 | 도입 |
|------|------|
| `@abstract` 클래스/메서드 | 4.5 |
| 가변 인자 `...args` | 4.5 |
| `match` 패턴 가드 `when` | 4.5 |
| `_static_init()` 정적 생성자 | 4.5 |
| `Dictionary[K, V]` 타입 | 4.4 |
| `@export_tool_button` | 4.4 |
| `@warning_ignore_start/restore` | 4.4 |
| `Tween.tween_await()` | **4.7** |

### GDExtension

프로젝트 설정에서 로드된 GDExtension 목록을 확인할 수 있다.
플러그인 충돌이나 로드 실패를 진단하기 쉬워졌다.

---

## 7. Android와 모바일

### GABE (Gradle Build & Export) 안정화

Gradle 기반 내보내기와 게시가 안정화되었다.
커스텀 빌드, 플러그인 통합, Play 스토어 게시 과정이 개선되었다.

### Picture-in-Picture

Android에서 PiP 창 모드를 지원한다. 미디어 플레이어나 컷신에 활용할 수 있다.

### 커스텀 스플래시

Android 네이티브 스플래시를 **내보내기 프리셋 옵션만으로** 설정한다.
이전에는 Gradle 커스텀 빌드를 켜고 네이티브 리소스 폴더에 파일을 직접 넣어야 했다.

경로: `Project > Export... > Android > Options > Splash Screen`

| 옵션 | 의미 |
|---|---|
| `splash_screen/icon` | 중앙 아이콘 |
| `splash_screen/branding_image` | 하단 브랜딩 이미지 |
| `splash_screen/background_color` | 배경색 |
| `splash_screen/disable_godot_boot_splash` | Godot 부트 스플래시를 끈다 |

**스플래시는 두 종류다.** 네이티브 스플래시(위, 엔진 로딩 전) → Godot 부트
스플래시(`project.godot`의 `boot_splash/*`, 엔진 초기화 후) 순으로 뜬다.
배경색이 다르면 두 번 깜빡이는 것처럼 보인다.
→ [performance-mobile.md](performance-mobile.md)의 Android 내보내기

### Perfetto 추적

성능 분석 기본 도구로 Perfetto가 채택되었다.
Android Studio의 프로파일러와 연동해 상세한 프레임 분석이 가능하다.

### Java 인터페이스 구현

**GDScript에서 Java 인터페이스를 직접 오버라이드할 수 있다.**
Android SDK의 콜백 인터페이스를 별도 플러그인 없이 구현할 수 있게 되었다.

### 에디터 (Android 버전)

- 임베드 게임 윈도우의 이동·크기 조정 — 다양한 화면 비율 테스트
- 스크립트 에디터 가로/세로 회전 — 키보드 공간 확보

---

## 8. XR

- **Android XR 지원** — Google과 협력해 최신 Android XR 기능에 접근
- **Steam Frame 준비** — 해당 플랫폼 지원
- **Vulkan 서브샘플 이미지** — 포비티드 렌더링 성능 대폭 향상
- **구성 레이어 개선** — HUD 고정, 월드 지오메트리 쌍, 플러그인 메인 레이어 제어
- **동작 맵 단순화** — 기본 프로필이 10개 이상에서 4개로 축소
- **Linux Wayland 터치** — 기존 X11 한정이던 터치 지원 확대

---

## 9. 입력

### VirtualJoystick 내장 노드

모바일용 가상 조이스틱이 엔진에 내장되었다. 애드온이 필요 없다.
`Fixed`(고정) / `Dynamic`(터치한 곳에 생성) / `Following`(손가락 추적) 3가지 모드와
StyleBox 테마 4종(`normal_joystick`, `normal_tip`, `pressed_joystick`, `pressed_tip`)을 지원한다.

**출력값을 읽는 API가 없다.** 지정된 InputMap 액션에 강도를 주입하는 방식이라,
게임플레이 코드는 `Input.get_vector()`만 쓰면 조이스틱의 존재를 몰라도 된다.

주의할 기본값 3가지: `action_*`이 `ui_left`/`ui_right`/`ui_up`/`ui_down`(그대로 두면
UI 포커스가 돌아다닌다), `deadzone_ratio = 0.0`(데드존 없음), 그리고 `joystick_size`는
Control 크기와 무관하다(**Control 크기를 안 잡으면 터치가 안 먹는다**).

전체 API·프로퍼티·시그널·함정 → [input-ui.md](input-ui.md)의 "터치와 가상 조이스틱"

### 게임패드 미포커스 무시

OS는 창이 비활성이어도 게임패드 입력을 계속 보낸다. 알트탭 중 패드를 건드려
의도치 않은 입력이 들어가는 것을 막는 설정이 생겼다.

```ini
[input_devices]

joypads/ignore_joypad_on_unfocused_application=true
```

경로: `Project Settings > Input Devices > Joypads > Ignore Joypad On Unfocused Application`
**기본값은 `false`** — 기존 동작 유지를 위해 꺼져 있으므로 직접 켠다.
Steam(PC) 빌드에서 켜는 것이 맞다.

### 키보드·마우스 장치 ID

게임패드처럼 키보드·마우스 입력에도 장치 ID가 부여되어, `InputEvent.device`만으로
장치를 구분할 수 있다.

| 상수 | 값 |
|---|---|
| `InputEvent.DEVICE_ID_EMULATION` | `-1` |
| `InputEvent.DEVICE_ID_KEYBOARD` | `16` |
| `InputEvent.DEVICE_ID_MOUSE` | `32` |
| 게임패드 | `0`부터 연결 순서대로 |

여러 키보드·마우스를 **개별 식별하는 기능은 아직 없다.** 나중에 구현할 기반만
마련한 단계다. 그리고 터치(`InputEventScreenTouch`)도 `device`가 `0`이라
게임패드와 겹치므로 타입 검사를 함께 한다. → [input-ui.md](input-ui.md)

### 컨트롤러

- **iOS SDL3 전환** — 컨트롤러 호환성 대폭 향상
- **자이로·가속도계 입력** 지원

---

## 10. 내보내기와 에셋

### 선택적 템플릿 다운로드

필요한 플랫폼과 아키텍처의 내보내기 템플릿만 골라 받는다.
전체 템플릿은 수 GB에 달하므로 디스크와 시간을 크게 아낀다.

### 새 Asset Store

`https://store.godotengine.org/`

- 폴리시된 항목 표시와 확대
- 평점 표시
- 백그라운드 스레딩으로 반응성 개선

기존 Asset Library를 대체하지만 2026년 8월 현재 아직 **beta** 표시가 있어
화면과 정책이 바뀔 수 있다. 설치 전 4.7.x 호환성, 라이선스, 소스 저장소를 확인한다.

---

## 11. 4.6에서 들어온 것 중 놓치기 쉬운 것

아래는 **4.7이 아니라 4.6** 신기능이다. 4.7 이상에서 그대로 쓸 수 있는데,
4.7 릴리스 노트만 보면 지나치기 쉬워 여기 함께 정리한다.

### 패치 PCK 델타 인코딩

패치 PCK 자체는 이전부터 있었지만 **바뀐 파일은 통째로** 들어갔다. 4.6부터
**이전 파일과의 차이만** 담는 델타 인코딩을 지원해 패치 용량이 크게 줄어든다.
큰 에셋의 일부만 고쳤을 때, 번역 파일에 언어를 추가했을 때 효과가 크다.

```bash
godot --headless --path . \
  --patches build/v1.0/game.pck \
  --export-patch "Android" build/v1.1/patch1.pck
```

에디터: `Project > Export... > Patching` 탭에서 `Base Packs`, `Export As Patch`,
`Enable Delta Encoding`, `Delta Encoding Compression Level`(기본 19) 등을 설정한다.
런타임 적용은 `ProjectSettings.load_resource_pack()`.

**가장 중요한 제약**: `Base Packs`에 나열한 팩은 게임이 런타임에 로드하는
**바로 그 파일이어야 하고 순서도 같아야 한다.** 그리고 예전 버전을 다시 내보내
기준으로 쓰면 안 된다(내보내기가 완전히 결정론적이지 않다) — 릴리스한 PCK를 보관한다.
→ [export-build.md](export-build.md)의 "패치 배포와 델타 인코딩"

### BoneConstraint3D — 본을 다른 본에 묶기

`BoneConstraint3D`와 그 자식인 `AimModifier3D`(겨냥) · `CopyTransformModifier3D`(복사) ·
`ConvertTransformModifier3D`(변환)로 본을 다른 본에 묶을 수 있다. 보조 본 처리와
더 자연스러운 포즈를 코드 없이 노드 설정으로 만든다. VR·메타버스 아바타에 특히 유용하다.
→ [animation-3d.md](animation-3d.md)의 "Skeleton3D와 본 조작"

### SceneTree 3D 물리 보간

4.4에서 `RenderingServer`에 구현되었던 3D 물리 보간이 **`SceneTree`로 이전**되었다.
노드가 `Node3D` 트랜스폼에 의존하는데 `RenderingServer`에 보간 값을 질의할 수 없었던
구조적 문제가 해결되었다. **사용자 API는 그대로라 기존 프로젝트를 고칠 필요가 없다.**
→ [physics-3d.md](physics-3d.md)

### 전용 2D 내비게이션 서버 · 비동기 리전 처리

`NavigationServer2D`는 사실 3D 서버의 프록시였다. 그래서 순수 2D 게임도 3D 지원이
포함된 export template이 필요해 파일이 커졌다. 이제 전용 2D 서버가 생겨
`navigation/2d/...`와 `navigation/3d/...`를 독립적으로 조정한다.
또한 맵·리전 처리를 백그라운드 스레드에 위임하는 비동기 옵션이 **기본으로 켜져 있다**
(`world/map_use_async_iterations`, `world/region_use_async_iterations`).
→ [navigation-3d.md](navigation-3d.md)

### SDL3 게임패드 드라이버

게임패드 처리를 성숙한 크로스플랫폼 라이브러리인 SDL3에 위임했다. **이 전환 자체가
새 기능을 주지는 않지만**, 앞으로 버그 수정과 새 기능이 빨라진다. 지금 당장의 이득은
호환성이다. 코드는 그대로 쓴다. → [input-ui.md](input-ui.md)

### 환경광 스펙큘러 오클루전 · Bent Normal Map · SMAA 1x

- **스펙큘러 오클루전** — 벽돌 틈처럼 가려진 곳이 하늘빛을 그대로 반사해 이상하게
  반짝이던 문제를 저렴하게 해결한다. **기본으로 켜져 있으며**, 외형이 달라질 수 있어
  `rendering/reflections/specular_occlusion/enabled`로 끌 수 있다.
- **Bent Normal Map** — 가림이 가장 적은 방향을 담은 텍스처(`bent_normal_texture`).
  스펙큘러 오클루전과 간접광 정확도를 높인다. 텍스처를 따로 구워야 한다.
- **SMAA 1x** — Godot-SMAA 애드온이 엔진에 정식 편입. FXAA보다 선명하고 더 비싸다.
  `Viewport.SCREEN_SPACE_AA_SMAA`.

→ [rendering-3d.md](rendering-3d.md)

### Mobile 렌더러의 반정밀도(F16) 부동소수점

Mobile 렌더러가 하드웨어 지원 시 **F16을 명시적으로 요청**한다. 대역폭과 전력이 줄어
프레임 페이싱이 안정되고 발열·배터리가 개선된다. **설정이 아니라 자동 적용**이므로,
개발자가 할 일은 셰이더에서 불필요하게 높은 정밀도를 강요하지 않는 것뿐이다.

### Import 독의 배치 편집 부활

FileSystem 독에서 파일을 여러 개 선택하면 Import 독에서 **편집할 속성을 골라**
`Reimport` 한 번으로 전체에 적용한다. 텍스처 수십 장의 압축 모드를 통일할 때 쓴다.
→ [resources-assets.md](resources-assets.md)

### 메시에서 프리미티브 콜리전 셰이프 자동 생성

`MeshInstance3D` 선택 → `Mesh > Create Collision Shape...`의 셰이프 타입에
**`Primitive`**가 추가되었다. 메시가 박스·구·실린더·캡슐이면 **대응하는 프리미티브
셰이프를 크기까지 맞춰** 만들어 준다. 이전에는 타입을 고르고 손으로 정렬해야 했다.

프리미티브 셰이프는 볼록·삼각형 셰이프보다 훨씬 빠르므로, 귀찮아서 `Single Convex`로
넘어가던 것을 클릭 한 번으로 최적 셰이프로 바꿀 수 있다.

**주의**: 이것은 **에디터 기능이다.** 코드 API(`create_convex_collision()` 등)에는
프리미티브 자동 매칭이 없다. 런타임에 필요하면 직접 매핑한다.
→ [physics-3d.md](physics-3d.md)의 "콜리전 셰이프 선택"

---

## 12. 이 프로젝트에 당장 쓸 수 있는 것

`Laryen 3D`는 Mobile 렌더러 + Jolt Physics + Android/Steam 대상이다.
그 조합에서 실제로 이득이 있는 항목만 추린다.

| 기능 | 활용 |
|------|------|
| **AreaLight3D** | 실내 조명, 화면 발광체. **소수만** — 가장 비싼 광원 |
| **파티클 3D 스케일·회전** | 파편·잔해 표현력 향상 |
| **포비티드 렌더링 최적화** | XR로 확장할 경우 |
| **Tween.tween_await()** | 컷신·연출 시퀀스를 한 체인으로 |
| **Control 오프셋 변환** | 버튼 흔들림 연출 + 정확한 터치 판정 |
| **RichTextLabel `1em` 이미지** | 인벤토리·상점 UI의 아이콘 정렬 |
| **GradientTexture2D 원뿔형** | 쿨다운·진행도 표시 |
| **DrawableTexture2D** | 미니맵, 안개 효과 |
| **VirtualJoystick 노드** | Android 왼손 이동 조작 — 직접 구현 대신 |
| **게임패드 미포커스 무시** | Steam 빌드에서 알트탭 대응 (기본 꺼짐 — 직접 켠다) |
| **키보드·마우스 장치 ID** | 입력 장치별 UI 프롬프트 전환 |
| **패치 PCK 델타 인코딩** (4.6) | 핫픽스·이벤트 데이터를 작은 용량으로 배포 |
| **프리미티브 콜리전 자동 생성** (4.6) | 상자·기둥 배치 시 최적 셰이프를 클릭 한 번에 |
| **선택적 템플릿 다운로드** | Android + Windows만 받아 시간 절약 |
| **GABE Gradle 내보내기** | Android 게시 파이프라인 |
| **Java 인터페이스 구현** | Android 네이티브 연동이 필요할 때 |
| **3D 정점 스냅 / 트랙볼 회전** | 레벨 배치 작업 효율 |
| **MeshLibrary 에디터** | GridMap으로 레벨을 만들 경우 |
| **CSG Autosmooth** | 프로토타이핑 |
| **Path3D 콜라이더 스냅** | 순찰 경로, 카메라 레일 |

### 쓸 수 없는 것 (Mobile 렌더러 제약)

**SSR 대개편** — 반사 품질과 속도가 크게 좋아졌지만 **Forward+ 전용**이다.
Mobile 렌더러에서는 `ssr_enabled`를 켜도 아무 일도 일어나지 않는다.
반사는 `ReflectionProbe`로 얻는다.

HDR 출력은 Mobile 렌더러에서도 동작하지만, Android 기기 대부분이
HDR 출력을 지원하지 않으므로 실질적 이득은 데스크톱 빌드에 한정된다.

---

## 13. 마이그레이션 체크리스트

엔진 버전을 올릴 때 확인할 항목이다. 아래는 **4.6 이하 → 4.7** 기준이며,
그 이후 버전으로 올릴 때도 절차 자체는 같다.

### 올리기 전에

- [ ] **프로젝트 전체를 백업하거나 커밋한다.** 되돌릴 수 없는 변환이 있다
- [ ] 사용 중인 애드온이 4.7을 지원하는지 확인한다
- [ ] GDExtension 플러그인은 4.7용으로 다시 빌드해야 할 수 있다

### 올린 뒤

- [ ] `project.godot`의 `config/features`에 `"4.7"`이 들어갔는지 확인
- [ ] 에디터를 열어 오류·경고 패널을 확인한다
- [ ] **LSP로 전체 스크립트를 진단한다**
      ```bash
      python3 .claude/skills/godot/scripts/gdscript_lsp.py diagnose --changed
      ```
- [ ] 모든 씬을 한 번씩 열어 노드 누락·경고가 없는지 본다
      ```bash
      godot --headless --path . --script res://tools/validate_scenes.gd
      ```
- [ ] 애니메이션 블렌딩 결과가 달라지지 않았는지 확인 (RESET 애니메이션 점검)
- [ ] 물리 동작 확인 — Jolt 설정이 `physics/jolt_physics_3d/` 경로에 있는지
- [ ] 머티리얼 외형 확인 — Clearcoat를 쓴 머티리얼은 결과가 달라진다
- [ ] 파티클 확인 — 스케일/회전 속성이 추가되어 기본값이 바뀌었을 수 있다
- [ ] 내보내기 프리셋 재확인 — **export template 버전이 엔진 버전과 정확히 일치**해야 한다
      (`godot --version` 결과와 `export_templates/<버전>.stable/` 폴더명이 같아야 한다)
- [ ] 실제 기기에서 빌드·실행 테스트

### 4.4 이하에서 올라오는 경우 추가 확인

- [ ] Jolt 프로젝트 설정 경로 변경: `physics/jolt_3d/` → `physics/jolt_physics_3d/`
      - `sleep/enabled` → `simulation/allow_sleep`
      - `solver/position_iterations` → `simulation/position_steps`
      - `collisions/use_shape_margins` → `collisions/collision_margin_fraction`
- [ ] `SkeletonIK3D`는 폐기 예정 — `SkeletonModifier3D` 계열로 교체
- [ ] `.gd.uid` 파일이 생성되며, **커밋해야 한다**

### 공식 마이그레이션 안내

기존 프로젝트를 4.7로 옮기기 전에 공식 마이그레이션 가이드를 읽는다.

- 릴리스 노트: https://godotengine.org/releases/4.7/
- 변경 기록: https://github.com/godotengine/godot/blob/4.7-stable/CHANGELOG.md
- 릴리스 목록: https://github.com/godotengine/godot-builds/releases
