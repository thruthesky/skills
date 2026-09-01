# Asset Store — 애드온 찾기·설치·활성화

Godot 에서 남이 만든 에셋·애드온을 가져오는 경로와, **설치된 애드온이 프로젝트에
정확히 무엇을 남기는가**(`addons/` 폴더, `plugin.cfg`, `[editor_plugins]`, `[autoload]`)를
다룬다. AI 도구 애드온의 상세는 [ai-tooling.md](ai-tooling.md) 로 넘긴다.

확인 기준은 **4.7.2.stable** 이다.

---

## 1. 새 Asset Store

`https://store.godotengine.org/`

4.7 에서 기존 **Asset Library(AssetLib)** 를 대체한 새 스토어다.
에디터 상단의 **AssetLib 탭**에서도 같은 목록을 본다.

- 폴리시된 항목 표시와 확대
- 평점 표시
- 백그라운드 스레딩으로 반응성 개선 (목록을 넘길 때 에디터가 멈추지 않는다)

> ⚠️ **2026년 8월 현재 아직 `beta` 표시가 있다.** 화면과 정책이 바뀔 수 있다.

### 설치 전에 반드시 확인할 4가지

| 항목 | 왜 |
|---|---|
| **4.7.x 호환성** | 3.x 용 애드온이 그대로 올라와 있다. `EditorPlugin` API 는 4.0 에서 크게 갈렸다 |
| **라이선스** | MIT·Apache 는 안전하다. GPL 계열은 게임 전체에 전염될 수 있다. 상용 출시 전에 본다 |
| **소스 저장소** | GitHub 링크가 살아 있고 최근 커밋이 있는가. 스토어 사본만 있고 원본이 죽은 애드온은 버그가 나도 고칠 사람이 없다 |
| **에디터 전용인가 런타임 포함인가** | 런타임 코드가 있으면 **빌드에 들어가고 성능·용량에 영향을 준다**. §4 참조 |

### 에셋의 두 종류

| 종류 | 내용 | 설치 후 |
|---|---|---|
| **애드온(플러그인)** | `addons/<이름>/` + `plugin.cfg` | `Project Settings > Plugins` 에서 **활성화해야** 동작한다 |
| **템플릿·프로젝트·에셋 팩** | 씬·메시·텍스처·스크립트 | 활성화 개념이 없다. 파일을 그대로 쓴다 |

---

## 2. 설치 경로 3가지

| 경로 | 방법 | 언제 |
|---|---|---|
| **에디터 AssetLib 탭** | 검색 → Download → Install | 가장 간단. 대부분 이걸로 끝난다 |
| **`.zip` 수동 설치** | 받은 zip 을 열어 `addons/` 를 프로젝트 루트에 푼다 | 스토어에 없는 것, 특정 버전 고정이 필요할 때 |
| **git submodule** | `addons/<이름>` 위치에 서브모듈로 붙인다 | 애드온을 직접 고쳐 쓰거나 버전을 커밋으로 못박을 때 |

셋 다 결과는 같다 — **프로젝트 루트에 `addons/<이름>/` 이 생긴다.**

> 🛑 **설치와 활성화는 사람 개발자가 에디터에서 한다.**
> Claude 는 어떤 애드온을 왜 쓰는지와 활성화 경로만 알려주고,
> `project.godot`·`plugin.cfg`·`.import` 를 편집하지 않는다 (`CLAUDE.md` 작업 규칙).

---

## 3. 활성화가 프로젝트에 남기는 것

### `[editor_plugins]` 섹션

`project.godot` 의 이 섹션이 **에디터 플러그인(`EditorPlugin`) 활성화 목록**이다.

```ini
[editor_plugins]

enabled=PackedStringArray("res://addons/godot_ai/plugin.cfg")
```

| 요소 | 의미 |
|---|---|
| `enabled` | 현재 프로젝트에서 **켜져 있는** 플러그인들의 `plugin.cfg` 경로 배열. **여기 적힌 것만** 에디터가 로드한다 |
| `PackedStringArray(...)` | Godot 의 문자열 배열 타입. 플러그인이 여러 개면 쉼표로 계속 나열된다 |

이 값은 `Project > Project Settings > Plugins` 탭에서 **체크박스를 켜고 끌 때 에디터가
자동으로 써 넣는다. 직접 편집하는 항목이 아니다.**

### 로드 순서

```
에디터 기동
  → enabled 목록의 plugin.cfg 를 읽는다
  → plugin.cfg 의 script= 값(보통 plugin.gd)을 로드한다
  → 그 스크립트는 @tool extends EditorPlugin 이므로 에디터 프로세스 안에서 실행된다
  → _enter_tree() 에서 독(Dock) 추가 · 메뉴 추가 · 오토로드 등록 등을 수행한다
```

**게임 실행 파일에는 포함되지 않는다.** 에디터 전용이므로 익스포트한 빌드에 영향이 없다.

### `plugin.cfg` 의 구조

```ini
[plugin]

name="Godot AI"
description="MCP server and AI tools for Godot"
author="..."
version="3.1.2"
script="plugin.gd"        ← 이 파일이 EditorPlugin 을 extends 한다
```

---

## 4. 함정 — 애드온이 `[autoload]` 를 심는 경우

플러그인이 `_enter_tree()` 에서 `add_autoload_singleton()` 을 호출하면
`project.godot` 에 오토로드가 **자동으로 추가된다.**

```ini
[autoload]

_mcp_game_helper="*res://addons/godot_ai/runtime/game_helper.gd"
```

여기서 중요한 구분이 있다.

| | `plugin.gd` | 오토로드 스크립트 |
|---|---|---|
| 도는 프로세스 | **에디터** | **실행 중인 게임** |
| 익스포트 빌드 포함 | ❌ 안 됨 | ✅ **포함된다** |
| 역할 | 독·메뉴·기즈모 추가 | 런타임 로그 수집, 게임 화면 캡처, 노드 조회 등을 에디터로 되돌려 보냄 |

**즉 "에디터 전용 플러그인"이라고 해서 런타임 비용이 0 인 것이 아니다.**
오토로드가 붙었다면 그 스크립트는 게임과 함께 돌고 빌드에도 들어간다.
개발용 애드온이라면 **릴리즈 빌드 전에 플러그인을 끄거나** 익스포트 프리셋에서
`addons/` 를 제외하는 것을 검토한다.

### 설치 후 확인 절차

```bash
# 1. 애드온이 project.godot 에 무엇을 남겼는지 본다
grep -A5 -E '^\[(editor_plugins|autoload)\]' project.godot

# 2. 런타임 코드가 있는지 본다 (@tool 이 없는 .gd 는 게임에서 돈다)
grep -rL '@tool' addons/<이름> --include='*.gd'
```

---

## 5. 이 프로젝트에서 쓰는 애드온

**현재 라리엔 3D 에는 활성화된 애드온이 없다.** `project.godot` 에 `[editor_plugins]` 도
`[autoload]` 도 없고 `addons/` 폴더 자체가 없는 상태다.

애드온을 도입한다면 이 표를 갱신한다.

| 애드온 | 용도 | 런타임 오토로드 | 문서 |
|---|---|---|---|
| **Godot AI** (`godot_ai`) | 에디터 안에 MCP 서버를 띄워 AI 가 씬·노드·스크립트를 조작 | ✅ `_mcp_game_helper` | [ai-tooling.md](ai-tooling.md) |
| Terrain3D | 대규모 야외 지형 (내장 터레인 에디터가 없다) | — | [level-design.md](level-design.md) |

> 애드온을 늘리기 전에 **엔진 내장 기능으로 되는지 먼저 본다.** 애드온은 엔진 업그레이드마다
> 깨질 수 있는 의존성이고, 이 프로젝트는 모바일 용량 예산이 빠듯하다.
