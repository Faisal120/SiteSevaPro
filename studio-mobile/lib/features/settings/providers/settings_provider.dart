import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../auth/providers/auth_provider.dart';
import '../data/settings_remote_data_source.dart';
import '../data/settings_repository_impl.dart';
import '../models/settings_models.dart';
import '../repository/settings_repository.dart';

final settingsRemoteDataSourceProvider = Provider<SettingsRemoteDataSource>(
  (ref) => const HttpSettingsRemoteDataSource(),
);

final settingsRepositoryProvider = Provider<SettingsRepository>((ref) {
  return SettingsRepositoryImpl(
    remote: ref.watch(settingsRemoteDataSourceProvider),
    fallbackUser: ref.watch(authControllerProvider).valueOrNull,
  );
});

final settingsControllerProvider =
    StateNotifierProvider.autoDispose<
      SettingsController,
      AsyncValue<SettingsWorkspaceData>
    >((ref) {
      final controller = SettingsController(
        ref.watch(settingsRepositoryProvider),
      );
      unawaited(controller.load());
      return controller;
    });

final subscriptionRenewalControllerProvider =
    StateNotifierProvider.autoDispose<
      SubscriptionRenewalController,
      AsyncValue<bool>
    >(
      (ref) =>
          SubscriptionRenewalController(ref.watch(settingsRepositoryProvider)),
    );

final passwordChangeControllerProvider =
    StateNotifierProvider.autoDispose<
      PasswordChangeController,
      AsyncValue<bool>
    >((ref) => PasswordChangeController(ref.watch(settingsRepositoryProvider)));

final preferencesControllerProvider =
    StateNotifierProvider.autoDispose<PreferencesController, AsyncValue<bool>>(
      (ref) => PreferencesController(ref.watch(settingsRepositoryProvider)),
    );

class SettingsController
    extends StateNotifier<AsyncValue<SettingsWorkspaceData>> {
  SettingsController(this._repository) : super(const AsyncValue.loading());

  final SettingsRepository _repository;

  Future<void> load() async {
    state = const AsyncValue.loading();
    state = await AsyncValue.guard<SettingsWorkspaceData>(
      _repository.fetchWorkspace,
    );
  }

  Future<void> refresh() async {
    final previous = state.valueOrNull;
    if (previous == null) return load();
    try {
      state = AsyncValue.data(await _repository.fetchWorkspace());
    } catch (error, stackTrace) {
      state = AsyncValue<SettingsWorkspaceData>.error(
        error,
        stackTrace,
      ).copyWithPrevious(AsyncValue.data(previous));
    }
  }
}

class SubscriptionRenewalController extends StateNotifier<AsyncValue<bool>> {
  SubscriptionRenewalController(this._repository)
    : super(const AsyncValue.data(false));
  final SettingsRepository _repository;

  Future<bool> request() async {
    state = const AsyncValue.loading();
    try {
      await _repository.requestSubscriptionRenewal();
      state = const AsyncValue.data(true);
      return true;
    } catch (error, stackTrace) {
      state = AsyncValue.error(error, stackTrace);
      return false;
    }
  }
}

class PreferencesController extends StateNotifier<AsyncValue<bool>> {
  PreferencesController(this._repository) : super(const AsyncValue.data(false));
  final SettingsRepository _repository;

  Future<bool> save(WorkspacePreferences preferences) async {
    state = const AsyncValue.loading();
    try {
      await _repository.updateCompanyPreferences(preferences);
      state = const AsyncValue.data(true);
      return true;
    } catch (error, stackTrace) {
      state = AsyncValue.error(error, stackTrace);
      return false;
    }
  }
}

class PasswordChangeController extends StateNotifier<AsyncValue<bool>> {
  PasswordChangeController(this._repository)
    : super(const AsyncValue.data(false));
  final SettingsRepository _repository;

  Future<bool> change({
    required String currentPassword,
    required String newPassword,
  }) async {
    if (newPassword.length < 8) {
      state = AsyncValue.error(
        ArgumentError('Use at least 8 characters for the new password.'),
        StackTrace.current,
      );
      return false;
    }
    state = const AsyncValue.loading();
    try {
      await _repository.changePassword(
        currentPassword: currentPassword,
        newPassword: newPassword,
      );
      state = const AsyncValue.data(true);
      return true;
    } catch (error, stackTrace) {
      state = AsyncValue.error(error, stackTrace);
      return false;
    }
  }
}
