import 'package:hive_flutter/hive_flutter.dart';

abstract interface class WorkforceCache {
  Future<CachedWorkforcePayload?> readAttendance(
    String userId,
    String siteKey,
    String date,
  );
  Future<void> writeAttendance(
    String userId,
    String siteKey,
    String date,
    Map<String, dynamic> payload,
  );
  Future<CachedWorkforcePayload?> readStudio(String userId);
  Future<void> writeStudio(String userId, Map<String, dynamic> payload);
  Future<CachedWorkforcePayload?> readDetail(String userId, String labourId);
  Future<void> writeDetail(
    String userId,
    String labourId,
    Map<String, dynamic> payload,
  );
  Future<CachedWorkforcePayload?> readPayroll(String userId, String month);
  Future<void> writePayroll(
    String userId,
    String month,
    Map<String, dynamic> payload,
  );
}

class CachedWorkforcePayload {
  const CachedWorkforcePayload({required this.payload, required this.cachedAt});
  final Map<String, dynamic> payload;
  final DateTime cachedAt;
}

class HiveWorkforceCache implements WorkforceCache {
  static const _boxName = 'siteseva.workforce.cache.v1';

  Future<Box<dynamic>> _box() => Hive.openBox<dynamic>(_boxName);

  @override
  Future<CachedWorkforcePayload?> readAttendance(
    String userId,
    String siteKey,
    String date,
  ) => _read('$userId::attendance::$siteKey::$date');

  @override
  Future<void> writeAttendance(
    String userId,
    String siteKey,
    String date,
    Map<String, dynamic> payload,
  ) => _write('$userId::attendance::$siteKey::$date', payload);

  @override
  Future<CachedWorkforcePayload?> readStudio(String userId) =>
      _read('$userId::studio');

  @override
  Future<void> writeStudio(String userId, Map<String, dynamic> payload) =>
      _write('$userId::studio', payload);

  @override
  Future<CachedWorkforcePayload?> readDetail(String userId, String labourId) =>
      _read('$userId::detail::$labourId');

  @override
  Future<void> writeDetail(
    String userId,
    String labourId,
    Map<String, dynamic> payload,
  ) => _write('$userId::detail::$labourId', payload);

  @override
  Future<CachedWorkforcePayload?> readPayroll(String userId, String month) =>
      _read('$userId::payroll::$month');

  @override
  Future<void> writePayroll(
    String userId,
    String month,
    Map<String, dynamic> payload,
  ) => _write('$userId::payroll::$month', payload);

  Future<CachedWorkforcePayload?> _read(String key) async {
    final raw = (await _box()).get(key);
    if (raw is! Map) return null;
    final payload = raw['payload'];
    final cachedAt = DateTime.tryParse('${raw['cached_at'] ?? ''}');
    if (payload is! Map || cachedAt == null) return null;
    return CachedWorkforcePayload(
      payload: _stringMap(payload),
      cachedAt: cachedAt.toLocal(),
    );
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
