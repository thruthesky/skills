---
name: godot
description: 최신 Godot 으로 3D 게임을 개발할 때 따라야 할 개발 규범과 검증 도구를 제공하며, **Godot 을 배우는 학습 자료이기도 합니다** — 노드·씬·인스턴싱·리소스·생명주기·에디터 사용법 같은 엔진 기본 개념을 설명합니다. GDScript, 노드·씬·.tscn, Node3D 좌표계, Jolt Physics, CharacterBody3D, 머티리얼·라이팅·셰이더, AnimationTree, 내비게이션, 입력·UI, glTF 임포트, 오디오, 멀티플레이어, 성능 최적화, project.godot 포맷, LSP 정적 검증, EditorPlugin, Android·iOS·macOS·Windows 빌드를 다룹니다. 다음 상황에서 반드시 사용하세요 - (1) GDScript 작성·수정(작성 후 LSP 진단 필수), (2) 씬·노드·.tscn 편집, (3) 캐릭터 이동·충돌·물리, (4) 머티리얼·조명·셰이더, (5) 애니메이션 블렌딩, (6) 길찾기·적 AI, (7) 성능 최적화, (8) 테스트 빌드·설치·실행·릴리즈 빌드(export template·APK·AAB·adb·Xcode·서명·공증), (9) project.godot 설정 변경, (10) 최신 버전 신기능·마이그레이션·엔진 업그레이드, (11) 에디터 도구·플러그인, (12) 에디터 없이 터미널만으로 작업하거나 실기기(아이폰·안드로이드)에 설치·실행할 때, (13) 맵·레벨을 만들거나 블록아웃·CSG·GridMap 으로 맵 구조를 짤 때, (14) Godot 용어의 뜻을 확인할 때, (15) Asset Store 에서 애드온·에셋을 받거나 플러그인을 켜고 끌 때, (16) Godot 기본 개념·사용법을 배우거나 설명할 때(노드가 뭔지, 씬이 뭔지, 인스턴싱이 뭔지, 에디터 어디를 누르는지). **(17) HUD·메뉴·버튼·인벤토리 같은 화면 UI 를 만들거나 디자인할 때(체력바, 스킬 버튼, 메인 메뉴, 일시정지, 설정 화면, Theme 로 디자인 통일, 화면을 눌렀는데 캐릭터가 안 움직이는 문제).** **🛑 성능·조명·저사양 관련 질문이면 references/performance-mobile.md §0(최소 지원 사양 3GB RAM Android)을 먼저 읽으세요.** 키워드 - 저사양 안드로이드, 3GB RAM, 최소 지원 사양, 모바일 MMORPG, Galaxy A12, SM-A125N, PowerVR, GE8320, 60fps, 프레임 드랍, fill rate, 픽셀 셰이딩, 정점 컬러 굽기, vertex color, UNSHADED, 조명 없음, 라이트맵 느림, 빌드 타임 베이킹, build time bake, 프로시저럴 생성, procedural, 머티리얼 병합, 청크, 드로우콜 줄이기, 스켈레톤 갱신, 본 수 줄이기, 스킨드 메시, SIGSEGV, WorkerThread, 분산 로딩, 셰이더 예열, Godot, 고도, GDScript, gdshader, tscn, tres, Node3D, CharacterBody3D, Jolt, AnimationTree, NavigationAgent3D, StandardMaterial3D, LSP, 3D 게임, 라리엔, VirtualJoystick, 가상 조이스틱, GPUParticles3D, 게임패드, PCK, 패치 배포, 빌드, 테스트 빌드, 릴리즈 빌드, 내보내기, export, export template, 익스포트 템플릿, export_presets.cfg, --export-debug, --export-release, APK, AAB, adb install, logcat, keystore, 키스토어, Gradle, GABE, ipa, Xcode, xcodebuild, TestFlight, 공증, codesign, Steam Deck, 원클릭 배포, 스텐실, stencil, stencil_mode, 외곽선, X-ray, 벽 뚫어보기, duplicate_deep, 깊은 복사, RichTextLabel, BBCode, 콜리전 셰이프, 델타 인코딩, BoneConstraint3D, AimModifier3D, CopyTransformModifier3D, 본 제약, 물리 보간, physics_interpolation, NavigationServer2D, 비동기 내비게이션, SDL3, bent normal, 스펙큘러 오클루전, SMAA, F16, 반정밀도, Import 독, 배치 임포트, 에디터 없이 작업, headless, 헤드리스, install.sh, 실기기 설치, 실기기 실행, 아이폰 실행, 안드로이드 실행, Remote Deploy, 리모트 디플로이, devicectl, xctrace, UDID, device-id, Team ID, app_store_team_id, export_project_only, gdignore, .gdignore, Cmd+B, 실행 버튼, 기본 개념, 기초, 입문, 공부, 학습, 배우기, pass, 패스, 빈 함수, 빈 블록, 자리표시자, Expected indented block, return, 반환, Receiver Method, 수신 메서드, 콜백, callback, 이벤트 핸들러, event handler, _on_, connection, tscn 연결, CONNECT_PERSIST, 연결 아이콘, Connect a Signal to a Method, 궤도 회전, orbit, 팬, pan, 프리룩, freelook, 카메라 회전, 뷰포트 회전, 시그널, Signal, signal, 시그널 발산, emit, emit_signal, connect, disconnect, is_connected, Callable, 콜러블, 옵저버, Observer, 관찰자 패턴, 결합도, 느슨한 결합, 이벤트, event, 내장 시그널, 엔진 시그널, 커스텀 시그널, body_entered, area_entered, pressed, CONNECT_ONE_SHOT, CONNECT_DEFERRED, ERR_INVALID_PARAMETER, 중복 연결, Node 독, Signals 탭, await, 시그널 대기, 에디터 조작, 뷰포트 조작, 궤도 회전, orbit, 팬, pan, 줌, 프리룩, freelook, 가운데 버튼, 휠 클릭, 3버튼 마우스, Magic Mouse, 매직마우스, 매직 마우스, Magic Keyboard, 매직 키보드, 왼손잡이, 왼손 마우스, 단축키 변경, 키 변경, Shortcuts, Editor Settings, 에디터 설정, emulate_3_button_mouse, Emulate 3 Button Mouse, Navigation Scheme, Maya 방식, orbit_mouse_button, pan_mouse_button, zoom_mouse_button, spatial_editor, freelook_forward, WASD, IJKL, 보조 클릭, Secondary click, 우클릭, InputMap, 인풋맵, 액션, action, 리바인딩, rebinding, 키 재설정, action_add_event, action_erase_events, physical_keycode, keycode, 자판 배열, QWERTY, 접근성, 노드, Node, 씬, Scene, 인스턴싱, Instancing, instantiate, PackedScene, preload, load, Instantiate Child Scene, Cmd+Shift+A, Ctrl+Shift+A, Editable Children, Make Local, 리소스, Resource, 생명주기, _ready, _process, extends, 에디터 화면, Scene 독, Inspector, FileSystem, Output, res://, user://, 용어집, 용어, dictionary, CSG, Constructive Solid Geometry, 구성적 입체 기하, CSGShape3D, CSGCombiner3D, CSGBox3D, CSGPolygon3D, use_collision, bake_static_mesh, bake_collision_shape, Union, Intersection, Subtraction, 불리언 연산, 블록아웃, blockout, 그레이박싱, greyboxing, 화이트박싱, 회색 상자, 레벨 디자인, 맵 구조, 맵 만들기, 맵 제작, 레벨 제작, level design, GridMap, MeshLibrary, cell_size, bake_navigation, 모듈러, 타일, glTF, glb, 프롭, 소품, 터레인, terrain, HeightMapShape3D, Terrain3D, 씬 골격, main.tscn, Main Scene, 메인 씬, Level 교체, 맵 전환, load_threaded_request, load_threaded_get_status, THREAD_LOAD_LOADED, 비동기 로딩, 로딩 화면, SpawnPoints, Marker3D, WorldEnvironment, Add Sun to Scene, Add Environment to Scene, DirectionalLight3D, 씬 뼈대, 자식 노드 추가, Cmd+A, Ctrl+A, F2, Use Collision, Camera3D, 카메라 배치, 쿼터뷰, 카메라 각도, fov, Preview, Current, Align Transform with View, CameraRig, CSGBox3D, 상자 6개, 방 좌표, 좌표표, 벽 두께, Doorway, 문 뚫기, Cmd+D, 복제, 방, room, 보스방, 복도, 광장, 실내, 야외, 사냥터, 던전, 피치, pitch, 요, yaw, 롤, roll, 회전 3축, 오일러, rotation_degrees, 노멀, normal, 법선, 플랫 셰이딩, 스무스 셰이딩, flat shading, smooth shading, smooth_faces, autosmooth, smoothing_angle, 텍스처, texture, UV, UV 언랩, UV unwrap, UV1, UV2, 언랩, 맵, map, 알베도, albedo, albedo_color, albedo_texture, 컬러맵, 러프니스맵, roughness, 메탈릭, metallic, ORM, PBR, 아틀라스, atlas, 텍스처 아틀라스, 타일링, tiling, 해상도, resolution, 128px, 256px, 512px, 2K, 4K, ASTC, 텍스처 용량, 번들 용량, 파일 크기, 벡터 그래픽, SVG, 픽셀, pixel, 노멀맵, normal map, normal_enabled, normal_texture, normal_scale, 하이폴리, high-poly, 로우폴리, low-poly, 폴리곤, polygon, 베이킹, baking, 굽기, bake, 삼각형 수, 트라이앵글, ZBrush, OpenGL 규약, DirectX 규약, G 채널 반전, Asset Store, 에셋 스토어, AssetLib, 애셋 라이브러리, 애드온, addon, addons, 플러그인, plugin.cfg, editor_plugins, enabled, PackedStringArray, autoload, 오토로드, add_autoload_singleton, EditorPlugin, godot-ai, godot_ai, Godot AI, mcp__godot-ai, node_create, scene_open, editor_screenshot, project_run, logs_read, enabledMcpjsonServers, mcp.json, MCP 서버, HUD, 헤드업 디스플레이, 메뉴, 메인 메뉴, 일시정지, 설정 화면, 버튼, 체력바, HP바, 게이지, 미니맵, 인벤토리, 인벤토리 UI, 장비창, 대화창, 화면 UI, UI 디자인, UI 만들기, UI 조립, 화면 배치, Control, Container, VBoxContainer, HBoxContainer, MarginContainer, CenterContainer, GridContainer, PanelContainer, ScrollContainer, AspectRatioContainer, TabContainer, CanvasLayer, layer, Theme, 테마, theme_type_variation, 타입 배리에이션, StyleBox, StyleBoxFlat, 스타일박스, 앵커, anchor, 오프셋, offset, 프리셋, preset, PRESET_FULL_RECT, Full Rect, Layout 버튼, size_flags, SIZE_EXPAND_FILL, custom_minimum_size, custom_maximum_size, separation, mouse_filter, MOUSE_FILTER_STOP, MOUSE_FILTER_PASS, MOUSE_FILTER_IGNORE, 터치가 안 먹힘, UI 가 입력을 먹음, focus_mode, focus_neighbor, Button, TextureButton, BaseButton, action_mode, pressed 시그널, Label, RichTextLabel, ProgressBar, TextureProgressBar, radial_fill_degrees, 쿨다운 UI, TextureRect, NinePatchRect, Panel, Access as Unique Name, 유니크 이름, %노드, process_mode, PROCESS_MODE_WHEN_PAUSED, get_tree().paused, 일시정지 함정, 세이프 에어리어, safe area, get_display_safe_area, get_display_cutouts, 노치, 홈 인디케이터, 터치 크기, 48dp, 엄지 영역, 세로 화면, портрет, portrait, SCREEN_PORTRAIT, orientation, 1080x1920, 화면 방향, 해상도 대응, stretch, canvas_items, expand, Label3D, 월드 스페이스 UI, 머리 위 이름표, 미니맵 회전, 폰트, 한글 폰트, CJK, 글자가 네모, 네모로 나옴, 두부, tofu, SystemFont, FontFile, FontVariation, fallbacks, 폰트 폴백, 서브셋, subset, Noto Sans KR, MSDF, multichannel signed distance field, default_font_generate_mipmaps, 폰트 밉맵, 폰트 크기, LabelSettings, 외곽선, outline_size, content_scale_factor, stretch mode, stretch aspect, canvas_items, keep_width, expand, scale_mode, fractional, integer, 기준 해상도, base resolution, 정사각형 기준, Layout 메뉴 잠김, 앵커 vs 컨테이너, 컨테이너 중첩, 중첩 깊이, ScrollContainer, follow_focus, scroll_deadzone, drag_threshold, emulate_mouse_from_touch, 터치 드래그, 재사용 컴포넌트, 컴포넌트화, class_name, tool 스크립트, Engine.is_editor_hint, is_node_ready, Editable Children, UI 애니메이션, Tween, set_ease, set_trans, EASE_OUT, TRANS_CUBIC, kill, 트윈 겹침, offset_transform, offset_transform_enabled, offset_transform_visual_only, 오프셋 변환, 버튼 흔들기, 화면 전환, 페이드, ColorRect, 씬 전환, 접근성, accessibility, AccessKit, 스크린 리더, screen reader, accessibility_name, 아이콘 버튼, 대비, 색약, keep_aspect, KEEP_HEIGHT, KEEP_WIDTH, 세로 화면 시야, 카메라 종횡비, 테마 아틀라스, UI 드로우콜, 라이선스, 서브모듈, **(18) 처음 배우는 사람에게 3D 씬을 처음부터 만들어 보이거나 따라 하게 할 때(빈 프로젝트 → 바닥·벽·플레이어 → 화살표 키로 이동) — references/example.md 가 정본**, **(19) 사용자가 `/godot init` 이라고 지시하면 .claude/commands/ 에 godot 슬래시 명령들을 설치한다**. 키워드 - init, godot init, 초기화, 슬래시 명령 설치, 명령어 생성, commands 설치, example, 예제, 기본 예제, 첫 씬, 처음 만들기, 튜토리얼, 따라하기, 실습, 바닥 만들기, 벽 만들기, 캐릭터 움직이기, 화살표 키 이동, 걸어다니기, 쿼터뷰 카메라, 블록아웃 예제
---

# Godot — 3D 게임 개발·학습 스킬

**최신 Godot 기준**으로 3D 게임을 개발하기 위한 전체 개발 정보와 검증 도구를 제공한다.

## 이 스킬의 두 가지 성격

이 스킬은 **개발 규범이자 학습 자료**다. 둘 다이며, 어느 한쪽이 아니다.

| 성격 | 뜻 |
|---|---|
| **개발 규범** | 라리엔 3D 코드는 여기 적힌 방식을 따른다. "절대 규칙" 절은 예외 없이 지킨다 |
| **학습 자료** | 사용자는 **Godot 을 배우면서 게임을 만들고 있다.** 엔진 사용법·기본 개념도 이 스킬이 설명한다 |

### 그래서 답할 때 지킬 것

**결과만 주지 말고 왜 그런지를 함께 설명한다.** 사용자는 코드를 받는 것이 아니라
**Godot 을 이해하려 하고 있다.**

| 하지 않는다 | 한다 |
|---|---|
| "이 코드를 쓰세요" 하고 끝 | 그 노드가 무엇이고, 왜 그 노드인지, 대안은 무엇인지 한 줄이라도 붙인다 |
| 에디터 조작을 말로만 | **어느 독에서 · 어떤 버튼·단축키로** 하는지 경로를 준다 |
| 용어를 설명 없이 사용 | 처음 나오는 용어는 뜻을 밝히거나 [dictionary.md](references/dictionary.md) 로 보낸다 |
| 값을 추측해서 단언 | 엔진에서 확인하고, 확인했다는 사실과 값을 함께 보인다 |

### 🛑 소스 코드를 요청받으면 — **주석을 단 전체 파일**로 준다

사용자가 *"소스 코드를 보여 달라"* · *"설명을 달아 달라"* 고 하면
**조각이 아니라 파일 전체**를, **그 자리에서 읽고 이해할 수 있는 주석과 함께** 준다.

**표준 형식은 [example.md](references/example.md) §7 의 "📜 주석 완전판"** 이다.
새로 코드를 설명할 때도 그 형식을 따른다.

| 반드시 담을 것 | 예 |
|---|---|
| **파일 머리 블록** | 이 스크립트가 **붙는 자리**, **기대하는 씬 구조**, 좌표 규약 |
| **함수마다** | **누가 부르는가**(내가? 엔진이?) · **언제 부르는가** · 이름을 틀리면 어떻게 되는가 |
| **줄·블록마다** | 무엇을 하는가 → **왜 그렇게 하는가** → **바꾸면 어떻게 되는가** |
| **함정 표시** | 🛑 로 표시하고 **틀렸을 때 나오는 실제 오류 메시지**를 적는다 |
| **이름의 출처** | 엔진이 정한 이름인지, 내가 지은 이름인지 (바꿔도 되는지) |
| 🛑 **선언 없이 쓰는 이름** | `extends` 로 물려받아 그냥 쓰는 것(`velocity`·`is_on_floor()`·`global_position` …)은 **처음 나오는 자리에서** 정체·타입·단위·이름을 바꿀 수 있는지까지 밝힌다 |

**주석은 실행에 영향이 없으므로 그대로 복사해 써도 된다는 것**을 함께 알린다.

> 🛑 **다 쓴 뒤 반드시 점검한다** — **파일 안에 `var`·`func` 로 선언되지 않았는데
> 설명 없이 등장하는 이름이 있는지** 훑는다. 독자는 그 이름이 어디서 왔는지 알 방법이
> 없고, "왜 이건 설명이 없나" 로 막힌다. 실제로 `velocity` 를 빠뜨려 지적받았다.

**설명이 문서에 없으면 먼저 문서에 채우고 나서 답한다.** 답변만 하고 끝내면
같은 질문이 반복되고, 문서와 답이 갈라진다.


**Godot 을 처음 접하는 질문이면 [basics.md](references/basics.md) 를 먼저 읽는다.**
노드·씬·인스턴싱·리소스·생명주기·에디터 화면 구성이 거기 있다.

### 새 내용을 어느 문서에 넣을 것인가

**기본은 [basics.md](references/basics.md) 로 모은다.** 문서가 늘어날수록 "기본 개념을
찾으려면 어디를 봐야 하는가"가 흐려지므로, 아래 기준으로 갈라 놓는다.

| 성격 | 넣을 곳 |
|---|---|
| **기본 개념·기본 문법·기본 사용법** — Godot 을 배우는 사람이 알아야 할 것 | **[basics.md](references/basics.md)** |
| **저사양(3GB RAM) 60fps 실측·노하우** — 베이킹·병목 진단·본 수·크래시 회피 | **[lowend-3gb-60fps.md](references/lowend-3gb-60fps.md)** |
| 용어의 뜻 한 가지 | [dictionary.md](references/dictionary.md) |
| 특정 영역의 **테크닉·심화·실전 패턴** | 그 영역 문서 (physics-3d, rendering-3d, animation-3d …) |
| 문법의 **전수 목록·상세 레퍼런스** | [gdscript.md](references/gdscript.md) |

판단이 애매하면 이렇게 가른다 — **"Godot 을 처음 배우는 사람이 이걸 몰라서 막히는가?"**
그렇다면 `basics.md` 다. **"이미 아는 사람이 더 잘하려고 찾는 것인가?"** 그렇다면 영역 문서다.

같은 주제를 양쪽에 쓸 때는 **`basics.md` 에 개념을, 영역 문서에 실전을** 두고 서로 링크한다.
인스턴싱이 그 예다 — 개념과 4단계는 `basics.md` §3, 스포너·풀링 같은 패턴은
[nodes-scenes.md](references/nodes-scenes.md) §4 에 있다.

특정 패치 버전에 묶인 문서가 아니다. 새 기능은 **도입 버전을 표기**해
(`(4.5+)`, `(4.6 신규)`, `(4.7 신규)`) 쓸 수 있는지 바로 판단하게 한다.
버전별 신기능과 업그레이드 절차는 [references/whats-new.md](references/whats-new.md)에 모아 둔다.

> **검증 기준**: 문서의 API·기본값·설정 키는 **엔진에서 직접 추출·실행해 확인한 것**이며,
> 현재 확인 기준 버전은 `godot --version` 기준 **4.7.2.stable**이다.
> 엔진을 올렸다면 값이 달라질 수 있으므로, 의심스러우면 그 자리에서 다시 확인한다.
>
> ```bash
> godot --version                          # 현재 엔진 버전
> godot --headless --doctool /tmp/gddoc     # 클래스 정의 XML 전체 추출
> ```

## `/godot init` — 프로젝트에 슬래시 명령을 설치한다

사용자가 **`/godot init`** 이라고 지시하면, 이 스킬이 들고 있는 명령 파일들을
**대상 프로젝트의 `.claude/commands/` 로 복사**한다. 그 뒤로는 `/godot-example` 처럼
짧게 부를 수 있다.

### 설치하는 것

| 원본 (이 스킬 안) | 설치 위치 | 무엇을 하는 명령인가 |
|---|---|---|
| `commands/godot-example.md` | `.claude/commands/godot-example.md` | **기본 예제 생성** — 빈 프로젝트에 바닥·벽·플레이어를 세우고 화살표 키로 걸어다니게 한다 (→ [example.md](references/example.md) 1~8단계) |

새 명령을 늘릴 때는 `commands/` 에 파일을 추가하고 이 표에 한 줄을 더한다.
**표에 없는 파일은 설치하지 않는다.**

### 절차

```bash
# 1. 이 스킬의 commands 폴더를 확인한다
ls .claude/skills/godot/commands/

# 2. 대상의 commands 폴더를 만든다 (없으면)
mkdir -p <대상>/.claude/commands

# 3. 복사한다
cp .claude/skills/godot/commands/godot-example.md <대상>/.claude/commands/
```

인자로 경로가 오면(`/godot init ~/apps/ex2`) 그 프로젝트에, 없으면 **현재 프로젝트**에 설치한다.

### 지킬 것

| 규칙 | 이유 |
|---|---|
| **같은 이름의 파일이 이미 있으면 덮어쓰지 않는다** | 사용자가 고쳐 둔 명령을 날린다. 차이를 보여주고 물어본다 |
| 설치 후 **무엇이 생겼고 어떻게 부르는지** 알린다 | 파일만 복사하고 끝내면 쓸 줄 모른다 |
| 새 명령은 **`commands/` 에 원본을 두고** 복사한다 | 내용이 두 곳으로 갈라지지 않게 한다 |
| 슬래시 명령은 **재시작 후 인식**될 수 있다 | 목록에 안 보이면 세션을 다시 열라고 안내한다 |

---

## 🛑 게임 규칙은 `game` 스킬의 SSOT 가 최종 권위다

이 스킬은 **엔진 사용법**을 담는다. **"라리엔이 어떤 규칙으로 만들어지는가"** 는
[`game` 스킬의 SSOT.md](../game/references/SSOT.md) 에 있고 **그쪽이 최종 권위다.**

| 이 스킬에서 다루는 것 | SSOT 가 정하는 것 |
|---|---|
| `Camera3D` 의 `fov`·투영·`SpringArm3D` 사용법 | **카메라 각도는 회전 3축 전부 고정**(피치 −45°·yaw 0°·roll 0°), 줌만 0.5~2배 |
| `LightmapGI` 굽는 방법·설정 | **동적 조명은 존재하지 않는다** — 낮/밤·날씨·동적 그림자 전면 금지 |
| 드로우콜을 줄이는 기법 | **예산은 300** (텍스처 200MB · 메모리 1,120MB) |
| `visibility_range`·`MultiMesh` API | **거리 3구간 배분**(AOI 82개 → 8/20/54) |

**엔진이 할 수 있는 것과 이 게임이 하기로 한 것은 다르다.**
예: Godot 은 실시간 그림자를 지원하지만 **라리엔 3D 는 쓰지 않는다.**
기능을 제안하기 전에 SSOT 를 확인한다.

## 현재 프로젝트 컨텍스트

[`project.godot`](../../../project.godot)에 고정된 값이며, 모든 코드는 이 전제 위에서 작성한다.

| 항목 | 값 | 개발상 의미 |
|------|-----|------------|
| `config/name` | `Laryen 3D` | 프로젝트 이름 |
| `config/features` | `4.7`, `Mobile` | Godot 4.7 API, Mobile 렌더러 |
| `renderer/rendering_method` | `mobile` | **SDFGI·VoxelGI·SSR·SSAO·SSIL·볼류메트릭 포그·TAA 사용 불가** |
| `3d/physics_engine` | `Jolt Physics` | Godot Physics 전용 조인트 속성 사용 불가 |
| `rendering_device/driver.windows` | `d3d12` | Windows는 Direct3D 12, 그 외는 Vulkan/Metal |
| `window/stretch/mode` | `canvas_items` | UI 스케일링 방식 |

**🛑 최소 지원 사양 — 3GB RAM Android (Galaxy A12 급) 에서 60fps**

> ### **모바일 3D MMORPG 의 최소 지원 RAM 은 3GB 다.**
>
> "요즘 폰은 8GB 니까" 로 기준을 올리지 않는다. **MMORPG 는 수명이 길고,
> 그 기간 내내 구형 기기가 접속한다.** 기준을 올리는 순간 실사용자의 상당수가 잘려 나간다.
> **FPS 와 메모리가 그래픽 품질보다 우선한다.**

**🛑 저사양 60fps 작업을 시작하기 전에 반드시 읽는다 →
[references/lowend-3gb-60fps.md](references/lowend-3gb-60fps.md)**

프로시저럴 생성 → **빌드 타임 베이킹** 파이프라인, 병목을 실험으로 가려내는 절차,
조명을 정점 컬러에 굽는 법, 스킨드 캐릭터 30명 이상을 60fps 로 돌리는 법,
저사양 기기의 크래시 회피까지 **A12 실측 기록**으로 정리되어 있다.

기준 기기·실측값·규범은
[references/performance-mobile.md §0](references/performance-mobile.md#0--최소-지원-사양--3gb-ram-android-가-기준이다) 에도 있고,
성능 판단을 하기 전에 **반드시 그 절을 먼저 읽는다.**

| 실측 요약 (SM-A125N · PowerVR GE8320 · Mobile 렌더러) | |
|---|---|
| 🛑 **조명을 쓰지 않는다** — 실시간도, 라이트맵도 | 라이트맵 **1.0fps** / 실시간 22.3fps / **조명 없음 60fps** |
| 반복 배치는 **무조건 `MultiMeshInstance3D`** | Mobile 렌더러엔 자동 인스턴싱이 없다 (실기기 DC 300 vs 1) |
| 🛑 **메모리도 예산이다** | 반복물을 병합하면 정점이 복제되어 **메모리 400배**. 나무 1,000그루 = MultiMesh 81KB vs 병합 33MB → [lowend-3gb-60fps.md §5.3](references/lowend-3gb-60fps.md#53--multimesh-vs-병합--메모리를-400배-내는-거래) |
| 폴리곤은 아끼지 않아도 된다 | 지형 삼각형 20만까지 실질 무해 |
| 진짜 병목은 **픽셀당 셰이딩** | 삼각형 2개짜리 면 하나가 60→22fps |
| **스킨드 캐릭터는 본 수가 곧 프레임** | 30명 기준 본 25 → **40.3fps** / 본 16 → **60.0fps** |
| **병목은 하나가 아니다 — 순서대로 드러난다** | 메모리 → 드로우콜 → 정점 → VRAM → 스켈레톤 → 로딩 |
| 드로우콜 한계는 **650~900** | 병합 전 1,291 → 병합 후 **6**. DC 83 은 문제가 아니었다 |
| 프로시저럴은 **빌드 타임에 굽는다** | 배치 6,227개를 3.4초에 bake → 런타임 생성 코드 **0줄** · DC 9~23 |
| 리소스를 한꺼번에 로드하면 **드라이버가 죽는다** | `SIGSEGV in WorkerThread` — 프레임에 나눠 읽으면 5/5 성공 |

**Mobile 렌더러 전제로 반드시 지킬 것**

- 🛑 **같은 모양이 대량 반복되는 것(나무·풀·바위)은 `MultiMeshInstance3D` 로 묶는다.**
  병합하면 정점이 개수만큼 복제되어 **메모리를 400배** 쓴다. 병합은 **꼭짓점 단위로
  밝기가 달라야 할 때만** 지불하는 대가다 (→ lowend-3gb-60fps.md §5.3).
- 🛑 **광원 노드를 씬에 두지 않는다.** 조명은 **빌드 타임에 정점 컬러로 굽고**
  런타임 머티리얼은 `SHADING_MODE_UNSHADED` + `vertex_color_use_as_albedo` 를 쓴다.
  `LightmapGI` 는 저사양에서 **오히려 가장 느리다** (→ performance-mobile.md §8).
- `SDFGI`/`VoxelGI`는 Mobile 렌더러에 없다. 제안하지 않는다.
- 안티에일리어싱은 `MSAA 3D` 또는 `FXAA`/`SMAA`를 쓴다. `TAA`/`FSR2`는 없다.
- 후처리는 `Glow`, `Adjustments`, 기본 `Fog`까지만 가능하다.
- `SubsurfaceScattering`은 Forward+ 전용이므로 머티리얼에서 쓰지 않는다.
- AO는 화면공간 대신 **정점 컬러에 구운 AO** 또는 베이킹된 AO 텍스처를 쓴다.

렌더러별 지원/미지원 전체 표는 [references/rendering-3d.md](references/rendering-3d.md)에 있다.

## 작업 흐름 — 이 순서를 지킨다

### 1. 시작 전

- **버전 확인**: `godot --version`으로 현재 엔진 버전을 본다. 쓰려는 기능의 도입 버전이
  그보다 높으면 안 된다. 버전별 신기능과 업그레이드 시 확인할 것은
  [references/whats-new.md](references/whats-new.md)에 정리되어 있다.
- **관련 reference를 먼저 읽는다.** 아래 목록에서 해당 영역 문서를 읽고,
  Mobile 렌더러 / Jolt 제약에 맞는 방법을 고른다.
- **`.tscn`/`.tres`를 직접 편집하기 전에** [references/project-config.md](references/project-config.md)의
  포맷 규칙을 읽는다. `load_steps`나 리소스 ID를 잘못 쓰면 씬이 깨진다.

### 2. 구현 중

- 씬 구조를 먼저 정한다 — 재사용 단위마다 `.tscn`으로 분리하고 루트 노드 타입을 신중히 고른다.
- **스크립트는 씬 옆에 둔다** — `scenes/player/player.tscn` + `scenes/player/player.gd`.
  아래 "파일 배치 규범" 참고.
- 스크립트는 **정적 타입**으로 작성한다. 노드 참조는 `@onready` + 고유 이름(`%`)을 쓴다.
- 물리·이동은 `_physics_process`, 시각·입력 폴링은 `_process`에 둔다.
- 노드 간 결합은 직접 참조 대신 시그널로 푼다.

#### 파일 배치 규범 — 스크립트는 씬 옆에

Godot에서는 타입별로 `scripts/`에 모으는 방식보다 **씬과 스크립트를 같은 폴더에
나란히 두는 것이 공식 권장이자 실무 다수**다. Unity의 `Scripts/` 관습을 그대로
가져오면 Godot에서는 오히려 관리가 어려워진다.

| 근거 | 내용 |
|------|------|
| 엔진이 그 관습을 전제로 동작 | Attach Script의 기본 경로가 **현재 씬 폴더 + 노드 이름**이다. `scripts/`로 두려면 매번 손으로 고쳐야 한다 |
| 씬과 스크립트는 1:1로 강하게 묶임 | `extends`는 루트 타입에, `$Child`는 노드 구조에 종속된다. 재사용 불가능한 **사실상 씬의 일부**다 |
| 파일명이 충돌 | `ui/player_hud.tscn`과 `entities/player.tscn`이 각각 스크립트를 가지면 결국 `scripts/ui/`, `scripts/entities/`로 **폴더 구조를 두 번 유지**하게 된다 |

**예외 — `scripts/`·`autoload/`에 모으는 것**: 씬에 붙지 않는 스크립트다.
오토로드 싱글턴(`GameState`, `AudioManager`), `class_name`을 가진 공용 클래스
(상태 머신 베이스, 수학 유틸), 커스텀 `Resource` 정의(`ItemData`, `SkillData`).
**`scripts/` 폴더를 없애는 게 아니라 용도를 바꾸는 것이다.**

```
res://
├─ scenes/
│  ├─ main.tscn
│  ├─ main.gd              ← 씬 옆에
│  ├─ player/
│  │  ├─ player.tscn
│  │  ├─ player.gd
│  │  └─ player.glb        ← 한 씬에서만 쓰는 모델도 같이
│  └─ ui/
│     ├─ hud.tscn
│     └─ hud.gd
├─ autoload/
│  └─ game_state.gd
└─ scripts/                ← 씬에 안 붙는 공용 코드만
   └─ save_system.gd
```

상세 근거와 확장 구조는 [references/nodes-scenes.md](references/nodes-scenes.md) 11절.

### 3. GDScript를 작성·수정한 직후 — 필수

**LSP로 진단한다. 이 단계를 건너뛰지 않는다.**

```bash
python3 .claude/skills/godot/scripts/gdscript_lsp.py diagnose res://수정한파일.gd

# 여러 파일을 건드렸으면 git 변경분 전체
python3 .claude/skills/godot/scripts/gdscript_lsp.py diagnose --changed
```

오류가 하나라도 남아 있으면 작업이 끝난 것이 아니다.
**"코드를 작성했다"고 보고하기 전에 이 명령이 오류 0개를 반환해야 한다.**

종료 코드: `0`=오류 없음, `1`=오류 있음, `2`=LSP 연결 실패.

Godot 에디터가 실행 중이어야 동작한다. 자세한 사용법·경고 종류·문제 해결은
[references/lsp.md](references/lsp.md)를 읽는다.

### 4. 기존 코드를 수정할 때

1. 해당 기능의 reference에 기록된 **핵심 로직과 소스코드를 먼저 확인**한다.
2. 문서에 기록된 패턴을 유지한 채 최소 범위로 수정한다. 기존 로직을 임의로 재작성하지 않는다.
3. 로직이 실제로 바뀌었다면 reference 문서도 함께 갱신한다.

### 5. 문제를 진단할 때

**채널을 순서대로 올라간다. 위쪽이 싸고 빠르다.**

| 알고 싶은 것 | 방법 |
|-------------|------|
| 문법·타입 오류, 경고 | `gdscript_lsp.py diagnose` |
| 파일 구조 (클래스·함수 목록) | `gdscript_lsp.py symbols` — 파일 전체를 읽지 않고 파악 |
| 변수의 타입, 심볼 정의 | `gdscript_lsp.py hover` / `definition` |
| 씬 구조, 프로젝트 설정 | `.tscn` / `project.godot` 직접 읽기 |
| 런타임 오류, 실제 노드 값, 화면 | MCP 도구 ([references/ai-tooling.md](references/ai-tooling.md)) |
| 특정 시점의 지역 변수 | DAP 브레이크포인트 |
| 성능 병목 | [references/performance-mobile.md](references/performance-mobile.md)의 CPU/GPU 구분 절차 |

**LSP로 잡을 수 있는 문제를 게임 실행으로 찾지 않는다.**
**코드만 읽고 런타임 동작을 단정하지 않는다** — 값을 확인해야 하면 MCP로 관찰한다.
**원인 파악 전에 최적화하지 않는다.**

## 절대 규칙

Godot에서 실제로 버그를 만들어내는 지점이다. 예외 없이 지킨다.

| 규칙 | 이유 |
|------|------|
| 물리 관련 코드는 `_physics_process(delta)`에만 쓴다 | 물리 서버는 고정 틱(기본 60Hz)으로 돈다. `_process`에서 바디를 움직이면 지터·터널링이 생긴다 |
| 3D 회전은 `rotation`(오일러) 대신 `Transform3D`/`Basis`/`Quaternion`으로 다룬다 | 오일러는 짐벌락·회전 순서 의존·보간 왜곡을 일으킨다 |
| 전방 벡터는 `-transform.basis.z`다 | Godot 3D는 **-Z가 forward**, +Y가 up, +X가 right |
| `:=`는 우변 타입이 확실할 때만 쓴다 | `Object.get()`, 딕셔너리 값, 빈 `[]`/`{}`, 불확실한 노드 경로에서 추론하면 Variant가 되어 이후 모든 접근이 unsafe가 된다 |
| `name`·`position`·`rotation`·`scale`·`visible`·`seed`를 변수명으로 쓰지 않는다 | 엔진 멤버를 가려 예측 불가능한 동작을 만든다 |
| `@export`와 `@onready`를 함께 쓰지 않는다 | 인스펙터 값이 `_init()` 시점에 신뢰할 수 없다 |
| 필수 노드는 `@onready var n := $Path as Type` 대신 명시적 타입을 쓴다 | `as`는 실패 시 조용히 `null`이 된다 |
| `await` 뒤에 `is_instance_valid(self)`와 `is_inside_tree()`를 확인한다 | 대기 중 노드가 제거될 수 있다 |
| 물리·접촉 콜백에서 씬 트리·콜리전 셰이프·monitoring 변경은 `call_deferred`로 미룬다 | 물리 쿼리 중 상태 변경은 오류를 낸다 |
| `free()` 대신 `queue_free()`를 쓴다 | 프레임 중간 `free()`는 순회 중인 트리를 깨뜨린다 |
| 씬 첫 프레임에 NavigationServer 결과를 읽지 않는다 | 첫 물리 프레임 전까지 맵이 동기화되지 않는다. `await get_tree().physics_frame` 필요 |
| 누적 회전 후 `transform = transform.orthonormalized()` | 부동소수점 오차로 basis가 찌그러진다 |
| 리소스를 인스턴스 간 공유할 때 주의한다 | 머티리얼·AnimationTree 등은 기본 공유. 개별화는 `duplicate()` 또는 `Local to Scene` |
| 씬에 붙는 스크립트는 씬과 같은 폴더에 둔다 | 엔진의 Attach Script 기본 경로가 그 구조를 전제한다. 씬과 1:1로 묶인 코드를 분리하면 이동·삭제 때마다 두 폴더를 손으로 동기화해야 하고 파일명이 충돌한다 |

## 참조 문서

각 문서는 **핵심 개념 → 핵심 로직 → 실제 소스코드** 순으로 구성되어 있으며,
문서만 보고 해당 기능을 완전히 재구현할 수 있도록 작성되었다. 필요한 것만 읽는다.

**처음 배우는 순서**: [basics.md](references/basics.md)(노드·씬·인스턴싱) → **[example.md](references/example.md)(손으로 한 번 만들어 본다)** →
[dictionary.md](references/dictionary.md)(용어) → [gdscript.md](references/gdscript.md)(문법) →
[nodes-scenes.md](references/nodes-scenes.md)(구조 심화) →
[3d-core.md](references/3d-core.md)(좌표·카메라) →
[level-design.md](references/level-design.md)(맵 만들기) →
[physics-3d.md](references/physics-3d.md)(움직임·충돌).
**만들면서 배우는 사람**은 처음 두 개만 읽고 바로 맵 만들기로 가도 된다.
**넓은 야외 맵을 만들려는 사람은 코드를 쓰기 전에**
[openworld-3d.md](references/openworld-3d.md) **§0 을 먼저 읽는다** —
맵 크기는 나중에 조금씩 키울 수 있는 값이 아니다.

### [lowend-3gb-60fps.md](references/lowend-3gb-60fps.md) — 🛑 3GB RAM 폰에서 60fps ★ 저사양 작업 전 필독

**모바일 3D MMORPG 의 최소 지원 사양(3GB RAM)에서 60fps 를 확보한 A12 실측 기록.**
의견이 아니라 전부 실기기 측정값이며, **처음 읽는 사람도 따라올 수 있게** 기초부터 쓰여 있다.

맨 앞에 **"딱 세 가지만 기억하세요"** 와 **증상별 읽을 곳 표**가 있어, 무엇부터 볼지 바로 정해진다.

| 절 | 내용 |
|---|---|
| **§1 기초** | 60fps = 16.7ms 예산 · 용어 5개(드로우콜·삼각형·정점·본·fill rate) · 프레임이 만들어지는 과정 |
| **§2 병목 6가지** | 무엇이 무엇에 비례하는지 표 · 해결 순서 · **드로우콜은 언제 문제이고 언제 아닌가** |
| **§3 진단** ★ | 변수를 하나씩 빼서 재는 절차. 이 작업에서 병목을 **세 번 잘못 짚었다** · 측정 함정 6가지 |
| **§4 조명** | 광원 0개. 라이트맵 1.0fps / 실시간 22.3fps / **정점 색 굽기 60.0fps** |
| **§5 기물 만들기** ★ | 프로시저럴 → **빌드 타임 굽기** 전체 흐름도 · 함정 6개 |
| **§5.3 MultiMesh vs 병합** ★ | **메모리를 400배 내는 거래.** 판단표 · 인스턴스 색 · 기물 종류별(자연물/인공물) 권장 · 스킨드 캐릭터는 왜 안 묶이는가 |
| **§6 외부 에셋** | glTF 임포터가 텍스처를 복제해 **1.8GB** 가 되는 함정 · 반드시 바꿀 임포트 설정 7가지 |
| **§7 캐릭터 30명** | **본 65 → 16** · 갱신 빈도 조절은 효과 없음 · **장비 교체는 프레임과 무관**(실측) |
| **§8 크래시** | 리소스를 프레임에 나눠 읽기 (5/5 성공) |
| **§9~11** | 수단 총정리 · 체크리스트 · 예산표 |

### [basics.md](references/basics.md) — Godot 기본 ★ 처음 배울 때 먼저 · 기본은 여기 모은다

맨 앞에 **기본적으로 공부해야 할 목록**(5단계 체크리스트 — 엔진 구조 → GDScript 문법 →
3D 기초 → 움직임·충돌 → 만들어 보기)이 있어, 무엇을 알아야 하는지부터 판단하게 한다.
**"Godot 이 왜 이렇게 생겼는가"**를 다루는 입문 문서. 다른 문서가 "어떻게 하는가"라면
이쪽은 개념의 뼈대다. Godot 의 세계관 3문장(**모든 것은 노드 → 노드를 묶으면 씬 →
씬은 다른 씬의 부품이 된다**)과 다른 엔진과의 차이(**레벨과 프리팹을 나누지 않고 둘 다
`.tscn` 씬**), 노드의 상속 계층, **노드와 리소스의 구분**(리소스는 기본이 공유 · 커스텀 `Resource` 와 `.tres`)와
**씬 트리가 정하는 것과 정하지 않는 것** — 트리는 좌표 상속·함께 지워짐·생명주기 순서를 정하지만 🔑 **충돌은 정하지 않는다.** 충돌은 **물리 공간(space)** 에서 일어나므로 **트리에서 어디에 있든 부딪힌다**(플레이어를 `Main` 자식 / `Geometry` 자식 / 무관한 가지에 각각 두고 잰 실측이 **소수점까지 같다**). 충돌 성립 3조건과 `collision_layer`(내가 입은 옷) vs `collision_mask`(내가 쓴 안경). 🔍 **물리 바디는 자격과 형체가 따로다** — `CharacterBody3D` → `PhysicsBody3D` → `CollisionObject3D` 상속이라 **태어날 때부터 물리 바디이고 물리 공간에도 등록되지만 모양이 하나도 없어** 아무것과도 안 부딪히고, **`CollisionShape3D` 는 옵션을 켜는 것이 아니라 빈 몸에 형체를 넣어 주는 것**이다(CSG 와 방향이 정반대 — 보이는 것→물리 vs 물리←넣어 준 모양. 그래서 한쪽엔 스위치가 있고 다른 쪽엔 없다). ⚠️ 단 **내 몸을 조립하는 것은 직속 부모를 따진다** — 중간에 `Node3D` 를 끼우면 **등록 shape 이 0** 이 되어 뚫고 떨어진다(실측). **누구와 부딪히는가는 트리와 무관하지만, 내 몸을 이루는 부품은 직속 부모에게만 붙는다.**
**그 구분이 인스펙터에서 나타나는 형태** — `MeshInstance3D` 의 프로퍼티는 `mesh`·`skeleton`·`skin`
**셋뿐**이라 **`Size` 가 인스펙터에 없고 `Scale` 만 보이는** 일이 생긴다. `Size` 는 `BoxMesh` **리소스**의
것이라 `Mesh` 슬롯을 **클릭해 펼쳐야** 나오며, `CSGBox3D` 는 **노드 자체가 `size` 를 가져** 바로 보이므로
CSG 로 벽을 만들다 `MeshInstance3D` 로 넘어가는 순간 걸린다(소속 대조표 · 상속 계층은 엔진 확인).
🛑 **크기를 `Scale` 로 대신하지 않는다** — 화면 결과는 같지만 자식에 전파되고, 비균등 스케일이 노멀을
왜곡해 조명이 어긋나며, 콜리전에서 동작이 달라진다(**메시의 크기는 메시에서, 노드의 배치는 Transform 에서**).
같은 "씬"이라는 말이 가리키는 **세 가지**(씬 파일 = 설계도 / 씬 인스턴스 = 실체 /
SceneTree = 실행 중인 트리). 여기에 **트리 맨 위의 노드는 씬이 아니라 루트 노드**라는 절이
붙는다 — **씬은 루트 노드와 그 아래 전부를 묶은 것**이고 트리에서 짚고 있는 그 한 노드는
**루트 노드**다(에디터 UI 문자열 `Create Root Node:`·`Make Scene Root`·`A root node is required to save the scene.` 로 확인). 🛑 **`root` 가 두 곳에서 쓰이는 함정** —
**`get_tree().root` 는 엔진이 자동으로 얹는 `Window` 이지 내 씬의 루트가 아니고**, 내 씬의 루트는 **`get_tree().current_scene`**(doctool 확인 — `root` 는 `type="Window"`,
`current_scene` 은 `type="Node"`). **루트 노드만 다른 점 4가지**(씬마다 정확히 하나 · `owner` 가 `null` · `.tscn` 에 `parent=` 가 없다 · `scene_file_path` 가 채워진다 — 실측)와
**`instantiate()` 가 돌려주는 것도 루트 노드**라서 **씬의 타입은 루트 노드 타입이 정한다**는 것(`Node3D` 면 3D, `Control` 이면 UI — 나중에 못 바꾼다). 중심은 **인스턴싱** — 왜 필요한지 3가지, 에디터 방법
(체인 버튼 `Instantiate Child Scene`·**Cmd+Shift+A**·드래그), 코드 방법 3단계, 그리고
**"메모리에 올린다"의 정확한 의미를 4단계로 분해**한다 — ① `.tscn` 은 설계도일 뿐
② `load()` 는 설계도를 메모리로 읽을 뿐 **아직 노드 0개** ③ `instantiate()` 에서 **비로소
`Node` 들이 생성**되지만 트리 밖이라 화면에 없음 ④ `add_child()` 로 트리에 연결해야 표시됨.
여기에 **반대 방향인 `Save Branch as Scene...`** 이 붙는다 — 이미 현재 씬 안에서 만든 노드
묶음(= **브랜치**: 루트가 아닌 노드 하나와 그 자손 전부)을 **독립 `.tscn` 으로 떼어내고 그 자리를
인스턴스로 교체**하는 기능. `.tscn` 텍스트가 **자식 노드 나열 → `ext_resource` + `instance=ExtResource(...)`
두 줄**로 줄어드는 실측, 저장 대화상자의 **`Reset Position` 이 기본 켜짐**(새 씬 안에서만 원점이 되고 원본
씬의 인스턴스는 원래 위치·시그널·`%` 고유 이름을 유지)이라는 것, `Save Scene As...`·`Duplicate`·
`New Inherited Scene...`·`Make Local` 과의 차이표, **엔진이 거부하는 5가지 경우**(루트 노드 · 인스턴스 ·
인스턴스의 자식 · 상속 씬의 일부 · 2개 이상 선택)를 엔진 메시지 그대로 싣고, **공식 문서 링크**를 단다
(이 메뉴를 이름으로 설명한 페이지는 3.2 UI 튜토리얼뿐이고 4.x 문서에는 없다).
**단계별 "존재하는 것 / 화면에 보이나 / `_ready` 불렸나" 대조표**와 흐름도로 보이고,
**엔진 실행 결과로 검증**한다(`instantiate()` 직후 `is_inside_tree=false`,
`_ready` 는 `add_child()` 안에서 호출, `preload` 와 `load` 는 같은 리소스 객체).
거기서 나오는 규칙 3가지(전역 좌표는 `add_child()` 뒤에, 일반 변수는 앞에),
`preload`/`load` 비교, `extends` 가 정하는 것, **생명주기 호출 순서와 자식이 먼저
`_ready` 되는 이유**, **`pass`(§4)** — 스크립트를 붙이면 템플릿에 딸려 나오는 그것이
**"아무 일도 하지 않는 문장"이고 `return` 과 달리 함수를 끝내지 않는다**는 것
(엔진 확인 — `pass` 뒤 줄은 실행되고 `return` 뒤는 죽은 코드다), **있는 이유는
GDScript 가 빈 블록을 문법 오류로 보기 때문**(`Expected indented block after function
declaration`)이라 **자리를 채우는 문장**이며 코드를 쓰면 지운다는 것, 그리고
**`pass` 만 있는 함수가 `null` 을 반환하는 건 `pass` 때문이 아니라 끝까지 도달해서**라는 것,
**GDScript 문법의 기초(§4)** — **왕초보가 코드가 무엇을 하는지 이전에 막히는 것들**을 실측으로 답한다. 🔑 **블록은 들여쓰기로만 정해진다**(중괄호가 없다 · 줄 끝 `:` 은 블록 시작 표시 · 빈 블록은 오류라 `pass` 를 넣는다). **들여쓰기는 마음대로 해도 되는가** — **탭·스페이스 4칸·2칸·1칸이 전부 통과**하지만 🛑 **한 파일에서 섞으면 오류**(`Used space character for indentation instead of tab as used before in the file.`), 같은 블록인데 깊이가 다르면 `Expected statement, found "Indent"`. **Godot 에디터 기본은 탭**이라 그냥 쓰면 맞고, **웹에서 복사해 붙일 때 섞인다**(`Edit > Indentation > Convert Indent to Tabs`). **`:=` 가 무엇인가** — 변수 선언 3가지(`var a = 1` / `var b := 1` / `var c: int = 1`)의 차이는 **나중에 다른 타입을 넣을 수 있는가**이고, **`:=` 는 값에서 타입을 정해 고정한다**(실측 — `1`→`int`, `1.0`→`float`, `"글자"`→`String`, `Vector3(…)`→`Vector3`. **소수점 하나로 갈린다**). 고정하면 `Cannot assign a value of type "String" as "int".` 로 **실행 전에 실수를 잡는다**. 🛑 **`var a: int := 1` 은 문법 오류**이고, ⚠️ **`int` 변수에 `2.7` 을 넣으면 경고 없이 `2` 로 잘린다**(실측). `const` 와 `var` 의 차이, `#`/`##` 주석, `-> void`, **`and`·`or`·`not`(`&&`·`||`·`!` 가 아니다)**, 줄 끝 `;` 불필요. **시그널(§5)** — 노드가 서로를 직접 부르지 않고 알리는 메커니즘이자
옵저버 패턴의 엔진 구현. **직접 호출과 나란히 놓고 왜 결합도가 문제인지**부터 보이고
(적이 UI 경로를 알면 재사용도 테스트도 불가능해진다), 내장/커스텀 두 종류가 **사용법이
완전히 같다**는 것과 **엔진에서 센 실제 개수**(`Node` 13 · `Area3D` 25 · **`BaseButton` 33**),
**Godot 4 에서 시그널이 문자열이 아니라 `Signal` 타입의 "값"이라는 것**
(`typeof` 확인 결과 포함 — 그래서 `hit.emit()` 처럼 점을 찍고, 옛 `emit_signal("hit")` 과 달리
**오타를 그 자리에서 잡아 준다**), `emit()`/`connect()` 와 **함수에 괄호를 붙이면 안 되는 이유**,
**에디터 연결 상세** — Signals 탭이 **상속 계층별로 그룹**되는 이유, 연결 대화상자의
네 칸(From Signal / Connect to Script / **Receiver Method** / Advanced), **함수 이름 자동
생성 규칙**(`_on_` + 보내는 노드 이름 + 시그널 — **자기 자신에게 연결하면 노드 이름이
빠진다**), 그리고 **연결이 코드가 아니라 `.tscn` 에 저장된다**는 것
(`[connection signal="..." from="..." to="..." method="..."]` — 실제 저장 형식 확인,
**`CONNECT_PERSIST` 를 준 것만 저장되고 에디터 연결이 그 플래그를 쓴다**).
**스크립트를 읽어도 연결 코드가 없어서 왜 불리는지 알 수 없는 것이 가장 큰 함정**이고,
**함수 왼쪽 초록 아이콘**이 그 표시라는 것. 이어서 **받는 함수를 뭐라고 부르는가** —
**에디터 UI 의 공식 명칭은 `Receiver Method`(수신 메서드)**, **API 상의 타입은 `Callable`**,
콜백·이벤트 핸들러는 통용되지만 **"시그널 함수"는 시그널 자체와 헷갈리므로 권하지 않는다**,
`_on_` 은 문법이 아니라 관례라는 것.
그리고 **엔진에서 확인한 실제 동작 4가지** — 여러 개를 연결하면 **연결한 순서대로** 불리고,
**듣는 사람이 0명이어도 오류가 아니며**, **같은 함수를 두 번 연결하면 거부된다**
(반환값 `31` = `ERR_INVALID_PARAMETER` — 노드 풀링·재사용에서 실제로 걸리므로
`is_connected()` 로 방어), `CONNECT_ONE_SHOT` 은 1회 호출 후 **연결 수가 0이 된다**.
마지막으로 **`await` 로 시그널을 기다리는 것**(실행 순서를 찍어 **emit 이 대기 중인 함수를
그 자리에서 재개시킨다**는 것을 보인다)과 **방향 규칙 — 통지는 시그널로 위로, 명령은 직접
호출로 아래로**. 이어서 에디터 4개 독의 역할과 단축키, `res://`·`user://`,
**메뉴 항목 하나하나와 각 에디터 뷰의 화면을 정리한 별도 Google 문서 링크**(§6 — 이 절은 뼈대만 세우고, 항목 단위로 찾을 때는 그쪽을 본다),
**에디터 조작을 손에 맞추는 절(§7)** — 먼저 **궤도 회전과 프리룩을 가른다**
(**궤도 회전은 한 점을 중심으로 그 주위를 도는 것 — 물체를 손에 들고 돌려 보는 것**,
**프리룩은 제자리에서 방향만 바꾸는 것 — 서서 고개를 돌리는 것**, **팬은 회전이 아니라
방향을 유지한 채 평행 이동**). 그다음 Godot 기본 조작이 **"오른손 마우스 + 3버튼"을
전제**하므로 벗어나면 **일부 기능이 아예 동작하지 않는다는 것**. **Magic Mouse 처럼
가운데 버튼이 없으면 궤도 회전과 팬이 되지 않고**, 해법은
`Editors > 3D > Navigation` 의 **Emulate 3 Button Mouse**(Option+좌클릭으로 대체)와
**Navigation Scheme 을 Maya 로**(Alt 조합 기반이라 3버튼 없는 마우스에 맞는다),
그리고 **4.7.2 에 실재함을 확인한** `orbit_mouse_button`/`pan_mouse_button`/
`zoom_mouse_button` 개별 지정. **마우스를 왼손에 두면 오른손이 키보드 우측에 있으므로
프리룩 WASD 가 겹친다** — `Shortcuts` 탭에서 `freelook` 검색 후 **IJKL**(권장, 화살표는
Scene 독과 문맥 충돌) 또는 화살표로 옮기되 **기존 키를 지우고 교체한다**(첫 바인딩만
인식되는 동작이 보고됨). **macOS 는 시스템 설정에서 보조 클릭이 꺼져 있으면 우클릭이
안 되어 프리룩이 시작조차 되지 않는다.** 마지막으로 **에디터 설정과 게임 조작은 완전히
별개**라는 것 — 게임은 `InputMap` 액션으로만 접근하고(`Input.is_key_pressed` 금지),
리바인딩 API(`action_erase_events`/`action_add_event`/`action_get_events`/
`load_from_project_settings`, 4.7.2 시그니처 확인)와 **`keycode` 가 아니라
`physical_keycode` 를 써야 자판 배열이 달라도 같은 자리를 가리킨다**는 것.
끝으로 **따라 만들어 볼 동영상 강좌 4개(§8)** — ① **비주얼 에디터만으로 3시간 만에 첫 게임**
(Godot 4.7 완전 초보 라이브 트레이닝 · 다루는 항목이 §1~§7 과 그대로 겹쳐 절 대응표를 붙였다),
② **안드로이드용 Godot 편집기**로 바닥·카메라·조명·하늘부터 집을 짓는 3분짜리 4편 시리즈
(BoxMesh 벽 → CSG 문·창문 → 박공지붕 · **모바일에서 제작할 때만**),
③ 에셋 임포트와 잔디·물·하늘로 만드는 **3D 워킹 시뮬레이터** 시리즈,
④ **CSG 로 도로를 프로토타이핑 → Blender 로 내보내 Shrinkwrap 으로 지형 → Godot 재임포트**
왕복 전 과정(타임스탬프 표 포함 · **라리엔 3D 의 블록아웃과 가장 가깝다**) —
과 다음에 읽을 문서 안내를 담는다. 강좌의 값·구조는 그대로 옮기지 않는다는 경고를 함께 둔다
(카메라·조명·성능 예산은 SSOT 와 `performance-mobile.md` §0 이 정한다).

### [example.md](references/example.md) — 예제: 빈 프로젝트에서 캐릭터가 움직이기까지 ★ 손으로 한 번 만들어 본다

**`basics.md` 가 개념이라면 이쪽은 실습이다.** 빈 3D 프로젝트에서 시작해
**바닥 위를 화살표 키로 걸어다니는 캐릭터**까지를 **8단계**로 만든다.
에디터 조작을 단축키까지 적었고, **왜 그렇게 하는지**와 **틀리면 어떤 화면이 나오는지**를
함께 담았다. 값은 전부 엔진에서 확인했다(기본값은 doctool, 화면은 실제 렌더 비교,
이동 수치는 실행해서 좌표를 찍음).

| 단계 | 내용 | 여기서만 다루는 것 |
|---|---|---|
| 1 | 씬 만들고 저장 | 씬의 타입은 **루트 노드가 정하고 나중에 못 바꾼다** |
| **2** | **환경 — 🛑 태양을 만들지 않는다** | **광원 0개로도 형태가 다 보인다**는 렌더 비교 5조건(A~E)과 A12 실측(라이트맵 1.0 / 실시간 22.3 / **광원 0개 60.0 fps**). **⋮ 메뉴로 만들지 않으면 화면이 납작해진다** — `Environment.background_mode` 기본값이 `BG_CLEAR_COLOR`(하늘 없음)라, 손으로 추가하면 하늘이 안 붙는다. **입체를 만든 건 태양이 아니라 하늘**이라는 것(광원 수를 0으로 고정한 채 `background_mode` 만 바꿔 확인). `ambient=DISABLED` 를 **미리 켜면 새까매지는** 이유(정점 색을 구운 뒤에 켜는 값이다) |
| **3** | **바닥 (CSG)** | `CSGBox3D` 원점은 **중심** → 윗면을 `y=0` 에 맞추려면 `y=-0.5`. 맵 제작 5방식 비교. 🖱 **숫자를 일일이 넣지 않고 마우스로 하는 법** — CSG 도형의 **면 핸들은 `Scale` 이 아니라 `Size` 를 직접 바꾸고**(소스 확인: `set_size()` · Undo 이름 `Change CSG Box Size`), **`Y` 로 스냅을 켜면 핸들 드래그에도 스냅이 걸려** 값이 정수로 떨어진다(`Transform > Configure Snap...` 의 `Translate Snap` = 1m). **`Alt` + 핸들이면 중심 고정 대칭, 그냥 끌면 반대편 면 고정**이라 `Position` 이 따라 움직인다. 🛑 **`R`(Scale Mode)로 늘리면 `Scale` 이 바뀐다** — 면 핸들과 구분한다. 3D 뷰포트 단축키표(Q·W·E·R·V·**Y**·T·B·PageDown, 소스 확인) |
| **4** | **플레이어 씬** | 🔍 **`Size` 가 인스펙터에 없고 `Scale` 만 보이는 이유** — `MeshInstance3D` 의 프로퍼티는 `mesh`·`skeleton`·`skin` 셋뿐이고 `Size` 는 **`BoxMesh` 리소스**의 것이라 슬롯을 **클릭해 펼쳐야** 나온다. `CSGBox3D` 는 **노드가 `size` 를 직접 가져** 바로 보이므로 그 차이에서 걸린다. 🛑 **크기를 `Scale` 로 대신하지 않는 이유 3가지** |
| **5** | **카메라** | 🔑 **카메라는 광원이 아니다** — `Light3D` 를 한 번도 만들지 않고 카메라만 바꾼 렌더 3조건(**없으면 단색 화면** / 넣으면 정상 / **멀리 옮겨도 명암은 그대로**). 누가 무엇을 정하는지 역할표. `(0,12,12)`·`-45°` 의 시야 계산과 **`y`·`z` 를 같게 유지하면 각도 고정 · 줌만** |
| **6** | **스크립트 2개 — ★ 코드를 한 줄씩 100% 뜯어본다** | 🔑 먼저 **이름에는 세 종류가 있다** — **① 엔진이 정한 것**(`velocity`·`_physics_process`·`move_and_slide`·`is_on_floor`·`Input`·`Vector3`·`x`/`y`/`z` — 🛑 못 바꾼다), **② 내가 정하되 엔진과 약속한 것**(`"ui_accept"` 같은 액션 이름 — 양쪽 철자만 같으면 된다), **③ 순수하게 내 것**(`SPEED`·`dir`·`input`·`delta`·`_mesh` — 마음대로). 그다음 요소별 상세 — **`_physics_process` 는 내가 부르지 않고 엔진이 부르는 콜백**이라 **철자를 틀리면 오류도 경고도 없이 조용히 안 불린다**(`_process` 와의 주기 차이, `delta` 를 곱하는 이유), **`is_on_floor()` 는 `move_and_slide()` 가 기록한 값을 읽을 뿐**이라 `_ready()` 에서는 항상 `false` 이고 🛑 **땅속으로 꺼져 떨어지는 것은 감지하지 못한다**(닿은 게 없으니 계속 `false` — `global_position.y` 를 직접 검사하는 낙사·리스폰 코드 제공), **`velocity` 는 `CharacterBody3D` 의 `Vector3` 프로퍼티**라 `move_and_slide()` 가 그 이름을 읽으므로 바꿀 수 없고 `.x`/`.y`/`.z` 는 `Vector3` 의 성분 이름이며 **통째로 대입하면 중력이 지워진다**(`+=` 와 `=` 의 차이), **`Input` 은 엔진 싱글턴**(`is_action_pressed` vs `just_pressed` — `just_` 를 빼면 하늘로 날아간다), **액션은 키 이름이 아니라 이름표**라 코드가 키를 모르고(기본 `ui_*` 70여 개와 실제 키 바인딩 표 · 내 액션 만드는 법), **`dir` 은 순수하게 내가 지은 `Vector3`**(`Vector2` → `Vector3` 로 축이 느는 그림 · `y=0` 인 이유), `move_toward`·`look_at`·`move_and_slide()`(Godot 3 와 달리 **인자 없음**). 🛑 **`$` 는 이름으로 찾으므로 노드 이름을 바꾸면 코드가 깨진다** — 실제로 `Player` → `PlayerCharacter` 로 바꿨더니 `Invalid access to property 'global_position' on a base object of type 'null instance'` 가 났다(**오류가 `global_position` 을 가리켜 좌표 문제처럼 보이지만 진짜 원인은 앞줄의 `$` 경로**). 노드를 잡는 세 방법 비교 — `$`/`%` 는 이름이 바뀌면 깨지고 **`@export var` 만 안 깨진다**. **`global_position`** 은 월드 원점 기준 절대 좌표라 **부모가 다른 노드끼리 위치를 더하거나 비교할 때 반드시 쓴다**(`position` 은 부모 기준 · 로컬/전역 대응표 · `look_at()` 이 월드 좌표를 받는다는 것 · 대입하면 엔진이 역산해 준다). **이름 앞의 밑줄은 문법이 아니라 관습**이며 🔑 **붙는 자리가 세 군데인데 뜻이 전부 다르다** — `var _mesh`(내부용 표시 · **떼어도 됨**) / `func _physics_process`(엔진 콜백 · **떼면 안 불림**) / `func _process(_delta)`(안 쓰는 인자 · **떼면 경고**). 밑줄은 `position`·`name` 같은 **엔진 멤버를 가리는 사고도 막아 준다**. **`_mesh` 와 `$Mesh` 는 다른 것** — 왼쪽은 마음대로, 오른쪽은 씬 노드 이름을 따라가야 한다. `main.gd` 도 같은 방식으로 — `_process` 를 쓰는 이유, **`_delta` 앞 밑줄의 뜻**, `global_position` 과 `position` 의 차이, **회전을 코드로 건드리지 않아 각도가 안 틀어진다**는 것, 두 스크립트 대조표. ⏱ **한 틱 동안의 전체 흐름 5단계**(①중력 ②점프 ③입력→방향 ④방향→수평속도 ⑤`move_and_slide()`) — **①②는 `y` 만, ④는 `x`·`z` 만 건드려 서로 간섭하지 않으므로 순서를 신경 쓸 필요가 없고, 🛑 `move_and_slide()` 만 맨 마지막이어야 한다**(먼저 부르면 그 틱의 속도가 반영되지 않는다). **틱 단위 실측 시나리오 3개** — 낙하 시 `velocity.y` 가 매 틱 `0.163`(=9.8×0.0167)씩 **쌓이고**(`+=` 가 가속), 걷기는 `-5.00` 으로 **일정**하며(`=` 가 등속), **벽에 붙으면 키를 누르고 있어도 `velocity` 가 `0`** 이다 — 🔑 **`velocity` 는 내가 원하는 속도를 쓰는 칸이자 엔진이 실제 결과를 돌려주는 칸**이라는 증거. 두 스크립트가 **플레이어의 `global_position` 이라는 공통 지점**을 통해 만나는 그림과 물리 틱(60Hz 고정) vs 렌더 프레임(주사율)의 관계. 📜 **주석 완전판** — 두 파일 전체에 파일 머리 블록(붙는 자리·기대하는 씬 구조·좌표 규약)과 함수·블록·줄 단위 주석을 붙인 것으로, **그대로 복사해 쓸 수 있고 코드 설명을 요청받았을 때의 표준 형식**이다. 이어서 ⌨ **화살표 키가 이동으로 바뀌기까지 4단계**(키 → 액션 이름 → `Vector2` → 월드 `Vector3`). **`ui_up` 이 `negative_y` 자리인 이유**(화면 좌표계는 위가 음수)와 **화면 위쪽이 월드 `-Z` 와 맞아떨어지는 것은 카메라 yaw 가 0 이기 때문**(돌리면 `transform.basis` 변환이 필요해진다). 키별 대응표와 **실측 — 대각선도 정확히 5.000 m/s**(`get_vector()` 가 정규화. 손으로 조합하면 √2 배 빨라진다). `velocity` 를 통째로 대입하면 **중력이 지워져 공중에 뜬다**. 🛑 **스크립트를 `player.tscn` 루트에 붙인다** — 실제로 여기서 막혔고, 안 붙이면 **이동뿐 아니라 중력도 안 받아 공중에 뜬다.** 기존 파일은 **`Load`** 로 붙인다(`Attach Script` 는 코드를 덮어쓴다) |
| 7 | 메인 씬 지정·실행 | 조작이 화살표인 이유(기본 InputMap), WASD 로 바꿔도 **코드는 그대로** |
| **8** | **벽 추가** | **좌표를 외우지 않고 세우는 법** — `Size` 세 숫자의 축 의미, 방향 규약(`-Z`=북), **평면도·측면도 그림**, 벽 4개를 "어느 방향으로 길어야 하나"부터 하나씩 유도. **`y=1.5` 는 높이의 절반**, **바닥만 `y` 가 음수**인 이유. 자주 틀리는 5가지(동쪽 벽에 북쪽 `Size` 를 그대로 넣어 **얇은 판이 누움** 등). 🛑 **벽을 `Node3D` 로 묶으면 보이는데 통과한다** — `CSGCombiner3D` 는 자식 중 `CSGShape3D` 계열만 CSG 트리에 넣으므로 평범한 `Node3D` 가 끼면 그 아래는 **콜리전에서 통째로 빠지고**, 그런데도 각 도형이 **자기 자신을 독립 CSG 루트로 렌더해 화면에는 보인다**. 엔진 실측 — `Node3D` 로 묶으면 AABB `(12,1,12)`·정점 **36**(바닥뿐), `CSGCombiner3D` 로 바꾸면 `(13,4,13)`·정점 **228**. 고치는 법은 `Change Type...` 으로 `CSGCombiner3D`(그룹 유지) 또는 `Reparent...`. **왜 그런지는 엔진 규칙 3개로 설명한다**(소스 인용) — ① **루트는 부모가 CSG 가 아닌 도형**(`is_root_shape()` 는 `!parent_shape` 이고 `parent_shape` 는 부모를 `CSGShape3D` 로 캐스팅한 결과다. 부모가 CSG 면 자식은 **`set_base(RID())` 로 자기 렌더를 끈다**), ② **자식 순회에서 CSG 가 아니면 `continue`** — 그 아래로 내려가지 않는다, ③ **콜리전은 루트만 만든다**(`if (!is_root_shape()) return;` — 자식에서 `use_collision` 을 켜도 무시). 그래서 `Node3D` 아래 벽은 **각자 루트가 되어 스스로 그려지지만**(보인다) `use_collision` 기본값이 `false` 라 콜리전이 없다(통과한다). **벽마다 `use_collision` 을 켜면 막히기는 하지만**(실측 확인) `Geometry` 의 형상에 벽이 없어 **`bake_static_mesh()` 때 벽이 통째로 빠지고** Subtraction 도 안 걸리므로 쓰지 않는다. `Debug > Visible Collision Shapes` 로 눈으로 확인한다. 🔑 **충돌은 씬 트리가 아니라 물리 공간에서 일어난다** — 플레이어를 `Main` 자식 / `Geometry` 자식 / 무관한 가지에 각각 두고 재니 **소수점까지 같은 결과**(트리 위치 무관). 충돌 성립 3조건과 `collision_layer`(입은 옷) vs `collision_mask`(쓴 안경). ⚠️ 단 **내 몸을 조립하는 것은 직속 부모를 따진다** — `CharacterBody3D` 는 `CollisionObject3D` 상속이라 **몸은 있는데 모양이 0개**이고 `CollisionShape3D` 는 스위치가 아니라 **형체를 공급하는 도우미 노드**라 **중간에 `Node3D` 가 끼면 등록 shape 이 0** 이 된다(실측). **CSG 와 정반대 구조**(보이는 것→물리 vs 물리←넣어 준 모양)이지만 **함정은 똑같다** |

마지막에 **검증표**(`y=1.0` 정착 · ↑1초 `z=-5.0` · 광원 0 · CSG AABB)와
**증상별 진단표 17줄**(꿈쩍 안 함 / 바닥 뚫음 / 납작함 / 새까맘 / 하늘만 보임 /
`Size` 없음 / 대각선만 빠름 / 공중에서 멈춤 …), 그리고 **CSG 블록아웃 → bake →
정점 색 굽기** 로 넘어가는 다음 단계를 담는다.

**`/godot init` 으로 설치되는 `/godot-example` 명령이 이 문서를 정본으로 삼는다.**

### [lsp.md](references/lsp.md) — Godot LSP 정적 검증 ★ 코드 작성 시 필수

Godot 에디터가 127.0.0.1:6005에 노출하는 GDScript Language Server를 이용해 게임을
실행하지 않고 문법·타입 오류와 경고를 잡는 방법을 다룬다. 번들 스크립트
`scripts/gdscript_lsp.py`의 다섯 가지 명령(`diagnose`로 오류 진단, `symbols`로 파일
구조 파악, `hover`로 타입 확인, `definition`으로 정의 위치 조회, `complete`로 자동완성)
사용법과 종료 코드, git 변경분 일괄 검증(`--changed`), JSON 출력을 설명한다. 또한
`UNUSED_VARIABLE`·`SHADOWED_GLOBAL_IDENTIFIER`·`UNSAFE_CAST` 등 GDScript 경고 30여 종의
의미와 대응, `project.godot`의 경고 수준 설정(0=무시/1=경고/2=오류 승격), 정적 타입
가드레일, LSP 프로토콜 상세(0-based 좌표 주의), DAP(6006) 디버깅, VS Code 연동,
그리고 LSP로 잡히지 않는 것(런타임 null, 노드 경로 오타, 논리 오류)을 정리한다.

### [gdscript.md](references/gdscript.md) — GDScript 2.0 언어 전체

GDScript 문법 전부를 다룬다. 정적 타입 선언과 타입 추론(`:=`), `Array[T]`·
`Dictionary[K,V]` 타입 컨테이너, 팩드 배열, `class_name`과 상속, `@abstract`(4.5+)
추상 클래스/메서드, 가변 인자(`...args`), `when` 패턴 가드, 모든 `@export_*` 어노테이션
목록과 인스펙터 표시 방법, 시그널 선언·연결·플래그(`CONNECT_DEFERRED`/`ONE_SHOT`),
`await`와 코루틴, 람다와 `Callable`, `match` 패턴 매칭, setter/getter, 정적 변수와
`_static_init()`, `#region` 코드 접기, `##` 문서 주석, 그리고 생명주기 콜백
(`_init`/`_enter_tree`/`_ready`/`_process`/`_physics_process`/`_input`/`_exit_tree`)의
정확한 호출 순서를 코드와 함께 설명한다. **복사 3단계**(`duplicate()` / `duplicate(true)` /
`duplicate_deep()`)도 여기서 다룬다 — `duplicate(true)`는 중첩 배열·딕셔너리는 복사하지만
**그 안의 `Resource`는 원본과 공유**하므로 "깊은 복사"가 아니며, 이 때문에 추가된
`duplicate_deep()`과 `DEEP_DUPLICATE_NONE`/`INTERNAL`(기본)/`ALL` 모드의 차이를
실측 결과와 함께 설명한다. GDScript를 한 줄이라도 쓰기 전에 읽는다.

### [nodes-scenes.md](references/nodes-scenes.md) — 노드·씬·SceneTree 아키텍처

씬 파일(`.tscn`)과 씬 인스턴스, `SceneTree`의 차이를 먼저 구분한다. 3D 개발에 필요한
노드 상속 계층, 노드 참조 방법 6가지 비교(`$`, `%` 고유 이름, `@export NodePath`,
`@export Node`, `get_node_or_null`, 그룹), 씬 인스턴싱과 초기 데이터 전달 패턴,
`PackedScene.pack()`과 `owner`의 의미, 씬 전환과 `load_threaded_request()` 기반 비동기
로딩 화면 구현, 오토로드(싱글턴) 등록·사용 원칙과 이벤트 버스 패턴, 그룹
(`call_group`/`call_group_flags`), `queue_free()`와 `is_instance_valid()`, 오브젝트 풀링,
`process_mode` 5종과 일시정지 처리, 시그널 기반 컴포넌트 조합을 다룬다. 마지막으로
로직 종류별 배치 위치와 파일 경로를 정리한 역할 분리 표, 그리고 **스크립트를 씬 옆에
두는 폴더 구조 규범**(엔진의 Attach Script 기본 경로, 씬-스크립트 1:1 결합, 파일명 충돌
세 가지 근거와 `autoload/`·`scripts/` 예외, 에셋 배치까지 포함한 전체 구조)을 담는다.

### [3d-core.md](references/3d-core.md) — Node3D·Transform3D·카메라

3D 공간의 기초 전부를 다룬다. Godot 좌표계 규약(-Z forward, +Y up, 오른손 좌표계),
`Transform3D`와 `Basis`의 내부 구조 및 축 벡터의 의미, 로컬(`position`/`transform`)과
글로벌(`global_position`/`global_transform`)의 차이, 오일러를 쓰지 말아야 하는 세 가지
이유(회전 순서 의존·짐벌락·보간 왜곡), 짐벌락 없는 FPS 카메라 회전 패턴과 3인칭 노드
분리 방식, `look_at`의 up 벡터 함정과 안전한 래퍼, 내적·외적을 이용한 시야·좌우 판정,
`Quaternion.slerp`와 프레임레이트 독립 지수 감쇠 보간, `orthonormalized()`가 필요한 이유,
벡터 연산 실전, `Camera3D`의 투영·FOV·near/far 설정과 `unproject_position`·
`project_ray_normal`을 이용한 HUD 마커와 마우스 피킹, `SpringArm3D` 3인칭 카메라 완성
코드, `MeshInstance3D` 머티리얼 개별화와 가시성·LOD 제어를 코드로 설명한다.

### [physics-3d.md](references/physics-3d.md) — Jolt Physics와 3D 물리

이 프로젝트가 쓰는 Jolt Physics 기준으로 3D 물리 전체를 설명한다. 물리 서버가 별도
고정 틱으로 도는 구조, 4가지 충돌체(`Area3D`·`StaticBody3D`·`RigidBody3D`·
`CharacterBody3D`)의 선택 기준, `collision_layer`/`collision_mask` 비트마스크 설계법과
히트박스/허트박스 패턴, 콜리전 셰이프 성능 순위, **에디터의 `Mesh > Create Collision
Shape...` 6가지 타입**(4.6 신규 `Primitive`가 박스·구·실린더·캡슐 메시를 대응 셰이프로
자동 변환 — 단 에디터 전용이라 코드 API에는 없으며 직접 매핑 코드를 제공), glTF 접미사
자동 생성(`-col`/`-convcol`/`-colonly`), `CharacterBody3D`의 전체 속성표(`motion_mode`·`floor_max_angle`·
`floor_snap_length`·`platform_on_leave` 등)와 상태 조회 메서드, 코요테 타임·점프 버퍼·
하강 중력 가중을 포함한 1인칭 컨트롤러 완성 코드, 카메라 기준 이동과 모델 회전을 분리한
3인칭 컨트롤러 완성 코드, `move_and_collide`와 `KinematicCollision3D`, `RigidBody3D`의 힘·
임펄스·`_integrate_forces`·`freeze`·폭발 구현, `Area3D` 트리거와 중력 오버라이드,
`RayCast3D`/`ShapeCast3D`, `PhysicsDirectSpaceState3D` 직접 질의, 조인트, **Jolt가 4.4의
실험 옵션에서 4.7의 정식 기본 엔진이 된 경위와 기존 프로젝트는 자동 전환되지 않는다는
점**, Jolt 고유 차이와 `physics/jolt_physics_3d/*` 설정 전체(엔진에서 확인한 실제 키와
기본값 — 솔버 반복, 슬립 임계값, CCD, `max_bodies` 한계, `enable_ray_cast_face_index`),
물리 보간과 터널링 방지를 다룬다.

### [rendering-3d.md](references/rendering-3d.md) — 렌더러·머티리얼·조명·환경

Forward+/Mobile/Compatibility 렌더러의 기능 지원표와 Mobile에서 하지 말아야 할 것을 먼저
정리한다. `StandardMaterial3D`의 모든 속성 그룹(Transparency 5종 비교와 선택 가이드,
Shading 모드, Albedo/Metallic/Roughness PBR, Emission, Normal Map, Rim, Clearcoat(4.7 개선),
Anisotropy, AO, Height, Backlight, Refraction, Detail, UV1/UV2 Triplanar, Billboard, Grow,
Proximity/Distance Fade, Stencil, Render Priority)과 각 옵션의 성능 비용, 머티리얼 코드
조작과 `set_instance_shader_parameter()`로 배칭을 유지하는 방법, 피격 플래시·`next_pass`
외곽선 실전 코드, `DirectionalLight3D`/`OmniLight3D`/`SpotLight3D`/`AreaLight3D`(4.7 신규)
속성과 `light_bake_mode`, shadow bias·normal bias·PSSM split 튜닝과 모바일 그림자 최적화,
`LightmapGI` 베이킹 절차와 실패 원인, `ReflectionProbe`와 box projection,
**스텐실 버퍼**(4.5+ — `stencil_mode`의 `OUTLINE`/`XRAY` 프리셋과 `CUSTOM` 조합,
플래그·비교·참조값 전체, **벽 너머 캐릭터 보이기** 구현, Mobile 렌더러에서도 동작하며
투명 패스로 넘어가는 비용과 그리는 순서 함정), **4.7에서 전면 재작성된 SSR**(`ssr_enabled`·`ssr_max_steps`·`ssr_depth_tolerance`와
`screen_space_reflection/half_size` 해상도 설정 — 단 **Forward+ 전용이라 이 프로젝트에서는
동작하지 않는다**), `WorldEnvironment`의 톤매퍼·Glow·Fog·색보정, `Decal` 탄흔 배치,
파티클(**4.7 축별 스케일·3D 회전** — `use_scale_3d`/`use_rotation_3d`/
`use_rotation_velocity_3d` 세 플래그가 모두 기본 꺼져 있는 함정, 기존 float 방식과의
차이, 빌보드에서는 효과가 안 보이는 이유), 렌더 레이어와 `SubViewport` 활용을 설명한다.

### [animation-3d.md](references/animation-3d.md) — 애니메이션 시스템

**`BoneConstraint3D` 계열(4.6+)** — `AimModifier3D`·`CopyTransformModifier3D`·
`ConvertTransformModifier3D`로 본을 다른 본에 묶는 방법과 인덱스 기반 설정 API 포함.

Animation·AnimationPlayer·AnimationTree의 3계층 구조를 먼저 구분한다. `AnimationPlayer`의
트랙 종류와 Call Method Track으로 공격 판정 타이밍을 애니메이션에 위임하는 방법,
`callback_mode_process`를 물리 프레임으로 두어야 하는 이유, **RESET 애니메이션이 블렌딩의
전제 조건인 이유**, `AnimationTree` 구성 요소 전체 — `AnimationNodeStateMachine`
(Immediate/Sync/AtEnd 전환, Advance Condition vs Advance Expression, `travel()` A* 경로
탐색), `BlendSpace1D`/`BlendSpace2D`(Sync Mode 4종으로 발 맞춤 해결, Blend Mode 3종),
`BlendTree`, 상하체 분리를 위한 `Blend2` 필터, `OneShot` 요청/중단, `TimeSeek`, `TimeScale`,
`Transition`, `Add2` — 을 `animation_tree["parameters/..."]`로 제어하는 방법, 파라미터 경로
상수화, Root Motion 추출과 상태별 혼합 전략, `Skeleton3D` 본 조작과 `SkeletonModifier3D`
기반 절차적 조준, `BoneAttachment3D` 무기 장착, 래그돌, `Tween`과 4.7 신규 `tween_await()`,
glTF 애니메이션 임포트와 후처리 스크립트, 콤보·히트스톱을 포함한 3인칭 캐릭터 애니메이터
완성 코드를 담는다.

### [navigation-3d.md](references/navigation-3d.md) — 길찾기와 적 AI

**전용 2D 내비게이션 서버 분리(4.6+)와 비동기 리전 처리**(기본 켜짐)도 다룬다.

`NavigationServer3D` 기반 길찾기 전체를 다룬다. 서버가 물리 프레임에 비동기 동기화되므로
첫 프레임에 경로를 요청하면 안 되는 이유, `NavigationRegion3D`와 `NavigationMesh` 베이킹
파라미터 전체표(agent radius/height/max climb/max slope, cell size)와 설정 원칙,
콜라이더 기반 베이킹, `NavigationAgent3D`의 모든 속성(경로 탐색 12종, 회피 9종)과 메서드·
시그널, `get_next_path_position()`을 프레임당 한 번만 호출해야 하는 이유, 목표 갱신 빈도를
제한한 추적 AI 완성 코드, RVO 회피의 두 단계 흐름(`set_velocity` → `velocity_computed`
콜백에서 `move_and_slide`)과 파라미터 튜닝, `NavigationObstacle3D`와 `carve_navigation_mesh`,
`NavigationLink3D`로 점프·사다리 구현, `navigation_layers` 비트마스크, `NavigationServer3D`
직접 질의(경로 계산·랜덤 위치·도달 가능 여부), 런타임 재베이킹과 값싼 대안, `AStar3D`와의
선택 기준, 그리고 감지/상실 반경 분리·시야각·레이캐스트 2단계 검사를 포함한 상태 머신
기반 적 AI 완성 코드를 설명한다.

### [input-ui.md](references/input-ui.md) — 입력 처리와 Control UI

입력 파이프라인(`_input` → `_gui_input` → `_shortcut_input` → `_unhandled_key_input` →
`_unhandled_input`)의 호출 순서와 목적별 콜백 선택 기준, `set_input_as_handled()`의 사용
시점을 설명한다. `InputMap` 액션 정의와 `physical_keycode`를 써야 하는 이유,
`Input.get_vector()`가 대각선 정규화와 데드존을 처리하는 방식, `InputEvent` 계층 전체와
`relative` vs `screen_relative`의 차이, 마우스 캡처 관리와 알트탭 대응, 게임패드 연결
감지와 입력 장치 자동 전환, **4.7 장치 ID 상수**(`DEVICE_ID_KEYBOARD`=16 /
`DEVICE_ID_MOUSE`=32 / 게임패드는 0부터 — 터치도 0이라 겹치는 함정 포함),
**창 미포커스 시 게임패드 입력 무시 설정**(`joypads/ignore_joypad_on_unfocused_application`,
기본 꺼짐), 키 리바인딩 저장/로드를 다룬다. **4.7 내장 `VirtualJoystick` 노드는 전체
API를 담았다** — 프로퍼티 11종과 기본값·범위, `JoystickMode`/`VisibilityMode` 열거형,
시그널 5종(`pressed`/`released`/`tapped`/`flicked`/`flick_canceled`), StyleBox 테마 4종,
**출력값을 읽는 API가 없고 InputMap 액션에 강도를 주입하는 설계**, 조이스틱 벡터를 카메라
yaw 기준 월드 방향으로 변환하는 3D 이동 코드, 그리고 함정 6가지(Control 크기를 안 잡으면
터치가 안 먹힘, 기본 액션이 `ui_*`, 미등록 액션 에러, `deadzone_ratio` 기본 0 등).
UI 쪽은 `Control` 앵커/오프셋/프리셋/`size_flags`, **`mouse_filter`가 게임 입력을 막는
문제**, 컨테이너 12종, `Theme`와 `StyleBox`, **`RichTextLabel`과 BBCode**(`bbcode_enabled`,
`append_text()`, 4.7 `em` 단위로 폰트 크기에 맞춰 자동 조정되는 `[img]` 이미지, `[img]`
옵션 전체와 픽셀/`em`/`%` 단위 비교, `add_image()`는 픽셀만 받는 제약, 유저 입력 BBCode
이스케이프), 3D 게임의 `CanvasLayer` 구성과 일시정지 메뉴, 화면 스트레치 설정, 모바일
세이프 에어리어, `Label3D`와 `SubViewport` 기반 월드 스페이스 UI, 게임패드 UI 내비게이션을
코드와 함께 설명한다.

> **HUD·메뉴·버튼을 실제로 만드는 작업 절차는 [hud-menu.md](references/hud-menu.md) 에 있다.**
> 이 문서는 속성과 API 의 정의를, 그쪽은 화면을 조립하는 순서를 담는다.

### [hud-menu.md](references/hud-menu.md) — HUD·메뉴·버튼 만들기 (화면 UI 조립)

**input-ui.md 가 Control API 레퍼런스라면 이 문서는 화면을 조립하는 작업 절차다.**
먼저 이 프로젝트의 화면이 **모바일 세로 1080×1920(`orientation=1` = `SCREEN_PORTRAIT`)과
데스크톱 가로 1920×1080 두 가지**라는 전제를 실제 `project.godot` 값으로 확인하고,
종횡비가 뒤집히므로 좌표 배치가 반드시 깨진다는 것을 숫자로 보인다. UI 의 네 기둥
(`Control`·`Container`·`Theme`·`CanvasLayer`)을 **"없으면 무엇이 깨지는가"**로 설명하고,
`CanvasLayer.layer`(기본 `1`)를 HUD 1 / 창 5 / 모달 10 / 로딩 100 으로 나누는 층 설계를
제시한다. **작업 순서를 앵커 → 컨테이너 → Theme → 시그널 넷으로 고정**하고, 프리셋 16종
중 실제로 쓰는 것, `size_flags` 6종(`SIZE_EXPAND_FILL`=3 이 주력, `Label`만
`size_flags_vertical` 기본이 `4`), **컨테이너 안에서 `position` 이 무시되는 이유와 대신
쓰는 4가지 수단**(`separation`·`MarginContainer`·`custom_minimum_size`·`stretch_ratio`),
컨테이너 9종 선택표를 담는다. **노드별 `mouse_filter` 실측 기본값 표가 핵심이다** —
`Control`·`PanelContainer` 는 `0`(STOP)이라 화면을 덮는 순간 터치를 전부 삼키고,
`Label`·`NinePatchRect` 는 `2`(IGNORE), `TextureRect`·`TextureProgressBar` 는 `1`(PASS)로
서로 다르다. **"화면을 눌렀는데 캐릭터가 안 움직인다"의 원인 1순위**가 이것이다.
실전으로는 세로 화면 기준 라리엔 HUD 씬 구조(정보는 위 / 조작은 아래, 왼손 이동 ·
오른손 전투), 에디터 조작 8단계, **서버 권위를 지키는 체력바 코드**(HP 는 서버 스냅샷이
올 때만 갱신하고 클라가 계산하지 않는다), `%UniqueName` 접근, 메인 메뉴·일시정지
(`PROCESS_MODE_WHEN_PAUSED`)와 **온라인 게임이라 `get_tree().paused` 로 월드를 멈출 수
없다는 함정**, `Theme` 3층 우선순위(개별 오버라이드가 이긴다)와 `.tres` 만드는 절차,
`StyleBoxFlat` 실측 기본값(`border_width`·`shadow_size` 가 `0` 이라 기본은 테두리도
그림자도 없다)과 버튼 4상태, 타입 배리에이션, 세로 1080px 기준 폰트 크기표를 다룬다.
모바일 필수 3가지는 **세이프 에어리어**(`DisplayServer.get_display_safe_area()` 적용
코드 — 에디터에서는 검증되지 않고 실기기에서만 확인된다), **터치 최소 48dp(1080px 폭에서
100~120px)**, **엄지 영역**(하단 1/3 은 손가락이 덮으므로 읽을 글자를 두지 않는다)이다.
3D 특유의 함정으로 월드 스페이스 UI 3종의 비용 비교(**AOI 82개에 `SubViewport` UI 를
붙이면 예산이 끝난다 — 이름표는 `Label3D`**)와 **카메라 yaw 고정 덕에 미니맵을 회전시킬
필요가 없다는 점**, 성능 규칙(`_process` 에서 `Label.text` 를 매 프레임 바꾸지 않는다),
자주 하는 실수 표, 공식 문서·데모·커뮤니티 자료 링크를 담는다.

**공식 권장값과 대조한 결과도 담았다** — Godot 공식 문서의 플랫폼별 stretch 조합표
(모바일 세로 = 기준 720×1280 또는 고사양 1080×1920 + `canvas_items` + `expand`)와
이 프로젝트 설정이 일치하지만 **기준이 고사양 쪽 값이라 720 폭 저사양 폰에서 UI 가
0.67 배로 축소된다**는 함의, stretch mode 3종·aspect 5종 선택표(공식 문서가 GUI 에
"대개 최선"이라 적은 `keep_width` 포함), 세로·가로 양쪽 지원의 두 방법(정사각형 기준
vs 현재의 `.mobile` 오버라이드) 비교, 런타임 UI 배율 `content_scale_factor`,
**앵커와 컨테이너는 같은 노드에 함께 쓸 수 없다는 것**(컨테이너 자식은 `Layout` 메뉴가
잠긴다 — "화면에 붙이는 것은 앵커, 그 안을 채우는 것은 컨테이너"), 컨테이너 중첩 깊이
비용과 `ScrollContainer` 실측값(`follow_focus` 기본 `false`, 터치 드래그는
`emulate_mouse_from_touch` 에 의존), **StyleBox 는 4개가 아니라 5개**(`focus` 포함)이며
빠뜨린 상태는 조용히 기본 테마로 돌아간다는 것과 `Duplicate` 로 5상태를 만드는 순서를
다룬다. **§9 폰트는 한글이 먼저다** — 내장 폰트에 한글 글리프가 없어 □ 가 뜨는 것,
CJK 폰트가 15~20MB 라 SSOT 번들 용량 규칙과 정면으로 부딪치는 것, 해법 3가지(`SystemFont`
기기 내장 = 0MB / 서브셋 1~3MB / 통째), `Font.fallbacks` 폴백 체인, **MSDF 는 저사양
모바일에서 렌더링 기본 비용이 올라 이 프로젝트에서는 켜지 않는다**(엔진 기본값이 이미
`false`), 대신 **축소 렌더링 때문에 폰트 밉맵을 켜는 것을 검토**해야 한다는 것,
3D 위 글자의 외곽선을 담는다. **§10 재사용 컴포넌트**는 `@tool` + `class_name` +
`@export` setter 조합과 `Engine.is_editor_hint()` 가드, `is_node_ready()` 검사,
`Editable Children` 을 피해야 하는 이유를 다룬다. **§11 UI 애니메이션**은 `Tween` 의
`set_ease`/`set_trans`, 겹칠 때 `kill()`, **4.7 오프셋 변환**(`offset_transform_enabled`
기본 `false`, `offset_transform_visual_only` 기본 `true` — 레이아웃 재계산도 터치 판정도
건드리지 않고 흔들 수 있다), `layer = 100` 페이드 전환을 담는다. **§13.4 는 세로 화면의
`Camera3D.keep_aspect` 함정**이다 — 실측 기본값이 `KEEP_HEIGHT` 라 9:16 에서 좌우 시야가
좁아지고 공식 문서도 세로에서는 `Keep Width` 를 권하지만, **SSOT §6 의 줌 상한 ↔ AOI
계약 계산이 가로 해상도 기준이라 사람의 판단이 필요하다**고 명시한다. **§15 접근성**은
4.5 AccessKit 통합으로 `Control` 에 들어온 `accessibility_name`/`description`/`live` 등
실측 속성과, 아이콘 버튼부터 채우라는 우선순위를 담는다.

### [resources-assets.md](references/resources-assets.md) — 리소스와 에셋 임포트

`Resource`의 개념과 **참조 공유 규칙**(같은 경로를 여러 번 `load()`하면 같은 인스턴스),
`duplicate()`와 `resource_local_to_scene`으로 개별화하는 방법을 먼저 다룬다.
**§3 은 맵 설정·카메라 설정처럼 "미리 정의해 두는 정적 정보"를 `.tres` 로 빼는 방법**을
독립해 다룬다 — 개체 데이터(아이템 100종)와 구성 데이터(맵마다 하나)의 구분,
**`const` 로 두면 맵이 둘이 되는 순간 막히는 이유**와 판단 기준표,
`@export_group` 으로 인스펙터를 접는 정의 패턴, 그리고 엔진 실측으로 확인한 함정들 —
**🛑 선언 기본값과 같은 값은 명시적으로 대입해도 `.tres` 에 저장되지 않는다**(그래서
기본값은 운영 맵 값이 아니라 **작고 안전한 폴백**으로 잡아야 파일에 그 맵의 값이 남는다),
**로드 순서가 `_init()` → setter** 라 `_init()` 에서 다른 프로퍼티를 읽으면 기본값만 보인다는 것,
**setter 가 손으로 고친 `.tres` 의 범위 밖 값까지 막아 준다**는 것(`hp = 99999` → `100`),
**`@export var` 에 대입해도 `changed` 가 저절로 나가지 않아 setter 에서 `emit_changed()` 를
직접 불러야 한다**는 것. 이어 `assert` 대신 문제 목록을 돌려주는 **`validate()` 패턴**과
`_get_configuration_warnings()` 연동, 파생값을 프로퍼티가 아닌 **메서드로 계산**하는 이유,
`@export` 로 끼워 쓰는 쪽 코드, **로드된 설정이 공유되므로 런타임에 고치면 안 된다**는 것,
헤드리스에서 `ResourceSaver` 로 `.tres` 를 찍어내는 스크립트(폴더가 없으면
`ERR_CANT_OPEN`(19), 새 `class_name` 은 `--import` 를 한 번 돌려야 인식),
그리고 **`.res` 가 항상 작지 않다는 실측**(작은 설정 208B vs 380B, 문자열 2천개 24,200B vs
34,345B — 설정·데이터는 `.tres` 를 쓴다)을 담는다.
**`duplicate(true)`의 한계와 `duplicate_deep()`** — `Array`/`Dictionary` 프로퍼티 안에
담긴 하위 리소스는 `duplicate(true)`로 복제되지 않으므로 인벤토리·스킬 목록처럼 리소스를
배열에 담는 구조에서 반드시 걸린다. 복제 범위 3단계와 언제 `ALL`을 피해야 하는지 포함. 커스텀
`Resource` 클래스로 아이템·무기 데이터를 정의하고 `.tres`로 밸런싱하는 패턴, 폴더 스캔
자동 등록과 `.remap` 처리, `preload`/`load`/`load_threaded_request()`의 차이와 로딩 화면
구현, `ResourceUID`와 `.import` 시스템, 3D 모델 임포트 옵션 전체표와 콜리전 자동 생성
접미사, `EditorScenePostImport` 후처리 스크립트, Blender 작업 규칙 6가지, 텍스처 압축 모드
비교와 플랫폼별 실제 포맷·모바일 권장 크기·ORM 채널 패킹, 오디오 임포트(3D는 반드시 모노),
`user://` 세이브 파일의 JSON·이진·암호화 저장과 버전 마이그레이션 완성 코드, `ConfigFile`
설정 관리와 `linear_to_db()` 볼륨 변환, `FileAccess`/`DirAccess` API를 담는다.

### [audio.md](references/audio.md) — 3D 오디오

플레이어·버스·서버의 3계층 구조와 "개별 볼륨 대신 버스로 카테고리를 나눈다"는 설계 원칙을
먼저 세운다. `AudioStreamPlayer` 3종의 차이, `volume_db`와 선형 값 변환,
`AudioStreamPlayer3D`의 공간 설정(감쇠 모델 4종, `unit_size`/`max_distance` 소리별 권장값,
지향성, 공기 흡수, 도플러, `area_mask`), `Area3D` 리버브 존으로 동굴 울림을 자동 적용하는
방법, 권장 버스 구조와 `AudioServer` API, 버스 이펙트 15종과 Master 리미터 필수 이유,
물속 저역 통과 필터 전환 코드, `AudioStreamRandomizer`로 반복감을 없애는
`PLAYBACK_RANDOM_NO_REPEATS`, 3D 플레이어 풀링과 크로스페이드 BGM을 포함한 오디오 매니저
오토로드 완성 코드, `AudioStreamInteractive`·`AudioStreamSynchronized`(4.3+) 기반 인터랙티브
뮤직, 지연(latency)과 정확한 재생 위치 계산, 모바일 오디오 7가지 주의사항을 담는다.

### [shaders-3d.md](references/shaders-3d.md) — 셰이더

`vertex()`/`fragment()`/`light()`의 실행 시점과 "계산을 `vertex()`로 옮긴다"는 성능 원칙을
먼저 세운다. `shader_type spatial` 기본 구조와 `varying`, `render_mode` 전체 목록(블렌딩·
뎁스·컬링·조명 모델·기타), 내장 변수 전체 목록(전역·vertex·fragment)과 `SCREEN_TEXTURE`·
`DEPTH_TEXTURE`를 4.x에서 uniform으로 선언하는 방법, `uniform`과 `hint_*`·필터·반복 옵션,
**`instance uniform`으로 머티리얼 복제 없이 인스턴스별 값을 주는 방법**, 전역 uniform,
코드에서 파라미터 전달과 트윈 애니메이션을 설명한다. 실전 셰이더로 외곽선(툰), 디졸브,
홀로그램, 모바일 친화 물 표면, 삼중 평면 매핑, 인스턴스 uniform 피격 플래시, 정점 단계에서
처리하는 바람 식생, 프레넬 발광 8종의 전체 소스코드를 제공하고, `next_pass` 다중 패스,
셰이더 컴파일 스터터 대응(워밍업 코드 포함), 모바일에서 피해야 할 연산 10가지를 다룬다.
**스텐실은 `render_mode`가 아니라 독립 `stencil_mode` 구문**이라는 점과 플래그·비교 키워드
전체, 벽에 캐릭터 모양 구멍을 뚫는 2패스 셰이더 예제, 투명 패스 제약도 여기 있다.

### [performance-mobile.md](references/performance-mobile.md) — 최적화와 내보내기 ★ §0 먼저

**§0 이 최소 지원 사양(3GB RAM Android · Galaxy A12)과 실기기 실측값을 담는다.**
성능·조명·드로우콜을 판단하기 전에 **§0 을 먼저 읽는다** — 조명을 쓰지 않는 이유,
`MultiMesh` 가 선택이 아닌 이유, 폴리곤을 아끼지 않아도 되는 이유가 전부 실측으로 있다.

"측정 없이 최적화하지 않는다"는 원칙과 최적화 5단계 순서를 먼저 세운다. 해상도 테스트로
CPU/GPU 병목을 가르는 방법, `Performance` 모니터 전체 목록과 디버그 오버레이 완성 코드
(고아 노드로 누수 감지 포함), 프로파일러와 Visual Profiler 읽는 법, 드로우콜 상한과 줄이는
5가지 방법, 오버드로우, 메시 LOD와 `visibility_range`(HLOD)·`VisibleOnScreenEnabler3D`,
오클루전 컬링이 효과 있는 경우와 없는 경우, `MultiMeshInstance3D` 풀밭 완성 코드와 셰이더
연동·한계, 조명 비용 순위와 모바일 조명 전략·그림자 축소, CPU 최적화(타이머 분할·캐시·
`StringName`·시간 분할·`WorkerThreadPool` 스레드 안전 규칙), 물리 최적화, VRAM 예산과 메모리
누수 원인, 모바일 전용 렌더링 설정과 동적 해상도 스케일링·기기 등급 자동 감지, 기능 태그
오버라이드를 다룬다. **빌드·설치·실행·릴리즈 절차는 아래 export-build 문서로 분리했다.**

### [headless-workflow.md](references/headless-workflow.md) — 에디터 없이 작업하기 ★ 기본 작업 방식

에디터 GUI 를 열지 않고 **코드 작성 → LSP 검증 → 창 없는 검사 → 데스크톱 실행 → 실기기 확인**
까지 도는 개발 루프를 담는다. 기본 명령 6가지(`--quit-after` 는 초가 아니라 프레임이라는 점,
`--import --quit`, PNG 캡처 시 `RenderingServer.frame_post_draw` 대기), **`install.sh` 로
기기 ID 하나만 주면 Android·iOS 를 판별해 빌드·설치·실행까지 끝내는 방법**, `.ipa` 가
나오게 하는 iOS preset 다섯 값(`runnable`·`app_store_team_id`·`code_sign_identity_debug`·
`export_method_debug`·`export_project_only`)과 **Team ID 는 인증서 이름 괄호 안이 아니라
`OU=` 값이라는 함정**, 에디터 실행 버튼(`Cmd+B`)과 Remote Deploy 의 차이와 아이콘이 뜨는
전체 조건, 빌드 산출물이 `res://` 안에 있을 때 `.gdignore` 로 임포트를 막는 법을 다룬다.
**실행 버튼을 기기로 향하게 하는 설정은 없다** — 이 구분이 이 문서의 출발점이다.

### [export-build.md](references/export-build.md) — 빌드와 내보내기 (플랫폼 공통)

"export template 은 export 할 때만 필요하다"는 경계를 먼저 세운다. 데스크톱 실행·
`--headless` 검사·`--export-pack` 은 템플릿 0개로 돌고, 패키지를 만들 때 처음 필요해진다.
**엔진에서 직접 실측해 확정한 작업별 최소 필요 파일 판정표**가 핵심이다 — Android
테스트 APK 는 `android_debug.apk` 하나, Gradle 빌드는 `android_source.zip` 만, Windows 는
debug/release 가 서로 다른 파일을 쓴다. **템플릿이 없을 때 오류는 없는 파일을 전부
나열할 뿐 그게 필수 목록이 아니라는 함정**, `use_gradle_build` 한 값이 요구 파일을 통째로
가른다는 규칙, 4.7 의 에디터 선택 설치와 CLI TPZ 설치, `--export-debug`/`--export-release`/
`--export-pack`/`--export-patch`/`--install-android-build-template` 전체 규칙과 출력 경로·
종료 코드 판정, 오류 메시지 해석표, `export_presets.cfg` 포맷, **패치 PCK 배포와 4.6 델타
인코딩**(`--export-patch`/`--patches` CLI, Patching 탭 설정 전체,
`ProjectSettings.load_resource_pack()`으로 런타임 적용, 그리고 Base Packs가 런타임 로드
목록과 파일·순서까지 같아야 한다는 제약과 예전 버전 재익스포트 금지), 이 프로젝트에서
사람만 고칠 수 있는 파일의 경계를 담는다. 플랫폼별 상세는 아래 세 문서로 갈라진다.

### [export-build-android.md](references/export-build-android.md) — Android 빌드

테스트 APK 를 만들어 실기기에 설치·실행하고 Play 스토어 릴리즈까지 가는 전 과정.
JDK 17·Android SDK·에디터 경로 준비(`java_sdk_path` 가 비면 템플릿이 다 있어도 막힌다),
`--export-debug` 빌드 → `adb install -r` 설치 → `adb logcat -s godot` 로그의 반복 루프,
원클릭 배포와 원격 디버그·무선 디버깅, **debug keystore 는 Godot 이 자동 생성하므로
`keytool` 이 불필요**하다는 점과 서명 충돌 시 `adb uninstall`, 릴리즈 keystore 생성과
`GODOT_ANDROID_KEYSTORE_*` 환경변수 주입, `use_gradle_build`/`export_format` 으로 APK·AAB 를
가르는 판정표, GABE 와 `res://android/build/` 의 엔진 버전 종속, preset 옵션 전체,
권한 최소화, **네이티브 스플래시와 부트 스플래시의 이중 구조**(배경색을 맞추지 않으면 두 번
깜빡인다)를 담는다.

### [export-build-ios.md](references/export-build-ios.md) — iOS 빌드

Godot 이 `.ipa` 를 직접 만들지 않고 **Xcode 프로젝트까지만 내보내면 Xcode 가 서명·아카이브·
배포를 맡는 2단계 구조**를 먼저 세운다. macOS 전용이라는 제약, `ios.zip`·Xcode·Team ID·
프로비저닝 준비, `application/export_project_only` 값이 산출물을 가르는 규칙,
`xcrun simctl` 로 시뮬레이터에 설치·실행하는 절차와 `xcrun devicectl` 로 실기기에 올리는
절차, 기기 신뢰 설정과 무료 계정 7일 만료, Console.app·`log stream` 로그, `xcodebuild
archive` → `ExportOptions.plist` → `.ipa` → TestFlight 업로드, 그리고 **헤드리스에서 설정
오류 메시지가 빈 문자열로 나오는 실측 현상**과 그때 점검할 항목 순서를 담는다.

### [export-build-desktop.md](references/export-build-desktop.md) — macOS·Windows·Linux

데스크톱 3종의 테스트 실행과 Steam 배포용 릴리즈. 플랫폼별 필요 템플릿(macOS 는 debug·
release 가 `macos.zip` 하나를 공유하고, Windows·Linux 는 모드마다 파일이 다르다)과 어느
OS 에서 무엇을 크로스 빌드할 수 있는지, macOS 의 `universal` 아키텍처와 서명·공증
(notarization)·Gatekeeper `xattr` 우회, Windows 의 `embed_pck` 단일 실행 파일과 `print()`
를 보기 위한 `.console.exe`·코드 서명, Linux 실행 권한과 Steam Deck 대응(Mobile 렌더러가
유리한 이유), `exclude_filter` 로 빌드 산출물이 자기 자신에 들어가지 않게 막는 규칙,
d3d12·Mobile 렌더러 선택, GodotSteam 연동과 Steam 빌드 체크리스트, 크로스 플랫폼 빌드
스크립트를 담는다.

### [multiplayer.md](references/multiplayer.md) — 멀티플레이어

RPC·MultiplayerSpawner·MultiplayerSynchronizer 세 축과 피어 ID 규칙, "승패에 영향을 주는
것은 반드시 서버 권위로 한다"는 원칙을 먼저 세운다. `ENetMultiplayerPeer` 서버/클라이언트
생성과 시그널 처리를 포함한 네트워크 매니저 완성 코드, `@rpc` 어노테이션 4개 인자 전체
(`any_peer` 사용 시 서버 검증 필수, transfer_mode 선택 기준, 채널 분리), 노드 권한 설정과
`@export peer_id` setter 패턴, `MultiplayerSpawner`의 자동/커스텀 스폰과 노드 이름 일치
문제, `MultiplayerSynchronizer`의 Spawn/Sync/Watch 구분과 가시성 필터·입력 역방향 동기화,
서버 권위 플레이어 완성 코드(발사 요청의 3단계 검증 포함), 클라이언트 예측과 서버 화해
(reconciliation) 구현, 원격 플레이어 100ms 지연 보간, 입력 검증 체크리스트와 레이트
리미팅, 연결 끊김 처리, 에디터 다중 인스턴스 로컬 테스트를 담는다.

### [project-config.md](references/project-config.md) — 설정 파일 포맷과 CLI

Godot 파일이 전부 텍스트라는 설계와 직접 편집해도 되는 것/위험한 것을 먼저 구분한다.
`project.godot`의 INI 문법·전체 구조·섹션별 주요 설정 항목(application/display/physics/
rendering/debug)과 정적 타입을 강제하는 GDScript 경고 설정, 기능 태그 오버라이드
(`.mobile`·`.android`) 규칙과 우선순위, **`.tscn` 파일 포맷 전체** — `load_steps` 계산,
`[ext_resource]`/`[sub_resource]`/`[node]`/`[connection]` 블록, `parent`·`index`·
`unique_name_in_owner`, `Transform3D` 12개 인자의 의미, 값 표기법 — 을 직접 편집할 수
있을 만큼 상세히 다룬다. **`.tres` 포맷**은 헤더 필드 전체(`script_class`·`load_steps`·`uid`)와
**기본값과 같은 프로퍼티가 기록되지 않는 규칙**(그래서 파일이 비어 보여도 값이 없는 게 아니고,
적힌 줄은 전부 "기본값과 다른 값"이며, **선언 기본값을 바꾸면 저장 안 된 모든 `.tres` 가
조용히 따라 바뀐다**), 로드가 setter 를 거친다는 것, 중첩 리소스의 `[sub_resource]` 인라인과
공유가 필요하면 별도 파일로 빼야 한다는 것, **`.res` 가 이진인데도 더 큰 실측 수치**,
스크립트 일괄 밸런싱, `.import` 파일과 `.godot/`
캐시, `.gitignore`/`.gitattributes` 권장 설정과 커밋해야 할 것/안 될 것, `godot` CLI 옵션
전체(헤드리스·내보내기·디버그·유틸리티)와 CI 예시, `SceneTree` 상속 자동화 스크립트,
`ProjectSettings` 코드 API를 담는다.

### [ai-tooling.md](references/ai-tooling.md) — LSP·MCP·Codex 연동

AI가 Godot을 다룰 때 쓸 수 있는 네 개의 채널(파일·LSP·MCP·DAP)과 각자 볼 수 있는 것,
비용과 정보량의 반비례 관계, 알고 싶은 것별 채널 선택 결정표를 먼저 제시한다.
`godot-mcp`(TypeScript 서버 + GDScript 브리지)의 아키텍처와 **세 가지 캡처 모드**
(`debug_data` 신호·`mcp:` capture·에디터 API)의 원리, 도구 전체 목록(런타임 관찰·
브레이크포인트 디버깅·에디터 시점 에셋), 전형적 사용 흐름, 4.0~4.7 프로토콜 호환성.
`Open-Godot-MCP`(Python, ~35 도구 ~130 액션)의 도구 영역별 정리와 **결정론적 플레이테스트**
(`godot_game_time freeze`/`step`/`step_until`), `godot_lsp` 5개 액션, DAP 조건부 중단점의
평가 컨텍스트, 기본 포트. `GodexCLI`의 `#I`/`#F` 마커 인라인 생성과 요청 프로파일,
그리고 이 스킬이 채택한 GDScript 가드레일. **`Godot AI`(`godot_ai` 애드온, `mcp__godot-ai__*`)**
는 별도 서버 바이너리 없이 **에디터 플러그인 하나가 MCP 서버를 겸하는** 방식으로,
대표 도구(`node_create`·`scene_open`·`editor_screenshot`·`project_run`·`logs_read`)와
**에디터 프로세스(`plugin.gd`)와 게임 프로세스(`runtime/game_helper.gd` 오토로드)로
갈라지는 구조** — 후자는 **익스포트 빌드에 포함되므로 릴리즈 전에 끈다 —**, 그리고
Claude Code 쪽에서 `.claude/settings.json` 의 `enabledMcpjsonServers` 로 켜는 방법을 다룬다.
MCP 설정 파일, `@tool`에서 에디터 API를 쓸 때
타입 캐스트가 필요한 이유, eval 비활성화·읽기 전용 모드·네트워크 노출·프롬프트 인젝션
보안 주의사항을 다룬다.

### [editor-plugin.md](references/editor-plugin.md) — @tool과 EditorPlugin 개발

"에디터도 Godot으로 만든 앱"이라는 전제에서 시작해 `@tool` 스크립트와 `EditorPlugin`의
차이를 구분한다. `@tool`의 절대 규칙(`Engine.is_editor_hint()` 분기, 에디터에서 만든 노드의
`owner` 지정), 인스펙터 setter 반응과 `_validate_property`로 조건부 프로퍼티 숨기기,
`_get_configuration_warnings()`로 설정 누락 알리기. `plugin.cfg`와 `plugin.gd` 구조,
생명주기 콜백 전체, 플러그인이 등록할 수 있는 것 12종(커스텀 노드 타입·도크·하단 패널·
툴바·도구 메뉴·오토로드·임포트 플러그인·인스펙터 플러그인·3D 기즈모·디버거 플러그인)과
`_exit_tree()` 대칭 제거, 에디터 설정 vs 프로젝트 설정 구분과 `add_property_info()` 등록
패턴, `EditorInterface` API와 스크립트 에디터의 `CodeEdit` 접근·HiDPI 스케일. 실전 도구로
3D 뷰포트 클릭 배치 플러그인, 임포트 후처리, 헤드리스 씬 일괄 검증 스크립트, 커스텀 기즈모
전체 소스코드를 제공하고, **Undo/Redo 등록 규칙**을 설명한다.

### [whats-new.md](references/whats-new.md) — 최신 버전 신기능과 마이그레이션

**최신 Godot에서 새로 쓸 수 있게 된 것**을 영역별로 모으고, 기능마다 도입 버전을
표기한다. 현재 4.7 / 4.6 / 4.5를 다룬다. 3D 렌더링(`AreaLight3D` 신규 노드와 비용, HDR 출력, Clearcoat 개선, 파티클 3D
스케일/회전, **SSR 대개편 — Forward+ 전용이라 이 프로젝트엔 못 씀**, 포비티드 렌더링
최적화), 물리(**Jolt가 정식 기본 엔진화**, 방향 기반 일방향 충돌, Path3D 콜라이더 스냅),
애니메이션(`Tween.tween_await()` 예제, AnimationPlayer 트랙 집계), GUI(Control 오프셋 변환,
`DrawableTexture2D`, 원뿔형 그래디언트, **RichTextLabel `em` 단위 이미지 스케일**), 에디터(3D 정점
스냅·트랙볼 회전·카메라 추종·룰러 축별 길이, 2D 씬 페인터, MeshLibrary 에디터, CSG
Autosmooth, 인스펙터 복사/붙여넣기), Android(GABE Gradle, PiP, 커스텀 스플래시, Perfetto,
Java 인터페이스 구현), XR, 입력(**`VirtualJoystick` 내장 노드**, **게임패드 미포커스 무시
설정**, **키보드·마우스 장치 ID 상수**, iOS SDL3), 내보내기(선택적 템플릿
다운로드), 새 Asset Store를 다룬다. **4.6에서 들어와 4.7 노트만 보면 놓치기 쉬운 것**
(패치 PCK 델타 인코딩, 메시→프리미티브 콜리전 자동 생성)을 따로 모았고, 마지막으로
**이 프로젝트에 당장 쓸 수 있는 것**을
추리고, 4.6 이하에서 올릴 때의 마이그레이션 체크리스트(LSP 전체 진단 포함)를 제공한다.

### [asset-store.md](references/asset-store.md) — Asset Store와 애드온

남이 만든 에셋·애드온을 가져오는 경로와, **설치·활성화가 프로젝트에 정확히 무엇을
남기는가**를 다룬다. 4.7에서 AssetLib를 대체한 **새 Asset Store**(`store.godotengine.org`,
아직 beta)와 설치 전 확인할 4가지(4.7.x 호환성, 라이선스 전염, 소스 저장소 생존,
에디터 전용인지 런타임 포함인지), 설치 경로 3가지(AssetLib 탭 / `.zip` 수동 / git submodule).
후반부는 **`[editor_plugins]` 섹션의 정확한 의미** — `enabled`가 `plugin.cfg` 경로의
`PackedStringArray`이고 **여기 적힌 것만 에디터가 로드**하며, `Plugins` 탭 체크박스가
자동으로 써 넣는 값이라 **직접 편집하지 않는다**는 것 — 과 로드 순서
(`plugin.cfg` → `script=` → `@tool extends EditorPlugin` → `_enter_tree()`),
`plugin.cfg` 구조. 그리고 **가장 큰 함정** — 플러그인이 `add_autoload_singleton()`으로
`[autoload]`를 심으면 그 스크립트는 **게임 프로세스에서 돌고 익스포트 빌드에 포함된다**.
"에디터 전용이니 런타임 비용 0"이 아니라는 것과, 설치 후 무엇이 남았는지 확인하는
`grep` 절차를 제공한다.

### [level-design.md](references/level-design.md) — 맵 만들기

맵을 **무엇으로 만들 것인가**와 **어떤 구조에 담을 것인가**를 다룬다. 제작 방식 5가지
(**CSG 블록아웃** — 프로토타입 전용, **GridMap + MeshLibrary** — 던전·실내 모듈러,
**glTF 통째 임포트** — 확정된 아트, **씬 인스턴싱** — 소품, **지형** — 대규모 야외)를
"최종물로 쓸 수 있나" 기준으로 비교하고, **A(블록아웃) → B(GridMap) + D(프롭), 야외만 C**
라는 라리엔 3D 권장 경로를 카메라 피치 고정이라는 전제에서 근거와 함께 제시한다.
방식별 함정을 엔진 실측값으로 정리한다 — CSG `use_collision` 기본 `false`,
**GridMap `cell_size` 기본값이 `Vector3(2,2,2)`**(1m 아님)과 `bake_navigation` 기본 `false`,
**Godot 에 터레인 에디터가 내장돼 있지 않다**는 사실(`HeightMapShape3D`는 콜리전 셰이프일 뿐).
후반부는 씬 골격 — `Main` 아래 `WorldEnvironment`/`DirectionalLight3D`/**`Level`(교체 지점)**/
`Player`/`CameraRig` 구조와 `Level` 하위 `Geometry`·`NavigationRegion3D`·`Props`·`SpawnPoints`를
각각 왜 분리하는지 설명한 뒤, **빈 씬에서 그 뼈대까지 만드는 에디터 조작 5단계**(루트 이름
변경 → 뷰포트 툴바 **⋮**의 `Add Sun`/`Add Environment` → `Level` → `CSGCombiner3D`, 노드 4개)를
표로 제공한다 — **5단계 직후 `Use Collision` 을 켜지 않으면 벽을 통과한다**.
**쿼터뷰 카메라**는 `Level` 이 아닌 `Main` 아래에 두고 `Position (0,12,12)` ·
`Rotation (-45,0,0)` 을 직접 입력한다 — **`y`·`z` 를 같게 유지한 채 키우면 각도는 그대로 두고
줌아웃만 되므로**(피치 고정·줌 제한이라는 이 프로젝트 카메라 규범과 그대로 맞는다),
기본 `fov=75` 기준 시야 계산과 `Preview` 체크박스·`Current`·
`Transform > Align Transform with View` 사용법을 함께 담는다.
그다음 **문이 뚫린 12×12m 방을 상자 6개로 만드는 좌표표**(바닥 1 + 벽 4 + 문 1,
**헤드리스로 조립해 AABB 로 검증한 값**)와 **좌표가 전부 정수가 되는 규칙 3개**
(`CSGBox3D` 원점은 중심 → 벽 위치는 `±방크기/2`, `y` 는 높이의 절반, 바닥만 음수 /
**벽 두께를 `1` 로 잡는 것이 정수 좌표의 핵심**), 방 크기를 바꿀 때의 대응표,
그리고 **빼는 상자는 벽보다 두껍게** 잡아야 면이 깨끗이 뚫린다는 점을 담는다. 이어
`load_threaded_request()`·`load_threaded_get_status()`
(진행률 `Array` 인자, `THREAD_LOAD_*` 상수 4종) 기반 **맵 비동기 교체 전체 코드**를 제공한다.

### [openworld-3d.md](references/openworld-3d.md) — 오픈월드 만들기 ★ 넓은 야외 맵

**"맵 크기는 처음부터 최종값, 콘텐츠는 중앙부터 넓힌다"** 를 제1원칙으로 세우고,
그 근거를 **크기를 바꿔 가며 실제로 만들어 잰 측정**으로 제시한다 —
5m·50m·250m·1km 는 **상주 비율이 전부 100%** 라 스트리밍이 아무 일도 하지 않고,
4km 에서 6.2% 가 된다. 즉 **맵 크기는 연속적인 값이 아니라 계단**이며,
"5×5m 로 시작해 1m 씩 키운다"는 계획은 **1.25km 까지 아무것도 안 변하다가 그 뒤에
전부 다시 만들게 되는** 방식이다. 임계점이 1.25km 인 이유도 계산으로 보인다
(상주 상한 (2r+2)²=16개 ≤ 맵 청크 수여야 하므로 250m 청크 기준 한 축 5칸부터).
**비율 열을 단독으로 읽으면 안 된다는 경고**도 함께 둔다 — 상주 수는 관찰자가
청크 중심에 있는지 경계에 있는지에 따라 **9~16 사이를 오가고 그것이 정상**이라,
검증 기준을 9로 잡으면 멀쩡한 동작이 실패로 잡힌다.
규모별 필요 기법 표(~50m 무기법 / ~500m 시야·안개 / 1.25km~ 스트리밍 /
2km~ LOD·임포스터 / 100km~ floating origin)와 **float 정밀도 한계**(4km 에서 0.1mm,
16km 에서 0.5mm, 1mm 넘으면 위치가 끊긴다)를 계산 코드와 함께 담는다.
본론은 **지면 3층 구조** — 원경 평면 1장(드로우콜 1, **이것이 없으면 시야를 상주
범위보다 멀리 둘 수 없다**) + 상주 청크 (2r+1)² + `MultiMesh` 랜드마크 1 — 와
**청크 스트리밍 4장치**(상주 반경 · 경계 50m 전 미리 로딩 · 지연 해제 · 프레임 예산).
미리 로딩을 **예측 로직이 아니라 판정 중심을 미는 것**으로 구현하는 코드,
🛑 **순간이동 예외**(겹치지 않는 곳으로 건너뛰면 유예 없이 즉시 정리 — 없으면
존 이동마다 **메모리가 잠시 두 배**가 되고 그것이 최대 사용량이 된다),
**상한이 `(2r+1)²` 이 아니라 `(2r+2)²`** 라 검증 기준을 잘못 잡으면 정상 동작이
실패로 잡힌다는 것. 이어 **좁게 시작하는 법** — 크기가 아니라 `view_distance` 를
줄이면 안개가 앞을 덮어 작은 맵처럼 느껴지되 구조·좌표는 그대로다 — 와
**시야 거리는 카메라가 아니라 월드가 정한다**(`far` 와 안개가 어긋나면 잘린 지면이
그대로 보인다), `FOG_MODE_DEPTH` 로 바꾸면 `fog_density` 가 1.0 으로 재설정된다는 실측.
설정을 `Resource` 로 빼는 이유와 🛑 **폴백 기본값을 작은 맵으로 둬야 하는 이유**
(Godot 은 기본값과 같은 값을 `.tres` 에 저장하지 않아, 폴백이 4km 면 맵 파일에
크기가 기록조차 되지 않는다), `validate()` 로 설정을 스스로 검사하게 하는 패턴.
후반부는 **기물 흩기** — `MultiMesh`(개수와 무관하게 드로우콜 1) vs 개별
`MeshInstance3D`(모양이 달라야 할 때) 판단 기준과, **구를 노이즈로 찌그러뜨려 바위를
만드는 프로시저럴 메시 전체 코드** 및 함정 3가지(**방향으로 노이즈를 뽑아야** UV
이음매가 안 갈라진다 / `FastNoiseLite` 기본 `frequency` 가 **0.01** 이라 방향을 10배로
벌려야 한다 / **노멀을 다시 계산**하지 않으면 모양은 울퉁불퉁한데 조명은 매끈한 구로
계산돼 형태가 안 보인다), 거부 샘플링 배치와 **반지름에 제곱근을 취해야 밀도가 고른**
이유. 마지막으로 **검증** — **스트리밍은 잘 돌 때 화면에 아무 일도 일어나지 않으므로**
플레이어를 옮겨 놓고 상주 청크가 따라오는지를 숫자로 확인해야 하고, 대기는 프레임 수가
아니라 **누적 시간**으로 세야 하며(헤드리스는 프레임이 훨씬 빨리 돈다), 헤드리스에서는
**드로우콜과 `MultiMesh` 트랜스폼을 잴 수 없다**(더미 렌더러 · 버퍼가 렌더링 서버에 있다)는
것과 그 대안. **실제로 걸린 함정 8가지**(원점 기물이 스폰을 가리는데 검증은 전부 통과 /
`specular` 는 3.x 이름이라 조용히 무시 / 이름 없는 노드가 `@CollisionShape3D@2` 가 되어
경로로 못 찾음 / 원경 평면 z-fighting / `floor()` 가 Variant 반환 / `_process` 의
`await` 가 SceneTree 를 즉시 종료시킴 / `_initialize` 에서 노드 접근 불가 /
**HUD 외곽선이 드로우콜 68개**를 먹어 3D 전체(11개)보다 8배 비쌌던 것)와 성능 실측치를 담는다.

### [dictionary.md](references/dictionary.md) — 용어집

**맨 앞에 분류별 목차**가 있어 찾아보는 문서로 쓴다. Godot 문서·에디터 UI·다른 참조 문서에 그대로 나오는 용어를 **뜻 → 왜 그렇게 부르는가 →
라리엔 3D 에서 실제로 어떻게 쓰는가** 순으로 정리한다. "이름은 봤는데 무엇인지 모르겠는"
상태를 없애는 것이 목적이다. 현재 **CSG**(Constructive Solid Geometry, 구성적 입체 기하 —
불리언 3연산 `OPERATION_UNION`/`INTERSECTION`/`SUBTRACTION`, 엔진에서 확인한 CSG 노드 계층과
각 프리미티브 기본값, **`use_collision` 기본값이 `false`** 라 켜지 않으면 벽을 통과하는 함정),
**블록아웃**(blockout·그레이박싱 — 회색 상자로 구조·동선·크기감을 먼저 짜는 단계와 그 이유),
**방**(room — 집의 방이 아니라 **맵의 구획 단위**. 연습 기준 치수 **12×12m ≈ 43평**과
**현실보다 훨씬 크게 잡아야 하는 이유** 3가지, 그리고 **실내는 방+복도 / 야외는 넓은 바닥+
지형 기복+경계 산맥**으로 구조가 완전히 갈린다는 것),
**"CSG 블록아웃"**(둘을 합친 말 — 구멍을 뚫을 수 있는 건 CSG 뿐이라 표준이 된 이유,
`MeshInstance3D`·`GridMap` 과의 비교표, 실제 씬 구조 예시),
**피치·요·롤**(카메라 회전 3축 — **yaw 는 도리도리, pitch 는 끄덕임, roll 은 갸웃**이고
**줌은 회전이 아니라는 것**, `rotation` 의 `(x,y,z)` 가 곧 (pitch, yaw, roll) 이라는 것,
고정 시점 게임에서 **피치가 yaw 보다 비싼 이유**),
**텍스처**(**3D 모델의 표면을 통째로 벗겨 펼쳐 만든 이미지**라는 것 — 종이 상자를
갈라 펼치는 비유, 펼치는 작업이 **UV 언랩**이고 축이 X·Y·Z 와 겹치지 않게 **U·V** 로
불린다는 것, UV1 과 **라이트맵 전용 UV2** 의 구분, **"맵"은 담긴 내용의 종류를 가리키는
말**일 뿐이라 컬러맵·노멀맵·러프니스맵이 전부 그냥 이미지라는 것과 `StandardMaterial3D`
대응 속성표. **왜 파일이 커지는가를 실측으로 답한다** — 256×256 PNG 를 직접 만들어
재보니 **단색 761B / 큰 영역 4개 817B / 픽셀마다 다른 실사 87,743B** 로 **115배** 차이가
난다. 그래서 **텍스처가 큰 이유는 3D 가 아니라 실사**이며, 단색이면 `albedo_color` 하나로
**0 바이트**다. *"좌표 범위 + 색상만 적으면 되지 않나"* 라는 자연스러운 의문에 **그것이
벡터 그래픽(SVG)이고 게임에 안 쓰는 이유 둘**로 답한다 — 실사는 영역으로 안 나뉘어
오히려 커지고, **GPU 는 픽셀을 직접 읽도록 회로가 박힌 하드웨어**다.
**128px·256px 은 화면 크기가 아니라 이미지 자체의 픽셀 수**이고 2K·4K 와 같은 단위이며,
**변이 2배면 넓이가 4배**라 용량이 가파르다는 것(해상도별 ASTC 용량표). 마지막으로
용량을 줄이는 세 수단 — **타일링**(512px 을 8번 반복해 4096px 상당 벽을 64KB 로),
**아틀라스 공유**, **단색 0바이트** — 과 **타일링이야말로 "좌표 범위 지정" 직관의
UV 판 구현**이라는 것, 그리고 **카메라 3축 고정 덕에 건물이 화면에서 최대 500px 를
넘지 않아 2K 텍스처가 필요 없다**는 계산),
**노멀**(법선 — 면이 향한 방향이고 **조명 밝기가 전적으로 여기 달려 있다**는 것,
**같은 메시가 각져/매끄럽게 보이는 차이**가 플랫·스무스 셰이딩이라는 것과 CSG `smooth_faces`·
`autosmooth` 기본값),
**노멀맵**(RGB 가 노멀의 XYZ 라서 **연보라색인 이유**, 그리고 **실루엣은 안 바뀐다**는 한계),
**하이폴리·로우폴리·베이킹**("하이폴리에서 구워 로우폴리에 입힌다"의 3단계 흐름,
모바일에서 디테일을 확보하는 사실상 유일한 방법인 이유, **`normal_enabled` 기본값이
`false`** 라 텍스처만 넣으면 아무 일도 안 일어나는 함정, OpenGL/DirectX 규약 차이,
그리고 **"굽는다"가 노멀맵·CSG·라이트맵 세 군데에서 다른 것을 가리킨다**는 정리),
그리고 **CSG 는 최종물이 아니라는
제약**(런타임 CPU 실시간 계산 → `bake_static_mesh()`/`bake_collision_shape()` 로 굳히고
CSG 노드를 삭제하는 흐름)을 다룬다.

## 번들 스크립트

### scripts/gdscript_lsp.py

Godot LSP 클라이언트. **Python 표준 라이브러리만 사용**하므로 설치가 필요 없다.

```bash
python3 .claude/skills/godot/scripts/gdscript_lsp.py ping                      # 연결 확인
python3 .claude/skills/godot/scripts/gdscript_lsp.py diagnose res://a.gd       # 진단
python3 .claude/skills/godot/scripts/gdscript_lsp.py diagnose --changed        # git 변경분 전체
python3 .claude/skills/godot/scripts/gdscript_lsp.py --json diagnose --changed # JSON 출력
python3 .claude/skills/godot/scripts/gdscript_lsp.py symbols res://a.gd        # 파일 구조
python3 .claude/skills/godot/scripts/gdscript_lsp.py hover res://a.gd 42 10    # 타입 정보
python3 .claude/skills/godot/scripts/gdscript_lsp.py definition res://a.gd 42 10
python3 .claude/skills/godot/scripts/gdscript_lsp.py complete res://a.gd 42 10
```

Godot 에디터가 실행 중이어야 한다. 상세 사용법은 [references/lsp.md](references/lsp.md).

### scripts/install.sh

**빌드·설치·실행 스크립트.** 그냥 실행하면 **지금 쓸 수 있는 장치를 번호로 보여주고**,
번호를 고르면 그 플랫폼으로 빌드·설치·실행까지 한다. macOS·iOS·Android 를 한 입구에서
다룬다. preset 이름·패키지 ID·산출물 경로는 `export_presets.cfg` 에서 직접 읽으므로
프로젝트마다 고쳐 쓸 필요가 없다.

```bash
.claude/skills/godot/scripts/install.sh          # 장치 목록 → 번호 입력
.claude/skills/godot/scripts/install.sh --list   # 목록만 보고 끝
.claude/skills/godot/scripts/install.sh 1        # 1번을 바로 선택
```

```
사용 가능한 장치:

  1)  macOS     이 맥에서 실행 (arm64)
  2)  iOS       JaeHo16 — iPhone 16 Pro Max (iPhone17,2)
                67BD02AA-6E29-53D7-A5CE-A1619F9CF934

  (Android 기기 없음 — USB 디버깅을 켜고 연결한다)
```

**목록에 오르는 기준이 플랫폼마다 다르다.** macOS 는 이 맥이라 항상 1번에 있고,
iOS 는 `devicectl` 이 `available` 로 판정한 것만(신뢰하지 않은 기기는 `unavailable`
이라 뜨지 않는다), Android 는 `adb devices` 의 `device` 상태만 오른다. 연결이 없는
플랫폼은 목록에서 빠지는 대신 **왜 없는지**를 한 줄로 알려 준다.

번호 대신 기기 ID 나 `macos` 를 직접 줘도 된다 — 스크립트나 CI 에서 쓸 때 편하다.

```bash
install.sh macos                     # 이 맥에서 빌드·실행
install.sh R58X609XXYV               # Android (adb 시리얼)
install.sh 00008140-001C24C9…        # iOS (UDID·UUID 모두 가능)
install.sh <선택> --console          # 실행 로그를 터미널에 붙인다
install.sh <선택> --skip-build       # 설치·실행만 (수 초)
install.sh <선택> --release          # 릴리즈 빌드
install.sh <선택> --no-launch        # 설치만
install.sh <선택> --path ~/game      # 프로젝트 경로 지정
```

**stdin 이 터미널이 아니면 묻지 않는다** — 목록만 찍고 끝나므로 CI 나 스크립트에서
멈추지 않는다. 이때는 번호를 인자로 준다.

macOS 는 `export_path` 가 `.zip` 이면 풀어서 `.app` 을 꺼내고, `com.apple.quarantine`
속성을 지운 뒤 `open` 한다 — 서명 없는 자기 빌드가 Gatekeeper 에 막히는 것을 피한다.

**에디터 Remote Deploy 와 결과가 같으므로, 에디터를 띄우지 않는 작업에서는 이 스크립트를
쓴다.** 상세는 [references/headless-workflow.md](references/headless-workflow.md) §3.

## 프로젝트 내 학습 문서

`docs/godot/` 에는 사람이 읽는 입문 문서가 따로 있다(`에디터 없이 작업.md`, `기본 개념.md`,
`GDScript.md` 등). 이 스킬이 **라리엔 3D 기준 규범**이고 그쪽은 일반 학습용이므로,
**두 곳이 어긋나면 이 스킬이 맞다.**

`에디터 없이 작업.md` §13 은 에디터 없이 4개 플랫폼을 테스트 빌드·설치·릴리즈까지 가져가는
전 과정을 예제(`./app`)로 다룬다. 템플릿 필요 파일 판정은 이 스킬
([export-build.md](references/export-build.md) §2)과 같은 실측 결과로 맞춰져 있다.

## 공식 참조

- 공식 문서(4.7): https://docs.godotengine.org/en/4.7/
- 클래스 레퍼런스: https://docs.godotengine.org/en/4.7/classes/
- 엔진 소스: https://github.com/godotengine/godot
- 릴리스: https://github.com/godotengine/godot-builds/releases
- Asset Store: https://store.godotengine.org/

클래스의 정확한 시그니처가 필요하면 추측하지 말고 `hover`로 확인하거나
`https://docs.godotengine.org/en/4.7/classes/class_<소문자클래스명>.html`을 조회한다.
