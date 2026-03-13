#!/bin/bash
# Open-Meteo 지오코딩 API 테스트 스크립트
# 사용법: ./test-geocoding.sh [검색어]
#
# 기본값: "Seoul"
# 예제: ./test-geocoding.sh "Tokyo"

set -e

# 기본 검색어 설정
SEARCH_QUERY=${1:-Seoul}

# 색상 정의
GREEN='\033[0;32m'
BLUE='\033[0;34m'
YELLOW='\033[1;33m'
NC='\033[0m' # No Color

echo -e "${BLUE}========================================${NC}"
echo -e "${BLUE}  Open-Meteo 지오코딩 API 테스트${NC}"
echo -e "${BLUE}========================================${NC}"
echo ""

# 1. 기본 지오코딩 검색
echo -e "${GREEN}[테스트 1] 지명 검색: '${SEARCH_QUERY}'${NC}"
echo ""

# URL 인코딩 (공백을 %20으로 변환)
ENCODED_QUERY=$(echo "${SEARCH_QUERY}" | sed 's/ /%20/g')

GEO_URL="https://geocoding-api.open-meteo.com/v1/search?name=${ENCODED_QUERY}&count=5&language=ko"

echo "요청 URL:"
echo "${GEO_URL}"
echo ""

echo "응답:"
curl -s "${GEO_URL}" | jq '.'
echo ""

# 2. 영어로 검색
echo -e "${GREEN}[테스트 2] 영어 결과${NC}"
echo ""

GEO_EN_URL="https://geocoding-api.open-meteo.com/v1/search?name=${ENCODED_QUERY}&count=5&language=en"

echo "요청 URL:"
echo "${GEO_EN_URL}"
echo ""

echo "응답 (간략):"
curl -s "${GEO_EN_URL}" | jq '.results[] | {name, country, latitude, longitude, timezone, population}'
echo ""

# 3. 특정 국가 필터링 테스트
echo -e "${GREEN}[테스트 3] 한국 내 검색 (countryCode=KR)${NC}"
echo ""

GEO_KR_URL="https://geocoding-api.open-meteo.com/v1/search?name=${ENCODED_QUERY}&count=10&language=ko&countryCode=KR"

echo "요청 URL:"
echo "${GEO_KR_URL}"
echo ""

echo "응답:"
curl -s "${GEO_KR_URL}" | jq '.results // empty | .[] | {name, admin1, latitude, longitude}'
echo ""

# 4. 주요 도시 좌표 조회
echo -e "${GREEN}[테스트 4] 주요 도시 좌표 조회${NC}"
echo ""

CITIES=("Seoul" "Busan" "Tokyo" "New York" "Paris")

for city in "${CITIES[@]}"; do
    CITY_URL="https://geocoding-api.open-meteo.com/v1/search?name=${city}&count=1&language=en"
    RESULT=$(curl -s "${CITY_URL}" | jq -r '.results[0] | "\(.name), \(.country): \(.latitude), \(.longitude)"')
    echo "  ${RESULT}"
done
echo ""

echo -e "${BLUE}========================================${NC}"
echo -e "${GREEN}모든 테스트 완료!${NC}"
echo -e "${BLUE}========================================${NC}"
