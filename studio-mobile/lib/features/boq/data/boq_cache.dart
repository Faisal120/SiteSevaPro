import 'package:hive_flutter/hive_flutter.dart';

abstract interface class BoqCache {
  Future<CachedBoqStudio?> readStudio(String userId);
  Future<void> writeStudio(String userId, Map<String, dynamic> payload);
  Future<CachedBoq?> readBoq(String userId, String boqId);
  Future<void> writeBoq(
    String userId,
    String boqId,
    Map<String, dynamic> payload,
  );
}

class CachedBoqStudio {
  const CachedBoqStudio({required this.payload, required this.cachedAt});
  final Map<String, dynamic> payload;
  final DateTime cachedAt;
}

class CachedBoq {
  const CachedBoq({required this.payload, required this.cachedAt});
  final Map<String, dynamic> payload;
  final DateTime cachedAt;
}

class HiveBoqCache implements BoqCache {
  static const _boxName = 'siteseva.boq.cache.v1';

  Future<Box<dynamic>> _box() => Hive.openBox<dynamic>(_boxName);

  @override
  Future<CachedBoqStudio?> readStudio(String userId) async {
    final raw = (await _box()).get('$userId::studio');
    if (raw is! Map) return null;
    final payload = raw['payload'];
    final cachedAt = DateTime.tryParse('${raw['cached_at'] ?? ''}');
    if (payload is! Map || cachedAt == null) return null;
    return CachedBoqStudio(
      payload: _stringMap(payload),
      cachedAt: cachedAt.toLocal(),
    );
  }

  @override
  Future<void> writeStudio(String userId, Map<String, dynamic> payload) =>
      _write('$userId::studio', payload);

  @override
  Future<CachedBoq?> readBoq(String userId, String boqId) async {
    final raw = (await _box()).get('$userId::$boqId');
    if (raw is! Map) return null;
    final payload = raw['payload'];
    final cachedAt = DateTime.tryParse('${raw['cached_at'] ?? ''}');
    if (payload is! Map || cachedAt == null) return null;
    return CachedBoq(
      payload: _stringMap(payload),
      cachedAt: cachedAt.toLocal(),
    );
  }

  @override
  Future<void> writeBoq(
    String userId,
    String boqId,
    Map<String, dynamic> payload,
  ) => _write('$userId::$boqId', payload);

  Future<void> _write(String key, Map<String, dynamic> payload) async {
    if (key.startsWith('::')) return;
    await (await _box()).put(key, {
      'payload': payload,
      'cached_at': DateTime.now().toUtc().toIso8601String(),
    });
  }
}

Map<String, dynamic> _stringMap(Map<dynamic, dynamic> source) =>
    source.map((key, value) => MapEntry('$key', _normalize(value)));

dynamic _normalize(dynamic value) {
  if (value is Map) return _stringMap(value);
  if (value is List) return value.map(_normalize).toList();
  return value;
}
