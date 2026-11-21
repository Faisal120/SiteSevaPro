import 'package:hive_flutter/hive_flutter.dart';

abstract interface class DesignStudioCache {
  Future<CachedDesignStudio?> readStudio(String userId);
  Future<void> writeStudio(String userId, Map<String, dynamic> payload);
  Future<CachedDesign?> readDesign(String userId, String designId);
  Future<void> writeDesign(
    String userId,
    String designId,
    Map<String, dynamic> payload,
  );
  Future<void> removeDesign(String userId, String designId);
}

class CachedDesignStudio {
  const CachedDesignStudio({required this.payload, required this.cachedAt});
  final Map<String, dynamic> payload;
  final DateTime cachedAt;
}

class CachedDesign {
  const CachedDesign({required this.payload, required this.cachedAt});
  final Map<String, dynamic> payload;
  final DateTime cachedAt;
}

class HiveDesignStudioCache implements DesignStudioCache {
  static const _boxName = 'siteseva.design-studio.cache.v1';

  Future<Box<dynamic>> _box() => Hive.openBox<dynamic>(_boxName);

  @override
  Future<CachedDesignStudio?> readStudio(String userId) async {
    final raw = (await _box()).get('$userId::studio');
    if (raw is! Map) return null;
    final payload = raw['payload'];
    final cachedAt = DateTime.tryParse('${raw['cached_at'] ?? ''}');
    if (payload is! Map || cachedAt == null) return null;
    return CachedDesignStudio(
      payload: _stringMap(payload),
      cachedAt: cachedAt.toLocal(),
    );
  }

  @override
  Future<void> writeStudio(String userId, Map<String, dynamic> payload) =>
      _write('$userId::studio', payload);

  @override
  Future<CachedDesign?> readDesign(String userId, String designId) async {
    final raw = (await _box()).get('$userId::$designId');
    if (raw is! Map) return null;
    final payload = raw['payload'];
    final cachedAt = DateTime.tryParse('${raw['cached_at'] ?? ''}');
    if (payload is! Map || cachedAt == null) return null;
    return CachedDesign(
      payload: _stringMap(payload),
      cachedAt: cachedAt.toLocal(),
    );
  }

  @override
  Future<void> writeDesign(
    String userId,
    String designId,
    Map<String, dynamic> payload,
  ) => _write('$userId::$designId', payload);

  @override
  Future<void> removeDesign(String userId, String designId) async {
    await (await _box()).delete('$userId::$designId');
    final cached = await readStudio(userId);
    if (cached == null) return;
    final designs = cached.payload['designs'];
    if (designs is! List) return;
    await writeStudio(userId, {
      ...cached.payload,
      'designs': designs
          .where((item) => item is! Map || '${item['id']}' != designId)
          .toList(),
    });
  }

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
