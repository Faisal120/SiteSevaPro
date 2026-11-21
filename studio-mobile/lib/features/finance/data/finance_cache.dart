import 'package:hive_flutter/hive_flutter.dart';

abstract interface class FinanceCache {
  Future<CachedFinanceStudio?> readStudio(String userId);
  Future<void> writeStudio(String userId, Map<String, dynamic> payload);
}

class CachedFinanceStudio {
  const CachedFinanceStudio({required this.payload, required this.cachedAt});
  final Map<String, dynamic> payload;
  final DateTime cachedAt;
}

class HiveFinanceCache implements FinanceCache {
  static const _boxName = 'siteseva.finance.cache.v1';

  Future<Box<dynamic>> _box() => Hive.openBox<dynamic>(_boxName);

  @override
  Future<CachedFinanceStudio?> readStudio(String userId) async {
    final raw = (await _box()).get('$userId::studio');
    if (raw is! Map) return null;
    final payload = raw['payload'];
    final cachedAt = DateTime.tryParse('${raw['cached_at'] ?? ''}');
    if (payload is! Map || cachedAt == null) return null;
    return CachedFinanceStudio(
      payload: _stringMap(payload),
      cachedAt: cachedAt.toLocal(),
    );
  }

  @override
  Future<void> writeStudio(String userId, Map<String, dynamic> payload) async {
    if (userId.isEmpty) return;
    await (await _box()).put('$userId::studio', {
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
