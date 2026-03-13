#!/bin/bash
# Open-Meteo API 전체 테스트 스크립트
# 사용법: ./test-all.sh
#
# 모든 API 엔드포인트를 테스트합니다.

set -e

# 스크립트 디렉토리 경로
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

# 색상 정의
GREEN='\033[0;32m'
BLUE='\033[0;34m'
YELLOW='\033[1;33m'
RED='\033[0;31m'
NC='\033[0m' # No Color

# 기본 좌표 (서울)
LATITUDE=37.5665
LONGITUDE=126.9780

echo -e "${BLUE}╔══════════════════════════════════════════════════════════════╗${NC}"
echo -e "${BLUE}║          Open-Meteo API 전체 테스트 스크립트                   ║${NC}"
echo -e "${BLUE}╚══════════════════════════════════════════════════════════════╝${NC}"
echo ""
echo -e "${YELLOW}테스트 위치: 서울 (${LATITUDE}, ${LONGITUDE})${NC}"
echo ""

# 테스트 함수
test_api() {
    local name=$1
    local url=$2

    echo -e "${GREEN}▶ ${name}${NC}"

    # API 호출 및 상태 확인
    HTTP_CODE=$(curl -s -o /dev/null -w "%{http_code}" "${url}")

    if [ "${HTTP_CODE}" == "200" ]; then
        echo -e "  상태: ${GREEN}✓ 성공 (HTTP ${HTTP_CODE})${NC}"
        # 응답의 첫 200자만 표시
        RESPONSE=$(curl -s "${url}" | jq -c '.' | head -c 200)
        echo -e "  응답 미리보기: ${RESPONSE}..."
    else
        echo -e "  상태: ${RED}✗ 실패 (HTTP ${HTTP_CODE})${NC}"
    fi
    echo ""
}

echo -e "${BLUE}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
echo -e "${BLUE}[1] 날씨 예보 API 테스트${NC}"
echo -e "${BLUE}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
echo ""

test_api "Forecast API" \
    "https://api.open-meteo.com/v1/forecast?latitude=${LATITUDE}&longitude=${LONGITUDE}&hourly=temperature_2m&timezone=Asia/Seoul"

test_api "Current Weather" \
    "https://api.open-meteo.com/v1/forecast?latitude=${LATITUDE}&longitude=${LONGITUDE}&current=temperature_2m,weather_code&timezone=Asia/Seoul"

echo -e "${BLUE}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
echo -e "${BLUE}[2] 과거 데이터 API 테스트${NC}"
echo -e "${BLUE}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
echo ""

# 어제 날짜 계산
YESTERDAY=$(date -v-1d +%Y-%m-%d 2>/dev/null || date -d "yesterday" +%Y-%m-%d)
WEEK_AGO=$(date -v-7d +%Y-%m-%d 2>/dev/null || date -d "7 days ago" +%Y-%m-%d)

test_api "Archive API" \
    "https://archive-api.open-meteo.com/v1/archive?latitude=${LATITUDE}&longitude=${LONGITUDE}&start_date=${WEEK_AGO}&end_date=${YESTERDAY}&daily=temperature_2m_max&timezone=Asia/Seoul"

echo -e "${BLUE}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
echo -e "${BLUE}[3] 대기질 API 테스트${NC}"
echo -e "${BLUE}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
echo ""

test_api "Air Quality API" \
    "https://air-quality-api.open-meteo.com/v1/air-quality?latitude=${LATITUDE}&longitude=${LONGITUDE}&hourly=pm10,pm2_5,us_aqi&timezone=Asia/Seoul"

echo -e "${BLUE}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
echo -e "${BLUE}[4] 해양 날씨 API 테스트${NC}"
echo -e "${BLUE}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
echo ""

# 부산 앞바다 좌표
test_api "Marine API" \
    "https://marine-api.open-meteo.com/v1/marine?latitude=35.1796&longitude=129.0756&hourly=wave_height,wave_direction&timezone=Asia/Seoul"

echo -e "${BLUE}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
echo -e "${BLUE}[5] 지오코딩 API 테스트${NC}"
echo -e "${BLUE}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
echo ""

test_api "Geocoding API" \
    "https://geocoding-api.open-meteo.com/v1/search?name=Seoul&count=1&language=ko"

echo -e "${BLUE}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
echo -e "${BLUE}[6] 고도 API 테스트${NC}"
echo -e "${BLUE}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
echo ""

test_api "Elevation API" \
    "https://api.open-meteo.com/v1/elevation?latitude=${LATITUDE}&longitude=${LONGITUDE}"

echo -e "${BLUE}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
echo -e "${BLUE}[7] 특정 모델 API 테스트${NC}"
echo -e "${BLUE}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
echo ""

test_api "DWD ICON Model" \
    "https://api.open-meteo.com/v1/dwd-icon?latitude=${LATITUDE}&longitude=${LONGITUDE}&hourly=temperature_2m&timezone=Asia/Seoul"

test_api "GFS Model" \
    "https://api.open-meteo.com/v1/gfs?latitude=${LATITUDE}&longitude=${LONGITUDE}&hourly=temperature_2m&timezone=Asia/Seoul"

test_api "ECMWF Model" \
    "https://api.open-meteo.com/v1/ecmwf?latitude=${LATITUDE}&longitude=${LONGITUDE}&hourly=temperature_2m&timezone=Asia/Seoul"

echo ""
echo -e "${BLUE}╔══════════════════════════════════════════════════════════════╗${NC}"
echo -e "${BLUE}║                    테스트 완료                                ║${NC}"
echo -e "${BLUE}╚══════════════════════════════════════════════════════════════╝${NC}"
echo ""
echo -e "${GREEN}모든 Open-Meteo API 테스트가 완료되었습니다.${NC}"
echo ""
echo -e "${YELLOW}상세 테스트를 원하시면 개별 스크립트를 실행하세요:${NC}"
echo "  ./test-forecast.sh     - 날씨 예보 상세 테스트"
echo "  ./test-air-quality.sh  - 대기질 상세 테스트"
echo "  ./test-geocoding.sh    - 지오코딩 상세 테스트"
echo ""
