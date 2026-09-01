# Godot 기본 — 엔진을 이해하는 첫 문서

**Godot 을 처음 배울 때 알아야 할 구조**를 다룬다. 다른 참조 문서가 "어떻게 하는가"를
담는다면 이 문서는 **"Godot 이 왜 이렇게 생겼는가"**를 담는다.

문법은 [gdscript.md](gdscript.md), 노드 API 상세는 [nodes-scenes.md](nodes-scenes.md),
용어 뜻은 [dictionary.md](dictionary.md) 로 간다. 여기서는 **개념의 뼈대**만 세운다.

동작은 **엔진에서 직접 실행해 확인한 것**이며 기준은 **4.7.2.stable** 이다.

---

## 0. 기본적으로 공부해야 할 목록

**Godot 으로 게임을 만들려면 최소한 이만큼은 알아야 한다.**
각 항목은 "설명할 수 있는가"로 판단한다 — 코드를 베껴 쓸 수 있는 것과 다르다.

### 1단계 — 엔진 구조 (이 문서 §1~§5)

- [ ] **노드**가 무엇이고 왜 상속 계층을 갖는가
- [ ] **씬**이 무엇이고, `.tscn` 파일 / 씬 인스턴스 / SceneTree **셋의 차이**
- [ ] **루트 노드**와 씬의 차이 — 트리 맨 위의 그것은 씬이 아니다, 그리고 **`get_tree().root` 는 그것이 아니다**
- [ ] **노드와 리소스**의 차이 — 리소스는 기본이 공유라는 것
- [ ] **몸 · 모양 · 그림 세 가지가 한 세트**라는 것 — `StaticBody3D`(벽·바닥)와 `CharacterBody3D`(플레이어·몹)를 고르는 기준, **`CollisionShape3D` 가 없으면 그냥 통과한다**는 것
- [ ] **플레이어를 노드 4개로 조립하는 법** — `CharacterBody3D` + 메시 + 셰이프 + 카메라, 그리고 **캡슐 원점이 중앙이라 `y = 1` 로 올려야 한다**는 것
- [ ] **인스턴싱** — `load()` → `instantiate()` → `add_child()` **각 단계에서 무슨 일이 일어나는가**
- [ ] `preload` 와 `load` 의 차이
- [ ] **`Save Branch as Scene...`** — 이미 만든 노드 묶음을 재사용 가능한 씬으로 **떼어내는** 반대 방향
- [ ] 스크립트가 노드에 붙는다는 것과 `extends` 가 정하는 것
- [ ] **생명주기** — `_ready` 와 `_process` 와 `_physics_process` 를 언제 쓰는가
- [ ] **`_ready` 가 왜 안 불리는가** — 씬 트리에 없는 노드는 실행되지 않는다는 것
- [ ] **`pass`** 가 무엇이고 **`return` 과 어떻게 다른가**
- [ ] **시그널** — 노드가 서로 직접 부르지 않고 알리는 방법, 그리고 **Godot 4 에서 시그널이 "값"이라는 것**
- [ ] 에디터 4개 독(Scene·Inspector·FileSystem·Output)의 역할

**에디터 조작이 손에 안 맞으면 §7 을 먼저 본다** — 마우스에 가운데 버튼이 없거나
(Magic Mouse) 마우스를 왼손에 두면 **기본 설정으로는 일부 조작이 아예 안 된다.**

**메뉴와 각 에디터 뷰 화면은 [별도 Google 문서](https://docs.google.com/document/d/1b9LPX5Lp6AbaSfdsThvtci5HWcj3O3KQ6eFtJFXUvBw/edit?usp=sharing) 에 정리되어 있다** (§6).

> **개념을 한 바퀴 돌았으면 §9 의 캐릭터 컨트롤러를 한 줄씩 읽는다** —
> 위 항목들이 실제로 도는 코드 한 파일 안에서 어떻게 맞물리는지 보여 준다.

### 2단계 — GDScript 문법 ([gdscript.md](gdscript.md))

- [ ] **정적 타입 선언**과 `:=` 를 언제 쓰고 언제 쓰면 안 되는가
- [ ] `@export` — 인스펙터에 값을 노출하는 것
- [ ] `@onready` 와 노드 참조(`$`, `%`)
- [ ] **시그널 문법 상세** — 연결 플래그, 인자 바인딩 (개념은 이 문서 §5)
- [ ] `Array[T]` 같은 타입 컨테이너
- [ ] `await` 가 무엇을 기다리는가
- [ ] `class_name` 과 상속

### 3단계 — 3D 기초 ([3d-core.md](3d-core.md))

- [ ] Godot 좌표계 — **-Z 가 앞, +Y 가 위**
- [ ] `position` (로컬) 과 `global_position` 의 차이
- [ ] **오일러 회전을 쓰면 안 되는 이유**와 `Transform3D`/`Basis`
- [ ] `Camera3D` 의 `fov`·`near`·`far`

### 4단계 — 움직임과 충돌 ([physics-3d.md](physics-3d.md))

- [ ] `Area3D`·`StaticBody3D`·`RigidBody3D`·`CharacterBody3D` **넷 중 무엇을 언제 쓰는가**
- [ ] `CollisionShape3D` 없이는 충돌하지 않는다는 것
- [ ] `collision_layer` 와 `collision_mask` 의 차이
- [ ] `move_and_slide()` 와 `velocity`

### 5단계 — 만들어 보기 ([level-design.md](level-design.md))

- [ ] CSG 로 방 하나 만들기 — 바닥·벽·문
- [ ] 카메라를 놓고 실행해 보기
- [ ] 씬을 나누고 인스턴싱으로 조립하기

> **순서대로 다 읽고 시작할 필요는 없다.** 1단계만 이해하면 바로 만들기 시작해도 되고,
> 막히는 곳에서 해당 단계를 펴 보는 편이 실제로는 더 빨리 는다.
>
> **글보다 손으로 먼저 익히고 싶으면 §8 의 동영상 강좌부터 본다.**

---

## 1. Godot 의 세계관 — 노드 → 씬 → 씬 속의 씬

Godot 의 구조는 세 문장으로 끝난다.

```
① 모든 것은 노드(Node)다.        — 이미지 한 장, 소리 하나, 충돌체 하나가 전부 노드
② 노드를 묶은 것이 씬(Scene)이다. — 여러 노드를 부모-자식으로 엮어 하나의 덩어리로
③ 씬은 다른 씬의 부품이 된다.     — 그 덩어리를 또 다른 씬 안에 넣는다  ← 이것이 인스턴싱
```

**③ 이 Godot 의 핵심**이다. 다른 엔진처럼 "레벨"과 "프리팹"을 다른 개념으로 나누지 않고,
**둘 다 그냥 씬**이다. 총알도 씬, 적도 씬, 맵도 씬, 게임 전체도 씬이다.
크기와 역할만 다를 뿐 **파일 형식도 다루는 법도 똑같다.**

| 다른 엔진 | Godot |
|---|---|
| Scene(레벨) / Prefab(재사용 부품) — 다른 개념 | **둘 다 `.tscn` 씬** |
| GameObject + Component 조합 | **노드 자체가 기능을 가짐**. 조합은 부모-자식으로 |

### 노드란 무엇인가

**한 가지 일을 하는 부품**이다. 이름·위치를 갖고, 부모와 자식을 가질 수 있다.

```
Player (CharacterBody3D)      ← 움직이고 부딪힌다
├─ MeshInstance3D             ← 보인다
├─ CollisionShape3D           ← 부딪힐 모양
├─ Camera3D                   ← 따라다니며 비춘다
└─ AudioStreamPlayer3D        ← 소리를 낸다
```

노드는 **상속 계층**을 갖는다. `CharacterBody3D` 는 `Node3D` 를 물려받고,
`Node3D` 는 `Node` 를 물려받는다. 그래서 `Node3D` 를 상속한 모든 노드는
`position` 을 갖는다 — 개별 노드마다 외울 필요가 없다.


### 씬 트리가 정하는 것과 **정하지 않는 것**

트리에서 부모-자식으로 묶으면 많은 것이 따라오지만, **따라오지 않는 것**도 있다.
이 경계를 모르면 "왜 이게 되지" 또는 "왜 이게 안 되지"에서 계속 막힌다.

| 트리가 **정하는** 것 | |
|---|---|
| **좌표(Transform) 상속** | 부모를 옮기면 자식이 따라 움직인다 |
| **함께 지워진다** | 부모를 `queue_free()` 하면 자식도 사라진다 |
| **생명주기 순서** | 자식의 `_ready()` 가 부모보다 먼저 불린다 |
| **처리·입력 전달 순서** | 트리 순서를 따른다 |

| 트리가 **정하지 않는** 것 | |
|---|---|
| 🔑 **누구와 충돌하는가** | 트리에서 어디에 있든 상관없다 |

#### 🔑 충돌은 씬 트리가 아니라 **물리 공간(space)** 에서 일어난다

**같은 3D 월드에 있는 물리 객체끼리는 트리에서 어디에 있든 서로 부딪힌다.**

```
Main
├─ Level
│  └─ Geometry (CSGCombiner3D)   use_collision = true
│     ├─ Floor
│     └─ Walls
└─ Player (CharacterBody3D)      ← Geometry 의 자식이 아니라 형제인데도 바닥 위에 선다
```

화면에서 바닥 **위**에 서 있는 것과, 트리에서 **아래**에 있는 것은 전혀 다른 이야기다.
플레이어는 `Geometry` 의 자식이 아니지만 아무 문제 없이 바닥에 선다.

**엔진에서 확인한 결과** — 플레이어를 트리의 여러 위치로 옮겨 놓고 똑같이 떨어뜨렸다.

| 플레이어를 어디에 두었나 | 낙하 후 `y` | `is_on_floor()` | 옆으로 밀면 |
|---|---|---|---|
| `Main` 의 자식 | `1.00` | `true` | 벽에 막힘 ✅ |
| **`Geometry` 의 자식** | `1.00` | `true` | 벽에 막힘 ✅ |
| **완전히 무관한 다른 가지 아래** | `1.00` | `true` | 벽에 막힘 ✅ |

**세 결과가 소수점까지 똑같다.** 트리 위치는 충돌에 아무 영향이 없다.

물리 객체는 씬 트리에 들어갈 때 **`World3D` 의 물리 공간(space)에 등록**되고,
충돌 판정은 **그 공간 안에서** 이루어진다. 트리는 그 등록에 관여하지 않는다.

#### 그럼 무엇이 충돌을 정하는가 — 조건 세 가지

**양쪽 모두** 갖춰야 한다. 한쪽만으로는 아무 일도 일어나지 않는다.

| # | 조건 | 확인할 것 |
|---|---|---|
| ① | **물리 객체일 것** | `CollisionObject3D` 계열이거나 `use_collision` 을 켠 CSG 루트 |
| ② | **모양이 있을 것** | `CollisionShape3D` 의 `Shape` 이 채워져 있는가 |
| ③ | **레이어·마스크가 겹칠 것** | `collision_layer` · `collision_mask` (둘 다 기본 `1`) |

`collision_layer` 는 **"나는 어느 층에 있는가"**(남에게 보이는 방식),
`collision_mask` 는 **"나는 어느 층을 보는가"**(내가 감지하는 대상)다.
**A 가 B 를 감지하려면 `A.collision_mask` 와 `B.collision_layer` 가 겹쳐야 한다.**

#### 🔍 물리 바디는 **"자격"과 "형체"가 따로다**

`CharacterBody3D` 에는 `use_collision` 같은 스위치가 없다. 대신 `CollisionShape3D` 를
자식으로 넣는다. **그럼 콜리전은 원래 있는 것인가, 자식이 켜 주는 것인가.**

**둘 다 아니고 그 중간이다.** 상속 계층을 보면 답이 나온다(doctool 확인).

```
CharacterBody3D  →  PhysicsBody3D  →  CollisionObject3D  →  Node3D
                                       ↑ "충돌할 수 있는 물체" 라는 자격
```

**`CollisionObject3D` 를 상속하므로 태어날 때부터 물리 바디이고, 물리 공간에도 등록된다.**
**그런데 모양이 하나도 없다.** 형체가 없으니 아무것과도 부딪히지 않는다.

그래서 **`CollisionShape3D` 는 "옵션을 켜는 것"이 아니라 "빈 몸에 형체를 넣어 주는 것"** 이다.

| | 자격 (물리 객체인가) | 형체 (모양이 있는가) |
|---|---|---|
| `CharacterBody3D` 만 있을 때 | ⭕ **있다** | ❌ **없다** → 아무것과도 안 부딪힌다 |
| `CollisionShape3D` 를 넣으면 | ⭕ 있다 | ⭕ **생긴다** → 비로소 부딪힌다 |

**모양을 따로 넣는 이유** — 보이는 모습과 부딪히는 모양은 **달라야 하는 경우가 많다.**
캐릭터는 팔다리가 있어도 충돌은 **캡슐 하나**로 처리하는 것이 훨씬 싸고 안정적이다.

##### CSG 와는 방향이 정반대다

| | **CSG** (`CSGCombiner3D`) | **`CharacterBody3D`** |
|---|---|---|
| 태생 | **시각 메시**가 주인공 | **물리 바디**가 주인공 |
| 기본 상태 | 콜리전이 **아예 없다** | 몸은 있는데 **모양이 0개** |
| 콜리전을 갖는 법 | `use_collision` 을 켜면 **메시로부터 만들어 준다** | `CollisionShape3D` 가 **모양을 공급한다** |
| 방향 | 보이는 것 **→** 물리 | 물리 **←** 따로 넣어 준 모양 |

**그래서 한쪽에는 스위치가 있고 다른 쪽에는 없다.** CSG 는 이미 있는 메시를 물리에
쓸지 말지를 정하는 것이고, 물리 바디는 없는 모양을 넣어 주는 것이다.

#### ⚠️ 단, **내 몸을 조립하는 것**은 트리 관계를 따진다

여기서 혼동이 생긴다. **"누구와 부딪히는가"와 "내 몸이 어떻게 생겼는가"는 다른 문제**다.

| 질문 | 트리 관계가 중요한가 |
|---|---|
| **누구와 부딪히는가** | ❌ 무관 — 물리 공간과 레이어/마스크가 정한다 |
| **내 몸이 어떻게 생겼는가** | ⭕ **중요하다** — 아래 참고 |

`CollisionShape3D` 는 **그 자체로는 물리 객체가 아니다.** 부모를 찾아
**자기 `Shape` 을 등록해 주는 도우미 노드**이고, **직속 부모만** 본다.

```
CharacterBody3D
└─ CollisionShape3D          ✅ 등록된다

CharacterBody3D
└─ Node3D                    ← 중간에 끼면
   └─ CollisionShape3D       🛑 등록되지 않는다
```

**엔진에서 확인한 결과** (물리 서버에 실제로 등록된 shape 개수):

| 구조 | 등록된 shape | 낙하 후 `y` |
|---|---|---|
| `CharacterBody3D` > `CollisionShape3D` | **1** | `1.00` 바닥에 섬 ✅ |
| **`CharacterBody3D` > `Node3D` > `CollisionShape3D`** | **0** | `-18.09` 🛑 뚫고 떨어짐 |
| `CollisionShape3D` 는 있지만 `Shape` 이 비어 있음 | **0** | `-18.09` 🛑 |
| `CollisionShape3D` 가 아예 없음 | **0** | `-18.09` 🛑 |

**CSG 도 같은 함정이 있다** — `CSGCombiner3D` 아래에 `Node3D` 를 끼우면
그 아래 도형이 형상과 콜리전에서 통째로 빠진다.

> 🔑 **한 줄로** — **누구와 부딪히는가는 트리와 무관하지만,
> 내 몸을 이루는 부품은 직속 부모에게만 붙는다.**
> 정리용으로 빈 `Node3D` 를 끼울 때는 **그 아래에 콜리전이나 CSG 도형이 없는지** 확인한다.

실전 예제와 전체 검증 수치는 [example.md](example.md) §9 에 있다.

### 노드와 리소스는 다르다

초보자가 가장 많이 헷갈리는 구분이다.

| | 노드(Node) | 리소스(Resource) |
|---|---|---|
| 정체 | **씬 트리에 들어가는 것** | **노드가 쓰는 데이터** |
| 예 | `MeshInstance3D`, `Camera3D` | `Mesh`, `Material`, `Texture2D`, `PackedScene` |
| 위치 | 트리의 한 자리 | 노드의 프로퍼티 안 |
| 공유 | 각자 독립 | **여러 노드가 같은 것을 공유한다** |

**리소스는 기본이 공유**라는 점이 중요하다. 머티리얼 하나를 적 10마리가 쓰고 있으면,
한 마리 색을 바꿨을 때 10마리가 전부 바뀐다. 개별화하려면 `duplicate()` 하거나
`Local to Scene` 을 켠다 ([resources-assets.md](resources-assets.md)).

**리소스는 직접 만들 수도 있다.** 엔진이 준 것(`Mesh`·`Material`)만 리소스인 게 아니라,
`extends Resource` 로 자기 데이터 타입을 정의해 `.tres` 파일로 저장할 수 있다.
맵 설정·아이템 표·난이도 프리셋처럼 **코드가 아니라 데이터로 두어야 할 값**이 여기 들어간다.

```gdscript
class_name WorldConfig
extends Resource

@export var world_size: float = 1000.0
@export var chunk_size: float = 250.0
```

```
res://resources/maps/plains_4km.tres    ← world_size = 4000
res://resources/maps/arena_750m.tres    ← world_size = 750
```

스크립트에 `const WORLD_SIZE := 4000.0` 으로 박아 두면 맵이 둘이 되는 순간 막히지만,
리소스로 빼면 **`.tres` 만 늘어나고 코드는 그대로**다. 만드는 법과 함정
(**기본값과 같은 값은 파일에 저장되지 않는다** 등)은
[resources-assets.md](resources-assets.md) §3 에 있다.

#### 🔍 인스펙터에서 리소스 프로퍼티는 **한 겹 안쪽**에 있다

이 구분은 개념으로 끝나지 않는다. **에디터에서 값을 찾지 못하는 형태로 곧장 나타난다.**

예 — `MeshInstance3D` 에 `BoxMesh` 를 붙이고 상자 크기를 바꾸려는데
**인스펙터에 `Size` 가 없다.** 대신 `Scale` 만 보인다.

`MeshInstance3D` 가 가진 프로퍼티는 `mesh`·`skeleton`·`skin` **셋뿐**이고(엔진 확인),
`Scale` 은 그 위의 `Node3D` 에서 물려받은 것이다.
**`Size` 는 `BoxMesh` 라는 리소스의 프로퍼티**라 노드 인스펙터에 나올 이유가 없다.

**찾는 법** — 인스펙터의 `Mesh` 슬롯에 있는 `BoxMesh` 썸네일을 **클릭한다.**
인스펙터 아래쪽이 펼쳐지며 `Size`·`Subdivide *`·`Material` 이 나온다. 다시 클릭하면 접힌다.
`Shape`·`Material`·`Texture` 슬롯도 전부 같은 방식이다.

**헷갈리는 이유는 같은 이름이 양쪽에 다 있기 때문이다** (엔진에서 확인한 소속).

| 만지는 값 | 소속 | 상속 | 인스펙터 |
|---|---|---|---|
| `CSGBox3D` 의 `Size` | **노드** | `CSGBox3D` → `CSGPrimitive3D` | 바로 보인다 |
| `BoxMesh` 의 `Size` | **리소스** | `BoxMesh` → `PrimitiveMesh` | `Mesh` 를 클릭해 펼친다 |
| `CapsuleMesh` 의 `Height`·`Radius` | **리소스** | `CapsuleMesh` → `PrimitiveMesh` | `Mesh` 를 클릭해 펼친다 |
| `CapsuleShape3D` 의 `Height`·`Radius` | **리소스** | `CapsuleShape3D` → `Shape3D` | `Shape` 를 클릭해 펼친다 |
| `Scale` | **노드** | `Node3D` | 바로 보인다 |

`CSGBox3D` 는 **노드 자체가 `size` 를 갖는** 경우다. 그래서 CSG 로 바닥·벽을 만들 때는
바로 보이다가, `MeshInstance3D` + `BoxMesh` 로 넘어가는 순간 안 보여서 걸린다.

#### 🛑 크기를 `Scale` 로 대신하지 않는다

크기가 리소스 안에 숨어 있으니 **노드의 `Scale` 로 대신하고 싶어진다.**
화면상 결과는 같다 — `BoxMesh` 의 `Size` 를 `1, 1, 1` 로 두고
`Scale` 에 `0.25, 0.25, 0.5` 를 넣으면 똑같이 보인다.

그래도 `Size` 를 쓴다.

| `Scale` 로 크기를 주면 | 무슨 일이 생기나 |
|---|---|
| **자식에게 전파된다** | 아래 달린 노드가 전부 같이 찌그러진다 |
| **비균등 스케일이 노멀을 왜곡한다** | 면이 향한 방향이 틀어져 조명 계산이 어긋난다 |
| **콜리전·물리에서 문제가 된다** | 셰이프에 스케일을 주면 엔진에 따라 동작이 달라진다 |

말단 장식이라면 당장은 차이가 없다. 문제는 **같은 습관을 콜리전이나 조명이 붙은 곳에
그대로 쓸 때**이고, 그때는 원인을 찾기 어렵다.

**메시의 크기는 메시에서, 노드의 배치는 Transform 에서** — 이렇게 나눠 두면 헷갈리지 않는다.

---

### 3D 게임에서 실제로 만나는 노드들 — 몸 · 모양 · 그림

노드 종류는 수백 개지만, **3D 게임을 시작할 때 실제로 쓰는 것은 몇 개 안 된다.**
그리고 그중 가장 먼저 이해해야 하는 것이 **"몸"** 이다.

#### 🔑 하나를 놓는 게 아니라 셋을 한 세트로 놓는다

**왕초보가 가장 크게 막히는 지점이다.** 벽 하나를 만들려면 노드 하나가 아니라
**세 가지 역할**이 필요하다.

| 역할 | 노드 | 없으면 |
|---|---|---|
| **① 몸** — 물리 세계에서 무엇으로 취급되나 | `StaticBody3D` 등 | 물리 세계에 존재하지 않는다 |
| **② 모양** — 어디까지가 부딪히는 범위인가 | **`CollisionShape3D`** | **그냥 통과한다** |
| **③ 그림** — 눈에 보이는 겉모습 | `MeshInstance3D` | 안 보인다 (부딪히기는 한다) |

```
Wall (StaticBody3D)          ← ① 몸
├─ CollisionShape3D          ← ② 모양 (BoxShape3D 를 넣는다)
└─ MeshInstance3D            ← ③ 그림 (BoxMesh 를 넣는다)
```

> 🛑 **보이는 것과 부딪히는 것은 완전히 별개다.**
> `MeshInstance3D` 만 놓으면 **벽처럼 보이지만 그대로 통과**하고,
> `CollisionShape3D` 만 놓으면 **보이지 않는 벽**이 된다.
> "분명히 벽을 만들었는데 캐릭터가 지나간다"의 원인은 대부분 ②가 없어서다.

#### 몸(물리 바디) 4종 — 무엇이 이것을 움직이는가

**고르는 기준은 딱 하나다 — "누가 이 물체의 위치를 정하는가."**

| 노드 | 위치를 정하는 주체 | 쓰는 곳 |
|---|---|---|
| **`StaticBody3D`** | **아무도.** 움직이지 않는다 | **벽·바닥·건물·지형** 같은 움직이지 않는 환경 |
| **`CharacterBody3D`** | **내 스크립트.** 매 틱 직접 속도를 써 넣는다 | **점프·미끄러짐처럼 직접 짠 이동 로직이 필요한 개체** — 플레이어·몬스터·NPC |
| `RigidBody3D` | **물리 엔진.** 힘을 주면 알아서 굴러간다 | 굴러가는 통, 무너지는 상자, 던진 물건 |
| `Area3D` | (몸이 아니다) **막지 않고 감지만 한다** | 세이프존 경계, 함정 발동, 아이템 줍기 범위 |

> **`Area3D` 는 부딪히지 않는다.** 통과하면서 **"들어왔다·나갔다"만 알려준다**
> (`body_entered` / `body_exited` 시그널). 나머지 셋은 **실제로 막는다.**

한 가지가 더 있는데, 처음에는 몰라도 된다.

| 노드 | |
|---|---|
| `AnimatableBody3D` | `StaticBody3D` 를 상속한 **"움직이는 정적 바디"** — 엘리베이터, 움직이는 발판. `sync_to_physics` 기본값이 `true` 라 그 위에 탄 캐릭터를 밀지 않고 함께 옮긴다 |

#### 고르는 순서

```
막아야 하나?
├─ 아니오 → Area3D              (감지만)
└─ 예
   ├─ 움직이나?
   │  ├─ 아니오 → StaticBody3D      ← 벽·바닥. 맵의 대부분이 이것
   │  └─ 예
   │     ├─ 내가 조종하나? → CharacterBody3D   ← 플레이어·몹
   │     ├─ 정해진 경로로 움직이나? → AnimatableBody3D
   │     └─ 물리에 맡기나? → RigidBody3D
```

**맵을 만들면 노드의 90% 는 `StaticBody3D` 다.** 그리고 살아 움직이는 것은
거의 다 `CharacterBody3D` 다. 이 둘만 알아도 게임 하나가 나온다.

#### `StaticBody3D` — 움직이지 않는 환경

**아무 설정 없이 그냥 놓으면 된다.** 속도도 중력도 없다. 물리 엔진은 이것을
**"질량이 무한대인 벽"** 으로 취급해서, 계산 비용이 가장 싸다.

실측 속성은 셋뿐이다 (엔진에서 확인).

| 속성 | 기본값 | 무엇 |
|---|---|---|
| `physics_material_override` | `None` | 마찰·반발력. 얼음 바닥·트램펄린을 만들 때 |
| `constant_linear_velocity` | `Vector3(0, 0, 0)` | **몸은 가만히 있는데 표면만 흐른다** — 컨베이어 벨트 |
| `constant_angular_velocity` | `Vector3(0, 0, 0)` | 회전판 |

> **`constant_linear_velocity` 는 실제로 노드를 움직이지 않는다.**
> 표면에 닿은 물체를 밀어낼 뿐이다. 그래서 컨베이어 벨트를 `StaticBody3D` 로
> 만들 수 있다 — 정적 바디의 싼 비용을 유지한 채로.

**CSG 로 블록아웃할 때는 `CSGCombiner3D` 의 `use_collision` 을 켜면
`StaticBody3D` 를 따로 놓지 않아도 된다** → [level-design.md](level-design.md)

#### `CharacterBody3D` — 직접 짠 이동 로직이 필요할 때

**점프·미끄러짐·계단 오르기처럼 "게임다운" 움직임**을 위한 몸이다.
이런 것을 **키네마틱(kinematic) 바디**라고 부른다.

> **키네마틱 = "물리 법칙에 맡기지 않고 내가 직접 위치를 정한다"**

**왜 캐릭터를 물리 엔진에 맡기지 않는가** — `RigidBody3D` 로 플레이어를 만들면
**미끄러지고, 넘어지고, 밀리고, 관성이 남는다.** 현실적이지만 **조작감이 나쁘다.**
게임 캐릭터는 "키를 떼면 즉시 멈추고, 절대 넘어지지 않는" **비현실적인 움직임이
오히려 옳다.**

역할 분담은 이렇게 나뉜다.

| | 담당 |
|---|---|
| **어디로 얼마나 빨리 갈 것인가** | 🧑‍💻 **내 스크립트** — `velocity` 에 써 넣는다 |
| **가다가 부딪히면 어떻게 할 것인가** | ⚙️ **엔진** — `move_and_slide()` 가 처리한다 |

```gdscript
extends CharacterBody3D

func _physics_process(delta: float) -> void:
	velocity.y -= 9.8 * delta          # ① 내가 속도를 정하고
	move_and_slide()                   # ② 엔진이 부딪힘을 처리한다
```

알아 둘 만한 실측 기본값이다 (엔진에서 확인).

| 속성 | 기본값 | 무엇 |
|---|---|---|
| `velocity` | `Vector3(0, 0, 0)` | **내가 써 넣는 속도.** m/s |
| `up_direction` | `Vector3(0, 1, 0)` | 어느 쪽이 "위"인가 — 바닥 판정의 기준 |
| **`floor_max_angle`** | **`0.7853982` rad = 45°** | **이보다 가파르면 바닥이 아니라 벽**으로 친다 |
| `floor_snap_length` | `0.1` | 내리막에서 지면에 붙어 있게 하는 거리 |
| `motion_mode` | `0` (GROUNDED) | 지면 기반. 우주선처럼 위아래가 없으면 `1`(FLOATING) |
| `max_slides` | `6` | 한 번에 미끄러져 재시도하는 최대 횟수 |
| `slide_on_ceiling` | `true` | 천장에 부딪히면 미끄러진다 |

> **`floor_max_angle` 45° 가 뜻하는 것** — 경사가 45° 를 넘으면 `is_on_floor()` 가
> `false` 가 되어 **캐릭터가 미끄러져 내려온다.** "언덕을 못 올라간다"의 원인이
> 대개 이 값이다.

**라리엔에서는 몹도 `CharacterBody3D` 다. 다만 입력으로 움직이지 않는다** —
**위치는 서버가 정하고**([SSOT §7](../../game/references/SSOT.md)), 클라이언트는
받은 좌표로 보간해 옮긴다. "내 스크립트가 위치를 정한다"의 *내 스크립트* 가
**서버 스냅샷을 반영하는 코드**인 셈이다.

#### 🛑 `CollisionShape3D` 에 셰이프를 넣지 않으면 아무 일도 안 일어난다

`CollisionShape3D` 의 **`shape` 기본값은 `None`** 이다 (엔진에서 확인).
노드를 추가하기만 하고 인스펙터에서 셰이프를 지정하지 않으면 **경고만 뜨고 통과한다.**

| # | 조작 |
|---|---|
| 1 | 몸 노드 선택 → **Cmd+A** → `CollisionShape3D` 추가 |
| 2 | 인스펙터의 **`Shape`** → `New BoxShape3D`(상자) · `New SphereShape3D`(구) · `New CapsuleShape3D`(캡슐 — **사람 모양에 표준**) |
| 3 | 크기를 맞춘다 |

> **셰이프는 눈에 보이는 메시와 자동으로 맞춰지지 않는다.** 메시를 키우면
> 셰이프도 따로 키워야 한다. 이 둘이 어긋난 것이 "허공에서 막힌다"의 원인이다.

#### 상속 관계 — 왜 collision_layer 는 전부 갖고 있나 (엔진에서 확인)

```
Node3D
└─ CollisionObject3D          collision_layer = 1 · collision_mask = 1
   ├─ Area3D                  감지만 (monitoring 기본 true)
   └─ PhysicsBody3D           실제로 막는다
      ├─ StaticBody3D
      │  └─ AnimatableBody3D  sync_to_physics = true
      ├─ RigidBody3D          mass = 1.0 · gravity_scale = 1.0
      └─ CharacterBody3D      velocity · move_and_slide()
```

넷 다 `CollisionObject3D` 를 물려받으므로 **`collision_layer` · `collision_mask`
(둘 다 기본 `1`)를 공통으로 갖는다.** 이 둘로 "누가 누구와 부딪히는가"를 정한다
→ [physics-3d.md](physics-3d.md)

#### 흔한 실수

| 증상 | 원인 | 해결 |
|---|---|---|
| **벽을 만들었는데 통과한다** | `CollisionShape3D` 가 없거나 `shape` 가 `None` | 셰이프를 지정한다 |
| **아무것도 안 보이는데 막힌다** | `MeshInstance3D` 가 없다 | 그림을 붙인다 |
| **캐릭터가 계속 떨어진다** | 바닥에 몸(`StaticBody3D`)이 없다 | 바닥도 몸이어야 한다 |
| **언덕을 못 올라간다** | 경사가 `floor_max_angle`(45°)을 넘는다 | 경사를 낮추거나 값을 올린다 |
| **플레이어가 미끄러지고 넘어진다** | `RigidBody3D` 로 만들었다 | `CharacterBody3D` 로 바꾼다 |
| **`Area3D` 인데 안 막힌다** | **정상이다.** 감지 전용이다 | 막으려면 `StaticBody3D` |
| **`RigidBody3D` 충돌 시그널이 안 온다** | `contact_monitor` 기본값이 `false` | 켜고 `max_contacts_reported` 를 올린다 |

**실제 코드로 캐릭터를 움직이는 것은 [§9](#9-실전--3d-캐릭터-컨트롤러를-한-줄씩-읽는다),
물리 전반은 [physics-3d.md](physics-3d.md) 에 있다.**

---

### 해 보기 — 플레이어 캐릭터를 만든다 (노드 4개)

앞 절에서 **몸 · 모양 · 그림 세 가지가 한 세트**라는 것을 봤다.
여기서는 그것을 **실제로 에디터에서 조립한다.** 노드 4개면 끝난다.

#### 목표 구조

```
Main (Node3D)                     ← 메인 씬의 루트
├─ WorldEnvironment
├─ DirectionalLight3D
└─ Player (CharacterBody3D)       ← ① 몸.  이름을 Player 로 바꾼다
   ├─ MeshInstance3D              ← ③ 그림. 눈에 보이는 캡슐
   ├─ CollisionShape3D            ← ② 모양. 부딪히는 캡슐 (보이지 않는다)
   └─ Camera3D                    ← 화면을 찍는 눈
```

**`Player` 아래에 셋을 넣는 이유는 하나다 — 부모가 움직이면 자식이 따라가기 때문**이다.
카메라를 밖에 두면 캐릭터만 걸어가고 화면은 제자리에 남는다.

#### 조작 순서

> 🛑 **씬 파일(`.tscn`)은 사람 개발자가 에디터에서 직접 만든다**
> ([CLAUDE.md](../../../../CLAUDE.md) 작업 규칙). 아래는 그 조작 순서다.

| # | 무엇을 선택하고 | 조작 | 결과 |
|---|---|---|---|
| 1 | **`Main`** (루트) | **Cmd+A** → `CharacterBody3D` | 몸이 생긴다 |
| 2 | **`CharacterBody3D`** | **Cmd+A** → `MeshInstance3D` | 그림 |
| 3 | **`CharacterBody3D`** | **Cmd+A** → `CollisionShape3D` | 모양 |
| 4 | **`CharacterBody3D`** | **Cmd+A** → `Camera3D` | 눈 |
| 5 | `CharacterBody3D` | **F2** → `Player` | 이름 변경 |

`Cmd+A` 는 macOS 의 **자식 노드 추가**다 (Windows·Linux 는 `Ctrl+A`).

> 🛑 **2~4 번에서 매번 `CharacterBody3D` 를 다시 선택한다.**
> `Cmd+A` 는 **지금 선택된 노드의 자식**으로 넣는다. 1번 직후 `CharacterBody3D` 가
> 선택된 상태에서 계속 누르면 `MeshInstance3D` 안에 `CollisionShape3D` 가 들어가
> **점점 깊어진다.** 셋은 **형제**여야 한다.

**이름은 마지막에 바꾼다.** 먼저 바꿔도 되지만, 노드를 추가하는 동안은
타입 이름 그대로 두는 편이 무엇을 만들고 있는지 눈에 보인다.

#### 노드마다 반드시 해야 하는 설정

**노드를 추가한 것만으로는 아무것도 보이지 않고 아무것도 부딪히지 않는다.**
셋 다 인스펙터에서 내용물을 지정해야 한다.

| 노드 | 인스펙터에서 | 지정하지 않으면 |
|---|---|---|
| `MeshInstance3D` | **`Mesh`** → `New CapsuleMesh` | **안 보인다** (`mesh` 기본값 `None`) |
| `CollisionShape3D` | **`Shape`** → `New CapsuleShape3D` | **그냥 통과한다** (`shape` 기본값 `None`) |
| `Camera3D` | **위치를 뒤·위로 옮긴다** | **캐릭터 안쪽에서 찍혀 아무것도 안 보인다** |

> 🔑 **`CapsuleMesh` 와 `CapsuleShape3D` 의 기본값이 서로 같다** (엔진에서 확인) —
> 둘 다 `height = 2.0`, `radius = 0.5` 다. **그래서 둘 다 기본값으로 두면
> 보이는 것과 부딪히는 것이 정확히 일치한다.** 한쪽만 크기를 바꾸면 그때부터
> 어긋나기 시작한다.

#### 🛑 캡슐이 바닥에 반쯤 묻힌다 — 원점이 중앙이기 때문

**가장 먼저 만나는 함정이다.** 캡슐의 원점은 **가운데**에 있다.
`Player` 를 `y = 0` 에 두면 **아래 절반(1m)이 바닥 밑으로 들어간다.**

| 무엇 | 값 |
|---|---|
| 캡슐 높이 | `2.0` m |
| 중심에서 발끝까지 | **`1.0` m** |
| **바닥(`y = 0`) 위에 세우려면** | **`Player` 의 `position.y = 1`** |

**`MeshInstance3D` 와 `CollisionShape3D` 는 `(0, 0, 0)` 에 그대로 두고,
부모인 `Player` 만 올린다.** 자식을 각각 올리면 나중에 둘이 어긋난다.

#### 카메라를 어디에 둘 것인가

`Camera3D` 를 추가한 직후에는 **캐릭터 몸 안쪽**에 있다. 실행하면 캡슐 내부라
아무것도 안 보이거나 온통 회색이다. **인스펙터의 `Transform > Position` 을 옮긴다.**

| 시점 | `Camera3D` 위치 (Player 기준) | 비고 |
|---|---|---|
| **3인칭** | `(0, 1.5, 4)` 정도 | **`+Z` 가 뒤쪽**이다. 뒤로 물러나 등을 본다 |
| **1인칭** | `(0, 0.7, 0)` 정도 | 눈높이. `MeshInstance3D` 를 숨기는 편이 낫다 |

**Godot 에서 `-Z` 가 앞, `+Z` 가 뒤다.** 카메라를 `z = 4` 로 두면 캐릭터 **뒤**에
서게 된다 — 이 좌표 규약은 [§9.3](#93-godot-의-3d-좌표-규약--왕초보가-가장-먼저-넘어지는-곳) 에서 자세히 다룬다.

> `Camera3D.current` 의 기본값은 `false` 지만 (엔진에서 확인),
> **씬에 카메라가 하나뿐이면 엔진이 알아서 그것을 쓴다.** 카메라가 둘 이상일 때만
> 어느 것을 쓸지 `current` 로 정한다.

#### ⚠️ 이름 하나 짚고 넘어간다 — `MeshInterface3D` 라는 노드는 없다

학습 자료에서 종종 `MeshInterface3D` 라고 잘못 적힌 것을 보게 되는데,
**실제 노드 이름은 `MeshInstance3D`** 다. *Interface* 가 아니라 ***Instance*(실체)**
— "메시 리소스를 씬에 실체로 놓은 것"이라는 뜻이다.
[노드와 리소스는 다르다](#노드와-리소스는-다르다) 에서 본 구분이 이름에 그대로 들어 있다.

#### 🛑 라리엔 3D 에서는 카메라를 `Player` 자식으로 두지 않는다

**위 구조는 자유 시점 게임의 전형이고, 대부분의 Godot 튜토리얼이 이렇게 가르친다.**
캐릭터가 돌면 카메라도 함께 도는 구조다.

**라리엔은 카메라 회전 3축이 전부 고정이다** ([SSOT §1](../../game/references/SSOT.md)).
카메라를 `Player` 의 자식으로 두면 **캐릭터가 도는 순간 카메라도 돌아서 그 규칙이 깨진다.**

```
Main
├─ CameraRig (Node3D)      ← 카메라는 여기. PC 를 따라가되 회전은 하지 않는다
│  └─ Camera3D
└─ Player (CharacterBody3D)
   ├─ MeshInstance3D
   └─ CollisionShape3D     ← 카메라가 없다
```

**연습으로 만들 때는 자식으로 둬도 된다.** 다만 라리엔 본체에 옮길 때는
`Main` 아래로 빼야 한다는 것을 알고 있어야 한다 → [level-design.md](level-design.md)

#### 여기까지 하면 무엇이 되나

**아직 움직이지 않는다.** 노드만 놓은 상태이고, **움직이려면 스크립트가 필요하다.**

| 지금 되는 것 | 아직 안 되는 것 |
|---|---|
| 캡슐이 화면에 보인다 | 키를 눌러도 반응이 없다 |
| 벽·바닥에 부딪힌다 (바닥에 몸이 있다면) | 중력이 없어 공중에 떠 있다 |
| 카메라가 캐릭터를 따라간다 | |

**다음은 스크립트다** — `Player` 를 선택하고 스크립트를 붙인 뒤,
[§9 실전 — 3D 캐릭터 컨트롤러](#9-실전--3d-캐릭터-컨트롤러를-한-줄씩-읽는다) 를
한 줄씩 읽으면 걸어다니게 된다.

#### 흔한 실수

| 증상 | 원인 | 해결 |
|---|---|---|
| **아무것도 안 보인다** | `MeshInstance3D` 의 `Mesh` 가 `None` | `New CapsuleMesh` 를 지정 |
| **화면이 온통 회색·검정이다** | 카메라가 캐릭터 몸 안에 있다 | 카메라를 뒤로 (`z = 4`) 옮긴다 |
| **캡슐이 바닥에 묻혀 있다** | 원점이 중앙인데 `y = 0` 에 뒀다 | `Player.position.y = 1` |
| **캐릭터가 바닥을 통과해 떨어진다** | 바닥에 `StaticBody3D` + `CollisionShape3D` 가 없다 | 바닥도 몸이어야 한다 |
| **노드가 형제가 아니라 점점 깊어진다** | `Cmd+A` 를 연속으로 눌렀다 | 매번 `CharacterBody3D` 를 다시 선택 |
| **카메라가 캐릭터를 안 따라간다** | `Camera3D` 가 `Player` 밖에 있다 | 자식으로 끌어다 넣는다 |
| **몸과 그림이 어긋난다** | 메시와 셰이프의 크기를 따로 바꿨다 | 둘 다 `height 2.0` · `radius 0.5` 로 맞춘다 |

> **저사양을 생각한다면** — `CapsuleMesh` 의 `radial_segments` 기본값은 **`64`** 다
> (엔진에서 확인). 연습용 캡슐 하나야 상관없지만, **이런 프리미티브를 화면에 수십 개
> 놓을 거라면 8~16 으로 낮춘다.** 라리엔의 드로우콜·정점 예산은
> [SSOT §3](../../game/references/SSOT.md) 에 있다.

---

## 2. 씬(Scene) — 파일인가 객체인가

같은 "씬"이라는 말이 **세 가지**를 가리킨다. 이 셋을 구분하지 못하면 계속 막힌다.

| 용어 | 정체 | 어디 있나 |
|---|---|---|
| **씬 파일** (`.tscn`) | 노드 구성을 적어 둔 **텍스트 파일** = **설계도** | 디스크 |
| **씬 인스턴스** | 설계도로 만들어 낸 **실제 노드 묶음** = **실체** | 메모리 |
| **SceneTree** | 지금 돌아가는 게임의 **활성 노드 트리 전체** | 실행 중인 프로세스 |

`.tscn` 은 그냥 텍스트다. 열어 보면 이렇게 생겼다.

```ini
[gd_scene load_steps=2 format=3 uid="uid://..."]

[ext_resource type="Script" path="res://scenes/bullet.gd" id="1_b"]

[node name="Bullet" type="Node3D"]
script = ExtResource("1_b")

[node name="Body" type="MeshInstance3D" parent="."]
```

**이 파일이 있다고 게임에 총알이 생기는 것이 아니다.** 설계도일 뿐이다.
설계도를 실체로 바꾸는 것이 **인스턴싱**이다.

### 트리 맨 위의 그것은 "씬"이 아니라 **루트 노드**다

에디터 Scene 독에서 이런 트리를 볼 때, 맨 위의 `Demo` 를 무엇이라 불러야 하는가.

```
Demo                    ← 이것을 뭐라고 부르나?
└─ StaticBody3D
   └─ MeshInstance3D
```

**`Demo` 를 Root Node(루트 노드)라고 부르는 쪽이 정확하다.** `Demo` 는 **노드 하나**이고,
**씬은 `Demo` 하나가 아니라 `Demo` 와 그 아래 전부를 묶은 것**이다.

| 부르는 말 | 가리키는 것 |
|---|---|
| **루트 노드** | **`Demo` 노드 하나** — 트리의 맨 위 |
| **씬** | `Demo` + `StaticBody3D` + `MeshInstance3D` **전체** |
| **씬 파일** | 그 전체를 적어 둔 `demo.tscn` |

**그렇다고 "Demo 씬"이라는 말이 틀린 것은 아니다** — 그때 `Demo` 는 **씬의 이름**이지
그 노드 하나를 씬이라고 부르는 것이 아니다. 헷갈리는 이유는 관행상 **루트 노드 이름과
씬 파일 이름을 같게 짓기 때문**이다 (`Demo` → `demo.tscn`).

> **한 문장으로** — **씬은 묶음이고, 루트 노드는 그 묶음의 맨 위 노드 하나다.**
> 트리에서 손가락으로 `Demo` 를 짚고 있다면 그것은 **루트 노드**다.

**에디터가 쓰는 말도 "루트 노드"다.** *(4.7.2 바이너리에서 확인한 UI 문자열)*

| 언제 | 에디터가 보여 주는 말 |
|---|---|
| 빈 씬을 만들면 | **`Create Root Node:`** |
| 다른 노드를 맨 위로 올리면 (Scene 독 우클릭) | **`Make Scene Root`** |
| 맨 위 노드를 지우려 하면 | **`Delete the root node "%s"?`** |
| 루트가 없는 채로 저장하면 | `A root node is required to save the scene.` |

#### 🛑 `root` 라는 말은 두 곳에서 쓰인다 — `get_tree().root` 는 `Demo` 가 아니다

이쪽이 진짜 함정이다. 게임이 실행되면 Godot 은 씬 위에 **`Window` 를 자동으로 얹는다.**
그리고 **그 `Window` 의 이름도 `root`** 다.

```
root              ← get_tree().root      (Window — 엔진이 만든 것)
└─ Demo           ← get_tree().current_scene  (내 씬의 루트 노드)
   └─ StaticBody3D
      └─ MeshInstance3D
```

```gdscript
# Demo 에 붙인 스크립트에서
print(get_tree().root)            # root:<Window#...>   🛑 Demo 가 아니다
print(get_tree().current_scene)   # Demo:<Node3D#...>   ✅ 이것이 내 씬의 루트 노드
print(get_parent())               # root:<Window#...>   부모는 Window 다
```

| 코드 | 타입 | 돌아오는 것 |
|---|---|---|
| `get_tree().root` | **`Window`** | 엔진이 자동 생성한 최상위 뷰포트 — **씬과 무관** |
| `get_tree().current_scene` | `Node` | **지금 씬의 루트 노드** = `Demo` |

*(4.7.2 `--doctool` 확인 — `SceneTree.root` 는 `type="Window"` 이고 setter 가 없다.
`SceneTree.current_scene` 은 `type="Node"`.)*

#### 루트 노드만 다른 점 — 엔진에서 확인한 것

| | 루트 노드 (`Demo`) | 나머지 노드 |
|---|---|---|
| **개수** | 씬마다 **정확히 하나** | 제한 없음 |
| **`owner`** | **`null`** | 루트 노드 (`Demo`) |
| **`.tscn` 의 `parent=`** | **없다** | 있다 (`parent="."` 등) |
| **`scene_file_path`** | **`res://demo.tscn`** | 빈 문자열 |
| **실행 중 부모** | `root` (`Window`) | 씬 안의 다른 노드 |

```gdscript
# 실측 출력 (4.7.2)
Demo.scene_file_path            = 'res://demo.tscn'
StaticBody3D.scene_file_path    = ''
MeshInstance3D.scene_file_path  = ''
```

`.tscn` 에서 **루트 노드에만 `parent=` 가 없는 것**이 눈으로 보이는 증거다.
위 §2 의 `.tscn` 예시에서 `[node name="Bullet" type="Node3D"]` 에는 `parent` 가 없고
`[node name="Body" ... parent="."]` 에는 있다. 엔진은 이 규칙을 강제한다 —
`Invalid scene: root node %s cannot specify a parent node.`

#### 씬을 인스턴싱하면 돌아오는 것도 **루트 노드**다

```gdscript
var demo = load("res://demo.tscn").instantiate()
```

여기서 `demo` 에 담기는 것은 "씬"이라는 어떤 객체가 아니라 **`Demo` 라는 노드**다.
자식들은 그 아래에 이미 달려 있다.

```gdscript
# 실측 출력 (4.7.2)
instantiate() 반환 타입   = Node3D      # 루트 노드의 타입 그대로
instantiate() 반환 이름   = Demo        # 루트 노드의 이름 그대로
반환된 것의 자식 수       = 1           # 자식은 이미 붙어 있다
반환 직후 owner           = <Object#null>
```

**그래서 씬의 "타입"은 루트 노드의 타입이 정한다.** 루트가 `Node3D` 면 그 씬은 3D 공간에
놓을 수 있고, `Control` 이면 UI 로만 쓴다. **씬을 만들 때 루트 노드 타입을 먼저
정하는 이유**가 이것이다 — 나중에 바꾸려면 전체를 다시 짜야 한다.

> **정리** — 씬을 다루는 코드는 전부 **루트 노드를 주고받는다.**
> `instantiate()` 가 돌려주는 것도, `current_scene` 이 가리키는 것도, `add_child()` 에
> 넘기는 것도 루트 노드다. **"씬"이라는 이름의 객체는 실행 중에 존재하지 않는다** —
> 존재하는 것은 `PackedScene`(설계도)과 노드들뿐이다.


---

## 3. 인스턴싱(Instancing) — 설계도로 실체를 찍어낸다

**미리 만들어 둔 씬을 불러와 새 노드 묶음을 만들어 내는 것**이다.
탄막 슈팅에서 총알 씬 하나를 만들어 두고 **쏠 때마다 찍어내는** 것이 전형적인 예다.

> 🔑 **인스턴싱하지 않은 씬은 실행되지 않는다.** `.tscn` 이 프로젝트 폴더에 있는 것과
> 게임 안에 존재하는 것은 별개다 — 그 씬의 스크립트에 `_ready()` 를 아무리 써도
> 불리지 않는다. 자세한 것은 §4 [`_ready()` 가 실행되지 않는다](#_ready-가-실행되지-않는다--파일이-있다고-실행되는-게-아니다).

### 왜 필요한가

| 이유 | 내용 |
|---|---|
| **반복 제작이 사라진다** | 적 100마리를 손으로 100번 만들지 않는다. 씬 하나 + 100번 인스턴싱 |
| **고칠 곳이 한 군데다** | **원본 씬을 고치면 모든 인스턴스에 반영된다.** 총알 크기를 바꾸려고 100개를 찾아다니지 않는다 |
| **코드가 짧아진다** | 노드를 하나씩 `new()` 해서 조립하는 코드가 통째로 사라진다 |

### 방법 1 — 에디터에서

씬 독(Scene 패널)에서 부모 노드를 선택하고,

- **체인 모양 버튼**(`Instantiate Child Scene`) 을 누르거나
- **Cmd+Shift+A** (Windows·Linux 는 `Ctrl+Shift+A`)

`.tscn` 파일을 고르면 그 씬이 자식으로 들어온다.
**파일 독에서 씬을 뷰포트로 드래그해도 같다.**

인스턴스는 씬 독에서 **영화 슬레이트 아이콘**으로 표시되고, 자식 노드들은 접힌 채로 온다.
**원본을 고치면 이 인스턴스도 함께 바뀐다** — 그것이 인스턴싱의 값어치다.

### 방법 2 — 코드에서

3단계다. **각 단계가 무엇을 하는지가 이 절의 핵심**이다.

```gdscript
extends Node3D

const BULLET: PackedScene = preload("res://scenes/bullet.tscn")   # ① 설계도를 메모리로

func fire() -> void:
	var bullet: Node3D = BULLET.instantiate()   # ② 설계도로 실체를 만든다 (아직 트리 밖)
	bullet.speed = 30.0                          # ③ 이 인스턴스만의 값을 준다
	add_child(bullet)                            # ④ 트리에 넣는다 → 여기서 _ready 가 불린다
	bullet.global_position = muzzle.global_position   # ⑤ 전역 좌표는 트리에 들어간 뒤에
```

### "메모리에 올린다"가 무슨 뜻인가 — 4단계

강의·문서에서 자주 나오는 이 말은 **단계마다 다른 것을 가리킨다.**
`.tscn` 하나가 화면의 캐릭터가 되기까지 **네 번의 상태 변화**를 거친다.

```gdscript
var player_scene: PackedScene = load("res://Player.tscn")   # ②
var player: CharacterBody3D = player_scene.instantiate()    # ③
add_child(player)                                            # ④
```

#### ① 아무것도 하지 않은 상태 — `.tscn` 은 설계도일 뿐

`res://Player.tscn` 은 디스크에 있는 **텍스트 파일**이다.
파일이 있다는 것만으로는 **게임 실행 중에 아무 일도 일어나지 않는다.**
건축 도면이 있다고 집이 서 있는 것은 아닌 것과 같다.

#### ② `load("res://Player.tscn")` — 설계도를 메모리로 읽는다

씬 리소스를 메모리에 불러와 **`PackedScene` 객체**로 만든다.
**아직 설계도를 손에 든 것뿐이다.** 노드는 하나도 생기지 않았고 화면에도 없다.

> 흔한 오해 — "load 했으니 화면에 나오겠지"가 아니다.
> 이 줄만 실행하면 **여전히 아무 일도 일어나지 않는다.**

#### ③ `player_scene.instantiate()` — 설계도로 실체를 찍어낸다

**이때 비로소 `Node` 들이 생성된다.** 씬에 적힌 노드 구성이 그대로 메모리에 만들어지고,
자식 노드도 함께 생긴다. 이것이 **"객체화"** 다.

다만 **아직 트리 밖이다.** 화면에 없고 `_ready()` 도 불리지 않았다.
`get_tree()` 는 `null` 이고 `@onready` 변수도 비어 있다.

#### ④ `add_child(player)` — 씬 트리에 연결해야 화면에 나온다

**SceneTree 에 붙는 순간** 화면에 표시되고 `_process`·`_physics_process` 가 돌기 시작한다.
`_ready()` 도 여기서 불린다.

### 한 장으로 보는 4단계

| | 단계 | 코드 | 이 시점에 존재하는 것 | 화면에 보이나 | `_ready` |
|---|---|---|---|---|---|
| ① | 아무것도 안 함 | — | 디스크의 `.tscn` 텍스트 | ❌ | ❌ |
| ② | 설계도를 메모리로 | `load()` | ＋ `PackedScene` 객체 | ❌ | ❌ |
| ③ | 실체를 찍어냄 | `instantiate()` | ＋ **노드들** (트리 밖) | ❌ | ❌ |
| ④ | 트리에 연결 | `add_child()` | ＋ SceneTree 안의 자리 | ✅ | ✅ |

```
res://Player.tscn          ①  디스크의 텍스트 — 설계도. 아무 일도 안 일어난다
      │ load() / preload()
      ▼
PackedScene                ②  메모리의 설계도 객체. 노드는 아직 0개
      │ instantiate()
      ▼
CharacterBody3D + 자식들    ③  노드가 생겼다. 하지만 트리 밖 — 화면에 없다
      │ add_child()
      ▼
SceneTree 안               ④  화면에 나오고 _ready·_process 가 돈다
```

**한 줄로 줄이면** — 인스턴싱이란 **씬 리소스를 기반으로 새로운 객체를 메모리에 생성하는
과정**이고, 그 객체가 실제로 동작하려면 **트리에 연결(④)까지** 해야 한다.

### 엔진에서 확인한 실제 동작 (4.7.2)

```
instantiate 직후  is_inside_tree = false      ← ③ 아직 트리 밖
    [_ready] BulletA  speed=5.0               ← ④ add_child() 안에서 즉시 호출된다
add_child 직후    is_inside_tree = true
preload 와 load 가 같은 객체인가? true         ← 같은 경로는 리소스 캐시를 공유한다
```

여기서 나오는 규칙 세 가지다.

| 규칙 | 이유 |
|---|---|
| **`instantiate()` 직후에는 `get_tree()` 가 `null`, `@onready` 도 아직 안 채워졌다** | ③ 은 트리 밖이기 때문 |
| **전역 좌표(`global_position`)는 `add_child()` 뒤에 준다** | 트리 밖에서는 부모 좌표계가 없어 무시된다 |
| **일반 변수(`speed` 등)는 `add_child()` 앞에 줘도 된다** | `_ready()` 가 그 값을 보고 시작할 수 있어 오히려 낫다 |

### `preload` 와 `load` 의 차이

| | `preload()` | `load()` |
|---|---|---|
| 읽는 시점 | **스크립트가 컴파일될 때** (게임 시작 전) | **그 줄이 실행될 때** |
| 인자 | 문자열 **상수만** | 변수 가능 |
| 쓰는 곳 | `const` 로 파일 상단에 | 경로가 실행 중에 정해질 때 |

같은 경로를 여러 번 불러도 **엔진이 캐시해 같은 리소스 객체를 준다**(위 검증의 `true`).
그래서 "여러 번 load 하면 메모리를 여러 배 쓴다"는 걱정은 하지 않아도 된다.

### 반대 방향 — `Save Branch as Scene...` (만들어 놓은 묶음을 씬으로 떼어낸다)

여기까지가 **씬 파일 → 화면 위의 노드**였다면, 이것은 **화면 위의 노드 → 씬 파일**이다.
씬을 미리 만들어 두고 인스턴싱하는 게 정석이지만, 실제로는 **일단 현재 씬에서 만들어 보고
나중에 "이거 재사용하겠다"고 깨닫는 일**이 훨씬 많다. 그때 쓰는 기능이다.

#### 브랜치(Branch)란 — **선택한 노드 + 그 아래 전부**

씬은 노드의 트리다. 맨 위가 **루트**, 끝이 **잎**이고,
**루트가 아닌 노드 하나와 그 아래 자손 전체**를 **브랜치**라고 부른다.
`Boxes` 를 선택했다면 브랜치는 이 넷 전부다.

```
Boxes          ← 선택한 노드
├─ Box
├─ Box2
└─ Box3
```

#### 실행하면 무슨 일이 일어나나 — 트리

```
[실행 전]                          [실행 후]

light_scene.tscn                   boxes.tscn          ← ① 새 파일로 저장된다
└─ Boxes                           └─ Boxes
   ├─ Box                             ├─ Box
   ├─ Box2                            ├─ Box2
   └─ Box3                            └─ Box3

                                   light_scene.tscn
                                   └─ Boxes  ← ② 그 자리는 boxes.tscn 의 인스턴스로 바뀐다
                                              (자식들은 접혀서 안 보인다)
```

세 가지가 한 번에 일어난다.

1. `Boxes` 와 그 자손을 **별도의 `.tscn` 파일로 저장**한다.
2. 원래 씬의 그 자리는 **새 씬의 인스턴스로 교체**된다 — 씬 독에서 **영화 슬레이트 아이콘**이 붙는다.
3. 이후 `boxes.tscn` 을 **다른 씬 어디에나 인스턴싱**할 수 있고, **원본을 고치면 전부 반영**된다.

한 줄로 줄이면 — **현재 씬 안에서 만든 노드 묶음을 독립적인 재사용 가능 씬으로 분리한다.**

#### `.tscn` 텍스트가 실제로 어떻게 바뀌나 (4.7.2 실측)

이것이 "고칠 곳이 한 군데"의 물리적 근거다. **자식 노드 정의가 원본 씬에서 통째로 사라지고
참조 두 줄만 남는다.**

```ini
; 실행 전 — light_scene.tscn 이 상자 3개를 직접 들고 있다
[node name="LightScene" type="Node3D"]
[node name="Boxes" type="Node3D" parent="."]
[node name="Box"  type="MeshInstance3D" parent="Boxes"]
[node name="Box2" type="MeshInstance3D" parent="Boxes"]
[node name="Box3" type="MeshInstance3D" parent="Boxes"]
```

```ini
; 실행 후 — light_scene.tscn
[ext_resource type="PackedScene" path="res://boxes.tscn" id="1_ul0ol"]   ; ← 참조를 선언하고

[node name="LightScene" type="Node3D"]
[node name="Boxes" type="Node3D" parent="." instance=ExtResource("1_ul0ol")]   ; ← 한 줄로 끝난다
```

```ini
; 실행 후 — boxes.tscn (Boxes 가 이 씬의 루트가 된다 → parent="." 로 바뀐다)
[node name="Boxes" type="Node3D"]
[node name="Box"  type="MeshInstance3D" parent="."]
[node name="Box2" type="MeshInstance3D" parent="."]
[node name="Box3" type="MeshInstance3D" parent="."]
```

> 위는 헤드리스 Godot 4.7.2 로 같은 구조를 만들어 저장한 결과다.
> **에디터로 저장하면 `ext_resource` 줄에 `uid="uid://..."` 가 함께 붙는다** — 경로가 바뀌어도
> 참조가 안 깨지게 하는 식별자이고, 의미는 같다.

#### 방법

씬 독에서 **떼어낼 노드를 하나만 선택** → **우클릭** → **`Save Branch as Scene...`**
→ 저장할 경로·파일명을 정한다(기본 파일명은 노드 이름에서 자동으로 만들어진다).

**기본 단축키는 없다.** 자주 쓴다면 `Editor > Editor Settings > Shortcuts` 에서
`scene_tree/save_branch_as_scene` 에 직접 지정한다.

#### 🛑 저장 대화상자의 `Reset Position` 은 기본이 **켜짐**이다

대화상자 아래에 체크박스 3개가 있고, **기본값이 다르다**(엔진 소스 확인).

| 옵션 | 기본값 | 켜져 있으면 |
|---|---|---|
| **`Reset Position`** | ✅ **켜짐** | 새 씬 안에서 루트의 위치가 **원점(0,0,0)** 이 된다 |
| `Reset Rotation` | ❌ 꺼짐 | 회전을 0 으로 |
| `Reset Scale` | ❌ 꺼짐 | 스케일을 1 로 |

**원본 씬은 그대로 보인다** — 남는 인스턴스는 떼어내기 전의 위치·회전·스케일을 그대로
물려받기 때문이다(연결해 둔 시그널과 `%` 고유 이름도 유지된다).
달라지는 것은 **새로 만들어진 `boxes.tscn` 을 열었을 때**뿐이다. 원점에 놓여 있다.

**이 기본값이 맞는 경우가 대부분이다.** 재사용할 부품은 원점에 있어야 어디에 갖다 놔도
예측 가능하기 때문이다. 다만 **여러 부품의 상대 위치가 의미를 갖는 묶음**(예: 원점에서 멀리
떨어진 지형 위에 배치한 구조물)이라면 끄고 저장한다.

#### 언제 쓰나

여러 곳에서 반복해 쓸 물건을 **이미 현재 씬 안에 만들어 놨을 때**다.

- 적 캐릭터와 그 충돌체·애니메이션
- 총과 총구·발사 이펙트
- 문과 손잡이·충돌체
- 상자 여러 개로 이루어진 구조물
- UI 패널과 그 아래 버튼·라벨

라리엔에서는 **맵에 반복 배치할 지물**(가로등, 표지판, 잔해 더미)이 여기에 해당한다.
블록아웃 중 손으로 조합해 본 묶음을 씬으로 떼어내면 그때부터 인스턴싱 대상이 된다.
→ [level-design.md](level-design.md)

#### 비슷한 메뉴와 헷갈리지 않는다

| 메뉴 | 하는 일 | 새 `.tscn` 이 생기나 |
|---|---|---|
| **`Save Branch as Scene...`** | **선택한 노드와 그 자손만** 새 씬으로 분리하고, 그 자리를 인스턴스로 교체 | ✅ |
| `Scene > Save Scene As...` | **지금 열려 있는 씬 전체**를 다른 이름으로 저장 | ✅ (하지만 분리가 아니다) |
| `Duplicate` (`Cmd+D`) | 현재 씬 **안에서** 노드를 복제. 원본과 아무 관계가 없어 **따로 고쳐야 한다** | ❌ |
| `Scene > New Inherited Scene...` | 기존 씬을 **부모로 삼아** 변형 씬을 만드는 상속 기능 | ✅ (브랜치를 떼는 것이 아니다) |
| `Make Local` | 반대 동작. **인스턴스를 풀어** 현재 씬의 평범한 노드들로 되돌린다 | ❌ |

#### 🛑 이럴 때는 거부당한다 — 메시지 그대로 읽으면 답이 있다

엔진이 막는 경우가 정해져 있다(4.7.2 소스 확인).

| 상황 | 엔진이 하는 말 | 해야 할 일 |
|---|---|---|
| **루트 노드**를 선택했다 | *Can't save the root node branch as an instantiated scene.* | 씬 전체는 브랜치가 아니다. `Save Scene As...` 나 `New Inherited Scene...` 를 쓴다 |
| 이미 **인스턴스**인 노드를 선택했다 | *Can't save the branch of an already instantiated scene.* | 변형이 필요하면 `New Inherited Scene...` 로 상속 씬을 만든다 |
| **인스턴스의 자식**을 선택했다 | *Can't save a branch which is a child of an already instantiated scene.* | **원본 씬을 열어서** 거기서 떼어낸다 |
| **상속 씬의 일부**를 선택했다 | *Can't save a branch which is part of an inherited scene.* | 마찬가지로 원본 씬에서 한다 |
| 노드를 **2개 이상** 선택했다 | *…requires selecting only one node…* | 하나만 고른다. 여러 개를 묶고 싶으면 **먼저 부모 `Node` 를 하나 만들어 넣고** 그 부모를 고른다 |

마지막 줄이 실무에서 제일 자주 걸린다. **여러 노드를 한 씬으로 떼려면 부모가 먼저 필요하다.**

#### 떼어낸 뒤 — 내부를 다시 만지려면

인스턴스가 된 뒤에는 씬 독에서 **자식들이 접혀 보이지 않고, 보이더라도 편집이 잠긴다.**
그 자리에서만 손보고 싶으면 우클릭 → **`Editable Children`** 을 켠다.
다만 이렇게 바꾼 값은 **그 인스턴스에만 남는 재정의(override)** 이고,
**원본 씬에 반영되지 않는다.** 원본을 고칠 생각이면 `boxes.tscn` 을 직접 열어야 한다.

> `Editable Children` 을 다시 끄면 **그 아래에서 바꾼 값이 전부 기본값으로 되돌아간다** —
> 엔진도 끌 때 경고한다(*…will cause all properties of this subscene's descendant nodes to be
> reverted to their default.*).

#### 공식 문서

- **[Save Branch as Scene 을 문장으로 설명하는 공식 문서 (3.2 UI 튜토리얼)](https://docs.godotengine.org/en/3.2/getting_started/step_by_step/ui_game_user_interface.html#turn-the-bar-and-counter-into-reusable-ui-components)**
  — *"노드 브랜치를 별도의 씬으로 캡슐화한다"* 는 설명과 브랜치의 정의(루트도 잎도 아닌
  노드와 그 자식들)가 여기 있다. **최신 4.x 문서에는 이 튜토리얼이 없어졌고**, 4.x 문서 어디에도
  이 메뉴를 이름으로 설명한 페이지가 없다(문서 검색 인덱스 확인). 기능 자체는 4.7.2 에서 그대로 동작한다.
- [인스턴싱 (4.x, stable)](https://docs.godotengine.org/en/stable/getting_started/step_by_step/instancing.html) — 떼어낸 씬을 다시 갖다 쓰는 쪽
- [노드와 씬 인스턴스 (4.x, stable)](https://docs.godotengine.org/en/stable/tutorials/scripting/nodes_and_scene_instances.html) — 코드에서 다루기
- [씬 구성 모범 사례 (4.x, stable)](https://docs.godotengine.org/en/stable/tutorials/best_practices/scene_organization.html) — **어디서 씬을 나눌 것인가**의 판단 기준

---

## 4. 스크립트 — 노드에 붙는 것

GDScript 파일은 혼자 돌지 않는다. **노드에 붙어야** 실행된다.

```gdscript
extends CharacterBody3D    # ← "이 스크립트는 CharacterBody3D 노드에 붙는다"는 선언
```

`extends` 가 정하는 것은 **이 스크립트가 어떤 노드의 기능을 물려받는가**다.
`CharacterBody3D` 를 상속했으므로 `velocity`·`move_and_slide()` 를 그냥 쓸 수 있다.

**스크립트는 씬과 같은 폴더에 둔다** — 엔진의 Attach Script 기본 경로가 그 구조를
전제하기 때문이다. 근거는 [nodes-scenes.md](nodes-scenes.md) §11.

### GDScript 문법의 기초 — 왕초보가 가장 먼저 막히는 것들

**코드가 무엇을 하는지 이전에, 코드가 어떻게 생겼는지부터** 알아야 한다.
여기 나오는 값은 전부 **엔진에 직접 넣어 돌려 본 결과**다.

#### 🔑 블록은 **들여쓰기로만** 정해진다 — 중괄호가 없다

C·Java·JavaScript 는 `{ }` 로 묶는다. **GDScript 에는 그것이 없다.**

```gdscript
if dir.is_zero_approx():
	velocity.x = 0.0        # ← 들여쓴 줄이 if 안쪽
	velocity.z = 0.0        # ← 이것도 안쪽
move_and_slide()            # ← 들여쓰기를 뺐으므로 if 바깥
```

**같은 깊이로 들여쓴 연속된 줄들이 하나의 블록**이다.
들여쓰기를 한 칸 빼는 순간 그 블록은 끝난다.

##### 줄 끝의 `:` 은 "이제 블록이 시작된다"는 표시

```gdscript
func _physics_process(delta: float) -> void:    # ← 콜론
	if not is_on_floor():                       # ← 콜론
		velocity += get_gravity() * delta
```

`func`·`if`·`else`·`for`·`while` 뒤에는 **반드시 `:` 을 찍고 다음 줄부터 들여쓴다.**
`:` 을 빼면 오류가 나고, `:` 만 찍고 들여쓰지 않아도 오류가 난다(엔진 확인).

```
Expected indented block after function declaration.
```

> 💡 아무것도 안 할 블록에는 **`pass`** 를 넣는다. 빈 블록은 문법 오류이기 때문이다.

#### 들여쓰기를 개발자 마음대로 해도 되나 — **크기와 문자는 자유, 일관성은 필수**

**결론부터** — 탭이든 스페이스든, 1칸이든 8칸이든 **내 마음대로 고를 수 있다.**
**단 한 파일 안에서는 끝까지 같아야 한다.**

엔진에서 직접 확인한 결과다.

| 들여쓰기 방식 | 결과 |
|---|---|
| **탭** | ✅ 통과 |
| **스페이스 4칸** | ✅ 통과 |
| **스페이스 2칸** | ✅ 통과 |
| **스페이스 1칸** | ✅ 통과 |
| **한 파일에서 탭과 스페이스를 섞음** | 🛑 **오류** |
| 같은 블록인데 어떤 줄만 더 깊게 | 🛑 **오류** |
| 블록인데 들여쓰기를 안 함 | 🛑 **오류** |

섞었을 때 나오는 메시지는 이렇다.

```
Parse Error: Used space character for indentation instead of tab as used before in the file.
```

**"앞에서는 탭을 쓰더니 여기서는 스페이스를 썼다"** 고 정확히 알려준다.

같은 블록인데 깊이가 다르면 이렇게 나온다.

```
Parse Error: Expected statement, found "Indent" instead.
```

##### 그래서 실제로는 무엇을 쓰나 — **탭**

**Godot 에디터의 기본값이 탭이고, 공식 스타일 가이드도 탭**이다.
에디터에서 Tab 키를 누르면 탭 문자가 들어가므로 **그냥 쓰면 자동으로 맞는다.**

**문제는 인터넷에서 코드를 복사해 붙일 때** 생긴다. 웹 페이지의 코드는
스페이스인 경우가 많아 **붙이는 순간 탭과 섞인다.**
위 오류가 나면 **복사해 온 줄의 들여쓰기를 지우고 Tab 키로 다시 넣는다.**

> 💡 Godot 에디터에서 **`Edit > Indentation > Convert Indent to Tabs`** 로
> 파일 전체를 한 번에 바꿀 수 있다.

#### `:=` 가 무엇인가 — 변수를 선언하는 **세 가지 방법**

```gdscript
var a = 1              # ① 타입 없이
var b := 1             # ② 타입 추론  ← 이 스킬의 기본
var c: int = 1         # ③ 타입 명시
```

세 개가 다 동작한다. 차이는 **"이 변수에 나중에 다른 타입을 넣을 수 있는가"** 다.

| | 쓰는 법 | 타입이 | 다른 타입을 넣으면 |
|---|---|---|---|
| ① | `var a = 1` | **고정되지 않는다** | ✅ 된다 — 나중에 문자열도 담긴다 |
| ② | `var b := 1` | **`int` 으로 고정** | 🛑 **오류** |
| ③ | `var c: int = 1` | **`int` 으로 고정** | 🛑 오류 |

**②와 ③은 결과가 같다.** `:=` 는 **"타입을 값에서 알아서 정하라"** 는 뜻이고,
③은 **"타입을 내가 직접 적겠다"** 는 뜻이다.

##### `:=` 가 실제로 정하는 타입 (엔진에서 확인)

| 코드 | 정해지는 타입 |
|---|---|
| `var a := 1` | **`int`** |
| `var b := 1.0` | **`float`** |
| `var c := "글자"` | **`String`** |
| `var d := Vector3(1,2,3)` | **`Vector3`** |

**소수점 하나로 타입이 갈린다.** `1` 은 `int`, `1.0` 은 `float` 이다.

##### 타입을 고정하면 무엇이 좋은가

```gdscript
var b := 1
b = "문자열"      # 🛑 게임을 실행하기 전에 에디터가 잡아 준다
```

```
Parse Error: Cannot assign a value of type "String" as "int".
```

**실수를 실행 전에 잡는다.** 타입 없이 선언하면 이 실수가 통과해 버리고,
게임을 한참 돌리다 엉뚱한 곳에서 터진다.
**그래서 이 스킬은 `:=` 또는 `: 타입 =` 을 쓰는 것을 규범으로 한다.**

##### 🛑 `var a: int := 1` 은 문법 오류다

```
Parse Error: Expected end of statement after variable declaration, found ":" instead.
```

**`:` 과 `:=` 를 함께 쓸 수 없다.** 둘 중 하나만 쓴다.

##### ⚠️ `int` 변수에 실수를 넣으면 **조용히 잘린다**

```gdscript
var f := 1        # int 로 고정
f = 2.7           # 오류가 나지 않는다
print(f)          # → 2
```

엔진에서 확인한 결과 **`2`** 가 나온다. 소수점이 버려진 것이다.
**오류도 경고도 없다.** 소수를 다룰 값이면 처음부터 `1.0` 으로 써서 `float` 이 되게 한다.

##### `const` 는 `var` 와 무엇이 다른가

```gdscript
const SPEED := 5.0     # 한 번 정하면 바꿀 수 없다
var velocity_x := 0.0  # 언제든 바꿀 수 있다
```

`const` 에 나중에 대입하면 오류가 난다. **바뀌면 안 되는 값에 `const` 를 쓰면
실수로 고치는 사고를 막을 수 있다.** 대문자로 쓰는 것은 관습이다.

#### `@` 로 시작하는 것 — 어노테이션(annotation)

```gdscript
@onready var _mesh: Node3D = $Mesh
@export var speed := 5.0
@tool
```

**`@` 로 시작하는 것을 어노테이션이라고 한다.** 변수도 함수도 아니고,
**바로 아래(또는 같은 줄)에 오는 것을 엔진이 어떻게 다룰지 지시하는 표시**다.

`@onready` 는 **"이 변수의 대입을 노드가 씬 트리에 들어간 뒤로 미뤄라"** 는 지시다.
코드가 하는 일이 아니라 **엔진에게 시키는 일**이라서 `@` 를 붙여 구분한다.

##### 🛑 개발자가 마음대로 만들 수 없다

**엔진이 제공하는 고정 목록에서 골라 쓰는 것**이고, 새로 만들 수 없다.
없는 이름을 쓰면 그 자리에서 막힌다(엔진 확인).

```gdscript
@my_annotation
var a := 1
```
```
Parse Error: Unrecognized annotation: "@my_annotation".
```

**변수·함수 이름은 내가 짓지만, 어노테이션은 고를 수만 있다.**
이 점이 다른 이름들과 결정적으로 다르다.

##### 붙일 수 있는 자리도 정해져 있다

`@onready` 하나만 놓고 잘못된 자리에 붙여 봤다. 전부 막힌다(엔진 확인).

| 잘못 쓴 예 | 엔진이 내는 오류 |
|---|---|
| 함수 안 **지역 변수**에 | `Annotation "@onready" is not allowed in this level.` |
| **`Node` 를 상속하지 않는** 클래스에서 | `"@onready" can only be used in classes that inherit "Node".` |
| **함수**에 붙임 | `Annotation "@onready" cannot be applied to a function.` |
| `@export` 와 **함께** 씀 | `"@onready" will set the default value after "@export" takes effect and will override it.` |

**마지막 것이 이 스킬의 절대 규칙 중 하나**다 — `@export` 와 `@onready` 를 함께 쓰면
인스펙터에서 넣은 값이 `@onready` 대입에 덮여 버린다. 엔진이 직접 경고한다.

##### 어떤 것들이 있나 (엔진에서 추출한 전체 목록 · 37개)

| 분류 | 어노테이션 |
|---|---|
| **노드·씬** | `@onready` · `@tool` · `@icon` |
| **인스펙터 노출** | `@export` 와 그 변형 **24개** — `@export_range` · `@export_enum` · `@export_file` · `@export_dir` · `@export_multiline` · `@export_color_no_alpha` · `@export_node_path` · `@export_flags` · `@export_group` · `@export_subgroup` · `@export_category` · `@export_placeholder` · `@export_custom` · `@export_storage` · `@export_tool_button` · `@export_exp_easing` · `@export_global_file` · `@export_global_dir` · `@export_file_path` · `@export_flags_2d_*` / `_3d_*` / `_avoidance` |
| **네트워크** | `@rpc` |
| **클래스** | `@abstract` · `@static_unload` |
| **경고 제어** | `@warning_ignore` · `@warning_ignore_start` · `@warning_ignore_restore` |

**절반 이상이 `@export` 계열**이다. 인스펙터에 값을 어떤 모습으로 띄울지
(슬라이더로? 드롭다운으로? 파일 선택 버튼으로?) 정하는 것들이다.

##### 초보가 실제로 쓰게 되는 것은 셋뿐이다

| 어노테이션 | 언제 |
|---|---|
| **`@onready`** | 자식 노드를 변수에 잡을 때 — **가장 자주 쓴다** |
| **`@export`** | 인스펙터에서 값을 조절하고 싶을 때 |
| `@tool` | 에디터에서도 스크립트를 돌리고 싶을 때 (당분간 필요 없다) |

```gdscript
@export var speed := 5.0        # 인스펙터에 "Speed" 칸이 생긴다
@export_range(1.0, 20.0) var jump := 4.5   # 슬라이더로 나온다
```

**`@export` 를 쓰면 코드를 고치지 않고 씬마다 다른 값**을 줄 수 있다.
`const` 로 박아 둔 `SPEED` 를 `@export var` 로 바꾸면 인스펙터에서 바로 조절된다.

전체 어노테이션의 상세와 인스펙터 표시 방법은 [gdscript.md](gdscript.md) 에 있다.

#### 그 밖에 먼저 알아 둘 것

| 문법 | 뜻 |
|---|---|
| `# 주석` | 이 줄은 실행되지 않는다 |
| `## 문서 주석` | 인스펙터·자동완성에 설명으로 뜬다 |
| `func 이름():` | 함수 선언 |
| `-> void` | **반환 타입** — 값을 돌려주지 않는다는 표시 |
| `and` · `or` · `not` | **`&&`·`||`·`!` 가 아니다** |
| 줄 끝 `;` | **필요 없다** (써도 되지만 관습이 아니다) |
| `_` 로 시작하는 이름 | 내부용이라는 **관습**(변수) 또는 엔진 콜백(함수) |

```gdscript
## 걷는 속도 (m/s)          ← 이 설명이 자동완성에 뜬다
const SPEED := 5.0

# 아래는 그냥 메모다          ← 이건 안 뜬다
func _physics_process(delta: float) -> void:
	if is_on_floor() and Input.is_action_just_pressed("ui_accept"):
		velocity.y = JUMP_VELOCITY
```

문법 전체 목록과 심화는 [gdscript.md](gdscript.md) 에 있다.
실제 코드에 이 문법이 어떻게 쓰이는지는 [example.md](example.md) §7 을 본다.


### 생명주기 — 언제 불리는가

```
_init()            객체 생성 시. 아직 트리 밖, 자식도 없다
_enter_tree()      트리에 들어갈 때
_ready()           자식까지 전부 준비된 뒤 한 번   ← 초기화는 보통 여기서
_process(delta)    매 프레임 (프레임레이트에 따라 간격이 다름)
_physics_process() 고정 틱 (기본 60Hz)             ← 물리·이동은 반드시 여기서
_exit_tree()       트리에서 나갈 때
```

**부모보다 자식의 `_ready()` 가 먼저 불린다.** 자식이 다 준비된 뒤에 부모가 준비되는
순서라, 부모의 `_ready()` 에서는 자식을 안심하고 만질 수 있다.

### `_ready()` 가 실행되지 않는다 — 파일이 있다고 실행되는 게 아니다

**초보자가 가장 많이 겪는 혼란이다.** `.gd` 파일 여러 개에 `_ready()` 를 써 놨는데
실행하면 그중 하나의 `print` 만 찍힌다.

**원인은 하나다 — `_ready()` 는 "파일이 존재하면" 불리는 게 아니라,
그 스크립트가 붙은 노드가 실행 중인 씬 트리(SceneTree)에 들어갈 때 불린다.**

프로젝트 폴더에 `.gd` 나 `.tscn` 이 놓여 있는 것과, 그것이 게임 안에서
**살아 있는 노드로 존재하는 것**은 완전히 별개다. 존재하지 않는 노드의 `_ready()` 는
불릴 이유가 없다.

#### 실제 사례 — 두 개의 씬, 네 개의 스크립트

```
project.godot     run/main_scene="uid://ekov44a2ii3w"   ← demo.tscn 의 UID

demo.tscn         Demo (Node3D)
                  └── TheBox (StaticBody3D)   ← the_box.gd

light_scene.tscn  LightScene (Node3D)         ← light_scene.gd
                  └── StaticBody3D            ← static_body_3d.gd
                      └── MeshInstance3D      ← mesh_instance_3d.gd
```

| 스크립트 | 붙은 노드가 있는 씬 | 실행되나 |
|---|---|---|
| `the_box.gd` | **demo.tscn** = 메인 씬 | ✅ |
| `light_scene.gd` | light_scene.tscn | ❌ |
| `static_body_3d.gd` | light_scene.tscn | ❌ |
| `mesh_instance_3d.gd` | light_scene.tscn | ❌ |

`light_scene.tscn` 은 **demo.tscn 어디에서도 인스턴싱되어 있지 않다.**
디스크에 놓인 파일일 뿐이라 실행 중인 게임 안에는 존재하지 않는다.
스크립트가 세 개나 붙어 있어도 결과는 같다 — **노드가 없으면 `_ready()` 도 없다.**

#### 확인하는 법 — 씬이 인스턴싱되었는지 본다

`.tscn` 을 텍스트로 열어 `ext_resource` 와 `PackedScene` 을 본다.
부모 씬이 자식 씬을 품고 있으면 이런 줄이 있어야 한다.

```
[ext_resource type="PackedScene" uid="uid://c73oplm6ylkw8" path="res://light_scene.tscn" id="2_xxxxx"]
...
[node name="LightScene" parent="." instance=ExtResource("2_xxxxx")]
```

이 두 줄이 없으면 그 씬은 **실행되지 않는다.**

#### 해결 — 셋 중 하나를 고른다

| 원하는 것 | 방법 |
|---|---|
| **두 씬을 함께 돌린다** | 메인 씬 안에 다른 씬을 **인스턴싱**한다 (아래 ①) |
| **그 씬만 돌린다** | 메인 씬을 바꾸거나 <kbd>F6</kbd> 로 현재 씬만 실행 (아래 ②③) |
| **항상 살아 있어야 한다** | **오토로드(Autoload)** 로 등록 (아래 ④) |

**① 메인 씬 안에 인스턴싱한다 (가장 흔한 정답)**

씬 독에서 부모가 될 노드를 선택하고 **Instantiate Child Scene**
(체인 모양 아이콘, <kbd>Cmd</kbd>+<kbd>Shift</kbd>+<kbd>A</kbd> · Windows·Linux 는 `Ctrl+Shift+A`) 으로 `.tscn` 을 고른다.
파일 독에서 씬 트리로 **드래그 앤 드롭** 해도 같다. 코드로 넣는 방법은 §3 참고.

**② 메인 씬 자체를 바꾼다**

`Project > Project Settings > Application > Run > Main Scene`

단, 이러면 **원래 메인 씬 쪽 `_ready()` 가 반대로 안 불린다.** 교체이지 추가가 아니다.

**③ 지금 열어 둔 씬만 단독 실행 — <kbd>F6</kbd>**

메인 씬 설정을 건드리지 않고 확인만 할 때 쓴다.
<kbd>F5</kbd> 는 **메인 씬**, <kbd>F6</kbd> 는 **지금 열려 있는 씬**을 실행한다.
이 둘을 헷갈려서 "왜 내가 편집 중인 씬이 안 뜨지" 하는 경우가 많다.

**④ 오토로드로 등록한다**

`Project > Project Settings > Globals > Autoload`

씬이나 스크립트를 등록하면 엔진이 **루트(`/root`) 바로 아래에 붙여** 게임 내내
살려 둔다. 씬을 바꿔도 죽지 않으므로 사운드 매니저·세이브 매니저처럼
**전역으로 하나만 있어야 하는 것**에 쓴다. 일반 게임 오브젝트에는 쓰지 않는다.

#### `_ready()` 가 안 불리는 다른 원인들

씬 인스턴싱이 압도적으로 흔하지만, 다음도 확인한다.

| 원인 | 증상 | 확인 |
|---|---|---|
| **스크립트를 노드에 안 붙였다** | 파일만 만들고 Attach 를 안 함 | 인스펙터 맨 아래 `Script` 칸이 비었는지 |
| **함수 이름 오타** | `_Ready`, `ready`, `_redy` | GDScript 는 **`_ready` 정확히** 소문자·언더스코어 하나 |
| **`extends` 가 노드 타입과 불일치** | 스크립트가 아예 안 붙는다 | `extends Node3D` 인데 `MeshInstance3D` 에 붙이려 함 |
| **부모가 `_ready()` 를 오버라이드하고 `super()` 안 부름** | 상속받은 클래스에서만 발생 | 부모 클래스의 `_ready()` 를 부르려면 `super()` |
| **`add_child()` 를 안 했다** | 코드로 `.new()`/`instantiate()` 만 함 | §3 "메모리에 올린다가 무슨 뜻인가" 4단계 |

> **`_ready()` 는 노드당 평생 한 번이다.** `remove_child()` 로 뺐다가 다시 붙이면
> `_enter_tree()` 는 다시 불리지만 `_ready()` 는 불리지 않는다.
> 다시 붙을 때마다 실행할 초기화는 `_enter_tree()` 에 둔다.

### `pass` 는 무엇인가 — 스크립트를 붙이면 처음 보게 되는 것

노드에 스크립트를 붙이면 에디터가 이런 뼈대를 만들어 준다.

```gdscript
extends Button

# Called when the node enters the scene tree for the first time.
func _ready() -> void:
    pass # Replace with function body.
```

**`pass` 는 "아무 일도 하지 않는 문장"이다.**

`return` 과 헷갈리기 쉬운데 **완전히 다르다. `pass` 는 함수를 끝내지 않는다.**

```gdscript
func with_pass() -> String:
    pass
    print("실행된다")          # ← pass 뒤의 줄은 그대로 실행된다
    return "값"

func with_return() -> String:
    return "값"
    print("실행되지 않는다")    # ← return 뒤는 죽은 코드다
```

| | `pass` | `return` |
|---|---|---|
| 함수를 끝내나 | 🛑 **아니다** | ✅ 그렇다 |
| 뒤의 줄은 | **실행된다** | 실행되지 않는다 |
| 하는 일 | **없다** | 값을 돌려주며 빠져나온다 |

> **엔진에서 확인 (4.7.2)** — `pass` 를 지나간 함수는 뒤 줄을 실행했고
> (`["pass 다음 줄이 실행되었다"]`), `return` 뒤의 줄은 실행되지 않았다 (`[]`).

**그럼 왜 있는가 — GDScript 는 함수 몸통이 비면 문법 오류이기 때문이다.**

```
pass 없이 몸통을 비우면
  Parse Error: Expected indented block after function declaration.
pass 를 넣으면
  통과
```

**즉 `pass` 는 "여기 아직 코드가 없다"는 자리를 채우는 문장**이다.
템플릿에 함께 붙는 주석 `# Replace with function body.` 가 그 뜻이다 —
**지우고 여기에 코드를 쓰라**는 말이다.

```gdscript
func _ready() -> void:
    pass                 # ← 코드를 쓸 때는 지운다

func _ready() -> void:
    print("시작")        # ← 이렇게
```

남겨 두어도 동작에는 영향이 없지만 의미가 없다.

> **`pass` 만 있는 함수의 반환값은 `null` 이다.** `pass` 가 돌려준 것이 아니라
> **함수가 마지막 줄까지 도달해 그냥 끝났기 때문**이다. 반환값이 없는 함수는
> 자동으로 `null` 을 돌려준다 *(엔진 확인: 타입 `Nil`)*.

**`pass` 는 함수뿐 아니라 모든 빈 블록에 쓴다** — `if`, `for`, `while`,
`match` 의 분기도 마찬가지다.

---

## 5. 시그널(Signal) — 노드끼리 대화하는 방법

**노드가 어떤 사건(event)이 일어났음을 외부에 알리는 메커니즘**이다.

핵심은 **알리는 쪽이 받는 쪽을 모른다**는 것이다. 한 노드가 다른 노드의 함수를
직접 호출하지 않고 "이런 일이 있었다"고 방송만 하면, 관심 있는 노드들이 각자
받아서 처리한다. 이렇게 하면 **결합도(coupling)가 낮아진다.**

> 디자인 패턴의 **관찰자(Observer) 패턴**을 언어·엔진 차원에서 구현한 것이다.

### 왜 필요한가 — 직접 호출과 비교

적이 죽었을 때 UI 점수를 올리고, 사운드를 재생하고, 스포너에 알려야 한다고 하자.

```gdscript
# 🛑 직접 호출 — 적이 UI·사운드·스포너를 전부 알아야 한다
func die() -> void:
    get_node("/root/Main/UI/ScoreLabel").add_score(10)
    get_node("/root/Main/AudioManager").play("death")
    get_node("/root/Main/Spawner").on_enemy_died(self)
    queue_free()
```

이 코드의 문제는 **적이 씬 구조 전체를 알고 있다**는 것이다. UI 경로가 바뀌면
적 코드가 깨지고, 적을 다른 씬에서 재사용할 수 없으며, 적만 따로 테스트할 수 없다.

```gdscript
# ✅ 시그널 — 적은 "죽었다"는 사실만 알린다
signal died(score: int)

func die() -> void:
    died.emit(10)
    queue_free()
```

**적은 누가 듣는지 모른다.** 듣는 쪽이 알아서 연결한다. 수신자가 늘어나거나
줄어들어도 **적 코드는 한 글자도 바뀌지 않는다.**

### 시그널의 두 종류

| 종류 | 무엇 | 예 |
|---|---|---|
| **엔진(내장) 시그널** | 엔진이 이미 정의해 둔 것 | `Button.pressed`, `Area3D.body_entered`, `Node.ready` |
| **커스텀 시그널** | 내가 스크립트에서 `signal` 키워드로 선언한 것 | `signal died(score: int)` |

**둘은 사용 방법이 완전히 같다.** 선언만 엔진이 했느냐 내가 했느냐의 차이다.

> **엔진에서 확인 (4.7.2)** — 내장 시그널은 상속 계층을 따라 쌓인다.
> `ClassDB.class_get_signal_list()` 로 센 결과다.
>
> | 클래스 | 개수 | 그 클래스에서 새로 생긴 것 |
> |---|---|---|
> | `Node` | 13 | `ready` `renamed` `tree_entered` `tree_exiting` `tree_exited` `child_entered_tree` … |
> | `Area3D` | 25 | `body_entered` `body_exited` `area_entered` `area_exited` `input_event` `mouse_entered` … |
> | `BaseButton` | 33 | `pressed` `button_up` `button_down` `toggled` |
>
> **즉 버튼 하나에 33개의 시그널이 이미 달려 있다.** 무엇을 쓸 수 있는지는
> 인스펙터 옆 **Node 독 → Signals 탭**에서 전부 볼 수 있다.

### 선언 — `signal` 키워드

```gdscript
signal hit                          # 인자 없음
signal hit(damage: int)             # 인자 하나
signal item_picked(item: ItemData, count: int)   # 여러 개, 타입 자유
```

**인자 타입은 원하는 대로 지정한다.** 타입을 적어 두면 연결하는 함수의 시그니처가
맞는지 에디터와 LSP 가 검사해 준다. 적지 않아도 동작하지만 **적는 편이 좋다.**

### 🔑 Godot 4 에서 시그널은 "값"이다

**이것이 Godot 3 에서 넘어올 때 가장 헷갈리는 지점**이며, 왜 `hit.emit()` 처럼
점을 찍는지 설명해 준다.

`signal hit` 이라고 쓰면 **`hit` 이라는 `Signal` 타입의 값이 생긴다.**
문자열이 아니라 **객체**다.

```
엔진에서 확인 (4.7.2)
  typeof(hit) 의 이름   : Signal
  hit 를 출력하면        : SceneTree(test.gd)::[signal]hit
  hit is Signal         : true
  hit.get_object()      : 시그널을 가진 노드 자신
```

그래서 **점을 찍어 메서드를 부를 수 있다.**

| Godot 3 (문자열) | **Godot 4 (값)** |
|---|---|
| `emit_signal("hit", 10)` | **`hit.emit(10)`** |
| `connect("hit", self, "_on_hit")` | **`hit.connect(_on_hit)`** |
| 오타가 나도 **실행 전까지 모른다** | **오타 나면 그 자리에서 오류** |

**옛 방식도 아직 동작하지만 쓰지 않는다.** 문자열은 오타를 잡아 주지 못한다.

### 발신 — `emit()`

```gdscript
hit.emit()        # 인자 없는 시그널
hit.emit(10)      # 선언한 인자를 그대로 넘긴다
```

**"발산한다 / 방출한다(emit)"** 고 표현한다. 신호를 쏘아 보내는 것이지
누군가를 호출하는 것이 아니다 — **듣는 사람이 없어도 상관없다.**

### 받기 — `connect()`

**방법 1 — 코드에서**

```gdscript
func _ready() -> void:
    var enemy := $Enemy
    enemy.died.connect(_on_enemy_died)     # 함수 이름에 () 를 붙이지 않는다

func _on_enemy_died(score: int) -> void:
    total_score += score
```

`_on_enemy_died` 에 **괄호를 붙이지 않는 것**에 주의한다. 붙이면 함수를 *실행해서
그 결과*를 넘기게 된다. 붙이지 않아야 **함수 자체(`Callable`)** 가 넘어간다.

**방법 2 — 에디터에서**

1. **Scene 독**에서 시그널을 *보내는* 노드를 선택한다 (예: `Button`)
2. 오른쪽 **Inspector 옆의 Signals 탭**을 연다
3. 원하는 시그널을 **더블클릭**한다 (예: `button_down()`)
4. **Connect a Signal to a Method** 대화상자에서 *받을* 노드를 고르고 **Connect**
5. 받는 노드의 스크립트에 `_on_...` 함수가 **자동으로 생성**된다

**Signals 탭은 클래스 계층별로 묶여 있다.** 버튼을 선택하면
`BaseButton` / `Control` / `CanvasItem` / `Node` / `Object` 로 그룹이 나뉘는데,
**상속받은 모든 조상의 시그널이 쌓여서** 그렇다. `button_down()` 은 `BaseButton` 것이다.

**대화상자의 각 칸**

| 칸 | 뜻 |
|---|---|
| **From Signal** | **어떤 사건**을 받을 것인가 (`button_down()`) |
| **Connect to Script** | **누가 받을 것인가** — 받을 노드를 트리에서 고른다 |
| **Receiver Method** | **어느 함수가** 받을 것인가 (`_on_button_down`) |
| **Advanced** | 켜면 연결 플래그(`ONE_SHOT`·`DEFERRED`)와 추가 인자를 지정할 수 있다 |

**함수 이름은 에디터가 지어 준다.** 규칙은 `_on_` + **보내는 노드 이름** + `_` + 시그널 이름이다.

| 누가 받는가 | 자동 생성되는 이름 |
|---|---|
| **보내는 노드 자신** (버튼이 자기 시그널을 받음) | `_on_button_down` — **노드 이름이 빠진다** |
| 다른 노드 (`Main` 이 버튼 시그널을 받음) | `_on_button_button_down` |

> **`_on_` 접두사는 문법이 아니라 관례다.** 아무 이름이나 써도 동작한다.
> 다만 에디터가 이 이름을 지어 주고 모두가 그렇게 쓰므로 따르는 편이 좋다.

**🛑 연결은 코드가 아니라 씬 파일(`.tscn`)에 저장된다.**

```
[node name="Main" type="Node"]
[node name="Button" type="Button" parent="."]
[connection signal="button_down" from="Button" to="." method="_on_button_button_down"]
```

*(엔진에서 실제로 저장해 확인한 형식이다.)*

**이것이 에디터 연결의 가장 큰 함정이다.** 스크립트를 아무리 읽어도 **연결하는 코드가
없어서**, `_on_button_down()` 이 왜 불리는지 알 수 없다.

그래서 에디터가 표시해 준다 — **함수 왼쪽의 초록색 연결 아이콘**이 그것이고,
**"이 함수는 시그널에 연결되어 있다"** 는 뜻이다. 클릭하면 어느 연결인지 보여준다.
*(`_ready` 왼쪽에 붙는 다른 아이콘은 부모 메서드를 재정의했다는 표시로 성격이 다르다.)*

| | 에디터 연결 | 코드 연결 |
|---|---|---|
| 저장 위치 | `.tscn` | 스크립트 |
| 코드만 봐서 보이나 | 🛑 **안 보인다** | ✅ 보인다 |
| 동적으로 생성한 노드 | 불가 | ✅ 가능 |
| 언제 쓰나 | UI 버튼처럼 **씬에 고정된 것** | **그 외 대부분** |

> 코드로 연결한 것은 씬에 저장되지 않는다. `CONNECT_PERSIST` 플래그를 준 것만
> 저장되며, **에디터 연결이 바로 그 플래그를 쓴다** *(엔진 확인: 플래그 없이
> 저장하면 `[connection]` 줄이 생기지 않는다)*.

### 이 함수를 뭐라고 부르는가

시그널을 **받는 함수**를 부르는 말이 여럿이라 헷갈린다. Godot 기준으로 정리하면 이렇다.

| 부르는 말 | Godot 에서 | 비고 |
|---|---|---|
| **Receiver Method / 수신 메서드** | ✅ **에디터 UI 의 공식 명칭** | 연결 대화상자의 칸 이름이 그대로 `Receiver Method` 다 |
| **`Callable`** | ✅ **API 상의 정식 타입** | `connect()` 의 인자 이름이 `callable` 이다 |
| 콜백 (callback) | ⭕ 통용된다 | 일반 프로그래밍 용어. 뜻이 통하고 흔히 쓴다 |
| 이벤트 핸들러 | ⭕ 통용된다 | 다른 엔진·프레임워크 출신이 이렇게 부른다 |
| **"시그널 함수"** | 🛑 **권하지 않는다** | **시그널 자체**(`button_down`)와 **받는 함수**(`_on_button_down`)가 헷갈린다 |

> **엔진에서 확인 (4.7.2)** — `_on_ping` 의 타입은 `Callable` 이고,
> 연결 정보에도 `callable` 로 기록된다.

**실무에서 "콜백"이라고 해도 문제없다.** 다만 문서를 검색하거나 남에게 물을 때는
**"receiver method"** 또는 **"시그널을 받는 메서드"** 가 가장 정확하다.

### 실제 동작 — 엔진에서 확인한 것 (4.7.2)

| 질문 | 답 | 확인된 값 |
|---|---|---|
| **여러 개를 연결하면 순서는?** | **연결한 순서대로** 호출된다 | A → B 순으로 연결 후 emit → `["A", "B"]` |
| **듣는 사람이 없으면?** | **아무 일도 일어나지 않는다. 오류가 아니다** | 연결 0개에서 `emit()` → 정상 통과 |
| **같은 함수를 두 번 연결하면?** | 🛑 **거부되고 오류가 찍힌다** | 두 번째 `connect()` 반환값 `31` = `ERR_INVALID_PARAMETER`, 연결 수는 1 유지 |
| `connect()` 가 성공하면? | `0`(`OK`)을 반환한다 | |

**세 번째 항목이 실전에서 자주 걸린다.** `_ready()` 가 두 번 불리는 구조
(노드를 재사용하거나 풀링할 때)에서 같은 연결을 다시 시도하면 오류가 난다.
방어하려면 확인하고 연결한다.

```gdscript
if not enemy.died.is_connected(_on_enemy_died):
    enemy.died.connect(_on_enemy_died)
```

**한 번만 받고 자동으로 끊으려면** `CONNECT_ONE_SHOT` 을 쓴다.

```gdscript
enemy.died.connect(_on_enemy_died, CONNECT_ONE_SHOT)
```

> 엔진 확인 — 세 번 `emit()` 해도 **호출은 1회**, 그 뒤 **연결 수가 0** 이 된다.

### `await` — 시그널이 올 때까지 기다리기

시그널은 **함수를 멈춰 두는 용도로도 쓴다.**

```gdscript
func play_intro() -> void:
    print("시작")
    await animation_player.animation_finished    # 애니메이션이 끝날 때까지 멈춤
    print("애니메이션 끝난 뒤 실행")

    await get_tree().create_timer(2.0).timeout   # 2초 대기
    print("2초 뒤 실행")
```

**`emit()` 이 대기 중인 함수를 그 자리에서 재개시킨다.** 엔진에서 확인한 실행 순서다.

```
_waiter() 호출        → await 에서 멈춤
"호출 직후" 출력       ← 멈춰 있는 동안 다음 줄이 먼저 실행됨
done.emit(42)         → 멈춰 있던 _waiter 가 여기서 재개
"await 가 받은 값: 42" ← emit 문장이 끝나기 전에 출력된다
"emit 직후" 출력
```

`await` 로 받으면 **인자가 그대로 반환값이 된다** (`var v: int = await done`).

### 방향 규칙 — 통지는 위로, 명령은 아래로

시그널을 어디에 쓸지 헷갈릴 때의 기준이다.

| 방향 | 수단 | 예 |
|---|---|---|
| **자식 → 부모** (통지) | **시그널** | 체력 컴포넌트가 `died` 를 쏜다 |
| **부모 → 자식** (명령) | **직접 호출** | 부모가 `child.take_damage(10)` 을 부른다 |

**자식은 부모를 몰라야 한다.** 자식이 부모를 직접 부르면 그 자식은 그 부모
아래에서만 동작하게 되어 재사용할 수 없다.

### 더 깊이

| 알고 싶은 것 | 문서 |
|---|---|
| 연결 플래그 전체(`CONNECT_DEFERRED` 등), 인자 바인딩(`bind`), `await` 상세 | [gdscript.md](gdscript.md) §10·§11 |
| 시그널로 컴포넌트를 조합하는 실전 구조, 이벤트 버스 | [nodes-scenes.md](nodes-scenes.md) §10 |

> **물리 콜백 안에서 노드를 추가·삭제할 때는 `CONNECT_DEFERRED` 나
> `call_deferred()` 가 필요하다.** `body_entered` 같은 시그널은 물리 계산 도중에
> 불리므로, 그 안에서 씬 트리를 바꾸면 오류가 난다. → [gdscript.md](gdscript.md) §10

---

## 6. 에디터 화면 — 어디에 무엇이 있나

> 📄 **메뉴 항목 하나하나와 각 에디터 뷰의 화면은 별도 문서에 정리되어 있다.**
> → **[Godot 에디터 메뉴·화면 정리 (Google 문서)](https://docs.google.com/document/d/1b9LPX5Lp6AbaSfdsThvtci5HWcj3O3KQ6eFtJFXUvBw/edit?usp=sharing)**
>
> 이 절은 **어디에 무엇이 있는지 뼈대**만 세운다.
> `Scene`·`Project`·`Debug`·`Editor`·`Help` 메뉴 아래에 각각 무엇이 있는지,
> 2D·3D·Script·AssetLib **각 에디터 뷰가 실제로 어떤 화면인지**처럼
> **항목 단위로 찾을 때는 위 문서를 본다.**

```
┌──────────────────────────────────────────────────────────┐
│  [2D] [3D] [Script] [AssetLib]        ▶(실행)            │  ← 상단: 작업 모드 전환
├────────────┬──────────────────────────┬──────────────────┤
│ Scene 독   │                          │  Inspector 독    │
│            │        뷰포트            │                  │
│ 노드 트리  │   (지금 보고 있는 씬)     │  선택한 노드의    │
│ 구조       │                          │  프로퍼티 전부    │
├────────────┤                          │                  │
│ FileSystem │                          │                  │
│ 독         │                          │                  │
│ res:// 안의│                          │                  │
│ 파일 전부  │                          │                  │
├────────────┴──────────────────────────┴──────────────────┤
│  Output / Debugger / Audio  하단 패널                     │  ← print() 결과가 여기
└──────────────────────────────────────────────────────────┘
```

| 독 | 하는 일 | 자주 쓰는 조작 |
|---|---|---|
| **Scene** | 지금 씬의 노드 트리 | **Cmd+A** 자식 노드 추가 / **Cmd+Shift+A** 씬 인스턴싱 / **F2** 이름 변경 / **Cmd+D** 복제 |
| **Inspector** | 선택한 노드의 모든 프로퍼티 | 값 입력, 리소스 연결 |
| **FileSystem** | `res://` 안의 파일 | 드래그로 씬 인스턴싱·리소스 연결 |
| **Output** | `print()` 출력, 오류 | 게임을 돌린 뒤 여기부터 본다 |

`res://` 는 **프로젝트 폴더**를 가리키는 Godot 전용 경로다.
`user://` 는 세이브 파일이 저장되는 **사용자 데이터 폴더**다 (플랫폼마다 실제 위치가 다르다).

### 3D 뷰포트 위의 툴바 — 파란 압정을 조심한다

3D 편집 화면 상단에는 이동·회전·크기 도구가 줄지어 있다. 그중 **압정 모양 버튼이
`Preserve Children Transform`**(자식의 전역 변환 유지, 단축키 <kbd>P</kbd>)이다.
**켜져 있으면 부모를 옮겨도 자식은 화면의 원래 자리에 그대로 남는다.**

| 압정 | 부모를 위로 5m 옮기면 |
|---|---|
| **꺼짐(회색)** — 보통 이 상태 | 자식도 **함께 5m 올라간다.** 자식의 로컬 Position 은 그대로 |
| **켜짐(파랑)** | 자식은 **제자리에 남는다.** 대신 자식의 로컬 Y 가 자동으로 −5 로 바뀐다 |

> 🛑 **캐릭터가 길게 늘어난 것처럼 보이면 이것부터 확인한다.** 부모의 이동 기즈모만
> 위로 올라가고 `MeshInstance3D`·`CollisionShape3D` 는 아래에 남아, 원점과 자식
> 사이가 늘어진 것처럼 보인다.
>
> **고치는 법** — 3D 뷰포트를 클릭해 포커스를 준 뒤 <kbd>P</kbd> 를 누르거나 압정을
> 눌러 회색으로 만든다. 그다음 자식들의 Transform 을 초기화하고 부모 위치를 다시 잡는다.

**쓸 데가 있어서 있는 기능이다** — 자식들의 배치는 건드리지 않고 **부모의 원점(피벗)만
옮길 때**, 또는 계층 구조를 정리할 때 쓴다. 평소에는 꺼 둔다.

> ⚠️ **버튼은 에디터 옵션이지만 결과는 씬에 남는다.** 켠 채로 부모를 옮기면 자식의
> 로컬 Transform 이 실제로 바뀌고, 저장하면 `.tscn` 에 그대로 기록된다.
> 노드에 저장되는 속성인 **`top_level`**(부모의 변환을 아예 상속하지 않음)과는 성격이
> 다르다 — 이쪽은 편집 중에만 작동하는 보정이다.

*(엔진 4.7.2 의 툴팁 원문: "When enabled, transforming a node will preserve the
global transform of its children." 단축키 경로는 `spatial_editor/preserve_children_transform`
이며 [공식 문서](https://docs.godotengine.org/en/stable/tutorials/3d/introduction_to_3d.html)
에도 <kbd>P</kbd> 로 명시되어 있다.)*

### 새 프로젝트를 만들면 이미 들어 있는 파일들

Godot 이 프로젝트를 만들 때 **자동으로 넣어 주는 파일**이 셋 있다. 씬도 스크립트도
아니라 용도가 잘 안 보이는데, **셋 다 Godot 자신이 아니라 바깥 도구를 위한 것**이다.

| 파일 | 누가 읽나 | 하는 일 |
|---|---|---|
| **`.editorconfig`** | **외부 에디터·IDE** (VS Code 등) | 코드 스타일 규약 — 인코딩·들여쓰기를 통일 |
| `.gitattributes` | git | `* text=auto eol=lf` — 개행을 LF 로 통일해 OS 가 섞여도 diff 가 깨지지 않게 |
| `.gitignore` | git | `.godot/`(임포트 캐시)·`/android/` 를 커밋에서 뺀다 |

**`.editorconfig` 는 [EditorConfig](https://editorconfig.org) 규약을 따르는 파일이다.**
"이 프로젝트의 코드는 이렇게 저장한다"를 적어 두면 **VS Code·Sublime·JetBrains 등
어떤 에디터로 열어도 같은 규칙이 적용된다.** 사람마다 인코딩·들여쓰기가 달라
**고치지도 않은 줄까지 diff 에 뜨는 일**을 막는 것이 목적이다.

Godot 이 넣어 주는 내용은 두 줄뿐이다.

```ini
root = true       # 여기가 최상위 — 상위 폴더의 .editorconfig 를 더 찾지 않는다

[*]               # 모든 파일에 적용 (glob 패턴)
charset = utf-8   # UTF-8 로 저장한다
```

`root = true` 가 필요한 이유는 **EditorConfig 가 파일이 있는 폴더에서 위로 계속
거슬러 올라가며 설정을 찾기 때문**이다. 이 줄이 없으면 홈 디렉터리에 있는 다른 설정까지
끌어온다. `charset = utf-8` 은 **한글 주석이 깨지지 않게** 한다 — Godot 은 `.gd`·`.tscn`
을 UTF-8 로 다루므로 외부 에디터가 다른 인코딩으로 저장하면 글자가 깨진다.

> 🛑 **정작 Godot 내장 스크립트 에디터는 이 파일을 읽지 않는다 — 만들어 주기만 하고
> 자기는 쓰지 않는다.** *(엔진 확인 4.7.2 — 바이너리에 생성 실패 메시지
> `Couldn't create .editorconfig in project path.` 는 있지만, `indent_style`·`end_of_line`
> 같은 EditorConfig 표준 키를 읽는 코드는 없다.)* 내장 에디터의 들여쓰기·인코딩은
> `Editor Settings > Text Editor > Behavior` 가 따로 정한다.
> **즉 이 파일은 순전히 외부 에디터를 위한 배려다.**

---

## 7. 에디터 조작을 내 손에 맞춘다 — 마우스와 단축키

**Godot 의 기본 조작은 "오른손 마우스 + 3버튼 마우스"를 전제로 만들어져 있다.**
그 전제에서 벗어나면 **일부 기능이 아예 동작하지 않는다.** 익숙해지려 애쓰지 말고
설정을 바꾼다. 3D 작업은 뷰포트를 하루에 수백 번 돌리므로 이 차이가 크게 쌓인다.

> 🛑 **에디터 설정은 사람이 직접 바꾼다.** Claude 는 파일을 고치지 않고
> **어느 메뉴에서 무엇을 어떤 값으로** 바꿀지만 알려준다 (→ [CLAUDE.md](../../../../CLAUDE.md)).
> 아래 표의 "UI 경로"를 그대로 따라가면 된다.

### 먼저 용어 — 궤도 회전과 프리룩은 다르다

**둘 다 카메라를 돌리지만 무엇을 중심으로 도는지가 다르다.** 이 둘을 섞어서 이해하면
설정을 어디서 바꿔야 할지 계속 헷갈린다.

| 용어 | 무엇인가 | 비유 |
|---|---|---|
| **궤도 회전 (orbit)** | 카메라가 **한 점을 중심으로 그 주위를 돈다** | **물체를 손에 들고 이리저리 돌려 보는 것** |
| **프리룩 (freelook)** | 카메라가 **제자리에서 방향만 바꾼다** | **서서 고개를 돌리는 것** |

```
궤도 회전 — 중심은 대상, 카메라가 움직인다
        카메라
          ↘
    ●  ← 대상은 화면 가운데 고정
          ↗
        카메라

프리룩 — 중심은 카메라 자신, 카메라는 제자리
      ← ●  →      카메라 위치는 그대로, 보는 방향만 바뀐다
```

**따라서 쓰임도 다르다.**

| | 궤도 회전 | 프리룩 |
|---|---|---|
| 무엇을 볼 때 | **하나의 물체**를 여러 각도에서 | **넓은 공간**을 돌아다니며 |
| 대상이 화면에서 | 가운데 유지된다 | 벗어난다 |
| 라리엔에서 | 건물·캐릭터 모델을 점검할 때 | 맵을 훑어볼 때 |

**팬(pan)** 은 회전이 아니다. **카메라가 보는 방향을 유지한 채 평행으로 미끄러지는 것**이다.
지도를 손으로 밀어 옮기는 것과 같다.

### 3D 뷰포트의 기본 조작

| 동작 | 기본 조작 |
|---|---|
| **궤도 회전** (대상을 중심으로 돌기) | **가운데 버튼 드래그** |
| **팬** (평행 이동) | **Shift + 가운데 버튼** |
| **줌** | 휠 |
| **프리룩** (제자리에서 방향 전환 + 이동) | **우클릭 홀드 + WASD** |
| 프리룩 토글 | Shift+F |

**앞의 둘이 가운데 버튼에 묶여 있다는 점이 중요하다.**

### 🖱 가운데 버튼이 없는 마우스 — Magic Mouse 등

**Magic Mouse 에는 가운데 버튼이 없다. 즉 궤도 회전과 팬이 아예 되지 않는다.**
단축키보다 이쪽이 먼저 막히는 문제다.

**Editor → Editor Settings → Editors → 3D → Navigation** 에서 푼다.

| 설정 | 무엇 | 권장 |
|---|---|---|
| **Emulate 3 Button Mouse** | **Option(Alt) + 좌클릭**을 가운데 버튼으로 대신 쓴다 | ✅ **가장 먼저 켠다** |
| **Navigation Scheme** | Godot / Maya / Modo 중 선택 | **Maya** — Alt 조합 기반이라 3버튼 없는 마우스에 잘 맞는다 |
| **Orbit Mouse Button** | 궤도 회전에 쓸 버튼을 직접 지정 | 위 둘로 안 되면 여기서 바꾼다 |
| **Pan Mouse Button** | 팬에 쓸 버튼 | 동일 |
| **Zoom Mouse Button** | 줌에 쓸 버튼 | 동일 |

> **엔진 확인 (4.7.2)** — 위 다섯 항목은 실제로 존재한다.
> 설정 키는 `editors/3d/navigation/emulate_3_button_mouse`,
> `.../navigation_scheme`, `.../orbit_mouse_button`, `.../pan_mouse_button`,
> `.../zoom_mouse_button` 이다.
> **버튼을 개별 지정하는 세 항목은 버전에 따라 없을 수도 있다고 알려져 있으나,
> 4.7.2 에는 있다.**

**Navigation Scheme 을 Maya 로 두면** 조작이 이렇게 바뀐다 — 이 편이
Magic Mouse 에 훨씬 낫다.

```
Alt + 좌클릭 드래그   → 궤도 회전
Alt + 가운데 드래그    → 팬        (Emulate 3 Button 과 함께 쓰면 Alt+좌클릭에 흡수됨)
Alt + 우클릭 드래그    → 줌
```

### ⌨ 프리룩 키를 왼손잡이에 맞춘다

프리룩(우클릭 홀드 상태의 1인칭 이동)은 기본이 **WASD** 다. 이것은
**마우스를 오른손에 두어 왼손이 키보드 좌측에 있다**는 전제다.

**마우스를 왼손에 두면 오른손이 키보드 우측에 있으므로 WASD 는 손이 겹친다.**
오른손이 자연스럽게 닿는 자리로 옮긴다.

**Editor → Editor Settings → Shortcuts 탭 → `freelook` 으로 검색**

| 단축키 이름 | 기본값 | **IJKL 안** | **화살표 안** |
|---|---|---|---|
| `spatial_editor/freelook_forward` | W | **I** | ↑ |
| `spatial_editor/freelook_backwards` | S | **K** | ↓ |
| `spatial_editor/freelook_left` | A | **J** | ← |
| `spatial_editor/freelook_right` | D | **L** | → |
| `spatial_editor/freelook_up` | E | **O** | PageUp |
| `spatial_editor/freelook_down` | Q | **U** | PageDown |
| `spatial_editor/freelook_speed_modifier` | Shift | 그대로 | 그대로 |
| `spatial_editor/freelook_slow_modifier` | Alt | 그대로 | 그대로 |
| `spatial_editor/freelook_toggle` | Shift+F | 그대로 | 그대로 |

**IJKL 을 권한다.** 화살표는 Scene 독에서 노드 이동·선택에도 쓰여 문맥에 따라
가로채이는 일이 있고, 손을 홈 포지션에서 더 멀리 옮겨야 한다.

> ⚠️ **기존 키를 지우고 새 키로 교체한다.**
> 프리룩 단축키는 **첫 번째로 등록된 키만 인식**되는 동작이 보고된 적이 있다.
> 두 번째 바인딩을 추가하는 방식으로는 안 먹을 수 있으므로,
> **W/A/S/D 를 지운 뒤 I/J/K/L 을 넣는다.**

**Shift(가속)와 Alt(감속)는 그대로 둔다.** 양손 어느 쪽에서도 닿고,
다른 단축키와 충돌하지 않는다.

### macOS 에서 먼저 확인할 것

**시스템 설정 → 마우스 → 보조 클릭(Secondary click)** 이 켜져 있어야 한다.

**꺼져 있으면 우클릭이 안 되고, 우클릭이 안 되면 프리룩 자체가 시작되지 않는다.**
Magic Mouse 는 이 항목이 꺼진 상태로 오는 경우가 있다.

| 항목 | 상태 | 영향 |
|---|---|---|
| 보조 클릭 | **켜야 한다** | 우클릭 → **프리룩 진입**, 뷰포트 컨텍스트 메뉴 |
| 두 손가락 스크롤 | 기본 켜짐 | 휠로 인식되어 **줌은 문제없다** |
| 스크롤 방향(자연스럽게) | 취향 | 줌 방향이 뒤집혀 느껴지면 여기 또는 에디터의 `zoom_style` 을 본다 |

### 게임 안의 조작은 별개다 — `InputMap`

**에디터 설정은 에디터에만 적용된다. 게임 안 조작과 아무 관계가 없다.**

게임 조작은 **Project → Project Settings → Input Map** 에서 **액션(action)** 으로
정의하고, 코드는 **액션 이름으로만** 접근한다.

```gdscript
# ✅ 이렇게 쓴다 — 어떤 키인지 코드가 모른다
if Input.is_action_pressed("move_forward"):
    ...

# 🛑 이렇게 쓰지 않는다 — 키가 코드에 박힌다
if Input.is_key_pressed(KEY_W):
    ...
```

**이유는 리바인딩이다.** 액션으로 감싸 두면 나중에 **플레이어가 직접 키를 바꾸는
설정 메뉴**를 붙일 때 **코드를 한 줄도 고치지 않아도 된다.**
키를 코드에 박아 두면 그 메뉴를 만들 때 전부 다시 써야 한다.

**리바인딩 API** (4.7.2 에서 시그니처 확인)

```gdscript
InputMap.action_erase_events("move_forward")          # 기존 바인딩 전부 삭제
InputMap.action_add_event("move_forward", new_event)  # 새 키 등록

InputMap.action_erase_event(action, event)            # 하나만 삭제
InputMap.action_get_events(action) -> InputEvent[]    # 현재 바인딩 조회
InputMap.action_has_event(action, event) -> bool
InputMap.load_from_project_settings()                 # 기본값으로 되돌리기
```

**키 이벤트는 `physical_keycode` 로 만든다.**

```gdscript
var ev := InputEventKey.new()
ev.physical_keycode = KEY_I        # keycode 가 아니라 physical_keycode
InputMap.action_add_event("move_forward", ev)
```

`keycode` 는 **키캡에 적힌 문자**라 자판 배열(QWERTY/AZERTY/드보락)이 다르면
엉뚱한 키가 된다. `physical_keycode` 는 **키의 물리적 위치**라 배열과 무관하게
같은 자리를 가리킨다 *(엔진 확인: `InputEventKey.physical_keycode`, 기본값 `0`)*.

> **Steam(PC) 버전에서는 리바인딩 메뉴가 사실상 필수다.**
> 왼손잡이, 다른 자판 배열, 접근성 요구가 전부 여기로 들어온다.
> **지금 액션 이름만 제대로 정해 두면 나중에 할 일이 거의 없다.**
> 저장·불러오기 구현은 [input-ui.md](input-ui.md) 에 있다.

---

## 8. 동영상 강좌 — 손으로 한 번 따라 만들어 본다

**개념은 한 번 따라 만들어 봐야 손에 붙는다.** 아래 넷은 처음부터 끝까지 따라갈 수
있는 강좌이고, 이 문서의 어느 절과 맞닿는지를 함께 적어 둔다.

> 🛑 **강좌의 값·구조를 그대로 라리엔 3D 에 옮기지 않는다.** 카메라 각도·조명·성능
> 예산은 [SSOT.md](../../game/references/SSOT.md) 가 최종 권위다. 강좌는 **엔진 조작을
> 익히는 용도**로 본다.

| | 강좌 | 무엇에 좋은가 |
|---|---|---|
| ① | [Godot 4.7 완전 초보 라이브 트레이닝](https://www.youtube.com/watch?v=QntG8plRY1M) | **에디터만으로 첫 게임까지** — 전체 흐름 잡기 |
| ② | Build a 3D House in Godot 4.7 (GodotwithMe) | **안드로이드 편집기**로 만드는 짧은 시리즈 |
| ③ | [Godot 3D Beginner — Walking Simulator](https://www.youtube.com/watch?v=d2i00O4bfDk&list=PLPdCd0OwI4tarX0u6ukZkMruBQ5AtAMQ0&index=2) | **3D 에셋 임포트·잔디·물·하늘** |
| ④ | [CSG 로 도로 프로토타입 → Blender → 지형](https://www.youtube.com/watch?v=3JH5fP4MjuE) | **블록아웃과 Blender 왕복** 실전 |

---

### ① 3시간 만에 첫 게임 — 비주얼 에디터만으로

**Complete Beginners Live Training for Godot 4.7** · Visual Coding Hub

- 영상: <https://www.youtube.com/watch?v=QntG8plRY1M> — 3시간 라이브 빌드 풀버전
- 게임 플레이·다운로드, 소스코드·프로젝트 파일: 영상 설명란의 `visualcodinghub.itch.io` 링크
- 결과물 플레이 영상: *Simple 3d Game I made in 3 Hours on a YouTube Live*

> "In this Complete Beginners Live Training for Godot 4.7, I will take you from zero to
> your first playable game using only the visual editor. No prior experience needed."

**사전 지식이 전혀 없어도 되고, 비주얼 에디터만으로** 플레이 가능한 게임까지 간다.
다루는 항목이 이 문서 §1~§7 과 거의 그대로 겹친다.

| 강좌가 다루는 것 | 이 문서에서는 |
|---|---|
| Godot 엔진 소개 | §1 |
| 에디터 인터페이스 소개 | §6 |
| 알아 두면 좋은 에디터 기능 | §6 · §7 |
| 노드 소개 | §1 |
| 유용한 애드온 소개 | [asset-store.md](asset-store.md) |
| 스크립팅 경로 선택 — GDScript 인가 비주얼 스크립팅인가 | §4 · [gdscript.md](gdscript.md) |
| 빠른 코드 팁 | [gdscript.md](gdscript.md) |
| 인디 게임 개발자를 위한 조언 | — |

> **라리엔 3D 는 GDScript 로 간다.** 강좌의 "스크립팅 경로 선택" 부분은 이미 판단이
> 끝난 항목이니 비교 설명만 참고하고 결론은 따르지 않는다.

---

### ② 모바일에서 만든다면 — 안드로이드 편집기로 집 짓기

**Build a 3D House in Godot 4.7 — Part 1** · GodotwithMe · 2026-07-10 · 3분 13초

새 프로젝트 생성부터 **바닥·카메라·조명·하늘**을 설정하고 집을 만들어 가는
왕초보 시리즈다. 한 편이 3분대라 부담이 없다.

| 편 | 내용 | 관련 문서 |
|---|---|---|
| 1편 | 새 프로젝트, 바닥·카메라·조명·하늘 | §6 · [3d-core.md](3d-core.md) · [rendering-3d.md](rendering-3d.md) |
| 2편 | `BoxMesh` 로 벽 만들기 | [level-design.md](level-design.md) |
| 3편 | CSG 로 문과 창문 뚫기 | [level-design.md](level-design.md) |
| 4편 | 박공지붕 만들기 | [level-design.md](level-design.md) |

> 🛑 **이 시리즈는 안드로이드용 Godot 편집기를 쓴다.** 데스크톱 에디터와 화면 배치와
> 조작이 다르다. **모바일에서 제작할 때** 보고, 데스크톱으로 작업 중이라면 ①·③ 을 본다.

---

### ③ 3D 워킹 시뮬레이터 — 에셋 임포트부터 잔디·물·하늘까지

**Godot 3D Beginner Tutorial series** · 재생목록 전체

- 영상: <https://www.youtube.com/watch?v=d2i00O4bfDk&list=PLPdCd0OwI4tarX0u6ukZkMruBQ5AtAMQ0&index=2>

**완전 초보 대상**이며 Godot 경험도 게임 개발 경험도 필요 없다. 시리즈를 끝내면
걸어 다닐 수 있는 3D 워킹 시뮬레이터 하나가 남는다.

| 배우는 것 | 이 문서·다른 문서에서는 |
|---|---|
| 에디터 안에서 움직이는 법 | §6 · §7 |
| 프로젝트에 에셋 임포트 | [resources-assets.md](resources-assets.md) |
| 잔디·물·하늘 넣기 | [rendering-3d.md](rendering-3d.md) · [shaders-3d.md](shaders-3d.md) |
| 걸어 다닐 수 있는 3D 만들기 | [physics-3d.md](physics-3d.md) |

**코드가 많은 주제는 뒤로 미루고 에디터에 익숙해지는 것을 먼저 둔다** — 한 단계씩
직접 만들어 보며 배우는 구성이라, 이 문서 §0 의 1단계와 병행하기 좋다.

---

### ④ CSG 로 도로를 깔고 Blender 로 지형을 만든다

- 영상: <https://www.youtube.com/watch?v=3JH5fP4MjuE>

**CSG 로 게임플레이용 도로를 프로토타이핑한 뒤 Blender 로 내보내 지형을 만들고
다시 Godot 으로 가져오는** 실제 작업 과정을 처음부터 끝까지 보여 준다. 대본 없이
작업하며 말하는 영상이라 정돈되어 있지는 않지만, **블록아웃 → 지형 → 재임포트**
왕복이 실제로 어떻게 굴러가는지 보기에는 이만한 게 없다.

| 시각 | 내용 |
|---|---|
| 0:00 | 미리보기 |
| 0:44 | 첫 번째 도로 프로토타이핑 |
| 1:55 | 첫 번째 도로 테스트와 수정 |
| 3:05 | 두 번째 도로 |
| 4:25 | 세 번째 도로 |
| 6:03 | 아스팔트 |
| 6:40 | 레벨 전체 테스트 |
| 7:49 | Blender 로 내보내기 |
| 8:36 | Shrinkwrap 설정 |
| 10:26 | 안쪽 지형 타임랩스 |
| 13:36 | Godot 으로 임포트 |
| 14:19 | 안쪽 지형 테스트 |
| 14:52 | 바깥쪽 지형 타임랩스 |
| 18:10 | Blender 작업 완료 |
| 18:49 | 마무리 |
| 20:17 | 완성 |

**라리엔 3D 와 가장 가까운 강좌다.** CSG 블록아웃은 [level-design.md](level-design.md),
Blender 왕복과 임포트 설정은 [resources-assets.md](resources-assets.md) 에 있다.

> 🛑 **지형 물량은 그대로 따라가지 않는다.** 최소 지원 사양은 **3GB RAM 안드로이드**이고
> 드로우콜·정점 예산은 [performance-mobile.md](performance-mobile.md) §0 과
> [lowend-3gb-60fps.md](lowend-3gb-60fps.md) 가 정한다.

---

## 9. 실전 — 3D 캐릭터 컨트롤러를 한 줄씩 읽는다

여기까지 읽었다면 **노드**(§1), **씬**(§2), **인스턴싱**(§3), **스크립트와 생명주기**(§4)를
따로따로는 안다. 이 절은 그 넷이 **한 파일 안에서 어떻게 맞물리는지**를 실제로 도는
코드로 보여 준다.

다루는 것은 **3D 캐릭터 컨트롤러** — 마우스로 시점을 돌리고, 키보드로 걷고, 점프하고,
중력에 떨어지고, 벽에 부딪히면 미끄러지는 그것이다. 3D 게임을 만들면 **가장 먼저**
만들게 되는 스크립트이고, Godot 이 `CharacterBody3D` 노드에 기본 템플릿으로
제공하는 코드이기도 하다.

> 🛑 **라리엔 3D 본편에는 이 코드를 그대로 쓰지 않는다.** 이 예제는 마우스로 시점을
> 자유롭게 돌리지만, 라리엔은 [SSOT](../../game/references/SSOT.md) 에서 **카메라 회전
> 3축을 전부 고정**하기로 결정되어 있다(피치 −45° 고정, 요 고정, 롤 0°, 줌만 허용).
> 여기서 배울 것은 **`CharacterBody3D` 로 몸을 움직이는 방법**이고, 카메라 조작 부분은
> "Godot 표준 예제는 이렇게 한다"는 참고로만 본다.

---

### 9.1 먼저 씬 구조를 본다 — 코드보다 이게 먼저다

```
world.tscn                        ← 메인 씬 (project.godot 의 run/main_scene)
├── WorldEnvironment              ← 하늘·글로우
├── DirectionalLight3D            ← 태양광
├── PC          ◄── pc.tscn 인스턴스 + pc.gd 스크립트   ★ 이 절의 주인공
│   ├── MeshInstance3D            ← 눈에 보이는 캡슐
│   ├── CollisionShape3D          ← 부딪히는 캡슐 (보이지 않는다)
│   └── Camera3D                  ← 화면을 찍는 눈
└── Map         ◄── Map.gltf 인스턴스 (지형)
```

**보이는 몸(`MeshInstance3D`)과 부딪히는 몸(`CollisionShape3D`)은 별개다.**
초보자가 자주 헷갈리는 부분인데, 메시는 **그림**일 뿐이고 충돌은 **콜리전 셰이프**가
담당한다. 둘 중 하나만 있어도 게임은 돌지만 — 메시만 있으면 유령처럼 통과하고,
셰이프만 있으면 보이지 않는 채로 부딪힌다.

#### ⚠️ 스크립트가 붙은 자리를 확인한다

```
pc.tscn    → 스크립트 없음
world.tscn → PC 인스턴스에 pc.gd 가 얹혀 있음
```

`.tscn` 파일을 열어 보면 이렇게 되어 있다.

```gdscript
[node name="PC" parent="." instance=ExtResource("1_nnsk1")]
script = ExtResource("2_rwgxs")     # ← world.tscn 쪽에서 덧붙인 스크립트
```

**즉 `pc.tscn` 을 다른 씬에 가져다 놓으면 이 스크립트는 따라가지 않는다.**
그 씬의 PC 는 움직이지 않는 캡슐이 된다. §4 [`_ready()` 가 실행되지
않는다](#_ready-가-실행되지-않는다--파일이-있다고-실행되는-게-아니다) 와 같은 뿌리의
문제다 — **스크립트는 "파일"이 아니라 "노드"에 붙는다.**

PC 를 여러 맵에서 쓸 계획이라면 `pc.tscn` 의 **루트 노드에 직접** 붙이는 편이 낫다.
그래야 씬을 인스턴싱할 때 스크립트가 함께 따라온다.

#### 실행하면 무슨 일이 일어나나

`world.tscn` 에서 PC 는 `y = 6.82`, 지형(Map)은 `y = 2.50` 에 있다.
즉 **PC 는 지형보다 4.3m 위 공중에서 시작한다.** <kbd>F5</kbd> 를 누르면 캡슐이
잠깐 떨어져 바닥에 닿는데, 이것이 아래 중력 코드가 실제로 도는 모습이다.

---

### 9.2 `extends CharacterBody3D` — 어떤 "몸"을 고를 것인가

```gdscript
extends CharacterBody3D
```

§4 에서 봤듯 `extends` 는 **이 스크립트가 어떤 노드의 기능을 물려받는가**를 정한다.
`CharacterBody3D` 를 상속했으므로 `velocity`, `move_and_slide()`, `is_on_floor()` 를
선언 없이 그냥 쓸 수 있다.

**물리 바디 4종을 고르는 기준과 `CharacterBody3D` 가 키네마틱인 이유는
[§1 의 "3D 게임에서 실제로 만나는 노드들"](#3d-게임에서-실제로-만나는-노드들--몸--모양--그림)
에서 이미 다뤘다.** 여기서 코드를 읽는 데 필요한 것은 **역할 분담 하나**다.

| | 담당 |
|---|---|
| **어디로 얼마나 빨리 갈 것인가** | 🧑‍💻 **내 스크립트** (`velocity` 에 써 넣는다) |
| **가다가 부딪히면 어떻게 할 것인가** | ⚙️ **엔진** (`move_and_slide()` 가 처리) |

---

### 9.3 Godot 의 3D 좌표 규약 — 왕초보가 가장 먼저 넘어지는 곳

코드를 읽기 전에 **반드시** 머리에 넣어야 하는 세 가지다.

#### ① 1 단위 = 1 미터

`position.y = 2` 는 "2 미터 위"다. 픽셀이 아니다. 2D 에서 오다가 3D 로 넘어오면
`100` 같은 숫자를 쓰기 쉬운데, 3D 에서 100 은 **축구장 길이**다.

#### ② −Z 가 앞이다 (여기서 다들 넘어진다)

```
        +Y  위
         │
         │
         │
         └──────── +X  오른쪽
        ╱
      ╱
    −Z  앞 ◄── 카메라가 기본으로 바라보는 방향
```

| 방향 | 축 |
|---|---|
| 앞 (forward) | **−Z** ← 음수다 |
| 뒤 | +Z |
| 오른쪽 | +X |
| 왼쪽 | −X |
| 위 | +Y |
| 아래 | −Y |

**"앞으로 가는데 왜 마이너스인가"** — Godot 이 OpenGL 의 오른손 좌표계를 따르기
때문이다. 이유를 외울 필요는 없고, **−Z 가 앞**이라는 사실만 몸에 배면 된다.

이 규약 때문에 나중에 `Vector3(input_dir.x, 0, input_dir.y)` 에서 **부호를 뒤집지
않아도 맞아떨어지는** 일이 생긴다. 9.8 에서 다시 나온다.

#### ③ 회전은 전부 라디안(radian)이다

`rotation.x = 90` 이라고 쓰면 90도가 아니라 **90 라디안**(약 5157도)이 된다.

| | 값 |
|---|---|
| 180도 | π ≈ 3.14159 라디안 |
| 90도 | π/2 ≈ 1.5708 라디안 |
| 1도 | ≈ 0.01745 라디안 |

사람이 읽을 코드에는 **`deg_to_rad(90)`** 처럼 변환 함수를 쓴다. 반대는 `rad_to_deg()`.

> **인스펙터는 도(degree)로 보여 준다.** 에디터에서 Rotation 이 `90` 이라고 적혀
> 있어도 코드에서 `rotation.x` 를 읽으면 `1.5708` 이 나온다. 화면과 코드의 단위가
> 다르다는 걸 알고 있어야 한다.

---

### 9.4 전체 코드

이제 실제 코드다. **주석이 코드보다 긴데, 그게 이 파일의 목적이다.**
한 번 훑어보고, 아래 9.5~9.10 의 보충 해설로 넘어간다.

```gdscript
extends CharacterBody3D

# =============================================================================
# PC(Player Character) 이동·시점 컨트롤러
#
# 【이 스크립트가 붙는 자리】
#   pc.tscn 자체가 아니라 world.tscn 의 "PC" 인스턴스에 스크립트가 얹혀 있다.
#   즉 pc.tscn 을 다른 씬에 가져다 놓으면 이 스크립트는 따라가지 않는다.
#   PC 를 여러 곳에서 쓸 계획이라면 pc.tscn 의 루트 노드에 직접 붙이는 편이 낫다.
#
# 【CharacterBody3D 란】
#   물리 바디 중 "키네마틱(kinematic)" 종류다. RigidBody3D 와 달리 물리 엔진이
#   대신 밀어 주지 않는다. 매 물리 틱마다 우리가 원하는 속도를 velocity 에 써 넣고
#   move_and_slide() 를 호출하면, 엔진이 그 속도만큼 몸통을 밀어 보면서
#   충돌체에 부딪히면 멈추고, 벽에는 달라붙는 대신 미끄러지게(slide) 해 준다.
#   "어떻게 움직일지"는 전적으로 이 스크립트의 책임이고, 엔진은 "부딪히면
#   어떻게 처리할지"만 담당한다.
#
# 【Godot 3D 좌표 규약】
#   - 1 단위 = 1 미터
#   - -Z 가 앞(forward), +X 가 오른쪽, +Y 가 위
#   - 회전값은 전부 라디안(radian). 도(degree)를 쓰려면 deg_to_rad() 로 변환한다.
#
# 【현재 시점은 1인칭이 아니라 3인칭이다】
#   pc.tscn 의 Camera3D 위치는 (0, 0, 1.6885) 이다. +Z 는 뒤쪽이므로 카메라가
#   캡슐 중심에서 1.69m "뒤"에 놓여 있고, 높이는 캡슐 한가운데(눈높이가 아니다).
#   그래서 화면에는 캡슐 뒷모습이 보인다.
#   1인칭으로 바꾸려면 카메라를 (0, 눈높이, 0) 근처로 옮기면 된다.
# =============================================================================


# ---------------------------------------------------------------------------
# 인스펙터에서 조절 가능한 값들 (@export)
#
# @export 를 붙이면 Godot 에디터 인스펙터 창에 노출되어, 코드를 고치지 않고
# 씬 인스턴스마다 다른 값을 줄 수 있다. 여기 적힌 값은 어디까지나 "기본값"이고,
# 씬에서 값을 바꿨다면 씬에 저장된 값이 이긴다.
# ---------------------------------------------------------------------------

# 수평 이동 속도. 단위는 m/s.
# 3.0 은 사람이 빠르게 걷는 정도의 속도다. 달리기는 보통 5~7 정도를 쓴다.
@export var SPEED = 3.0

# 점프하는 순간 단 한 틱에만 Y 속도에 꽂아 넣는 값. 단위는 m/s.
# 도달 높이는 대략 JUMP_VELOCITY^2 / (2 * 중력) 이다.
# 기본 중력 9.8 m/s^2 기준으로 4.5^2 / 19.6 ≈ 1.03m 까지 뛴다.
@export var JUMP_VELOCITY = 4.5

# 마우스 감도. "마우스가 1픽셀 움직일 때 몇 라디안 회전할 것인가"를 뜻한다.
# 0.003 rad ≈ 0.17도. 즉 마우스를 1000픽셀 끌면 약 172도 돌아간다.
@export var SENSITIVITY = 0.003


# 카메라 노드 참조.
#
# @onready 는 "이 노드가 씬 트리에 들어간 직후에 대입하라"는 뜻이다.
# 그냥 var 로 쓰면 자식 노드가 아직 만들어지기 전에 $Camera3D 를 찾게 되어
# null 이 들어간다. 노드 참조에는 사실상 항상 @onready 를 붙인다고 보면 된다.
#
# 카메라는 이 몸통의 자식이므로, 아래에서 몸통을 rotate_y() 로 돌리면
# 카메라도 함께 돌아간다. 그래서 좌우 회전(요)은 몸통이, 상하 회전(피치)은
# 카메라가 따로 담당하는 구조가 된다.
@onready var camera_3d: Camera3D = $Camera3D


# 노드가 씬 트리에 들어오고 자식들까지 준비된 뒤 한 번 호출된다.
func _ready():
	# 마우스 커서를 감추고 창 안에 가둔다(캡처).
	#
	# 캡처 상태여야 InputEventMouseMotion 의 relative 값이 무한정 나온다.
	# 캡처하지 않으면 커서가 화면 끝에 닿는 순간 relative 가 0 이 되어
	# 더 이상 회전할 수 없게 된다. 1인칭·3인칭 시점 조작에 필수적인 설정이다.
	#
	# 주의: 캡처를 풀 방법을 만들어 두지 않으면 개발 중에 에디터로 못 돌아온다.
	# 이 스크립트는 아래에서 Esc 로 게임 자체를 종료하는 방식으로 해결하고 있다.
	Input.set_mouse_mode(Input.MOUSE_MODE_CAPTURED)


# 마우스 시점 조작과 종료 입력을 처리한다.
#
# _unhandled_input() 은 UI(Control 노드)가 먼저 먹지 않은 입력만 받는다.
# 그리고 "입력 이벤트가 실제로 들어왔을 때만" 호출된다 — 매 프레임 호출되는
# _process() 나 _physics_process() 와는 성격이 완전히 다르다.
# 마우스가 멈춰 있으면 이 함수는 아예 불리지 않는다.
func _unhandled_input(event):
	if event is InputEventMouseMotion:
		# 【좌우 회전(요, yaw)】 — 카메라가 아니라 몸통 전체를 Y축으로 돌린다.
		#
		# 카메라만 돌리지 않고 몸통을 돌리는 것이 핵심이다. 몸통이 돌아야
		# 아래 _physics_process() 의 transform.basis(몸통의 방향 축)가 시선과
		# 같이 돌고, 그래야 "앞으로 가기"가 "보고 있는 쪽으로 가기"가 된다.
		#
		# 부호가 음수인 이유: 마우스를 오른쪽(+x)으로 밀면 시야는 오른쪽으로
		# 돌아야 하는데, Godot 에서 Y축 양의 회전은 왼쪽(반시계) 방향이다.
		rotate_y(-event.relative.x * SENSITIVITY)

		# 【상하 회전(피치, pitch)】 — 몸통이 아니라 카메라만 X축으로 돌린다.
		#
		# 몸통까지 앞뒤로 기울이면 캡슐이 넘어지고 이동 방향에 Y 성분이 섞여
		# 걷는데 하늘로 뜨거나 땅으로 파고드는 현상이 생긴다.
		# 몸통은 항상 똑바로 선 상태를 유지해야 한다.
		camera_3d.rotate_x(-event.relative.y * SENSITIVITY)

		# 피치 각도를 제한해 시야가 뒤집히는 것을 막는다.
		#
		# rotate_x() 를 계속 누적하면 고개가 한 바퀴 돌아 화면이 거꾸로 뒤집힌다.
		# 그래서 매번 clamp() 로 잘라 준다. rotate_x() 로 "더하고" 나서
		# rotation.x 를 "잘라내는" 순서라는 점에 주의.
		#
		# X 회전이 음수면 위를, 양수면 아래를 본다. 여기서는 -40도 ~ +60도로
		# 비대칭인데, 위보다 아래를 더 많이 볼 수 있다는 뜻이다.
		# 3인칭에서는 지면을 내려다볼 일이 많아 아래쪽을 넉넉히 준 설정이다.
		#
		# 참고: 지금은 카메라가 제자리에서 고개만 드는 방식이라, 3인칭에서
		# 피치를 크게 주면 캐릭터가 화면 밖으로 밀려난다. 캐릭터를 중심에 두고
		# 카메라가 원을 그리며 도는(궤도) 방식을 원하면, 몸통 원점에 피벗용
		# Node3D 를 하나 두고 그 피벗을 회전시키면서 카메라를 자식으로 뒤에
		# 오프셋시키는 구조(또는 SpringArm3D)로 바꿔야 한다.
		camera_3d.rotation.x = clamp(camera_3d.rotation.x, deg_to_rad(-40), deg_to_rad(60))

	# Esc 를 누르면 게임을 종료한다.
	#
	# 참고: Input.is_action_just_pressed() 는 지금 들어온 event 를 보는 게 아니라
	# "이번 프레임의 전역 입력 상태"를 조회하는 함수다. 여기서 제대로 동작하는
	# 이유는 Esc 를 누른 그 이벤트가 바로 이 콜백을 깨웠기 때문일 뿐이다.
	# 입력 콜백 안에서의 정석은 실제로 전달된 이벤트를 검사하는
	# event.is_action_pressed("esc") 이며, 이 형태는 한 프레임에 두 번 발동할
	# 여지도 없다.
	if Input.is_action_just_pressed("esc"):
		get_tree().quit()


# 물리 처리 단계.
#
# 렌더링 프레임레이트와 무관하게 고정된 주기(기본 60Hz)로 호출된다.
# 그래서 delta 값이 거의 일정하고, 속도·중력 같은 수치 적분이 안정적이다.
# 화면이 30fps 로 떨어져도 물리는 60번 돌기 때문에, 이동·충돌 로직은
# _process() 가 아니라 반드시 여기에 둔다.
func _physics_process(delta: float) -> void:
	# 【중력】 — 공중에 떠 있을 때만 적용한다.
	#
	# get_gravity() 는 이 몸통이 속한 월드/Area3D 의 중력 벡터를 돌려준다.
	# 상수를 직접 쓰지 않고 이 함수를 쓰면 중력을 바꾸는 구역(물속, 저중력존,
	# 중력 반전 구역)을 나중에 추가해도 코드를 고칠 필요가 없다.
	#
	# delta 를 곱하는 이유: 중력은 가속도(m/s^2)라서, 이번 틱 동안의 속도
	# 변화량(m/s)으로 바꾸려면 흐른 시간을 곱해야 한다.
	#
	# 땅에 서 있을 때는 일부러 누적하지 않는다. move_and_slide() 는 바닥에
	# 붙어 있게 하려고 아래쪽으로 아주 작은 잔류 속도를 남기는데, 이걸 매 틱
	# 계속 더하면 값이 눈덩이처럼 커져서 결국 얇은 바닥을 뚫고 떨어진다.
	if not is_on_floor():
		velocity += get_gravity() * delta

	# 【점프】
	#
	# 액션 이름은 InputMap(Project > Project Settings > Input Map)에 등록된
	# 이름과 글자 하나까지 정확히 같아야 한다. Godot 은 비슷한 이름으로
	# 대체해 주지 않는다. 없는 액션을 조회하면 콘솔에 에러만 찍고 그냥
	# false 를 돌려주기 때문에, 점프가 "조용히" 동작하지 않는다.
	# 이 프로젝트는 스페이스바를 "jump" 가 아니라 "move_jump" 로 등록해 두었다.
	#
	# is_action_just_pressed() 는 키가 "눌린 그 틱"에만 true 다. 그래서
	# 스페이스를 꾹 누르고 있어도 매 틱 다시 튀어 오르지 않는다.
	# (계속 누르면 반복 점프시키고 싶다면 is_action_pressed() 를 쓴다.)
	#
	# is_on_floor() 는 "직전 move_and_slide() 가 기록해 둔" 충돌 결과를 읽는다.
	# 그래서 이번 틱에 아직 움직이지 않았는데도 여기서 바로 쓸 수 있다.
	if Input.is_action_just_pressed("move_jump") and is_on_floor():
		# 더하지 않고 대입(=)하는 이유: 낙하 중이라 velocity.y 가 음수인 상태에서
		# 더하면 점프 높이가 상황마다 달라진다. 대입하면 언제 뛰든 항상 같은 높이다.
		velocity.y = JUMP_VELOCITY

	# 【이동 입력 읽기】
	#
	# Input.get_vector(음의X, 양의X, 음의Y, 양의Y) 는 네 액션을 묶어
	# Vector2 하나로 돌려준다. 결과가 단위원 안으로 정규화되어 있어서,
	# 대각선 입력이 직선 입력보다 빨라지는(√2 배) 고전적인 버그가 생기지 않는다.
	# -1/+1 축을 손으로 조합하면 이 처리를 직접 해 줘야 한다.
	#
	# 주의: "most_left" 는 이 프로젝트 InputMap 의 오타다. 원래 의도는
	# "move_left" 였다. 지금은 InputMap 에 등록된 실제 이름에 코드를 맞춰 둔
	# 상태이므로 동작은 한다. 제대로 고치려면 Project Settings 에서 액션
	# 이름을 move_left 로 바꾸고 이 줄도 함께 수정해야 한다.
	var input_dir := Input.get_vector("most_left", "move_right", "move_forward", "move_backward")

	# 【2D 입력을 3D 이동 방향으로 변환】
	#
	# 입력의 X 는 그대로 X 로, 입력의 Y 는 Z 로 옮긴다. 화면상의 "위/아래"가
	# 3D 에서는 "앞/뒤", 즉 Z 축이기 때문이다. 가운데 0 은 Y(높이)로, 걷는
	# 입력이 수직 속도를 건드리지 못하게 막는 역할이다.
	#
	# 부호를 따로 뒤집지 않아도 되는 이유: 앞으로 가는 키를 누르면
	# input_dir.y 가 -1 이 되고, Godot 에서 -Z 가 바로 앞 방향이라 그대로 맞다.
	#
	# transform.basis 를 곱하면 이 "몸통 기준 방향"이 "월드 기준 방향"으로
	# 회전한다. 이것이 앞서 마우스로 몸통을 돌려 둔 것과 맞물려,
	# 앞으로 가기 = 지금 보고 있는 쪽으로 가기 가 되게 만든다.
	#
	# normalized() 는 길이를 1 로 만들어 순수한 방향만 남긴다.
	# (입력이 없으면 길이 0 인 벡터가 그대로 나온다.)
	var direction := (transform.basis * Vector3(input_dir.x, 0, input_dir.y)).normalized()

	# GDScript 에서 Vector3 를 조건식에 쓰면 "길이가 0 이 아닌가"로 평가된다.
	# 즉 이 if 는 "이동 입력이 있는가?" 라는 뜻이다.
	if direction:
		# 가속 없이 곧바로 최고 속도로 붙인다(즉발 이동).
		# 관성 있는 움직임을 원하면 여기서 lerp() 나 move_toward() 로
		# 서서히 목표 속도에 다가가게 바꾸면 된다.
		#
		# X 와 Z 만 건드리고 Y 는 손대지 않는다. Y 에는 위에서 계산한
		# 중력과 점프 속도가 들어 있어서, 덮어쓰면 공중에서 멈춰 버린다.
		velocity.x = direction.x * SPEED
		velocity.z = direction.z * SPEED
	else:
		# 입력이 없으면 속도를 0 쪽으로 줄인다.
		#
		# move_toward(현재값, 목표값, 최대변화량) 의 세 번째 인자는 "비율"이
		# 아니라 "이번 호출에서 최대 얼마나 바꿀 수 있는가"다. 게다가 여기서는
		# delta 를 곱하지 않았다. 그래서 60Hz 기준 한 틱에 3.0 m/s 씩 줄어드는데,
		# 최고 속도가 마침 3.0 이라 사실상 한 틱 만에 딱 멈춘다.
		# (Godot 기본 템플릿이 원래 이렇게 되어 있다.)
		#
		# 미끄러지듯 서서히 멈추게 하려면 SPEED 대신 감속도 * delta 를 넘긴다.
		# 예: velocity.x = move_toward(velocity.x, 0, DECELERATION * delta)
		velocity.x = move_toward(velocity.x, 0, SPEED)
		velocity.z = move_toward(velocity.z, 0, SPEED)

	# 【실제 이동】
	#
	# 지금까지 계산한 velocity 대로 몸통을 밀고, 충돌을 해결하고, 벽을 만나면
	# 미끄러뜨리고, 계단·경사를 처리한다. 그리고 그 과정에서 무엇에 닿았는지를
	# 기록해 두기 때문에, 다음 틱의 is_on_floor() / is_on_wall() /
	# is_on_ceiling() 이 올바른 값을 돌려줄 수 있다.
	#
	# delta 를 넘기지 않는 점에 주의 — move_and_slide() 는 물리 틱의 delta 를
	# 내부에서 알아서 곱한다. 그래서 velocity 는 "이번 틱 이동량"이 아니라
	# "초당 이동 속도" 단위로 채워 넣는 것이 맞다.
	move_and_slide()
```

---

### 9.5 `@export` — 코드를 고치지 않고 값을 바꾼다

```gdscript
@export var SPEED = 3.0
```

`@export` 를 붙인 변수는 **에디터 인스펙터 창에 입력칸으로 나타난다.**
게임을 실행하지 않고도, 코드를 다시 저장하지 않고도 숫자를 바꿔 볼 수 있다.

```
없을 때 : 속도를 바꾸려면 → 코드 열기 → 숫자 고치기 → 저장 → 실행
있을 때 : 속도를 바꾸려면 → 인스펙터에서 숫자 고치기 → 실행
```

**더 중요한 것은 "인스턴스마다 다른 값"이 가능해진다는 점이다.** 같은 `enemy.tscn`
을 세 번 인스턴싱해 놓고 각각 속도를 2.0 / 3.0 / 5.0 으로 줄 수 있다.

> ⚠️ **인스펙터에서 한 번이라도 값을 만지면, 그 값이 씬 파일에 저장되어 코드의
> 기본값을 이긴다.** 코드에서 `3.0` 을 `5.0` 으로 고쳤는데 게임이 안 빨라지면
> 이걸 의심한다. 인스펙터의 해당 항목 옆 **되돌리기(↺) 아이콘**을 누르면
> 코드 기본값으로 돌아간다.

**이름을 대문자로 쓴 것은 관습일 뿐이다.** `SPEED` 는 대문자라 상수처럼 보이지만
실제로는 그냥 변수다(진짜 상수는 `const`). Godot 기본 템플릿이 이렇게 되어 있어서
많은 코드가 이 스타일을 따른다.

#### 세 값이 실제로 뜻하는 것

| 변수 | 값 | 뜻 |
|---|---|---|
| `SPEED` | 3.0 | **초당 3미터.** 빠르게 걷는 정도. 달리기는 5~7 |
| `JUMP_VELOCITY` | 4.5 | 뛰어오르는 **초기 속도**. 최고 높이는 4.5² ÷ (2 × 9.8) ≈ **1.03m** |
| `SENSITIVITY` | 0.003 | 마우스 **1픽셀당 0.003 라디안**(≈0.17도). 1000픽셀 끌면 약 172도 |

---

### 9.6 `@onready` 와 `$` — 자식 노드를 붙잡는 두 도구

```gdscript
@onready var camera_3d: Camera3D = $Camera3D
```

한 줄에 개념이 셋이나 들어 있다. 하나씩 뜯어본다.

#### `$Camera3D` — 자식 노드를 찾는 축약 기호

`$` 는 `get_node()` 의 축약이다. **자기 자신을 기준으로** 자식을 찾는다.

```gdscript
$Camera3D                    # get_node("Camera3D") 와 완전히 같다
$Head/Camera3D               # 손자도 슬래시로 내려간다
$"../Enemy"                   # 이름에 특수문자가 있으면 따옴표
```

> **이름이 정확히 일치해야 한다.** 씬 트리에서 노드 이름이 `Camera3D` 인데
> `$Camera` 라고 쓰면 `null` 이 온다. 노드 이름을 바꾸면 코드도 바꿔야 한다.
> **씬 독에서 노드를 <kbd>Ctrl</kbd> 드래그해 코드 창에 놓으면** 정확한 `$` 경로가
> 자동으로 입력된다 — 오타를 없애는 가장 쉬운 방법이다.

#### `@onready` — "지금 말고, 트리에 들어간 뒤에 대입하라"

이게 없으면 **거의 확실히 `null` 이 들어간다.** 이유는 §4 의 생명주기에 있다.

```
① _init()        객체가 만들어진다. 이때 var 초기값들이 대입된다
                 └── 하지만 자식 노드는 아직 존재하지 않는다! ← 여기서 $Camera3D 는 null
② _enter_tree()  트리에 들어간다
③ @onready 대입   ← 자식이 모두 준비된 이 시점에 대입된다
④ _ready()       초기화 코드가 돈다
```

```gdscript
var cam = $Camera3D            # 🛑 null — 자식이 아직 없다
@onready var cam = $Camera3D   # ✅ 정상
```

> **외우는 법: `$` 를 쓰는 변수에는 무조건 `@onready` 를 붙인다.**
> 예외 상황은 훨씬 나중에 만나게 된다.

#### `: Camera3D` — 타입 선언

`camera_3d` 가 `Camera3D` 타입임을 명시한다. 안 써도 돌아가지만 쓰면
**에디터가 자동완성을 해 주고, 오타를 실행 전에 잡아 준다.** 자세한 것은
[gdscript.md](gdscript.md) 의 정적 타입 절을 본다.

#### 왜 카메라가 캐릭터의 "자식"인가

```
PC (CharacterBody3D)  ← rotate_y() 로 여기를 돌리면
└── Camera3D          ← 자식인 카메라도 함께 돌아간다 (따라온다)
```

**부모를 움직이면 자식이 전부 따라온다.** 이것이 씬 트리의 가장 중요한 성질이고,
이 컨트롤러 설계의 뼈대다. 카메라를 따로 따라다니게 하는 코드를 한 줄도 쓰지 않아도
카메라가 캐릭터를 따라가는 이유가 이것이다.

---

### 9.7 입력 함수 4형제 — 어느 것을 언제 쓰나

`_unhandled_input()` 이라는 낯선 이름이 나왔다. Godot 의 입력 콜백은 넷이고
**들어온 입력이 이 순서대로 흘러간다.**

```
입력 발생 (키보드·마우스·터치)
   │
   ▼
① _input()               ← 무조건 가장 먼저. 모든 입력을 본다
   │
   ▼
② Control 노드의 UI 처리   ← 버튼·텍스트 입력창 등이 여기서 입력을 "먹는다"
   │
   ▼
③ _unhandled_input()     ← UI 가 먹지 않고 남은 입력만 온다  ★ 이 코드가 쓰는 것
   │
   ▼
④ _unhandled_key_input() ← 그중 키보드 입력만
```

| 함수 | 언제 쓰나 |
|---|---|
| `_input()` | 무엇보다 먼저 가로채야 할 때 (거의 안 쓴다) |
| `_unhandled_input()` | **게임플레이 입력 — 시점 회전, 사격, 상호작용** |
| `_process()` | 매 프레임 상태를 확인 (연출·UI 갱신) |
| `_physics_process()` | **이동·충돌** |

**`_unhandled_input()` 을 쓰는 이유는 UI 와 싸우지 않기 위해서다.**
채팅창에 글자를 입력하는 중에 캐릭터가 같이 움직이면 안 된다. UI 가 입력을
먼저 소비하면 `_unhandled_input()` 에는 오지 않으므로, 이 문제가 저절로 해결된다.

#### 🔑 `_process()` 와 결정적으로 다른 점

```
_process()          매 프레임 무조건 호출된다        (초당 60번 이상)
_unhandled_input()  입력이 들어왔을 때만 호출된다     (마우스가 멈춰 있으면 0번)
```

**마우스가 가만히 있으면 `_unhandled_input()` 은 아예 불리지 않는다.**
그래서 "매 프레임 체크"가 필요한 로직을 여기 넣으면 안 된다.

---

### 9.8 시점 회전 — 왜 몸통과 카메라를 나눠서 돌리나

이 컨트롤러에서 **가장 중요한 설계 판단**이다.

```gdscript
rotate_y(-event.relative.x * SENSITIVITY)             # 몸통을 좌우로
camera_3d.rotate_x(-event.relative.y * SENSITIVITY)   # 카메라를 위아래로
```

| 회전 | 이름 | 누구를 돌리나 | 왜 |
|---|---|---|---|
| 좌우 | **요(yaw)** | **몸통(`self`)** | 몸이 돌아야 "앞으로"가 "보는 쪽으로"가 된다 |
| 위아래 | **피치(pitch)** | **카메라만** | 몸까지 기울면 캡슐이 넘어지고 걷다가 하늘로 뜬다 |

#### `event.relative` 가 무엇인가

마우스 이벤트의 `relative` 는 **"직전 위치에서 얼마나 움직였는가"**다.
화면 절대 좌표(`position`)가 아니다.

```
마우스를 오른쪽으로 10픽셀 → event.relative = Vector2(10, 0)
마우스를 아래로 5픽셀      → event.relative = Vector2(0, 5)
```

#### 왜 앞에 마이너스(−)가 붙나

| | 마우스 | 원하는 결과 | Godot 의 회전 부호 |
|---|---|---|---|
| 좌우 | 오른쪽 = `relative.x` **양수** | 시야가 오른쪽으로 | Y축 **양의 회전 = 왼쪽(반시계)** → 뒤집어야 한다 |
| 상하 | 아래로 = `relative.y` **양수** | 시야가 아래로 | X축 **양의 회전 = 위쪽** → 뒤집어야 한다 |

**즉 마우스 좌표계와 3D 회전 방향이 서로 반대라서 부호를 뒤집는다.**
마이너스를 빼면 마우스를 오른쪽으로 밀 때 화면이 왼쪽으로 도는, 소위
"반전(inverted)" 조작이 된다. 실제로 그걸 선호하는 사람도 있어서 게임 옵션에
"Y축 반전" 이 있는 것이다.

#### `clamp()` — 고개가 한 바퀴 도는 것을 막는다

```gdscript
camera_3d.rotation.x = clamp(camera_3d.rotation.x, deg_to_rad(-40), deg_to_rad(60))
```

`clamp(값, 최소, 최대)` 는 **값을 범위 안으로 잘라 내는** 함수다.

```
clamp(1.5, 0, 1)   → 1     (최대를 넘으면 최대로)
clamp(-3,  0, 1)   → 0     (최소보다 작으면 최소로)
clamp(0.5, 0, 1)   → 0.5   (범위 안이면 그대로)
```

이게 없으면 마우스를 계속 위로 밀 때 **고개가 뒤로 넘어가 화면이 거꾸로 뒤집힌다.**
`rotate_x()` 는 각도를 **계속 더하기만 할 뿐** 스스로 멈추지 않기 때문이다.

**순서에 주의한다** — 먼저 `rotate_x()` 로 더하고, 그다음 `rotation.x` 를 잘라 낸다.

| 값 | 어디를 보나 |
|---|---|
| `deg_to_rad(-40)` | **위쪽** 40도까지 |
| `0` | 정면 |
| `deg_to_rad(60)` | **아래쪽** 60도까지 |

아래를 더 넉넉히 준 것은 **3인칭이라 지면을 내려다볼 일이 많기** 때문이다.
1인칭이라면 보통 위아래 대칭으로 `-90 ~ +90` 을 준다.

---

### 9.9 `_physics_process()` — 이동은 반드시 여기에 쓴다

```gdscript
func _physics_process(delta: float) -> void:
```

#### `_process()` 와 무엇이 다른가

| | `_process(delta)` | `_physics_process(delta)` |
|---|---|---|
| 호출 주기 | **화면 프레임마다** — 기기에 따라 30·60·144번 | **고정 60번/초** (설정 가능) |
| `delta` 값 | 들쭉날쭉하다 | **거의 일정하다** |
| 쓰는 곳 | 연출, UI 갱신, 카메라 보간 | **이동, 충돌, 물리** |

**게이밍 모니터에서만 캐릭터가 빨라지는 버그**의 원인이 이것이다. 이동을
`_process()` 에 두면 프레임이 많이 나오는 기기에서 더 자주 움직인다.
`_physics_process()` 는 화면이 몇 프레임이 나오든 **초당 60번으로 고정**이다.

#### `delta` 가 무엇인가

**"지난 호출로부터 흐른 시간(초)"** 이다. `_physics_process` 에서는 보통
`0.01666…`(= 1/60초)이다.

**왜 곱해야 하나** — 속도는 "초당 몇 미터"인데, 한 틱은 1초가 아니라 1/60초이기
때문이다.

```
초당 3미터로 걷는다 = SPEED 3.0
한 틱(1/60초) 동안 실제로 가는 거리 = 3.0 × 0.0166 = 0.05미터
```

> **이 코드에서 `delta` 를 직접 곱하는 곳은 중력 계산 한 군데뿐이다.**
> 이동은 `move_and_slide()` 가 내부에서 알아서 곱해 준다 — 9.13 참고.

#### `velocity` 가 무엇인가

`CharacterBody3D` 가 물려준 변수로, **`Vector3` 타입의 "초당 이동 속도"**다.

```gdscript
velocity = Vector3(0, 0, -3)     # 앞으로 초당 3미터
velocity.y = 4.5                 # 위로 초당 4.5미터 (점프)
```

**이 변수에 값을 쓰는 것만으로는 아무 일도 일어나지 않는다.**
맨 마지막의 `move_and_slide()` 가 실제로 몸을 민다. `velocity` 는 그때까지
**"이렇게 움직이고 싶다"는 주문서**를 적어 두는 칸이다.

---

### 9.10 중력과 점프

#### 중력 — 공중에 있을 때만 더한다

```gdscript
if not is_on_floor():
	velocity += get_gravity() * delta
```

| 함수 | 하는 일 |
|---|---|
| `is_on_floor()` | **직전** `move_and_slide()` 에서 바닥에 닿았는지 |
| `get_gravity()` | 이 몸통에 걸린 중력 벡터. 기본은 `Vector3(0, -9.8, 0)` |

**`get_gravity()` 를 쓰고 상수를 직접 안 쓰는 이유** — 나중에 물속·저중력 구역
같은 걸 `Area3D` 로 만들면, 그 안에 들어갔을 때 이 함수가 알아서 다른 값을
돌려준다. 코드를 고칠 필요가 없어진다.

**🔑 `if not is_on_floor()` 가 왜 필요한가 — 이게 이 절에서 제일 중요한 함정이다.**

`move_and_slide()` 는 캐릭터를 바닥에 딱 붙여 두려고 **아래쪽으로 아주 작은 속도를
남겨 둔다.** 만약 땅에 서 있을 때도 중력을 계속 더하면 이렇게 된다.

```
1초 후  velocity.y = -9.8      (아직 괜찮다)
10초 후 velocity.y = -98
60초 후 velocity.y = -588      ← 한 틱에 10미터 가까이 내려간다
                                  얇은 바닥은 그냥 뚫고 지나간다
```

가만히 서 있던 캐릭터가 몇십 초 뒤 갑자기 바닥을 뚫고 떨어지는 버그가 이것이다.

#### 점프

```gdscript
if Input.is_action_just_pressed("move_jump") and is_on_floor():
	velocity.y = JUMP_VELOCITY
```

**`just_pressed` 와 `pressed` 의 차이**

| 함수 | 언제 `true` |
|---|---|
| `is_action_just_pressed()` | 키를 **누른 그 순간 딱 한 틱** |
| `is_action_pressed()` | 키를 **누르고 있는 내내** |

점프에 `just_pressed` 를 쓰는 이유는 명확하다. `pressed` 를 쓰면 스페이스를 꾹
누르고 있을 때 **매 틱 다시 뛰어올라 하늘로 날아간다.**

**`and is_on_floor()` 는 공중 2단 점프를 막는다.** 이걸 빼면 무한히 점프할 수 있다.
반대로 2단 점프를 만들고 싶으면 점프한 횟수를 세는 변수를 두면 된다.

**`=` 이지 `+=` 가 아니다.** 떨어지는 중이라 `velocity.y` 가 `-8` 인 상태에서
`+= 4.5` 를 하면 `-3.5` 가 되어 뛰지도 못한다. 대입하면 **어떤 상황에서도 항상
같은 높이**로 뛴다.

---

### 9.11 이동 입력 — `Input.get_vector()` 와 InputMap

```gdscript
var input_dir := Input.get_vector("most_left", "move_right", "move_forward", "move_backward")
```

#### `get_vector()` 는 네 액션을 `Vector2` 하나로 묶는다

```
Input.get_vector( 왼쪽 , 오른쪽 , 위 , 아래 )
                    ↓       ↓      ↓    ↓
                  −X      +X     −Y   +Y
```

| 누른 키 | 결과 |
|---|---|
| 아무것도 안 누름 | `(0, 0)` |
| 앞 | `(0, -1)` |
| 오른쪽 | `(1, 0)` |
| 앞 + 오른쪽 | `(0.707, -0.707)` ← **길이가 1** |

**마지막 줄이 이 함수를 쓰는 진짜 이유다.** 손으로 `-1/+1` 을 조합하면 대각선일 때
길이가 √2 ≈ 1.414 가 되어 **대각선으로 걸을 때만 40% 빨라지는** 고전적인 버그가
생긴다. `get_vector()` 는 결과를 원 안으로 눌러 담아 이 문제를 없애 준다.

#### ⚠️ 액션 이름은 InputMap 에 등록된 것과 **글자 하나까지** 같아야 한다

`"most_left"`, `"move_jump"` 같은 문자열은 **`Project > Project Settings > Input Map`**
에 미리 등록해 둔 이름이다. Godot 은 비슷한 이름으로 대신 찾아 주지 않는다.

**없는 액션을 조회하면 에러를 내고 멈추는 게 아니라, 출력 창에 메시지만 찍고
그냥 `false` 를 돌려준다.** 그래서 "점프가 조용히 안 된다" 는 증상이 나온다.
게임이 멀쩡히 도는데 특정 키만 안 먹으면 **가장 먼저 InputMap 의 철자를 확인한다.**

#### 이 프로젝트에 실제로 등록된 것

| 동작 | 액션 이름 | 키 |
|---|---|---|
| 앞으로 | `move_forward` | <kbd>O</kbd> |
| 뒤로 | `move_backward` | <kbd>L</kbd> |
| 왼쪽 | **`most_left`** ⚠️ | <kbd>J</kbd> |
| 오른쪽 | `move_right` | <kbd>;</kbd> |
| 점프 | `move_jump` | <kbd>Space</kbd> |
| 종료 | `esc` | <kbd>Esc</kbd> |

**두 가지가 눈에 띈다.**

**① `most_left` 는 `move_left` 의 오타다.** 하지만 InputMap 과 코드가 **똑같이**
오타 상태라서 게임은 정상 동작한다. 고치려면 **둘 다** 고쳐야 한다 — 한쪽만
고치면 그 순간 왼쪽 이동이 죽는다.

**② 이동 키가 WASD 가 아니라 <kbd>J</kbd><kbd>O</kbd><kbd>L</kbd><kbd>;</kbd> 다.**

```
          O  ← 앞
    J     L     ;
   왼쪽   뒤    오른쪽
```

키보드 **오른쪽**에 있는 키들이다. **왼손으로 마우스를 잡고 오른손으로 이동하는
배치**로, 왼손잡이용 설정이다. WASD 를 쓰고 싶으면 InputMap 에서 키만 바꾸면 되고
**코드는 한 글자도 고치지 않아도 된다** — 액션 이름으로 추상화해 둔 덕분이다.

> **`physical_keycode` 로 등록되어 있다.** 자판 배열(QWERTY/Dvorak)이나 언어와
> 무관하게 **키보드에서 그 자리에 있는 키**가 먹는다는 뜻이다. 한글 입력 상태에서도
> 정상 동작한다. 액션을 만들 때 사실상 항상 이쪽을 쓴다.

> **`deadzone: 0.2`** — 게임패드 스틱이 살짝 기울어져 있어도 0.2 미만이면 무시한다.
> 키보드에는 영향이 없다.

---

### 9.12 `transform.basis` — 이 스크립트에서 가장 어려운 한 줄

```gdscript
var direction := (transform.basis * Vector3(input_dir.x, 0, input_dir.y)).normalized()
```

**왕초보가 반드시 막히는 줄이다.** 셋으로 쪼개서 본다.

#### ① `Vector3(input_dir.x, 0, input_dir.y)` — 2D 입력을 3D 로 펼친다

```
input_dir 는 Vector2 (x, y)   — 평면 위의 방향
direction 은 Vector3 (x, y, z) — 공간의 방향
```

| 입력의 축 | 3D 의 축 | 왜 |
|---|---|---|
| `input_dir.x` | **X** | 좌우는 그대로 좌우 |
| `0` | **Y** | **높이는 건드리지 않는다** ← 걷기가 점프·중력을 망치지 못하게 |
| `input_dir.y` | **Z** | 화면의 "위/아래"는 3D 에서 "앞/뒤", 즉 **Z축** |

**부호를 뒤집지 않아도 맞는 이유** — 앞으로 가는 키를 누르면 `input_dir.y` 가
`-1` 이 되고, Godot 에서 **−Z 가 곧 앞**이다(9.3 ②). 두 개의 마이너스가
우연히 맞아떨어진다. Godot 이 이렇게 설계한 것이다.

#### ② `transform.basis *` — "몸 기준"을 "월드 기준"으로 바꾼다

**이게 핵심이다.**

①에서 만든 벡터는 **"내 몸을 기준으로 한 앞"** 이다. 하지만 캐릭터는 마우스로
빙글빙글 돌려 놓은 상태다. 월드 전체에서 보면 그 "앞"이 어느 쪽인지는 **몸이
어디를 향해 있느냐**에 따라 달라진다.

```
캐릭터가 북쪽을 볼 때  "몸 기준 앞" = 월드 기준 북쪽
캐릭터가 동쪽을 볼 때  "몸 기준 앞" = 월드 기준 동쪽   ← 같은 (0,0,-1) 인데 결과가 다르다
```

`transform.basis` 는 **이 노드가 현재 어느 쪽을 향해 있는지를 담은 3×3 회전 정보**다.
여기에 곱하면 몸 기준 방향이 **월드 기준 방향으로 회전**된다.

```gdscript
transform.basis.x    # 이 몸의 "오른쪽"이 월드에서 어느 방향인가
transform.basis.y    # 이 몸의 "위"
transform.basis.z    # 이 몸의 "뒤" (앞은 -transform.basis.z)
```

**그래서 9.8 에서 `rotate_y()` 로 몸통을 돌린 것이 여기서 결실을 맺는다.**

```
마우스로 몸통을 돌린다  →  transform.basis 가 바뀐다  →  "앞으로 가기"의 실제 방향이 바뀐다
                                                          = 보고 있는 쪽으로 간다
```

**만약 이 곱셈을 빼면** 캐릭터는 어느 쪽을 보든 **항상 월드의 북쪽으로만** 걷는다.
마우스로 아무리 돌려도 이동 방향이 안 바뀐다.

> **왜 카메라가 아니라 몸통을 돌렸는지**도 이제 설명된다. 카메라만 돌리면
> `transform.basis`(몸통의 것)는 그대로라서, **보는 쪽과 걷는 쪽이 따로 논다.**

#### ③ `.normalized()` — 길이를 1로 만든다

방향만 남기고 **크기를 없앤다.** 이미 `get_vector()` 가 정규화해 주지만,
`transform.basis` 곱셈 뒤에 미세한 오차가 생길 수 있어 한 번 더 눌러 준다.

> 입력이 없으면 `(0,0,0)` 이 들어오는데, 길이 0 인 벡터를 `normalized()` 하면
> Godot 은 오류 없이 `(0,0,0)` 을 그대로 돌려준다. 안전하다.

---

### 9.13 속도를 정하고 실제로 움직인다

#### `if direction:` — 벡터를 조건문에 쓴다

```gdscript
if direction:
```

GDScript 에서 `Vector3` 를 조건식에 쓰면 **"길이가 0 이 아닌가"** 로 평가된다.
즉 이 줄은 **"이동 입력이 있는가?"** 라는 뜻이다.

```gdscript
if direction:                          # ✅ 짧고 관용적
if direction != Vector3.ZERO:          # 같은 뜻, 더 명시적
if input_dir != Vector2.ZERO:          # 이렇게도 쓴다
```

#### 입력이 있을 때 — 즉시 최고 속도

```gdscript
velocity.x = direction.x * SPEED
velocity.z = direction.z * SPEED
```

**가속이 없다.** 키를 누른 순간 0 → 3.0 m/s 가 된다. 반응이 칼같아서 조작감이
좋지만 묵직한 느낌은 없다. 관성을 주고 싶으면 `lerp()` 나 `move_toward()` 로
목표 속도에 서서히 다가가게 바꾼다.

**🔑 `velocity.y` 를 건드리지 않는 것이 중요하다.** Y 에는 위에서 계산한 중력과
점프 속도가 들어 있다. 여기서 `velocity = Vector3(...)` 처럼 통째로 대입하면
**Y가 0으로 덮어써져 공중에서 그대로 멈춘다.** X와 Z만 따로 대입하는 이유다.

#### 입력이 없을 때 — `move_toward()`

```gdscript
velocity.x = move_toward(velocity.x, 0, SPEED)
```

`move_toward(현재값, 목표값, 최대변화량)` 은 **한 번에 지정한 양만큼만** 목표로
다가간다.

```
move_toward(10, 0, 3)  → 7      (3만큼 줄었다)
move_toward(2,  0, 3)  → 0      (넘어가지 않고 목표에서 멈춘다)
```

> ⚠️ **여기에는 `delta` 가 곱해져 있지 않다.** 그래서 한 **틱**에 3.0씩 줄어드는데,
> 최고 속도가 마침 3.0 이라 **사실상 한 틱 만에 즉시 멈춘다.** Godot 기본 템플릿이
> 원래 이렇게 되어 있어서 그대로 두었지만, 의도한 감속이라기보다 우연에 가깝다.
>
> 미끄러지듯 멈추게 하려면 감속도를 따로 두고 `delta` 를 곱한다.
> ```gdscript
> @export var DECELERATION = 10.0
> velocity.x = move_toward(velocity.x, 0, DECELERATION * delta)
> ```

#### `move_and_slide()` — 여기서 비로소 움직인다

```gdscript
move_and_slide()
```

지금까지의 모든 줄은 **`velocity` 라는 주문서를 채운 것**이고, 실제 이동은
이 한 줄이 한다. 엔진이 하는 일은 이렇다.

| 하는 일 | 설명 |
|---|---|
| **민다** | `velocity × delta` 만큼 몸을 이동시킨다 |
| **부딪히면 미끄러진다** | 벽에 45도로 부딪히면 멈추지 않고 벽을 따라 미끄러진다. `slide` 가 이 뜻 |
| **계단·경사 처리** | 인스펙터의 `Floor Max Angle`, `Floor Snap Length` 설정을 따른다 |
| **충돌 결과를 기록한다** | 다음 틱의 `is_on_floor()` / `is_on_wall()` / `is_on_ceiling()` 이 이걸 읽는다 |

**마지막 항목 때문에 순서가 중요하다.** `is_on_floor()` 는 "지금 이 순간"이 아니라
**"직전 `move_and_slide()` 가 남긴 기록"** 을 읽는다. 그래서 함수 맨 위에서
`is_on_floor()` 를 써도 값이 올바르다.

> ⚠️ **`delta` 를 넘기지 않는다.** `move_and_slide(delta)` 라고 쓰면 오류다.
> 물리 틱의 `delta` 는 엔진이 내부에서 알아서 곱한다. 그래서 `velocity` 에는
> **"이번 틱 이동 거리"가 아니라 "초당 속도"** 를 넣는 것이 맞다.
> (Godot 3 에서는 인자를 넘겼다. 옛 강좌를 보고 따라 하면 여기서 막힌다.)

---

### 9.14 마우스 캡처 — 편리하지만 위험한 한 줄

```gdscript
func _ready():
	Input.set_mouse_mode(Input.MOUSE_MODE_CAPTURED)
```

**커서를 감추고 창 안에 가둔다.**

| 모드 | 커서 | `relative` 값 |
|---|---|---|
| `MOUSE_MODE_VISIBLE` | 보인다 | 화면 끝에 닿으면 **0** |
| `MOUSE_MODE_CAPTURED` | **감춰진다** | **무한정 나온다** |

**캡처가 없으면 시점 회전이 화면 끝에서 멈춘다.** 커서가 모니터 오른쪽 끝에
도달하는 순간 더 이상 움직일 수 없으니 `relative.x` 가 0 이 되기 때문이다.
1인칭·3인칭 게임이 예외 없이 캡처를 쓰는 이유다.

> 🛑 **캡처를 푸는 방법을 반드시 만들어 둔다.** 안 만들면 개발 중에 게임 창에서
> 빠져나오지 못한다. 이 스크립트는 <kbd>Esc</kbd> 로 **게임 자체를 종료**하는
> 방식으로 해결했다.
>
> 종료 대신 커서만 풀고 싶으면 이렇게 한다.
> ```gdscript
> if event.is_action_pressed("esc"):
>     Input.set_mouse_mode(Input.MOUSE_MODE_VISIBLE)
> ```
>
> **비상 탈출** — macOS 는 <kbd>Cmd</kbd>+<kbd>Q</kbd>, Windows·Linux 는
> <kbd>Alt</kbd>+<kbd>F4</kbd>. 에디터에서 실행했다면 에디터의 **정지(■) 버튼**
> 이나 <kbd>F8</kbd> 로도 끌 수 있다.

#### 입력 콜백 안에서는 `event` 를 검사하는 것이 정석이다

```gdscript
if Input.is_action_just_pressed("esc"):     # ⚠️ 동작은 하지만 정석이 아니다
if event.is_action_pressed("esc"):          # ✅ 이쪽
```

`Input.is_action_just_pressed()` 는 **지금 들어온 `event` 를 보는 게 아니라
"이번 프레임의 전역 입력 상태"를 조회한다.** 위 코드가 제대로 도는 이유는
Esc 를 누른 그 이벤트가 마침 이 콜백을 깨웠기 때문일 뿐이다.

입력 콜백 안에서는 **실제로 전달된 `event` 를 검사**한다. 한 프레임에 이벤트가
두 번 들어와도 중복 발동하지 않고, 의도가 코드에 그대로 드러난다.

---

### 9.15 이 예제가 3인칭인 이유와 1인칭으로 바꾸는 법

```
pc.tscn 의 Camera3D transform = (0, 0, 1.6885)
                                 x  y     z
```

**+Z 는 "뒤"다**(9.3 ②). 즉 카메라가 캡슐 중심에서 **1.69m 뒤**에 놓여 있다.
높이(`y`)는 0 이라 캡슐 한가운데다 — 눈높이가 아니다. 그래서 화면에는
**캡슐의 뒷모습**이 보인다.

| 원하는 시점 | 카메라 위치 |
|---|---|
| **1인칭** | `(0, 0.6, 0)` 근처 — 캡슐 위쪽, 눈높이 |
| **3인칭** | `(0, 1.0, 2.5)` 근처 — 뒤쪽 위 |

> ⚠️ **지금 구조에는 3인칭의 약점이 하나 있다.** 카메라가 제자리에서 고개만
> 드는 방식이라, 피치를 크게 주면 **캐릭터가 화면 밖으로 밀려난다.**
>
> 제대로 만들려면 캐릭터를 화면 중앙에 두고 카메라가 **원을 그리며 도는(궤도)**
> 구조가 필요하다.
>
> ```
> PC
> └── CameraPivot (Node3D)     ← 여기를 rotate_x() 한다
>     └── Camera3D             ← 뒤로 오프셋 (0, 0, 3)
> ```
>
> 벽을 만나면 카메라를 자동으로 당겨 주는 **`SpringArm3D`** 노드를 피벗 대신
> 쓰면 더 낫다. 자세한 것은 [3d-core.md](3d-core.md) 를 본다.

---

### 9.16 자주 넘어지는 곳 — 증상으로 찾는 표

| 증상 | 원인 | 고치는 곳 |
|---|---|---|
| 캐릭터가 **꿈쩍도 안 한다** | 스크립트가 노드에 안 붙었다 | 인스펙터 맨 아래 `Script` 칸 확인 (§4) |
| 인스펙터에 **`Size` 가 없다** (`Scale` 만 있다) | 리소스 프로퍼티라 한 겹 안쪽에 있다 | `Mesh`/`Shape` 슬롯을 클릭해 펼친다 (§1) |
| **특정 키만** 안 먹는다 | InputMap 액션 이름 철자 불일치 | `Project Settings > Input Map` |
| 캐릭터가 **하늘로 날아간다** | 점프에 `is_action_pressed()` 를 썼다 | `is_action_just_pressed()` 로 |
| 가만히 있다가 **바닥을 뚫는다** | 땅에서도 중력을 누적했다 | `if not is_on_floor():` 추가 |
| **공중에서 멈춘다** | `velocity` 를 통째로 대입해 Y를 덮었다 | `velocity.x`·`velocity.z` 만 대입 |
| 보는 쪽과 **걷는 쪽이 다르다** | `transform.basis` 곱셈이 빠졌다 | 9.12 |
| 마우스를 밀면 **반대로 돈다** | 부호(−)가 빠졌거나 더 붙었다 | 9.8 |
| 화면이 **거꾸로 뒤집힌다** | `clamp()` 가 없다 | 9.8 |
| 시점이 **화면 끝에서 멈춘다** | 마우스를 캡처하지 않았다 | 9.14 |
| **모니터마다 속도가 다르다** | 이동을 `_process()` 에 뒀다 | `_physics_process()` 로 |
| **대각선만 빠르다** | `get_vector()` 대신 손으로 조합했다 | 9.11 |
| `move_and_slide(delta)` **오류** | Godot 3 문법이다 | 인자 없이 호출 (9.13) |
| 카메라가 `null` | `@onready` 를 안 붙였다 | 9.6 |
| **씬을 옮겼더니** 안 움직인다 | 스크립트가 `world.tscn` 쪽에 붙어 있다 | 9.1 |

---

### 9.17 직접 해 볼 것

읽기만 해서는 남지 않는다. **값을 바꿔 가며 눈으로 확인한다.**

| 해 볼 것 | 방법 | 확인 |
|---|---|---|
| 걷기 → 달리기 | 인스펙터에서 `SPEED` 를 `6.0` 으로 | 재실행 없이 값만 바꿔도 되는 게 `@export` 의 값어치 |
| 달 중력 | `JUMP_VELOCITY` 를 `10.0` 으로 | 최고 높이 = 10² ÷ 19.6 ≈ **5.1m** |
| 마우스 반전 | `rotate_y()` 의 `-` 를 뗀다 | 왜 부호가 필요한지 몸으로 안다 |
| 1인칭 만들기 | Camera3D 를 `(0, 0.6, 0)` 으로 | 9.15 |
| `basis` 지우기 | `transform.basis *` 를 뺀다 | **항상 한 방향으로만 걷는다** — 9.12 가 왜 핵심인지 |
| `clamp` 지우기 | 그 줄을 주석 처리 | 위를 계속 보면 화면이 뒤집힌다 |
| 미끄러운 바닥 | `move_toward` 에 `DECELERATION * delta` | 9.13 |
| 이동 키를 WASD 로 | InputMap 에서 키만 교체 | **코드를 안 고쳐도 된다** |

---

## 10. 다음에 무엇을 읽나

| 하고 싶은 것 | 문서 |
|---|---|
| 용어 뜻만 빠르게 | [dictionary.md](dictionary.md) |
| GDScript 문법 | [gdscript.md](gdscript.md) |
| 노드·씬 깊이 있게 (참조·시그널·오토로드·풀링) | [nodes-scenes.md](nodes-scenes.md) |
| 3D 좌표·회전·카메라 | [3d-core.md](3d-core.md) |
| 캐릭터를 움직이고 부딪히게 | **§9(전체 코드 해설)** · [physics-3d.md](physics-3d.md) |
| 맵 만들기 | [level-design.md](level-design.md) |
| 에디터 없이 터미널로 작업 | [headless-workflow.md](headless-workflow.md) |

**막히면 추측하지 말고 확인한다.** 이 스킬의 문서들은 전부 그렇게 쓰였다.

```bash
godot --version                           # 엔진 버전
godot --headless --doctool /tmp/gddoc      # 클래스 정의 XML 전체 (기본값·시그니처 확인)
python3 .claude/skills/godot/scripts/gdscript_lsp.py hover res://a.gd 42 10   # 이 변수의 타입
```
