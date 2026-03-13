# Share Plus - Flutter 공유 기능 가이드

## Table of Contents

- [Overview](#overview)
- [Workflow](#workflow)
- [설치](#설치)
- [지원 플랫폼](#지원-플랫폼)
- [핵심 API](#핵심-api)
- [사용 패턴](#사용-패턴)
- [플랫폼별 설정](#플랫폼별-설정)
- [게시글 공유 구현 패턴](#게시글-공유-구현-패턴)
- [에러 처리](#에러-처리)
- [마이그레이션 가이드](#마이그레이션-가이드)
- [Best Practices](#best-practices)

## Overview

`share_plus`는 Flutter에서 텍스트, URI, 파일 등을 OS 네이티브 공유 시트(Share Sheet)를 통해 외부 앱으로 공유할 수 있게 해주는 패키지입니다.

- **pub.dev**: [share_plus](https://pub.dev/packages/share_plus)
- **최신 버전**: 12.0.1
- **필수 환경**: Flutter ≥3.22.0, Dart ≥3.4.0

## Workflow

공유 기능 구현 시 아래 순서를 따릅니다:

1. **설치**: pubspec.yaml에 패키지 추가
2. **플랫폼 설정**: iPad sharePositionOrigin, iOS 로컬라이제이션 등 확인
3. **공유 버튼 UI**: Comic 디자인 가이드라인에 맞는 공유 버튼 배치
4. **공유 로직 구현**: SharePlus.instance.share() 호출
5. **결과 처리**: ShareResult 상태에 따른 피드백

## 설치

```yaml
dependencies:
  share_plus: ^12.0.1
```

```bash
flutter pub get
```

## 지원 플랫폼

| 플랫폼 | 텍스트 | URI | 파일 |
|--------|--------|-----|------|
| Android | ✅ | ✅ | ✅ |
| iOS | ✅ | ✅ | ✅ |
| macOS | ✅ | ✅ | ✅ |
| Web | ✅ | 텍스트로 변환 | ✅ |
| Linux | ✅ | 텍스트로 변환 | ❌ |
| Windows | ✅ | 텍스트로 변환 | ✅ |

## 핵심 API

### SharePlus (싱글톤 인스턴스)

```dart
import 'package:share_plus/share_plus.dart';

// 싱글톤 접근
SharePlus.instance.share(ShareParams(...));
```

### ShareParams (공유 파라미터)

| 파라미터 | 타입 | 설명 |
|----------|------|------|
| `text` | `String?` | 공유할 텍스트 |
| `title` | `String?` | 공유 시트 제목 |
| `subject` | `String?` | 이메일 제목 |
| `files` | `List<XFile>?` | 공유할 파일 목록 |
| `uri` | `Uri?` | 공유할 URI |
| `sharePositionOrigin` | `Rect?` | iPad 팝오버 위치 (iPad 필수) |
| `excludedCupertinoActivities` | `List?` | iOS/macOS 제외 활동 |
| `downloadFallbackEnabled` | `bool?` | 웹 다운로드 폴백 |

### ShareResult (공유 결과)

| 속성 | 타입 | 설명 |
|------|------|------|
| `status` | `ShareResultStatus` | 공유 결과 상태 |
| `raw` | `String` | 상세 결과 문자열 |

### ShareResultStatus (결과 상태)

| 상태 | 설명 |
|------|------|
| `success` | 공유 성공 |
| `dismissed` | 사용자가 공유 시트를 닫음 (취소) |
| `unavailable` | 해당 플랫폼에서 결과 확인 불가 |

## 사용 패턴

### 1. 텍스트 공유 (가장 기본)

```dart
import 'package:share_plus/share_plus.dart';

/// 텍스트를 외부 앱으로 공유
Future<void> shareText(String text) async {
  final result = await SharePlus.instance.share(
    ShareParams(text: text),
  );

  if (result.status == ShareResultStatus.success) {
    // 공유 성공 처리
  }
}
```

### 2. URL 텍스트 공유

```dart
/// URL을 포함한 텍스트 공유
Future<void> shareUrl(String title, String url) async {
  await SharePlus.instance.share(
    ShareParams(
      text: '$title\n$url',
      subject: title, // 이메일로 공유 시 제목으로 사용
    ),
  );
}
```

### 3. URI 공유

```dart
/// URI 객체를 직접 공유
Future<void> shareUri(Uri uri) async {
  await SharePlus.instance.share(
    ShareParams(uri: uri),
  );
}
```

### 4. 파일 공유

```dart
import 'package:cross_file/cross_file.dart';

/// 단일 파일 공유
Future<void> shareFile(String filePath) async {
  await SharePlus.instance.share(
    ShareParams(
      text: '파일을 공유합니다',
      files: [XFile(filePath)],
    ),
  );
}
```

### 5. 다중 파일 공유

```dart
/// 여러 파일을 한 번에 공유
Future<void> shareMultipleFiles(List<String> filePaths) async {
  await SharePlus.instance.share(
    ShareParams(
      files: filePaths.map((path) => XFile(path)).toList(),
    ),
  );
}
```

### 6. 동적 데이터 공유 (메모리에서 직접)

```dart
import 'dart:convert';

/// 메모리에 있는 데이터를 파일로 공유
Future<void> shareDynamicData(String content) async {
  await SharePlus.instance.share(
    ShareParams(
      files: [
        XFile.fromData(
          utf8.encode(content),
          mimeType: 'text/plain',
        ),
      ],
      fileNameOverrides: ['shared_content.txt'],
    ),
  );
}
```

### 7. iPad 호환 공유 (필수)

```dart
/// iPad에서 공유 시트 위치 지정 (iPad에서 필수)
/// iPad에서 sharePositionOrigin 없으면 크래시 발생 가능
Future<void> shareWithPosition(BuildContext context, String text) async {
  final box = context.findRenderObject() as RenderBox?;
  await SharePlus.instance.share(
    ShareParams(
      text: text,
      sharePositionOrigin: box != null
          ? box.localToGlobal(Offset.zero) & box.size
          : null,
    ),
  );
}
```

## 플랫폼별 설정

### iPad (필수)

iPad에서 공유 시트는 팝오버(popover)로 표시되므로 `sharePositionOrigin`이 필수입니다. 미지정 시 iOS 26 이상에서 크래시가 발생할 수 있습니다.

```dart
// 버튼의 RenderBox를 사용하여 위치 지정
final box = context.findRenderObject() as RenderBox?;
final sharePositionOrigin = box != null
    ? box.localToGlobal(Offset.zero) & box.size
    : null;
```

### iOS/macOS 로컬라이제이션

공유 시트 UI의 다국어 지원을 위해 `Info.plist`에 아래 설정 추가:

```xml
<key>CFBundleAllowMixedLocalizations</key>
<true/>
<key>CFBundleDevelopmentRegion</key>
<string>ko</string>
```

### Android

Android 14(API 34) 이상에서는 공유 결과(ShareResult)를 정확히 받을 수 있습니다. 이전 버전에서는 `unavailable`이 반환될 수 있습니다.

**필수 빌드 환경:**
- Android Gradle Plugin ≥ 8.12.1
- Gradle wrapper ≥ 8.13
- Kotlin 2.2.0
- Java 17

### Facebook 공유 제한

Meta의 정책으로 인해 Facebook 앱으로의 텍스트 공유가 불안정합니다. Facebook 공유가 필요한 경우 Facebook SDK를 별도로 사용해야 합니다.

## 게시글 공유 구현 패턴

게시판(Forum) 앱에서 게시글 공유 버튼을 구현하는 표준 패턴입니다.

### 공유 헬퍼 함수

```dart
import 'package:flutter/material.dart';
import 'package:share_plus/share_plus.dart';

/// 게시글 공유 함수
///
/// [context] 위젯 컨텍스트 (iPad sharePositionOrigin 계산에 필요)
/// [title] 게시글 제목
/// [url] 게시글 URL
/// [description] 게시글 요약 (선택)
Future<ShareResult> sharePost({
  required BuildContext context,
  required String title,
  required String url,
  String? description,
}) async {
  // 공유할 텍스트 구성
  final buffer = StringBuffer();
  buffer.writeln(title);
  if (description != null && description.isNotEmpty) {
    buffer.writeln(description);
  }
  buffer.writeln(url);

  // iPad 팝오버 위치 계산
  final box = context.findRenderObject() as RenderBox?;
  final origin = box != null
      ? box.localToGlobal(Offset.zero) & box.size
      : null;

  return SharePlus.instance.share(
    ShareParams(
      text: buffer.toString(),
      subject: title,
      sharePositionOrigin: origin,
    ),
  );
}
```

### Comic 스타일 공유 버튼 위젯

```dart
import 'package:flutter/material.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:share_plus/share_plus.dart';

/// Comic 스타일 공유 버튼
/// ComicActionButton 위젯과 동일한 스타일로 공유 버튼을 제공합니다.
class ShareButton extends StatelessWidget {
  const ShareButton({
    super.key,
    required this.title,
    required this.url,
    this.description,
  });

  /// 공유할 게시글 제목
  final String title;

  /// 공유할 URL
  final String url;

  /// 공유할 설명 (선택)
  final String? description;

  @override
  Widget build(BuildContext context) {
    return ComicActionButton(
      icon: FontAwesomeIcons.shareNodes,
      onPressed: () => _onShare(context),
    );
  }

  Future<void> _onShare(BuildContext context) async {
    try {
      final result = await sharePost(
        context: context,
        title: title,
        url: url,
        description: description,
      );

      if (!context.mounted) return;

      if (result.status == ShareResultStatus.success) {
        // 공유 성공 시 피드백 (선택)
        showSuccessSnackBar(context, '공유되었습니다');
      }
    } catch (e) {
      if (context.mounted) {
        showErrorSnackBar(context, '공유 중 오류가 발생했습니다');
      }
    }
  }
}
```

### PostViewButtons에 공유 버튼 추가 예시

```dart
/// 기존 PostViewButtons의 Row에 공유 버튼을 추가하는 패턴
Row(
  children: [
    // ... 기존 좋아요, 답글 버튼들

    /// 공유 버튼
    ComicActionButton(
      icon: FontAwesomeIcons.shareNodes,
      onPressed: () async {
        // 게시글 URL 구성
        final postUrl = 'https://philgo.com/post/${post.idx}';

        final box = context.findRenderObject() as RenderBox?;
        await SharePlus.instance.share(
          ShareParams(
            text: '${post.subject}\n$postUrl',
            subject: post.subject,
            sharePositionOrigin: box != null
                ? box.localToGlobal(Offset.zero) & box.size
                : null,
          ),
        );
      },
    ),

    // ... 기존 버튼들 계속
  ],
)
```

### PopupMenu에 공유 항목 추가 예시

```dart
/// 점세개 옵션 메뉴에 공유 항목 추가 패턴
PopupMenuItem(
  value: MenuAction.share,
  child: Row(
    children: [
      const FaIcon(FontAwesomeIcons.shareNodes, size: 16),
      const SizedBox(width: 12),
      Text(Lo.of(context)!.share),
    ],
  ),
),
```

## 에러 처리

### 공통 에러 상황 및 처리

```dart
Future<void> safeShare(BuildContext context, String text) async {
  try {
    final result = await SharePlus.instance.share(
      ShareParams(text: text),
    );

    if (!context.mounted) return;

    switch (result.status) {
      case ShareResultStatus.success:
        // 공유 완료 (로그 기록 등)
        break;
      case ShareResultStatus.dismissed:
        // 사용자가 공유 시트를 닫음 - 별도 처리 불필요
        break;
      case ShareResultStatus.unavailable:
        // 플랫폼에서 결과를 확인할 수 없음 (일부 Android 버전)
        break;
    }
  } on MissingPluginException {
    // 플러그인 미등록 (드물게 발생)
    debugPrint('share_plus 플러그인이 등록되지 않았습니다');
  } catch (e) {
    // 기타 예외
    debugPrint('공유 중 오류: $e');
    if (context.mounted) {
      showErrorSnackBar(context, '공유할 수 없습니다');
    }
  }
}
```

## 마이그레이션 가이드

### v11 이전 → v12 마이그레이션

```dart
// ❌ 이전 방식 (v11 이전) - deprecated
Share.share('Shared text');
Share.shareXFiles([XFile('path/to/file')]);

// ✅ 현재 방식 (v12)
SharePlus.instance.share(ShareParams(text: 'Shared text'));
SharePlus.instance.share(ShareParams(files: [XFile('path/to/file')]));
```

### 주요 변경 사항

| 이전 (v11 이전) | 현재 (v12) |
|-----------------|-----------|
| `Share.share(text)` | `SharePlus.instance.share(ShareParams(text: text))` |
| `Share.shareXFiles(files)` | `SharePlus.instance.share(ShareParams(files: files))` |
| `Share.shareWithResult(text)` | `SharePlus.instance.share(ShareParams(text: text))` (결과 항상 반환) |

## Best Practices

1. **항상 sharePositionOrigin 제공**: iPad 크래시 방지를 위해 항상 `context.findRenderObject()`를 사용하여 위치를 전달합니다.

2. **결과 처리는 선택적**: `ShareResultStatus.dismissed`는 무시해도 됩니다. 사용자가 취소한 것이므로 별도 피드백이 불필요합니다.

3. **context.mounted 확인**: 비동기 공유 완료 후 반드시 `context.mounted`를 확인합니다.

4. **i18n 사용**: 공유 관련 텍스트(버튼 레이블, 성공/실패 메시지)는 반드시 i18n 번역을 사용합니다.

5. **Theme 기반 스타일링**: 공유 버튼의 아이콘 색상, 크기는 Theme.of(context)를 사용합니다.

6. **Font Awesome 아이콘**: 공유 아이콘은 `FontAwesomeIcons.shareNodes` (Light 우선) 사용을 권장합니다.

7. **Facebook 공유 주의**: Meta 정책으로 Facebook 공유가 불안정하므로, 별도 대응이 필요한 경우 Facebook SDK를 사용합니다.
