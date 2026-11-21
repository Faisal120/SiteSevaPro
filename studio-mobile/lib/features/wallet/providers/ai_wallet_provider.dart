import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../auth/providers/auth_provider.dart';
import '../data/ai_wallet_cache.dart';
import '../data/ai_wallet_remote_data_source.dart';
import '../data/ai_wallet_repository_impl.dart';
import '../models/ai_wallet_models.dart';
import '../repository/ai_wallet_repository.dart';

final aiWalletRemoteDataSourceProvider = Provider<AiWalletRemoteDataSource>(
  (ref) => const HttpAiWalletRemoteDataSource(),
);

final aiWalletCacheProvider = Provider<AiWalletCache>(
  (ref) => HiveAiWalletCache(),
);

final aiWalletRepositoryProvider = Provider<AiWalletRepository>((ref) {
  return AiWalletRepositoryImpl(
    remote: ref.watch(aiWalletRemoteDataSourceProvider),
    cache: ref.watch(aiWalletCacheProvider),
    user: ref.watch(authControllerProvider).valueOrNull,
  );
});

final aiWalletControllerProvider = StateNotifierProvider.autoDispose<
  AiWalletController,
  AsyncValue<AiWalletData>
>((ref) {
  final controller = AiWalletController(ref.watch(aiWalletRepositoryProvider));
  unawaited(controller.load());
  return controller;
});

class AiWalletController extends StateNotifier<AsyncValue<AiWalletData>> {
  AiWalletController(this._repository) : super(const AsyncValue.loading());

  final AiWalletRepository _repository;

  Future<void> load() async {
    state = const AsyncValue.loading();
    state = await AsyncValue.guard(_repository.fetchWallet);
  }

  Future<void> refresh() async {
    final previous = state.valueOrNull;
    try {
      state = AsyncValue.data(await _repository.fetchWallet());
    } catch (error, stackTrace) {
      if (previous == null) state = AsyncValue.error(error, stackTrace);
      rethrow;
    }
  }

  Future<AiCreditPurchaseRequest> requestPurchase(
    AiCreditPurchaseInput input,
  ) async {
    final request = await _repository.requestPurchase(input);
    await refresh();
    return request;
  }
}
