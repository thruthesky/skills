# 리소스와 에셋 임포트

## 목차

1. [핵심 개념 — Resource란 무엇인가](#1-핵심-개념--resource란-무엇인가)
2. [커스텀 Resource로 게임 데이터 정의](#2-커스텀-resource로-게임-데이터-정의)
3. [설정·정적 데이터를 `.tres` 로 빼기](#3-설정정적-데이터를-tres-로-빼기)
4. [로딩 — load / preload / 스레드 로딩](#4-로딩--load--preload--스레드-로딩)
5. [ResourceUID와 .import 시스템](#5-resourceuid와-import-시스템)
6. [3D 모델 임포트 (glTF / .blend)](#6-3d-모델-임포트-gltf--blend)
7. [텍스처 임포트와 압축](#7-텍스처-임포트와-압축)
8. [오디오 임포트](#8-오디오-임포트)
9. [세이브 파일 (user://)](#9-세이브-파일-user)
10. [설정 파일 (ConfigFile)](#10-설정-파일-configfile)
11. [FileAccess와 DirAccess](#11-fileaccess와-diraccess)
12. [자주 하는 실수](#12-자주-하는-실수)

---

## 1. 핵심 개념 — Resource란 무엇인가

`Resource`는 **디스크에 저장할 수 있고, 참조로 공유되는 데이터 객체**다.
`Node`가 "씬 트리에 존재하는 것"이라면 `Resource`는 "그 노드들이 사용하는 데이터"다.

```
Node    — 씬 트리에 붙고, 생명주기 콜백을 가지며, 위치가 있다
Resource — 디스크에 저장되고, 여러 노드가 공유하며, 참조 카운트로 관리된다
```

### 엔진 내장 Resource

`PackedScene`(.tscn), `Texture2D`, `Mesh`, `Material`, `Animation`, `AudioStream`,
`Shape3D`, `Font`, `Theme`, `Shader`, `Curve`, `Gradient`, `Environment`, `NavigationMesh`...

### 참조 공유 — 가장 중요한 특성

**같은 경로의 리소스를 여러 번 `load()`하면 같은 인스턴스가 반환된다.**

```gdscript
var a := load("res://materials/red.tres")
var b := load("res://materials/red.tres")
# a == b — 같은 객체다

a.albedo_color = Color.BLUE
# b.albedo_color도 파랗게 바뀐다
```

이는 메모리 효율을 위한 의도된 설계지만, 인스턴스마다 다른 값이 필요할 때 함정이 된다.

```gdscript
# 개별화 방법
var unique := shared_resource.duplicate()          # 얕은 복사 — 하위 리소스 공유
var deep := shared_resource.duplicate(true)        # 프로퍼티의 하위 리소스까지 복제
var full := shared_resource.duplicate_deep()       # Array/Dictionary 안의 리소스까지 복제

# 또는 에디터에서
#   - 인스펙터에서 리소스 우클릭 → "Make Unique"
#   - 리소스의 "Local to Scene" 체크 → 씬 인스턴스마다 자동 복제
```

**`duplicate(true)`의 한계 — `duplicate_deep()`이 추가된 이유**

`duplicate(true)`는 리소스의 **프로퍼티에 직접 담긴** 하위 리소스는 복제하지만,
**`Array`나 `Dictionary` 프로퍼티 안에 들어 있는 하위 리소스는 복제하지 않는다.**
`Array.duplicate(true)` / `Dictionary.duplicate(true)`도 마찬가지다.

```gdscript
var mat := StandardMaterial3D.new()
var arr := [mat]

arr.duplicate(true)[0] == mat        # true  — 공유된다
arr.duplicate_deep()[0] == mat       # false — 복제된다
```

인벤토리 아이템 배열, 스킬 목록처럼 **리소스를 배열에 담는 구조에서 반드시 걸린다.**
복제했다고 생각하고 값을 바꿨는데 원본까지 바뀐다.

`duplicate_deep(deep_subresources_mode)`로 복제 범위를 직접 정한다.

| 모드 | 값 | 동작 |
|---|---|---|
| `Resource.DEEP_DUPLICATE_NONE` | 0 | 하위 리소스를 전혀 복제하지 않는다. 배열·딕셔너리 구조만 복사 |
| `Resource.DEEP_DUPLICATE_INTERNAL` | 1 (기본) | **경로가 없거나 씬 로컬 경로인** 하위 리소스만 복제 |
| `Resource.DEEP_DUPLICATE_ALL` | 2 | 외부 파일 리소스까지 전부 복제 |

```gdscript
# 아이템 템플릿에서 인스턴스를 만든다. 공용 아이콘 텍스처는 공유하고,
# 씬 안에서 만들어진 스탯 리소스만 복제한다 — 기본값 INTERNAL 이 정확히 이 동작이다
var item := item_template.duplicate_deep()

# 원본과 완전히 끊어야 할 때만 ALL. 큰 텍스처까지 복제되므로 메모리를 크게 쓴다
var isolated := item_template.duplicate_deep(Resource.DEEP_DUPLICATE_ALL)
```

`resource_local_to_scene = true`로 두면 씬을 인스턴스화할 때마다 자동 복제된다.
캐릭터마다 다른 머티리얼 색이 필요한 경우 이 방법이 가장 깔끔하다.

---

## 2. 커스텀 Resource로 게임 데이터 정의

**코드를 수정하지 않고 밸런싱하려면 데이터를 리소스로 뺀다.**
이는 이 프로젝트의 핵심 설계 원칙이다.

### 아이템 정의

```gdscript
# res://scripts/resources/item_data.gd
@icon("res://assets/icons/item.svg")
class_name ItemData
extends Resource

enum ItemType { WEAPON, ARMOR, CONSUMABLE, MATERIAL, QUEST }

@export_group("기본 정보")
@export var id: StringName = &""
@export var display_name: String = ""
@export_multiline var description: String = ""
@export var icon: Texture2D
@export var type: ItemType = ItemType.MATERIAL

@export_group("스택")
@export var stackable: bool = true
@export_range(1, 999) var max_stack: int = 99

@export_group("경제")
@export var buy_price: int = 100
@export var sell_price: int = 30

@export_group("3D 표현")
@export var world_scene: PackedScene          # 바닥에 떨어졌을 때
@export var equip_scene: PackedScene          # 장착했을 때

func can_stack_with(other: ItemData) -> bool:
    return stackable and other != null and other.id == id
```

### 무기 정의 (상속)

```gdscript
# res://scripts/resources/weapon_data.gd
class_name WeaponData
extends ItemData

enum DamageType { PHYSICAL, FIRE, ICE, LIGHTNING }

@export_group("전투")
@export var damage: int = 10
@export var damage_type: DamageType = DamageType.PHYSICAL
@export_range(0.1, 5.0, 0.05) var attack_speed: float = 1.0
@export_range(0.5, 10.0, 0.1) var attack_range: float = 2.0
@export_range(0.0, 1.0, 0.01) var crit_chance: float = 0.05
@export_range(1.0, 5.0, 0.1) var crit_multiplier: float = 2.0

@export_group("연출")
@export var swing_sound: AudioStream
@export var hit_effect: PackedScene
@export var trail_color: Color = Color.WHITE

func _init() -> void:
    type = ItemType.WEAPON
    stackable = false
    max_stack = 1

func roll_damage() -> Dictionary:
    var is_crit := randf() < crit_chance
    var dmg := damage
    if is_crit:
        dmg = int(dmg * crit_multiplier)
    return {"damage": dmg, "critical": is_crit, "type": damage_type}
```

### .tres 파일 생성과 사용

에디터: FileSystem에서 우클릭 → `New Resource...` → `WeaponData` 선택 →
`res://resources/weapons/iron_sword.tres`로 저장 → 인스펙터에서 값 편집.

```gdscript
# 코드에서 사용
const IRON_SWORD: WeaponData = preload("res://resources/weapons/iron_sword.tres")

@export var weapon: WeaponData        # 인스펙터에서 드래그로 지정

func attack() -> void:
    if weapon == null:
        return
    var result := weapon.roll_damage()
    target.take_damage(result.damage, result.type)
    if result.critical:
        _show_crit_effect()
```

### 리소스 배열로 데이터베이스 구성

```gdscript
# res://scripts/resources/item_database.gd
class_name ItemDatabase
extends Resource

@export var items: Array[ItemData] = []

var _lookup: Dictionary[StringName, ItemData] = {}

func _init() -> void:
    _rebuild_lookup()

func _rebuild_lookup() -> void:
    _lookup.clear()
    for item in items:
        if item and not item.id.is_empty():
            _lookup[item.id] = item

func get_item(id: StringName) -> ItemData:
    if _lookup.is_empty():
        _rebuild_lookup()
    return _lookup.get(id)
```

### 폴더 스캔으로 자동 등록

수동으로 배열에 넣는 대신 폴더를 스캔한다.

```gdscript
static func load_all_from_dir(path: String) -> Array[ItemData]:
    var result: Array[ItemData] = []
    var dir := DirAccess.open(path)
    if dir == null:
        push_error("폴더를 열 수 없음: %s" % path)
        return result
    dir.list_dir_begin()
    var file_name := dir.get_next()
    while file_name != "":
        if not dir.current_is_dir():
            # 내보낸 빌드에서는 .tres가 .res로 변환될 수 있다
            if file_name.ends_with(".tres") or file_name.ends_with(".res") \
                    or file_name.ends_with(".remap"):
                var clean := file_name.trim_suffix(".remap")
                var res := ResourceLoader.load(path.path_join(clean))
                if res is ItemData:
                    result.append(res)
        file_name = dir.get_next()
    dir.list_dir_end()
    return result
```

**`.remap` 처리가 중요하다.** 내보내기 시 리소스가 변환되면 원본 경로에
`.remap` 파일이 생긴다. 이를 고려하지 않으면 에디터에서는 동작하고
빌드에서는 실패한다.

---

## 3. 설정·정적 데이터를 `.tres` 로 빼기

앞 절이 **개체를 여러 개 정의하는** 리소스(아이템 100종)였다면, 이 절은
**하나짜리 구성값을 데이터로 빼는** 쪽이다. 맵 설정, 카메라 설정, 난이도 프리셋,
스폰 테이블처럼 **게임이 시작될 때 정해져 있고 실행 중에는 변하지 않는 정보**다.

### 두 가지 성격을 구분한다

| | 개체 데이터 | **구성 데이터 (이 절)** |
|---|---|---|
| 예 | 아이템·무기·몬스터 아키타입 | **맵 설정·카메라 설정·난이도 프리셋** |
| 개수 | 수십~수백 개 | **선택지 몇 개** (맵마다 하나) |
| 쓰는 쪽 | 데이터베이스에서 id 로 조회 | **`@export` 로 하나를 끼운다** |
| 바뀌는 시점 | 밸런싱 | **맵을 갈아끼울 때** |
| 흔한 잘못 | 코드에 하드코딩된 배열 | **스크립트의 `const`** |

### 왜 `const` 로 두면 안 되는가

이것이 이 절의 출발점이다. 처음에는 `const` 가 자연스럽다.

```gdscript
# 🛑 맵이 하나뿐일 때는 잘 돌아간다
class_name GameWorld
extends Node3D

const WORLD_SIZE := 4000.0
const CHUNK_SIZE := 250.0
const VIEW_DISTANCE := 1200.0
```

**맵이 둘이 되는 순간 막힌다.** 750m 짜리 투기장을 추가하려면 스크립트를 복제하거나,
`if map_id == "arena"` 분기를 넣거나, 상수를 변수로 바꾸고 초기화 코드를 짜야 한다.
셋 다 맵이 늘어날수록 나빠진다.

`Resource` 로 빼면 **스크립트는 한 줄도 바뀌지 않고 `.tres` 만 늘어난다.**

```
res://resources/maps/plains_4km.tres     ← world_size = 4000
res://resources/maps/arena_750m.tres     ← world_size = 750
res://resources/maps/dungeon_500m.tres   ← 새 맵을 추가해도 코드는 그대로
```

| `const` 를 쓸 때 | `Resource` 로 뺄 때 |
|---|---|
| 값이 **엔진·수학적으로 고정** (`GRAVITY`, `TAU`) | 값이 **선택지** — 맵마다·난이도마다 다르다 |
| 바뀌면 코드도 같이 바뀌어야 한다 | **사람이 인스펙터에서 조절**한다 |
| 하나뿐이고 앞으로도 하나다 | 둘째가 생길 수 있다 |

**밸런싱은 코드 작업이 아니다.** 값을 만지는 사람이 스크립트를 열지 않아도 되게 하는 것이
`Resource` 로 빼는 진짜 이유다.

### 정의 — 맵 설정 리소스

```gdscript
# res://scripts/world_config.gd
class_name WorldConfig
extends Resource
## 맵 하나의 설정. 코드가 아니라 데이터로 둔다.

@export_group("월드 크기")

## 월드 한 변의 길이(m). 좌표 범위는 -world_size/2 ~ +world_size/2 다.
@export var world_size: float = 1000.0:
    set(value):
        world_size = maxf(value, 1.0)
        emit_changed()

## 청크 한 변의 길이(m).
@export var chunk_size: float = 250.0:
    set(value):
        chunk_size = maxf(value, 1.0)
        emit_changed()

@export_group("청크 스트리밍")

## 상주 반경. 1 이면 3×3(자신 + 인접 8).
@export_range(0, 8, 1) var resident_radius: int = 1:
    set(value):
        resident_radius = clampi(value, 0, 8)
        emit_changed()

## 청크 경계 몇 m 전에 다음 청크를 미리 만들지.
@export var preload_margin: float = 50.0:
    set(value):
        preload_margin = maxf(value, 0.0)
        emit_changed()
```

**`@export_group` 으로 인스펙터를 접는다.** 설정 리소스는 프로퍼티가 20개를 넘기 쉬운데,
그룹이 없으면 사람이 값을 찾지 못한다. `@export_group` 은 **다음 그룹 선언까지의 모든
프로퍼티**를 묶으므로 선언 순서가 곧 화면 순서다.

`@export_range` 를 준 것은 인스펙터에 슬라이더가 생기고 **범위를 문서 없이 알 수 있기**
때문이다. 단 인스펙터에서만 강제되므로 코드 대입은 setter 로 따로 막는다.

### 🛑 기본값과 같은 값은 `.tres` 에 저장되지 않는다

**설정 리소스를 쓸 때 가장 먼저 부딪히는 함정이다.** Godot 은 스크립트의 선언 기본값과
같은 프로퍼티를 파일에 쓰지 않는다. **명시적으로 대입해도 마찬가지다.**

엔진에서 확인한 결과(4.7.2) — `world_size` 의 선언 기본값이 `1000.0` 인 리소스를
세 가지 방식으로 저장했다.

```gdscript
# ① 아무 값도 건드리지 않고 저장
var a := WorldConfig.new()
ResourceSaver.save(a, "res://out/a.tres")

# ② 기본값과 "같은 값"을 명시적으로 대입하고 저장
var b := WorldConfig.new()
b.world_size = 1000.0        # 기본값과 동일
ResourceSaver.save(b, "res://out/b.tres")

# ③ 다른 값을 대입하고 저장
var c := WorldConfig.new()
c.world_size = 4000.0
ResourceSaver.save(c, "res://out/c.tres")
```

```ini
; ① 과 ② — 결과가 완전히 같다. world_size 가 아예 없다
[gd_resource type="Resource" script_class="WorldConfig" format=3]
[ext_resource type="Script" path="res://scripts/world_config.gd" id="1_x"]
[resource]
script = ExtResource("1_x")

; ③ — 달라진 것만 기록된다
[resource]
script = ExtResource("1_x")
world_size = 4000.0
```

**그래서 `.tres` 를 열어 보고 "값이 비어 있다"고 놀랄 필요가 없다.**
비어 있다는 것은 **전부 기본값을 쓴다**는 뜻이다. 로드하면 스크립트의 기본값이 들어간다.

여기서 실무적인 결론이 나온다.

> **선언 기본값은 "설정을 끼우지 않았을 때의 안전 폴백"으로 잡는다.**

기본값을 실제 운영 맵과 같게 두면(예: `world_size = 4000.0`) **그 맵의 `.tres` 에는
`world_size` 가 기록되지 않는다.** 파일만 봐서는 4km 인지 알 수 없고, 나중에 스크립트
기본값을 바꾸면 **파일을 건드리지 않았는데 맵 크기가 조용히 바뀐다.**

폴백을 작은 값으로 두면 두 문제가 동시에 풀린다 — 맵 파일에 그 맵의 값이 실제로
기록되고, 설정을 빠뜨렸을 때 무거운 맵이 조용히 만들어지지 않는다.

| 기본값을 어떻게 잡나 | 결과 |
|---|---|
| 🛑 운영 맵과 같게 (`4000.0`) | 그 맵 `.tres` 가 비어 보이고, 기본값을 바꾸면 맵이 따라 바뀐다 |
| ✅ **작고 안전한 폴백** (`1000.0`) | 맵마다 자기 값이 파일에 남고, 설정 누락이 눈에 띈다 |

### 로드 순서 — `_init()` 이 먼저, 그다음 setter

`.tres` 를 로드할 때 엔진이 하는 일을 순서대로 확인했다(4.7.2).

```
① 스크립트를 붙이고 _init() 호출     ← 이때 프로퍼티는 전부 선언 기본값
② 파일에 적힌 프로퍼티를 하나씩 대입  ← setter 를 통해 들어간다
```

두 가지가 따라 나온다.

**`_init()` 에서 다른 프로퍼티 값을 읽으면 안 된다.** 아직 파일 값이 들어오기 전이라
기본값만 보인다. 파생값은 `_init()` 에서 계산해 캐시하지 말고 **메서드로 그때그때
계산**한다(아래 "파생값" 참고).

**setter 는 로드할 때도 실행된다.** 이것이 setter 에 방어 코드를 두는 근거다.

### setter 가 손으로 고친 `.tres` 를 막아 준다

`.tres` 는 사람이 열어 고칠 수 있는 텍스트 파일이다. 잘못된 값이 들어가면 어떻게 되는지
확인했다 — `hp` 의 setter 가 `clampi(value, 0, 100)` 을 하는 리소스에서:

```ini
; 파일을 손으로 고쳐 범위 밖 값을 넣었다
hp = 99999
```

```
로드 결과 → hp = 100     ← setter 가 그 자리에서 잘랐다
```

**setter 가 없었다면 `99999` 가 그대로 들어간다.** 설정 리소스에 `maxf`·`clampi` 를
두는 것은 인스펙터 실수만 막는 게 아니라 **파일 손편집·외부 도구 생성·구버전 파일까지
막는다.**

### `emit_changed()` — 값이 바뀐 것을 알리기

`Resource` 에는 내장 시그널 `changed` 가 있다(엔진 확인). 값이 바뀌면 이걸 쏴서
쓰는 쪽이 다시 그리게 한다.

> 🛑 **`@export var` 에 값을 대입한다고 `changed` 가 저절로 나가지 않는다.**
> 확인 결과 setter 안에서 **`emit_changed()` 를 직접 불러야만** 발신된다.

```gdscript
@export var world_size: float = 1000.0:
    set(value):
        world_size = maxf(value, 1.0)
        emit_changed()        # ← 이 줄이 없으면 아무도 모른다
```

쓰는 쪽:

```gdscript
@export var config: WorldConfig:
    set(value):
        if config and config.changed.is_connected(_rebuild):
            config.changed.disconnect(_rebuild)    # 이전 것을 반드시 끊는다
        config = value
        if config:
            config.changed.connect(_rebuild)
        _rebuild()

func _rebuild() -> void:
    ...  # 월드를 다시 만든다
```

**이전 리소스의 연결을 끊는 것을 잊지 않는다.** 설정을 갈아끼울 때마다 연결이 쌓이면
낡은 리소스가 여전히 월드를 다시 그리게 만든다.

`@tool` 을 붙이면 **에디터에서 값을 만지는 즉시 뷰포트가 갱신**된다. 설정 리소스의
효과를 눈으로 보면서 조절할 수 있어 값을 정하는 속도가 크게 달라진다.

### `validate()` — 설정이 성립하는지 스스로 검사한다

설정 리소스는 **사람이 값을 잘못 넣는 것이 정상적인 사용 방식**이다. 그래서 값을 쓰는
쪽에서 `assert` 로 터뜨리는 대신, 리소스가 자기 문제를 목록으로 돌려주게 한다.

```gdscript
## 설정이 성립하는지 검사한다. 빈 배열이면 문제 없음.
func validate() -> PackedStringArray:
    var problems := PackedStringArray()

    var count := world_size / chunk_size
    if absf(count - round(count)) > 0.001:
        problems.append(
            "world_size(%.1f) 가 chunk_size(%.1f) 로 나누어떨어지지 않는다"
            % [world_size, chunk_size])

    if view_distance > world_size:
        problems.append(
            "view_distance(%.0f m) 가 월드(%.0f m)보다 넓다 — 맵 밖이 보인다"
            % [view_distance, world_size])

    return problems
```

**`assert` 와 다른 점**은 세 가지다.

| | `assert` | **`validate()`** |
|---|---|---|
| 릴리즈 빌드 | **통째로 제거된다** | 그대로 동작한다 |
| 문제가 여럿일 때 | 첫 번째에서 멈춘다 | **전부 모아서 보여준다** |
| 부르는 시점 | 값을 쓰는 순간 | **원할 때** — 에디터 경고·빌드 검사·기동 시 |

`_get_configuration_warnings()` 와 묶으면 **에디터 씬 트리에 노란 경고 삼각형**으로
뜬다([editor-plugin.md](editor-plugin.md) 참고).

```gdscript
@tool
extends Node3D

@export var config: WorldConfig

func _get_configuration_warnings() -> PackedStringArray:
    if config == null:
        return PackedStringArray(["WorldConfig 가 비어 있다"])
    return config.validate()
```

### 파생값은 저장하지 말고 메서드로 계산한다

`world_size / chunk_size` 같은 값은 **프로퍼티로 두지 않는다.** 저장되면 원본과 어긋날
수 있고, `.tres` 에도 중복 기록된다.

```gdscript
# ✅ 메서드 — 항상 현재 값에서 계산된다
func chunk_count() -> int:
    return int(round(world_size / chunk_size))

func half_extent() -> float:
    return world_size * 0.5

func resident_capacity() -> int:
    var side := resident_radius * 2 + 1
    return side * side        # 3×3 = 9
```

```gdscript
# 🛑 @export 로 두면 — 저장되고, 원본이 바뀌어도 안 따라오고, 사람이 고칠 수 있다
@export var chunk_count: int = 16
```

**`Resource` 에 메서드를 두는 것은 정상이다.** 데이터만 담는 그릇이 아니라
"데이터 + 그 데이터에 대한 계산"을 함께 두면 쓰는 쪽이 단순해진다.

### 쓰는 쪽 — `@export` 로 끼운다

```gdscript
class_name GameWorld
extends Node3D

## 인스펙터에서 .tres 를 드래그해 끼운다. 코드는 어느 맵인지 모른다.
@export var config: WorldConfig

func _ready() -> void:
    if config == null:
        push_error("WorldConfig 가 비어 있다")
        return
    for problem in config.validate():
        push_warning(problem)
    _build()

func _build() -> void:
    var half := config.half_extent()
    for z in config.chunk_count():
        for x in config.chunk_count():
            ...
```

**코드 어디에도 `4000` 이나 `250` 이 없다.** 이것이 목표 상태다.

> ⚠️ **`@export` 와 `@onready` 를 함께 쓰지 않는다** — 인스펙터 값이 `_init()` 시점에
> 신뢰할 수 없어진다. 스킬 SKILL.md 의 절대 규칙이다.

### 🛑 로드된 설정은 공유된다 — 런타임에 고치지 않는다

§1 의 참조 공유 규칙이 설정 리소스에서 특히 위험하게 나타난다. 확인한 동작:

```gdscript
var a := load("res://resources/maps/plains_4km.tres")
var b := load("res://resources/maps/plains_4km.tres")
print(a == b)          # true — 같은 객체다

a.world_size = 12345.0
print(b.world_size)    # 12345.0 — b 도 바뀐다
```

**게다가 에디터에서는 그 변경이 `.tres` 파일에 저장될 수 있다.** 런타임에 설정값을
건드려야 한다면 반드시 복제한다.

```gdscript
var runtime := config.duplicate()   # resource_path 가 빈 문자열이 된다 (확인)
runtime.world_size *= 2.0           # 원본 .tres 는 안전하다
```

`duplicate(true)` 는 **배열·딕셔너리 안의 하위 리소스까지는 복제하지 않는다.**
설정 안에 리소스 배열이 있다면 `duplicate_deep()` 이 필요하다 → §1 과
[gdscript.md](gdscript.md) 의 복사 3단계.

### 코드로 `.tres` 를 찍어낸다 (에디터 없이)

이 프로젝트는 에디터를 열지 않고 작업하는 경우가 많다
([headless-workflow.md](headless-workflow.md)). `.tres` 를 손으로 쓰면 리소스 ID·타입
표기를 틀려 로드가 깨지므로, **`ResourceSaver` 가 직렬화하게 둔다.**

```gdscript
# res://tools/build_resources.gd
extends SceneTree
## godot --headless --path <프로젝트> --script res://tools/build_resources.gd

func _initialize() -> void:
    _save(_plains_4km(), "res://resources/maps/plains_4km.tres")
    _save(_arena_750m(), "res://resources/maps/arena_750m.tres")
    quit()

func _save(resource: Resource, path: String) -> void:
    DirAccess.make_dir_recursive_absolute(path.get_base_dir())
    for problem in resource.call("validate"):
        printerr("  ⚠ %s: %s" % [path.get_file(), problem])
    var error := ResourceSaver.save(resource, path)
    if error != OK:
        printerr("저장 실패 %s (%d)" % [path, error])
        return
    print("  저장 %s" % path)

func _plains_4km() -> WorldConfig:
    var config := WorldConfig.new()
    config.resource_name = "평원 4km"
    config.world_size = 4000.0
    config.chunk_size = 250.0
    config.view_distance = 1200.0
    return config

func _arena_750m() -> WorldConfig:
    var config := WorldConfig.new()
    config.resource_name = "투기장 750m"
    config.world_size = 750.0
    config.view_distance = 400.0
    return config
```

**이 스크립트는 처음 한 벌을 찍어내기 위한 것이다.** 이후 값 조정은
**에디터 인스펙터에서** 한다 — `.tres` 는 사람이 편집하는 것이 정상적인 사용 방식이다.

세 가지를 확인해 둔다.

| 항목 | 확인된 동작 (4.7.2) |
|---|---|
| `ResourceSaver.save()` 반환 | 성공 `OK`(0). 폴더가 없으면 **`ERR_CANT_OPEN`(19)** — 그래서 `make_dir_recursive_absolute` 를 먼저 부른다 |
| `resource_name` | **저장된다.** `.tres` 에서 `script` 줄보다 **위**에 온다 |
| 새 `class_name` | 헤드리스에서 스크립트를 새로 만들면 **`godot --headless --import` 를 한 번 돌려야** `class_name` 이 인식된다. 안 그러면 `Identifier "X" not declared` 로 파스 에러가 난다 |

### `.tres` · `.res` · `.tscn` — 무엇을 쓰나

| 확장자 | 내용 | 쓰는 곳 |
|---|---|---|
| **`.tres`** | 텍스트 리소스 | **설정·데이터 전부.** git diff 가 읽히고 손으로 고칠 수 있다 |
| `.res` | 이진 리소스 | 사람이 안 보는 대용량 데이터 |
| `.tscn` | 텍스트 씬 (`PackedScene`) | 노드 트리 — 설정 데이터가 아니다 |

**`.res` 가 항상 작지 않다.** 같은 리소스를 두 형식으로 저장해 재 봤다(4.7.2).

```
작은 설정 리소스      .tres   208 B  /  .res   380 B   ← 이진이 더 크다
문자열 2000개 배열    .tres 24,200 B  /  .res 34,345 B  ← 여전히 더 크다
```

이진 포맷은 타입 태그·정렬 패딩을 붙이므로 **작은 데이터나 문자열에서는 오히려 커진다.**
`.res` 가 유리한 것은 파싱 속도이며, 설정 리소스 정도의 크기에서는 **차이가 의미 없다.**

> **설정·데이터는 `.tres` 를 쓴다.** git 에서 무엇이 바뀌었는지 보이는 것이
> 몇백 바이트보다 훨씬 가치 있다.

### 라리엔 3D 에서

카메라·청크·조명 값은 [`game` 스킬 SSOT](../../game/references/SSOT.md) 가 정한다.
설정 리소스에 그 값을 담을 때는 **인스펙터에 노출하되 "바꾸라는 뜻이 아니다"를 문서 주석과
`validate()` 로 명시한다.**

```gdscript
## 피치(상하). SSOT §1 = −45° 고정.
@export var pitch_degrees: float = -45.0

func validate() -> PackedStringArray:
    var problems := PackedStringArray()
    if not is_equal_approx(pitch_degrees, -45.0):
        problems.append("pitch_degrees 가 %.1f° 다 — SSOT §1 은 −45° 고정이다" % pitch_degrees)
    if zoom_max_ratio > 2.0:
        problems.append(
            "zoom_max_ratio 가 %.2f 다 — 서버 AOI 계약(SSOT §6)에 묶여 있다" % zoom_max_ratio)
    return problems
```

**값을 한곳에서 보이게 하는 것**과 **그 값을 바꿔도 되는 것**은 다르다.
SSOT 값을 리소스에 담는 목적은 전자다.

---
## 4. 로딩 — load / preload / 스레드 로딩

| 방식 | 시점 | 특징 |
|------|------|------|
| `preload()` | 컴파일 타임 | 스크립트 로드 시 함께 로드. `const` 가능. 경로가 상수여야 함 |
| `load()` | 런타임 | 호출 시점에 로드. 첫 호출은 느리고 이후는 캐시 |
| `ResourceLoader.load()` | 런타임 | `load()`와 동일하되 옵션 지정 가능 |
| `load_threaded_request()` | 백그라운드 | 프레임 정지 없음. 큰 씬·모델에 필수 |

```gdscript
# preload — 이 스크립트가 로드될 때 함께 로드된다
const BULLET: PackedScene = preload("res://scenes/bullet.tscn")

# load — 필요할 때 로드
var boss := load("res://scenes/boss.tscn") as PackedScene

# 캐시 무시하고 다시 로드
var fresh := ResourceLoader.load(path, "", ResourceLoader.CACHE_MODE_IGNORE)

# 존재 확인
if ResourceLoader.exists("res://scenes/optional.tscn"):
    pass

# 의존성 조회
var deps := ResourceLoader.get_dependencies("res://scenes/level.tscn")
```

### 스레드 로딩 (로딩 화면)

```gdscript
# res://autoload/asset_loader.gd
extends Node

signal progress(ratio: float)
signal finished(resource: Resource)
signal failed(path: String)

var _path: String = ""
var _progress_array: Array = []

func request(path: String, type_hint: String = "") -> void:
    if not _path.is_empty():
        push_warning("이미 로딩 중: %s" % _path)
        return
    var err := ResourceLoader.load_threaded_request(
        path, type_hint, true, ResourceLoader.CACHE_MODE_REUSE
    )
    if err != OK:
        failed.emit(path)
        return
    _path = path
    set_process(true)

func _process(_delta: float) -> void:
    if _path.is_empty():
        return
    var status := ResourceLoader.load_threaded_get_status(_path, _progress_array)
    match status:
        ResourceLoader.THREAD_LOAD_IN_PROGRESS:
            progress.emit(float(_progress_array[0]))
        ResourceLoader.THREAD_LOAD_LOADED:
            var res := ResourceLoader.load_threaded_get(_path)
            var done := _path
            _path = ""
            set_process(false)
            progress.emit(1.0)
            finished.emit(res)
        ResourceLoader.THREAD_LOAD_FAILED, \
        ResourceLoader.THREAD_LOAD_INVALID_RESOURCE:
            var bad := _path
            _path = ""
            set_process(false)
            failed.emit(bad)
```

**`use_sub_threads = true`(세 번째 인자)** 로 두면 하위 리소스도 병렬 로드되어 빠르지만,
CPU 코어를 많이 쓰므로 로딩 중 다른 처리가 느려질 수 있다.

### 저장

```gdscript
# 리소스 저장
var err := ResourceSaver.save(my_resource, "res://resources/data.tres")

# 플래그 지정
ResourceSaver.save(res, path,
    ResourceSaver.FLAG_COMPRESS | ResourceSaver.FLAG_BUNDLE_RESOURCES)
```

| 플래그 | 의미 |
|--------|------|
| `FLAG_RELATIVE_PATHS` | 상대 경로로 저장 |
| `FLAG_BUNDLE_RESOURCES` | 하위 리소스를 파일 안에 포함 |
| `FLAG_CHANGE_PATH` | 저장 후 리소스의 경로를 갱신 |
| `FLAG_COMPRESS` | 압축 |
| `FLAG_REPLACE_SUBRESOURCE_PATHS` | 하위 리소스 경로 교체 |

**주의**: `res://`는 내보낸 빌드에서 **읽기 전용**이다. 런타임 저장은 `user://`에만 가능하다.

---

## 5. ResourceUID와 .import 시스템

### .import 파일

Godot은 원본 에셋(`.png`, `.glb`, `.wav`)을 직접 쓰지 않는다.
임포트 과정을 거쳐 `.godot/imported/`에 엔진 최적화 포맷으로 변환하고,
그 설정을 원본 옆의 `.import` 파일에 저장한다.

```ini
# icon.svg.import
[remap]

importer="texture"
type="CompressedTexture2D"
uid="uid://c3v8x2mqk1nrt"
path="res://.godot/imported/icon.svg-218a8f2b3041327d8a5756f3a245f83b.ctex"

[deps]

source_file="res://icon.svg"
dest_files=["res://.godot/imported/icon.svg-....ctex"]

[params]

compress/mode=0
mipmaps/generate=false
```

**Git 관리 규칙**

- `.import` 파일은 **커밋한다** (임포트 설정이 팀원 간 동일해야 함)
- `.godot/` 폴더는 **커밋하지 않는다** (생성물, 용량 큼)

### ResourceUID

`uid://` 형식의 고유 식별자다. 파일을 옮기거나 이름을 바꿔도 참조가 유지된다.

```gdscript
# 4.x의 씬 파일은 UID로 참조한다
# [ext_resource type="PackedScene" uid="uid://bx8k2v" path="res://scenes/enemy.tscn" id="1"]

# 코드 API
var id := ResourceUID.text_to_id("uid://c3v8x2mqk1nrt")
var path := ResourceUID.get_id_path(id)
var exists := ResourceUID.has_id(id)

# UID로 직접 로드도 가능
var scene := load("uid://c3v8x2mqk1nrt")
```

**`.gd.uid` 파일(4.4+)**: 스크립트에도 UID가 부여된다. 이 파일도 커밋한다.

### 임포트 재실행

```bash
# 헤드리스로 전체 재임포트 (CI에서 유용)
godot --headless --import --path /path/to/project --quit
```

에디터에서는 FileSystem 독에서 파일 우클릭 → `Reimport`.

### 여러 파일의 임포트 설정을 한 번에 바꾸기 (4.6+)

같은 임포트 설정을 여러 파일에 적용하는 **배치 편집**이 Import 독에 (다시) 들어왔다.

1. **FileSystem 독에서 파일을 여러 개 선택**한다 (`Shift`/`Cmd`+클릭)
2. **Import 독**에 공통 속성이 뜬다. **어느 속성을 편집할지 체크**해서 고른다
3. 값을 정하고 **`Reimport`를 한 번 누르면** 선택한 파일 전체에 적용된다

체크한 속성만 덮어쓰므로, 파일마다 다르게 설정해 둔 나머지 값은 보존된다.

**실제로 쓰는 곳** — 텍스처 수십 장의 압축 모드나 Mipmaps를 한꺼번에 바꿀 때,
glTF 여러 개의 애니메이션 임포트 옵션을 통일할 때. 이전에는 파일을 하나씩 눌러
같은 값을 반복 입력해야 했다.

**주의**: 서로 종류가 다른 파일(텍스처 + 모델)을 함께 선택하면 공통 속성만 보인다.
같은 종류끼리 묶어서 처리하는 편이 실수가 적다.

> 이 작업은 **에디터에서 사람이 한다.** `.import` 파일은 Claude 수정 금지 대상이다
> (→ CLAUDE.md). Claude는 어떤 속성을 어떤 값으로 바꿔야 하는지만 알려준다.

---

## 6. 3D 모델 임포트 (glTF / .blend)

### 지원 포맷

| 포맷 | 권장도 | 비고 |
|------|--------|------|
| `.glb` / `.gltf` | **최우선** | 업계 표준. PBR 머티리얼, 애니메이션, 스킨 완전 지원 |
| `.blend` | 권장 | Blender 설치 시 자동 변환(내부적으로 glTF로) |
| `.fbx` | 조건부 | FBX2glTF 변환기 필요. 라이선스 이슈 |
| `.dae`, `.obj` | 비권장 | 기능 제한 |

**`.blend` 직접 임포트 설정**: `Editor Settings → FileSystem → Import → Blender → Blender Path`에
Blender 실행 파일 경로를 지정하면 `.blend` 파일을 프로젝트에 그대로 넣을 수 있다.

### 씬 임포트 옵션 (Import 탭)

| 그룹 | 옵션 | 권장값 | 이유 |
|------|------|--------|------|
| Nodes | `Root Type` | `Node3D` | 필요시 `CharacterBody3D` 등 |
| | `Root Name` | 모델명 | |
| | `Apply Root Scale` | On | |
| | `Root Scale` | `1.0` | Blender에서 미터 단위로 작업 |
| | `Import as Skeleton Bones` | Off | |
| Meshes | `Ensure Tangents` | **On** | 노멀맵 필수 |
| | `Generate LODs` | **On** | 자동 LOD |
| | `Create Shadow Meshes` | **On** | 그림자용 저폴리 |
| | `Light Baking` | `Static Lightmaps` | UV2 자동 생성 (Mobile 필수) |
| | `Lightmap Texel Size` | `0.2` | 라이트맵 밀도 |
| | `Force Disable Compression` | Off | |
| Skins | `Use Named Skins` | On | |
| Animation | `Import` | On | |
| | `FPS` | `30` | |
| | `Trimming` | On | |
| | `Remove Immutable Tracks` | On | 용량 절감 |
| | `Import Rest as Reset` | On | RESET 애니메이션 자동 생성 |
| | `Naming Version` | `2` (기본) | |

### 콜리전 자동 생성 (메시 이름 접미사)

Blender에서 오브젝트 이름 끝에 붙이면 임포트 시 자동 처리된다.

| 접미사 | 결과 |
|--------|------|
| `-col` | trimesh `StaticBody3D` 자식 생성, 시각 메시도 유지 |
| `-colonly` | trimesh 콜리전만, 시각 메시 제거 |
| `-convcol` | 볼록 다면체 콜리전 + 시각 메시 |
| `-convcolonly` | 볼록 콜리전만 |
| `-navmesh` | `NavigationRegion3D`로 변환 |
| `-occ` | `OccluderInstance3D` 생성 |
| `-occonly` | 오클루더만 |
| `-vehicle` | `VehicleBody3D` |
| `-vehwheel` | `VehicleWheel3D` |
| `-rigid` | `RigidBody3D` |
| `-noimp` | 임포트에서 제외 |

예: `Wall_01-colonly` → 벽 콜리전만 생성.

### 노드별 개별 설정 (Advanced Import)

Import 탭의 `Advanced...` 버튼을 누르면 씬 트리가 표시되고,
각 노드/메시/애니메이션별로 설정할 수 있다.

- **Save to File**: 메시·머티리얼·애니메이션을 별도 리소스로 추출.
  머티리얼을 추출해야 에디터에서 수정한 값이 재임포트 시 유지된다.
- **Physics**: 노드별 콜리전 생성 (Trimesh / Convex / Simplified Convex / Box / Sphere / Capsule / Cylinder)
- **Animation**: 루프 모드, 슬라이스

### 임포트 후처리 스크립트

```gdscript
# res://tools/level_post_import.gd
@tool
extends EditorScenePostImport

func _post_import(scene: Node) -> Object:
    _process_node(scene)
    return scene

func _process_node(node: Node) -> void:
    if node is MeshInstance3D:
        var mi := node as MeshInstance3D
        mi.gi_mode = GeometryInstance3D.GI_MODE_STATIC
        mi.lod_bias = 1.0
        # 이름 규칙으로 그림자 끄기
        if mi.name.begins_with("NoShadow_"):
            mi.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
    elif node is StaticBody3D:
        (node as StaticBody3D).collision_layer = 1
        (node as StaticBody3D).collision_mask = 0
    for child in node.get_children():
        _process_node(child)
```

Import 탭의 `Import Script`에 이 파일을 지정한다.
**매번 손으로 하던 설정을 자동화하는 것이 목적이다.**

### Blender 작업 규칙 (임포트 문제 예방)

1. **Apply Transform** — 오브젝트 모드에서 `Ctrl+A → All Transforms`.
   적용하지 않으면 Godot에서 스케일이 이상해진다.
2. **모델의 정면을 -Y(Blender)로** — Blender의 -Y가 Godot의 -Z(forward)에 대응한다.
3. **원점을 발밑에** — 캐릭터는 원점이 발 위치여야 지면 배치가 쉽다.
4. **머티리얼 이름을 명확히** — Godot에서 그 이름으로 추출된다.
5. **삼각화** — Godot이 자동으로 하지만, 미리 하면 결과가 예측 가능하다.
6. **본 이름을 표준화** — 리타게팅을 쓰려면 `SkeletonProfileHumanoid` 이름 규칙을 따른다.

---

## 7. 텍스처 임포트와 압축

### 압축 모드

| 모드 | VRAM | 품질 | 용도 |
|------|------|------|------|
| `Lossless` (PNG) | 큼 | 무손실 | UI 아이콘, 작은 텍스처 |
| `Lossy` (WebP) | 중간 | 손실 | 디스크 용량이 중요할 때 |
| **`VRAM Compressed`** | **작음** | 손실 | **3D 텍스처 기본값** |
| `VRAM Uncompressed` | 매우 큼 | 무손실 | 데이터 텍스처 (높이맵 등) |
| `Basis Universal` | 작음 | 손실 | 크로스 플랫폼 초압축 |

**3D 텍스처는 반드시 `VRAM Compressed`를 쓴다.**
GPU가 압축된 상태로 직접 읽으므로 VRAM 사용량이 1/4 ~ 1/6로 줄고 대역폭도 절약된다.

### 플랫폼별 실제 포맷

| 플랫폼 | 포맷 |
|--------|------|
| 데스크톱 (PC/Mac) | S3TC/BPTC (DXT, BC7) |
| Android/iOS | ETC2/ASTC |
| 웹 | ETC2 또는 S3TC |

Godot이 자동으로 대상 플랫폼에 맞는 포맷을 생성한다.
`Project Settings → Rendering → Textures → VRAM Compression`에서
어떤 포맷을 생성할지 지정한다. **Android 대상이면 `Import ETC2 ASTC`를 켠다.**

### 임포트 옵션

| 옵션 | 권장값 | 설명 |
|------|--------|------|
| `Compress/Mode` | `VRAM Compressed` | 3D 텍스처 |
| `Compress/High Quality` | Off | On이면 BPTC(BC7) — 품질↑ 용량↑ |
| `Compress/HDR Compression` | `Opaque Only` | |
| `Compress/Normal Map` | `Detect` 또는 `Enable` | 노멀맵 전용 압축 |
| `Compress/Channel Pack` | `sRGB Friendly` | ORM 텍스처는 `Optimized` |
| `Mipmaps/Generate` | **On** | 3D는 필수. 없으면 원거리에서 심하게 반짝임 |
| `Roughness/Mode` | 텍스처 용도에 맞게 | 노멀맵 기반 러프니스 보정 |
| `Process/Fix Alpha Border` | On | 알파 가장자리 검은 테두리 방지 |
| `Process/Premult Alpha` | Off | |
| `Process/Normal Map Invert Y` | 상황에 따라 | DirectX 규약 노멀맵이면 On |
| `Detect 3D/Compress To` | `VRAM Compressed` | 2D 텍스처가 3D에서 쓰이면 자동 전환 |

### 텍스처 크기 지침 (모바일)

| 용도 | 권장 크기 |
|------|----------|
| 캐릭터 albedo | 1024×1024 또는 2048×2048 |
| 소품 | 512×512 |
| 지형 타일 | 1024×1024 |
| UI 아이콘 | 원본 크기, Lossless |
| 스카이박스 | 2048×1024 (파노라마) |

**2의 거듭제곱 크기를 쓴다.** 비-2의 거듭제곱은 일부 압축 포맷에서 지원되지 않거나
밉맵 생성이 부정확하다.

### 텍스처 채널 패킹 (ORM)

Occlusion(R) / Roughness(G) / Metallic(B)을 한 텍스처에 담으면
텍스처 3장이 1장이 된다. glTF 표준 방식이며 `ORMMaterial3D`가 이를 직접 지원한다.

```gdscript
var mat := ORMMaterial3D.new()
mat.albedo_texture = albedo
mat.orm_texture = orm         # R=AO, G=Roughness, B=Metallic
mat.normal_texture = normal
mat.normal_enabled = true
```

---

## 8. 오디오 임포트

| 포맷 | 용도 | 특징 |
|------|------|------|
| `.wav` | **효과음** | 무압축, 즉시 재생, CPU 부하 없음 |
| `.ogg` | **BGM** | Vorbis 압축, 용량 작음, 디코딩 CPU 사용 |
| `.mp3` | BGM | 지원되나 ogg 권장 |

### WAV 임포트 옵션

| 옵션 | 권장 | 설명 |
|------|------|------|
| `Force/8 Bit` | Off | |
| `Force/Mono` | **On (3D 효과음)** | 3D 위치 오디오는 모노여야 정상 작동 |
| `Force/Max Rate` | On, `22050` (모바일) | 샘플레이트 제한으로 용량 절감 |
| `Edit/Trim` | On | 앞뒤 무음 제거 |
| `Edit/Normalize` | 상황에 따라 | |
| `Edit/Loop Mode` | `Disabled` (효과음) | |
| `Compress/Mode` | `QOA` 또는 `Disabled` | QOA(4.3+)는 용량/품질 균형이 좋음 |

**3D 오디오는 반드시 모노다.** 스테레오 파일을 `AudioStreamPlayer3D`에 쓰면
공간 위치 계산이 무시되거나 부정확해진다.

### OGG 임포트

```
Loop         : BGM이면 On
Loop Offset  : 인트로 후 루프 시작점(초)
BPM / Beat Count / Bar Beats : 인터랙티브 뮤직 동기화용
```

---

## 9. 세이브 파일 (user://)

### user:// 실제 경로

| 플랫폼 | 경로 |
|--------|------|
| Windows | `%APPDATA%\Godot\app_userdata\<프로젝트명>\` |
| macOS | `~/Library/Application Support/Godot/app_userdata/<프로젝트명>/` |
| Linux | `~/.local/share/godot/app_userdata/<프로젝트명>/` |
| Android | 앱 내부 저장소 |

`application/config/use_custom_user_dir=true`로 설정하면 `Godot/app_userdata` 대신
직접 지정한 폴더를 쓴다.

```gdscript
print(OS.get_user_data_dir())
print(ProjectSettings.globalize_path("user://save.json"))
```

### JSON 세이브 (권장 — 디버깅 쉬움)

```gdscript
# res://autoload/save_manager.gd
extends Node

const SAVE_DIR := "user://saves/"
const SAVE_VERSION := 2

func _ready() -> void:
    DirAccess.make_dir_recursive_absolute(SAVE_DIR)

func save_game(slot: int) -> bool:
    var data := {
        "version": SAVE_VERSION,
        "timestamp": Time.get_unix_time_from_system(),
        "play_time": GameState.play_time,
        "player": {
            "level": GameState.player_level,
            "exp": GameState.player_exp,
            "health": GameState.player_health,
            "position": _v3_to_array(GameState.player_position),
            "current_scene": GameState.current_scene_path,
        },
        "inventory": _serialize_inventory(),
        "flags": GameState.story_flags,
    }

    var path := SAVE_DIR + "slot_%d.json" % slot
    var file := FileAccess.open(path, FileAccess.WRITE)
    if file == null:
        push_error("세이브 실패 (%d): %s" % [FileAccess.get_open_error(), path])
        return false
    file.store_string(JSON.stringify(data, "\t"))
    file.close()
    return true

func load_game(slot: int) -> bool:
    var path := SAVE_DIR + "slot_%d.json" % slot
    if not FileAccess.file_exists(path):
        return false

    var file := FileAccess.open(path, FileAccess.READ)
    if file == null:
        push_error("세이브 파일 열기 실패: %s" % path)
        return false
    var text := file.get_as_text()
    file.close()

    var json := JSON.new()
    if json.parse(text) != OK:
        push_error("JSON 파싱 실패 (%d행): %s" % [json.get_error_line(), json.get_error_message()])
        return false

    var data: Dictionary = json.data
    # 버전 마이그레이션 — 구버전 세이브를 버리지 않는다
    data = _migrate(data)

    GameState.player_level = int(data.player.level)
    GameState.player_exp = int(data.player.exp)
    GameState.player_position = _array_to_v3(data.player.position)
    GameState.story_flags = data.get("flags", {})
    _deserialize_inventory(data.get("inventory", []))
    return true

func _migrate(data: Dictionary) -> Dictionary:
    var v := int(data.get("version", 1))
    if v < 2:
        # v1에는 play_time이 없었다
        data["play_time"] = 0.0
        data["version"] = 2
    return data

func _v3_to_array(v: Vector3) -> Array:
    return [v.x, v.y, v.z]

func _array_to_v3(a: Array) -> Vector3:
    return Vector3(a[0], a[1], a[2]) if a.size() >= 3 else Vector3.ZERO

func _serialize_inventory() -> Array:
    var out: Array = []
    for entry in GameState.inventory:
        out.append({"id": String(entry.item.id), "count": entry.count})
    return out

func _deserialize_inventory(arr: Array) -> void:
    GameState.inventory.clear()
    for e in arr:
        var item := ItemDB.get_item(StringName(e.id))
        if item:
            GameState.inventory.append({"item": item, "count": int(e.count)})

func list_saves() -> Array[Dictionary]:
    var result: Array[Dictionary] = []
    var dir := DirAccess.open(SAVE_DIR)
    if dir == null:
        return result
    for f in dir.get_files():
        if not f.ends_with(".json"):
            continue
        var file := FileAccess.open(SAVE_DIR + f, FileAccess.READ)
        if file == null:
            continue
        var json := JSON.new()
        if json.parse(file.get_as_text()) == OK:
            result.append({"file": f, "data": json.data})
        file.close()
    return result

func delete_save(slot: int) -> void:
    DirAccess.remove_absolute(SAVE_DIR + "slot_%d.json" % slot)
```

### JSON 직렬화 주의사항

- `JSON.stringify()`는 `Vector3`, `Color` 등 Godot 타입을 그대로 저장하지 못한다.
  배열이나 딕셔너리로 변환해야 한다.
- **모든 숫자가 `float`로 파싱된다.** `int(data.level)`로 명시적 변환이 필요하다.
- 노드나 리소스 객체를 직접 저장하지 말고, **ID를 저장하고 로드 시 조회**한다.

### 이진 저장 (빠르고 작지만 사람이 못 읽음)

```gdscript
# store_var는 Godot 타입을 그대로 저장한다
var file := FileAccess.open("user://save.dat", FileAccess.WRITE)
file.store_var(data, true)      # true = 객체 포함 허용
file.close()

var read := FileAccess.open("user://save.dat", FileAccess.READ)
var loaded = read.get_var(true)
read.close()
```

**보안 경고**: `get_var(true)`는 임의 객체를 역직렬화하므로 신뢰할 수 없는
파일에 사용하면 코드 실행 취약점이 된다. 세이브 파일은 로컬이므로 대체로 안전하지만,
네트워크로 받은 데이터에는 절대 쓰지 않는다.

### 암호화 저장

```gdscript
const KEY := "이 문자열을 실제 키로 교체"

func save_encrypted(data: Dictionary) -> void:
    var file := FileAccess.open_encrypted_with_pass(
        "user://save.enc", FileAccess.WRITE, KEY
    )
    if file == null:
        return
    file.store_string(JSON.stringify(data))
    file.close()

func load_encrypted() -> Dictionary:
    if not FileAccess.file_exists("user://save.enc"):
        return {}
    var file := FileAccess.open_encrypted_with_pass(
        "user://save.enc", FileAccess.READ, KEY
    )
    if file == null:
        return {}
    var json := JSON.new()
    var ok := json.parse(file.get_as_text()) == OK
    file.close()
    return json.data if ok else {}
```

암호화는 캐주얼한 변조를 막을 뿐이다. 키가 바이너리에 포함되므로
결정적인 보호는 되지 않는다. 온라인 게임이라면 서버 검증이 필요하다.

---

## 10. 설정 파일 (ConfigFile)

INI 형식으로 사람이 읽고 편집할 수 있다. 게임 설정에 적합하다.

```gdscript
# res://autoload/settings.gd
extends Node

const PATH := "user://settings.cfg"

var master_volume: float = 1.0
var music_volume: float = 0.8
var sfx_volume: float = 1.0
var fullscreen: bool = false
var vsync: bool = true
var mouse_sensitivity: float = 1.0
var shadow_quality: int = 1
var language: String = "ko"

func _ready() -> void:
    load_settings()
    apply_all()

func save_settings() -> void:
    var cfg := ConfigFile.new()
    cfg.set_value("audio", "master", master_volume)
    cfg.set_value("audio", "music", music_volume)
    cfg.set_value("audio", "sfx", sfx_volume)
    cfg.set_value("video", "fullscreen", fullscreen)
    cfg.set_value("video", "vsync", vsync)
    cfg.set_value("video", "shadow_quality", shadow_quality)
    cfg.set_value("gameplay", "mouse_sensitivity", mouse_sensitivity)
    cfg.set_value("gameplay", "language", language)
    cfg.save(PATH)

func load_settings() -> void:
    var cfg := ConfigFile.new()
    if cfg.load(PATH) != OK:
        return                       # 파일이 없으면 기본값 유지
    master_volume = cfg.get_value("audio", "master", master_volume)
    music_volume = cfg.get_value("audio", "music", music_volume)
    sfx_volume = cfg.get_value("audio", "sfx", sfx_volume)
    fullscreen = cfg.get_value("video", "fullscreen", fullscreen)
    vsync = cfg.get_value("video", "vsync", vsync)
    shadow_quality = cfg.get_value("video", "shadow_quality", shadow_quality)
    mouse_sensitivity = cfg.get_value("gameplay", "mouse_sensitivity", mouse_sensitivity)
    language = cfg.get_value("gameplay", "language", language)

func apply_all() -> void:
    _apply_audio()
    _apply_video()
    TranslationServer.set_locale(language)

func _apply_audio() -> void:
    _set_bus_volume("Master", master_volume)
    _set_bus_volume("Music", music_volume)
    _set_bus_volume("SFX", sfx_volume)

func _set_bus_volume(bus_name: String, linear: float) -> void:
    var idx := AudioServer.get_bus_index(bus_name)
    if idx < 0:
        return
    AudioServer.set_bus_volume_db(idx, linear_to_db(clampf(linear, 0.0, 1.0)))
    AudioServer.set_bus_mute(idx, linear < 0.001)

func _apply_video() -> void:
    DisplayServer.window_set_mode(
        DisplayServer.WINDOW_MODE_FULLSCREEN if fullscreen
        else DisplayServer.WINDOW_MODE_WINDOWED
    )
    DisplayServer.window_set_vsync_mode(
        DisplayServer.VSYNC_ENABLED if vsync else DisplayServer.VSYNC_DISABLED
    )
    var sizes := [1024, 2048, 4096]
    ProjectSettings.set_setting(
        "rendering/lights_and_shadows/directional_shadow/size",
        sizes[clampi(shadow_quality, 0, 2)]
    )
```

**`linear_to_db()` 변환이 중요하다.** 볼륨 슬라이더는 0~1 선형이지만
오디오 버스는 데시벨이다. 직접 dB를 슬라이더에 연결하면 체감이 부자연스럽다.

---

## 11. FileAccess와 DirAccess

```gdscript
# 파일 읽기
if FileAccess.file_exists(path):
    var f := FileAccess.open(path, FileAccess.READ)
    if f == null:
        push_error("열기 실패 코드: %d" % FileAccess.get_open_error())
    else:
        var text := f.get_as_text()
        var bytes := f.get_buffer(f.get_length())
        var line := f.get_line()
        var csv := f.get_csv_line(",")
        f.close()

# 쓰기
var f := FileAccess.open(path, FileAccess.WRITE)       # WRITE / READ_WRITE / WRITE_READ
f.store_string("텍스트")
f.store_line("한 줄")
f.store_var(data, true)
f.store_buffer(bytes)
f.store_csv_line(["a", "b", "c"])
f.close()

# 압축 파일
var cf := FileAccess.open_compressed(path, FileAccess.WRITE, FileAccess.COMPRESSION_GZIP)

# 정적 헬퍼 (짧은 작업에 편리)
var content := FileAccess.get_file_as_string(path)
var raw := FileAccess.get_file_as_bytes(path)
```

```gdscript
# 디렉터리
DirAccess.make_dir_recursive_absolute("user://saves/screenshots")
DirAccess.remove_absolute(path)
DirAccess.copy_absolute(from, to)
DirAccess.rename_absolute(from, to)
var exists := DirAccess.dir_exists_absolute(path)

var dir := DirAccess.open("user://saves/")
if dir:
    for file_name in dir.get_files():
        print(file_name)
    for sub in dir.get_directories():
        print(sub)
```

### 경로 유틸리티

```gdscript
"res://scenes/levels/level_01.tscn".get_file()       # "level_01.tscn"
"res://scenes/levels/level_01.tscn".get_basename()   # "res://scenes/levels/level_01"
"res://scenes/levels/level_01.tscn".get_extension()  # "tscn"
"res://scenes/levels/level_01.tscn".get_base_dir()   # "res://scenes/levels"
"res://scenes".path_join("levels/a.tscn")            # "res://scenes/levels/a.tscn"
ProjectSettings.globalize_path("user://save.json")   # OS 절대 경로
ProjectSettings.localize_path("/home/u/proj/a.tscn") # "res://a.tscn"
```

---

## 12. 자주 하는 실수

| 실수 | 증상 | 해결 |
|------|------|------|
| 리소스 수정이 모든 인스턴스에 반영 | 참조 공유 | `duplicate()` 또는 `resource_local_to_scene` |
| `duplicate(true)` 했는데 배열 안 리소스가 원본과 함께 바뀜 | `Array`/`Dictionary` 안의 하위 리소스는 복제되지 않음 | `duplicate_deep()` |
| `res://`에 런타임 저장 | 빌드에서 실패 | `user://` 사용 |
| JSON에서 `int`를 그대로 사용 | 타입 오류 | `int(data.value)` 명시 변환 |
| JSON에 `Vector3` 직접 저장 | 파싱 실패 | 배열로 변환 |
| 3D 텍스처를 `Lossless`로 임포트 | VRAM 폭증 | `VRAM Compressed` |
| 3D 텍스처에 밉맵 비활성화 | 원거리 반짝임 | `Mipmaps/Generate` On |
| 3D 효과음이 스테레오 | 공간 오디오 미적용 | `Force/Mono` On |
| `.import` 파일을 gitignore | 팀원마다 임포트 설정 다름 | `.import`는 커밋 |
| `.godot/` 폴더를 커밋 | 저장소 비대 | gitignore |
| 큰 씬을 `load()`로 로드 | 수 초간 프레임 정지 | `load_threaded_request()` |
| Blender에서 Transform 미적용 | 스케일 이상 | `Ctrl+A → All Transforms` |
| 노멀맵 사용 시 Ensure Tangents Off | 노멀맵이 이상하게 보임 | On |
| 폴더 스캔 시 `.remap` 미처리 | 빌드에서만 실패 | `.remap` 접미사 제거 후 로드 |
| 세이브 버전 관리 없음 | 업데이트 후 세이브 깨짐 | `version` 필드 + 마이그레이션 |
| 볼륨 슬라이더를 dB에 직접 연결 | 체감이 부자연스러움 | `linear_to_db()` |
