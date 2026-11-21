import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'api_client.dart';

class AppController extends ChangeNotifier {
  AppController({ApiClient? api}) : api = api ?? ApiClient();

  static const _tokenKey = 'auth_token';

  final ApiClient api;
  Map<String, dynamic>? user;
  bool isReady = false;

  bool get isLoggedIn => api.token != null && user != null;
  String get role => user?['role']?.toString() ?? '';

  Future<void> initialize() async {
    final preferences = await SharedPreferences.getInstance();
    api.token = preferences.getString(_tokenKey);
    if (api.token != null) {
      try {
        final data = await api.get('/auth/me');
        user = Map<String, dynamic>.from(data as Map);
      } catch (_) {
        await preferences.remove(_tokenKey);
        api.token = null;
      }
    }
    isReady = true;
    notifyListeners();
  }

  Future<void> login(String email, String password) async {
    final data = await api.post(
      '/auth/login',
      body: {'email': email.trim(), 'password': password},
    );
    final result = Map<String, dynamic>.from(data as Map);
    api.token = result['token']?.toString();
    user = Map<String, dynamic>.from(result['user'] as Map);
    final preferences = await SharedPreferences.getInstance();
    await preferences.setString(_tokenKey, api.token!);
    notifyListeners();
  }

  Future<void> refreshUser() async {
    final data = await api.get('/auth/me');
    user = Map<String, dynamic>.from(data as Map);
    notifyListeners();
  }

  Future<void> logout() async {
    final preferences = await SharedPreferences.getInstance();
    await preferences.remove(_tokenKey);
    api.token = null;
    user = null;
    notifyListeners();
  }
}
