# 성능 최적화와 내보내기

## 목차

0. [🛑 최소 지원 사양 — 3GB RAM Android 가 기준이다](#0--최소-지원-사양--3gb-ram-android-가-기준이다)
1. [핵심 개념 — 측정 없이 최적화하지 않는다](#1-핵심-개념--측정-없이-최적화하지-않는다)
2. [CPU/GPU 병목 구분 절차](#2-cpugpu-병목-구분-절차)
3. [프로파일러 읽는 법](#3-프로파일러-읽는-법)
4. [렌더링 최적화 — 드로우콜 줄이기](#4-렌더링-최적화--드로우콜-줄이기)
5. [메시 LOD와 가시 범위](#5-메시-lod와-가시-범위)
6. [오클루전 컬링](#6-오클루전-컬링)
7. [MultiMeshInstance3D](#7-multimeshinstance3d)
8. [조명 — 🛑 저사양에서는 광원을 하나도 두지 않는다](#8-조명--저사양에서는-광원을-하나도-두지-않는다)
9. [CPU 최적화](#9-cpu-최적화)
10. [물리 최적화](#10-물리-최적화)
11. [메모리와 텍스처](#11-메모리와-텍스처)
12. [모바일 전용 설정](#12-모바일-전용-설정)
13. [빌드와 내보내기 → export-build.md](#13-빌드와-내보내기--export-buildmd)
14. [기능 태그와 플랫폼별 설정](#14-기능-태그와-플랫폼별-설정)
15. [자주 하는 실수](#15-자주-하는-실수)

---

## 0. 🛑 최소 지원 사양 — 3GB RAM Android 가 기준이다

> ### 🛑 이 절은 요약이다 — 실제 작업은 [lowend-3gb-60fps.md](lowend-3gb-60fps.md) 를 본다
>
> **모바일 3D MMORPG 의 최소 지원 RAM 은 3GB 다.**
>
> 🛑 **드로우콜·GPU 만 보지 말고 메모리도 예산으로 잡는다.** 반복 배치를 병합하면
> 정점이 개수만큼 복제되어 **메모리를 400배** 쓴다 —
> 나무 1,000그루 기준 MultiMesh 81 KB vs 병합 33 MB
> (→ [lowend-3gb-60fps.md §5.3](lowend-3gb-60fps.md#53--multimesh-vs-병합--메모리를-400배-내는-거래)). 프로시저럴 → **빌드 타임 베이킹**,
> 병목을 실험으로 가려내는 절차, 조명을 정점 컬러에 굽는 법, 스킨드 캐릭터 30명 이상,
> 저사양 크래시 회피가 그 문서에 A12 실측과 함께 정리되어 있다.

> **이 프로젝트의 성능 목표는 "요즘 폰에서 잘 도는 것"이 아니다.
> 10년 전에 나온 저가 안드로이드 폰에서 60fps 가 나오는 것이다.**
>
> **FPS 와 메모리가 다른 모든 것에 우선한다.** 그래픽 품질·기능·편의는
> 이 기준을 넘긴 뒤에 논의한다. 반대 순서로 하지 않는다.

### 기준 기기 — 여기서 60fps 가 안 나오면 채택하지 않는다

| 항목 | 값 |
|---|---|
| **기기** | **Samsung Galaxy A12 (SM-A125N)** |
| SoC | MediaTek MT6765 (Helio P35) · arm64-v8a 8코어 |
| **GPU** | **PowerVR Rogue GE8320** |
| **RAM** | **2,808,852 kB — 물리 3GB** |
| OS / API | Android 12 (SDK 31) · **Vulkan 1.1.131** · Forward Mobile |
| 화면 | 720 × 1600 |
| **텍스처 압축** | **`astc_ldr` 만 지원 — 🛑 ASTC HDR 없음** |

**"중급기 30fps" 같은 목표를 세우지 않는다.** 이 기기에서 **60fps** 를 낸다.

### 🛑 실측이 뒤집은 것 — 병목은 폴리곤도 드로우콜도 아니다

아래는 전부 **위 실기기에서 Mobile 렌더러로 직접 잰 값**이다. 추정이 아니다.

**① 삼각형은 병목이 아니다** (지형 1개, DC 1, 조건 동일, A/B 반복)

| 바닥 삼각형 | 2 | 20,000 | 200,000 | **200,000 + 조명 끔** |
|---|---|---|---|---|
| FPS | 22.3 | 20.7 | 16.4 | **60.0** |

삼각형을 **10만 배** 늘려도 22.3 → 16.4 다. 그런데 **같은 20만 삼각형에 조명만 끄면 60fps** 다.

**② 드로우콜도 생각보다 여유가 있다** (18tri 메시, 개수만 증가)

| DC | 100 | 300 | 654 | **898** |
|---|---|---|---|---|
| FPS | 60.0 | 60.0 | 60.1 | **57.3** |

**③ 진짜 병목은 픽셀당 셰이딩(fill rate) 이다**

| 바닥 조건 | DC | 삼각형 | FPS |
|---|---|---|---|
| 바닥 없음 | 0 | 0 | 60.0 |
| **바닥 1장 (실시간 조명)** | **1** | **2** | **🛑 22.3** |
| 바닥 1장 + 렌더스케일 0.7 | 1 | 2 | 38.5 |
| 바닥 1장 + 렌더스케일 0.5 | 1 | 2 | 46.0 |
| **바닥 1장 (조명 끔 · UNSHADED)** | **1** | **2** | **✅ 60.0** |

**삼각형 2개짜리 면 하나가 60 → 22fps 로 떨어뜨린다.** 화면을 덮는 픽셀에
조명 계산을 하는 것이 이 기기에서 가장 비싼 일이다.

### 그래서 지키는 규범 셋

| # | 규범 | 근거 |
|---|---|---|
| **1** | **조명을 쓰지 않는다** — 실시간도, 라이트맵도 (→ §8) | 22.3 / 1.0 fps vs **60.0** |
| **2** | **반복 배치는 무조건 `MultiMeshInstance3D`** (→ §7) | Mobile 렌더러엔 자동 인스턴싱이 없다 |
| **3** | **폴리곤을 아끼느라 시간 쓰지 않는다** | 20만 삼각형까지 실질 무해 |

### 메모리 — 실측상 여유가 크다

나무 5,220그루(MultiMesh 27개) + UI 를 띄운 상태:

```
정적 메모리 80.5 MB · VRAM 19.6 MB
```

**3GB 폰에서 OOM 을 피하는 안전선(약 1,120 MB)의 7%** 다.
**메모리보다 GPU 가 훨씬 먼저 막힌다.**

### 🛑 저사양 기기에서만 터지는 함정

| 함정 | 증상 | 대처 |
|---|---|---|
| **ASTC HDR 미지원** | `Image format ASTC_4x4_HDR not supported` → **SIGSEGV 크래시** | HDR 텍스처(.exr 등)의 임포트에서 `compress/hdr_compression = Disabled`. 애초에 HDR 텍스처를 쓰지 않는 것이 낫다 |
| **Forward+ 에만 있는 자동 인스턴싱** | 데스크톱에서 DC 2, 실기기에서 **DC 300** | 개발 PC 의 드로우콜 수치를 믿지 않는다. → §7 |
| **첫 케이스가 항상 느리다** | 셰이더 컴파일이 측정 구간에 섞인다 | 같은 조건을 **두 번 이상** 재고 두 번째 값을 쓴다 |

> **개발 PC 에서 잰 값은 근거가 되지 못한다.** 이 문서의 수치는 전부 실기기 값이며,
> 새로운 판단이 필요하면 **실기기에서 다시 잰다.**

---

## 1. 핵심 개념 — 측정 없이 최적화하지 않는다

Godot 공식 문서의 성능 철학: **"속도와 사용성·유연성 사이에는 항상 트레이드오프가 있다."**

최적화의 순서는 고정되어 있다.

```
1. 문제가 있는지 확인한다        — 목표 프레임레이트에 실제로 못 미치는가
2. 병목이 CPU인지 GPU인지 가른다  — 이 판단이 틀리면 모든 노력이 헛수고다
3. 프로파일러로 원인을 특정한다   — 추측하지 않는다
4. 가장 비싼 것부터 고친다        — 상위 3개가 보통 전체의 80%다
5. 다시 측정한다                 — 개선됐는지 확인
```

**목표 설정 (이 프로젝트)** — 기준은 §0 의 최소 지원 사양이다.

| 플랫폼 | 목표 |
|--------|------|
| **Android 저사양 (3GB · Galaxy A12 급)** | **60fps (16.6ms)** ← 🛑 이것이 기준이다 |
| Android 중급기 이상 | 60fps (여유) |
| Steam(데스크톱) | 60fps 이상 |

🛑 **"저사양은 30fps 로 타협한다"를 기본값으로 두지 않는다.** §0 실측대로
조명을 쓰지 않으면 A12 에서도 60fps 가 나온다. 30fps 로 내리는 것은
그 이후에 판단할 일이다.

---

## 2. CPU/GPU 병목 구분 절차

### 판별 방법

**방법 1: 해상도 테스트 (가장 빠름)**

```gdscript
# 렌더 해상도를 절반으로 낮춘다
get_viewport().scaling_3d_scale = 0.5
```

- 프레임레이트가 **크게 오르면 → GPU 병목** (픽셀 처리가 문제)
- **거의 변화 없으면 → CPU 병목** (스크립트/물리/드로우콜 제출이 문제)

**방법 2: 모니터 값 확인**

```gdscript
func _process(_delta: float) -> void:
    var fps := Engine.get_frames_per_second()
    var draw_calls := Performance.get_monitor(Performance.RENDER_TOTAL_DRAW_CALLS_IN_FRAME)
    var primitives := Performance.get_monitor(Performance.RENDER_TOTAL_PRIMITIVES_IN_FRAME)
    var objects := Performance.get_monitor(Performance.RENDER_TOTAL_OBJECTS_IN_FRAME)
    var process_time := Performance.get_monitor(Performance.TIME_PROCESS)
    var physics_time := Performance.get_monitor(Performance.TIME_PHYSICS_PROCESS)
    var mem := Performance.get_monitor(Performance.MEMORY_STATIC)
    var video_mem := Performance.get_monitor(Performance.RENDER_VIDEO_MEM_USED)
```

| 지표 | CPU 병목 신호 | GPU 병목 신호 |
|------|--------------|--------------|
| `TIME_PROCESS` + `TIME_PHYSICS_PROCESS` | 프레임 시간의 대부분 | 작음 |
| 드로우콜 수 | 매우 많음 (>2000) | 상관 없음 |
| 해상도 축소 효과 | 없음 | 큼 |
| 화면 밖을 보면 | 그대로 느림 | 빨라짐 |

### 주요 Performance 모니터

```gdscript
Performance.TIME_FPS
Performance.TIME_PROCESS                            # _process 총 시간
Performance.TIME_PHYSICS_PROCESS                    # _physics_process 총 시간
Performance.TIME_NAVIGATION_PROCESS
Performance.MEMORY_STATIC                           # 정적 메모리
Performance.OBJECT_COUNT
Performance.OBJECT_NODE_COUNT
Performance.OBJECT_ORPHAN_NODE_COUNT                # 누수 감지 — 0이어야 정상
Performance.OBJECT_RESOURCE_COUNT
Performance.RENDER_TOTAL_OBJECTS_IN_FRAME
Performance.RENDER_TOTAL_PRIMITIVES_IN_FRAME        # 삼각형 수
Performance.RENDER_TOTAL_DRAW_CALLS_IN_FRAME
Performance.RENDER_VIDEO_MEM_USED
Performance.RENDER_TEXTURE_MEM_USED
Performance.RENDER_BUFFER_MEM_USED
Performance.PHYSICS_3D_ACTIVE_OBJECTS
Performance.PHYSICS_3D_COLLISION_PAIRS
Performance.PHYSICS_3D_ISLAND_COUNT
Performance.AUDIO_OUTPUT_LATENCY
```

### 디버그 오버레이 (완성 코드)

```gdscript
# res://scenes/debug/perf_overlay.gd
extends CanvasLayer

@onready var label: Label = $Label

var _accum: float = 0.0

func _ready() -> void:
    process_mode = Node.PROCESS_MODE_ALWAYS
    visible = OS.is_debug_build()

func _input(event: InputEvent) -> void:
    if event is InputEventKey:
        var k := event as InputEventKey
        if k.pressed and k.keycode == KEY_F3 and not k.echo:
            visible = not visible

func _process(delta: float) -> void:
    if not visible:
        return
    _accum += delta
    if _accum < 0.25:
        return
    _accum = 0.0

    var draw_calls := Performance.get_monitor(Performance.RENDER_TOTAL_DRAW_CALLS_IN_FRAME)
    var prims := Performance.get_monitor(Performance.RENDER_TOTAL_PRIMITIVES_IN_FRAME)
    var proc_ms := Performance.get_monitor(Performance.TIME_PROCESS) * 1000.0
    var phys_ms := Performance.get_monitor(Performance.TIME_PHYSICS_PROCESS) * 1000.0
    var vram := Performance.get_monitor(Performance.RENDER_VIDEO_MEM_USED) / 1048576.0
    var mem := Performance.get_monitor(Performance.MEMORY_STATIC) / 1048576.0
    var orphans := Performance.get_monitor(Performance.OBJECT_ORPHAN_NODE_COUNT)
    var bodies := Performance.get_monitor(Performance.PHYSICS_3D_ACTIVE_OBJECTS)

    label.text = """FPS      : %d
draw call: %d
삼각형    : %s
process  : %.2f ms
physics  : %.2f ms
VRAM     : %.1f MB
RAM      : %.1f MB
고아 노드 : %d
활성 바디 : %d""" % [
        Engine.get_frames_per_second(), draw_calls,
        String.num_uint64(int(prims)), proc_ms, phys_ms,
        vram, mem, orphans, bodies
    ]
```

**`OBJECT_ORPHAN_NODE_COUNT`가 계속 증가하면 메모리 누수다.**
트리에서 뗀 노드를 `free()`하지 않았거나 순환 참조가 있다.

---

## 3. 프로파일러 읽는 법

에디터 하단 `Debugger → Profiler` 탭에서 실행 중 측정한다.

| 항목 | 의미 |
|------|------|
| Frame Time | 전체 프레임 시간 |
| Process Time | `_process` 총합 |
| Physics Time | `_physics_process` + 물리 서버 |
| Physics Frame | 물리 프레임 |
| Script Functions | **함수별 자체 시간과 총 시간** |

**Self Time(자체 시간)이 큰 함수를 먼저 본다.** Total Time이 큰 것은
하위 호출이 무거운 경우가 많다.

### Visual Profiler

`Debugger → Visual Profiler`는 GPU 단계별 시간을 보여준다.

| 단계 | 무엇이 비싼가 |
|------|--------------|
| Shadow Map | 그림자 렌더링 — 광원 수·거리·해상도 |
| Depth Pre-Pass | 뎁스 프리패스 |
| Opaque | 불투명 지오메트리 — 드로우콜·셰이더 복잡도 |
| Transparent | 반투명 — 오버드로우 |
| Post Process | 후처리 — Glow, 톤매핑 |

**모바일에서 Shadow Map이 전체의 30% 이상이면** 그림자 설정부터 손본다.

### 커스텀 측정

```gdscript
func expensive_operation() -> void:
    var start := Time.get_ticks_usec()
    _do_work()
    var elapsed := Time.get_ticks_usec() - start
    if elapsed > 1000:      # 1ms 초과 시만 로그
        print("작업 시간: %.2f ms" % (elapsed / 1000.0))
```

---

## 4. 렌더링 최적화 — 드로우콜 줄이기

**드로우콜 = CPU가 GPU에 "이걸 그려라"라고 명령하는 횟수.**
각 호출에 고정 오버헤드가 있어 모바일에서는 개수 자체가 병목이 된다.

| 플랫폼 | 권장 드로우콜 상한 |
|--------|------------------|
| 모바일 저사양 | ~300 |
| 모바일 중급 | ~800 |
| 데스크톱 | ~2000 |

### 줄이는 방법

**1. 머티리얼 개수를 줄인다**

머티리얼이 다르면 드로우콜이 분리된다. 텍스처 아틀라스로 여러 오브젝트가
한 머티리얼을 공유하게 만든다.

**2. 메시를 병합한다**

정적 오브젝트(벽, 바닥 타일)는 하나의 메시로 합친다.

```gdscript
# 런타임 병합 (에디터 도구로 만드는 게 더 좋다)
func merge_meshes(parent: Node3D) -> ArrayMesh:
    var surface := SurfaceTool.new()
    surface.begin(Mesh.PRIMITIVE_TRIANGLES)
    for child in parent.get_children():
        if child is MeshInstance3D:
            var mi := child as MeshInstance3D
            surface.append_from(mi.mesh, 0, mi.transform)
    surface.index()
    surface.generate_normals()
    surface.generate_tangents()
    return surface.commit()
```

**3. 자동 인스턴싱을 활용한다**

같은 메시 + 같은 머티리얼이면 Godot이 자동으로 인스턴싱한다.
**변형(다른 머티리얼)을 만들지 말고 `instance uniform`으로 색을 바꾼다.**

**4. MultiMeshInstance3D를 쓴다** (7절 참고)

**5. 머티리얼 복제를 피한다**

`material.duplicate()`는 배칭을 깬다. `set_instance_shader_parameter()`를 쓴다.

### 오버드로우 줄이기

반투명 픽셀이 겹치면 같은 픽셀을 여러 번 셰이딩한다.
모바일 GPU에서 가장 흔한 병목이다.

- 큰 반투명 파티클을 겹치지 않는다
- `Alpha` 대신 `Alpha Scissor`를 쓴다
- 반투명 오브젝트 수를 제한한다
- 파티클의 `amount`를 줄이고 텍스처로 대체한다

---

## 5. 메시 LOD와 가시 범위

### 자동 메시 LOD

glTF 임포트 시 `Generate LODs`를 켜면 Godot이 자동으로 단순화된 버전을 만든다.
거리에 따라 자동 전환된다.

```gdscript
mesh_instance.lod_bias = 1.0      # 낮출수록 더 일찍 LOD 전환 (성능↑ 품질↓)
```

```ini
[rendering]

mesh_lod/lod_change/threshold_pixels=1.0        # 화면상 크기 임계값
mesh_lod/lod_change/threshold_pixels.mobile=4.0 # 모바일은 더 공격적으로
```

### 가시 범위 (HLOD)

멀어지면 아예 안 그리거나 다른 노드로 교체한다.

```gdscript
# 소품은 30m 밖에서 사라진다
prop.visibility_range_begin = 0.0
prop.visibility_range_begin_margin = 0.0
prop.visibility_range_end = 30.0
prop.visibility_range_end_margin = 5.0        # 페이드 구간
prop.visibility_range_fade_mode = GeometryInstance3D.VISIBILITY_RANGE_FADE_SELF
```

| 페이드 모드 | 동작 |
|------------|------|
| `VISIBILITY_RANGE_FADE_DISABLED` | 즉시 사라짐 (팝핑) |
| `VISIBILITY_RANGE_FADE_SELF` | 자기 자신이 페이드 아웃 |
| `VISIBILITY_RANGE_FADE_DEPENDENCIES` | 부모/자식과 교차 페이드 |

**계층적 LOD 구성**

```
Building (Node3D)
├─ DetailedModel (MeshInstance3D)     range_end = 50, FADE_SELF
└─ SimpleModel (MeshInstance3D)       range_begin = 45, FADE_DEPENDENCIES
```

가까이서는 상세 모델, 멀리서는 단순 모델을 그린다.

### VisibleOnScreenEnabler3D

화면 밖 오브젝트의 **처리(스크립트)** 까지 멈춘다.
`visible = false`는 렌더링만 막지 `_process`는 계속 돈다.

```
Enemy (CharacterBody3D)
└─ VisibleOnScreenEnabler3D          enable_node_path = ".." (부모)
                                     aabb = 적절한 크기
```

```gdscript
enabler.enable_mode = VisibleOnScreenEnabler3D.ENABLE_MODE_INHERIT
# ENABLE_MODE_INHERIT / ENABLE_MODE_ALWAYS / ENABLE_MODE_WHEN_PAUSED
```

**주의**: 화면 밖 적이 완전히 멈추면 플레이어가 돌아봤을 때 부자연스럽다.
AI는 저빈도로 계속 돌리고, 애니메이션·이펙트만 끄는 편이 낫다.

---

## 6. 오클루전 컬링

건물 뒤에 가려진 물체를 그리지 않는다. Mobile 렌더러에서도 지원된다.

### 설정

1. `Project Settings → Rendering → Occlusion Culling → Use Occlusion Culling` 켜기
2. 씬에 `OccluderInstance3D` 추가
3. 상단 `Bake Occluders` 클릭 (씬 전체의 정적 지오메트리를 자동 수집)

또는 메시 이름에 `-occ` / `-occonly` 접미사를 붙여 임포트 시 자동 생성.

```gdscript
occluder.bake_mask = 0xFFFFFFFF        # 어떤 레이어를 오클루더로 구울지
occluder.bake_simplification_distance = 0.1
```

### 개별 오브젝트 설정

```gdscript
# 이 메시가 다른 것을 가리는가 (기본 false — 베이킹된 오클루더만 사용)
mesh.ignore_occlusion_culling = false
```

### 효과가 있는 경우와 없는 경우

| 효과 큼 | 효과 없음 |
|---------|----------|
| 실내, 복도, 도시 | 개활지, 평원 |
| 큰 벽·건물이 시야를 막음 | 시야가 트여 있음 |
| 오브젝트가 많음 | 오브젝트가 적음 |

오클루전 컬링 자체도 CPU를 쓴다. 개활지 맵에서는 오히려 손해다.

---

## 7. MultiMeshInstance3D

**같은 메시를 수백~수만 개 그릴 때 드로우콜을 1개로 만든다.**
풀, 나무, 바위, 파편에 필수적이다.

```gdscript
class_name GrassField
extends MultiMeshInstance3D

@export var grass_mesh: Mesh
@export var count: int = 2000
@export var area_size: float = 40.0
@export var material: Material

func _ready() -> void:
    var mm := MultiMesh.new()
    mm.transform_format = MultiMesh.TRANSFORM_3D
    mm.use_colors = true                  # 인스턴스별 색상
    mm.use_custom_data = false            # 인스턴스별 커스텀 vec4
    mm.mesh = grass_mesh
    mm.instance_count = count

    var rng := RandomNumberGenerator.new()
    rng.seed = 12345                      # 고정 시드 — 매번 같은 배치

    for i in count:
        var pos := Vector3(
            rng.randf_range(-area_size, area_size),
            0.0,
            rng.randf_range(-area_size, area_size)
        )
        pos.y = _sample_terrain_height(pos)

        var basis := Basis()
        basis = basis.rotated(Vector3.UP, rng.randf() * TAU)
        basis = basis.scaled(Vector3.ONE * rng.randf_range(0.8, 1.3))

        mm.set_instance_transform(i, Transform3D(basis, pos))
        # 색 변주로 반복감 제거
        mm.set_instance_color(i, Color(
            rng.randf_range(0.85, 1.0),
            rng.randf_range(0.9, 1.0),
            rng.randf_range(0.8, 1.0)
        ))

    multimesh = mm
    material_override = material
    # 컬링용 AABB를 반드시 설정한다
    custom_aabb = AABB(
        Vector3(-area_size, -1, -area_size),
        Vector3(area_size * 2, 5, area_size * 2)
    )
    cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF   # 풀은 그림자 끔

func _sample_terrain_height(_pos: Vector3) -> float:
    return 0.0
```

### 런타임 인스턴스 조작

```gdscript
# 개수 조절 (visible_instance_count로 일부만 그리기)
mm.visible_instance_count = 500       # -1이면 전부

# 개별 변환 갱신 (비쌈 — 매 프레임 전체 갱신은 피한다)
mm.set_instance_transform(idx, new_transform)
var t := mm.get_instance_transform(idx)
mm.set_instance_custom_data(idx, Color(time_offset, 0, 0, 0))
```

### 셰이더에서 인스턴스 데이터 사용

```glsl
shader_type spatial;

void vertex() {
    // COLOR는 set_instance_color로 설정한 값
    // INSTANCE_CUSTOM은 set_instance_custom_data로 설정한 값
    float phase = INSTANCE_CUSTOM.r;
    VERTEX.x += sin(TIME + phase) * 0.1 * COLOR.a;
}

void fragment() {
    ALBEDO = base_color.rgb * COLOR.rgb;
}
```

### MultiMesh의 한계

- 모든 인스턴스가 **같은 메시, 같은 머티리얼**이어야 한다
- 개별 인스턴스에 충돌·스크립트를 붙일 수 없다
- 인스턴스 개수를 자주 바꾸면 버퍼 재할당이 일어난다

충돌이 필요하면 별도의 `StaticBody3D`를 배치하거나,
플레이어 근처에만 동적으로 콜리전을 생성한다.

---

## 8. 조명 — 🛑 저사양에서는 광원을 하나도 두지 않는다

### 🛑 "LightmapGI 는 런타임 비용 0" 은 A12 에서 사실이 아니다

이 문서는 오랫동안 라이트맵을 가장 싼 선택지로 적어 두었으나, **실기기 측정 결과
정반대였다.** 같은 지형(900×900m · 삼각형 200 · DC 1)을 조건만 바꿔 잰 값이다.

| 조명 방식 | FPS | |
|---|---|---|
| **`LightmapGI` 베이크 적용** | **🛑 1.0** | 실시간 조명보다 **16배 느리다** |
| 실시간 `DirectionalLight3D` 1개 (그림자 없음) | 16.2 ~ 22.3 | |
| **광원 없음 (`SHADING_MODE_UNSHADED`)** | **✅ 55.5 ~ 60.0** | |

라이트맵 텍스처는 **128×128 · 64 KB** 로 아주 작았고, 포맷을 `RGBE9995` → `RGBAHalf`
로 바꿔도 **1.0 fps 그대로**였다. 크기 문제도 포맷 문제도 아니다.

> **결론 — 저사양 안드로이드를 지원하려면 조명을 아예 쓰지 않는다.**
> 실시간 조명도, 라이트맵도 쓰지 않는다. 광원 노드를 씬에 두지 않는다.

### 그럼 어떻게 입체감을 내는가 — **정점 컬러에 굽는다**

조명을 끄면 화면이 평평해진다. 해법은 **런타임에 조명을 계산하지 않고,
빌드 타임에 계산해 정점 컬러로 저장하는 것**이다.

```gdscript
# 빌드 타임 — 툴 스크립트에서 한 번
var ndotl := maxf(normal.dot(-sun_dir), 0.0)
var lit := ambient + sun_color * ndotl        # 조명을 여기서 계산한다
st.set_color(Color(lit.x, lit.y, lit.z))
st.add_vertex(p)
```

```gdscript
# 런타임 머티리얼 — 픽셀당 조명 계산이 0 이다
mat.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
mat.vertex_color_use_as_albedo = true
```

**정점 컬러 보간은 래스터라이저가 공짜로 해 준다.** 픽셀 셰이더는 텍스처 한 번
읽고 곱하기만 한다. 이것이 A12 에서 60fps 를 내는 유일하게 검증된 조합이다.

| | 라이트맵 | **정점 컬러 굽기** |
|---|---|---|
| 런타임 픽셀 비용 | 텍스처 샘플 + 셰이딩 경로 | **곱하기 하나** |
| UV2 필요 | ✅ | ❌ |
| 베이크 도구 | 에디터 GUI 전용 (CLI 불가) | **툴 스크립트로 자동화 가능** |
| A12 실측 | **1.0 fps** | **60.0 fps** |
| 그림자 | 구워짐 | 직접 계산해 넣어야 함 (AO 근사 등) |

### 고사양 기기에서만 조명을 켜고 싶다면

**기본값을 "조명 없음"으로 두고**, 고사양에서만 켜는 방향으로만 확장한다.
반대로 하면 저사양이 기본에서 탈락한다 (→ §12 저사양 기기 자동 감지).

### (참고) 광원을 쓸 수 있는 기기에서의 비용 순위

```
AreaLight3D + 그림자      ← 가장 비쌈 (4.7 신규)
SpotLight3D + 그림자
OmniLight3D + 그림자 (Cube)
OmniLight3D + 그림자 (Dual Paraboloid)
DirectionalLight3D + 그림자 (4 splits)
DirectionalLight3D + 그림자 (1 split)
그림자 없는 광원들
LightmapGI                ← 🛑 저사양에서는 오히려 가장 느리다 (위 실측)
```

### 그림자 설정 축소

```ini
[rendering]

lights_and_shadows/directional_shadow/size=4096
lights_and_shadows/directional_shadow/size.mobile=1024
lights_and_shadows/directional_shadow/soft_shadow_filter_quality=2
lights_and_shadows/directional_shadow/soft_shadow_filter_quality.mobile=0
lights_and_shadows/positional_shadow/atlas_size=4096
lights_and_shadows/positional_shadow/atlas_size.mobile=1024
lights_and_shadows/positional_shadow/soft_shadow_filter_quality.mobile=0
```

```gdscript
# 그림자 거리 축소가 가장 효과적이다
dir_light.directional_shadow_max_distance = 40.0     # 기본 100
dir_light.directional_shadow_mode = DirectionalLight3D.SHADOW_PARALLEL_2_SPLITS
dir_light.directional_shadow_fade_start = 0.9

# 원거리 광원 자동 페이드
omni.distance_fade_enabled = true
omni.distance_fade_begin = 20.0
omni.distance_fade_length = 5.0
omni.distance_fade_shadow = 15.0       # 그림자는 더 일찍 끔
```

### 그림자 캐스팅 제어

```gdscript
# 작은 소품은 그림자를 만들지 않는다
small_prop.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF

# 그림자만 만들고 자신은 안 보임 (프록시 메시)
shadow_proxy.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_SHADOW_ONLY
```

**Shadow Mesh (임포트 옵션)**: 그림자 렌더링용 저폴리 메시를 자동 생성한다.
그림자 패스의 정점 처리 비용이 크게 줄어든다. **반드시 켠다.**

---

## 9. CPU 최적화

### 원칙

```gdscript
# 1. _process에서 매 프레임 할 필요 없는 것은 타이머로
var _ai_timer: float = 0.0

func _physics_process(delta: float) -> void:
    _ai_timer -= delta
    if _ai_timer <= 0.0:
        _ai_timer = 0.2          # 초당 5회면 충분
        _update_ai_decision()
    _update_movement(delta)      # 이동은 매 프레임

# 2. 노드 참조를 캐시한다
@onready var player: Node3D = get_tree().get_first_node_in_group("player")
# get_node()를 매 프레임 호출하지 않는다

# 3. 거리 비교는 제곱으로
if global_position.distance_squared_to(target) < range_sq:
    pass

# 4. 문자열 대신 StringName
tree.set(&"parameters/blend", 0.5)
if node.is_in_group(&"enemies"):
    pass

# 5. 배열 조회 결과를 캐시
# 나쁨: for e in get_tree().get_nodes_in_group("enemies") (매 프레임)
# 좋음: 그룹 변경 시에만 갱신하거나, 스포너가 배열을 유지
```

### 시간 분할 (Time Slicing)

많은 오브젝트를 프레임마다 나눠서 처리한다.

```gdscript
class_name EnemyManager
extends Node

const UPDATES_PER_FRAME: int = 4

var _enemies: Array[Enemy] = []
var _cursor: int = 0

func _physics_process(_delta: float) -> void:
    if _enemies.is_empty():
        return
    for i in mini(UPDATES_PER_FRAME, _enemies.size()):
        var e := _enemies[_cursor]
        _cursor = (_cursor + 1) % _enemies.size()
        if is_instance_valid(e):
            e.update_expensive_ai()
```

적 100마리가 있어도 프레임당 4마리만 무거운 판단을 한다.
전체 갱신 주기는 25프레임(약 0.4초)이며, 실제로 체감되지 않는다.

### 서버 API 직접 사용

노드 오버헤드를 없애고 렌더링 서버를 직접 쓴다.
수천 개의 단순 시각 요소에만 쓴다.

```gdscript
var instance := RenderingServer.instance_create()
RenderingServer.instance_set_base(instance, mesh.get_rid())
RenderingServer.instance_set_scenario(instance, get_world_3d().scenario)
RenderingServer.instance_set_transform(instance, transform)
# 해제
RenderingServer.free_rid(instance)
```

**대부분의 경우 MultiMesh로 충분하다.** 서버 API는 최후의 수단이다.

### 멀티스레딩

```gdscript
# WorkerThreadPool — 짧은 병렬 작업
var task_id := WorkerThreadPool.add_task(_heavy_work)
WorkerThreadPool.wait_for_task_completion(task_id)

# 그룹 작업
var group_id := WorkerThreadPool.add_group_task(_process_chunk, chunk_count)
WorkerThreadPool.wait_for_group_task_completion(group_id)

func _process_chunk(index: int) -> void:
    # 스레드에서 실행됨 — 씬 트리를 건드리면 안 된다
    pass
```

**스레드 안전 규칙**

- 씬 트리 조작(`add_child`, `queue_free`)은 메인 스레드에서만
- 노드 프로퍼티 변경도 메인 스레드에서 (`call_deferred` 사용)
- 순수 계산(경로 탐색 전처리, 노이즈 생성, 메시 생성)은 스레드에서 가능
- `Mutex`, `Semaphore`로 공유 데이터 보호

---

## 10. 물리 최적화

```gdscript
# 1. 마스크를 0으로 — 감지당하기만 하는 바디
hitbox.collision_layer = LAYER_ENEMY_HITBOX
hitbox.collision_mask = 0            # 능동 스캔 안 함 → 비용 절감

# 2. 슬립을 활용한다
rb.can_sleep = true                  # 기본값 유지

# 3. 안 쓰는 물리 처리는 끈다
set_physics_process(false)

# 4. RayCast3D를 필요할 때만 켠다
ray.enabled = false
# ... 필요 시
ray.enabled = true
ray.force_raycast_update()

# 5. Area3D의 monitorable 끄기
area.monitoring = true               # 내가 감지한다
area.monitorable = false             # 남이 나를 감지하지 않는다 → 비용 절감
```

### 물리 틱 조정

```ini
[physics]

common/physics_ticks_per_second=60
common/physics_ticks_per_second.mobile=30      # 모바일은 30으로 낮출 수 있다
common/max_physics_steps_per_frame=8
```

물리 틱을 30으로 낮추면 물리 비용이 절반이 된다.
다만 빠른 물체의 터널링 위험이 커지고 조작 반응이 둔해진다.
**액션 게임에서는 60을 유지하고 다른 곳을 최적화한다.**

### 콜리전 셰이프 단순화

```
느림: ConcavePolygonShape3D (trimesh) — 정적 지형에만
     ↓
     ConvexPolygonShape3D
     ↓
     CylinderShape3D
     ↓
     BoxShape3D
     ↓
     CapsuleShape3D
     ↓
빠름: SphereShape3D
```

**시각 메시와 콜리전 메시를 분리한다.** 10만 폴리곤 바위의 콜리전을
trimesh로 만들면 안 된다. 박스 몇 개로 근사한다.

---

## 11. 메모리와 텍스처

### VRAM 사용량 계산

```
비압축 RGBA8 2048×2048 = 2048 × 2048 × 4 = 16MB
VRAM 압축 (ETC2/ASTC)    = 약 2.7MB  (1/6)
밉맵 추가                = 약 +33%
```

**모바일 VRAM 예산**

| 기기 등급 | 텍스처 예산 |
|----------|------------|
| 저사양 | ~200MB |
| 중급 | ~400MB |
| 고급 | ~800MB |

### 확인

```gdscript
var vram := Performance.get_monitor(Performance.RENDER_VIDEO_MEM_USED) / 1048576.0
var tex := Performance.get_monitor(Performance.RENDER_TEXTURE_MEM_USED) / 1048576.0
print("VRAM %.1f MB (텍스처 %.1f MB)" % [vram, tex])
```

### 리소스 해제

```gdscript
# 리소스는 참조 카운트로 관리된다. 참조가 사라지면 자동 해제
var tex: Texture2D = load("res://big.png")
tex = null                                   # 다른 참조가 없으면 해제

# 캐시 상태 확인
# 로드된 리소스 목록은 --verbose 실행 시 확인 가능
```

### 메모리 누수 감지

```gdscript
# 게임 종료 시 또는 씬 전환 후
var orphans := Performance.get_monitor(Performance.OBJECT_ORPHAN_NODE_COUNT)
if orphans > 0:
    push_warning("고아 노드 %d개 — 누수 가능성" % orphans)
    # 디버그 빌드에서 상세 목록 출력
    print_orphan_nodes()
```

**흔한 누수 원인**

- `remove_child()` 후 `free()` 누락
- 순환 참조 (`RefCounted` 간 상호 참조)
- 시그널 연결이 남은 채로 노드만 제거
- 람다가 노드를 캡처한 채 살아 있음

---

## 12. 모바일 전용 설정

### 렌더링

```ini
[rendering]

renderer/rendering_method="mobile"
renderer/rendering_method.mobile="mobile"

textures/vram_compression/import_etc2_astc=true      # Android 필수
textures/default_filters/anisotropic_filtering_level=1
textures/default_filters/use_nearest_mipmap_filter=false

anti_aliasing/quality/msaa_3d=1                       # 2x
anti_aliasing/quality/msaa_3d.mobile=1
anti_aliasing/quality/screen_space_aa=0               # FXAA 대신 MSAA
anti_aliasing/quality/use_taa=false                   # Mobile 미지원

scaling_3d/mode=0                                     # Bilinear
scaling_3d/scale=1.0
scaling_3d/scale.mobile=0.85                          # 렌더 해상도 85%

environment/defaults/default_clear_color=Color(0.1,0.1,0.12,1)
occlusion_culling/use_occlusion_culling=true

mesh_lod/lod_change/threshold_pixels.mobile=4.0
```

### 해상도 스케일링

가장 효과 대비 구현 비용이 낮은 최적화다.

```gdscript
# 동적 해상도 조절
func _adjust_resolution_scale() -> void:
    var fps := Engine.get_frames_per_second()
    var vp := get_viewport()
    if fps < 27 and vp.scaling_3d_scale > 0.6:
        vp.scaling_3d_scale = maxf(0.6, vp.scaling_3d_scale - 0.05)
    elif fps > 55 and vp.scaling_3d_scale < 1.0:
        vp.scaling_3d_scale = minf(1.0, vp.scaling_3d_scale + 0.02)
```

3D 렌더링만 축소되고 UI는 원 해상도로 유지되므로 체감 품질 저하가 적다.

### 프레임레이트 제한

```gdscript
Engine.max_fps = 60                    # 발열·배터리 절약
Engine.max_fps = 30                    # 저사양 기기

DisplayServer.window_set_vsync_mode(DisplayServer.VSYNC_ENABLED)
```

**모바일에서 무제한 fps는 해롭다.** 배터리를 소모하고 발열로 스로틀링이 걸려
결과적으로 더 느려진다. 명시적으로 제한한다.

### 저사양 기기 자동 감지

```gdscript
func detect_quality_tier() -> int:
    var name := RenderingServer.get_video_adapter_name()
    var mem := OS.get_memory_info().get("physical", 0) / 1073741824.0    # GB

    if OS.has_feature("mobile"):
        if mem < 3.0:
            return 0        # 저사양
        elif mem < 6.0:
            return 1        # 중급
        return 2            # 고급
    return 2

func apply_quality(tier: int) -> void:
    var vp := get_viewport()
    match tier:
        0:
            Engine.max_fps = 30
            vp.scaling_3d_scale = 0.7
            vp.msaa_3d = Viewport.MSAA_DISABLED
            _set_shadow_size(512)
            _set_shadow_distance(25.0)
        1:
            Engine.max_fps = 60
            vp.scaling_3d_scale = 0.85
            vp.msaa_3d = Viewport.MSAA_2X
            _set_shadow_size(1024)
            _set_shadow_distance(40.0)
        2:
            Engine.max_fps = 60
            vp.scaling_3d_scale = 1.0
            vp.msaa_3d = Viewport.MSAA_4X
            _set_shadow_size(2048)
            _set_shadow_distance(60.0)
```

---

## 13. 빌드와 내보내기 → [export-build.md](export-build.md)

**빌드·설치·실행·릴리즈 절차 전체는 [export-build.md](export-build.md) 와 플랫폼별 문서로
옮겼다.** 이 문서는 "게임을 빠르게 만드는 법"을, 그쪽은 "게임을 앱으로 만드는 법"을 다룬다.

### 여기서 꼭 알아야 할 것만

**export template 은 export 할 때만 필요하다.** 개발 중 반복하는 루프
(`godot --path .` 실행, `--headless` 검사, `--export-pack`)는 템플릿 **0개**로 돈다.

필요한 파일은 **지금 만드는 플랫폼의, 지금 쓰는 모드 하나**뿐이다. Android APK 를 만들 때
`ios.zip`·`macos.zip`·`windows*.exe` 는 한 번도 열리지 않는다.

| 작업 | 필요한 파일 |
|---|---|
| Android 테스트 APK (`--export-debug`, gradle off) | `android_debug.apk` |
| Android Gradle 빌드 (APK/AAB 무관) | `android_source.zip` **만** |
| macOS | `macos.zip` |
| Windows debug / release | `windows_debug_x86_64.exe` / `windows_release_x86_64.exe` |
| iOS | `ios.zip` |

⚠️ 템플릿이 없을 때 오류는 **없는 파일을 전부 나열**한다. 그게 전부 필수라는 뜻이 아니다.

**패치 배포(Patch PCK)와 델타 인코딩**도 내보내기 주제이므로
[export-build.md](export-build.md) 에 있다. 바뀐 리소스만 담아 배포 용량을 줄이는 방법이다.

### 플랫폼별 문서

**[export-build.md](export-build.md)** — 템플릿 개념과 작업별 필요 파일 판정표(4.7.2 실측),
에디터 선택 설치와 CLI TPZ 설치, `--export-debug`/`--export-release`/`--export-pack`/
`--install-android-build-template` 전체 규칙, 실패 시 오류 메시지 해석표,
`export_presets.cfg` 포맷, 이 프로젝트에서 누가 무엇을 수정할 수 있는지의 경계를 담는다.

**[export-build-android.md](export-build-android.md)** — JDK·SDK·에디터 경로 준비부터
`--export-debug` 로 테스트 APK 를 만들고 `adb install -r` 로 설치해 `adb logcat -s godot`
으로 로그를 보는 반복 루프, debug keystore 자동 생성, 서명 충돌 시 `adb uninstall`,
릴리즈 keystore 와 환경변수 주입, `use_gradle_build`/`export_format` 으로 APK·AAB 를 가르는
규칙, GABE, 권한 최소화, **네이티브 스플래시와 부트 스플래시의 이중 구조**를 담는다.

**[export-build-ios.md](export-build-ios.md)** — Godot 이 Xcode 프로젝트까지만 만들고
서명·아카이브는 Xcode 가 맡는 2단계 구조, `export_project_only` 의 의미,
시뮬레이터(`xcrun simctl`)와 실기기(`xcrun devicectl`) 설치·실행, Console.app 로그,
TestFlight·App Store 업로드를 담는다.

**[export-build-desktop.md](export-build-desktop.md)** — macOS 서명·공증과 Gatekeeper,
Windows 의 debug/release 템플릿 분리와 `.console.exe`, Linux·Steam Deck, `embed_pck`,
렌더러 선택(d3d12·Mobile), GodotSteam 연동, 크로스 플랫폼 빌드 스크립트를 담는다.

---

## 14. 기능 태그와 플랫폼별 설정

### 오버라이드 문법

`project.godot`에서 설정 이름 뒤에 `.태그`를 붙이면 그 플랫폼에서만 적용된다.

```ini
[rendering]

anti_aliasing/quality/msaa_3d=2                # 기본: 4x
anti_aliasing/quality/msaa_3d.mobile=1         # 모바일: 2x
anti_aliasing/quality/msaa_3d.android=0        # 안드로이드: 끔

lights_and_shadows/directional_shadow/size=4096
lights_and_shadows/directional_shadow/size.mobile=1024

[physics]

common/physics_ticks_per_second=60
common/physics_ticks_per_second.mobile=60
```

**우선순위**: 더 구체적인 태그가 이긴다 (`android` > `mobile` > 기본).

### 기본 제공 기능 태그

```
windows, macos, linux, bsd, android, ios, web
mobile, pc, web_android, web_ios
editor, template, template_debug, template_release
debug, release
x86_32, x86_64, arm32, arm64, rv64, wasm32
double, single          (부동소수점 정밀도)
etc2, s3tc, bptc, astc  (텍스처 압축)
movie                   (무비 라이터 모드)
```

### 코드에서 확인

```gdscript
if OS.has_feature("mobile"):
    Engine.max_fps = 30
if OS.has_feature("android"):
    _setup_touch_controls()
if OS.has_feature("debug"):
    _enable_debug_ui()
if OS.has_feature("template_release"):
    _disable_cheats()

# 커스텀 태그 (내보내기 프리셋의 Features에 추가)
if OS.has_feature("demo"):
    _limit_to_first_level()
```

### 오버라이드 조회의 함정

```gdscript
# 오버라이드가 적용된 값을 얻는다
var msaa := ProjectSettings.get_setting("rendering/anti_aliasing/quality/msaa_3d")

# 오버라이드를 무시하고 기본값만 얻는다
var base := ProjectSettings.get_setting_with_override("rendering/anti_aliasing/quality/msaa_3d")
```

**주의**: `get_setting()`은 실행 중인 플랫폼의 오버라이드가 이미 반영된 값을 반환한다.
`.mobile` 오버라이드를 별도로 조회할 수는 없다.

---

## 15. 자주 하는 실수

| 실수 | 결과 | 해결 |
|------|------|------|
| 측정 없이 최적화 | 시간 낭비 | 프로파일러 먼저 |
| CPU/GPU 병목 오판 | 엉뚱한 곳 개선 | 해상도 테스트로 판별 |
| 머티리얼 복제 남용 | 드로우콜 급증 | `instance uniform` |
| `visibility_aabb` 미설정 (파티클) | 컬링 실패 | AABB 설정 |
| `custom_aabb` 미설정 (MultiMesh) | 컬링 실패 | AABB 설정 |
| 모든 오브젝트가 그림자 캐스팅 | 그림자 패스 폭증 | 작은 소품은 `SHADOW_CASTING_OFF` |
| `directional_shadow_max_distance` 과다 | 흐리고 느림 | 필요한 거리만 |
| trimesh 콜리전을 동적 바디에 | 경고·부정확 | 단순 셰이프로 근사 |
| `Engine.max_fps` 미설정 (모바일) | 발열·스로틀링 | 30 또는 60으로 제한 |
| 텍스처를 Lossless로 임포트 | VRAM 폭증 | `VRAM Compressed` |
| ETC2/ASTC 미활성화 | Android 빌드 실패 또는 거대한 용량 | `import_etc2_astc=true` |
| 매 프레임 `get_nodes_in_group()` | CPU 낭비 | 캐시 |
| 매 프레임 전체 AI 갱신 | 프레임 저하 | 시간 분할 |
| 키스토어 분실 | Play 스토어 업데이트 불가 | 백업 필수 |
| 불필요한 Android 권한 | 스토어 심사 문제 | 최소 권한 |
| APK로 Play 업로드 시도 | 거부됨 | AAB 사용 |
| 고아 노드 누적 | 메모리 누수 | `OBJECT_ORPHAN_NODE_COUNT` 감시 |
| `x86_64` 아키텍처 포함 (Android 릴리스) | 용량 증가 | `arm64-v8a`만 |
