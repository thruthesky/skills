# GDScript 2.0 언어 레퍼런스

## 목차

1. [핵심 개념](#1-핵심-개념)
2. [파일 구조와 선언 순서](#2-파일-구조와-선언-순서)
3. [변수와 정적 타입](#3-변수와-정적-타입)
4. [내장 타입](#4-내장-타입)
5. [연산자·조건문·반복문](#5-연산자조건문반복문)
6. [match 패턴 매칭](#6-match-패턴-매칭)
7. [함수](#7-함수)
8. [클래스와 상속](#8-클래스와-상속)
9. [어노테이션 전체 목록](#9-어노테이션-전체-목록)
10. [시그널](#10-시그널)
11. [await와 코루틴](#11-await와-코루틴)
12. [람다와 Callable](#12-람다와-callable)
13. [생명주기 콜백 호출 순서](#13-생명주기-콜백-호출-순서)
14. [4.5~4.7 신규 문법](#14-4547-신규-문법)
15. [자주 하는 실수](#15-자주-하는-실수)

---

## 1. 핵심 개념

GDScript는 Godot 전용 동적/정적 혼합 타입 스크립트 언어다. 설계 의도는 세 가지다.

- **엔진 통합** — 모든 스크립트는 엔진 클래스(`Node`, `Resource` 등)를 `extends`한다.
  스크립트 파일 자체가 하나의 클래스이며, 파일 경로가 곧 클래스 식별자다.
- **씬 시스템과의 결합** — 스크립트는 노드에 붙어서 동작하고, 노드 트리 진입/이탈 시점에
  생명주기 콜백이 호출된다.
- **점진적 정적 타입** — 타입 힌트는 선택이지만, 붙이면 컴파일 타임 검사·자동완성·성능 향상을
  얻는다. **이 프로젝트는 항상 타입을 명시한다.**

```gdscript
# 이 파일 자체가 하나의 클래스다. 파일명 player.gd → 기본 클래스명 없음.
# class_name을 선언하면 전역 타입으로 등록된다.
class_name Player
extends CharacterBody3D
```

---

## 2. 파일 구조와 선언 순서

Godot 공식 스타일 가이드가 정한 순서. 이 순서를 지키면 다른 파일과 구조가 일치해 탐색이 빨라진다.

```gdscript
## 파일 상단 문서 주석 — 클래스 설명 (에디터 툴팁에 표시)
@tool                      # 1. 스크립트 수준 어노테이션
@icon("res://icon.svg")
class_name Player          # 2. class_name
extends CharacterBody3D    # 3. extends

# 4. 시그널
signal health_changed(new_health: int)
signal died

# 5. 열거형
enum State { IDLE, RUN, JUMP, ATTACK }

# 6. 상수
const MAX_HEALTH: int = 100
const BULLET_SCENE: PackedScene = preload("res://scenes/bullet.tscn")

# 7. 정적 변수
static var instance_count: int = 0

# 8. @export 변수
@export var move_speed: float = 5.0
@export_range(0.0, 20.0, 0.1) var jump_velocity: float = 4.5

# 9. 일반 변수
var current_state: State = State.IDLE
var health: int = MAX_HEALTH

# 10. @onready 변수
@onready var camera: Camera3D = %Camera3D
@onready var anim_tree: AnimationTree = $AnimationTree

# 11. 내장 가상 메서드 (_init → _enter_tree → _ready → _process → _physics_process → _input)
func _ready() -> void:
    pass

# 12. public 메서드
func take_damage(amount: int) -> void:
    pass

# 13. private 메서드 (_ 접두사)
func _apply_gravity(delta: float) -> void:
    pass
```

---

## 3. 변수와 정적 타입

### 선언 방식

```gdscript
var a                       # 타입 없음 (Variant) — 사용하지 않는다
var b: int                  # 명시적 타입, 기본값 0
var c: int = 10             # 명시적 타입 + 초기값
var d := 10                 # 타입 추론 (int로 결정) — 권장
var e: Node3D = $Enemy      # 노드 참조는 항상 타입 명시
```

`:=`는 **추론**이지 동적 타입이 아니다. 한 번 추론된 타입은 고정된다.

### 타입 컨테이너

```gdscript
var scores: Array[int] = [1, 2, 3]
var names: PackedStringArray = ["a", "b"]          # 메모리 효율적인 팩드 배열
var lookup: Dictionary[String, int] = {"hp": 100}  # 4.4+ 타입 딕셔너리
var enemies: Array[Enemy] = []                     # 커스텀 클래스도 가능
```

팩드 배열(`PackedInt32Array`, `PackedFloat32Array`, `PackedVector3Array`, `PackedByteArray`,
`PackedColorArray`)은 연속 메모리를 쓰므로 대량 수치 데이터에 반드시 사용한다.
메시 정점, 오디오 PCM, 네트워크 페이로드가 그 대상이다.

### 상수와 preload

```gdscript
const GRAVITY: float = 9.8
const DIRS: Array[Vector3] = [Vector3.FORWARD, Vector3.BACK]

# preload는 컴파일 타임에 로드된다 → const로 선언 가능
const ENEMY_SCENE: PackedScene = preload("res://scenes/enemy.tscn")

# load는 런타임에 로드된다 → var
var boss_scene: PackedScene = load("res://scenes/boss.tscn")
```

### setter / getter

```gdscript
var health: int = 100:
    set(value):
        health = clampi(value, 0, MAX_HEALTH)
        health_changed.emit(health)
        if health == 0:
            died.emit()
    get:
        return health

# 계산 프로퍼티 (백킹 변수 없음)
var health_ratio: float:
    get:
        return float(health) / MAX_HEALTH
```

**주의**: setter 안에서 같은 변수에 대입하면 무한 재귀가 아니라 백킹 저장소에 직접 쓰인다.
하지만 `self.health = value`처럼 `self.`를 붙이면 setter가 다시 호출되어 무한 재귀가 된다.

---

## 4. 내장 타입

3D 개발에서 실제로 쓰는 것만 정리한다.

| 타입 | 용도 | 자주 쓰는 멤버 |
|------|------|---------------|
| `int` / `float` | 64비트 정수 / 실수 | `absi`, `clampf`, `lerpf`, `snappedf` |
| `String` / `StringName` | 문자열 / 인터닝된 문자열 | `StringName`은 비교가 빠름. 시그널·액션 이름에 사용 |
| `Vector2` / `Vector3` | 2D/3D 벡터 | `length`, `normalized`, `dot`, `cross`, `direction_to`, `distance_to`, `lerp`, `slerp`, `move_toward` |
| `Basis` | 3x3 회전·스케일 행렬 | `x`, `y`, `z` 축 벡터, `looking_at`, `orthonormalized` |
| `Transform3D` | `Basis` + `origin` | `translated_local`, `rotated`, `inverse`, `interpolate_with` |
| `Quaternion` | 회전 (짐벌락 없음) | `slerp`, `from_euler`, `normalized` |
| `Color` | RGBA | `srgb_to_linear`, `lerp`, `Color.from_hsv` |
| `AABB` | 3D 경계 상자 | `intersects`, `has_point`, `merge` |
| `Plane` | 무한 평면 | `intersects_ray`, `distance_to` |
| `NodePath` | 노드 경로 | `@export var target: NodePath` |
| `Callable` | 함수 참조 | `call`, `bind`, `call_deferred` |
| `Signal` | 시그널 참조 | `emit`, `connect`, `is_connected` |
| `RID` | 서버 리소스 핸들 | `RenderingServer`, `PhysicsServer3D` 직접 조작 시 |

### 벡터 상수 (Godot 3D 좌표계)

```gdscript
Vector3.FORWARD == Vector3(0, 0, -1)   # -Z가 전방
Vector3.BACK    == Vector3(0, 0,  1)
Vector3.UP      == Vector3(0, 1,  0)
Vector3.DOWN    == Vector3(0, -1, 0)
Vector3.RIGHT   == Vector3(1, 0,  0)
Vector3.LEFT    == Vector3(-1, 0, 0)
```

---

## 5. 연산자·조건문·반복문

```gdscript
# 산술: + - * / % **   (** 는 거듭제곱)
var power := 2 ** 10        # 1024

# 정수 나눗셈 주의: int / int = int
var half := 7 / 2           # 3  (정수 나눗셈)
var halff := 7.0 / 2        # 3.5

# 비교: == != < > <= >=
# 논리: and or not  (&& || ! 도 동작하지만 GDScript 스타일은 영단어)
# 멤버십: in
if "hp" in stats: pass
if enemy in get_tree().get_nodes_in_group("enemies"): pass

# 타입 검사
if node is CharacterBody3D: pass
var body := node as CharacterBody3D   # 실패하면 null

# 삼항
var speed := run_speed if is_running else walk_speed
```

### 반복문

```gdscript
for i in 10:                          # 0..9
    pass
for i in range(2, 10, 2):             # 2,4,6,8
    pass
for item in inventory:                # 배열 순회
    pass
for key in stats:                     # 딕셔너리 키 순회
    print(key, stats[key])
for child: Node3D in get_children():  # 순회 변수 타입 지정 (4.2+)
    child.visible = false

while health > 0:
    health -= 1
    if health == 50:
        continue
    if should_stop:
        break
```

---

## 6. match 패턴 매칭

`switch`보다 강력하다. 첫 번째로 매치되는 분기만 실행되고 fallthrough는 없다.

```gdscript
match current_state:
    State.IDLE:
        _do_idle()
    State.RUN, State.JUMP:            # 다중 패턴
        _do_move()
    _:                                # 와일드카드 (default)
        push_error("알 수 없는 상태")

# 배열 패턴 + 바인딩
match point:
    [0, 0]:
        print("원점")
    [var x, 0]:
        print("X축 위, x=", x)
    [var x, var y] when y == x:       # 패턴 가드 (4.5+)
        print("y = x 직선 위")
    [_, _, ..]:                       # 최소 2개, 나머지 무시
        print("3차원 이상")

# 딕셔너리 패턴
match config:
    {"type": "melee", "damage": var dmg}:
        _spawn_melee(dmg)
    {"type": "ranged", ..}:           # 나머지 키 허용
        _spawn_ranged()
```

---

## 7. 함수

```gdscript
# 기본형: 인자 타입과 반환 타입을 항상 명시한다
func take_damage(amount: int, source: Node3D = null) -> void:
    health -= amount

# 반환값이 있는 경우
func get_distance_to_player() -> float:
    return global_position.distance_to(player.global_position)

# 가변 인자 (4.5+) — rest 매개변수는 하나만, 반드시 마지막
func log_all(prefix: String, ...values: Array) -> void:
    for v in values:
        print(prefix, v)

log_all("[DEBUG] ", 1, "two", Vector3.ZERO)

# 정적 메서드
static func create_default() -> Player:
    return Player.new()
```

### 인자는 참조인가 값인가

- `int`, `float`, `bool`, `String`, `Vector3`, `Transform3D` 등 **값 타입**은 복사된다.
- `Array`, `Dictionary`, `Object`(노드·리소스 포함)는 **참조**로 전달된다.

```gdscript
func mutate(arr: Array, v: Vector3) -> void:
    arr.append(1)      # 호출자에게 반영됨
    v.x = 999          # 호출자에게 반영 안 됨 (값 복사)
```

### 복사 — duplicate / duplicate_deep

배열·딕셔너리를 값처럼 다루려면 복사해야 한다. **어디까지 복사되는지가 세 단계로 나뉜다.**

| 호출 | 중첩 Array/Dictionary | 안에 든 `Resource` |
|---|---|---|
| `duplicate()` | 공유 | 공유 |
| `duplicate(true)` | **복사** | 공유 |
| `duplicate_deep()` | 복사 | **복사** |

```gdscript
var original := [1, [2, 3]]

var a := original.duplicate()          # 얕은 복사 — 안쪽 [2,3] 을 공유한다
var b := original.duplicate(true)      # 안쪽 배열까지 복사
var c := original.duplicate_deep()     # 안쪽 배열 + 리소스까지 복사

original[1].append(99)
# a[1] == [2, 3, 99]   ← 딸려 바뀐다
# b[1] == [2, 3]
# c[1] == [2, 3]
```

**`duplicate(true)`는 "완전한 깊은 복사"가 아니다.** 중첩된 배열·딕셔너리는 복사하지만
그 안에 들어 있는 **`Resource`는 원본과 그대로 공유**한다. 오래 혼란을 준 지점이며,
이 때문에 `duplicate_deep()`이 추가되었다.

```gdscript
var mat := StandardMaterial3D.new()
var arr := [mat]

arr.duplicate(true)[0] == mat          # true  — 같은 머티리얼을 가리킨다
arr.duplicate_deep()[0] == mat         # false — 복제되었다
```

`duplicate_deep(mode)`의 인자로 리소스를 어디까지 복제할지 정한다.

| 모드 | 값 | 동작 |
|---|---|---|
| `Resource.DEEP_DUPLICATE_NONE` | 0 | 리소스는 전혀 복제하지 않는다. 배열·딕셔너리만 복사 |
| `Resource.DEEP_DUPLICATE_INTERNAL` | 1 (기본) | **경로가 없거나 씬 로컬인** 리소스만 복제 |
| `Resource.DEEP_DUPLICATE_ALL` | 2 | 외부 파일 리소스까지 전부 복제 |

`ALL`은 `.tres`/텍스처처럼 디스크에 있는 큰 리소스까지 복제하므로 메모리를 크게 쓴다.
**기본값인 `INTERNAL`이 대부분 옳다.** 인벤토리 아이템 데이터처럼 씬 안에서 만들어진
리소스만 복제하고, 공용 텍스처는 계속 공유하기 때문이다.

`Dictionary`도 동일한 세 가지 메서드를 갖는다.

---

## 8. 클래스와 상속

### 상속 대상 결정 규칙

| 만들려는 것 | extends |
|------------|---------|
| 3D 공간에 존재하는 것 (적, 아이템, 무기) | `Node3D` 또는 그 파생 |
| 코드로 제어하는 캐릭터 | `CharacterBody3D` |
| 물리에 맡기는 오브젝트 | `RigidBody3D` |
| 움직이지 않는 지형·벽 | `StaticBody3D` |
| 트리거·감지 영역 | `Area3D` |
| 매니저·상태 저장 (공간 개념 없음) | `Node` |
| UI | `Control` 또는 그 파생 |
| 데이터 컨테이너 (아이템 정의, 스탯 테이블) | `Resource` |
| 씬 트리와 무관한 순수 로직 | `RefCounted` (기본값, `extends` 생략 가능) |

### class_name과 전역 등록

```gdscript
# res://scripts/base_character.gd
class_name BaseCharacter
extends CharacterBody3D

@export var max_health: int = 100
var health: int

func _ready() -> void:
    health = max_health

func take_damage(amount: int) -> void:
    health = maxi(0, health - amount)
    if health == 0:
        die()

func die() -> void:              # 자식이 재정의할 훅
    queue_free()
```

```gdscript
# res://scenes/player/player.gd
class_name Player
extends BaseCharacter

func _ready() -> void:
    super()                      # 부모 _ready 호출 — 빠뜨리면 health가 0이 된다
    add_to_group("player")

func die() -> void:
    GameState.on_player_died()   # 부모와 다르게 처리
    super()                      # 부모 동작도 실행하려면 명시 호출
```

`class_name`을 선언하면 전역 클래스로 등록되어 `preload` 없이 `Player.new()`,
`node is Player`처럼 쓸 수 있다. 프로젝트 전체에서 이름이 유일해야 한다.

### @abstract (4.5+)

인스턴스화를 막고 자식이 반드시 구현하게 강제한다.

```gdscript
@abstract
class_name Weapon
extends Node3D

@export var damage: int = 10

@abstract
func fire(origin: Vector3, direction: Vector3) -> void

func can_fire() -> bool:         # 일반 메서드는 구현을 가질 수 있다
    return true
```

```gdscript
class_name Rifle
extends Weapon

func fire(origin: Vector3, direction: Vector3) -> void:   # 구현 필수
    var bullet := BULLET_SCENE.instantiate() as Bullet
    bullet.setup(origin, direction, damage)
    get_tree().current_scene.add_child(bullet)
```

`Weapon.new()`를 호출하면 런타임 에러가 난다. 4.5 이전에는 `push_error()`로 흉내냈지만
이제 언어 차원에서 지원한다.

### 내부 클래스

```gdscript
class InventorySlot:
    var item: ItemData
    var count: int = 0

    func _init(p_item: ItemData = null, p_count: int = 0) -> void:
        item = p_item
        count = p_count

var slots: Array[InventorySlot] = []

func add_slot() -> void:
    slots.append(InventorySlot.new(null, 0))
```

### _init 생성자

```gdscript
class_name WeaponData
extends Resource

@export var name: String
@export var damage: int

func _init(p_name: String = "", p_damage: int = 0) -> void:
    name = p_name
    damage = p_damage
```

**주의**: `Node`를 상속한 클래스는 씬에서 인스턴스화될 때 `_init()`이 인자 없이 호출되므로
모든 인자에 기본값이 있어야 한다.

### 다중 상속은 없다

인터페이스가 필요하면 조합(composition)이나 덕 타이핑으로 푼다.

```gdscript
# 조합: 기능을 자식 노드로 붙인다
# Player (CharacterBody3D)
#  ├─ HealthComponent (Node)
#  ├─ InventoryComponent (Node)
#  └─ HitboxComponent (Area3D)

@onready var health_comp: HealthComponent = $HealthComponent

# 덕 타이핑: 메서드 존재 여부로 판단
if body.has_method("take_damage"):
    body.take_damage(10)
```

---

## 9. 어노테이션 전체 목록

### 스크립트 수준

| 어노테이션 | 설명 |
|-----------|------|
| `@tool` | 에디터에서도 스크립트를 실행한다. `Engine.is_editor_hint()`로 분기 |
| `@icon("res://path.svg")` | 씬 트리에 표시할 아이콘 |
| `@static_unload` | 스크립트 참조가 없어지면 정적 변수를 언로드 |
| `@abstract` | 추상 클래스/메서드 (4.5+) |
| `@warning_ignore("unused_variable")` | 특정 경고 억제 |
| `@warning_ignore_start` / `@warning_ignore_restore` | 구간 단위 경고 억제 (4.4+) |

### 변수 수준

| 어노테이션 | 설명 |
|-----------|------|
| `@onready var x = $Node` | `_ready()` 직전에 초기화. 노드 참조에 필수 |
| `@export var x: int` | 인스펙터에 노출 + 씬에 저장 |
| `@export_range(min, max, step)` | 슬라이더. `"or_greater"`, `"or_less"`, `"exp"`, `"hide_slider"`, `"degrees"`, `"radians_as_degrees"` 옵션 |
| `@export_enum("A", "B", "C")` | 문자열/정수 드롭다운. `"A:10"`처럼 값 지정 가능 |
| `@export_flags("Fire", "Water", "Wind")` | 비트 플래그 체크박스 |
| `@export_flags_3d_physics` | 3D 물리 레이어 선택기 |
| `@export_flags_3d_render` | 3D 렌더 레이어 선택기 |
| `@export_flags_3d_navigation` | 3D 내비 레이어 선택기 |
| `@export_file("*.tscn")` | 파일 선택 다이얼로그 |
| `@export_dir` | 폴더 선택 |
| `@export_global_file` / `@export_global_dir` | `res://` 밖 경로도 허용 |
| `@export_multiline` | 여러 줄 텍스트 편집기 |
| `@export_placeholder("이름 입력")` | 빈 문자열일 때 표시할 힌트 |
| `@export_color_no_alpha` | 알파 없는 색상 선택 |
| `@export_node_path("Node3D")` | 특정 타입의 NodePath만 선택 |
| `@export_exp_easing` | 이징 커브 위젯 |
| `@export_group("이름", "접두사")` | 인스펙터 그룹 |
| `@export_subgroup("이름")` | 하위 그룹 |
| `@export_category("이름")` | 카테고리 구분선 |
| `@export_storage` | 저장은 하되 인스펙터에 숨김 (4.3+) |
| `@export_custom(hint, hint_string)` | 커스텀 힌트 직접 지정 (4.3+) |
| `@export_tool_button("라벨")` | 인스펙터 버튼 (4.4+, `@tool` 필요) |

### 실전 예시

```gdscript
@tool
class_name EnemySpawner
extends Node3D

@export_category("스폰 설정")
@export_range(1, 50, 1) var max_enemies: int = 10
@export_range(0.1, 10.0, 0.1, "or_greater") var spawn_interval: float = 2.0
@export_file("*.tscn") var enemy_scene_path: String = ""

@export_group("영역", "area_")
@export var area_radius: float = 20.0
@export_flags_3d_physics var area_collision_mask: int = 1

@export_group("디버그")
@export var draw_gizmo: bool = true
@export_tool_button("지금 스폰") var spawn_action: Callable = _editor_spawn

func _editor_spawn() -> void:
    if Engine.is_editor_hint():
        print("에디터에서 스폰 테스트")
```

### 네트워크

```gdscript
@rpc("any_peer", "call_local", "reliable", 1)
func request_fire(target: Vector3) -> void:
    pass
```

인자 순서는 자유롭고 생략 가능하다. 기본값은 `("authority", "call_remote", "unreliable", 0)`.
자세한 내용은 [multiplayer.md](multiplayer.md).

---

## 10. 시그널

시그널은 옵저버 패턴의 언어 차원 구현이며, **노드 간 결합을 끊는 유일한 권장 수단**이다.

> **시그널이 처음이라면 [basics.md §5](basics.md#5-시그널signal--노드끼리-대화하는-방법) 를 먼저 읽는다.**
> 왜 필요한지, **Godot 4 에서 시그널이 "값"이라는 것**, 에디터 연결 방법,
> 그리고 엔진에서 확인한 실제 동작(호출 순서·중복 연결 거부·원샷)이 거기 있다.
> 이 절은 **문법과 플래그의 상세**를 다룬다.

```gdscript
# 선언 — 인자에 타입을 붙인다
signal health_changed(new_health: int, max_health: int)
signal died
signal item_picked(item: ItemData, count: int)

# 발신
health_changed.emit(health, MAX_HEALTH)

# 연결 (코드)
func _ready() -> void:
    health_changed.connect(_on_health_changed)
    died.connect(_on_died, CONNECT_ONE_SHOT)     # 한 번만 실행 후 자동 해제

func _on_health_changed(new_health: int, max_health: int) -> void:
    hp_bar.value = float(new_health) / max_health

# 인자 바인딩 — 추가 인자를 뒤에 덧붙인다
button.pressed.connect(_on_slot_pressed.bind(slot_index))

func _on_slot_pressed(slot_index: int) -> void:
    pass

# 해제
if health_changed.is_connected(_on_health_changed):
    health_changed.disconnect(_on_health_changed)
```

### 연결 플래그

| 플래그 | 동작 |
|--------|------|
| `CONNECT_DEFERRED` | 현재 프레임 끝(아이들 시점)에 호출. 물리 콜백 중 노드 추가/제거할 때 필수 |
| `CONNECT_ONE_SHOT` | 한 번 호출 후 자동 해제 |
| `CONNECT_PERSIST` | 씬 저장 시 연결도 함께 저장 |
| `CONNECT_REFERENCE_COUNTED` | 같은 연결을 여러 번 허용, 카운트로 관리 |

### 물리 콜백 안에서 노드를 바꿀 때

```gdscript
func _on_body_entered(body: Node3D) -> void:
    # 물리 쿼리 중에는 물리 상태를 바꿀 수 없다 → deferred로 미룬다
    _spawn_explosion.call_deferred(global_position)
    queue_free()      # queue_free는 이미 지연 실행이라 안전
```

---

## 11. await와 코루틴

`await`는 함수를 일시 정지하고 시그널이나 코루틴이 완료될 때 재개한다.

```gdscript
# 시그널 대기
await get_tree().create_timer(2.0).timeout
await animation_player.animation_finished
await get_tree().physics_frame       # 다음 물리 프레임까지
await get_tree().process_frame       # 다음 아이들 프레임까지

# 다른 코루틴 함수 대기
func play_intro() -> void:
    await _fade_in()
    await get_tree().create_timer(1.0).timeout
    await _show_title()

func _fade_in() -> void:
    var tween := create_tween()
    tween.tween_property(overlay, "modulate:a", 0.0, 1.0)
    await tween.finished
```

**주의사항**

- `await` 중에 노드가 `queue_free()`될 수 있다. 재개 후 `is_instance_valid(self)`를 확인한다.
- `await`가 있는 함수는 반환 타입이 실질적으로 코루틴이 된다. 호출자가 `await` 없이 부르면
  즉시 반환되고 나머지는 백그라운드로 진행된다.

```gdscript
func _ready() -> void:
    await get_tree().physics_frame
    if not is_instance_valid(self):
        return
    nav_agent.target_position = target.global_position
```

---

## 12. 람다와 Callable

```gdscript
# 익명 람다
var double := func(x: int) -> int:
    return x * 2
print(double.call(5))            # 10 — 반드시 .call()

# 이름 있는 람다 (스택 트레이스에 이름이 남는다)
var validate := func check_range(v: int) -> bool:
    return v >= 0 and v <= 100

# 즉시 사용
get_tree().get_nodes_in_group("enemies").sort_custom(
    func(a: Node3D, b: Node3D) -> bool:
        return a.global_position.distance_to(global_position) \
             < b.global_position.distance_to(global_position)
)

# 메서드 참조와 바인딩
var handler := _on_hit.bind(damage_amount)
timer.timeout.connect(handler)

# 지연 호출
_apply_damage.call_deferred(10)
```

람다는 선언 시점의 지역 변수를 **값으로 캡처**한다. 이후 변수를 바꿔도 람다 안의 값은
그대로다. `self`는 참조로 캡처되므로 멤버 변수 접근은 최신 값이 보인다.

---

## 13. 생명주기 콜백 호출 순서

Godot에서 버그의 상당수가 이 순서를 오해해서 생긴다.

```
객체 생성
  └─ _init()                       # 노드가 트리 밖. $Node 접근 불가, @onready 미초기화

노드가 트리에 추가됨 (add_child / 씬 로드)
  └─ _enter_tree()                 # 부모 → 자식 순. get_tree() 사용 가능
       └─ (자식들의 _enter_tree)
  └─ @onready 변수 초기화          # 자식 → 부모 순으로 _ready 직전
  └─ _ready()                      # 자식 → 부모 순. 모든 자식이 준비된 뒤 호출

매 프레임
  └─ _process(delta)               # 가변 프레임레이트. 렌더링·UI·입력 폴링
  └─ _physics_process(delta)       # 고정 틱(기본 60Hz). 물리·이동

입력 발생 시 (전파 순서)
  └─ _input(event)                 # 모든 노드, 트리 역순
  └─ _shortcut_input(event)
  └─ _unhandled_key_input(event)
  └─ _unhandled_input(event)       # Control이 처리하지 않은 입력
  (Control 노드는 _gui_input 이 _input 이후 별도 경로로)

노드가 트리에서 제거됨
  └─ _exit_tree()                  # 부모 → 자식 순

객체 소멸
  └─ _notification(NOTIFICATION_PREDELETE)
```

### 핵심 규칙

- **`_ready()`는 자식이 먼저**다. 부모의 `_ready()`에서는 모든 자식이 준비된 상태다.
  반대로 자식의 `_ready()`에서 부모의 `@onready` 변수를 읽으면 아직 `null`이다.
- `_enter_tree()`는 트리 진입 때마다 호출되지만 `_ready()`는 기본적으로 한 번만 호출된다.
  재진입 시에도 호출하려면 `request_ready()`를 부른다.
- `_process`/`_physics_process`는 `set_process(false)`/`set_physics_process(false)`로 끌 수 있다.
  안 쓰는 콜백은 정의하지 않거나 꺼서 오버헤드를 줄인다.

### delta의 의미

```gdscript
func _process(delta: float) -> void:
    # delta = 지난 프레임 이후 경과 시간(초). 프레임레이트에 따라 변한다.
    rotate_y(1.0 * delta)          # 초당 1라디안 — 프레임레이트 무관

func _physics_process(delta: float) -> void:
    # delta = 고정값 (기본 1/60 ≈ 0.01667). 물리 틱 설정에 따름
    velocity.y -= GRAVITY * delta
```

---

## 14. 4.5~4.7 신규 문법

| 기능 | 버전 | 예시 |
|------|------|------|
| `@abstract` 클래스/메서드 | 4.5 | 위 [8절](#8-클래스와-상속) 참고 |
| 가변 인자 `...args` | 4.5 | `func f(a, ...rest: Array)` |
| `match` 패턴 가드 `when` | 4.5 | `[var x, var y] when y == x:` |
| `_static_init()` 정적 생성자 | 4.5 | 클래스 로드 시 1회 자동 호출 |
| `Dictionary[K, V]` 타입 | 4.4 | `var d: Dictionary[String, int]` |
| `@export_tool_button` | 4.4 | 인스펙터에 실행 버튼 |
| `@warning_ignore_start/restore` | 4.4 | 구간 경고 억제 |
| `Tween.tween_await()` | 4.7 | 트윈 중간에 시그널 대기 |
| `#region` / `#endregion` | 4.0 | 에디터 코드 접기 |

```gdscript
# 정적 생성자
static var lookup_table: Dictionary[String, int] = {}

static func _static_init() -> void:
    lookup_table["sword"] = 10
    lookup_table["axe"] = 15

# 4.7 tween_await
func play_sequence() -> void:
    var tween := create_tween()
    tween.tween_property(self, "position:y", 3.0, 0.5)
    tween.tween_await(animation_player.animation_finished)
    tween.tween_property(self, "position:y", 0.0, 0.5)
```

---

## 15. 자주 하는 실수

| 실수 | 결과 | 올바른 방법 |
|------|------|------------|
| `_init()`에서 `$Child` 접근 | `null` 참조 오류 | `_ready()` 또는 `@onready` 사용 |
| 부모 `_ready()`에서 `super()` 누락 | 부모 초기화가 안 됨 | 재정의 시 항상 `super()` 호출 여부를 판단 |
| `_process`에서 `move_and_slide()` | 지터·터널링 | `_physics_process`로 옮긴다 |
| `rotation.y += x` 누적 | 짐벌락·오차 | `Basis`/`Quaternion` 사용 |
| `free()` 를 시그널 콜백에서 호출 | 크래시 | `queue_free()` 사용 |
| `Array`를 값으로 착각 | 의도치 않은 공유 변경 | `duplicate(true)` (리소스까지 필요하면 `duplicate_deep()`) |
| `duplicate(true)`면 전부 복사된다고 착각 | 배열 안 `Resource`가 공유되어 한쪽 수정이 전체 반영 | `duplicate_deep()` |
| 리소스를 여러 인스턴스가 공유 | 한쪽 변경이 전체 반영 | `resource.duplicate()` 또는 `Local to Scene` 체크 |
| `await` 후 `self` 유효성 미확인 | "Freed object" 오류 | `is_instance_valid(self)` 확인 |
| 정수 나눗셈 `1/2 == 0` | 0이 나옴 | `1.0/2` 또는 `float(a)/b` |
| 시그널 연결 해제 안 함 | 제거된 노드 호출 오류 | `queue_free()`는 자동 해제하지만, 수동 연결은 `disconnect` |
| `class_name` 중복 | 파싱 오류 | 프로젝트 전역에서 유일하게 |
| `@onready` 를 `@export`와 같이 사용 | 저장값이 덮어써짐 | 둘 중 하나만 |

### 디버깅 도구

```gdscript
print("일반 출력")
print_rich("[color=red]강조[/color]")     # BBCode 지원
push_warning("경고 — 디버거 패널에 표시")
push_error("에러 — 스택 트레이스 포함")
printerr("stderr 출력")
assert(health >= 0, "health가 음수가 되면 안 됨")   # 릴리스 빌드에서는 제거됨
breakpoint                                          # 코드에서 디버거 정지
print_stack()                                       # 현재 호출 스택
print_tree_pretty()                                 # 노드 트리 시각화
```
