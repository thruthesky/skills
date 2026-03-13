# Flutter 메모리 캐시 서비스

LRU(Least Recently Used) 정책을 지원하는 간단한 싱글톤 메모리 캐시입니다.

## 파일 위치

`lib/services/memory_cache/memory_cache.service.dart`

## MemoryCache 클래스

```dart
/// 메모리 캐시 서비스 (Memory Cache Service)
///
/// LRU(Least Recently Used) 정책을 지원하는 싱글톤 메모리 캐시입니다.
class MemoryCache {
  MemoryCache._();

  /// 싱글톤 인스턴스 (Singleton instance)
  static final instance = MemoryCache._();

  /// 캐시 저장소 (Cache storage)
  final _map = <String, dynamic>{};

  /// 최대 캐시 항목 수 (Maximum cache entries)
  int maxEntries = 200;

  /// 캐시에서 값 조회 (Get value from cache)
  T? get<T>(String key) {
    final value = _map.remove(key);
    if (value == null) return null;

    // LRU: 최근 접근한 항목을 맨 뒤로 재삽입
    _map[key] = value;
    return value as T?;
  }

  /// 캐시에 값 저장 (Set value to cache)
  void set(String key, dynamic value) {
    _map.remove(key);
    _map[key] = value;

    // LRU: 용량 초과 시 가장 오래된 항목 제거
    while (_map.length > maxEntries) {
      _map.remove(_map.keys.first);
    }
  }

  /// 특정 키 삭제 (Remove specific key)
  void remove(String key) => _map.remove(key);

  /// 전체 캐시 삭제 (Clear all cache)
  void clear() => _map.clear();

  /// 캐시 항목 수 (Number of cached items)
  int get length => _map.length;
}
```

## 사용 예시

```dart
import 'package:philgo/services/memory_cache/memory_cache.service.dart';

// 저장
MemoryCache.instance.set('user:123', {'id': '123', 'name': 'JaeHo'});
MemoryCache.instance.set('token', 'abc123');

// 조회
final user = MemoryCache.instance.get<Map<String, dynamic>>('user:123');
final token = MemoryCache.instance.get<String>('token');

// 삭제
MemoryCache.instance.remove('user:123');

// 전체 삭제
MemoryCache.instance.clear();

// 캐시 항목 수 확인
print('캐시 항목 수: ${MemoryCache.instance.length}');
```

## API 레퍼런스

| 메서드 | 설명 |
|--------|------|
| `get<T>(String key)` | 캐시에서 값 조회 (없으면 null) |
| `set(String key, dynamic value)` | 캐시에 값 저장 |
| `remove(String key)` | 특정 키 삭제 |
| `clear()` | 전체 캐시 삭제 |
| `length` | 캐시 항목 수 |

## 설정

| 속성 | 기본값 | 설명 |
|------|--------|------|
| `maxEntries` | 200 | 최대 캐시 항목 수 (초과 시 LRU 제거) |

```dart
// 최대 항목 수 변경
MemoryCache.instance.maxEntries = 500;
```

## LRU 동작 원리

1. **조회 시**: 항목을 맵에서 제거 후 맨 뒤에 재삽입 (최근 사용으로 표시)
2. **저장 시**: 용량 초과 시 맨 앞 항목(가장 오래 안 쓰인 항목) 제거
