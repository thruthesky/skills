# 멀티플레이어

## 목차

1. [핵심 개념 — 권위와 동기화](#1-핵심-개념--권위와-동기화)
2. [연결 수립 (ENetMultiplayerPeer)](#2-연결-수립-enetmultiplayerpeer)
3. [@rpc 어노테이션 전체](#3-rpc-어노테이션-전체)
4. [멀티플레이어 권한(Authority)](#4-멀티플레이어-권한authority)
5. [MultiplayerSpawner](#5-multiplayerspawner)
6. [MultiplayerSynchronizer](#6-multiplayersynchronizer)
7. [서버 권위 모델 (완성 코드)](#7-서버-권위-모델-완성-코드)
8. [클라이언트 예측과 보간](#8-클라이언트-예측과-보간)
9. [입력 검증과 보안](#9-입력-검증과-보안)
10. [연결 끊김 처리](#10-연결-끊김-처리)
11. [로컬 테스트](#11-로컬-테스트)
12. [자주 하는 실수](#12-자주-하는-실수)

---

## 1. 핵심 개념 — 권위와 동기화

Godot의 하이레벨 멀티플레이 API는 세 가지 축으로 구성된다.

```
1. RPC (@rpc)                    — "이 함수를 다른 피어에서도 실행하라"
2. MultiplayerSpawner            — "이 노드가 생겼으니 너희도 만들어라"
3. MultiplayerSynchronizer       — "이 프로퍼티들을 계속 맞춰라"
```

### 피어 ID 규칙

| ID | 의미 |
|----|------|
| `1` | **서버** (항상 1) |
| `2` 이상 | 클라이언트 (연결 순서대로 랜덤 부여) |
| `0` | 브로드캐스트 대상 (모든 피어) |
| 음수 | 해당 피어를 **제외한** 모두 |

```gdscript
multiplayer.get_unique_id()          # 내 ID
multiplayer.is_server()              # 내가 서버인가
multiplayer.get_peers()              # 연결된 다른 피어 ID 배열
multiplayer.get_remote_sender_id()   # RPC 호출자 ID (RPC 함수 안에서만 유효)
```

### 권위(Authority) 모델

**"누가 이 노드의 상태를 결정하는가"** 를 정하는 것이 멀티플레이 설계의 전부다.

| 모델 | 장점 | 단점 |
|------|------|------|
| **서버 권위** | 치팅 방지, 일관성 | 입력 지연, 서버 부하 |
| **클라이언트 권위** | 반응 즉각적 | 치팅에 무방비 |
| **하이브리드** (예측 + 서버 검증) | 반응성 + 보안 | 구현 복잡 |

**원칙: 승패에 영향을 주는 것은 반드시 서버 권위로 한다.**
연출·시각 효과는 클라이언트 권위여도 된다.

---

## 2. 연결 수립 (ENetMultiplayerPeer)

```gdscript
# res://autoload/network_manager.gd
extends Node

const DEFAULT_PORT: int = 7777
const MAX_PLAYERS: int = 8

signal player_connected(peer_id: int, info: Dictionary)
signal player_disconnected(peer_id: int)
signal server_disconnected
signal connection_failed

var players: Dictionary[int, Dictionary] = {}
var local_player_info: Dictionary = {"name": "Player"}

func _ready() -> void:
    multiplayer.peer_connected.connect(_on_peer_connected)
    multiplayer.peer_disconnected.connect(_on_peer_disconnected)
    multiplayer.connected_to_server.connect(_on_connected_ok)
    multiplayer.connection_failed.connect(_on_connection_failed)
    multiplayer.server_disconnected.connect(_on_server_disconnected)

# ── 서버 ─────────────────────────────────────────────
func host_game(port: int = DEFAULT_PORT) -> Error:
    var peer := ENetMultiplayerPeer.new()
    var err := peer.create_server(port, MAX_PLAYERS)
    if err != OK:
        push_error("서버 생성 실패: %d" % err)
        return err
    multiplayer.multiplayer_peer = peer
    players[1] = local_player_info
    player_connected.emit(1, local_player_info)
    return OK

# ── 클라이언트 ───────────────────────────────────────
func join_game(address: String, port: int = DEFAULT_PORT) -> Error:
    var peer := ENetMultiplayerPeer.new()
    var err := peer.create_client(address, port)
    if err != OK:
        push_error("연결 실패: %d" % err)
        return err
    multiplayer.multiplayer_peer = peer
    return OK

func leave_game() -> void:
    if multiplayer.multiplayer_peer:
        multiplayer.multiplayer_peer.close()
    multiplayer.multiplayer_peer = null
    players.clear()

# ── 시그널 처리 ──────────────────────────────────────
func _on_peer_connected(id: int) -> void:
    # 새 피어에게 내 정보를 전달한다
    _register_player.rpc_id(id, local_player_info)

func _on_peer_disconnected(id: int) -> void:
    players.erase(id)
    player_disconnected.emit(id)

func _on_connected_ok() -> void:
    var my_id := multiplayer.get_unique_id()
    players[my_id] = local_player_info

func _on_connection_failed() -> void:
    multiplayer.multiplayer_peer = null
    connection_failed.emit()

func _on_server_disconnected() -> void:
    multiplayer.multiplayer_peer = null
    players.clear()
    server_disconnected.emit()

@rpc("any_peer", "reliable")
func _register_player(info: Dictionary) -> void:
    var id := multiplayer.get_remote_sender_id()
    # 검증 — 클라이언트가 보낸 데이터를 그대로 믿지 않는다
    var clean := {
        "name": String(info.get("name", "Player")).left(20),
    }
    players[id] = clean
    player_connected.emit(id, clean)
```

### 다른 Peer 종류

| 클래스 | 프로토콜 | 용도 |
|--------|---------|------|
| `ENetMultiplayerPeer` | UDP (ENet) | **기본. 대부분의 게임** |
| `WebSocketMultiplayerPeer` | WebSocket | 웹 빌드 |
| `WebRTCMultiplayerPeer` | WebRTC | P2P, 웹 |
| `OfflineMultiplayerPeer` | 없음 | 싱글플레이에서도 같은 코드 사용 |

### 압축 설정

```gdscript
var peer := ENetMultiplayerPeer.new()
peer.create_server(port, MAX_PLAYERS)
peer.host.compress(ENetConnection.COMPRESS_RANGE_CODER)
# COMPRESS_NONE / COMPRESS_RANGE_CODER / COMPRESS_FASTLZ / COMPRESS_ZLIB / COMPRESS_ZSTD
```

**서버와 클라이언트가 같은 압축 방식을 써야 한다.**

---

## 3. @rpc 어노테이션 전체

```gdscript
@rpc(mode, sync, transfer_mode, channel)
func my_function() -> void:
    pass
```

| 인자 | 값 | 기본값 | 의미 |
|------|-----|--------|------|
| mode | `"authority"` / `"any_peer"` | `"authority"` | 누가 이 RPC를 호출할 수 있는가 |
| sync | `"call_remote"` / `"call_local"` | `"call_remote"` | 호출자 자신에게서도 실행할까 |
| transfer | `"reliable"` / `"unreliable"` / `"unreliable_ordered"` | `"unreliable"` | 전송 보장 |
| channel | `int` | `0` | 채널 번호 (채널 간 순서 독립) |

인자 순서는 자유롭고 일부만 써도 된다.

### mode의 의미 — 가장 중요

```gdscript
# "authority" — 노드의 권한자만 호출 가능
# 서버가 클라이언트에게 명령을 내릴 때
@rpc("authority", "call_local", "reliable")
func apply_damage(amount: int) -> void:
    health -= amount

# "any_peer" — 아무나 호출 가능
# 클라이언트가 서버에게 요청할 때 (반드시 서버에서 검증!)
@rpc("any_peer", "call_remote", "reliable")
func request_fire(target: Vector3) -> void:
    if not multiplayer.is_server():
        return
    var sender := multiplayer.get_remote_sender_id()
    _validate_and_fire(sender, target)
```

**`"any_peer"`를 쓸 때는 반드시 서버에서 검증한다.** 이 어노테이션은
"누구나 이 함수를 원격 실행할 수 있다"는 뜻이므로, 악의적 클라이언트가
임의의 인자로 호출할 수 있다.

### transfer_mode 선택

| 모드 | 특성 | 용도 |
|------|------|------|
| `reliable` | 도착 보장 + 순서 보장. 느림 | 데미지, 아이템 획득, 채팅, 상태 변경 |
| `unreliable` | 유실 가능, 순서 무관. 빠름 | 위치 동기화 (다음 패킷이 곧 옴) |
| `unreliable_ordered` | 유실 가능, 오래된 것 무시 | 회전, 애니메이션 상태 |

**위치 업데이트를 `reliable`로 보내면 안 된다.** 패킷 유실 시 재전송을 기다리며
후속 패킷이 밀려 렉이 발생한다. 어차피 다음 프레임에 새 위치가 오므로 `unreliable`이 맞다.

### 호출 방법

```gdscript
# 모든 피어에게 (자신 포함 여부는 call_local에 따름)
my_function.rpc(arg1, arg2)

# 특정 피어에게만
my_function.rpc_id(target_peer_id, arg1)

# 서버에게만
my_function.rpc_id(1, arg1)

# 구식 문법 (4.x에서도 동작하나 비권장)
rpc("my_function", arg1)
rpc_id(1, "my_function", arg1)
```

### 채널 분리

```gdscript
@rpc("authority", "unreliable", 1)
func sync_position(pos: Vector3) -> void: pass

@rpc("authority", "reliable", 2)
func sync_inventory(items: Array) -> void: pass
```

채널이 다르면 서로의 순서에 영향을 주지 않는다.
큰 `reliable` 패킷이 작은 위치 패킷을 막는 것(head-of-line blocking)을 방지한다.

---

## 4. 멀티플레이어 권한(Authority)

각 노드는 하나의 권한자 피어를 가진다. 기본값은 서버(1)다.

```gdscript
# 권한 설정 — 서버에서 호출하고 모든 피어에 전파되어야 한다
player_node.set_multiplayer_authority(peer_id)

# 자식에게도 전파 (기본 true)
player_node.set_multiplayer_authority(peer_id, true)

# 조회
var authority := node.get_multiplayer_authority()
if node.is_multiplayer_authority():
    # 내가 이 노드를 제어한다
    pass
```

### 전형적인 패턴

```gdscript
class_name NetworkPlayer
extends CharacterBody3D

@export var peer_id: int = 1:
    set(value):
        peer_id = value
        # 권한 설정은 모든 피어에서 동일하게 실행되어야 한다
        set_multiplayer_authority(value)

@onready var camera: Camera3D = %Camera3D
@onready var synchronizer: MultiplayerSynchronizer = $MultiplayerSynchronizer

func _ready() -> void:
    var is_mine := is_multiplayer_authority()
    # 내 캐릭터만 카메라와 입력을 활성화한다
    camera.current = is_mine
    set_physics_process(is_mine)
    set_process_input(is_mine)

func _physics_process(delta: float) -> void:
    # 여기는 내 캐릭터에서만 실행된다
    _handle_input(delta)
    move_and_slide()
```

**`@export var peer_id`의 setter에서 권한을 설정하는 이유**:
`MultiplayerSpawner`가 스폰 시 이 프로퍼티를 전달하면
모든 피어에서 setter가 실행되어 권한이 일관되게 설정된다.

---

## 5. MultiplayerSpawner

서버에서 노드를 추가하면 모든 클라이언트에도 자동으로 생성된다.

### 설정

```
Level (Node3D)
├─ MultiplayerSpawner
│    spawn_path = "../Players"        ← 이 경로 아래의 노드를 감시
│    Auto Spawn List: player.tscn     ← 스폰 가능한 씬 등록
└─ Players (Node3D)                   ← 여기에 추가된 노드가 복제된다
```

### 자동 스폰

```gdscript
# 서버에서만 실행
func spawn_player(peer_id: int) -> void:
    if not multiplayer.is_server():
        return
    var player: NetworkPlayer = PLAYER_SCENE.instantiate()
    player.name = str(peer_id)              # 이름이 모든 피어에서 같아야 한다
    player.peer_id = peer_id
    $Players.add_child(player, true)        # true = 이름 충돌 방지
    # MultiplayerSpawner가 자동으로 클라이언트에 복제한다
```

**`add_child(node, true)`의 두 번째 인자**: 이름이 겹치면 `@`가 붙는데,
그러면 피어마다 이름이 달라져 동기화가 깨진다. `true`로 두면 유효한 이름을 보장한다.
**더 확실한 방법은 위처럼 명시적으로 고유한 이름을 지정하는 것이다.**

### 커스텀 스폰 함수 (초기 데이터 전달)

```gdscript
@onready var spawner: MultiplayerSpawner = $MultiplayerSpawner

func _ready() -> void:
    spawner.spawn_function = _spawn_enemy

# 서버에서 호출
func request_spawn_enemy(type: String, pos: Vector3) -> void:
    if not multiplayer.is_server():
        return
    spawner.spawn({"type": type, "position": pos})

# 모든 피어에서 실행된다 (서버가 넘긴 data로)
func _spawn_enemy(data: Variant) -> Node:
    var scene: PackedScene = ENEMY_SCENES[data.type]
    var enemy: Node3D = scene.instantiate()
    enemy.position = data.position
    return enemy
```

`spawn_function`이 반환한 노드가 `spawn_path` 아래에 추가된다.
`data`는 직렬화 가능한 타입만 가능하다 (노드나 리소스 참조는 불가).

### 제한

```gdscript
spawner.spawn_limit = 32          # 동시 스폰 제한 (0 = 무제한)
```

---

## 6. MultiplayerSynchronizer

노드의 프로퍼티를 자동으로 동기화한다.

### 설정

```
NetworkPlayer (CharacterBody3D)
└─ MultiplayerSynchronizer
     root_path = ".."
     replication_interval = 0.05        ← 초당 20회
     delta_interval = 0.0
     public_visibility = true
```

인스펙터 하단의 **Replication** 탭에서 동기화할 프로퍼티를 추가한다.

| 프로퍼티 | Spawn | Sync | Watch |
|---------|-------|------|-------|
| `position` | ✓ | ✓ | |
| `rotation:y` | ✓ | ✓ | |
| `velocity` | | ✓ | |
| `health` | ✓ | | ✓ |
| `peer_id` | ✓ | | |

| 열 | 의미 |
|----|------|
| **Spawn** | 노드 생성 시 한 번 전송 (초기값) |
| **Sync** | `replication_interval`마다 주기적 전송 |
| **Watch** | 값이 변할 때만 전송 (`delta_interval` 주기로 검사) |

**설계 지침**

- `position`, `rotation` → Sync (계속 변함)
- `health`, `state`, `weapon_id` → Watch (가끔 변함, 대역폭 절약)
- `peer_id`, `player_name`, `team` → Spawn only (안 변함)

### 코드에서 설정

```gdscript
func _ready() -> void:
    var config := SceneReplicationConfig.new()

    config.add_property(^".:position")
    config.property_set_spawn(^".:position", true)
    config.property_set_replication_mode(
        ^".:position", SceneReplicationConfig.REPLICATION_MODE_ALWAYS)

    config.add_property(^".:health")
    config.property_set_replication_mode(
        ^".:health", SceneReplicationConfig.REPLICATION_MODE_ON_CHANGE)

    $MultiplayerSynchronizer.replication_config = config
```

| 모드 | 의미 |
|------|------|
| `REPLICATION_MODE_NEVER` | 동기화 안 함 (Spawn만) |
| `REPLICATION_MODE_ALWAYS` | 매 주기 전송 |
| `REPLICATION_MODE_ON_CHANGE` | 변할 때만 |

### 가시성 필터 (관심 영역)

멀리 있는 플레이어의 정보를 보내지 않아 대역폭을 절약한다.

```gdscript
func _ready() -> void:
    var sync: MultiplayerSynchronizer = $MultiplayerSynchronizer
    sync.public_visibility = false
    sync.add_visibility_filter(_is_visible_to)

func _is_visible_to(peer_id: int) -> bool:
    var observer := NetworkManager.get_player_node(peer_id)
    if not is_instance_valid(observer):
        return false
    return global_position.distance_squared_to(observer.global_position) < 2500.0  # 50m

# 수동 제어
sync.set_visibility_for(peer_id, true)
sync.update_visibility()      # 필터 재평가
```

### 입력 동기화 (역방향)

`MultiplayerSynchronizer`의 권한을 클라이언트로 두면 클라이언트 → 서버 방향으로
동기화된다. 입력 전달에 쓴다.

```
NetworkPlayer
├─ MultiplayerSynchronizer          (서버 권위 — 위치를 클라이언트로)
└─ InputSynchronizer                (클라이언트 권위 — 입력을 서버로)
     set_multiplayer_authority(peer_id)
     Replication: input_direction, jump_pressed
```

```gdscript
# res://scripts/input_synchronizer.gd
class_name InputSynchronizer
extends MultiplayerSynchronizer

@export var input_direction: Vector2 = Vector2.ZERO
@export var look_rotation: float = 0.0
@export var jump_pressed: bool = false

func _ready() -> void:
    # 이 노드의 권한자(= 조종하는 클라이언트)에서만 입력을 읽는다
    if not is_multiplayer_authority():
        set_process(false)
        return

func _process(_delta: float) -> void:
    input_direction = Input.get_vector(
        "move_left", "move_right", "move_forward", "move_back")
    jump_pressed = Input.is_action_pressed("jump")
```

---

## 7. 서버 권위 모델 (완성 코드)

```gdscript
class_name NetworkPlayer
extends CharacterBody3D

const SPEED: float = 5.5
const JUMP_VELOCITY: float = 5.0

@export var peer_id: int = 1:
    set(value):
        peer_id = value
        set_multiplayer_authority(1)              # 몸체는 항상 서버 권위
        $InputSynchronizer.set_multiplayer_authority(value)

@export var max_health: int = 100
@export var health: int = 100:
    set(value):
        health = value
        health_changed.emit(health, max_health)
        if health <= 0 and multiplayer.is_server():
            _die()

signal health_changed(current: int, maximum: int)

@onready var input_sync: InputSynchronizer = $InputSynchronizer
@onready var camera: Camera3D = %Camera3D
@onready var _gravity: float = ProjectSettings.get_setting(
    "physics/3d/default_gravity", 9.8)

func _ready() -> void:
    var is_mine := input_sync.is_multiplayer_authority()
    camera.current = is_mine
    # 물리는 서버에서만 계산한다 (서버 권위)
    set_physics_process(multiplayer.is_server())

func _physics_process(delta: float) -> void:
    # 서버에서만 실행된다
    if not is_on_floor():
        velocity.y -= _gravity * delta
    elif input_sync.jump_pressed:
        velocity.y = JUMP_VELOCITY

    var dir := Vector3(input_sync.input_direction.x, 0.0,
                       input_sync.input_direction.y)
    rotation.y = input_sync.look_rotation
    dir = (transform.basis * dir).normalized()

    velocity.x = dir.x * SPEED
    velocity.z = dir.z * SPEED
    move_and_slide()
    # position/velocity는 MultiplayerSynchronizer가 클라이언트로 전파한다

# ── 데미지 (서버 권위) ───────────────────────────────
func take_damage(amount: int, from_peer: int = 1) -> void:
    if not multiplayer.is_server():
        return                                    # 서버만 체력을 바꾼다
    health = maxi(0, health - amount)
    _on_damaged.rpc(amount, from_peer)            # 연출은 전원에게

@rpc("authority", "call_local", "reliable")
func _on_damaged(amount: int, from_peer: int) -> void:
    # 모든 피어에서 실행 — 이펙트와 사운드
    _play_hit_effect()
    if is_multiplayer_authority() or input_sync.is_multiplayer_authority():
        _shake_camera(amount)

func _die() -> void:
    if not multiplayer.is_server():
        return
    _on_died.rpc()
    await get_tree().create_timer(3.0).timeout
    if is_instance_valid(self):
        health = max_health
        global_position = GameServer.get_spawn_point()

@rpc("authority", "call_local", "reliable")
func _on_died() -> void:
    $Model.visible = false
    _spawn_death_effect()
    await get_tree().create_timer(3.0).timeout
    if is_instance_valid(self):
        $Model.visible = true

# ── 발사 요청 (클라이언트 → 서버) ────────────────────
func try_fire() -> void:
    # 클라이언트에서 호출 → 서버에 요청
    _request_fire.rpc_id(1, camera.global_position, -camera.global_basis.z)

@rpc("any_peer", "call_remote", "reliable")
func _request_fire(origin: Vector3, direction: Vector3) -> void:
    if not multiplayer.is_server():
        return
    var sender := multiplayer.get_remote_sender_id()

    # 검증 1 — 요청자가 이 캐릭터의 조종자인가
    if sender != peer_id:
        push_warning("피어 %d가 남의 캐릭터로 발사 시도" % sender)
        return

    # 검증 2 — 발사 위치가 실제 캐릭터 근처인가 (텔레포트 핵 방지)
    if origin.distance_squared_to(global_position) > 9.0:
        push_warning("피어 %d의 비정상 발사 위치" % sender)
        return

    # 검증 3 — 연사 속도 제한
    var now := Time.get_ticks_msec()
    if now - _last_fire_ms < 200:
        return
    _last_fire_ms = now

    _do_fire(origin, direction.normalized())

var _last_fire_ms: int = 0

func _do_fire(origin: Vector3, direction: Vector3) -> void:
    var space := get_world_3d().direct_space_state
    var query := PhysicsRayQueryParameters3D.create(
        origin, origin + direction * 100.0, 0xFFFFFFFF, [get_rid()])
    var hit := space.intersect_ray(query)

    if not hit.is_empty():
        var target := hit.collider
        if target is NetworkPlayer:
            (target as NetworkPlayer).take_damage(25, peer_id)
        _show_impact.rpc(hit.position, hit.normal)
    else:
        _show_impact.rpc(origin + direction * 100.0, -direction)

@rpc("authority", "call_local", "unreliable")
func _show_impact(pos: Vector3, normal: Vector3) -> void:
    # 연출만 — 유실돼도 게임에 영향 없으므로 unreliable
    ImpactEffects.spawn(pos, normal)
```

### 설계 요약

| 요소 | 권위 | 전송 |
|------|------|------|
| 입력 (`input_direction`, `jump`) | 클라이언트 | Synchronizer (클→서) |
| 위치·속도 | 서버 | Synchronizer (서→클) |
| 체력 | 서버 | Synchronizer Watch |
| 발사 요청 | 클라이언트가 요청, 서버가 판정 | RPC `any_peer` + 검증 |
| 피격 연출 | 서버가 지시 | RPC `authority` `unreliable` |

---

## 8. 클라이언트 예측과 보간

순수 서버 권위는 왕복 지연(RTT)만큼 입력 반응이 늦다.
100ms 핑이면 키를 누르고 0.1초 뒤에 움직인다 — 액션 게임에서 용납되지 않는다.

### 클라이언트 예측 (Client-Side Prediction)

클라이언트가 입력을 서버에 보내는 **동시에** 자기 화면에서 즉시 적용한다.
서버 응답이 오면 어긋난 만큼만 보정한다.

```gdscript
class_name PredictedMovement
extends Node

const MAX_BUFFER: int = 128

var _input_buffer: Array[Dictionary] = []
var _sequence: int = 0

@export var body: CharacterBody3D

func _physics_process(delta: float) -> void:
    if not is_multiplayer_authority():
        return

    _sequence += 1
    var input := {
        "seq": _sequence,
        "dir": Input.get_vector("move_left", "move_right",
                                "move_forward", "move_back"),
        "jump": Input.is_action_just_pressed("jump"),
        "delta": delta,
    }

    # 1. 즉시 로컬에 적용 (예측)
    _apply_input(input)

    # 2. 버퍼에 저장 (재적용용)
    _input_buffer.append(input)
    if _input_buffer.size() > MAX_BUFFER:
        _input_buffer.pop_front()

    # 3. 서버에 전송
    _send_input.rpc_id(1, input)

func _apply_input(input: Dictionary) -> void:
    var dir: Vector2 = input.dir
    var d: float = input.delta
    body.velocity.x = dir.x * SPEED
    body.velocity.z = dir.y * SPEED
    if input.jump and body.is_on_floor():
        body.velocity.y = JUMP_VELOCITY
    if not body.is_on_floor():
        body.velocity.y -= GRAVITY * d
    body.move_and_slide()

@rpc("any_peer", "unreliable_ordered")
func _send_input(input: Dictionary) -> void:
    if not multiplayer.is_server():
        return
    _apply_input(input)
    # 서버의 결과를 클라이언트에 회신
    _reconcile.rpc_id(multiplayer.get_remote_sender_id(),
                      input.seq, body.global_position, body.velocity)

@rpc("authority", "unreliable_ordered")
func _reconcile(seq: int, server_pos: Vector3, server_vel: Vector3) -> void:
    # 서버가 확인한 시퀀스 이전 입력은 버린다
    while not _input_buffer.is_empty() and _input_buffer[0].seq <= seq:
        _input_buffer.pop_front()

    # 오차가 작으면 무시 (미세 보정은 오히려 떨림을 만든다)
    if body.global_position.distance_to(server_pos) < 0.1:
        return

    # 서버 상태로 되돌리고
    body.global_position = server_pos
    body.velocity = server_vel
    # 아직 확인되지 않은 입력들을 다시 적용한다
    for input in _input_buffer:
        _apply_input(input)
```

### 원격 플레이어 보간 (Entity Interpolation)

다른 플레이어는 예측할 수 없다. 대신 **과거 상태 두 개 사이를 보간**해
부드럽게 표시한다.

```gdscript
class_name RemoteInterpolator
extends Node

const INTERP_DELAY_MS: int = 100      # 100ms 과거를 그린다

@export var body: Node3D

var _states: Array[Dictionary] = []

func push_state(pos: Vector3, rot: float) -> void:
    _states.append({
        "time": Time.get_ticks_msec(),
        "pos": pos,
        "rot": rot,
    })
    while _states.size() > 32:
        _states.pop_front()

func _process(_delta: float) -> void:
    if _states.size() < 2:
        return
    var render_time := Time.get_ticks_msec() - INTERP_DELAY_MS

    # render_time을 감싸는 두 상태를 찾는다
    for i in range(_states.size() - 1):
        var a: Dictionary = _states[i]
        var b: Dictionary = _states[i + 1]
        if a.time <= render_time and render_time <= b.time:
            var span := float(b.time - a.time)
            var t := 0.0 if span <= 0.0 else (render_time - a.time) / span
            body.global_position = (a.pos as Vector3).lerp(b.pos, t)
            body.rotation.y = lerp_angle(a.rot, b.rot, t)
            return

    # 보간할 구간이 없으면 최신 상태로 (외삽 대신 스냅)
    var last: Dictionary = _states[-1]
    body.global_position = last.pos
    body.rotation.y = last.rot
```

**100ms 지연을 의도적으로 두는 이유**: 항상 두 개의 확정된 상태 사이를
보간하려면 최신 데이터보다 과거를 그려야 한다. 이 지연은 시각적으로만
존재하며, 자기 캐릭터에는 적용되지 않는다.

---

## 9. 입력 검증과 보안

**절대 규칙: 클라이언트가 보낸 모든 데이터는 거짓일 수 있다.**

```gdscript
@rpc("any_peer", "reliable")
func request_buy_item(item_id: StringName, quantity: int) -> void:
    if not multiplayer.is_server():
        return
    var sender := multiplayer.get_remote_sender_id()

    # 1. 타입·범위 검증
    if quantity <= 0 or quantity > 99:
        return
    var item := ItemDB.get_item(item_id)
    if item == null:
        return

    # 2. 소유권 검증 — 남의 계정으로 조작하는가
    var player := GameServer.get_player(sender)
    if player == null:
        return

    # 3. 상태 검증 — 실제로 가능한 행동인가
    if not player.is_near_shop():
        push_warning("피어 %d: 상점과 멀리서 구매 시도" % sender)
        return

    # 4. 자원 검증
    var cost := item.buy_price * quantity
    if player.gold < cost:
        return

    # 5. 실행
    player.gold -= cost
    player.add_item(item, quantity)
    _confirm_purchase.rpc_id(sender, item_id, quantity, player.gold)

@rpc("authority", "reliable")
func _confirm_purchase(item_id: StringName, qty: int, new_gold: int) -> void:
    UI.show_purchase_result(item_id, qty)
    UI.update_gold(new_gold)
```

### 체크리스트

| 항목 | 확인 |
|------|------|
| 인자 타입과 범위 | `quantity > 0`, 문자열 길이 제한 |
| 존재 여부 | 아이템 ID가 실제로 있는가 |
| 소유권 | `sender`가 이 캐릭터/계정의 주인인가 |
| 위치·거리 | 물리적으로 가능한 행동인가 |
| 쿨다운 | 연사 속도, 스킬 쿨타임 |
| 자원 | 골드, 마나, 탄약이 충분한가 |
| 상태 | 죽었는데 공격하는가, 스턴 중인가 |

### 레이트 리미팅

```gdscript
var _rpc_counts: Dictionary[int, Array] = {}

func _check_rate_limit(peer: int, max_per_sec: int = 30) -> bool:
    var now := Time.get_ticks_msec()
    if not _rpc_counts.has(peer):
        _rpc_counts[peer] = []
    var times: Array = _rpc_counts[peer]
    # 1초 이전 기록 제거
    while not times.is_empty() and now - times[0] > 1000:
        times.pop_front()
    if times.size() >= max_per_sec:
        push_warning("피어 %d 레이트 제한 초과" % peer)
        return false
    times.append(now)
    return true
```

### 그 외 보안 고려사항

- **`FileAccess.get_var(true)`를 네트워크 데이터에 쓰지 않는다** — 임의 객체
  역직렬화는 코드 실행 취약점이다.
- **RPC로 `Callable`, `Object`를 전달하지 않는다** — 기본 타입, `Dictionary`,
  `Array`만 쓴다.
- **`multiplayer.allow_object_decoding`은 기본 `false`로 둔다.**

---

## 10. 연결 끊김 처리

```gdscript
func _on_peer_disconnected(id: int) -> void:
    if multiplayer.is_server():
        var player := get_node_or_null("Players/%d" % id)
        if player:
            player.queue_free()       # MultiplayerSpawner가 클라이언트에도 전파
        players.erase(id)
        _notify_player_left.rpc(id)

@rpc("authority", "reliable")
func _notify_player_left(id: int) -> void:
    UI.show_message("플레이어 %d 퇴장" % id)

func _on_server_disconnected() -> void:
    # 클라이언트에서 서버가 끊어졌을 때
    multiplayer.multiplayer_peer = null
    get_tree().change_scene_to_file("res://scenes/ui/main_menu.tscn")
    UI.show_error("서버와의 연결이 끊어졌습니다")
```

### 타임아웃 설정

```gdscript
var peer := ENetMultiplayerPeer.new()
peer.create_client(address, port)
# ENetConnection 레벨에서 타임아웃 조정
multiplayer.multiplayer_peer = peer

# 연결 시도 타임아웃 직접 구현
func join_with_timeout(address: String, port: int, timeout: float = 5.0) -> bool:
    var err := join_game(address, port)
    if err != OK:
        return false
    var t := 0.0
    while multiplayer.multiplayer_peer.get_connection_status() \
            == MultiplayerPeer.CONNECTION_CONNECTING:
        await get_tree().process_frame
        t += get_process_delta_time()
        if t > timeout:
            leave_game()
            return false
    return multiplayer.multiplayer_peer.get_connection_status() \
        == MultiplayerPeer.CONNECTION_CONNECTED
```

---

## 11. 로컬 테스트

### 에디터 다중 인스턴스

`Debug → Customize Run Instances...`에서 실행 인스턴스 수를 설정하고
각 인스턴스에 커스텀 인자를 전달한다.

```
Instance 1: --server
Instance 2: --client
Instance 3: --client
```

```gdscript
func _ready() -> void:
    var args := OS.get_cmdline_args()
    if "--server" in args:
        NetworkManager.host_game()
    elif "--client" in args:
        NetworkManager.join_game("127.0.0.1")
```

4.7에서 임베드 게임 창의 이동·크기 조정이 가능해져 여러 인스턴스를
동시에 보기 편해졌다.

### 네트워크 조건 시뮬레이션

`Debug → Network Profiler`에서 대역폭을 확인하고,
`Debug` 메뉴의 네트워크 시뮬레이션 옵션으로 지연·패킷 유실을 재현한다.

```gdscript
# 코드로 지연 시뮬레이션 (테스트용)
if OS.is_debug_build() and simulate_lag:
    await get_tree().create_timer(0.1).timeout
    _actual_send()
```

### 헤드리스 서버

```bash
godot --headless --path /path/to/project -- --server --port 7777
```

전용 서버는 렌더링이 필요 없으므로 `--headless`로 실행한다.

---

## 12. 자주 하는 실수

| 실수 | 증상 | 해결 |
|------|------|------|
| 위치 동기화를 `reliable`로 | 렉, 대역폭 낭비 | `unreliable` |
| `any_peer` RPC에 검증 없음 | 치팅 가능 | 서버에서 sender·상태 검증 |
| 노드 이름이 피어마다 다름 | 동기화 실패 | 명시적 고유 이름 지정 |
| 클라이언트에서 물리 계산 | 위치 불일치 | 서버 권위로 통일 |
| 모든 클라이언트에서 `_physics_process` | 중복 계산 | 권한자만 활성화 |
| `set_multiplayer_authority`가 한쪽에만 | RPC 거부됨 | 모든 피어에서 동일하게 설정 |
| 예측 없이 서버 권위만 | 입력 지연 체감 | 클라이언트 예측 추가 |
| 원격 플레이어 위치를 즉시 스냅 | 뚝뚝 끊김 | 보간 |
| 미세 오차까지 보정 | 떨림 | 임계값 이하는 무시 |
| `MultiplayerSpawner` 없이 `add_child` | 클라이언트에 안 생김 | Spawner 사용 또는 RPC |
| Synchronizer로 모든 프로퍼티 동기화 | 대역폭 폭증 | Watch 모드, 가시성 필터 |
| RPC로 `Object` 전달 | 보안 위험, 실패 | 기본 타입만 |
| 서버/클라이언트 압축 설정 불일치 | 연결 실패 | 동일하게 설정 |
| 연결 끊김 미처리 | 유령 플레이어 | `peer_disconnected` 처리 |
