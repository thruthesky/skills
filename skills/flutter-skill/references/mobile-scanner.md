# Mobile Scanner - Flutter 바코드/QR코드 스캐너

## Workflow

1. `mobile_scanner` 패키지 설치 및 플랫폼별 권한 설정
2. `MobileScannerController` 생성 및 설정
3. `MobileScanner` 위젯 배치 및 `onDetect` 콜백 또는 `controller.barcodes` 스트림 구독
4. UI 컨트롤 위젯 추가 (플래시, 카메라 전환, 줌 등)
5. 리소스 정리 (`dispose`)

---

## 1. 패키지 개요

| 항목 | 내용 |
|------|------|
| 패키지 | [mobile_scanner](https://pub.dev/packages/mobile_scanner) |
| 최신 버전 | ^7.2.0 |
| 라이선스 | BSD-3-Clause |
| 지원 플랫폼 | Android, iOS, macOS, Web |
| 핵심 기능 | 바코드/QR코드 실시간 스캔, 이미지 분석, 다중 바코드 감지 |

---

## 2. 설치

```yaml
dependencies:
  mobile_scanner: ^7.2.0
```

### 플랫폼별 설정

#### Android

`android/app/build.gradle`에서 minSdkVersion 21 이상 확인.

MLKit 번들 버전 선택 (선택사항):
```groovy
// android/app/build.gradle
dependencies {
    // 번들 버전 (앱 크기 증가, 오프라인 사용 가능)
    implementation 'com.google.mlkit:barcode-scanning:17.3.0'
    // 또는 언번들 버전 (앱 크기 감소, Google Play Services 필요)
    // implementation 'com.google.android.gms:play-services-mlkit-barcode-scanning:18.3.1'
}
```

#### iOS

`ios/Runner/Info.plist`에 카메라 권한 추가:
```xml
<key>NSCameraUsageDescription</key>
<string>바코드 스캔을 위해 카메라 접근이 필요합니다.</string>
<key>NSPhotoLibraryUsageDescription</key>
<string>이미지에서 바코드를 분석하기 위해 사진 라이브러리 접근이 필요합니다.</string>
```

#### macOS

XCode에서 Signing & Capabilities > Camera 활성화.

---

## 3. COT (Chain-of-Thought) 분석

### 3.1 핵심 문제 이해

Mobile Scanner는 다음 세 가지 핵심 컴포넌트로 구성됩니다:

1. **MobileScannerController** - 카메라 제어 및 스캔 설정 관리
2. **MobileScanner 위젯** - 카메라 프리뷰 렌더링 및 바코드 감지
3. **BarcodeCapture** - 감지된 바코드 데이터 모델

### 3.2 해결 계획

```
[Controller 생성] → [MobileScanner 위젯 배치] → [바코드 감지 처리] → [UI 컨트롤 추가] → [리소스 정리]
```

### 3.3 MobileScannerController 주요 설정

| 파라미터 | 타입 | 기본값 | 설명 |
|----------|------|--------|------|
| `autoStart` | `bool` | `true` | 자동 시작 여부 |
| `cameraResolution` | `Size` | `Size(1920, 1080)` | 카메라 해상도 (Android) |
| `detectionSpeed` | `DetectionSpeed` | `unrestricted` | 감지 속도 |
| `detectionTimeoutMs` | `int` | `1000` | 감지 타임아웃 (ms) |
| `formats` | `List<BarcodeFormat>` | `[]` (전체) | 감지할 바코드 형식 |
| `returnImage` | `bool` | `false` | 바코드 이미지 반환 여부 |
| `invertImage` | `bool` | `false` | 이미지 반전 (Android) |
| `autoZoom` | `bool` | `false` | 자동 줌 (Android) |
| `lensType` | `CameraLensType` | `normal` | 렌즈 타입 |
| `torchEnabled` | `bool` | `false` | 토치(플래시) 활성화 |

### 3.4 DetectionSpeed 옵션

| 값 | 설명 |
|----|------|
| `unrestricted` | 제한 없이 최대 속도로 감지 |
| `normal` | `detectionTimeoutMs` 간격으로 감지 |
| `noDuplicates` | 중복 바코드 무시 |

### 3.5 CameraLensType 옵션

| 값 | 설명 |
|----|------|
| `any` | 기본 (시스템 선택) |
| `normal` | 일반 렌즈 |
| `wide` | 광각/초광각 렌즈 |
| `zoom` | 줌/망원 렌즈 |

---

## 4. TOT (Tree-of-Thought) 분석

### 4.1 하위 문제 분해

```
Mobile Scanner 구현
├── [A] 기본 스캔 (Simple)
│   ├── MobileScanner 위젯만 사용
│   └── onDetect 콜백으로 바코드 수신
├── [B] 고급 스캔 (Advanced)
│   ├── MobileScannerController로 세밀한 제어
│   ├── 카메라 전환, 플래시, 줌, 일시정지
│   ├── 스캔 윈도우 설정
│   └── 바코드 오버레이
├── [C] 픽리스트 스캔 (Picklist)
│   ├── 크로스헤어 중심 영역만 감지
│   ├── 터치로 스캔 일시정지/재개
│   └── 스트림 구독 방식
└── [D] 이미지 분석
    ├── 갤러리 이미지에서 바코드 검출
    └── controller.analyzeImage(path) 사용
```

### 4.2 [A] 기본 스캔 구현

Controller 없이 가장 간단한 구현:

```dart
import 'package:flutter/material.dart';
import 'package:mobile_scanner/mobile_scanner.dart';

class SimpleScannerScreen extends StatefulWidget {
  const SimpleScannerScreen({super.key});

  @override
  State<SimpleScannerScreen> createState() => _SimpleScannerScreenState();
}

class _SimpleScannerScreenState extends State<SimpleScannerScreen> {
  Barcode? _barcode;

  void _handleBarcode(BarcodeCapture barcodes) {
    if (mounted) {
      setState(() {
        _barcode = barcodes.barcodes.firstOrNull;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Simple Scanner')),
      backgroundColor: Colors.black,
      body: Stack(
        children: [
          MobileScanner(onDetect: _handleBarcode),
          Align(
            alignment: Alignment.bottomCenter,
            child: Container(
              height: 100,
              color: const Color.fromRGBO(0, 0, 0, 0.4),
              child: Center(
                child: Text(
                  _barcode?.displayValue ?? 'Scan something!',
                  style: const TextStyle(color: Colors.white),
                  overflow: TextOverflow.fade,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
```

### 4.3 [B] 고급 스캔 구현

Controller를 사용한 전체 기능 구현:

```dart
import 'dart:async';
import 'package:flutter/material.dart';
import 'package:mobile_scanner/mobile_scanner.dart';

class AdvancedScannerScreen extends StatefulWidget {
  const AdvancedScannerScreen({super.key});

  @override
  State<AdvancedScannerScreen> createState() => _AdvancedScannerScreenState();
}

class _AdvancedScannerScreenState extends State<AdvancedScannerScreen> {
  // Controller를 autoStart: false로 생성하고 initState에서 수동 시작
  late MobileScannerController controller;

  @override
  void initState() {
    super.initState();
    controller = MobileScannerController(
      autoStart: false,
      detectionSpeed: DetectionSpeed.normal,
      detectionTimeoutMs: 1000,
      returnImage: false,
      formats: [BarcodeFormat.qrCode, BarcodeFormat.ean13],
    );
    unawaited(controller.start());
  }

  @override
  Future<void> dispose() async {
    super.dispose();
    await controller.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Advanced Scanner')),
      backgroundColor: Colors.black,
      body: Stack(
        children: [
          MobileScanner(
            controller: controller,
            errorBuilder: (context, error) {
              return _ScannerErrorWidget(error: error);
            },
            fit: BoxFit.contain,
          ),
          // 스캔된 바코드 라벨
          Align(
            alignment: Alignment.bottomCenter,
            child: Container(
              height: 200,
              color: const Color.fromRGBO(0, 0, 0, 0.4),
              child: Column(
                children: [
                  // 바코드 스트림 표시
                  Expanded(
                    child: StreamBuilder<BarcodeCapture>(
                      stream: controller.barcodes,
                      builder: (context, snapshot) {
                        final barcodes = snapshot.data?.barcodes ?? [];
                        if (barcodes.isEmpty) {
                          return const Center(
                            child: Text(
                              'Scan something!',
                              style: TextStyle(color: Colors.white),
                            ),
                          );
                        }
                        return Center(
                          child: Text(
                            barcodes.map((b) => b.displayValue).join('\n'),
                            style: const TextStyle(color: Colors.white),
                          ),
                        );
                      },
                    ),
                  ),
                  // 줌 슬라이더
                  _ZoomSlider(controller: controller),
                  // 컨트롤 버튼 행
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                    children: [
                      _ToggleFlashButton(controller: controller),
                      _StartStopButton(controller: controller),
                      _PauseButton(controller: controller),
                      _SwitchCameraButton(controller: controller),
                    ],
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}
```

### 4.4 [C] 픽리스트 (크로스헤어) 스캔

화면 중앙의 크로스헤어에 바코드가 위치할 때만 감지:

```dart
import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:mobile_scanner/mobile_scanner.dart';

class PicklistScannerScreen extends StatefulWidget {
  const PicklistScannerScreen({super.key});

  @override
  State<PicklistScannerScreen> createState() => _PicklistScannerScreenState();
}

class _PicklistScannerScreenState extends State<PicklistScannerScreen> {
  final _controller = MobileScannerController(autoStart: false);
  StreamSubscription<Object?>? _subscription;
  final ValueNotifier<bool> _scannerEnabled = ValueNotifier(true);

  @override
  void initState() {
    super.initState();
    // 세로 방향 고정
    unawaited(
      SystemChrome.setPreferredOrientations([DeviceOrientation.portraitUp]),
    );
    // 스트림 구독 방식으로 바코드 수신
    _subscription = _controller.barcodes.listen(_handleBarcodes);
    unawaited(_controller.start());
  }

  @override
  void dispose() {
    unawaited(_subscription?.cancel());
    _subscription = null;
    super.dispose();
    unawaited(_controller.dispose());
  }

  void _handleBarcodes(BarcodeCapture barcodeCapture) {
    if (!_scannerEnabled.value) return;
    // 중앙 영역의 바코드만 처리
    final barcode = barcodeCapture.barcodes.firstOrNull;
    if (barcode != null) {
      debugPrint('Detected: ${barcode.displayValue}');
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Picklist Scanner')),
      backgroundColor: Colors.black,
      body: Listener(
        // 터치로 스캔 일시정지/재개
        behavior: HitTestBehavior.opaque,
        onPointerDown: (_) => _scannerEnabled.value = false,
        onPointerUp: (_) => _scannerEnabled.value = true,
        onPointerCancel: (_) => _scannerEnabled.value = true,
        child: Stack(
          fit: StackFit.expand,
          children: [
            MobileScanner(
              controller: _controller,
              fit: BoxFit.contain,
            ),
            // 크로스헤어 위젯
            ValueListenableBuilder<bool>(
              valueListenable: _scannerEnabled,
              builder: (context, enabled, _) {
                return Center(
                  child: Icon(
                    Icons.close,
                    color: enabled ? Colors.red : Colors.green,
                  ),
                );
              },
            ),
          ],
        ),
      ),
    );
  }
}
```

### 4.5 [D] 이미지 분석

갤러리 이미지에서 바코드 검출:

```dart
import 'package:image_picker/image_picker.dart';
import 'package:mobile_scanner/mobile_scanner.dart';

// controller가 이미 생성되어 있다고 가정
Future<void> analyzeImageFromGallery(
  BuildContext context,
  MobileScannerController controller,
) async {
  final picker = ImagePicker();
  final XFile? image = await picker.pickImage(source: ImageSource.gallery);
  if (image == null) return;

  final BarcodeCapture? result = await controller.analyzeImage(image.path);

  if (!context.mounted) return;

  if (result != null && result.barcodes.isNotEmpty) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('Barcode found: ${result.barcodes.first.displayValue}'),
        backgroundColor: Colors.green,
      ),
    );
  } else {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('No barcode found'),
        backgroundColor: Colors.red,
      ),
    );
  }
}
```

---

## 5. Controller 주요 메서드

| 메서드 | 설명 |
|--------|------|
| `start()` | 카메라 시작 |
| `stop()` | 카메라 중지 |
| `pause()` | 스캔 일시정지 |
| `dispose()` | 리소스 해제 |
| `switchCamera()` | 전면/후면 카메라 전환 |
| `toggleTorch()` | 플래시 토글 |
| `setZoomScale(double)` | 줌 레벨 설정 (0.0 ~ 1.0) |
| `analyzeImage(String)` | 이미지 파일에서 바코드 분석 |
| `getSupportedLenses()` | 지원 렌즈 타입 조회 |

### Controller 상태 구독 (ValueListenable)

```dart
ValueListenableBuilder(
  valueListenable: controller,
  builder: (context, state, child) {
    // state.isInitialized - 초기화 완료 여부
    // state.isRunning - 실행 중 여부
    // state.torchState - 토치 상태 (on/off/auto/unavailable)
    // state.zoomScale - 현재 줌 레벨
    // state.cameraDirection - 카메라 방향 (front/back/external/unknown)
    // state.availableCameras - 사용 가능한 카메라 수
    return child!;
  },
);
```

### 바코드 스트림 구독

```dart
// 방법 1: StreamBuilder 사용
StreamBuilder<BarcodeCapture>(
  stream: controller.barcodes,
  builder: (context, snapshot) {
    final barcodes = snapshot.data?.barcodes ?? [];
    // 바코드 처리
    return Text(barcodes.map((b) => b.displayValue).join(', '));
  },
);

// 방법 2: StreamSubscription 사용
StreamSubscription<Object?>? subscription;
subscription = controller.barcodes.listen((barcodeCapture) {
  for (final barcode in barcodeCapture.barcodes) {
    debugPrint('Detected: ${barcode.displayValue}');
  }
});
// dispose에서 반드시 취소
await subscription?.cancel();
```

---

## 6. 스캔 윈도우 & 오버레이

화면의 특정 영역만 스캔하도록 제한:

```dart
// 스캔 윈도우 정의
final scanWindow = Rect.fromCenter(
  center: MediaQuery.sizeOf(context).center(const Offset(0, -100)),
  width: 300,
  height: 200,
);

MobileScanner(
  controller: controller,
  scanWindow: scanWindow,  // 스캔 영역 제한
  fit: BoxFit.contain,
);

// 스캔 윈도우 시각적 오버레이
IgnorePointer(
  child: ScanWindowOverlay(
    scanWindow: scanWindow,
    controller: controller,
  ),
);

// 바코드 위치 오버레이
IgnorePointer(
  child: BarcodeOverlay(
    controller: controller,
    boxFit: BoxFit.contain,
  ),
);
```

> **참고**: 스캔 윈도우는 웹에서는 오버레이 프리뷰가 지원되지 않습니다.

---

## 7. 재사용 가능한 위젯 패턴

### 에러 위젯

```dart
class ScannerErrorWidget extends StatelessWidget {
  const ScannerErrorWidget({required this.error, super.key});
  final MobileScannerException error;

  @override
  Widget build(BuildContext context) {
    return ColoredBox(
      color: Colors.black,
      child: Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Padding(
              padding: EdgeInsets.only(bottom: 16),
              child: Icon(Icons.error, color: Colors.white),
            ),
            Text(
              error.errorCode.message,
              style: const TextStyle(color: Colors.white),
            ),
            if (error.errorDetails?.message case final String message)
              Text(message, style: const TextStyle(color: Colors.white)),
          ],
        ),
      ),
    );
  }
}
```

### 플래시 토글 버튼

```dart
class ToggleFlashButton extends StatelessWidget {
  const ToggleFlashButton({required this.controller, super.key});
  final MobileScannerController controller;

  @override
  Widget build(BuildContext context) {
    return ValueListenableBuilder(
      valueListenable: controller,
      builder: (context, state, child) {
        if (!state.isInitialized || !state.isRunning) {
          return const SizedBox.shrink();
        }
        switch (state.torchState) {
          case TorchState.auto:
            return IconButton(
              icon: const Icon(Icons.flash_auto),
              color: Colors.white,
              onPressed: controller.toggleTorch,
            );
          case TorchState.off:
            return IconButton(
              icon: const Icon(Icons.flash_off),
              color: Colors.white,
              onPressed: controller.toggleTorch,
            );
          case TorchState.on:
            return IconButton(
              icon: const Icon(Icons.flash_on),
              color: Colors.white,
              onPressed: controller.toggleTorch,
            );
          case TorchState.unavailable:
            return const Icon(Icons.no_flash, color: Colors.grey);
        }
      },
    );
  }
}
```

### 시작/중지 버튼

```dart
class StartStopButton extends StatelessWidget {
  const StartStopButton({required this.controller, super.key});
  final MobileScannerController controller;

  @override
  Widget build(BuildContext context) {
    return ValueListenableBuilder(
      valueListenable: controller,
      builder: (context, state, child) {
        if (!state.isInitialized || !state.isRunning) {
          return IconButton(
            icon: const Icon(Icons.play_arrow),
            color: Colors.white,
            onPressed: controller.start,
          );
        }
        return IconButton(
          icon: const Icon(Icons.stop),
          color: Colors.white,
          onPressed: controller.stop,
        );
      },
    );
  }
}
```

### 카메라 전환 버튼

```dart
class SwitchCameraButton extends StatelessWidget {
  const SwitchCameraButton({required this.controller, super.key});
  final MobileScannerController controller;

  @override
  Widget build(BuildContext context) {
    return ValueListenableBuilder(
      valueListenable: controller,
      builder: (context, state, child) {
        if (!state.isInitialized || !state.isRunning) {
          return const SizedBox.shrink();
        }
        if (state.availableCameras != null && state.availableCameras! < 2) {
          return const SizedBox.shrink();
        }
        final icon = switch (state.cameraDirection) {
          CameraFacing.front => const Icon(Icons.camera_front),
          CameraFacing.back => const Icon(Icons.camera_rear),
          CameraFacing.external => const Icon(Icons.usb),
          CameraFacing.unknown => const Icon(Icons.device_unknown),
        };
        return IconButton(
          icon: icon,
          color: Colors.white,
          onPressed: controller.switchCamera,
        );
      },
    );
  }
}
```

### 줌 슬라이더

```dart
class ZoomScaleSlider extends StatelessWidget {
  const ZoomScaleSlider({required this.controller, super.key});
  final MobileScannerController controller;

  @override
  Widget build(BuildContext context) {
    return ValueListenableBuilder(
      valueListenable: controller,
      builder: (context, state, child) {
        if (!state.isInitialized || !state.isRunning) {
          return const SizedBox.shrink();
        }
        return Padding(
          padding: const EdgeInsets.symmetric(horizontal: 8),
          child: Row(
            children: [
              const Text('0%', style: TextStyle(color: Colors.white)),
              Expanded(
                child: Slider(
                  value: state.zoomScale,
                  onChanged: controller.setZoomScale,
                ),
              ),
              const Text('100%', style: TextStyle(color: Colors.white)),
            ],
          ),
        );
      },
    );
  }
}
```

### 렌즈 전환 버튼

```dart
class SwitchLensButton extends StatefulWidget {
  const SwitchLensButton({
    required this.controller,
    required this.currentLensType,
    required this.onLensTypeChanged,
    super.key,
  });
  final MobileScannerController controller;
  final CameraLensType currentLensType;
  final ValueChanged<CameraLensType> onLensTypeChanged;

  @override
  State<SwitchLensButton> createState() => _SwitchLensButtonState();
}

class _SwitchLensButtonState extends State<SwitchLensButton> {
  List<CameraLensType> _availableLenses = [
    CameraLensType.normal,
    CameraLensType.wide,
    CameraLensType.zoom,
  ];

  @override
  void initState() {
    super.initState();
    unawaited(_loadSupportedLenses());
  }

  Future<void> _loadSupportedLenses() async {
    try {
      final supportedLenses = await widget.controller.getSupportedLenses();
      final specificLenses = supportedLenses
          .where((lens) => lens != CameraLensType.any)
          .toList();
      if (specificLenses.isNotEmpty && mounted) {
        setState(() => _availableLenses = specificLenses);
      }
    } on Exception {
      // 기본 목록 유지
    }
  }

  CameraLensType _getNextLensType() {
    if (_availableLenses.isEmpty) return CameraLensType.any;
    final currentIndex = _availableLenses.indexOf(widget.currentLensType);
    if (currentIndex == -1) return _availableLenses.first;
    return _availableLenses[(currentIndex + 1) % _availableLenses.length];
  }

  @override
  Widget build(BuildContext context) {
    if (_availableLenses.length < 2) return const SizedBox.shrink();
    return TextButton.icon(
      onPressed: () => widget.onLensTypeChanged(_getNextLensType()),
      icon: Icon(
        switch (widget.currentLensType) {
          CameraLensType.normal => Icons.camera,
          CameraLensType.wide => Icons.camera_outdoor,
          CameraLensType.zoom => Icons.zoom_in,
          CameraLensType.any => Icons.camera_alt,
        },
        color: Colors.white,
      ),
      label: Text(
        widget.currentLensType.name,
        style: const TextStyle(color: Colors.white, fontSize: 10),
      ),
    );
  }
}
```

---

## 8. Controller 재초기화 패턴

설정 변경 시 Controller를 재생성해야 할 경우:

```dart
/// 주의: 프로덕션에서는 설정을 MobileScanner 페이지 외부에서 구성하는 것을 권장
/// 이 패턴은 동적 설정 변경 데모용
Future<void> _reinitializeController() async {
  // 1. MobileScanner 위젯 숨김
  setState(() => hideMobileScannerWidget = true);

  // 2. UI 안정화 대기
  await Future<void>.delayed(const Duration(milliseconds: 300));

  // 3. 현재 Controller 해제
  await controller?.dispose();
  controller = null;

  // 4. 새 Controller 생성
  controller = MobileScannerController(
    autoStart: false,
    detectionSpeed: detectionSpeed,
    formats: selectedFormats,
    returnImage: returnImage,
    // ... 기타 설정
  );

  // 5. 위젯 다시 표시
  setState(() => hideMobileScannerWidget = false);
  await Future<void>.delayed(const Duration(milliseconds: 300));

  // 6. 스캔 시작
  await controller?.start();
}
```

---

## 9. BarcodeCapture 데이터 모델

```dart
// BarcodeCapture 구조
class BarcodeCapture {
  final List<Barcode> barcodes;   // 감지된 바코드 목록
  final Uint8List? image;          // 캡처된 이미지 (returnImage: true일 때)
  final Size? size;                // 이미지 크기
}

// Barcode 구조
class Barcode {
  final String? displayValue;      // 표시용 값
  final String? rawValue;          // 원본 값
  final Uint8List? rawDecodedBytes; // 원본 바이트
  final BarcodeFormat format;       // 바코드 형식
  final Rect? boundingBox;         // 바코드 경계 박스
  final List<Offset>? cornerPoints; // 코너 좌표
}
```

### 주요 BarcodeFormat 종류

| 형식 | 설명 |
|------|------|
| `BarcodeFormat.qrCode` | QR 코드 |
| `BarcodeFormat.ean13` | EAN-13 바코드 |
| `BarcodeFormat.ean8` | EAN-8 바코드 |
| `BarcodeFormat.code128` | Code 128 |
| `BarcodeFormat.code39` | Code 39 |
| `BarcodeFormat.upcA` | UPC-A |
| `BarcodeFormat.upcE` | UPC-E |
| `BarcodeFormat.pdf417` | PDF417 |
| `BarcodeFormat.dataMatrix` | Data Matrix |
| `BarcodeFormat.aztec` | Aztec |

---

## 10. 주의사항

1. **dispose 필수**: Controller는 반드시 `dispose()`를 호출하여 리소스 해제
2. **mounted 확인**: 비동기 작업 후 `mounted` 또는 `context.mounted` 확인
3. **autoStart: false 권장**: initState에서 수동 시작하는 패턴이 더 안정적
4. **웹 제한**: 스캔 윈도우 오버레이, 이미지 분석은 웹에서 미지원
5. **Android 전용**: `autoZoom`, `invertImage`, `cameraResolution`은 Android 전용
6. **라이프사이클**: 기본적으로 앱 라이프사이클에 따라 자동 관리됨 (`useAppLifecycleState: true`)
7. **tapToFocus**: `MobileScanner(tapToFocus: true)`로 터치 포커스 활성화 가능
