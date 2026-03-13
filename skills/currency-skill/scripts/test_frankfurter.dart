/// Frankfurter API 테스트 스크립트 (Dart)
/// 사용법: dart run test_frankfurter.dart
///
/// 이 스크립트는 Frankfurter API의 주요 기능을 테스트합니다:
/// - 최신 환율 조회
/// - 특정 통화 기준 환율 조회
/// - 금액 변환
/// - 특정 날짜 환율 조회
/// - 지원 통화 목록 조회

import 'dart:convert';
import 'dart:io';

/// Frankfurter API 기본 URL
const String baseUrl = 'https://api.frankfurter.dev/v1';

/// HTTP GET 요청을 보내고 JSON 응답을 반환
Future<Map<String, dynamic>> fetchJson(String url) async {
  final client = HttpClient();
  try {
    final request = await client.getUrl(Uri.parse(url));
    final response = await request.close();
    final body = await response.transform(utf8.decoder).join();
    return jsonDecode(body) as Map<String, dynamic>;
  } finally {
    client.close();
  }
}

/// 구분선 출력
void printSeparator(String title) {
  //// print('');
  //// print('=' * 50);
  //// print(title);
  //// print('=' * 50);
}

/// JSON을 보기 좋게 출력
void printJson(Map<String, dynamic> json) {
  final encoder = JsonEncoder.withIndent('  ');
  //// print(encoder.convert(json));
}

Future<void> main() async {
  //// print('');
  //// print('Frankfurter API Test (Dart)');
  //// print('');

  try {
    // 1. 최신 환율 (EUR 기준)
    //// printSeparator('1. Latest Rates (EUR base)');
    final latest = await fetchJson('$baseUrl/latest');
    //// printJson(latest);

    // 2. USD 기준 KRW, PHP 환율
    //// printSeparator('2. USD -> KRW, PHP');
    final usdRates = await fetchJson(
      '$baseUrl/latest?base=USD&symbols=KRW,PHP',
    );
    //// printJson(usdRates);

    // 3. 100 USD를 KRW로 변환
    //// printSeparator('3. Convert 100 USD to KRW');
    final converted = await fetchJson(
      '$baseUrl/latest?base=USD&symbols=KRW&amount=100',
    );
    //// printJson(converted);

    // 변환 결과 출력
    if (converted['rates'] != null && converted['rates']['KRW'] != null) {
      final krwAmount = converted['rates']['KRW'];
      //// print('');
      //// print('Result: 100 USD = $krwAmount KRW');
    }

    // 4. 특정 날짜 환율
    //// printSeparator('4. Historical Rate (2024-01-15)');
    final historical = await fetchJson(
      '$baseUrl/2024-01-15?base=USD&symbols=KRW',
    );
    //// printJson(historical);

    // 5. 지원 통화 목록
    //// printSeparator('5. Supported Currencies');
    final currencies = await fetchJson('$baseUrl/currencies');
    //// printJson(currencies);

    // 통화 개수 출력
    //// print('');
    //// print('Total currencies: ${currencies.length}');

    // 6. PHP 기준 KRW, USD 환율 (필고 앱에서 주로 사용)
    //// printSeparator('6. PHP -> KRW, USD (PhilGo use case)');
    final phpRates = await fetchJson(
      '$baseUrl/latest?base=PHP&symbols=KRW,USD',
    );
    //// printJson(phpRates);

    // 7. KRW 기준 PHP, USD 환율
    //// printSeparator('7. KRW -> PHP, USD');
    final krwRates = await fetchJson(
      '$baseUrl/latest?base=KRW&symbols=PHP,USD',
    );
    //// printJson(krwRates);

    //// print('');
    //// print('=' * 50);
    //// print('All tests completed successfully!');
    //// print('=' * 50);
    //// print('');
  } catch (e) {
    //// print('Error: $e');
    exit(1);
  }
}
