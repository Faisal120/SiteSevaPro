import 'package:hive_flutter/hive_flutter.dart';

abstract interface class DashboardCache {
  Future<CachedDashboard?> read(String userId);
  Future<void> write(String userId, Map<String, dynamic> payload);
  Future<void> clear(String userId);
}

class CachedDashboard {
  const CachedDashboard({required this.payload, required this.cachedAt});

  final Map<String, dynamic> payload;
  final DateTime cachedAt;
}

class HiveDashboardCache implements DashboardCache {
  static const _boxName = 'siteseva.dashboard.cache.v1';

  Future<Box<dynamic>> _box() => Hive.openBox<dynamic>(_boxName);

  @override
  Future<CachedDashboard?> read(String userId) async {
    if (userId.isEmpty) return null;
    final raw = (await _box()).get(userId);
    if (raw is! Map) return null;
    final payload = raw['payload'];
    final cachedAt = DateTime.tryParse('${raw['cached_at'] ?? ''}');
    if (payload is! Map || cachedAt == null) return null;
    return CachedDashboard(
      payload: _deepStringMap(payload),
      cachedAt: cachedAt.toLocal(),
    );
  }

  @override
  Future<void> write(String userId, Map<String, dynamic> payload) async {
    if (userId.isEmpty) return;
    await (await _box()).put(userId, {
      'payload': payload,
      'cached_at': DateTime.now().toUtc().toIso8601String(),
    });
  }

  @override
  Future<void> clear(String userId) async {
    if (userId.isEmpty) return;
    await (await _box()).delete(userId);
  }
}

Map<String, dynamic> _deepStringMap(Map<dynamic, dynamic> source) =>
    source.map((key, value) => MapEntry('$key', _normalize(value)));

dynamic _normalize(dynamic value) {
  if (value is Map) return _deepStringMap(value);
  if (value is List) return value.map(_normalize).toList();
  return value;
}
