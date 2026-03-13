Firebase Crashlytics 개발 가이드
====
Flutter 앱에서 Firebase Crashlytics를 설정하고 사용하는 방법을 설명합니다.

## 육하원칙 (5W1H)

| 항목 | 설명 |
|------|------|
| **What** | 실시간 크래시 리포팅 도구 - 앱에서 발생하는 에러와 크래시를 자동으로 수집 |
| **Why** | 사용자가 겪는 에러를 추적하여 앱 안정성 향상 및 문제 해결 |
| **When** | 프로덕션 앱에서 크래시 모니터링 필요 시 |
| **Where** | Firebase Console → Crashlytics 대시보드에서 확인 |
| **Who** | 개발팀이 사용자 문제를 분석하고 우선순위 결정 |
| **How** | SDK 통합 + 에러 핸들러 설정 + 사용자 식별 |

---

## 1. 설치

```bash
# 의존성 추가
flutter pub add firebase_crashlytics firebase_analytics

# Firebase 설정 (flutterfire CLI 사용)
flutterfire configure
```

**pubspec.yaml 확인:**
```yaml
dependencies:
  firebase_crashlytics: ^4.3.10
  firebase_analytics: ^11.6.0
```

---

## 2. 플랫폼별 설정

### Android

`android/app/build.gradle.kts`에 Crashlytics 플러그인 추가:

```kotlin
plugins {
    id("com.android.application")
    id("com.google.gms.google-services")
    id("com.google.firebase.crashlytics")  // Crashlytics 플러그인
    id("kotlin-android")
    id("dev.flutter.flutter-gradle-plugin")
}
```

### iOS

Flutter 3.12.0+ 및 Crashlytics 플러그인 3.3.4+ 사용 시 dSYM 파일이 자동으로 업로드됩니다.

---

## 3. 초기화 코드 (main.dart)

```dart
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_crashlytics/firebase_crashlytics.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Firebase 초기화
  await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform);

  // Flutter 프레임워크에서 발생하는 치명적 에러를 Crashlytics로 전달
  FlutterError.onError = FirebaseCrashlytics.instance.recordFlutterFatalError;

  // Flutter 프레임워크에서 처리하지 못한 비동기 에러를 Crashlytics로 전달
  PlatformDispatcher.instance.onError = (error, stack) {
    FirebaseCrashlytics.instance.recordError(error, stack, fatal: true);
    return true;
  };

  runApp(MyApp());
}
```

---

## 4. 사용자 식별

로그인한 사용자를 크래시와 연결하여 특정 사용자의 문제를 추적:

```dart
// 로그인 시 사용자 식별자 설정
FirebaseCrashlytics.instance.setUserIdentifier(user.uid);

// 로그아웃 시 식별자 초기화
FirebaseCrashlytics.instance.setUserIdentifier('');
```

**philgo_app 적용 예시:**
```dart
UserService.instance.initialize(
  onStateChange: (user) {
    if (user != null) {
      FirebaseCrashlytics.instance.setUserIdentifier(user.uid);
    } else {
      FirebaseCrashlytics.instance.setUserIdentifier('');
    }
  },
);
```

---

## 5. 수동 에러 보고

치명적이지 않은 에러도 수동으로 보고 가능:

```dart
try {
  // 에러 발생 가능 코드
} catch (e, stackTrace) {
  // 비치명적 에러 보고 (fatal: false)
  FirebaseCrashlytics.instance.recordError(e, stackTrace, fatal: false);
}
```

---

## 6. 테스트 크래시 발생

설정이 제대로 되었는지 확인:

```dart
TextButton(
  onPressed: () => throw Exception('Test Crash'),
  child: Text("테스트 크래시 발생"),
)
```

**확인 방법:**
1. 앱 빌드 후 실행
2. 테스트 크래시 버튼 클릭
3. 앱 재시작
4. Firebase Console → Crashlytics에서 크래시 확인 (최대 5분 소요)

---

## 7. Shorebird iOS dSYM 업로드

Shorebird로 빌드 시 **Missing dSYM** 경고 해결 방법:

### Step 1: xcarchive 찾기
```bash
cd <프로젝트_폴더>
find . -name "*.xcarchive" -maxdepth 6
```
가장 최근 릴리즈 빌드의 `.xcarchive` 선택

### Step 2: dSYMs zip 생성
```bash
cd <찾은_xcarchive_경로>
zip -r dSYMs.zip dSYMs
```

### Step 3: Firebase Console 업로드
1. Firebase Console → Crashlytics 이동
2. **Upload dSYM** 클릭
3. `dSYMs.zip` 파일 업로드

### 성공 확인
크래시 스택이 `0x0000...` 주소에서 **함수명/파일명/라인번호**로 변환되면 성공

---

## 8. 디버그 심볼 업로드 (난독화 빌드)

`--split-debug-info` 플래그 사용 시:

```bash
firebase crashlytics:symbols:upload \
  --app=FIREBASE_APP_ID \
  PATH/TO/symbols
```

**중요:** 크래시 보고 전에 반드시 심볼 업로드 필요

---

## 참고 자료

- [Firebase Crashlytics 공식 문서](https://firebase.google.com/docs/crashlytics/flutter/get-started)
- [Crashlytics Flutter Plugin](https://pub.dev/packages/firebase_crashlytics)
