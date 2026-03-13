# 외교부 공지사항 OpenAPI 기술 문서

> 문서 출처: 외교부 공지사항 API 기술 문서 v1.3
> 인터페이스: REST (GET)
> 데이터 포맷: JSON (또는 XML)
> 데이터 갱신주기: 수시
> **최종 검증일**: 2025-12-17

---

## 목차

- [1. API 서비스 명세](#1-api-서비스-명세)
- [2. 보안 / 표준 / 배포 정보](#2-보안--표준--배포-정보)
- [3. Endpoint](#3-endpoint)
- [4. 요청 파라미터](#4-요청-파라미터)
- [5. 실제 응답 구조](#5-실제-응답-구조)
- [6. 요청 / 응답 예제](#6-요청--응답-예제)
- [7. 에러 코드](#7-에러-코드)
- [8. HTML 엔티티 처리](#8-html-엔티티-처리)

---

## 1. API 서비스 명세

- **API명(국문)**: 공지사항
- **API명(영문)**: `NoticeService2`
- **API 설명**: 출국 전 꼭 참고해야 할 공지사항 목록 및 상세 정보를 제공

---

## 2. 보안 / 표준 / 배포 정보

### 보안

- **서비스 Key**: 사용 (공공데이터포털 발급)
- **SSL**: 미사용 (HTTP만 지원)

### 배포 정보

- **서비스 URL**: `http://apis.data.go.kr/1262000/NoticeService2`
- **서비스 버전**: 1.0
- **서비스 시작일**: 2020-12-24

---

## 3. Endpoint

```
http://apis.data.go.kr/1262000/NoticeService2/getNoticeList2
```

- **HTTP Method**: `GET`

---

## 4. 요청 파라미터

| 파라미터 | 항목명 | 필수 | 샘플 | 설명 |
|----------|--------|:----:|------|------|
| `serviceKey` | 인증키 | Y | (URL 인코딩된 키) | **반드시 URL Encode 필요** |
| `returnType` | 응답형식 | N | `JSON` | `XML` 또는 `JSON` |
| `numOfRows` | 결과 수 | Y | `10` | 한 페이지 결과 수 |
| `pageNo` | 페이지 | Y | `1` | 페이지 번호 |

---

## 5. 실제 응답 구조

> **중요**: 공공데이터포털 공식 문서와 실제 응답 구조가 다릅니다. 아래는 **실제 테스트로 검증된 구조**입니다.

### 5.1 전체 응답 구조

```json
{
  "response": {
    "header": {
      "resultCode": "0",
      "resultMsg": "정상"
    },
    "body": {
      "dataType": "JSON",
      "items": {
        "item": [
          {
            "file_download_url": null,
            "id": "ATC0000000048200",
            "title": "소방청 &#39;재외국민 119응급의료상담 서비스&#39; 안내",
            "txt_origin_cn": "소방청 중앙구급상황관리센터에서는...",
            "written_dt": "2025-12-15"
          }
        ]
      },
      "numOfRows": 5,
      "pageNo": 1,
      "totalCount": 1085
    }
  }
}
```

### 5.2 필드 매핑 (문서 vs 실제)

| 공식 문서 | 실제 응답 | 타입 |
|----------|----------|------|
| `resultCode` | `response.header.resultCode` | string |
| `resultMsg` | `response.header.resultMsg` | string |
| `totalCount` | `response.body.totalCount` | int |
| `numOfRows` | `response.body.numOfRows` | int |
| `pageNo` | `response.body.pageNo` | int |
| `data[]` | `response.body.items.item[]` | array |

### 5.3 개별 공지사항 필드

| 필드 | 설명 | 타입 | 예시 |
|------|------|------|------|
| `id` | 공지사항 ID | string | `"ATC0000000048200"` |
| `title` | 제목 | string | HTML 엔티티 포함 가능 |
| `txt_origin_cn` | 내용 | string/null | HTML 엔티티/태그 포함 가능 |
| `written_dt` | 작성일 | string | `"2025-12-15"` |
| `file_download_url` | 첨부파일 | string/null | URL 또는 null |

---

## 6. 요청 / 응답 예제

### 6.1 요청 예시

```bash
curl "http://apis.data.go.kr/1262000/NoticeService2/getNoticeList2?serviceKey=YOUR_ENCODED_KEY&pageNo=1&numOfRows=5&returnType=JSON"
```

### 6.2 실제 응답 예시 (2025-12-17 테스트)

```json
{
  "response": {
    "header": {
      "resultCode": "0",
      "resultMsg": "정상"
    },
    "body": {
      "dataType": "JSON",
      "items": {
        "item": [
          {
            "file_download_url": null,
            "id": "ATC0000000048200",
            "title": "소방청 &#39;재외국민 119응급의료상담 서비스&#39; 안내",
            "txt_origin_cn": "소방청 중앙구급상황관리센터에서는 응급의학전문의에 의한 24시간 응급상담이 가능하도록 &quot;119 재외국민 응급의료상담서비스&quot; 를 운영하고 있습니다.\n\n재외국민 대상 119응급의료상담서비스 운영 방법과 절차를 다음과 같이 알려드리니 응급상황시 활용하시기 바랍니다.\n\n- 대상 : 재외국민(육상&middot;해상), 해외 여행객 포함 누구나\n- 이용방법 : 전화, 전용 홈페이지,이메일, 카카오톡\n&nbsp; &nbsp;* 전화 : +82-44-320-0119",
            "written_dt": "2025-12-15"
          },
          {
            "file_download_url": null,
            "id": "ATC0000000048193",
            "title": "시스템 점검에 따른 홈페이지 접속 일시 제한 안내",
            "txt_origin_cn": "외교부 해외안전여행 홈페이지를 이용해주셔서 감사합니다.\n\n안정적인 서비스 제공을 위해 아래 시간동안 접속이 원할하지 않을 수 있으니 이용에 참고하시기 바랍니다.\n\n한국시간&nbsp;2025.12.9.(화) 19:00 -&nbsp;12.10.(수)&nbsp;05:00",
            "written_dt": "2025-12-09"
          },
          {
            "file_download_url": null,
            "id": "ATC0000000048126",
            "title": "숭실대학교 재난안전관리학과 재외국민보호 전공 석&middot;박사 과정 모집",
            "txt_origin_cn": null,
            "written_dt": "2025-10-16"
          }
        ]
      },
      "numOfRows": 5,
      "pageNo": 1,
      "totalCount": 1085
    }
  }
}
```

---

## 7. 에러 코드

| 코드 | 메시지 | 설명 |
|------|--------|------|
| `0` | 정상 | 성공 |
| `-1` | 시스템 내부 오류 | 서버 에러 |
| `-2` | 파라미터 부적합 | 잘못된 요청 파라미터 |
| `-3` | 등록되지 않은 서비스 | 존재하지 않는 서비스 |
| `-4` | 등록되지 않은 인증키 | 인증키 미등록 |
| `-9` | 종료된 서비스 | 서비스 종료 |
| `-10` | 트래픽 초과 | 일일 호출 횟수 초과 |
| `-401` | 유효하지 않은 인증키 | 인증키 오류 |

---

## 8. HTML 엔티티 처리

API 응답의 `title`과 `txt_origin_cn` 필드에는 HTML 엔티티가 포함될 수 있다.

### 8.1 발견된 HTML 엔티티

| 엔티티 | 의미 | 디코딩 결과 |
|--------|------|------------|
| `&#39;` | 작은따옴표 | `'` |
| `&quot;` | 큰따옴표 | `"` |
| `&amp;` | 앰퍼샌드 | `&` |
| `&lt;` | 미만 | `<` |
| `&gt;` | 초과 | `>` |
| `&nbsp;` | 공백 | ` ` |
| `&middot;` | 중간점 | `·` |

### 8.2 Dart 디코딩 예시

```dart
String decodeHtmlEntities(String text) {
  return text
    .replaceAll('&#39;', "'")
    .replaceAll('&quot;', '"')
    .replaceAll('&amp;', '&')
    .replaceAll('&lt;', '<')
    .replaceAll('&gt;', '>')
    .replaceAll('&nbsp;', ' ')
    .replaceAll('&middot;', '·')
    .replaceAll(RegExp(r'<[^>]*>'), '')  // HTML 태그 제거
    .replaceAll(RegExp(r'\s+'), ' ')      // 연속 공백 정리
    .trim();
}
```

### 8.3 JavaScript 디코딩 예시

```javascript
function decodeHtmlEntities(text) {
  const textarea = document.createElement('textarea');
  textarea.innerHTML = text;
  return textarea.value
    .replace(/<[^>]*>/g, '')
    .replace(/\s+/g, ' ')
    .trim();
}
```

### 8.4 PHP 디코딩 예시

```php
function decodeHtmlEntities(string $text): string {
    $text = html_entity_decode($text, ENT_QUOTES | ENT_HTML5, 'UTF-8');
    $text = strip_tags($text);
    $text = preg_replace('/\s+/', ' ', $text);
    return trim($text);
}
```

---

## 부록: 테스트 스크립트

API 테스트는 `scripts/test-mofa-api.sh` 스크립트를 사용한다.

```bash
# 사용법
./scripts/test-mofa-api.sh "<URL_ENCODED_API_KEY>"
```
