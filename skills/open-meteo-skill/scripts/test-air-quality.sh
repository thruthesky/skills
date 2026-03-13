#!/bin/bash
# Open-Meteo 대기질 API 테스트 스크립트
# 사용법: ./test-air-quality.sh [latitude] [longitude]
#
# 기본값: 서울 좌표 (37.5665, 126.9780)
# 예제: ./test-air-quality.sh 39.9042 116.4074  # 베이징

set -e

# 기본 좌표 설정 (서울)
LATITUDE=${1:-37.5665}
LONGITUDE=${2:-126.9780}

# 색상 정의
GREEN='\033[0;32m'
BLUE='\033[0;34m'
YELLOW='\033[1;33m'
RED='\033[0;31m'
NC='\033[0m' # No Color

echo -e "${BLUE}========================================${NC}"
echo -e "${BLUE}  Open-Meteo 대기질 API 테스트${NC}"
echo -e "${BLUE}========================================${NC}"
echo ""

# 1. 미세먼지 (PM10, PM2.5) 테스트
echo -e "${GREEN}[테스트 1] 미세먼지 예보${NC}"
echo -e "${YELLOW}위도: ${LATITUDE}, 경도: ${LONGITUDE}${NC}"
echo ""

PM_URL="https://air-quality-api.open-meteo.com/v1/air-quality?latitude=${LATITUDE}&longitude=${LONGITUDE}&hourly=pm10,pm2_5&timezone=Asia/Seoul"

echo "요청 URL:"
echo "${PM_URL}"
echo ""

echo "응답 (처음 24시간):"
curl -s "${PM_URL}" | jq '{
  latitude,
  longitude,
  timezone,
  hourly_units,
  hourly: {
    time: .hourly.time[0:24],
    pm10: .hourly.pm10[0:24],
    pm2_5: .hourly.pm2_5[0:24]
  }
}'
echo ""

# 2. 대기질 지수 (AQI) 테스트
echo -e "${GREEN}[테스트 2] 대기질 지수 (AQI)${NC}"
echo ""

AQI_URL="https://air-quality-api.open-meteo.com/v1/air-quality?latitude=${LATITUDE}&longitude=${LONGITUDE}&hourly=us_aqi,european_aqi&timezone=Asia/Seoul"

echo "요청 URL:"
echo "${AQI_URL}"
echo ""

echo "응답 (처음 24시간):"
curl -s "${AQI_URL}" | jq '{
  latitude,
  longitude,
  timezone,
  hourly_units,
  hourly: {
    time: .hourly.time[0:24],
    us_aqi: .hourly.us_aqi[0:24],
    european_aqi: .hourly.european_aqi[0:24]
  }
}'
echo ""

# 3. 전체 대기질 데이터 테스트
echo -e "${GREEN}[테스트 3] 전체 대기질 데이터${NC}"
echo ""

FULL_URL="https://air-quality-api.open-meteo.com/v1/air-quality?latitude=${LATITUDE}&longitude=${LONGITUDE}&hourly=pm10,pm2_5,carbon_monoxide,nitrogen_dioxide,sulphur_dioxide,ozone,dust,uv_index,us_aqi&timezone=Asia/Seoul"

echo "요청 URL:"
echo "${FULL_URL}"
echo ""

echo "현재 시간 대기질 (첫 번째 데이터):"
curl -s "${FULL_URL}" | jq '{
  latitude,
  longitude,
  timezone,
  current_time: .hourly.time[0],
  pm10: .hourly.pm10[0],
  pm2_5: .hourly.pm2_5[0],
  carbon_monoxide: .hourly.carbon_monoxide[0],
  nitrogen_dioxide: .hourly.nitrogen_dioxide[0],
  sulphur_dioxide: .hourly.sulphur_dioxide[0],
  ozone: .hourly.ozone[0],
  dust: .hourly.dust[0],
  uv_index: .hourly.uv_index[0],
  us_aqi: .hourly.us_aqi[0]
}'
echo ""

# AQI 등급 설명
echo -e "${GREEN}[참고] US AQI 등급 기준${NC}"
echo -e "${GREEN}  0-50    : 좋음 (Good)${NC}"
echo -e "${YELLOW}  51-100  : 보통 (Moderate)${NC}"
echo -e "${YELLOW}  101-150 : 민감군 주의 (Unhealthy for Sensitive Groups)${NC}"
echo -e "${RED}  151-200 : 나쁨 (Unhealthy)${NC}"
echo -e "${RED}  201-300 : 매우 나쁨 (Very Unhealthy)${NC}"
echo -e "${RED}  301+    : 위험 (Hazardous)${NC}"
echo ""

echo -e "${BLUE}========================================${NC}"
echo -e "${GREEN}모든 테스트 완료!${NC}"
echo -e "${BLUE}========================================${NC}"
