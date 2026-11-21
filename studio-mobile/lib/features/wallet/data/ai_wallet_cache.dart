import 'package:hive_flutter/hive_flutter.dart';

abstract interface class AiWalletCache {
  Future<CachedAiWallet?> read(String userId);
  Future<void> write(String userId, Map<String, dynamic> payload);
}

class CachedAiWallet {
  const CachedAiWallet({required this.payload, required this.cachedAt});
  final Map<String, dynamic> payload;
  final DateTime cachedAt;
}

class HiveAiWalletCache implements AiWalletCache {
  static const _boxName = 'siteseva.ai-wallet.cache.v1';

  Future<Box<dynamic>> _box() => Hive.openBox<dynamic>(_boxName);

  @override
  Future<CachedAiWallet?> read(String userId) async {
    final raw = (await _box()).get(userId);
    if (raw is! Map) return null;
    final payload = raw['payload'];
    final cachedAt = DateTime.tryParse('${raw['cached_at'] ?? ''}');
    if (payload is! Map || cachedAt == null) return null;
    return CachedAiWallet(
      payload: _normalizeMap(payload),
      cachedAt: cachedAt.toLocal(),
    );
  }

  @override
  Future<void> write(String userId, Map<String, dynamic> payload) async {
    await (await _box()).put(userId, {
      'payload': payload,
      'cached_at': DateTime.now().toUtc().toIso8601String(),
    });
  }
}

Map<String, dynamic> _normalizeMap(Map<dynamic, dynamic> value) =>
    value.map((key, item) => MapEntry('$key', _normalize(item)));

dynamic _normalize(dynamic value) {
  if (value is Map) return _normalizeMap(value);
  if (value is List) return value.map(_normalize).toList(growable: false);
  return value;
}
