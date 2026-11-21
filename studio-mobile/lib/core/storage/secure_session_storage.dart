import 'dart:convert';

import 'package:flutter_secure_storage/flutter_secure_storage.dart';

import '../../features/auth/models/auth_user.dart';

abstract interface class SessionStorage {
  Future<StoredSession?> read();
  Future<void> write({required String token, required AuthUser user});
  Future<void> clear();
}

class StoredSession {
  const StoredSession({required this.token, required this.user});

  final String token;
  final AuthUser user;
}

class SecureSessionStorage implements SessionStorage {
  SecureSessionStorage({FlutterSecureStorage? storage})
    : _storage = storage ?? const FlutterSecureStorage();

  static const _tokenKey = 'siteseva.session.token';
  static const _userKey = 'siteseva.session.user';

  final FlutterSecureStorage _storage;

  @override
  Future<StoredSession?> read() async {
    final values = await Future.wait([
      _storage.read(key: _tokenKey),
      _storage.read(key: _userKey),
    ]);
    final token = values[0];
    final encodedUser = values[1];
    if (token == null || token.isEmpty || encodedUser == null) return null;

    try {
      final user = AuthUser.fromJson(
        Map<String, dynamic>.from(jsonDecode(encodedUser) as Map),
      );
      return StoredSession(token: token, user: user);
    } on FormatException {
      await clear();
      return null;
    } on TypeError {
      await clear();
      return null;
    }
  }

  @override
  Future<void> write({required String token, required AuthUser user}) async {
    await Future.wait([
      _storage.write(key: _tokenKey, value: token),
      _storage.write(key: _userKey, value: jsonEncode(user.toJson())),
    ]);
  }

  @override
  Future<void> clear() => Future.wait([
    _storage.delete(key: _tokenKey),
    _storage.delete(key: _userKey),
  ]).then((_) {});
}
