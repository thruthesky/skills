# Frankfurter API 완전 레퍼런스

## 개요

Frankfurter는 무료 오픈소스 환율 데이터 API입니다. 유럽중앙은행(ECB) 등의 기관에서 제공하는 참조 환율 데이터를 제공합니다.

### 주요 특징

| 특징 | 설명 |
|------|------|
| **API 키** | 불필요 - 인증 없이 바로 사용 |
| **사용량 제한** | 없음 - 무제한 요청 가능 |
| **상업적 이용** | 무료 허용 |
| **데이터 출처** | 유럽중앙은행(ECB) |
| **업데이트 시간** | 매일 16:00 CET |
| **시간대** | UTC 기준 저장 |
| **운영 기간** | 10년 이상, 종료 계획 없음 |
| **호스팅** | Cloudflare 기반 |

## Base URL

```
https://api.frankfurter.dev/v1
```

## 전체 엔드포인트

### 1. 최신 환율 조회

**엔드포인트**: `GET /v1/latest`

**설명**: 가장 최근 근무일의 환율을 반환합니다. 매일 16:00 CET에 업데이트됩니다.

**파라미터**:

| 파라미터 | 타입 | 필수 | 기본값 | 설명 |
|---------|------|------|--------|------|
| `base` | string | 아니오 | EUR | 기준 통화 코드 (3자리) |
| `symbols` | string | 아니오 | 전체 | 대상 통화 코드 (쉼표로 구분) |
| `amount` | number | 아니오 | 1 | 변환할 금액 |

**요청 예시**:

```bash
# EUR 기준 모든 통화 환율
curl "https://api.frankfurter.dev/v1/latest"

# USD 기준 KRW, PHP 환율
curl "https://api.frankfurter.dev/v1/latest?base=USD&symbols=KRW,PHP"

# 100 USD를 KRW로 변환
curl "https://api.frankfurter.dev/v1/latest?base=USD&symbols=KRW&amount=100"
```

**응답 형식**:

```json
{
  "amount": 1,
  "base": "USD",
  "date": "2024-01-15",
  "rates": {
    "KRW": 1350.50,
    "PHP": 56.20
  }
}
```

### 2. 특정 날짜 환율 조회

**엔드포인트**: `GET /v1/{YYYY-MM-DD}`

**설명**: 특정 날짜의 환율을 조회합니다. 주말/휴일의 경우 마지막 영업일 환율을 반환합니다.

**파라미터**:

| 파라미터 | 타입 | 필수 | 기본값 | 설명 |
|---------|------|------|--------|------|
| `base` | string | 아니오 | EUR | 기준 통화 코드 |
| `symbols` | string | 아니오 | 전체 | 대상 통화 코드 |
| `amount` | number | 아니오 | 1 | 변환할 금액 |

**요청 예시**:

```bash
# 2024년 1월 15일 USD 기준 KRW 환율
curl "https://api.frankfurter.dev/v1/2024-01-15?base=USD&symbols=KRW"

# 특정 날짜에 100 EUR를 USD로 변환
curl "https://api.frankfurter.dev/v1/2024-01-15?base=EUR&symbols=USD&amount=100"
```

**응답 형식**:

```json
{
  "amount": 1,
  "base": "USD",
  "date": "2024-01-15",
  "rates": {
    "KRW": 1350.50
  }
}
```

**중요 사항**:

⚠️ **날짜 형식**: 반드시 `YYYY-MM-DD` 형식 사용 (예: 2024-02-14)
⚠️ **데이터 범위**: 1999년 1월 4일부터 제공
⚠️ **UTC 기준 저장**: 타임존 차이로 의도한 날짜와 다를 수 있음
⚠️ **당일 데이터 불안정**: 오늘 날짜 조회 시 데이터가 변경될 수 있음 → **어제 날짜 사용 권장**
⚠️ **주말/휴일 처리**: 해당 날짜에 데이터가 없으면 최근 영업일 환율 반환
⚠️ **미래 날짜**: 존재하지 않는 미래 날짜 요청 시 에러 반환

**날짜 계산 예시**:

```bash
# 오늘이 2024-02-14라고 가정

# 어제 (2024-02-13)
curl "https://api.frankfurter.dev/v1/2024-02-13?base=USD&symbols=KRW"

# 일주일 전 (2024-02-07)
curl "https://api.frankfurter.dev/v1/2024-02-07?base=USD&symbols=KRW"

# 한 달 전 (2024-01-14)
curl "https://api.frankfurter.dev/v1/2024-01-14?base=USD&symbols=KRW"

# 1년 전 (2023-02-14)
curl "https://api.frankfurter.dev/v1/2023-02-14?base=USD&symbols=KRW"
```

**주말/휴일 예시**:

```bash
# 토요일 날짜로 조회하면 금요일 환율 반환
curl "https://api.frankfurter.dev/v1/2024-02-10?base=USD&symbols=KRW"
# → 2024-02-10은 토요일이므로 2024-02-09(금요일) 환율 반환

# 일요일 날짜로 조회해도 금요일 환율 반환
curl "https://api.frankfurter.dev/v1/2024-02-11?base=USD&symbols=KRW"
# → 2024-02-11은 일요일이므로 2024-02-09(금요일) 환율 반환
```

### 3. 시계열 환율 데이터

**엔드포인트**: `GET /v1/{start-date}..{end-date}`

**설명**: 기간별 환율 추이 데이터를 조회합니다. 일별 환율 데이터를 제공합니다.

**파라미터**:

| 파라미터 | 타입 | 필수 | 기본값 | 설명 |
|---------|------|------|--------|------|
| `base` | string | 아니오 | EUR | 기준 통화 코드 |
| `symbols` | string | 아니오 | 전체 | 대상 통화 코드 |
| `amount` | number | 아니오 | 1 | 변환할 금액 |

**요청 예시**:

```bash
# 2024년 1월 전체 기간 USD 기준 KRW 환율
curl "https://api.frankfurter.dev/v1/2024-01-01..2024-01-31?base=USD&symbols=KRW"

# 특정 날짜부터 현재까지
curl "https://api.frankfurter.dev/v1/2024-01-01..?base=USD&symbols=KRW"

# 복수 통화 조회
curl "https://api.frankfurter.dev/v1/2024-01-01..2024-01-31?base=USD&symbols=KRW,JPY,CNY"
```

**응답 형식**:

```json
{
  "amount": 1,
  "base": "USD",
  "start_date": "2024-01-01",
  "end_date": "2024-01-31",
  "rates": {
    "2024-01-01": {"KRW": 1340.00},
    "2024-01-02": {"KRW": 1342.50},
    "2024-01-03": {"KRW": 1345.20},
    "...": {}
  }
}
```

**최적화 팁**:
- `symbols` 파라미터로 필터링하여 응답 크기 축소 권장
- 긴 기간 조회 시 필요한 통화만 지정
- 주말/휴일은 데이터에 포함되지 않음 (영업일만)

### 4. 지원 통화 목록

**엔드포인트**: `GET /v1/currencies`

**설명**: 지원하는 모든 통화 코드와 전체 이름을 반환합니다.

**파라미터**: 없음

**요청 예시**:

```bash
curl "https://api.frankfurter.dev/v1/currencies"
```

**응답 형식**:

```json
{
  "AUD": "Australian Dollar",
  "BGN": "Bulgarian Lev",
  "BRL": "Brazilian Real",
  "CAD": "Canadian Dollar",
  "CHF": "Swiss Franc",
  "CNY": "Chinese Renminbi Yuan",
  "CZK": "Czech Koruna",
  "DKK": "Danish Krone",
  "EUR": "Euro",
  "GBP": "British Pound",
  "HKD": "Hong Kong Dollar",
  "HUF": "Hungarian Forint",
  "IDR": "Indonesian Rupiah",
  "ILS": "Israeli New Sheqel",
  "INR": "Indian Rupee",
  "ISK": "Icelandic Króna",
  "JPY": "Japanese Yen",
  "KRW": "South Korean Won",
  "MXN": "Mexican Peso",
  "MYR": "Malaysian Ringgit",
  "NOK": "Norwegian Krone",
  "NZD": "New Zealand Dollar",
  "PHP": "Philippine Peso",
  "PLN": "Polish Złoty",
  "RON": "Romanian Leu",
  "SEK": "Swedish Krona",
  "SGD": "Singapore Dollar",
  "THB": "Thai Baht",
  "TRY": "Turkish Lira",
  "USD": "United States Dollar",
  "ZAR": "South African Rand"
}
```

## 지원 통화 코드

총 31개 통화 지원:

```
AUD, BGN, BRL, CAD, CHF, CNY, CZK, DKK, EUR, GBP,
HKD, HUF, IDR, ILS, INR, ISK, JPY, KRW, MXN, MYR,
NOK, NZD, PHP, PLN, RON, SEK, SGD, THB, TRY, USD, ZAR
```

## 통화 변환 구현 예시

### JavaScript/TypeScript

**최신 환율 조회:**

```javascript
async function convertCurrency(amount, from, to) {
  const response = await fetch(
    `https://api.frankfurter.dev/v1/latest?base=${from}&symbols=${to}&amount=${amount}`
  );
  const data = await response.json();
  return {
    amount: amount,
    from: from,
    to: to,
    rate: data.rates[to],
    convertedAmount: (amount * data.rates[to]).toFixed(2),
    date: data.date
  };
}

// 사용 예시
const result = await convertCurrency(100, 'USD', 'KRW');
console.log(`${result.amount} ${result.from} = ${result.convertedAmount} ${result.to}`);
// 출력: 100 USD = 135050.00 KRW
```

**날짜별 환율 조회:**

```javascript
// 날짜 문자열 생성 유틸리티 (YYYY-MM-DD)
function getDateString(daysAgo = 0) {
  const date = new Date();
  date.setDate(date.getDate() - daysAgo);
  return date.toISOString().split('T')[0];
}

// 어제 환율 조회
async function getYesterdayRate(from, to) {
  const dateString = getDateString(1); // 1일 전
  const response = await fetch(
    `https://api.frankfurter.dev/v1/${dateString}?base=${from}&symbols=${to}`
  );
  const data = await response.json();
  return {
    from: from,
    to: to,
    rate: data.rates[to],
    date: data.date
  };
}

// 일주일 전 환율 조회
async function getWeekAgoRate(from, to) {
  const dateString = getDateString(7); // 7일 전
  const response = await fetch(
    `https://api.frankfurter.dev/v1/${dateString}?base=${from}&symbols=${to}`
  );
  const data = await response.json();
  return {
    from: from,
    to: to,
    rate: data.rates[to],
    date: data.date
  };
}

// 특정 날짜 환율 조회
async function getRateByDate(from, to, date) {
  const dateString = date.toISOString().split('T')[0];
  const response = await fetch(
    `https://api.frankfurter.dev/v1/${dateString}?base=${from}&symbols=${to}`
  );
  const data = await response.json();
  return {
    from: from,
    to: to,
    rate: data.rates[to],
    date: data.date
  };
}

// 사용 예시
const yesterdayRate = await getYesterdayRate('USD', 'KRW');
console.log(`어제 (${yesterdayRate.date}): 1 ${yesterdayRate.from} = ${yesterdayRate.rate} ${yesterdayRate.to}`);

const weekAgoRate = await getWeekAgoRate('USD', 'KRW');
console.log(`일주일 전 (${weekAgoRate.date}): 1 ${weekAgoRate.from} = ${weekAgoRate.rate} ${weekAgoRate.to}`);

const specificDate = new Date('2024-01-15');
const specificRate = await getRateByDate('USD', 'KRW', specificDate);
console.log(`${specificRate.date}: 1 ${specificRate.from} = ${specificRate.rate} ${specificRate.to}`);
```

### Python

**최신 환율 조회:**

```python
import requests

def convert_currency(amount, from_currency, to_currency):
    url = f"https://api.frankfurter.dev/v1/latest"
    params = {
        'base': from_currency,
        'symbols': to_currency,
        'amount': amount
    }
    response = requests.get(url, params=params)
    data = response.json()

    return {
        'amount': amount,
        'from': from_currency,
        'to': to_currency,
        'rate': data['rates'][to_currency],
        'converted_amount': amount * data['rates'][to_currency],
        'date': data['date']
    }

# 사용 예시
result = convert_currency(100, 'USD', 'KRW')
print(f"{result['amount']} {result['from']} = {result['converted_amount']} {result['to']}")
# 출력: 100 USD = 135050.0 KRW
```

**날짜별 환율 조회:**

```python
import requests
from datetime import datetime, timedelta

# 날짜 문자열 생성 유틸리티 (YYYY-MM-DD)
def get_date_string(days_ago=0):
    date = datetime.now() - timedelta(days=days_ago)
    return date.strftime('%Y-%m-%d')

# 어제 환율 조회
def get_yesterday_rate(from_currency, to_currency):
    date_string = get_date_string(1)  # 1일 전
    url = f"https://api.frankfurter.dev/v1/{date_string}"
    params = {'base': from_currency, 'symbols': to_currency}
    response = requests.get(url, params=params)
    data = response.json()

    return {
        'from': from_currency,
        'to': to_currency,
        'rate': data['rates'][to_currency],
        'date': data['date']
    }

# 일주일 전 환율 조회
def get_week_ago_rate(from_currency, to_currency):
    date_string = get_date_string(7)  # 7일 전
    url = f"https://api.frankfurter.dev/v1/{date_string}"
    params = {'base': from_currency, 'symbols': to_currency}
    response = requests.get(url, params=params)
    data = response.json()

    return {
        'from': from_currency,
        'to': to_currency,
        'rate': data['rates'][to_currency],
        'date': data['date']
    }

# 특정 날짜 환율 조회
def get_rate_by_date(from_currency, to_currency, date):
    date_string = date.strftime('%Y-%m-%d')
    url = f"https://api.frankfurter.dev/v1/{date_string}"
    params = {'base': from_currency, 'symbols': to_currency}
    response = requests.get(url, params=params)
    data = response.json()

    return {
        'from': from_currency,
        'to': to_currency,
        'rate': data['rates'][to_currency],
        'date': data['date']
    }

# 사용 예시
yesterday_rate = get_yesterday_rate('USD', 'KRW')
print(f"어제 ({yesterday_rate['date']}): 1 {yesterday_rate['from']} = {yesterday_rate['rate']} {yesterday_rate['to']}")

week_ago_rate = get_week_ago_rate('USD', 'KRW')
print(f"일주일 전 ({week_ago_rate['date']}): 1 {week_ago_rate['from']} = {week_ago_rate['rate']} {week_ago_rate['to']}")

specific_date = datetime(2024, 1, 15)
specific_rate = get_rate_by_date('USD', 'KRW', specific_date)
print(f"{specific_rate['date']}: 1 {specific_rate['from']} = {specific_rate['rate']} {specific_rate['to']}")
```

### Dart/Flutter

**최신 환율 조회:**

```dart
import 'dart:convert';
import 'package:http/http.dart' as http;

Future<Map<String, dynamic>> convertCurrency(
  double amount,
  String from,
  String to
) async {
  final url = Uri.parse(
    'https://api.frankfurter.dev/v1/latest?base=$from&symbols=$to&amount=$amount'
  );

  final response = await http.get(url);

  if (response.statusCode == 200) {
    final data = json.decode(response.body);
    return {
      'amount': amount,
      'from': from,
      'to': to,
      'rate': data['rates'][to],
      'convertedAmount': amount * data['rates'][to],
      'date': data['date'],
    };
  } else {
    throw Exception('Failed to load exchange rate');
  }
}

// 사용 예시
void main() async {
  final result = await convertCurrency(100, 'USD', 'KRW');
  print('${result['amount']} ${result['from']} = ${result['convertedAmount']} ${result['to']}');
  // 출력: 100 USD = 135050.0 KRW
}
```

**날짜별 환율 조회 (어제, 일주일 전 등):**

```dart
import 'dart:convert';
import 'package:http/http.dart' as http;

// 어제 환율 조회
Future<Map<String, dynamic>> getYesterdayRate(String from, String to) async {
  final yesterday = DateTime.now().subtract(Duration(days: 1));
  final dateStr = yesterday.toIso8601String().split('T')[0]; // YYYY-MM-DD

  final url = Uri.parse(
    'https://api.frankfurter.dev/v1/$dateStr?base=$from&symbols=$to'
  );

  final response = await http.get(url);

  if (response.statusCode == 200) {
    final data = json.decode(response.body);
    return {
      'from': from,
      'to': to,
      'rate': data['rates'][to],
      'date': data['date'],
    };
  } else {
    throw Exception('Failed to load exchange rate');
  }
}

// 일주일 전 환율 조회
Future<Map<String, dynamic>> getWeekAgoRate(String from, String to) async {
  final weekAgo = DateTime.now().subtract(Duration(days: 7));
  final dateStr = weekAgo.toIso8601String().split('T')[0];

  final url = Uri.parse(
    'https://api.frankfurter.dev/v1/$dateStr?base=$from&symbols=$to'
  );

  final response = await http.get(url);

  if (response.statusCode == 200) {
    final data = json.decode(response.body);
    return {
      'from': from,
      'to': to,
      'rate': data['rates'][to],
      'date': data['date'],
    };
  } else {
    throw Exception('Failed to load exchange rate');
  }
}

// 특정 날짜 환율 조회 (범용 함수)
Future<Map<String, dynamic>> getRateByDate(
  String from,
  String to,
  DateTime date
) async {
  final dateStr = date.toIso8601String().split('T')[0]; // YYYY-MM-DD

  final url = Uri.parse(
    'https://api.frankfurter.dev/v1/$dateStr?base=$from&symbols=$to'
  );

  final response = await http.get(url);

  if (response.statusCode == 200) {
    final data = json.decode(response.body);
    return {
      'from': from,
      'to': to,
      'rate': data['rates'][to],
      'date': data['date'],
    };
  } else {
    throw Exception('Failed to load exchange rate');
  }
}

// 사용 예시
void main() async {
  // 어제 환율
  final yesterdayRate = await getYesterdayRate('USD', 'KRW');
  print('어제 (${yesterdayRate['date']}): 1 ${yesterdayRate['from']} = ${yesterdayRate['rate']} ${yesterdayRate['to']}');

  // 일주일 전 환율
  final weekAgoRate = await getWeekAgoRate('USD', 'KRW');
  print('일주일 전 (${weekAgoRate['date']}): 1 ${weekAgoRate['from']} = ${weekAgoRate['rate']} ${weekAgoRate['to']}');

  // 특정 날짜 환율 (예: 2024년 1월 1일)
  final specificDate = DateTime(2024, 1, 1);
  final specificRate = await getRateByDate('USD', 'KRW', specificDate);
  print('${specificRate['date']}: 1 ${specificRate['from']} = ${specificRate['rate']} ${specificRate['to']}');
}
```

## 에러 처리

### HTTP 상태 코드

| 코드 | 설명 |
|------|------|
| 200 | 성공 |
| 400 | 잘못된 요청 (유효하지 않은 통화 코드 등) |
| 404 | 엔드포인트를 찾을 수 없음 |
| 500 | 서버 에러 |

### 에러 응답 예시

```json
{
  "message": "invalid currency code"
}
```

### 에러 처리 구현

```javascript
async function safeConvertCurrency(amount, from, to) {
  try {
    const response = await fetch(
      `https://api.frankfurter.dev/v1/latest?base=${from}&symbols=${to}&amount=${amount}`
    );

    if (!response.ok) {
      const error = await response.json();
      throw new Error(error.message || `HTTP error! status: ${response.status}`);
    }

    const data = await response.json();
    return data;
  } catch (error) {
    console.error('Currency conversion failed:', error);
    throw error;
  }
}
```

## 모범 사례

### 1. 캐싱 전략

환율 데이터는 하루에 한 번만 업데이트되므로 캐싱을 적극 활용하세요:

```javascript
const cache = new Map();
const CACHE_DURATION = 3600000; // 1시간

async function getCachedRate(from, to) {
  const key = `${from}-${to}`;
  const cached = cache.get(key);

  if (cached && Date.now() - cached.timestamp < CACHE_DURATION) {
    return cached.data;
  }

  const data = await convertCurrency(1, from, to);
  cache.set(key, { data, timestamp: Date.now() });
  return data;
}
```

### 2. 응답 크기 최적화

필요한 통화만 `symbols` 파라미터로 지정:

```bash
# ❌ 나쁜 예 - 모든 통화 조회
curl "https://api.frankfurter.dev/v1/latest?base=USD"

# ✅ 좋은 예 - 필요한 통화만 조회
curl "https://api.frankfurter.dev/v1/latest?base=USD&symbols=KRW,JPY"
```

### 3. 날짜 관련 모범 사례

#### 3.1 안전한 날짜 사용

**⚠️ 오늘 날짜 사용 주의**: 당일 데이터는 불안정하므로 어제 날짜 사용 권장

```javascript
// ❌ 나쁜 예 - 오늘 날짜 사용
const today = new Date().toISOString().split('T')[0];
const data = await fetch(`https://api.frankfurter.dev/v1/${today}`);
// 문제: 데이터가 아직 업데이트 안 됐을 수 있음 (16:00 CET 이전)

// ✅ 좋은 예 - 어제 날짜 사용
const yesterday = new Date();
yesterday.setDate(yesterday.getDate() - 1);
const dateString = yesterday.toISOString().split('T')[0];
const data = await fetch(`https://api.frankfurter.dev/v1/${dateString}`);
```

#### 3.2 타임존 고려

UTC 기준으로 저장되므로 현지 시간대를 고려해야 합니다:

```javascript
// JavaScript - 날짜 계산 유틸리티 함수
function getDateString(daysAgo = 0) {
  const date = new Date();
  date.setDate(date.getDate() - daysAgo);
  return date.toISOString().split('T')[0]; // YYYY-MM-DD
}

// 사용 예시
const yesterday = getDateString(1);     // 1일 전
const weekAgo = getDateString(7);       // 7일 전
const monthAgo = getDateString(30);     // 30일 전

console.log(`어제: ${yesterday}`);       // 2024-02-13
console.log(`일주일 전: ${weekAgo}`);     // 2024-02-07
console.log(`한 달 전: ${monthAgo}`);     // 2024-01-14
```

```python
# Python - 날짜 계산 유틸리티 함수
from datetime import datetime, timedelta

def get_date_string(days_ago=0):
    date = datetime.now() - timedelta(days=days_ago)
    return date.strftime('%Y-%m-%d')  # YYYY-MM-DD

# 사용 예시
yesterday = get_date_string(1)      # 1일 전
week_ago = get_date_string(7)       # 7일 전
month_ago = get_date_string(30)     # 30일 전

print(f"어제: {yesterday}")           # 2024-02-13
print(f"일주일 전: {week_ago}")        # 2024-02-07
print(f"한 달 전: {month_ago}")        # 2024-01-14
```

#### 3.3 주말/휴일 처리

주말이나 휴일에는 최근 영업일 환율이 반환됩니다:

```javascript
// 주말 날짜로 조회 시 자동으로 금요일 환율 반환
async function getRateHandlingWeekend(date, from, to) {
  const dateString = date.toISOString().split('T')[0];
  const response = await fetch(
    `https://api.frankfurter.dev/v1/${dateString}?base=${from}&symbols=${to}`
  );
  const data = await response.json();

  // 실제 반환된 날짜 확인
  console.log(`요청한 날짜: ${dateString}`);
  console.log(`실제 데이터 날짜: ${data.date}`);

  return data;
}

// 예시: 토요일 날짜로 조회
const saturday = new Date('2024-02-10'); // 토요일
const rate = await getRateHandlingWeekend(saturday, 'USD', 'KRW');
// 요청한 날짜: 2024-02-10
// 실제 데이터 날짜: 2024-02-09 (금요일)
```

#### 3.4 날짜 범위 검증

```javascript
// 유효한 날짜 범위 확인
function isValidDateRange(date) {
  const minDate = new Date('1999-01-04'); // Frankfurter 최소 날짜
  const maxDate = new Date();
  maxDate.setDate(maxDate.getDate() - 1); // 어제까지만 안전

  return date >= minDate && date <= maxDate;
}

// 사용 예시
const testDate = new Date('2024-01-15');
if (isValidDateRange(testDate)) {
  console.log('유효한 날짜입니다');
} else {
  console.log('유효하지 않은 날짜입니다');
}
```

### 4. 에러 핸들링

항상 에러 처리를 구현하고 폴백 전략 준비:

```javascript
async function getRateWithFallback(from, to) {
  try {
    return await getLatestRate(from, to);
  } catch (error) {
    console.error('Latest rate failed, trying yesterday:', error);
    try {
      const yesterday = getYesterdayDate();
      return await getHistoricalRate(yesterday, from, to);
    } catch (fallbackError) {
      console.error('Fallback also failed:', fallbackError);
      throw new Error('Unable to fetch exchange rate');
    }
  }
}
```

## 자체 호스팅

대량 요청이 필요하거나 독립적인 인프라가 필요한 경우 Docker로 자체 호스팅 가능:

```bash
# Docker로 실행
docker run -d -p 80:8080 lineofflight/frankfurter

# 로컬에서 접근
curl "http://localhost/v1/latest"
```

## 데이터 업데이트 스케줄

| 시간 | 이벤트 |
|------|--------|
| 16:00 CET | ECB 환율 데이터 업데이트 |
| 매일 | 영업일 기준 새 데이터 추가 |
| 주말/휴일 | 마지막 영업일 데이터 반환 |

## 제한 사항 및 주의사항

1. **실시간 데이터 아님**: 하루 한 번 업데이트 (16:00 CET)
2. **당일 데이터 불안정**: 당일 날짜 조회 시 데이터가 변경될 수 있음
3. **타임존 영향**: UTC 기준 저장으로 시간대 차이 발생 가능
4. **주말/휴일**: 최근 영업일 데이터 반환
5. **대량 요청**: 무제한이지만 서버 부하 고려 시 자체 호스팅 권장
6. **역사 데이터 범위**: 1999년 1월 4일부터 제공

## 자주 묻는 질문 (FAQ)

### Q: API 키가 필요한가요?
A: 아니오, 인증 없이 바로 사용 가능합니다.

### Q: 사용량 제한이 있나요?
A: 공식적인 제한은 없지만, 대량 요청 시 자체 호스팅을 권장합니다.

### Q: 상업적으로 사용해도 되나요?
A: 네, 무료로 상업적 이용이 가능합니다.

### Q: 실시간 환율인가요?
A: 아니오, 매일 16:00 CET에 한 번 업데이트되는 참조 환율입니다.

### Q: 암호화폐 환율도 지원하나요?
A: 아니오, ECB 데이터 기반으로 전통 화폐만 지원합니다.

### Q: 과거 데이터는 얼마나 제공하나요?
A: 1999년 1월 4일부터 제공합니다.

## 참고 링크

- 공식 웹사이트: https://frankfurter.dev/
- 공식 문서: https://frankfurter.dev/docs/
- GitHub: https://github.com/lineofflight/frankfurter
- Docker Hub: https://hub.docker.com/r/lineofflight/frankfurter
