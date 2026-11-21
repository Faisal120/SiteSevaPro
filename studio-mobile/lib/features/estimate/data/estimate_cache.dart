import 'package:hive_flutter/hive_flutter.dart';

abstract interface class EstimateCache {
  Future<CachedEstimateStudio?> readStudio(String userId);
  Future<void> writeStudio(String userId, Map<String, dynamic> payload);
  Future<CachedEstimate?> readEstimate(String userId, String estimateId);
  Future<void> writeEstimate(
    String userId,
    String estimateId,
    Map<String, dynamic> payload,
  );
}

class CachedEstimateStudio {
  const CachedEstimateStudio({required this.payload, required this.cachedAt});
  final Map<String, dynamic> payload;
  final DateTime cachedAt;
}

class CachedEstimate {
  const CachedEstimate({required this.payload, required this.cachedAt});
  final Map<String, dynamic> payload;
  final DateTime cachedAt;
}

class HiveEstimateCache implements EstimateCache {
  static const _boxName = 'siteseva.estimate.cache.v1';

  Future<Box<dynamic>> _box() => Hive.openBox<dynamic>(_boxName);

  @override
  Future<CachedEstimateStudio?> readStudio(String userId) async {
    final raw = (await _box()).get('$userId::studio');
    if (raw is! Map) return null;
    final payload = raw['payload'];
    final cachedAt = DateTime.tryParse('${raw['cached_at'] ?? ''}');
    if (payload is! Map || cachedAt == null) return null;
    return CachedEstimateStudio(
      payload: _stringMap(payload),
      cachedAt: cachedAt.toLocal(),
    );
  }

  @override
  Future<void> writeStudio(String userId, Map<String, dynamic> payload) =>
      _write('$userId::studio', payload);

  @override
  Future<CachedEstimate?> readEstimate(String userId, String estimateId) async {
    final raw = (await _box()).get('$userId::$estimateId');
    if (raw is! Map) return null;
    final payload = raw['payload'];
    final cachedAt = DateTime.tryParse('${raw['cached_at'] ?? ''}');
    if (payload is! Map || cachedAt == null) return null;
    return CachedEstimate(
      payload: _stringMap(payload),
      cachedAt: cachedAt.toLocal(),
    );
  }

  @override
  Future<void> writeEstimate(
    String userId,
    String estimateId,
    Map<String, dynamic> payload,
  ) => _write('$userId::$estimateId', payload);

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
