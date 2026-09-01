# 3D 물리 — Jolt Physics

이 프로젝트는 `project.godot`에서 `3d/physics_engine="Jolt Physics"`로 설정되어 있다.
모든 물리 코드는 Jolt 기준으로 작성한다.

## 목차

1. [핵심 개념 — 물리 서버는 별도 틱으로 돈다](#1-핵심-개념--물리-서버는-별도-틱으로-돈다)
2. [4가지 충돌체 선택 기준](#2-4가지-충돌체-선택-기준)
3. [콜리전 레이어와 마스크](#3-콜리전-레이어와-마스크)
4. [콜리전 셰이프 선택](#4-콜리전-셰이프-선택)
5. [CharacterBody3D 전체 속성](#5-characterbody3d-전체-속성)
6. [1인칭 캐릭터 컨트롤러 (완성 코드)](#6-1인칭-캐릭터-컨트롤러-완성-코드)
7. [3인칭 캐릭터 컨트롤러 (완성 코드)](#7-3인칭-캐릭터-컨트롤러-완성-코드)
8. [move_and_collide와 커스텀 충돌 처리](#8-move_and_collide와-커스텀-충돌-처리)
9. [RigidBody3D](#9-rigidbody3d)
10. [Area3D](#10-area3d)
11. [RayCast3D와 ShapeCast3D](#11-raycast3d와-shapecast3d)
12. [직접 공간 질의 (PhysicsDirectSpaceState3D)](#12-직접-공간-질의-physicsdirectspacestate3d)
13. [조인트](#13-조인트)
14. [Jolt 고유 사항](#14-jolt-고유-사항)
15. [물리 보간과 프로젝트 설정](#15-물리-보간과-프로젝트-설정)
16. [자주 하는 실수](#16-자주-하는-실수)

---

## 1. 핵심 개념 — 물리 서버는 별도 틱으로 돈다

Godot의 물리는 **고정 틱**(기본 60Hz)으로 돌고, 렌더링은 가변 프레임레이트로 돈다.
이 둘은 별개의 루프다.

```
렌더 프레임 (가변, 예: 144fps)  ──┬─ _process(delta)
                                  │
물리 틱 (고정, 60Hz)          ────┴─ _physics_process(delta)   delta = 1/60 고정
```

**결론적 규칙**

- 바디를 움직이거나 물리 상태를 읽는 코드는 반드시 `_physics_process`에 둔다.
- `_process`에서 `move_and_slide()`를 부르면 물리 틱과 어긋나 지터와 터널링이 생긴다.
- 물리 콜백(`_on_body_entered` 등) 안에서는 물리 상태를 직접 바꿀 수 없다.
  `call_deferred()`로 미룬다.

```gdscript
func _on_area_body_entered(body: Node3D) -> void:
    # 물리 쿼리 도중이므로 여기서 노드를 추가/제거하면 경고 또는 크래시
    _spawn_effect.call_deferred(global_position)
    queue_free()          # queue_free는 이미 지연 실행이므로 안전
```

---

## 2. 4가지 충돌체 선택 기준

| 노드 | 물리 엔진이 움직이나 | 충돌 감지 | 용도 |
|------|-------------------|----------|------|
| `Area3D` | ✗ | ✓ (겹침만) | 트리거, 감지 영역, 중력/감쇠 오버라이드 |
| `StaticBody3D` | ✗ | ✓ | 지형, 벽, 움직이지 않는 구조물 |
| `RigidBody3D` | ✓ | ✓ | 상자, 배럴, 파편, 물리 퍼즐 |
| `CharacterBody3D` | ✗ (코드가 움직임) | ✓ | 플레이어, 적, NPC |

### 선택 규칙

- **캐릭터는 무조건 `CharacterBody3D`다.** `RigidBody3D`로 캐릭터를 만들면
  계단·경사·정지 제어가 극도로 어렵다.
- 움직이는 발판·엘리베이터는 `AnimatableBody3D`(`StaticBody3D` 파생)를 쓴다.
  `sync_to_physics=true`이면 위에 탄 `CharacterBody3D`를 함께 밀어준다.
- 파괴 가능한 벽처럼 상태가 바뀌는 것은 `RigidBody3D` + `freeze=true`로 시작해
  파괴 시 `freeze=false`로 전환한다.

---

## 3. 콜리전 레이어와 마스크

**가장 많이 혼동하는 부분이다. 정확히 구분하라.**

- `collision_layer` — **"나는 어느 레이어에 있는가"** (남이 나를 찾을 수 있는 채널)
- `collision_mask` — **"나는 어느 레이어를 감지하는가"** (내가 스캔하는 채널)

A가 B를 감지하려면 `A.collision_mask`와 `B.collision_layer`가 겹쳐야 한다.
**방향성이 있다.** A는 B를 감지하지만 B는 A를 감지하지 않는 설정이 가능하다.

### 이 프로젝트의 레이어 설계 (권장)

```ini
# project.godot
[layer_names]

3d_physics/layer_1="World"        # 지형·벽·정적 구조물
3d_physics/layer_2="Player"
3d_physics/layer_3="Enemy"
3d_physics/layer_4="PlayerHitbox"  # 플레이어 공격 판정
3d_physics/layer_5="EnemyHitbox"   # 적 공격 판정
3d_physics/layer_6="Pickup"        # 아이템
3d_physics/layer_7="Interactable"  # 상호작용 대상
3d_physics/layer_8="Projectile"
3d_physics/layer_9="Trigger"       # 컷신·영역 트리거
3d_physics/layer_10="Camera"       # SpringArm 충돌 전용
```

### 코드에서 설정

```gdscript
# 비트 위치는 1부터 시작하지만 값은 2^(n-1)
const LAYER_WORLD: int      = 1 << 0   # 1
const LAYER_PLAYER: int     = 1 << 1   # 2
const LAYER_ENEMY: int      = 1 << 2   # 4
const LAYER_PLAYER_HIT: int = 1 << 3   # 8
const LAYER_ENEMY_HIT: int  = 1 << 4   # 16

func _ready() -> void:
    collision_layer = LAYER_PLAYER
    collision_mask = LAYER_WORLD | LAYER_ENEMY

    # 개별 비트 조작 (레이어 번호는 1부터)
    set_collision_layer_value(2, true)     # 레이어 2 켜기
    set_collision_mask_value(3, false)     # 마스크 3 끄기
    var on := get_collision_layer_value(2)
```

`@export_flags_3d_physics var mask: int = 1`로 인스펙터에서 시각적으로 지정할 수도 있다.

### 히트박스/허트박스 패턴

```gdscript
# 플레이어의 검(공격 판정)
#   collision_layer = PlayerHitbox
#   collision_mask  = Enemy
# → 적을 감지하지만 적은 이 검을 감지하지 않는다

# 적의 몸(피격 판정)
#   collision_layer = Enemy
#   collision_mask  = 0            ← 아무것도 감지하지 않음. 감지당하기만 함
```

마스크를 0으로 두면 그 바디는 능동적으로 스캔하지 않으므로 물리 비용이 줄어든다.

---

## 4. 콜리전 셰이프 선택

성능 순서: **구 > 캡슐 > 박스 > 실린더 > 볼록 다면체 >> 삼각형 메시**

| 셰이프 | 용도 | 비고 |
|--------|------|------|
| `SphereShape3D` | 발사체, 픽업 | 가장 빠름 |
| `CapsuleShape3D` | **캐릭터** | 계단·경사에서 걸리지 않음. 캐릭터 표준 |
| `BoxShape3D` | 상자, 벽, 플랫폼 | |
| `CylinderShape3D` | 기둥, 배럴 | Jolt에서 박스보다 비쌈 |
| `ConvexPolygonShape3D` | 복잡한 동적 오브젝트 | 임포트 시 `-convcol` 접미사로 자동 생성 |
| `ConcavePolygonShape3D` (trimesh) | **정적 지형만** | 동적 바디에 쓰면 안 됨. `-col`/`-colonly` 접미사 |
| `HeightMapShape3D` | 지형 | 대규모 지형에 최적 |
| `SeparationRayShape3D` | 경사 처리 보조 | |
| `WorldBoundaryShape3D` | 무한 평면 (낙사 방지) | 정적 전용 |

### 캐릭터 캡슐 설정

```gdscript
# CollisionShape3D의 CapsuleShape3D
# height = 전체 높이(양 끝 반구 포함), radius = 반지름
# 캐릭터 키 1.8m → height 1.8, radius 0.35 정도
# CollisionShape3D의 position.y = height * 0.5 로 두어 발이 원점에 오게 한다
```

### 에디터에서 메시로 콜리전 만들기

`MeshInstance3D`를 선택하면 3D 뷰포트 상단에 `Mesh` 메뉴가 뜬다.
`Mesh > Create Collision Shape...`를 고르면 셰이프 종류와 배치 방식을 정할 수 있다.

**Collision Shape Type**

| 타입 | 만들어지는 것 | 쓰는 곳 |
|---|---|---|
| **Primitive** | 메시가 프리미티브면 그에 맞는 `Box`/`Sphere`/`Cylinder`/`Capsule` 셰이프 | **4.6 신규.** 아래 참고 |
| `Bounding Box` | 메시 AABB를 감싸는 `BoxShape3D` | 대충 막아도 되는 오브젝트 |
| `Single Convex` | `ConvexPolygonShape3D` 하나 | 동적 오브젝트 기본 선택 |
| `Simplified Convex` | 단순화된 볼록 셰이프 | 폴리곤이 많을 때 |
| `Multiple Convex` | 여러 개의 볼록 셰이프로 분해 | 오목한 형태의 동적 오브젝트 |
| `Trimesh` | `ConcavePolygonShape3D` | **정적 지형 전용** |

**Collision Shape Placement**: `Sibling`(형제 노드로) 또는 `Static Body Child`
(`StaticBody3D`를 자식으로 만들고 그 아래에 붙임).

#### Primitive 타입 — 4.6에서 추가

이전에는 상자 하나에 콜리전을 붙이려 해도 셰이프 종류를 직접 고르고 크기와 위치를
손으로 맞춰야 했다. 4.6부터 **메시가 단순한 기하 형태면 맞는 셰이프를 자동으로 생성**한다.

에디터 설명 원문: *"Creates a box, capsule, cylinder, or sphere primitive collision
shape if the mesh is a primitive."*

`BoxMesh` → `BoxShape3D`, `SphereMesh` → `SphereShape3D`,
`CylinderMesh` → `CylinderShape3D`, `CapsuleMesh` → `CapsuleShape3D`로 크기까지 맞춰 붙는다.

**왜 중요한가**: 프리미티브 셰이프는 볼록·삼각형 셰이프보다 **훨씬 빠르다**(위 성능 순서 참고).
예전에는 귀찮아서 `Single Convex`로 대충 넘어가기 쉬웠는데, 이제 상자·구·기둥은
한 번의 클릭으로 최적의 셰이프를 얻는다. 프로토타이핑에서 특히 값어치가 크다.

**한계**: 이름 그대로 **메시가 프리미티브일 때만** 동작한다. Blender에서 가져온
일반 메시는 대상이 아니다. `CylinderMesh`의 `top_radius`와 `bottom_radius`가 달라
원뿔 형태라면 `CylinderShape3D`로 정확히 표현되지 않는다.

#### 코드에서 할 때 — 프리미티브 자동 매칭은 없다

`MeshInstance3D`에는 콜리전 생성 메서드가 있지만, **프리미티브를 알아보는 것은
에디터 기능뿐이다.** 코드 API는 볼록/삼각형만 만든다.

```gdscript
mesh_instance.create_trimesh_collision()                     # StaticBody3D 자식 + 삼각형 셰이프
mesh_instance.create_convex_collision(true, false)           # clean, simplify
mesh_instance.create_multiple_convex_collisions(null)        # MeshConvexDecompositionSettings

# Mesh 자체에서 셰이프 리소스만 얻기 (노드를 만들지 않는다)
var concave := mesh.create_trimesh_shape()                   # ConcavePolygonShape3D
var convex := mesh.create_convex_shape()                     # ConvexPolygonShape3D
```

프리미티브에 맞는 셰이프를 코드로 만들려면 직접 매핑한다.
런타임에 절차적으로 오브젝트를 배치할 때 쓴다.

```gdscript
# 프리미티브 메시 → 대응하는 셰이프. 프로퍼티 이름과 기본값이 서로 일치한다
static func shape_from_primitive(mesh: Mesh) -> Shape3D:
    if mesh is BoxMesh:
        var box := BoxShape3D.new()
        box.size = (mesh as BoxMesh).size
        return box
    if mesh is SphereMesh:
        var sphere := SphereShape3D.new()
        sphere.radius = (mesh as SphereMesh).radius
        return sphere
    if mesh is CapsuleMesh:
        var capsule := CapsuleShape3D.new()
        capsule.radius = (mesh as CapsuleMesh).radius
        capsule.height = (mesh as CapsuleMesh).height
        return capsule
    if mesh is CylinderMesh:
        var cm := mesh as CylinderMesh
        if not is_equal_approx(cm.top_radius, cm.bottom_radius):
            return null                          # 원뿔 — CylinderShape3D 로 표현 불가
        var cyl := CylinderShape3D.new()
        cyl.radius = cm.top_radius
        cyl.height = cm.height
        return cyl
    return null                                  # 프리미티브가 아니면 볼록/삼각형을 쓴다
```

### 지형 콜리전 자동 생성 (glTF 임포트)

Blender에서 메시 이름에 접미사를 붙이면 임포트 시 콜리전이 자동 생성된다.

| 접미사 | 결과 |
|--------|------|
| `-col` | 자식으로 trimesh `StaticBody3D` 생성, 메시도 보임 |
| `-colonly` | 콜리전만 생성, 메시는 제거 |
| `-convcol` | 볼록 다면체 콜리전 |
| `-convcolonly` | 볼록 콜리전만 |
| `-rigid` | `RigidBody3D`로 생성 |
| `-navmesh` | 내비게이션 메시로 변환 |
| `-vehicle` / `-vehbody` / `-vehwheel` | 차량 노드 |

---

## 5. CharacterBody3D 전체 속성

| 속성 | 타입 | 기본값 | 의미 |
|------|------|--------|------|
| `velocity` | `Vector3` | `(0,0,0)` | 초당 이동 속도. `move_and_slide()`가 읽고 수정한다 |
| `motion_mode` | `MotionMode` | `MOTION_MODE_GROUNDED` (0) | `GROUNDED`=중력 있는 지상, `FLOATING`=탑다운·비행 |
| `up_direction` | `Vector3` | `(0,1,0)` | 어느 방향이 "위"인지. 바닥/벽/천장 판정 기준 |
| `floor_max_angle` | `float` | `0.7853982` (45°) | 이 각도 이하 경사면을 바닥으로 인정 |
| `floor_snap_length` | `float` | `0.1` | 내리막에서 바닥에 붙이는 거리. 0이면 경사에서 튄다 |
| `floor_stop_on_slope` | `bool` | `true` | 정지 시 경사면을 미끄러지지 않게 |
| `floor_block_on_wall` | `bool` | `true` | 벽에 막혔을 때 위로 밀려 올라가는 것 방지 |
| `floor_constant_speed` | `bool` | `false` | 경사에서도 수평 이동속도 유지 |
| `slide_on_ceiling` | `bool` | `true` | 천장에 부딪히면 미끄러짐 |
| `wall_min_slide_angle` | `float` | `0.2617994` (15°) | 이 각도 미만이면 미끄러지지 않고 정지 |
| `max_slides` | `int` | `6` | 한 프레임에 미끄러짐 재계산 최대 횟수 |
| `safe_margin` | `float` | `0.001` | 충돌 여유. 너무 작으면 끼임, 크면 부정확 |
| `platform_on_leave` | `PlatformOnLeave` | `ADD_VELOCITY` (0) | 움직이는 발판에서 떠날 때 속도 처리 |
| `platform_floor_layers` | `int` | `0xFFFFFFFF` | 발판으로 인정할 레이어 |
| `platform_wall_layers` | `int` | `0` | 벽 발판으로 인정할 레이어 |

### 상태 조회 메서드

```gdscript
is_on_floor()              # 바닥에 닿아 있는가
is_on_floor_only()         # 바닥에만 (벽·천장 X)
is_on_wall()
is_on_wall_only()
is_on_ceiling()
is_on_ceiling_only()

get_floor_normal() -> Vector3          # 바닥 법선
get_floor_angle(up: Vector3) -> float  # 바닥 경사각(라디안)
get_wall_normal() -> Vector3
get_real_velocity() -> Vector3         # 실제로 이동한 속도 (슬라이드 반영 후)
get_last_motion() -> Vector3
get_position_delta() -> Vector3
get_platform_velocity() -> Vector3     # 올라탄 발판의 속도
get_platform_angular_velocity() -> Vector3

get_slide_collision_count() -> int
get_slide_collision(idx) -> KinematicCollision3D
get_last_slide_collision() -> KinematicCollision3D

apply_floor_snap()                     # 수동으로 바닥에 스냅
move_and_slide() -> bool               # 충돌했으면 true
```

**`is_on_floor()`는 `move_and_slide()` 호출 이후에만 유효하다.** 호출 전에 읽으면
이전 프레임 값이다.

---

## 6. 1인칭 캐릭터 컨트롤러 (완성 코드)

```gdscript
class_name FPSController
extends CharacterBody3D

# ── 이동 파라미터 ────────────────────────────────────────
@export_group("이동")
@export var walk_speed: float = 5.0
@export var sprint_speed: float = 8.0
@export var crouch_speed: float = 2.5
@export var acceleration: float = 12.0
@export var air_acceleration: float = 3.0
@export var friction: float = 14.0

@export_group("점프")
@export var jump_velocity: float = 4.8
@export var coyote_time: float = 0.12          # 발판을 떠난 뒤 점프 허용 시간
@export var jump_buffer_time: float = 0.12     # 착지 직전 점프 입력 유예
@export var gravity_multiplier: float = 1.6    # 낙하 시 중력 가중 (체감 개선)

@export_group("시점")
@export var mouse_sensitivity: float = 0.002
@export var pitch_limit_deg: float = 89.0

# ── 내부 상태 ───────────────────────────────────────────
var _yaw: float = 0.0
var _pitch: float = 0.0
var _coyote_timer: float = 0.0
var _jump_buffer_timer: float = 0.0
var _is_crouching: bool = false

# 프로젝트 설정의 중력값을 그대로 사용 (하드코딩 금지)
@onready var _gravity: float = ProjectSettings.get_setting(
    "physics/3d/default_gravity", 9.8
)
@onready var head: Node3D = %Head
@onready var camera: Camera3D = %Camera
@onready var stand_shape: CollisionShape3D = %StandShape
@onready var ceiling_check: ShapeCast3D = %CeilingCheck

func _ready() -> void:
    Input.mouse_mode = Input.MOUSE_MODE_CAPTURED

func _unhandled_input(event: InputEvent) -> void:
    if event is InputEventMouseMotion and Input.mouse_mode == Input.MOUSE_MODE_CAPTURED:
        var m := event as InputEventMouseMotion
        _yaw -= m.screen_relative.x * mouse_sensitivity
        _pitch -= m.screen_relative.y * mouse_sensitivity
        _pitch = clampf(_pitch, -deg_to_rad(pitch_limit_deg), deg_to_rad(pitch_limit_deg))
        _apply_look()
    elif event.is_action_pressed("ui_cancel"):
        Input.mouse_mode = Input.MOUSE_MODE_VISIBLE

func _apply_look() -> void:
    # 몸통은 Yaw만, 머리는 Pitch만 — 짐벌락 원천 차단
    basis = Basis()
    rotate_object_local(Vector3.UP, _yaw)
    head.basis = Basis()
    head.rotate_object_local(Vector3.RIGHT, _pitch)

func _physics_process(delta: float) -> void:
    _update_timers(delta)
    _apply_gravity(delta)
    _handle_jump()
    _handle_crouch()
    _handle_movement(delta)
    move_and_slide()

func _update_timers(delta: float) -> void:
    if is_on_floor():
        _coyote_timer = coyote_time
    else:
        _coyote_timer = maxf(0.0, _coyote_timer - delta)

    if Input.is_action_just_pressed("jump"):
        _jump_buffer_timer = jump_buffer_time
    else:
        _jump_buffer_timer = maxf(0.0, _jump_buffer_timer - delta)

func _apply_gravity(delta: float) -> void:
    if is_on_floor():
        return
    # 상승 중보다 하강 중에 중력을 강하게 → 점프가 "무겁게" 느껴짐
    var g := _gravity * (gravity_multiplier if velocity.y < 0.0 else 1.0)
    velocity.y -= g * delta

func _handle_jump() -> void:
    if _jump_buffer_timer > 0.0 and _coyote_timer > 0.0:
        velocity.y = jump_velocity
        _jump_buffer_timer = 0.0
        _coyote_timer = 0.0

func _handle_crouch() -> void:
    var want_crouch := Input.is_action_pressed("crouch")
    if not want_crouch and _is_crouching:
        # 천장이 막혀 있으면 일어나지 못한다
        ceiling_check.force_shapecast_update()
        if ceiling_check.is_colliding():
            return
    if want_crouch != _is_crouching:
        _is_crouching = want_crouch
        var shape := stand_shape.shape as CapsuleShape3D
        shape.height = 1.0 if _is_crouching else 1.8
        stand_shape.position.y = shape.height * 0.5
        head.position.y = shape.height - 0.2

func _handle_movement(delta: float) -> void:
    var input_dir := Input.get_vector("move_left", "move_right", "move_forward", "move_back")
    # 로컬 입력을 몸통 회전에 맞춰 월드 방향으로 변환
    var direction := (basis * Vector3(input_dir.x, 0.0, input_dir.y)).normalized()

    var target_speed := walk_speed
    if _is_crouching:
        target_speed = crouch_speed
    elif Input.is_action_pressed("sprint"):
        target_speed = sprint_speed

    var accel := acceleration if is_on_floor() else air_acceleration

    if direction:
        velocity.x = move_toward(velocity.x, direction.x * target_speed, accel * delta)
        velocity.z = move_toward(velocity.z, direction.z * target_speed, accel * delta)
    elif is_on_floor():
        velocity.x = move_toward(velocity.x, 0.0, friction * delta)
        velocity.z = move_toward(velocity.z, 0.0, friction * delta)
```

### 씬 구조

```
FPSController (CharacterBody3D)
├─ StandShape (CollisionShape3D)     ← CapsuleShape3D, height 1.8, position.y 0.9
├─ Head (Node3D)                     ← position.y 1.6
│  └─ Camera (Camera3D)
└─ CeilingCheck (ShapeCast3D)        ← 일어설 공간 확인용
```

### 왜 이렇게 설계했는가

- **코요테 타임 / 점프 버퍼** — 물리적으로는 불필요하지만 조작감을 결정한다.
  플랫포머의 필수 요소이며, 없으면 "점프가 씹힌다"는 느낌을 준다.
- **하강 중력 가중** — 실제 포물선은 답답하게 느껴진다. 하강을 빠르게 해야 경쾌하다.
- **`ProjectSettings.get_setting`으로 중력 획득** — 프로젝트 설정과 코드의 중력값이
  어긋나면 `RigidBody3D`와 캐릭터의 낙하 속도가 달라진다.
- **몸통 Yaw / 머리 Pitch 분리** — 몸통은 이동 방향 계산에, 머리는 시점에 쓰인다.
  분리하면 각 노드가 단일 축만 회전해 짐벌락이 없다.

---

## 7. 3인칭 캐릭터 컨트롤러 (완성 코드)

카메라 방향 기준으로 이동하고, 캐릭터 모델은 이동 방향으로 부드럽게 회전한다.

```gdscript
class_name ThirdPersonController
extends CharacterBody3D

@export var move_speed: float = 5.5
@export var sprint_speed: float = 9.0
@export var jump_velocity: float = 5.0
@export var acceleration: float = 14.0
@export var friction: float = 16.0
@export var model_turn_speed: float = 12.0

@onready var _gravity: float = ProjectSettings.get_setting("physics/3d/default_gravity", 9.8)
@onready var camera_pivot: Node3D = %CameraPivot
@onready var model: Node3D = %Model
@onready var anim_tree: AnimationTree = %AnimationTree

func _physics_process(delta: float) -> void:
    if not is_on_floor():
        velocity.y -= _gravity * delta

    if Input.is_action_just_pressed("jump") and is_on_floor():
        velocity.y = jump_velocity

    var input_dir := Input.get_vector("move_left", "move_right", "move_forward", "move_back")

    # 카메라 기준 방향으로 변환 — Y축 성분을 제거해 지면 평면으로 투영
    var cam_basis := camera_pivot.global_basis
    var forward := -cam_basis.z
    var right := cam_basis.x
    forward.y = 0.0
    right.y = 0.0
    var direction := (right * input_dir.x + forward * -input_dir.y).normalized()

    var speed := sprint_speed if Input.is_action_pressed("sprint") else move_speed

    if direction:
        velocity.x = move_toward(velocity.x, direction.x * speed, acceleration * delta)
        velocity.z = move_toward(velocity.z, direction.z * speed, acceleration * delta)
        _rotate_model_toward(direction, delta)
    else:
        velocity.x = move_toward(velocity.x, 0.0, friction * delta)
        velocity.z = move_toward(velocity.z, 0.0, friction * delta)

    move_and_slide()
    _update_animation(speed)

func _rotate_model_toward(direction: Vector3, delta: float) -> void:
    var desired := Basis.looking_at(direction, Vector3.UP)
    var t := 1.0 - exp(-model_turn_speed * delta)
    model.global_basis = Basis(
        Quaternion(model.global_basis).normalized().slerp(
            Quaternion(desired).normalized(), t
        )
    )

func _update_animation(max_speed: float) -> void:
    var planar := Vector2(velocity.x, velocity.z).length()
    anim_tree.set("parameters/Locomotion/blend_position", planar / max_speed)
    anim_tree.set("parameters/conditions/is_grounded", is_on_floor())
```

**핵심 로직**: `input_dir.y`는 앞(-1)/뒤(+1)이므로 `forward * -input_dir.y`로 부호를 뒤집는다.
`forward.y = 0`으로 지면 평면에 투영해야 카메라가 아래를 볼 때 캐릭터가 땅으로 파고들지 않는다.

---

## 8. move_and_collide와 커스텀 충돌 처리

자동 슬라이드가 필요 없고 충돌 반응을 직접 정의할 때 쓴다.

```gdscript
# 튕기는 발사체
class_name BouncingProjectile
extends CharacterBody3D

@export var max_bounces: int = 3
var _bounces: int = 0

func _physics_process(delta: float) -> void:
    velocity.y -= 9.8 * delta
    var collision := move_and_collide(velocity * delta)
    if collision:
        _bounces += 1
        if _bounces > max_bounces:
            queue_free()
            return
        # 법선을 기준으로 반사, 에너지 손실 반영
        velocity = velocity.bounce(collision.get_normal()) * 0.7

        var body := collision.get_collider()
        if body and body.has_method("take_damage"):
            body.take_damage(10)
```

### KinematicCollision3D API

```gdscript
collision.get_position()          # 충돌 지점 (월드)
collision.get_normal()            # 충돌 법선
collision.get_collider()          # 충돌한 노드
collision.get_collider_id()
collision.get_collider_rid()
collision.get_collider_velocity() # 상대 바디의 속도
collision.get_collider_shape()
collision.get_travel()            # 실제로 이동한 거리
collision.get_remainder()         # 남은 이동 벡터
collision.get_angle(up)           # 법선과 up의 각도
collision.get_depth()             # 침투 깊이
```

### 이동 없이 충돌만 검사

```gdscript
# test_only=true — 실제로 움직이지 않고 결과만 확인
var would_hit := move_and_collide(velocity * delta, true)
if would_hit == null:
    move_and_collide(velocity * delta)
```

### 슬라이드 충돌 순회

```gdscript
func _physics_process(delta: float) -> void:
    move_and_slide()
    for i in get_slide_collision_count():
        var c := get_slide_collision(i)
        var collider := c.get_collider()
        # RigidBody를 밀어내기
        if collider is RigidBody3D:
            var rb := collider as RigidBody3D
            rb.apply_central_impulse(-c.get_normal() * 2.0)
```

---

## 9. RigidBody3D

물리 엔진이 완전히 제어한다. **`position`을 직접 대입하면 안 된다** —
시뮬레이션이 깨지고 순간이동 후 물리가 폭발한다.

### 주요 속성

| 속성 | 기본값 | 의미 |
|------|--------|------|
| `mass` | `1.0` | 질량(kg) |
| `linear_velocity` / `angular_velocity` | `(0,0,0)` | 속도 (읽기 권장, 쓰기는 신중히) |
| `linear_damp` / `angular_damp` | `0.0` | 감쇠 (공기 저항) |
| `gravity_scale` | `1.0` | 중력 배율. 0이면 무중력 |
| `freeze` / `freeze_mode` | `false` / `STATIC` | 시뮬레이션 정지 |
| `lock_rotation` | `false` | 회전 고정 |
| `can_sleep` / `sleeping` | `true` / `false` | 정지 시 자동 슬립 (성능) |
| `custom_integrator` | `false` | 기본 통합 비활성, `_integrate_forces`로 전면 제어 |
| `contact_monitor` | `false` | 접촉 시그널 활성화 (성능 비용 있음) |
| `max_contacts_reported` | `0` | 보고할 최대 접촉 수. contact_monitor와 함께 설정 |
| `continuous_cd` | `false` | 연속 충돌 감지 — 빠른 물체의 터널링 방지 |
| `center_of_mass_mode` / `center_of_mass` | `AUTO` / `(0,0,0)` | 무게중심 |
| `physics_material_override` | `null` | 마찰/반발 계수 |

### 힘과 임펄스

```gdscript
# 임펄스 = 즉발 (총알 충격, 폭발, 점프)
rb.apply_central_impulse(Vector3.UP * 10.0)
rb.apply_impulse(Vector3.UP * 10.0, offset_from_center)   # 위치 지정 → 회전 발생
rb.apply_torque_impulse(Vector3.UP * 5.0)

# 힘 = 지속 (매 물리 프레임 호출해야 함)
func _physics_process(_delta: float) -> void:
    rb.apply_central_force(Vector3.FORWARD * thrust)
    rb.apply_torque(Vector3.UP * steering)

# 상수 힘 — 한 번 설정하면 매 프레임 자동 적용 (바람, 부력)
rb.constant_force = Vector3.UP * 5.0
rb.add_constant_central_force(Vector3.FORWARD * 2.0)
```

| 구분 | 즉발 | 지속 |
|------|------|------|
| 선형 | `apply_central_impulse`, `apply_impulse` | `apply_central_force`, `apply_force`, `constant_force` |
| 회전 | `apply_torque_impulse` | `apply_torque`, `constant_torque` |

### 접촉 감지

```gdscript
func _ready() -> void:
    contact_monitor = true
    max_contacts_reported = 4      # 0이면 시그널이 발생하지 않는다
    body_entered.connect(_on_body_entered)

func _on_body_entered(body: Node) -> void:
    var impact := linear_velocity.length()
    if impact > 5.0:
        _play_impact_sound(impact)
```

### 폭발 (범위 임펄스)

```gdscript
func explode(center: Vector3, radius: float, force: float) -> void:
    var space := get_world_3d().direct_space_state
    var query := PhysicsShapeQueryParameters3D.new()
    var sphere := SphereShape3D.new()
    sphere.radius = radius
    query.shape = sphere
    query.transform = Transform3D(Basis(), center)
    query.collision_mask = 0xFFFFFFFF
    query.collide_with_bodies = true

    for result in space.intersect_shape(query, 32):
        var body := result.collider
        if body is RigidBody3D:
            var rb := body as RigidBody3D
            var dir := center.direction_to(rb.global_position)
            var dist := center.distance_to(rb.global_position)
            var falloff := 1.0 - clampf(dist / radius, 0.0, 1.0)
            rb.apply_impulse(dir * force * falloff, Vector3.ZERO)
```

### _integrate_forces

물리 상태를 안전하게 직접 조작할 수 있는 유일한 지점이다.

```gdscript
func _integrate_forces(state: PhysicsDirectBodyState3D) -> void:
    # 순간이동은 여기서만 안전하다
    if _teleport_requested:
        state.transform = Transform3D(state.transform.basis, _teleport_target)
        state.linear_velocity = Vector3.ZERO
        _teleport_requested = false

    # 최대 속도 제한
    if state.linear_velocity.length() > MAX_SPEED:
        state.linear_velocity = state.linear_velocity.normalized() * MAX_SPEED

    # 접촉 정보 조회
    for i in state.get_contact_count():
        var normal := state.get_contact_local_normal(i)
        var impulse := state.get_contact_impulse(i)   # Jolt에서는 추정치
```

### freeze 활용 (파괴 가능한 오브젝트)

```gdscript
class_name DestructibleCrate
extends RigidBody3D

func _ready() -> void:
    freeze = true
    freeze_mode = RigidBody3D.FREEZE_MODE_STATIC     # 정적처럼 동작, 비용 없음

func on_hit(impulse: Vector3) -> void:
    freeze = false                                   # 물리 시뮬레이션 시작
    apply_central_impulse(impulse)
```

---

## 10. Area3D

충돌 반응 없이 **겹침만 감지**한다. 트리거·감지 범위·중력 영역에 쓴다.

```gdscript
class_name PickupArea
extends Area3D

signal collected(by: Node3D)

func _ready() -> void:
    collision_layer = 0                      # 감지당할 필요 없음
    collision_mask = LAYER_PLAYER            # 플레이어만 감지
    monitoring = true                        # 다른 것을 감지
    monitorable = false                      # 남에게 감지되지 않음 (비용 절감)
    body_entered.connect(_on_body_entered)

func _on_body_entered(body: Node3D) -> void:
    if not body.is_in_group("player"):
        return
    collected.emit(body)
    queue_free()
```

### 시그널

```gdscript
body_entered(body: Node3D)          # PhysicsBody3D가 들어옴
body_exited(body: Node3D)
body_shape_entered(body_rid, body, body_shape_index, local_shape_index)
body_shape_exited(...)
area_entered(area: Area3D)          # 다른 Area3D가 들어옴
area_exited(area: Area3D)
area_shape_entered(...)
```

### 즉시 조회

시그널을 기다리지 않고 현재 겹친 것을 조회한다.

```gdscript
var bodies := area.get_overlapping_bodies()
var areas := area.get_overlapping_areas()
if area.has_overlapping_bodies():
    pass
```

**주의**: 물리 프레임이 지나야 갱신된다. `add_child` 직후에는 비어 있다.
`await get_tree().physics_frame` 후에 조회한다.

### 중력·감쇠 오버라이드 (물속, 저중력 영역)

```gdscript
# Area3D 인스펙터
area.gravity_space_override = Area3D.SPACE_OVERRIDE_REPLACE
area.gravity = 2.0
area.gravity_direction = Vector3.UP           # 부력
area.linear_damp_space_override = Area3D.SPACE_OVERRIDE_REPLACE
area.linear_damp = 3.0                        # 물의 저항
area.priority = 1                             # 여러 영역이 겹칠 때 우선순위
```

| 오버라이드 모드 | 동작 |
|----------------|------|
| `SPACE_OVERRIDE_DISABLED` | 영향 없음 |
| `SPACE_OVERRIDE_COMBINE` | 기본값에 더함 |
| `SPACE_OVERRIDE_COMBINE_REPLACE` | 더하고 하위 우선순위 무시 |
| `SPACE_OVERRIDE_REPLACE` | 완전 대체 |
| `SPACE_OVERRIDE_REPLACE_COMBINE` | 대체 후 하위와 결합 |

`Area3D`는 `CharacterBody3D`에 자동으로 영향을 주지 않는다. 캐릭터는 중력을
코드에서 직접 적용하므로, 영역 효과를 반영하려면 `_physics_process`에서 직접 처리한다.

---

## 11. RayCast3D와 ShapeCast3D

### RayCast3D — 씬에 배치하는 지속적 레이

```gdscript
@onready var ground_ray: RayCast3D = $GroundRay

func _ready() -> void:
    ground_ray.target_position = Vector3(0, -1.2, 0)   # 로컬 좌표 기준 끝점
    ground_ray.collision_mask = LAYER_WORLD
    ground_ray.enabled = true
    ground_ray.exclude_parent = true                    # 부모 바디 제외 (기본 true)
    ground_ray.hit_from_inside = false
    ground_ray.collide_with_areas = false
    ground_ray.collide_with_bodies = true

func _physics_process(_delta: float) -> void:
    if ground_ray.is_colliding():
        var point := ground_ray.get_collision_point()
        var normal := ground_ray.get_collision_normal()
        var body := ground_ray.get_collider()
        var face := ground_ray.get_collision_face_index()
```

**즉시 갱신**: `RayCast3D`는 물리 프레임마다 한 번 갱신된다. 노드를 옮긴 직후
결과가 필요하면 `force_raycast_update()`를 호출한다.

```gdscript
ground_ray.global_position = new_pos
ground_ray.force_raycast_update()
if ground_ray.is_colliding(): pass
```

### 상호작용 레이 (1인칭)

```gdscript
class_name InteractRay
extends RayCast3D

signal target_changed(target: Node3D)

var _current: Node3D = null

func _physics_process(_delta: float) -> void:
    var hit := get_collider() if is_colliding() else null
    var target := hit as Node3D if hit and hit.is_in_group("interactable") else null
    if target != _current:
        _current = target
        target_changed.emit(target)

func _unhandled_input(event: InputEvent) -> void:
    if event.is_action_pressed("interact") and _current:
        if _current.has_method("interact"):
            _current.interact(owner)
```

### ShapeCast3D — 두께가 있는 스윕

레이는 두께가 없어서 좁은 틈을 통과한다. 캐릭터가 지나갈 수 있는지 검사할 때는 셰이프캐스트를 쓴다.

```gdscript
@onready var cast: ShapeCast3D = $CeilingCheck

func _ready() -> void:
    var s := SphereShape3D.new()
    s.radius = 0.35
    cast.shape = s
    cast.target_position = Vector3(0, 1.0, 0)
    cast.max_results = 4

func can_stand_up() -> bool:
    cast.force_shapecast_update()
    return not cast.is_colliding()

func get_all_hits() -> Array:
    cast.force_shapecast_update()
    var hits: Array = []
    for i in cast.get_collision_count():
        hits.append({
            "collider": cast.get_collider(i),
            "point": cast.get_collision_point(i),
            "normal": cast.get_collision_normal(i),
        })
    return hits
```

---

## 12. 직접 공간 질의 (PhysicsDirectSpaceState3D)

노드를 만들지 않고 임의 위치에서 즉시 질의한다. **반드시 `_physics_process` 안에서 호출한다.**

### 레이 질의

```gdscript
func raycast(from: Vector3, to: Vector3, mask: int = 0xFFFFFFFF,
             exclude: Array[RID] = []) -> Dictionary:
    var space := get_world_3d().direct_space_state
    var query := PhysicsRayQueryParameters3D.create(from, to, mask, exclude)
    query.collide_with_bodies = true
    query.collide_with_areas = false
    query.hit_from_inside = false
    query.hit_back_faces = true
    return space.intersect_ray(query)
```

```gdscript
# 사용 — 시야 확인
func has_line_of_sight(target: Node3D) -> bool:
    var result := raycast(
        global_position + Vector3.UP,
        target.global_position + Vector3.UP,
        LAYER_WORLD,
        [get_rid()]
    )
    return result.is_empty()      # 아무것도 안 막으면 시야 확보
```

### 셰이프 질의

```gdscript
# 범위 안의 모든 바디
func query_sphere(center: Vector3, radius: float, mask: int) -> Array[Dictionary]:
    var space := get_world_3d().direct_space_state
    var shape := SphereShape3D.new()
    shape.radius = radius
    var params := PhysicsShapeQueryParameters3D.new()
    params.shape = shape
    params.transform = Transform3D(Basis(), center)
    params.collision_mask = mask
    params.collide_with_bodies = true
    return space.intersect_shape(params, 32)     # 최대 32개

# 셰이프 스윕 — 이동 경로 상 첫 충돌까지의 비율
func sweep_test(shape: Shape3D, from: Transform3D, motion: Vector3) -> Array:
    var space := get_world_3d().direct_space_state
    var params := PhysicsShapeQueryParameters3D.new()
    params.shape = shape
    params.transform = from
    params.motion = motion
    return space.cast_motion(params)     # [safe_fraction, unsafe_fraction]

# 침투 해소 벡터
func get_recovery(shape: Shape3D, at: Transform3D) -> Vector3:
    var space := get_world_3d().direct_space_state
    var params := PhysicsShapeQueryParameters3D.new()
    params.shape = shape
    params.transform = at
    var info := space.get_rest_info(params)
    return info.get("normal", Vector3.ZERO) * info.get("depth", 0.0)
```

### 사용 가능한 질의 메서드

| 메서드 | 반환 | 용도 |
|--------|------|------|
| `intersect_ray(query)` | `Dictionary` | 레이 첫 충돌 |
| `intersect_shape(query, max)` | `Array[Dictionary]` | 셰이프와 겹치는 것들 |
| `intersect_point(query, max)` | `Array[Dictionary]` | 한 점을 포함하는 셰이프들 |
| `cast_motion(query)` | `Array[float]` | 안전 이동 비율 |
| `collide_shape(query, max)` | `Array[Vector3]` | 충돌 접점 쌍 |
| `get_rest_info(query)` | `Dictionary` | 가장 깊은 침투 정보 |

---

## 13. 조인트

| 노드 | 자유도 | 용도 |
|------|--------|------|
| `PinJoint3D` | 회전 3축 자유 | 진자, 체인, 래그돌 관절 |
| `HingeJoint3D` | 1축 회전 | 문, 바퀴 |
| `SliderJoint3D` | 1축 직선 | 미닫이문, 피스톤 |
| `ConeTwistJoint3D` | 원뿔 범위 회전 | 어깨 관절 |
| `Generic6DOFJoint3D` | 6축 개별 설정 | 커스텀 제약 |

```gdscript
var joint := HingeJoint3D.new()
add_child(joint)
joint.node_a = door_frame.get_path()
joint.node_b = door.get_path()
joint.set_param(HingeJoint3D.PARAM_LIMIT_UPPER, deg_to_rad(90.0))
joint.set_param(HingeJoint3D.PARAM_LIMIT_LOWER, deg_to_rad(0.0))
joint.set_flag(HingeJoint3D.FLAG_USE_LIMIT, true)
```

**Jolt 제약**: `bias`, `damping`, `softness` 등 소프트 리미트 관련 파라미터는
Jolt에서 지원하지 않는다. 이 값들을 설정해도 무시되므로 대신 조인트 자체의
스프링/모터 파라미터를 쓴다.

---

## 14. Jolt 고유 사항

### 4.7에서 정식 기본 엔진이 되었다

Jolt는 4.4에서 **실험적(experimental) 옵션**으로 들어왔다. 4.7에서 실험 딱지가
떨어지고 **새로 만드는 3D 프로젝트의 기본 물리 엔진**이 되었다.
(Jolt는 Death Stranding 2 같은 상용 게임에도 쓰이는 독립 물리 엔진이다.)

**기존 프로젝트는 자동으로 바뀌지 않는다.** 4.7로 올려도 `project.godot`에 적힌
물리 엔진 설정이 그대로 유지된다. 바꾸려면 직접 설정한다.

```ini
[physics]

3d/physics_engine="Jolt Physics"
```

선택지는 4가지다: `DEFAULT`, `Jolt Physics`, `GodotPhysics3D`, `Dummy`.
`DEFAULT`는 엔진이 그 버전의 기본값으로 해석하므로, **의도를 남기려면 이름을 명시**한다.

에디터 경로: `Project > Project Settings > Physics > 3D > Physics Engine`

> **이 프로젝트는 이미 `3d/physics_engine="Jolt Physics"`로 명시되어 있다.**
> 확인만 하고 바꾸지 않는다. 모든 물리 코드는 Jolt 기준으로 작성한다.

### Godot Physics와의 차이

| 항목 | Jolt 동작 |
|------|----------|
| 조인트 소프트 리미트 | `bias`/`damping`/`softness` **미지원** |
| 단일 바디 조인트 | 한쪽 바디를 생략하면 동작이 다름. `World Node` 설정으로 조정 |
| 충돌 마진 | convex radius 방식 — 셰이프를 축소한 뒤 쉘을 적용 |
| Baumgarte 안정화 | 위치에만 적용 → 과도한 튕김이 없음 |
| 고스트 충돌 | Active Edge Detection + Enhanced Internal Edge Removal로 완화 |
| Kinematic RigidBody3D | 기본적으로 정적/키네마틱 바디와의 접촉을 보고하지 않음 |
| `face_index` (레이캐스트) | 기본값 `-1` |
| 접촉 임펄스 | 추정치이며 정확하지 않음 |

### 프로젝트 설정 경로

Jolt 설정은 `physics/jolt_physics_3d/` 아래에 있다 (4.4 이전 `physics/jolt_3d/`에서 이동).

아래는 엔진에서 실제로 확인한 키와 기본값이다.

| 설정 | 기본값 | 의미 |
|------|--------|------|
| `simulation/velocity_steps` | `10` | 속도 솔버 반복 횟수 |
| `simulation/position_steps` | `2` | 위치 솔버 반복 횟수 |
| `simulation/baumgarte_stabilization_factor` | `0.2` | 침투 해소 강도 |
| `simulation/use_enhanced_internal_edge_removal` | `true` | 고스트 충돌 완화 |
| `simulation/generate_all_kinematic_contacts` | `false` | 키네마틱 접촉을 모두 보고 |
| `simulation/penetration_slop` | `0.02` m | 허용 침투 깊이 |
| `simulation/speculative_contact_distance` | `0.02` m | 예측 접촉 거리 |
| `simulation/allow_sleep` | `true` | 슬립 허용 |
| `simulation/sleep_velocity_threshold` | `0.03` m/s | 슬립 진입 속도 |
| `simulation/sleep_time_threshold` | `0.5` s | 슬립 진입 대기 시간 |
| `simulation/continuous_cd_movement_threshold` | `0.75` | CCD 발동 이동량 비율 |
| `simulation/continuous_cd_max_penetration` | `0.25` | CCD 허용 침투 비율 |
| `motion_queries/use_enhanced_internal_edge_removal` | `true` | `move_and_slide` 계열의 턱 걸림 완화 |
| `motion_queries/recovery_iterations` | `4` | 침투 복구 반복 |
| `queries/enable_ray_cast_face_index` | `false` | 레이캐스트 `face_index` 활성화 |
| `collisions/collision_margin_fraction` | `0.08` | 충돌 마진 비율 |
| `collisions/active_edge_threshold` | `50°` | 활성 엣지 판정 각 |
| `joints/world_node` | `Node A` | 단일 바디 조인트의 기준 |
| `limits/temporary_memory_buffer_size` | `32` MiB | 임시 메모리 버퍼 |
| `limits/world_boundary_shape_size` | `2000` m | WorldBoundary 크기 |
| `limits/max_bodies` | `10240` | 최대 바디 수 |
| `limits/max_body_pairs` | `65536` | 최대 바디 쌍 |
| `limits/max_contact_constraints` | `20480` | 최대 접촉 제약 |

**`queries/enable_ray_cast_face_index`**: Jolt는 레이캐스트의 `face_index`를
기본적으로 주지 않는다(`-1`). 탄흔 데칼을 면 단위로 붙이는 등 이 값이 필요하면
이 설정을 켜야 하며, 켜면 메모리 사용이 늘어난다.

**대량 오브젝트를 다룰 때는 `limits/max_bodies`를 먼저 확인한다.** 기본 10240을
넘으면 초과분이 조용히 시뮬레이션에서 빠진다.

### Jolt를 쓸 때의 권장 사항

- **`ConcavePolygonShape3D`는 정적 바디에만** 쓴다. Jolt에서 동적 바디에 붙이면 경고가 뜬다.
- 얇은 벽을 통과하는 빠른 물체는 `continuous_cd = true`로 CCD를 켠다.
- 슬립을 끄면(`can_sleep = false`) 성능이 크게 떨어진다. 꼭 필요한 바디만 끈다.
- 대량의 정적 바디는 하나의 `StaticBody3D`에 여러 `CollisionShape3D`를 붙이는 편이 낫다.

---

## 15. 물리 보간과 프로젝트 설정

### 주요 프로젝트 설정

```ini
[physics]

common/physics_ticks_per_second=60          # 물리 틱 (기본 60)
common/max_physics_steps_per_frame=8        # 프레임당 최대 물리 스텝
common/physics_interpolation=false          # 물리 보간 (4.3+)
3d/default_gravity=9.8
3d/default_gravity_vector=Vector3(0, -1, 0)
3d/default_linear_damp=0.1
3d/default_angular_damp=0.1
3d/physics_engine="Jolt Physics"
```

### 물리 보간

물리는 60Hz인데 화면은 144Hz면 같은 위치가 여러 프레임 반복되어 미세한 끊김이 생긴다.
물리 보간을 켜면 엔진이 두 물리 스텝 사이를 자동으로 보간해 렌더링한다.

```gdscript
# 프로젝트 설정에서 physics_interpolation=true 로 켠 뒤

# 순간이동할 때는 보간을 무시해야 한다 (안 그러면 늘어난 궤적이 보임)
global_position = teleport_target
reset_physics_interpolation()
```

**주의**: 보간이 켜지면 `_process`에서 읽는 `global_position`은 보간된 값이고,
`_physics_process`에서 읽는 값은 실제 물리 위치다.

#### SceneTree로 이전되었다 (4.6+)

3D 물리 보간은 4.4에서 처음 들어올 때 **`RenderingServer`에서** 구현되었다.
보간은 결국 "중간 상태를 그리는 것"이라 렌더링 쪽이 자연스러워 보였고, 노드 코드를
건드리지 않아도 되는 장점이 있었다.

문제는 **노드가 `Node3D`의 트랜스폼에 의존해 동작한다**는 점이었다. 내장 노드도,
사용자가 만든 노드도 마찬가지다. 그런데 `RenderingServer`에 보간된 트랜스폼을
질의하는 것은 기술적·성능적으로 불가능했다.

4.6에서 **`SceneTree`로 옮겨졌다.** 노드가 사는 곳에서 보간이 이뤄지므로 여러 문제가
해결되었고 개념도 단순해졌다.

**사용자 API는 그대로다.** 프로젝트 설정도, `reset_physics_interpolation()`도 동일하다.
내부만 바뀌었으므로 **기존 프로젝트를 고칠 필요가 없다.**

```gdscript
# 코드에서 켜고 끄기 — SceneTree 프로퍼티
get_tree().physics_interpolation = true

# 보간된 트랜스폼을 직접 읽어야 할 때
var t := some_node_3d.get_global_transform_interpolated()
```

기본값은 `false`다. 물리 틱(60Hz)보다 화면 주사율이 높은 기기에서 켜면 부드러워진다.
모바일에서 물리 틱을 30~40으로 낮춰 CPU를 아끼면서 화면은 부드럽게 유지하는
조합에도 쓸 수 있다.

### 터널링 방지

빠른 물체가 얇은 벽을 통과하는 문제.

1. `RigidBody3D.continuous_cd = true` (가장 간단)
2. 물리 틱을 올린다 (`physics_ticks_per_second = 120`) — 전체 비용 증가
3. `move_and_collide` 대신 `ShapeCast3D`로 경로를 먼저 검사
4. 총알은 물리 바디 대신 레이캐스트(hitscan)로 처리

```gdscript
# 히트스캔 총알 — 물리 바디를 안 만들어 터널링이 원천적으로 없다
func fire_hitscan(from: Vector3, direction: Vector3, range_m: float) -> void:
    var space := get_world_3d().direct_space_state
    var query := PhysicsRayQueryParameters3D.create(
        from, from + direction * range_m, LAYER_WORLD | LAYER_ENEMY, [get_rid()]
    )
    var hit := space.intersect_ray(query)
    if hit.is_empty():
        return
    _spawn_impact(hit.position, hit.normal)
    var body := hit.collider
    if body.has_method("take_damage"):
        body.take_damage(damage)
```

---

## 16. 자주 하는 실수

| 실수 | 증상 | 해결 |
|------|------|------|
| `_process`에서 `move_and_slide()` | 지터, 터널링 | `_physics_process`로 이동 |
| `RigidBody3D.position` 직접 대입 | 물리 폭발, 순간이동 후 이상 동작 | `_integrate_forces`에서 `state.transform` 설정 |
| `move_and_slide()` 전에 `is_on_floor()` | 이전 프레임 값 | 호출 이후에 읽는다 |
| `contact_monitor`만 켜고 `max_contacts_reported=0` | 시그널이 안 옴 | 둘 다 설정 |
| `ConcavePolygonShape3D`를 동적 바디에 | 경고·부정확한 충돌 | 정적 바디에만 사용 |
| 콜백에서 노드 추가/제거 | "flushing queries" 오류 | `call_deferred` 사용 |
| `Area3D` 추가 직후 `get_overlapping_bodies()` | 빈 배열 | `await get_tree().physics_frame` |
| 중력값을 코드에 하드코딩 | 설정과 불일치 | `ProjectSettings.get_setting("physics/3d/default_gravity")` |
| `collision_layer`와 `mask`를 혼동 | 감지가 안 됨 | layer=내 정체, mask=내가 볼 것 |
| `floor_snap_length = 0` | 내리막에서 튐 | 기본 0.1 유지 또는 캐릭터 크기에 맞게 |
| `RayCast3D` 이동 후 즉시 조회 | 이전 결과 | `force_raycast_update()` |
| 캡슐 대신 박스로 캐릭터 | 계단·경사에서 걸림 | `CapsuleShape3D` 사용 |
| 슬립 전부 비활성화 | 프레임 저하 | 꼭 필요한 바디만 |
| 조인트에 `bias`/`softness` 설정 (Jolt) | 무시됨 | Jolt 지원 파라미터만 사용 |
