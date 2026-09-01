# 3D 오디오

## 목차

1. [핵심 개념 — 플레이어·버스·서버](#1-핵심-개념--플레이어버스서버)
2. [AudioStreamPlayer 3종](#2-audiostreamplayer-3종)
3. [AudioStreamPlayer3D 공간 설정](#3-audiostreamplayer3d-공간-설정)
4. [오디오 버스](#4-오디오-버스)
5. [버스 이펙트](#5-버스-이펙트)
6. [AudioStream 종류](#6-audiostream-종류)
7. [오디오 매니저 (완성 코드)](#7-오디오-매니저-완성-코드)
8. [인터랙티브 뮤직](#8-인터랙티브-뮤직)
9. [지연(latency)과 동기화](#9-지연latency과-동기화)
10. [모바일 오디오 주의사항](#10-모바일-오디오-주의사항)
11. [자주 하는 실수](#11-자주-하는-실수)

---

## 1. 핵심 개념 — 플레이어·버스·서버

```
AudioStream (Resource)     — 소리 데이터 (.wav, .ogg)
      ↓ 재생
AudioStreamPlayer* (Node)  — 재생 인스턴스. 어느 버스로 보낼지 지정
      ↓ 출력
Audio Bus                  — 믹싱 채널. 볼륨·이펙트 적용. 다른 버스로 라우팅 가능
      ↓
Master Bus                 — 최종 출력
      ↓
AudioServer                — 전역 제어 (버스 조작, 지연 조회)
```

**설계 원칙**: 개별 소리의 볼륨을 코드로 조절하지 말고, **버스 구조로 카테고리를
나눈 뒤 버스 볼륨을 조절한다.** 그래야 설정 메뉴의 볼륨 슬라이더가 단순해진다.

---

## 2. AudioStreamPlayer 3종

| 노드 | 공간감 | 용도 |
|------|--------|------|
| `AudioStreamPlayer` | 없음 | BGM, UI 효과음, 나레이션 |
| `AudioStreamPlayer2D` | 2D 위치 | 2D 게임 (이 프로젝트에서는 미사용) |
| `AudioStreamPlayer3D` | 3D 위치 + 감쇠 + 도플러 | **게임 월드의 모든 효과음** |

### 공통 API

```gdscript
player.stream = load("res://assets/audio/hit.wav")
player.volume_db = -6.0                 # 데시벨. 0이 원본 크기
player.pitch_scale = 1.0                # 재생 속도 + 음높이
player.bus = &"SFX"
player.autoplay = false
player.max_polyphony = 1                # 동시 재생 가능 수 (같은 노드에서)
player.playing = true

player.play()
player.play(3.5)                        # 3.5초 지점부터
player.stop()
player.seek(2.0)
var pos := player.get_playback_position()

player.finished.connect(_on_finished)

# 4.x 폴리포니 재생 — 같은 노드에서 여러 소리 겹치기
var playback := player.get_stream_playback() as AudioStreamPlaybackPolyphonic
if playback:
    var id := playback.play_stream(sound, 0.0, 0.0, 1.0)
    playback.set_stream_volume(id, -3.0)
    playback.stop_stream(id)
```

### volume_db와 선형 값 변환

```gdscript
# 슬라이더(0~1) → dB
player.volume_db = linear_to_db(0.5)      # 약 -6dB

# dB → 선형
var linear := db_to_linear(-6.0)          # 약 0.5

# 0은 무음이 아니다. -80dB 이하를 무음으로 취급한다
if slider_value < 0.001:
    AudioServer.set_bus_mute(bus_idx, true)
else:
    AudioServer.set_bus_volume_db(bus_idx, linear_to_db(slider_value))
```

**dB는 로그 스케일이다.** `-6dB`가 대략 절반 음량, `-12dB`가 1/4이다.
슬라이더에 dB를 직접 연결하면 대부분의 범위에서 변화를 못 느낀다.

---

## 3. AudioStreamPlayer3D 공간 설정

```gdscript
var p := AudioStreamPlayer3D.new()

# 감쇠
p.attenuation_model = AudioStreamPlayer3D.ATTENUATION_INVERSE_DISTANCE
p.unit_size = 10.0              # 이 거리에서 volume_db가 그대로 적용
p.max_db = 3.0                  # 최대 증폭 상한
p.max_distance = 50.0           # 이 거리 밖에서는 재생 중단 (0 = 무제한)

# 지향성
p.emission_angle_enabled = false
p.emission_angle_degrees = 45.0
p.emission_angle_filter_attenuation_db = -12.0

# 공기 흡수 (원거리 고음 감쇠)
p.attenuation_filter_cutoff_hz = 5000.0
p.attenuation_filter_db = -24.0

# 도플러
p.doppler_tracking = AudioStreamPlayer3D.DOPPLER_TRACKING_PHYSICS_STEP

# 영역 효과 (Area3D의 리버브 버스 적용)
p.area_mask = 1

# 패닝 강도
p.panning_strength = 1.0

add_child(p)
```

### 감쇠 모델

| 모델 | 특성 |
|------|------|
| `ATTENUATION_INVERSE_DISTANCE` | 1/d. 현실적. **기본 권장** |
| `ATTENUATION_INVERSE_SQUARE_DISTANCE` | 1/d². 급격히 작아짐 |
| `ATTENUATION_LOGARITHMIC` | 로그. 완만함 |
| `ATTENUATION_DISABLED` | 거리 무관. 패닝만 적용 |

### unit_size와 max_distance 설정 지침

```
unit_size    — "이 거리까지는 원래 볼륨"의 기준. 작으면 빨리 작아진다
max_distance — 이 거리 밖은 아예 재생 중단 (성능 최적화)
```

| 소리 | unit_size | max_distance |
|------|-----------|--------------|
| 발소리 | `2.0` | `20.0` |
| 총소리 | `20.0` | `150.0` |
| 폭발 | `30.0` | `200.0` |
| 환경음 (물, 바람) | `10.0` | `40.0` |
| 대화 | `5.0` | `25.0` |

**`max_distance`를 반드시 설정한다.** 0(무제한)이면 화면 밖 멀리 있는 소리도
믹싱 대상에 남아 CPU를 낭비한다.

### 도플러 효과

```gdscript
p.doppler_tracking = AudioStreamPlayer3D.DOPPLER_TRACKING_PHYSICS_STEP
# DOPPLER_TRACKING_DISABLED   — 끔 (기본)
# DOPPLER_TRACKING_IDLE_STEP  — 렌더 프레임 기준
# DOPPLER_TRACKING_PHYSICS_STEP — 물리 프레임 기준 (물리로 움직이는 물체)
```

`Camera3D`에도 `doppler_tracking`을 켜야 카메라 이동에 의한 도플러가 적용된다.

`Project Settings → Audio → General → 3D Panning Strength`,
`Doppler → Physics/Idle Frames`에서 전역 강도를 조정한다.

### Area3D 리버브 존

```gdscript
# Area3D에서 (동굴, 실내 등)
area.audio_bus_override = true
area.audio_bus_name = &"CaveReverb"
area.reverb_bus_enabled = true
area.reverb_bus_name = &"CaveReverb"
area.reverb_bus_amount = 0.8
area.reverb_bus_uniformity = 0.5
area.priority = 1
```

`AudioStreamPlayer3D.area_mask`가 이 `Area3D`의 레이어와 겹치면
해당 소리가 리버브 버스로 라우팅된다. 플레이어가 동굴에 들어가면
모든 소리가 자동으로 울린다.

---

## 4. 오디오 버스

### 권장 버스 구조

```
Master
├─ Music          (BGM)
├─ SFX            (효과음)
│  ├─ SFX_World   (월드 3D 사운드)
│  ├─ SFX_UI      (UI 클릭 등)
│  └─ SFX_Player  (플레이어 액션)
├─ Voice          (대사)
└─ Ambience       (환경음)
```

에디터: 하단 `Audio` 탭에서 버스를 추가하고 `Send To`로 라우팅을 지정한다.
`res://default_bus_layout.tres`에 저장되며,
`Project Settings → Audio → Buses → Default Bus Layout`에서 지정한다.

### AudioServer API

```gdscript
var idx := AudioServer.get_bus_index("Music")

AudioServer.set_bus_volume_db(idx, linear_to_db(0.7))
AudioServer.set_bus_mute(idx, false)
AudioServer.set_bus_solo(idx, false)
AudioServer.set_bus_bypass_effects(idx, false)

var db := AudioServer.get_bus_volume_db(idx)
var count := AudioServer.bus_count
var name := AudioServer.get_bus_name(idx)

# 버스 추가/제거
AudioServer.add_bus(2)
AudioServer.set_bus_name(2, "Custom")
AudioServer.set_bus_send(2, "Master")
AudioServer.remove_bus(2)

# 피크 볼륨 (VU 미터, 립싱크)
var peak_l := AudioServer.get_bus_peak_volume_left_db(idx, 0)
var peak_r := AudioServer.get_bus_peak_volume_right_db(idx, 0)

# 레이아웃 저장/복원
AudioServer.set_bus_layout(load("res://custom_bus_layout.tres"))
var layout := AudioServer.generate_bus_layout()
```

---

## 5. 버스 이펙트

```gdscript
var idx := AudioServer.get_bus_index("SFX")

var reverb := AudioEffectReverb.new()
reverb.room_size = 0.8
reverb.damping = 0.5
reverb.wet = 0.3
reverb.dry = 0.7
reverb.spread = 1.0
AudioServer.add_bus_effect(idx, reverb)

# 조회·토글
var fx := AudioServer.get_bus_effect(idx, 0)
AudioServer.set_bus_effect_enabled(idx, 0, false)
AudioServer.remove_bus_effect(idx, 0)
var fx_count := AudioServer.get_bus_effect_count(idx)
```

### 주요 이펙트

| 이펙트 | 용도 | 비용 |
|--------|------|------|
| `AudioEffectReverb` | 공간 잔향 | 중간 |
| `AudioEffectCompressor` | 다이내믹 레인지 압축 | 낮음 |
| `AudioEffectLimiter` | 클리핑 방지 (Master에 필수) | 낮음 |
| `AudioEffectEQ6/10/21` | 이퀄라이저 | 중간 |
| `AudioEffectLowPassFilter` | 저역 통과 (물속, 기절) | 낮음 |
| `AudioEffectHighPassFilter` | 고역 통과 (무전기) | 낮음 |
| `AudioEffectDelay` | 에코 | 중간 |
| `AudioEffectChorus` / `Phaser` / `Distortion` | 음색 변조 | 중간 |
| `AudioEffectPitchShift` | 음높이 변경 (속도 유지) | **높음** |
| `AudioEffectPanner` | 좌우 배치 | 낮음 |
| `AudioEffectSpectrumAnalyzer` | 주파수 분석 (시각화) | 높음 |
| `AudioEffectCapture` | 마이크 입력 캡처 | |
| `AudioEffectRecord` | 녹음 | |

### Master 버스 권장 체인

```gdscript
func _ready() -> void:
    var master := AudioServer.get_bus_index("Master")
    # 리미터로 클리핑(찢어짐)을 방지한다 — 여러 소리가 겹칠 때 필수
    var limiter := AudioEffectLimiter.new()
    limiter.ceiling_db = -0.5
    limiter.threshold_db = -1.0
    limiter.soft_clip_db = 2.0
    AudioServer.add_bus_effect(master, limiter)
```

### 상황별 필터 (물속, 피격)

```gdscript
class_name AudioFilterController
extends Node

var _lowpass: AudioEffectLowPassFilter
var _bus_idx: int

func _ready() -> void:
    _bus_idx = AudioServer.get_bus_index("SFX")
    _lowpass = AudioEffectLowPassFilter.new()
    _lowpass.cutoff_hz = 20500.0        # 사실상 무효과
    AudioServer.add_bus_effect(_bus_idx, _lowpass)

func enter_underwater() -> void:
    var tween := create_tween()
    tween.tween_method(_set_cutoff, _lowpass.cutoff_hz, 800.0, 0.4)

func exit_underwater() -> void:
    var tween := create_tween()
    tween.tween_method(_set_cutoff, _lowpass.cutoff_hz, 20500.0, 0.4)

func _set_cutoff(hz: float) -> void:
    _lowpass.cutoff_hz = hz
```

---

## 6. AudioStream 종류

| 클래스 | 설명 |
|--------|------|
| `AudioStreamWAV` | .wav 임포트 결과 |
| `AudioStreamOggVorbis` | .ogg |
| `AudioStreamMP3` | .mp3 |
| `AudioStreamRandomizer` | 여러 스트림 중 랜덤 재생 + 피치/볼륨 랜덤화 |
| `AudioStreamPlaylist` (4.2+) | 순차/셔플 재생 |
| `AudioStreamInteractive` (4.3+) | 클립 간 조건부 전환 |
| `AudioStreamSynchronized` (4.3+) | 여러 스트림 동시 재생 (레이어 믹싱) |
| `AudioStreamPolyphonic` | 하나의 플레이어로 다중 재생 |
| `AudioStreamGenerator` | 절차적 오디오 생성 |
| `AudioStreamMicrophone` | 마이크 입력 |

### AudioStreamRandomizer — 반복감 제거

같은 발소리를 반복하면 기계적으로 들린다. 여러 변형을 랜덤 재생하고
피치를 미세하게 흔든다.

```gdscript
var randomizer := AudioStreamRandomizer.new()
randomizer.playback_mode = AudioStreamRandomizer.PLAYBACK_RANDOM_NO_REPEATS
randomizer.random_pitch = 1.15        # 0.87 ~ 1.15 범위
randomizer.random_volume_offset_db = 3.0

for path in [
    "res://assets/audio/footstep_01.wav",
    "res://assets/audio/footstep_02.wav",
    "res://assets/audio/footstep_03.wav",
    "res://assets/audio/footstep_04.wav",
]:
    randomizer.add_stream(-1, load(path), 1.0)

player.stream = randomizer
```

`PLAYBACK_RANDOM_NO_REPEATS`는 직전에 재생한 것을 다시 고르지 않는다.
**이 모드를 쓰지 않으면 같은 소리가 연속으로 나와 어색하다.**

---

## 7. 오디오 매니저 (완성 코드)

오토로드로 등록해 어디서든 소리를 재생한다.
**3D 사운드 플레이어를 풀링해서 노드 생성/삭제 비용을 없앤다.**

```gdscript
# res://autoload/audio_manager.gd
extends Node

const POOL_SIZE_3D: int = 24
const POOL_SIZE_2D: int = 12
const MUSIC_FADE_TIME: float = 1.2

var _pool_3d: Array[AudioStreamPlayer3D] = []
var _pool_2d: Array[AudioStreamPlayer] = []
var _index_3d: int = 0
var _index_2d: int = 0

var _music_a: AudioStreamPlayer
var _music_b: AudioStreamPlayer
var _music_active_is_a: bool = true
var _music_tween: Tween

func _ready() -> void:
    process_mode = Node.PROCESS_MODE_ALWAYS      # 일시정지 중에도 동작

    for i in POOL_SIZE_3D:
        var p := AudioStreamPlayer3D.new()
        p.bus = &"SFX"
        p.attenuation_model = AudioStreamPlayer3D.ATTENUATION_INVERSE_DISTANCE
        p.unit_size = 10.0
        p.max_distance = 60.0
        add_child(p)
        _pool_3d.append(p)

    for i in POOL_SIZE_2D:
        var p := AudioStreamPlayer.new()
        p.bus = &"SFX"
        add_child(p)
        _pool_2d.append(p)

    _music_a = AudioStreamPlayer.new()
    _music_a.bus = &"Music"
    add_child(_music_a)
    _music_b = AudioStreamPlayer.new()
    _music_b.bus = &"Music"
    add_child(_music_b)

# ── 3D 효과음 ───────────────────────────────────────
func play_3d(stream: AudioStream, position: Vector3,
             volume_db: float = 0.0, pitch: float = 1.0,
             bus: StringName = &"SFX") -> AudioStreamPlayer3D:
    if stream == null:
        return null
    var p := _acquire_3d()
    p.stream = stream
    p.global_position = position
    p.volume_db = volume_db
    p.pitch_scale = pitch
    p.bus = bus
    p.play()
    return p

# 움직이는 대상에 붙여서 재생 (발소리, 엔진음)
func play_attached(stream: AudioStream, parent: Node3D,
                   volume_db: float = 0.0) -> AudioStreamPlayer3D:
    if stream == null or not is_instance_valid(parent):
        return null
    var p := AudioStreamPlayer3D.new()
    p.stream = stream
    p.volume_db = volume_db
    p.bus = &"SFX"
    p.unit_size = 5.0
    p.max_distance = 30.0
    parent.add_child(p)
    p.play()
    p.finished.connect(p.queue_free)
    return p

func _acquire_3d() -> AudioStreamPlayer3D:
    # 재생 중이지 않은 것을 우선 찾고, 없으면 가장 오래된 것을 재사용
    for i in POOL_SIZE_3D:
        var idx := (_index_3d + i) % POOL_SIZE_3D
        if not _pool_3d[idx].playing:
            _index_3d = (idx + 1) % POOL_SIZE_3D
            return _pool_3d[idx]
    var p := _pool_3d[_index_3d]
    _index_3d = (_index_3d + 1) % POOL_SIZE_3D
    return p

# ── 2D/UI 효과음 ────────────────────────────────────
func play_ui(stream: AudioStream, volume_db: float = 0.0,
             pitch: float = 1.0) -> void:
    if stream == null:
        return
    var p := _pool_2d[_index_2d]
    _index_2d = (_index_2d + 1) % POOL_SIZE_2D
    p.stream = stream
    p.volume_db = volume_db
    p.pitch_scale = pitch
    p.bus = &"SFX"
    p.play()

# ── BGM (크로스페이드) ──────────────────────────────
func play_music(stream: AudioStream, fade: float = MUSIC_FADE_TIME,
                from_position: float = 0.0) -> void:
    if stream == null:
        stop_music(fade)
        return
    var current := _music_a if _music_active_is_a else _music_b
    var next := _music_b if _music_active_is_a else _music_a

    if current.playing and current.stream == stream:
        return          # 같은 곡이면 무시

    next.stream = stream
    next.volume_db = -60.0
    next.play(from_position)

    if _music_tween and _music_tween.is_running():
        _music_tween.kill()
    _music_tween = create_tween().set_parallel(true)
    _music_tween.tween_property(next, "volume_db", 0.0, fade)
    if current.playing:
        _music_tween.tween_property(current, "volume_db", -60.0, fade)
        _music_tween.chain().tween_callback(current.stop)

    _music_active_is_a = not _music_active_is_a

func stop_music(fade: float = MUSIC_FADE_TIME) -> void:
    var current := _music_a if _music_active_is_a else _music_b
    if not current.playing:
        return
    if _music_tween and _music_tween.is_running():
        _music_tween.kill()
    _music_tween = create_tween()
    _music_tween.tween_property(current, "volume_db", -60.0, fade)
    _music_tween.tween_callback(current.stop)

func set_music_pitch(pitch: float) -> void:
    _music_a.pitch_scale = pitch
    _music_b.pitch_scale = pitch
```

### 사용

```gdscript
AudioManager.play_3d(hit_sound, collision_point, -3.0, randf_range(0.9, 1.1))
AudioManager.play_ui(click_sound)
AudioManager.play_music(boss_theme)
AudioManager.play_attached(engine_loop, vehicle)
```

### 왜 풀링하는가

`AudioStreamPlayer3D`를 매번 `new()` + `add_child()` + `queue_free()` 하면
초당 수십 개 생성 시 GC 압박과 노드 트리 변경 비용이 발생한다.
풀에서 재사용하면 이 비용이 0이 된다.

**단, 움직이는 대상에 붙는 소리(`play_attached`)는 풀링하지 않는다.**
부모가 달라지므로 재사용이 복잡해지고, 그런 소리는 개수가 적다.

---

## 8. 인터랙티브 뮤직

### AudioStreamInteractive (4.3+)

여러 클립과 전환 규칙을 리소스에 정의한다.
에디터에서 클립을 추가하고 전환 조건(즉시 / 다음 박 / 다음 마디)을 설정한다.

```gdscript
var playback := music_player.get_stream_playback() as AudioStreamPlaybackInteractive
playback.switch_to_clip_by_name(&"combat")
playback.switch_to_clip(2)
```

전투 진입 시 다음 마디에 맞춰 자연스럽게 곡이 바뀐다.

### AudioStreamSynchronized (4.3+) — 레이어 믹싱

같은 곡의 여러 레이어(드럼, 베이스, 멜로디)를 동시에 재생하고
상황에 따라 볼륨만 조절한다. 전환이 완벽하게 매끄럽다.

```gdscript
var sync := AudioStreamSynchronized.new()
sync.set_sync_stream_count(3)
sync.set_sync_stream(0, load("res://audio/music_base.ogg"))
sync.set_sync_stream(1, load("res://audio/music_tension.ogg"))
sync.set_sync_stream(2, load("res://audio/music_combat.ogg"))
sync.set_sync_stream_volume(1, -60.0)
sync.set_sync_stream_volume(2, -60.0)
music_player.stream = sync
music_player.play()

# 긴장도에 따라 레이어 볼륨 조절
func set_tension(level: float) -> void:
    var s := music_player.stream as AudioStreamSynchronized
    var tween := create_tween().set_parallel(true)
    tween.tween_method(
        func(db: float) -> void: s.set_sync_stream_volume(1, db),
        s.get_sync_stream_volume(1), lerpf(-60.0, 0.0, level), 0.8
    )
```

### 수동 크로스페이드 (버전 무관)

7절의 `AudioManager.play_music()`이 이 방식이다.
두 개의 플레이어를 번갈아 쓰며 볼륨을 트윈으로 교차시킨다.

---

## 9. 지연(latency)과 동기화

```gdscript
# 오디오 출력 지연 (초)
var latency := AudioServer.get_output_latency()

# 현재 믹싱된 시간 (리듬 게임에서 정확한 박자 판정에 사용)
var mix_time := AudioServer.get_time_since_last_mix()
var to_output := AudioServer.get_time_to_next_mix()

# 정확한 재생 위치 계산
func get_precise_position(player: AudioStreamPlayer) -> float:
    return player.get_playback_position() \
         + AudioServer.get_time_since_last_mix() \
         - AudioServer.get_output_latency()
```

### 프로젝트 설정

```ini
[audio]

driver/output_latency=15                 # ms. 낮을수록 반응 빠름, 지직거림 위험
driver/output_latency.web=50
buses/default_bus_layout="res://default_bus_layout.tres"
general/3d_panning_strength=1.0
general/2d_panning_strength=1.0
general/text_to_speech=false
```

**모바일은 지연을 낮추기 어렵다.** Android는 기기마다 오디오 스택이 달라
`output_latency`를 너무 낮추면 끊김이 생긴다. 기본값(15ms)을 유지하거나
문제 시 30~50ms로 올린다.

---

## 10. 모바일 오디오 주의사항

1. **동시 재생 수를 제한한다.** 모바일 오디오 믹서는 데스크톱보다 약하다.
   7절의 풀 크기(24개)가 적절한 상한이다.

2. **효과음 샘플레이트를 낮춘다.** 임포트 설정의 `Force/Max Rate`를
   `22050`으로 두면 파일 크기와 디코딩 비용이 절반이 된다.
   대부분의 효과음에서 차이를 느끼기 어렵다.

3. **BGM은 .ogg, 효과음은 .wav.** ogg는 디코딩에 CPU를 쓰므로
   짧은 효과음을 ogg로 하면 오히려 손해다.

4. **`max_distance`를 반드시 설정한다.** 무제한이면 멀리 있는 소리도
   믹싱 대상에 남는다.

5. **`AudioEffectPitchShift`, `AudioEffectSpectrumAnalyzer`는 비싸다.**
   모바일에서는 피한다. 음높이 변경은 `pitch_scale`(재생 속도 변경)로 대체한다.

6. **앱이 백그라운드로 갈 때 오디오를 멈춘다.**

```gdscript
func _notification(what: int) -> void:
    match what:
        NOTIFICATION_APPLICATION_PAUSED:
            AudioServer.set_bus_mute(AudioServer.get_bus_index("Master"), true)
        NOTIFICATION_APPLICATION_RESUMED:
            AudioServer.set_bus_mute(AudioServer.get_bus_index("Master"), false)
```

7. **오디오 포커스** — 다른 앱(전화, 음악)이 오디오를 점유하면
   Android가 자동으로 처리하지만, 게임 상태도 함께 일시정지하는 편이 좋다.

---

## 11. 자주 하는 실수

| 실수 | 증상 | 해결 |
|------|------|------|
| 3D 사운드가 스테레오 파일 | 위치감 없음 | 임포트에서 `Force/Mono` On |
| 슬라이더를 `volume_db`에 직접 연결 | 대부분 범위에서 변화 없음 | `linear_to_db()` |
| `max_distance = 0` | CPU 낭비 | 적절한 값 설정 |
| 매번 플레이어 노드 생성/삭제 | 프레임 저하 | 풀링 |
| 같은 효과음을 그대로 반복 | 기계적으로 들림 | `AudioStreamRandomizer` |
| Master에 리미터 없음 | 소리 겹칠 때 찢어짐 | `AudioEffectLimiter` 추가 |
| 짧은 효과음을 .ogg로 | 디코딩 오버헤드 | .wav 사용 |
| BGM을 .wav로 | 파일 크기 폭증 | .ogg 사용 |
| 일시정지 시 오디오 매니저도 멈춤 | UI 소리가 안 남 | `PROCESS_MODE_ALWAYS` |
| 크로스페이드 중 새 요청 | 볼륨이 튐 | 기존 Tween `kill()` |
| 모바일에서 `output_latency` 과도하게 낮춤 | 지직거림 | 기본값 유지 |
| `pitch_scale`을 매우 크게/작게 | 품질 저하 | 0.5~2.0 범위 유지 |
