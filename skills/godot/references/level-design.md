# 맵 만들기 — 제작 방식 선택과 씬 골격

맵을 **무엇으로 만들 것인가**(제작 방식 5가지)와 **어떤 구조에 담을 것인가**(씬 골격)를
다룬다. 개별 기능의 상세는 다른 문서로 넘긴다 — 용어는
[dictionary.md](dictionary.md), 길찾기는 [navigation-3d.md](navigation-3d.md),
콜리전은 [physics-3d.md](physics-3d.md), 임포트는 [resources-assets.md](resources-assets.md).

> 🛑 **넓은 야외 오픈월드(1.25km 이상)를 만들 것이라면
> [openworld-3d.md](openworld-3d.md) 를 먼저 읽는다.**
> 이 문서는 손으로 짜는 맵(방·복도·프롭 배치)을 다루고, 그쪽은 청크 스트리밍과
> **맵 크기를 언제 정해야 하는가**를 다룬다. **크기는 나중에 조금씩 키울 수 있는
> 값이 아니므로**, 순서를 바꾸면 만든 것을 다시 만들게 된다.

API·기본값은 **엔진에서 직접 추출해 확인한 것**이며, 확인 기준은 **4.7.2.stable** 이다.

---

## 1. 맵을 만드는 5가지 방식

| 방식 | 도구 | 언제 쓰나 | 최종물로 쓸 수 있나 |
|---|---|---|---|
| **A. CSG 블록아웃** | `CSGBox3D`, `CSGCombiner3D` | 동선·스케일 검증 (1일차) | ❌ **프로토타입 전용** |
| **B. GridMap + MeshLibrary** | 타일을 격자에 찍어 조립 | 던전·실내·모듈러 구조 | ✅ |
| **C. glTF 통째 임포트** | Blender → `.glb` | 아트가 확정된 맵, 랜드마크 | ✅ |
| **D. 씬 인스턴싱 배치** | 프롭 `.tscn` 을 수동 배치 | 나무·바위·상자 등 소품 | ✅ |
| **E. 지형(터레인)** | `HeightMapShape3D` / Terrain3D 애드온 | 대규모 야외 | ✅ (**내장 터레인 에디터 없음**) |

**실무는 A 로 시작해서 B·C·D 로 갈아끼우는 것이 정석이다.**
처음부터 C 로 가면 동선이 틀렸을 때 아트를 통째로 다시 만들게 된다.

### 이 프로젝트(라리엔 3D)의 권장 경로

**고정 쿼터뷰 + 모바일**이라는 전제에서 가장 값이 싼 조합은 이것이다.

```
A(블록아웃)  →  B(GridMap · 실내·던전)  +  D(프롭)
                야외 넓은 사냥터만 C 로 통짜 임포트
```

카메라 피치가 고정이라 **플레이어가 볼 면이 정해져 있다.** 안 보이는 면을 만들 필요가
없으므로 모듈러 타일(B)의 물량이 크게 줄고, C 로 통짜 임포트할 곳도 최소가 된다.

### 각 방식에서 반드시 알아야 할 값 (엔진에서 확인)

| 방식 | 함정 |
|---|---|
| A. CSG | `use_collision` 기본값 **`false`** — 켜지 않으면 벽을 통과한다. 최상위 `CSGCombiner3D` 에서 한 번만 켠다. 런타임 CPU 실시간 계산이라 **최종물로 쓰면 안 된다** → `bake_static_mesh()` / `bake_collision_shape()` 로 굳히고 CSG 노드를 삭제한다 |
| B. GridMap | `cell_size` 기본값이 **`Vector3(2, 2, 2)`** 다 (1m 아님). 타일 메시를 1m 로 만들어 놓고 격자가 안 맞는다고 헤매는 일이 흔하다. `bake_navigation` 도 기본 **`false`** |
| E. 지형 | Godot 에는 **터레인 에디터가 내장돼 있지 않다.** `HeightMapShape3D` 는 콜리전 셰이프일 뿐이고(`map_data`는 `PackedFloat32Array`), 시각 메시·텍스처 블렌딩·LOD 는 따로 만들거나 Terrain3D 같은 **외부 애드온**을 써야 한다 |

> A 와 B·C·D 의 관계는 **"버릴 것을 전제로 빠르게 만들고, 확정되면 갈아끼운다"** 이다.
> 블록아웃 단계에서 예쁘게 만들려고 시간을 쓰면 목적에서 벗어난다.
> 자세한 내용은 [dictionary.md](dictionary.md) 의 **블록아웃** 항목.

### 실내인가 야외인가 — 먼저 정한다

**같은 CSG 조작이라도 짜는 구조가 완전히 갈린다.** 방식을 고르기 전에 이것부터 정한다.

| 맵 종류 | 구조 | 만드는 법 |
|---|---|---|
| **실내** (던전·건물) | **방 + 복도** | 벽으로 칸을 나누고 문으로 잇는다. Subtraction 으로 문·창문을 뚫는다 |
| **야외** (사냥터·필드) | **넓은 바닥 + 지형 기복 + 경계 산맥** | 벽으로 막지 않는다. 높이로 동선을 만들고 맵 끝은 산맥·절벽·물로 닫는다 |

**방(room)** 은 집의 방이 아니라 **맵의 구획 단위**를 가리키는 레벨 디자인 용어이고,
방 하나의 기준 치수(**12×12m**)와 **현실보다 크게 잡아야 하는 이유**는
[dictionary.md](dictionary.md) 의 **방(room)** 항목에 있다.

야외가 **1.25km 를 넘어가면** 구조가 한 번 더 갈린다 — 그 지점부터 청크 스트리밍이
비로소 일을 하기 시작하고, 지면을 **원경 평면 + 상주 청크 + `MultiMesh`** 세 층으로
나눠야 한다. 근거와 구현은 [openworld-3d.md](openworld-3d.md) §1·§3 에 있다.

---

## 2. 실제 작업 순서

### 0단계 — 씬 골격

**현재 프로젝트 상태**: [`scenes/main.tscn`](../../../../scenes/main.tscn) 은 이미 있고
`run/main_scene` 도 지정돼 있다. 다만 **루트 `Node3D` 하나뿐이고 그 안의 골격이 비어 있다.**
아래 구조를 채우는 것이 0단계다.

새 씬을 처음부터 만든다면: `Scene > New Scene > 3D Scene` 으로 루트가 `Node3D` 인 씬을
만들어 `res://scenes/main.tscn` 으로 저장하고,
`Project > Project Settings > Application > Run > Main Scene` 에 지정한다.

> 🛑 **씬 파일(`.tscn`)과 `project.godot` 은 사람 개발자가 에디터에서 직접 만든다.**
> Claude 는 구조와 값을 알려줄 뿐 이 파일들을 편집하지 않는다 (`CLAUDE.md` 작업 규칙).

### 권장 씬 구조

```
Main (Node3D)
├─ WorldEnvironment          환경·톤매핑·포그
├─ DirectionalLight3D        태양
├─ Level (Node3D)            ← 맵 본체. 이걸 통째로 교체해 맵을 바꾼다
│  ├─ Geometry (Node3D)      벽·바닥 메시 + 콜리전
│  ├─ NavigationRegion3D     길찾기
│  ├─ Props (Node3D)         인스턴스된 소품 .tscn
│  └─ SpawnPoints (Node3D)   Marker3D 들
├─ Player
└─ CameraRig
```

이 구조의 핵심은 **맵 하나를 독립 `.tscn` 으로 두고 `Level` 자리에 갈아끼우는 것**이다.
조명·환경·플레이어·카메라는 `Main` 에 그대로 있고 맵만 교체되므로,
맵을 추가할 때 손댈 곳이 `.tscn` 파일 하나뿐이다.

| 노드 | 역할 | 왜 분리하는가 |
|---|---|---|
| `WorldEnvironment` · `DirectionalLight3D` | 환경·태양 | 맵이 바뀌어도 유지된다. 맵별로 다르게 하려면 맵 `.tscn` 안에 두면 그때만 덮인다 |
| `Level` | **교체 지점** | 자식 하나를 지우고 새 맵을 붙이면 맵 전환이 끝난다 |
| `Geometry` | 벽·바닥 + 콜리전 | 블록아웃(CSG) → bake 된 메시로 갈아끼우는 자리가 여기다 |
| `NavigationRegion3D` | 길찾기 | 지오메트리가 확정된 뒤 베이크한다. **첫 물리 프레임 전에는 결과를 읽지 않는다** |
| `Props` | 소품 인스턴스 | 지오메트리와 섞이면 내비메시 베이크 대상이 오염된다 |
| `SpawnPoints` | `Marker3D` 들 | 좌표를 코드에 하드코딩하지 않는다. 디자이너가 에디터에서 옮긴다 |

### 뼈대 만들기 — 에디터 조작 순서 (노드 4개)

빈 `Main` 하나뿐인 상태에서 위 구조의 **뼈대까지** 만드는 실제 조작이다.
새로 생기는 노드는 **4개**(태양·환경·`Level`·`CSGCombiner3D`)이고, 1번은 이름 변경이다.

| # | 조작 | 결과 |
|---|---|---|
| 1 | `Node3D` 선택 → **F2** → `Main` | 루트 이름 변경 |
| 2 | 뷰포트 툴바 **☀🌐** 오른쪽 **⋮** → **Add Sun to Scene** | `DirectionalLight3D` 생성 |
| 3 | 같은 **⋮** → **Add Environment to Scene** | `WorldEnvironment` 생성 |
| 4 | `Main` 선택 → **Cmd+A** → `Node3D` → **F2** → `Level` | 맵이 들어갈 자리 |
| 5 | `Level` 선택 → **Cmd+A** → `CSGCombiner3D` | CSG 컨테이너 |

> 🛑 **5번 직후 인스펙터에서 `Use Collision` 을 반드시 ON 으로 켠다.**
> 기본값이 `false` 라 켜지 않으면 만든 벽을 그대로 통과한다.
> 최상위 `CSGCombiner3D` 에서 한 번만 켜면 하위 도형에 전부 적용된다.

`Cmd+A` 는 macOS 의 **자식 노드 추가**다. Windows·Linux 는 `Ctrl+A` 다.

2·3번의 **⋮** 는 3D 뷰포트 툴바에서 **미리보기 태양·환경 토글(☀ 🌐) 바로 오른쪽**에 있다.
이 메뉴로 만들면 각도·색·톤매핑이 **미리보기와 같은 값으로 실제 노드에 박혀** 나오므로,
노드를 직접 추가해 값을 손으로 맞추는 것보다 빠르고 결과가 어긋나지 않는다.

여기까지 하면 **회색 상자를 놓을 준비가 끝난다.** 이후 `CSGCombiner3D` 아래에
`CSGBox3D` 로 바닥·벽을 세우고, 문은 겹친 상자의 `operation` 을 **Subtraction** 으로 바꿔
뚫는다 ([dictionary.md](dictionary.md) 의 **CSG** 항목).

### 카메라 놓기 — 쿼터뷰 수치

`Main` 선택 → **Cmd+A** → 검색창에 `Camera3D` → 추가.

**`Level` 이 아니라 `Main` 바로 아래에 둔다. 카메라는 맵의 일부가 아니다.**
맵을 갈아끼울 때 카메라까지 함께 지워지면 안 된다.

(위 권장 구조의 `CameraRig` 는 **추적·yaw 회전·줌을 붙인 최종 형태**다.
지금은 그 자리에 맨 `Camera3D` 를 두고, 값이 확정되면 `Node3D` 로 감싸 리그로 키운다.)

```
Main
├─ DirectionalLight3D
├─ WorldEnvironment
├─ Camera3D          ← 여기
└─ Level
```

인스펙터 `Node3D > Transform` 에 값을 직접 넣는다.

| 항목 | 값 |
|---|---|
| **Position** | `0, 12, 12` |
| **Rotation** | `-45, 0, 0` |

원점(방 중앙)을 **45도 위에서 내려다보는 쿼터뷰**가 되고, 12×12m 방 전체가 화면에 들어온다.

**왜 이 값인가** — 카메라가 `y=12`, `z=12` 에 있고 아래로 45도 기울면 시선이 정확히
`(0, 0, 0)` 을 지난다. `y` 와 `z` 를 **같게 유지한 채 키우면**(15,15 / 20,20)
**각도는 그대로 두고 줌아웃만 된다.** 라리엔 3D 는 **피치 고정 · 줌 제한 허용**이므로
카메라 거리를 조절할 때 이 규칙을 그대로 쓴다 (`CLAUDE.md` 카메라 규범).

계산으로 확인하면 이렇다 (기본 `fov = 75`, `keep_aspect = KEEP_HEIGHT`).

```
카메라 ~ 원점 거리 = √(12² + 12²) = 16.97 m
피치                = atan(12 / 12)  = 45.0°
수직 시야 폭        = 2 × 16.97 × tan(75°/2) = 26.0 m   → 12m 방이 여유 있게 들어온다
```

### 카메라 확인하는 법

`Camera3D` 를 선택하면 뷰포트 좌상단에 **Preview** 체크박스가 뜬다.
켜면 **게임에서 보일 화면이 그대로** 나온다. **확인 후 다시 끈다** —
켜 둔 채로는 뷰포트를 돌릴 수 없다.

인스펙터의 **`Current`** 는 기본값이 `false` 지만 **씬에 카메라가 하나뿐이면 자동으로
활성화**되므로 건드리지 않아도 된다.

### 눈으로 맞추는 방법

수치가 감이 안 잡히면 이렇게 해도 된다.

1. 뷰포트를 마우스로 돌려 원하는 시점을 만든다
2. `Camera3D` 를 선택한다
3. 상단 메뉴 **Transform > Align Transform with View**

지금 보고 있는 시점 그대로 카메라가 이동한다. 다만 **각도가 어중간한 값이 되므로**,
쿼터뷰처럼 각도를 딱 맞춰야 하는 경우엔 위의 수치 입력이 낫다.

여기까지 하고 **▶(실행)** 을 누르면 검은 화면 대신 **하늘과 바닥 그리드**가 보인다.
아직 `Level` 이 비어 있으니 아무것도 없는 것이 정상이고,
`CSGCombiner3D` 아래에 상자 6개(바닥 1 + 벽 4 + 문 1)를 넣으면 방이 나타난다 — **다음 절의 좌표표**.

### 방 하나 만들기 — 상자 6개 (좌표표)

`CSGCombiner3D` 아래에 `CSGBox3D` 6개를 넣으면 **문이 뚫린 12×12m 방**이 완성된다.
아래 값은 **헤드리스로 실제 조립해 `bake_static_mesh()` 의 AABB 로 검증한 것**이다.

| 노드 이름 | `size` | `position` | `operation` |
|---|---|---|---|
| `Floor` | `12, 1, 12` | `0, -0.5, 0` | Union |
| `WallNorth` | `12, 3, 1` | `0, 1.5, -6` | Union |
| `WallSouth` | `12, 3, 1` | `0, 1.5, 6` | Union |
| `WallEast` | `1, 3, 12` | `6, 1.5, 0` | Union |
| `WallWest` | `1, 3, 12` | `-6, 1.5, 0` | Union |
| `Doorway` | `2, 2, 2` | `0, 1, -6` | **Subtraction** |

만드는 법: `CSGCombiner3D` 선택 → **Cmd+A** → `CSGBox3D` → **F2** 로 이름 →
인스펙터에서 `Size` 와 `Transform > Position` 입력. 나머지는 **Cmd+D**(복제) 후 값만 고친다.
`Doorway` 만 인스펙터 맨 위 `Operation` 을 **Subtraction** 으로 바꾼다.

### 좌표가 전부 정수인 이유 — 규칙 3개

**`CSGBox3D` 의 원점은 상자의 중심**이다. 여기서 모든 값이 나온다.

| 규칙 | 공식 | 이 방에서는 |
|---|---|---|
| **벽 위치는 방 크기의 절반** | `±방크기 / 2` | `±6` |
| **`y` 는 높이의 절반** (바닥에 세우려면) | `높이 / 2` | 벽 `1.5`, 문 `1` |
| **바닥만 `y` 가 음수** (윗면을 `y=0` 에 맞춘다) | `-두께 / 2` | `-0.5` |

**벽 두께를 `1` 로 잡은 것이 좌표를 정수로 만드는 핵심**이다.
`0.5` 로 하면 `±6.25` 같은 값이 나와 계산이 번거로워진다. 블록아웃에서 벽 두께는
아무 의미가 없으므로 **계산이 쉬운 쪽을 고른다.**

방 크기를 바꿔도 같은 규칙이 그대로 쓰인다.

| 방 크기 | 벽 위치 | 바닥 `size` | 벽 `size` (북·남) |
|---|---|---|---|
| 12×12 | `±6` | `12, 1, 12` | `12, 3, 1` |
| 16×16 | `±8` | `16, 1, 16` | `16, 3, 1` |
| 20×20 | `±10` | `20, 1, 20` | `20, 3, 1` |

### 검증 결과 (엔진에서 확인)

```
AABB position = (-6.5, -1.0, -6.5)     ← 벽 바깥면 ±6.5, 바닥 아래 -1
AABB size     = (13.0, 4.0, 13.0)      ← 벽 위 y=3
문 구멍 안쪽 정점 수 = 0                ← Subtraction 이 제대로 뚫렸다
```

**실제로 걸어다닐 수 있는 안쪽 공간은 11×11m** 다 — 벽이 `±6` 에 중심을 두고 두께가 `1`
이므로 안쪽 면이 `±5.5` 가 된다. 12×12 를 정확히 확보하려면 벽을 `±6.5` 로 밀면 되지만,
**블록아웃 단계에서 0.5m 차이는 판단에 영향을 주지 않으므로 정수 좌표를 택한다.**

`Doorway` 의 깊이를 벽 두께(`1`)보다 큰 `2` 로 잡은 것도 의도적이다.
**빼는 상자가 벽을 완전히 관통해야 면이 깨끗하게 뚫린다.** 두께가 같으면
부동소수점 오차로 얇은 막이 남는 일이 있다.

### 맵 교체와 비동기 로딩

**큰 맵은 `load()` 로 불러오면 그 프레임이 통째로 멈춘다.**
`ResourceLoader.load_threaded_request()` 로 백그라운드에서 받아야 한다 (엔진에서 확인).

```gdscript
extends Node3D

@onready var _level_slot: Node3D = $Level

var _pending_path := ""

## 맵 로딩을 시작한다. 완료는 _process 에서 확인한다.
func change_level(scene_path: String) -> void:
	_pending_path = scene_path
	ResourceLoader.load_threaded_request(scene_path)

func _process(_delta: float) -> void:
	if _pending_path.is_empty():
		return

	var progress: Array = []
	var status := ResourceLoader.load_threaded_get_status(_pending_path, progress)

	match status:
		ResourceLoader.THREAD_LOAD_IN_PROGRESS:
			pass                                   # progress[0] 이 0.0~1.0 진행률
		ResourceLoader.THREAD_LOAD_LOADED:
			var packed: PackedScene = ResourceLoader.load_threaded_get(_pending_path)
			_swap_level(packed)
			_pending_path = ""
		ResourceLoader.THREAD_LOAD_FAILED, ResourceLoader.THREAD_LOAD_INVALID_RESOURCE:
			push_error("맵 로딩 실패: %s" % _pending_path)
			_pending_path = ""

func _swap_level(packed: PackedScene) -> void:
	for child in _level_slot.get_children():
		child.queue_free()                          # free() 를 쓰면 트리가 깨진다
	_level_slot.add_child(packed.instantiate())
```

`load_threaded_get_status()` 의 두 번째 인자 `progress` 는 **`Array` 를 넘기면 그 안에
진행률(0.0~1.0)이 채워진다.** 로딩 화면의 프로그레스 바가 여기서 나온다.

상태 상수는 4종이다 — `THREAD_LOAD_INVALID_RESOURCE`(0), `THREAD_LOAD_IN_PROGRESS`(1),
`THREAD_LOAD_FAILED`(2), `THREAD_LOAD_LOADED`(3).

> ⚠️ 맵을 갈아끼운 **직후에는 `NavigationServer` 결과를 읽지 않는다.**
> 첫 물리 프레임 전까지 내비게이션 맵이 동기화되지 않는다 —
> `await get_tree().physics_frame` 이 필요하다. 상세는 [navigation-3d.md](navigation-3d.md).
