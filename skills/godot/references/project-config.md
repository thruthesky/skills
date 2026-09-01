# 설정 파일 포맷과 CLI

## 목차

1. [핵심 개념 — 텍스트 기반 포맷](#1-핵심-개념--텍스트-기반-포맷)
2. [project.godot 구조](#2-projectgodot-구조)
3. [주요 설정 항목](#3-주요-설정-항목)
4. [기능 태그 오버라이드](#4-기능-태그-오버라이드)
5. [.tscn 씬 파일 포맷](#5-tscn-씬-파일-포맷)
6. [.tres 리소스 파일 포맷](#6-tres-리소스-파일-포맷)
7. [.import 파일과 .godot 캐시](#7-import-파일과-godot-캐시)
8. [Git 설정](#8-git-설정)
9. [Godot CLI](#9-godot-cli)
10. [ProjectSettings 코드 API](#10-projectsettings-코드-api)
11. [자주 하는 실수](#11-자주-하는-실수)

---

## 1. 핵심 개념 — 텍스트 기반 포맷

Godot의 모든 프로젝트 파일은 **사람이 읽고 편집할 수 있는 텍스트**다.
이는 Git 병합, 스크립트 자동화, AI 편집을 가능하게 하는 핵심 설계다.

| 확장자 | 내용 | 포맷 |
|--------|------|------|
| `project.godot` | 프로젝트 설정 | INI 계열 |
| `.tscn` | 씬 (텍스트) | INI 계열 |
| `.scn` | 씬 (바이너리) | 이진 |
| `.tres` | 리소스 (텍스트) | INI 계열 |
| `.res` | 리소스 (바이너리) | 이진 |
| `.gd` | GDScript | 텍스트 |
| `.gdshader` | 셰이더 | 텍스트 |
| `.import` | 임포트 설정 | INI 계열 |
| `.gd.uid` | 스크립트 UID | 텍스트 (한 줄) |
| `export_presets.cfg` | 내보내기 프리셋 | INI 계열 |
| `default_bus_layout.tres` | 오디오 버스 | INI 계열 |

**바이너리(.scn/.res)는 로드가 빠르지만 Git 병합이 불가능하다.**
개발 중에는 텍스트를 쓰고, 내보내기 시 Godot이 자동으로 바이너리로 변환한다.

### 직접 편집해도 되는가

| 작업 | 직접 편집 |
|------|----------|
| `project.godot`에 설정 추가 | 안전 |
| `.tscn`의 노드 프로퍼티 값 변경 | 안전 (형식 준수 시) |
| `.tscn`에 노드 추가/삭제 | 위험 — `load_steps`, 참조 ID를 정확히 맞춰야 함 |
| `.tres` 값 변경 | 안전 |
| `.import` 편집 | 가능하나 재임포트 필요 |
| UID 값 임의 변경 | **금지** — 참조가 깨진다 |

**편집 후에는 에디터에서 파일을 다시 열어 오류가 없는지 확인한다.**

---

## 2. project.godot 구조

```ini
; 주석은 세미콜론
; Engine configuration file.

config_version=5                          ; Godot 4.x는 5. 절대 수동 변경 금지

[application]

config/name="Laryen 3D"
config/description="라리엔 3D 게임"
config/version="1.0.0"
run/main_scene="res://scenes/main.tscn"
config/features=PackedStringArray("4.7", "Mobile")
config/icon="res://icon.svg"
config/use_custom_user_dir=false
config/custom_user_dir_name=""
boot_splash/image="res://assets/splash.png"
boot_splash/bg_color=Color(0.05, 0.05, 0.08, 1)
boot_splash/fullsize=true
boot_splash/use_filter=true
run/disable_stderr=false
run/flush_stdout_on_print=false

[autoload]

GameState="*res://autoload/game_state.gd"
AudioManager="*res://scenes/autoload/audio_manager.tscn"
SceneLoader="*res://autoload/scene_loader.gd"
Events="*res://autoload/events.gd"

[display]

window/size/viewport_width=1920
window/size/viewport_height=1080
window/size/mode=0
window/size/resizable=true
window/size/borderless=false
window/stretch/mode="canvas_items"
window/stretch/aspect="expand"
window/stretch/scale=1.0
window/handheld/orientation=0
window/vsync/vsync_mode=1
window/energy_saving/keep_screen_on=true

[input]

move_forward={
"deadzone": 0.2,
"events": [Object(InputEventKey,"resource_local_to_scene":false,"resource_name":"","device":-1,"window_id":0,"alt_pressed":false,"shift_pressed":false,"ctrl_pressed":false,"meta_pressed":false,"pressed":false,"keycode":0,"physical_keycode":87,"key_label":0,"unicode":0,"location":0,"echo":false,"script":null)
]
}

[layer_names]

3d_physics/layer_1="World"
3d_physics/layer_2="Player"
3d_physics/layer_3="Enemy"
3d_render/layer_1="Default"
3d_navigation/layer_1="Ground"

[physics]

common/physics_ticks_per_second=60
common/max_physics_steps_per_frame=8
3d/physics_engine="Jolt Physics"
3d/default_gravity=9.8
3d/default_gravity_vector=Vector3(0, -1, 0)

[rendering]

renderer/rendering_method="mobile"
renderer/rendering_method.mobile="mobile"
rendering_device/driver.windows="d3d12"
textures/vram_compression/import_etc2_astc=true
anti_aliasing/quality/msaa_3d=1
lights_and_shadows/directional_shadow/size.mobile=1024
occlusion_culling/use_occlusion_culling=true

[audio]

buses/default_bus_layout="res://default_bus_layout.tres"
driver/output_latency=15

[global_group]

player="플레이어 그룹"
enemies="적 그룹"

[editor_plugins]

enabled=PackedStringArray("res://addons/godot-mcp/plugin.cfg")
```

### 문법 규칙

| 규칙 | 예시 |
|------|------|
| 섹션 | `[application]` |
| 키는 `/` 로 계층 표현 | `config/name` |
| 문자열은 큰따옴표 | `"Laryen 3D"` |
| 불리언 | `true` / `false` (소문자) |
| 숫자 | `60`, `9.8` |
| Godot 타입 | `Color(1,1,1,1)`, `Vector2(0,0)`, `Vector3(0,-1,0)` |
| 배열 | `PackedStringArray("a","b")` |
| 오토로드는 `*` 접두사 | `"*res://autoload/game.gd"` |
| 주석 | `;` 로 시작 |

### config/features의 의미

```ini
config/features=PackedStringArray("4.7", "Mobile")
```

- `"4.7"` — 이 프로젝트가 작성된 Godot 버전. 낮은 버전으로 열면 경고가 뜬다.
- `"Mobile"` / `"Forward Plus"` / `"GL Compatibility"` — 프로젝트 생성 시 선택한 렌더러.
  **실제 렌더러는 `rendering/renderer/rendering_method`가 결정한다.** 이 항목은 표시용이다.
- `"Double Precision"` — 큰 월드 좌표 지원 빌드

---

## 3. 주요 설정 항목

### application

| 키 | 설명 |
|----|------|
| `config/name` | 프로젝트 이름. `user://` 폴더 이름에도 쓰임 |
| `run/main_scene` | 시작 씬 |
| `config/icon` | 아이콘 |
| `boot_splash/*` | 시작 스플래시 |
| `run/max_fps` | 최대 프레임레이트 (0=무제한) |
| `config/use_custom_user_dir` | `user://` 경로 커스터마이즈 |

### display

| 키 | 설명 |
|----|------|
| `window/size/viewport_width/height` | 기준 해상도 |
| `window/stretch/mode` | `disabled` / `canvas_items` / `viewport` |
| `window/stretch/aspect` | `ignore` / `keep` / `keep_width` / `keep_height` / `expand` |
| `window/handheld/orientation` | 0=landscape, 1=portrait, ... |
| `window/vsync/vsync_mode` | 0=disabled, 1=enabled, 2=adaptive, 3=mailbox |
| `window/energy_saving/keep_screen_on` | 모바일 화면 꺼짐 방지 |

### physics

| 키 | 설명 |
|----|------|
| `common/physics_ticks_per_second` | 물리 틱 (기본 60) |
| `common/max_physics_steps_per_frame` | 프레임당 최대 물리 스텝 |
| `common/physics_interpolation` | 물리 보간 (4.3+) |
| `3d/physics_engine` | `"DEFAULT"` / `"Jolt Physics"` / `"GodotPhysics3D"` |
| `3d/default_gravity` | 기본 중력 크기 |
| `3d/default_gravity_vector` | 중력 방향 |
| `3d/sleep_threshold_linear/angular` | 슬립 임계값 |
| `jolt_physics_3d/simulation/*` | Jolt 전용 설정 |

### rendering

| 키 | 설명 |
|----|------|
| `renderer/rendering_method` | `forward_plus` / `mobile` / `gl_compatibility` |
| `rendering_device/driver` | `vulkan` / `d3d12` / `metal` |
| `textures/vram_compression/import_etc2_astc` | Android 압축 |
| `textures/default_filters/anisotropic_filtering_level` | 이방성 필터링 |
| `anti_aliasing/quality/msaa_3d` | 0=off, 1=2x, 2=4x, 3=8x |
| `anti_aliasing/quality/screen_space_aa` | 0=off, 1=FXAA |
| `anti_aliasing/quality/use_taa` | Forward+ 전용 |
| `scaling_3d/mode` / `scale` | 해상도 스케일링 |
| `lights_and_shadows/directional_shadow/size` | 방향광 섀도우맵 크기 |
| `lights_and_shadows/positional_shadow/atlas_size` | 점광원 섀도우 아틀라스 |
| `occlusion_culling/use_occlusion_culling` | 오클루전 컬링 |
| `mesh_lod/lod_change/threshold_pixels` | LOD 전환 임계값 |
| `environment/defaults/default_environment` | 기본 환경 리소스 |
| `shader_compiler/shader_cache/enabled` | 셰이더 캐시 |

### debug

| 키 | 설명 |
|----|------|
| `gdscript/warnings/enable` | GDScript 경고 활성화 |
| `gdscript/warnings/untyped_declaration` | 타입 없는 선언 경고 |
| `gdscript/warnings/unsafe_property_access` | 안전하지 않은 프로퍼티 접근 |
| `gdscript/warnings/unused_variable` | 미사용 변수 |
| `settings/stdout/verbose_stdout` | 상세 로그 |
| `shapes/collision/draw_2d_outlines` | 콜리전 시각화 |
| `file_logging/enable_file_logging` | 로그 파일 저장 |

**정적 타입을 강제하려면**:

```ini
[debug]

gdscript/warnings/untyped_declaration=1        ; 1=경고, 2=에러
gdscript/warnings/inferred_declaration=0
gdscript/warnings/unsafe_property_access=1
gdscript/warnings/unsafe_method_access=1
gdscript/warnings/unsafe_cast=1
gdscript/warnings/unsafe_call_argument=1
gdscript/warnings/return_value_discarded=0
```

값이 `2`면 경고가 에러로 승격되어 실행이 막힌다. 팀 규율을 강제할 때 유용하다.

---

## 4. 기능 태그 오버라이드

설정 키 뒤에 `.태그`를 붙이면 해당 플랫폼에서만 적용된다.

```ini
[rendering]

anti_aliasing/quality/msaa_3d=2                     ; 기본 4x
anti_aliasing/quality/msaa_3d.mobile=1              ; 모바일 2x
anti_aliasing/quality/msaa_3d.android=0             ; 안드로이드 끔

lights_and_shadows/directional_shadow/size=4096
lights_and_shadows/directional_shadow/size.mobile=1024

[physics]

common/physics_ticks_per_second=60
common/physics_ticks_per_second.mobile=60
```

### 우선순위

더 구체적인 태그가 이긴다: `android` > `mobile` > 기본값.
여러 태그가 동시에 매치되면 `project.godot`에 나중에 나오는 것이 적용되므로
모호한 조합을 만들지 않는다.

### 사용 가능한 태그

```
플랫폼:  windows, macos, linux, bsd, android, ios, web
그룹:    mobile, pc, web_android, web_ios
빌드:    editor, template, template_debug, template_release, debug, release
아키텍처: x86_32, x86_64, arm32, arm64, rv64, wasm32
정밀도:  double, single
텍스처:  etc2, s3tc, bptc, astc
기타:    movie
```

내보내기 프리셋의 `Features` 필드에 커스텀 태그를 추가할 수 있다 (`demo`, `steam` 등).

---

## 5. .tscn 씬 파일 포맷

### 전체 구조

```ini
[gd_scene load_steps=6 format=3 uid="uid://bqx8k2vn1m3rt"]

[ext_resource type="Script" path="res://scenes/player/player.gd" id="1_abc12"]
[ext_resource type="PackedScene" uid="uid://c3v8x2mqk1nrt" path="res://scenes/weapon.tscn" id="2_def34"]
[ext_resource type="Texture2D" uid="uid://dh4k9v2m" path="res://assets/textures/skin.png" id="3_ghi56"]

[sub_resource type="CapsuleShape3D" id="CapsuleShape3D_xyz78"]
radius = 0.35
height = 1.8

[sub_resource type="StandardMaterial3D" id="StandardMaterial3D_jkl90"]
albedo_color = Color(0.8, 0.7, 0.6, 1)
albedo_texture = ExtResource("3_ghi56")
roughness = 0.7

[node name="Player" type="CharacterBody3D"]
collision_layer = 2
collision_mask = 5
script = ExtResource("1_abc12")
move_speed = 5.5
jump_velocity = 4.8

[node name="CollisionShape3D" type="CollisionShape3D" parent="."]
transform = Transform3D(1, 0, 0, 0, 1, 0, 0, 0, 1, 0, 0.9, 0)
shape = SubResource("CapsuleShape3D_xyz78")

[node name="Model" type="Node3D" parent="."]

[node name="MeshInstance3D" type="MeshInstance3D" parent="Model"]
material_override = SubResource("StandardMaterial3D_jkl90")

[node name="CameraPivot" type="Node3D" parent="." index="2"]
unique_name_in_owner = true
transform = Transform3D(1, 0, 0, 0, 1, 0, 0, 0, 1, 0, 1.6, 0)

[node name="Weapon" parent="Model" instance=ExtResource("2_def34")]
damage = 25

[connection signal="body_entered" from="HitArea" to="." method="_on_hit_area_body_entered"]
```

### 헤더

```ini
[gd_scene load_steps=6 format=3 uid="uid://bqx8k2vn1m3rt"]
```

| 필드 | 의미 |
|------|------|
| `load_steps` | `ext_resource` + `sub_resource` 개수 + 1. **틀리면 로드 경고가 뜬다** |
| `format` | Godot 4.x는 `3` |
| `uid` | 이 씬의 고유 ID. 다른 파일이 이 값으로 참조한다 |

**`load_steps`를 직접 계산하는 것은 오류가 나기 쉽다.** 노드를 추가/삭제할 때는
에디터를 쓰거나, 편집 후 에디터에서 씬을 열어 저장해 자동 정정시킨다.

### ext_resource — 외부 파일 참조

```ini
[ext_resource type="Script" path="res://scenes/player/player.gd" id="1_abc12"]
[ext_resource type="PackedScene" uid="uid://c3v8" path="res://scenes/weapon.tscn" id="2_def34"]
```

- `id`는 이 파일 안에서만 유효한 로컬 식별자다. `ExtResource("1_abc12")`로 참조한다.
- `uid`가 있으면 파일이 이동해도 참조가 유지된다. `path`는 폴백이다.
- `type`은 리소스 클래스명이다.

### sub_resource — 이 씬 안에만 존재하는 리소스

```ini
[sub_resource type="BoxShape3D" id="BoxShape3D_a1b2c"]
size = Vector3(2, 1, 2)
```

`SubResource("BoxShape3D_a1b2c")`로 참조한다.
씬 안에서만 쓰이는 셰이프, 머티리얼, 커브 등이 여기 들어간다.

### node — 노드 정의

```ini
[node name="Player" type="CharacterBody3D"]                     ; 루트 (parent 없음)
[node name="Shape" type="CollisionShape3D" parent="."]          ; 루트의 자식
[node name="Mesh" type="MeshInstance3D" parent="Model"]         ; Model의 자식
[node name="Deep" type="Node3D" parent="Model/Armature"]        ; 중첩 경로
[node name="Weapon" parent="." instance=ExtResource("2_def34")] ; 씬 인스턴스 (type 없음)
[node name="Cam" type="Camera3D" parent="." index="2"]          ; 형제 중 순서 지정
```

| 속성 | 의미 |
|------|------|
| `name` | 노드 이름. 형제 간 유일해야 함 |
| `type` | 노드 클래스. 인스턴스면 생략 |
| `parent` | 부모 경로. `"."`은 루트 |
| `instance` | 다른 씬을 인스턴스화 |
| `index` | 형제 사이의 순서 (0부터) |
| `owner` | 소유 씬 (보통 자동) |
| `groups` | `groups=["enemies", "damageable"]` |
| `unique_name_in_owner` | `true`면 `%이름`으로 접근 가능 |

노드 블록 다음 줄부터는 **기본값과 다른 프로퍼티만** 기록된다.

```ini
[node name="Player" type="CharacterBody3D"]
collision_layer = 2
script = ExtResource("1_abc12")
move_speed = 5.5              ; 스크립트의 @export 변수
```

### connection — 시그널 연결

```ini
[connection signal="body_entered" from="HitArea" to="." method="_on_body_entered"]
[connection signal="pressed" from="UI/Button" to="." method="_on_pressed" binds= [1]]
[connection signal="timeout" from="Timer" to="." method="_on_timeout" flags=3]
```

| 필드 | 의미 |
|------|------|
| `signal` | 시그널 이름 |
| `from` | 발신 노드 경로 |
| `to` | 수신 노드 경로 |
| `method` | 호출할 메서드 |
| `binds` | 추가 인자 |
| `flags` | 연결 플래그 (1=DEFERRED, 2=PERSIST, 4=ONESHOT의 조합) |

### 값 표기법

```ini
some_bool = true
some_int = 42
some_float = 1.5
some_string = "텍스트"
some_vector2 = Vector2(1, 2)
some_vector3 = Vector3(1, 2, 3)
some_color = Color(1, 0.5, 0, 1)
some_transform = Transform3D(1, 0, 0, 0, 1, 0, 0, 0, 1, 0, 0, 0)
some_array = [1, 2, 3]
some_typed_array = Array[int]([1, 2, 3])
some_dict = {"key": "value"}
some_nodepath = NodePath("../Target")
some_resource = ExtResource("1_abc12")
some_subresource = SubResource("BoxShape3D_a1b2c")
some_packed = PackedVector3Array(0, 0, 0, 1, 0, 0)
metadata/custom_key = "값"
```

**`Transform3D`의 12개 인자**: 앞 9개가 basis(x축 3개, y축 3개, z축 3개),
뒤 3개가 origin이다.

```
Transform3D(xx, xy, xz,  yx, yy, yz,  zx, zy, zz,  ox, oy, oz)
```

### 안전한 편집 예시

```ini
; 이 정도는 직접 편집해도 안전하다 — 값만 바꾼다
[node name="Player" type="CharacterBody3D"]
move_speed = 5.5      →  move_speed = 7.0

[node name="Light" type="OmniLight3D" parent="."]
light_energy = 1.0    →  light_energy = 2.5
omni_range = 5.0      →  omni_range = 8.0
```

```ini
; 이건 위험하다 — load_steps와 id 관리가 필요하다
[ext_resource ...]    ; 추가 시 load_steps도 +1
[sub_resource ...]    ; 추가 시 load_steps도 +1
```

---

## 6. .tres 리소스 파일 포맷

```ini
[gd_resource type="Resource" script_class="WeaponData" load_steps=3 format=3 uid="uid://dk2m9v4x"]

[ext_resource type="Script" path="res://scripts/resources/weapon_data.gd" id="1_script"]
[ext_resource type="AudioStream" uid="uid://b7x2" path="res://assets/audio/swing.ogg" id="2_sfx"]

[resource]
resource_name = "철검"
script = ExtResource("1_script")
id = &"iron_sword"
display_name = "철검"
description = "평범한 철제 검이다."
damage = 25
attack_speed = 1.2
crit_chance = 0.08
swing_sound = ExtResource("2_sfx")
```

| 필드 | 의미 |
|------|------|
| `type` | 기본 리소스 타입 (`Resource`, `StandardMaterial3D` 등) |
| `script_class` | 커스텀 스크립트의 `class_name` |
| `load_steps` | 로드 단계 수 — 외부·내부 리소스 개수 + 1. **틀리면 로드가 깨진다** |
| `uid` | `ResourceUID` — 경로가 바뀌어도 참조를 유지한다 |
| `[resource]` | 리소스 본체 프로퍼티 |
| `resource_name` | 사람이 읽는 이름. **`script` 줄보다 위에 온다**(엔진 확인) |
| `script` | 커스텀 리소스면 스크립트 참조 |

### 🛑 기본값과 같은 프로퍼티는 기록되지 않는다

**`.tres` 를 읽을 때 가장 먼저 알아야 할 규칙이다.** 엔진에서 확인한 동작(4.7.2) —
스크립트의 선언 기본값과 값이 같으면 **명시적으로 대입해도** 파일에 쓰이지 않는다.

```ini
; 전부 기본값인 리소스 — [resource] 아래에 script 한 줄뿐이다
[gd_resource type="Resource" script_class="CameraConfig" format=3]

[ext_resource type="Script" path="res://scripts/camera_config.gd" id="1_b5vfu"]

[resource]
resource_name = "쿼터뷰"
script = ExtResource("1_b5vfu")
```

**파일이 비어 보인다고 값이 없는 게 아니다.** 로드하면 스크립트의 기본값이 들어간다.
반대로 `.tres` 에 적힌 줄은 **전부 "기본값과 다른 값"** 이라는 뜻이라, diff 를 보면
그 리소스가 표준에서 무엇을 바꿨는지 바로 읽힌다.

이 규칙 때문에 **선언 기본값을 함부로 바꾸면 안 된다.** 기본값을 바꾸는 순간
그 값을 저장하지 않고 있던 모든 `.tres` 가 조용히 따라 바뀐다.
설정 리소스 설계 시의 대응은
[resources-assets.md](resources-assets.md) §3 을 읽는다.

### 로드할 때 setter 를 거친다

`.tres` 의 값은 **프로퍼티 setter 를 통해** 들어간다(엔진 확인). 그래서 파일을 손으로
고쳐 범위 밖 값을 넣어도 setter 의 `clampi`·`maxf` 가 그 자리에서 막는다.

```ini
hp = 99999          ; 파일에는 이렇게 적혀 있어도
```
```
로드 결과 → hp = 100     ; setter 가 clampi(value, 0, 100) 로 잘랐다
```

순서는 **① `_init()` → ② 파일 값을 setter 로 대입** 이다. `_init()` 안에서 다른
프로퍼티를 읽으면 아직 기본값만 보인다.

### 중첩 리소스는 `[sub_resource]` 로 인라인된다

리소스 안에 다른 리소스를 넣고 그것이 **별도 파일이 아니면** 같은 파일에 들어간다.

```ini
[sub_resource type="Resource" id="Resource_4mxed"]
script = ExtResource("1_etpn3")
hp = 55

[resource]
script = ExtResource("1_etpn3")
nested = SubResource("Resource_4mxed")
```

별도 `.tres` 로 저장된 리소스를 참조하면 `[ext_resource]` + `ExtResource(...)` 가 된다.
**같은 데이터를 여러 리소스가 공유해야 하면 별도 파일로 빼야 한다** — 인라인하면
파일마다 복사본이 생긴다.

### `.tres` 와 `.res` — 이진이 항상 작지 않다

| 확장자 | 포맷 | 쓰는 곳 |
|---|---|---|
| **`.tres`** | 텍스트 | **설정·게임 데이터 전부.** git diff 가 읽힌다 |
| `.res` | 이진 | 사람이 안 보는 대용량 데이터 |

같은 리소스를 두 형식으로 저장해 실측했다(4.7.2).

| 데이터 | `.tres` | `.res` |
|---|---|---|
| 작은 설정 리소스 | **208 B** | 380 B |
| 문자열 2,000개 배열 | **24,200 B** | 34,345 B |

이진 포맷은 타입 태그와 정렬 패딩이 붙어 **작은 데이터·문자열에서는 오히려 커진다.**
`.res` 의 장점은 파싱 속도이며, 설정 리소스 크기에서는 차이가 의미 없다.
**설정·데이터는 `.tres` 를 쓴다.**

### 값 편집과 일괄 밸런싱

**`.tres` 값 편집은 안전하다.** 밸런싱 수치를 스크립트로 일괄 수정할 수 있다.

```bash
# 예: 모든 무기의 damage를 10% 올린다
for f in resources/weapons/*.tres; do
  awk '/^damage = /{ printf "damage = %d\n", $3*1.1; next } {print}' "$f" > "$f.tmp"
  mv "$f.tmp" "$f"
done
```

단 **프로퍼티를 새로 추가하는 편집은 피한다** — `load_steps` 나 리소스 ID 를 함께
맞춰야 하는 경우가 있다. 새 리소스를 만들 때는 손으로 쓰지 말고
`ResourceSaver.save()` 가 직렬화하게 둔다
([resources-assets.md](resources-assets.md) §3 의 헤드리스 생성 절).

---

## 7. .import 파일과 .godot 캐시

### .import 파일

```ini
[remap]

importer="texture"
type="CompressedTexture2D"
uid="uid://c3v8x2mqk1nrt"
path.s3tc="res://.godot/imported/wall.png-a1b2c3.s3tc.ctex"
path.etc2="res://.godot/imported/wall.png-a1b2c3.etc2.ctex"
metadata={
"imported_formats": ["s3tc_bptc", "etc2_astc"],
"vram_texture": true
}

[deps]

source_file="res://assets/textures/wall.png"
dest_files=["res://.godot/imported/wall.png-a1b2c3.s3tc.ctex", "res://.godot/imported/wall.png-a1b2c3.etc2.ctex"]

[params]

compress/mode=2
compress/high_quality=false
compress/normal_map=0
mipmaps/generate=true
process/fix_alpha_border=true
```

`[params]` 섹션이 임포트 옵션이다. 여러 파일의 설정을 일괄 변경할 때
스크립트로 편집한 뒤 재임포트할 수 있다.

```bash
# 모든 텍스처의 밉맵을 켠다
find assets/textures -name "*.import" -exec \
  sed -i '' 's/mipmaps\/generate=false/mipmaps\/generate=true/' {} +
# 재임포트
godot --headless --path . --import --quit
```

### .godot/ 폴더

```
.godot/
├── imported/           변환된 에셋 (커밋 금지)
├── editor/             에디터 상태 (열린 씬, 레이아웃)
├── shader_cache/       컴파일된 셰이더
├── exported/           내보내기 캐시
├── global_script_class_cache.cfg    class_name 등록부
└── uid_cache.bin       UID 매핑
```

**전부 생성물이므로 커밋하지 않는다.** 삭제해도 에디터가 다시 만든다
(첫 실행이 느려질 뿐이다).

---

## 8. Git 설정

### .gitignore

```gitignore
# Godot 4+ 생성 파일
.godot/
/android/

# 내보내기 결과물
build/
export/
*.exe
*.apk
*.aab
*.pck
*.zip
*.dmg

# 서명 키 (절대 커밋 금지)
*.keystore
*.jks
release.cfg

# 에디터·OS
.DS_Store
Thumbs.db
*.swp
.vscode/
.idea/

# 내보내기 프리셋의 비밀번호가 들어갈 수 있음
# 팀에서 공유하려면 비밀번호를 환경변수로 빼고 커밋
# export_presets.cfg
```

**`export_presets.cfg`에 키스토어 비밀번호가 평문으로 저장된다.**
공유 저장소라면 커밋하지 말거나, 비밀번호 필드를 비우고 CI에서 주입한다.

### .gitattributes

```gitattributes
# Godot 텍스트 파일은 LF로 통일
* text=auto eol=lf

# 바이너리 취급
*.png binary
*.jpg binary
*.jpeg binary
*.webp binary
*.ogg binary
*.wav binary
*.mp3 binary
*.glb binary
*.blend binary
*.ttf binary
*.otf binary
*.res binary
*.scn binary
*.ctex binary

# Git LFS (대용량 에셋)
*.glb filter=lfs diff=lfs merge=lfs -text
*.blend filter=lfs diff=lfs merge=lfs -text
*.png filter=lfs diff=lfs merge=lfs -text
```

**커밋해야 하는 것**

- `project.godot`, 모든 `.tscn`/`.tres`/`.gd`
- **`.import` 파일** — 팀원 간 임포트 설정 일치를 위해 필수
- **`.gd.uid` 파일** (4.4+) — 스크립트 참조 유지
- 원본 에셋 (`.png`, `.glb`)
- `default_bus_layout.tres`

**커밋하면 안 되는 것**

- `.godot/` 폴더 전체
- 빌드 결과물
- 키스토어

---

## 9. Godot CLI

### 기본 실행

```bash
godot                                    # 프로젝트 매니저
godot --path /path/to/project            # 프로젝트 에디터 열기
godot --path . --editor                  # 명시적 에디터 실행
godot --path . scenes/test.tscn          # 특정 씬만 실행
godot --path . --main-pack game.pck      # pck 실행
```

### 헤드리스 (서버·CI)

```bash
godot --headless --path . --import --quit             # 에셋 임포트만
godot --headless --path . --script tools/build.gd     # 스크립트 실행
godot --headless --path . --export-release "Android" build/game.aab
godot --headless --path . --export-debug "Windows Desktop" build/game.exe
godot --headless --path . --export-pack "Android" build/game.pck
```

### 디버그·진단

```bash
godot --path . --verbose                 # 상세 로그
godot --path . --debug-collisions        # 콜리전 시각화
godot --path . --debug-navigation        # 내비메시 시각화
godot --path . --debug-paths
godot --path . --debug-stringnames
godot --path . --profiling               # 프로파일러 활성화
godot --path . --gpu-profile
godot --path . --remote-debug tcp://127.0.0.1:6007
godot --path . --check-only --script res://scenes/player/player.gd   # 문법 검사만
```

### 렌더링·디스플레이

```bash
godot --path . --rendering-method mobile
godot --path . --rendering-driver vulkan       # vulkan / d3d12 / metal / opengl3
godot --path . --resolution 1280x720
godot --path . --position 100,100
godot --path . --fullscreen
godot --path . --maximized
godot --path . --single-window
godot --path . --xr-mode off
```

### 유틸리티

```bash
godot --version
godot --version-full
godot --doctool docs/                    # 클래스 레퍼런스 XML 생성
godot --gdscript-docs res://scripts      # GDScript 문서 생성
godot --dump-gdextension-interface
godot --dump-extension-api
godot --validate-extension-api api.json
godot --write-movie output.avi           # 무비 라이터 (녹화)
godot --quit-after 100                   # 100 프레임 후 종료
```

### 커스텀 인자 전달

```bash
godot --path . -- --server --port 7777
```

`--` 뒤의 인자는 엔진이 아니라 게임에 전달된다.

```gdscript
func _ready() -> void:
    var args := OS.get_cmdline_user_args()      # -- 뒤의 인자만
    var all := OS.get_cmdline_args()            # 전부
    for arg in args:
        if arg == "--server":
            NetworkManager.host_game()
```

### CI 예시 (GitHub Actions)

```yaml
name: Build
on: [push]
jobs:
  build:
    runs-on: ubuntu-latest
    container: barichello/godot-ci:4.7.2
    steps:
      - uses: actions/checkout@v4
      - name: 내보내기 템플릿 설치
        run: |
          mkdir -p ~/.local/share/godot/export_templates/4.7.2.stable
          mv /root/.local/share/godot/export_templates/4.7.2.stable/* \
             ~/.local/share/godot/export_templates/4.7.2.stable/
      - name: 임포트
        run: godot --headless --path . --import --quit || true
      - name: 내보내기
        run: |
          mkdir -p build/linux
          godot --headless --path . --export-release "Linux" build/linux/game.x86_64
      - uses: actions/upload-artifact@v4
        with:
          name: linux-build
          path: build/linux
```

**`--import`에 `|| true`를 붙이는 이유**: 첫 임포트는 에러 코드를 반환하는 경우가
있지만 실제로는 성공한 것이다.

### 자동화 스크립트 (--script)

```gdscript
# res://tools/batch_process.gd
@tool
extends SceneTree

func _initialize() -> void:
    print("배치 작업 시작")
    _process_all_scenes("res://scenes")
    print("완료")
    quit()

func _process_all_scenes(dir_path: String) -> void:
    var dir := DirAccess.open(dir_path)
    if dir == null:
        return
    for file in dir.get_files():
        if file.ends_with(".tscn"):
            var path := dir_path.path_join(file)
            var scene := load(path) as PackedScene
            print("처리: ", path)
    for sub in dir.get_directories():
        _process_all_scenes(dir_path.path_join(sub))
```

```bash
godot --headless --path . --script res://tools/batch_process.gd
```

`SceneTree`를 상속하고 `_initialize()`에서 작업한 뒤 `quit()`을 호출한다.

---

## 10. ProjectSettings 코드 API

```gdscript
# 조회 (플랫폼 오버라이드 적용됨)
var gravity: float = ProjectSettings.get_setting("physics/3d/default_gravity", 9.8)
var name: String = ProjectSettings.get_setting("application/config/name")

# 오버라이드 무시하고 기본값
var base = ProjectSettings.get_setting_with_override("rendering/anti_aliasing/quality/msaa_3d")

# 존재 확인
if ProjectSettings.has_setting("my_game/difficulty"):
    pass

# 설정 (런타임 변경 — 일부는 즉시 반영되지 않는다)
ProjectSettings.set_setting("my_game/difficulty", 2)

# 커스텀 설정 등록 (에디터 인스펙터에 표시)
if not ProjectSettings.has_setting("my_game/max_enemies"):
    ProjectSettings.set_setting("my_game/max_enemies", 50)
ProjectSettings.set_initial_value("my_game/max_enemies", 50)
ProjectSettings.add_property_info({
    "name": "my_game/max_enemies",
    "type": TYPE_INT,
    "hint": PROPERTY_HINT_RANGE,
    "hint_string": "1,200,1"
})
ProjectSettings.set_as_basic("my_game/max_enemies", true)

# 저장 (에디터에서만 — 내보낸 빌드에서는 res://가 읽기 전용)
ProjectSettings.save()

# 경로 변환
var abs := ProjectSettings.globalize_path("res://assets/data.json")
var rel := ProjectSettings.localize_path("/home/u/proj/assets/data.json")
```

**주의**: 런타임에 `set_setting()`으로 바꿔도 이미 초기화된 서브시스템
(물리 틱, 렌더러)에는 반영되지 않는 항목이 많다. 그런 값은 게임 시작 전에
결정하거나 해당 서버 API를 직접 호출한다.

---

## 11. 자주 하는 실수

| 실수 | 결과 | 해결 |
|------|------|------|
| `.tscn`에 노드 추가하며 `load_steps` 미갱신 | 로드 경고 | 에디터로 저장해 자동 정정 |
| `ExtResource` id 중복/누락 | 씬 깨짐 | id를 유일하게 유지 |
| `uid` 값을 임의 변경 | 참조 끊김 | UID는 건드리지 않는다 |
| `.import` 파일 gitignore | 팀원마다 다른 임포트 결과 | 커밋한다 |
| `.godot/` 커밋 | 저장소 비대, 충돌 | gitignore |
| `config_version` 수동 변경 | 프로젝트 로드 실패 | 절대 변경 금지 |
| `export_presets.cfg` 커밋 | 키스토어 비밀번호 유출 | gitignore 또는 비밀번호 제거 |
| 키스토어 커밋 | 서명 키 유출 | gitignore + 별도 백업 |
| 런타임 `set_setting`으로 물리 틱 변경 | 반영 안 됨 | 시작 전 설정 |
| `Transform3D` 인자 순서 착각 | 이상한 변환 | basis 9개 + origin 3개 |
| 오버라이드 태그 오타 (`.moble`) | 조용히 무시됨 | 정확한 태그명 사용 |
| CRLF/LF 혼용 | Git diff 오염 | `.gitattributes`로 LF 통일 |
| `--import` 실패를 CI 오류로 처리 | 빌드 중단 | `\|\| true` 추가 |
