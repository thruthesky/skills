# 입력 처리와 Control UI

## 목차

1. [핵심 개념 — 입력 전파 순서](#1-핵심-개념--입력-전파-순서)
2. [InputMap — 액션 정의](#2-inputmap--액션-정의)
3. [Input 싱글턴 폴링](#3-input-싱글턴-폴링)
4. [InputEvent 처리](#4-inputevent-처리)
5. [마우스 캡처와 시점 조작](#5-마우스-캡처와-시점-조작)
6. [게임패드](#6-게임패드)
7. [터치와 가상 조이스틱](#7-터치와-가상-조이스틱)
8. [키 리바인딩](#8-키-리바인딩)
9. [Control 레이아웃 시스템](#9-control-레이아웃-시스템)
10. [컨테이너](#10-컨테이너)
11. [Theme와 StyleBox](#11-theme와-stylebox)
12. [RichTextLabel과 BBCode](#12-richtextlabel과-bbcode)
13. [3D 게임의 UI 구성](#13-3d-게임의-ui-구성)
14. [3D 월드 스페이스 UI](#14-3d-월드-스페이스-ui)
15. [포커스와 게임패드 UI 내비게이션](#15-포커스와-게임패드-ui-내비게이션)
16. [자주 하는 실수](#16-자주-하는-실수)

---

## 1. 핵심 개념 — 입력 전파 순서

하나의 입력 이벤트는 여러 콜백을 거쳐 전파된다. **어느 콜백에서 처리하느냐가
UI가 게임 입력을 가로챌지 말지를 결정한다.**

```
입력 발생
  │
  ├─ 1. Node._input(event)
  │       모든 노드가 받는다. 씬 트리 역순(나중에 추가된 것부터).
  │       가장 먼저 호출되므로 치트키·디버그 토글에 쓴다.
  │
  ├─ 2. Control._gui_input(event)
  │       마우스가 올라간 Control, 또는 포커스를 가진 Control만 받는다.
  │       여기서 처리하면 아래 단계로 내려가지 않는다.
  │
  ├─ 3. Node._shortcut_input(event)
  │       키/조합키 단축키 전용. InputEventKey, InputEventShortcut만.
  │
  ├─ 4. Node._unhandled_key_input(event)
  │       키 입력 중 위에서 처리되지 않은 것.
  │
  └─ 5. Node._unhandled_input(event)
          UI가 소비하지 않은 모든 입력. **게임플레이 입력은 여기서 처리한다.**
```

### 어느 콜백을 쓸 것인가

| 목적 | 콜백 |
|------|------|
| 게임플레이 (이동, 공격, 점프) | `_unhandled_input` — UI가 열려 있으면 자동으로 안 옴 |
| 마우스 시점 조작 | `_unhandled_input` |
| 일시정지, ESC | `_unhandled_input` 또는 `_shortcut_input` |
| 디버그 토글, 스크린샷 | `_input` |
| UI 버튼·슬라이더 | `_gui_input` (또는 시그널) |
| 연속 입력 (이동 방향) | 콜백이 아니라 `_physics_process`에서 `Input` 폴링 |

### set_input_as_handled()

```gdscript
func _unhandled_input(event: InputEvent) -> void:
    if event.is_action_pressed("pause"):
        _toggle_pause()
        get_viewport().set_input_as_handled()      # 이후 노드로 전파 중단
```

이 호출을 빼면 같은 입력을 여러 노드가 중복 처리한다.
**한 이벤트를 소비했으면 반드시 호출한다.**

---

## 2. InputMap — 액션 정의

물리적 키 대신 **액션 이름**으로 입력을 다룬다. 키 리바인딩과 여러 입력 장치 지원의 전제다.

### project.godot 표기

```ini
[input]

move_forward={
"deadzone": 0.2,
"events": [Object(InputEventKey,"physical_keycode":87)
, Object(InputEventJoypadMotion,"axis":1,"axis_value":-1.0)
]
}
jump={
"deadzone": 0.2,
"events": [Object(InputEventKey,"physical_keycode":32)
, Object(InputEventJoypadButton,"button_index":0)
]
}
```

**`physical_keycode`를 쓴다.** `keycode`는 키보드 레이아웃(QWERTY/AZERTY)에 따라
바뀌지만, `physical_keycode`는 물리적 키 위치를 가리키므로 어떤 레이아웃에서도
WASD가 같은 위치에 있다.

### 이 프로젝트 권장 액션 목록

```
move_forward / move_back / move_left / move_right
jump / crouch / sprint
attack_primary / attack_secondary
interact / reload
inventory / map / pause
camera_zoom_in / camera_zoom_out
ui_accept / ui_cancel / ui_up / ui_down / ui_left / ui_right    (엔진 내장)
```

### 코드에서 액션 관리

```gdscript
# 액션 추가
if not InputMap.has_action("dash"):
    InputMap.add_action("dash", 0.2)      # 두 번째 인자는 데드존

var ev := InputEventKey.new()
ev.physical_keycode = KEY_SHIFT
InputMap.action_add_event("dash", ev)

# 조회
var events := InputMap.action_get_events("dash")
var actions := InputMap.get_actions()

# 제거·교체
InputMap.action_erase_events("dash")
InputMap.action_erase_event("dash", ev)
InputMap.erase_action("dash")

# 이벤트가 특정 액션인지
if InputMap.event_is_action(event, "jump"):
    pass

# 프로젝트 설정에서 다시 로드 (리바인딩 초기화)
InputMap.load_from_project_settings()
```

---

## 3. Input 싱글턴 폴링

연속적으로 상태를 확인할 때 쓴다. 이벤트 콜백이 아니라 `_process`/`_physics_process`에서 호출한다.

```gdscript
func _physics_process(delta: float) -> void:
    # 눌린 상태 확인
    if Input.is_action_pressed("sprint"):
        speed = sprint_speed

    # 이번 프레임에 눌렸는가 (한 번만 true)
    if Input.is_action_just_pressed("jump"):
        _jump()

    # 이번 프레임에 떼어졌는가
    if Input.is_action_just_released("attack_primary"):
        _release_charge()

    # 아날로그 강도 (게임패드 트리거는 0~1)
    var throttle := Input.get_action_strength("accelerate")

    # 축 (두 액션의 차)
    var turn := Input.get_axis("turn_left", "turn_right")     # -1 ~ 1

    # 2D 벡터 (가장 많이 쓴다 — 데드존과 정규화 자동 처리)
    var move := Input.get_vector(
        "move_left", "move_right", "move_forward", "move_back"
    )
```

**`Input.get_vector()`를 쓰는 이유**: 키보드에서 대각선 이동 시 속도가 √2배가 되는
문제를 자동으로 처리하고, 게임패드 스틱의 원형 데드존도 적용한다.
직접 `Vector2(get_axis(...), get_axis(...))`로 만들면 이 처리가 빠진다.

### 기타 Input API

```gdscript
Input.get_mouse_button_mask()
Input.get_last_mouse_velocity()
Input.warp_mouse(Vector2(400, 300))
Input.set_default_cursor_shape(Input.CURSOR_CROSS)
Input.set_custom_mouse_cursor(texture, Input.CURSOR_ARROW, Vector2(8, 8))

Input.start_joy_vibration(0, 0.5, 0.8, 0.3)     # device, weak, strong, duration
Input.stop_joy_vibration(0)
Input.vibrate_handheld(200)                      # 모바일 진동(ms)

Input.get_gravity()          # 모바일 중력 센서
Input.get_accelerometer()
Input.get_gyroscope()
Input.get_magnetometer()

# 가상 입력 주입 (테스트, 리플레이, AI)
Input.action_press("jump")
Input.action_release("jump")
Input.parse_input_event(event)
```

---

## 4. InputEvent 처리

```gdscript
func _unhandled_input(event: InputEvent) -> void:
    # 액션 기반 (권장)
    if event.is_action_pressed("attack_primary"):
        _attack()
        get_viewport().set_input_as_handled()
    elif event.is_action_released("attack_primary"):
        _stop_attack()

    # 타입 기반
    if event is InputEventMouseMotion:
        var m := event as InputEventMouseMotion
        _look(m.screen_relative)
    elif event is InputEventMouseButton:
        var mb := event as InputEventMouseButton
        if mb.button_index == MOUSE_BUTTON_WHEEL_UP:
            _zoom_in()
    elif event is InputEventKey:
        var k := event as InputEventKey
        if k.pressed and k.keycode == KEY_F3 and not k.echo:
            _toggle_debug()
```

### InputEvent 계층

```
InputEvent
├─ InputEventFromWindow
│  ├─ InputEventWithModifiers        alt_pressed, ctrl_pressed, shift_pressed, meta_pressed
│  │  ├─ InputEventKey               keycode, physical_keycode, key_label, unicode, echo, pressed
│  │  ├─ InputEventMouse             position, global_position, button_mask
│  │  │  ├─ InputEventMouseButton    button_index, pressed, double_click, factor
│  │  │  └─ InputEventMouseMotion    relative, screen_relative, velocity, screen_velocity, pressure, tilt
│  │  ├─ InputEventGesture
│  │  │  ├─ InputEventMagnifyGesture
│  │  │  └─ InputEventPanGesture
│  │  ├─ InputEventScreenTouch       index, position, pressed, double_tap
│  │  └─ InputEventScreenDrag        index, position, relative, screen_relative, velocity
├─ InputEventJoypadButton            button_index, pressed, pressure
├─ InputEventJoypadMotion            axis, axis_value
├─ InputEventAction                  action, pressed, strength (코드로 만든 가상 입력)
├─ InputEventShortcut
└─ InputEventMIDI
```

### 장치 ID — `device` 속성 (4.7 확장)

모든 `InputEvent`에는 어느 장치에서 왔는지 나타내는 `device` 정수가 있다.
4.7부터 **키보드와 마우스에도 고정 ID가 부여**되어, 이벤트 타입을 검사하지 않고도
장치를 구분할 수 있다.

| 상수 | 값 | 대상 |
|---|---|---|
| `InputEvent.DEVICE_ID_EMULATION` | `-1` | 엔진이 만든 에뮬레이션 이벤트 (터치→마우스 변환 등) |
| `InputEvent.DEVICE_ID_KEYBOARD` | `16` | 모든 키보드 입력 |
| `InputEvent.DEVICE_ID_MOUSE` | `32` | 모든 마우스 입력 |
| `0`, `1`, `2` … | 0부터 | **게임패드**. 연결 순서대로 부여 |

```gdscript
func _input(event: InputEvent) -> void:
    match event.device:
        InputEvent.DEVICE_ID_KEYBOARD:
            _show_prompts_for(&"keyboard")
        InputEvent.DEVICE_ID_MOUSE:
            _show_prompts_for(&"mouse")
        InputEvent.DEVICE_ID_EMULATION:
            pass                                  # 엔진이 합성한 이벤트 — 무시
        _:
            _show_prompts_for(&"gamepad")         # 0 이상 = 게임패드 슬롯
```

**함정 — `device == 0`은 게임패드만의 것이 아니다.**
`InputEventScreenTouch`와 `InputEventAction`도 `device`가 `0`이다.
그래서 위 `match`의 `_` 분기는 터치 이벤트까지 게임패드로 잘못 분류한다.
터치를 쓰는 프로젝트(= 라리엔 3D)에서는 **타입 검사를 함께** 한다.

```gdscript
func _is_gamepad_event(event: InputEvent) -> bool:
    return event is InputEventJoypadButton or event is InputEventJoypadMotion
```

여러 키보드·마우스를 개별 식별하는 기능은 **아직 없다.** 4.7의 이 변경은
그것을 나중에 구현할 수 있도록 기반만 마련한 것이다. 지금은 모든 키보드가 `16`,
모든 마우스가 `32`로 동일하게 들어온다.

### `relative` vs `screen_relative`

Godot 4.x에서 마우스 이동량은 두 가지가 있다.

| 속성 | 의미 |
|------|------|
| `relative` | 뷰포트 좌표계 기준. 스트레치/스케일의 영향을 받음 |
| `screen_relative` | 실제 화면 픽셀 기준. **DPI·스트레치와 무관** |

**시점 조작에는 `screen_relative`를 쓴다.** 이 프로젝트는
`window/stretch/mode="canvas_items"`이므로 `relative`를 쓰면 창 크기에 따라
마우스 감도가 달라진다.

---

## 5. 마우스 캡처와 시점 조작

```gdscript
# 모드 4가지
Input.MOUSE_MODE_VISIBLE          # 기본
Input.MOUSE_MODE_HIDDEN           # 숨김 (움직임은 그대로)
Input.MOUSE_MODE_CAPTURED         # 숨김 + 중앙 고정 + 무한 이동 — FPS 표준
Input.MOUSE_MODE_CONFINED         # 창 안에 가둠 (보임)
Input.MOUSE_MODE_CONFINED_HIDDEN  # 창 안에 가둠 (숨김)
```

### 실전 관리 코드

```gdscript
class_name MouseCaptureManager
extends Node

func _ready() -> void:
    capture()

func capture() -> void:
    Input.mouse_mode = Input.MOUSE_MODE_CAPTURED

func release() -> void:
    Input.mouse_mode = Input.MOUSE_MODE_VISIBLE

func _unhandled_input(event: InputEvent) -> void:
    if event.is_action_pressed("ui_cancel"):
        release()
        get_viewport().set_input_as_handled()
    elif event is InputEventMouseButton:
        var mb := event as InputEventMouseButton
        # 게임 화면 클릭 시 다시 캡처 (UI가 안 열려 있을 때만)
        if mb.pressed and Input.mouse_mode == Input.MOUSE_MODE_VISIBLE \
                and not _is_ui_open():
            capture()

func _notification(what: int) -> void:
    # 창 포커스를 잃으면 캡처 해제 (알트탭 대응)
    if what == NOTIFICATION_APPLICATION_FOCUS_OUT:
        if Input.mouse_mode == Input.MOUSE_MODE_CAPTURED:
            release()

func _is_ui_open() -> bool:
    return get_tree().paused
```

**시점 조작은 반드시 `_unhandled_input`에 둔다.** `_input`에 두면 UI가 열려 있을 때도
마우스 이동이 카메라를 돌린다.

---

## 6. 게임패드

```gdscript
# 연결된 패드 확인
for device_id in Input.get_connected_joypads():
    print(Input.get_joy_name(device_id), " GUID: ", Input.get_joy_guid(device_id))
    var info := Input.get_joy_info(device_id)      # 4.4+ 상세 정보

# 연결/해제 감지
func _ready() -> void:
    Input.joy_connection_changed.connect(_on_joy_changed)

func _on_joy_changed(device: int, connected: bool) -> void:
    if connected:
        _switch_to_gamepad_ui()
    else:
        _switch_to_keyboard_ui()

# 직접 조회 (액션이 아닌 raw 값)
var lx := Input.get_joy_axis(0, JOY_AXIS_LEFT_X)
var trigger := Input.get_joy_axis(0, JOY_AXIS_TRIGGER_RIGHT)
if Input.is_joy_button_pressed(0, JOY_BUTTON_A):
    pass

# 진동
Input.start_joy_vibration(0, 0.3, 0.7, 0.25)      # weak, strong, duration
```

### 입력 장치 자동 감지 (UI 프롬프트 전환)

```gdscript
class_name InputDeviceTracker
extends Node

signal device_changed(is_gamepad: bool)

var is_gamepad: bool = false

func _input(event: InputEvent) -> void:
    var now_gamepad := event is InputEventJoypadButton \
                    or event is InputEventJoypadMotion
    var now_kbm := event is InputEventKey \
                or event is InputEventMouseButton
    # 스틱 미세 드리프트로 오탐하지 않도록 임계값 확인
    if event is InputEventJoypadMotion:
        var jm := event as InputEventJoypadMotion
        if absf(jm.axis_value) < 0.5:
            return
    if now_gamepad and not is_gamepad:
        is_gamepad = true
        device_changed.emit(true)
    elif now_kbm and is_gamepad:
        is_gamepad = false
        device_changed.emit(false)
```

### SDL3 게임패드 드라이버

게임패드 처리가 **SDL3에 위임**되었다. SDL은 오디오·키보드·마우스·조이스틱·그래픽을
다루는 성숙한 크로스플랫폼 라이브러리로, 오래 검증되었다.

기존 자체 드라이버는 시간이 지나며 문제가 쌓이고 최신 게임패드 기능(적응형 트리거,
고급 햅틱, 마이크, 모션 컨트롤)을 따라가지 못했다. SDL3로 옮기면서 **이 부담을 덜었다.**

**이 전환 자체가 새 기능을 주지는 않는다.** 다만 앞으로 버그 수정과 새 기능이
더 빨리 들어온다. 지금 당장의 이득은 **호환성**이다. 예전에 인식되지 않던 패드가
그냥 동작할 가능성이 높아졌다.

코드에서 달라질 것은 없다. `Input.get_joy_name()`, `Input.get_connected_joypads()`,
액션 매핑 모두 그대로 쓴다.

### 그 밖의 게임패드 개선

- iOS도 SDL3로 전환되어 컨트롤러 호환성이 크게 향상되었다.
- 자이로·가속도계 입력 지원.
- 키보드/마우스도 장치 ID로 식별할 수 있다
  (→ [4. InputEvent 처리](#4-inputevent-처리)의 장치 ID 표).

### 창이 포커스를 잃었을 때 게임패드 입력 무시

운영체제는 게임패드 입력을 **창이 비활성 상태여도 계속 보낸다.** 키보드·마우스와
다른 점이다. 그래서 알트탭으로 다른 창을 보는 동안 패드를 건드리면 게임이 반응하고,
최악의 경우 메뉴에서 "게임 종료"가 눌린다.

4.7부터 이를 막는 프로젝트 설정이 생겼다.

```ini
[input_devices]

joypads/ignore_joypad_on_unfocused_application=true
```

에디터 경로: `Project > Project Settings > Input Devices > Joypads >
Ignore Joypad On Unfocused Application`
(`Advanced Settings` 토글을 켜야 보인다.)

**기본값은 `false`다.** 기존 동작을 유지하기 위한 선택이므로, 필요하면 직접 켠다.

| 켜야 하는 경우 | 끄는 게 나은 경우 |
|---|---|
| 일반적인 싱글·멀티 게임 (Steam 빌드 포함) | 배경에서 계속 입력을 받아야 하는 도구 |
| 알트탭이 잦은 PC 환경 | 여러 창을 동시에 조작하는 특수 앱 |

라리엔 3D의 Steam(PC) 빌드는 **켜는 쪽이 맞다.** 모바일은 창 개념이 달라
영향이 사실상 없다. `project.godot`은 Claude가 수정하지 않으므로(→ CLAUDE.md 규칙)
사람이 위 경로에서 적용한다.

---

## 7. 터치와 가상 조이스틱

이 프로젝트는 Android를 대상으로 하므로 터치 입력이 필요하다.

### 터치를 마우스로 에뮬레이션

```ini
[input_devices]

pointing/emulate_mouse_from_touch=true    # 기본 true — 터치가 마우스 이벤트로도 전달됨
pointing/emulate_touch_from_mouse=false
```

에뮬레이션을 켜면 UI 버튼이 터치에서도 그냥 동작한다.
다만 멀티터치가 필요하면 `InputEventScreenTouch`/`InputEventScreenDrag`를 직접 처리한다.

### 4.7 내장 가상 조이스틱 — VirtualJoystick 노드

Godot 4.7부터 `VirtualJoystick`이 **엔진에 내장**되었다. 애드온이 필요 없다.
라리엔 3D는 모바일에서 왼손 엄지로 이동하므로, 이동 입력은 이 노드로 만든다.

#### 핵심 개념 — 값을 읽는 API가 없다

가장 먼저 알아야 할 사실이다. `VirtualJoystick`에는 **출력값을 돌려주는 메서드도
프로퍼티도 없다.** `get_output()`도 `output` 프로퍼티도 존재하지 않는다.
공개 메서드는 전부 위 프로퍼티의 setter/getter 뿐이다.
(서드파티 애드온에는 `output`이 있어서 혼동하기 쉽다. 내장 노드에는 없다.)

대신 이 노드는 지정된 **InputMap 액션에 강도(strength)를 직접 주입**한다.
그래서 게임플레이 코드는 조이스틱의 존재를 알 필요가 없다.

```gdscript
# 조이스틱이 있든 없든, 키보드든 터치든 이 코드 하나로 동작한다
var input := Input.get_vector(&"move_left", &"move_right", &"move_forward", &"move_back")
```

이것이 설계 의도다. **조이스틱을 화면에 놓기만 하면 기존 이동 코드가 그대로 돌아간다.**
값이 꼭 필요하면 `Input.get_vector()`로 읽거나 아래 시그널을 쓴다.

#### 전체 API (엔진에서 직접 추출한 값)

상속: `VirtualJoystick < Control < CanvasItem < Node < Object`

**프로퍼티**

| 프로퍼티 | 타입 | 기본값 | 에디터 범위 | 의미 |
|---|---|---|---|---|
| `joystick_mode` | `JoystickMode` | `0` (Fixed) | — | 조이스틱 배치 방식 |
| `visibility_mode` | `VisibilityMode` | `0` (Always) | — | 표시 조건 |
| `joystick_size` | `float` | `100.0` | 10~500 | 바깥 원(배경)의 크기(px) |
| `tip_size` | `float` | `50.0` | 5~250 | 손잡이(팁)의 크기(px) |
| `deadzone_ratio` | `float` | `0.0` | 0~1 | 이 반경 비율 안쪽은 입력 0으로 취급 |
| `clampzone_ratio` | `float` | `1.0` | 0~2 | 팁이 벗어날 수 있는 최대 반경 비율 |
| `initial_offset_ratio` | `Vector2` | `(0.5, 0.5)` | 0~1 | Control 사각형 안에서 조이스틱 중심 위치 |
| `action_left` | `StringName` | `&"ui_left"` | — | 왼쪽 입력을 주입할 액션 |
| `action_right` | `StringName` | `&"ui_right"` | — | 오른쪽 입력을 주입할 액션 |
| `action_up` | `StringName` | `&"ui_up"` | — | 위쪽 입력을 주입할 액션 |
| `action_down` | `StringName` | `&"ui_down"` | — | 아래쪽 입력을 주입할 액션 |

**열거형**

```gdscript
# JoystickMode
VirtualJoystick.JOYSTICK_FIXED      # 0 — 조이스틱이 움직이지 않는다
VirtualJoystick.JOYSTICK_DYNAMIC    # 1 — 처음 터치한 곳에 나타나고, 떼면 원위치로 돌아온다
VirtualJoystick.JOYSTICK_FOLLOWING  # 2 — 터치한 곳에 나타나고, 손가락이 범위를 벗어나면 따라간다

# VisibilityMode
VirtualJoystick.VISIBILITY_ALWAYS        # 0 — 항상 보인다
VirtualJoystick.VISIBILITY_WHEN_TOUCHED  # 1 — 터치 중일 때만 보인다
```

**시그널**

| 시그널 | 인자 | 발생 시점 |
|---|---|---|
| `pressed()` | — | 조이스틱을 누른 순간 |
| `released(input_vector: Vector2)` | 뗄 때의 입력 벡터 | 손을 뗀 순간 |
| `tapped()` | — | **팁을 움직이지 않고** 떼었을 때 (= 탭) |
| `flicked(input_vector: Vector2)` | 튕긴 방향 | 데드존 밖으로 움직인 뒤 떼었을 때 |
| `flick_canceled()` | — | 데드존 밖에 있던 팁이 다시 데드존 안으로 들어왔을 때 |

`tapped`와 `flicked`는 상호 배타적이다. 움직였으면 `flicked`, 안 움직였으면 `tapped`가
오고, 어느 쪽이든 `released`는 항상 함께 발생한다.

**테마 프로퍼티** — 전부 `StyleBox`이며 기본 테마에서는 `StyleBoxFlat`이 들어 있다.

| 이름 | 대상 |
|---|---|
| `normal_joystick` | 평상시 바깥 원 |
| `normal_tip` | 평상시 팁 |
| `pressed_joystick` | 누르는 중 바깥 원 |
| `pressed_tip` | 누르는 중 팁 |

#### 씬 배치 — 사람이 에디터에서 한다

`.tscn`은 Claude가 수정하지 않는다(→ CLAUDE.md 규칙). 아래를 사람이 적용한다.

```
HUDLayer (CanvasLayer)
└─ HUD (Control, FULL_RECT, mouse_filter = IGNORE)
   └─ MoveJoystick (VirtualJoystick)     ← 화면 좌하단
```

`Project > Project Settings > Input Map`에서 이동 액션 4개를 먼저 만든다.
그 다음 인스펙터에서 `MoveJoystick`을 이렇게 설정한다.

| 항목 | 값 | 이유 |
|---|---|---|
| Layout | 좌하단 앵커 + 크기 약 `280 × 280` | **터치를 받는 영역은 Control의 크기다** (아래 함정 참고) |
| Joystick Mode | `Dynamic` | 엄지를 어디에 올려도 잡힌다. 화면을 안 가린다 |
| Visibility Mode | `When Touched` | 평소엔 화면이 깨끗하다 |
| Joystick Size | `160` | 엄지 기준. 기본 100은 모바일에서 작다 |
| Tip Size | `70` | 바깥 원의 약 45% |
| Deadzone Ratio | `0.15` | **기본 0은 손 떨림이 그대로 이동이 된다** |
| Clampzone Ratio | `1.0` | 원 밖으로 안 나감 |
| Action Left/Right/Up/Down | `move_left` / `move_right` / `move_forward` / `move_back` | **`ui_*` 기본값을 반드시 바꾼다** |

#### 카메라 기준으로 변환한다 — 3D에서 가장 중요한 부분

조이스틱이 주는 것은 **화면 기준 2D 벡터**다. 라리엔 3D는 카메라 yaw를 45도 단위로
회전할 수 있으므로(→ CLAUDE.md 카메라 규칙), 이 벡터를 그대로 월드 이동에 쓰면
카메라를 돌린 뒤 조작 방향이 어긋난다. 카메라 기준으로 변환해야 한다.

```gdscript
extends CharacterBody3D

@export var speed: float = 6.0
@onready var _camera: Camera3D = get_viewport().get_camera_3d()

func _physics_process(delta: float) -> void:
    # 조이스틱이든 키보드든 게임패드든 동일하게 읽힌다
    var input := Input.get_vector(&"move_left", &"move_right", &"move_forward", &"move_back")

    # 화면 기준 → 월드 기준. 카메라의 yaw만 반영한다 (피치는 고정이므로 y는 버린다)
    var basis := _camera.global_transform.basis
    var forward := -basis.z
    var right := basis.x
    forward.y = 0.0
    right.y = 0.0
    var direction := (right * input.x + forward * input.y).normalized()

    velocity.x = direction.x * speed
    velocity.z = direction.z * speed
    if not is_on_floor():
        velocity.y -= 20.0 * delta
    move_and_slide()

    # 이동 방향으로 캐릭터를 부드럽게 회전
    if direction.length_squared() > 0.01:
        var target_yaw := atan2(direction.x, direction.z)
        rotation.y = lerp_angle(rotation.y, target_yaw, 12.0 * delta)
```

`Input.get_vector()`의 y축은 `up`이 음수라 `input.y`가 그대로 "앞"이 된다.
`forward * input.y`에 부호를 뒤집지 않는 이유가 이것이다.

#### 시그널 활용 — 탭과 플릭

액션 주입만으로는 안 되는 제스처는 시그널로 받는다.

```gdscript
extends VirtualJoystick

@export var dash_threshold: float = 0.85

func _ready() -> void:
    flicked.connect(_on_flicked)
    tapped.connect(_on_tapped)

func _on_flicked(input_vector: Vector2) -> void:
    # 세게 튕기면 회피 대시. 살짝 움직인 것과 구분한다
    if input_vector.length() >= dash_threshold:
        Player.request_dash(input_vector)

func _on_tapped() -> void:
    # 움직이지 않고 떼면 제자리 상호작용 (줍기 등)
    Player.interact()
```

#### 터치 기기에서만 보이게 한다

Steam(PC) 빌드에서는 조이스틱이 화면을 가릴 뿐이다.

```gdscript
extends VirtualJoystick

func _ready() -> void:
    # 터치가 없는 기기에서는 숨긴다. 액션 주입도 함께 멈춘다
    visible = DisplayServer.is_touchscreen_available()
```

숨겨도 액션은 InputMap에 그대로 있으므로, 키보드·게임패드 입력이 같은 액션을 눌러
게임플레이 코드는 변경 없이 동작한다.

#### 테마로 외형 바꾸기

```gdscript
# 코드에서 개별 오버라이드 (한 노드만)
var outer := StyleBoxFlat.new()
outer.bg_color = Color(1, 1, 1, 0.12)
outer.set_corner_radius_all(999)          # 완전한 원
add_theme_stylebox_override("normal_joystick", outer)

var tip := StyleBoxFlat.new()
tip.bg_color = Color(1, 1, 1, 0.55)
tip.set_corner_radius_all(999)
add_theme_stylebox_override("normal_tip", tip)
```

프로젝트 전체에 적용하려면 `Theme` 리소스에서 타입 `VirtualJoystick`의
StyleBox 4개를 지정한다(→ [11. Theme와 StyleBox](#11-theme와-stylebox)).

#### 함정

**1. Control 크기를 안 잡으면 터치가 안 먹는다**

`joystick_size`는 **그려지는 원의 크기**일 뿐, Control의 레이아웃 크기와 무관하다.
실제로 `joystick_size`를 바꿔도 `get_minimum_size()`는 `(0, 0)`으로 그대로다.
터치를 받는 범위는 **Control의 `size`**이므로, 앵커/오프셋으로 크기를 직접 잡아야 한다.
크기가 0이면 조이스틱 그림은 보여도 손가락에 반응하지 않는다.

**2. 기본 액션이 `ui_left`/`ui_right`/`ui_up`/`ui_down`이다**

그대로 두면 조이스틱을 움직일 때마다 **UI 포커스가 돌아다닌다.**
메뉴가 열려 있으면 버튼 선택이 제멋대로 바뀐다. 반드시 게임 액션으로 교체한다.

**3. InputMap에 없는 액션을 지정하면 에러가 쏟아진다**

`action_*` 프로퍼티는 에디터 힌트가 `loose_mode`라 등록되지 않은 이름도 입력된다.
하지만 실행 중 주입 시점에 매 프레임 이런 에러가 난다.

```
ERROR: The InputMap action "move_forward" doesn't exist.
```

조용히 실패하지 않고 로그를 가득 채우므로, 액션을 먼저 만들어 둔다.

**4. `deadzone_ratio` 기본값이 `0.0`이다**

데드존이 아예 없다는 뜻이다. 엄지를 올려놓기만 해도 캐릭터가 미끄러진다.
모바일에서는 `0.1`~`0.2`를 준다.

**5. `Fixed` 모드는 엄지 위치를 강제한다**

화면 크기가 제각각인 안드로이드에서 고정 위치는 손이 닿지 않을 수 있다.
`Dynamic`이 기본 선택지다. `Following`은 손가락이 멀리 끌려가도 계속 조작되므로
드래그가 긴 게임에 맞는다.

**6. 두 개 이상 놓을 때는 영역이 겹치지 않게 한다**

왼손 이동 + 오른손 시점처럼 두 개를 쓸 경우, 두 Control의 사각형이 겹치면
먼저 처리한 쪽이 터치를 가져간다. 화면을 좌우로 확실히 나눈다.

### 직접 구현 (내장 노드로 부족할 때)

내장 노드는 원형 조이스틱 하나로 고정이다. 아래처럼 요구사항이 벗어나면 직접 만든다.

- 8방향 스냅, 사각형·십자 모양 등 원형이 아닌 입력
- 조이스틱 위에 스킬 아이콘·쿨다운 링 같은 커스텀 위젯을 올려야 할 때
- 입력값에 자체 곡선(가속 커브)을 적용해야 할 때

액션 주입 방식은 내장 노드와 동일하게 가져간다. 그래야 게임플레이 코드가 같아진다.

```gdscript
class_name TouchJoystick
extends Control

signal moved(direction: Vector2)

@export var max_radius: float = 90.0
@export var dead_zone: float = 0.15
@export var action_left: StringName = &"move_left"
@export var action_right: StringName = &"move_right"
@export var action_up: StringName = &"move_forward"
@export var action_down: StringName = &"move_back"

var _touch_index: int = -1
var _origin: Vector2
var _value: Vector2 = Vector2.ZERO

@onready var base: TextureRect = $Base
@onready var knob: TextureRect = $Knob

func _gui_input(event: InputEvent) -> void:
    if event is InputEventScreenTouch:
        var t := event as InputEventScreenTouch
        if t.pressed and _touch_index == -1:
            _touch_index = t.index
            _origin = t.position
            base.global_position = _origin - base.size * 0.5
            base.visible = true
            accept_event()
        elif not t.pressed and t.index == _touch_index:
            _release()
            accept_event()
    elif event is InputEventScreenDrag:
        var d := event as InputEventScreenDrag
        if d.index == _touch_index:
            _update(d.position)
            accept_event()

func _update(pos: Vector2) -> void:
    var offset := (pos - _origin).limit_length(max_radius)
    knob.global_position = _origin + offset - knob.size * 0.5
    _value = offset / max_radius
    if _value.length() < dead_zone:
        _value = Vector2.ZERO
    _apply_actions()
    moved.emit(_value)

func _release() -> void:
    _touch_index = -1
    _value = Vector2.ZERO
    base.visible = false
    _apply_actions()
    moved.emit(Vector2.ZERO)

func _apply_actions() -> void:
    # Input 액션에 직접 강도를 주입 → 기존 이동 코드를 그대로 재사용
    Input.action_release(action_left)
    Input.action_release(action_right)
    Input.action_release(action_up)
    Input.action_release(action_down)
    if _value.x < 0.0:
        Input.action_press(action_left, -_value.x)
    elif _value.x > 0.0:
        Input.action_press(action_right, _value.x)
    if _value.y < 0.0:
        Input.action_press(action_up, -_value.y)
    elif _value.y > 0.0:
        Input.action_press(action_down, _value.y)
```

**핵심 로직**: 조이스틱 값을 `Input.action_press(action, strength)`로 주입하면
게임플레이 코드는 키보드인지 터치인지 구분할 필요가 없다.
`Input.get_vector()`가 그대로 동작한다.

---

## 8. 키 리바인딩

```gdscript
class_name RebindManager
extends Node

const SAVE_PATH := "user://input_bindings.cfg"

func start_rebind(action: StringName, on_done: Callable) -> void:
    set_process_input(true)
    _pending_action = action
    _pending_callback = on_done

var _pending_action: StringName = &""
var _pending_callback: Callable

func _input(event: InputEvent) -> void:
    if _pending_action.is_empty():
        return
    # 리바인딩 가능한 이벤트만 수락
    var valid := event is InputEventKey and event.pressed \
              or event is InputEventMouseButton and event.pressed \
              or event is InputEventJoypadButton and event.pressed
    if not valid:
        return
    if event is InputEventKey and (event as InputEventKey).keycode == KEY_ESCAPE:
        _finish(false)
        return

    InputMap.action_erase_events(_pending_action)
    InputMap.action_add_event(_pending_action, event)
    get_viewport().set_input_as_handled()
    _finish(true)

func _finish(success: bool) -> void:
    set_process_input(false)
    var cb := _pending_callback
    _pending_action = &""
    _pending_callback = Callable()
    if cb.is_valid():
        cb.call(success)

# ── 저장/로드 ────────────────────────────────────────
func save_bindings() -> void:
    var cfg := ConfigFile.new()
    for action in InputMap.get_actions():
        if String(action).begins_with("ui_"):
            continue      # 엔진 기본 UI 액션은 저장하지 않는다
        cfg.set_value("input", action, InputMap.action_get_events(action))
    cfg.save(SAVE_PATH)

func load_bindings() -> void:
    var cfg := ConfigFile.new()
    if cfg.load(SAVE_PATH) != OK:
        return
    for action in cfg.get_section_keys("input"):
        if not InputMap.has_action(action):
            continue
        InputMap.action_erase_events(action)
        for ev in cfg.get_value("input", action):
            InputMap.action_add_event(action, ev)

func reset_to_default() -> void:
    InputMap.load_from_project_settings()
```

### 키 이름 표시

```gdscript
func get_binding_text(action: StringName) -> String:
    var events := InputMap.action_get_events(action)
    if events.is_empty():
        return "없음"
    var ev := events[0]
    if ev is InputEventKey:
        var k := ev as InputEventKey
        # physical_keycode를 현재 레이아웃의 표시 이름으로 변환
        return OS.get_keycode_string(
            DisplayServer.keyboard_get_keycode_from_physical(k.physical_keycode)
        )
    elif ev is InputEventMouseButton:
        return "마우스 %d" % (ev as InputEventMouseButton).button_index
    elif ev is InputEventJoypadButton:
        return "패드 %d" % (ev as InputEventJoypadButton).button_index
    return ev.as_text()
```

---

## 9. Control 레이아웃 시스템

Control은 **앵커(anchor) + 오프셋(offset)** 으로 위치를 정한다.

```
anchor_left/top/right/bottom : 0.0 ~ 1.0 — 부모 사각형 기준 비율
offset_left/top/right/bottom : 픽셀 — 앵커 지점으로부터의 거리
```

```gdscript
# 예: 화면 우상단에 고정, 크기 200x80
control.anchor_left = 1.0
control.anchor_top = 0.0
control.anchor_right = 1.0
control.anchor_bottom = 0.0
control.offset_left = -220.0
control.offset_top = 20.0
control.offset_right = -20.0
control.offset_bottom = 100.0
```

### 프리셋 (실무에서 대부분 이걸로 충분)

```gdscript
control.set_anchors_preset(Control.PRESET_FULL_RECT)      # 부모 전체 채움
control.set_anchors_preset(Control.PRESET_CENTER)
control.set_anchors_preset(Control.PRESET_TOP_LEFT)
control.set_anchors_preset(Control.PRESET_BOTTOM_WIDE)    # 하단 가로 전체

# 앵커 + 오프셋을 한 번에
control.set_anchors_and_offsets_preset(
    Control.PRESET_FULL_RECT, Control.PRESET_MODE_MINSIZE, 16     # 여백 16px
)
```

에디터에서는 상단의 "Layout" 버튼으로 같은 작업을 한다.

### 크기 플래그

컨테이너 안에 있을 때만 유효하다.

```gdscript
control.size_flags_horizontal = Control.SIZE_EXPAND_FILL
control.size_flags_vertical = Control.SIZE_SHRINK_CENTER
control.size_flags_stretch_ratio = 2.0      # 다른 형제 대비 2배 공간
```

| 플래그 | 동작 |
|--------|------|
| `SIZE_SHRINK_BEGIN` | 최소 크기, 시작 정렬 |
| `SIZE_SHRINK_CENTER` | 최소 크기, 중앙 정렬 |
| `SIZE_SHRINK_END` | 최소 크기, 끝 정렬 |
| `SIZE_FILL` | 할당된 공간 채움 |
| `SIZE_EXPAND` | 남는 공간을 요구 |
| `SIZE_EXPAND_FILL` | 요구 + 채움 (가장 많이 씀) |

### 마우스 필터

**UI가 게임 입력을 막는 문제의 90%는 이것 때문이다.**

```gdscript
control.mouse_filter = Control.MOUSE_FILTER_STOP      # 입력 소비 (기본, 버튼 등)
control.mouse_filter = Control.MOUSE_FILTER_PASS      # 처리 후 통과
control.mouse_filter = Control.MOUSE_FILTER_IGNORE    # 완전 무시 — HUD 배경에 필수
```

**HUD의 배경 `Control`/`Panel`은 반드시 `MOUSE_FILTER_IGNORE`로 둔다.**
그렇지 않으면 화면을 덮은 HUD가 모든 마우스 클릭을 삼켜 게임이 반응하지 않는다.

---

## 10. 컨테이너

컨테이너는 자식의 위치·크기를 자동으로 정한다. 자식의 `position`/`size`를
직접 설정해도 무시된다.

| 컨테이너 | 배치 |
|---------|------|
| `VBoxContainer` / `HBoxContainer` | 세로/가로 나열 (`theme_override_constants/separation`) |
| `GridContainer` | 격자 (`columns`) |
| `MarginContainer` | 여백 추가 (`theme_override_constants/margin_*`) |
| `CenterContainer` | 자식을 중앙에 |
| `PanelContainer` | 배경 패널 + 자식 하나 |
| `ScrollContainer` | 스크롤 (자식의 `size_flags`가 중요) |
| `TabContainer` | 탭 |
| `SplitContainer` (H/V) | 드래그로 크기 조절 |
| `AspectRatioContainer` | 비율 유지 |
| `FlowContainer` (H/V) | 넘치면 다음 줄로 |
| `SubViewportContainer` | SubViewport 표시 |

### 전형적인 UI 조합

```
Control (PRESET_FULL_RECT, MOUSE_FILTER_IGNORE)
└─ MarginContainer (여백 24)
   └─ VBoxContainer (separation 12)
      ├─ Label ("설정")
      ├─ HBoxContainer
      │  ├─ Label ("마우스 감도")     size_flags_horizontal = EXPAND_FILL
      │  └─ HSlider                    custom_minimum_size.x = 200
      ├─ HBoxContainer
      │  ├─ Label ("전체화면")
      │  └─ CheckButton
      └─ HBoxContainer
         ├─ Button ("적용")
         └─ Button ("취소")
```

### 커스텀 최소 크기

```gdscript
control.custom_minimum_size = Vector2(200, 48)
```

컨테이너 안에서 크기를 보장하려면 `size` 대신 `custom_minimum_size`를 쓴다.

---

## 11. Theme와 StyleBox

### 개별 오버라이드 (한 노드만)

```gdscript
label.add_theme_font_size_override("font_size", 24)
label.add_theme_color_override("font_color", Color.YELLOW)
label.add_theme_constant_override("outline_size", 4)
button.add_theme_stylebox_override("normal", my_stylebox)
container.add_theme_constant_override("separation", 16)

# 제거
label.remove_theme_color_override("font_color")

# 조회
var c := label.get_theme_color("font_color")
var sb := button.get_theme_stylebox("hover")
```

에디터에서는 인스펙터의 `Theme Overrides` 섹션에 해당한다.

### Theme 리소스 (프로젝트 전체)

`Theme` 리소스를 만들어 루트 `Control`에 지정하면 모든 자식이 상속한다.

```gdscript
var theme := Theme.new()
theme.default_font = load("res://assets/fonts/main.ttf")
theme.default_font_size = 16

# 타입별 설정
theme.set_color("font_color", "Button", Color(0.9, 0.9, 0.9))
theme.set_font_size("font_size", "Button", 18)
theme.set_stylebox("normal", "Button", normal_box)
theme.set_stylebox("hover", "Button", hover_box)
theme.set_stylebox("pressed", "Button", pressed_box)
theme.set_constant("h_separation", "HBoxContainer", 12)

$UI.theme = theme
```

**프로젝트 기본 테마**: `Project Settings → GUI → Theme → Custom`에 지정하면
모든 씬에 자동 적용된다.

### StyleBox 종류

```gdscript
# 단색 + 둥근 모서리 + 테두리
var flat := StyleBoxFlat.new()
flat.bg_color = Color(0.12, 0.13, 0.16, 0.95)
flat.set_corner_radius_all(8)
flat.set_border_width_all(2)
flat.border_color = Color(0.3, 0.32, 0.4)
flat.set_content_margin_all(12)
flat.shadow_size = 6
flat.shadow_color = Color(0, 0, 0, 0.4)
flat.anti_aliasing = true

# 나인패치 텍스처
var tex := StyleBoxTexture.new()
tex.texture = load("res://assets/ui/panel.png")
tex.set_texture_margin_all(16)
tex.axis_stretch_horizontal = StyleBoxTexture.AXIS_STRETCH_MODE_TILE

# 선
var line := StyleBoxLine.new()
line.color = Color.WHITE
line.thickness = 2

# 빈 (여백만)
var empty := StyleBoxEmpty.new()
empty.set_content_margin_all(8)
```

### 타입 배리에이션

같은 `Button`이라도 "위험 버튼", "주요 버튼"처럼 변형이 필요할 때 쓴다.

```gdscript
# Theme에서 "DangerButton" 타입을 만들고 base type을 "Button"으로 지정
theme.add_type("DangerButton")
theme.set_type_variation("DangerButton", "Button")
theme.set_color("font_color", "DangerButton", Color.RED)

# 노드에 적용
delete_button.theme_type_variation = "DangerButton"
```

---

## 12. RichTextLabel과 BBCode

`Label`은 한 가지 서식만 쓴다. 문장 중간에 색·크기·아이콘이 섞이는 텍스트는
`RichTextLabel`을 쓴다. 채팅, 아이템 툴팁, 전투 로그, 퀘스트 설명이 여기 해당한다.

```gdscript
var log_label := RichTextLabel.new()
log_label.bbcode_enabled = true          # 이걸 켜야 태그가 해석된다
log_label.fit_content = true             # 내용 높이에 맞춰 자동 확장
log_label.scroll_following = true        # 새 줄이 추가되면 자동 스크롤
log_label.text = "[color=#ff6b6b]몹[/color]에게 [b]128[/b] 피해를 입혔다."
```

`bbcode_enabled`를 켜지 않으면 태그가 **글자 그대로 화면에 나온다.** 가장 흔한 실수다.

### 폰트 크기에 맞춰 자동으로 커지는 이미지 (4.7 신규)

4.7 이전에는 `[img=32]`처럼 이미지 크기를 픽셀로 직접 박아야 했다.
그래서 폰트 크기를 바꾸거나 접근성 설정으로 글자를 키우면 **아이콘만 그대로 남아**
텍스트와 어긋났다. 4.7부터 `em` 단위로 **폰트 크기에 상대적인 크기**를 줄 수 있다.

```
[font_size=40]골드: [img height=1em]res://ui/icons/gold.png[/img] 1,250[/font_size]
```

`1em` = 주변 폰트 크기와 같은 픽셀값이다. 위 예시에서 아이콘은 40px 높이로 그려진다.
`font_size`를 16으로 바꾸면 아이콘도 16px가 된다. **손댈 곳이 한 군데로 줄어든다.**

실측으로 확인한 동작(폰트 16pt 기준):

| BBCode | 이미지 실제 높이 |
|---|---|
| `[img height=1em]` | 16px (= 폰트 크기) |
| `[img height=2em]` | 32px (= 폰트 크기 × 2) |
| `[img height=0.75em]` | 12px |

### `[img]` 태그의 전체 문법

```
[img]{경로}[/img]
[img={폭}]{경로}[/img]
[img={폭}x{높이}]{경로}[/img]
[img {옵션들}]{경로}[/img]
```

| 옵션 | 값 | 의미 |
|---|---|---|
| `width` / `height` | 숫자 + 단위 | 목표 크기. 하나만 주면 비율 유지 |
| `color` | 색 이름 또는 `#RRGGBB` | 이미지 틴트(모듈레이트) |
| `region` | `x,y,폭,높이` (px) | 스프라이트시트에서 한 칸만 잘라 쓴다 |
| `pad` | `true` / `false` | 이미지가 지정 크기보다 작을 때 **확대 대신 여백**을 채운다 |
| `tooltip` | 문자열 | 마우스 오버 툴팁 |
| `align` | 정렬값 | 주변 텍스트 기준 정렬 |
| `alt` | 문자열 | 스크린 리더용 설명 |

**크기 단위 3종**

| 표기 | 기준 | 예 |
|---|---|---|
| 숫자만 | 픽셀 | `height=32` → 32px |
| `em` | **주변 폰트 크기** | `height=1em` → 글자 높이와 같음 |
| `%` | **Control의 폭** | `width=50%` → 라벨 폭의 절반 |

`%`는 폭에 대한 비율이라는 점에 주의한다. `height=50%`도 **Control의 폭**을 기준으로 한다.

### 실전 — 아이콘이 섞인 로그

```gdscript
const ICON_GOLD := "res://ui/icons/gold.png"
const ICON_EXP  := "res://ui/icons/exp.png"

func append_reward(gold: int, exp: int) -> void:
    # em 을 쓰면 유저가 글자 크기를 바꿔도 아이콘이 따라간다
    log_label.append_text(
        "보상: [img height=1em]%s[/img] %d  [img height=1em]%s[/img] %d\n"
        % [ICON_GOLD, gold, ICON_EXP, exp]
    )
```

`append_text()`는 BBCode를 해석하며 덧붙인다. 반면 `text +=`는 전체를 다시 파싱하므로
로그가 길어질수록 느려진다. **줄 단위로 쌓는 로그에는 `append_text()`를 쓴다.**

### 코드로 이미지를 넣을 때는 em을 못 쓴다

`em`과 `%`는 **BBCode 태그 전용**이다. 코드 API는 픽셀만 받는다.

```gdscript
# width/height 는 float 픽셀이다. "1em" 같은 문자열을 넣을 수 없다
log_label.add_image(preload("res://ui/icons/gold.png"), 0, 24)   # 높이 24px
```

`add_image(image, width, height, color, region, key, pad, tooltip, alt_text)`에서
`width`/`height`에 `0`을 주면 그 축은 원본 비율대로 계산된다.
폰트 크기에 맞추고 싶으면 직접 계산해서 넘긴다.

```gdscript
var font_size := log_label.get_theme_font_size("normal_font_size")
log_label.add_image(icon, 0, font_size)          # 1em 과 같은 결과
```

`key`를 지정해 두면 나중에 `update_image(key, ...)`로 그 이미지만 교체할 수 있다.
쿨다운 아이콘처럼 자주 바뀌는 것에 쓴다.

### 함정

- **`bbcode_enabled`를 켜지 않으면** 태그가 그대로 출력된다.
- **유저 입력을 그대로 넣지 않는다.** 채팅에 `[color=...]`를 쓰면 남이 내 화면 서식을
  조작한다. `String`을 `[lb]`/`[rb]`로 이스케이프하거나 `bbcode_enabled = false`인
  별도 라벨에 표시한다.
- **`text +=`로 로그를 쌓지 않는다.** 매번 전체 재파싱이라 줄이 늘수록 급격히 느려진다.
- 이미지 경로는 **임포트된 리소스**여야 한다. 임포트 전이면 로드 실패로 아무것도 안 나온다.

---

## 13. 3D 게임의 UI 구성

### 레이어 구조

```
Main (Node3D)
├─ Level (Node3D)                    ← 3D 월드
├─ Player (CharacterBody3D)
│  └─ CameraPivot/SpringArm3D/Camera3D
├─ HUDLayer (CanvasLayer, layer = 0)
│  └─ HUD (Control, FULL_RECT, MOUSE_FILTER_IGNORE)
│     ├─ Crosshair (TextureRect, CENTER)
│     ├─ HealthBar (ProgressBar)
│     └─ AmmoLabel (Label)
├─ MenuLayer (CanvasLayer, layer = 10)
│  └─ PauseMenu (Control, visible = false, PROCESS_MODE_WHEN_PAUSED)
└─ TransitionLayer (CanvasLayer, layer = 100)
   └─ FadeRect (ColorRect)
```

**`CanvasLayer`를 쓰는 이유**: 3D 카메라의 변환과 무관하게 화면 좌표에 UI를 고정한다.
`layer` 값이 클수록 위에 그려진다.

### 일시정지 메뉴

```gdscript
class_name PauseMenu
extends Control

func _ready() -> void:
    # 일시정지 중에도 동작해야 한다
    process_mode = Node.PROCESS_MODE_WHEN_PAUSED
    visible = false
    $Panel/VBox/ResumeButton.pressed.connect(_resume)
    $Panel/VBox/QuitButton.pressed.connect(_quit)

func _unhandled_input(event: InputEvent) -> void:
    if event.is_action_pressed("pause"):
        if visible:
            _resume()
        else:
            _pause()
        get_viewport().set_input_as_handled()

func _pause() -> void:
    get_tree().paused = true
    visible = true
    Input.mouse_mode = Input.MOUSE_MODE_VISIBLE
    $Panel/VBox/ResumeButton.grab_focus()      # 게임패드 대응

func _resume() -> void:
    get_tree().paused = false
    visible = false
    Input.mouse_mode = Input.MOUSE_MODE_CAPTURED

func _quit() -> void:
    get_tree().paused = false
    get_tree().change_scene_to_file("res://scenes/ui/main_menu.tscn")
```

### 화면 스케일 설정

```ini
[display]

window/size/viewport_width=1920
window/size/viewport_height=1080
window/stretch/mode="canvas_items"     # 이 프로젝트 설정
window/stretch/aspect="expand"
window/stretch/scale=1.0
window/stretch/scale_mode="fractional"
```

| stretch mode | 동작 |
|-------------|------|
| `disabled` | 스케일 없음. 창이 커지면 UI가 작아 보임 |
| `canvas_items` | UI를 비율에 맞춰 확대/축소. **일반 게임 권장** |
| `viewport` | 저해상도 렌더링 후 확대. 픽셀아트 전용 |

| aspect | 동작 |
|--------|------|
| `ignore` | 비율 무시, 늘어남 |
| `keep` | 비율 유지, 레터박스 |
| `keep_width` / `keep_height` | 한 축 고정 |
| `expand` | 비율 유지 + 남는 공간을 게임 영역으로 확장. **권장** |

`expand`는 다양한 화면 비율(모바일 세로/가로, 울트라와이드)에서 가장 자연스럽다.
다만 앵커를 제대로 설정해야 UI가 화면 밖으로 나가지 않는다.

### 모바일 세이프 에어리어

노치가 있는 기기에서 UI가 가려지지 않게 한다.

```gdscript
func _ready() -> void:
    _apply_safe_area()
    get_tree().root.size_changed.connect(_apply_safe_area)

func _apply_safe_area() -> void:
    var safe := DisplayServer.get_display_safe_area()
    var screen := DisplayServer.window_get_size()
    if screen.x == 0 or screen.y == 0:
        return
    var scale := Vector2(size) / Vector2(screen)
    $MarginContainer.add_theme_constant_override(
        "margin_left", int(safe.position.x * scale.x))
    $MarginContainer.add_theme_constant_override(
        "margin_top", int(safe.position.y * scale.y))
    $MarginContainer.add_theme_constant_override(
        "margin_right", int((screen.x - safe.end.x) * scale.x))
    $MarginContainer.add_theme_constant_override(
        "margin_bottom", int((screen.y - safe.end.y) * scale.y))
```

---

## 14. 3D 월드 스페이스 UI

### Sprite3D / Label3D (가장 저렴)

```gdscript
var label := Label3D.new()
label.text = "체력 100"
label.billboard = BaseMaterial3D.BILLBOARD_ENABLED      # 항상 카메라를 향함
label.no_depth_test = false
label.fixed_size = false                                 # true면 거리와 무관한 크기
label.pixel_size = 0.005
label.outline_size = 8
label.modulate = Color.WHITE
label.font_size = 48
add_child(label)
```

`Label3D`/`Sprite3D`는 3D 공간에 직접 그려지므로 별도 뷰포트가 필요 없다.
**데미지 숫자, 이름표에는 이것을 쓴다.**

### SubViewport + QuadMesh (인터랙티브 UI)

버튼이나 슬라이더 같은 실제 Control이 3D 공간에 필요할 때 쓴다.

```
WorldUI (Node3D)
├─ SubViewport (size 512x512, transparent_bg, UPDATE_ALWAYS)
│  └─ Control (실제 UI)
└─ MeshInstance3D (QuadMesh)
   └─ material: StandardMaterial3D
        albedo_texture = SubViewport의 ViewportTexture
        transparency = ALPHA
        shading_mode = UNSHADED
```

```gdscript
class_name WorldSpaceUI
extends Node3D

@onready var sub: SubViewport = $SubViewport
@onready var quad: MeshInstance3D = $MeshInstance3D
@onready var area: Area3D = $Area3D

func _ready() -> void:
    var mat := StandardMaterial3D.new()
    mat.albedo_texture = sub.get_texture()
    mat.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
    mat.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
    mat.cull_mode = BaseMaterial3D.CULL_DISABLED
    quad.material_override = mat

# 3D 레이캐스트 결과를 SubViewport의 2D 좌표로 변환해 입력 전달
func handle_ray_hit(world_pos: Vector3, pressed: bool) -> void:
    var local := quad.global_transform.affine_inverse() * world_pos
    var mesh_size := (quad.mesh as QuadMesh).size
    var uv := Vector2(
        (local.x / mesh_size.x) + 0.5,
        0.5 - (local.y / mesh_size.y)
    )
    var ev := InputEventMouseButton.new()
    ev.position = uv * Vector2(sub.size)
    ev.button_index = MOUSE_BUTTON_LEFT
    ev.pressed = pressed
    sub.push_input(ev)
```

**성능 주의**: `UPDATE_ALWAYS`인 SubViewport는 매 프레임 UI를 다시 그린다.
모바일에서는 값이 바뀔 때만 `UPDATE_ONCE`로 갱신하거나 해상도를 낮춘다.

---

## 15. 포커스와 게임패드 UI 내비게이션

```gdscript
# 포커스 부여
button.grab_focus()
button.release_focus()
if button.has_focus(): pass

# 포커스 모드
button.focus_mode = Control.FOCUS_ALL       # 클릭·키보드 모두
button.focus_mode = Control.FOCUS_CLICK
button.focus_mode = Control.FOCUS_NONE

# 이동 경로 지정 (자동 계산이 부정확할 때)
button_a.focus_neighbor_bottom = button_b.get_path()
button_b.focus_neighbor_top = button_a.get_path()
button_a.focus_next = button_b.get_path()      # Tab
button_a.focus_previous = button_c.get_path()

# 시그널
button.focus_entered.connect(_on_focus)
button.focus_exited.connect(_on_unfocus)
```

**메뉴를 열 때 반드시 첫 요소에 `grab_focus()`를 호출한다.**
포커스가 없으면 게임패드로 메뉴를 조작할 수 없다.

### 포커스 시각 표시

```gdscript
func _ready() -> void:
    for btn in get_tree().get_nodes_in_group("menu_buttons"):
        btn.focus_entered.connect(_on_button_focused.bind(btn))

func _on_button_focused(btn: Control) -> void:
    var tween := create_tween()
    tween.tween_property(btn, "scale", Vector2(1.05, 1.05), 0.1)
```

`Theme`의 `focus` StyleBox를 설정하면 자동으로 테두리가 표시된다.

---

## 16. 자주 하는 실수

| 실수 | 증상 | 해결 |
|------|------|------|
| HUD 배경이 `MOUSE_FILTER_STOP` | 게임이 마우스에 반응 안 함 | `MOUSE_FILTER_IGNORE` |
| 게임 입력을 `_input`에 작성 | UI 열려 있어도 입력됨 | `_unhandled_input` |
| `set_input_as_handled()` 누락 | 입력이 중복 처리됨 | 소비했으면 호출 |
| `relative` 사용 | 창 크기에 따라 감도 변함 | `screen_relative` |
| `keycode` 사용 | AZERTY에서 WASD가 다른 위치 | `physical_keycode` |
| 대각선 이동이 빠름 | 정규화 안 함 | `Input.get_vector()` |
| 일시정지 메뉴가 안 뜸 | `process_mode`가 PAUSABLE | `PROCESS_MODE_WHEN_PAUSED` |
| 메뉴 열어도 게임패드로 조작 불가 | 포커스 없음 | `grab_focus()` |
| 컨테이너 자식의 `position` 설정 | 무시됨 | `size_flags`, `custom_minimum_size` 사용 |
| SubViewport UI가 매 프레임 갱신 | 프레임 저하 | `UPDATE_WHEN_VISIBLE` 또는 수동 |
| 알트탭 후 마우스가 캡처된 채 | 다른 창 조작 불가 | `NOTIFICATION_APPLICATION_FOCUS_OUT` 처리 |
| 노치 기기에서 UI 잘림 | 세이프 에어리어 미적용 | `DisplayServer.get_display_safe_area()` |
| 게임패드 스틱 드리프트로 UI 전환 | 임계값 없음 | `axis_value` 0.5 이상만 인정 |
