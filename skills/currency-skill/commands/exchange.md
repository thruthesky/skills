---
description: "Frankfurter API를 사용한 환율 정보 조회 및 통화 변환. 무료 오픈소스 환율 API로 유럽중앙은행(ECB) 데이터 기반. API 키 불필요, 사용량 제한 없음. 사용 시점: (1) 최신/과거 환율 조회 (2) 통화 변환 계산 (3) 기간별 환율 시계열 데이터 분석 (4) 지원 통화 목록 확인 (5) Flutter/웹 앱에서 환율 기능 구현 (6) 자동화/AI 도구에서 환율 데이터 활용. 키워드: 환율, exchange rate, 통화 변환, currency conversion, ECB, 유럽중앙은행, USD, KRW, EUR, 시계열 데이터, API"
---

# Frankfurter Currency Exchange API

Frankfurter는 무료 오픈소스 환율 API입니다. API 키나 인증이 필요 없으며, 사용량 제한도 없습니다.

## 빠른 시작 (Quick Start)

### 최신 환율 조회

```bash
# USD 기준 KRW 환율
curl "https://api.frankfurter.dev/v1/latest?base=USD&symbols=KRW"

# 100 USD를 KRW로 변환
curl "https://api.frankfurter.dev/v1/latest?base=USD&symbols=KRW&amount=100"
```

### 과거 환율 조회

```bash
# 특정 날짜 환율 (YYYY-MM-DD 형식 필수)
curl "https://api.frankfurter.dev/v1/2024-01-15?base=USD&symbols=KRW"

# 어제 환율 (오늘이 2024-02-14라면)
curl "https://api.frankfurter.dev/v1/2024-02-13?base=USD&symbols=KRW"

# 일주일 전 환율
curl "https://api.frankfurter.dev/v1/2024-02-07?base=USD&symbols=KRW"

# 한 달 전 환율
curl "https://api.frankfurter.dev/v1/2024-01-14?base=USD&symbols=KRW"
```

**날짜 관련 중요 사항:**
- 날짜 형식: `YYYY-MM-DD` (예: 2024-02-14)
- 데이터 범위: 1999년 1월 4일부터 제공
- UTC 기준 저장: 타임존 차이로 의도한 날짜와 다를 수 있음
- 주말/휴일: 해당 날짜에 데이터 없으면 최근 영업일 환율 반환
- **오늘 날짜 사용 주의**: 데이터가 불안정하므로 안전하게 어제 날짜 사용 권장

### 시계열 데이터

```bash
# 기간별 환율 추이 (시작일..종료일)
curl "https://api.frankfurter.dev/v1/2024-01-01..2024-01-31?base=USD&symbols=KRW"

# 일주일 전부터 오늘까지 (종료일 생략 = 현재)
curl "https://api.frankfurter.dev/v1/2024-02-07..?base=USD&symbols=KRW"

# 한 달 전부터 현재까지
curl "https://api.frankfurter.dev/v1/2024-01-14..?base=USD&symbols=KRW"

# 작년 전체 데이터
curl "https://api.frankfurter.dev/v1/2024-01-01..2024-12-31?base=USD&symbols=KRW"
```

## 주요 기능

| 기능 | 엔드포인트 | 설명 |
|------|-----------|------|
| **최신 환율** | `/v1/latest` | 가장 최근 영업일 환율 (매일 16:00 CET 업데이트) |
| **과거 환율** | `/v1/{YYYY-MM-DD}` | 특정 날짜의 환율 (1999년부터 제공) |
| **시계열 데이터** | `/v1/{start}..{end}` | 기간별 환율 추이 분석 |
| **통화 목록** | `/v1/currencies` | 지원 통화 코드 및 이름 |

## 기본 파라미터

| 파라미터 | 설명 | 기본값 | 예시 |
|---------|------|--------|------|
| `base` | 기준 통화 (3자리 코드) | EUR | `base=USD` |
| `symbols` | 대상 통화 (쉼표 구분) | 전체 | `symbols=KRW,JPY` |
| `amount` | 변환할 금액 | 1 | `amount=100` |

## 응답 형식

```json
{
  "amount": 100,
  "base": "USD",
  "date": "2024-01-15",
  "rates": {
    "KRW": 135050.00
  }
}
```

## 지원 통화 (31개)

```
AUD, BGN, BRL, CAD, CHF, CNY, CZK, DKK, EUR, GBP,
HKD, HUF, IDR, ILS, INR, ISK, JPY, KRW, MXN, MYR,
NOK, NZD, PHP, PLN, RON, SEK, SGD, THB, TRY, USD, ZAR
```

## 주요 특징

- **API 키 불필요** - 인증 없이 바로 사용
- **무제한 사용** - 사용량 제한 없음
- **무료 상업 이용** - 상업적 목적으로도 무료
- **신뢰할 수 있는 데이터** - 유럽중앙은행(ECB) 공식 데이터
- **10년 이상 운영** - 안정적인 서비스
- **자체 호스팅 가능** - Docker 이미지 제공

## 사용 시 주의사항

- **실시간 데이터 아님**: 매일 16:00 CET에 한 번 업데이트
- **타임존 고려**: UTC 기준 저장으로 시간대 차이 발생 가능
- **당일 데이터 불안정**: 오늘 날짜 조회 시 데이터 변경 가능
- **주말/휴일**: 최근 영업일 환율 반환

## 상세 문서

더 자세한 API 정보, 구현 예시, 에러 처리, 모범 사례는 다음 문서를 참조하세요:

**[완전한 API 레퍼런스](references/api-reference.md)** - 모든 엔드포인트, 파라미터, 응답 형식, 구현 예시 (JavaScript/Python/Dart), 에러 처리, 캐싱 전략, 자체 호스팅 가이드 포함

## 테스트 스크립트

API 동작을 확인하기 위한 테스트 스크립트:

```bash
# Bash 테스트 실행
./scripts/test_frankfurter.sh

# Dart 테스트 실행
dart run scripts/test_frankfurter.dart
```

## 구현 예시 (빠른 참조)

### JavaScript - 날짜별 환율 조회

```javascript
// 어제 환율 조회
async function getYesterdayRate(from, to) {
  const yesterday = new Date();
  yesterday.setDate(yesterday.getDate() - 1);
  const dateStr = yesterday.toISOString().split('T')[0]; // YYYY-MM-DD

  const response = await fetch(
    `https://api.frankfurter.dev/v1/${dateStr}?base=${from}&symbols=${to}`
  );
  const data = await response.json();
  return data.rates[to];
}

// 일주일 전 환율 조회
async function getWeekAgoRate(from, to) {
  const weekAgo = new Date();
  weekAgo.setDate(weekAgo.getDate() - 7);
  const dateStr = weekAgo.toISOString().split('T')[0];

  const response = await fetch(
    `https://api.frankfurter.dev/v1/${dateStr}?base=${from}&symbols=${to}`
  );
  const data = await response.json();
  return data.rates[to];
}

// 사용 예시
const yesterdayRate = await getYesterdayRate('USD', 'KRW');
console.log(`어제: 1 USD = ${yesterdayRate} KRW`);

const weekAgoRate = await getWeekAgoRate('USD', 'KRW');
console.log(`일주일 전: 1 USD = ${weekAgoRate} KRW`);
```

### Python - 날짜별 환율 조회

```python
import requests
from datetime import datetime, timedelta

# 어제 환율 조회
def get_yesterday_rate(from_currency, to_currency):
    yesterday = datetime.now() - timedelta(days=1)
    date_str = yesterday.strftime('%Y-%m-%d')  # YYYY-MM-DD

    url = f"https://api.frankfurter.dev/v1/{date_str}"
    params = {'base': from_currency, 'symbols': to_currency}
    response = requests.get(url, params=params)
    data = response.json()
    return data['rates'][to_currency]

# 일주일 전 환율 조회
def get_week_ago_rate(from_currency, to_currency):
    week_ago = datetime.now() - timedelta(days=7)
    date_str = week_ago.strftime('%Y-%m-%d')

    url = f"https://api.frankfurter.dev/v1/{date_str}"
    params = {'base': from_currency, 'symbols': to_currency}
    response = requests.get(url, params=params)
    data = response.json()
    return data['rates'][to_currency]

# 사용 예시
yesterday_rate = get_yesterday_rate('USD', 'KRW')
print(f"어제: 1 USD = {yesterday_rate} KRW")

week_ago_rate = get_week_ago_rate('USD', 'KRW')
print(f"일주일 전: 1 USD = {week_ago_rate} KRW")
```

더 자세한 구현 예시와 에러 처리는 [API 레퍼런스](references/api-reference.md)를 참조하세요.
