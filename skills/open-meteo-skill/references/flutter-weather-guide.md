# Flutter 날씨 구현 가이드

Open-Meteo API를 활용한 Flutter 앱 날씨 기능 구현 가이드입니다.

**핵심 설계 원칙: 도시명 + 국가코드 기반 날씨 조회**

위도/경도를 직접 지정하지 않습니다. 도시명과 국가코드만 설정하면
Open-Meteo Geocoding API가 자동으로 위도/경도를 조회합니다.
별도 위치 모델(WeatherLocation) 없이 `CenterAppConfig`의 설정만으로 동작합니다.

## 관련 소스 코드

- 날씨 모델: [lib/weather/models/weather.model.dart](../../../lib/weather/models/weather.model.dart)
- 날씨 서비스: [lib/weather/services/weather.service.dart](../../../lib/weather/services/weather.service.dart)
- 날씨 화면: [lib/weather/screens/weather.screen.dart](../../../lib/weather/screens/weather.screen.dart)
- 앱 설정 추상 클래스: [lib/abstractions/center.app.config.dart](../../../lib/abstractions/center.app.config.dart)
- 수도 도시 매핑: [lib/weather/constants/capital_cities.dart](../../../lib/weather/constants/capital_cities.dart)

---

## 1. 앱 설정 (CenterAppConfig)

각 앱은 `CenterAppConfig`를 상속하여 `weatherCityName`과 `countryCode`를 필수로 구현해야 합니다.
별도 위치 모델 없이 이 두 속성만으로 날씨가 동작합니다.

```dart
abstract class CenterAppConfig {
  String get countryCode;        // 국가 코드 (필수)
  String get weatherCityName;    // 날씨 도시명 (필수)
  // ... 기타 속성
}
```

**앱별 설정 예시:**

```dart
// Singapore 앱
class SingaporeAppConfig extends CenterAppConfig {
  @override String get countryCode => 'sg';
  @override String get weatherCityName => 'Singapore';
}

// Angcafe 앱 (Angeles City)
class AngcafeConfig extends CenterAppConfig {
  @override String get countryCode => 'ph';
  @override String get weatherCityName => 'Angeles City';
}

// USA 앱
class USAConfig extends CenterAppConfig {
  @override String get countryCode => 'us';
  @override String get weatherCityName => 'Washington';
}
```

---

## 2. WeatherService 위치 결정 흐름

### 2.1 위치 결정 우선순위

```
호출: _resolveCity() (내부 전용)
  │
  ├─ 1순위: appConfig.weatherCityName + countryCode
  │   → (cityName: 'Singapore', countryCode: 'sg')
  │
  └─ 2순위: capitalCities[countryCode] + countryCode (기본값)
      → (cityName: 'Singapore', countryCode: 'sg')
```

### 2.2 Geocoding → Forecast 자동 파이프라인

WeatherService 내부에서 자동으로 처리되는 흐름:

```
_resolveCity() → (cityName: 'Singapore', countryCode: 'sg')
  │
  ├─ [Geocoding API 호출 - 내부 자동]
  │   GET geocoding-api.open-meteo.com/v1/search
  │     ?name=Singapore&country=sg&count=1&language=en
  │   ⚠️ 파라미터명은 'country'입니다 ('countryCode'가 아님!)
  │   → {latitude: 1.2897, longitude: 103.8501, timezone: 'Asia/Singapore'}
  │   → 7일간 캐시
  │
  └─ [Forecast API 호출]
      GET api.open-meteo.com/v1/forecast
        ?latitude=1.2897&longitude=103.8501
        &hourly=temperature_2m,weather_code,relative_humidity_2m
        &forecast_days=8&timezone=Asia/Singapore
      → WeatherData (192개 HourlyWeather)
      → 30분간 캐시
```

### 2.3 _resolveCity 핵심 코드

```dart
/// 앱 설정에서 도시명과 국가코드를 결정 (내부 전용)
({String cityName, String countryCode}) _resolveCity() {
  final config = CenterService.instance.appConfig;
  final countryCode = config.countryCode.toLowerCase();
  final cityName = config.weatherCityName;

  // weatherCityName이 설정된 경우
  if (cityName != '') {
    return (cityName: cityName, countryCode: countryCode);
  }

  // 기본값: 수도 자동 검색 (capitalCities 상수 사용)
  final capitalName =
      capitalCities[countryCode.toUpperCase()] ?? config.countryName;
  return (cityName: capitalName, countryCode: countryCode);
}
```

### 2.4 내부 Geocoding 메서드

```dart
/// Open-Meteo Geocoding API로 도시명+국가코드 → 위도/경도/타임존 변환
/// ⚠️ 파라미터명은 'country'입니다 ('countryCode'가 아님!)
/// Geocoding 결과는 7일간 캐시됩니다.
Future<Map<String, dynamic>> _geocode(String cityName, String countryCode) async {
  final cacheKey = _buildGeocodingCacheKey(cityName, countryCode);

  // 캐시 확인
  final cached = await _geocodingCache.get(cacheKey);
  if (cached != null) return cached;

  // Geocoding API 호출
  final response = await dio.get(
    'https://geocoding-api.open-meteo.com/v1/search',
    queryParameters: {
      'name': cityName,
      'country': countryCode,  // ⚠️ 'countryCode'가 아닌 'country' 사용!
      'count': 1,
      'language': 'en',
    },
  );

  final results = response.data['results'] as List?;
  if (results == null || results.isEmpty) {
    throw Exception('날씨 위치를 찾을 수 없습니다: $cityName ($countryCode)');
  }

  final r = results.first as Map<String, dynamic>;
  final result = {
    'latitude': (r['latitude'] as num).toDouble(),
    'longitude': (r['longitude'] as num).toDouble(),
    'timezone': r['timezone'] as String,
    'resolvedName': r['name'] as String,
  };

  // 캐시 저장
  await _geocodingCache.set(cacheKey, result);
  return result;
}
```

---

## 3. 캐시 설정

### 3.1 이중 캐시 구조

| 캐시 대상 | TTL | 용도 | 메모리 캐시 |
|-----------|-----|------|------------|
| **Geocoding 결과** | 7일 | 도시명 → 위도/경도/타임존 | O |
| **날씨 데이터** | 30분 | Forecast API 응답 | O |

### 3.2 FileCache 설정

```dart
/// 날씨 데이터 캐시 (30분 TTL)
final _weatherCache = FileCache<WeatherData>(
  cacheName: 'weather',
  defaultTtl: Duration(minutes: 30),
  fromJson: WeatherData.fromJson,
  toJson: (data) => data.toJson(),
  useMemoryCache: true,
);

/// Geocoding 결과 캐시 (7일 TTL)
final _geocodingCache = FileCache<Map<String, dynamic>>(
  cacheName: 'weather_geocoding',
  defaultTtl: Duration(days: 7),
  fromJson: (json) => Map<String, dynamic>.from(json),
  toJson: (data) => data,
  useMemoryCache: true,
);
```

### 3.3 캐시 키 생성

```dart
/// 날씨 캐시 키 (도시명 + 국가코드 기반)
String _buildCacheKey(String cityName, String countryCode) {
  final raw = 'weather_${countryCode}_${cityName.toLowerCase().replaceAll(' ', '_')}';
  return raw.replaceAll(RegExp(r'[^a-zA-Z0-9_-]'), '_');
}

/// Geocoding 캐시 키
String _buildGeocodingCacheKey(String cityName, String countryCode) {
  return 'geo_${countryCode}_$cityName'
      .toLowerCase()
      .replaceAll(' ', '_')
      .replaceAll(RegExp(r'[^a-z0-9_]'), '_');
}
```

---

## 4. 시간대별 날씨 표시 기법

### 4.1 핵심 개념

| 기간 | 표시 간격 | 이유 |
|------|----------|------|
| **오늘** | 2시간 단위 | 현재 시간 근처의 상세한 날씨 정보 필요 |
| **내일~7일** | 4시간 단위 | 대략적인 일별 날씨 패턴 파악 |

### 4.2 오늘 날씨 (2시간 단위)

```dart
List<HourlyWeather> getTodayWeather() {
  final now = DateTime.now();
  final today = DateTime(now.year, now.month, now.day);
  final tomorrow = today.add(const Duration(days: 1));

  final todayWeather = hourlyWeather
      .where((w) =>
          w.time.isAfter(now.subtract(const Duration(hours: 1))) &&
          w.time.isBefore(tomorrow))
      .toList();

  // 2시간 단위 (짝수 시간대: 00, 02, 04, ..., 22시)
  return todayWeather.where((w) => w.time.hour % 2 == 0).toList();
}
```

### 4.3 내일~7일 날씨 (4시간 단위)

```dart
List<HourlyWeather> getDayWeather(DateTime date) {
  final dayStart = DateTime(date.year, date.month, date.day);
  final dayEnd = dayStart.add(const Duration(days: 1));

  final dayWeather = hourlyWeather
      .where((w) => w.time.isAfter(dayStart) || w.time.isAtSameMomentAs(dayStart))
      .where((w) => w.time.isBefore(dayEnd))
      .toList();

  // 4시간 단위 (0, 4, 8, 12, 16, 20시)
  return dayWeather.where((w) => w.time.hour % 4 == 0).toList();
}
```

---

## 5. 캐시 기반 실시간 날씨 아이콘 표시

### 5.1 FutureBuilder 패턴

```dart
FutureBuilder<HourlyWeather?>(
  future: WeatherService.instance.getCurrentWeather(),
  builder: (context, snapshot) {
    final weather = snapshot.data;
    final weatherIcon = weather?.icon ?? Icons.wb_cloudy;
    final weatherIconColor = weather?.iconColor ?? const Color(0xFFFF9800);

    return _buildQuickMenuItem(
      icon: weatherIcon,
      label: '날씨',
      color: const Color(0xFFFFF3E0),
      iconColor: weatherIconColor,
      onTap: () => WeatherScreen.show(context),
    );
  },
),
```

### 5.2 현재 날씨 조회 로직

```dart
/// WeatherData.getCurrentWeather() - 현재 시간과 가장 가까운 날씨
HourlyWeather? getCurrentWeather() {
  if (hourlyWeather.isEmpty) return null;
  final now = DateTime.now();

  HourlyWeather? closest;
  int? minDiff;
  for (final weather in hourlyWeather) {
    final diff = (weather.time.difference(now).inMinutes).abs();
    if (minDiff == null || diff < minDiff) {
      minDiff = diff;
      closest = weather;
    }
  }
  return closest;
}

/// WeatherService.getCurrentWeather() - 서비스 레벨 (파라미터 없음)
Future<HourlyWeather?> getCurrentWeather() async {
  try {
    final data = await getWeather();
    return data.getCurrentWeather();
  } catch (e) {
    return null;  // 에러 시 null → UI에서 기본 아이콘 표시
  }
}
```

---

## 6. WMO 날씨 코드 매핑

### 6.1 아이콘 매핑

| WMO 코드 | 설명 | 낮 아이콘 | 밤 아이콘 | 색상 |
|-----------|------|-----------|-----------|------|
| 0 | 맑음 | `Icons.wb_sunny` | `Icons.nights_stay` | 노란/보라 |
| 1-2 | 대체로 맑음 | `Icons.wb_sunny` | `Icons.nights_stay` | 노란/보라 |
| 3 | 흐림 | `Icons.cloud` | `Icons.cloud` | 회색 |
| 45-48 | 안개 | `Icons.foggy` | `Icons.foggy` | 연한 회색 |
| 51-57 | 이슬비 | `Icons.grain` | `Icons.grain` | 파란 |
| 61-67 | 비 | `Icons.water_drop` | `Icons.water_drop` | 파란 |
| 71-77 | 눈 | `Icons.ac_unit` | `Icons.ac_unit` | 하늘 |
| 80-82 | 소나기 | `Icons.shower` | `Icons.shower` | 파란 |
| 95-99 | 뇌우 | `Icons.thunderstorm` | `Icons.thunderstorm` | 보라 |

### 6.2 낮/밤 판단

```dart
bool get isDay {
  final hour = time.hour;
  return hour >= 6 && hour < 18;
}
```

---

## 7. Forecast API 파라미터

위도/경도는 Geocoding API에서 자동으로 획득되며, 직접 지정하지 않습니다.

```dart
final response = await dio.get(
  'https://api.open-meteo.com/v1/forecast',
  queryParameters: {
    'latitude': geo['latitude'],      // Geocoding 결과에서 자동 획득
    'longitude': geo['longitude'],    // Geocoding 결과에서 자동 획득
    'hourly': 'temperature_2m,weather_code,relative_humidity_2m',
    'forecast_days': 8,
    'timezone': geo['timezone'],      // Geocoding 결과에서 자동 획득
  },
);
```

| 파라미터 | 값 | 설명 |
|---------|-----|------|
| `latitude` | Geocoding 자동 | 도시명+국가코드 → Geocoding API → 위도 |
| `longitude` | Geocoding 자동 | 도시명+국가코드 → Geocoding API → 경도 |
| `hourly` | temperature_2m,weather_code,relative_humidity_2m | 시간별 데이터 |
| `forecast_days` | 8 | 오늘 포함 8일간 예보 |
| `timezone` | Geocoding 자동 | 도시명+국가코드 → Geocoding API → 타임존 |

---

## 8. 전체 구현 체크리스트

### 8.1 앱 설정 (필수)

- [ ] `CenterAppConfig` 상속
- [ ] `countryCode` 구현 (필수!)
- [ ] `weatherCityName` 구현 (필수! 날씨를 표시할 도시명)

### 8.2 모델 (weather.model.dart)

- [ ] `HourlyWeather` 클래스 - 시간별 날씨 데이터
  - [ ] `icon` getter - WMO 코드 → Flutter 아이콘
  - [ ] `iconColor` getter - WMO 코드 → 아이콘 색상
  - [ ] `isDay` getter - 낮/밤 판단
  - [ ] `description` getter - 한글 날씨 설명
- [ ] `WeatherData` 클래스 - 전체 날씨 응답
  - [ ] `getTodayWeather()` - 오늘 2시간 단위
  - [ ] `getDayWeather(date)` - 특정일 4시간 단위
  - [ ] `getUpcomingDays()` - 내일~7일 날짜 목록
  - [ ] `getCurrentWeather()` - 현재 시간 날씨

### 8.3 서비스 (weather.service.dart)

- [ ] 싱글톤 패턴 적용
- [ ] 30분 FileCache (날씨 데이터)
- [ ] 7일 FileCache (Geocoding 결과)
- [ ] `_resolveCity()` - 앱 설정에서 도시명+국가코드 자동 결정 (내부 전용)
- [ ] `_geocode()` - 도시명+국가코드 → 위도/경도 (내부 전용, **`country` 파라미터 사용!**)
- [ ] `getWeather()` - 캐시 우선 조회 (파라미터 없음)
- [ ] `getResolvedCityName()` - Geocoding 해결된 도시명 조회
- [ ] `getCurrentWeather()` - 현재 날씨 조회 (파라미터 없음)
- [ ] `clearCache()` - 캐시 삭제 (파라미터 없음)

### 8.4 화면 (홈 퀵메뉴)

- [ ] FutureBuilder로 동적 아이콘 표시
- [ ] 로딩/에러 시 기본 아이콘 폴백
- [ ] 아이콘 탭 시 날씨 화면 표시 (BottomSheet)
