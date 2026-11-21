import 'package:hive_flutter/hive_flutter.dart';

abstract interface class DocumentCache {
  Future<CachedDocumentsWorkspace?> read(String userId);
  Future<void> write(String userId, Map<String, dynamic> payload);
}

class CachedDocumentsWorkspace {
  const CachedDocumentsWorkspace({required this.payload, required this.cachedAt});

  final Map<String, dynamic> payload;
  final DateTime cachedAt;
}

class HiveDocumentCache implements DocumentCache {
  static const _boxName = 'siteseva.documents.cache.v1';

  Future<Box<dynamic>> _box() => Hive.openBox<dynamic>(_boxName);

  @override
  Future<CachedDocumentsWorkspace?> read(String userId) async {
    if (userId.isEmpty) return null;
    final raw = (await _box()).get(userId);
    if (raw is! Map) return null;
    final payload = raw['payload'];
    final cachedAt = DateTime.tryParse('${raw['cached_at'] ?? ''}');
    if (payload is! Map || cachedAt == null) return null;
    return CachedDocumentsWorkspace(
      payload: _stringMap(payload),
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
}

Map<String, dynamic> _stringMap(Map<dynamic, dynamic> source) =>
    source.map((key, value) => MapEntry('$key', _normalize(value)));

dynamic _normalize(Object? value) {
  if (value is Map) return _stringMap(value);
  if (value is List) return value.map(_normalize).toList(growable: false);
  return value;
}
