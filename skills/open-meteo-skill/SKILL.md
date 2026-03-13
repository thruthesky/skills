---
name: open-meteo-skill
description: "전세계 날씨 데이터를 제공하는 무료 오픈소스 Open-Meteo API 통합 스킬. 16일 예보, 80년 역사 데이터, 대기질, 해양 날씨, 위치 검색, 고도 조회를 지원하며, Flutter 앱에서 시간대별 날씨 표시와 캐시 기반 실시간 아이콘 표시 기능을 구현하는 가이드를 포함합니다. Claude가 다음 작업을 수행해야 할 때 사용: (1) Open-Meteo API로 날씨/대기질/해양 데이터 조회, (2) Flutter 앱에 날씨 기능 구현 (WeatherService, 이중 캐시, FutureBuilder 패턴, WMO 코드 매핑), (3) Geocoding API로 도시명→좌표 변환, (4) 과거 날씨 데이터 분석, (5) MCP 서버를 통한 Claude Desktop 날씨 통합."
---

# Open-Meteo API 스킬

전 세계 국가 기상청 데이터를 통합한 무료 오픈소스 날씨 API. API 키 불필요, 10ms 이하 응답.

## 주요 엔드포인트

| 엔드포인트 | URL | 용도 |
|-----------|-----|------|
| Forecast | `api.open-meteo.com/v1/forecast` | 날씨 예보 (최대 16일) |
| Archive | `archive-api.open-meteo.com/v1/archive` | 과거 데이터 (1940~현재) |
| Air Quality | `air-quality-api.open-meteo.com/v1/air-quality` | 대기질 |
| Marine | `marine-api.open-meteo.com/v1/marine` | 해양 날씨 |
| Geocoding | `geocoding-api.open-meteo.com/v1/search` | 위치 검색 |
| Elevation | `api.open-meteo.com/v1/elevation` | 고도 조회 |

## 빠른 시작

```bash
curl "https://api.open-meteo.com/v1/forecast?latitude=37.5665&longitude=126.9780&hourly=temperature_2m,precipitation&daily=temperature_2m_max,temperature_2m_min&timezone=Asia/Seoul"
```

Forecast API 필수 파라미터: `latitude` (-90~90), `longitude` (-180~180).

Flutter 앱에서는 위도/경도 대신 **도시명 + 국가코드**를 사용한다. Geocoding API가 자동 변환.

## Geocoding API 핵심 주의사항

**국가 코드 파라미터명은 반드시 `country`를 사용한다 (`countryCode`가 아님).**

```bash
# 올바름 - country 파라미터
curl "https://geocoding-api.open-meteo.com/v1/search?name=Singapore&country=sg&count=1&language=en"

# 잘못됨 - countryCode는 무시됨
curl "https://geocoding-api.open-meteo.com/v1/search?name=Singapore&countryCode=sg&count=1&language=en"
```

동일 도시명이 여러 국가에 존재하므로 `country` 파라미터를 반드시 함께 사용한다.

## 상세 참조 문서

### API 상세 명세 → [api-spec.md](references/api-spec.md)

Open-Meteo의 6개 주요 API 엔드포인트(Forecast, Archive, Air Quality, Marine, Geocoding,
Elevation)의 상세 명세를 다룹니다. 각 API별 필수/선택 파라미터, 요청 URL 형식, JSON 응답
구조와 예제를 포함합니다. Forecast API의 시간별/일별 데이터 조회 방법, Archive API의
1940년~현재 역사 데이터 접근법, Air Quality API의 미세먼지/가스 변수, Marine API의
파도/해류 변수, Geocoding API의 지명→좌표 변환, Elevation API의 고도 조회를 설명합니다.
HTTP 상태 코드(200/400/429/500)와 에러 응답 형식, 지원 날씨 모델(ECMWF, NOAA, DWD 등)
목록도 포함합니다.

### Flutter 날씨 구현 가이드 → [flutter-weather-guide.md](references/flutter-weather-guide.md)

Flutter 앱에서 Open-Meteo API를 활용한 날씨 기능 구현 전체 가이드를 다룹니다.
**도시명+국가코드 기반 위치 결정** (위도/경도 직접 지정 불필요, Geocoding API 자동 변환),
`CenterAppConfig.weatherCityName` + `countryCode` 필수 설정,
`WeatherService`가 내부적으로 `_resolveCity()`를 통해 앱 설정에서 도시명과 국가코드를 자동 결정,
**시간대별 날씨 표시 기법** (오늘 2시간 단위, 내일~7일 4시간 단위),
**이중 캐시** (Geocoding 7일 + 날씨 30분), FutureBuilder 패턴으로 홈 화면 퀵메뉴에
동적 아이콘 표시, WMO 날씨 코드 → Flutter Icons 매핑 등 핵심 코드와 체크리스트를 포함합니다.
별도 위치 모델(WeatherLocation) 없이 앱 설정만으로 동작합니다.

### MCP 서버 가이드 → [mcp-guide.md](references/mcp-guide.md)

Model Context Protocol(MCP) 기반 Open-Meteo 날씨 서버의 설치와 설정을 다룹니다.
npx로 직접 실행하는 방법과 전역 설치, 소스 빌드 3가지 설치 방법을 설명합니다.
Claude Desktop의 `claude_desktop_config.json`에 MCP 서버를 등록하는 설정 예제를
포함하며, 16개의 MCP 도구(forecast, archive, air_quality, marine_weather 등 기본 6개,
DWD/GFS/ECMWF 등 모델별 7개, flood/seasonal/climate/ensemble 고급 4개) 목록과
사용 예시를 제공합니다. axios 기반 API 클라이언트 구조와 TypeScript 타입 정의도 포함합니다.

### 날씨 변수 목록 → [weather-variables.md](references/weather-variables.md)

Open-Meteo API에서 사용 가능한 모든 날씨 변수의 상세 목록을 다룹니다.
Current(현재 날씨) 15개 변수, Hourly(시간별) 50+개 변수(기본/바람/고도별 기온/토양/
일사량/기타), Daily(일별) 20+개 변수(기온/강수/바람/일출일몰), Air Quality(대기질)
미세먼지/가스/AQI 변수, Marine(해양) 파도/해류 변수를 포함합니다.
WMO 표준 날씨 코드(0~99) 전체 매핑표를 제공하며, 맑음(0)/흐림(1-3)/안개(45-48)/
이슬비(51-57)/비(61-67)/눈(71-77)/소나기(80-86)/뇌우(95-99) 분류를 포함합니다.

## 테스트 스크립트

```bash
./scripts/test-all.sh               # 전체 API 테스트
./scripts/test-forecast.sh          # 날씨 예보 테스트
./scripts/test-air-quality.sh       # 대기질 테스트
./scripts/test-geocoding.sh         # 지오코딩 테스트
```
