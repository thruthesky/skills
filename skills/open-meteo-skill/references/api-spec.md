# Open-Meteo API 상세 명세서

## 목차

1. [개요](#개요)
2. [Forecast API (날씨 예보)](#forecast-api-날씨-예보)
3. [Archive API (과거 데이터)](#archive-api-과거-데이터)
4. [Air Quality API (대기질)](#air-quality-api-대기질)
5. [Marine API (해양 날씨)](#marine-api-해양-날씨)
6. [Geocoding API (위치 검색)](#geocoding-api-위치-검색)
7. [Elevation API (고도)](#elevation-api-고도)
8. [응답 형식](#응답-형식)
9. [에러 처리](#에러-처리)

---

## 개요

Open-Meteo는 전 세계 국가 기상청의 날씨 모델을 통합하여 고해상도 날씨 데이터를 제공하는 무료 오픈소스 API입니다.

### 기본 정보

| 항목 | 내용 |
|------|------|
| 기본 URL | `https://api.open-meteo.com/v1/` |
| 인증 | 불필요 (비상업적 사용) |
| 응답 형식 | JSON, CSV, XLSX |
| 요청 제한 | 공정 사용 정책 (명시적 제한 없음) |
| 타임아웃 | 30초 권장 |

### 지원 날씨 모델

| 제공자 | 모델 | 해상도 | 예보 기간 |
|--------|------|--------|-----------|
| ECMWF (EU) | IFS, AIFS | 25km | 15일 |
| NOAA (미국) | GFS, HRRR | 3-25km | 16일 |
| DWD (독일) | ICON, ICON-D2 | 2-11km | 7.5일 |
| Météo-France | ARPEGE, AROME | 1-25km | 4일 |
| UK Met Office | UKMO | 10km | 7일 |
| JMA (일본) | MSM, GSM | 5-20km | 11일 |
| 캐나다 | GEM, HRDPS | 2.5-15km | 10일 |

---

## Forecast API (날씨 예보)

최대 16일의 날씨 예보 데이터를 제공합니다.

### 엔드포인트

```
GET https://api.open-meteo.com/v1/forecast
```

### 필수 파라미터

| 파라미터 | 타입 | 설명 |
|----------|------|------|
| `latitude` | float | 위도 (-90 ~ 90) |
| `longitude` | float | 경도 (-180 ~ 180) |

### 선택 파라미터

| 파라미터 | 기본값 | 설명 |
|----------|--------|------|
| `hourly` | - | 시간별 날씨 변수 (쉼표로 구분) |
| `daily` | - | 일별 날씨 변수 (쉼표로 구분) |
| `current` | - | 현재 날씨 변수 |
| `forecast_days` | 7 | 예보 기간 (0-16일) |
| `past_days` | 0 | 과거 데이터 포함 (0-92일) |
| `timezone` | GMT | 시간대 (auto 또는 IANA 형식) |
| `temperature_unit` | celsius | 온도 단위 (celsius/fahrenheit) |
| `wind_speed_unit` | kmh | 풍속 단위 (kmh/ms/mph/kn) |
| `precipitation_unit` | mm | 강수량 단위 (mm/inch) |
| `timeformat` | iso8601 | 시간 형식 (iso8601/unixtime) |
| `models` | auto | 특정 모델 선택 |

### 요청 예제

```bash
# 서울 7일 예보 (시간별 + 일별)
curl "https://api.open-meteo.com/v1/forecast?\
latitude=37.5665&\
longitude=126.9780&\
hourly=temperature_2m,relative_humidity_2m,precipitation,wind_speed_10m&\
daily=weather_code,temperature_2m_max,temperature_2m_min,sunrise,sunset&\
timezone=Asia/Seoul"
```

### 응답 예제

```json
{
  "latitude": 37.5625,
  "longitude": 126.96875,
  "generationtime_ms": 0.5,
  "utc_offset_seconds": 32400,
  "timezone": "Asia/Seoul",
  "timezone_abbreviation": "KST",
  "elevation": 38,
  "hourly_units": {
    "time": "iso8601",
    "temperature_2m": "°C",
    "precipitation": "mm"
  },
  "hourly": {
    "time": ["2024-01-15T00:00", "2024-01-15T01:00", ...],
    "temperature_2m": [2.1, 1.8, 1.5, ...],
    "precipitation": [0, 0, 0.2, ...]
  },
  "daily_units": {
    "time": "iso8601",
    "temperature_2m_max": "°C"
  },
  "daily": {
    "time": ["2024-01-15", "2024-01-16", ...],
    "temperature_2m_max": [5.2, 7.1, ...],
    "sunrise": ["2024-01-15T07:46", ...]
  }
}
```

---

## Archive API (과거 데이터)

1940년부터 현재까지의 역사적 날씨 데이터를 제공합니다 (ERA5 재분석 데이터).

### 엔드포인트

```
GET https://archive-api.open-meteo.com/v1/archive
```

### 필수 파라미터

| 파라미터 | 타입 | 설명 |
|----------|------|------|
| `latitude` | float | 위도 |
| `longitude` | float | 경도 |
| `start_date` | string | 시작일 (YYYY-MM-DD) |
| `end_date` | string | 종료일 (YYYY-MM-DD) |

### 요청 예제

```bash
# 서울 2023년 1월 과거 데이터
curl "https://archive-api.open-meteo.com/v1/archive?\
latitude=37.5665&\
longitude=126.9780&\
start_date=2023-01-01&\
end_date=2023-01-31&\
daily=temperature_2m_max,temperature_2m_min,precipitation_sum&\
timezone=Asia/Seoul"
```

---

## Air Quality API (대기질)

대기질 예보 데이터를 제공합니다.

### 엔드포인트

```
GET https://air-quality-api.open-meteo.com/v1/air-quality
```

### 주요 파라미터

| 파라미터 | 설명 |
|----------|------|
| `hourly` | 시간별 대기질 변수 |

### 대기질 변수

- `pm10`: 미세먼지 PM10 (μg/m³)
- `pm2_5`: 초미세먼지 PM2.5 (μg/m³)
- `carbon_monoxide`: 일산화탄소 (μg/m³)
- `nitrogen_dioxide`: 이산화질소 (μg/m³)
- `sulphur_dioxide`: 이산화황 (μg/m³)
- `ozone`: 오존 (μg/m³)
- `aerosol_optical_depth`: 에어로졸 광학 깊이
- `dust`: 먼지 (μg/m³)
- `uv_index`: 자외선 지수
- `european_aqi`: 유럽 대기질 지수
- `us_aqi`: 미국 대기질 지수

### 요청 예제

```bash
# 서울 대기질 예보
curl "https://air-quality-api.open-meteo.com/v1/air-quality?\
latitude=37.5665&\
longitude=126.9780&\
hourly=pm10,pm2_5,us_aqi,uv_index&\
timezone=Asia/Seoul"
```

---

## Marine API (해양 날씨)

파도 높이, 해수면 온도 등 해양 날씨 데이터를 제공합니다.

### 엔드포인트

```
GET https://marine-api.open-meteo.com/v1/marine
```

### 해양 변수

- `wave_height`: 파도 높이 (m)
- `wave_direction`: 파도 방향 (°)
- `wave_period`: 파도 주기 (s)
- `wind_wave_height`: 풍랑 높이 (m)
- `swell_wave_height`: 너울 높이 (m)
- `ocean_current_velocity`: 해류 속도 (m/s)
- `ocean_current_direction`: 해류 방향 (°)

### 요청 예제

```bash
# 부산 앞바다 해양 날씨
curl "https://marine-api.open-meteo.com/v1/marine?\
latitude=35.1796&\
longitude=129.0756&\
hourly=wave_height,wave_direction,wave_period&\
timezone=Asia/Seoul"
```

---

## Geocoding API (위치 검색)

지명으로 좌표를 검색합니다.

### 엔드포인트

```
GET https://geocoding-api.open-meteo.com/v1/search
```

### 파라미터

| 파라미터 | 타입 | 설명 |
|----------|------|------|
| `name` | string | 검색할 지명 (최소 2자) |
| `count` | int | 결과 수 (기본: 10, 최대: 100) |
| `language` | string | 언어 코드 (en, ko, ja 등) |
| `country` | string | ISO-3166-1 alpha-2 국가 코드 필터 (예: `sg`, `ph`, `us`). **주의: `countryCode`가 아닌 `country`를 사용해야 함** |

### 요청 예제

```bash
# "Seoul" 검색
curl "https://geocoding-api.open-meteo.com/v1/search?\
name=Seoul&\
count=5&\
language=ko"
```

### 응답 예제

```json
{
  "results": [
    {
      "id": 1835848,
      "name": "Seoul",
      "latitude": 37.566,
      "longitude": 126.9784,
      "elevation": 38,
      "feature_code": "PPLC",
      "country_code": "KR",
      "country": "South Korea",
      "timezone": "Asia/Seoul",
      "population": 10349312,
      "admin1": "Seoul"
    }
  ]
}
```

---

## Elevation API (고도)

특정 좌표의 고도 정보를 제공합니다.

### 엔드포인트

```
GET https://api.open-meteo.com/v1/elevation
```

### 파라미터

| 파라미터 | 타입 | 설명 |
|----------|------|------|
| `latitude` | float/array | 위도 (배열 가능) |
| `longitude` | float/array | 경도 (배열 가능) |

### 요청 예제

```bash
# 서울, 부산 고도 조회
curl "https://api.open-meteo.com/v1/elevation?\
latitude=37.5665,35.1796&\
longitude=126.9780,129.0756"
```

### 응답 예제

```json
{
  "elevation": [38, 12]
}
```

---

## 응답 형식

### 기본 응답 구조

```json
{
  "latitude": 37.5625,
  "longitude": 126.96875,
  "generationtime_ms": 0.5,
  "utc_offset_seconds": 32400,
  "timezone": "Asia/Seoul",
  "timezone_abbreviation": "KST",
  "elevation": 38,
  "hourly_units": { ... },
  "hourly": { ... },
  "daily_units": { ... },
  "daily": { ... },
  "current_units": { ... },
  "current": { ... }
}
```

### 시간 형식

- **iso8601**: `"2024-01-15T00:00"` (기본값)
- **unixtime**: `1705276800` (Unix 타임스탬프)

---

## 에러 처리

### HTTP 상태 코드

| 코드 | 설명 |
|------|------|
| 200 | 성공 |
| 400 | 잘못된 요청 (파라미터 오류) |
| 429 | 요청 제한 초과 |
| 500 | 서버 오류 |

### 에러 응답 예제

```json
{
  "error": true,
  "reason": "Latitude must be in range of -90 to 90°. Given: 100."
}
```

---

## 공식 문서 레퍼런스

- [Open-Meteo API 문서](https://open-meteo.com/en/docs)
- [Forecast API 문서](https://open-meteo.com/en/docs)
- [Historical Weather API](https://open-meteo.com/en/docs/historical-weather-api)
- [Air Quality API](https://open-meteo.com/en/docs/air-quality-api)
- [Marine Weather API](https://open-meteo.com/en/docs/marine-weather-api)
- [Geocoding API](https://open-meteo.com/en/docs/geocoding-api)
