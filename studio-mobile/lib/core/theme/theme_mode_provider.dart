import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';

final appThemeModeProvider =
    StateNotifierProvider<ThemeModeController, ThemeMode>((ref) {
      final controller = ThemeModeController();
      unawaited(controller.load());
      return controller;
    });

class ThemeModeController extends StateNotifier<ThemeMode> {
  ThemeModeController({FlutterSecureStorage? storage})
    : _storage = storage ?? const FlutterSecureStorage(),
      super(ThemeMode.system);

  static const _key = 'siteseva.preferences.theme-mode';
  final FlutterSecureStorage _storage;

  Future<void> load() async {
    final raw = await _storage.read(key: _key);
    state = switch (raw) {
      'light' => ThemeMode.light,
      'dark' => ThemeMode.dark,
      _ => ThemeMode.system,
    };
  }

  Future<void> setThemeMode(ThemeMode mode) async {
    state = mode;
    await _storage.write(key: _key, value: mode.name);
  }
}
