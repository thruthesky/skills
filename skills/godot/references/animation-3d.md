# 3D 애니메이션 시스템

## 목차

1. [핵심 개념 — 3계층 구조](#1-핵심-개념--3계층-구조)
2. [AnimationPlayer](#2-animationplayer)
3. [RESET 애니메이션 — 블렌딩의 전제 조건](#3-reset-애니메이션--블렌딩의-전제-조건)
4. [AnimationTree 기본](#4-animationtree-기본)
5. [AnimationNodeStateMachine](#5-animationnodestatemachine)
6. [BlendSpace1D / BlendSpace2D](#6-blendspace1d--blendspace2d)
7. [BlendTree와 노드들](#7-blendtree와-노드들)
8. [코드에서 파라미터 제어](#8-코드에서-파라미터-제어)
9. [Root Motion](#9-root-motion)
10. [Skeleton3D와 본 조작](#10-skeleton3d와-본-조작)
11. [Tween](#11-tween)
12. [glTF 애니메이션 임포트](#12-gltf-애니메이션-임포트)
13. [완성 예제 — 3인칭 캐릭터 애니메이션](#13-완성-예제--3인칭-캐릭터-애니메이션)
14. [자주 하는 실수](#14-자주-하는-실수)

---

## 1. 핵심 개념 — 3계층 구조

Godot 애니메이션은 세 계층으로 나뉘고, 각 계층의 책임이 명확히 다르다.

```
Animation (Resource)        — 키프레임 데이터. "무엇이 언제 어떤 값인가"
      ↑ 담김
AnimationLibrary (Resource) — Animation들의 이름표 모음
      ↑ 담김
AnimationPlayer (Node)      — 재생 엔진. 트랙을 실제 노드 속성에 적용
      ↑ 제어
AnimationTree (Node)        — 블렌딩·상태 전이 로직. AnimationPlayer를 제어
```

**공식 문서의 정의**: "AnimationPlayer는 애니메이션을 담고, AnimationTree는 그 재생을 제어한다."

### 언제 무엇을 쓰는가

| 상황 | 선택 |
|------|------|
| 단순 재생 (문 열림, 아이템 회전) | `AnimationPlayer` 단독 |
| 캐릭터 이동·전투 (블렌딩 필요) | `AnimationPlayer` + `AnimationTree` |
| UI 페이드, 값 보간 | `Tween` (애니메이션 리소스 불필요) |
| 절차적 본 조작 (조준, IK) | `Skeleton3D` 직접 조작 또는 `SkeletonModifier3D` |

---

## 2. AnimationPlayer

### 트랙 종류

| 트랙 | 대상 | 비고 |
|------|------|------|
| Property Track | 노드의 임의 속성 | 가장 범용적 |
| 3D Position / Rotation / Scale Track | `Node3D` 변환 | 압축 저장되어 효율적 |
| Blend Shape Track | 메시 블렌드셰이프 | 표정 애니메이션 |
| Call Method Track | 특정 시점에 메서드 호출 | 발소리, 히트 판정 |
| Bezier Track | 부드러운 곡선 보간 | 카메라 워크 |
| Audio Playback Track | 오디오 재생 | |
| Animation Playback Track | 하위 AnimationPlayer 제어 | |

### 코드 API

```gdscript
@onready var anim: AnimationPlayer = $AnimationPlayer

# 재생
anim.play("attack")
anim.play("walk", 0.2)                      # 0.2초 블렌드 인
anim.play("run", -1, 1.5)                   # 속도 1.5배
anim.play_backwards("open_door")
anim.queue("idle")                          # 현재 애니메이션 후 재생
anim.stop()
anim.pause()

# 상태
anim.is_playing()
anim.current_animation                      # 현재 재생 중인 이름
anim.current_animation_position             # 현재 시간(초)
anim.current_animation_length
anim.speed_scale = 0.5                      # 전체 속도

# 시크
anim.seek(1.5, true)                        # true = 즉시 업데이트

# 애니메이션 조회
if anim.has_animation("attack"):
    var a: Animation = anim.get_animation("attack")
    a.loop_mode = Animation.LOOP_LINEAR      # NONE / LINEAR / PINGPONG
    print(a.length)

# 블렌드 시간 기본값 설정
anim.set_blend_time("idle", "walk", 0.2)
anim.playback_default_blend_time = 0.15

# 시그널
anim.animation_finished.connect(_on_finished)      # 루프가 아닌 것이 끝날 때
anim.animation_changed.connect(_on_changed)
anim.animation_started.connect(_on_started)

func _on_finished(anim_name: StringName) -> void:
    if anim_name == "attack":
        anim.play("idle")
```

### Call Method Track 활용

애니메이션의 특정 프레임에 게임 로직을 연결한다. 공격 판정 타이밍을 코드가 아니라
애니메이션에 두면 애니메이터가 직접 조정할 수 있다.

```gdscript
# 애니메이션 트랙에서 호출할 메서드
func _on_attack_hit_frame() -> void:
    var hits := hitbox.get_overlapping_bodies()
    for body in hits:
        if body.has_method("take_damage"):
            body.take_damage(attack_damage)

func _on_footstep() -> void:
    AudioManager.play_footstep(global_position, _get_surface_type())
```

**주의**: Call Method Track은 `AnimationMixer.callback_mode_method`가
`ANIMATION_CALLBACK_MODE_METHOD_DEFERRED`(기본)이면 지연 호출된다.
즉시 호출이 필요하면 `ANIMATION_CALLBACK_MODE_METHOD_IMMEDIATE`로 바꾼다.

### 프로세스 모드

```gdscript
anim.callback_mode_process = AnimationMixer.ANIMATION_CALLBACK_MODE_PROCESS_PHYSICS
# ANIMATION_CALLBACK_MODE_PROCESS_PHYSICS — 물리 프레임 (캐릭터 애니메이션 권장)
# ANIMATION_CALLBACK_MODE_PROCESS_IDLE    — 렌더 프레임 (UI, 연출)
# ANIMATION_CALLBACK_MODE_PROCESS_MANUAL  — 수동 (advance() 직접 호출)
```

캐릭터가 물리로 움직이는데 애니메이션이 아이들 프레임에서 갱신되면
루트 모션과 이동이 어긋난다. **캐릭터는 `PROCESS_PHYSICS`로 둔다.**

---

## 3. RESET 애니메이션 — 블렌딩의 전제 조건

**이것을 이해하지 못하면 블렌딩 결과가 항상 이상해진다.**

블렌딩은 여러 애니메이션의 같은 트랙 값을 섞는다. 문제는 어떤 애니메이션에는
그 트랙이 있고 다른 애니메이션에는 없을 때다. 트랙이 없으면 엔진은
**기본값(0 또는 본의 Rest 포즈)**으로 간주하고 섞어버린다.

예: `walk`에는 팔 회전 트랙이 있고 `attack`에는 없다면,
둘을 50% 블렌딩할 때 팔이 Rest 포즈로 반쯤 끌려간다.

### 해결: RESET 애니메이션

`RESET`이라는 이름의 애니메이션을 만들고, **모든 애니메이션이 건드리는 모든 프로퍼티**에
대해 기본값 키프레임을 0초에 하나씩 넣는다.

- 에디터에서 애니메이션 목록 → `RESET` 생성 (기본으로 있는 경우도 많음)
- 각 트랙에서 우클릭 → 값을 복사해 RESET에 추가
- 씬 저장 시 Godot은 RESET 포즈를 기준 상태로 사용한다

RESET이 있으면 트랙이 없는 애니메이션도 "RESET 값 유지"로 처리되어 블렌딩이 정확해진다.

### Skeleton3D 팁

- 모델은 **T-포즈 또는 A-포즈**로 임포트한다. Rest 포즈가 기준이 된다.
- 본이 180도 이상 회전해야 하는 애니메이션은 쿼터니언 보간이 최단 경로를 택해
  반대로 돌 수 있다. Root Motion을 쓰거나 중간 키를 추가한다.

---

## 4. AnimationTree 기본

```gdscript
@onready var tree: AnimationTree = $AnimationTree

# 필수 설정
tree.anim_player = $AnimationPlayer.get_path()      # 어느 플레이어의 애니메이션을 쓸지
tree.active = true                                  # 이걸 켜야 동작한다
tree.callback_mode_process = AnimationMixer.ANIMATION_CALLBACK_MODE_PROCESS_PHYSICS
tree.tree_root = <AnimationRootNode>                # 루트 노드 타입
```

`AnimationTree.active = true`가 되면 **`AnimationPlayer.play()`는 무시된다.**
모든 재생 제어가 AnimationTree로 넘어간다.

### 루트 노드 타입

| 타입 | 용도 |
|------|------|
| `AnimationNodeAnimation` | 단일 애니메이션만 재생 |
| `AnimationNodeBlendTree` | 노드 그래프로 자유롭게 조합 |
| `AnimationNodeBlendSpace1D` | 1축 파라미터로 블렌딩 (속도) |
| `AnimationNodeBlendSpace2D` | 2축 파라미터로 블렌딩 (속도 + 방향) |
| `AnimationNodeStateMachine` | 상태와 전이 |

**실전 구성**: 최상위는 `AnimationNodeStateMachine`, 각 상태 안에
`BlendSpace2D`(이동)나 `BlendTree`(상체/하체 분리)를 넣는다.

---

## 5. AnimationNodeStateMachine

상태와 전이로 애니메이션 흐름을 정의한다.

### 전이 타입

| 타입 | 동작 | 사용처 |
|------|------|--------|
| `Immediate` | 즉시 전환 | idle → run |
| `Sync` | 즉시 전환하되 재생 위치 동기화 | walk → run (발 위치 유지) |
| `At End` | 현재 애니메이션 끝난 뒤 전환 | attack → idle |

### 전이 조건 — Advance Condition vs Advance Expression

**Advance Condition** (단순): 단일 bool 파라미터가 `true`인지만 확인한다.

```gdscript
# 에디터의 전이에서 Advance Condition = "is_running" 설정 후
tree.set("parameters/conditions/is_running", true)
```

**Advance Expression** (권장): 임의 표현식을 평가한다.

```
is_walking
is_walking && !is_attacking
velocity_length > 0.1
health < 30
```

Advance Expression을 쓰려면 `AnimationTree.advance_expression_base_node`를
평가 기준 노드(보통 캐릭터 루트)로 지정한다. 그러면 표현식에서 그 노드의
프로퍼티와 메서드를 직접 참조할 수 있다.

```gdscript
func _ready() -> void:
    tree.advance_expression_base_node = get_path()

# 이제 전이 표현식에서 이렇게 쓸 수 있다:
#   is_on_floor()
#   velocity.length() > 0.1
#   current_state == 2
```

**주의**: 표현식은 대소문자를 구분한다. GDScript 프로퍼티는 `snake_case`,
C#은 `PascalCase`로 써야 한다.

### travel() — 자동 경로 탐색

현재 상태에서 목표 상태까지 A* 알고리즘으로 경로를 찾아 중간 전이를 자동 수행한다.

```gdscript
@onready var playback: AnimationNodeStateMachinePlayback = \
    tree["parameters/StateMachine/playback"]

func attack() -> void:
    playback.travel("attack")

# 상태 조회
var current: StringName = playback.get_current_node()
var length: float = playback.get_current_length()
var pos: float = playback.get_current_play_position()
var is_traveling: bool = playback.is_playing()
var path: Array[StringName] = playback.get_travel_path()

# 강제 시작 (전이 무시)
playback.start("death")
playback.stop()
```

**`travel()`은 StateMachine이 실행 중일 때만 동작한다.** `_ready()`에서 즉시
호출하면 무시될 수 있으므로 첫 프레임 이후에 호출한다.

### 상태 머신 종류

| `state_machine_type` | 동작 |
|---------------------|------|
| `STATE_MACHINE_TYPE_ROOT` | 독립 실행. Start/End 노드 사용 |
| `STATE_MACHINE_TYPE_NESTED` | 부모 그래프에 포함되어 부모가 제어 |
| `STATE_MACHINE_TYPE_GROUPED` | 부모와 전이를 공유 |

중첩 상태 머신(상체/하체 분리 등)에서는 `NESTED` 또는 `GROUPED`를 쓴다.

---

## 6. BlendSpace1D / BlendSpace2D

파라미터 값으로 여러 애니메이션을 연속적으로 섞는다.

### BlendSpace1D — 속도 블렌딩

```
   idle        walk         run
     ●───────────●───────────●
    0.0         0.5         1.0
```

```gdscript
# 이동 속도를 0~1로 정규화해 넣는다
var speed_ratio := Vector2(velocity.x, velocity.z).length() / max_speed
tree.set("parameters/Locomotion/blend_position", speed_ratio)
```

### BlendSpace2D — 이동 방향 + 속도 (스트레이프 포함)

```
        forward_run (0, 1)
              ●
              │
 left ●───────●───────● right
   (-1,0)   idle    (1,0)
              │
              ●
        back (0,-1)
```

```gdscript
var input := Input.get_vector("move_left", "move_right", "move_forward", "move_back")
tree.set("parameters/Locomotion2D/blend_position", input)
```

`Auto Triangles`를 켜면 삼각형 분할이 자동 생성된다. 수동으로 삼각형을 그리면
특정 조합에서만 블렌딩되게 제어할 수 있다.

### Sync Mode

| 모드 | 동작 |
|------|------|
| `None` | 비활성 애니메이션 정지 (기본) |
| `Independent` | 비활성 애니메이션도 각자 진행 |
| `Cyclic Mutable` | 모든 애니메이션 시간 동기화 — **걷기/뛰기 발 맞춤에 필수** |
| `Cyclic Constant` | 고정 사이클 길이로 동기화 |

**walk와 run을 블렌딩할 때 발이 어긋나면 `Cyclic Mutable`로 바꾼다.**

### Blend Mode

| 모드 | 동작 |
|------|------|
| `Continuous` | 삼각형/선 내부를 연속 보간 (기본) |
| `Discrete` | 중간 상태 없이 가장 가까운 것만 |
| `Carry` | 전환 시 재생 위치 유지 |

---

## 7. BlendTree와 노드들

`AnimationNodeBlendTree`는 노드 그래프다. `Output` 노드에 연결된 것이 최종 결과다.

### Blend2 / Blend3 — 가중 블렌딩 + 필터

```gdscript
tree.set("parameters/UpperBodyBlend/blend_amount", 1.0)   # 0=A, 1=B
```

**필터의 용도**: 상체/하체 분리. `Blend2`에서 `Filter Enabled`를 켜고
상체 본만 체크하면, B 애니메이션의 상체만 A에 덮어씌운다.

```
Locomotion (하체 걷기) ──┐
                        ├─ Blend2 (필터: 상체 본만) ──> Output
Aim (상체 조준)      ────┘
```

이 구조로 "걸으면서 조준"을 구현한다.

### OneShot — 일회성 애니메이션 삽입

```gdscript
# 발동
tree.set("parameters/AttackOneShot/request",
    AnimationNodeOneShot.ONE_SHOT_REQUEST_FIRE)

# 중단
tree.set("parameters/AttackOneShot/request",
    AnimationNodeOneShot.ONE_SHOT_REQUEST_ABORT)

# 페이드아웃하며 중단
tree.set("parameters/AttackOneShot/request",
    AnimationNodeOneShot.ONE_SHOT_REQUEST_FADE_OUT)

# 실행 중인지 확인 (읽기 전용)
var active: bool = tree.get("parameters/AttackOneShot/active")
var internal_active: bool = tree.get("parameters/AttackOneShot/internal_active")
```

`OneShot` 속성: `fadein_time`, `fadeout_time`, `autorestart`, `break_loop_at_end`,
`mix_mode`(Blend / Add).

**`mix_mode = Add`**로 두면 기존 애니메이션 위에 더해진다. 피격 반응처럼
이동을 유지하면서 상체만 흔들 때 유용하다.

### TimeSeek

```gdscript
tree.set("parameters/TimeSeek/seek_request", 0.0)     # 처음부터
tree.set("parameters/TimeSeek/seek_request", 12.0)    # 12초 지점부터
```

### TimeScale

```gdscript
tree.set("parameters/TimeScale/scale", 0.5)    # 절반 속도
tree.set("parameters/TimeScale/scale", 0.0)    # 정지
tree.set("parameters/TimeScale/scale", -1.0)   # 역재생
```

슬로우모션 연출이나 공격 속도 스탯 반영에 쓴다.

### Transition — 포트 선택

```gdscript
tree.set("parameters/Transition/transition_request", "state_2")
var current: String = tree.get("parameters/Transition/current_state")
var idx: int = tree.get("parameters/Transition/current_index")
```

### Add2 / Add3 — 가산 블렌딩

기본 포즈와의 차이를 더한다. 호흡, 조준 오프셋, 피격 반동에 쓴다.

```gdscript
tree.set("parameters/BreathAdd/add_amount", 0.6)
```

### Sub2 — 감산

애니메이션에서 기준 포즈를 빼서 가산용 애니메이션을 만들 때 쓴다.

---

## 8. 코드에서 파라미터 제어

파라미터 경로는 `parameters/<노드이름>/<속성>` 형태다.
정확한 경로는 인스펙터의 "Parameters" 섹션에서 확인하거나, 그래프 노드에 마우스를 올리면 나온다.

```gdscript
# 세 가지 표기가 모두 동일하다
tree.set("parameters/Locomotion/blend_position", 0.7)
tree["parameters/Locomotion/blend_position"] = 0.7
tree.set_parameter("parameters/Locomotion/blend_position", 0.7)   # 4.x

# 읽기
var v: float = tree.get("parameters/Locomotion/blend_position")
```

### 파라미터 경로 상수화 (권장)

문자열 오타는 조용히 실패한다. 상수로 모아두면 안전하다.

```gdscript
class_name AnimParams

const LOCOMOTION := "parameters/StateMachine/Move/blend_position"
const PLAYBACK := "parameters/StateMachine/playback"
const ATTACK_REQUEST := "parameters/AttackOneShot/request"
const ATTACK_ACTIVE := "parameters/AttackOneShot/active"
const UPPER_BLEND := "parameters/UpperBodyBlend/blend_amount"
const TIME_SCALE := "parameters/TimeScale/scale"
const COND_GROUNDED := "parameters/conditions/is_grounded"
const COND_ATTACKING := "parameters/conditions/is_attacking"
```

```gdscript
tree.set(AnimParams.LOCOMOTION, speed_ratio)
```

### AnimationTree는 리소스를 공유한다

`tree_root`는 `AnimationRootNode` 리소스다. 같은 씬을 여러 개 인스턴스화하면
**모든 인스턴스가 같은 트리 리소스를 공유한다.** 하지만 파라미터 값은
`AnimationTree` 노드마다 별도로 저장되므로 실제 문제는 없다.

트리 구조 자체를 런타임에 인스턴스별로 바꾸려면 `tree_root = tree_root.duplicate(true)`가 필요하다.

---

## 9. Root Motion

애니메이션에 포함된 루트 본의 이동을 추출해 캐릭터 이동에 사용한다.
발 미끄러짐(foot sliding)이 없는 자연스러운 이동을 얻는다.

### 설정

1. `AnimationTree` 인스펙터에서 `Root Motion Track`을
   `Skeleton3D:<루트본이름>` (보통 `Hips` 또는 `Root`)으로 지정한다.
2. 그러면 해당 본의 변환이 시각적으로 상쇄되고, 대신 코드로 델타를 읽을 수 있다.

### 코드

```gdscript
func _physics_process(delta: float) -> void:
    # 이번 물리 프레임 동안의 루트 모션 이동량 (로컬 좌표)
    var motion := tree.get_root_motion_position()
    var rot := tree.get_root_motion_rotation()
    var scl := tree.get_root_motion_scale()

    # 누적값 (블렌딩된 결과)
    var acc_pos := tree.get_root_motion_position_accumulator()
    var acc_rot := tree.get_root_motion_rotation_accumulator()

    # 캐릭터 방향으로 회전시켜 속도로 변환
    var world_motion := global_basis * motion
    velocity.x = world_motion.x / delta
    velocity.z = world_motion.z / delta

    if not is_on_floor():
        velocity.y -= gravity * delta
    else:
        velocity.y = 0.0

    move_and_slide()

    # 루트 모션에 회전이 포함된 경우
    quaternion = quaternion * rot
```

### Root Motion을 쓸 때와 쓰지 않을 때

| 상황 | 선택 |
|------|------|
| 공격 콤보, 구르기, 회피 (애니메이션이 이동을 정의) | **Root Motion** |
| 자유 이동 (플레이어 입력이 이동을 정의) | 코드 이동 + 블렌드스페이스 |
| 사다리 오르기, 커버 진입 등 정해진 동작 | Root Motion |

**혼합 전략**: 상태 머신의 상태별로 Root Motion 사용 여부를 바꾼다.
`Move` 상태는 코드 이동, `Attack`/`Dodge` 상태는 Root Motion.

```gdscript
func _physics_process(delta: float) -> void:
    var state := playback.get_current_node()
    if state in [&"attack_1", &"attack_2", &"dodge"]:
        _apply_root_motion(delta)
    else:
        _apply_input_movement(delta)
    move_and_slide()
```

---

## 10. Skeleton3D와 본 조작

```gdscript
@onready var skeleton: Skeleton3D = %Skeleton3D

# 본 조회
var bone_idx := skeleton.find_bone("Head")
var bone_count := skeleton.get_bone_count()
var bone_name := skeleton.get_bone_name(bone_idx)
var parent_idx := skeleton.get_bone_parent(bone_idx)

# 포즈 (애니메이션이 적용된 현재 상태)
var pose := skeleton.get_bone_pose(bone_idx)                  # Transform3D
var pos := skeleton.get_bone_pose_position(bone_idx)
var rot := skeleton.get_bone_pose_rotation(bone_idx)          # Quaternion
var scl := skeleton.get_bone_pose_scale(bone_idx)

skeleton.set_bone_pose_rotation(bone_idx, Quaternion(Vector3.RIGHT, angle))

# Rest 포즈 (바인드 포즈 — 기준 상태)
var rest := skeleton.get_bone_rest(bone_idx)
skeleton.reset_bone_poses()

# 글로벌 포즈 (스켈레톤 공간)
var global_pose := skeleton.get_bone_global_pose(bone_idx)
skeleton.set_bone_global_pose(bone_idx, t)

# 월드 좌표로 변환
var world := skeleton.global_transform * skeleton.get_bone_global_pose(bone_idx)
```

### 절차적 머리 조준 (Look-at)

애니메이션 위에 덧씌워야 하므로 `_process`가 아니라
`SkeletonModifier3D` 또는 `AnimationMixer` 이후 시점에 적용해야 한다.

```gdscript
class_name HeadLookAt
extends SkeletonModifier3D          # 4.3+ — 애니메이션 이후 자동 호출됨

@export var target: Node3D
@export var max_angle_deg: float = 70.0
@export var weight: float = 1.0

var _bone_idx: int = -1

func _ready() -> void:
    var sk := get_skeleton()
    if sk:
        _bone_idx = sk.find_bone("Head")

func _process_modification() -> void:
    if _bone_idx < 0 or not is_instance_valid(target):
        return
    var sk := get_skeleton()
    var bone_global := sk.global_transform * sk.get_bone_global_pose(_bone_idx)
    var to_target := bone_global.origin.direction_to(target.global_position)

    # 몸통 정면 기준 각도 제한
    var body_forward := -sk.global_basis.z
    if body_forward.dot(to_target) < cos(deg_to_rad(max_angle_deg)):
        return

    var desired := Basis.looking_at(to_target, Vector3.UP)
    var local_desired := sk.global_basis.inverse() * desired
    var current := sk.get_bone_global_pose(_bone_idx).basis
    var blended := Quaternion(current).slerp(Quaternion(local_desired), weight)
    sk.set_bone_global_pose(_bone_idx,
        Transform3D(Basis(blended), sk.get_bone_global_pose(_bone_idx).origin))
```

**`SkeletonModifier3D`(4.3+)를 쓰는 이유**: 애니메이션 적용 이후,
스키닝 이전 시점에 자동 호출된다. `_process`에서 본을 건드리면
다음 프레임 애니메이션이 덮어써서 떨림이 생긴다.

### 내장 SkeletonModifier3D

| 노드 | 기능 |
|------|------|
| `SkeletonIK3D` (deprecated) | 구형 IK. 4.3부터 아래로 대체 |
| `LookAtModifier3D` (4.4+) | 본이 대상을 바라보게 |
| `SpringBoneSimulator3D` (4.4+) | 머리카락·옷 흔들림 물리 |
| `PhysicalBoneSimulator3D` | 래그돌 |
| `ModifierBoneTarget3D` | 본을 노드 위치로 |
| `RetargetModifier3D` | 다른 스켈레톤의 애니메이션 리타게팅 |
| `BoneConstraint3D` 계열 (4.6+) | **본을 다른 본에 묶는다** — 아래 참고 |

### BoneConstraint3D — 본을 다른 본에 묶기 (4.6+)

한 본이 움직일 때 다른 본이 따라 움직이게 하는 **제약(constraint)** 계열이다.
"어깨가 돌면 쇄골도 따라 돈다", "손목 회전을 팔뚝에 절반만 전달한다" 같은
보조 본 처리를 코드 없이 노드 설정으로 해결한다.

상속 구조는 `BoneConstraint3D < SkeletonModifier3D < Node3D`이고, 실제로는
아래 3종의 자식 클래스를 쓴다.

| 노드 | 하는 일 |
|---|---|
| `AimModifier3D` | 대상 방향을 **겨냥**하도록 본을 회전시킨다 |
| `CopyTransformModifier3D` | 다른 본의 위치·회전·스케일을 **복사**한다 |
| `ConvertTransformModifier3D` | 한 축의 변화를 다른 축·다른 단위로 **변환**해 전달한다 |

**설정은 인덱스 기반 목록이다.** 노드 하나에 여러 제약을 담을 수 있다.

```gdscript
# 쇄골이 어깨를 60% 따라가게 한다
var c := CopyTransformModifier3D.new()
c.set_setting_count(1)                       # 제약 1개
c.set_apply_bone_name(0, "Clavicle_L")       # 영향을 받을 본
c.set_reference_bone_name(0, "Shoulder_L")   # 기준이 될 본
c.set_amount(0, 0.6)                         # 전달 비율 (1.0 = 그대로)
skeleton.add_child(c)
```

| 메서드 | 의미 |
|---|---|
| `set_setting_count(count)` / `get_setting_count()` | 제약 개수 |
| `clear_setting()` | 전체 삭제 |
| `set_apply_bone_name(i, name)` / `set_apply_bone(i, idx)` | 영향을 받을 본 (이름 또는 인덱스) |
| `set_reference_bone_name(i, name)` / `set_reference_bone(i, idx)` | 기준 본 |
| `set_reference_node(i, path)` | 본 대신 **노드**를 기준으로 삼는다 |
| `set_reference_type(i, type)` | 기준으로 삼을 성분(위치/회전/스케일 등) |
| `set_amount(i, amount)` | 전달 비율 |

**쓰는 곳**: 보조 본이 많은 리깅(쇄골, 무릎·팔꿈치 보정 본), 옷·장비가 몸을 따라가는
처리, 그리고 **VR·메타버스 아바타**처럼 표준 리그에 절차적 보정을 얹어야 하는 경우.

라리엔 3D는 카메라가 고정된 각도로 내려다보므로 미세한 보조 본 처리의 시각적 이득은
크지 않다. **장비 부착과 조준 정도에 한정해 쓰고** 몹 수가 많은 씬에서는 남발하지 않는다.
`SkeletonModifier3D` 계열은 매 프레임 본을 다시 계산하므로 캐릭터 수에 비례해 비용이 는다.

### BoneAttachment3D — 본에 오브젝트 붙이기

```gdscript
# 무기를 손 본에 붙인다
# Skeleton3D
#  └─ BoneAttachment3D (bone_name = "RightHand")
#     └─ WeaponHolder (Node3D)
#        └─ Sword

@onready var hand: BoneAttachment3D = %RightHandAttachment

func equip(weapon_scene: PackedScene) -> void:
    for c in hand.get_children():
        c.queue_free()
    hand.add_child(weapon_scene.instantiate())
```

### 래그돌

```gdscript
@onready var phys_bones: PhysicalBoneSimulator3D = %PhysicalBoneSimulator3D

func enable_ragdoll(impulse: Vector3) -> void:
    tree.active = false                          # 애니메이션 정지
    phys_bones.physical_bones_start_simulation()
    var hips := phys_bones.get_node_or_null("Physical Bone Hips") as PhysicalBone3D
    if hips:
        hips.apply_central_impulse(impulse)

func disable_ragdoll() -> void:
    phys_bones.physical_bones_stop_simulation()
    tree.active = true
```

셋업: `Skeleton3D` 선택 → 상단 `Skeleton` 메뉴 → `Create Physical Skeleton`.
생성된 `PhysicalBone3D`들의 콜리전 셰이프와 조인트 제한을 손으로 다듬어야 한다.

---

## 11. Tween

애니메이션 리소스 없이 값을 보간한다. UI, 간단한 연출, 절차적 움직임에 쓴다.

```gdscript
# 생성 — 노드에 종속되어 노드가 사라지면 자동 정리
var tween := create_tween()

# 속성 보간
tween.tween_property(self, "position", Vector3(0, 5, 0), 1.0)
tween.tween_property(mesh, "scale", Vector3.ONE * 1.5, 0.3)
tween.tween_property(material, "albedo_color:a", 0.0, 0.5)     # 하위 속성 접근

# 이징
tween.tween_property(self, "position:y", 3.0, 0.6) \
    .set_trans(Tween.TRANS_ELASTIC) \
    .set_ease(Tween.EASE_OUT) \
    .set_delay(0.2) \
    .from(0.0)

# 병렬 실행
tween.set_parallel(true)
tween.tween_property(self, "position:y", 2.0, 0.5)
tween.tween_property(self, "rotation:y", TAU, 0.5)
tween.set_parallel(false)

# 또는
tween.tween_property(a, "modulate:a", 0.0, 0.3)
tween.parallel().tween_property(b, "modulate:a", 1.0, 0.3)

# 콜백과 대기
tween.tween_callback(_on_midpoint)
tween.tween_interval(0.5)
tween.tween_method(_set_progress, 0.0, 1.0, 1.0)      # 커스텀 setter

# 4.7 신규 — 시그널 대기
tween.tween_await(anim.animation_finished)

# 루프와 제어
tween.set_loops()                    # 무한 반복
tween.set_loops(3)
tween.set_process_mode(Tween.TWEEN_PROCESS_PHYSICS)
tween.set_pause_mode(Tween.TWEEN_PAUSE_PROCESS)      # 게임 일시정지 중에도 진행

tween.kill()
tween.pause()
tween.play()
await tween.finished
```

### 이징 종류

`TRANS_LINEAR`, `TRANS_SINE`, `TRANS_QUINT`, `TRANS_QUART`, `TRANS_QUAD`,
`TRANS_EXPO`, `TRANS_ELASTIC`, `TRANS_CUBIC`, `TRANS_CIRC`, `TRANS_BOUNCE`,
`TRANS_BACK`, `TRANS_SPRING`(4.2+)

`EASE_IN`, `EASE_OUT`, `EASE_IN_OUT`, `EASE_OUT_IN`

**실용 조합**: UI 팝업은 `TRANS_BACK` + `EASE_OUT`, 낙하는 `TRANS_BOUNCE` + `EASE_OUT`,
부드러운 이동은 `TRANS_SINE` + `EASE_IN_OUT`.

### 기존 트윈 중복 방지

```gdscript
var _tween: Tween

func flash() -> void:
    if _tween and _tween.is_running():
        _tween.kill()
    _tween = create_tween()
    _tween.tween_property(self, "modulate", Color.WHITE, 0.2)
```

---

## 12. glTF 애니메이션 임포트

### 임포트 설정 (파일 선택 → Import 탭)

| 설정 | 권장값 | 이유 |
|------|--------|------|
| `Root Type` | `Node3D` 또는 `CharacterBody3D` | 루트를 바로 물리 바디로 |
| `Root Name` | 모델 이름 | |
| `Apply Root Scale` / `Root Scale` | `1.0` | Blender 단위와 맞춤 |
| `Meshes → Ensure Tangents` | On | 노멀맵 사용 시 필수 |
| `Meshes → Generate LODs` | On | 자동 LOD 생성 |
| `Meshes → Create Shadow Meshes` | On | 그림자 전용 저폴리 메시 |
| `Meshes → Light Baking` | `Static Lightmaps` | 라이트맵 UV2 자동 생성 |
| `Skins → Use Named Skins` | On | |
| `Animation → Import` | On | |
| `Animation → FPS` | `30` | 키프레임 샘플링 빈도 |
| `Animation → Trimming` | On | 앞뒤 빈 구간 제거 |
| `Animation → Remove Immutable Tracks` | On | 변하지 않는 트랙 제거 (용량↓) |
| `Import Script` | 커스텀 후처리 | 아래 참고 |

### 애니메이션 개별 설정

Import 탭의 `Advanced...` → 애니메이션 목록에서 각각 설정한다.

- **Loop Mode**: `None` / `Linear` / `Pingpong`
- **Save to File**: 애니메이션을 별도 `.res`로 분리 (여러 모델이 공유할 때)
- **Slice**: 하나의 긴 애니메이션을 구간별로 잘라 여러 개로 (Mixamo 등)

### 임포트 후처리 스크립트

임포트할 때마다 수동 작업을 반복하지 않으려면 `EditorScenePostImport`를 쓴다.

```gdscript
# res://tools/character_post_import.gd
@tool
extends EditorScenePostImport

func _post_import(scene: Node) -> Object:
    _setup_recursive(scene)
    return scene

func _setup_recursive(node: Node) -> void:
    if node is MeshInstance3D:
        var mi := node as MeshInstance3D
        mi.gi_mode = GeometryInstance3D.GI_MODE_DYNAMIC
        mi.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_ON
    elif node is AnimationPlayer:
        var ap := node as AnimationPlayer
        ap.callback_mode_process = \
            AnimationMixer.ANIMATION_CALLBACK_MODE_PROCESS_PHYSICS
        # 이름 규칙으로 루프 자동 설정
        for anim_name in ap.get_animation_list():
            if anim_name.begins_with("loop_") or anim_name in ["idle", "walk", "run"]:
                ap.get_animation(anim_name).loop_mode = Animation.LOOP_LINEAR
    for child in node.get_children():
        _setup_recursive(child)
```

Import 탭의 `Import Script`에 이 파일을 지정한다.

### 리타게팅 (Mixamo 등 외부 애니메이션)

Godot 4.3+는 SkeletonProfile 기반 리타게팅을 지원한다.

1. 모델 임포트 시 `Skeleton3D → Retarget → Bone Map`에 `BoneMap` 리소스 생성
2. `SkeletonProfileHumanoid` 프로필 선택
3. 각 본을 표준 이름에 매핑 (자동 추측 버튼 있음)
4. 다른 모델에도 같은 프로필을 적용하면 애니메이션 공유 가능

---

## 13. 완성 예제 — 3인칭 캐릭터 애니메이션

### AnimationTree 구조

```
StateMachine (root)
├─ Move (BlendSpace2D)          — idle/walk/run, Sync Mode: Cyclic Mutable
├─ Jump (Animation)
├─ Fall (Animation)
├─ Land (Animation)             — At End 전이로 Move
├─ Attack1 (Animation)          — At End 전이로 Attack2 또는 Move
├─ Attack2 (Animation)
├─ Hit (Animation)
└─ Death (Animation)
```

### 컨트롤러 코드

```gdscript
class_name PlayerAnimator
extends Node

const P_PLAYBACK := "parameters/StateMachine/playback"
const P_MOVE := "parameters/StateMachine/Move/blend_position"
const P_TIME_SCALE := "parameters/TimeScale/scale"

@export var tree: AnimationTree
@export var body: CharacterBody3D

var _playback: AnimationNodeStateMachinePlayback
var _combo_index: int = 0
var _combo_window_open: bool = false

func _ready() -> void:
    tree.active = true
    tree.callback_mode_process = \
        AnimationMixer.ANIMATION_CALLBACK_MODE_PROCESS_PHYSICS
    tree.advance_expression_base_node = body.get_path()
    _playback = tree[P_PLAYBACK]

func _physics_process(_delta: float) -> void:
    _update_locomotion()
    _update_air_state()

func _update_locomotion() -> void:
    var state := _playback.get_current_node()
    if state != &"Move":
        return
    # 로컬 속도를 -1~1 범위로 정규화해 BlendSpace2D에 전달
    var local_vel := body.global_basis.inverse() * body.velocity
    var planar := Vector2(local_vel.x, -local_vel.z) / body.max_speed
    var current: Vector2 = tree.get(P_MOVE)
    # 급격한 변화를 부드럽게
    tree.set(P_MOVE, current.lerp(planar.limit_length(1.0), 0.25))

func _update_air_state() -> void:
    var state := _playback.get_current_node()
    if not body.is_on_floor():
        if body.velocity.y > 0.1 and state != &"Jump":
            _playback.travel("Jump")
        elif body.velocity.y < -0.5 and state not in [&"Fall", &"Jump"]:
            _playback.travel("Fall")
    elif state == &"Fall":
        _playback.travel("Land")

# ── 공격 콤보 ────────────────────────────────────────
func try_attack() -> void:
    var state := _playback.get_current_node()
    if state == &"Move":
        _combo_index = 1
        _playback.travel("Attack1")
    elif _combo_window_open and _combo_index == 1:
        _combo_index = 2
        _playback.travel("Attack2")

# AnimationPlayer의 Call Method Track에서 호출
func _anim_open_combo_window() -> void:
    _combo_window_open = true

func _anim_close_combo_window() -> void:
    _combo_window_open = false

func _anim_hit_frame() -> void:
    body.deal_damage()

# ── 히트스톱 (타격감) ─────────────────────────────────
func hit_stop(duration: float = 0.06) -> void:
    tree.set(P_TIME_SCALE, 0.05)
    await get_tree().create_timer(duration).timeout
    if is_instance_valid(self):
        tree.set(P_TIME_SCALE, 1.0)

func play_hit_reaction() -> void:
    _playback.travel("Hit")

func play_death() -> void:
    _playback.travel("Death")
    set_physics_process(false)
```

### 왜 이렇게 설계했는가

- **콤보 창을 애니메이션이 정의한다** — 코드의 타이머가 아니라 Call Method Track이
  창을 열고 닫으므로, 애니메이터가 모션을 바꾸면 타이밍이 자동으로 따라온다.
- **BlendSpace 값에 `lerp`를 적용** — 입력이 급변할 때 애니메이션이 튀는 것을 막는다.
- **로컬 속도로 변환** — 캐릭터가 회전해도 "앞으로 걷기"가 유지된다.
- **`ANIMATION_CALLBACK_MODE_PROCESS_PHYSICS`** — 물리 이동과 애니메이션이 같은
  프레임에 갱신되어 발 미끄러짐이 줄어든다.

---

## 14. 자주 하는 실수

| 실수 | 증상 | 해결 |
|------|------|------|
| `AnimationTree.active = true`인데 `play()` 호출 | 아무 반응 없음 | AnimationTree의 파라미터로 제어 |
| RESET 애니메이션 없음 | 블렌딩 시 팔다리가 이상하게 꺾임 | 모든 트랙의 기본값을 RESET에 추가 |
| 파라미터 경로 오타 | 조용히 무시됨 | 경로를 상수로 모으고 인스펙터에서 확인 |
| `_ready()`에서 즉시 `travel()` | 무시됨 | 첫 프레임 이후 호출 |
| `callback_mode_process`가 IDLE인데 물리 이동 | 발 미끄러짐 | `PROCESS_PHYSICS`로 변경 |
| walk/run 블렌딩 시 발 어긋남 | Sync Mode가 None | `Cyclic Mutable` |
| `_process`에서 본 조작 | 떨림 | `SkeletonModifier3D` 사용 |
| Root Motion 켜고 코드로도 이동 | 두 배 속도 | 상태별로 하나만 사용 |
| Tween 중복 생성 | 값이 튐 | 기존 Tween `kill()` 후 재생성 |
| 애니메이션 이름 문자열 직접 사용 | 오타 시 조용히 실패 | `StringName`(`&"name"`) 상수화 |
| Advance Expression 대소문자 | 조건이 항상 false | GDScript는 `snake_case` |
| `advance_expression_base_node` 미설정 | 표현식에서 프로퍼티 참조 실패 | `_ready()`에서 설정 |
