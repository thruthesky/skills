# 3D 렌더링 — 렌더러·머티리얼·조명·환경

> **이 프로젝트는 Mobile 렌더러다.** `project.godot`의
> `renderer/rendering_method="mobile"`. 아래 제약을 항상 전제한다.

## 목차

1. [렌더러 3종 비교](#1-렌더러-3종-비교)
2. [Mobile 렌더러에서 하지 말아야 할 것](#2-mobile-렌더러에서-하지-말아야-할-것)
3. [StandardMaterial3D 전체 속성](#3-standardmaterial3d-전체-속성)
4. [투명도 5종 선택 가이드](#4-투명도-5종-선택-가이드)
5. [머티리얼 코드 조작](#5-머티리얼-코드-조작)
6. [조명](#6-조명)
7. [그림자 튜닝](#7-그림자-튜닝)
8. [LightmapGI 베이킹](#8-lightmapgi-베이킹)
9. [ReflectionProbe](#9-reflectionprobe)
10. [WorldEnvironment](#10-worldenvironment)
11. [Decal](#11-decal)
12. [파티클](#12-파티클)
13. [렌더 레이어와 뷰포트](#13-렌더-레이어와-뷰포트)
14. [자주 하는 실수](#14-자주-하는-실수)

---

## 1. 렌더러 3종 비교

| 기능 | Forward+ | **Mobile** | Compatibility |
|------|----------|-----------|---------------|
| 그래픽 API | Vulkan / D3D12 / Metal | Vulkan / D3D12 / Metal | OpenGL ES 3.0 / WebGL 2 |
| 조명 방식 | 클러스터 포워드 | 포워드 단일 패스 | 포워드 |
| 대상 | 데스크톱 | 모바일 + 데스크톱 | 웹·저사양 |
| **SDFGI** | ✓ | ✗ | ✗ |
| **VoxelGI** | ✓ | ✗ | ✗ |
| **LightmapGI** | ✓ | ✓ | ✓ |
| **ReflectionProbe** | ✓ | ✓ | ✓ |
| **SSAO** | ✓ | ✗ | ✗ |
| **SSIL** | ✓ | ✗ | ✗ |
| **SSR** (화면공간 반사) | ✓ | ✗ | ✗ |
| **볼류메트릭 포그** | ✓ | ✗ | ✗ |
| 기본 포그 (Depth/Height) | ✓ | ✓ | ✓ |
| Glow | ✓ | ✓ | ✓ |
| Adjustments (색보정) | ✓ | ✓ | ✓ |
| **TAA** | ✓ | ✗ | ✗ |
| **FSR2** | ✓ | ✗ | ✗ |
| FXAA | ✓ | ✓ | ✗ |
| SMAA | ✓ | ✓ | ✗ |
| MSAA 3D | ✓ | ✓ | ✓ |
| SSAA (Supersampling) | ✓ | ✓ | ✓ |
| PCSS 소프트 섀도우 | 전 광원 | DirectionalLight 제외 | ✗ |
| **SubsurfaceScattering** | ✓ | ✗ | ✗ |
| Decal | ✓ | ✓ | 제한적 |
| 컴퓨트 셰이더 | ✓ | ✓ (성능 페널티) | ✗ |
| CompositorEffects | ✓ | ✓ | ✗ |
| 오클루전 컬링 | ✓ | ✓ | ✓ |
| 메시 LOD | ✓ | ✓ | ✓ |
| VRS (가변 셰이딩) | ✓ | ✓ | ✗ |
| 포비티드 렌더링 (XR) | ✓ | ✓ (4.7에서 대폭 개선) | ✗ |
| HDR 출력 (4.7 신규) | ✓ | ✓ | ✗ |

**렌더러 전환 비용**: 씬·스크립트·머티리얼은 그대로 유지된다. 다만 Forward+ 전용 기능을
쓴 부분은 Mobile에서 무시되며, 조명 결과가 달라진다. 4.7에서 프로젝트 매니저가
렌더링 방식을 표시하므로 실수로 Forward+ 프로젝트를 만들지 않도록 확인한다.

---

## 2. Mobile 렌더러에서 하지 말아야 할 것

**전역 조명**

- `SDFGI`, `VoxelGI` 노드를 추가하지 않는다. 씬에 있어도 렌더링되지 않는다.
- 대신 `LightmapGI`로 정적 지오메트리를 베이킹하고, 동적 오브젝트는
  `LightmapProbe` 또는 `ReflectionProbe`로 처리한다.

**화면공간 효과**

- `WorldEnvironment`의 SSAO / SSIL / SSR 항목을 켜도 아무 일도 일어나지 않는다.
- AO가 필요하면 **텍스처에 베이킹된 AO 맵**을 `StandardMaterial3D`의
  Ambient Occlusion 슬롯에 넣는다. 품질도 화면공간 방식보다 낫다.

**안티에일리어싱**

- TAA/FSR2 대신 `MSAA 3D` (2x/4x) 또는 `FXAA`/`SMAA`를 쓴다.
- 모바일 GPU에서 MSAA는 타일 기반 렌더링 덕분에 비교적 저렴하다. 4x까지는 실용적이다.

**SMAA 1x** — 애드온으로 있던 Godot-SMAA가 엔진에 정식 편입된 것이다.
FXAA보다 **선명한** 결과를 주는 대신 더 비싸다.

```gdscript
# 뷰포트 단위로 지정한다
get_viewport().screen_space_aa = Viewport.SCREEN_SPACE_AA_SMAA   # DISABLED / FXAA / SMAA
```

```ini
[rendering]

anti_aliasing/quality/screen_space_aa="smaa"
anti_aliasing/quality/smaa_edge_detection_threshold=0.05   ; 0.01~0.2. 낮을수록 더 많은 경계를 잡고 비싸다
```

| 방식 | 선명도 | 비용 | 모바일 |
|---|---|---|---|
| `MSAA 3D` 2x/4x | 지오메트리 경계만 깔끔 | 타일 GPU에서 저렴 | **1순위** |
| `FXAA` | 흐릿함 | 가장 쌈 | 저사양 폴백 |
| `SMAA` | 선명 | FXAA보다 비쌈 | 중상급 기기에서 선택지 |

모바일에서는 `MSAA 3D 2x`를 기본으로 두고, 기기 등급이 높을 때만 SMAA를 얹는 편이 낫다.

**Mobile 렌더러의 반정밀도(F16) 부동소수점**

Mobile 렌더러가 하드웨어가 지원하면 **F16(half-precision)을 명시적으로 요청**한다.
F32는 렌더링 용도로는 과할 때가 많은데, F16을 쓰면 대역폭과 전력이 줄어 **프레임 페이싱이
안정되고 발열·배터리 소모가 개선된다.** 최근 기기는 대부분 지원한다.

**켜고 끄는 설정이 아니다.** 하드웨어가 지원하면 자동으로 적용된다. 개발자가 할 일은
셰이더에서 **불필요하게 높은 정밀도를 강요하지 않는 것**이다.
`highp`를 습관적으로 붙이면 이 이득이 사라진다(→ [shaders-3d.md](shaders-3d.md)).

**머티리얼**

- Subsurface Scattering 슬롯을 쓰지 않는다.
- Refraction은 동작하지만 화면 텍스처를 읽으므로 모바일에서 비싸다. 최소화한다.
- Height(Parallax)는 픽셀당 반복 샘플링이므로 모바일에서 피한다.

**조명**

- 실시간 그림자를 켠 광원의 수를 최소화한다. 이상적으로 `DirectionalLight3D` 하나.
- `AreaLight3D`(4.7 신규)는 가장 비싸다. 필요한 곳에만 소수.
- 나머지는 라이트맵으로 굽는다.

---

## 3. StandardMaterial3D 전체 속성

`StandardMaterial3D`는 셰이더를 작성하지 않고 PBR을 다루는 표준 머티리얼이다.
`ORMMaterial3D`는 Occlusion/Roughness/Metallic이 한 텍스처의 RGB 채널에 담긴 변형이다
(glTF 표준 방식, 텍스처 메모리 절약).

### Transparency

| 옵션 | 비용 | 그림자 | 용도 |
|------|------|--------|------|
| `Disabled` | 가장 낮음 | ✓ | 기본값. 불투명한 모든 것 |
| `Alpha` | 높음 | ✗ | 유리, 페이드 인/아웃 |
| `Alpha Scissor` | 낮음 | ✓ | **나뭇잎, 울타리, 풀** — 모바일 권장 |
| `Alpha Hash` | 중간 | ✓ | 디더링 기반. 머리카락 |
| `Depth Pre-Pass` | 매우 높음 | ✓ | 겹치는 반투명의 정렬 문제 해결 |

관련 속성: `alpha_scissor_threshold`(기본 0.5), `alpha_antialiasing_mode`,
`blend_mode`(Mix/Add/Sub/Mul), `cull_mode`(Back/Front/Disabled),
`depth_draw_mode`, `no_depth_test`.

### Shading

| 모드 | 설명 |
|------|------|
| `Per-Pixel` | 픽셀별 조명 계산. 기본값 |
| `Per-Vertex` | 정점별 계산. **저사양 모바일에서 유효한 최적화** |
| `Unshaded` | 조명 무시, albedo 그대로 출력. 가장 빠름. UI 3D·발광체 |

`diffuse_mode`: `Burley`(기본, Disney PBS) / `Lambert` / `Lambert Wrap`(머리·SSS 흉내) / `Toon`
`specular_mode`: `SchlickGGX`(기본) / `Toon` / `Disabled`(반사 제거 — 모바일 절약)

### PBR 핵심 3요소

```
Albedo    — 베이스 색상. 다른 모든 계산의 기준
Metallic  — 0=비금속, 1=금속. 중간값은 물리적으로 드물다
Roughness — 0=거울, 1=완전 확산
```

`metallic_specular`(기본 0.5)는 비금속의 반사 강도를 조절한다.
`metallic_texture_channel` / `roughness_texture_channel`로 텍스처 채널을 지정한다.

### 나머지 속성 그룹

| 그룹 | 핵심 속성 | 비고 |
|------|----------|------|
| **Emission** | `emission`, `emission_energy_multiplier`, `emission_operator` | Mobile에서는 주변 지오메트리에 GI 영향 없음 (VoxelGI/SDFGI 필요) |
| **Normal Map** | `normal_enabled`, `normal_scale` | **OpenGL 규약(Y+)** 필수. DirectX 규약이면 G 채널을 뒤집어야 함 |
| **Rim** | `rim`, `rim_tint` | 가장자리 발광. 값싼 림라이트 |
| **Clearcoat** | `clearcoat`, `clearcoat_roughness` | 4.7에서 Disney PBR에 근접하게 개선. 자동차 도장 |
| **Anisotropy** | `anisotropy`, `anisotropy_flowmap` | 머리카락, 브러시드 메탈 |
| **Ambient Occlusion** | `ao_enabled`, `ao_light_affect`, `ao_texture_channel` | **베이킹 AO 맵이 SSAO보다 품질·성능 모두 우수** |
| **Bent Normal Map** | `bent_normal_enabled`, `bent_normal_texture` | 반사·간접광 정확도 향상 (아래 참고) |
| **Height** | `heightmap_enabled`, `heightmap_scale`, `heightmap_deep_parallax` | 픽셀당 레이마칭. **모바일에서 사용 금지** |
| **Subsurface Scattering** | `subsurf_scatter_enabled` | **Forward+ 전용. Mobile에서 사용 금지** |
| **Back Lighting** | `backlight_enabled`, `backlight` | 얇은 물체 투과광. 나뭇잎 |
| **Refraction** | `refraction_enabled`, `refraction_scale` | 화면 텍스처 읽기. 모바일에서 비쌈 |
| **Detail** | `detail_enabled`, `detail_blend_mode`, `detail_uv_layer` | 근접 시 디테일 추가 |
| **UV1 / UV2** | `uv1_scale`, `uv1_offset`, `uv1_triplanar`, `uv1_world_triplanar` | UV2는 라이트맵용으로 예약됨 |
| **Sampling** | `texture_filter`, `texture_repeat` | `NEAREST`로 픽셀아트/레트로 |
| **Shadows** | `shadow_to_opacity`, `disable_receive_shadows` | |
| **Billboard** | `billboard_mode`, `billboard_keep_scale`, `particles_anim_*` | `ENABLED`/`Y_BILLBOARD`/`PARTICLES` |
| **Grow** | `grow`, `grow_amount` | 정점을 법선 방향으로 밀어냄. 외곽선 |
| **Transform** | `fixed_size`, `use_point_size`, `point_size` | `fixed_size`=거리 무관 동일 크기 |
| **Proximity Fade** | `proximity_fade_enabled`, `proximity_fade_distance` | 다른 지오메트리와 만나는 경계 페이드 (물 가장자리) |
| **Distance Fade** | `distance_fade_mode`, `distance_fade_min/max_distance` | `PIXEL_ALPHA`(느림) / `PIXEL_DITHER` / `OBJECT_DITHER`(가장 빠름) |
| **Stencil** (4.5+) | `stencil_mode`, `stencil_flags`, `stencil_compare`, `stencil_reference` | 외곽선, X-ray, 벽 뚫어보기 (아래 참고) |
| **Material** | `render_priority`, `next_pass`, `cull_mode` | `render_priority`로 반투명 정렬 강제 |

---

### 환경광 스펙큘러 오클루전

빛이 잘 들지 않아야 할 틈새가 **이상하게 반짝이는** 문제가 있었다. 벽돌 사이 홈에
하늘빛이 그대로 반사되는 식이다. 표면에서 반사되는 빛을 계산할 때 **앰비언트
오클루전을 고려하지 않았기** 때문이다.

이제 저렴한 스펙큘러 오클루전 옵션이 이를 해결한다. **기본으로 켜져 있다.**

```ini
[rendering]

reflections/specular_occlusion/enabled=true    ; 기본 true
```

에디터 경로: `Project > Project Settings > Rendering > Reflections >
Specular Occlusion > Enabled`

기존 프로젝트에서 **외형이 달라질 수 있으므로** 끌 수 있게 토글이 제공된다.
이미 조명을 맞춰 둔 씬이 어두워졌다면 이 설정을 의심한다.

AO 맵을 쓰는 머티리얼에서 효과가 크다. 라리엔 3D는 Mobile 렌더러라 SSAO를 못 쓰고
**베이킹된 AO 텍스처**를 쓰므로(→ 2장), 이 기능과 잘 맞는다. 비용도 싸다.

### Bent Normal Map

일반 노멀 맵의 벡터가 **표면에 수직**인 방향을 담는다면, bent normal은 **가림이 가장
적은 방향**(빛이 가장 잘 들어오는 방향)을 담는다. 동굴 안에서 bent normal을 구우면
각 벡터가 입구 쪽을 가리키는 식이다.

이 정보로 렌더러가 두 가지를 개선한다.

1. **스펙큘러 오클루전 강화** — 반사를 많이 받지 않아야 할 곳을 더 정확히 어둡게
2. **간접광 정확도** — 더 그럴듯한 반사

```gdscript
var mat := StandardMaterial3D.new()
mat.normal_enabled = true
mat.normal_texture = load("res://assets/textures/wall_normal.png")

mat.bent_normal_enabled = true                                    # 기본 false
mat.bent_normal_texture = load("res://assets/textures/wall_bent_normal.png")
```

**텍스처를 따로 구워야 한다.** Blender·Substance 등에서 AO를 굽는 것과 같은 절차로
bent normal 맵을 별도로 만든다. 노멀 맵을 그대로 넣으면 안 된다.

**모바일 판단**: 텍스처가 하나 더 늘어 VRAM과 대역폭을 먹는다. 라리엔 3D처럼 카메라가
고정된 각도로 내려다보는 게임에서는 **표면 디테일의 미세한 반사 차이가 잘 드러나지
않는다.** 주인공·보스처럼 화면에서 크게 보이는 대상에 한정해 쓰고, 지형·잡몹에는 쓰지 않는다.

### 스텐실 버퍼 (4.5+)

깊이 버퍼가 "이 픽셀의 거리"를 담는다면, **스텐실 버퍼는 임의의 값을 써 두고
나중에 비교하는** 버퍼다. 값을 직접 정할 수 있고 비교 방식도 고를 수 있다는 점이
깊이 버퍼와 다르다.

**대표적인 쓰임 — 벽 너머의 캐릭터 보기**

캐릭터를 감싸는 보이지 않는 구를 둔다. 이 구는 화면에 그려지지 않지만 **자기 모양을
스텐실 버퍼에 기록**한다. 그리고 벽 셰이더가 "스텐실에 표시된 픽셀이면 그리지 않는다"고
하면, 벽에 캐릭터 모양의 구멍이 뚫린 것처럼 보인다.

라리엔 3D는 카메라를 고정된 각도로 내려다보므로 **건물·지형이 캐릭터를 가리는 상황이
구조적으로 발생한다**(→ CLAUDE.md 카메라 규칙). 스텐실은 그 해법 중 하나다.

> **Mobile 렌더러에서 동작한다.** 스텐실은 Vulkan·D3D12·Metal·GLES3 모든 백엔드에
> 노출되므로, SSR·SSAO와 달리 이 프로젝트에서 실제로 쓸 수 있다.

#### StandardMaterial3D의 스텐실 속성

| 속성 | 타입 | 기본값 | 의미 |
|---|---|---|---|
| `stencil_mode` | `StencilMode` | `DISABLED`(0) | `DISABLED` / `OUTLINE` / `XRAY` / `CUSTOM` |
| `stencil_flags` | 비트 플래그 | `0` | `READ`(1) / `WRITE`(2) / `WRITE_DEPTH_FAIL`(4) |
| `stencil_compare` | `StencilCompare` | `ALWAYS`(0) | 비교 방식 7종 (아래) |
| `stencil_reference` | `int` | `1` | 0~255. 쓰거나 비교할 기준값 |
| `stencil_color` | `Color` | 검정 | `OUTLINE`/`XRAY` 프리셋의 색 |
| `stencil_outline_thickness` | `float` | `0.01` m | `OUTLINE` 프리셋의 두께 |

**비교 방식** — `STENCIL_COMPARE_` 접두사

`ALWAYS`(0) / `LESS`(1) / `EQUAL`(2) / `LESS_OR_EQUAL`(3) /
`GREATER`(4) / `NOT_EQUAL`(5) / `GREATER_OR_EQUAL`(6)

#### 프리셋 — Outline과 X-Ray

`OUTLINE`과 `XRAY`는 **`next_pass`에 미리 구성된 스텐실 머티리얼을 자동으로 넣어 준다.**
직접 셰이더를 짜지 않고 인스펙터에서 색과 두께만 정하면 된다.

```gdscript
# 캐릭터 강조 외곽선
var mat := StandardMaterial3D.new()
mat.stencil_mode = BaseMaterial3D.STENCIL_MODE_OUTLINE
mat.stencil_color = Color(1.0, 0.85, 0.2)
mat.stencil_outline_thickness = 0.02

# 벽 너머에서도 실루엣이 보이게
mat.stencil_mode = BaseMaterial3D.STENCIL_MODE_XRAY
mat.stencil_color = Color(0.3, 0.8, 1.0)
```

`CUSTOM`은 플래그·비교·참조값을 직접 조합할 때 쓴다.

```gdscript
# 마커: 스텐실에 값 1을 기록하기만 한다
var writer := StandardMaterial3D.new()
writer.stencil_mode = BaseMaterial3D.STENCIL_MODE_CUSTOM
writer.stencil_flags = BaseMaterial3D.STENCIL_FLAG_WRITE
writer.stencil_compare = BaseMaterial3D.STENCIL_COMPARE_ALWAYS
writer.stencil_reference = 1

# 벽: 스텐실이 1인 곳에서는 그리지 않는다 (NOT_EQUAL 로 통과 조건을 뒤집는다)
var wall := StandardMaterial3D.new()
wall.stencil_mode = BaseMaterial3D.STENCIL_MODE_CUSTOM
wall.stencil_flags = BaseMaterial3D.STENCIL_FLAG_READ
wall.stencil_compare = BaseMaterial3D.STENCIL_COMPARE_NOT_EQUAL
wall.stencil_reference = 1
```

#### 함정

**1. 스텐실을 쓰는 머티리얼은 항상 투명 패스로 간다**

스텐실 버퍼에 쓰는 머티리얼은 불투명이더라도 **투명 패스에서 그려진다.**
따라서 투명 렌더링의 제약(정렬 문제, 오버드로우 비용)을 그대로 받는다.
모바일에서 큰 면적에 남발하면 성능이 급격히 나빠진다.

**2. 읽기는 투명 패스에서만 가능하다**

불투명 패스에서 스텐실을 읽으려는 시도는 실패한다. 지원되지 않는 동작이다.

**3. 그리는 순서를 직접 잡아야 한다**

기록하는 쪽이 읽는 쪽보다 **먼저** 그려져야 한다. 순서가 뒤집히면 아무 효과가 없다.
`render_priority`로 강제한다(낮을수록 먼저).

```gdscript
writer.render_priority = -1     # 마커를 먼저
wall.render_priority = 0        # 벽을 나중에
```

**4. 값 하나를 여러 효과가 나눠 쓴다**

스텐실 참조값은 0~255의 정수 하나뿐이다. 외곽선·X-ray·투시를 동시에 쓰면
서로 값을 덮어쓴다. **효과별로 참조값을 미리 배분**해 두고 문서에 적어 둔다.

**5. `stencil_color`의 setter 이름이 다르다**

프로퍼티는 `stencil_color`인데 메서드는 `set_stencil_effect_color()`다.
`stencil_outline_thickness` ↔ `set_stencil_effect_outline_thickness()`도 마찬가지다.
`mat.stencil_color = ...` 형태로 프로퍼티를 직접 쓰면 헷갈릴 일이 없다.

---

## 4. 투명도 5종 선택 가이드

**모바일 3D에서 반투명은 가장 큰 성능 위험 요소다.** 오버드로우가 누적되면
프래그먼트 셰이딩 비용이 폭발한다.

```
식생·울타리·격자 → Alpha Scissor    (그림자 O, 저비용)
유리·물          → Alpha            (그림자 X, 소수만)
머리카락         → Alpha Hash       (그림자 O)
페이드 인/아웃   → Distance Fade의 OBJECT_DITHER 또는 Alpha
UI 3D            → Unshaded + Alpha
```

```gdscript
# 나뭇잎 머티리얼
var leaf := StandardMaterial3D.new()
leaf.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA_SCISSOR
leaf.alpha_scissor_threshold = 0.5
leaf.cull_mode = BaseMaterial3D.CULL_DISABLED       # 양면 렌더링
leaf.backlight_enabled = true                       # 투과광
leaf.backlight = Color(0.2, 0.35, 0.1)
```

---

## 5. 머티리얼 코드 조작

```gdscript
@onready var mesh: MeshInstance3D = $MeshInstance3D

# 새 머티리얼 생성
var mat := StandardMaterial3D.new()
mat.albedo_color = Color(0.8, 0.2, 0.2)
mat.metallic = 0.0
mat.roughness = 0.6
mat.albedo_texture = load("res://assets/textures/crate_albedo.png")
mat.normal_enabled = true
mat.normal_texture = load("res://assets/textures/crate_normal.png")
mat.ao_enabled = true
mat.ao_texture = load("res://assets/textures/crate_ao.png")
mesh.material_override = mat

# 기존 머티리얼 수정 — 반드시 복제해야 다른 인스턴스에 영향이 없다
var unique := mesh.get_active_material(0).duplicate() as StandardMaterial3D
unique.albedo_color = Color.RED
mesh.material_override = unique
```

### 인스턴스별 파라미터 (권장 — 배칭 유지)

머티리얼을 복제하면 드로우콜 배칭이 깨진다. 색상만 다르게 하려면 인스턴스 유니폼을 쓴다.

```gdscript
# ShaderMaterial에서 instance uniform 선언
# shader_type spatial;
# instance uniform vec4 tint : source_color = vec4(1.0);
# void fragment() { ALBEDO *= tint.rgb; }

mesh.set_instance_shader_parameter("tint", Color.RED)
```

### 피격 플래시 (실전 패턴)

```gdscript
class_name HitFlash
extends Node

@export var mesh: MeshInstance3D
@export var flash_color: Color = Color(1.0, 0.3, 0.3)
@export var duration: float = 0.12

var _material: StandardMaterial3D
var _original_emission: Color
var _tween: Tween

func _ready() -> void:
    # 한 번만 복제해서 재사용
    _material = mesh.get_active_material(0).duplicate() as StandardMaterial3D
    mesh.material_override = _material
    _original_emission = _material.emission
    _material.emission_enabled = true

func flash() -> void:
    if _tween and _tween.is_running():
        _tween.kill()
    _material.emission = flash_color
    _tween = create_tween()
    _tween.tween_property(_material, "emission", _original_emission, duration)
```

### next_pass 외곽선 (툰 렌더링)

```gdscript
var outline := StandardMaterial3D.new()
outline.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
outline.albedo_color = Color.BLACK
outline.cull_mode = BaseMaterial3D.CULL_FRONT      # 앞면 컬링 → 뒷면만 보임
outline.grow = true
outline.grow_amount = 0.02
base_material.next_pass = outline
```

**원리**: 원본 메시를 법선 방향으로 살짝 부풀리고 앞면을 컬링하면,
원본 실루엣 바깥으로 삐져나온 뒷면만 보여 외곽선이 된다. 모바일에서도 저렴하다.

---

## 6. 조명

| 노드 | 비용 | 용도 |
|------|------|------|
| `DirectionalLight3D` | 낮음 (그림자 켜면 중간) | 태양·달. 씬 전체를 덮음 |
| `OmniLight3D` | 중간 | 전구, 횃불 |
| `SpotLight3D` | 중간 | 손전등, 가로등 |
| `AreaLight3D` (4.7 신규) | **높음** | TV 화면, 광고판, 창문의 부드러운 빛 |

### 공통 속성

```gdscript
light.light_color = Color(1.0, 0.95, 0.85)
light.light_energy = 1.5                     # 밝기
light.light_indirect_energy = 1.0            # 간접광(GI) 기여도
light.light_volumetric_fog_energy = 1.0      # Forward+ 전용
light.light_specular = 1.0                   # 0이면 하이라이트 제거
light.light_cull_mask = 0xFFFFF              # 이 광원이 비출 레이어
light.light_negative = false                 # 어둠을 "칠하는" 음의 광원
light.light_size = 0.0                       # 소프트 섀도우용 광원 크기
light.light_bake_mode = Light3D.BAKE_STATIC  # DISABLED / STATIC / DYNAMIC
light.shadow_enabled = true
```

### light_bake_mode

| 모드 | LightmapGI 베이킹 | 실시간 |
|------|------------------|--------|
| `BAKE_DISABLED` | 굽지 않음 | ✓ 항상 실시간 |
| `BAKE_STATIC` | 직접광+간접광 모두 굽기 | ✗ (베이킹 후 꺼짐) |
| `BAKE_DYNAMIC` | 간접광만 굽기 | ✓ 직접광은 실시간 |

**모바일 전략**: 정적 조명은 `BAKE_STATIC`, 태양처럼 시간에 따라 움직이는 것만
`BAKE_DYNAMIC`, 손전등처럼 완전히 동적인 것만 `BAKE_DISABLED`.

### 노드별 속성

```gdscript
# DirectionalLight3D
dir_light.directional_shadow_mode = DirectionalLight3D.SHADOW_PARALLEL_4_SPLITS
dir_light.directional_shadow_split_1 = 0.1     # 각 캐스케이드 경계 (0~1 비율)
dir_light.directional_shadow_split_2 = 0.2
dir_light.directional_shadow_split_3 = 0.5
dir_light.directional_shadow_blend_splits = true
dir_light.directional_shadow_max_distance = 100.0   # 그림자 렌더 거리 — 성능에 직결
dir_light.directional_shadow_fade_start = 0.8
dir_light.sky_mode = DirectionalLight3D.SKY_MODE_LIGHT_AND_SKY

# OmniLight3D
omni.omni_range = 5.0
omni.omni_attenuation = 1.0                    # 감쇠 커브 (1.0=역제곱)
omni.omni_shadow_mode = OmniLight3D.SHADOW_CUBE   # CUBE(정확) / DUAL_PARABOLOID(빠름)

# SpotLight3D
spot.spot_range = 10.0
spot.spot_angle = 45.0                         # 원뿔 반각(도)
spot.spot_angle_attenuation = 1.0
spot.spot_attenuation = 1.0

# AreaLight3D (4.7 신규)
area_light.size = Vector2(2.0, 1.0)            # 직사각형 크기
area_light.two_sided = false
```

### 물리 광량 단위

`Project Settings → Rendering → Lights and Shadows → Use Physical Light Units`를 켜면
루멘·룩스·켈빈으로 조명을 다룰 수 있다. 실사 조명을 맞출 때 유용하지만
`Camera3D`의 노출 설정과 함께 조정해야 하므로 스타일라이즈드 게임에는 과하다.

---

## 7. 그림자 튜닝

### bias 문제 두 가지

| 증상 | 원인 | 해결 |
|------|------|------|
| **Shadow Acne** — 표면에 줄무늬 그림자 | bias가 너무 낮음 | `shadow_bias` 증가 |
| **Peter-Panning** — 그림자가 물체에서 떨어짐 | bias가 너무 높음 | `shadow_bias` 감소, `shadow_normal_bias` 조정 |

```gdscript
light.shadow_bias = 0.03                # 기본 0.03(directional), 0.02(omni/spot)
light.shadow_normal_bias = 1.0          # 법선 방향 오프셋 — acne에 더 효과적
light.shadow_opacity = 1.0
light.shadow_blur = 1.0
light.shadow_transmittance_bias = 0.05
```

**튜닝 절차**: `shadow_normal_bias`를 먼저 올려 acne를 없애고, peter-panning이
생기면 `shadow_bias`를 낮춘다. 광원마다 개별 조정이 필요하다.

### 모바일 그림자 최적화

```ini
[rendering]

lights_and_shadows/directional_shadow/size=2048          # 기본 4096 → 2048
lights_and_shadows/directional_shadow/size.mobile=1024   # 모바일은 더 낮게
lights_and_shadows/positional_shadow/atlas_size=2048
lights_and_shadows/positional_shadow/atlas_size.mobile=1024
lights_and_shadows/directional_shadow/soft_shadow_filter_quality=1
```

| 필터 품질 | 비용 |
|----------|------|
| `Hard` | 최저 |
| `Soft Very Low` ~ `Soft Low` | 낮음 — **모바일 권장** |
| `Soft Medium` | 중간 |
| `Soft High` / `Soft Ultra` | 높음 |

**가장 효과적인 최적화는 `directional_shadow_max_distance`를 줄이는 것이다.**
100m를 50m로 줄이면 같은 섀도우맵 해상도로 두 배 선명해지고 렌더 대상도 절반이 된다.

---

## 8. LightmapGI 베이킹

Mobile 렌더러에서 전역 조명을 얻는 **유일한 실용적 방법**이다.

### 절차

1. 정적 지오메트리의 `MeshInstance3D`에서 `gi_mode = GI_MODE_STATIC` 설정
2. 각 메시에 **UV2 라이트맵 좌표**가 필요하다
   - glTF 임포트 시: Import 탭에서 `Light Baking = Static (Lightmaps)` 선택
   - 또는 메시 선택 → 상단 `Mesh` 메뉴 → `Unwrap UV2 for Lightmap/AO`
3. 광원의 `light_bake_mode`를 `BAKE_STATIC` 또는 `BAKE_DYNAMIC`으로 설정
4. 씬에 `LightmapGI` 노드 추가
5. `LightmapGI` 선택 → 상단 `Bake Lightmaps` 클릭

### LightmapGI 속성

```gdscript
lightmap.quality = LightmapGI.BAKE_QUALITY_MEDIUM   # LOW/MEDIUM/HIGH/ULTRA
lightmap.bounces = 3                                 # 간접광 반사 횟수
lightmap.bounce_indirect_energy = 1.0
lightmap.use_denoiser = true                         # 노이즈 제거 (권장)
lightmap.denoiser_strength = 0.1
lightmap.directional = false                         # 방향성 라이트맵 (노멀맵과 상호작용, 용량 2배)
lightmap.max_texture_size = 4096
lightmap.environment_mode = LightmapGI.ENVIRONMENT_MODE_SCENE
lightmap.camera_attributes = null
lightmap.generate_probes_subdiv = LightmapGI.GENERATE_PROBES_SUBDIV_8
```

### 동적 오브젝트 조명

라이트맵은 정적 지오메트리만 밝힌다. 움직이는 캐릭터는 **라이트 프로브**로 처리한다.

- `LightmapGI.generate_probes_subdiv`를 `SUBDIV_8` 이상으로 두면 자동 생성된다.
- 특정 위치에 정밀한 프로브가 필요하면 `LightmapProbe` 노드를 수동 배치한다.
- 동적 메시는 `gi_mode = GI_MODE_DYNAMIC`으로 설정한다.

### 베이킹이 실패할 때

| 오류 | 원인 |
|------|------|
| "Mesh has no UV2" | UV2 언랩 필요 |
| "Lightmap size exceeds maximum" | `max_texture_size` 증가 또는 메시 분할 |
| 결과가 검게 나옴 | 광원의 `light_bake_mode`가 `DISABLED` |
| 시간이 매우 오래 걸림 | `quality`를 낮추거나 `bounces` 감소 |

---

## 9. ReflectionProbe

Mobile 렌더러에서 반사를 얻는 방법. SSR이 없으므로 프로브가 필수다.

```gdscript
probe.update_mode = ReflectionProbe.UPDATE_ONCE   # ONCE(정적) / ALWAYS(매 프레임, 비쌈)
probe.intensity = 1.0
probe.max_distance = 0.0                          # 0이면 무제한
probe.size = Vector3(20, 10, 20)                  # 영향 범위
probe.origin_offset = Vector3.ZERO
probe.box_projection = true                       # 실내에서 정확한 반사 (권장)
probe.interior = true                             # 하늘 반사 제외 (실내)
probe.enable_shadows = false                      # 프로브 캡처 시 그림자 (비쌈)
probe.cull_mask = 0xFFFFF
probe.mesh_lod_threshold = 1.0
probe.ambient_mode = ReflectionProbe.AMBIENT_ENVIRONMENT
```

**`UPDATE_ALWAYS`는 매 프레임 큐브맵 6면을 다시 렌더링한다.** 모바일에서는
사실상 사용 불가다. `UPDATE_ONCE`로 두고 필요할 때만 코드로 갱신한다.

```gdscript
# 조명이 크게 바뀌었을 때만 수동 갱신
probe.update_mode = ReflectionProbe.UPDATE_ALWAYS
await get_tree().process_frame
await get_tree().process_frame
probe.update_mode = ReflectionProbe.UPDATE_ONCE
```

**`box_projection`**: 켜면 프로브의 `size` 박스를 기준으로 반사 좌표를 보정한다.
실내에서 벽 반사가 자연스러워지므로 실내 씬에서는 반드시 켠다.

---

### 화면공간 반사(SSR) — 4.7 대개편, 그러나 Forward+ 전용

4.7에서 SSR이 전면 재작성되었다. 거칠기(roughness) 처리가 정확해져 금속·물·유리가
훨씬 사실적으로 보이고, 시간에 따른 깜빡임이 줄었으며, 속도까지 빨라졌다.
해상도도 고를 수 있게 되어 **절반 해상도로도 쓸 만한 품질**이 나온다.

```gdscript
var env := Environment.new()
env.ssr_enabled = true               # 기본 false
env.ssr_max_steps = 64               # 32~512. 광선 추적 단계 수. 늘리면 먼 반사가 잡히고 느려진다
env.ssr_fade_in = 0.15               # 반사가 시작되는 거리에서의 페이드
env.ssr_fade_out = 2.0               # 반사가 사라지는 거리
env.ssr_depth_tolerance = 0.5        # 0.01~128. 깊이 오차 허용치. 낮으면 정확, 높으면 누락이 줄어든다
```

해상도는 **프로젝트 설정**에서 정한다(Environment가 아니다).

```ini
[rendering]

environment/screen_space_reflection/half_size=true    # 기본 true — 절반 해상도
```

에디터 경로: `Project > Project Settings > Rendering > Environment >
Screen Space Reflection > Half Size`

| 값 | 결과 |
|---|---|
| `true` (기본) | 뷰포트의 절반 해상도로 계산. 4.7 개편 덕에 품질 손실이 작다 |
| `false` | 전체 해상도. 최고 품질, 그만큼 비싸다 |

> **이 프로젝트에서는 쓸 수 없다.**
> SSR은 **Forward+ 전용**이다. 라리엔 3D는 Mobile 렌더러이므로
> `ssr_enabled = true`를 넣어도 **아무 일도 일어나지 않는다**(에러도 안 난다).
> 모바일에서 반사가 필요하면 위의 `ReflectionProbe`를 쓴다. 이것이 대안이며,
> 정적인 씬에서는 오히려 더 안정적이다.

---

## 10. WorldEnvironment

씬당 하나만 둔다. `Environment` 리소스와 `CameraAttributes`를 담는다.

```gdscript
var env := Environment.new()

# 배경
env.background_mode = Environment.BG_SKY          # CLEAR_COLOR / COLOR / SKY / CANVAS / KEEP
env.sky = Sky.new()
var sky_mat := ProceduralSkyMaterial.new()
sky_mat.sky_top_color = Color(0.35, 0.55, 0.85)
sky_mat.sky_horizon_color = Color(0.65, 0.72, 0.80)
sky_mat.ground_bottom_color = Color(0.18, 0.16, 0.14)
sky_mat.sun_angle_max = 30.0
env.sky.sky_material = sky_mat
env.sky_custom_fov = 0.0

# 환경광 (Mobile에서 중요 — GI가 없으므로 여기서 기본 밝기를 잡는다)
env.ambient_light_source = Environment.AMBIENT_SOURCE_SKY   # BG / DISABLED / COLOR / SKY
env.ambient_light_color = Color(0.3, 0.32, 0.38)
env.ambient_light_sky_contribution = 1.0
env.ambient_light_energy = 1.0

# 반사
env.reflected_light_source = Environment.REFLECTION_SOURCE_SKY

# 톤매핑 — Mobile에서도 동작
env.tonemap_mode = Environment.TONE_MAPPER_ACES    # LINEAR / REINHARD / FILMIC / ACES / AGX
env.tonemap_exposure = 1.0
env.tonemap_white = 1.0

# Glow (블룸) — Mobile 지원
env.glow_enabled = true
env.glow_intensity = 0.8
env.glow_strength = 1.0
env.glow_bloom = 0.0
env.glow_blend_mode = Environment.GLOW_BLEND_MODE_SOFTLIGHT
env.glow_hdr_threshold = 1.0
env.glow_hdr_scale = 2.0
env.set_glow_level(1, 1.0)      # 레벨별 강도 (1~7)

# 포그 — Mobile 지원 (볼류메트릭은 미지원)
env.fog_enabled = true
env.fog_mode = Environment.FOG_MODE_EXPONENTIAL
env.fog_light_color = Color(0.6, 0.68, 0.78)
env.fog_light_energy = 1.0
env.fog_sun_scatter = 0.1
env.fog_density = 0.008
env.fog_sky_affect = 0.5
env.fog_height = 0.0
env.fog_height_density = 0.0
env.fog_aerial_perspective = 0.0

# 색보정 — Mobile 지원
env.adjustment_enabled = true
env.adjustment_brightness = 1.0
env.adjustment_contrast = 1.05
env.adjustment_saturation = 1.1
env.adjustment_color_correction = load("res://assets/luts/warm.png")

$WorldEnvironment.environment = env
```

### 톤매퍼 선택

| 모드 | 특징 |
|------|------|
| `LINEAR` | 톤매핑 없음. HDR 값이 그대로 클리핑됨 |
| `REINHARD` | 부드럽지만 채도가 빠짐 |
| `FILMIC` | 영화적 대비 |
| `ACES` | 업계 표준. 하이라이트 처리가 우수. **기본 권장** |
| `AGX` (4.3+) | 극단적 밝기에서 색상 유지가 뛰어남 |

### CameraAttributes

```gdscript
var attrs := CameraAttributesPractical.new()
attrs.dof_blur_far_enabled = false          # 피사계 심도 (모바일에서 비쌈)
attrs.auto_exposure_enabled = false         # 자동 노출
$WorldEnvironment.camera_attributes = attrs
```

`CameraAttributesPhysical`을 쓰면 조리개·셔터·ISO로 제어할 수 있지만
물리 광량 단위와 함께 써야 의미가 있다.

---

## 11. Decal

표면에 텍스처를 투영한다. 탄흔, 핏자국, 물웅덩이, 도로 표시에 쓴다.
Mobile 렌더러에서 지원된다.

```gdscript
var decal := Decal.new()
decal.size = Vector3(1.0, 1.0, 1.0)          # Y가 투영 깊이
decal.texture_albedo = load("res://assets/decals/bullet_hole.png")
decal.texture_normal = load("res://assets/decals/bullet_hole_n.png")
decal.texture_orm = null
decal.texture_emission = null
decal.albedo_mix = 1.0
decal.normal_fade = 0.0                      # 급격한 각도에서 페이드
decal.upper_fade = 0.3
decal.lower_fade = 0.3
decal.distance_fade_enabled = true
decal.distance_fade_begin = 20.0
decal.distance_fade_length = 10.0
decal.cull_mask = 1                          # 어느 레이어에 투영할지
add_child(decal)
```

### 탄흔 배치 (실전)

```gdscript
const DECAL_SCENE: PackedScene = preload("res://scenes/vfx/bullet_decal.tscn")
const MAX_DECALS: int = 32

var _decals: Array[Decal] = []

func spawn_bullet_hole(point: Vector3, normal: Vector3) -> void:
    var d: Decal = DECAL_SCENE.instantiate()
    get_tree().current_scene.add_child(d)
    d.global_position = point + normal * 0.01
    # Decal은 -Y 방향으로 투영하므로 법선의 반대가 아래를 향하게 회전
    d.look_at(point - normal, _pick_up_vector(normal))
    d.rotate_object_local(Vector3.RIGHT, PI * 0.5)
    d.rotate_object_local(Vector3.UP, randf() * TAU)   # 랜덤 회전으로 반복감 제거

    _decals.append(d)
    if _decals.size() > MAX_DECALS:
        var old := _decals.pop_front() as Decal
        if is_instance_valid(old):
            old.queue_free()

func _pick_up_vector(normal: Vector3) -> Vector3:
    return Vector3.FORWARD if absf(normal.dot(Vector3.UP)) > 0.99 else Vector3.UP
```

**데칼 개수를 제한하는 이유**: 데칼은 겹칠 때마다 프래그먼트 비용이 누적된다.
모바일에서는 32개 정도가 상한이다.

---

## 12. 파티클

| 노드 | 처리 | 특징 |
|------|------|------|
| `GPUParticles3D` | GPU | 수만 개 가능. Mobile 렌더러 지원 |
| `CPUParticles3D` | CPU | 호환성 최고. 소수 파티클에 적합 |

```gdscript
var particles := GPUParticles3D.new()
particles.amount = 64
particles.lifetime = 1.5
particles.one_shot = true
particles.explosiveness = 1.0          # 1.0이면 한 번에 전부 방출
particles.randomness = 0.3
particles.fixed_fps = 30               # 모바일에서 30으로 낮추면 비용 절감
particles.interpolate = true
particles.local_coords = false
particles.draw_order = GPUParticles3D.DRAW_ORDER_VIEW_DEPTH
particles.visibility_aabb = AABB(Vector3(-5,-5,-5), Vector3(10,10,10))  # 컬링용 — 반드시 설정

var mat := ParticleProcessMaterial.new()
mat.direction = Vector3(0, 1, 0)
mat.spread = 45.0
mat.initial_velocity_min = 3.0
mat.initial_velocity_max = 6.0
mat.gravity = Vector3(0, -9.8, 0)
mat.damping_min = 0.5
mat.damping_max = 1.0
mat.scale_min = 0.5
mat.scale_max = 1.2
mat.color = Color(1.0, 0.7, 0.3)
particles.process_material = mat

var draw := QuadMesh.new()
draw.size = Vector2(0.3, 0.3)
particles.draw_pass_1 = draw
```

### 4.7 신규 — 축별 스케일과 3D 회전

4.7 이전의 파티클은 **한 방향으로만** 크기를 조절할 수 있었고(`scale_min`/`scale_max`가
float), 회전은 화면을 향한 평면 회전(`angle_min`/`angle_max`) 뿐이었다.
그래서 "옆으로 늘어난 불꽃", "축을 중심으로 도는 파편" 같은 표현을 만들 수 없었다.

4.7부터 **축별 스케일(스트레치·스쿼시)과 진짜 3D 회전**이 가능하다.

```gdscript
var mat := ParticleProcessMaterial.new()

# ── 축별 스케일 ──
mat.use_scale_3d = true                          # 기본 false. 켜야 아래 Vector3 가 쓰인다
mat.scale_3d_min = Vector3(0.6, 1.8, 0.6)        # 세로로 늘어난 불꽃
mat.scale_3d_max = Vector3(1.0, 2.6, 1.0)        # min~max 사이에서 파티클마다 랜덤

# ── 3D 회전 (초기 각도) ──
mat.use_rotation_3d = true                       # 기본 false
mat.rotation_3d_min = Vector3(0, 0, 0)           # 라디안
mat.rotation_3d_max = Vector3(TAU, TAU, TAU)     # 모든 축으로 랜덤 방향

# ── 3D 회전 속도 (계속 돈다) ──
mat.use_rotation_velocity_3d = true              # 기본 false
mat.rotation_velocity_3d_min = Vector3(-2.0, -2.0, -2.0)   # 라디안/초
mat.rotation_velocity_3d_max = Vector3( 2.0,  2.0,  2.0)
```

**세 개의 `use_*` 플래그가 전부 기본 `false`다.** 켜지 않으면 Vector3 값을
아무리 넣어도 무시되고 기존 float 방식이 그대로 쓰인다. 가장 흔한 실수다.

| 프로퍼티 | 타입 | 기본값 | 의미 |
|---|---|---|---|
| `use_scale_3d` | `bool` | `false` | 축별 스케일 사용 |
| `scale_3d_min` / `scale_3d_max` | `Vector3` | `(1,1,1)` | 축별 스케일 범위 |
| `use_rotation_3d` | `bool` | `false` | 3D 초기 회전 사용 |
| `rotation_3d_min` / `rotation_3d_max` | `Vector3` | `(0,0,0)` | 초기 회전 범위(라디안) |
| `use_rotation_velocity_3d` | `bool` | `false` | 3D 회전 속도 사용 |
| `rotation_velocity_3d_min` / `_max` | `Vector3` | `(0,0,0)` | 회전 속도 범위(라디안/초) |
| `rotation_velocity_3d_curve` | `Texture2D` | `null` | 수명에 따른 회전 속도 곡선 |

**기존 float 방식과의 관계**

| 기존 (계속 유효) | 4.7 신규 | 차이 |
|---|---|---|
| `scale_min` / `scale_max` (float) | `scale_3d_min` / `_max` (Vector3) | 균일 확대 vs 축별 |
| `angle_min` / `angle_max` (float) | `rotation_3d_min` / `_max` (Vector3) | 평면 회전 vs 3축 회전 |

**주의 — `scale_over_velocity_min`/`_max`는 `float`다.** 이름이 비슷해 Vector3를
넣기 쉽지만 타입이 다르다. 속도에 따라 크기를 바꾸는 별개의 기능이다.

**메시를 쓸 때만 의미가 있다**

`draw_pass_1`이 `QuadMesh`처럼 카메라를 향하는 빌보드면 3D 회전 효과가 잘 안 보인다.
파편·돌조각처럼 입체 메시를 쓸 때 값어치가 나온다.

```gdscript
# 튀는 파편 — 입체 메시 + 3축 회전
particles.draw_pass_1 = preload("res://vfx/debris_chunk.res")
mat.use_rotation_3d = true
mat.use_rotation_velocity_3d = true
mat.rotation_velocity_3d_min = Vector3(-6, -6, -6)
mat.rotation_velocity_3d_max = Vector3( 6,  6,  6)
```

**모바일 비용**: 축별 스케일과 3D 회전은 파티클마다 변환 행렬을 더 계산한다.
`GPUParticles3D`에서는 GPU가 처리하므로 부담이 작지만, `CPUParticles3D`에서는
파티클 수에 비례해 CPU 비용이 늘어난다. 모바일에서 많은 수를 쓸 때는 `amount`를
먼저 줄인다.

**모바일 파티클 주의사항**

- `visibility_aabb`를 반드시 설정한다. 없으면 컬링이 안 되어 화면 밖에서도 그린다.
- `fixed_fps = 30`으로 시뮬레이션 빈도를 낮춘다.
- 파티클 머티리얼의 투명도는 오버드로우를 만든다. 큰 반투명 파티클을 많이 겹치지 않는다.
- `Trail`은 비싸다. 꼭 필요할 때만.

---

## 13. 렌더 레이어와 뷰포트

### VisualInstance3D 레이어

```gdscript
mesh.layers = 1                      # 비트마스크 (1~20)
mesh.set_layer_mask_value(2, true)

camera.cull_mask = 0b0001            # 레이어 1만 렌더링
light.light_cull_mask = 0b0011       # 레이어 1,2만 비춤
```

**용도**: 1인칭 무기를 별도 레이어에 두고 전용 카메라로 렌더링하면
벽에 무기가 파묻히는 문제를 해결할 수 있다.

```gdscript
# 씬 구조
# Player
#  ├─ MainCamera (Camera3D, cull_mask = 월드 레이어)
#  └─ WeaponViewport (SubViewport)
#     └─ WeaponCamera (Camera3D, cull_mask = 무기 레이어, near = 0.01)
#        └─ WeaponModel
```

### SubViewport (3D를 텍스처로)

```gdscript
# 미니맵, 캐릭터 초상화, 감시 카메라 모니터
var sub := SubViewport.new()
sub.size = Vector2i(256, 256)
sub.render_target_update_mode = SubViewport.UPDATE_ALWAYS
sub.transparent_bg = true
sub.msaa_3d = Viewport.MSAA_DISABLED       # 모바일 비용 절감
add_child(sub)

var cam := Camera3D.new()
sub.add_child(cam)

# 결과를 TextureRect나 머티리얼에 사용
$MinimapRect.texture = sub.get_texture()
```

**성능 주의**: `UPDATE_ALWAYS`인 SubViewport는 매 프레임 씬을 한 번 더 그린다.
모바일에서는 `UPDATE_WHEN_VISIBLE`을 쓰거나 해상도를 낮춘다.

---

## 14. 자주 하는 실수

| 실수 | 증상 | 해결 |
|------|------|------|
| Mobile에서 SDFGI/SSAO/SSR 활성화 | 아무 변화 없음 | LightmapGI + AO 텍스처 사용 |
| 머티리얼 수정이 전체에 반영 | 리소스 공유 | `duplicate()` 또는 `set_instance_shader_parameter` |
| 노멀맵이 반대로 보임 | DirectX 규약 텍스처 | G 채널 반전, 또는 OpenGL 규약으로 재출력 |
| Alpha 투명 물체에 그림자 없음 | `TRANSPARENCY_ALPHA`의 제약 | `ALPHA_SCISSOR` 또는 `ALPHA_HASH` |
| 반투명 물체 정렬이 이상함 | 뎁스 정렬 한계 | `render_priority` 조정 또는 `DEPTH_PRE_PASS` |
| 그림자에 줄무늬(acne) | bias 부족 | `shadow_normal_bias` 증가 |
| 그림자가 떠 있음 | bias 과다 | `shadow_bias` 감소 |
| 라이트맵 베이킹 실패 | UV2 없음 | `Unwrap UV2 for Lightmap` 실행 |
| 라이트맵 결과가 검음 | `light_bake_mode = DISABLED` | `BAKE_STATIC`으로 변경 |
| 파티클이 화면 밖에서도 그려짐 | `visibility_aabb` 미설정 | AABB 설정 |
| `ReflectionProbe.UPDATE_ALWAYS` | 프레임 폭락 | `UPDATE_ONCE` 사용 |
| Emission이 주변을 밝히지 않음 | Mobile은 GI 없음 | 별도 `OmniLight3D` 배치 |
| `far`가 매우 큼 | Z-fighting | 필요한 거리만 |
| SubViewport 항상 갱신 | 프레임 저하 | `UPDATE_WHEN_VISIBLE` |
| 그림자 최대 거리가 과함 | 그림자가 흐림 + 느림 | `directional_shadow_max_distance` 축소 |
