#!/bin/bash
# Open-Meteo 날씨 예보 API 테스트 스크립트
# 사용법: ./test-forecast.sh [latitude] [longitude]
#
# 기본값: 서울 좌표 (37.5665, 126.9780)
# 예제: ./test-forecast.sh 35.1796 129.0756  # 부산

set -e

# 기본 좌표 설정 (서울)
LATITUDE=${1:-37.5665}
LONGITUDE=${2:-126.9780}

# 색상 정의
GREEN='\033[0;32m'
BLUE='\033[0;34m'
YELLOW='\033[1;33m'
NC='\033[0m' # No Color

echo -e "${BLUE}========================================${NC}"
echo -e "${BLUE}  Open-Meteo 날씨 예보 API 테스트${NC}"
echo -e "${BLUE}========================================${NC}"
echo ""

# 1. 기본 날씨 예보 테스트
echo -e "${GREEN}[테스트 1] 기본 날씨 예보 (7일)${NC}"
echo -e "${YELLOW}위도: ${LATITUDE}, 경도: ${LONGITUDE}${NC}"
echo ""

API_URL="https://api.open-meteo.com/v1/forecast?latitude=${LATITUDE}&longitude=${LONGITUDE}&hourly=temperature_2m,relative_humidity_2m,precipitation,weather_code&daily=weather_code,temperature_2m_max,temperature_2m_min,sunrise,sunset&timezone=Asia/Seoul"

echo "요청 URL:"
echo "${API_URL}"
echo ""

echo "응답:"
curl -s "${API_URL}" | jq '.'
echo ""

# 2. 현재 날씨 테스트
echo -e "${GREEN}[테스트 2] 현재 날씨${NC}"
echo ""

CURRENT_URL="https://api.open-meteo.com/v1/forecast?latitude=${LATITUDE}&longitude=${LONGITUDE}&current=temperature_2m,relative_humidity_2m,apparent_temperature,precipitation,weather_code,wind_speed_10m&timezone=Asia/Seoul"

echo "요청 URL:"
echo "${CURRENT_URL}"
echo ""

echo "응답:"
curl -s "${CURRENT_URL}" | jq '.'
echo ""

# 3. 특정 모델 (DWD ICON) 테스트
echo -e "${GREEN}[테스트 3] DWD ICON 모델 예보${NC}"
echo ""

ICON_URL="https://api.open-meteo.com/v1/dwd-icon?latitude=${LATITUDE}&longitude=${LONGITUDE}&hourly=temperature_2m,precipitation&timezone=Asia/Seoul"

echo "요청 URL:"
echo "${ICON_URL}"
echo ""

echo "응답 (처음 24시간만):"
curl -s "${ICON_URL}" | jq '{
  latitude,
  longitude,
  timezone,
  hourly_units,
  hourly: {
    time: .hourly.time[0:24],
    temperature_2m: .hourly.temperature_2m[0:24],
    precipitation: .hourly.precipitation[0:24]
  }
}'
echo ""

echo -e "${BLUE}========================================${NC}"
echo -e "${GREEN}모든 테스트 완료!${NC}"
echo -e "${BLUE}========================================${NC}"
