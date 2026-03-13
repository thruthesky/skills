# Open-Meteo MCP 서버 가이드

## 목차

1. [개요](#개요)
2. [설치 방법](#설치-방법)
3. [Claude Desktop 설정](#claude-desktop-설정)
4. [제공 도구 목록](#제공-도구-목록)
5. [사용 예시](#사용-예시)
6. [API 클라이언트 구조](#api-클라이언트-구조)
7. [타입 정의](#타입-정의)

---

## 개요

Open-Meteo MCP 서버는 Model Context Protocol(MCP) 기반의 날씨 데이터 서버로, 대규모 언어 모델(LLM)에게 Open-Meteo 날씨 API에 대한 포괄적인 액세스를 제공합니다.

### 핵심 기능

- **날씨 예보**: 최대 16일 시간별/일별 예보
- **역사 데이터**: 1940년부터 현재까지 (ERA5 재분석)
- **대기질**: PM2.5, PM10, 오존 등 대기질 예보
- **해양 날씨**: 파도 높이, 해류, 수온
- **지오코딩**: 지명으로 좌표 검색
- **고급 기능**: 홍수 예보, 계절 예보, 기후 변화 전망

---

## 설치 방법

### 방법 1: npx로 직접 실행 (권장)

설치 없이 바로 실행할 수 있습니다:

```bash
npx open-meteo-mcp-server
```

### 방법 2: 전역 설치

```bash
npm install -g open-meteo-mcp-server
```

### 방법 3: 소스에서 설치

```bash
git clone https://github.com/cmer81/open-meteo-mcp
cd open-meteo-mcp
npm install
npm run build
```

---

## Claude Desktop 설정

`claude_desktop_config.json` 파일에 다음 설정을 추가합니다:

### 간단한 설정 (npx 사용)

```json
{
  "mcpServers": {
    "open-meteo": {
      "command": "npx",
      "args": ["open-meteo-mcp-server"]
    }
  }
}
```

### 전역 설치 후 설정

```json
{
  "mcpServers": {
    "open-meteo": {
      "command": "open-meteo-mcp-server"
    }
  }
}
```

### 환경변수 설정 (선택)

API URL을 커스터마이즈할 수 있습니다:

```json
{
  "mcpServers": {
    "open-meteo": {
      "command": "npx",
      "args": ["open-meteo-mcp-server"],
      "env": {
        "OPEN_METEO_API_URL": "https://customer-api.open-meteo.com",
        "OPEN_METEO_AIR_QUALITY_API_URL": "https://customer-air-quality-api.open-meteo.com"
      }
    }
  }
}
```

---

## 제공 도구 목록

MCP 서버에서 제공하는 16개의 날씨 도구입니다.

### 기본 도구

| 도구 | 설명 |
|------|------|
| `weather_forecast` | 좌표 기반 날씨 예보 (최대 16일) |
| `weather_archive` | ERA5 역사적 날씨 데이터 (1940년~현재) |
| `air_quality` | 대기질 예보 (PM2.5, PM10, 오존 등) |
| `marine_weather` | 해양 날씨 (파도 높이, 주기, 해류) |
| `elevation` | 좌표 기반 고도 정보 |
| `geocoding` | 지명으로 좌표 검색 |

### 특정 모델 도구

| 도구 | 설명 |
|------|------|
| `dwd_icon_forecast` | DWD ICON 모델 예보 (독일) |
| `gfs_forecast` | NOAA GFS 모델 예보 (미국) |
| `meteofrance_forecast` | Météo-France 모델 예보 |
| `ecmwf_forecast` | ECMWF 모델 예보 (유럽) |
| `jma_forecast` | JMA 모델 예보 (일본) |
| `metno_forecast` | MET Norway 모델 예보 (노르웨이) |
| `gem_forecast` | GEM 모델 예보 (캐나다) |

### 고급 도구

| 도구 | 설명 |
|------|------|
| `flood_forecast` | GloFAS 하천 유량 및 홍수 예보 |
| `seasonal_forecast` | 최대 9개월 장기 계절 예보 |
| `climate_projection` | CMIP6 기후 변화 전망 |
| `ensemble_forecast` | 앙상블 예보 (불확실성 정보) |

---

## 사용 예시

MCP 도구를 통해 Claude에게 자연어로 질문할 수 있습니다.

### 위치 검색

```
"파리의 좌표를 찾아주세요"
→ geocoding 도구 호출
```

### 날씨 예보

```
"서울의 향후 3일 날씨 예보를 알려주세요"
→ weather_forecast 도구 호출 (latitude=37.5665, longitude=126.9780)
```

### 과거 데이터

```
"2023년 1월 런던의 평균 기온은 얼마였나요?"
→ weather_archive 도구 호출 (start_date=2023-01-01, end_date=2023-01-31)
```

### 대기질

```
"베이징의 현재 미세먼지 수치를 알려주세요"
→ air_quality 도구 호출
```

### 해양 날씨

```
"제주도 앞바다의 파도 높이와 수온 정보를 알려주세요"
→ marine_weather 도구 호출
```

---

## API 클라이언트 구조

MCP 서버는 axios 기반의 HTTP 클라이언트를 사용합니다.

### 클라이언트 인스턴스

```typescript
private client: AxiosInstance;           // 기본 API
private archiveClient: AxiosInstance;    // 역사 데이터
private airQualityClient: AxiosInstance; // 대기질
private marineClient: AxiosInstance;     // 해양
private geocodingClient: AxiosInstance;  // 지오코딩
private floodClient: AxiosInstance;      // 홍수 예보
private climateClient: AxiosInstance;    // 기후
private ensembleClient: AxiosInstance;   // 앙상블
private seasonalClient: AxiosInstance;   // 계절 예보
```

### 기본 URL 매핑

| 클라이언트 | 기본 URL |
|------------|----------|
| client | api.open-meteo.com |
| archiveClient | archive-api.open-meteo.com |
| airQualityClient | air-quality-api.open-meteo.com |
| marineClient | marine-api.open-meteo.com |
| geocodingClient | geocoding-api.open-meteo.com |
| floodClient | flood-api.open-meteo.com |
| climateClient | climate-api.open-meteo.com |
| ensembleClient | ensemble-api.open-meteo.com |
| seasonalClient | seasonal-api.open-meteo.com |

### 파라미터 처리

배열 값은 쉼표로 구분된 문자열로 변환됩니다:

```typescript
// 입력
{ hourly: ['temperature_2m', 'precipitation'] }

// 변환 결과
{ hourly: 'temperature_2m,precipitation' }
```

---

## 타입 정의

### 좌표 스키마

```typescript
const CoordinateSchema = z.object({
  latitude: z.number().min(-90).max(90),
  longitude: z.number().min(-180).max(180)
});
```

### 예보 파라미터 스키마

```typescript
const ForecastParamsSchema = CoordinateSchema.extend({
  hourly: z.array(z.string()).optional(),
  daily: z.array(z.string()).optional(),
  current: z.array(z.string()).optional(),
  timezone: z.string().default('auto'),
  forecast_days: z.number().min(1).max(16).default(7),
  past_days: z.number().min(0).max(92).default(0),
  temperature_unit: z.enum(['celsius', 'fahrenheit']).default('celsius'),
  wind_speed_unit: z.enum(['kmh', 'ms', 'mph', 'kn']).default('kmh'),
  precipitation_unit: z.enum(['mm', 'inch']).default('mm'),
  timeformat: z.enum(['iso8601', 'unixtime']).default('iso8601')
});
```

### 지오코딩 파라미터 스키마

```typescript
const GeocodingParamsSchema = z.object({
  name: z.string().min(2),
  count: z.number().min(1).max(100).default(10),
  language: z.string().default('en'),
  countryCode: z.string().optional()  // MCP 서버 내부 명칭. 실제 Open-Meteo API에서는 'country' 파라미터로 전송됨
});
```

### 응답 타입

```typescript
interface WeatherResponse {
  latitude: number;
  longitude: number;
  generationtime_ms: number;
  utc_offset_seconds: number;
  timezone: string;
  timezone_abbreviation: string;
  elevation: number;
  hourly_units?: Record<string, string>;
  hourly?: Record<string, (number | string)[]>;
  daily_units?: Record<string, string>;
  daily?: Record<string, (number | string)[]>;
  current_units?: Record<string, string>;
  current?: Record<string, number | string>;
}

interface GeocodingResponse {
  results?: {
    id: number;
    name: string;
    latitude: number;
    longitude: number;
    elevation: number;
    feature_code: string;
    country_code: string;
    country: string;
    timezone: string;
    population?: number;
    admin1?: string;
  }[];
}

interface ElevationResponse {
  elevation: number[];
}
```

---

## 공식 문서 레퍼런스

- [Open-Meteo MCP GitHub](https://github.com/cmer81/open-meteo-mcp)
- [Open-Meteo 공식 문서](https://open-meteo.com/en/docs)
- [MCP 프로토콜 문서](https://modelcontextprotocol.io/)
