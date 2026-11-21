import 'dart:async';
import 'dart:typed_data';

import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../auth/providers/auth_provider.dart';
import '../data/profile_company_cache.dart';
import '../data/profile_company_remote_data_source.dart';
import '../data/profile_company_repository_impl.dart';
import '../models/profile_models.dart';
import '../repository/profile_company_repository.dart';

final profileCompanyRemoteDataSourceProvider =
    Provider<ProfileCompanyRemoteDataSource>(
      (ref) => const HttpProfileCompanyRemoteDataSource(),
    );

final profileCompanyCacheProvider = Provider<ProfileCompanyCache>(
  (ref) => HiveProfileCompanyCache(),
);

final profileCompanyRepositoryProvider = Provider<ProfileCompanyRepository>((
  ref,
) {
  final user = ref.watch(authControllerProvider).valueOrNull;
  return ProfileCompanyRepositoryImpl(
    remote: ref.watch(profileCompanyRemoteDataSourceProvider),
    cache: ref.watch(profileCompanyCacheProvider),
    userId: user?.id ?? '',
    fallbackUser: user,
  );
});

final profileCompanyControllerProvider =
    StateNotifierProvider.autoDispose<ProfileCompanyController,
        AsyncValue<ProfileCompanyData>>((ref) {
      final controller = ProfileCompanyController(
        ref.watch(profileCompanyRepositoryProvider),
      );
      unawaited(controller.load());
      return controller;
    });

class ProfileCompanyController
    extends StateNotifier<AsyncValue<ProfileCompanyData>> {
  ProfileCompanyController(this._repository)
    : super(const AsyncValue.loading());

  final ProfileCompanyRepository _repository;

  Future<void> load() async {
    state = const AsyncValue.loading();
    state = await AsyncValue.guard<ProfileCompanyData>(
      _repository.fetchWorkspace,
    );
  }

  Future<void> refresh() async {
    final previous = state.valueOrNull;
    if (previous == null) state = const AsyncValue.loading();
    try {
      state = AsyncValue.data(await _repository.fetchWorkspace());
    } catch (error, stackTrace) {
      if (previous != null) {
        state = AsyncValue<ProfileCompanyData>.error(
          error,
          stackTrace,
        ).copyWithPrevious(
          AsyncValue<ProfileCompanyData>.data(previous),
        );
      } else {
        state = AsyncValue.error(error, stackTrace);
      }
    }
  }

  Future<void> saveBranding(BrandingUpdate input) async {
    final previous = state.valueOrNull;
    state = const AsyncValue.loading();
    try {
      state = AsyncValue.data(await _repository.saveBranding(input));
    } catch (error, stackTrace) {
      state = previous == null
          ? AsyncValue<ProfileCompanyData>.error(error, stackTrace)
          : AsyncValue<ProfileCompanyData>.error(
              error,
              stackTrace,
            ).copyWithPrevious(
              AsyncValue<ProfileCompanyData>.data(previous),
            );
      rethrow;
    }
  }

  Future<void> uploadLogo({
    required Uint8List bytes,
    required String filename,
  }) async {
    final previous = state.valueOrNull;
    state = const AsyncValue.loading();
    try {
      state = AsyncValue.data(
        await _repository.uploadLogo(bytes: bytes, filename: filename),
      );
    } catch (error, stackTrace) {
      state = previous == null
          ? AsyncValue<ProfileCompanyData>.error(error, stackTrace)
          : AsyncValue<ProfileCompanyData>.error(
              error,
              stackTrace,
            ).copyWithPrevious(
              AsyncValue<ProfileCompanyData>.data(previous),
            );
      rethrow;
    }
  }
}
