import 'package:hive_flutter/hive_flutter.dart';

abstract interface class NotificationsCache {
  Future<CachedNotificationsInbox?> readInbox(String userId);
  Future<void> writeInbox(String userId, Map<String, dynamic> payload);
}

class CachedNotificationsInbox {
  const CachedNotificationsInbox({
    required this.payload,
    required this.cachedAt,
  });

  final Map<String, dynamic> payload;
  final DateTime cachedAt;
}

class HiveNotificationsCache implements NotificationsCache {
  static const _boxName = 'siteseva.notifications.cache.v1';

  Future<Box<dynamic>> _box() => Hive.openBox<dynamic>(_boxName);

  @override
  Future<CachedNotificationsInbox?> readInbox(String userId) async {
    final raw = (await _box()).get('$userId::inbox');
    if (raw is! Map) return null;
    final payload = raw['payload'];
    final cachedAt = DateTime.tryParse('${raw['cached_at'] ?? ''}');
    if (payload is! Map || cachedAt == null) return null;
    return CachedNotificationsInbox(
      payload: _stringMap(payload),
      cachedAt: cachedAt.toLocal(),
    );
  }

  @override
  Future<void> writeInbox(String userId, Map<String, dynamic> payload) async {
    if (userId.isEmpty) return;
    await (await _box()).put('$userId::inbox', {
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
