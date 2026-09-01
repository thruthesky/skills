# HUD·메뉴·버튼 만들기 — 화면 UI 조립

**화면에 붙는 UI 를 실제로 어떻게 짜는가**를 다룬다. 체력바·미니맵 같은 HUD,
메인 메뉴·일시정지·설정 같은 메뉴 화면, 그리고 그것들의 디자인을 한 곳에서
관리하는 방법이다.

> **이 문서와 [input-ui.md](input-ui.md) 의 분담**
>
> | 문서 | 담는 것 |
> |---|---|
> | [input-ui.md](input-ui.md) | **입력 파이프라인과 Control API 레퍼런스** — `_input` 전파 순서, `InputMap`, 게임패드, 가상 조이스틱, 앵커·`size_flags`·`mouse_filter` 의 속성 정의, BBCode 문법 |
> | **이 문서** | **화면을 조립하는 작업 절차** — 어떤 노드를 어떤 순서로 쌓고, 에디터에서 무엇을 누르고, 라리엔 3D 의 HUD 를 구체적으로 어떻게 설계하는가 |
>
> 속성 하나의 정확한 뜻이 궁금하면 input-ui.md, **"화면을 만들어야 한다"면 이 문서**다.

API·기본값은 **엔진에서 직접 추출해 확인한 것**이며, 확인 기준은 **4.7.2.stable** 이다.

**Godot 은 UI 시스템이 엔진에 내장되어 있다.** 외부 라이브러리를 설치할 일이
거의 없다. 공식 문서는 [Godot UI 튜토리얼](https://docs.godotengine.org/en/stable/tutorials/ui/index.html) 이다.

---

## 목차

**전제** — [0. 이 프로젝트의 화면](#0-먼저--이-프로젝트의-화면은-두-가지다) ·
[1. 네 개의 기둥](#1-네-개의-기둥--control--container--theme--canvaslayer) ·
[2. 절대 원칙](#2-절대-원칙--좌표로-놓지-않는다)

**조립** — [3. 레이아웃](#3-레이아웃--앵커와-프리셋) ·
[4. 컨테이너 고르기](#4-컨테이너-고르기) ·
[5. 노드 고르기](#5-노드-고르기--무엇으로-만들-것인가)

**실전** — [6. HUD 만들기](#6-hud-만들기--실전) ·
[7. 메뉴 만들기](#7-메뉴-만들기) ·
[8. Theme](#8-theme--디자인을-한-곳에서-관리한다) ·
[9. 폰트](#9-폰트--한글이-먼저다) ·
[10. 재사용 컴포넌트](#10-재사용-컴포넌트--ui-를-씬으로-쪼갠다) ·
[11. UI 애니메이션](#11-ui-애니메이션--싸게-살아있게-만든다)

**라리엔 3D** — [12. 모바일 필수](#12-모바일에서-반드시-해야-하는-3가지) ·
[13. 3D 게임 특유의 함정](#13-3d-게임-특유의-함정) ·
[14. 성능](#14-성능--ui-도-공짜가-아니다) ·
[15. 접근성](#15-접근성--45-부터-스크린-리더가-붙는다) ·
[16. 자주 하는 실수](#16-자주-하는-실수) ·
[17. 공식 문서와 참고 자료](#17-공식-문서와-참고-자료)

---

## 0. 먼저 — 이 프로젝트의 화면은 두 가지다

**UI 를 그리기 전에 이것부터 봐야 한다.** [`project.godot`](../../../../project.godot) 의
실제 값이다.

```ini
[display]
window/size/viewport_width  = 1920      # 데스크톱 기준
window/size/viewport_height = 1080
window/size/viewport_width.mobile  = 1080   # 모바일 오버라이드
window/size/viewport_height.mobile = 1920
window/handheld/orientation = 1             # = SCREEN_PORTRAIT (엔진에서 확인)
window/stretch/mode   = "canvas_items"
window/stretch/aspect = "expand"
```

| 플랫폼 | 해상도 | 방향 |
|---|---|---|
| **모바일** | **1080 × 1920** | 🛑 **세로 (Portrait)** |
| 데스크톱(Steam) | 1920 × 1080 | 가로 (Landscape) |

> `orientation = 1` 은 `DisplayServer.SCREEN_PORTRAIT` 다 (0 = LANDSCAPE, 1 = PORTRAIT,
> 2 = REVERSE_LANDSCAPE, 3 = REVERSE_PORTRAIT, 4~6 = SENSOR 계열).

### 이것이 UI 설계에 뜻하는 것

**같은 UI 가 세로 9:16 과 가로 16:9 양쪽에서 성립해야 한다.** 종횡비가 뒤집힌다.

| 결과 | 내용 |
|---|---|
| 🛑 **좌표를 손으로 박으면 반드시 깨진다** | 세로에서 맞춘 위치가 가로에서 화면 밖으로 나간다 |
| **세로가 기준이다** | 주 플랫폼이 모바일이다. 세로에서 먼저 맞추고 가로를 확인한다 |
| **가로 폭이 좁다** | 1080px 안에 좌우 배치를 욱여넣지 않는다. **위아래로 쌓는다**(`VBoxContainer`) |
| **아래쪽 절반은 손가락이 덮는다** | 세로 화면 하단은 왼손·오른손 엄지 영역이다 → [§12](#12-모바일에서-반드시-해야-하는-3가지) |

`stretch/mode = canvas_items` 는 **UI 를 해상도에 맞춰 늘려주는** 모드다.
`aspect = expand` 는 **비율이 다르면 잘라내지 않고 보이는 영역을 넓힌다**는 뜻이라,
넓어진 쪽에 무엇이 들어와도 괜찮게 짜야 한다는 조건이 붙는다.

### 공식 권장값과 대조하면 — 이 설정은 맞다

Godot 공식 문서([Multiple resolutions](https://docs.godotengine.org/en/stable/tutorials/rendering/multiple_resolutions.html))가
플랫폼별로 권장하는 조합이다.

| 대상 | 기준 해상도 | Stretch Mode | Stretch Aspect |
|---|---|---|---|
| 데스크톱 (비픽셀아트) | 1920×1080 | `canvas_items` | `expand` |
| 모바일 가로 | 1280×720 (고사양 1920×1080) | `canvas_items` | `expand` |
| **모바일 세로** | **720×1280 (고사양 1080×1920)** | **`canvas_items`** | **`expand`** |
| 픽셀아트 | 640×360 | `viewport` | `keep` + `scale_mode = integer` |

**이 프로젝트는 모바일 세로 권장 조합과 정확히 일치한다.** 다만 기준 해상도가
**고사양 쪽 값(1080×1920)** 이라는 점은 알고 있어야 한다.

> **최소 지원 사양이 3GB RAM Android** 인데([performance-mobile.md](performance-mobile.md) §0)
> 그런 기기의 실제 화면은 대개 **720×1600 급**이다. 기준이 1080 이므로 UI 는
> 약 **0.67 배로 축소되어** 그려진다. `canvas_items` 는 필터링을 적용하므로
> 레이아웃이 깨지지는 않지만, **얇은 선과 작은 글자는 뭉갠다.**
> → 1px 구분선을 쓰지 않고 2px 이상으로 잡는다. 폰트는 [§9](#9-폰트--한글이-먼저다).

### Stretch 설정 3×5 — 무엇을 고르는가

`display/window/stretch/mode` (엔진 기본값은 `"disabled"`, 이 프로젝트는 `canvas_items`)

| 값 | 무엇을 하나 | 언제 |
|---|---|---|
| `disabled` | 아무것도 안 늘린다. 1단위 = 1픽셀 | 창 크기가 고정된 도구 |
| **`canvas_items`** | **2D 요소 자체를 화면 크기에 맞춰 늘린다** | **일반 게임 — 이 프로젝트** |
| `viewport` | 기준 해상도로 먼저 렌더하고 그 결과를 확대 | **픽셀아트** (필터링 없이 확대) |

`display/window/stretch/aspect` (엔진 기본값 `"keep"`, 이 프로젝트는 `expand`)

| 값 | 비율이 다르면 | |
|---|---|---|
| `ignore` | 늘려서 채운다 — **찌그러진다** | 쓰지 않는다 |
| `keep` | 검은 띠(레터박스)를 넣는다 | 화면을 꽉 채우고 싶지 않을 때 |
| `keep_width` | 폭을 유지하고 위아래가 넓어진다 | 공식 문서가 **"GUI·HUD 에 대개 최선"** 이라고 적은 값 |
| `keep_height` | 높이를 유지하고 좌우가 넓어진다 | 가로 스크롤 2D |
| **`expand`** | **띠 없이 보이는 영역을 넓힌다** | **모바일 권장 — 이 프로젝트** |

> **`expand` 를 쓰면 "넓어진 쪽에 무엇이 보이는가"가 기기마다 달라진다.**
> 그래서 **배경은 넉넉히 크게, 중요한 것은 앵커로 모서리에 고정**해야 한다.
> 화면 한가운데를 기준으로 좌표를 재면 21:9 폰에서 어긋난다.

### 세로·가로를 모두 지원하는 두 가지 길

공식 문서는 **기준 해상도를 정사각형(1:1)으로 두라**고 권한다. 하지만 이 프로젝트는
**`.mobile` 접미사 오버라이드**로 플랫폼마다 다른 기준을 준다.

| 방법 | 장점 | 단점 |
|---|---|---|
| 정사각형 기준 (1080×1080) | 설정이 하나 | **양쪽 다 어중간하다.** 세로에서 위아래가 남고 가로에서 좌우가 남는다 |
| **`.mobile` 오버라이드 (현재)** | **각 플랫폼에 딱 맞는 기준** | 레이아웃을 **양쪽에서 다 확인해야** 한다 |

**현재 방식이 낫다.** 대신 **PC 빌드로 UI 를 확인했다고 끝난 것이 아니다** —
가로 16:9 와 세로 9:16 을 둘 다 봐야 한다.

> **에디터에서 두 비율을 빠르게 확인하는 법** — 실행 창을 마우스로 세로로 길게
> 늘였다 줄였다 하면 `canvas_items` 스트레치가 실시간으로 다시 계산된다.
> 앵커와 컨테이너로만 짰다면 이때 아무것도 깨지지 않는다. **이것이 검사법이다.**

### 런타임에 UI 배율을 바꾸려면 — `content_scale_factor`

"UI 크기" 옵션을 설정 화면에 두고 싶을 때 쓴다.

```gdscript
get_tree().root.content_scale_factor = 1.25    # 기본 1.0 (엔진에서 확인)
```

> 🛑 **이 값은 창 안의 2D 콘텐츠 전체에 걸린다.** UI 만 골라 키우는 것이 아니라
> 2D 로 그려지는 것이 전부 커진다. 3D 월드는 영향을 받지 않으므로 이 프로젝트에서는
> 사실상 UI 배율로 쓸 수 있다.
>
> 함께 있는 `display/window/stretch/scale_mode` 는 `fractional`(기본) 과 `integer` 중
> 고르는데, **`integer` 는 픽셀아트 전용**이다. 라리엔은 `fractional` 을 유지한다.

> 🛑 **`project.godot` 은 Claude 가 고치지 않는다** ([CLAUDE.md](../../../../CLAUDE.md) 작업 규칙).
> 값을 바꿔야 하면 경로와 값을 알려주고 사람이 에디터에서 적용한다.

---

## 1. 네 개의 기둥 — Control · Container · Theme · CanvasLayer

Godot UI 는 이 넷으로 이루어진다. **각각이 없으면 무엇이 깨지는지**로 이해하는 게 빠르다.

| 기둥 | 하는 일 | 없으면 |
|---|---|---|
| **`Control`** | 모든 UI 노드의 조상. **화면 어디에 붙을지**(앵커)를 정한다 | 해상도가 바뀌면 위치가 어긋난다 |
| **`Container`** | 자식들을 **자동 정렬**한다 | 항목을 하나 추가할 때마다 아래 것들을 손으로 다시 민다 |
| **`Theme`** | 색·폰트·테두리·마우스오버를 **한 곳에서** 정의한다 | 버튼 색을 바꾸려고 버튼 40개를 하나씩 연다 |
| **`CanvasLayer`** | UI 를 3D 화면 **위에 고정**한다 | 카메라가 움직이면 체력바가 같이 흘러간다 |

### `Control` 은 왜 `Node2D` 가 아닌가

둘 다 2D 인데 갈라져 있다. **좌표를 다루는 방식이 다르기 때문**이다.

| | `Node2D` | `Control` |
|---|---|---|
| 위치 | `position` 하나 | **앵커 + 오프셋** (부모 크기에 상대적) |
| 크기 | 개념 없음 | `size` 가 있고 **부모가 바꿀 수 있다** |
| 용도 | 게임 월드의 2D 물체 | **화면에 붙는 UI** |

**UI 는 전부 `Control` 계열로 짠다.** `Sprite2D` 로 버튼을 만들지 않는다.

### `CanvasLayer` — 3D 위에 UI 를 얹는 유일한 방법

`CanvasLayer` 는 **독립된 2D 그리기 층**을 만든다. 3D 카메라의 영향을 받지 않는다.

```
layer 기본값 = 1   (엔진에서 확인)
```

숫자가 클수록 위에 그려진다. 라리엔에서 쓸 층 배치는 이렇다.

| `layer` | 무엇 |
|---|---|
| `0` | (3D 월드 자체 — CanvasLayer 밖) |
| **`1`** | **HUD** — 체력·미니맵·스킬 버튼 |
| **`5`** | **창** — 인벤토리·장터·퀘스트 |
| **`10`** | **모달** — 일시정지·확인 대화상자 |
| **`100`** | **로딩·페이드** — 존 전환 시 화면 덮기 |

> 층을 나누는 이유는 **인벤토리를 열었을 때 HUD 위에 확실히 오게** 하기 위해서다.
> 같은 층에 두면 씬 트리 순서에 의존하게 되어, 노드를 옮기다 순서가 뒤집힌다.

---

## 2. 절대 원칙 — 좌표로 놓지 않는다

**UI 작업에서 가장 중요한 규칙이다.** 마우스로 끌어다 놓는 것은 시작일 뿐이고,
그 상태로 두면 반드시 깨진다.

### 왜 깨지는가 — 실제 숫자로

체력바를 "왼쪽 위에서 x=40, y=40" 에 두었다고 하자.

| 화면 | x=40 이 실제로 뜻하는 것 |
|---|---|
| 모바일 세로 1080×1920 | 화면 폭의 **3.7%** 지점 |
| 태블릿 가로 2048×1536 | 화면 폭의 **2.0%** 지점 — 더 붙어 보인다 |
| 노치가 있는 폰 | **노치에 가려 안 보인다** |

**앵커를 쓰면 "왼쪽 위 모서리에서 40px" 라는 뜻이 유지된다.**

### 순서는 넷이다

```
1. 앵커(Anchor)  로 어느 모서리에 붙을지 정한다
2. 컨테이너      로 자식들을 자동 정렬한다
3. Theme         로 디자인을 통일한다
4. 시그널        로 코드와 연결한다
```

**이 순서를 지키면 해상도·언어·글자 길이가 바뀌어도 UI 가 무너지지 않는다.**
반대로 1·2 를 건너뛰고 좌표로 배치하면 3·4 를 아무리 잘해도 소용이 없다.

### 앵커와 컨테이너는 **같은 노드에 함께 쓸 수 없다**

**둘 다 "위치를 정하는 수단"이라 서로 배타적이다.** 이걸 모르면
"Layout 메뉴가 회색으로 잠겨 있다"에서 막힌다.

| 부모가 | 그 자식의 위치를 정하는 것 | 에디터 `Layout` 메뉴 |
|---|---|---|
| **컨테이너** (`VBox`·`Margin`…) | **부모 컨테이너** | 🛑 **잠긴다 (정상)** |
| 그냥 `Control`·`CanvasLayer` | **자기 앵커** | 쓸 수 있다 |

**그래서 실무는 둘을 층으로 나눠 섞는다.**

```
HUD (CanvasLayer)
├─ Top (MarginContainer)      ← 앵커로 화면 상단에 붙인다   (앵커 층)
│  └─ VBoxContainer           ← 여기서부터는 컨테이너가 지배 (컨테이너 층)
│     ├─ Label
│     └─ HpBar
└─ Bottom (MarginContainer)   ← 앵커로 화면 하단에         (앵커 층)
```

| 쓰는 것 | 언제 |
|---|---|
| **앵커만** | 체력바 하나, 대화 상자 하나처럼 **개수가 고정된 덩어리를 화면에 붙일 때** |
| **컨테이너** | 인벤토리 칸, 스킬 슬롯 줄, 메뉴 버튼 목록처럼 **개수가 변하거나 정렬이 필요할 때** |

**"화면에 붙이는 것은 앵커, 그 안을 채우는 것은 컨테이너"** 로 기억하면 된다.


---

## 3. 레이아웃 — 앵커와 프리셋

### 앵커는 "부모의 어디에 붙을 것인가"다

`Control` 의 앵커 4개는 **0.0 ~ 1.0 의 비율**이다 (엔진에서 확인한 기본값은 전부 `0.0`).

| 속성 | 기본값 | 뜻 |
|---|---|---|
| `anchor_left` · `anchor_top` | `0.0` | 부모의 왼쪽·위 |
| `anchor_right` · `anchor_bottom` | `0.0` | 〃 |
| `offset_left` ~ `offset_bottom` | `0.0` | 앵커 지점에서 **픽셀 단위**로 얼마나 떨어질지 |

`anchor_right = 1.0` 이면 **부모의 오른쪽 끝에 붙는다**는 뜻이고, 부모가 커지면 같이 커진다.

### 실무에서는 프리셋으로 끝난다

앵커 4개를 손으로 넣는 일은 거의 없다. **에디터 상단의 `Layout` 버튼**에서 고른다.
엔진에 정의된 프리셋은 16종이다.

| 값 | 상수 | 실제로 쓰는 곳 |
|---|---|---|
| `15` | **`PRESET_FULL_RECT`** | **화면 전체를 덮는 것** — 메뉴 루트, 모달 배경 |
| `0`~`3` | `PRESET_TOP_LEFT` · `TOP_RIGHT` · `BOTTOM_LEFT` · `BOTTOM_RIGHT` | **HUD 의 네 모서리** |
| `8` | `PRESET_CENTER` | 가운데 정렬 |
| `12` | `PRESET_BOTTOM_WIDE` | 하단 바 (스킬 슬롯) |
| `10` | `PRESET_TOP_WIDE` | 상단 바 |
| `9` · `11` | `PRESET_LEFT_WIDE` · `RIGHT_WIDE` | 좌우 세로 바 |
| `4`~`7`, `13`, `14` | 나머지 | 드물게 |

> 🛑 **메뉴·HUD 의 루트 `Control` 은 거의 항상 `PRESET_FULL_RECT` 다.**
> 루트가 화면 전체를 차지해야 그 안의 컨테이너가 화면 기준으로 정렬할 수 있다.
> 이걸 빼먹으면 컨테이너가 크기 0 인 영역 안에서 정렬하려 해서 UI 가 왼쪽 위에 뭉친다.

### `size_flags` — 컨테이너 안에서의 행동

컨테이너 **안에 있을 때만** 의미가 있다. 실측 기본값은 `size_flags_horizontal = 1`,
`size_flags_vertical = 1` (= `SIZE_FILL`) 이다.

| 값 | 상수 | 뜻 |
|---|---|---|
| `0` | `SIZE_SHRINK_BEGIN` | 최소 크기로 줄이고 앞쪽 정렬 |
| **`1`** | **`SIZE_FILL`** | **기본값.** 배정받은 자리를 채운다 |
| `2` | `SIZE_EXPAND` | 남는 공간을 요구한다 |
| **`3`** | **`SIZE_EXPAND_FILL`** | **남는 공간을 요구하고 채운다** — 가장 자주 쓴다 |
| `4` | `SIZE_SHRINK_CENTER` | 최소 크기로 줄이고 가운데 |
| `8` | `SIZE_SHRINK_END` | 최소 크기로 줄이고 뒤쪽 |

**`Label` 만은 `size_flags_vertical` 기본값이 `4`(`SHRINK_CENTER`) 다** (엔진에서 확인).
글자는 세로로 늘어날 이유가 없기 때문이다.

`size_flags_stretch_ratio`(기본 `1.0`)는 **`EXPAND` 끼리 남는 공간을 나누는 비율**이다.
둘 다 `EXPAND` 인데 하나만 `2.0` 이면 2:1 로 나눈다.

---

## 4. 컨테이너 고르기

### 언제 무엇을 쓰나

| 컨테이너 | 하는 일 | 쓰는 곳 |
|---|---|---|
| **`VBoxContainer`** | 세로로 쌓는다 | **메뉴 버튼 목록**, 세로 화면의 HUD |
| **`HBoxContainer`** | 가로로 쌓는다 | 스킬 슬롯 줄, 아이콘 + 라벨 |
| **`MarginContainer`** | 안쪽 여백을 준다 | **화면 가장자리 여백** — HUD 루트에 거의 항상 |
| **`CenterContainer`** | 자식을 가운데 | 메인 메뉴, 로딩 문구 |
| **`GridContainer`** | 격자 (`columns` 지정) | **인벤토리 칸**, 장비창 |
| **`PanelContainer`** | 배경(`StyleBox`)을 깔고 자식을 감싼다 | 창의 테두리·배경 |
| **`ScrollContainer`** | 넘치면 스크롤 | 아이템 목록, 채팅 로그 |
| **`AspectRatioContainer`** | 비율 유지 (`ratio` 기본 `1.0`) | 정사각형 초상화·아이콘 |
| **`TabContainer`** | 탭으로 전환 | 설정 화면 |

`VBoxContainer`·`HBoxContainer` 는 실은 **`BoxContainer` 하나**이고,
`vertical` 속성(기본 `false`)으로 갈린다 (엔진에서 확인).

### 🛑 컨테이너 안에서는 `position` 이 무시된다

**가장 많이 겪는 혼란이다.** 컨테이너의 자식을 마우스로 끌면 제자리로 돌아간다.

**버그가 아니다.** 컨테이너가 자식의 위치와 크기를 **매 프레임 다시 계산해 덮어쓰기**
때문이다. 그것이 컨테이너의 존재 이유다.

**컨테이너 안에서 위치를 조절하는 방법은 넷이다.**

| 원하는 것 | 방법 |
|---|---|
| 간격을 벌린다 | 부모 컨테이너의 **`theme_override_constants/separation`** |
| 가장자리 여백 | **`MarginContainer`** 로 감싸고 `margin_*` 상수 |
| 특정 자식만 더 크게 | 그 자식의 **`custom_minimum_size`** (기본 `Vector2(0, 0)`) |
| 남는 공간 분배 | **`size_flags` + `stretch_ratio`** ([§3](#3-레이아웃--앵커와-프리셋)) |

> **`custom_maximum_size`** 는 4.7 에 있는 속성으로 기본값이 `Vector2(-1, -1)`(제한 없음)이다.
> 글자가 길어져도 버튼이 무한정 넓어지지 않게 막을 때 쓴다.

### 전형적인 중첩

```
Control            PRESET_FULL_RECT        ← 화면 전체를 잡는다
└─ MarginContainer                          ← 가장자리 여백
   └─ VBoxContainer                         ← 세로로 쌓는다
      ├─ Label
      └─ HBoxContainer                      ← 그 안에서 가로로
         ├─ TextureRect
         └─ Label
```

**컨테이너는 중첩해서 쓰는 것이 정상이다.** 하나로 다 하려 하지 않는다.

### 깊이 — 중첩은 정상이지만 무한정은 아니다

컨테이너는 **크기가 바뀔 때마다 자식 배치를 다시 계산**한다. 이 계산은 부모에서
자식으로 내려가므로 **깊이가 깊고 자식이 많을수록 비싸진다.**

| 규칙 | |
|---|---|
| **깊이 4~5 층이면 충분하다** | `CanvasLayer > Margin > VBox > HBox > 위젯` |
| 🛑 **한 컨테이너에 자식 수백 개를 두지 않는다** | 인벤토리 200칸을 `GridContainer` 에 한 번에 넣으면 여는 순간 멈칫한다 |
| **긴 목록은 `ScrollContainer` + 가시 범위만 생성** | 화면에 보이는 20칸만 만들고 스크롤에 따라 재활용한다 |
| **의미 단위로 끊는다** | 깊게 겹치기보다 **별도 씬으로 빼서** 인스턴싱한다 → [§10](#10-재사용-컴포넌트--ui-를-씬으로-쪼갠다) |

> **모바일 GPU 는 데스크톱보다 이 비용에 훨씬 민감하다.** 에디터에서 부드럽다고
> 실기기에서도 부드러운 것이 아니다 → [§14](#14-성능--ui-도-공짜가-아니다)

`ScrollContainer` 실측 기본값 중 알아야 할 것:

| 속성 | 기본값 | |
|---|---|---|
| `follow_focus` | **`false`** | 게임패드로 포커스를 옮겨도 **자동으로 스크롤되지 않는다.** 패드 지원을 하려면 켠다 |
| `clip_contents` | `true` | 넘치는 부분을 잘라낸다 |
| `horizontal_scroll_mode` · `vertical_scroll_mode` | `1` | 필요할 때만 스크롤바 표시 |
| `scroll_deadzone` | `0` | 터치 드래그가 시작되는 여유. **0 이면 살짝만 움직여도 스크롤로 인식**해 버튼 탭이 씹힐 수 있다 |

> **터치 드래그 스크롤은 `input_devices/pointing/emulate_mouse_from_touch` 가
> 켜져 있어야 동작한다** — 엔진 기본값이 `true` 라 보통 그냥 된다. 이걸 끄면
> UI 클릭 자체가 안 된다. 목록 안에 탭 가능한 항목이 있어 오작동하면
> `scroll_deadzone` 을 올리거나 `gui/common/drag_threshold`(기본 `10`)를 조정한다.


---

## 5. 노드 고르기 — 무엇으로 만들 것인가

### 같은 목적에 두 개씩 있다

| 목적 | 단순한 쪽 | 아트가 들어간 쪽 | 고르는 기준 |
|---|---|---|---|
| **글자** | `Label` | `RichTextLabel` | 색·아이콘이 **문장 중간에** 섞이면 Rich. 아니면 `Label` |
| **버튼** | `Button` | `TextureButton` | 이미지 버튼이면 Texture. **테마로 꾸밀 거면 `Button`** |
| **게이지** | `ProgressBar` | `TextureProgressBar` | 체력바처럼 모양이 중요하면 Texture |
| **배경** | `Panel` | `NinePatchRect` | 테두리 이미지를 늘려야 하면 NinePatch |
| **이미지** | `TextureRect` | — | |

**`RichTextLabel` 은 `Label` 보다 훨씬 비싸다.** 채팅·아이템 설명처럼 서식이 정말
필요한 곳에만 쓴다. [§14](#14-성능--ui-도-공짜가-아니다)

`TextureProgressBar` 는 `fill_mode` 로 채우는 방향을 바꾸고,
**`radial_fill_degrees`(기본 `360.0`)·`radial_initial_angle`** 로 원형 게이지를 만든다.
스킬 쿨다운이 이것이다.

### 🛑 `mouse_filter` — 노드마다 기본값이 다르다 (실측)

**3D 게임에서 "화면을 눌렀는데 캐릭터가 안 움직인다"의 원인 1순위다.**
UI 가 터치를 먹어버린 것이다. 노드별 실측 기본값은 이렇게 다르다.

| 노드 | `mouse_filter` 기본값 | 뜻 |
|---|---|---|
| **`Control`** | **`0` (STOP)** | 🛑 **입력을 먹는다** |
| **`PanelContainer`** | **`0` (STOP)** | 🛑 **먹는다** |
| `TextureRect` | `1` (PASS) | 자기도 받고 아래로도 넘긴다 |
| `TextureProgressBar` | `1` (PASS) | |
| **`Label`** | **`2` (IGNORE)** | 통과시킨다 |
| **`NinePatchRect`** | **`2` (IGNORE)** | 통과시킨다 |

| 값 | 상수 | 동작 |
|---|---|---|
| `0` | `MOUSE_FILTER_STOP` | **여기서 멈춘다.** 아래 3D 로 안 간다 |
| `1` | `MOUSE_FILTER_PASS` | 자기가 처리하고 **아래로도 보낸다** |
| `2` | `MOUSE_FILTER_IGNORE` | **아예 안 받는다** |

> 🛑 **HUD 루트와 빈 배경 `Control` 은 반드시 `IGNORE` 로 바꾼다.**
> 기본값이 `STOP` 이라, 화면 전체를 덮는 `PRESET_FULL_RECT` 컨테이너를 그냥 두면
> **화면 전체가 터치를 삼킨다.** 버튼만 `STOP`(기본값)으로 두면 된다.

`Button` 은 `BaseButton` 을 통해 `Control` 의 기본값 `0`(STOP)을 그대로 쓴다.
**버튼이 입력을 먹는 것은 정상이고 의도된 동작**이다.

### 포커스 — 게임패드·키보드로 UI 를 돌아다닐 때

| 노드 | `focus_mode` 기본값 |
|---|---|
| `Control` | `0` (`FOCUS_NONE`) |
| **`BaseButton` 계열** | **`2` (`FOCUS_ALL`)** |

버튼만 기본으로 포커스를 받는다. Steam 판에서 게임패드로 메뉴를 조작하려면
`focus_neighbor_*` 로 이동 순서를 정한다 → [input-ui.md](input-ui.md) §15.


---

## 6. HUD 만들기 — 실전

### 원칙 — HUD 는 별도 씬으로 분리한다

```
scenes/ui/hud.tscn        ← HUD 만 들어 있는 독립 씬
scenes/main.tscn          ← 그 씬을 인스턴스로 붙인다
```

**분리하는 이유는 셋이다.**

| 이유 | 내용 |
|---|---|
| **맵을 갈아끼워도 HUD 는 남는다** | [level-design.md](level-design.md) 의 `Level` 교체 구조와 맞물린다 |
| **HUD 만 따로 열어 작업한다** | 3D 씬을 열지 않아도 UI 를 고칠 수 있다 |
| **테스트가 쉽다** | `hud.tscn` 을 단독 실행해 값만 넣어보면 된다 |

### 라리엔 3D 의 HUD 구조 (세로 1080×1920 기준)

```
hud.tscn
└─ HUD (CanvasLayer)              layer = 1
   ├─ Top (MarginContainer)       PRESET_TOP_WIDE     mouse_filter = IGNORE
   │  └─ VBoxContainer
   │     ├─ SelfBar (HBoxContainer)      내 HP / MP
   │     └─ TargetBar (PanelContainer)   대상 몹 이름 + HP  (평소 hidden)
   ├─ MiniMap (TextureRect)       PRESET_TOP_RIGHT
   ├─ Chat (ScrollContainer)      PRESET_LEFT_WIDE    반투명
   └─ Bottom (MarginContainer)    PRESET_BOTTOM_WIDE  ← 엄지 영역
      └─ HBoxContainer
         ├─ MoveStick (VirtualJoystick)  ← 왼손
         ├─ (Spacer)                     size_flags = EXPAND_FILL
         └─ SkillGrid (GridContainer)    ← 오른손. columns = 3
```

**세로 화면이라 위아래로 나눈다.** 가로 폭 1080px 안에서 좌우로 나누면
양쪽 다 좁아진다. **정보는 위, 조작은 아래**가 원칙이다.

> **왼손 이동 / 오른손 전투**는 카메라 3축 고정의 근거이기도 하다
> ([SSOT §1](../../game/references/SSOT.md)). **엄지를 카메라에 뺏기지 않으므로**
> 하단 양쪽을 이동과 스킬에 온전히 쓸 수 있다.

### 에디터 조작 순서

> 🛑 **씬 파일(`.tscn`)은 사람 개발자가 에디터에서 직접 만든다**
> ([CLAUDE.md](../../../../CLAUDE.md) 작업 규칙). 아래는 그 조작 순서다.

| # | 조작 | 결과 |
|---|---|---|
| 1 | `Scene > New Scene` → **Other Node** → `CanvasLayer` → **F2** → `HUD` | HUD 루트 |
| 2 | `res://scenes/ui/hud.tscn` 으로 저장 | |
| 3 | `HUD` 선택 → **Cmd+A** → `MarginContainer` → **F2** → `Top` | 상단 영역 |
| 4 | `Top` 선택 → 뷰포트 상단 **`Layout`** → **`Top Wide`** | 화면 폭 전체에 붙는다 |
| 5 | 인스펙터 → **`Mouse > Filter`** 를 **`Ignore`** 로 | 🛑 **터치를 삼키지 않게** |
| 6 | 인스펙터 → `Theme Overrides > Constants` → `Margin Left/Top/Right` 에 여백 | 가장자리 여백 |
| 7 | `Top` 선택 → **Cmd+A** → `VBoxContainer` → 그 아래 `Label`·`TextureProgressBar` | 내용 |
| 8 | `main.tscn` 열고 루트 선택 → **Cmd+Shift+A** → `hud.tscn` 선택 | HUD 인스턴스 배치 |

`Cmd+A` 는 macOS 의 **자식 노드 추가**, `Cmd+Shift+A` 는 **자식 씬 인스턴싱**이다
(Windows·Linux 는 `Ctrl` ).

### 체력바 스크립트 — 서버 권위를 지킨다

> 🛑 **HP·데미지·사망은 전부 서버가 계산한다** ([SSOT §7](../../game/references/SSOT.md)).
> **HUD 는 받은 값을 표시할 뿐 스스로 계산하지 않는다.**

```gdscript
extends CanvasLayer

@onready var hp_bar: TextureProgressBar = %HpBar
@onready var hp_text: Label = %HpText

func _ready() -> void:
	# 서버 스냅샷이 도착할 때만 갱신한다. _process 에서 매 프레임 읽지 않는다.
	GameState.self_stats_changed.connect(_on_self_stats_changed)

func _on_self_stats_changed(hp: int, hp_max: int) -> void:
	hp_bar.max_value = hp_max
	hp_bar.value = hp
	hp_text.text = "%d / %d" % [hp, hp_max]
```

**`%HpBar` 는 유니크 이름 접근**이다. 노드에 마우스 오른쪽 → **`Access as Unique Name`**
을 켜면 `$Top/VBoxContainer/SelfBar/HpBar` 같은 긴 경로 대신 `%HpBar` 로 닿는다.
**UI 는 구조가 자주 바뀌므로 경로를 박아두면 매번 깨진다.**

> **부드럽게 줄어드는 체력바**를 원하면 `value` 를 직접 넣지 말고 트윈을 쓴다.
> ```gdscript
> create_tween().tween_property(hp_bar, "value", float(hp), 0.2)
> ```

---

## 7. 메뉴 만들기

### 메인 메뉴 구조

```
main_menu.tscn
└─ MainMenu (Control)             PRESET_FULL_RECT
   ├─ Background (TextureRect)    PRESET_FULL_RECT   mouse_filter = IGNORE
   └─ CenterContainer             PRESET_FULL_RECT
      └─ VBoxContainer            separation = 24
         ├─ TitleLabel
         ├─ StartButton           custom_minimum_size = (320, 96)
         ├─ OptionsButton
         └─ QuitButton
```

**루트가 `Control` 이고 `PRESET_FULL_RECT` 라는 것이 핵심이다.**
`CenterContainer` 는 부모 크기의 가운데에 자식을 두는데, 부모가 화면 전체가 아니면
"가운데"가 화면 가운데가 아니게 된다.

### 버튼을 코드에 연결한다 — 시그널

```gdscript
extends Control

@onready var start_button: Button = %StartButton
@onready var options_button: Button = %OptionsButton
@onready var quit_button: Button = %QuitButton

func _ready() -> void:
	start_button.pressed.connect(_on_start_pressed)
	options_button.pressed.connect(_on_options_pressed)
	quit_button.pressed.connect(_on_quit_pressed)

func _on_start_pressed() -> void:
	get_tree().change_scene_to_file("res://scenes/main.tscn")

func _on_options_pressed() -> void:
	%OptionsPanel.show()

func _on_quit_pressed() -> void:
	get_tree().quit()
```

에디터의 **`Node` 독 → `Signals` 탭 → `pressed()` 더블클릭**으로 연결하면
수신 메서드가 자동 생성된다. 시그널의 전체 개념은 [basics.md](basics.md) 를 본다.

> **버튼 시그널 4종을 구분한다** — `pressed`(눌렀다 뗐을 때), `button_down`,
> `button_up`, `toggled`(`toggle_mode = true` 일 때). **평범한 버튼은 `pressed` 다.**
> `BaseButton.action_mode` 기본값은 **`1`(`ACTION_MODE_BUTTON_RELEASE`)** 이라
> **손가락을 떼야 발동한다** — 누르는 순간 발동시키려면 `0`(`ACTION_MODE_BUTTON_PRESS`)
> 으로 바꾼다. 액션 게임의 공격 버튼은 `0` 쪽이 반응이 빠르게 느껴진다.

### 일시정지 메뉴 — `process_mode` 가 핵심이다

```gdscript
extends CanvasLayer

func _ready() -> void:
	# 게임이 멈춰도 이 메뉴는 계속 돈다
	process_mode = Node.PROCESS_MODE_WHEN_PAUSED
	hide()

func toggle_pause() -> void:
	var paused := not get_tree().paused
	get_tree().paused = paused
	visible = paused
```

| `process_mode` | 언제 도나 | 어디에 |
|---|---|---|
| `PROCESS_MODE_INHERIT` (기본) | 부모를 따른다 | 대부분의 노드 |
| **`PROCESS_MODE_WHEN_PAUSED`** | **멈췄을 때만** | **일시정지 메뉴** |
| `PROCESS_MODE_ALWAYS` | 항상 | 로딩 화면, 네트워크 |
| `PROCESS_MODE_DISABLED` | 절대 안 돈다 | |

> 🛑 **라리엔은 온라인 게임이라 `get_tree().paused` 로 게임을 멈출 수 없다.**
> 서버는 계속 돌고 몹은 계속 때린다. **메뉴를 열어도 월드는 멈추지 않는다** —
> 싱글플레이 튜토리얼의 일시정지 패턴을 그대로 옮기면 안 된다.
> 온라인에서 "일시정지"는 **입력을 UI 로 돌리는 것**이지 시간을 멈추는 것이 아니다.

---

## 8. Theme — 디자인을 한 곳에서 관리한다

### 세 가지 층이 있다 — 좁은 것이 이긴다

| 층 | 범위 | 어디에 |
|---|---|---|
| **1. 개별 오버라이드** | 노드 하나 | 인스펙터 `Theme Overrides` |
| **2. Theme 리소스** | 그 노드와 자손 전부 | `Control.theme` 에 `.tres` 지정 |
| **3. 프로젝트 기본 테마** | 게임 전체 | `Project Settings > GUI > Theme > Custom` |

**개별 오버라이드가 Theme 를 이긴다.** 그래서 오버라이드를 남발하면
**나중에 Theme 를 바꿔도 그 노드만 안 바뀌는** 상황이 생긴다.

> 🛑 **오버라이드는 예외를 만들 때만 쓴다.** "이 버튼만 빨갛게" 가 아니라면
> Theme 에서 정의한다. 예외가 셋을 넘으면 **타입 배리에이션**으로 승격시킨다.

### Theme 리소스 만들기

| # | 조작 |
|---|---|
| 1 | `FileSystem` 독에서 우클릭 → `New Resource...` → **`Theme`** |
| 2 | `res://ui/theme/laryen.tres` 로 저장 |
| 3 | 더블클릭하면 하단에 **Theme 에디터**가 열린다 |
| 4 | 왼쪽 **`+`** → 타입 추가 (`Button`, `Label`, `PanelContainer` …) |
| 5 | 각 타입에서 `Color` · `Constant` · `Font` · `Font Size` · `Icon` · `StyleBox` 를 정의 |
| 6 | 루트 `Control` 의 `Theme` 속성에 이 `.tres` 를 지정 |

`Theme` 리소스 자체의 실측 속성은 셋뿐이다 — `default_font`(`None`),
`default_font_size`(`-1`), `default_base_scale`(`0.0`). 나머지는 전부 타입별 항목이다.

### `StyleBox` — 버튼의 "모양"은 여기서 나온다

버튼의 배경·테두리·둥근 모서리는 전부 `StyleBox` 다.

| 종류 | 무엇 |
|---|---|
| **`StyleBoxFlat`** | **코드로 그리는 사각형.** 색·테두리·둥근 모서리·그림자. **가장 많이 쓴다** |
| `StyleBoxTexture` | 이미지 9-슬라이스 |
| `StyleBoxLine` | 선 하나 (구분선) |
| `StyleBoxEmpty` | 아무것도 안 그림 |

`StyleBoxFlat` 실측 기본값 중 실제로 만지는 것들:

| 속성 | 기본값 | |
|---|---|---|
| `bg_color` | `Color(0.6, 0.6, 0.6, 1)` | 배경색 |
| `border_color` | `Color(0.8, 0.8, 0.8, 1)` | 테두리색 |
| `border_width_*` | `0` | **0 이라 기본은 테두리가 없다** |
| `corner_radius_*` | `0` | 둥근 모서리 |
| `corner_detail` | `8` | 곡선 분할 수 |
| `shadow_color` | `Color(0, 0, 0, 0.6)` | |
| `shadow_size` | `0` | **0 이라 기본은 그림자가 없다** |
| `expand_margin_*` | `0.0` | 실제 크기보다 넓게 그린다 |
| `anti_aliasing` | `true` | |

**버튼 하나에 `StyleBox` 를 5개 정의한다** — `normal` · `hover` · `pressed` ·
`disabled` · **`focus`**. 이 다섯이 곧 버튼의 "느낌"이고, **빠뜨린 상태는 조용히
기본 테마로 되돌아간다** — 그래서 "테마를 적용했는데 누르면 회색으로 돌아온다"가 생긴다.

**가장 빠른 작업 순서** (커뮤니티에서 굳어진 방법):

| # | 조작 |
|---|---|
| 1 | `normal` 에 `New StyleBoxFlat` 을 만들고 **여기서만 제대로 디자인한다** |
| 2 | 그 `StyleBoxFlat` 에 우클릭 → **`Duplicate`** → `hover` 에 붙여넣고 **배경을 조금 밝게** |
| 3 | 또 복제 → `pressed` 에 붙여넣고 **조금 어둡게** (+ `expand_margin` 을 줄여 눌린 느낌) |
| 4 | 또 복제 → `disabled` 에 붙여넣고 **채도를 빼고 알파를 낮춘다** |
| 5 | 또 복제 → `focus` 에 붙여넣고 **테두리만 남긴다** (`draw_center = false` + `border_width`) |

> **모바일에는 `hover` 가 사실상 없다.** 손가락은 "올려놓기"가 없기 때문이다.
> 그래도 정의는 해 둔다 — **Steam 판에서는 마우스가 있고**, 정의를 비워 두면
> 그때만 기본 테마가 튀어나온다.

> **`focus` 는 게임패드·키보드 조작의 생명선이다.** 지금 어디에 커서가 있는지
> 보이지 않으면 패드로 메뉴를 못 쓴다. Steam 판을 낼 것이므로 반드시 채운다.

### 타입 배리에이션 — 같은 `Button` 인데 다르게

"위험한 버튼은 빨갛게" 같은 변형을 **오버라이드 없이** 만든다.

| # | 조작 |
|---|---|
| 1 | Theme 에디터에서 새 타입 이름을 **`DangerButton`** 으로 추가 |
| 2 | 그 타입의 **`Base Type`** 을 `Button` 으로 지정 |
| 3 | 원하는 항목만 덮어쓴다 (나머지는 `Button` 것을 상속) |
| 4 | 노드의 **`theme_type_variation`** 에 `DangerButton` 입력 |

**라리엔에서 쓸 만한 배리에이션** — `DangerButton`(파티 탈퇴·아이템 버리기),
`SkillButton`(정사각형 큰 터치 영역), `ChatLabel`(작고 반투명).

### 폰트 크기 — 세로 화면에서 특히 조심한다

1080×1920 세로 화면은 **가로 폭이 1080px 뿐**이다. 데스크톱 감각으로 16px 폰트를
쓰면 실기기에서 읽히지 않는다.

| 쓰임 | 권장 (1080px 폭 기준) |
|---|---|
| 본문·대화 | **32 ~ 36 px** |
| 버튼 라벨 | **36 ~ 40 px** |
| 제목 | 56 ~ 72 px |
| 보조 정보 (채팅 시간 등) | 26 ~ 28 px |

> **`Theme.default_font_size` 하나로 전체를 조절할 수 있게 짠다.**
> 나중에 "글자가 작다"는 피드백이 왔을 때 고칠 곳이 한 군데가 된다.

---

## 9. 폰트 — 한글이 먼저다

**Godot 내장 기본 폰트에는 한글 글리프가 없다.** 아무 설정 없이 한국어를 넣으면
네모(□)가 뜬다. **폰트를 넣는 것은 선택이 아니라 필수 작업**이다.

### 🛑 그런데 한글 폰트는 무겁다 — 번들 용량과 정면으로 부딪친다

| | 영문 폰트 | **한글(CJK) 폰트** |
|---|---|---|
| 글리프 수 | 수백 | **수천~수만** |
| 파일 크기 | 100~300 KB | **15 ~ 20 MB** |

[SSOT §3.1](../../game/references/SSOT.md) 은 **번들 용량을 드로우콜·메모리와 같은 급의
제약**으로 못박고 있다. **폰트 하나가 3D 모델 전체보다 클 수 있다.** 해법은 셋이다.

| 방법 | 용량 | 대가 |
|---|---|---|
| **① 기기 내장 폰트 (`SystemFont`)** | **0 MB** | 기기마다 글자 모양이 다르다. 브랜딩 불가 |
| **② 서브셋 폰트** | **1 ~ 3 MB** | 서브셋에 없는 글자가 □ 로 뜬다 |
| ③ 전체 폰트 통째 | 15~20 MB | 확실하지만 비싸다 |

**권장은 ① + ② 를 섞는 것이다.** UI 라벨·버튼처럼 **문구가 우리 손 안에 있는 곳**은
서브셋 폰트로 예쁘게, **유저 닉네임·채팅처럼 무엇이 올지 모르는 곳**은 시스템 폰트
폴백으로 받는다.

```gdscript
# 기기 내장 한글 폰트 — 번들 용량 0
var sys := SystemFont.new()
sys.font_names = PackedStringArray(["Noto Sans CJK KR", "Malgun Gothic", "Apple SD Gothic Neo"])
sys.allow_system_fallback = true        # 기본값 true (엔진에서 확인)
```

### 폴백 체인 — 없는 글자만 다음 폰트에서 찾는다

`Font.fallbacks` 는 `Font[]` 이고 **기본값은 빈 배열**이다 (엔진에서 확인).
앞에서부터 찾다가 없으면 다음으로 넘어간다.

```
주 폰트 (서브셋 한글 · 우리 브랜드)
  └─ 폴백 1: SystemFont  (닉네임·채팅의 낯선 글자)
       └─ 폴백 2: 이모지·기호 폰트
```

에디터에서는 폰트 리소스의 **`Fallbacks`** 배열에 다른 폰트를 끌어다 넣으면 된다.

> **서브셋을 만들 때 무엇을 넣는가** — 한국어 상용 음절(KS X 1001 완성형 2,350자)에
> **게임에 실제로 쓰는 한자·기호**를 더한다. 아이템 이름·스킬 이름·시스템 문구를
> 전부 모아 거기 쓰인 글자만 뽑는 것이 가장 정확하다.

### 🛑 MSDF 는 이 프로젝트에서 켜지 않는다

**MSDF**(multichannel signed distance field)는 폰트를 크기와 무관하게 선명하게
그리는 방식이다. 매력적으로 들리지만 **공식 문서가 명시한 단점이 라리엔의 조건과
정확히 겹친다.**

| MSDF 의 장점 | MSDF 의 단점 |
|---|---|
| 어떤 크기에서도 선명하다 | 🛑 **폰트 렌더링 기본 비용이 높다 — 저사양 모바일에서 체감된다** |
| 크기를 바꿔도 다시 굽지 않는다 | **작은 글자는 오히려 덜 또렷하다** |
| 큰 글자 첫 표시의 멈칫함이 없다 | LCD 서브픽셀 최적화를 못 쓴다 |

**최소 지원 사양이 3GB RAM 안드로이드**이고([performance-mobile.md](performance-mobile.md) §0)
**UI 폰트 크기는 몇 종으로 고정**되므로, MSDF 가 주는 이점이 거의 없다.

**엔진 기본값이 이미 꺼져 있다** — `gui/theme/default_font_multichannel_signed_distance_field = false`
(엔진에서 확인). **그대로 둔다.**

### 대신 켜야 하는 것 — 밉맵

| 프로젝트 설정 | 엔진 기본값 | 라리엔 판단 |
|---|---|---|
| `gui/theme/default_font_generate_mipmaps` | **`false`** | ✅ **켜는 것을 검토한다** |
| `gui/theme/default_font_multichannel_signed_distance_field` | `false` | 🛑 그대로 끈다 |
| `gui/theme/default_font_antialiasing` | `1` (Grayscale) | 그대로 |
| `gui/theme/default_font_hinting` | `1` (Light) | 그대로 |
| `gui/theme/default_font_subpixel_positioning` | `1` (Auto) | 그대로 |
| `gui/theme/default_theme_scale` | `1.0` | 그대로 |

**밉맵을 켜는 이유** — 기준 해상도 1080 폭인 UI 가 **720 폭 저사양 폰에서 0.67 배로
축소**되어 그려진다([§0](#0-먼저--이-프로젝트의-화면은-두-가지다)). 밉맵이 없으면
축소된 글자가 **자글거린다.** 밉맵은 텍스처 메모리를 약 33% 더 쓰지만
폰트 아틀라스는 원래 작아서 감당된다.

> 🛑 **설정 파일은 사람이 바꾼다.** 경로는
> `Project > Project Settings > GUI > Theme > Default Font Generate Mipmaps`.

### 3D 위에 얹는 글자에는 외곽선을 준다

**배경이 무엇이 될지 모른다.** 밝은 지면 위에서는 흰 글자가 사라지고, 어두운 동굴에서는
검은 글자가 사라진다. **외곽선 1~2px 이면 어디서든 읽힌다.**

`LabelSettings` 의 실측 기본값은 `outline_size = 0`(없음), `font_size = 16` 이다.
**둘 다 라리엔에는 맞지 않는다** — 크기는 [§8 의 폰트 크기표](#8-theme--디자인을-한-곳에서-관리한다)
대로, 외곽선은 켠다.

| 어디 | 외곽선 |
|---|---|
| **머리 위 이름표·데미지 숫자** (3D 위) | **필수** — `outline_size` 4~6, 색은 검정 |
| 창 안의 글자 (패널 배경 위) | 불필요. 배경색을 우리가 정했으므로 |

---

## 10. 재사용 컴포넌트 — UI 를 씬으로 쪼갠다

**같은 모양이 두 번 나오면 씬으로 뺀다.** 스킬 버튼 6개를 손으로 6번 만들면
아이콘 위치를 바꿀 때 6번 고쳐야 한다.

### 무엇을 씬으로 뺄 것인가

| 뺀다 | 빼지 않는다 |
|---|---|
| **여러 번 나오는 것** — 스킬 버튼, 인벤토리 칸, 아이템 줄, 파티원 카드 | 한 번만 나오는 화면 전체 배치 |
| **혼자 테스트하고 싶은 것** — 대화창, 상점 패널 | 단순 `Label` 하나 |
| **다른 화면에서도 쓸 것** — 확인 대화상자, 로딩 스피너 | |

### 만드는 법 — `class_name` + `@export` + setter

```gdscript
@tool
class_name SkillButton
extends Button

@export var skill_icon: Texture2D:
	set(value):
		skill_icon = value
		if is_node_ready():
			%Icon.texture = value

@export var cooldown_seconds: float = 0.0:
	set(value):
		cooldown_seconds = value
		if is_node_ready():
			%Cooldown.max_value = maxf(value, 0.001)

func _ready() -> void:
	custom_minimum_size = Vector2(140, 140)     # 터치 최소 크기 (§12.2)
	%Icon.texture = skill_icon
```

**세 가지가 함께 작동한다.**

| 요소 | 하는 일 |
|---|---|
| **`@tool`** | **에디터에서도 스크립트가 돈다** — 아이콘을 지정하는 순간 뷰포트에 바로 보인다 |
| **`@export` + setter** | 인스펙터에서 값을 넣으면 **즉시 자식 노드에 반영**된다 |
| **`class_name`** | 다른 스크립트에서 `SkillButton` 타입으로 받을 수 있고, 노드 추가 창에도 뜬다 |

> 🛑 **`@tool` 스크립트는 에디터 안에서도 실행된다.** `_ready()` 에서 파일을 지우거나
> 서버에 접속하는 코드를 두면 **에디터가 그걸 실행한다.** 에디터에서 돌면 안 되는
> 것은 `if Engine.is_editor_hint(): return` 으로 막는다.

> **`is_node_ready()` 검사가 필요한 이유** — setter 는 `_ready()` 보다 먼저 불릴 수
> 있다. 그때 `%Icon` 은 아직 없어서 그냥 접근하면 에러가 난다.

### 인스턴싱한 뒤 안을 고치고 싶을 때

`hud.tscn` 안에 넣은 `skill_button.tscn` 의 자식을 건드리려면
**노드 우클릭 → `Editable Children`** 을 켠다.

> 🛑 **켜면 원본과의 연결이 부분적으로 끊긴다.** 원본에서 자식을 지우거나 이름을
> 바꿨을 때 인스턴스 쪽에 찌꺼기가 남을 수 있다. **`@export` 로 해결되는 것은
> `Editable Children` 을 쓰지 않는다.** 그것이 이 절의 요점이다.

---

## 11. UI 애니메이션 — 싸게, 살아있게 만든다

**UI 가 툭툭 나타나고 사라지면 값싸 보인다.** 그런데 UI 애니메이션은 3D 와 달리
**거의 공짜다** — 폴리곤도 조명도 없다. **저사양에서도 아낄 이유가 없는 몇 안 되는
연출**이다.

### `Tween` — 코드 한 줄로 시작한다

```gdscript
func show_panel(panel: Control) -> void:
	panel.modulate.a = 0.0
	panel.show()
	var t := create_tween()
	t.set_trans(Tween.TRANS_CUBIC).set_ease(Tween.EASE_OUT)
	t.tween_property(panel, "modulate:a", 1.0, 0.18)
```

| 하는 것 | 왜 |
|---|---|
| **`set_ease(Tween.EASE_OUT)`** | **끝에서 감속한다.** 같은 시간이어도 훨씬 정돈돼 보인다 |
| `set_trans(Tween.TRANS_CUBIC)` | 곡선 모양. 메뉴에는 `CUBIC`, 튕기는 느낌엔 `BACK`·`ELASTIC` |
| **`0.15 ~ 0.25 초`** | **UI 는 짧아야 한다.** 0.4초를 넘으면 "느린 게임"으로 느껴진다 |

> 🛑 **트윈이 겹치면 값이 싸운다.** 버튼을 연타하면 서로 다른 목표로 끌어당긴다.
> **이전 것을 죽이고 시작한다.**
> ```gdscript
> if _tween and _tween.is_running():
> 	_tween.kill()
> _tween = create_tween()
> ```

### 🔑 4.7 — 레이아웃을 건드리지 않고 흔든다 (`offset_transform`)

**컨테이너 안의 버튼을 움직이면 원래는 레이아웃이 다시 계산된다.** 흔들기 연출
하나가 매 프레임 부모 컨테이너를 재계산시키는 것이다.

**4.7 의 오프셋 변환은 순수한 시각 변환이라 그 문제가 없다.** 실측 기본값이다.

| 속성 | 기본값 | |
|---|---|---|
| `offset_transform_enabled` | `false` | 🛑 **켜야 나머지가 동작한다** |
| `offset_transform_position` | `Vector2(0, 0)` | 시각적으로만 이동 |
| `offset_transform_rotation` | `0.0` | |
| `offset_transform_scale` | `Vector2(1, 1)` | |
| **`offset_transform_visual_only`** | **`true`** | **터치 판정은 원위치에 그대로 남는다** |
| `offset_transform_pivot_ratio` | `Vector2(0.5, 0.5)` | 기본 중심 기준 |

```gdscript
# 피격 시 체력바 흔들기 — 레이아웃도 터치 판정도 건드리지 않는다
hp_bar.offset_transform_enabled = true
var t := create_tween()
t.tween_property(hp_bar, "offset_transform_position", Vector2(6, 0), 0.04)
t.tween_property(hp_bar, "offset_transform_position", Vector2(-6, 0), 0.04)
t.tween_property(hp_bar, "offset_transform_position", Vector2.ZERO, 0.04)
```

> **이전에는 `position` 을 흔들면 클릭 영역까지 함께 움직여** 연타 중에 빗나갔다.
> `offset_transform_visual_only` 가 기본 `true` 라 그 문제가 사라진다.

### 화면 전환 — 페이드는 최상위 층에서

[§1 의 층 배치](#1-네-개의-기둥--control--container--theme--canvaslayer)에서
**`layer = 100` 을 로딩·페이드용으로 비워 둔 이유**가 이것이다.

```gdscript
extends CanvasLayer            # layer = 100, process_mode = ALWAYS

@onready var fade: ColorRect = %Fade      # 검은 ColorRect, PRESET_FULL_RECT

func change_scene(path: String) -> void:
	fade.mouse_filter = Control.MOUSE_FILTER_STOP   # 전환 중 입력 차단
	var t := create_tween()
	t.tween_property(fade, "modulate:a", 1.0, 0.2)
	await t.finished
	get_tree().change_scene_to_file(path)
	var t2 := create_tween()
	t2.tween_property(fade, "modulate:a", 0.0, 0.2)
	await t2.finished
	fade.mouse_filter = Control.MOUSE_FILTER_IGNORE
```

**전환 중에 `mouse_filter` 를 `STOP` 으로 올리는 것이 요령이다.**
페이드가 덮인 동안 아래 버튼이 눌리는 것을 막는다.

> 🛑 **존 전환은 씬 교체가 아니다.** 라리엔의 존 이동은 **서버 계약**이라
> 클라이언트가 마음대로 씬을 바꾸는 것이 아니다([SSOT §5](../../game/references/SSOT.md)).
> 위 코드는 **로그인 → 캐릭터 선택 → 게임 진입** 같은 화면 전환에 쓴다.

### 어떤 연출을 넣는가 — 최소 목록

| 대상 | 연출 | 시간 |
|---|---|---|
| 창 열기·닫기 | 알파 페이드 + `scale` 0.96 → 1.0 | 0.15 s |
| 버튼 누름 | `offset_transform_scale` 0.94 로 눌렀다 복귀 | 0.08 s |
| 체력 감소 | `value` 트윈 (숫자가 흐르게) | 0.2 s |
| 피격 | 화면 가장자리 붉은 비네트 알파 | 0.25 s |
| 획득 알림 | 위로 떠오르며 사라짐 | 0.6 s |

---

## 12. 모바일에서 반드시 해야 하는 3가지

### 12.1 세이프 에어리어 — 노치·홈 인디케이터

**노치 있는 폰에서 상단 UI 가 잘린다.** 화면 크기와 실제로 보이는 영역은 다르다.

```gdscript
extends MarginContainer

func _ready() -> void:
	_apply_safe_area()
	get_viewport().size_changed.connect(_apply_safe_area)

func _apply_safe_area() -> void:
	var safe: Rect2i = DisplayServer.get_display_safe_area()
	var full := DisplayServer.screen_get_size()
	var scale := float(get_viewport().get_visible_rect().size.y) / float(full.y)

	add_theme_constant_override("margin_top", int(safe.position.y * scale))
	add_theme_constant_override("margin_bottom",
		int((full.y - safe.position.y - safe.size.y) * scale))
```

**`DisplayServer.get_display_safe_area()` 는 `Rect2i` 를 돌려준다** (엔진에서 확인).
`get_display_cutouts()` 는 카메라 구멍의 정확한 위치를 `Rect2[]` 로 준다.

> **에디터에서는 전체 화면이 안전 영역으로 나온다.** 이 코드가 맞는지는
> **실기기에서만 확인된다.** → [headless-workflow.md](headless-workflow.md) 의 실기기 실행

### 12.2 터치 최소 크기 — 48dp

**손가락은 마우스 커서보다 훨씬 굵다.** 버튼이 작으면 눌리지 않는다.

| 기준 | 값 |
|---|---|
| 최소 터치 크기 | **48dp** (약 9mm) |
| **1080px 폭 화면에서** | **약 100 ~ 120 px** |
| 스킬 버튼 권장 | **140 × 140 px** 이상 |
| 버튼 사이 간격 | **최소 16px** — 오폭 방지 |

**`custom_minimum_size` 로 강제한다.** 아이콘이 작아도 터치 영역은 크게 잡는다.

```gdscript
skill_button.custom_minimum_size = Vector2(140, 140)
```

### 12.3 엄지 영역 — 손가락이 화면을 가린다

세로 화면에서 **아래쪽 1/3 은 양손 엄지가 덮는다.**

| 영역 | 무엇을 두나 | 무엇을 두지 않나 |
|---|---|---|
| **상단** | 체력·대상 정보·미니맵 | 자주 누르는 버튼 (손이 안 닿는다) |
| **중앙** | 3D 월드 (건드리지 않는다) | 고정 UI |
| **하단 좌** | **이동 조이스틱** | 읽어야 하는 글자 |
| **하단 우** | **스킬·공격 버튼** | 〃 |

> **중요한 글자를 하단에 두지 않는다.** 손가락에 가려 안 보인다.
> 데미지 숫자·시스템 메시지는 **화면 중상단**에 띄운다.

---

## 13. 3D 게임 특유의 함정

### 13.1 UI 가 3D 입력을 먹는다

**증상** — 화면을 눌렀는데 캐릭터가 안 움직인다. 특정 영역에서만 그렇다.

**원인** — `Control` 의 `mouse_filter` 기본값이 **`0`(STOP)** 이라, 화면을 덮는
투명한 컨테이너가 터치를 전부 삼킨다 ([§5](#5-노드-고르기--무엇으로-만들-것인가)).

**해결** — **덮는 것은 전부 `IGNORE`, 누르는 것만 `STOP`.**

```
HUD (CanvasLayer)
├─ Top (MarginContainer)      mouse_filter = IGNORE   ← 덮기만 한다
│  └─ HpBar                   mouse_filter = IGNORE   ← 누를 일 없다
└─ Bottom (MarginContainer)   mouse_filter = IGNORE
   └─ SkillButton             mouse_filter = STOP     ← 이것만 먹는다 (기본값)
```

### 13.2 월드 스페이스 UI — 머리 위 이름표·HP바

캐릭터 머리 위에 뜨는 것은 **화면 UI 가 아니라 3D 공간의 물체**다. 방법이 셋이다.

| 방법 | 비용 | 언제 |
|---|---|---|
| **`Label3D`** | **가장 싸다** | **이름표 — 라리엔은 이것** |
| `Sprite3D` | 싸다 | 아이콘·상태 표시 |
| `SubViewport` + `QuadMesh` | **비싸다** | 인터랙티브 UI. **몹에는 쓰지 않는다** |
| `Camera3D.unproject_position()` + 2D `Control` | 중간 | 정확한 화면 정렬이 필요할 때 |

> 🛑 **근거리 AOI 상한이 82개**다 ([SSOT §4](../../game/references/SSOT.md)).
> 82개 전부에 `SubViewport` UI 를 붙이면 그것만으로 예산이 끝난다.
> **원거리 54개는 임포스터**라 이름표를 아예 그리지 않고, 근거리 8개 정도에만 붙인다.

`Label3D` 는 `billboard` 를 켜서 항상 카메라를 보게 한다.
**카메라 yaw 가 고정이라** ([SSOT §1](../../game/references/SSOT.md)) 빌보드 회전이
매 프레임 바뀌지 않는다 — 고정 시점이 여기서도 비용을 아낀다.

### 13.3 미니맵이 회전하지 않아도 된다

**카메라 yaw 고정의 부수 효과다.** 플레이어 시선 방향이 항상 같으므로
미니맵을 회전시킬 이유가 없다. **정적 텍스처 한 장 + 점 몇 개**로 끝난다.

자유 시점 게임이라면 미니맵을 매 프레임 회전시켜야 하고, 그만큼 비싸진다.

---


### 13.4 🛑 세로 화면에서 `Camera3D.keep_aspect` 를 확인한다

**UI 문서에 3D 카메라 이야기가 들어오는 이유** — 세로 화면에서 **화면에 보이는 월드의
범위**가 달라지고, 그것이 HUD 가 무엇을 가리는지와 직접 얽히기 때문이다.

`Camera3D.keep_aspect` 의 실측 기본값은 **`1` (`KEEP_HEIGHT`)** 이다.

| 값 | 뜻 | 세로 9:16 화면에서 |
|---|---|---|
| `0` `KEEP_WIDTH` | **가로** 시야를 유지하고 세로가 늘어난다 | 좌우 시야가 보장된다 |
| **`1` `KEEP_HEIGHT` (기본)** | **세로** 시야를 유지하고 가로가 줄어든다 | 🛑 **좌우가 극도로 좁아진다** |

**`fov = 75.0`(실측 기본값)은 세로 방향 화각**이다. 가로 16:9 에서는 넓게 보이지만,
세로 9:16 에서는 **같은 fov 로도 좌우가 절반 이하**가 된다.

공식 문서도 **세로 모드에서는 `Keep Width` 를 고려하라**고 적고 있다.

> 🛑 **다만 이 값을 임의로 바꾸지 않는다.** 카메라가 보여주는 범위는
> [SSOT §6](../../game/references/SSOT.md) 의 **줌 상한 ↔ 서버 AOI 계약**에 묶여 있다.
> SSOT 의 계산은 **1920×1080·2560×1440 가로 기준**으로 적혀 있는데,
> **모바일은 1080×1920 세로**다. 즉 **세로 화면에서의 화면 코너까지 거리를 다시 계산해
> 봐야 하고, 그 결과에 따라 `keep_aspect` 판단이 갈린다.**
>
> **이것은 사람이 판단할 사항이다** ([CLAUDE.md](../../../../CLAUDE.md) — SSOT 와
> 어긋나 보이면 측정값과 함께 보고하고 승인을 받는다). 클라이언트에서 값만 바꾸면
> **화면 가장자리 몹이 사라지는 버그**로 나타난다.

---

## 14. 성능 — UI 도 공짜가 아니다

**최소 지원 사양은 3GB RAM Android 다**
([performance-mobile.md](performance-mobile.md) §0). UI 도 예산 안에서 짠다.

| 규칙 | 이유 |
|---|---|
| 🛑 **`_process` 에서 `Label.text` 를 매 프레임 바꾸지 않는다** | 텍스트가 바뀌면 **폰트 레이아웃을 다시 계산**한다. 값이 바뀔 때만 갱신한다 |
| **`RichTextLabel` 을 남용하지 않는다** | BBCode 파싱 + 서식 계산이 `Label` 보다 훨씬 비싸다 |
| **안 보이는 UI 는 `hide()`** | 숨긴 `Control` 은 그리지도 계산하지도 않는다 |
| **인벤토리 칸을 미리 다 만들지 않는다** | 200칸을 항상 들고 있지 말고 열 때 만든다 |
| **UI 텍스처도 아틀라스로 묶는다** | [SSOT §3.1](../../game/references/SSOT.md) 의 번들 용량 규칙이 UI 에도 적용된다 |
| **`CanvasLayer` 를 필요 이상 만들지 않는다** | 층마다 그리기 패스가 하나씩 는다 |
| **컨테이너를 깊게 겹치지 않는다** | 크기가 바뀔 때마다 위에서 아래로 재계산한다 → [§4](#4-컨테이너-고르기) |
| **`offset_transform` 으로 애니메이션한다** | `position` 을 흔들면 부모 컨테이너가 매 프레임 다시 계산한다 → [§11](#11-ui-애니메이션--싸게-살아있게-만든다) |
| 🛑 **MSDF 폰트를 켜지 않는다** | 저사양 모바일에서 폰트 렌더링 기본 비용이 오른다 → [§9](#9-폰트--한글이-먼저다) |

**값이 바뀔 때만 갱신하는 패턴:**

```gdscript
var _shown_hp: int = -1

func _on_snapshot(hp: int) -> void:
	if hp == _shown_hp:
		return                       # 같은 값이면 아무것도 하지 않는다
	_shown_hp = hp
	hp_text.text = str(hp)
```

---


### 드로우콜을 줄이는 가장 큰 한 수 — 테마 아틀라스

**UI 도 드로우콜을 쓴다.** 그리고 UI 의 드로우콜은 대부분 **텍스처가 바뀌는 지점**에서
생긴다. 버튼 배경·아이콘·테두리가 제각각 다른 이미지 파일이면 **그 개수만큼 콜이 늘어난다.**

| 하는 것 | 결과 |
|---|---|
| 🛑 UI 이미지를 파일마다 따로 둔다 | 위젯 수십 개 = 드로우콜 수십 개 |
| ✅ **UI 텍스처를 아틀라스 한 장으로 묶는다** | **수십 개가 한 콜로 접힌다** |
| ✅ `StyleBoxFlat` 을 쓴다 (이미지 없이 그림) | 텍스처 자체가 없다 |

**라리엔의 UI 는 `StyleBoxFlat` 을 기본으로 하고, 아이콘만 아틀라스로 묶는 방식이 맞다.**
[SSOT §3.1](../../game/references/SSOT.md) 의 "재질 단위 아틀라스 공유" 규칙이
3D 모델뿐 아니라 **UI 에도 그대로 적용**된다.

### 측정은 실기기에서만 유효하다

> 🛑 **에디터 프로파일러는 데스크톱 GPU 를 보여준다.** 모바일 GPU 는 드로우콜과
> 픽셀 채우기에 훨씬 민감하다. **UI 를 다 올린 상태로, AOI 82개를 채운 채,
> 실기기에서** 잰다 ([SSOT §3](../../game/references/SSOT.md) 측정 규칙).

**UI 가 성능을 먹고 있는지 빠르게 가리는 법** — HUD 의 `CanvasLayer` 를
`visible = false` 로 껐다 켰다 하면서 프레임을 본다. 차이가 크면 UI 문제다.

---

## 15. 접근성 — 4.5 부터 스크린 리더가 붙는다

Godot 4.5 가 **AccessKit** 을 통합하면서 `Control` 노드가 **운영체제의 스크린 리더에
직접 노출**된다. 별도 애드온 없이 엔진이 접근성 트리를 만들어 OS 에 밀어 넣는다.

**`Control` 에 접근성 속성이 실제로 들어와 있다** (엔진에서 확인):

| 속성 | 기본값 | 무엇 |
|---|---|---|
| `accessibility_name` | `""` | **읽어줄 이름.** 아이콘만 있는 버튼에 필수 |
| `accessibility_description` | `""` | 보조 설명 |
| `accessibility_live` | `0` | 값이 바뀌면 알릴지 (알림·경고 영역) |
| `accessibility_labeled_by_nodes` | `[]` | 이 컨트롤을 설명하는 `Label` 을 지정 |
| `accessibility_described_by_nodes` | `[]` | 〃 |
| `accessibility_controls_nodes` | `[]` | 이 컨트롤이 조작하는 대상 |
| `accessibility_flow_to_nodes` | `[]` | 논리적 다음 순서 |

### 라리엔에서 최소한 할 것

**전부 채울 필요는 없다.** 비용 대비 효과가 큰 것부터 한다.

| 우선 | 대상 | 무엇 |
|---|---|---|
| **1** | **아이콘만 있는 버튼** (스킬·설정·닫기) | `accessibility_name` 을 넣는다. 글자가 없으므로 **읽을 것이 아예 없다** |
| **2** | 체력·경험치 같은 값 표시 | `accessibility_name` 에 "체력" 처럼 무엇인지 |
| 3 | 시스템 알림 영역 | `accessibility_live` 로 갱신을 알림 |

```gdscript
%SkillButton1.accessibility_name = "스킬 1"
%HpBar.accessibility_name = "체력"
```

> **글자가 있는 `Button` 은 대개 그대로도 읽힌다** — 버튼의 `text` 가 이름으로 쓰인다.
> 문제는 **아이콘 버튼**이다. 라리엔의 하단 스킬 버튼이 정확히 그 경우다.

> ⚠️ **스크린 리더 지원은 아직 새 기능이고 실험적 단계**라고 공지되어 있다.
> 모바일에서의 동작은 **실기기에서 확인해야** 한다. 다만 위 속성을 채워 두는 것은
> **비용이 거의 0** 이고, 나중에 지원이 성숙했을 때 그대로 효과를 본다.

### 접근성은 스크린 리더만이 아니다

**실제로 더 많은 사람에게 닿는 것은 이쪽이다.**

| 항목 | 라리엔에서 |
|---|---|
| **글자 크기** | 설정에 "UI 크기" 를 두고 `content_scale_factor` 로 조절 → [§0](#0-먼저--이-프로젝트의-화면은-두-가지다) |
| **대비** | 3D 위의 글자는 **외곽선**으로 대비를 보장 → [§9](#9-폰트--한글이-먼저다) |
| **터치 크기** | 48dp 최소 → [§12.2](#122-터치-최소-크기--48dp) |
| **색만으로 구분하지 않기** | 적/아군을 색으로만 나누지 않고 **모양·아이콘**도 다르게 |
| **깜빡임 자제** | 빠른 점멸은 광과민성 발작을 유발할 수 있다 |

---

## 16. 자주 하는 실수

| 증상 | 원인 | 해결 |
|---|---|---|
| **UI 가 왼쪽 위에 뭉친다** | 루트 `Control` 이 `PRESET_FULL_RECT` 가 아니다 | Layout → `Full Rect` |
| **자식을 끌어도 제자리로 간다** | 컨테이너가 위치를 덮어쓴다 (정상) | `separation`·`MarginContainer`·`custom_minimum_size` 로 조절 |
| **화면을 눌러도 캐릭터가 안 움직인다** | `mouse_filter` 기본값이 `STOP` | 덮는 것은 전부 `Ignore` |
| **버튼을 눌러도 반응이 없어 보인다** | `hover`·`pressed` `StyleBox` 미정의 | Theme 에 4가지 상태를 다 채운다 |
| **Theme 를 바꿔도 안 바뀌는 노드가 있다** | 개별 오버라이드가 이긴다 | 인스펙터에서 `Theme Overrides` 를 지운다 |
| **해상도를 바꾸면 UI 가 깨진다** | 좌표로 배치했다 | 앵커 + 컨테이너로 다시 짠다 |
| **노치에 가려 안 보인다** | 세이프 에어리어 미적용 | [§12.1](#121-세이프-에어리어--노치홈-인디케이터) |
| **실기기에서 버튼이 안 눌린다** | 터치 영역이 너무 작다 | `custom_minimum_size` 최소 100px |
| **`$Path/To/Node` 가 자꾸 깨진다** | 구조를 바꿀 때마다 경로가 바뀐다 | **`Access as Unique Name`** → `%NodeName` |
| **가상 조이스틱이 안 먹는다** | `Control` 크기를 안 잡았다 (`joystick_size` 와 별개) | 크기를 명시 → [input-ui.md](input-ui.md) §7 |
| **일시정지가 온라인에서 이상하다** | `get_tree().paused` 는 서버를 멈추지 못한다 | 입력만 UI 로 돌린다 ([§7](#7-메뉴-만들기)) |
| **한글이 네모(□)로 나온다** | 내장 기본 폰트에 한글 글리프가 없다 | 폰트를 지정한다 ([§9](#9-폰트--한글이-먼저다)) |
| **`Layout` 메뉴가 회색으로 잠겨 있다** | 부모가 컨테이너다 (정상) | 위치는 부모 컨테이너로 조절한다 ([§2](#2-절대-원칙--좌표로-놓지-않는다)) |
| **버튼을 연타하면 크기가 이상해진다** | 트윈이 겹쳐 서로 다른 목표로 당긴다 | 새 트윈 전에 `kill()` ([§11](#11-ui-애니메이션--싸게-살아있게-만든다)) |
| **게임패드로 메뉴를 쓸 수 없다** | `focus` `StyleBox` 가 없어 커서 위치가 안 보인다 | Theme 에 `focus` 를 채운다 ([§8](#8-theme--디자인을-한-곳에서-관리한다)) |
| **에디터가 게임 코드를 실행한다** | `@tool` 스크립트는 에디터에서도 돈다 | `if Engine.is_editor_hint(): return` ([§10](#10-재사용-컴포넌트--ui-를-씬으로-쪼갠다)) |
| **세로 화면에서 3D 좌우 시야가 좁다** | `Camera3D.keep_aspect` 기본이 `KEEP_HEIGHT` | 🛑 임의로 바꾸지 말고 보고한다 ([§13.4](#134--세로-화면에서-camera3dkeep_aspect-를-확인한다)) |
| **저사양 폰에서 글자가 자글거린다** | UI 가 축소되는데 폰트 밉맵이 꺼져 있다 | `default_font_generate_mipmaps` 검토 ([§9](#9-폰트--한글이-먼저다)) |
| **테마를 적용했는데 누르면 회색으로 돌아온다** | `pressed`·`hover` `StyleBox` 를 안 채웠다 | 5상태를 전부 채운다 ([§8](#8-theme--디자인을-한-곳에서-관리한다)) |

---

## 17. 공식 문서와 참고 자료

### 공식 문서 (Godot Engine)

| 주제 | 링크 |
|---|---|
| UI 전체 | https://docs.godotengine.org/en/stable/tutorials/ui/index.html |
| 크기와 앵커 | https://docs.godotengine.org/en/stable/tutorials/ui/size_and_anchors.html |
| 컨테이너 | https://docs.godotengine.org/en/stable/tutorials/ui/gui_containers.html |
| Theme 에디터 | https://docs.godotengine.org/en/stable/tutorials/ui/gui_using_theme_editor.html |
| **타입 배리에이션** | https://docs.godotengine.org/en/stable/tutorials/ui/gui_theme_type_variations.html |
| **폰트 사용법 (MSDF 포함)** | https://docs.godotengine.org/en/stable/tutorials/ui/gui_using_fonts.html |
| CanvasLayer | https://docs.godotengine.org/en/stable/tutorials/2d/canvas_layers.html |
| **여러 해상도 대응** | https://docs.godotengine.org/en/stable/tutorials/rendering/multiple_resolutions.html |
| **Godot 4.5 릴리스 (접근성)** | https://godotengine.org/releases/4.5/ |
| Godot 4.7 릴리스 | https://godotengine.org/releases/4.7/ |

### 공식 데모 프로젝트 — 받아서 돌려보는 것이 가장 빠르다

| 데모 | 링크 |
|---|---|
| **여러 해상도·종횡비 데모** | https://github.com/godotengine/godot-demo-projects/tree/master/gui/multiple_resolutions |
| MSDF 폰트 데모 | https://github.com/godotengine/godot-demo-projects/blob/master/gui/msdf_font/README.md |

> **해상도 데모는 이 프로젝트에 특히 값어치가 있다.** 세로·가로를 오가며
> stretch 조합이 실제로 어떻게 보이는지 손으로 확인할 수 있다.

### 커뮤니티·강좌 (2024~2026 조사)

| 자료 | 담긴 것 |
|---|---|
| [GDQuest — 컨테이너 개요](https://school.gdquest.com/courses/learn_2d_gamedev_godot_4/start_a_dialogue/all_the_containers) | 컨테이너 선택 기준, **깊게 겹치지 말라**는 근거 |
| [GDQuest — 테마 에디터](https://school.gdquest.com/courses/learn_2d_gamedev_godot_4/telling_a_story/all_theme_editor_areas) | Theme 에디터 영역별 사용법 |
| [Febucci — Godot UI 핵심 개념](https://blog.febucci.com/2024/11/godots-ui-tutorial-part-one/) | Control·앵커·컨테이너가 맞물리는 방식 |
| [Chickensoft — Display Scaling in Godot 4](https://chickensoft.games/blog/display-scaling) | 스케일링 실전 정리 |
| [Josh Anthony — Anchors and Margins and Containers](https://joshanthony.info/2023/04/22/anchors-and-margins-and-containers-godot-my/) | **앵커와 컨테이너를 섞는 실무 감각** |
| [slicker.me — 모바일 최적화 현장 가이드](https://slicker.me/godot/mobile-optimization.html) | 실기기 프로파일링, 드로우콜 |
| [Bugnet — StyleBox 가 상태별로 안 먹을 때](https://bugnet.io/blog/fix-godot-ui-theme-stylebox-not-applying-on-button-state) | **5상태를 다 채워야 하는 이유** |
| [Android 개발자 — Godot 폼팩터 대응](https://developer.android.com/games/engines/godot/godot-formfactor) | 안드로이드 화면 크기 대응 공식 안내 |
| [Saltmire — Godot 4 화면 전환 5가지](https://saltmire.github.io/godot-4-scene-transitions.html) | 페이드·아이리스·디졸브 구현 |
| [godot-font-baker](https://github.com/shiena/godot-font-baker) | **CJK 폰트를 구워 배포 용량·라이선스를 푸는 접근** |

> **이 문서의 수치는 커뮤니티 자료가 아니라 엔진에서 직접 뽑은 것이다.**
> 위 자료들은 **판단의 근거와 관례**를 확인하는 데 썼다. 값이 서로 다르면
> **엔진 실측이 맞다.**

**관련 문서** — 입력·Control API 는 [input-ui.md](input-ui.md),
씬·시그널 기초는 [basics.md](basics.md), 용어는 [dictionary.md](dictionary.md),
성능 예산은 [performance-mobile.md](performance-mobile.md),
불변 결정은 [SSOT.md](../../game/references/SSOT.md) 를 본다.
