---
description: "대한민국 공공데이터포털(data.go.kr)에서 제공하는 각종 공공데이터 API 사용. 공공데이터 개발 또는 공공 API 개발을 할 때 사용. 키워드: 공공데이터, data.go.kr, 외교부, 공공API, 한국 정부 데이터, serviceKey"
---

# 대한민국 공공데이터포털 API 스킬

## Center 프로젝트 글 생성/수정/관리 작업 시 필수 확인

> **Center 프로젝트에서 글 관련 작업(생성, 수정, 삭제, 배치 생성 등)을 수행할 때는 반드시 다음 순서로 문서를 확인하세요:**
>
> 1. **[api-spec.md](../center-skill/references/api-spec.md)** - API 사용 가이드, 테스트용 토큰, curl 예시
> 2. **[create_post.sh](../center-skill/scripts/create_post.sh)** - 단일/배치 게시글 생성 스크립트

---

## 1. 개요

**대한민국 공공데이터포털(data.go.kr)**은 중앙정부, 지자체, 공공기관이 보유한 데이터를 개방·제공하는 공식 플랫폼이다.

### 주요 특징

- **REST API 기반**: HTTP GET/POST 방식 호출
- **응답 형식**: JSON 또는 XML 선택 가능
- **인증 방식**: 서비스키(serviceKey) 기반
- **무료 제공**: 대부분의 API는 무료로 사용 가능

## 2. 실제 API 응답 구조

**중요**: 공공데이터포털 API 문서와 실제 응답 구조가 다를 수 있다. 아래는 **실제 응답 구조**이다.

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
          { /* 실제 데이터 항목 */ }
        ]
      },
      "numOfRows": 10,
      "pageNo": 1,
      "totalCount": 225
    }
  }
}
```

### 핵심 포인트

| 항목 | 문서 (잘못됨) | 실제 응답 (올바름) |
|------|--------------|------------------|
| 결과 코드 | `resultCode` (int) | `response.header.resultCode` (string) |
| 데이터 배열 | `data[]` | `response.body.items.item[]` |
| 총 개수 | `totalCount` | `response.body.totalCount` |

### 에러 코드

| 코드 | 메시지 | 설명 |
|------|--------|------|
| `0` | OK | 정상 |
| `-1` | 시스템 내부 오류 | 서버 에러 |
| `-2` | 파라미터 부적합 | 요청 파라미터 오류 |
| `-4` | 등록되지 않은 인증키 | 인증키 미등록 |
| `-10` | 트래픽 초과 | 일일 호출 횟수 초과 |
| `-401` | 유효하지 않은 인증키 | 인증키 오류 |

## 3. 제공 스크립트

### 3.1 외교부 공지사항 API 테스트 (`scripts/test-mofa-api.sh`)

외교부 공지사항 API를 터미널에서 직접 테스트할 수 있는 쉘 스크립트이다.

#### 사용법

```bash
# 스크립트 실행
./scripts/test-mofa-api.sh "<URL_ENCODED_API_KEY>"

# 예시
./scripts/test-mofa-api.sh "FAK7%2BJL3rqrFr7Wtn%2FxkKhW8hq1zDsite%2FxQdIwug4pDLD5bsqFJDKzroRXTkY8fm5LXMMMzIaTuvl%2F4iDtQ%2Bw%3D%3D"
```

#### 출력 내용

1. API 요청 정보 (엔드포인트, 파라미터)
2. HTTP 상태 코드
3. 결과 코드/메시지
4. 공지사항 목록 (제목, ID, 작성일)
5. 원본 JSON 응답 (처음 1500자)

#### 주의사항

- API Key는 **반드시 URL 인코딩된 값**을 사용해야 한다
- 공공데이터포털에서 발급받은 키를 그대로 복사하면 이미 인코딩되어 있음
- 스크립트 실행 전 실행 권한 필요: `chmod +x scripts/test-mofa-api.sh`

## 4. 제공 API 레퍼런스

| API | 문서 | 설명 |
|-----|------|------|
| 외교부 공지사항 | [references/mofa-reminder.md](references/mofa-reminder.md) | 출국 전 참고 공지사항 목록 조회 |

### 4.1 외교부 공지사항 API 빠른 참조

- **서비스 URL**: `http://apis.data.go.kr/1262000/NoticeService2/getNoticeList2`
- **HTTP Method**: GET
- **응답 형식**: JSON/XML
- **상세 문서**: [references/mofa-reminder.md](references/mofa-reminder.md)

## 5. Flutter 연동 가이드

Flutter 앱에서 공공데이터 API를 사용하는 방법이다. 본 프로젝트의 `lib/services/data/` 디렉토리에 구현되어 있다.

### 5.1 파일 구조

```
lib/services/data/
├── data.service.dart      # API 호출 및 캐싱 서비스 (싱글톤)
└── mofa_notice.model.dart # 응답 데이터 모델
```

### 5.2 모델 클래스 (`mofa_notice.model.dart`)

#### MofaNotice - 개별 공지사항

```dart
class MofaNotice {
  final String id;           // 공지사항 ID (예: "ATC0000000048200")
  final String title;        // 제목 (HTML 엔티티 포함)
  final String content;      // 내용 (txt_origin_cn)
  final String writtenDate;  // 작성일 (예: "2025-12-15")
  final String fileUrl;      // 첨부파일 URL (없으면 빈 문자열)

  // HTML 엔티티 디코딩된 제목/내용 반환
  String get decodedTitle => _decodeHtmlEntities(title);
  String get decodedContent => _decodeHtmlEntities(content);
}
```

#### MofaNoticeResponse - API 응답 래퍼

```dart
class MofaNoticeResponse {
  final String resultCode;   // "0" = 성공
  final String resultMsg;    // 결과 메시지
  final int totalCount;      // 전체 공지사항 수
  final int numOfRows;       // 요청한 개수
  final int pageNo;          // 페이지 번호
  final List<MofaNotice> notices; // 공지사항 목록
  final DateTime fetchedAt;  // 조회 시간

  bool get isSuccess => resultCode == '0';

  // API 응답 파싱 (실제 구조에 맞게)
  factory MofaNoticeResponse.fromApiJson(Map<String, dynamic> json) {
    final response = json['response'];
    final header = response['header'];
    final body = response['body'];
    final items = body['items']['item'] as List;
    // ...
  }
}
```

### 5.3 서비스 클래스 (`data.service.dart`)

싱글톤 패턴으로 구현된 API 서비스이다.

#### 핵심 개념

1. **싱글톤 패턴**: 앱 전체에서 하나의 인스턴스만 사용
2. **캐시 우선 전략**: 캐시 → API 호출 → 캐시 저장
3. **1시간 TTL**: 1시간마다 자동으로 캐시 만료
4. **이중 캐싱**: 메모리 + 파일 캐싱으로 성능 최적화

#### 사용법

```dart
import 'package:philgo/services/data/data.service.dart';

// 1. 공지사항 로드 (캐시 우선)
final response = await DataService.instance.loadMofaNotices();

// 2. 성공 여부 확인
if (response.isSuccess) {
  // 3. 공지사항 목록 접근
  for (final notice in response.notices) {
    print('제목: ${notice.decodedTitle}');
    print('날짜: ${notice.writtenDate}');
    print('내용: ${notice.decodedContent}');
  }
}

// 4. 캐시 강제 초기화 (새로고침)
await DataService.instance.clearMofaCache();

// 5. 캐시 남은 시간 확인
final remaining = DataService.instance.mofaCacheRemainingTime;
```

#### 주요 구현 코드

```dart
class DataService {
  static DataService? _instance;
  static DataService get instance => _instance ??= DataService._();

  // API Key (이미 URL 인코딩됨)
  static const String apiKey = AppConfig.dataApiKey;

  // 1시간 캐시 TTL
  static const Duration _mofaCacheTtl = Duration(hours: 1);

  // FileCache 사용 (메모리 + 파일 이중 캐싱)
  late final FileCache<MofaNoticeResponse> _mofaCache = FileCache(
    cacheName: 'mofa_notices',
    defaultTtl: _mofaCacheTtl,
    fromJson: MofaNoticeResponse.fromJson,
    toJson: (data) => data.toJson(),
    useMemoryCache: true,
  );

  Future<MofaNoticeResponse> loadMofaNotices() async {
    // 1. 캐시 확인
    final cached = await _mofaCache.get('mofa_notices');
    if (cached != null) return cached;

    // 2. API 호출
    final response = await http.get(Uri.parse(
      '$_mofaApiBaseUrl?serviceKey=$apiKey&returnType=JSON&numOfRows=5&pageNo=1'
    ));

    // 3. UTF-8 디코딩 (한글 깨짐 방지)
    final json = jsonDecode(utf8.decode(response.bodyBytes));

    // 4. 실제 응답 구조에 맞게 파싱
    final data = MofaNoticeResponse.fromApiJson(json);

    // 5. 캐시 저장
    await _mofaCache.set('mofa_notices', data);

    return data;
  }
}
```

### 5.4 UI 연동 예시

```dart
class _NoticeScreenState extends State<NoticeScreen> {
  bool _isLoading = true;
  MofaNoticeResponse? _response;

  @override
  void initState() {
    super.initState();
    _loadNotices();
  }

  Future<void> _loadNotices() async {
    final response = await DataService.instance.loadMofaNotices();
    setState(() {
      _response = response;
      _isLoading = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return CircularProgressIndicator();
    }

    if (!_response!.isSuccess) {
      return Text('에러: ${_response!.resultMsg}');
    }

    return ListView.builder(
      itemCount: _response!.notices.length,
      itemBuilder: (context, index) {
        final notice = _response!.notices[index];
        return ListTile(
          title: Text(notice.decodedTitle),
          subtitle: Text(notice.writtenDate),
          onTap: () => _showDetail(notice),
        );
      },
    );
  }
}
```

## 6. 개발 시 주의사항

1. **인증키 보안**: 인증키를 소스코드에 직접 하드코딩하지 말고 환경변수나 설정 파일로 관리
2. **URL Encode**: serviceKey는 반드시 URL Encode 처리
3. **응답 구조 확인**: 문서와 실제 응답 구조가 다를 수 있으므로 반드시 실제 응답 확인
4. **UTF-8 디코딩**: 한글 깨짐 방지를 위해 `utf8.decode(response.bodyBytes)` 사용
5. **HTML 엔티티 디코딩**: 제목/내용에 `&#39;`, `&nbsp;` 등이 포함될 수 있음
6. **캐싱**: 동일한 데이터를 반복 조회할 경우 캐싱 적용 권장
