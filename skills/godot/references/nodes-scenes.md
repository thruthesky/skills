# 노드·씬·SceneTree 아키텍처

## 목차

1. [핵심 개념 — 세 가지를 구분하라](#1-핵심-개념--세-가지를-구분하라)
2. [노드 계층과 상속 트리](#2-노드-계층과-상속-트리)
3. [노드 참조 방법](#3-노드-참조-방법)
4. [씬 인스턴싱](#4-씬-인스턴싱)
5. [씬 전환과 로딩](#5-씬-전환과-로딩)
6. [오토로드(싱글턴)](#6-오토로드싱글턴)
7. [그룹](#7-그룹)
8. [노드 생성·제거·유효성](#8-노드-생성제거유효성)
9. [SceneTree API](#9-scenetree-api)
10. [시그널 기반 느슨한 결합](#10-시그널-기반-느슨한-결합)
11. [이 프로젝트의 역할 분리 지침](#11-이-프로젝트의-역할-분리-지침)
12. [씬 설계 원칙](#12-씬-설계-원칙)

---

## 1. 핵심 개념 — 세 가지를 구분하라

Godot 초보자가 가장 많이 혼동하는 지점이다. 세 가지는 완전히 다른 것이다.

| 용어 | 정체 | 존재 위치 |
|------|------|----------|
| **씬 파일** (`.tscn`) | 노드 구성을 기록한 **텍스트 파일** | 디스크 |
| **씬 인스턴스** | 씬 파일로부터 메모리에 만들어진 **노드 객체 묶음** | 메모리 |
| **SceneTree** | 실행 중인 게임의 **활성 노드 트리 전체** | 실행 중인 프로세스 |

```gdscript
const ENEMY_SCENE: PackedScene = preload("res://scenes/enemy.tscn")  # 씬 파일 → PackedScene 리소스

var enemy: Enemy = ENEMY_SCENE.instantiate()   # 씬 인스턴스 생성 (아직 SceneTree에 없음)
enemy.global_position = spawn_point            # 이 시점엔 _ready() 미호출
add_child(enemy)                               # SceneTree에 진입 → _enter_tree, _ready 호출
```

**중요**: `instantiate()` 직후에는 노드가 트리 밖에 있다. 이 시점에서
`get_tree()`는 `null`을 반환하고 `@onready` 변수는 아직 초기화되지 않았다.
전역 좌표를 설정하려면 `add_child()` 이후에 해야 한다.

```gdscript
# 잘못됨 — 트리 밖에서 global_position 설정은 무시되거나 부모 좌표계 반영이 안 됨
var e := ENEMY_SCENE.instantiate()
e.global_position = Vector3(10, 0, 5)
add_child(e)

# 올바름
var e := ENEMY_SCENE.instantiate()
add_child(e)
e.global_position = Vector3(10, 0, 5)
```

---

## 2. 노드 계층과 상속 트리

3D 개발에서 알아야 할 상속 관계.

```
Object
 └─ RefCounted                     참조 카운트 자동 관리. 순수 로직 클래스
     └─ Resource                   디스크 저장 가능. 데이터 정의
         ├─ PackedScene            .tscn을 담는 리소스
         ├─ Material               StandardMaterial3D, ShaderMaterial
         ├─ Mesh                   BoxMesh, ArrayMesh, ...
         ├─ Texture2D
         ├─ Animation
         └─ Shape3D                BoxShape3D, CapsuleShape3D, ...
 └─ Node                           SceneTree에 들어갈 수 있는 최소 단위
     ├─ CanvasItem
     │   ├─ Node2D                 2D 공간
     │   └─ Control                UI
     ├─ Node3D                     3D 공간 (transform 보유)
     │   ├─ VisualInstance3D
     │   │   ├─ GeometryInstance3D
     │   │   │   ├─ MeshInstance3D
     │   │   │   └─ MultiMeshInstance3D
     │   │   ├─ Light3D            DirectionalLight3D, OmniLight3D, SpotLight3D, AreaLight3D
     │   │   ├─ Camera3D
     │   │   └─ Decal, GPUParticles3D, ...
     │   ├─ CollisionObject3D
     │   │   ├─ PhysicsBody3D
     │   │   │   ├─ StaticBody3D
     │   │   │   ├─ RigidBody3D
     │   │   │   └─ CharacterBody3D
     │   │   └─ Area3D
     │   ├─ CollisionShape3D
     │   ├─ RayCast3D, ShapeCast3D
     │   ├─ NavigationRegion3D, NavigationAgent3D(Node), NavigationLink3D
     │   ├─ Skeleton3D, BoneAttachment3D
     │   ├─ AudioStreamPlayer3D
     │   ├─ SpringArm3D
     │   └─ Marker3D               위치만 표시하는 빈 노드
     ├─ AnimationMixer
     │   ├─ AnimationPlayer
     │   └─ AnimationTree
     ├─ Timer
     ├─ Viewport → SubViewport / Window
     └─ MultiplayerSpawner, MultiplayerSynchronizer
```

`Node3D`를 상속하면 `transform`, `position`, `rotation`, `scale`, `visible`을 얻는다.
공간 개념이 필요 없는 매니저는 `Node`를 상속해 불필요한 변환 계산을 피한다.

---

## 3. 노드 참조 방법

### 방법 비교

| 방법 | 장점 | 단점 | 사용 시점 |
|------|------|------|----------|
| `$Path` | 짧다 | 이름/구조 변경에 취약 | 같은 씬 안, 안정적인 자식 |
| `%UniqueName` | 구조 변경에 강함 | 씬에서 고유 이름 지정 필요 | **권장 기본값** |
| `@export var NodePath` | 씬에서 시각적으로 연결 | 인스펙터 작업 필요 | 씬 간 참조 |
| `@export var Node3D` | 타입 안전 + 시각적 연결 | 같은 씬 내 노드만 | 씬 내부 참조 |
| `get_node_or_null()` | 없어도 안전 | 매번 문자열 탐색 | 존재가 불확실할 때 |
| 그룹 | 다대다 | 순서 보장 없음 | 여러 대상 일괄 처리 |
| 시그널 | 결합 없음 | 흐름 추적이 어려움 | **자식 → 부모 통지** |

### 코드

```gdscript
extends CharacterBody3D

# $ 문법 — get_node("...")의 축약
@onready var mesh: MeshInstance3D = $MeshInstance3D
@onready var shape: CollisionShape3D = $CollisionShape3D
@onready var muzzle: Marker3D = $Model/RightHand/Muzzle    # 중첩 경로

# % 고유 이름 — 씬 트리에서 노드 우클릭 → "Access as Unique Name" 체크
# 노드를 다른 부모로 옮겨도 경로가 깨지지 않는다
@onready var camera: Camera3D = %Camera3D
@onready var anim_tree: AnimationTree = %AnimationTree

# @export NodePath — 다른 씬의 노드를 인스펙터에서 연결
@export var target_path: NodePath
@onready var target: Node3D = get_node_or_null(target_path)

# @export Node — 4.x부터 노드 자체를 직접 export 가능 (타입 안전, 권장)
@export var spawn_marker: Marker3D
@export var hud: Control

func _ready() -> void:
    # 부모 탐색
    var parent := get_parent()
    var root := get_tree().current_scene

    # 안전한 탐색 — 없으면 null
    var optional := get_node_or_null("OptionalChild")
    if optional:
        optional.queue_free()

    # 상대 경로
    var sibling := get_node("../Sibling")
```

**`$`와 `%`의 차이**: `$Path`는 트리 경로를 그대로 따라간다. `%Name`은 씬 소유자
(`owner`)를 기준으로 고유 이름 등록부를 조회한다. 리팩터링 내성이 필요하면 `%`를 쓴다.

---

## 4. 씬 인스턴싱

**미리 만들어 둔 씬을 불러와 새 노드 묶음을 만들어 내는 것**이다. 개념과 "설계도 → 실체"
흐름은 [basics.md](basics.md) §3 에 있고, 여기서는 실전 패턴을 다룬다.

**반대 방향** — 이미 현재 씬 안에 만들어 놓은 노드 묶음을 재사용 가능한 씬으로 떼어내는
`Save Branch as Scene...` 은 [basics.md](basics.md) §3 에 있다(브랜치의 정의, `.tscn` 이
어떻게 바뀌는지, `Reset Position` 기본값, 거부당하는 5가지 경우).

### 에디터에서 인스턴싱하기

씬 독에서 부모 노드를 선택한 뒤,

- **체인 모양 버튼**(`Instantiate Child Scene`), 또는
- **Cmd+Shift+A** (Windows·Linux `Ctrl+Shift+A`), 또는
- **FileSystem 독에서 `.tscn` 을 뷰포트·씬 독으로 드래그**

인스턴스는 씬 독에서 **영화 슬레이트 아이콘**으로 표시되고 자식이 접힌 채로 들어온다.
**원본 씬을 고치면 모든 인스턴스에 반영된다** — 이것이 인스턴싱을 쓰는 이유다.

| 인스턴스에서 할 수 있는 것 | 방법 |
|---|---|
| 이 인스턴스만 프로퍼티 바꾸기 | 인스펙터에서 값 수정 → **되돌리기 화살표**가 붙어 원본과 다름을 표시 |
| 이 인스턴스에만 자식 추가 | 그냥 추가하면 된다 |
| 원본 구조를 여기서만 뜯어고치기 | 우클릭 → **Editable Children** (되도록 쓰지 않는다 — 원본 변경 추적이 어려워진다) |
| 인스턴스를 원본과 끊기 | 우클릭 → **Make Local** — 인스턴스 관계가 사라지고 평범한 노드 묶음이 된다 |

**정적으로 배치할 것은 에디터에서, 실행 중 생겨나는 것은 코드에서** 인스턴싱한다.
맵에 미리 놓는 나무·상자는 에디터, 총알·적·이펙트는 코드다.

### 기본 패턴

```gdscript
class_name EnemySpawner
extends Node3D

const ENEMY_SCENE: PackedScene = preload("res://scenes/enemies/slime.tscn")

@export var spawn_count: int = 5
@export var spawn_radius: float = 10.0

func spawn_wave() -> void:
    for i in spawn_count:
        var enemy: Enemy = ENEMY_SCENE.instantiate()
        # 부모에 붙인 뒤 위치를 잡는다
        get_tree().current_scene.add_child(enemy)
        var angle := TAU * i / spawn_count
        enemy.global_position = global_position + Vector3(
            cos(angle) * spawn_radius, 0.0, sin(angle) * spawn_radius
        )
        enemy.died.connect(_on_enemy_died)

func _on_enemy_died() -> void:
    pass
```

### 인스턴스에 초기 데이터를 넘기는 두 가지 방법

```gdscript
# 방법 1: add_child 전에 일반 변수 설정 (권장 — _ready에서 사용 가능)
var bullet: Bullet = BULLET_SCENE.instantiate()
bullet.damage = weapon.damage
bullet.direction = aim_direction
add_child(bullet)

# 방법 2: setup 메서드 (전역 좌표가 필요한 경우)
var bullet: Bullet = BULLET_SCENE.instantiate()
add_child(bullet)
bullet.setup(muzzle.global_position, -muzzle.global_basis.z, weapon.damage)
```

```gdscript
# bullet.gd
class_name Bullet
extends Area3D

var damage: int = 10
var direction: Vector3 = Vector3.FORWARD
var speed: float = 30.0

func setup(p_origin: Vector3, p_direction: Vector3, p_damage: int) -> void:
    global_position = p_origin
    direction = p_direction.normalized()
    damage = p_damage
    look_at(p_origin + direction, Vector3.UP)

func _physics_process(delta: float) -> void:
    global_position += direction * speed * delta
```

### PackedScene 저장 (런타임에 씬 만들기)

```gdscript
func save_prefab(root: Node, path: String) -> void:
    # owner가 root로 설정된 노드만 저장된다 — 필수
    for child in root.get_children():
        child.owner = root
    var packed := PackedScene.new()
    var result := packed.pack(root)
    if result == OK:
        ResourceSaver.save(packed, path)
```

**`owner`의 의미**: 노드가 어느 씬에 "속하는지"를 나타낸다. `.tscn`으로 저장할 때
`owner`가 루트로 설정된 노드만 기록된다. 런타임에 `add_child()`로 붙인 노드는
`owner`가 `null`이므로 저장되지 않는다 — 이는 의도된 동작이다.

---

## 5. 씬 전환과 로딩

### 즉시 전환

```gdscript
# 파일 경로로
get_tree().change_scene_to_file("res://scenes/levels/level_02.tscn")

# 미리 로드한 PackedScene으로 (권장 — 로딩 시점 제어 가능)
get_tree().change_scene_to_packed(LEVEL_02)
```

`change_scene_to_*`는 **현재 프레임이 끝난 뒤** 실행된다. 호출 직후 코드는 아직
이전 씬에서 동작한다. 반환값은 `Error`이므로 확인한다.

### 비동기 로딩 (로딩 화면)

큰 3D 레벨은 반드시 스레드 로딩을 쓴다. 그렇지 않으면 수 초간 프레임이 멈춘다.

```gdscript
# res://autoload/scene_loader.gd  (오토로드 등록)
extends Node

signal progress_changed(ratio: float)
signal load_finished(scene: PackedScene)

var _loading_path: String = ""
var _progress: Array = []

func load_scene_async(path: String) -> void:
    _loading_path = path
    var err := ResourceLoader.load_threaded_request(path, "PackedScene", true)
    if err != OK:
        push_error("씬 로드 요청 실패: %s" % path)
        return
    set_process(true)

func _process(_delta: float) -> void:
    if _loading_path.is_empty():
        return

    var status := ResourceLoader.load_threaded_get_status(_loading_path, _progress)
    match status:
        ResourceLoader.THREAD_LOAD_IN_PROGRESS:
            progress_changed.emit(float(_progress[0]))
        ResourceLoader.THREAD_LOAD_LOADED:
            var scene: PackedScene = ResourceLoader.load_threaded_get(_loading_path)
            _loading_path = ""
            set_process(false)
            progress_changed.emit(1.0)
            load_finished.emit(scene)
        ResourceLoader.THREAD_LOAD_FAILED, ResourceLoader.THREAD_LOAD_INVALID_RESOURCE:
            push_error("씬 로드 실패: %s" % _loading_path)
            _loading_path = ""
            set_process(false)
```

```gdscript
# 사용
func go_to_level(path: String) -> void:
    get_tree().change_scene_to_file("res://scenes/ui/loading.tscn")
    SceneLoader.load_finished.connect(_on_loaded, CONNECT_ONE_SHOT)
    SceneLoader.load_scene_async(path)

func _on_loaded(scene: PackedScene) -> void:
    get_tree().change_scene_to_packed(scene)
```

### 씬을 통째로 바꾸지 않는 방식 (권장)

큰 3D 게임에서는 루트를 유지하고 하위 레벨 노드만 교체하는 편이 상태 관리에 유리하다.

```gdscript
# main.gd — 항상 살아있는 루트
extends Node3D

@onready var level_holder: Node3D = %LevelHolder

func change_level(scene: PackedScene) -> void:
    for child in level_holder.get_children():
        child.queue_free()
    await get_tree().process_frame        # 삭제가 반영될 때까지 대기
    var level := scene.instantiate()
    level_holder.add_child(level)
```

---

## 6. 오토로드(싱글턴)

`Project Settings → Globals → Autoload`에 등록한 씬/스크립트는 게임 시작 시
씬 트리 루트 바로 아래에 자동으로 붙고, 씬이 바뀌어도 살아남는다.

```ini
# project.godot
[autoload]

GameState="*res://autoload/game_state.gd"
AudioManager="*res://scenes/autoload/audio_manager.tscn"
SceneLoader="*res://autoload/scene_loader.gd"
```

`*` 접두사는 "싱글턴으로 등록"을 의미하며, 이름으로 전역 접근이 가능해진다.

```gdscript
# res://autoload/game_state.gd
extends Node

signal score_changed(new_score: int)
signal game_over

var score: int = 0:
    set(value):
        score = value
        score_changed.emit(score)

var current_level: int = 1
var player_data: PlayerData = PlayerData.new()

func reset() -> void:
    score = 0
    current_level = 1
    player_data = PlayerData.new()

func save_to_disk() -> void:
    var file := FileAccess.open("user://save.dat", FileAccess.WRITE)
    if file == null:
        push_error("세이브 파일 열기 실패")
        return
    file.store_var({"score": score, "level": current_level}, true)
    file.close()
```

```gdscript
# 어디서든 접근
GameState.score += 100
GameState.score_changed.connect(_on_score_changed)
```

### 오토로드 사용 원칙

**쓸 곳** — 게임 전역 상태, 세이브/로드, 오디오 매니저, 씬 로더, 설정, 이벤트 버스.

**쓰지 말 곳** — 특정 레벨에서만 쓰는 로직, 플레이어 인스턴스 참조(레벨마다 바뀜),
UI 노드 참조. 오토로드가 늘어날수록 결합도가 올라가고 테스트가 어려워진다.

**이벤트 버스 패턴** — 서로 모르는 시스템끼리 통신할 때만 사용한다.

```gdscript
# res://autoload/events.gd
extends Node

signal enemy_killed(enemy: Node3D, killer: Node3D)
signal item_collected(item_id: StringName)
signal level_completed(level_index: int)
```

```gdscript
# 발신 측
Events.enemy_killed.emit(self, attacker)

# 수신 측 (서로를 몰라도 된다)
func _ready() -> void:
    Events.enemy_killed.connect(_on_enemy_killed)
```

---

## 7. 그룹

노드에 태그를 붙여 일괄 조회·호출한다.

```gdscript
func _ready() -> void:
    add_to_group("enemies")
    add_to_group("damageable")

func _exit_tree() -> void:
    # 명시적 제거는 보통 불필요 — 노드가 사라지면 자동 해제된다
    pass
```

```gdscript
# 조회
var enemies := get_tree().get_nodes_in_group("enemies")
print("적 %d명" % get_tree().get_node_count_in_group("enemies"))

# 일괄 메서드 호출 (지연 실행 — 아이들 프레임에 처리)
get_tree().call_group("enemies", "on_alarm_triggered", global_position)

# 즉시 호출 (물리 프레임 안에서 필요할 때)
get_tree().call_group_flags(SceneTree.GROUP_CALL_DEFERRED, "enemies", "stop")

# 소속 확인
if body.is_in_group("player"):
    take_damage(10)
```

**주의**: `get_nodes_in_group()`은 순서를 보장하지 않고 매 호출마다 배열을 새로 만든다.
매 프레임 호출하지 말고 필요할 때만 조회하거나 캐시한다.

에디터에서도 노드 인스펙터의 "Node → Groups" 탭에서 그룹을 지정할 수 있다.

---

## 8. 노드 생성·제거·유효성

```gdscript
# 생성
var node := Node3D.new()
node.name = "DynamicNode"
add_child(node)

# 에디터에서 보이게 하려면 (@tool 스크립트)
node.owner = get_tree().edited_scene_root

# 제거 — 항상 queue_free()
node.queue_free()          # 프레임 끝에 안전하게 삭제

# free()는 즉시 삭제 — 순회 중이거나 시그널 콜백 안에서는 크래시 위험
# node.free()              # 특별한 이유가 없으면 쓰지 않는다

# 트리에서만 떼기 (재사용하려면)
remove_child(node)         # 메모리에는 남는다 — 직접 free 해야 누수 없음

# 부모 바꾸기
node.reparent(new_parent)                    # 전역 변환 유지
node.reparent(new_parent, false)             # 로컬 변환 유지
```

### 유효성 확인

```gdscript
# queue_free()된 노드를 참조하면 "Freed object" 오류
var target: Node3D

func _physics_process(_delta: float) -> void:
    if not is_instance_valid(target):
        target = null
        return
    look_at(target.global_position, Vector3.UP)

# 트리 안에 있는지
if is_inside_tree():
    var t := get_tree()

# queue_free 예약됐는지 (4.x)
if target.is_queued_for_deletion():
    return
```

### 오브젝트 풀 (총알·이펙트처럼 자주 생성/삭제되는 것)

```gdscript
class_name BulletPool
extends Node3D

const BULLET_SCENE: PackedScene = preload("res://scenes/bullet.tscn")
const POOL_SIZE: int = 64

var _pool: Array[Bullet] = []
var _index: int = 0

func _ready() -> void:
    for i in POOL_SIZE:
        var b: Bullet = BULLET_SCENE.instantiate()
        b.process_mode = Node.PROCESS_MODE_DISABLED
        b.visible = false
        add_child(b)
        _pool.append(b)

func acquire() -> Bullet:
    var b := _pool[_index]
    _index = (_index + 1) % POOL_SIZE
    b.process_mode = Node.PROCESS_MODE_INHERIT
    b.visible = true
    return b

func release(b: Bullet) -> void:
    b.process_mode = Node.PROCESS_MODE_DISABLED
    b.visible = false
```

풀링은 GC 압박과 인스턴싱 비용을 없앤다. 초당 수십 개 이상 생성되는 객체에 적용한다.

---

## 9. SceneTree API

```gdscript
var tree := get_tree()

tree.current_scene            # 현재 메인 씬의 루트 노드
tree.root                     # Window (최상위 뷰포트)
tree.paused = true            # 전체 일시정지

# 타이머 (노드 없이 일회성 대기)
await tree.create_timer(1.5).timeout

# 프레임 대기
await tree.process_frame      # 다음 아이들 프레임
await tree.physics_frame      # 다음 물리 프레임

# 종료
tree.quit()

# 시그널
tree.node_added.connect(_on_node_added)
tree.tree_changed.connect(_on_tree_changed)
```

### 일시정지 처리

`get_tree().paused = true`로 게임을 멈추면 모든 노드의 `_process`/`_physics_process`가
멈춘다. UI는 계속 동작해야 하므로 `process_mode`를 조정한다.

```gdscript
# 인스펙터의 Node → Process → Mode, 또는 코드로
pause_menu.process_mode = Node.PROCESS_MODE_WHEN_PAUSED   # 일시정지 중에만 동작
hud.process_mode = Node.PROCESS_MODE_ALWAYS               # 항상 동작
enemy.process_mode = Node.PROCESS_MODE_PAUSABLE           # 기본값 — 일시정지 시 멈춤
```

| 모드 | 동작 |
|------|------|
| `PROCESS_MODE_INHERIT` | 부모를 따름 (기본) |
| `PROCESS_MODE_PAUSABLE` | 일시정지 시 멈춤 |
| `PROCESS_MODE_WHEN_PAUSED` | 일시정지 중에만 동작 |
| `PROCESS_MODE_ALWAYS` | 항상 동작 |
| `PROCESS_MODE_DISABLED` | 항상 멈춤 |

---

## 10. 시그널 기반 느슨한 결합

**핵심 원칙: 자식은 부모를 몰라야 한다. 통지는 시그널로 올리고, 명령은 아래로 내린다.**

> 시그널의 **개념과 기본 사용법**은 [basics.md §5](basics.md#5-시그널signal--노드끼리-대화하는-방법),
> **문법과 연결 플래그**는 [gdscript.md §10](gdscript.md#10-시그널) 에 있다.
> 이 절은 **그것으로 무엇을 조립하는가**를 다룬다.

```gdscript
# health_component.gd — 재사용 가능한 컴포넌트
class_name HealthComponent
extends Node

signal health_changed(current: int, maximum: int)
signal died

@export var max_health: int = 100

var current_health: int

func _ready() -> void:
    current_health = max_health

func take_damage(amount: int) -> void:
    if current_health <= 0:
        return
    current_health = maxi(0, current_health - amount)
    health_changed.emit(current_health, max_health)
    if current_health == 0:
        died.emit()

func heal(amount: int) -> void:
    current_health = mini(max_health, current_health + amount)
    health_changed.emit(current_health, max_health)
```

```gdscript
# enemy.gd — 컴포넌트를 조합해 쓴다
class_name Enemy
extends CharacterBody3D

signal died      # 외부(스포너)에 알릴 시그널을 다시 노출

@onready var health: HealthComponent = $HealthComponent
@onready var anim_tree: AnimationTree = $AnimationTree

func _ready() -> void:
    health.died.connect(_on_died)
    health.health_changed.connect(_on_health_changed)

func _on_died() -> void:
    set_physics_process(false)
    anim_tree.set("parameters/StateMachine/playback", "death")
    died.emit()
    await get_tree().create_timer(2.0).timeout
    queue_free()

func _on_health_changed(current: int, maximum: int) -> void:
    # 피격 이펙트 등
    pass
```

이 구조는 `HealthComponent`를 플레이어·파괴 가능한 오브젝트에 그대로 재사용할 수 있게 한다.

---

## 11. 이 프로젝트의 역할 분리 지침

| 로직 종류 | 배치 위치 | 파일 경로 | 이유 |
|----------|----------|----------|------|
| 캐릭터 이동·충돌 | 해당 캐릭터 씬의 루트 스크립트 | `scenes/player/player.gd` | 캐릭터마다 다르고 인스턴스 상태를 가짐 |
| 무기·스킬 | 무기 씬(`Node3D`) + `Resource` 데이터 | `scenes/weapons/sword.gd` | 장착·교체가 쉬움 |
| 체력·상태이상 | 컴포넌트 노드(`Node`) | `scenes/components/health_component.gd` | 여러 엔티티에서 재사용 |
| 적 AI | 적 씬 안의 상태 머신 노드 | `scenes/enemies/slime.gd` | 적 종류마다 다름 |
| UI | 별도 `CanvasLayer` 씬 | `scenes/ui/hud.gd` | 3D 카메라와 독립 |
| 점수·진행도 | 오토로드 `GameState` | `autoload/game_state.gd` | 씬 전환에도 유지 |
| 세이브/로드 | 오토로드 `SaveManager` | `autoload/save_manager.gd` | 전역 접근 필요 |
| BGM·SFX | 오토로드 `AudioManager` | `autoload/audio_manager.gd` | 씬 전환 중에도 끊기면 안 됨 |
| 씬 전환·로딩 | 오토로드 `SceneLoader` | `autoload/scene_loader.gd` | 전환 자체를 담당 |
| 시스템 간 통지 | 오토로드 `Events` (이벤트 버스) | `autoload/events.gd` | 서로 모르는 시스템 연결 |
| 공용 베이스 클래스 | `class_name` 스크립트 | `scripts/base_character.gd` | 씬에 붙지 않고 여러 씬이 상속 |
| 수학·유틸 | `class_name` 스크립트 | `scripts/math_utils.gd` | 씬 종속성 없음 |
| 아이템·적 정의 클래스 | 커스텀 `Resource` | `scripts/resources/item_data.gd` | 씬 종속성 없음 |
| 아이템·적 정의 데이터 | `.tres` 인스턴스 | `resources/items/sword.tres` | 코드 수정 없이 밸런싱 |

**경로 규칙이 두 갈래인 이유**: 씬에 붙는 스크립트는 씬 옆(`scenes/...`),
씬에 안 붙는 코드는 `autoload/` 또는 `scripts/`다. 아래 절에서 근거를 설명한다.

### 폴더 구조 — 스크립트는 씬 옆에 둔다

**결론: `scenes/main.tscn`과 `scenes/main.gd`를 같은 폴더에 나란히 둔다.**

Godot에서는 타입별로 `scripts/`에 모으는 방식보다 **씬과 스크립트를 같은 폴더에
나란히 두는 것이 공식 권장이자 실무 다수**다. Unity의 `Scripts/` 폴더 관습을 그대로
가져오면 Godot에서는 오히려 관리가 어려워진다.

#### 근거

**1. 엔진 자체가 그 관습을 전제로 동작한다.**

Attach Script 대화상자의 기본 경로는 **현재 씬 파일이 있는 폴더 + 노드 이름**으로
자동 제안된다. `scenes/main.tscn`에서 `Main` 노드에 스크립트를 붙이면
`res://scenes/main.gd`가 기본값으로 채워진다.
`res://scripts/main.gd`로 하려면 **매번 경로를 손으로 고쳐야 한다.**

**2. 씬과 스크립트는 1:1로 강하게 묶여 있다.**

`extends Node3D`는 그 씬의 루트 타입에 종속되고, `$Child` 참조는 그 씬의 노드 구조에
종속된다. 이 스크립트는 다른 씬에 재사용할 수 없는 **사실상 씬의 일부**다.
폴더를 나누면 씬을 옮기거나 지울 때마다 두 폴더를 손으로 동기화해야 한다.

**3. 파일명이 충돌한다.**

`ui/player_hud.tscn`과 `entities/player.tscn`이 각각 스크립트를 가지면
`scripts/` 안에서 이름이 겹치기 시작하고, 결국 `scripts/ui/`, `scripts/entities/`로
**폴더 구조를 두 번 유지**하게 된다.

#### 예외 — `scripts/`에 모으는 게 맞는 것

**씬에 붙지 않는 스크립트**는 따로 모으는 게 맞다.

| 종류 | 예 | 위치 |
|------|-----|------|
| 오토로드(싱글턴) | `GameState`, `AudioManager` | `autoload/` |
| `class_name`을 가진 공용 클래스 | 상태 머신 베이스, 수학 유틸 | `scripts/` |
| 커스텀 `Resource` 정의 | `ItemData`, `SkillData` | `scripts/` 또는 `scripts/resources/` |

이런 코드는 특정 씬에 종속되지 않으므로 `scripts/`나 `autoload/`에 두는 게 자연스럽다.
**`scripts/` 폴더를 없애는 게 아니라 용도를 바꾸는 것이다** —
"모든 스크립트"가 아니라 "씬에 안 붙는 공용 코드"를 담는 곳이 된다.

#### 이 프로젝트 권장 구조

```
res://
├─ scenes/
│  ├─ main.tscn
│  ├─ main.gd              ← 씬 옆에
│  ├─ player/
│  │  ├─ player.tscn
│  │  ├─ player.gd
│  │  └─ player.glb        ← 모델도 같이
│  ├─ enemies/
│  │  ├─ slime.tscn
│  │  ├─ slime.gd
│  │  └─ slime.glb
│  ├─ levels/
│  │  ├─ level_01.tscn
│  │  └─ level_01.gd
│  ├─ components/
│  │  ├─ health_component.tscn
│  │  └─ health_component.gd
│  └─ ui/
│     ├─ hud.tscn
│     ├─ hud.gd
│     ├─ pause_menu.tscn
│     └─ pause_menu.gd
├─ autoload/
│  ├─ game_state.gd
│  ├─ audio_manager.gd
│  └─ events.gd
├─ scripts/                ← 씬에 안 붙는 공용 코드만
│  ├─ save_system.gd
│  ├─ math_utils.gd
│  └─ resources/
│     ├─ item_data.gd
│     └─ weapon_data.gd
├─ resources/              ← .tres 데이터 인스턴스
│  ├─ items/
│  └─ weapons/
├─ assets/                 ← 씬에 종속되지 않는 공용 에셋
│  ├─ textures/
│  ├─ audio/
│  └─ fonts/
└─ addons/
```

#### 에셋도 같은 원칙을 따른다

`player.glb`처럼 **한 씬에서만 쓰는 에셋은 그 씬 옆에 둔다.**
여러 씬이 공유하는 텍스처·폰트·효과음만 `assets/`로 뺀다.

이렇게 하면 `scenes/player/` 폴더를 통째로 복사하는 것만으로 다른 프로젝트에
캐릭터를 옮길 수 있고, 폴더를 지우면 관련 파일이 전부 함께 사라져 고아 파일이 남지 않는다.

---

## 12. 씬 설계 원칙

**하나의 씬 = 하나의 재사용 단위.** 다음 기준으로 분리한다.

1. **여러 번 인스턴스화되는가** — 적, 총알, 아이템 → 별도 씬
2. **독립적으로 테스트할 수 있는가** — F6으로 단독 실행해서 의미가 있으면 별도 씬
3. **다른 씬에서도 쓰는가** — 컴포넌트, UI 위젯 → 별도 씬

### 씬 루트 노드 선택

루트 노드 타입이 그 씬의 "정체"를 결정한다. 나중에 바꾸기 어려우므로 신중히 고른다.

```
player.tscn
└─ Player (CharacterBody3D)          ← 루트가 물리 바디여야 move_and_slide 사용 가능
   ├─ CollisionShape3D
   ├─ Model (Node3D)                 ← glTF 임포트 결과를 여기에 붙임
   │  └─ Skeleton3D → MeshInstance3D
   ├─ AnimationPlayer
   ├─ AnimationTree
   ├─ CameraPivot (Node3D)
   │  └─ SpringArm3D
   │     └─ Camera3D
   ├─ HealthComponent (Node)
   └─ InteractRay (RayCast3D)
```

### 씬 간 통신 규칙

- **부모 → 자식**: 직접 메서드 호출 (`$Child.do_something()`) — 괜찮다
- **자식 → 부모**: 시그널로 통지 — 직접 `get_parent().something()` 호출 금지
- **형제 간**: 공통 부모가 중계하거나 이벤트 버스 사용
- **전역**: 오토로드

이 규칙을 지키면 씬을 다른 곳으로 옮겨도 깨지지 않는다.
