#!/bin/bash

# ============================================================
# 외교부 공지사항 API 테스트 스크립트
# MOFA Notice API Test Script
# ============================================================
#
# 사용법 (Usage):
#   ./test-mofa-api.sh <API_KEY>
#
# 예시 (Example):
#   ./test-mofa-api.sh "FAK7%2BJL3rqrFr7Wtn%2FxkKhW8hq1zDsite%2FxQdIwug4pDLD5bsqFJDKzroRXTkY8fm5LXMMMzIaTuvl%2F4iDtQ%2Bw%3D%3D"
#
# 참고: API Key는 이미 URL 인코딩된 값을 사용해야 합니다.
# Note: API Key must be URL encoded.
#
# 실제 API 응답 구조:
# {
#   "response": {
#     "header": { "resultCode": "0", "resultMsg": "정상" },
#     "body": {
#       "items": { "item": [...] },
#       "numOfRows": 5,
#       "pageNo": 1,
#       "totalCount": 1085
#     }
#   }
# }
# ============================================================

# 색상 정의 (Color definitions)
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# API 엔드포인트 (API endpoint)
API_BASE_URL="http://apis.data.go.kr/1262000/NoticeService2/getNoticeList2"

# 파라미터 확인 (Check parameters)
if [ -z "$1" ]; then
    echo -e "${RED}오류: API Key가 필요합니다.${NC}"
    echo ""
    echo "사용법: ./test-mofa-api.sh <API_KEY>"
    echo ""
    echo "예시:"
    echo "  ./test-mofa-api.sh \"YOUR_ENCODED_API_KEY\""
    echo ""
    echo "참고: 공공데이터포털(data.go.kr)에서 발급받은 인코딩된 API Key를 사용하세요."
    exit 1
fi

SERVICE_KEY="$1"

echo -e "${BLUE}============================================================${NC}"
echo -e "${BLUE}  외교부 공지사항 API 테스트 (MOFA Notice API Test)${NC}"
echo -e "${BLUE}============================================================${NC}"
echo ""

# API URL 구성 (Build API URL)
FULL_URL="${API_BASE_URL}?serviceKey=${SERVICE_KEY}&returnType=JSON&numOfRows=5&pageNo=1"

echo -e "${YELLOW}[1] API 요청 정보${NC}"
echo "-----------------------------------------------------------"
echo "엔드포인트: ${API_BASE_URL}"
echo "요청 파라미터:"
echo "  - serviceKey: ${SERVICE_KEY:0:20}... (일부만 표시)"
echo "  - returnType: JSON"
echo "  - numOfRows: 5"
echo "  - pageNo: 1"
echo ""

echo -e "${YELLOW}[2] API 호출 중...${NC}"
echo "-----------------------------------------------------------"

# API 호출 및 응답 저장 (Call API and save response)
RESPONSE=$(curl -s -w "\n%{http_code}" "${FULL_URL}")
HTTP_CODE=$(echo "$RESPONSE" | tail -n1)
BODY=$(echo "$RESPONSE" | sed '$d')

echo "HTTP 상태 코드: ${HTTP_CODE}"
echo ""

# HTTP 상태 코드 확인 (Check HTTP status code)
if [ "$HTTP_CODE" -eq 200 ]; then
    echo -e "${GREEN}[3] API 호출 성공!${NC}"
    echo "-----------------------------------------------------------"

    # JSON 응답 파싱 - 실제 응답 구조에 맞게 수정
    # response.header.resultCode, response.body.items.item[]
    RESULT_CODE=$(echo "$BODY" | python3 -c "
import sys, json
try:
    d = json.load(sys.stdin)
    print(d.get('response', {}).get('header', {}).get('resultCode', 'N/A'))
except:
    print('N/A')
" 2>/dev/null)

    RESULT_MSG=$(echo "$BODY" | python3 -c "
import sys, json
try:
    d = json.load(sys.stdin)
    print(d.get('response', {}).get('header', {}).get('resultMsg', 'N/A'))
except:
    print('N/A')
" 2>/dev/null)

    TOTAL_COUNT=$(echo "$BODY" | python3 -c "
import sys, json
try:
    d = json.load(sys.stdin)
    print(d.get('response', {}).get('body', {}).get('totalCount', 'N/A'))
except:
    print('N/A')
" 2>/dev/null)

    NUM_OF_ROWS=$(echo "$BODY" | python3 -c "
import sys, json
try:
    d = json.load(sys.stdin)
    print(d.get('response', {}).get('body', {}).get('numOfRows', 'N/A'))
except:
    print('N/A')
" 2>/dev/null)

    echo "결과 코드 (resultCode): ${RESULT_CODE}"
    echo "결과 메시지 (resultMsg): ${RESULT_MSG}"
    echo "전체 개수 (totalCount): ${TOTAL_COUNT}"
    echo "요청 개수 (numOfRows): ${NUM_OF_ROWS}"
    echo ""

    # 결과 코드 확인 (Check result code)
    if [ "$RESULT_CODE" = "0" ]; then
        echo -e "${GREEN}[4] API 응답 정상!${NC}"
        echo "-----------------------------------------------------------"
        echo ""
        echo -e "${YELLOW}[5] 공지사항 목록:${NC}"
        echo "-----------------------------------------------------------"

        # 공지사항 목록 출력 - 실제 응답 구조에 맞게 수정
        echo "$BODY" | python3 -c "
import sys, json

try:
    data = json.load(sys.stdin)
    items = data.get('response', {}).get('body', {}).get('items', {})
    notices = items.get('item', [])

    if not notices:
        print('공지사항이 없습니다.')
    else:
        for i, notice in enumerate(notices, 1):
            title = notice.get('title', 'N/A')
            # HTML 엔티티 디코딩
            title = title.replace('&#39;', \"'\")
            title = title.replace('&quot;', '\"')
            title = title.replace('&amp;', '&')
            title = title.replace('&lt;', '<')
            title = title.replace('&gt;', '>')

            written_dt = notice.get('written_dt', 'N/A')
            notice_id = notice.get('id', 'N/A')

            print(f'[{i}] {title}')
            print(f'    ID: {notice_id}')
            print(f'    작성일: {written_dt}')
            print('')
except Exception as e:
    print(f'JSON 파싱 오류: {e}')
" 2>/dev/null

    else
        echo -e "${RED}[4] API 응답 에러!${NC}"
        echo "-----------------------------------------------------------"
        echo "에러 코드: ${RESULT_CODE}"
        echo "에러 메시지: ${RESULT_MSG}"
        echo ""
        echo "에러 코드 설명:"
        echo "  0: 정상"
        echo "  -1: 시스템 내부 오류"
        echo "  -2: 잘못된 파라미터"
        echo "  -3: 등록되지 않은 서비스"
        echo "  -4: 등록되지 않은 인증키"
        echo "  -9: 종료된 서비스"
        echo "  -10: 트래픽 초과"
        echo "  -401: 유효하지 않은 인증키"
    fi

else
    echo -e "${RED}[3] API 호출 실패!${NC}"
    echo "-----------------------------------------------------------"
    echo "HTTP 상태 코드: ${HTTP_CODE}"
    echo ""
    echo "응답 본문:"
    echo "$BODY"
fi

echo ""
echo -e "${BLUE}============================================================${NC}"
echo -e "${YELLOW}[6] 원본 JSON 응답 (처음 1500자):${NC}"
echo -e "${BLUE}============================================================${NC}"
echo "${BODY:0:1500}"
echo ""
if [ ${#BODY} -gt 1500 ]; then
    echo "... (${#BODY}자 중 1500자만 표시)"
fi
echo ""
echo -e "${BLUE}============================================================${NC}"
echo "테스트 완료!"
echo -e "${BLUE}============================================================${NC}"
