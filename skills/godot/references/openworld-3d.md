# 오픈월드 만들기 — 크기는 처음부터, 콘텐츠는 중앙부터

넓은 야외 맵을 어떻게 짜는가를 다룬다. 실내·던전 블록아웃은
[level-design.md](level-design.md), 용어는 [dictionary.md](dictionary.md),
성능 측정 절차는 [performance-mobile.md](performance-mobile.md)에 있다.

수치는 **엔진에서 직접 만들어 측정한 것**이며 확인 기준은 **4.7.2.stable** 이다.

> 🛑 라리엔 3D 의 맵 규칙(카메라 3축 고정 · 드로우콜 300 · 청크 250m · 상주 3×3)은
> [`game` 스킬의 SSOT.md](../../game/references/SSOT.md) 가 최종 권위다.
> 이 문서는 **그 규칙을 엔진에서 어떻게 구현하는가**를 담는다.

---

## 0. 제1원칙 — 크기는 처음부터 최종값, 콘텐츠는 중앙부터 넓힌다

오픈월드를 만들 때 가장 자주 나오는 계획이 이것이다.

> "작게 5×5m 로 시작해서 1m 씩 조금씩 키워 나가자."

**이렇게 하면 안 된다.** 늘려야 할 것은 맵의 크기가 아니라 **채워진 영역**이다.

| | 처음에 | 나중에 |
|---|---|---|
| **맵의 물리적 크기**(`world_size`) | ✅ **최종값으로 고정** | ❌ 바꾸지 않는다 |
| **실제로 채운 영역** | 중앙 100m 만 | ✅ **중앙에서 바깥으로 넓힌다** |
| **보이는 거리**(`view_distance`) | 짧게 | ✅ 콘텐츠가 늘면 함께 늘린다 |

**4km 맵을 만들어 놓고 중앙 100m 만 채운다.** 나머지 15.99km² 는 빈 풀밭으로 둔다.
그래도 된다 — 빈 청크는 **아예 만들어지지 않으므로 비용이 0** 이다(§4).

왜 크기를 먼저 고정하는가는 다음 절의 측정이 답한다.

---

## 1. 맵 크기는 연속적인 값이 아니라 계단이다

크기를 바꿔 가며 실제로 만들어 재 봤다. 같은 코드에 `world_size` 만 바꾼 결과다.

```
맵                    청크수     상주   메모리비율   노드수   정밀도(m)
5 m (방 하나)          1×1        1     100.0%       20     0.0000
50 m (마당)            1×1        1     100.0%       20     0.0000
250 m (작은 사냥터)     1×1        1     100.0%       20     0.0000
1 km (마을+들판)        4×4       16     100.0%       35     0.0000
1.25 km               5×5        9      36.0%       28     0.0001
1.5 km                6×6       16      44.4%       35     0.0001
2 km                  8×8       16      25.0%       35     0.0001
4 km                 16×16       16       6.2%       35     0.0001
16 km (대륙)          64×64       16       0.4%       35     0.0005
```

**1km 까지는 스트리밍이 아무 일도 하지 않는다(100%).** 짜 놓은 코드가 통째로 놀고 있다.

계산으로 경계가 나온다. 상주 반경 1(3×3)에 미리 로딩분을 더하면 최대
(2r+2)² = **16개**가 필요하므로, **맵의 청크 수가 16개 이하이면 전부 상주한다.**
250m 청크 기준 한 축 4칸 = 1km 다. 따라서 —

| | 크기 (250m 청크 기준) |
|---|---|
| **스트리밍이 일하기 시작하는 지점** | 한 축 **5칸 = 1.25km** |
| **효과가 뚜렷해지는 지점** | 한 축 8칸 = **2km** (25% 이하) |
| **본격적인 오픈월드** | **4km** (6.2%) |

> ⚠️ **비율 열을 단독으로 읽으면 안 된다.** 1.25km 가 36% 로 1.5km(44.4%)보다
> 낮은 것은 스트리밍이 더 잘 돼서가 아니라 **상주 수가 9개였기 때문**이다.
> 상주 수는 **관찰자가 청크 중심에 있는지 경계에 있는지에 따라 9~16 사이에서
> 오간다** — 경계에 있으면 `preload_margin` 이 네 방향에 다 걸려 16개가 된다.
> 이것이 §4 의 `resident_capacity()`(9)와 `resident_peak()`(16)의 차이이며,
> **정상 동작이다.** 검증 기준을 9로 잡으면 멀쩡한 동작이 실패로 잡힌다.

### 규모별로 필요한 것이 통째로 달라진다

| 규모 | 필요한 것 | 이 구간에서 |
|---|---|---|
| **~50m** | 평면 1장 + 콜리전 1개 | 컬링·LOD·스트리밍이 전부 **무의미**하다 |
| **~500m** | + 시야 거리·안개 | 여기서 처음 "지평선을 어떻게 가릴까"가 생긴다 |
| **1.25km~** | + **청크 스트리밍** · 원경 지면 | 스트리밍이 비로소 일한다(한 축 5칸) |
| **2km~** | + LOD · 임포스터 | 먼 캐릭터를 통짜로 그릴 수 없어진다 |
| **100km~** | + floating origin | float 좌표가 끊기기 시작한다 |

**5m → 6m → 7m 로 키우면 1.25km 까지 아무 일도 일어나지 않다가, 그 뒤에 전부 다시
만들게 된다.**
계단을 보지 못하고 걷는 것과 같다.

### 1m 씩 키우기가 특히 위험한 이유 세 가지

| 이유 | 내용 |
|---|---|
| **스케일 감각이 틀어진다** | 5m 맵에서 8m/s 는 "0.6초에 횡단"이다. 그 감각으로 잡은 속도·건물 크기·카메라 거리는 4km 에서 전부 다시 잡아야 한다 |
| **성능 문제가 보이지 않는다** | 드로우콜 20개로 개발하다 갑자기 3000개가 된다. 그때는 이미 만든 것이 많아 되돌리기 어렵다 |
| **전제가 다르다** | 5m 방은 조명 하나로 끝나지만, 4km 야외는 그림자 거리·안개·원경 처리가 얽힌다 |

### float 정밀도 — 크기의 물리적 상한

32비트 float 는 값이 커질수록 촘촘함을 잃는다. 맵 가장자리에서 표현 가능한 최소 간격이
위 표의 `정밀도` 열이다. 4km 에서 0.1mm, 16km 에서 0.5mm 로 아직 여유가 있다.
**1mm 를 넘어가면 위치가 눈에 띄게 끊기므로**, 그보다 큰 맵은 floating origin
(원점을 주기적으로 플레이어 쪽으로 옮기는 기법)이 필요해진다.

```gdscript
## 맵 가장자리에서 float 좌표가 표현할 수 있는 최소 간격(m).
func float_precision(distance: float) -> float:
	if distance <= 0.0:
		return 0.0
	# float 가수부 24비트 → 상대 정밀도 2^-23
	# floor() 가 아니라 floorf() 다 — floor() 는 Vector 도 받아 Variant 를 돌려준다.
	var exponent := floorf(log(distance) / log(2.0))
	return pow(2.0, exponent - 23.0)
```

---

## 2. 처음에 정할 값 — 되돌리기 비싼 것들

이 넷은 **나중에 바꾸면 만든 것 대부분을 다시 만든다.** 첫날 정하고 문서에 못 박는다.

| 값 | 권장 | 왜 되돌리기 어려운가 |
|---|---|---|
| **`world_size`** | 최종 규모 | 위 §1 의 계단 전체가 이 값에 달려 있다 |
| **`chunk_size`** | 250m (SSOT §5) | 상주 수·미리 로딩·기물 배치 단위가 전부 여기 묶인다 |
| **1 유닛 = 1 미터** | 고정 | 바꾸면 물리 상수·카메라·애니메이션이 동시에 어긋난다 |
| **카메라 자유도** | 3축 고정 (SSOT §1) | 풀면 임포스터·LOD·아트 물량이 함께 무너진다 |

**최종 크기를 정하지 못하겠으면 4km 로 잡는다.** 아래 구조가 16km 까지
코드 변경 없이 간다는 것이 §1 의 측정으로 확인됐다.

---

## 3. 지면은 3층으로 나눈다

4000m 평면 한 장으로 만들어도 그려지기는 한다. 문제는 그 위에 나무·몹·기물을
올리는 순간이다 — **화면 밖은 컬링이 안 그려 줄 뿐, 트리에 있는 것은 메모리를 그대로 쓴다.**
그래서 "안 보이니 괜찮다"가 아니라 **아예 만들지 않는** 쪽으로 짠다.

| 층 | 무엇 | 드로우콜 | 역할 |
|---|---|---|---|
| **① 원경 지면** | `world_size` 평면 **한 장** | **1** | 상주 범위 밖을 받쳐 준다 |
| **② 상주 청크** | 관찰자 주변 (2r+1)² 개만 존재 | ≤ 9 | 기물·풀·콜리전이 얹히는 자리 |
| **③ 랜드마크·식생** | `MultiMesh` 하나 | **1** | 몇 개를 세워도 드로우콜 1 |

### ①이 없으면 시야를 멀리 둘 수 없다

상주 범위가 250m 인데 카메라 `far` 가 1200m 면, **청크가 없는 곳이 빈 하늘로 보인다.**
평면 한 장이 그 아래를 받쳐 주면 구멍이 사라진다.
**"멀리 보이되 디테일은 가까이만"을 가장 싸게 만드는 방법이다.**

```gdscript
func _build_distant_ground() -> void:
	var mesh := PlaneMesh.new()
	mesh.size = Vector2(config.world_size, config.world_size)
	# PlaneMesh 는 기본이 orientation = FACE_Y 라 XZ 평면에 눕고 위(+Y)를 본다.

	var node := MeshInstance3D.new()
	node.name = "DistantGround"
	node.mesh = mesh
	node.material_override = _make_ground_material(config.color_distant)
	# 🛑 청크와 같은 높이(y=0)에 두면 z-fighting 으로 화면이 지글거린다.
	node.position = Vector3(0.0, -config.distant_ground_drop, 0.0)   # 0.05m
	node.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	add_child(node)
```

**원경 평면의 색은 청크 두 톤의 중간으로 잡는다.** 그래야 상주 경계가 눈에 띄지 않는다.

### ②의 체커 두 톤 — 스케일을 눈에 보이게

청크를 두 가지 톤으로 번갈아 칠하면 격자가 보여 **거리를 가늠할 수 있다.**
단색 4km 평지에서는 달려도 움직인 것 같지 않다. 단색이 필요하면 두 색을 같게 하면 된다.

---

## 4. 청크 스트리밍

핵심은 **"관찰자 주변만 트리에 존재한다"** 이다. 나머지는 만들지 않는다.

### 상주 판정

```gdscript
## 지금 상주해야 할 청크 좌표 범위.
func _desired_range() -> Rect2i:
	var pos := _observer_position()
	var radius := config.resident_radius
	var margin := config.preload_margin

	# 상주는 **청크 좌표 기준 반경**이다 (SSOT §5 = 3×3).
	# 미터 거리로 잡으면 반경 안에 몇 열이 들어오는지가 청크 크기에 따라
	# 달라져, 3×3 이 4×4 가 되어 버린다.
	#
	# preload_margin 은 여기에 더하는 것이 아니라 **중심을 옮기는 데** 쓴다.
	# 경계에서 margin 안쪽에 있으면 그 방향 좌표가 이웃 청크로 넘어가므로,
	# 결과적으로 진행 방향 한 열이 미리 붙는다.
	var lo := coord_at(pos.x - margin, pos.z - margin) - Vector2i(radius, radius)
	var hi := coord_at(pos.x + margin, pos.z + margin) + Vector2i(radius, radius)

	var last := config.chunk_count() - 1
	lo = Vector2i(clampi(lo.x, 0, last), clampi(lo.y, 0, last))
	hi = Vector2i(clampi(hi.x, 0, last), clampi(hi.y, 0, last))
	return Rect2i(lo, hi - lo + Vector2i.ONE)
```

**미리 로딩을 예측 로직으로 만들지 않는다.** 판정 중심을 `preload_margin` 만큼
밀어 두면, 경계에 다가가는 것만으로 그 방향 한 열이 자연히 범위에 들어온다.

### 네 가지 장치

| 장치 | 값 | 없으면 |
|---|---|---|
| **상주 반경** | 1 → 3×3 = 9개 | — |
| **미리 로딩** | 경계 50m 전 | 경계를 넘는 순간 앞이 비어 보인다 |
| **지연 해제** | 4초 | 경계를 왔다 갔다 하면 로드/언로드가 반복된다 |
| **프레임 예산** | 2개/프레임 | 청크가 무거워지면 프레임이 통째로 멈춘다 |

### 🛑 순간이동 예외 — 놓치기 쉬운 곳

지연 해제는 "경계를 왔다 갔다 할 때"를 위한 장치다. **텔레포트·존 이동으로 범위가
통째로 바뀌었다면 돌아올 일이 없다.** 그대로 두면 옛 청크가 4초 동안 남아
**메모리가 잠시 두 배**가 되고, 존 이동이 잦은 게임에서는 그것이 곧 최대 사용량이 된다.

```gdscript
	# 겹치지 않는 곳으로 건너뛰었는가.
	var jumped := _has_range and not _last_range.intersects(wanted)
	...
	for coord in _chunks.keys():
		if wanted.has_point(coord):
			continue
		if jumped:
			_remove_chunk(coord)          # 돌아올 일이 없다. 기다리지 않는다
		elif not _cooldown.has(coord):
			_cooldown[coord] = config.unload_delay
```

### 상주 수의 상한은 (2r+1)² 이 아니라 (2r+2)² 다

미리 로딩으로 앞 열이 붙고 뒤 열이 유예로 남아 있는 동안은 평상시보다 많다.
**이 겹침이 정상**이며, 없으면 경계를 넘는 순간 지면이 사라진다.

```gdscript
func resident_capacity() -> int:      # 평상시. 반경 1 → 9
	var side := resident_radius * 2 + 1
	return side * side

func resident_peak() -> int:          # 실제 상한. 반경 1 → 16
	var side := resident_radius * 2 + 2
	return side * side
```

검증에서 `resident_peak()` 를 기준으로 삼아야 한다. `capacity()` 로 잡으면
정상 동작이 실패로 잡힌다.

---

## 5. 좁게 시작하는 법 — 크기가 아니라 시야를 줄인다

§0 의 "콘텐츠를 중앙부터 넓힌다"를 실제로 하는 방법이다.

```
world_size    = 4000.0   ← 그대로 둔다 (구조 결정)
view_distance =  300.0   ← 이걸 줄인다 (보이는 범위)
```

`view_distance` 를 줄이면 안개가 300m 앞을 덮어 **작은 맵처럼 느껴진다.**
구조·좌표·스케일은 4km 그대로다. 콘텐츠가 늘면 1200m 로 되돌리는 것만으로
세계가 넓어진다 — **코드도 에셋도 손대지 않는다.**

### 시야 거리는 카메라가 아니라 월드가 정한다

`Camera3D.far` 와 안개 거리가 어긋나면 **지면이 잘린 경계가 그대로 보인다.**
두 값은 반드시 같은 출처에서 나와야 한다.

```gdscript
## 시야 거리를 카메라와 안개에 한 번에 적용한다.
func _apply_view_distance() -> void:
	var config := _world.config
	_camera_rig.set_view_distance(config.view_distance)

	var environment := _environment.environment
	environment.fog_enabled = true
	environment.fog_mode = Environment.FOG_MODE_DEPTH
	environment.fog_depth_begin = config.fog_begin()      # view_distance * 0.45
	environment.fog_depth_end = config.view_distance
	environment.fog_light_color = config.fog_color
	environment.fog_sky_affect = 0.0     # 하늘까지 뿌옇게 만들지 않는다
```

> `fog_mode` 를 `FOG_MODE_DEPTH` 로 바꾸면 `fog_density` 가 **1.0 으로 재설정된다**
> (엔진 확인). DEPTH 모드에서 density 는 최대 농도 배율이므로 1.0 이 맞다.

---

## 6. 크기·색·시야를 `Resource` 로 뺀다

값을 스크립트 `const` 로 두면 **맵이 둘이 되는 순간 막힌다.**
`Resource` 로 빼 두면 `.tres` 를 하나 더 만들면 되고 스크립트는 한 줄도 바뀌지 않는다.

```
resources/maps/plains_4km.tres     world_size 4000 · view 1200 · landmark 500
resources/maps/arena_750m.tres     world_size  750 · view  400 · landmark 150
```

### 🛑 폴백 기본값은 작은 맵으로 둔다

Godot 은 **기본값과 같은 프로퍼티를 `.tres` 에 저장하지 않는다.**
`WorldConfig` 의 기본 `world_size` 를 4000 으로 두면 `plains_4km.tres` 에
그 값이 아예 기록되지 않아, 파일만 봐서는 크기를 알 수 없다.
게다가 실수로 config 를 빠뜨렸을 때 무거운 맵이 조용히 만들어진다.

```gdscript
## 기본값은 "설정을 끼우지 않았을 때의 안전 폴백"이다. 실제 맵 값은 .tres 에 있다.
@export var world_size: float = 1000.0:
	set(value):
		world_size = maxf(value, 1.0)
		emit_changed()
```

### 설정이 성립하는지 스스로 검사하게 한다

사람이 인스펙터에서 값을 잘못 넣는 것은 **정상적인 사용 방식**이다.
`assert` 로 터뜨리는 대신 문제 목록을 돌려준다.

```gdscript
func validate() -> PackedStringArray:
	var problems := PackedStringArray()

	var count := world_size / chunk_size
	if absf(count - round(count)) > 0.001:
		problems.append("world_size 가 chunk_size 로 나누어떨어지지 않는다")

	if distant_ground_enabled:
		if view_distance > world_size:
			problems.append("view_distance 가 월드보다 넓다 — 맵 밖이 보인다")
	elif view_distance > resident_reach():
		problems.append("원경 지면이 꺼져 있는데 시야가 상주 범위보다 멀다 — 빈 공간이 보인다")

	return problems
```

---

## 7. 콜리전과 경계

### 바닥은 물리 바디 하나로 덮는다

청크마다 콜리전을 두면 물리 바디가 청크 수만큼 생긴다. **지면이 평평하면 상자 하나면 된다.**
지형에 높낮이가 생기는 시점에 청크별 콜리전으로 옮긴다.

```gdscript
var box := BoxShape3D.new()
box.size = Vector3(config.world_size, config.ground_depth, config.world_size)
# 상자 원점은 중심이므로 절반만큼 내려야 윗면이 y = 0 에 온다.
shape.position = Vector3(0.0, -config.ground_depth * 0.5, 0.0)
```

### 경계 벽 — 안쪽 면을 정확히 ±half 에 맞춘다

```gdscript
var offset := half + thickness * 0.5          # 중심을 이만큼 밀면 안쪽 면이 ±half
var span := config.world_size + thickness * 2.0   # 네 모서리를 메운다
```

야외 맵의 정석은 산맥·절벽으로 닫는 것이지만, 블록아웃 단계에서는
**경계가 어디인지 눈에 보이는 편이 낫다.**

---

## 8. 기물 흩기 — 무엇을 묶고 무엇을 따로 그리는가

오픈월드에서 가장 자주 하는 판단이다.

| | 만드는 법 | 드로우콜 | 언제 |
|---|---|---|---|
| **`MultiMesh`** | 기준 메시 하나를 크기·회전만 바꿔 | **개수와 무관하게 1** | 개체차가 크기·회전으로 충분할 때 |
| **개별 `MeshInstance3D`** | 각자 고유 메시 | **개수만큼** | 모양 자체가 달라야 할 때 |

나무 10그루를 `MultiMesh` 2개(줄기·잎)로 그리면 드로우콜 2이고, 개별 노드로 놓으면
20이다. **나무는 몇 그루가 되든 2로 고정된다.**

### 프로시저럴 메시 — 구를 노이즈로 찌그러뜨리기

바위처럼 개체마다 모양이 달라야 하는 것은 코드로 만든다. 세 가지 함정이 있고
전부 엔진에서 확인했다.

```gdscript
func _make_rock_mesh(radius: float) -> ArrayMesh:
	var sphere := SphereMesh.new()
	sphere.radius = radius
	sphere.height = radius * 2.0
	sphere.radial_segments = 14
	sphere.rings = 7

	var noise := FastNoiseLite.new()
	noise.noise_type = FastNoiseLite.TYPE_SIMPLEX
	noise.seed = _rng.randi()
	noise.frequency = 0.55

	var arrays := sphere.surface_get_arrays(0)
	var vertices: PackedVector3Array = arrays[Mesh.ARRAY_VERTEX]
	for i in vertices.size():
		var vertex := vertices[i]
		var direction := vertex.normalized()
		var amount := noise.get_noise_3d(
			direction.x * 10.0, direction.y * 10.0, direction.z * 10.0)
		vertices[i] = vertex * (1.0 + amount * 0.32)
	arrays[Mesh.ARRAY_VERTEX] = vertices

	var mesh := ArrayMesh.new()
	mesh.add_surface_from_arrays(Mesh.PRIMITIVE_TRIANGLES, arrays)

	var tool := SurfaceTool.new()
	tool.create_from(mesh, 0)
	tool.generate_normals()
	return tool.commit()
```

| 함정 | 내용 |
|---|---|
| **방향으로 노이즈를 뽑는다** | 구 메시는 UV 이음매에서 같은 위치에 정점이 둘 있다. 좌표값으로 뽑으면 둘이 다른 값을 받아 **이음매가 갈라진다** |
| **방향을 10배로 벌린다** | `FastNoiseLite` 기본 `frequency` 는 **0.01** 이다. 길이 1인 방향을 그대로 넣으면 노이즈가 거의 변하지 않아 그냥 구가 나온다 |
| **노멀을 다시 계산한다** | 정점을 옮기면 원래 노멀이 표면과 어긋난다. 그대로 두면 모양은 울퉁불퉁한데 조명은 매끈한 구처럼 계산돼 **형태가 안 보인다** |

`SurfaceTool.generate_normals()` 는 **인덱스를 유지한 채** 스무스 노멀을 다시 낸다
(엔진 확인 — 정점 54개, 인덱스 유지).

### 배치 — 시드 하나로 재현한다

```gdscript
## 겹치지 않는 자리를 찾는다. 못 찾으면 Vector3.INF.
##
## null 대신 INF 를 쓰는 이유는 반환 타입을 Vector3 로 못 박기 위해서다.
## Variant 를 돌려주면 받는 쪽의 := 추론이 전부 Variant 가 된다.
func _find_spot(occupy_radius: float) -> Vector3:
	for attempt in 64:
		# 반지름을 균등 난수로 뽑으면 안쪽에 몰린다. 제곱근을 취해야
		# 면적당 밀도가 고르다 — 바깥 고리가 안쪽보다 넓기 때문이다.
		var t := _rng.randf()
		var distance := sqrt(lerpf(inner_radius * inner_radius, outer_radius * outer_radius, t))
		var angle := _rng.randf_range(0.0, TAU)
		var candidate := Vector3(cos(angle) * distance, 0.0, sin(angle) * distance)
		...
	return Vector3.INF
```

**큰 것부터 놓는다.** 작은 것을 먼저 흩으면 큰 것이 들어갈 자리를 못 찾아 헛돈다.
**시작 지점 반경은 비운다** — 안 그러면 첫 화면에서 기물이 캐릭터를 가린다(§10).

---

## 9. 검증 — 스트리밍은 잘 돌 때 화면에 아무 일도 안 일어난다

**이것이 오픈월드 검증의 핵심이다.** 스트리밍이 꺼져 있어도 화면은 똑같이 보인다.
숫자를 보지 않으면 켜져 있는지조차 알 수 없다.

헤드리스로 **플레이어를 옮겨 놓고 상주 청크가 따라오는지** 확인한다.

```gdscript
# 대기는 프레임 수가 아니라 **누적 시간**으로 센다 — 헤드리스는 프레임이
# 훨씬 빨리 돌아, 프레임 수로 세면 4초 유예가 0.5초 만에 지나간 것이 된다.
func _process(delta: float) -> bool:
	_elapsed += delta
	match _step:
		0: ...   # 원점에서 상주 확인
		1: ...   # (1000, 1000) 으로 순간이동 → 옛 청크가 유예 없이 정리되는가
		2: ...   # 이웃 청크로 걸어 나가 유예 발생 → unload_delay 후 정리되는가
```

확인할 것은 넷이다.

| 검증 | 기준 |
|---|---|
| 상주 수 | `resident_peak()` 이하 |
| 전부 관찰자 주변인가 | 반경 +1 을 벗어난 청크 0개 |
| 순간이동 후 | 유예 없이 즉시 정리 |
| 유예 경과 후 | 뒤쪽 청크가 사라짐 |

### 헤드리스로 잴 수 없는 것

| 항목 | 이유 | 대안 |
|---|---|---|
| **드로우콜** | 더미 렌더러라 항상 0 | 창 모드로 실행해 측정 |
| **`MultiMesh` 인스턴스 트랜스폼** | 버퍼가 렌더링 서버에 있어 되읽히지 않는다 | 배치 결과를 **스크립트 쪽에도** 배열로 남긴다 |

```gdscript
## MultiMesh 에 넣은 값은 헤드리스(더미 렌더러)에서 되읽을 수 없다.
## 그래서 배치 결과를 스크립트 쪽에도 남겨 둔다.
var tree_transforms: Array[Transform3D] = []
```

---

## 10. 실제로 걸린 함정들 (전부 실측)

| 함정 | 증상 | 대응 |
|---|---|---|
| **원점에 기물이 서 있다** | 첫 화면에서 **플레이어가 통째로 가려진다.** 좌표·개수 검증은 전부 통과한다 | 격자 배치에서 원점을 제외하거나 시작 반경을 비운다 |
| **`specular` 는 Godot 3 이름** | `SpatialMaterial remapped parameter not found` 경고만 뜨고 **값이 조용히 무시된다** | 4.x 는 `metallic_specular` (기본 0.5) |
| **이름 없는 노드** | `@CollisionShape3D@2` 같은 이름이 붙어 **경로로 찾을 수 없다** | 코드로 만든 노드에는 `name` 을 명시한다 |
| **원경 평면과 청크가 같은 높이** | z-fighting 으로 지면이 지글거린다 | 평면을 0.05m 내린다 |
| **`floor()` 가 Variant 반환** | 경고를 오류로 승격한 프로젝트에서 **컴파일이 막힌다** | float 전용 `floorf()` |
| **`_process` 에서 `await`** | 함수가 코루틴이 되어 **반환값이 항상 참으로 읽힌다**(SceneTree 스크립트가 즉시 종료) | 프레임 카운터로만 기다린다 |
| **`_initialize` 에서 노드 접근** | 트리 안이 아니라 `global_position` 이 안 되고 `_ready` 도 안 돌았다 | 첫 `_process` 로 미룬다 |
| **HUD 가 드로우콜을 먹는다** | 글자 외곽선을 켜면 **글리프마다 패스가 하나 더** 붙는다. 실측 HUD 68개 vs 3D 전체 11개 | 외곽선 대신 반투명 패널(드로우콜 1). 그리고 **접을 수 있게** 만든다 |

---

## 11. 성능 실측 (참고값)

4km 맵 · 청크 256개 중 상주 16개 · 나무 10 · 바위 3 · 랜드마크 48개 기준.
**1280×720 · Mobile 렌더러 · vsync 끔 · Apple M5 Max.**

```
줌   14 m   평균 FPS 130.1   드로우콜 60   그린 오브젝트 173
줌   28 m   평균 FPS 119.7   드로우콜 62   그린 오브젝트 175
줌   56 m   평균 FPS 150.0   드로우콜 72   그린 오브젝트 185
텍스처 VRAM 62 MB · 노드 86 개
```

**드로우콜 60~72 중 34개가 HUD 몫이다.** 3D 지오메트리는 실제로 20~38개다.
디버그 표시를 접고 재지 않으면 예산 판단이 통째로 어긋난다.

> ⚠️ **첫 측정 구간은 셰이더 컴파일 때문에 항상 낮게 나온다.** 순서를 뒤집어
> 두 번 재면 확인된다 — 같은 줌이 첫 구간에서 78.8, 마지막 구간에서 163.2 였다.

---

## 12. 요약 — 오픈월드를 시작하는 순서

1. **최종 크기를 정한다.** 모르겠으면 4km. 이 구조가 16km 까지 코드 변경 없이 간다
2. **`WorldConfig` `.tres` 를 만든다.** 크기·청크·시야·색을 전부 여기 둔다
3. **지면 3층을 만든다.** 원경 평면 1장 + 상주 청크 + 랜드마크 `MultiMesh`
4. **바닥 콜리전 하나, 경계 벽 넷**을 세운다
5. **`view_distance` 를 짧게 두고 중앙 100m 만 채운다**
6. **콘텐츠를 중앙에서 바깥으로 넓히며** 시야도 함께 늘린다
7. **매번 검증한다** — 스트리밍은 화면에 보이지 않는다

> **크기는 처음부터 최종값, 콘텐츠는 중앙부터.**
> 이 한 줄이 오픈월드 제작에서 가장 되돌리기 비싼 결정을 막아 준다.
