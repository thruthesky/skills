# @tool 스크립트와 EditorPlugin

## 목차

1. [핵심 개념 — 에디터도 게임이다](#1-핵심-개념--에디터도-게임이다)
2. [@tool 스크립트](#2-tool-스크립트)
3. [EditorPlugin 기본 구조](#3-editorplugin-기본-구조)
4. [플러그인이 등록할 수 있는 것](#4-플러그인이-등록할-수-있는-것)
5. [에디터·프로젝트 설정 등록](#5-에디터프로젝트-설정-등록)
6. [EditorInterface API](#6-editorinterface-api)
7. [실전 도구 — 레벨 배치 헬퍼](#7-실전-도구--레벨-배치-헬퍼)
8. [실전 도구 — 임포트 후처리](#8-실전-도구--임포트-후처리)
9. [실전 도구 — 씬 일괄 처리](#9-실전-도구--씬-일괄-처리)
10. [에디터 기즈모](#10-에디터-기즈모)
11. [Undo/Redo](#11-undoredo)
12. [자주 하는 실수](#12-자주-하는-실수)

---

## 1. 핵심 개념 — 에디터도 게임이다

Godot 에디터는 **Godot 엔진으로 만들어진 애플리케이션**이다.
따라서 게임에서 쓰는 모든 API를 에디터 확장에도 그대로 쓸 수 있다.

```
Godot 엔진
 ├─ 에디터 (Godot으로 만든 앱)
 │   └─ EditorPlugin (내 확장)      ← @tool 스크립트로 동작
 └─ 게임 (내 프로젝트)
```

### @tool과 EditorPlugin의 차이

| | `@tool` 스크립트 | `EditorPlugin` |
|---|---|---|
| 실행 위치 | 노드에 붙어 에디터·게임 양쪽 | 에디터 전용 |
| 목적 | 씬 안에서 미리보기·자동 배치 | 에디터 UI·기능 확장 |
| 등록 | 스크립트 첫 줄에 `@tool` | `addons/*/plugin.cfg` + Plugins 활성화 |
| 게임 빌드 포함 | 포함됨 | 포함 안 됨 |

**언제 만드나**: 손으로 반복하는 작업이 있을 때. 오브젝트 배치, 임포트 설정 조정,
데이터 검증, 씬 일괄 수정 등이다. 세 번 이상 반복한다면 도구를 만들 시점이다.

---

## 2. @tool 스크립트

스크립트 첫 줄에 `@tool`을 붙이면 **에디터에서도 코드가 실행된다.**

```gdscript
@tool
class_name SpawnRing
extends Node3D

@export var count: int = 8:
    set(value):
        count = maxi(1, value)
        _rebuild()

@export var radius: float = 5.0:
    set(value):
        radius = maxf(0.1, value)
        _rebuild()

@export var marker_scene: PackedScene:
    set(value):
        marker_scene = value
        _rebuild()

func _ready() -> void:
    _rebuild()

func _rebuild() -> void:
    if not is_inside_tree():
        return
    for child in get_children():
        child.queue_free()
    if marker_scene == null:
        return
    for i in count:
        var angle := TAU * i / count
        var node := marker_scene.instantiate() as Node3D
        add_child(node)
        node.position = Vector3(cos(angle), 0.0, sin(angle)) * radius
        # 에디터에서 만든 노드는 owner를 지정해야 씬에 저장된다
        if Engine.is_editor_hint():
            node.owner = get_tree().edited_scene_root
```

### 절대 규칙

**`Engine.is_editor_hint()`로 분기한다.**

```gdscript
@tool
extends Node3D

func _process(delta: float) -> void:
    if Engine.is_editor_hint():
        _editor_preview()      # 에디터에서만
        return
    _game_logic(delta)         # 게임에서만
```

이 분기를 빠뜨리면 게임 로직이 에디터에서 실행되어 씬을 오염시키거나
에디터를 멈추게 한다. 특히 다음이 위험하다.

- 무한 루프·긴 계산 → 에디터가 응답 없음
- `queue_free()`로 씬의 노드 삭제 → 작업 내용 소실
- 파일 쓰기 → 프로젝트 파일 손상
- 물리·입력 처리 → 의미 없는 부하

### 에디터에서 만든 노드는 owner를 지정한다

```gdscript
var node := Node3D.new()
add_child(node)
if Engine.is_editor_hint():
    node.owner = get_tree().edited_scene_root
```

`owner`가 없으면 `.tscn`에 저장되지 않는다. 에디터를 껐다 켜면 사라진다.

### 인스펙터에서 값이 바뀔 때 반응하기

setter를 쓰는 것이 가장 간단하다. 더 복잡한 경우 `_validate_property`,
`_get_property_list`, `_property_can_revert`를 쓴다.

```gdscript
@tool
extends Node3D

@export_enum("구", "박스", "실린더") var shape_type: int = 0:
    set(value):
        shape_type = value
        notify_property_list_changed()      # 인스펙터 갱신
        _rebuild()

@export var sphere_radius: float = 1.0
@export var box_size: Vector3 = Vector3.ONE

func _validate_property(property: Dictionary) -> void:
    # 선택한 타입에 맞지 않는 프로퍼티를 인스펙터에서 숨긴다
    if property.name == "sphere_radius" and shape_type != 0:
        property.usage = PROPERTY_USAGE_NO_EDITOR
    elif property.name == "box_size" and shape_type != 1:
        property.usage = PROPERTY_USAGE_NO_EDITOR
```

### 설정 경고

에디터의 씬 트리에 경고 아이콘을 띄운다.

```gdscript
@tool
extends Node3D

@export var target: Node3D:
    set(value):
        target = value
        update_configuration_warnings()

func _get_configuration_warnings() -> PackedStringArray:
    var warnings: PackedStringArray = []
    if target == null:
        warnings.append("target을 지정해야 동작합니다.")
    if get_child_count() == 0:
        warnings.append("자식 노드가 필요합니다.")
    return warnings
```

사용자가 설정을 빠뜨렸을 때 실행 전에 알려주므로,
팀에서 쓰는 노드에는 반드시 넣는다.

### @tool 스크립트 수정 후

**에디터가 이미 로드한 옛 버전을 계속 쓴다.** 다음 중 하나로 재로드한다.

- 스크립트 에디터에서 저장 → 대체로 자동 재로드
- `Project → Reload Current Project`
- 플러그인이면 `Project Settings → Plugins`에서 껐다 켜기

---

## 3. EditorPlugin 기본 구조

### 디렉터리

```
res://addons/my_tool/
├── plugin.cfg          (필수)
├── plugin.gd           (필수 — EditorPlugin 상속)
├── panel.tscn          (선택 — UI)
└── icons/
```

### plugin.cfg

```ini
[plugin]

name="레벨 도구"
description="레벨 배치를 자동화하는 도구"
author="JaeHo Song"
version="1.0.0"
script="plugin.gd"
```

### plugin.gd

```gdscript
@tool
extends EditorPlugin

const PANEL_SCENE := preload("res://addons/my_tool/panel.tscn")
const SETTING_PREFIX := "my_tool/"

var _panel: Control

func _enter_tree() -> void:
    # 플러그인이 활성화될 때 호출된다
    _panel = PANEL_SCENE.instantiate()
    add_control_to_dock(EditorPlugin.DOCK_SLOT_RIGHT_UL, _panel)
    _setup_settings()

func _exit_tree() -> void:
    # 비활성화될 때 — 등록한 것을 전부 되돌린다
    if _panel:
        remove_control_from_docks(_panel)
        _panel.queue_free()
        _panel = null

func _get_plugin_name() -> String:
    return "레벨 도구"

func _has_main_screen() -> bool:
    return false        # true면 2D/3D/Script와 나란한 메인 화면이 된다

func _setup_settings() -> void:
    if not ProjectSettings.has_setting(SETTING_PREFIX + "grid_size"):
        ProjectSettings.set_setting(SETTING_PREFIX + "grid_size", 1.0)
    ProjectSettings.set_initial_value(SETTING_PREFIX + "grid_size", 1.0)
    ProjectSettings.add_property_info({
        "name": SETTING_PREFIX + "grid_size",
        "type": TYPE_FLOAT,
        "hint": PROPERTY_HINT_RANGE,
        "hint_string": "0.1,10.0,0.1",
    })
```

**`_exit_tree()`에서 정리를 빠뜨리면 안 된다.** 플러그인을 껐다 켤 때마다
UI가 중복 생성되거나 메모리가 샌다.

### 생명주기 콜백

| 콜백 | 시점 |
|------|------|
| `_enter_tree()` | 플러그인 활성화 |
| `_exit_tree()` | 비활성화 |
| `_ready()` | 에디터 트리에 진입 후 |
| `_enable_plugin()` / `_disable_plugin()` | 사용자가 체크박스를 토글 (오토로드 등록에 사용) |
| `_process(delta)` | 에디터 매 프레임 (`set_process(true)` 필요) |
| `_handles(object)` | 이 오브젝트를 이 플러그인이 다루는가 |
| `_edit(object)` | `_handles`가 true인 오브젝트가 선택됨 |
| `_make_visible(visible)` | 플러그인 UI 표시 여부 |
| `_forward_3d_gui_input(camera, event)` | 3D 뷰포트 입력 가로채기 |
| `_forward_3d_draw_over_viewport(overlay)` | 3D 뷰포트 위에 그리기 |
| `_save_external_data()` | 에디터가 저장할 때 |
| `_apply_changes()` | 게임 실행 직전 |

---

## 4. 플러그인이 등록할 수 있는 것

```gdscript
func _enter_tree() -> void:
    # 커스텀 노드 타입 (씬 트리의 Add Node 목록에 나타남)
    add_custom_type("HealthComponent", "Node",
        preload("res://scenes/components/health_component.gd"),
        preload("res://addons/my_tool/icons/health.svg"))

    # 도크 패널
    add_control_to_dock(EditorPlugin.DOCK_SLOT_RIGHT_UL, _panel)

    # 하단 패널 (Output, Debugger와 나란히)
    _bottom_button = add_control_to_bottom_panel(_bottom_panel, "레벨 도구")

    # 상단 컨테이너 (2D/3D 뷰포트 툴바)
    add_control_to_container(
        EditorPlugin.CONTAINER_SPATIAL_EDITOR_MENU, _toolbar)

    # 도구 메뉴 항목 (Project → Tools)
    add_tool_menu_item("모든 레벨 검증", _validate_all_levels)
    add_tool_submenu_item("레벨 도구", _submenu)

    # 오토로드 (사용자 프로젝트에 싱글턴 추가)
    add_autoload_singleton("MyToolRuntime",
        "res://addons/my_tool/runtime.gd")

    # 임포트 플러그인
    add_import_plugin(MyImporter.new())

    # 씬 임포트 후처리
    add_scene_post_import_plugin(MyPostImport.new())

    # 인스펙터 커스텀 UI
    add_inspector_plugin(MyInspectorPlugin.new())

    # 3D 기즈모
    add_node_3d_gizmo_plugin(MyGizmoPlugin.new())

    # 에디터 디버거 플러그인 (실행 중인 게임과 통신)
    add_debugger_plugin(MyDebuggerPlugin.new())

    # 내보내기 플러그인
    add_export_plugin(MyExportPlugin.new())

    # 리소스 변환 플러그인
    add_resource_conversion_plugin(MyConverter.new())

func _exit_tree() -> void:
    remove_custom_type("HealthComponent")
    remove_control_from_docks(_panel)
    remove_control_from_bottom_panel(_bottom_panel)
    remove_control_from_container(
        EditorPlugin.CONTAINER_SPATIAL_EDITOR_MENU, _toolbar)
    remove_tool_menu_item("모든 레벨 검증")
    remove_autoload_singleton("MyToolRuntime")
    # ... 등록한 모든 것을 대칭으로 제거
```

### 도크 슬롯

```
DOCK_SLOT_LEFT_UL / LEFT_BL / LEFT_UR / LEFT_BR
DOCK_SLOT_RIGHT_UL / RIGHT_BL / RIGHT_UR / RIGHT_BR
```

`UL`=좌상, `BL`=좌하, `UR`=우상, `BR`=우하.
씬 트리는 `RIGHT_UL`, 인스펙터는 `RIGHT_BL`에 있다.

### 컨테이너 위치

```
CONTAINER_TOOLBAR
CONTAINER_SPATIAL_EDITOR_MENU          3D 뷰포트 상단 메뉴
CONTAINER_SPATIAL_EDITOR_SIDE_LEFT/RIGHT
CONTAINER_SPATIAL_EDITOR_BOTTOM
CONTAINER_CANVAS_EDITOR_MENU           2D 뷰포트
CONTAINER_INSPECTOR_BOTTOM
CONTAINER_PROJECT_SETTING_TAB_LEFT/RIGHT
```

### 오토로드 등록의 정석

`_enter_tree`가 아니라 `_enable_plugin`에서 한다.
그래야 플러그인 활성화/비활성화에 정확히 대응한다.

```gdscript
func _enable_plugin() -> void:
    add_autoload_singleton("MyToolRuntime", "res://addons/my_tool/runtime.gd")

func _disable_plugin() -> void:
    remove_autoload_singleton("MyToolRuntime")
```

---

## 5. 에디터·프로젝트 설정 등록

플러그인이 자기 설정을 등록하고 인스펙터에 예쁘게 표시하는 표준 패턴이다.

```gdscript
@tool
extends EditorPlugin

const PREFIX := "MyTool/"

var editor_settings_defaults := {
    PREFIX + "context_dir": "res://addons/my_tool/context",
    PREFIX + "executable": "mytool",
}

var project_settings_defaults := {
    PREFIX + "grid_size": 1.0,
    PREFIX + "auto_snap": true,
    PREFIX + "mode": "balanced",
}

# 더 이상 쓰지 않는 설정 — 정리 대상
const DEPRECATED_SETTINGS: PackedStringArray = [
    PREFIX + "old_option",
]

func _enter_tree() -> void:
    _setup_settings()
    # 사용자가 에디터 설정을 바꾸면 다시 적용
    EditorInterface.get_editor_settings().settings_changed.connect(_setup_settings)

func _setup_settings() -> void:
    var es := EditorInterface.get_editor_settings()

    # 에디터 설정 — 사용자별 (경로, 실행 파일 등)
    for key in editor_settings_defaults:
        if not es.has_setting(key):
            es.set_setting(key, editor_settings_defaults[key])

    # 프로젝트 설정 — 팀 공유 (동작 옵션)
    for key in project_settings_defaults:
        if not ProjectSettings.has_setting(key):
            ProjectSettings.set_setting(key, project_settings_defaults[key])

    # 폐기된 설정 제거
    for key in DEPRECATED_SETTINGS:
        if ProjectSettings.has_setting(key):
            ProjectSettings.set_setting(key, null)

    # 인스펙터 표시 방식 지정
    es.add_property_info({
        "name": PREFIX + "context_dir",
        "type": TYPE_STRING,
        "hint": PROPERTY_HINT_DIR,
        "hint_string": "도구가 사용할 컨텍스트 폴더",
    })
    es.add_property_info({
        "name": PREFIX + "executable",
        "type": TYPE_STRING,
        "hint": PROPERTY_HINT_PLACEHOLDER_TEXT,
        "hint_string": "mytool",
    })
    ProjectSettings.add_property_info({
        "name": PREFIX + "grid_size",
        "type": TYPE_FLOAT,
        "hint": PROPERTY_HINT_RANGE,
        "hint_string": "0.1,10.0,0.1",
    })
    ProjectSettings.add_property_info({
        "name": PREFIX + "mode",
        "type": TYPE_STRING,
        "hint": PROPERTY_HINT_ENUM,
        "hint_string": "fast,balanced,quality",
    })
```

### 에디터 설정 vs 프로젝트 설정

| | 에디터 설정 | 프로젝트 설정 |
|---|---|---|
| 저장 위치 | 사용자 홈 | `project.godot` |
| 공유 | 개인 | 팀 전체 |
| 용도 | 실행 파일 경로, 개인 취향 | 도구 동작 옵션 |

**절대 경로나 개인 환경에 의존하는 값은 반드시 에디터 설정에 넣는다.**
프로젝트 설정에 넣으면 다른 팀원의 환경에서 깨진다.

---

## 6. EditorInterface API

Godot 4.2부터 `EditorInterface`는 싱글턴이라 어디서든 접근할 수 있다.

```gdscript
# 씬
var root := EditorInterface.get_edited_scene_root()
EditorInterface.open_scene_from_path("res://scenes/level_01.tscn")
EditorInterface.reload_scene_from_path("res://scenes/level_01.tscn")
EditorInterface.save_scene()
EditorInterface.save_all_scenes()
var open_scenes := EditorInterface.get_open_scenes()

# 선택
var selection := EditorInterface.get_selection()
var selected := selection.get_selected_nodes()
selection.clear()
selection.add_node(some_node)
selection.selection_changed.connect(_on_selection_changed)

# 인스펙터
EditorInterface.inspect_object(some_resource)
EditorInterface.edit_node(some_node)
EditorInterface.edit_resource(some_resource)

# 파일 시스템
var fs := EditorInterface.get_resource_filesystem()
fs.scan()                       # 전체 스캔
fs.scan_sources()               # 소스만
fs.update_file(path)
fs.reimport_files(PackedStringArray([path]))
fs.filesystem_changed.connect(_on_fs_changed)

# 리소스 미리보기
var previewer := EditorInterface.get_resource_previewer()
previewer.queue_resource_preview(path, self, "_on_preview_ready", null)

# 실행 제어
EditorInterface.play_main_scene()
EditorInterface.play_current_scene()
EditorInterface.play_custom_scene("res://scenes/test.tscn")
EditorInterface.stop_playing_scene()
var playing := EditorInterface.is_playing_scene()

# UI 접근
var base := EditorInterface.get_base_control()      # 테마·팝업 부모로 사용
var script_editor := EditorInterface.get_script_editor()
var current_script := script_editor.get_current_script()
var code_edit := script_editor.get_current_editor().get_base_editor()  # CodeEdit

# 설정
var es := EditorInterface.get_editor_settings()
var scale := EditorInterface.get_editor_scale()     # HiDPI 대응에 필수

# 커맨드 팔레트
EditorInterface.get_command_palette().add_command(
    "레벨 검증", "my_tool/validate", _validate)
```

### 스크립트 에디터 접근

GodexCLI 같은 도구가 쓰는 패턴이다. 현재 열린 스크립트의 `CodeEdit`를 얻는다.

```gdscript
func get_current_code_editor() -> CodeEdit:
    var script_editor := EditorInterface.get_script_editor()
    var base := script_editor.get_current_editor()
    if base == null:
        return null
    return base.get_base_editor()

func _process(_delta: float) -> void:
    var editor := get_current_code_editor()
    if editor == null:
        return
    var line := editor.get_caret_line()
    if line < 0 or line >= editor.get_line_count():
        return
    var text := editor.get_line(line).strip_edges()
    # ... 마커 감지 등
```

### HiDPI 대응

```gdscript
var scale := EditorInterface.get_editor_scale()
button.custom_minimum_size = Vector2(120, 32) * scale
```

**이 스케일을 적용하지 않으면 고해상도 디스플레이에서 UI가 아주 작게 보인다.**

---

## 7. 실전 도구 — 레벨 배치 헬퍼

3D 뷰포트에서 클릭한 지점에 오브젝트를 배치하는 플러그인이다.

```gdscript
# res://addons/level_tool/plugin.gd
@tool
extends EditorPlugin

var _toolbar: HBoxContainer
var _scene_option: OptionButton
var _active: bool = false
var _scenes: Array[PackedScene] = []

func _enter_tree() -> void:
    _build_toolbar()
    add_control_to_container(
        EditorPlugin.CONTAINER_SPATIAL_EDITOR_MENU, _toolbar)

func _exit_tree() -> void:
    remove_control_from_container(
        EditorPlugin.CONTAINER_SPATIAL_EDITOR_MENU, _toolbar)
    if _toolbar:
        _toolbar.queue_free()
        _toolbar = null

func _build_toolbar() -> void:
    var scale := EditorInterface.get_editor_scale()
    _toolbar = HBoxContainer.new()

    var toggle := CheckButton.new()
    toggle.text = "배치"
    toggle.toggled.connect(func(on: bool) -> void: _active = on)
    _toolbar.add_child(toggle)

    _scene_option = OptionButton.new()
    _scene_option.custom_minimum_size.x = 160 * scale
    _toolbar.add_child(_scene_option)
    _load_scene_list()

func _load_scene_list() -> void:
    _scenes.clear()
    _scene_option.clear()
    var dir := DirAccess.open("res://scenes/props")
    if dir == null:
        return
    for file in dir.get_files():
        if not file.ends_with(".tscn"):
            continue
        var scene := load("res://scenes/props/".path_join(file)) as PackedScene
        if scene:
            _scenes.append(scene)
            _scene_option.add_item(file.get_basename())

# 3D 뷰포트 입력을 가로챈다
func _forward_3d_gui_input(camera: Camera3D, event: InputEvent) -> int:
    if not _active:
        return EditorPlugin.AFTER_GUI_INPUT_PASS
    if not (event is InputEventMouseButton):
        return EditorPlugin.AFTER_GUI_INPUT_PASS

    var mb := event as InputEventMouseButton
    if mb.button_index != MOUSE_BUTTON_LEFT or not mb.pressed:
        return EditorPlugin.AFTER_GUI_INPUT_PASS

    var hit := _raycast_scene(camera, mb.position)
    if hit.is_empty():
        return EditorPlugin.AFTER_GUI_INPUT_PASS

    _place_at(hit.position, hit.normal)
    return EditorPlugin.AFTER_GUI_INPUT_STOP      # 입력 소비

func _raycast_scene(camera: Camera3D, mouse_pos: Vector2) -> Dictionary:
    var root := EditorInterface.get_edited_scene_root()
    if root == null or not root.is_inside_tree():
        return {}
    var from := camera.project_ray_origin(mouse_pos)
    var to := from + camera.project_ray_normal(mouse_pos) * 1000.0
    var space := root.get_world_3d().direct_space_state
    var query := PhysicsRayQueryParameters3D.create(from, to)
    return space.intersect_ray(query)

func _place_at(pos: Vector3, normal: Vector3) -> void:
    var idx := _scene_option.selected
    if idx < 0 or idx >= _scenes.size():
        return
    var root := EditorInterface.get_edited_scene_root()
    if root == null:
        return

    var node := _scenes[idx].instantiate() as Node3D
    var grid: float = ProjectSettings.get_setting("level_tool/grid_size", 1.0)

    # Undo/Redo에 등록해야 Ctrl+Z로 되돌릴 수 있다
    var undo := get_undo_redo()
    undo.create_action("오브젝트 배치")
    undo.add_do_method(root, "add_child", node)
    undo.add_do_method(node, "set_owner", root)
    undo.add_do_property(node, "global_position", pos.snapped(Vector3.ONE * grid))
    undo.add_do_reference(node)
    undo.add_undo_method(root, "remove_child", node)
    undo.commit_action()
```

### `_forward_3d_gui_input` 반환값

| 값 | 의미 |
|----|------|
| `AFTER_GUI_INPUT_PASS` | 에디터가 계속 처리 |
| `AFTER_GUI_INPUT_STOP` | 입력 소비 (에디터가 처리 안 함) |
| `AFTER_GUI_INPUT_CUSTOM` | 커스텀 처리 |

---

## 8. 실전 도구 — 임포트 후처리

3D 모델을 임포트할 때마다 손으로 하던 설정을 자동화한다.

```gdscript
# res://tools/character_post_import.gd
@tool
extends EditorScenePostImport

func _post_import(scene: Node) -> Object:
    _setup(scene)
    return scene

func _setup(node: Node) -> void:
    if node is MeshInstance3D:
        var mi := node as MeshInstance3D
        mi.gi_mode = GeometryInstance3D.GI_MODE_DYNAMIC
        mi.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_ON
        mi.lod_bias = 1.0
        # 이름 규칙으로 예외 처리
        if mi.name.begins_with("NoShadow_"):
            mi.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF

    elif node is AnimationPlayer:
        var ap := node as AnimationPlayer
        # 캐릭터 애니메이션은 물리 프레임에 맞춰야 발 미끄러짐이 줄어든다
        ap.callback_mode_process = \
            AnimationMixer.ANIMATION_CALLBACK_MODE_PROCESS_PHYSICS
        for anim_name in ap.get_animation_list():
            var anim := ap.get_animation(anim_name)
            if anim_name in ["idle", "walk", "run"] \
                    or anim_name.begins_with("loop_"):
                anim.loop_mode = Animation.LOOP_LINEAR

    elif node is StaticBody3D:
        var sb := node as StaticBody3D
        sb.collision_layer = 1      # World
        sb.collision_mask = 0       # 능동 스캔 불필요

    for child in node.get_children():
        _setup(child)
```

임포트 대상 파일 선택 → Import 탭 → `Import Script`에 이 파일을 지정 → Reimport.

### 임포트 옵션을 추가하는 플러그인

```gdscript
# res://addons/my_tool/post_import_plugin.gd
@tool
extends EditorScenePostImportPlugin

func _get_import_options(path: String) -> void:
    add_import_option_advanced(
        TYPE_BOOL, "custom/auto_collision", false)
    add_import_option_advanced(
        TYPE_FLOAT, "custom/lod_bias", 1.0,
        PROPERTY_HINT_RANGE, "0.1,4.0,0.1")

func _post_process(scene: Node) -> void:
    if get_option_value("custom/auto_collision"):
        _generate_collisions(scene)
```

```gdscript
# plugin.gd에서 등록
var _post_import: EditorScenePostImportPlugin

func _enter_tree() -> void:
    _post_import = preload("res://addons/my_tool/post_import_plugin.gd").new()
    add_scene_post_import_plugin(_post_import)

func _exit_tree() -> void:
    remove_scene_post_import_plugin(_post_import)
```

---

## 9. 실전 도구 — 씬 일괄 처리

프로젝트의 모든 씬을 검사하거나 수정한다. `--headless`로도 실행할 수 있다.

```gdscript
# res://tools/validate_scenes.gd
@tool
extends SceneTree

func _initialize() -> void:
    var problems := 0
    problems += _scan("res://scenes")
    if problems > 0:
        print("문제 %d건 발견" % problems)
        quit(1)
    else:
        print("모든 씬 정상")
        quit(0)

func _scan(dir_path: String) -> int:
    var count := 0
    var dir := DirAccess.open(dir_path)
    if dir == null:
        push_error("폴더 열기 실패: %s" % dir_path)
        return 0

    for file in dir.get_files():
        if not file.ends_with(".tscn"):
            continue
        var path := dir_path.path_join(file)
        var packed := load(path) as PackedScene
        if packed == null:
            print("  ✗ 로드 실패: %s" % path)
            count += 1
            continue
        var root := packed.instantiate()
        count += _validate(root, path)
        root.free()

    for sub in dir.get_directories():
        count += _scan(dir_path.path_join(sub))
    return count

func _validate(node: Node, scene_path: String) -> int:
    var count := 0

    # 콜리전 셰이프가 비어 있는지
    if node is CollisionShape3D and (node as CollisionShape3D).shape == null:
        print("  ✗ %s: %s 의 shape가 비어 있음" % [scene_path, node.name])
        count += 1

    # 대용량 텍스처
    if node is MeshInstance3D:
        var mi := node as MeshInstance3D
        var mat := mi.get_active_material(0)
        if mat is StandardMaterial3D:
            var tex := (mat as StandardMaterial3D).albedo_texture
            if tex and (tex.get_width() > 2048 or tex.get_height() > 2048):
                print("  ! %s: %s 의 텍스처가 %dx%d (모바일에 과함)"
                    % [scene_path, node.name, tex.get_width(), tex.get_height()])
                count += 1

    # 설정 경고
    var warnings := node.get_configuration_warnings()
    for w in warnings:
        print("  ! %s: %s — %s" % [scene_path, node.name, w])
        count += 1

    for child in node.get_children():
        count += _validate(child, scene_path)
    return count
```

```bash
godot --headless --path . --script res://tools/validate_scenes.gd
echo "종료코드: $?"
```

**`SceneTree`를 상속하고 `_initialize()`에서 작업한 뒤 `quit(코드)`를 호출한다.**
종료 코드로 CI에서 실패를 감지할 수 있다.

---

## 10. 에디터 기즈모

커스텀 노드를 3D 뷰포트에 시각화한다.

```gdscript
# res://addons/my_tool/spawn_gizmo.gd
@tool
extends EditorNode3DGizmoPlugin

func _init() -> void:
    create_material("lines", Color(0.2, 0.9, 0.4))
    create_handle_material("handles")

func _get_gizmo_name() -> String:
    return "SpawnRing"

func _has_gizmo(node: Node3D) -> bool:
    return node is SpawnRing

func _redraw(gizmo: EditorNode3DGizmo) -> void:
    gizmo.clear()
    var node := gizmo.get_node_3d() as SpawnRing
    if node == null:
        return

    var lines := PackedVector3Array()
    var segments := 48
    for i in segments:
        var a := TAU * i / segments
        var b := TAU * (i + 1) / segments
        lines.append(Vector3(cos(a), 0, sin(a)) * node.radius)
        lines.append(Vector3(cos(b), 0, sin(b)) * node.radius)

    gizmo.add_lines(lines, get_material("lines", gizmo), false)

    # 반지름 조절 핸들
    var handles := PackedVector3Array([Vector3(node.radius, 0, 0)])
    gizmo.add_handles(handles, get_material("handles", gizmo), [])

func _get_handle_name(gizmo: EditorNode3DGizmo, id: int,
                      secondary: bool) -> String:
    return "반지름"

func _get_handle_value(gizmo: EditorNode3DGizmo, id: int,
                       secondary: bool) -> Variant:
    return (gizmo.get_node_3d() as SpawnRing).radius

func _set_handle(gizmo: EditorNode3DGizmo, id: int, secondary: bool,
                 camera: Camera3D, point: Vector2) -> void:
    var node := gizmo.get_node_3d() as SpawnRing
    var gt := node.global_transform
    var ray_from := camera.project_ray_origin(point)
    var ray_dir := camera.project_ray_normal(point)
    var plane := Plane(gt.basis.y, gt.origin)
    var hit = plane.intersects_ray(ray_from, ray_dir)
    if hit == null:
        return
    node.radius = maxf(0.1, gt.origin.distance_to(hit))

func _commit_handle(gizmo: EditorNode3DGizmo, id: int, secondary: bool,
                    restore: Variant, cancel: bool) -> void:
    var node := gizmo.get_node_3d() as SpawnRing
    if cancel:
        node.radius = restore
        return
    var undo := EditorInterface.get_editor_undo_redo()
    undo.create_action("반지름 변경")
    undo.add_do_property(node, "radius", node.radius)
    undo.add_undo_property(node, "radius", restore)
    undo.commit_action()
```

```gdscript
# plugin.gd에서 등록
var _gizmo: EditorNode3DGizmoPlugin

func _enter_tree() -> void:
    _gizmo = preload("res://addons/my_tool/spawn_gizmo.gd").new()
    add_node_3d_gizmo_plugin(_gizmo)

func _exit_tree() -> void:
    remove_node_3d_gizmo_plugin(_gizmo)
```

---

## 11. Undo/Redo

**에디터에서 씬을 수정하는 모든 작업은 Undo/Redo에 등록한다.**
그렇지 않으면 사용자가 Ctrl+Z로 되돌릴 수 없고, 실수로 작업을 잃는다.

```gdscript
var undo := get_undo_redo()          # EditorPlugin 안에서
# 또는
var undo := EditorInterface.get_editor_undo_redo()

undo.create_action("액션 이름 (Undo 메뉴에 표시)")

# 프로퍼티 변경
undo.add_do_property(node, "position", new_position)
undo.add_undo_property(node, "position", node.position)

# 메서드 호출
undo.add_do_method(parent, "add_child", new_node)
undo.add_undo_method(parent, "remove_child", new_node)

# 새로 만든 객체는 참조를 등록해야 Undo 중 해제되지 않는다
undo.add_do_reference(new_node)

undo.commit_action()
```

### 순서 규칙

- `add_do_*`는 **실행할 순서대로**, `add_undo_*`는 **되돌릴 순서대로** 넣는다.
- 노드를 추가할 때는 `add_child` → `set_owner` 순서다.
- `commit_action()`이 호출되면 do 동작이 즉시 실행된다.
  실행을 미루려면 `commit_action(false)`.

```gdscript
# 여러 노드 일괄 수정
undo.create_action("선택 노드 정렬")
for node in EditorInterface.get_selection().get_selected_nodes():
    if node is Node3D:
        var n := node as Node3D
        undo.add_do_property(n, "position", n.position.snapped(Vector3.ONE))
        undo.add_undo_property(n, "position", n.position)
undo.commit_action()
```

---

## 12. 자주 하는 실수

| 실수 | 결과 | 해결 |
|------|------|------|
| `@tool` 스크립트에 `Engine.is_editor_hint()` 분기 없음 | 에디터에서 게임 로직 실행, 씬 오염 | 반드시 분기 |
| 에디터에서 만든 노드에 `owner` 미지정 | 씬에 저장 안 됨 | `node.owner = get_tree().edited_scene_root` |
| `_exit_tree()`에서 정리 누락 | UI 중복, 메모리 누수 | 등록한 모든 것을 대칭 제거 |
| Undo/Redo 미등록 | Ctrl+Z 안 됨, 작업 손실 | `create_action` ~ `commit_action` |
| `add_do_reference` 누락 | Undo 중 노드가 해제됨 | 새 객체는 참조 등록 |
| `EditorInterface`를 게임 코드에서 사용 | 빌드 실패 | `Engine.is_editor_hint()` 분기 |
| 에디터 API 반환값을 타입 캐스트 없이 사용 | 조용한 실패 | 명시적 타입 선언 |
| `get_editor_scale()` 미적용 | HiDPI에서 UI가 작음 | 크기에 스케일 곱하기 |
| 절대 경로를 프로젝트 설정에 저장 | 팀원 환경에서 깨짐 | 에디터 설정에 저장 |
| `@tool` 수정 후 재로드 안 함 | 옛 코드 동작 | 플러그인 껐다 켜기 |
| `_enter_tree`에서 오토로드 등록 | 토글 동작 불일치 | `_enable_plugin` 사용 |
| 에디터에서 무거운 `_process` | 에디터 응답 없음 | `set_process(false)` 기본, 필요할 때만 |
| `_forward_3d_gui_input`에서 항상 `STOP` | 에디터 조작 불가 | 처리한 입력만 `STOP` |
