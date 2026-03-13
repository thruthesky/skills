# Flutter Isolate 가이드

Flutter에서 무거운 작업 수행 시 UI Jank(프레임 드랍)를 방지하기 위한 Isolate 사용 가이드.

## 핵심 개념

### Isolate란?
- Dart의 동시성 모델로, **자체 메모리를 가진 독립 실행 환경**
- 상태 공유 없이 **메시지 패싱으로만 통신**
- Flutter 앱은 기본적으로 메인 Isolate에서 모든 작업 수행

### Event Loop와 UI Jank
```
메인 Isolate Event Queue:
├── UI 터치 이벤트
├── 함수 실행
└── 프레임 렌더링 (60fps = 16.67ms마다)
```
**UI Jank 발생**: 프레임 간격(16.67ms) 내에 작업 미완료 시 발생

---

## 사용 시점

### Isolate 사용이 필요한 경우
```
✓ 대용량 JSON 파싱/디코딩
✓ 이미지/오디오/비디오 처리 및 압축
✓ 로컬 데이터베이스 대량 읽기/쓰기
✓ 복잡한 리스트/데이터 필터링
✓ 암호화/해싱 연산
✓ 파일 변환 작업
```

### Isolate 사용이 불필요한 경우
```
✗ 단순 HTTP 요청 (이미 비동기)
✗ 작은 JSON 파싱 (<10KB)
✗ 단순 UI 상태 업데이트
✗ 기본 파일 I/O
```

---

## Isolate.run() - 단기 Isolate (권장)

### 기본 사용법
```dart
import 'dart:isolate';
import 'dart:convert';

/// JSON 파싱을 Isolate에서 수행
Future<List<MyModel>> parseJsonInIsolate(String jsonString) {
  return Isolate.run(() {
    final List<dynamic> jsonList = json.decode(jsonString);
    return jsonList
        .map((e) => MyModel.fromJson(e as Map<String, dynamic>))
        .toList();
  });
}
```

### 실제 프로젝트 예시 (TravelSpotService)
```dart
/// lib/services/travel/travel_spot.service.dart
static Future<List<TravelSpot>> _parseJsonInIsolate(String jsonString) {
  return Isolate.run(() {
    final List<dynamic> jsonList = json.decode(jsonString);
    return jsonList
        .map((e) => TravelSpot.fromJson(e as Map<String, dynamic>))
        .toList();
  });
}

/// 사용 예시
Future<List<TravelSpot>> _fetchFromRemote() async {
  final response = await http.get(Uri.parse(_remoteUrl));
  if (response.statusCode != 200) {
    throw Exception('HTTP ${response.statusCode}');
  }

  /// Isolate에서 JSON 디코딩 (메인 스레드 차단 방지)
  return _parseJsonInIsolate(response.body);
}
```

### 주의사항
- 콜백 함수는 **top-level 또는 static 메서드**여야 함
- 클로저 내에서 **인스턴스 변수 접근 불가**
- **웹 플랫폼 미지원** (compute() 사용 필요)

---

## compute() - 플랫폼 호환 방식

### 기본 사용법
```dart
import 'package:flutter/foundation.dart';

/// top-level 또는 static 함수 필수
List<MyModel> _parseJson(String jsonString) {
  final List<dynamic> jsonList = json.decode(jsonString);
  return jsonList.map((e) => MyModel.fromJson(e)).toList();
}

/// compute() 호출
Future<List<MyModel>> loadData(String jsonString) async {
  return await compute(_parseJson, jsonString);
}
```

### 플랫폼별 동작
| 플랫폼 | 동작 |
|--------|------|
| iOS/Android/Desktop | 별도 스레드에서 실행 |
| Web | 메인 스레드에서 실행 (Isolate 미지원) |

---

## 장기 Isolate (ReceivePort/SendPort)

반복적인 계산이나 지속적인 백그라운드 작업에 사용.

### 기본 패턴
```dart
import 'dart:isolate';

class BackgroundWorker {
  late SendPort _sendPort;
  late Isolate _isolate;

  Future<void> start() async {
    final receivePort = ReceivePort();
    _isolate = await Isolate.spawn(_workerEntryPoint, receivePort.sendPort);

    /// 워커의 SendPort 수신
    _sendPort = await receivePort.first as SendPort;
  }

  /// 워커에 작업 요청
  Future<dynamic> process(dynamic data) async {
    final responsePort = ReceivePort();
    _sendPort.send([data, responsePort.sendPort]);
    return await responsePort.first;
  }

  void stop() {
    _isolate.kill();
  }
}

/// 워커 진입점 (top-level 함수)
void _workerEntryPoint(SendPort mainSendPort) {
  final workerReceivePort = ReceivePort();
  mainSendPort.send(workerReceivePort.sendPort);

  workerReceivePort.listen((message) {
    final data = message[0];
    final replyPort = message[1] as SendPort;

    /// 무거운 작업 수행
    final result = _heavyComputation(data);
    replyPort.send(result);
  });
}
```

---

## 제한사항

### 1. 메모리 독립성
```dart
/// ❌ 작동 안 함 - Isolate 간 상태 공유 불가
class AppState {
  static String value = 'initial';
}

void _worker(_) {
  AppState.value = 'changed';  // 메인 Isolate의 value는 변경되지 않음
}
```

### 2. rootBundle 접근 불가
```dart
/// ❌ Isolate 내에서 불가능
void _worker(_) async {
  final data = await rootBundle.loadString('assets/data.json');  // 오류!
}

/// ✓ 해결책: 메인에서 먼저 로드 후 전달
Future<void> main() async {
  final data = await rootBundle.loadString('assets/data.json');
  final result = await Isolate.run(() => processData(data));
}
```

### 3. UI/Widget 작업 불가
```dart
/// ❌ Isolate에서 불가능
void _worker(_) {
  setState(() {});         // 불가
  context.push('/home');   // 불가
}
```

### 4. 플랫폼 플러그인 사용 시 초기화 필요 (Flutter 3.7+)
```dart
void main() {
  RootIsolateToken rootIsolateToken = RootIsolateToken.instance!;
  Isolate.spawn(_isolateMain, rootIsolateToken);
}

Future<void> _isolateMain(RootIsolateToken token) async {
  BackgroundIsolateBinaryMessenger.ensureInitialized(token);
  /// 이제 플러그인 사용 가능
}
```

---

## 코드 템플릿

### 서비스에서 Isolate 사용 패턴
```dart
import 'dart:convert';
import 'dart:isolate';

import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:http/http.dart' as http;

class DataService {
  static DataService? _instance;
  static DataService get instance => _instance ??= DataService._();
  DataService._();

  /// 데이터 로드 (캐시 → 원격 → 번들 폴백)
  Future<List<MyModel>> loadData() async {
    try {
      final response = await http.get(Uri.parse('https://api.example.com/data'));
      if (response.statusCode == 200) {
        return _parseJsonInIsolate(response.body);
      }
    } catch (e) {
      debugPrint('원격 로드 실패: $e');
    }

    /// 폴백: 번들 파일
    final jsonString = await rootBundle.loadString('assets/data.json');
    return _parseJsonInIsolate(jsonString);
  }

  /// Isolate에서 JSON 파싱 (static 필수)
  static Future<List<MyModel>> _parseJsonInIsolate(String jsonString) {
    return Isolate.run(() {
      final List<dynamic> jsonList = json.decode(jsonString);
      return jsonList
          .map((e) => MyModel.fromJson(e as Map<String, dynamic>))
          .toList();
    });
  }
}
```

---

## 선택 가이드

| 상황 | 권장 방식 |
|------|-----------|
| 일회성 무거운 작업 | `Isolate.run()` |
| 웹 호환 필요 | `compute()` |
| 반복/지속 작업 | 장기 Isolate (ReceivePort/SendPort) |
| 작은 작업 (<10ms) | Isolate 불필요 (오버헤드 > 이득) |
