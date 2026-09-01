# 3D 내비게이션과 AI 이동

## 목차

1. [핵심 개념 — 서버 기반 길찾기](#1-핵심-개념--서버-기반-길찾기)
2. [NavigationRegion3D와 navmesh 베이킹](#2-navigationregion3d와-navmesh-베이킹)
3. [NavigationAgent3D 전체 속성](#3-navigationagent3d-전체-속성)
4. [기본 추적 AI (완성 코드)](#4-기본-추적-ai-완성-코드)
5. [회피(Avoidance)](#5-회피avoidance)
6. [NavigationObstacle3D](#6-navigationobstacle3d)
7. [NavigationLink3D](#7-navigationlink3d)
8. [내비게이션 레이어](#8-내비게이션-레이어)
9. [NavigationServer3D 직접 사용](#9-navigationserver3d-직접-사용)
10. [런타임 재베이킹](#10-런타임-재베이킹)
11. [AStar3D와의 선택 기준](#11-astar3d와의-선택-기준)
12. [적 AI 상태 머신 (완성 코드)](#12-적-ai-상태-머신-완성-코드)
13. [자주 하는 실수](#13-자주-하는-실수)

---

## 1. 핵심 개념 — 서버 기반 길찾기

Godot의 내비게이션은 **폴리곤 메시 위의 최단 경로 탐색**이다.
그리드 기반이 아니라 폴리곤 기반이므로, 넓은 평지를 단 몇 개의 폴리곤으로 표현할 수 있어
대규모 월드에서도 메모리와 탐색 비용이 낮다.

```
NavigationServer3D          — 실제 계산을 수행하는 서버 (스레드에서 동작)
   ├─ NavMap (RID)          — 하나의 내비게이션 공간. World3D마다 기본 맵이 하나
   │   ├─ NavRegion (RID)   — NavigationRegion3D가 등록하는 폴리곤 덩어리
   │   ├─ NavLink (RID)     — 떨어진 두 지점 연결
   │   ├─ NavAgent (RID)    — 회피 계산 참여자
   │   └─ NavObstacle (RID) — 회피 장애물
   └─ (노드는 모두 이 RID들의 래퍼일 뿐이다)
```

**가장 중요한 사실: 서버는 물리 프레임에 맞춰 비동기로 동기화된다.**
씬이 로드된 첫 프레임에는 맵이 아직 준비되지 않았다. 이 시점에 경로를 요청하면
빈 경로가 돌아온다.

```gdscript
func _ready() -> void:
    _setup.call_deferred()

func _setup() -> void:
    await get_tree().physics_frame        # 맵 동기화 대기 — 반드시 필요
    agent.target_position = target.global_position
```

### 2D와 3D 서버가 분리되었다 (4.6+)

원래 `NavigationServer2D`는 이름만 2D였고 **내부적으로 `NavigationServer3D`를 두 축으로
제한해 쓰는 프록시**였다. 그래서 순수 2D 게임도 **3D 지원이 포함된 export template**이
필요했고, 내보낸 파일 크기가 그만큼 커졌다.

4.6부터 **전용 2D 내비게이션 서버**가 생겼다. 2D와 3D 설정을 독립적으로 조정할 수 있다.

```ini
[navigation]

2d/navigation_engine="DEFAULT"      ; 2D 와 3D 를 따로 지정한다
3d/navigation_engine="DEFAULT"
3d/default_cell_size=0.25
2d/default_cell_size=1.0
```

라리엔 3D는 3D 내비게이션만 쓰므로 **직접적인 영향은 없다.** 다만 설정 경로가
`navigation/3d/...`로 분리되어 있으므로, 값을 찾을 때 `2d` 쪽을 보지 않도록 주의한다.

### 비동기 처리 — 기본으로 켜져 있다

내비게이션 맵과 리전 처리를 **백그라운드 스레드에 위임**하는 옵션이다.
메인 스레드가 모든 일을 떠안지 않게 되어 전체 성능이 좋아진다.

```ini
[navigation]

world/map_use_async_iterations=true        ; 기본 true
world/region_use_async_iterations=true     ; 기본 true
pathfinding/max_threads=4
baking/thread_model/baking_use_multiple_threads=true
avoidance/thread_model/avoidance_use_multiple_threads=true
```

**둘 다 기본값이 `true`다.** 따로 켤 필요가 없다.

대신 **비동기라는 점을 전제로 코드를 짜야 한다.** 리전을 바꾼 직후 그 결과가 즉시
반영되어 있다고 가정하면 안 된다. 맵 동기화를 기다리는 규칙(위 `await
get_tree().physics_frame`)이 그래서 필요하다. 런타임 재베이킹에서도 마찬가지다
(→ [10. 런타임 재베이킹](#10-런타임-재베이킹)).

---

## 2. NavigationRegion3D와 navmesh 베이킹

### 에디터 절차

1. 씬에 `NavigationRegion3D` 추가
2. 인스펙터에서 `NavigationMesh` 리소스 새로 만들기
3. 지형 메시(`MeshInstance3D`)를 `NavigationRegion3D`의 **자식**으로 배치
   (또는 `geometry_source_group_name` 그룹으로 지정)
4. `NavigationRegion3D` 선택 → 상단 `Bake NavigationMesh` 클릭
5. 반투명한 파란 메시가 생기면 성공

### NavigationMesh 베이킹 파라미터

| 파라미터 | 기본값 | 의미 |
|---------|--------|------|
| `cell_size` | `0.25` | 복셀화 셀 크기(수평). 작을수록 정밀·느림 |
| `cell_height` | `0.25` | 복셀 높이 |
| `agent_height` | `1.5` | 에이전트 키. 이보다 낮은 천장 아래는 제외 |
| `agent_radius` | `0.5` | 에이전트 반지름. 벽에서 이만큼 떨어진 곳까지만 걷기 가능 |
| `agent_max_climb` | `0.25` | 올라갈 수 있는 최대 턱 높이 (계단) |
| `agent_max_slope` | `45.0` | 걸을 수 있는 최대 경사(도) |
| `region_min_size` | `2.0` | 이보다 작은 고립 영역 제거 |
| `region_merge_size` | `20.0` | 이보다 작은 영역은 인접 영역에 병합 |
| `edge_max_length` | `12.0` | 폴리곤 가장자리 최대 길이 |
| `edge_max_error` | `1.3` | 단순화 허용 오차 |
| `detail_sample_distance` | `6.0` | 높이 디테일 샘플 간격 |
| `detail_sample_max_error` | `1.0` | 높이 디테일 오차 |
| `geometry_parsed_geometry_type` | `Mesh Instances` | `Mesh Instances` / `Static Colliders` / `Both` |
| `geometry_source_geometry_mode` | `Root Node Children` | 어디서 지오메트리를 수집할지 |
| `geometry_collision_mask` | `0xFFFFFFFF` | 콜라이더 파싱 시 대상 레이어 |
| `filter_low_hanging_obstacles` | `false` | 낮은 장애물 제거 |
| `filter_ledge_spans` | `false` | 절벽 가장자리 제거 |
| `filter_walkable_low_height_spans` | `false` | 낮은 통로 제거 |

### 파라미터 설정 원칙

**`agent_radius`가 가장 중요하다.** 이 값이 실제 캐릭터의 `CapsuleShape3D.radius`보다
작으면 캐릭터가 벽에 끼인다. **실제 반지름보다 약간 크게** 잡는다.

```
캐릭터 CapsuleShape3D.radius = 0.35
→ NavigationMesh.agent_radius = 0.4  (여유 포함)
```

`cell_size`는 `agent_radius`의 1/2 이하로 두는 것이 권장된다.
너무 크면 좁은 통로가 사라지고, 너무 작으면 베이킹이 매우 느려진다.

### 콜라이더 기반 베이킹 (권장)

`Static Colliders` 모드를 쓰면 시각 메시가 아니라 물리 콜리전에서 navmesh를 만든다.
시각 메시와 콜리전이 다른 경우(저폴리 콜리전 사용) 이 방식이 정확하다.

```gdscript
nav_mesh.geometry_parsed_geometry_type = \
    NavigationMesh.PARSED_GEOMETRY_STATIC_COLLIDERS
nav_mesh.geometry_collision_mask = 0b0001      # World 레이어만
```

### glTF 임포트로 navmesh 생성

Blender에서 메시 이름에 `-navmesh` 접미사를 붙이면 임포트 시
`NavigationRegion3D`로 자동 변환된다.

---

## 3. NavigationAgent3D 전체 속성

```gdscript
@onready var agent: NavigationAgent3D = $NavigationAgent3D
```

### 경로 탐색 관련

| 속성 | 기본값 | 의미 |
|------|--------|------|
| `target_position` | `(0,0,0)` | 목표 지점. 설정하면 경로 재계산 |
| `path_desired_distance` | `1.0` | 경로 지점에 이만큼 접근하면 다음 지점으로 |
| `target_desired_distance` | `1.0` | 목표에 이만큼 접근하면 도착으로 판정 |
| `path_max_distance` | `5.0` | 경로에서 이만큼 벗어나면 재계산 |
| `path_height_offset` | `0.0` | 경로 지점의 Y 오프셋 |
| `path_postprocessing` | `CORRIDORFUNNEL` | `CORRIDORFUNNEL`(자연스러움) / `EDGECENTERED` |
| `path_metadata_flags` | `ALL` | 경로 지점의 메타데이터 수집 |
| `navigation_layers` | `1` | 사용할 내비 레이어 비트마스크 |
| `pathfinding_algorithm` | `ASTAR` | 경로 탐색 알고리즘 |
| `simplify_path` | `false` | 경로 단순화 (4.3+) |
| `simplify_epsilon` | `0.0` | 단순화 허용 오차 |

### 회피 관련

| 속성 | 기본값 | 의미 |
|------|--------|------|
| `avoidance_enabled` | `false` | RVO 회피 활성화 |
| `radius` | `0.5` | 회피 계산용 반지름 |
| `height` | `1.0` | 3D 회피 시 높이 |
| `neighbor_distance` | `50.0` | 이 거리 안의 이웃만 고려 |
| `max_neighbors` | `10` | 고려할 최대 이웃 수 |
| `time_horizon_agents` | `1.0` | 에이전트 충돌 예측 시간(초) |
| `time_horizon_obstacles` | `0.0` | 장애물 충돌 예측 시간 |
| `max_speed` | `10.0` | 회피 계산 시 최대 속도 |
| `use_3d_avoidance` | `false` | 3D(높이 포함) 회피. 비행 유닛용 |
| `avoidance_layers` / `avoidance_mask` | `1` | 회피 레이어 |
| `avoidance_priority` | `1.0` | 높을수록 덜 비켜줌 |

### 메서드와 시그널

```gdscript
# 메서드
agent.get_next_path_position() -> Vector3      # 다음에 향할 지점 (핵심)
agent.is_navigation_finished() -> bool
agent.is_target_reached() -> bool
agent.is_target_reachable() -> bool
agent.distance_to_target() -> float
agent.get_current_navigation_path() -> PackedVector3Array
agent.get_current_navigation_path_index() -> int
agent.get_final_position() -> Vector3          # 실제 도달 가능한 최종 지점
agent.set_velocity(v: Vector3)                 # 회피 사용 시 이걸로 속도 전달
agent.set_velocity_forced(v: Vector3)
agent.get_rid() -> RID
agent.get_navigation_map() -> RID
agent.set_navigation_map(rid: RID)

# 시그널
agent.path_changed.connect(_on_path_changed)
agent.target_reached.connect(_on_target_reached)
agent.navigation_finished.connect(_on_navigation_finished)
agent.velocity_computed.connect(_on_velocity_computed)     # 회피 활성화 시 필수
agent.waypoint_reached.connect(_on_waypoint_reached)
agent.link_reached.connect(_on_link_reached)               # NavigationLink 진입
```

### `get_next_path_position()`의 동작

이 메서드는 **호출할 때마다 내부 상태를 갱신한다.**
현재 위치가 `path_desired_distance` 안에 들어오면 인덱스를 다음으로 넘긴다.

따라서 **한 물리 프레임에 한 번만 호출한다.** 여러 번 호출하면 경로를 건너뛴다.

---

## 4. 기본 추적 AI (완성 코드)

```gdscript
class_name NavAgentMover
extends CharacterBody3D

@export var move_speed: float = 3.5
@export var acceleration: float = 12.0
@export var turn_speed: float = 10.0
@export var repath_interval: float = 0.4      # 목표 재설정 주기

@onready var agent: NavigationAgent3D = $NavigationAgent3D
@onready var model: Node3D = %Model
@onready var _gravity: float = ProjectSettings.get_setting(
    "physics/3d/default_gravity", 9.8
)

var target: Node3D
var _repath_timer: float = 0.0

func _ready() -> void:
    agent.path_desired_distance = 0.5
    agent.target_desired_distance = 1.0
    agent.path_max_distance = 3.0
    agent.avoidance_enabled = false
    _setup.call_deferred()

func _setup() -> void:
    # 서버 동기화 대기 — 이걸 빼면 첫 경로가 비어 있다
    await get_tree().physics_frame

func set_target(node: Node3D) -> void:
    target = node
    _repath_timer = 0.0

func _physics_process(delta: float) -> void:
    if not is_on_floor():
        velocity.y -= _gravity * delta

    _update_target(delta)

    if agent.is_navigation_finished():
        velocity.x = move_toward(velocity.x, 0.0, acceleration * delta)
        velocity.z = move_toward(velocity.z, 0.0, acceleration * delta)
        move_and_slide()
        return

    # 한 프레임에 한 번만 호출한다
    var next_pos := agent.get_next_path_position()
    var direction := global_position.direction_to(next_pos)
    direction.y = 0.0
    direction = direction.normalized()

    velocity.x = move_toward(velocity.x, direction.x * move_speed, acceleration * delta)
    velocity.z = move_toward(velocity.z, direction.z * move_speed, acceleration * delta)

    _face_direction(direction, delta)
    move_and_slide()

func _update_target(delta: float) -> void:
    if not is_instance_valid(target):
        return
    _repath_timer -= delta
    if _repath_timer > 0.0:
        return
    _repath_timer = repath_interval
    # 목표가 크게 움직였을 때만 갱신 — 매 프레임 설정하면 서버 부하가 크다
    if agent.target_position.distance_squared_to(target.global_position) > 0.25:
        agent.target_position = target.global_position

func _face_direction(direction: Vector3, delta: float) -> void:
    if direction.length_squared() < 0.01:
        return
    var desired := Basis.looking_at(direction, Vector3.UP)
    var t := 1.0 - exp(-turn_speed * delta)
    model.global_basis = Basis(
        Quaternion(model.global_basis).normalized()
            .slerp(Quaternion(desired).normalized(), t)
    )
```

### 왜 이렇게 설계했는가

- **`repath_interval`로 목표 갱신을 제한** — `target_position`을 매 프레임 설정하면
  매번 A* 탐색이 다시 돈다. 적이 수십 마리면 서버가 병목이 된다.
- **거리 임계값 체크** — 목표가 거의 안 움직였으면 재계산 자체를 건너뛴다.
- **`direction.y = 0`** — 지상 유닛은 수평 이동만 한다. 경로 지점의 높이 차이를
  그대로 속도에 넣으면 공중에 뜨거나 땅으로 파고든다.
- **`get_next_path_position()` 한 번만 호출** — 내부 인덱스가 전진하므로 중복 호출은
  경로를 건너뛴다.

---

## 5. 회피(Avoidance)

여러 에이전트가 서로 겹치지 않게 하는 RVO(Reciprocal Velocity Obstacles) 알고리즘.

**회피는 경로 탐색과 별개다.** 경로는 navmesh를 따라 계산되고, 회피는 그 경로를
따라가는 속도를 즉석에서 보정한다.

```gdscript
func _ready() -> void:
    agent.avoidance_enabled = true
    agent.radius = 0.5
    agent.height = 1.8
    agent.max_speed = move_speed
    agent.neighbor_distance = 8.0        # 50은 너무 넓다 — 성능을 위해 줄인다
    agent.max_neighbors = 6
    agent.time_horizon_agents = 1.0
    agent.time_horizon_obstacles = 0.5
    agent.use_3d_avoidance = false       # 지상 유닛은 false
    # 회피 결과를 받는 콜백 — 반드시 연결해야 한다
    agent.velocity_computed.connect(_on_velocity_computed)

func _physics_process(delta: float) -> void:
    if agent.is_navigation_finished():
        return
    var next_pos := agent.get_next_path_position()
    var desired := global_position.direction_to(next_pos) * move_speed
    desired.y = 0.0

    # 회피 켜짐: set_velocity로 "원하는 속도"를 넘기면
    # 서버가 보정한 결과를 velocity_computed 시그널로 돌려준다
    agent.set_velocity(desired)
    # 여기서 move_and_slide()를 호출하지 않는다!

func _on_velocity_computed(safe_velocity: Vector3) -> void:
    velocity.x = safe_velocity.x
    velocity.z = safe_velocity.z
    if not is_on_floor():
        velocity.y -= _gravity * get_physics_process_delta_time()
    move_and_slide()
```

**핵심 로직**: 회피가 켜지면 이동 흐름이 두 단계로 나뉜다.

```
_physics_process       → agent.set_velocity(원하는 속도)
        ↓ (서버가 이웃을 고려해 계산)
velocity_computed 시그널 → 보정된 속도로 move_and_slide()
```

`set_velocity()` 후 같은 프레임에서 `move_and_slide()`를 부르면 회피가 반영되지 않는다.

### 회피 파라미터 튜닝

| 증상 | 조정 |
|------|------|
| 에이전트들이 서로 통과함 | `radius` 증가, `avoidance_enabled` 확인 |
| 너무 일찍 피함 | `time_horizon_agents` 감소 |
| 좁은 통로에서 교착 | `max_neighbors` 감소, `avoidance_priority` 차등화 |
| 성능 저하 | `neighbor_distance` 감소 (기본 50 → 8~10) |
| 진동(떨림) | `max_speed`를 실제 이동 속도와 일치시킴 |

### avoidance_priority

우선순위가 높은 에이전트는 덜 비켜준다. 보스나 플레이어의 우선순위를 높이면
잡몹들이 알아서 길을 비킨다.

```gdscript
boss_agent.avoidance_priority = 1.0
minion_agent.avoidance_priority = 0.3
```

---

## 6. NavigationObstacle3D

**경로 탐색에는 영향을 주지 않고, 회피 동작에만 제약을 가한다.**

경로 자체를 막으려면 navmesh를 다시 구워야 한다. 동적으로 나타나는 장애물
(플레이어가 놓은 상자, 이동하는 차량)에 쓴다.

```gdscript
var obstacle := NavigationObstacle3D.new()
add_child(obstacle)

# 방법 1: 반지름 기반 (움직이는 장애물)
obstacle.radius = 1.5
obstacle.height = 2.0
obstacle.avoidance_enabled = true
obstacle.velocity = Vector3.ZERO      # 움직이면 실제 속도 대입

# 방법 2: 정점 기반 (정적 영역 차단)
obstacle.vertices = PackedVector3Array([
    Vector3(-2, 0, -2), Vector3(2, 0, -2),
    Vector3(2, 0, 2), Vector3(-2, 0, 2),
])
obstacle.affect_navigation_mesh = true       # 4.3+ — navmesh 베이킹에도 반영
obstacle.carve_navigation_mesh = true        # navmesh에 구멍을 뚫음
```

**`carve_navigation_mesh`(4.3+)**: 런타임 재베이킹 시 이 장애물 영역을
navmesh에서 제외한다. 문이 닫히거나 다리가 무너지는 상황을 표현할 수 있다.

---

## 7. NavigationLink3D

떨어져 있는 두 navmesh 지점을 논리적으로 연결한다.
점프, 사다리, 텔레포터, 짚라인처럼 걸어서 갈 수 없는 이동을 표현한다.

```gdscript
var link := NavigationLink3D.new()
add_child(link)
link.start_position = Vector3(0, 0, 0)      # 로컬 좌표
link.end_position = Vector3(0, 5, 3)
link.bidirectional = false                   # 한 방향만 (낙하)
link.navigation_layers = 1
link.enter_cost = 0.0
link.travel_cost = 1.0                       # 높이면 이 경로를 덜 선호
link.enabled = true
```

**중요**: 링크는 경로 계산에만 참여한다. **실제 이동은 코드가 직접 처리해야 한다.**

```gdscript
func _ready() -> void:
    agent.path_metadata_flags = NavigationPathQueryParameters3D.PATH_METADATA_INCLUDE_ALL
    agent.link_reached.connect(_on_link_reached)

func _on_link_reached(details: Dictionary) -> void:
    # details: { "position", "type", "rid", "owner", "link_entry_position", "link_exit_position" }
    var entry: Vector3 = details["link_entry_position"]
    var exit: Vector3 = details["link_exit_position"]
    var link_node := details["owner"] as NavigationLink3D

    if link_node.has_meta("link_type"):
        match link_node.get_meta("link_type"):
            "jump":
                await _perform_jump(entry, exit)
            "ladder":
                await _climb_ladder(entry, exit)

func _perform_jump(from: Vector3, to: Vector3) -> void:
    set_physics_process(false)
    var tween := create_tween()
    tween.tween_method(
        func(t: float) -> void:
            var pos := from.lerp(to, t)
            pos.y += sin(t * PI) * 2.0        # 포물선 궤적
            global_position = pos,
        0.0, 1.0, 0.6
    )
    await tween.finished
    set_physics_process(true)
```

---

## 8. 내비게이션 레이어

비트마스크로 "어떤 에이전트가 어떤 영역을 지날 수 있는지" 구분한다.

```ini
# project.godot
[layer_names]

3d_navigation/layer_1="Ground"
3d_navigation/layer_2="Water"
3d_navigation/layer_3="Lava"
3d_navigation/layer_4="Flying"
3d_navigation/layer_5="Small"      # 작은 유닛만 지나는 좁은 길
```

```gdscript
# 물 영역
water_region.navigation_layers = 0b0010

# 지상 유닛 — 물과 용암을 지날 수 없다
ground_agent.navigation_layers = 0b0001

# 수영 가능 유닛
swimmer_agent.navigation_layers = 0b0011      # 지상 + 물

# 비행 유닛 — 전부 통과
flyer_agent.navigation_layers = 0b1111
```

```gdscript
# 코드에서 개별 비트 조작
region.set_navigation_layer_value(2, true)
var enabled := region.get_navigation_layer_value(2)
```

---

## 9. NavigationServer3D 직접 사용

노드를 만들지 않고 즉석에서 경로를 계산한다.
프리뷰 표시, 도달 가능 여부 확인, 대량 유닛 처리에 유용하다.

### 단순 경로 계산

```gdscript
func compute_path(from: Vector3, to: Vector3, layers: int = 1) -> PackedVector3Array:
    var map := get_world_3d().navigation_map
    return NavigationServer3D.map_get_path(map, from, to, true, layers)
    # 세 번째 인자 optimize=true 면 코리도-퍼널 알고리즘 적용
```

### 상세 질의 (파라미터 지정)

```gdscript
func query_path(from: Vector3, to: Vector3) -> NavigationPathQueryResult3D:
    var params := NavigationPathQueryParameters3D.new()
    params.map = get_world_3d().navigation_map
    params.start_position = from
    params.target_position = to
    params.navigation_layers = 1
    params.pathfinding_algorithm = \
        NavigationPathQueryParameters3D.PATHFINDING_ALGORITHM_ASTAR
    params.path_postprocessing = \
        NavigationPathQueryParameters3D.PATH_POSTPROCESSING_CORRIDORFUNNEL
    params.metadata_flags = \
        NavigationPathQueryParameters3D.PATH_METADATA_INCLUDE_ALL
    params.simplify_path = true
    params.simplify_epsilon = 0.2

    var result := NavigationPathQueryResult3D.new()
    NavigationServer3D.query_path(params, result)
    return result
    # result.path, result.path_types, result.path_rids, result.path_owner_ids
```

### 유틸리티 질의

```gdscript
var map := get_world_3d().navigation_map

# navmesh 위의 가장 가까운 지점으로 스냅
var snapped := NavigationServer3D.map_get_closest_point(map, world_pos)
var normal := NavigationServer3D.map_get_closest_point_normal(map, world_pos)
var owner_id := NavigationServer3D.map_get_closest_point_owner(map, world_pos)

# 레이 질의 (navmesh 가장자리까지)
var hit := NavigationServer3D.map_get_closest_point_to_segment(map, from, to, false)

# 랜덤 위치 (순찰 지점 생성)
var random_pos := NavigationServer3D.map_get_random_point(map, 1, true)

# 맵 설정
NavigationServer3D.map_set_cell_size(map, 0.25)
NavigationServer3D.map_set_edge_connection_margin(map, 0.25)
NavigationServer3D.map_set_up(map, Vector3.UP)

# 동기화 대기
await NavigationServer3D.map_changed
```

### 도달 가능 여부 확인

```gdscript
func is_reachable(from: Vector3, to: Vector3) -> bool:
    var path := compute_path(from, to)
    if path.is_empty():
        return false
    # 마지막 지점이 목표에서 멀면 도달 불가 (막힌 경로)
    return path[-1].distance_to(to) < 1.5
```

`NavigationAgent3D.is_target_reachable()`도 같은 원리로 동작한다.

---

## 10. 런타임 재베이킹

문이 열리거나 지형이 파괴될 때 navmesh를 갱신한다.

```gdscript
# 동기 베이킹 — 프레임이 멈춘다. 작은 영역에만 사용
region.bake_navigation_mesh(false)

# 비동기 베이킹 (권장)
region.bake_navigation_mesh(true)
await region.bake_finished
```

### 스레드 베이킹 (대규모)

```gdscript
func rebake_async(region: NavigationRegion3D) -> void:
    var source := NavigationMeshSourceGeometryData3D.new()
    # 지오메트리 파싱은 메인 스레드에서
    NavigationServer3D.parse_source_geometry_data(
        region.navigation_mesh, source, region
    )
    # 실제 베이킹은 스레드에서
    NavigationServer3D.bake_from_source_geometry_data_async(
        region.navigation_mesh, source,
        func() -> void:
            region.navigation_mesh = region.navigation_mesh   # 갱신 알림
    )
```

### 재베이킹 대신 쓸 수 있는 값싼 방법

| 상황 | 방법 |
|------|------|
| 문 열림/닫힘 | `NavigationLink3D.enabled` 토글 |
| 영역 통제 | `NavigationRegion3D.enabled = false` |
| 임시 장애물 | `NavigationObstacle3D` (회피만) |
| 경로 비용 변경 | `region.travel_cost` / `enter_cost` 조정 |

**재베이킹은 비싸다.** 위 방법으로 해결되면 그쪽을 택한다.

---

## 11. AStar3D와의 선택 기준

| | NavigationServer3D | AStar3D / AStarGrid2D |
|---|---|---|
| 이동 자유도 | 연속(폴리곤 위 어디든) | 이산(정해진 노드만) |
| 적합한 게임 | 액션, FPS, RPG | 턴제, 그리드 퍼즐, 타워디펜스 |
| 셋업 | navmesh 베이킹 | 노드·연결을 코드로 구성 |
| 동적 변경 | 재베이킹 필요 (비쌈) | 노드 비활성화 (저렴) |
| 회피 | RVO 내장 | 직접 구현 |

**이 프로젝트는 3D 액션이므로 NavigationServer3D를 기본으로 한다.**
격자 기반 전략 요소가 추가되면 그때 `AStar3D`를 병용한다.

```gdscript
# AStar3D 기본 사용 (참고)
var astar := AStar3D.new()
astar.add_point(0, Vector3(0, 0, 0))
astar.add_point(1, Vector3(5, 0, 0))
astar.connect_points(0, 1)
var path := astar.get_point_path(0, 1)
astar.set_point_disabled(1, true)      # 노드 비활성화 — 매우 저렴
```

---

## 12. 적 AI 상태 머신 (완성 코드)

내비게이션과 감지, 상태 전이를 결합한 실전 패턴.

```gdscript
class_name EnemyAI
extends CharacterBody3D

enum State { IDLE, PATROL, CHASE, ATTACK, RETURN, DEAD }

@export_group("감지")
@export var detect_radius: float = 12.0
@export var lose_radius: float = 18.0
@export var fov_degrees: float = 110.0
@export_flags_3d_physics var sight_block_mask: int = 1

@export_group("이동")
@export var patrol_speed: float = 2.0
@export var chase_speed: float = 4.5
@export var attack_range: float = 2.0
@export var attack_cooldown: float = 1.2

@export_group("순찰")
@export var patrol_points: Array[Node3D] = []
@export var patrol_wait: float = 2.0

@onready var agent: NavigationAgent3D = $NavigationAgent3D
@onready var animator: PlayerAnimator = $Animator
@onready var _gravity: float = ProjectSettings.get_setting(
    "physics/3d/default_gravity", 9.8
)

var state: State = State.IDLE
var player: Node3D
var _home_position: Vector3
var _patrol_index: int = 0
var _state_timer: float = 0.0
var _attack_timer: float = 0.0
var _repath_timer: float = 0.0

func _ready() -> void:
    _home_position = global_position
    agent.path_desired_distance = 0.5
    agent.target_desired_distance = 1.0
    agent.avoidance_enabled = true
    agent.radius = 0.5
    agent.neighbor_distance = 8.0
    agent.max_neighbors = 6
    agent.velocity_computed.connect(_on_velocity_computed)
    _init_async.call_deferred()

func _init_async() -> void:
    await get_tree().physics_frame
    player = get_tree().get_first_node_in_group("player")
    _change_state(State.PATROL if not patrol_points.is_empty() else State.IDLE)

# ── 상태 전이 ────────────────────────────────────────
func _change_state(new_state: State) -> void:
    if state == new_state:
        return
    _exit_state(state)
    state = new_state
    _state_timer = 0.0
    _enter_state(new_state)

func _enter_state(s: State) -> void:
    match s:
        State.PATROL:
            agent.max_speed = patrol_speed
            _goto_next_patrol_point()
        State.CHASE:
            agent.max_speed = chase_speed
            animator.play_alert()
        State.ATTACK:
            velocity = Vector3.ZERO
        State.RETURN:
            agent.max_speed = patrol_speed
            agent.target_position = _home_position
        State.DEAD:
            set_physics_process(false)
            agent.avoidance_enabled = false
            animator.play_death()

func _exit_state(_s: State) -> void:
    pass

# ── 메인 루프 ────────────────────────────────────────
func _physics_process(delta: float) -> void:
    _state_timer += delta
    _attack_timer = maxf(0.0, _attack_timer - delta)
    _repath_timer = maxf(0.0, _repath_timer - delta)

    match state:
        State.IDLE:      _tick_idle()
        State.PATROL:    _tick_patrol()
        State.CHASE:     _tick_chase()
        State.ATTACK:    _tick_attack()
        State.RETURN:    _tick_return()
        State.DEAD:      return

    _move(delta)

func _tick_idle() -> void:
    if _can_see_player():
        _change_state(State.CHASE)

func _tick_patrol() -> void:
    if _can_see_player():
        _change_state(State.CHASE)
        return
    if agent.is_navigation_finished():
        if _state_timer > patrol_wait:
            _goto_next_patrol_point()
            _state_timer = 0.0

func _tick_chase() -> void:
    if not is_instance_valid(player):
        _change_state(State.RETURN)
        return
    var dist := global_position.distance_to(player.global_position)
    if dist > lose_radius:
        _change_state(State.RETURN)
        return
    if dist <= attack_range and _has_line_of_sight():
        _change_state(State.ATTACK)
        return
    # 목표 갱신 빈도 제한
    if _repath_timer <= 0.0:
        _repath_timer = 0.3
        agent.target_position = player.global_position

func _tick_attack() -> void:
    if not is_instance_valid(player):
        _change_state(State.RETURN)
        return
    var dist := global_position.distance_to(player.global_position)
    if dist > attack_range * 1.3:
        _change_state(State.CHASE)
        return
    _face_target(player.global_position)
    if _attack_timer <= 0.0:
        _attack_timer = attack_cooldown
        animator.play_attack()

func _tick_return() -> void:
    if _can_see_player():
        _change_state(State.CHASE)
        return
    if agent.is_navigation_finished():
        _change_state(State.PATROL if not patrol_points.is_empty() else State.IDLE)

# ── 이동 ─────────────────────────────────────────────
func _move(delta: float) -> void:
    if state == State.ATTACK or agent.is_navigation_finished():
        velocity.x = move_toward(velocity.x, 0.0, 20.0 * delta)
        velocity.z = move_toward(velocity.z, 0.0, 20.0 * delta)
        if not is_on_floor():
            velocity.y -= _gravity * delta
        move_and_slide()
        return

    var next_pos := agent.get_next_path_position()
    var dir := global_position.direction_to(next_pos)
    dir.y = 0.0
    agent.set_velocity(dir.normalized() * agent.max_speed)
    # move_and_slide는 velocity_computed 콜백에서 호출된다

func _on_velocity_computed(safe_velocity: Vector3) -> void:
    velocity.x = safe_velocity.x
    velocity.z = safe_velocity.z
    if not is_on_floor():
        velocity.y -= _gravity * get_physics_process_delta_time()
    else:
        velocity.y = 0.0
    if velocity.length_squared() > 0.04:
        _face_target(global_position + Vector3(velocity.x, 0.0, velocity.z))
    move_and_slide()

func _face_target(pos: Vector3) -> void:
    var flat := Vector3(pos.x, global_position.y, pos.z)
    if flat.is_equal_approx(global_position):
        return
    var desired := Basis.looking_at(global_position.direction_to(flat), Vector3.UP)
    var t := 1.0 - exp(-10.0 * get_physics_process_delta_time())
    global_basis = Basis(
        Quaternion(global_basis).normalized()
            .slerp(Quaternion(desired).normalized(), t)
    )

# ── 감지 ─────────────────────────────────────────────
func _can_see_player() -> bool:
    if not is_instance_valid(player):
        return false
    if global_position.distance_squared_to(player.global_position) \
            > detect_radius * detect_radius:
        return false
    var to_player := global_position.direction_to(player.global_position)
    if (-global_basis.z).dot(to_player) < cos(deg_to_rad(fov_degrees * 0.5)):
        return false
    return _has_line_of_sight()

func _has_line_of_sight() -> bool:
    var space := get_world_3d().direct_space_state
    var query := PhysicsRayQueryParameters3D.create(
        global_position + Vector3.UP * 1.5,
        player.global_position + Vector3.UP * 1.0,
        sight_block_mask,
        [get_rid()]
    )
    return space.intersect_ray(query).is_empty()

func _goto_next_patrol_point() -> void:
    if patrol_points.is_empty():
        return
    _patrol_index = (_patrol_index + 1) % patrol_points.size()
    var pt := patrol_points[_patrol_index]
    if is_instance_valid(pt):
        agent.target_position = pt.global_position
```

### 설계 근거

- **감지 반경(`detect_radius`)과 상실 반경(`lose_radius`)을 분리** — 같으면 경계선에서
  추적/포기가 반복되어 적이 떨린다. 이력 현상(hysteresis)이 필요하다.
- **시야각 + 레이캐스트 2단계 검사** — 레이캐스트가 비싸므로 거리와 각도로 먼저 걸러낸다.
- **`_repath_timer`로 경로 재계산 제한** — 적 20마리가 매 프레임 A*를 돌리면 병목이 된다.
- **회피를 켠 상태에서 `move_and_slide()`는 콜백에서만** — 중복 호출하면 회피가 무시된다.
- **`ATTACK` 상태에서 이동 정지** — 공격 중 미끄러지면 타격감이 무너진다.

---

## 13. 자주 하는 실수

| 실수 | 증상 | 해결 |
|------|------|------|
| 첫 프레임에 경로 요청 | 경로가 비어 있음 | `await get_tree().physics_frame` |
| `get_next_path_position()` 여러 번 호출 | 경로 건너뜀 | 프레임당 1회 |
| 매 프레임 `target_position` 설정 | 서버 부하, 프레임 저하 | 거리 임계값 + 타이머로 제한 |
| 회피 켜고 `set_velocity` 후 즉시 `move_and_slide()` | 회피 미반영 | `velocity_computed` 콜백에서 호출 |
| `agent_radius` < 실제 캡슐 반지름 | 벽에 끼임 | navmesh `agent_radius`를 더 크게 |
| `neighbor_distance` 기본값(50) 유지 | 성능 저하 | 8~10으로 축소 |
| `direction.y`를 그대로 속도에 사용 | 공중에 뜨거나 땅에 박힘 | `direction.y = 0` |
| `NavigationObstacle3D`로 경로를 막으려 함 | 경로가 그대로 통과 | 재베이킹 또는 `carve_navigation_mesh` |
| `NavigationLink3D`만 두고 이동 코드 없음 | 캐릭터가 순간이동하거나 멈춤 | `link_reached`에서 직접 이동 처리 |
| 감지/상실 반경이 동일 | 적이 추적/포기를 반복 | 상실 반경을 더 크게 |
| 매 프레임 `bake_navigation_mesh()` | 프레임 정지 | 비동기 베이킹 또는 링크 토글 |
| navmesh가 계단을 인식 못 함 | 경로가 끊김 | `agent_max_climb` 증가 |
| 좁은 통로가 navmesh에서 사라짐 | 경로 없음 | `cell_size` 감소, `agent_radius` 확인 |
