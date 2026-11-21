import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/storage/secure_session_storage.dart';
import '../data/auth_remote_data_source.dart';
import '../data/auth_repository_impl.dart';
import '../models/auth_user.dart';
import '../models/contractor_application.dart';
import '../repository/auth_repository.dart';
import '../../notifications/data/push_notifications_service.dart';

final sessionStorageProvider = Provider<SessionStorage>(
  (ref) => SecureSessionStorage(),
);

final authRemoteDataSourceProvider = Provider<AuthRemoteDataSource>(
  (ref) => const AuthRemoteDataSource(),
);

final authRepositoryProvider = Provider<AuthRepository>(
  (ref) => AuthRepositoryImpl(
    remote: ref.watch(authRemoteDataSourceProvider),
    storage: ref.watch(sessionStorageProvider),
  ),
);

final authControllerProvider =
    StateNotifierProvider<AuthController, AsyncValue<AuthUser?>>((ref) {
      final controller = AuthController(ref.watch(authRepositoryProvider));
      unawaited(controller.restore());
      return controller;
    });

final contractorApplicationProvider =
    StateNotifierProvider.autoDispose<
      ContractorApplicationController,
      AsyncValue<ContractorApplication?>
    >(
      (ref) =>
          ContractorApplicationController(ref.watch(authRepositoryProvider)),
    );

class AuthController extends StateNotifier<AsyncValue<AuthUser?>> {
  AuthController(this._repository) : super(const AsyncValue.loading());

  final AuthRepository _repository;

  Future<void> restore() async {
    state = const AsyncValue.loading();
    state = await AsyncValue.guard(_repository.restoreSession);
    if (state.valueOrNull != null) {
      unawaited(PushNotificationsService.instance.syncRegistration());
    }
  }

  Future<void> login({
    required String email,
    required String password,
    bool rememberSession = true,
  }) async {
    state = const AsyncValue.loading();
    try {
      final user = await _repository.signIn(
        email: email,
        password: password,
        rememberSession: rememberSession,
      );
      state = AsyncValue.data(user);
      unawaited(PushNotificationsService.instance.syncRegistration());
    } catch (error, stackTrace) {
      state = AsyncValue.error(error, stackTrace);
      rethrow;
    }
  }

  Future<void> logout() async {
    await PushNotificationsService.instance.unregisterCurrentDevice();
    await _repository.signOut();
    state = const AsyncValue.data(null);
  }
}

class ContractorApplicationController
    extends StateNotifier<AsyncValue<ContractorApplication?>> {
  ContractorApplicationController(this._repository)
    : super(const AsyncValue.data(null));

  final AuthRepository _repository;

  Future<ContractorApplication> submit(ContractorApplicationInput input) async {
    state = const AsyncValue.loading();
    try {
      final result = await _repository.submitApplication(input);
      state = AsyncValue.data(result);
      return result;
    } catch (error, stackTrace) {
      state = AsyncValue.error(error, stackTrace);
      rethrow;
    }
  }
}
