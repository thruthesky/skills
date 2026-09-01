---
name: godot-example
description: Godot 3D 기본 예제를 만든다 — 빈 프로젝트에 바닥·벽·플레이어를 세우고 화살표 키로 걸어다니게 하는 1~8단계 전 과정. godot 스킬의 references/example.md 를 정본으로 따르며, 광원 0개·CSG 블록아웃·CharacterBody3D 이동 규범을 그대로 적용한다. 사용 시점 — "godot 예제 만들어줘", "기본 씬 만들어줘", "캐릭터 움직이는 것부터", "3D 예제 시작", "블록아웃 만들어줘". 키워드 - godot example, 기본 예제, 첫 씬, 블록아웃, CSG, CharacterBody3D, 바닥, 벽, 플레이어 이동.
argument-hint: "[프로젝트 경로] (생략하면 현재 작업 디렉터리)"
---

# /godot-example — Godot 3D 기본 예제 만들기

빈 Godot 프로젝트에 **바닥 위를 걸어다니는 캐릭터**까지를 만든다.
`godot` 스킬의 [`references/example.md`](../references/example.md) 가 **정본**이고,
이 명령은 그 문서를 실행 절차로 옮긴 것이다.

**대상 프로젝트:** `$ARGUMENTS`

인자가 비어 있으면 **현재 작업 디렉터리**를 대상으로 한다.

---

## 🛑 시작 전에 반드시 — 정본을 읽는다

```
.claude/skills/godot/references/example.md
```

**이 파일을 먼저 읽는다. 예외 없다.** 좌표·기본값·함정이 전부 거기 있고,
전부 엔진에서 확인한 값이다. 기억에 의존해 값을 지어내지 않는다.

찾지 못하면 **작업을 멈추고** 사용자에게 알린다 — `godot` 스킬이 설치되지 않은 것이다.

---

## 1단계 — 대상 프로젝트를 파악한다

```bash
cat <프로젝트>/project.godot
find <프로젝트> -name "*.tscn" -not -path "*/.godot/*"
```

확인할 것:

| 항목 | 기대값 | 다르면 |
|---|---|---|
| `project.godot` 존재 | 있음 | **멈추고 알린다** — Godot 프로젝트가 아니다 |
| `renderer/rendering_method` | `mobile` | 그대로 진행하되 결과 보고에 적는다 |
| `3d/physics_engine` | `Jolt Physics` | 그대로 진행하되 결과 보고에 적는다 |
| `run/main_scene` | 없음 (빈 프로젝트) | **있으면 2단계로** |
| `.tscn` 파일 | 0개 | **있으면 2단계로** |

## 2단계 — 이미 내용이 있으면 먼저 묻는다

씬이 이미 있거나 `run/main_scene` 이 지정돼 있으면 **덮어쓰지 않는다.**
무엇이 있는지 보여주고 사용자에게 고르게 한다.

- 기존 파일을 남기고 **다른 폴더**(`scene_example/`)에 만들 것인가
- 덮어쓸 것인가
- 중단할 것인가

## 3단계 — 만들 것을 먼저 보여주고 승인받는다

**파일을 만들기 전에** 목록을 제시한다. `project.godot` 수정이 포함되므로 반드시 확인을 받는다.

```
만들 파일
  scene/main.tscn      Main · WorldEnvironment · Camera3D · Level/Geometry(Floor+벽4) · Player 인스턴스
  scene/main.gd        카메라가 플레이어를 따라간다
  scene/player.tscn    CharacterBody3D + CollisionShape3D + Mesh(+Nose)
  scene/player.gd      이동·중력·점프

고칠 파일
  project.godot        run/main_scene="res://scene/main.tscn" 한 줄
```

> 🛑 **`project.godot` 은 원래 사람이 고치는 파일이다**(프로젝트 `CLAUDE.md` 작업 규칙).
> 이 명령에서는 **`run/main_scene` 한 줄만** 다루며, **승인 없이는 건드리지 않는다.**
> 사용자가 거절하면 파일만 만들고 지정 방법을 안내한다 —
> `Project > Project Settings > Application > Run > Main Scene`.

## 4단계 — 파일을 만든다

`example.md` 의 값을 **그대로** 쓴다. 아래는 대조용 요약이며, **충돌하면 `example.md` 가 맞다.**

### 씬 구조

```
Main (Node3D)                    main.gd
├─ WorldEnvironment              background_mode = Sky (=2) + ProceduralSkyMaterial
├─ Camera3D                      Position (0,12,12) · Rotation (-45,0,0)
├─ Level (Node3D)
│  └─ Geometry (CSGCombiner3D)   🛑 use_collision = true
│     ├─ Floor      Size (12,1,12)  Position (0,-0.5,0)
│     ├─ WallNorth  Size (12,3,1)   Position (0,1.5,-6)
│     ├─ WallSouth  Size (12,3,1)   Position (0,1.5,6)
│     ├─ WallEast   Size (1,3,12)   Position (6,1.5,0)
│     └─ WallWest   Size (1,3,12)   Position (-6,1.5,0)
└─ Player                        player.tscn 인스턴스 · Position (0,2,0)

Player (CharacterBody3D)         player.gd   ← 스크립트는 이 씬의 루트에 붙는다
├─ CollisionShape3D              CapsuleShape3D (기본값 height 2.0 / radius 0.5)
└─ Mesh (MeshInstance3D)         CapsuleMesh (기본값)
   └─ Nose (MeshInstance3D)      BoxMesh Size (0.25,0.25,0.5) · Position (0,0.3,-0.6)
```

### 광원은 0개다

**`DirectionalLight3D` 를 만들지 않는다.** 밝기는 `WorldEnvironment` 의 하늘이 만든다
(`ambient_light_source` 는 기본값 `AMBIENT_SOURCE_BG` 그대로 둔다).
근거는 `example.md` §3 — A12 실측 및 렌더 비교 5조건.

### `.tscn` 을 직접 쓸 때 주의

| 함정 | 대응 |
|---|---|
| `Transform3D` 는 인자가 **정확히 12개** | 세어 본다. 13개면 파싱 오류가 난다 |
| 카메라 `-45°` 의 basis 부호 | `Transform3D(1,0,0, 0,0.7071068,0.7071068, 0,-0.7071068,0.7071068, 0,12,12)` |
| `load_steps` | ext_resource + sub_resource + 1 |

> 💡 카메라 회전은 **부호를 반대로 넣기 쉽다.** 쓴 뒤 반드시 5단계에서 값을 확인한다.

### 스크립트

`example.md` §7 의 `player.gd` · `main.gd` 를 **그대로** 쓴다. 임의로 고치지 않는다.
`script = ExtResource(...)` 를 **`player.tscn` 의 루트**와 **`main.tscn` 의 루트**에
각각 넣는다 — 붙이는 위치를 틀리면 캐릭터가 움직이지 않는다(§7 의 함정).

## 5단계 — 검증한다 (건너뛰지 않는다)

**만들었다고 보고하기 전에 실제로 돌려서 확인한다.**

```bash
godot --path <프로젝트> --import --headless 2>&1 | grep -i error
python3 .claude/skills/godot/scripts/gdscript_lsp.py diagnose res://scene/player.gd
```

LSP 는 Godot 에디터가 떠 있어야 동작한다. 연결되지 않으면 그 사실을 보고에 적는다.

이어서 임시 관찰 스크립트로 **실제 동작**을 확인한다.
검증 코드는 **대상 프로젝트가 아니라 스크래치패드**에 만들고, 끝나면 지운다.

| 확인 항목 | 기대값 |
|---|---|
| `y=2` 에서 시작 → 0.5초 뒤 | `y ≈ 1.0` · `is_on_floor() = true` |
| `ui_up` 1초 | `z ≈ -5.0` |
| `ui_right` 1초 | `x ≈ +5.0` |
| 벽에 대고 계속 | 더 이상 움직이지 않음 |
| 씬의 광원 수 | **0** |
| 카메라 `global_rotation_degrees` | **`(-45, 0, 0)`** |

**하나라도 어긋나면 고치고 다시 잰다.** `example.md` §11 의 증상별 진단표를 쓴다.

## 6단계 — 설명하며 보고한다

**파일 목록만 나열하고 끝내지 않는다.** 사용자는 Godot 을 배우는 중이다.

보고에 반드시 담을 것:

1. **만든 것** — 파일과 씬 구조
2. **단계별로 무엇을 왜 그렇게 했는가** — 1~8단계를 각각 두세 줄로
   - 특히 **광원을 왜 0개로 두었는지**, **`Use Collision` 이 왜 필요한지**,
     **스크립트를 왜 `player.tscn` 루트에 붙였는지**
3. **검증 수치** — 5단계에서 실제로 나온 값
4. **조작법** — 화살표 이동 · 스페이스 점프
5. **다음에 읽을 것** — `example.md` §12

---

## 이 명령이 하지 않는 것

| 하지 않는 것 | 이유 |
|---|---|
| 에디터 설정·임포트 옵션 변경 | 사람이 에디터에서 한다 |
| `project.godot` 의 `run/main_scene` **외** 항목 수정 | 프로젝트 `CLAUDE.md` 작업 규칙 |
| 기존 씬 덮어쓰기 (승인 없이) | 되돌릴 수 없다 |
| 광원 추가 | 저사양 규범 위반 (`example.md` §3) |
| CSG 를 최종물로 남기기 | 블록아웃 전용. bake 는 별도 단계 |

## 라리엔 3D 본체에서 실행된 경우

대상이 **라리엔 3D 본체**(`.claude/skills/game/references/SSOT.md` 가 있는 프로젝트)라면
**파일을 만들지 않는다.** 그 프로젝트의 씬은 사람이 에디터에서 만든다는 규칙이 있다.

이때는 `example.md` 를 따라 **에디터 조작 안내만** 출력하고, 그 사실을 먼저 알린다.
연습용 프로젝트 경로를 인자로 주면 거기에 만들 수 있다고 덧붙인다.
