# Firebase FCM Push Notification 통합 가이드

Flutter 앱에서 Firebase Cloud Messaging(FCM)을 사용한 푸시 알림 구현 가이드입니다.

## 목차

- [개요](#개요)
- [서버 환경 설정](#서버-환경-설정)
- [Flutter 클라이언트 설정](#flutter-클라이언트-설정)
- [Android Head-up Display 알림](#android-head-up-display-알림)
- [PhilGo 앱 구현 사례](#philgo-앱-구현-사례)
- [베스트 프랙티스](#베스트-프랙티스)
- [트러블슈팅](#트러블슈팅)

---

## 개요

### FCM이란?

Firebase Cloud Messaging(FCM)은 Google이 제공하는 무료 크로스 플랫폼 메시징 솔루션입니다. 서버에서 클라이언트 앱으로 알림 메시지와 데이터 메시지를 안정적으로 전송할 수 있습니다.

### 메시지 타입

FCM은 두 가지 유형의 메시지를 지원합니다:

| 메시지 타입 | 설명 | 처리 방식 |
|------------|------|----------|
| **Notification 메시지** | 사전 정의된 필드(title, body) 포함 | 시스템이 자동으로 알림 표시 |
| **Data 메시지** | 사용자 정의 키-값 쌍 | 앱 코드에서 직접 처리 |
| **혼합 메시지** | Notification + Data 모두 포함 | 앱 상태에 따라 다르게 처리 |

```json
{
  "notification": {
    "title": "새 메시지",
    "body": "채팅방에 새 메시지가 도착했습니다"
  },
  "data": {
    "roomId": "chat_room_123",
    "type": "chat_message"
  }
}
```

### 디바이스 상태별 동작

FCM 메시지 처리는 앱의 실행 상태에 따라 달라집니다:

| 상태 | 설명 | Notification 메시지 | Data 메시지 |
|------|------|---------------------|-------------|
| **Foreground** | 앱이 화면에 활성화됨 | `onMessage` 스트림으로 수신 | `onMessage` 스트림으로 수신 |
| **Background** | 앱이 최소화됨 | 시스템 트레이에 자동 표시 | `onBackgroundMessage` 핸들러 |
| **Terminated** | 앱이 완전히 종료됨 | 시스템 트레이에 자동 표시 | `onBackgroundMessage` 핸들러 |

---

## 서버 환경 설정

> 출처: [Firebase Cloud Messaging Server Environment](https://firebase.google.com/docs/cloud-messaging/server-environment)

### FCM 아키텍처

FCM 서버는 두 가지 핵심 구성요소로 이루어집니다:

```
┌─────────────────┐     ┌─────────────────┐     ┌─────────────────┐
│   앱 서버       │ --> │  FCM 백엔드     │ --> │  클라이언트 앱  │
│ (Admin SDK 등) │     │ (Google 서버)   │     │  (iOS/Android)  │
└─────────────────┘     └─────────────────┘     └─────────────────┘
```

1. **앱 서버 또는 신뢰할 수 있는 서버 환경**: Cloud Functions, 자체 서버 등에서 실행되는 서버 로직
2. **Google의 FCM 백엔드**: 메시지 라우팅 담당

### 메시지 전송 대상

Firebase Admin SDK 또는 FCM 프로토콜을 사용하여 다음 대상으로 메시지를 전송할 수 있습니다:

| 전송 대상 | 설명 | 사용 예시 |
|----------|------|----------|
| **Topic** | 특정 주제를 구독한 모든 기기 | 뉴스 알림, 공지사항 |
| **Condition** | 여러 토픽의 조합 조건 | `'TopicA' in topics && 'TopicB' in topics` |
| **등록 토큰** | 개별 기기 고유 토큰 | 1:1 채팅 알림 |
| **기기 그룹** | 여러 기기를 하나의 그룹으로 | 한 사용자의 여러 기기 |

### 필수 자격증명

| 자격증명 | 설명 | 획득 방법 |
|---------|------|----------|
| **프로젝트 ID** | Firebase 프로젝트 고유 식별자 | Firebase Console > 프로젝트 설정 |
| **등록 토큰** | 각 클라이언트 앱 인스턴스 식별 토큰 | `FirebaseMessaging.instance.getToken()` |
| **발신자 ID** | Firebase 프로젝트 생성 시 자동 생성 | Firebase Console > 프로젝트 설정 |
| **액세스 토큰** | HTTP v1 API 요청 승인용 OAuth 2.0 토큰 | 서비스 계정 키로 생성 |

### 서버 상호작용 방법

#### 1. Firebase Admin SDK (권장)

Node.js, Java, Python, C#, Go 지원. 개별 기기, 토픽, 조건 기반 메시지 전송 가능.

```javascript
// Node.js 예시
const admin = require('firebase-admin');

admin.initializeApp({
  credential: admin.credential.applicationDefault()
});

const message = {
  notification: {
    title: '새 메시지',
    body: '채팅방에 새 메시지가 도착했습니다'
  },
  data: {
    roomId: 'chat_room_123',
    type: 'chat_message'
  },
  token: 'device_registration_token'
};

admin.messaging().send(message);
```

#### 2. FCM HTTP v1 API

REST API 기반 접근 방식. POST 요청에 HTTP 헤더와 JSON 본문을 포함합니다.

```bash
POST https://fcm.googleapis.com/v1/projects/{project_id}/messages:send
Authorization: Bearer {access_token}
Content-Type: application/json

{
  "message": {
    "token": "device_token",
    "notification": {
      "title": "알림 제목",
      "body": "알림 내용"
    }
  }
}
```

---

## Flutter 클라이언트 설정

> 출처: [Receive messages in a Flutter app](https://firebase.google.com/docs/cloud-messaging/flutter/receive-messages)

### 패키지 설치

```yaml
dependencies:
  firebase_core: ^latest
  firebase_messaging: ^latest
```

### 권한 요청

iOS, macOS, Web, Android 13+ 에서는 메시지 수신 전 사용자 허가가 필수입니다.

```dart
import 'package:firebase_messaging/firebase_messaging.dart';

Future<void> requestPermission() async {
  NotificationSettings settings = await FirebaseMessaging.instance.requestPermission(
    alert: true,        // 알림 표시
    badge: true,        // 앱 아이콘 배지
    sound: true,        // 알림 소리
    announcement: false,
    carPlay: false,
    criticalAlert: false,
    provisional: false, // true면 임시 허가 (iOS)
  );

  // 권한 상태 확인
  switch (settings.authorizationStatus) {
    case AuthorizationStatus.authorized:
      print('사용자가 권한을 허용했습니다');
      break;
    case AuthorizationStatus.denied:
      print('사용자가 권한을 거부했습니다');
      break;
    case AuthorizationStatus.notDetermined:
      print('사용자가 아직 결정하지 않았습니다');
      break;
    case AuthorizationStatus.provisional:
      print('임시 권한이 부여되었습니다');
      break;
  }
}
```

### FCM 토큰 획득

```dart
// FCM 토큰 가져오기
String? token = await FirebaseMessaging.instance.getToken();
print('FCM Token: $token');

// 토큰 갱신 리스너
FirebaseMessaging.instance.onTokenRefresh.listen((newToken) {
  print('Token refreshed: $newToken');
  // 서버에 새 토큰 저장
});
```

### Foreground 메시지 처리

앱이 활성 상태일 때 메시지를 수신하려면 `onMessage` 스트림을 리스닝합니다:

```dart
FirebaseMessaging.onMessage.listen((RemoteMessage message) {
  print('Foreground 메시지 수신!');
  print('메시지 데이터: ${message.data}');

  if (message.notification != null) {
    print('제목: ${message.notification?.title}');
    print('내용: ${message.notification?.body}');
  }

  // 인앱 알림 표시 (SnackBar, Dialog 등)
  _showInAppNotification(message);
});
```

**주의**: Foreground 상태에서는 시스템 알림이 자동으로 표시되지 않습니다. 직접 인앱 알림을 구현해야 합니다.

### Background 메시지 처리

**중요**: Background 핸들러는 반드시 **top-level 함수**로 정의해야 합니다.

```dart
// ⚠️ 반드시 top-level 함수여야 함 (클래스 밖에 정의)
@pragma('vm:entry-point')
Future<void> _firebaseMessagingBackgroundHandler(RemoteMessage message) async {
  // Firebase 초기화 필수
  await Firebase.initializeApp();

  print('Background 메시지 처리: ${message.messageId}');
  print('데이터: ${message.data}');

  // 여기서 로컬 저장, 배지 업데이트 등 처리
}

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp();

  // Background 핸들러 등록 (runApp 전에 호출)
  FirebaseMessaging.onBackgroundMessage(_firebaseMessagingBackgroundHandler);

  runApp(MyApp());
}
```

**Background 핸들러 제약사항**:
- ❌ 익명 함수 사용 불가
- ❌ UI 업데이트 불가
- ⏱️ 30초 이내에 완료되어야 함
- ✅ 로컬 저장소 접근 가능
- ✅ HTTP 요청 가능

### Terminated 상태에서 앱 실행

앱이 완전히 종료된 상태에서 알림을 탭해 실행된 경우:

```dart
// 앱 시작 시 초기 메시지 확인
RemoteMessage? initialMessage = await FirebaseMessaging.instance.getInitialMessage();

if (initialMessage != null) {
  print('앱이 알림에서 실행됨: ${initialMessage.data}');
  // 해당 화면으로 네비게이션
  _handleMessageNavigation(initialMessage);
}
```

### 사용자 알림 탭 처리

Background 상태에서 사용자가 알림을 탭했을 때:

```dart
// Background에서 알림 탭 시 호출
FirebaseMessaging.onMessageOpenedApp.listen((RemoteMessage message) {
  print('알림 탭됨: ${message.data}');
  // 해당 화면으로 네비게이션
  _handleMessageNavigation(message);
});
```

### 전체 초기화 코드

```dart
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_messaging/firebase_messaging.dart';

// Top-level background handler
@pragma('vm:entry-point')
Future<void> _firebaseMessagingBackgroundHandler(RemoteMessage message) async {
  await Firebase.initializeApp();
  print('Background 메시지: ${message.messageId}');
}

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp();

  // 1. Background 핸들러 등록
  FirebaseMessaging.onBackgroundMessage(_firebaseMessagingBackgroundHandler);

  runApp(MyApp());
}

class MyApp extends StatefulWidget {
  @override
  _MyAppState createState() => _MyAppState();
}

class _MyAppState extends State<MyApp> {
  @override
  void initState() {
    super.initState();
    _setupFCM();
  }

  Future<void> _setupFCM() async {
    // 2. 권한 요청
    await FirebaseMessaging.instance.requestPermission();

    // 3. 토큰 획득 및 저장
    String? token = await FirebaseMessaging.instance.getToken();
    print('FCM Token: $token');

    // 4. Foreground 메시지 리스너
    FirebaseMessaging.onMessage.listen(_handleForegroundMessage);

    // 5. 알림 탭 리스너 (Background → Foreground)
    FirebaseMessaging.onMessageOpenedApp.listen(_handleMessageNavigation);

    // 6. Terminated 상태에서 실행된 경우
    RemoteMessage? initialMessage =
        await FirebaseMessaging.instance.getInitialMessage();
    if (initialMessage != null) {
      _handleMessageNavigation(initialMessage);
    }
  }

  void _handleForegroundMessage(RemoteMessage message) {
    // 인앱 알림 표시
  }

  void _handleMessageNavigation(RemoteMessage message) {
    // 해당 화면으로 이동
    final roomId = message.data['roomId'];
    if (roomId != null) {
      Navigator.pushNamed(context, '/chat/$roomId');
    }
  }

  @override
  Widget build(BuildContext context) => MaterialApp(...);
}
```

---

## Android Head-up Display 알림

Android에서 FCM 푸시 알림을 화면 상단에 배너(Head-up Display, Heads-up Notification) 형태로 표시하는 방법입니다.

### Head-up Display란?

Head-up Display(HUD) 알림은 사용자가 다른 앱을 사용 중일 때 화면 상단에 잠시 표시되는 배너 형태의 알림입니다. 중요도가 높은 알림에만 사용됩니다.

```
┌─────────────────────────────────────┐
│  📱 새 메시지                        │  ← Head-up Display 배너
│  홍길동: 안녕하세요!                  │
└─────────────────────────────────────┘
         ↓ (4초 후 축소)
┌─────────────────────────────────────┐
│  일반 앱 화면                        │
│                                     │
└─────────────────────────────────────┘
```

### Head-up Display 표시 조건

| 조건 | 필수 여부 | 설명 |
|------|----------|------|
| Notification Channel `IMPORTANCE_HIGH` | ✅ 필수 | 채널 중요도가 HIGH 이상 |
| FCM payload `channel_id` | ✅ 필수 | 생성한 채널 ID와 일치 |
| FCM payload `priority: high` | ✅ 필수 | 메시지 우선순위 HIGH |
| 앱 상태 | - | Background/Terminated 상태 |

### 1단계: Android Notification Channel 설정 (클라이언트)

#### MainActivity.kt 설정

**위치**: `android/app/src/main/kotlin/.../MainActivity.kt`

```kotlin
package com.withcenter.philgo

import android.app.NotificationChannel
import android.app.NotificationManager
import android.media.AudioAttributes
import android.net.Uri
import android.content.ContentResolver
import android.os.Build.VERSION
import android.os.Build.VERSION_CODES
import io.flutter.embedding.android.FlutterActivity
import io.flutter.embedding.engine.FlutterEngine
import io.flutter.plugin.common.MethodChannel

class MainActivity: FlutterActivity() {
    // Flutter에서 호출할 채널 이름
    private val CHANNEL = "com.withcenter.philgo/push_notification"

    override fun configureFlutterEngine(flutterEngine: FlutterEngine) {
        super.configureFlutterEngine(flutterEngine)

        MethodChannel(flutterEngine.dartExecutor.binaryMessenger, CHANNEL)
            .setMethodCallHandler { call, result ->
                if (call.method == "createNotificationChannel") {
                    val argData = call.arguments as HashMap<String, String>
                    val completed = createNotificationChannel(argData)
                    if (completed) {
                        result.success(completed)
                    } else {
                        result.error("Error", "채널 생성 실패", null)
                    }
                } else {
                    result.notImplemented()
                }
            }
    }

    private fun createNotificationChannel(mapData: HashMap<String, String>): Boolean {
        if (VERSION.SDK_INT >= VERSION_CODES.O) {
            val id = mapData["id"]
            val name = mapData["name"]
            val descriptionText = mapData["description"]
            val sound = mapData["sound"]

            // ⚠️ 핵심: IMPORTANCE_HIGH 설정 (Head-up Display 필수 조건)
            val importance = NotificationManager.IMPORTANCE_HIGH
            val mChannel = NotificationChannel(id, name, importance)
            mChannel.description = descriptionText

            // 커스텀 사운드 설정 (선택사항)
            if (sound != null) {
                val soundUri = Uri.parse(
                    ContentResolver.SCHEME_ANDROID_RESOURCE + "://" +
                    applicationContext.packageName + "/raw/" + sound
                )
                val att = AudioAttributes.Builder()
                    .setUsage(AudioAttributes.USAGE_NOTIFICATION)
                    .setContentType(AudioAttributes.CONTENT_TYPE_SPEECH)
                    .build()
                mChannel.setSound(soundUri, att)
            }

            // 시스템에 채널 등록
            val notificationManager = getSystemService(NOTIFICATION_SERVICE) as NotificationManager
            notificationManager.createNotificationChannel(mChannel)
            return true
        }
        return false
    }
}
```

#### Flutter에서 채널 생성 호출

**위치**: `lib/functions/init.functions.dart`

```dart
import 'package:flutter/services.dart';

void initNotificationChannel() async {
  // Android 전용 Notification Channel 초기화
  const MethodChannel channel = MethodChannel(
    'com.withcenter.philgo/push_notification',
  );

  Map<String, String> channelMap = {
    "id": "main_notification",           // 채널 ID (서버에서 동일하게 사용)
    "name": "Main Notifications",        // 사용자에게 표시되는 이름
    "description": "앱 주요 알림 설정",    // 채널 설명
    "sound": "custom_sound",             // res/raw/custom_sound.mp3 (선택사항)
  };

  try {
    await channel.invokeMethod('createNotificationChannel', channelMap);
    debugPrint('Notification Channel 생성 완료');
  } on PlatformException catch (e) {
    debugPrint('Notification Channel 생성 실패: ${e.message}');
  }
}
```

#### 앱 시작 시 채널 초기화

```dart
void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp();

  // Android Notification Channel 생성 (앱 시작 시 1회)
  if (Platform.isAndroid) {
    initNotificationChannel();
  }

  runApp(MyApp());
}
```

### 2단계: Cloud Functions FCM Payload 설정 (서버)

#### Head-up Display용 FCM 메시지 구조

Cloud Functions에서 FCM을 전송할 때 **반드시** `android.notification.channel_id`와 `priority`를 설정해야 합니다.

```typescript
import * as admin from 'firebase-admin';

// Cloud Functions에서 FCM 전송
export const sendPushNotification = functions.https.onCall(async (data, context) => {
  const { token, title, body, roomId, type } = data;

  const message: admin.messaging.Message = {
    token: token,

    // Notification 메시지 (시스템 알림 표시용)
    notification: {
      title: title,
      body: body,
    },

    // Data 메시지 (앱에서 처리할 데이터)
    data: {
      roomId: roomId,
      type: type,
      click_action: 'FLUTTER_NOTIFICATION_CLICK',
    },

    // ⚠️ 핵심: Android 전용 설정
    android: {
      // 메시지 우선순위 HIGH (Head-up Display 필수)
      priority: 'high',

      notification: {
        // 클라이언트에서 생성한 채널 ID와 일치해야 함
        channelId: 'main_notification',

        // 알림 우선순위 HIGH
        priority: 'high',

        // 기본 알림음 사용 (채널에서 커스텀 사운드 설정 시 생략)
        // sound: 'default',

        // 기본 진동 패턴
        defaultVibrateTimings: true,

        // 알림 아이콘 (res/drawable에 위치)
        icon: 'ic_notification',

        // 알림 색상 (선택사항)
        color: '#FF5722',
      },
    },

    // iOS/APNs 설정 (참고용)
    apns: {
      payload: {
        aps: {
          alert: {
            title: title,
            body: body,
          },
          sound: 'default',
          badge: 1,
        },
      },
    },
  };

  try {
    const response = await admin.messaging().send(message);
    console.log('FCM 전송 성공:', response);
    return { success: true, messageId: response };
  } catch (error) {
    console.error('FCM 전송 실패:', error);
    throw new functions.https.HttpsError('internal', 'FCM 전송 실패');
  }
});
```

#### 토픽 기반 메시지 전송

```typescript
// 토픽 구독자 전체에게 전송
const topicMessage: admin.messaging.Message = {
  topic: 'news',

  notification: {
    title: '새 소식',
    body: '중요한 업데이트가 있습니다.',
  },

  android: {
    priority: 'high',
    notification: {
      channelId: 'main_notification',
      priority: 'high',
    },
  },
};

await admin.messaging().send(topicMessage);
```

#### 다중 토큰 전송 (sendEachForMulticast)

```typescript
// 여러 기기에 동시 전송
const multicastMessage: admin.messaging.MulticastMessage = {
  tokens: ['token1', 'token2', 'token3'],

  notification: {
    title: '새 메시지',
    body: '채팅방에 새 메시지가 도착했습니다.',
  },

  android: {
    priority: 'high',
    notification: {
      channelId: 'main_notification',
      priority: 'high',
    },
  },
};

const response = await admin.messaging().sendEachForMulticast(multicastMessage);
console.log(`성공: ${response.successCount}, 실패: ${response.failureCount}`);
```

### 3단계: Foreground 상태에서 Head-up Display 표시

앱이 **Foreground** 상태일 때는 FCM이 시스템 알림을 자동으로 표시하지 않습니다. `flutter_local_notifications` 패키지를 사용하여 직접 알림을 표시해야 합니다.

#### 패키지 설치

```yaml
# pubspec.yaml
dependencies:
  flutter_local_notifications: ^18.0.0
```

#### 초기화 및 사용

```dart
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:firebase_messaging/firebase_messaging.dart';

class LocalNotificationService {
  static final FlutterLocalNotificationsPlugin _plugin =
      FlutterLocalNotificationsPlugin();

  /// 초기화
  static Future<void> initialize() async {
    const AndroidInitializationSettings androidSettings =
        AndroidInitializationSettings('@mipmap/ic_launcher');

    const DarwinInitializationSettings iosSettings =
        DarwinInitializationSettings(
      requestAlertPermission: true,
      requestBadgePermission: true,
      requestSoundPermission: true,
    );

    const InitializationSettings settings = InitializationSettings(
      android: androidSettings,
      iOS: iosSettings,
    );

    await _plugin.initialize(
      settings,
      onDidReceiveNotificationResponse: (NotificationResponse response) {
        // 알림 탭 시 처리
        _handleNotificationTap(response.payload);
      },
    );
  }

  /// Foreground에서 Head-up Display 알림 표시
  static Future<void> showHeadUpNotification(RemoteMessage message) async {
    final notification = message.notification;
    if (notification == null) return;

    // ⚠️ 핵심: importance와 priority를 max/high로 설정
    const AndroidNotificationDetails androidDetails = AndroidNotificationDetails(
      'main_notification',              // 채널 ID (MainActivity와 동일)
      'Main Notifications',             // 채널 이름
      channelDescription: '앱 주요 알림 설정',
      importance: Importance.max,       // 중요도 MAX (Head-up Display)
      priority: Priority.high,          // 우선순위 HIGH
      showWhen: true,
      enableVibration: true,
      playSound: true,
      // 커스텀 사운드 사용 시
      // sound: RawResourceAndroidNotificationSound('custom_sound'),
    );

    const DarwinNotificationDetails iosDetails = DarwinNotificationDetails(
      presentAlert: true,
      presentBadge: true,
      presentSound: true,
    );

    const NotificationDetails details = NotificationDetails(
      android: androidDetails,
      iOS: iosDetails,
    );

    await _plugin.show(
      message.hashCode,                 // 알림 ID
      notification.title,               // 제목
      notification.body,                // 내용
      details,
      payload: message.data.toString(), // 탭 시 전달할 데이터
    );
  }

  static void _handleNotificationTap(String? payload) {
    if (payload == null) return;
    // payload 파싱 후 네비게이션 처리
    debugPrint('알림 탭됨: $payload');
  }
}
```

#### FCM Foreground 핸들러에서 사용

```dart
Future<void> _setupFCM() async {
  // Local Notification 초기화
  await LocalNotificationService.initialize();

  // Foreground 메시지 핸들러
  FirebaseMessaging.onMessage.listen((RemoteMessage message) {
    debugPrint('Foreground 메시지 수신: ${message.messageId}');

    // Foreground에서 Head-up Display 표시
    LocalNotificationService.showHeadUpNotification(message);
  });
}
```

### 앱 상태별 Head-up Display 동작 요약

| 앱 상태 | FCM 자동 표시 | 추가 구현 필요 | Head-up Display |
|---------|--------------|---------------|-----------------|
| **Terminated** | ✅ | ❌ | `channel_id` + `priority: high` 설정 시 자동 표시 |
| **Background** | ✅ | ❌ | `channel_id` + `priority: high` 설정 시 자동 표시 |
| **Foreground** | ❌ | ✅ `flutter_local_notifications` | `Importance.max` + `Priority.high` 설정 |

### Head-up Display 트러블슈팅

#### 알림이 상단에 표시되지 않고 알림 센터에만 표시됨

**원인**: Notification Channel의 중요도가 낮음

**해결 방법**:
1. `MainActivity.kt`에서 `IMPORTANCE_HIGH` 확인
2. 이미 생성된 채널은 **앱 삭제 후 재설치** 필요 (채널 설정은 변경 불가)

```kotlin
// 중요도 확인
val importance = NotificationManager.IMPORTANCE_HIGH  // ✅ 올바름
// val importance = NotificationManager.IMPORTANCE_DEFAULT  // ❌ Head-up 안됨
```

#### Cloud Functions에서 전송했는데 Head-up이 안됨

**원인**: FCM payload에 `channel_id`가 누락됨

**해결 방법**:

```typescript
// ❌ 잘못된 예시 - channel_id 누락
const message = {
  notification: { title: '제목', body: '내용' },
  token: token,
};

// ✅ 올바른 예시 - channel_id 포함
const message = {
  notification: { title: '제목', body: '내용' },
  android: {
    priority: 'high',
    notification: {
      channelId: 'main_notification',  // 필수!
      priority: 'high',
    },
  },
  token: token,
};
```

#### Foreground에서 알림이 표시되지 않음

**원인**: `flutter_local_notifications` 미설정

**해결 방법**: 위의 "3단계: Foreground 상태에서 Head-up Display 표시" 섹션 참고

#### Android 8.0 미만에서 알림이 안됨

**원인**: Notification Channel은 Android 8.0 (API 26) 이상에서만 지원

**해결 방법**:
- Android 8.0 미만에서는 자동으로 기본 알림 표시
- `VERSION_CODES.O` 체크 후 분기 처리

```kotlin
if (VERSION.SDK_INT >= VERSION_CODES.O) {
    // 채널 생성 로직
} else {
    // Android 8.0 미만은 채널 불필요
}
```

#### 사용자가 알림을 차단한 경우

**확인 방법**:

```dart
// 알림 권한 상태 확인
final settings = await FirebaseMessaging.instance.getNotificationSettings();
if (settings.authorizationStatus == AuthorizationStatus.denied) {
  // 설정 화면으로 유도
  showDialog(
    context: context,
    builder: (context) => AlertDialog(
      title: Text('알림 권한 필요'),
      content: Text('알림을 받으려면 설정에서 권한을 허용해주세요.'),
      actions: [
        TextButton(
          onPressed: () => openAppSettings(),
          child: Text('설정으로 이동'),
        ),
      ],
    ),
  );
}
```

### PhilGo 앱 Head-up Display 구현 참조

PhilGo 앱에서의 실제 구현 위치:

| 파일 | 역할 |
|------|------|
| `android/app/src/main/kotlin/.../MainActivity.kt` | Notification Channel 생성 (IMPORTANCE_HIGH) |
| `lib/functions/init.functions.dart` | Flutter에서 채널 생성 호출 |
| `packages/philgo_api/lib/src/messaging/messaging.service.dart` | FCM 서비스 관리 |

---

## PhilGo 앱 구현 사례

### MessagingService 클래스

PhilGo 앱에서는 `MessagingService` 싱글톤 클래스로 FCM 기능을 관리합니다.

**위치**: `packages/philgo_api/lib/src/messaging/messaging.service.dart`

#### 클래스 구조

```dart
class MessagingService {
  static MessagingService? _instance;
  static MessagingService get instance => _instance ??= MessagingService._();
  MessagingService._();

  FirebaseMessaging get messaging => FirebaseMessaging.instance;
  FirebaseAuth get auth => FirebaseAuth.instance;

  String? lastSavedToken;  // 토큰 캐싱용
  bool isInitialized = false;

  // 콜백 함수들
  Function(RemoteMessage)? onForegroundMessage;
  Function(RemoteMessage)? onMessageOpenedFromTerminated;
  Function(RemoteMessage)? onMessageOpenedFromBackground;
}
```

#### initialize() 메서드

FCM 서비스 초기화 및 핸들러 설정:

```dart
Future<void> initialize({
  required String domain,
  Function(RemoteMessage)? onForegroundMessage,
  Function(RemoteMessage)? onMessageOpenedFromTerminated,
  Function(RemoteMessage)? onMessageOpenedFromBackground,
  Future<void> Function(RemoteMessage)? onBackgroundMessage,
}) async {
  if (isInitialized) return;

  this.domain = domain;

  // Background 핸들러 등록
  if (onBackgroundMessage != null) {
    FirebaseMessaging.onBackgroundMessage(onBackgroundMessage);
  }

  // 콜백 설정
  this.onForegroundMessage = onForegroundMessage;
  this.onMessageOpenedFromTerminated = onMessageOpenedFromTerminated;
  this.onMessageOpenedFromBackground = onMessageOpenedFromBackground;

  // 권한 요청
  final settings = await messaging.requestPermission(
    alert: true,
    badge: true,
    sound: true,
  );

  if (settings.authorizationStatus == AuthorizationStatus.authorized) {
    await _setupMessageHandlers();

    // 로그인 상태 변경 시 토큰 저장
    auth.authStateChanges().listen((User? user) async {
      if (user != null) await saveToken();
    });

    await saveToken();
  }

  isInitialized = true;
}
```

#### saveToken() 메서드

FCM 토큰을 서버에 저장 (캐싱으로 중복 호출 방지):

```dart
Future<void> saveToken() async {
  final token = await FirebaseMessaging.instance.getToken();
  if (token == null || token.isEmpty) return;

  final data = <String, dynamic>{
    'device': getDeviceType(),  // 'android' | 'ios' | 'web'
    'token': token,
    'domain': domain,
  };

  String tokenCache = token;
  final user = FirebaseAuth.instance.currentUser;
  if (user != null) {
    data['uid'] = user.uid;
    tokenCache = token + user.uid;
  }

  // 동일한 토큰이면 API 호출 스킵
  if (tokenCache == lastSavedToken) return;
  lastSavedToken = tokenCache;

  // 서버에 토큰 저장
  await func<Map<String, dynamic>>(
    MessagingConfig.messagingSaveTokenApi,
    data: data,
  );
}
```

#### _setupMessageHandlers() 메서드

메시지 핸들러 설정:

```dart
Future<void> _setupMessageHandlers() async {
  // Foreground 메시지
  FirebaseMessaging.onMessage.listen(onForegroundMessage);

  // Background → Foreground 알림 탭
  FirebaseMessaging.onMessageOpenedApp.listen(onMessageOpenedFromBackground);

  // Terminated 상태에서 실행
  final initialMessage = await messaging.getInitialMessage();
  if (initialMessage != null) {
    onMessageOpenedFromTerminated?.call(initialMessage);
  }
}
```

#### 토픽 구독/해제

```dart
Future<void> subscribeToTopic(String topic) async {
  try {
    await messaging.subscribeToTopic(topic);
    debugPrint('토픽 구독 완료: $topic');
  } catch (e) {
    debugPrint('토픽 구독 실패: $e');
  }
}

Future<void> unsubscribeFromTopic(String topic) async {
  try {
    await messaging.unsubscribeFromTopic(topic);
    debugPrint('토픽 구독 해제: $topic');
  } catch (e) {
    debugPrint('토픽 해제 실패: $e');
  }
}
```

### PushNotificationIcon 위젯

채팅방별 알림 토글 위젯입니다.

**위치**: `packages/philgo_api/lib/src/messaging/widget/push_notification_icon.dart`

```dart
class PushNotificationIcon extends StatefulWidget {
  final String subscriptionId;  // 보통 roomId
  final bool reverse;           // 로직 반전 여부

  const PushNotificationIcon({
    super.key,
    required this.subscriptionId,
    this.reverse = false,
  });
}
```

#### 사용 예시

```dart
// AppBar에 알림 토글 아이콘 추가
AppBar(
  title: Text('채팅방'),
  actions: [
    PushNotificationIcon(subscriptionId: roomId),
  ],
)
```

#### 동작 원리

Firebase Realtime Database의 구독 상태를 실시간으로 읽어 아이콘 상태를 결정합니다:

```dart
StreamBuilder(
  stream: FirebaseDatabase.instance
      .ref('${MessagingConfig.subscribePath}/${widget.subscriptionId}/$uid')
      .onValue,
  builder: (context, event) {
    bool isSubscribed = event.data?.snapshot.value == true;

    return IconButton(
      icon: isSubscribed
          ? Icon(Icons.notifications, color: Colors.blue)
          : Icon(Icons.notifications_off, color: Colors.grey),
      onPressed: () => toggleNotification(isSubscribed),
    );
  },
)
```

### Firebase Realtime Database 스키마

#### FCM 토큰 저장 구조

```
fcm-tokens/
└── {token}/
    ├── uid: string        // 사용자 ID
    ├── device: string     // "android" | "ios" | "web"
    ├── domain: string     // 앱 도메인
    └── timestamp: number  // 저장 시간
```

#### FCM 구독 상태 구조

```
fcm-subscriptions/
└── {roomId}/
    └── {uid}: true  // true면 구독 중
```

### 알림 페이로드 구조

#### 채팅 메시지 알림

```json
{
  "notification": {
    "title": "새 메시지",
    "body": "홍길동: 안녕하세요!"
  },
  "data": {
    "roomId": "chat_room_123",
    "roomName": "일반 채팅",
    "type": "chat_message",
    "senderUid": "user_456"
  }
}
```

### main.dart 초기화 예시

```dart
// Top-level background handler
@pragma('vm:entry-point')
Future<void> firebaseMessagingBackgroundHandler(RemoteMessage message) async {
  await Firebase.initializeApp();
  debugPrint('Background 메시지: ${message.messageId}');
}

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform);

  runApp(const PhilGoApp());
}

class _PhilGoAppState extends State<PhilGoApp> {
  @override
  void initState() {
    super.initState();
    _initMessaging();
  }

  Future<void> _initMessaging() async {
    await MessagingService.instance.initialize(
      domain: 'philgo_app',
      onBackgroundMessage: firebaseMessagingBackgroundHandler,
      onForegroundMessage: (message) {
        MessagingService.instance.handleForegroundMessage(
          context: context,
          message: message,
          onPressed: (msg) => _navigateToChat(msg.data['roomId']),
        );
      },
      onMessageOpenedFromTerminated: (message) {
        _navigateToChat(message.data['roomId']);
      },
      onMessageOpenedFromBackground: (message) {
        _navigateToChat(message.data['roomId']);
      },
    );
  }

  void _navigateToChat(String? roomId) {
    if (roomId != null) {
      context.push('/chat/$roomId');
    }
  }
}
```

---

## 베스트 프랙티스

### 에러 처리

모든 FCM 작업은 try-catch로 감싸고 사용자에게 피드백을 제공합니다:

```dart
Future<void> subscribeToTopic(String topic) async {
  try {
    await messaging.subscribeToTopic(topic);
    showSuccessSnackBar('알림이 활성화되었습니다');
  } catch (e) {
    debugPrint('토픽 구독 실패: $e');
    showErrorSnackBar('알림 설정에 실패했습니다');
  }
}
```

### 성능 최적화

#### 토큰 캐싱

```dart
String? lastSavedToken;

Future<void> saveToken() async {
  final token = await messaging.getToken();
  final tokenCache = '$token${user?.uid ?? ''}';

  // 동일한 토큰이면 API 호출 스킵
  if (tokenCache == lastSavedToken) return;
  lastSavedToken = tokenCache;

  // 서버에 저장
  await saveTokenToServer(token);
}
```

#### 초기화 중복 방지

```dart
bool isInitialized = false;

Future<void> initialize() async {
  if (isInitialized) return;  // 중복 초기화 방지

  // 초기화 로직...

  isInitialized = true;
}
```

### 보안 고려사항

| 항목 | 권장 사항 |
|------|----------|
| 토큰 저장 | 서버에만 저장, 클라이언트에 노출 금지 |
| 페이로드 검증 | `roomId` 등 데이터 유효성 검사 후 네비게이션 |
| 인증 확인 | 민감한 알림은 사용자 인증 상태 확인 |
| HTTPS 사용 | 서버 통신 시 항상 HTTPS 사용 |

```dart
void handleMessageNavigation(RemoteMessage message) {
  // 데이터 검증
  final roomId = message.data['roomId'];
  if (roomId == null || roomId.isEmpty) {
    debugPrint('잘못된 roomId');
    return;
  }

  // 사용자 인증 확인
  if (FirebaseAuth.instance.currentUser == null) {
    debugPrint('로그인 필요');
    return;
  }

  // 안전하게 네비게이션
  context.push('/chat/$roomId');
}
```

---

## 트러블슈팅

### 토큰이 생성되지 않음

**원인**: Firebase 설정 오류 또는 권한 미허용

**해결 방법**:
1. `google-services.json` (Android) / `GoogleService-Info.plist` (iOS) 확인
2. Firebase Console에서 앱 등록 상태 확인
3. 권한 요청 결과 확인

```dart
final settings = await messaging.requestPermission();
print('권한 상태: ${settings.authorizationStatus}');

final token = await messaging.getToken();
print('토큰: $token');  // null이면 설정 문제
```

### 네비게이션이 동작하지 않음

**원인**: BuildContext 또는 라우터가 초기화되지 않음

**해결 방법**:
1. `GlobalKey<NavigatorState>` 사용
2. 초기화 완료 후 네비게이션 시도

```dart
// 글로벌 네비게이터 키 설정
final GlobalKey<NavigatorState> navigatorKey = GlobalKey<NavigatorState>();

// MaterialApp에 키 연결
MaterialApp(
  navigatorKey: navigatorKey,
  ...
)

// Terminated 상태 메시지 처리 시 지연
onMessageOpenedFromTerminated: (message) async {
  // 라우터 초기화 대기
  await Future.delayed(Duration(milliseconds: 500));
  navigatorKey.currentState?.pushNamed('/chat/${message.data['roomId']}');
},
```

### API 호출 실패

**원인**: 인증 오류 또는 네트워크 문제

**해결 방법**:
1. 사용자 인증 상태 확인
2. API 엔드포인트 URL 확인
3. 네트워크 연결 상태 확인

```dart
Future<void> saveToken() async {
  try {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) {
      debugPrint('로그인 필요');
      return;
    }

    await func(MessagingConfig.messagingSaveTokenApi, data: {...});
  } catch (e) {
    debugPrint('API 호출 실패: $e');
    // 재시도 로직 또는 사용자 알림
  }
}
```

### Background 핸들러가 호출되지 않음

**원인**: 핸들러가 top-level 함수가 아님

**해결 방법**:

```dart
// ❌ 잘못된 예시 - 클래스 내부 메서드
class MyService {
  Future<void> handleBackground(RemoteMessage message) async {...}
}

// ✅ 올바른 예시 - top-level 함수
@pragma('vm:entry-point')
Future<void> firebaseMessagingBackgroundHandler(RemoteMessage message) async {
  await Firebase.initializeApp();
  // 처리 로직
}
```

### iOS에서 알림이 표시되지 않음

**해결 방법**:
1. APNs 인증서/키 설정 확인
2. Xcode에서 Push Notifications capability 추가
3. Background Modes에서 Remote notifications 활성화

```
Xcode > Signing & Capabilities > + Capability
├── Push Notifications
└── Background Modes
    └── ✓ Remote notifications
```

---

## 참고 문서

- [Firebase Cloud Messaging 서버 환경](https://firebase.google.com/docs/cloud-messaging/server-environment)
- [Flutter에서 메시지 수신](https://firebase.google.com/docs/cloud-messaging/flutter/receive-messages)
- [Firebase Admin SDK](https://firebase.google.com/docs/admin/setup)
- [FCM HTTP v1 API](https://firebase.google.com/docs/cloud-messaging/send-message)
