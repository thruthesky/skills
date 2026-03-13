#!/bin/bash
# Frankfurter API 테스트 스크립트
# 사용법: ./test_frankfurter.sh

set -e

BASE_URL="https://api.frankfurter.dev/v1"

echo "============================================"
echo "Frankfurter API Test"
echo "============================================"
echo ""

# 1. 최신 환율 (EUR 기준)
echo "1. Latest Rates (EUR base)"
echo "-------------------------------------------"
curl -s "$BASE_URL/latest" | python3 -m json.tool 2>/dev/null || curl -s "$BASE_URL/latest"
echo ""
echo ""

# 2. USD 기준 KRW, PHP 환율
echo "2. USD -> KRW, PHP"
echo "-------------------------------------------"
curl -s "$BASE_URL/latest?base=USD&symbols=KRW,PHP" | python3 -m json.tool 2>/dev/null || curl -s "$BASE_URL/latest?base=USD&symbols=KRW,PHP"
echo ""
echo ""

# 3. 100 USD를 KRW로 변환
echo "3. Convert 100 USD to KRW"
echo "-------------------------------------------"
curl -s "$BASE_URL/latest?base=USD&symbols=KRW&amount=100" | python3 -m json.tool 2>/dev/null || curl -s "$BASE_URL/latest?base=USD&symbols=KRW&amount=100"
echo ""
echo ""

# 4. 특정 날짜 환율
echo "4. Historical Rate (2024-01-15)"
echo "-------------------------------------------"
curl -s "$BASE_URL/2024-01-15?base=USD&symbols=KRW" | python3 -m json.tool 2>/dev/null || curl -s "$BASE_URL/2024-01-15?base=USD&symbols=KRW"
echo ""
echo ""

# 5. 지원 통화 목록
echo "5. Supported Currencies"
echo "-------------------------------------------"
curl -s "$BASE_URL/currencies" | python3 -m json.tool 2>/dev/null || curl -s "$BASE_URL/currencies"
echo ""
echo ""

echo "============================================"
echo "All tests completed successfully!"
echo "============================================"
