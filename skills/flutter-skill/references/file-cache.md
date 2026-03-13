파일 캐시 코딩 가이드라인
=====

`file_cache_flutter` 패키지를 사용한 데이터 캐싱 가이드입니다.

## 개요

file_cache_flutter는 philgo_app 프로젝트 전용 범용 파일 캐시 라이브러리입니다.

**핵심 특징:**
- 메모리 + 파일 이중 캐싱
- TTL(Time-To-Live) 지원
- 제네릭 타입으로 모든 데이터 캐싱 가능
- 키-값 기반 저장

**패키지 위치:** `packages/file_cache_flutter/`

## 핵심 클래스

### FileCache<T>

```dart
final cache = FileCache<MyData>(
  cacheName: 'my_cache',           // 캐시 디렉토리명 (필수)
  fromJson: MyData.fromJson,       // JSON → T 변환 (필수)
  toJson: (d) => d.toJson(),       // T → JSON 변환 (필수)
  defaultTtl: Duration(minutes: 30), // 기본 TTL
  useMemoryCache: true,            // 메모리 캐시 사용 여부
  enableLogging: false,            // 디버그 로그
);
```

### 주요 메서드

| 메서드 | 설명 |
|--------|------|
| `get(key)` | 캐시 조회 (만료 시 null) |
| `set(key, data, {ttl})` | 캐시 저장 |
| `has(key)` | 존재 여부 확인 |
| `remove(key)` | 특정 캐시 삭제 |
| `clear()` | 전체 캐시 삭제 |
| `cleanup()` | 만료된 캐시 정리 |
| `getRemainingTime(key)` | 남은 시간 조회 |

## 서비스 구현 패턴

philgo_app에서 사용하는 표준 패턴입니다. **반드시 이 패턴을 따라 구현하세요.**

### 싱글톤 + 캐시 우선 전략

```dart
import 'package:file_cache_flutter/file_cache_flutter.dart';

class MyService {
  // 1. 싱글톤 패턴
  static MyService? _instance;
  static MyService get instance => _instance ??= MyService._();
  MyService._();

  // 2. 캐시 설정
  static const Duration cacheTtl = Duration(minutes: 25);
  static const String _cacheKey = 'my_data';

  // 3. FileCache 인스턴스
  late final FileCache<MyData> _cache = FileCache<MyData>(
    cacheName: 'my_data',
    defaultTtl: cacheTtl,
    fromJson: MyData.fromJson,
    toJson: (data) => data.toJson(),
    useMemoryCache: true,
  );

  // 4. 캐시 우선 로드 메서드
  Future<MyData> loadData() async {
    // 캐시 먼저 확인
    final cached = await _cache.get(_cacheKey);
    if (cached != null) return cached;

    // API 호출
    final data = await _fetchFromApi();

    // 캐시 저장
    await _cache.set(_cacheKey, data);
    return data;
  }

  // 5. 캐시 초기화
  Future<void> clearCache() async {
    await _cache.clear();
  }

  // 6. 남은 시간 조회
  Duration? get cacheRemainingTime => _cache.getRemainingTime(_cacheKey);
}
```

### 실제 사용 예시 (philgo_app)

| 서비스 | TTL | 캐시명 | 용도 |
|--------|-----|--------|------|
| CurrencyService | 25분 | exchange_rate | 환율 데이터 |
| WeatherService | 20분 | weather | 날씨 데이터 |
| PostContentService | 48시간 | post_content | 게시글 |
| DataService | 48시간 | mofa_notices | 외교부 공지 |

## 데이터 모델 설계

### 필수 구현: fromJson / toJson

```dart
class ExchangeRateData {
  final Map<String, double> rates;
  final String date;

  const ExchangeRateData({required this.rates, required this.date});

  // 필수: JSON 역직렬화
  factory ExchangeRateData.fromJson(Map<String, dynamic> json) {
    return ExchangeRateData(
      rates: Map<String, double>.from(json['rates']),
      date: json['date'] as String,
    );
  }

  // 필수: JSON 직렬화
  Map<String, dynamic> toJson() => {'rates': rates, 'date': date};
}
```

### 리스트 캐싱: 래퍼 클래스 패턴

FileCache는 단일 객체용이므로 리스트는 래퍼 클래스 사용:

```dart
// 래퍼 클래스
class TravelSpotsData {
  final List<TravelSpot> spots;
  final DateTime fetchedAt;

  const TravelSpotsData({required this.spots, required this.fetchedAt});

  factory TravelSpotsData.fromJson(Map<String, dynamic> json) {
    return TravelSpotsData(
      spots: (json['spots'] as List)
          .map((e) => TravelSpot.fromJson(e))
          .toList(),
      fetchedAt: DateTime.parse(json['fetchedAt'] as String),
    );
  }

  Map<String, dynamic> toJson() => {
    'spots': spots.map((e) => e.toJson()).toList(),
    'fetchedAt': fetchedAt.toIso8601String(),
  };
}

// 캐시 사용
final cache = FileCache<TravelSpotsData>(
  cacheName: 'travel_spots',
  fromJson: TravelSpotsData.fromJson,
  toJson: (d) => d.toJson(),
);
```

### 중첩 객체 처리

```dart
class WeatherData {
  final Map<String, CityWeatherData> cities;
  final DateTime fetchedAt;

  factory WeatherData.fromJson(Map<String, dynamic> json) {
    final citiesMap = <String, CityWeatherData>{};
    final citiesJson = json['cities'] as Map<String, dynamic>;

    for (final entry in citiesJson.entries) {
      citiesMap[entry.key] = CityWeatherData.fromJson(entry.value);
    }

    return WeatherData(
      cities: citiesMap,
      fetchedAt: DateTime.parse(json['fetchedAt'] as String),
    );
  }

  Map<String, dynamic> toJson() {
    final citiesJson = <String, dynamic>{};
    for (final entry in cities.entries) {
      citiesJson[entry.key] = entry.value.toJson();
    }
    return {'cities': citiesJson, 'fetchedAt': fetchedAt.toIso8601String()};
  }
}
```

## 동적 캐시 키 패턴

게시글처럼 ID별로 캐싱이 필요한 경우:

```dart
Future<Post> loadPost(int postId, {bool forceRefresh = false}) async {
  final cacheKey = 'post_$postId';  // 동적 키

  if (!forceRefresh) {
    final cached = await _cache.get(cacheKey);
    if (cached != null) return cached;
  }

  final post = await getPost(postId);
  await _cache.set(cacheKey, post);
  return post;
}

// 특정 게시글 캐시만 삭제
Future<void> clearPostCache(int postId) async {
  await _cache.remove('post_$postId');
}
```

## 개별 TTL 설정

```dart
// 특정 항목만 다른 TTL 적용
await cache.set(
  'important_data',
  data,
  ttl: Duration(hours: 2),  // 기본 TTL 무시
);
```

## 캐시 남은 시간 표시

```dart
// UI에서 캐시 남은 시간 표시
Duration? get cacheRemainingTime => _cache.getRemainingTime(_cacheKey);

// 위젯에서 사용
Text('다음 업데이트: ${remaining?.inMinutes ?? 0}분 후')
```

## 다중 캐시 인스턴스

하나의 서비스에서 여러 캐시 사용:

```dart
class WeatherService {
  // 전체 날씨 데이터 캐시
  late final FileCache<WeatherData> _cache = FileCache<WeatherData>(
    cacheName: 'weather',
    defaultTtl: Duration(minutes: 20),
    fromJson: WeatherData.fromJson,
    toJson: (d) => d.toJson(),
  );

  // 마닐라 현재 날씨 캐시 (별도)
  late final FileCache<HourlyWeather> _manilaCache = FileCache<HourlyWeather>(
    cacheName: 'manila_current',
    defaultTtl: Duration(minutes: 20),
    fromJson: HourlyWeather.fromJson,
    toJson: (d) => d.toJson(),
  );
}
```

## TTL 권장값

| 데이터 유형 | 권장 TTL | 이유 |
|------------|----------|------|
| 환율 | 25분 | API 호출 제한, 실시간 불필요 |
| 날씨 | 20분 | 적절한 업데이트 주기 |
| 뉴스/공지 | 48시간 | 자주 변경되지 않음 |
| 게시글 | 48시간 | 정보성 글은 변경 적음 |
| 사용자 데이터 | 5-10분 | 빠른 업데이트 필요 |

## 주의사항

1. **fromJson/toJson 필수**: 모든 캐시 데이터는 JSON 직렬화 가능해야 함
2. **DateTime 직렬화**: `toIso8601String()` / `DateTime.parse()` 사용
3. **Map 캐스팅**: `Map<String, double>.from(json['rates'])` 형태로 안전하게 캐스팅
4. **특수문자 키**: 키에 특수문자 포함 시 자동으로 언더스코어로 변환됨
5. **메모리 캐시**: 앱 재시작 시 메모리 캐시는 사라지지만 파일 캐시는 유지됨

## 테스트 코드 작성

```dart
import 'package:flutter_test/flutter_test.dart';
import 'package:file_cache_flutter/file_cache_flutter.dart';
import 'package:path_provider_platform_interface/path_provider_platform_interface.dart';
import 'package:plugin_platform_interface/plugin_platform_interface.dart';

// Mock PathProvider
class MockPathProviderPlatform extends Fake
    with MockPlatformInterfaceMixin
    implements PathProviderPlatform {
  final String tempPath;
  MockPathProviderPlatform(this.tempPath);

  @override
  Future<String?> getTemporaryPath() async => tempPath;
}

void main() {
  late Directory tempDir;
  late FileCache<TestData> cache;

  setUp(() async {
    tempDir = await Directory.systemTemp.createTemp('test_');
    PathProviderPlatform.instance = MockPathProviderPlatform(tempDir.path);

    cache = FileCache<TestData>(
      cacheName: 'test',
      fromJson: TestData.fromJson,
      toJson: (d) => d.toJson(),
    );
  });

  tearDown(() async {
    if (await tempDir.exists()) {
      await tempDir.delete(recursive: true);
    }
  });

  test('should store and retrieve data', () async {
    await cache.set('key1', TestData(name: 'test', value: 123));
    final result = await cache.get('key1');

    expect(result, isNotNull);
    expect(result!.name, 'test');
  });
}
```
