# Godot LSP — GDScript 정적 검증

> **이 문서의 내용은 선택이 아니다.** GDScript를 작성하거나 수정한 뒤에는
> 반드시 LSP로 진단해서 오류가 없음을 확인한 뒤 작업을 마친다.

## 목차

1. [핵심 개념 — 왜 LSP인가](#1-핵심-개념--왜-lsp인가)
2. [전제 조건과 설정](#2-전제-조건과-설정)
3. [번들 스크립트 사용법](#3-번들-스크립트-사용법)
4. [필수 워크플로우](#4-필수-워크플로우)
5. [진단 결과 해석](#5-진단-결과-해석)
6. [GDScript 경고 종류](#6-gdscript-경고-종류)
7. [경고 수준 설정](#7-경고-수준-설정)
8. [LSP 프로토콜 상세](#8-lsp-프로토콜-상세)
9. [DAP — 디버그 어댑터](#9-dap--디버그-어댑터)
10. [외부 에디터 연동](#10-외부-에디터-연동)
11. [LSP로 잡히지 않는 것](#11-lsp로-잡히지-않는-것)
12. [문제 해결](#12-문제-해결)

---

## 1. 핵심 개념 — 왜 LSP인가

GDScript는 동적 요소가 있는 언어라 **파일을 열어보는 것만으로는 오류를 알 수 없다.**
오타 난 메서드 이름, 잘못된 타입 대입, 존재하지 않는 프로퍼티는 그 코드가 실제로
실행될 때까지 드러나지 않는다.

Godot 에디터는 내부적으로 완전한 GDScript 파서와 타입 분석기를 갖고 있고,
이를 **Language Server Protocol**로 외부에 노출한다.

```
Godot 에디터 (실행 중)
   └─ GDScript 파서 + 타입 분석기 + 경고 시스템
        └─ LSP 서버 (127.0.0.1:6005)
             ↑ TCP + JSON-RPC
        Claude / VS Code / Neovim
```

### 이 채널만이 제공하는 것

- **타입 오류** — `var x: int = "문자열"`
- **존재하지 않는 메서드/프로퍼티** — `self.nonexistent()`
- **경고** — 미사용 변수, 안전하지 않은 캐스트, 섀도잉
- **정확한 행·열 위치**

`godot --check-only --script`는 **문법 오류만** 잡는다.
타입 검사와 경고는 에디터 프로세스 안에서만 생성되므로 LSP가 유일한 경로다.

### 게임을 실행하기 전에 LSP를 먼저 쓴다

정적 검증으로 잡을 수 있는 문제를 게임 실행으로 찾는 것은 시간 낭비다.
LSP 진단은 1초 안에 끝나고, 게임 실행은 로딩·씬 전환·재현 조건까지 필요하다.

---

## 2. 전제 조건과 설정

### 필수 조건

**Godot 에디터가 대상 프로젝트를 연 채로 실행 중이어야 한다.**
LSP 서버는 에디터 프로세스의 일부이므로 에디터가 꺼져 있으면 접속할 수 없다.

### 에디터 설정

`Editor → Editor Settings → Network → Language Server`

| 항목 | 기본값 | 설명 |
|------|--------|------|
| `Remote Host` | `127.0.0.1` | 바인딩 주소 |
| `Remote Port` | `6005` | LSP 포트 |
| `Enable Smart Resolve` | On | 심볼 해석 강화 |
| `Show Native Symbols In Editor` | Off | 내장 클래스 심볼 노출 |
| `Use Thread` | On | 별도 스레드에서 처리 |

`Network → Debug Adapter`

| 항목 | 기본값 |
|------|--------|
| `Remote Port` | `6006` |
| `Request Timeout` | `1000` |
| `Sync Breakpoints` | On |

### 연결 확인

```bash
# 포트가 열려 있는지 (macOS/Linux)
lsof -iTCP:6005 -sTCP:LISTEN -n -P

# 스크립트로 확인
python3 .claude/skills/godot/scripts/gdscript_lsp.py ping
```

기대 출력:

```
Godot LSP 연결 성공: 127.0.0.1:6005
프로젝트: /Users/thruthesky/apps/game/laryen3d
```

---

## 3. 번들 스크립트 사용법

`.claude/skills/godot/scripts/gdscript_lsp.py`는 표준 라이브러리만 쓰는 LSP 클라이언트다.
설치가 필요 없고 `python3`만 있으면 동작한다.

### diagnose — 가장 많이 쓴다

```bash
# 단일 파일
python3 .claude/skills/godot/scripts/gdscript_lsp.py diagnose res://scenes/player/player.gd

# 여러 파일
python3 .claude/skills/godot/scripts/gdscript_lsp.py diagnose \
    res://scenes/player/player.gd res://scenes/enemies/slime.gd

# git 기준 변경된 .gd 전부 (커밋 전 검증)
python3 .claude/skills/godot/scripts/gdscript_lsp.py diagnose --changed

# JSON 출력 (자동 처리용)
python3 .claude/skills/godot/scripts/gdscript_lsp.py --json diagnose --changed
```

출력 예:

```
GDScript 진단 (1개 파일)
  res://scenes/player/player.gd
    ✗ 8:2 error: Function "undefined_function_call()" not found in base self.
    ✗ 11:15 error: Cannot assign a value of type "String" as "int".
    ! 11:2 warning [UNUSED_VARIABLE]: The local variable "x" is declared but never used in the block.

오류 3개, 경고 1개
```

**종료 코드**

| 코드 | 의미 |
|------|------|
| `0` | 오류 없음 (경고는 있을 수 있음) |
| `1` | 오류 1개 이상 |
| `2` | LSP 연결 실패 또는 실행 오류 |

종료 코드로 분기할 수 있으므로 CI나 훅에 그대로 넣을 수 있다.

### symbols — 파일 구조 파악

파일 전체를 읽지 않고 클래스·함수·변수 목록만 얻는다.
큰 스크립트를 탐색할 때 토큰을 아낀다.

```bash
python3 .claude/skills/godot/scripts/gdscript_lsp.py symbols res://scenes/player/player.gd
```

```
res://scenes/player/player.gd 심볼
    1  class      player.gd  — class player.gd
      3  variable   health  — var health: int = 100
      4  variable   unused_var  — var unused_var: int = 42
      6  method     _ready  — func _ready() -> void
     10  method     typo_test  — func typo_test() -> void
```

### hover — 타입과 정의 확인

특정 위치의 심볼이 무엇인지, 어떤 타입인지 확인한다.
**행·열 번호는 1부터 시작한다.**

```bash
python3 .claude/skills/godot/scripts/gdscript_lsp.py hover res://scenes/player/player.gd 3 5
```

```
	var health: int = 100

Defined in [res://scenes/player/player.gd](file:///...)
```

### definition — 정의로 이동

```bash
python3 .claude/skills/godot/scripts/gdscript_lsp.py definition res://scenes/player/player.gd 42 10
# → res://scripts/base_character.gd:15:6
```

`class_name`으로 등록된 커스텀 클래스나 상속받은 메서드의 실제 위치를 찾을 때 쓴다.

### complete — 자동완성 후보

```bash
python3 .claude/skills/godot/scripts/gdscript_lsp.py complete res://scenes/player/player.gd 42 10
```

어떤 메서드·프로퍼티가 있는지 확인할 때 쓴다.
**컨텍스트에 따라 결과가 비어 있을 수 있다** — Godot의 completion은 커서 앞
문맥(점 표기 등)에 민감하다. 결과가 없으면 `hover`나 클래스 레퍼런스를 쓴다.

### 옵션

```bash
--host 127.0.0.1      # LSP 호스트
--port 6005           # LSP 포트
--project /path       # 프로젝트 루트 (기본: project.godot을 위로 탐색)
--timeout 15          # 요청 타임아웃(초)
--json                # JSON 출력
```

환경변수 `GODOT_LSP_HOST`, `GODOT_LSP_PORT`, `GODOT_LSP_TIMEOUT`으로도 지정할 수 있다.

---

## 4. 필수 워크플로우

### GDScript를 작성·수정한 직후

```bash
python3 .claude/skills/godot/scripts/gdscript_lsp.py diagnose res://수정한파일.gd
```

**오류가 하나라도 남아 있으면 작업이 끝난 것이 아니다.**
"코드를 작성했다"고 보고하기 전에 이 명령이 오류 0개를 반환해야 한다.

### 여러 파일을 건드린 작업 끝에

```bash
python3 .claude/skills/godot/scripts/gdscript_lsp.py diagnose --changed
```

git이 추적하는 변경분 전체를 한 번에 검증한다.

### 오류를 고치는 순환

```
1. diagnose 실행
2. 첫 번째 오류의 파일:행:열을 확인
3. 그 위치를 읽고 수정
4. 다시 diagnose
5. 오류 0개가 될 때까지 반복
```

**한 번에 하나씩 고친다.** 앞선 오류가 뒤의 오류를 유발하는 경우가 많아,
첫 오류를 고치면 나머지가 함께 사라지기도 한다.

### 모르는 API를 쓰기 전에

```bash
# 이 타입에 이런 메서드가 있는지 확인
python3 .claude/skills/godot/scripts/gdscript_lsp.py hover res://scenes/player/player.gd 42 20
```

추측해서 코드를 쓰고 나중에 고치는 것보다, 먼저 확인하는 편이 빠르다.
클래스 레퍼런스가 필요하면
`https://docs.godotengine.org/en/4.7/classes/class_<소문자클래스명>.html`를 조회한다.

### 커밋 전 훅 (선택)

```bash
# .git/hooks/pre-commit
#!/usr/bin/env bash
set -e
if lsof -iTCP:6005 -sTCP:LISTEN -n -P >/dev/null 2>&1; then
    python3 .claude/skills/godot/scripts/gdscript_lsp.py diagnose --changed || {
        echo "GDScript 오류가 있어 커밋을 중단합니다."
        exit 1
    }
else
    echo "Godot 에디터가 실행 중이 아니어서 LSP 검증을 건너뜁니다."
fi
```

---

## 5. 진단 결과 해석

### 필드

| 필드 | 의미 |
|------|------|
| `file` | `res://` 경로 |
| `line` / `column` | **1부터 시작하는** 행·열 |
| `end_line` / `end_column` | 문제 구간의 끝 |
| `severity` | `error` / `warning` / `info` / `hint` |
| `code` | 경고 종류 이름 (오류는 빈 문자열) |
| `message` | 설명 |

### severity별 대응

| severity | 대응 |
|----------|------|
| `error` | **반드시 고친다.** 게임이 실행되지 않거나 런타임에 터진다 |
| `warning` | 대부분 고친다. 의도적이면 `_` 접두사나 `@warning_ignore`로 명시 |
| `info` / `hint` | 참고 |

### 자주 보는 오류 메시지

| 메시지 | 원인 |
|--------|------|
| `Function "X()" not found in base self.` | 메서드 이름 오타, 또는 해당 클래스에 없음 |
| `Cannot assign a value of type "A" as "B".` | 타입 불일치 |
| `Identifier "X" not declared in the current scope.` | 변수 오타, 선언 누락 |
| `Cannot find member "X" in base "Y".` | 프로퍼티가 그 타입에 없음 |
| `Parse Error: Expected ...` | 문법 오류 (들여쓰기, 콜론 누락) |
| `Class "X" hides a global script class.` | `class_name` 중복 |
| `Cannot infer the type of "X" variable...` | `:=` 우변이 Variant |
| `Too many arguments for "X()" call.` | 인자 개수 불일치 |
| `Function "X()" is a static function but was called from an instance.` | 정적/인스턴스 혼동 |

---

## 6. GDScript 경고 종류

`code` 필드에 나타나는 주요 경고와 대응이다.

| 코드 | 의미 | 대응 |
|------|------|------|
| `UNUSED_VARIABLE` | 선언했지만 안 씀 | 제거하거나 `_` 접두사 |
| `UNUSED_LOCAL_CONSTANT` | 미사용 상수 | 제거 |
| `UNUSED_PARAMETER` | 미사용 인자 | `_delta`처럼 `_` 접두사 |
| `UNUSED_SIGNAL` | 발신되지 않는 시그널 | 제거하거나 사용 |
| `UNUSED_PRIVATE_CLASS_VARIABLE` | 미사용 private 멤버 | 제거 |
| `UNTYPED_DECLARATION` | 타입 힌트 없음 | **타입 명시** (이 프로젝트 규칙) |
| `INFERRED_DECLARATION` | `:=` 사용 | 대체로 괜찮음. 엄격 모드에서만 경고 |
| `UNSAFE_PROPERTY_ACCESS` | Variant에서 프로퍼티 접근 | 타입 캐스트 후 접근 |
| `UNSAFE_METHOD_ACCESS` | Variant에서 메서드 호출 | 타입 캐스트 |
| `UNSAFE_CAST` | 안전하지 않은 캐스트 | `is`로 확인 후 `as` |
| `UNSAFE_CALL_ARGUMENT` | 인자 타입 불확실 | 명시적 변환 |
| `UNSAFE_VOID_RETURN` | void 함수의 반환값 사용 | 제거 |
| `RETURN_VALUE_DISCARDED` | 반환값 무시 | 의도적이면 무시 가능 |
| `SHADOWED_VARIABLE` | 상위 스코프 변수 가림 | 이름 변경 |
| `SHADOWED_VARIABLE_BASE_CLASS` | 부모 클래스 멤버 가림 | 이름 변경 |
| `SHADOWED_GLOBAL_IDENTIFIER` | 전역 식별자 가림 (`name`, `position` 등) | **반드시 이름 변경** |
| `NARROWING_CONVERSION` | float → int 암묵 변환 | `int()` 명시 |
| `INT_AS_ENUM_WITHOUT_CAST` | int를 enum에 대입 | 캐스트 |
| `STANDALONE_EXPRESSION` | 효과 없는 표현식 | 오타일 가능성 높음 |
| `STANDALONE_TERNARY` | 결과를 안 쓰는 삼항 | `if`로 변경 |
| `INTEGER_DIVISION` | 정수 나눗셈 | 의도했으면 무시, 아니면 `float()` |
| `REDUNDANT_AWAIT` | 코루틴이 아닌 것에 `await` | 제거 |
| `ASSERT_ALWAYS_TRUE/FALSE` | 항상 참/거짓인 assert | 조건 재검토 |
| `INCOMPATIBLE_TERNARY` | 삼항의 두 분기 타입 불일치 | 타입 통일 |
| `NATIVE_METHOD_OVERRIDE` | 엔진 메서드를 잘못 재정의 | 시그니처 확인 |
| `GET_NODE_DEFAULT_WITHOUT_ONREADY` | `$Node`를 `@onready` 없이 | `@onready` 추가 |
| `ONREADY_WITH_EXPORT` | `@onready` + `@export` 동시 사용 | 둘 중 하나만 |
| `EMPTY_FILE` | 빈 파일 | |
| `DEPRECATED_KEYWORD` | 폐기된 키워드 | 대체 문법 사용 |

### 이 프로젝트의 코딩 가드레일

경고를 줄이는 것 이상으로, 다음 규칙을 따르면 애초에 문제가 생기지 않는다.

| 규칙 | 이유 |
|------|------|
| `:=`는 우변 타입이 확실할 때만 쓴다 | `Object.get()`, 딕셔너리 값, 빈 `[]`/`{}`, 동적 프로퍼티, 불확실한 노드 경로에서 추론하면 Variant가 되어 이후 모든 접근이 unsafe가 된다 |
| `Variant`는 동적 경계에서만 쓰고 `is` 검사 후 `var x: Type`으로 좁힌다 | 타입 검사를 복원한다 |
| `name`, `position`, `rotation`, `scale`, `visible`, `seed`를 변수명으로 쓰지 않는다 | 엔진 멤버를 가려 예측 불가능한 동작을 만든다 |
| `@export`와 `@onready`를 함께 쓰지 않는다 | 인스펙터 값이 `_init()` 시점에 신뢰할 수 없다 |
| 필수 노드는 `@onready var n := $Path as Type` 대신 명시적 타입을 쓴다 | `as`는 실패 시 조용히 `null`이 된다. 타입 선언은 실패를 드러낸다 |
| `await` 뒤에는 `is_instance_valid(self)`와 `is_inside_tree()`를 확인한다 | 대기 중 노드가 제거될 수 있다 |
| 물리·접촉 콜백에서의 씬 트리·콜리전 셰이프·monitoring 변경은 `call_deferred`로 미룬다 | 물리 쿼리 중 상태 변경은 오류를 낸다 |
| enum·캐스트·정수 나눗셈은 명시적으로 쓴다 | 암묵 변환이 조용히 값을 바꾼다 |
| 중첩 타입 컨테이너(`Array[Array[int]]`)는 피한다 | 지원되지 않는다 |

```gdscript
# 나쁨 — 추론 결과가 Variant
var speed := config.get("speed")            # Dictionary.get()은 Variant
var node := get_node("Path")                # 반환 타입 불확실
var items := []                             # Array (요소 타입 없음)

# 좋음
var speed: float = config.get("speed", 5.0)
var node: CharacterBody3D = get_node("Path")
var items: Array[ItemData] = []

# 나쁨 — 조용한 실패
@onready var cam := $Camera3D as Camera3D   # 없으면 null, 오류 안 남

# 좋음 — 타입 불일치가 드러난다
@onready var cam: Camera3D = $Camera3D

# 나쁨 — 엔진 멤버 섀도잉
var name: String = "적"
var position: int = 3

# 좋음
var display_name: String = "적"
var slot_index: int = 3
```

---

## 7. 경고 수준 설정

`Project Settings → Debug → GDScript` 또는 `project.godot`에서 직접 설정한다.

```ini
[debug]

gdscript/warnings/enable=true
gdscript/warnings/exclude_addons=true

; 0 = 무시, 1 = 경고, 2 = 오류로 승격
gdscript/warnings/untyped_declaration=1
gdscript/warnings/inferred_declaration=0
gdscript/warnings/unsafe_property_access=1
gdscript/warnings/unsafe_method_access=1
gdscript/warnings/unsafe_cast=1
gdscript/warnings/unsafe_call_argument=1
gdscript/warnings/shadowed_global_identifier=2
gdscript/warnings/standalone_expression=2
gdscript/warnings/integer_division=1
gdscript/warnings/return_value_discarded=0
gdscript/warnings/unused_variable=1
gdscript/warnings/unused_parameter=0
```

**값이 `2`면 경고가 오류로 승격되어 스크립트가 로드되지 않는다.**
팀 규율을 강제할 때 유효하다. 이 프로젝트는 정적 타입을 쓰므로
`untyped_declaration=1`, `shadowed_global_identifier=2`를 권장한다.

### 코드에서 개별 억제

```gdscript
@warning_ignore("unused_parameter")
func _process(delta: float) -> void:
    pass

# 구간 억제 (4.4+)
@warning_ignore_start("unsafe_method_access")
node.dynamic_call()
node.another_dynamic_call()
@warning_ignore_restore("unsafe_method_access")
```

**억제는 마지막 수단이다.** 먼저 코드를 고칠 수 있는지 검토한다.

---

## 8. LSP 프로토콜 상세

직접 클라이언트를 구현하거나 문제를 진단할 때 필요한 정보다.

### 전송 형식

TCP 위의 JSON-RPC 2.0. 각 메시지는 헤더와 본문으로 구성된다.

```
Content-Length: 123\r\n
\r\n
{"jsonrpc":"2.0","id":1,"method":"initialize","params":{...}}
```

### 핸드셰이크

```
클라이언트 → initialize  { processId, rootUri, rootPath, capabilities }
서버      → 결과         { capabilities, serverInfo }
클라이언트 → initialized (알림)
클라이언트 → textDocument/didOpen  { textDocument: { uri, languageId:"gdscript", version, text } }
서버      → textDocument/publishDiagnostics (푸시 알림)
```

**진단은 요청-응답이 아니라 푸시다.** `didOpen` 후 서버가 알림을 보내오길
기다려야 한다. 오류가 없어도 빈 배열을 푸시하므로, 타임아웃은 곧
LSP 자체의 문제(에디터가 인덱싱 중 등)를 뜻한다.

### 지원 메서드

| 메서드 | 방향 | 용도 |
|--------|------|------|
| `initialize` | 요청 | 핸드셰이크 |
| `initialized` | 알림 | 준비 완료 |
| `textDocument/didOpen` | 알림 | 파일 열기 → 진단 트리거 |
| `textDocument/didChange` | 알림 | 내용 변경 |
| `textDocument/didClose` | 알림 | 파일 닫기 |
| `textDocument/publishDiagnostics` | 서버 푸시 | **진단 결과** |
| `textDocument/completion` | 요청 | 자동완성 |
| `completionItem/resolve` | 요청 | 완성 항목 상세 |
| `textDocument/hover` | 요청 | 타입·문서 정보 |
| `textDocument/definition` | 요청 | 정의 위치 |
| `textDocument/documentSymbol` | 요청 | 문서 심볼 |
| `textDocument/signatureHelp` | 요청 | 함수 시그니처 |
| `workspace/symbol` | 요청 | 프로젝트 전역 심볼 |
| `godot/*` | 확장 | Godot 고유 확장 |

### 좌표계 주의

**LSP는 0부터 시작하는 행·열을 쓴다.** 사람이 읽는 편집기는 1부터 시작한다.
번들 스크립트는 입력을 1-based로 받고 내부에서 변환하며, 출력도 1-based다.
직접 프로토콜을 다룰 때는 `line - 1`, `character - 1` 변환을 잊지 않는다.

### 연결을 오래 유지하지 않는 이유

Godot의 LSP 워크스페이스는 **모든 클라이언트가 공유하는 싱글턴**이다.
장시간 연결을 유지하면 사용자의 VS Code 같은 다른 LSP 클라이언트와 간섭할 수 있다.
번들 스크립트는 매 작업마다 접속 → 처리 → 종료한다.

---

## 9. DAP — 디버그 어댑터

포트 `6006`에서 Debug Adapter Protocol을 제공한다. 실행 중인 게임에
브레이크포인트를 걸고 변수를 검사할 수 있다.

| 기능 | 설명 |
|------|------|
| `setBreakpoints` | 스크립트 경로 + 행 번호에 중단점 |
| 조건부 중단점 | `health < 10` 같은 GDScript 불리언 표현식 |
| `stackTrace` | 호출 스택 (프레임 인덱스, 함수명, 경로, 행) |
| `variables` | 프레임 변수 (`local` / `members` / `global` 스코프) |
| `continue` / `stepIn` / `stepOver` / `stepOut` | 실행 제어 |
| `evaluate` | 중단 지점의 스코프에서 표현식 평가 |

**조건부 중단점의 평가 컨텍스트**는 중단 지점의 **지역 스코프**다.
그 함수의 지역 변수와 `self` 멤버에 접근할 수 있다. SceneTree 루트가 아니다.

DAP를 직접 쓰려면 [ai-tooling.md](ai-tooling.md)의 MCP 도구를 이용하는 편이 쉽다.

---

## 10. 외부 에디터 연동

`Editor → Editor Settings → Text Editor → External`

| 항목 | 설명 |
|------|------|
| `Use External Editor` | 활성화 |
| `Exec Path` | 에디터 실행 파일 |
| `Exec Flags` | 인자 (플레이스홀더 사용) |

플레이스홀더: `{project}`, `{file}`, `{line}`, `{col}`

| 에디터 | Exec Flags |
|--------|-----------|
| VS Code | `{project} --goto {file}:{line}:{col}` |
| Sublime Text | `{project} {file}:{line}:{col}` |
| Emacs | `emacs +{line}:{col} {file}` |
| JetBrains Rider | `{project} --line {line} {file}` |

**Godot 4.5부터는 이 플래그가 자동 감지되므로 수동 입력이 대체로 불필요하다.**

### VS Code DAP 설정

```json
{
    "version": "0.2.0",
    "configurations": [
        {
            "name": "GDScript Godot",
            "type": "godot",
            "request": "launch",
            "project": "${workspaceFolder}",
            "debugServer": 6006
        }
    ]
}
```

### 자동 재로드

`Editor Settings → Text Editor → Behavior → Files → Auto Reload Scripts on External Change`를
켜면 외부에서 파일을 수정했을 때 에디터가 자동으로 다시 읽는다.

**이 옵션이 꺼져 있으면 파일을 고쳐도 LSP 진단이 옛 내용을 기준으로 나올 수 있다.**
반드시 켠다.

---

## 11. LSP로 잡히지 않는 것

LSP는 정적 분석이므로 한계가 있다. 다음은 실행해봐야 알 수 있다.

| 잡히지 않는 것 | 어떻게 확인하나 |
|---------------|----------------|
| 런타임 `null` 참조 | 게임 실행 + 에러 로그 |
| 씬 안의 노드 경로 오타 (`$WrongPath`) | 실행 시 `null` 오류 |
| 시그널 연결 누락 | 동작 확인 |
| 물리·충돌 레이어 설정 실수 | 게임 플레이 |
| 성능 문제 | 프로파일러 |
| `.tscn` 파일의 구조적 오류 | 에디터에서 씬 열기 |
| 리소스 경로 오류 (`load()` 실패) | 실행 시 오류 |
| 논리 오류 | 테스트 |
| 동적 타입 경계 너머의 문제 | 실행 |

**LSP 진단 통과는 "문법과 타입이 맞다"는 뜻이지 "동작한다"는 뜻이 아니다.**
정적 검증 후 실제 실행 확인이 필요하면 [ai-tooling.md](ai-tooling.md)의
MCP 도구로 런타임 상태를 관찰한다.

---

## 12. 문제 해결

| 증상 | 원인 | 해결 |
|------|------|------|
| `접속할 수 없습니다` | 에디터가 꺼져 있음 | Godot 에디터로 프로젝트를 연다 |
| 포트가 다름 | 설정 변경됨 | `Editor Settings → Network → Language Server`에서 확인, `--port`로 지정 |
| `응답 대기 시간 초과` | 에디터가 인덱싱 중 | 몇 초 뒤 재시도, `--timeout` 증가 |
| 진단이 옛 내용 기준 | 에디터가 파일을 다시 안 읽음 | `Auto Reload Scripts on External Change` 켜기 |
| `project.godot을 찾을 수 없습니다` | 다른 디렉터리에서 실행 | `--project`로 경로 지정 |
| 여러 Godot 인스턴스 실행 중 | 포트 충돌 | 두 번째 인스턴스는 다른 포트를 쓴다. `lsof`로 확인 |
| `complete` 결과가 비어 있음 | 커서 문맥 부족 | 정상. `hover`나 클래스 레퍼런스 사용 |
| 경고가 전혀 안 나옴 | 경고 비활성 | `project.godot`의 `gdscript/warnings/enable=true` |
| addons의 경고가 섞여 나옴 | | `gdscript/warnings/exclude_addons=true` |
| 진단은 깨끗한데 실행하면 오류 | 정적 분석의 한계 | 11절 참고 — 실행 확인 필요 |
