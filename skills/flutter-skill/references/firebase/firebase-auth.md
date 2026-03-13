Firebase Auth 개발 관련 문서
====

## 개요

이 문서는 센터 프로젝트에서 Firebase Authentication을 사용할 때 필요한 설정과 에러 처리 방법을 설명합니다.

## Email Enumeration Protection 설정

### Email Enumeration Protection이란?

Firebase에서 제공하는 보안 기능으로, 악의적인 사용자가 이메일 주소를 통해 등록된 사용자를 열거(enumerate)하는 것을 방지합니다.

### 설정에 따른 에러 코드 차이

| 설정 상태 | 에러 코드 | 설명 |
|-----------|-----------|------|
| **Protection 켜짐** (기본값) | `invalid-credential` | 모호한 에러 코드 반환. 이메일 존재 여부를 알 수 없음 |
| **Protection 꺼짐** | `user-not-found` | 해당 이메일로 등록된 계정이 없음 |
| **Protection 꺼짐** | `wrong-password` | 이메일은 존재하지만 비밀번호가 틀림 |

### Firebase Console 설정 방법

1. [Firebase Console](https://console.firebase.google.com/)에 접속
2. 프로젝트 선택
3. **Authentication** 메뉴 클릭
4. **Settings** 탭 선택
5. **User actions** 섹션으로 이동
6. **Email enumeration protection** 토글을 끔 (Disable)

```
경로: Firebase Console → Authentication → Settings → User actions → Email enumeration protection
```

### 개발/프로덕션 환경 권장 설정

| 환경 | 권장 설정 | 이유 |
|------|-----------|------|
| **개발 환경** | Protection 끄기 | 구체적인 에러 메시지로 디버깅 용이 |
| **프로덕션 환경** | Protection 켜기 | 보안 강화 (이메일 열거 공격 방지) |

## 에러 처리

### handleError() 함수

센터 프로젝트에서는 `handleError()` 함수를 통해 Firebase Auth 에러를 일관되게 처리합니다.

**소스 코드 위치**: [lib/functions/util.functions.dart](lib/functions/util.functions.dart)

### 지원되는 Firebase Auth 에러 코드

| 에러 코드 | 번역 키 | 설명 |
|-----------|---------|------|
| `invalid-email` | `errorInvalidEmail` | 이메일 형식이 올바르지 않음 |
| `invalid-credential` | `errorInvalidCredential` | 로그인 정보가 올바르지 않음 (Email enumeration protection 활성화 시) |
| `user-disabled` | `errorUserDisabled` | 계정이 비활성화됨 |
| `user-not-found` | `errorUserNotFound` | 해당 이메일로 등록된 계정이 없음 |
| `wrong-password` | `errorWrongPassword` | 비밀번호가 틀림 |
| `email-already-in-use` | `errorEmailAlreadyInUse` | 이미 등록된 이메일 |
| `operation-not-allowed` | `errorOperationNotAllowed` | 허용되지 않은 작업 |
| `weak-password` | `errorWeakPassword` | 비밀번호가 너무 약함 |

### 사용 예시

```dart
try {
  await FirebaseAuth.instance.signInWithEmailAndPassword(
    email: email,
    password: password,
  );
} catch (e) {
  handleError(context, e);
}
```

## iOS Phone Auth (전화번호 인증)

### 동작 원리

Firebase Phone Auth는 iOS에서 다음 순서로 동작한다:

1. `verifyPhoneNumber()` 호출
2. Firebase Auth SDK 내부에서 `checkNotificationForwarding()` 실행
   - fake "prober" notification을 `application.delegate`에 전송
   - `canHandleNotification()`이 1초 내에 호출되는지 확인
   - 실패 시 `notification-not-forwarded` 에러 발생
3. notification forwarding 통과 후 `appVerificationDisabledForTesting` 확인
4. reCAPTCHA 또는 APNs silent push로 앱 검증
5. Firebase 서버에 SMS 전송 요청
6. `codeSent` 콜백으로 verificationId 반환

### Flutter 3.41+ Scene-based Lifecycle 문제

Flutter 3.41+에서 Scene-based lifecycle(`FlutterSceneDelegate`)을 사용하면, Firebase Auth SDK의 내부 notification forwarding 체크가 정상 동작하지 않는다. SDK가 fake prober notification을 `application.delegate`에 보내지만, Scene-based lifecycle에서 이 notification이 AppDelegate의 `didReceiveRemoteNotification`에 도달하지 못한다.

**증상**: `verifyPhoneNumber` 호출 시 즉시 `notification-not-forwarded` 에러 발생

### 해결 방법: Fake Prober Notification 사전 등록

AppDelegate의 `didFinishLaunchingWithOptions`에서 Firebase 초기화 직후, Firebase Auth의 `canHandleNotification()`에 fake prober notification을 직접 전달하여 SDK 내부의 `checkNotificationForwarding()` 체크를 사전 통과시킨다.

### AppDelegate.swift 설정 (필수)

```swift
import Flutter
import UIKit
import FirebaseCore
import FirebaseAuth
import FirebaseMessaging

@main
@objc class AppDelegate: FlutterAppDelegate, FlutterImplicitEngineDelegate {
  override func application(
    _ application: UIApplication,
    didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]?
  ) -> Bool {
    // 1. Firebase를 native에서 먼저 초기화
    FirebaseApp.configure()

    // 2. Firebase Auth의 checkNotificationForwarding() 체크를 사전 통과시킴
    //    Scene-based lifecycle(Flutter 3.41+)에서 SDK 내부 notification forwarding 체크가
    //    정상 동작하지 않으므로, 앱 시작 시 직접 prober notification을 Auth에 전달
    let fakeProber: [AnyHashable: Any] = [
      "com.google.firebase.auth": ["warning": "This fake notification should be forwarded to Firebase Auth."]
    ]
    let _ = Auth.auth().canHandleNotification(fakeProber)

    // 3. APNs 등록 요청
    application.registerForRemoteNotifications()

    return super.application(application, didFinishLaunchingWithOptions: launchOptions)
  }

  func didInitializeImplicitFlutterEngine(_ engineBridge: FlutterImplicitEngineBridge) {
    GeneratedPluginRegistrant.register(with: engineBridge.pluginRegistry)
  }

  // APNs 토큰을 Firebase Auth와 Messaging에 수동 전달
  override func application(
    _ application: UIApplication,
    didRegisterForRemoteNotificationsWithDeviceToken deviceToken: Data
  ) {
    Auth.auth().setAPNSToken(deviceToken, type: .unknown)
    Messaging.messaging().apnsToken = deviceToken
    super.application(application, didRegisterForRemoteNotificationsWithDeviceToken: deviceToken)
  }

  override func application(
    _ application: UIApplication,
    didFailToRegisterForRemoteNotificationsWithError error: Error
  ) {
    super.application(application, didFailToRegisterForRemoteNotificationsWithError: error)
  }

  // Remote notification을 Firebase Auth와 Messaging에 전달
  override func application(
    _ application: UIApplication,
    didReceiveRemoteNotification userInfo: [AnyHashable: Any],
    fetchCompletionHandler completionHandler: @escaping (UIBackgroundFetchResult) -> Void
  ) {
    if Auth.auth().canHandleNotification(userInfo) {
      completionHandler(.noData)
      return
    }
    Messaging.messaging().appDidReceiveMessage(userInfo)
    super.application(application, didReceiveRemoteNotification: userInfo, fetchCompletionHandler: completionHandler)
  }
}
```

### Info.plist 설정

```xml
<!-- Firebase Messaging의 method swizzling 비활성화 (수동 처리) -->
<key>FirebaseAppDelegateProxyEnabled</key>
<false/>

<!-- 백그라운드 모드 - 원격 알림 수신 필수 -->
<key>UIBackgroundModes</key>
<array>
  <string>remote-notification</string>
  <string>fetch</string>
</array>
```

### Runner.entitlements 설정

Push Notification capability가 활성화되어 있어야 한다:

```xml
<key>aps-environment</key>
<string>development</string>
```

### Firebase Console 설정

- Authentication > Sign-in method에서 **Phone** 인증 활성화
- Project Settings > Cloud Messaging에서 **APNs Authentication Key** 업로드

### Phone Auth 에러 코드

| 에러 코드 | 원인 | 해결 방법 |
|-----------|------|-----------|
| `notification-not-forwarded` | AppDelegate에서 notification이 Firebase Auth로 전달되지 않음 | fake prober notification 사전 등록 (위 AppDelegate 코드 참조) |
| `missing-client-identifier` | 클라이언트 식별자(APNs 토큰 또는 reCAPTCHA) 없음 | `appVerificationDisabledForTesting` 제거, 정상적인 APNs/reCAPTCHA 사용 |
| `invalid-phone-number` | 전화번호 형식 오류 | E.164 형식 사용 (예: `+821012345678`) |
| `too-many-requests` | SMS 전송 한도 초과 | Firebase Console에서 할당량 확인 |
| `quota-exceeded` | 프로젝트 SMS 할당량 초과 | Firebase 유료 플랜으로 업그레이드 |

### appVerificationDisabledForTesting 주의사항

- 이 설정은 **reCAPTCHA 검증만 건너뛰며**, notification forwarding 체크는 우회하지 않음
- 프로덕션에서는 절대 사용하지 말 것
- 시뮬레이터에서도 fake prober 사전 등록이 있으면 불필요

### easy_phone_sign_in 패키지

PhilGo 앱에서 사용하는 전화번호 인증 패키지.

**위치**: `packages/easy_phone_sign_in/`

```dart
PhoneSignIn(
  debug: true, // 디버그 로그 활성화
  onCompletePhoneNumber: (String phoneNumber) {
    // 로컬 입력을 E.164 국제 형식으로 변환
    if (phoneNumber.startsWith('10')) return '+82$phoneNumber'; // 한국
    if (phoneNumber.startsWith('9')) return '+63$phoneNumber';  // 필리핀
    return phoneNumber;
  },
  onValidatePhoneNumber: (String phoneNumber) {
    // null 반환 시 유효, String 반환 시 에러 메시지
    if (phoneNumber.startsWith('+82')) return null;
    if (phoneNumber.startsWith('+63')) return null;
    return '허용되지 않은 전화번호입니다';
  },
  onSignInSuccess: () { /* 로그인 성공 처리 */ },
  onSignInFailed: (FirebaseAuthException error) { /* 에러 표시 */ },
  specialAccounts: const SpecialAccounts(
    reviewEmail: 'review@email.com',
    reviewPassword: '12345zB,*c',
    reviewPhoneNumber: '+11234567890',
    reviewSmsCode: '123456',
    emailLogin: true,
  ),
)
```

## 관련 소스 코드

- 에러 처리 함수: [lib/functions/util.functions.dart](lib/functions/util.functions.dart)
- 로그인 화면: [lib/screens/entry/entry.login.screen.dart](lib/screens/entry/entry.login.screen.dart)
- iOS AppDelegate: [ios/Runner/AppDelegate.swift](ios/Runner/AppDelegate.swift)
- iOS Info.plist: [ios/Runner/Info.plist](ios/Runner/Info.plist)
- iOS Entitlements: [ios/Runner/Runner.entitlements](ios/Runner/Runner.entitlements)
- Phone Sign In 패키지: [packages/easy_phone_sign_in/](packages/easy_phone_sign_in/)
- 다국어 번역 (한국어): [lib/l10n/app_ko.arb](lib/l10n/app_ko.arb)
- 다국어 번역 (영어): [lib/l10n/app_en.arb](lib/l10n/app_en.arb)
- 다국어 번역 (일본어): [lib/l10n/app_ja.arb](lib/l10n/app_ja.arb)
- 다국어 번역 (중국어): [lib/l10n/app_zh.arb](lib/l10n/app_zh.arb)

## 참고 자료

- [Firebase Authentication 공식 문서](https://firebase.google.com/docs/auth)
- [Firebase Phone Auth iOS 설정](https://firebase.google.com/docs/auth/ios/phone-auth)
- [Email enumeration protection 공식 문서](https://cloud.google.com/identity-platform/docs/admin/email-enumeration-protection)
