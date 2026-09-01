# 3D 셰이더

## 목차

1. [핵심 개념 — 셰이더 파이프라인](#1-핵심-개념--셰이더-파이프라인)
2. [spatial 셰이더 기본 구조](#2-spatial-셰이더-기본-구조)
3. [render_mode 전체 목록](#3-render_mode-전체-목록)
4. [내장 변수 전체 목록](#4-내장-변수-전체-목록)
5. [uniform과 hint](#5-uniform과-hint)
6. [코드에서 파라미터 전달](#6-코드에서-파라미터-전달)
7. [실전 셰이더 모음](#7-실전-셰이더-모음)
8. [next_pass와 다중 패스](#8-next_pass와-다중-패스)
9. [셰이더 컴파일 스터터](#9-셰이더-컴파일-스터터)
10. [모바일에서 피해야 할 것](#10-모바일에서-피해야-할-것)
11. [자주 하는 실수](#11-자주-하는-실수)

---

## 1. 핵심 개념 — 셰이더 파이프라인

Godot 셰이더는 GLSL 기반의 자체 언어다. 세 개의 처리 함수가 순서대로 실행된다.

```
정점마다 실행     → vertex()      정점 위치·법선·UV 변형
      ↓ 래스터화 (GPU 자동)
픽셀마다 실행     → fragment()    ALBEDO, ROUGHNESS 등 머티리얼 속성 결정
      ↓ 광원마다
픽셀·광원마다 실행 → light()       커스텀 조명 모델 (생략하면 기본 PBR)
```

추가로:
- `start()` / `process()` — 파티클 셰이더
- `sky()` — 하늘 셰이더
- `fog()` — 포그 볼륨 셰이더

**성능 원칙**: `fragment()`는 화면 픽셀 수만큼 실행된다(1080p면 200만 번).
`vertex()`는 정점 수만큼(보통 수천 번). **계산은 가능한 한 `vertex()`로 옮긴다.**

### ShaderMaterial vs StandardMaterial3D

| | StandardMaterial3D | ShaderMaterial |
|---|---|---|
| 작성 | 인스펙터 체크박스 | 코드 |
| 성능 | 최적화된 내장 셰이더 | 작성하기 나름 |
| 유연성 | 정해진 기능만 | 무제한 |
| 권장 | **기본은 이것** | 표준으로 안 되는 것만 |

`StandardMaterial3D`를 우클릭 → `Convert to ShaderMaterial`로 변환하면
동등한 셰이더 코드가 생성된다. 커스터마이즈의 출발점으로 유용하다.

---

## 2. spatial 셰이더 기본 구조

```glsl
shader_type spatial;
render_mode blend_mix, depth_draw_opaque, cull_back, diffuse_burley, specular_schlick_ggx;

// ── uniform (외부에서 값 전달) ───────────────────────
uniform vec4 albedo : source_color = vec4(1.0);
uniform sampler2D albedo_texture : source_color, filter_linear_mipmap, repeat_enable;
uniform sampler2D normal_texture : hint_normal;
uniform float roughness : hint_range(0.0, 1.0) = 0.5;
uniform float metallic : hint_range(0.0, 1.0) = 0.0;
uniform float wave_speed = 1.0;
uniform float wave_height = 0.2;

// ── varying (vertex → fragment 전달) ─────────────────
varying vec3 world_position;
varying float wave_offset;

void vertex() {
    // 정점 파동 — 무거운 계산은 여기서
    wave_offset = sin(VERTEX.x * 2.0 + TIME * wave_speed) * wave_height;
    VERTEX.y += wave_offset;

    // 월드 좌표 계산 (MODEL_MATRIX는 오브젝트→월드 변환)
    world_position = (MODEL_MATRIX * vec4(VERTEX, 1.0)).xyz;
}

void fragment() {
    vec4 tex = texture(albedo_texture, UV);
    ALBEDO = albedo.rgb * tex.rgb;
    ALPHA = albedo.a * tex.a;
    ROUGHNESS = roughness;
    METALLIC = metallic;
    NORMAL_MAP = texture(normal_texture, UV).rgb;
    NORMAL_MAP_DEPTH = 1.0;
}
```

### varying

`vertex()`에서 계산한 값을 `fragment()`로 넘긴다. 정점 사이에서 자동 보간된다.

```glsl
varying vec3 v_world_pos;
varying flat int v_index;        // flat = 보간하지 않음
```

---

## 3. render_mode 전체 목록

### 블렌딩

| 모드 | 설명 |
|------|------|
| `blend_mix` | 일반 알파 블렌딩 (기본) |
| `blend_add` | 가산 — 불, 발광 효과 |
| `blend_sub` | 감산 |
| `blend_mul` | 곱셈 — 그림자, 어둡게 |
| `blend_premul_alpha` | 미리 곱해진 알파 |

### 뎁스

| 모드 | 설명 |
|------|------|
| `depth_draw_opaque` | 불투명만 뎁스 기록 (기본) |
| `depth_draw_always` | 항상 기록 |
| `depth_draw_never` | 기록 안 함 — 반투명 파티클 |
| `depth_prepass_alpha` | 알파 프리패스 — 반투명 정렬 개선 |
| `depth_test_disabled` | 뎁스 테스트 끔 — 항상 앞에 그림 (X-ray) |

### 컬링

| 모드 | 설명 |
|------|------|
| `cull_back` | 뒷면 제거 (기본) |
| `cull_front` | 앞면 제거 — 외곽선 |
| `cull_disabled` | 양면 렌더링 — 나뭇잎, 천 |

### 조명 모델

| 모드 | 설명 |
|------|------|
| `diffuse_burley` | Disney PBS (기본) |
| `diffuse_lambert` / `diffuse_lambert_wrap` | 램버트 |
| `diffuse_toon` | 툰 |
| `specular_schlick_ggx` | 표준 (기본) |
| `specular_toon` | 툰 |
| `specular_disabled` | 반사광 제거 — 모바일 절약 |
| `unshaded` | 조명 계산 완전 생략 — 가장 빠름 |

### 기타

| 모드 | 설명 |
|------|------|
| `skip_vertex_transform` | 정점 변환을 직접 수행 |
| `world_vertex_coords` | `VERTEX`가 월드 좌표로 |
| `vertex_lighting` | 정점 단위 조명 — **모바일 최적화** |
| `shadows_disabled` | 그림자 받지 않음 |
| `ambient_light_disabled` | 환경광 무시 |
| `shadow_to_opacity` | 그림자를 알파로 (AR 그림자) |
| `alpha_to_coverage` | MSAA 기반 알파 |
| `fog_disabled` | 포그 미적용 |

---

### stencil_mode — render_mode가 아닌 별도 구문 (4.5+)

스텐실은 `render_mode`가 아니라 **독립된 `stencil_mode` 구문**으로 지정한다.
`render_mode stencil_read` 같은 표기는 `Invalid render mode` 오류가 난다.

```glsl
shader_type spatial;
stencil_mode <플래그...>, <비교>, <참조값>;
```

| 키워드 | 의미 |
|---|---|
| `read` | 스텐실 버퍼에서 읽는다 |
| `write` | 참조값을 스텐실 버퍼에 쓴다 |
| `write_if_depth_fail` | 깊이 테스트에 실패했을 때만 참조값을 쓴다 |
| `compare_always` | 항상 통과 |
| `compare_equal` | 참조값 == 버퍼값이면 통과 |
| `compare_not_equal` | 참조값 != 버퍼값이면 통과 |
| `compare_less` / `compare_less_or_equal` | 참조값 < (또는 ≤) 버퍼값 |
| `compare_greater` / `compare_greater_or_equal` | 참조값 > (또는 ≥) 버퍼값 |

마지막 숫자가 참조값(0~255)이다. 플래그는 쉼표로 여러 개 나열할 수 있다.

```glsl
// ① 마커 — 화면에 안 보이지만 스텐실에 1을 기록한다
shader_type spatial;
render_mode unshaded, depth_draw_never;
stencil_mode write, compare_always, 1;

void fragment() {
    ALPHA = 0.0;                 // 색은 그리지 않는다
}
```

```glsl
// ② 벽 — 스텐실이 1인 픽셀에서는 그리지 않는다 → 캐릭터 모양으로 구멍이 뚫린다
shader_type spatial;
stencil_mode read, compare_not_equal, 1;

uniform sampler2D albedo_tex : source_color;

void fragment() {
    ALBEDO = texture(albedo_tex, UV).rgb;
}
```

①을 캐릭터를 감싸는 구 메시에, ②를 벽 메시에 적용한다.
`render_priority`로 **①이 ②보다 먼저** 그려지게 한다(→ [8. next_pass와 다중 패스](#8-next_pass와-다중-패스)).

**제약**

- **읽기는 투명 패스에서만 가능하다.** 불투명 패스에서 읽으려 하면 실패한다.
- 스텐실에 쓰는 머티리얼은 불투명이어도 **투명 패스로 넘어간다.** 투명 렌더링의
  정렬·오버드로우 비용을 그대로 받으므로 모바일에서 큰 면적에 남발하지 않는다.
- 참조값은 0~255 정수 하나뿐이다. 여러 효과가 동시에 쓰면 서로 덮어쓰므로
  효과별로 값을 미리 배분한다.

간단한 외곽선·X-ray는 셰이더를 짜지 말고 `StandardMaterial3D`의 `stencil_mode`
프리셋(`OUTLINE`/`XRAY`)을 쓰는 편이 낫다(→ [rendering-3d.md](rendering-3d.md)).

---

## 4. 내장 변수 전체 목록

### 전역 (모든 함수)

| 변수 | 타입 | 설명 |
|------|------|------|
| `TIME` | `float` | 시작 후 경과 시간(초) |
| `PI`, `TAU`, `E` | `float` | 상수 |
| `VIEWPORT_SIZE` | `vec2` | 뷰포트 크기(픽셀) |
| `MODEL_MATRIX` | `mat4` | 오브젝트 → 월드 |
| `MODEL_NORMAL_MATRIX` | `mat3` | 법선용 오브젝트 → 월드 |
| `VIEW_MATRIX` | `mat4` | 월드 → 뷰 |
| `INV_VIEW_MATRIX` | `mat4` | 뷰 → 월드 |
| `PROJECTION_MATRIX` | `mat4` | 뷰 → 클립 |
| `INV_PROJECTION_MATRIX` | `mat4` | 역투영 |
| `CAMERA_POSITION_WORLD` | `vec3` | 카메라 월드 위치 |
| `CAMERA_DIRECTION_WORLD` | `vec3` | 카메라 방향 |
| `CAMERA_VISIBLE_LAYERS` | `uint` | 카메라 컬 마스크 |
| `OUTPUT_IS_SRGB` | `bool` | |

### vertex()

| 변수 | 타입 | 읽기/쓰기 | 설명 |
|------|------|----------|------|
| `VERTEX` | `vec3` | R/W | 정점 위치 (기본: 로컬 좌표) |
| `NORMAL` | `vec3` | R/W | 법선 |
| `TANGENT` / `BINORMAL` | `vec3` | R/W | 탄젠트 공간 |
| `UV` / `UV2` | `vec2` | R/W | 텍스처 좌표 |
| `COLOR` | `vec4` | R/W | 정점 색 |
| `POINT_SIZE` | `float` | W | 포인트 크기 |
| `INSTANCE_ID` | `int` | R | 인스턴스 인덱스 (MultiMesh) |
| `INSTANCE_CUSTOM` | `vec4` | R | 인스턴스 커스텀 데이터 |
| `VERTEX_ID` | `int` | R | 정점 인덱스 |
| `ROUGHNESS` | `float` | W | 정점 단위 러프니스 |
| `POSITION` | `vec4` | W | 클립 공간 직접 지정 |
| `NODE_POSITION_WORLD` | `vec3` | R | 노드의 월드 위치 |
| `NODE_POSITION_VIEW` | `vec3` | R | 노드의 뷰 위치 |
| `VIEW_INDEX` / `VIEW_MONO_LEFT` / `VIEW_RIGHT` | `int` | R | XR 스테레오 |

### fragment()

| 변수 | 타입 | R/W | 설명 |
|------|------|-----|------|
| `ALBEDO` | `vec3` | W | 베이스 색상 |
| `ALPHA` | `float` | W | 투명도 (쓰면 자동으로 투명 파이프라인) |
| `ALPHA_SCISSOR_THRESHOLD` | `float` | W | 알파 컷오프 |
| `ALPHA_HASH_SCALE` | `float` | W | 해시 디더 스케일 |
| `ALPHA_ANTIALIASING_EDGE` | `float` | W | |
| `METALLIC` | `float` | W | 금속성 |
| `SPECULAR` | `float` | W | 비금속 반사 강도 |
| `ROUGHNESS` | `float` | W | 거칠기 |
| `RIM` / `RIM_TINT` | `float` | W | 림 라이트 |
| `CLEARCOAT` / `CLEARCOAT_ROUGHNESS` | `float` | W | 클리어코트 |
| `ANISOTROPY` / `ANISOTROPY_FLOW` | `float`/`vec2` | W | 이방성 |
| `AO` / `AO_LIGHT_AFFECT` | `float` | W | 앰비언트 오클루전 |
| `EMISSION` | `vec3` | W | 발광 |
| `NORMAL` | `vec3` | R/W | 뷰 공간 법선 |
| `NORMAL_MAP` / `NORMAL_MAP_DEPTH` | `vec3`/`float` | W | 노멀맵 (탄젠트 공간) |
| `BACKLIGHT` | `vec3` | W | 후광 |
| `SSS_STRENGTH` / `SSS_TRANSMITTANCE_*` | | W | SSS (**Forward+ 전용**) |
| `FOG` / `RADIANCE` / `IRRADIANCE` | `vec4` | W | |
| `UV` / `UV2` / `COLOR` | | R | vertex에서 전달 |
| `FRAGCOORD` | `vec4` | R | 화면 픽셀 좌표 |
| `SCREEN_UV` | `vec2` | R | 화면 UV (0~1) |
| `POINT_COORD` | `vec2` | R | 포인트 스프라이트 좌표 |
| `VERTEX` | `vec3` | R | 뷰 공간 위치 |
| `VIEW` | `vec3` | R | 뷰 방향 벡터 |
| `FRONT_FACING` | `bool` | R | 앞면인가 |
| `DEPTH` | `float` | W | 깊이 직접 쓰기 |
| `LIGHT_VERTEX` | `vec3` | W | 조명 계산용 위치 |

### 텍스처 샘플러 (내장)

| 샘플러 | 설명 | 비고 |
|--------|------|------|
| `SCREEN_TEXTURE` | 화면 색상 | 4.x에서는 `hint_screen_texture` uniform으로 선언 |
| `DEPTH_TEXTURE` | 깊이 버퍼 | `hint_depth_texture` |
| `NORMAL_ROUGHNESS_TEXTURE` | 법선+러프니스 | `hint_normal_roughness_texture` |

```glsl
// 4.x 방식 — 반드시 uniform으로 선언한다
uniform sampler2D screen_texture : hint_screen_texture, filter_linear_mipmap;
uniform sampler2D depth_texture : hint_depth_texture, filter_linear_mipmap;

void fragment() {
    vec3 behind = texture(screen_texture, SCREEN_UV).rgb;
    float depth = texture(depth_texture, SCREEN_UV).r;
}
```

**모바일 주의**: 화면 텍스처를 읽으면 렌더 패스가 분리되어 타일 기반 GPU에서
비용이 크다. 꼭 필요할 때만 쓴다.

---

## 5. uniform과 hint

```glsl
// 기본 타입
uniform float value = 1.0;
uniform int count = 4;
uniform bool enabled = true;
uniform vec2 offset = vec2(0.0);
uniform vec3 direction = vec3(0.0, 1.0, 0.0);
uniform vec4 color : source_color = vec4(1.0);       // source_color = sRGB 변환
uniform mat4 custom_transform;

// 범위 제한 (인스펙터에 슬라이더)
uniform float strength : hint_range(0.0, 1.0) = 0.5;
uniform float scale : hint_range(0.0, 10.0, 0.1) = 1.0;   // 세 번째 = step

// 텍스처
uniform sampler2D tex : source_color, filter_linear_mipmap, repeat_enable;
uniform sampler2D normal_tex : hint_normal;
uniform sampler2D roughness_tex : hint_roughness_r;       // R 채널 사용
uniform sampler2D noise : repeat_enable, filter_linear;
uniform sampler2D gradient : source_color, filter_linear, repeat_disable;
uniform samplerCube env : source_color;
uniform sampler3D volume;

// 필터 옵션
//   filter_nearest / filter_linear
//   filter_nearest_mipmap / filter_linear_mipmap
//   filter_nearest_mipmap_anisotropic / filter_linear_mipmap_anisotropic
// 반복 옵션
//   repeat_enable / repeat_disable

// 기본 텍스처 지정
uniform sampler2D tex : hint_default_white;
// hint_default_black, hint_default_white, hint_default_transparent,
// hint_normal_roughness_texture, hint_anisotropy

// 전역 uniform (모든 셰이더가 공유)
global uniform float game_time;
global uniform vec3 wind_direction;

// 인스턴스 uniform (머티리얼 복제 없이 인스턴스별 값)
instance uniform vec4 tint : source_color = vec4(1.0);
instance uniform float damage_flash = 0.0;
```

### instance uniform이 중요한 이유

`instance uniform`은 **머티리얼을 복제하지 않고** 인스턴스마다 다른 값을 준다.
머티리얼을 복제하면 드로우콜 배칭이 깨져 성능이 떨어진다.

```gdscript
# GDScript에서
mesh_instance.set_instance_shader_parameter("tint", Color.RED)
mesh_instance.set_instance_shader_parameter("damage_flash", 1.0)
```

제약: 인스턴스 uniform은 스칼라·벡터만 가능하고 텍스처는 안 된다.
최대 개수 제한이 있다.

### 전역 uniform

`Project Settings → Shader Globals`에서 등록한 뒤 코드로 값을 설정한다.
바람 방향, 게임 내 시간처럼 모든 셰이더가 공유하는 값에 쓴다.

```gdscript
RenderingServer.global_shader_parameter_set("wind_direction", Vector3(1, 0, 0.3))
RenderingServer.global_shader_parameter_set("game_time", elapsed)
```

---

## 6. 코드에서 파라미터 전달

```gdscript
var mat := mesh.material_override as ShaderMaterial

# 설정
mat.set_shader_parameter("strength", 0.8)
mat.set_shader_parameter("color", Color.RED)
mat.set_shader_parameter("tex", load("res://tex.png"))
mat.set_shader_parameter("custom_transform", global_transform)

# 조회
var v: float = mat.get_shader_parameter("strength")

# 셰이더 교체
mat.shader = load("res://shaders/dissolve.gdshader")

# 트윈으로 애니메이션
var tween := create_tween()
tween.tween_method(
    func(v: float) -> void: mat.set_shader_parameter("dissolve_amount", v),
    0.0, 1.0, 1.5
)
```

**`set_shader_parameter`는 머티리얼 단위다.** 여러 인스턴스가 같은 머티리얼을 쓰면
전부 바뀐다. 인스턴스별로 다르게 하려면 `instance uniform` + `set_instance_shader_parameter`.

---

## 7. 실전 셰이더 모음

### 7-1. 외곽선 (툰 렌더링) — next_pass용

```glsl
shader_type spatial;
render_mode unshaded, cull_front, depth_draw_opaque;

uniform vec4 outline_color : source_color = vec4(0.0, 0.0, 0.0, 1.0);
uniform float outline_width : hint_range(0.0, 0.2) = 0.02;
uniform bool fixed_screen_size = true;

void vertex() {
    if (fixed_screen_size) {
        // 카메라 거리에 비례해 두께를 키워 화면상 두께를 일정하게
        float dist = length((MODELVIEW_MATRIX * vec4(VERTEX, 1.0)).xyz);
        VERTEX += NORMAL * outline_width * dist * 0.05;
    } else {
        VERTEX += NORMAL * outline_width;
    }
}

void fragment() {
    ALBEDO = outline_color.rgb;
    ALPHA = outline_color.a;
}
```

**원리**: 메시를 법선 방향으로 부풀리고 앞면을 컬링하면 원본 실루엣 바깥의
뒷면만 보인다. 모바일에서 저렴한 외곽선 기법이다.

### 7-2. 디졸브 (소멸 효과)

```glsl
shader_type spatial;
render_mode cull_disabled;

uniform sampler2D albedo_texture : source_color;
uniform sampler2D noise_texture : repeat_enable, filter_linear;
uniform float dissolve_amount : hint_range(0.0, 1.0) = 0.0;
uniform float edge_width : hint_range(0.0, 0.3) = 0.06;
uniform vec4 edge_color : source_color = vec4(1.0, 0.4, 0.05, 1.0);
uniform float edge_energy : hint_range(0.0, 10.0) = 4.0;
uniform float noise_scale = 1.0;

void fragment() {
    float noise = texture(noise_texture, UV * noise_scale).r;

    // 노이즈 값이 임계값보다 작으면 픽셀 제거
    if (noise < dissolve_amount) {
        discard;
    }

    ALBEDO = texture(albedo_texture, UV).rgb;

    // 경계 부근을 발광시킨다
    float edge = smoothstep(dissolve_amount, dissolve_amount + edge_width, noise);
    EMISSION = edge_color.rgb * (1.0 - edge) * edge_energy;
}
```

```gdscript
# 사용
func dissolve_out(duration: float = 1.2) -> void:
    var mat := mesh.get_active_material(0) as ShaderMaterial
    var tween := create_tween()
    tween.tween_method(
        func(v: float) -> void: mat.set_shader_parameter("dissolve_amount", v),
        0.0, 1.0, duration
    )
    await tween.finished
    queue_free()
```

**`discard`는 모바일에서 비싸다.** 타일 기반 GPU의 얼리-Z 최적화를 무효화한다.
디졸브는 연출용이므로 동시에 많은 오브젝트에 적용하지 않는다.

### 7-3. 홀로그램

```glsl
shader_type spatial;
render_mode blend_add, cull_disabled, depth_draw_never, unshaded;

uniform vec4 hologram_color : source_color = vec4(0.2, 0.8, 1.0, 1.0);
uniform float scanline_count = 60.0;
uniform float scanline_speed = 2.0;
uniform float fresnel_power : hint_range(0.5, 8.0) = 3.0;
uniform float flicker_speed = 12.0;
uniform float alpha : hint_range(0.0, 1.0) = 0.7;

varying vec3 v_world_pos;

void vertex() {
    v_world_pos = (MODEL_MATRIX * vec4(VERTEX, 1.0)).xyz;
}

void fragment() {
    // 프레넬 — 가장자리를 밝게
    float fresnel = pow(1.0 - clamp(dot(NORMAL, VIEW), 0.0, 1.0), fresnel_power);

    // 스캔라인 — 월드 Y 기준이라 오브젝트가 움직여도 라인이 고정된다
    float scan = sin(v_world_pos.y * scanline_count - TIME * scanline_speed);
    scan = smoothstep(0.0, 1.0, scan) * 0.4 + 0.6;

    // 미세한 깜빡임
    float flicker = 0.92 + 0.08 * sin(TIME * flicker_speed);

    ALBEDO = hologram_color.rgb;
    EMISSION = hologram_color.rgb * (fresnel + 0.3) * scan * flicker * 2.0;
    ALPHA = alpha * scan * flicker * (fresnel * 0.6 + 0.4);
}
```

### 7-4. 물 표면 (모바일 친화)

```glsl
shader_type spatial;
render_mode blend_mix, cull_back, specular_schlick_ggx;

uniform vec4 shallow_color : source_color = vec4(0.15, 0.55, 0.65, 0.75);
uniform vec4 deep_color : source_color = vec4(0.02, 0.12, 0.25, 0.95);
uniform sampler2D wave_normal_a : hint_normal, repeat_enable;
uniform sampler2D wave_normal_b : hint_normal, repeat_enable;
uniform vec2 wave_direction_a = vec2(1.0, 0.2);
uniform vec2 wave_direction_b = vec2(-0.4, 0.8);
uniform float wave_speed = 0.05;
uniform float wave_scale = 4.0;
uniform float wave_strength : hint_range(0.0, 2.0) = 0.4;
uniform float vertex_wave_height = 0.08;
uniform float vertex_wave_freq = 1.5;

void vertex() {
    // 정점 파동 — fragment보다 훨씬 저렴하다
    float w = sin(VERTEX.x * vertex_wave_freq + TIME)
            * cos(VERTEX.z * vertex_wave_freq * 0.7 + TIME * 0.8);
    VERTEX.y += w * vertex_wave_height;
}

void fragment() {
    // 두 개의 노멀맵을 서로 다른 방향으로 흘려 반복감을 없앤다
    vec2 uv_a = UV * wave_scale + wave_direction_a * TIME * wave_speed;
    vec2 uv_b = UV * wave_scale * 1.3 + wave_direction_b * TIME * wave_speed;

    vec3 n_a = texture(wave_normal_a, uv_a).rgb;
    vec3 n_b = texture(wave_normal_b, uv_b).rgb;
    vec3 blended = normalize(n_a + n_b - vec3(1.0, 1.0, 0.0));

    NORMAL_MAP = blended;
    NORMAL_MAP_DEPTH = wave_strength;

    // 시야각으로 얕은/깊은 색을 섞는다 (깊이 텍스처 없이)
    float fresnel = pow(1.0 - clamp(dot(NORMAL, VIEW), 0.0, 1.0), 2.0);
    vec4 col = mix(deep_color, shallow_color, fresnel);

    ALBEDO = col.rgb;
    ALPHA = col.a;
    ROUGHNESS = 0.05;
    METALLIC = 0.0;
    SPECULAR = 0.8;
}
```

**모바일 설계 근거**: `DEPTH_TEXTURE`나 `SCREEN_TEXTURE`를 쓰지 않는다.
깊이 기반 색 변화 대신 프레넬로 근사했다. 굴절은 포기했다.

### 7-5. 삼중 평면 매핑 (지형 — UV 없이)

```glsl
shader_type spatial;

uniform sampler2D top_texture : source_color, repeat_enable;
uniform sampler2D side_texture : source_color, repeat_enable;
uniform float texture_scale = 0.5;
uniform float blend_sharpness : hint_range(1.0, 16.0) = 4.0;

varying vec3 v_world_pos;
varying vec3 v_world_normal;

void vertex() {
    v_world_pos = (MODEL_MATRIX * vec4(VERTEX, 1.0)).xyz;
    v_world_normal = normalize((MODEL_NORMAL_MATRIX * NORMAL));
}

void fragment() {
    vec3 blend = pow(abs(v_world_normal), vec3(blend_sharpness));
    blend /= (blend.x + blend.y + blend.z);

    vec3 x_tex = texture(side_texture, v_world_pos.zy * texture_scale).rgb;
    vec3 y_tex = texture(top_texture, v_world_pos.xz * texture_scale).rgb;
    vec3 z_tex = texture(side_texture, v_world_pos.xy * texture_scale).rgb;

    ALBEDO = x_tex * blend.x + y_tex * blend.y + z_tex * blend.z;
    ROUGHNESS = 0.9;
}
```

UV 언랩 없이 절벽·바위에 텍스처를 입힌다. 대신 텍스처를 3번 샘플링하므로
비용이 3배다. 모바일에서는 지형에만 제한적으로 쓴다.

### 7-6. 피격 플래시 (인스턴스 uniform)

```glsl
shader_type spatial;

uniform sampler2D albedo_texture : source_color;
uniform sampler2D normal_texture : hint_normal;
uniform float roughness_value : hint_range(0.0, 1.0) = 0.6;

// 인스턴스마다 다른 값 — 머티리얼 복제 불필요
instance uniform float hit_flash : hint_range(0.0, 1.0) = 0.0;
instance uniform vec4 tint : source_color = vec4(1.0);

void fragment() {
    vec3 base = texture(albedo_texture, UV).rgb * tint.rgb;
    ALBEDO = mix(base, vec3(1.0), hit_flash);
    EMISSION = vec3(1.0, 0.25, 0.2) * hit_flash * 3.0;
    NORMAL_MAP = texture(normal_texture, UV).rgb;
    ROUGHNESS = roughness_value;
}
```

```gdscript
func flash() -> void:
    var tween := create_tween()
    tween.tween_method(
        func(v: float) -> void: mesh.set_instance_shader_parameter("hit_flash", v),
        1.0, 0.0, 0.15
    )
```

### 7-7. 바람에 흔들리는 식생

```glsl
shader_type spatial;
render_mode cull_disabled, depth_prepass_alpha;

uniform sampler2D albedo_texture : source_color;
uniform float alpha_cutoff : hint_range(0.0, 1.0) = 0.5;
uniform vec2 wind_direction = vec2(1.0, 0.3);
uniform float wind_strength : hint_range(0.0, 1.0) = 0.15;
uniform float wind_speed = 1.5;
uniform float stiffness = 1.0;      // 정점 색 R 채널이 흔들림 가중치

void vertex() {
    // 정점 색 R로 흔들림 정도를 제어 (뿌리=0, 끝=1)
    float weight = COLOR.r / max(stiffness, 0.001);

    // 오브젝트 위치를 위상 오프셋으로 써서 개체마다 다르게 흔들린다
    vec3 world_origin = MODEL_MATRIX[3].xyz;
    float phase = world_origin.x * 0.7 + world_origin.z * 0.4;

    float sway = sin(TIME * wind_speed + phase) * 0.7
               + sin(TIME * wind_speed * 2.3 + phase * 1.7) * 0.3;

    VERTEX.x += wind_direction.x * sway * wind_strength * weight;
    VERTEX.z += wind_direction.y * sway * wind_strength * weight;
}

void fragment() {
    vec4 tex = texture(albedo_texture, UV);
    ALBEDO = tex.rgb;
    ALPHA = tex.a;
    ALPHA_SCISSOR_THRESHOLD = alpha_cutoff;
    // 얇은 잎의 투과광
    BACKLIGHT = vec3(0.25, 0.4, 0.12);
}
```

**핵심**: 모든 계산이 `vertex()`에 있다. 정점 수는 픽셀 수보다 훨씬 적으므로
모바일에서도 수백 그루를 흔들 수 있다.

### 7-8. 프레넬 발광 (아이템 하이라이트)

```glsl
shader_type spatial;
render_mode blend_add, cull_front, depth_draw_never, unshaded;

uniform vec4 glow_color : source_color = vec4(1.0, 0.85, 0.3, 1.0);
uniform float power : hint_range(0.5, 8.0) = 2.5;
uniform float energy : hint_range(0.0, 5.0) = 1.5;
uniform float pulse_speed = 2.0;
uniform float expand = 0.01;

void vertex() {
    VERTEX += NORMAL * expand;
}

void fragment() {
    float fresnel = pow(1.0 - clamp(dot(NORMAL, VIEW), 0.0, 1.0), power);
    float pulse = 0.7 + 0.3 * sin(TIME * pulse_speed);
    ALBEDO = glow_color.rgb;
    EMISSION = glow_color.rgb * fresnel * energy * pulse;
    ALPHA = fresnel * glow_color.a;
}
```

`next_pass`로 붙이면 원본 머티리얼 위에 발광 껍질이 씌워진다.

---

## 8. next_pass와 다중 패스

머티리얼을 겹쳐 그린다. 외곽선, 발광 오라, 얼음 코팅 등에 쓴다.

```gdscript
var base := StandardMaterial3D.new()
base.albedo_color = Color(0.7, 0.7, 0.75)

var outline := ShaderMaterial.new()
outline.shader = preload("res://shaders/outline.gdshader")
outline.set_shader_parameter("outline_color", Color.BLACK)

base.next_pass = outline
mesh.material_override = base
```

`next_pass`는 체인으로 연결할 수 있다(`a.next_pass = b`, `b.next_pass = c`).
**각 패스가 드로우콜을 추가하므로 모바일에서는 2단계까지만 쓴다.**

### 하이라이트 토글 (상호작용 대상 표시)

```gdscript
class_name Highlightable
extends Node

const OUTLINE_MAT: ShaderMaterial = preload("res://materials/outline.tres")

@export var mesh: MeshInstance3D
var _base_material: Material

func _ready() -> void:
    _base_material = mesh.get_active_material(0)

func set_highlighted(on: bool) -> void:
    if _base_material == null:
        return
    if on and _base_material.next_pass == null:
        # 원본 머티리얼을 건드리지 않도록 복제 후 붙인다
        var copy := _base_material.duplicate()
        copy.next_pass = OUTLINE_MAT
        mesh.material_override = copy
    elif not on:
        mesh.material_override = null
```

---

## 9. 셰이더 컴파일 스터터

Godot은 셰이더를 **처음 그려질 때** 컴파일한다. 새 효과가 화면에 처음 나타날 때
수십~수백 ms의 프레임 정지가 발생한다. 모바일에서 특히 심하다.

### 대응책

**1. 셰이더 워밍업 (권장)**

게임 시작 시 또는 로딩 화면에서 모든 머티리얼을 한 번씩 렌더링한다.

```gdscript
# res://scenes/tools/shader_warmup.gd
extends Node3D

@export var materials_to_warm: Array[Material] = []

func _ready() -> void:
    await _warm_up()
    queue_free()

func _warm_up() -> void:
    var cam := Camera3D.new()
    add_child(cam)
    cam.current = true
    cam.position = Vector3(0, 0, 2)

    for mat in materials_to_warm:
        var mi := MeshInstance3D.new()
        mi.mesh = BoxMesh.new()
        mi.material_override = mat
        # 카메라 앞에 아주 작게 배치 — 보이지만 눈에 띄지 않음
        mi.scale = Vector3.ONE * 0.001
        add_child(mi)
        await get_tree().process_frame
        await get_tree().process_frame
        mi.queue_free()
```

**2. `ubershader` 방식 회피** — Godot 4.4+는 셰이더 캐시를 디스크에 저장하므로
두 번째 실행부터는 빠르다. 첫 실행 경험만 신경 쓰면 된다.

**3. 셰이더 종류를 줄인다** — 같은 셰이더에 uniform으로 변형을 주면
컴파일은 한 번만 일어난다. 비슷한 셰이더 10개보다 uniform이 많은 셰이더 1개가 낫다.

**4. 프로젝트 설정**

```ini
[rendering]

shader_compiler/shader_cache/enabled=true
shader_compiler/shader_cache/compress=true
shader_compiler/shader_cache/use_zstd_compression=true
shader_compiler/shader_cache/strip_debug.release=true
```

---

## 10. 모바일에서 피해야 할 것

| 피할 것 | 이유 | 대안 |
|---------|------|------|
| `SCREEN_TEXTURE` 읽기 | 렌더 패스 분리, 타일 GPU에서 매우 비쌈 | 프레넬로 근사 |
| `DEPTH_TEXTURE` 읽기 | 위와 동일 | 정점 색이나 거리 계산 |
| `discard` 남용 | 얼리-Z 무효화 | `ALPHA_SCISSOR_THRESHOLD` |
| `fragment()`의 복잡한 반복문 | 픽셀마다 실행 | `vertex()`로 이동 |
| 삼중 평면 매핑 전면 사용 | 텍스처 샘플 3배 | 지형에만, UV가 있으면 UV 사용 |
| `pow()`, `exp()`, `sin()` 남용 | 초월함수는 비쌈 | 룩업 텍스처 또는 근사식 |
| 텍스처 샘플 5개 이상 | 대역폭 병목 | ORM 채널 패킹 |
| 동적 분기(`if`)로 셰이더 분기 | 워프 다이버전스 | `mix()`, `step()` |
| SSS, Refraction | Mobile 렌더러 미지원/고비용 | 사용 안 함 |
| 다중 `next_pass` 3단계 이상 | 드로우콜 배수 | 2단계까지 |

### 저렴한 대안 패턴

```glsl
// if 대신 step/mix
// 느림: if (x > 0.5) { c = a; } else { c = b; }
vec3 c = mix(b, a, step(0.5, x));

// pow(x, 2.0) 대신
float sq = x * x;

// normalize를 여러 번 하지 말고 한 번만
vec3 n = normalize(NORMAL);   // 재사용

// 정점 조명 (모바일 최적화)
render_mode vertex_lighting;
```

---

## 11. 자주 하는 실수

| 실수 | 증상 | 해결 |
|------|------|------|
| `SCREEN_TEXTURE`를 uniform 없이 사용 | 컴파일 오류 | `hint_screen_texture` uniform 선언 |
| `ALPHA`를 쓰기만 하고 `render_mode` 미설정 | 정렬 문제 | `blend_mix` + 적절한 `depth_draw` |
| 색상 uniform에 `source_color` 누락 | 색이 어둡거나 밝게 나옴 | `: source_color` 추가 |
| 노멀맵에 `hint_normal` 누락 | 노멀맵이 이상함 | 힌트 추가 |
| `NORMAL`에 노멀맵을 직접 대입 | 좌표계 불일치 | `NORMAL_MAP` 사용 |
| `fragment()`에서 무거운 계산 | 프레임 저하 | `vertex()`로 이동 |
| 머티리얼 파라미터를 인스턴스별로 변경 | 전부 바뀜 | `instance uniform` |
| `TIME`을 물리 계산에 사용 | 일시정지 시에도 진행 | `TIME`은 연출용, 게임 로직은 GDScript |
| 셰이더 워밍업 없음 | 첫 등장 시 프레임 정지 | 로딩 중 워밍업 |
| `cull_disabled` 남용 | 폴리곤 2배 | 필요한 곳만 |
| `repeat_enable` 누락 | 텍스처가 늘어남 | UV가 1을 넘으면 필요 |
| `varying`을 `fragment()`에서 쓰기 | 컴파일 오류 | `vertex()`에서만 대입 |
