# Open-Meteo 날씨 변수 목록

## 목차

1. [현재 날씨 변수 (Current)](#현재-날씨-변수-current)
2. [시간별 변수 (Hourly)](#시간별-변수-hourly)
3. [일별 변수 (Daily)](#일별-변수-daily)
4. [대기질 변수 (Air Quality)](#대기질-변수-air-quality)
5. [해양 변수 (Marine)](#해양-변수-marine)
6. [날씨 코드 (Weather Code)](#날씨-코드-weather-code)

---

## 현재 날씨 변수 (Current)

`current` 파라미터에서 사용 가능한 변수들입니다.

| 변수 | 설명 | 단위 |
|------|------|------|
| `temperature_2m` | 지상 2m 기온 | °C |
| `relative_humidity_2m` | 상대 습도 | % |
| `apparent_temperature` | 체감 온도 | °C |
| `is_day` | 낮/밤 여부 | 0/1 |
| `precipitation` | 강수량 | mm |
| `rain` | 강우량 | mm |
| `showers` | 소나기량 | mm |
| `snowfall` | 강설량 | cm |
| `weather_code` | 날씨 코드 | WMO |
| `cloud_cover` | 구름량 | % |
| `pressure_msl` | 해수면 기압 | hPa |
| `surface_pressure` | 지표면 기압 | hPa |
| `wind_speed_10m` | 지상 10m 풍속 | km/h |
| `wind_direction_10m` | 풍향 | ° |
| `wind_gusts_10m` | 돌풍 속도 | km/h |

---

## 시간별 변수 (Hourly)

`hourly` 파라미터에서 사용 가능한 변수들입니다.

### 기본 변수

| 변수 | 설명 | 단위 |
|------|------|------|
| `temperature_2m` | 지상 2m 기온 | °C |
| `relative_humidity_2m` | 상대 습도 | % |
| `dew_point_2m` | 이슬점 | °C |
| `apparent_temperature` | 체감 온도 | °C |
| `precipitation_probability` | 강수 확률 | % |
| `precipitation` | 강수량 | mm |
| `rain` | 강우량 | mm |
| `showers` | 소나기량 | mm |
| `snowfall` | 강설량 | cm |
| `snow_depth` | 적설량 | m |
| `weather_code` | 날씨 코드 | WMO |
| `pressure_msl` | 해수면 기압 | hPa |
| `surface_pressure` | 지표면 기압 | hPa |
| `cloud_cover` | 전체 구름량 | % |
| `cloud_cover_low` | 하층 구름량 | % |
| `cloud_cover_mid` | 중층 구름량 | % |
| `cloud_cover_high` | 상층 구름량 | % |
| `visibility` | 가시거리 | m |
| `evapotranspiration` | 증발산량 | mm |
| `et0_fao_evapotranspiration` | 기준 증발산량 | mm |
| `vapour_pressure_deficit` | 증기압 부족량 | kPa |

### 바람 변수

| 변수 | 설명 | 단위 |
|------|------|------|
| `wind_speed_10m` | 지상 10m 풍속 | km/h |
| `wind_speed_80m` | 지상 80m 풍속 | km/h |
| `wind_speed_120m` | 지상 120m 풍속 | km/h |
| `wind_speed_180m` | 지상 180m 풍속 | km/h |
| `wind_direction_10m` | 지상 10m 풍향 | ° |
| `wind_direction_80m` | 지상 80m 풍향 | ° |
| `wind_direction_120m` | 지상 120m 풍향 | ° |
| `wind_direction_180m` | 지상 180m 풍향 | ° |
| `wind_gusts_10m` | 돌풍 속도 | km/h |

### 고도별 기온 변수

| 변수 | 설명 | 단위 |
|------|------|------|
| `temperature_80m` | 80m 고도 기온 | °C |
| `temperature_120m` | 120m 고도 기온 | °C |
| `temperature_180m` | 180m 고도 기온 | °C |

### 토양 변수

| 변수 | 설명 | 단위 |
|------|------|------|
| `soil_temperature_0cm` | 지표면 토양 온도 | °C |
| `soil_temperature_6cm` | 6cm 토양 온도 | °C |
| `soil_temperature_18cm` | 18cm 토양 온도 | °C |
| `soil_temperature_54cm` | 54cm 토양 온도 | °C |
| `soil_moisture_0_to_1cm` | 0-1cm 토양 수분 | m³/m³ |
| `soil_moisture_1_to_3cm` | 1-3cm 토양 수분 | m³/m³ |
| `soil_moisture_3_to_9cm` | 3-9cm 토양 수분 | m³/m³ |
| `soil_moisture_9_to_27cm` | 9-27cm 토양 수분 | m³/m³ |
| `soil_moisture_27_to_81cm` | 27-81cm 토양 수분 | m³/m³ |

### 일사량 변수

| 변수 | 설명 | 단위 |
|------|------|------|
| `shortwave_radiation` | 단파 복사 | W/m² |
| `direct_radiation` | 직접 복사 | W/m² |
| `diffuse_radiation` | 산란 복사 | W/m² |
| `direct_normal_irradiance` | 직달 일사량 | W/m² |
| `global_tilted_irradiance` | 경사면 일사량 | W/m² |
| `terrestrial_radiation` | 지구 복사 | W/m² |
| `sunshine_duration` | 일조 시간 | s |

### 기타 변수

| 변수 | 설명 | 단위 |
|------|------|------|
| `cape` | 대기불안정지수 | J/kg |
| `lifted_index` | 상승지수 | - |
| `convective_inhibition` | 대류억제 | J/kg |
| `freezing_level_height` | 빙점고도 | m |
| `boundary_layer_height` | 경계층 고도 | m |
| `is_day` | 낮/밤 여부 | 0/1 |

---

## 일별 변수 (Daily)

`daily` 파라미터에서 사용 가능한 변수들입니다.

### 기온 변수

| 변수 | 설명 | 단위 |
|------|------|------|
| `temperature_2m_max` | 일 최고 기온 | °C |
| `temperature_2m_min` | 일 최저 기온 | °C |
| `apparent_temperature_max` | 일 최고 체감온도 | °C |
| `apparent_temperature_min` | 일 최저 체감온도 | °C |

### 강수 변수

| 변수 | 설명 | 단위 |
|------|------|------|
| `precipitation_sum` | 일 총 강수량 | mm |
| `rain_sum` | 일 총 강우량 | mm |
| `showers_sum` | 일 총 소나기량 | mm |
| `snowfall_sum` | 일 총 강설량 | cm |
| `precipitation_hours` | 강수 시간 | h |
| `precipitation_probability_max` | 최대 강수 확률 | % |
| `precipitation_probability_min` | 최소 강수 확률 | % |
| `precipitation_probability_mean` | 평균 강수 확률 | % |

### 바람 변수

| 변수 | 설명 | 단위 |
|------|------|------|
| `wind_speed_10m_max` | 일 최대 풍속 | km/h |
| `wind_gusts_10m_max` | 일 최대 돌풍 | km/h |
| `wind_direction_10m_dominant` | 주풍향 | ° |

### 일출/일몰 변수

| 변수 | 설명 | 단위 |
|------|------|------|
| `sunrise` | 일출 시간 | iso8601 |
| `sunset` | 일몰 시간 | iso8601 |
| `daylight_duration` | 일조 시간 | s |
| `sunshine_duration` | 실제 일조 시간 | s |

### 기타 변수

| 변수 | 설명 | 단위 |
|------|------|------|
| `weather_code` | 대표 날씨 코드 | WMO |
| `uv_index_max` | 최대 자외선 지수 | - |
| `uv_index_clear_sky_max` | 맑은 하늘 UV 지수 | - |
| `et0_fao_evapotranspiration` | 기준 증발산량 | mm |

---

## 대기질 변수 (Air Quality)

Air Quality API의 `hourly` 파라미터에서 사용 가능한 변수들입니다.

### 미세먼지

| 변수 | 설명 | 단위 |
|------|------|------|
| `pm10` | 미세먼지 PM10 | μg/m³ |
| `pm2_5` | 초미세먼지 PM2.5 | μg/m³ |

### 가스

| 변수 | 설명 | 단위 |
|------|------|------|
| `carbon_monoxide` | 일산화탄소 (CO) | μg/m³ |
| `nitrogen_dioxide` | 이산화질소 (NO₂) | μg/m³ |
| `sulphur_dioxide` | 이산화황 (SO₂) | μg/m³ |
| `ozone` | 오존 (O₃) | μg/m³ |
| `ammonia` | 암모니아 (NH₃) | μg/m³ |
| `methane` | 메탄 (CH₄) | μg/m³ |

### 기타

| 변수 | 설명 | 단위 |
|------|------|------|
| `aerosol_optical_depth` | 에어로졸 광학 깊이 | - |
| `dust` | 먼지 | μg/m³ |
| `uv_index` | 자외선 지수 | - |
| `uv_index_clear_sky` | 맑은 하늘 UV 지수 | - |

### 대기질 지수

| 변수 | 설명 | 범위 |
|------|------|------|
| `european_aqi` | 유럽 대기질 지수 | 0-500 |
| `european_aqi_pm2_5` | PM2.5 유럽 AQI | 0-500 |
| `european_aqi_pm10` | PM10 유럽 AQI | 0-500 |
| `european_aqi_no2` | NO₂ 유럽 AQI | 0-500 |
| `european_aqi_o3` | O₃ 유럽 AQI | 0-500 |
| `european_aqi_so2` | SO₂ 유럽 AQI | 0-500 |
| `us_aqi` | 미국 대기질 지수 | 0-500 |
| `us_aqi_pm2_5` | PM2.5 미국 AQI | 0-500 |
| `us_aqi_pm10` | PM10 미국 AQI | 0-500 |
| `us_aqi_no2` | NO₂ 미국 AQI | 0-500 |
| `us_aqi_o3` | O₃ 미국 AQI | 0-500 |
| `us_aqi_so2` | SO₂ 미국 AQI | 0-500 |
| `us_aqi_co` | CO 미국 AQI | 0-500 |

---

## 해양 변수 (Marine)

Marine API의 `hourly` 파라미터에서 사용 가능한 변수들입니다.

### 파도 변수

| 변수 | 설명 | 단위 |
|------|------|------|
| `wave_height` | 파고 | m |
| `wave_direction` | 파향 | ° |
| `wave_period` | 파주기 | s |
| `wind_wave_height` | 풍랑 높이 | m |
| `wind_wave_direction` | 풍랑 방향 | ° |
| `wind_wave_period` | 풍랑 주기 | s |
| `wind_wave_peak_period` | 풍랑 첨두 주기 | s |
| `swell_wave_height` | 너울 높이 | m |
| `swell_wave_direction` | 너울 방향 | ° |
| `swell_wave_period` | 너울 주기 | s |
| `swell_wave_peak_period` | 너울 첨두 주기 | s |

### 해류 변수

| 변수 | 설명 | 단위 |
|------|------|------|
| `ocean_current_velocity` | 해류 속도 | m/s |
| `ocean_current_direction` | 해류 방향 | ° |

---

## 날씨 코드 (Weather Code)

WMO 표준 날씨 코드입니다.

### 맑음/흐림

| 코드 | 설명 | 설명 (영문) |
|------|------|-------------|
| 0 | 맑음 | Clear sky |
| 1 | 대체로 맑음 | Mainly clear |
| 2 | 부분적 흐림 | Partly cloudy |
| 3 | 흐림 | Overcast |

### 안개

| 코드 | 설명 | 설명 (영문) |
|------|------|-------------|
| 45 | 안개 | Fog |
| 48 | 서리 안개 | Depositing rime fog |

### 이슬비

| 코드 | 설명 | 설명 (영문) |
|------|------|-------------|
| 51 | 약한 이슬비 | Light drizzle |
| 53 | 보통 이슬비 | Moderate drizzle |
| 55 | 강한 이슬비 | Dense drizzle |
| 56 | 약한 어는 이슬비 | Light freezing drizzle |
| 57 | 강한 어는 이슬비 | Dense freezing drizzle |

### 비

| 코드 | 설명 | 설명 (영문) |
|------|------|-------------|
| 61 | 약한 비 | Slight rain |
| 63 | 보통 비 | Moderate rain |
| 65 | 강한 비 | Heavy rain |
| 66 | 약한 어는 비 | Light freezing rain |
| 67 | 강한 어는 비 | Heavy freezing rain |

### 눈

| 코드 | 설명 | 설명 (영문) |
|------|------|-------------|
| 71 | 약한 눈 | Slight snow fall |
| 73 | 보통 눈 | Moderate snow fall |
| 75 | 강한 눈 | Heavy snow fall |
| 77 | 눈 알갱이 | Snow grains |

### 소나기

| 코드 | 설명 | 설명 (영문) |
|------|------|-------------|
| 80 | 약한 소나기 | Slight rain showers |
| 81 | 보통 소나기 | Moderate rain showers |
| 82 | 강한 소나기 | Violent rain showers |
| 85 | 약한 눈 소나기 | Slight snow showers |
| 86 | 강한 눈 소나기 | Heavy snow showers |

### 뇌우

| 코드 | 설명 | 설명 (영문) |
|------|------|-------------|
| 95 | 약간의 뇌우 | Thunderstorm: Slight |
| 96 | 우박 동반 뇌우 | Thunderstorm with slight hail |
| 99 | 강한 우박 뇌우 | Thunderstorm with heavy hail |

---

## 공식 문서 레퍼런스

- [Open-Meteo API 문서](https://open-meteo.com/en/docs)
- [Weather Variables](https://open-meteo.com/en/docs#weathervariables)
