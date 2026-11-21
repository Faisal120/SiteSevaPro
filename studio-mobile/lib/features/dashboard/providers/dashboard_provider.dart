import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../auth/providers/auth_provider.dart';
import '../data/dashboard_cache.dart';
import '../data/dashboard_remote_data_source.dart';
import '../data/dashboard_repository_impl.dart';
import '../models/dashboard_data.dart';
import '../repository/dashboard_repository.dart';

final dashboardRemoteDataSourceProvider = Provider<DashboardRemoteDataSource>(
  (ref) => const HttpDashboardRemoteDataSource(),
);

final dashboardCacheProvider = Provider<DashboardCache>(
  (ref) => HiveDashboardCache(),
);

final dashboardRepositoryProvider = Provider<DashboardRepository>((ref) {
  final user = ref.watch(authControllerProvider).valueOrNull;
  return DashboardRepositoryImpl(
    remote: ref.watch(dashboardRemoteDataSourceProvider),
    cache: ref.watch(dashboardCacheProvider),
    userId: user?.id ?? '',
    role: user?.role ?? '',
  );
});

final dashboardControllerProvider =
    StateNotifierProvider<DashboardController, AsyncValue<DashboardData>>((
      ref,
    ) {
      final controller = DashboardController(
        ref.watch(dashboardRepositoryProvider),
      );
      unawaited(controller.load());
      return controller;
    });

final dashboardClockProvider = StreamProvider.autoDispose<DateTime>((
  ref,
) async* {
  yield DateTime.now();
  yield* Stream<DateTime>.periodic(
    const Duration(minutes: 1),
    (_) => DateTime.now(),
  );
});

class DashboardController extends StateNotifier<AsyncValue<DashboardData>> {
  DashboardController(this._repository) : super(const AsyncValue.loading());

  final DashboardRepository _repository;

  Future<void> load() async {
    state = const AsyncValue.loading();
    state = await AsyncValue.guard(_repository.fetch);
  }

  Future<void> refresh() async {
    final previous = state.valueOrNull;
    if (previous == null) state = const AsyncValue.loading();
    try {
      state = AsyncValue.data(await _repository.fetch());
    } catch (error, stackTrace) {
      state = AsyncValue.error(error, stackTrace);
    }
  }
}
