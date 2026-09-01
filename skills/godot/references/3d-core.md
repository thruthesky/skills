# Node3D·Transform3D·카메라

## 목차

1. [핵심 개념 — Godot 3D 좌표계](#1-핵심-개념--godot-3d-좌표계)
2. [Transform3D와 Basis의 내부 구조](#2-transform3d와-basis의-내부-구조)
3. [로컬과 글로벌](#3-로컬과-글로벌)
4. [회전 — 오일러를 쓰지 않는 이유](#4-회전--오일러를-쓰지-않는-이유)
5. [실전 회전 패턴](#5-실전-회전-패턴)
6. [Quaternion과 보간](#6-quaternion과-보간)
7. [orthonormalize — 오차 누적 방지](#7-orthonormalize--오차-누적-방지)
8. [벡터 연산 실전](#8-벡터-연산-실전)
9. [Camera3D](#9-camera3d)
10. [SpringArm3D 3인칭 카메라](#10-springarm3d-3인칭-카메라)
11. [마우스 피킹](#11-마우스-피킹)
12. [MeshInstance3D와 가시성](#12-meshinstance3d와-가시성)
13. [자주 하는 실수](#13-자주-하는-실수)

---

## 1. 핵심 개념 — Godot 3D 좌표계

Godot 3D는 **오른손 좌표계, Y-up**을 쓴다. 이 규약을 외우지 않으면 모든 방향 계산이 틀린다.

```
        +Y (UP)
         │
         │
         └──── +X (RIGHT)
        ╱
      ╱
   +Z (BACK)      ← 화면 바깥쪽(플레이어 쪽)이 +Z
```

| 방향 | 벡터 | 의미 |
|------|------|------|
| **FORWARD** | `Vector3(0, 0, -1)` = `-Z` | **객체가 바라보는 방향** |
| BACK | `Vector3(0, 0, 1)` = `+Z` | 뒤 |
| UP | `Vector3(0, 1, 0)` | 위 |
| DOWN | `Vector3(0, -1, 0)` | 아래 |
| RIGHT | `Vector3(1, 0, 0)` | 오른쪽 |
| LEFT | `Vector3(-1, 0, 0)` | 왼쪽 |

**가장 중요한 결론**: 노드의 전방 벡터는 `-transform.basis.z`다.

```gdscript
# 총알을 노드가 바라보는 방향으로 발사
bullet.linear_velocity = -global_transform.basis.z * BULLET_SPEED

# 또는 (Basis.z는 뒤쪽 축이므로 부호를 뒤집는다)
var forward := -global_basis.z          # 4.x에서 global_basis 프로퍼티 사용 가능
var right := global_basis.x
var up := global_basis.y
```

**Blender/Maya에서 임포트할 때 주의**: Blender는 Z-up이다. glTF 임포트 시 Godot이
자동 변환하지만, 모델의 "정면"이 -Z를 향하도록 모델링해야 `look_at`이 자연스럽다.

---

## 2. Transform3D와 Basis의 내부 구조

### Transform3D

```
Transform3D = { basis: Basis, origin: Vector3 }
```

- `origin` — 위치 (translation)
- `basis` — 회전 + 스케일 + 기울임을 담은 3×3 행렬

### Basis

`Basis`는 세 개의 축 벡터로 구성된다. **각 축 벡터는 회전 후 그 축이 가리키는 방향이다.**

```gdscript
var b := Basis()
b.x    # Vector3 — 로컬 X축(right)이 월드에서 향하는 방향
b.y    # Vector3 — 로컬 Y축(up)
b.z    # Vector3 — 로컬 Z축(back)

# 항등 basis (회전 없음)
Basis.IDENTITY == Basis(Vector3(1,0,0), Vector3(0,1,0), Vector3(0,0,1))
```

축 벡터의 **길이가 스케일**이다. 길이가 1이면 스케일 1.
따라서 `basis.x.length()`가 스케일 X값이다.

### 생성과 조작

```gdscript
# 축-각도로 생성
var b := Basis(Vector3.UP, deg_to_rad(45.0))

# 쿼터니언에서
var b2 := Basis(Quaternion(Vector3.UP, PI * 0.5))

# 방향을 바라보는 basis (Z가 -direction을 향함)
var b3 := Basis.looking_at(direction, Vector3.UP)

# Transform3D 생성
var t := Transform3D(b, Vector3(0, 2, 0))
var t2 := Transform3D.IDENTITY.translated(Vector3(0, 2, 0))

# 조합 — 순서가 중요하다 (행렬 곱)
var combined := parent_transform * child_local_transform

# 역변환 — 월드 좌표를 로컬로
var local_point := global_transform.affine_inverse() * world_point

# 점 변환
var world_point := global_transform * local_point       # 위치 변환 (translation 포함)
var world_dir := global_transform.basis * local_dir     # 방향 변환 (translation 제외)
```

**중요**: 위치는 `transform * point`, 방향은 `transform.basis * dir`이다.
방향에 translation을 적용하면 틀린다.

---

## 3. 로컬과 글로벌

| 로컬 (부모 기준) | 글로벌 (월드 기준) |
|-----------------|-------------------|
| `position` | `global_position` |
| `rotation` | `global_rotation` |
| `basis` | `global_basis` |
| `transform` | `global_transform` |
| `translate()` | — |
| `rotate()` | `global_rotate()` |
| `translate_object_local()` | — |

```gdscript
# 부모가 없으면(루트) 로컬 = 글로벌
position          # 부모 노드 좌표계에서의 위치
global_position   # 월드 좌표계에서의 위치

# 로컬 이동 — 부모 좌표계 기준
position += Vector3(1, 0, 0)

# 자기 자신 기준 이동 (전방으로 전진)
translate_object_local(Vector3(0, 0, -1) * speed * delta)
# 동등한 표현
global_position += -global_basis.z * speed * delta
```

**트리 밖에서는 `global_*`이 무의미하다.** `instantiate()` 직후에는 부모가 없으므로
`add_child()` 이후에 글로벌 좌표를 설정한다.

---

## 4. 회전 — 오일러를 쓰지 않는 이유

공식 문서의 권고: **"회전(rotation) 속성을 게임 로직에 사용하지 마라. Transform3D를 써라."**

세 가지 문제 때문이다.

### (1) 회전 순서 의존

오일러 각도 `(x, y, z)`는 적용 순서에 따라 결과가 다르다.
Godot 기본은 YXZ 순서지만, 다른 시스템(Blender, Unity)과 다를 수 있다.

### (2) 짐벌락

X축을 90도 돌리면 Y축과 Z축이 겹쳐 자유도 하나를 잃는다.
비행기·우주선처럼 자유 회전이 필요한 경우 치명적이다.

### (3) 보간 왜곡

`lerp(rot_a, rot_b, t)`로 오일러를 보간하면 최단 경로가 아니라 이상한 궤적을 그린다.
359도 → 1도로 갈 때 358도를 역주행한다.

### 그럼 언제 rotation을 써도 되는가

- 에디터에서 값을 한 번 세팅할 때 (인스펙터)
- 단일 축 회전만 하고 누적하지 않을 때 (예: 아이템이 Y축으로만 도는 연출)

```gdscript
# 이 정도는 괜찮다
func _process(delta: float) -> void:
    rotate_y(SPIN_SPEED * delta)     # 단일 축, 짐벌락 무관
```

---

## 5. 실전 회전 패턴

### FPS 카메라 (마우스 룩) — 회전 순서를 직접 제어

```gdscript
class_name FPSCamera
extends Node3D

const MOUSE_SENSITIVITY: float = 0.002
const PITCH_LIMIT: float = deg_to_rad(89.0)

var _yaw: float = 0.0
var _pitch: float = 0.0

@onready var camera: Camera3D = $Camera3D

func _ready() -> void:
    Input.mouse_mode = Input.MOUSE_MODE_CAPTURED

func _unhandled_input(event: InputEvent) -> void:
    if event is InputEventMouseMotion and Input.mouse_mode == Input.MOUSE_MODE_CAPTURED:
        var motion := event as InputEventMouseMotion
        # 4.x는 screen_relative를 쓴다 (DPI/해상도 스케일 보정됨)
        _yaw -= motion.screen_relative.x * MOUSE_SENSITIVITY
        _pitch -= motion.screen_relative.y * MOUSE_SENSITIVITY
        _pitch = clampf(_pitch, -PITCH_LIMIT, PITCH_LIMIT)
        _apply_rotation()

func _apply_rotation() -> void:
    # 매 프레임 IDENTITY에서 다시 만든다 → 오차 누적 없음, 짐벌락 없음
    # 순서가 핵심: Yaw(Y축) 먼저, Pitch(X축) 나중
    basis = Basis()
    rotate_object_local(Vector3.UP, _yaw)
    rotate_object_local(Vector3.RIGHT, _pitch)
```

**핵심 로직**: 각도 값(`_yaw`, `_pitch`)을 float로 따로 보관하고,
매번 `Basis()`(항등)에서 새로 회전을 구성한다. `basis`에 계속 곱하지 않기 때문에
부동소수점 오차가 누적되지 않고 짐벌락도 발생하지 않는다.

### 3인칭 — 요와 피치를 분리된 노드에

```gdscript
# Player (CharacterBody3D)
#  └─ CameraPivot (Node3D)      ← Yaw만 담당
#     └─ SpringArm3D            ← Pitch만 담당
#        └─ Camera3D

@onready var pivot: Node3D = %CameraPivot
@onready var arm: SpringArm3D = %SpringArm3D

func _unhandled_input(event: InputEvent) -> void:
    if event is InputEventMouseMotion:
        var m := event as InputEventMouseMotion
        pivot.rotate_y(-m.screen_relative.x * MOUSE_SENSITIVITY)
        arm.rotation.x = clampf(
            arm.rotation.x - m.screen_relative.y * MOUSE_SENSITIVITY,
            deg_to_rad(-70.0), deg_to_rad(30.0)
        )
```

노드를 분리하면 각 노드가 단일 축만 회전하므로 짐벌락이 원천적으로 생기지 않는다.
**3인칭 카메라는 이 방식을 기본으로 한다.**

### 특정 지점 바라보기 (look_at)

```gdscript
# 기본 사용 — up 벡터는 기본 Vector3.UP
look_at(target.global_position, Vector3.UP)

# 목표가 바로 위/아래에 있으면 up과 평행해져 실패한다 → 방어
func safe_look_at(target_pos: Vector3) -> void:
    var dir := target_pos - global_position
    if dir.length_squared() < 0.0001:
        return
    var up := Vector3.UP
    if absf(dir.normalized().dot(up)) > 0.999:
        up = Vector3.FORWARD      # 대체 up 벡터
    look_at(target_pos, up)

# Y축 회전만 (지면 위 캐릭터가 목표를 향함) — 가장 흔한 패턴
func face_target_yaw_only(target_pos: Vector3) -> void:
    var flat := target_pos
    flat.y = global_position.y
    if flat.is_equal_approx(global_position):
        return
    look_at(flat, Vector3.UP)

# 부드럽게 회전
func smooth_look_at(target_pos: Vector3, delta: float, speed: float = 8.0) -> void:
    var flat := Vector3(target_pos.x, global_position.y, target_pos.z)
    if flat.is_equal_approx(global_position):
        return
    var desired := Basis.looking_at(global_position.direction_to(flat), Vector3.UP)
    global_basis = global_basis.slerp(desired, 1.0 - exp(-speed * delta))
```

`1.0 - exp(-speed * delta)` 형태는 **프레임레이트 독립적인 지수 감쇠 보간**이다.
`lerp(a, b, speed * delta)`는 프레임레이트에 따라 결과가 달라지므로 이 형태를 쓴다.

### 적이 플레이어를 보고 있는가 (내적)

```gdscript
func can_see_player(player: Node3D, fov_degrees: float = 90.0) -> bool:
    var to_player := global_position.direction_to(player.global_position)
    var forward := -global_basis.z
    # 내적 = cos(두 벡터 사이 각도)
    var cos_half_fov := cos(deg_to_rad(fov_degrees * 0.5))
    return forward.dot(to_player) > cos_half_fov
```

| 내적 값 | 의미 |
|---------|------|
| `1.0` | 같은 방향 |
| `0.0` | 수직 (90도) |
| `-1.0` | 반대 방향 |

### 좌우 판정 (외적)

```gdscript
func is_target_on_right(target: Node3D) -> bool:
    var to_target := global_position.direction_to(target.global_position)
    var cross := (-global_basis.z).cross(to_target)
    return cross.y < 0.0     # Y성분 부호로 좌우 판별
```

---

## 6. Quaternion과 보간

쿼터니언은 회전만 표현하며 짐벌락이 없고 보간이 자연스럽다.

```gdscript
# 생성
var q1 := Quaternion(global_basis)                       # Basis에서
var q2 := Quaternion(Vector3.UP, deg_to_rad(90.0))       # 축-각도
var q3 := Quaternion.from_euler(Vector3(0, PI, 0))       # 오일러에서

# 구면 선형 보간 — 최단 경로로 회전
var mid := q1.slerp(q2, 0.5)
global_basis = Basis(mid)

# 회전 합성 (곱셈 순서 = 적용 순서의 역순)
var combined := q2 * q1        # q1 적용 후 q2 적용

# 벡터 회전
var rotated := q1 * Vector3.FORWARD

# 두 방향 사이의 회전 구하기
var from_dir := Vector3.FORWARD
var to_dir := global_position.direction_to(target)
var rot := Quaternion(from_dir, to_dir)     # from을 to로 돌리는 회전
```

### 부드러운 회전 추적 (완성 코드)

```gdscript
class_name TurretAim
extends Node3D

@export var turn_speed: float = 5.0
@export var target: Node3D

func _physics_process(delta: float) -> void:
    if not is_instance_valid(target):
        return
    var desired_basis := Basis.looking_at(
        global_position.direction_to(target.global_position), Vector3.UP
    )
    var current := Quaternion(global_basis).normalized()
    var desired := Quaternion(desired_basis).normalized()
    var t := 1.0 - exp(-turn_speed * delta)
    global_basis = Basis(current.slerp(desired, t))
```

### Basis vs Quaternion 선택

| 상황 | 선택 |
|------|------|
| 회전만 필요, 보간 필요 | `Quaternion` |
| 스케일도 함께 다룸 | `Basis` |
| 축 벡터를 직접 읽어야 함 (`basis.z`) | `Basis` |
| 네트워크 전송·저장 | `Quaternion` (4개 float) |
| 애니메이션 키프레임 | `Quaternion` (엔진 내부도 이걸 씀) |

---

## 7. orthonormalize — 오차 누적 방지

`basis`에 회전을 계속 곱하면 부동소수점 오차로 축들이 직교하지 않게 되고
길이도 1에서 벗어난다. 결과적으로 모델이 서서히 기울거나 늘어난다.

```gdscript
# 매 프레임 회전을 누적하는 경우 반드시 정규화
func _physics_process(delta: float) -> void:
    global_basis = global_basis.rotated(Vector3.UP, spin * delta)
    global_transform = global_transform.orthonormalized()

# 스케일을 유지하면서 정규화
var s := scale
transform = transform.orthonormalized()
scale = s
```

`orthonormalized()`는 그람-슈미트 직교화를 수행해 축을 다시 직교·단위길이로 만든다.

**5절의 FPS 카메라처럼 매번 `Basis()`에서 새로 만드는 방식을 쓰면 이 문제가 없다.**
가능하면 그 방식을 우선한다.

---

## 8. 벡터 연산 실전

```gdscript
var a := Vector3(1, 2, 3)
var b := Vector3(4, 5, 6)

a.length()                  # 크기
a.length_squared()          # 제곱 크기 — 비교만 할 땐 sqrt를 피해 이걸 쓴다
a.normalized()              # 단위 벡터
a.distance_to(b)
a.distance_squared_to(b)    # 거리 비교용
a.direction_to(b)           # (b - a).normalized()
a.dot(b)                    # 내적 — 각도 관계
a.cross(b)                  # 외적 — 두 벡터에 수직인 벡터
a.lerp(b, 0.5)              # 선형 보간
a.slerp(b, 0.5)             # 구면 보간 (방향 보간에 적합)
a.move_toward(b, 0.1)       # b를 향해 일정 거리만큼 (오버슈트 없음)
a.limit_length(10.0)        # 최대 길이 제한
a.project(b)                # b 위로 투영
a.bounce(normal)            # 반사
a.reflect(normal)
a.slide(normal)             # 평면을 따라 미끄러짐 — 벽 슬라이딩 계산에 사용
a.rotated(Vector3.UP, PI)   # 축 기준 회전
a.snapped(Vector3.ONE)      # 그리드 스냅
a.is_equal_approx(b)        # 부동소수점 근사 비교 — == 대신 이것을 쓴다
a.is_zero_approx()
```

### 거리 비교는 제곱으로

```gdscript
# 느림 — sqrt 연산
if global_position.distance_to(target) < attack_range: pass

# 빠름 — 매 프레임 수백 번 도는 코드에서는 이렇게
if global_position.distance_squared_to(target) < attack_range * attack_range: pass
```

### 속도 감쇠와 가속 (프레임레이트 독립)

```gdscript
const ACCEL: float = 20.0
const FRICTION: float = 15.0

func _physics_process(delta: float) -> void:
    var input_dir := Input.get_vector("move_left", "move_right", "move_forward", "move_back")
    var direction := (transform.basis * Vector3(input_dir.x, 0, input_dir.y)).normalized()

    if direction:
        velocity.x = move_toward(velocity.x, direction.x * SPEED, ACCEL * delta)
        velocity.z = move_toward(velocity.z, direction.z * SPEED, ACCEL * delta)
    else:
        velocity.x = move_toward(velocity.x, 0.0, FRICTION * delta)
        velocity.z = move_toward(velocity.z, 0.0, FRICTION * delta)
```

---

## 9. Camera3D

```gdscript
@onready var camera: Camera3D = %Camera3D

# 주요 속성
camera.fov = 75.0                      # 수직 시야각 (도). 기본 75
camera.near = 0.05                     # 근평면 — 너무 작으면 Z-fighting
camera.far = 4000.0                    # 원평면 — 너무 크면 깊이 정밀도 손실
camera.projection = Camera3D.PROJECTION_PERSPECTIVE   # 또는 PROJECTION_ORTHOGONAL
camera.size = 10.0                     # 직교 투영일 때의 크기
camera.current = true                  # 이 카메라를 활성화
camera.cull_mask = 0xFFFFF             # 렌더 레이어 마스크
camera.keep_aspect = Camera3D.KEEP_HEIGHT
camera.h_offset = 0.0                  # 화면 오프셋 (조준 시 시야 이동)
camera.v_offset = 0.0

# 여러 카메라 중 전환
camera.make_current()
```

**near/far 설정 지침**: `far / near` 비율이 깊이 버퍼 정밀도를 결정한다.
비율이 클수록 원거리에서 Z-fighting이 생긴다. `near = 0.05`, `far = 1000` 정도가
일반적인 3D 게임의 안전한 값이다. 모바일에서는 `far`를 더 줄여 컬링 이득을 얻는다.

### 좌표 변환 API

```gdscript
# 3D 월드 좌표 → 2D 화면 좌표 (HUD 마커, 데미지 숫자)
var screen_pos: Vector2 = camera.unproject_position(enemy.global_position)

# 카메라 뒤에 있는지 확인 — 없으면 뒤쪽 물체가 화면에 잘못 표시된다
if camera.is_position_behind(enemy.global_position):
    marker.visible = false
else:
    marker.position = screen_pos
    marker.visible = true

# 2D 화면 좌표 → 3D 광선
var from := camera.project_ray_origin(mouse_pos)
var dir := camera.project_ray_normal(mouse_pos)

# 화면 좌표를 특정 깊이의 3D 좌표로
var world_pos := camera.project_position(mouse_pos, 10.0)

# 절두체 안에 있는지
if camera.is_position_in_frustum(target.global_position):
    pass
```

### HUD 마커 (3D 대상 위에 2D UI 표시)

```gdscript
class_name WorldMarker
extends Control

@export var target: Node3D
@export var offset: Vector3 = Vector3(0, 2, 0)

@onready var camera: Camera3D = get_viewport().get_camera_3d()

func _process(_delta: float) -> void:
    if not is_instance_valid(target) or camera == null:
        visible = false
        return
    var world_pos := target.global_position + offset
    if camera.is_position_behind(world_pos):
        visible = false
        return
    visible = true
    global_position = camera.unproject_position(world_pos) - size * 0.5
```

---

## 10. SpringArm3D 3인칭 카메라

`SpringArm3D`는 자식(보통 카메라)을 `-Z` 방향으로 `spring_length`만큼 밀어내되,
그 사이에 충돌체가 있으면 자동으로 당겨서 벽을 통과하지 않게 한다.

```gdscript
# 씬 구조
# Player (CharacterBody3D)
#  └─ CameraPivot (Node3D)
#     └─ SpringArm3D
#        └─ Camera3D
```

```gdscript
class_name ThirdPersonCamera
extends Node3D            # CameraPivot에 붙는 스크립트

const MOUSE_SENSITIVITY: float = 0.003
const PITCH_MIN: float = deg_to_rad(-60.0)
const PITCH_MAX: float = deg_to_rad(30.0)

@export var follow_target: Node3D
@export var follow_speed: float = 12.0

@onready var arm: SpringArm3D = $SpringArm3D
@onready var camera: Camera3D = $SpringArm3D/Camera3D

func _ready() -> void:
    Input.mouse_mode = Input.MOUSE_MODE_CAPTURED
    arm.spring_length = 4.0
    arm.margin = 0.2                              # 벽에서 띄울 여유
    arm.collision_mask = 1                        # 지형 레이어만 감지
    # 플레이어 자신과 충돌하지 않도록 예외 등록
    arm.add_excluded_object(get_parent().get_rid())
    # 카메라 피벗을 플레이어 회전에서 분리 (top_level)
    top_level = true

func _unhandled_input(event: InputEvent) -> void:
    if event is InputEventMouseMotion and Input.mouse_mode == Input.MOUSE_MODE_CAPTURED:
        var m := event as InputEventMouseMotion
        rotate_y(-m.screen_relative.x * MOUSE_SENSITIVITY)
        arm.rotation.x = clampf(
            arm.rotation.x - m.screen_relative.y * MOUSE_SENSITIVITY,
            PITCH_MIN, PITCH_MAX
        )

func _physics_process(delta: float) -> void:
    if not is_instance_valid(follow_target):
        return
    # 지수 감쇠로 부드럽게 추적 (프레임레이트 독립)
    var t := 1.0 - exp(-follow_speed * delta)
    global_position = global_position.lerp(
        follow_target.global_position + Vector3.UP * 1.5, t
    )
```

**`top_level = true`의 의미**: 부모의 변환을 무시하고 자신의 글로벌 변환을 직접 관리한다.
카메라 피벗을 플레이어의 자식으로 두되 플레이어 회전에 딸려 돌지 않게 할 때 필수다.

### SpringArm3D 주요 속성

| 속성 | 설명 |
|------|------|
| `spring_length` | 최대 거리 (기본 1.0) |
| `margin` | 충돌 지점에서 추가로 띄울 거리. 카메라가 벽에 파묻히는 것을 방지 |
| `collision_mask` | 어떤 레이어와 충돌 검사할지 |
| `shape` | 레이 대신 셰이프로 검사 (`SphereShape3D` 권장 — 좁은 틈에서 덜 튐) |
| `add_excluded_object(rid)` | 특정 바디 무시 |
| `get_hit_length()` | 실제로 적용된 거리 |

---

## 11. 마우스 피킹

화면의 마우스 위치에서 3D 공간의 물체를 선택한다.

```gdscript
class_name MousePicker
extends Node3D

const RAY_LENGTH: float = 1000.0

@onready var camera: Camera3D = get_viewport().get_camera_3d()

func _unhandled_input(event: InputEvent) -> void:
    if event is InputEventMouseButton:
        var mb := event as InputEventMouseButton
        if mb.button_index == MOUSE_BUTTON_LEFT and mb.pressed:
            var hit := _raycast_from_mouse(mb.position)
            if not hit.is_empty():
                _on_picked(hit.collider as Node3D, hit.position as Vector3)

func _raycast_from_mouse(mouse_pos: Vector2) -> Dictionary:
    var from := camera.project_ray_origin(mouse_pos)
    var to := from + camera.project_ray_normal(mouse_pos) * RAY_LENGTH

    var space := get_world_3d().direct_space_state
    var query := PhysicsRayQueryParameters3D.create(from, to)
    query.collide_with_areas = true
    query.collide_with_bodies = true
    query.collision_mask = 0b0000_0010     # 선택 가능 레이어만
    return space.intersect_ray(query)

func _on_picked(node: Node3D, world_pos: Vector3) -> void:
    print("선택: %s at %v" % [node.name, world_pos])
```

`intersect_ray()`가 반환하는 딕셔너리 구조:

```gdscript
{
    "position": Vector3,      # 충돌 지점 (월드)
    "normal": Vector3,        # 표면 법선
    "collider": Object,       # 충돌한 노드
    "collider_id": int,       # 인스턴스 ID
    "rid": RID,               # 물리 서버 핸들
    "shape": int,             # 몇 번째 셰이프인지
    "face_index": int         # 삼각형 인덱스 (Jolt는 기본 -1)
}
```

비어 있으면 `{}`(빈 딕셔너리)다. 반드시 `is_empty()`로 확인한다.

### 지면 위치 구하기 (RTS 스타일)

```gdscript
func get_ground_position(mouse_pos: Vector2) -> Vector3:
    var from := camera.project_ray_origin(mouse_pos)
    var dir := camera.project_ray_normal(mouse_pos)
    # Y=0 평면과의 교점 — 물리 없이 수학으로 계산 (더 빠름)
    var plane := Plane(Vector3.UP, 0.0)
    var hit := plane.intersects_ray(from, dir)
    return hit if hit != null else Vector3.ZERO
```

---

## 12. MeshInstance3D와 가시성

```gdscript
@onready var mesh: MeshInstance3D = $MeshInstance3D

# 메시 교체
mesh.mesh = load("res://assets/models/sword.tres")

# 머티리얼 — 세 가지 경로가 있다
mesh.material_override = my_material                    # 모든 서피스 강제 교체
mesh.set_surface_override_material(0, my_material)      # 특정 서피스만
mesh.mesh.surface_set_material(0, my_material)          # 메시 리소스 자체 수정(공유됨!)

# 인스턴스별 셰이더 파라미터 (머티리얼을 복제하지 않고)
mesh.set_instance_shader_parameter("tint", Color.RED)

# 그림자 캐스팅
mesh.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_ON
# SHADOW_CASTING_SETTING_OFF / ON / DOUBLE_SIDED / SHADOW_ONLY

# GI 모드 (LightmapGI 베이킹 대상 지정)
mesh.gi_mode = GeometryInstance3D.GI_MODE_STATIC        # 라이트맵 베이킹 대상
# GI_MODE_DISABLED / STATIC / DYNAMIC

# LOD
mesh.lod_bias = 1.0                                     # 낮출수록 일찍 LOD 전환

# 가시 범위 (HLOD)
mesh.visibility_range_begin = 0.0
mesh.visibility_range_end = 100.0
mesh.visibility_range_end_margin = 10.0
mesh.visibility_range_fade_mode = GeometryInstance3D.VISIBILITY_RANGE_FADE_SELF

# 투명도 (0=완전 투명)
mesh.transparency = 0.5
```

### 가시성 제어

```gdscript
# 자신만 숨김 (자식은 부모가 숨으면 함께 안 보임)
visible = false

# 자식 포함 실제 렌더링 여부
if is_visible_in_tree():
    pass

# 처리까지 멈추려면 process_mode도 함께
visible = false
process_mode = Node.PROCESS_MODE_DISABLED
```

**성능 주의**: `visible = false`는 렌더링만 막고 `_process`는 계속 돈다.
화면 밖 객체의 로직까지 멈추려면 `VisibleOnScreenEnabler3D`를 쓴다.

```gdscript
# VisibleOnScreenEnabler3D — 화면에 보일 때만 노드를 활성화
# 씬에 자식으로 추가하고 enable_node_path를 부모로 지정
```

### 머티리얼 개별화

머티리얼은 리소스이므로 같은 씬을 여러 개 인스턴스화하면 **공유된다**.
한 인스턴스의 색을 바꾸면 전부 바뀐다.

```gdscript
func _ready() -> void:
    # 이 인스턴스만의 머티리얼로 분리
    var mat := mesh.get_active_material(0)
    if mat:
        mesh.material_override = mat.duplicate()
```

또는 인스펙터에서 리소스를 우클릭 → **Make Unique**, 혹은 `Local to Scene` 체크.

가장 가벼운 방법은 `set_instance_shader_parameter()`다.
머티리얼을 복제하지 않으므로 드로우콜 배칭이 유지된다.

---

## 13. 자주 하는 실수

| 실수 | 증상 | 해결 |
|------|------|------|
| `transform.basis.z`를 전방으로 사용 | 뒤로 감 | `-transform.basis.z` |
| `instantiate()` 직후 `global_position` 설정 | 위치가 안 먹음 | `add_child()` 이후에 설정 |
| `rotation`을 누적 | 짐벌락·떨림 | `Basis()`에서 재구성하거나 노드 분리 |
| `look_at`에 up과 평행한 방향 | 에러/NaN | 방향 검사 후 대체 up 사용 |
| `lerp(a, b, speed * delta)` | 프레임레이트 의존 | `1.0 - exp(-speed * delta)` |
| `basis`에 계속 `rotated()` 곱하기 | 모델이 기울어짐 | `orthonormalized()` |
| `distance_to`를 매 프레임 대량 호출 | CPU 낭비 | `distance_squared_to` |
| `camera.unproject_position`만 사용 | 뒤쪽 물체가 앞에 표시됨 | `is_position_behind` 확인 |
| SpringArm이 플레이어와 충돌 | 카메라가 붙어버림 | `add_excluded_object` |
| 머티리얼 색 변경이 전체에 반영 | 리소스 공유 | `duplicate()` 또는 `set_instance_shader_parameter` |
| `far`를 매우 크게 설정 | Z-fighting | `far`를 필요한 만큼만 |
| 트리 밖에서 `global_transform` 읽기 | 잘못된 값 | 트리 진입 후 접근 |
