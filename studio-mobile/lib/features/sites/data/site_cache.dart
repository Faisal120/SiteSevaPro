import 'package:hive_flutter/hive_flutter.dart';

abstract interface class SiteCache {
  Future<CachedSiteList?> readList(String userId);
  Future<void> writeList(String userId, List<Map<String, dynamic>> payload);
  Future<CachedSiteDetail?> readDetail(String userId, String siteId);
  Future<void> writeDetail(
    String userId,
    String siteId,
    Map<String, dynamic> payload,
  );
  Future<void> removeSite(String userId, String siteId);
  Future<CachedSiteRecords?> readRecords(
    String userId,
    String siteId,
    String type,
  );
  Future<void> writeRecords(
    String userId,
    String siteId,
    String type,
    List<Map<String, dynamic>> payload,
  );
}

class CachedSiteList {
  const CachedSiteList({required this.payload, required this.cachedAt});

  final List<Map<String, dynamic>> payload;
  final DateTime cachedAt;
}

class CachedSiteDetail {
  const CachedSiteDetail({required this.payload, required this.cachedAt});

  final Map<String, dynamic> payload;
  final DateTime cachedAt;
}

class CachedSiteRecords {
  const CachedSiteRecords({required this.payload, required this.cachedAt});

  final List<Map<String, dynamic>> payload;
  final DateTime cachedAt;
}

class HiveSiteCache implements SiteCache {
  static const _boxName = 'siteseva.sites.cache.v1';

  Future<Box<dynamic>> _box() => Hive.openBox<dynamic>(_boxName);

  @override
  Future<CachedSiteList?> readList(String userId) async {
    final raw = (await _box()).get(_listKey(userId));
    if (raw is! Map) return null;
    final payload = raw['payload'];
    final cachedAt = DateTime.tryParse('${raw['cached_at'] ?? ''}');
    if (payload is! List || cachedAt == null) return null;
    return CachedSiteList(
      payload: _mapList(payload),
      cachedAt: cachedAt.toLocal(),
    );
  }

  @override
  Future<void> writeList(String userId, List<Map<String, dynamic>> payload) =>
      _write(_listKey(userId), payload);

  @override
  Future<CachedSiteDetail?> readDetail(String userId, String siteId) async {
    final raw = (await _box()).get(_detailKey(userId, siteId));
    if (raw is! Map) return null;
    final payload = raw['payload'];
    final cachedAt = DateTime.tryParse('${raw['cached_at'] ?? ''}');
    if (payload is! Map || cachedAt == null) return null;
    return CachedSiteDetail(
      payload: _stringMap(payload),
      cachedAt: cachedAt.toLocal(),
    );
  }

  @override
  Future<void> writeDetail(
    String userId,
    String siteId,
    Map<String, dynamic> payload,
  ) => _write(_detailKey(userId, siteId), payload);

  @override
  Future<void> removeSite(String userId, String siteId) async {
    final box = await _box();
    await box.delete(_detailKey(userId, siteId));
    final cached = await readList(userId);
    if (cached == null) return;
    await writeList(
      userId,
      cached.payload.where((site) => '${site['id']}' != siteId).toList(),
    );
  }

  @override
  Future<CachedSiteRecords?> readRecords(
    String userId,
    String siteId,
    String type,
  ) async {
    final raw = (await _box()).get(_recordsKey(userId, siteId, type));
    if (raw is! Map) return null;
    final payload = raw['payload'];
    final cachedAt = DateTime.tryParse('${raw['cached_at'] ?? ''}');
    if (payload is! List || cachedAt == null) return null;
    return CachedSiteRecords(
      payload: _mapList(payload),
      cachedAt: cachedAt.toLocal(),
    );
  }

  @override
  Future<void> writeRecords(
    String userId,
    String siteId,
    String type,
    List<Map<String, dynamic>> payload,
  ) => _write(_recordsKey(userId, siteId, type), payload);

  Future<void> _write(String key, Object payload) async {
    if (key.startsWith('::')) return;
    await (await _box()).put(key, {
      'payload': payload,
      'cached_at': DateTime.now().toUtc().toIso8601String(),
    });
  }

  String _listKey(String userId) => '$userId::list';
  String _detailKey(String userId, String siteId) => '$userId::$siteId::detail';
  String _recordsKey(String userId, String siteId, String type) =>
      '$userId::$siteId::$type';
}

List<Map<String, dynamic>> _mapList(List<dynamic> source) => source
    .whereType<Map>()
    .map((item) => _stringMap(item))
    .toList(growable: false);

Map<String, dynamic> _stringMap(Map<dynamic, dynamic> source) =>
    source.map((key, value) => MapEntry('$key', _normalize(value)));

dynamic _normalize(dynamic value) {
  if (value is Map) return _stringMap(value);
  if (value is List) return value.map(_normalize).toList();
  return value;
}
