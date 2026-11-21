import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../auth/providers/auth_provider.dart';
import '../data/estimate_cache.dart';
import '../data/estimate_remote_data_source.dart';
import '../data/estimate_repository_impl.dart';
import '../models/estimate_models.dart';
import '../repository/estimate_repository.dart';

final estimateRemoteDataSourceProvider = Provider<EstimateRemoteDataSource>(
  (ref) => const HttpEstimateRemoteDataSource(),
);

final estimateCacheProvider = Provider<EstimateCache>(
  (ref) => HiveEstimateCache(),
);

final estimateRepositoryProvider = Provider<EstimateRepository>((ref) {
  final user = ref.watch(authControllerProvider).valueOrNull;
  return EstimateRepositoryImpl(
    remote: ref.watch(estimateRemoteDataSourceProvider),
    cache: ref.watch(estimateCacheProvider),
    userId: user?.id ?? '',
    canManage: user?.isContractor == true,
  );
});

final estimateStudioControllerProvider =
    StateNotifierProvider<
      EstimateStudioController,
      AsyncValue<EstimateStudioData>
    >((ref) {
      final controller = EstimateStudioController(
        ref.watch(estimateRepositoryProvider),
      );
      unawaited(controller.load());
      return controller;
    });

final estimateDetailControllerProvider = StateNotifierProvider.autoDispose
    .family<EstimateDetailController, AsyncValue<EstimateDocument>, String>((
      ref,
      estimateId,
    ) {
      final controller = EstimateDetailController(
        repository: ref.watch(estimateRepositoryProvider),
        estimateId: estimateId,
      );
      unawaited(controller.load());
      return controller;
    });

final estimateBriefProvider =
    StateNotifierProvider.autoDispose<EstimateBriefController, EstimateBrief>(
      (ref) => EstimateBriefController(),
    );

class EstimateActionState {
  const EstimateActionState({this.value = const AsyncValue.data(null)});
  final AsyncValue<EstimateDocument?> value;
  bool get isLoading => value.isLoading;
}

final estimateActionControllerProvider =
    StateNotifierProvider.autoDispose<
      EstimateActionController,
      EstimateActionState
    >((ref) {
      return EstimateActionController(
        repository: ref.watch(estimateRepositoryProvider),
        onCreated: (estimateId) async {
          try {
            await ref.read(estimateStudioControllerProvider.notifier).refresh();
          } catch (_) {
            // Creation remains successful if a subsequent refresh is offline.
          }
          ref.invalidate(estimateDetailControllerProvider(estimateId));
        },
      );
    });

class EstimateStudioController
    extends StateNotifier<AsyncValue<EstimateStudioData>> {
  EstimateStudioController(this._repository)
    : super(const AsyncValue.loading());

  final EstimateRepository _repository;

  Future<void> load() async {
    state = const AsyncValue.loading();
    state = await AsyncValue.guard(_repository.fetchStudio);
  }

  Future<void> refresh() async {
    final previous = state.valueOrNull;
    try {
      final fresh = await _repository.fetchStudio();
      state = AsyncValue.data(
        fresh.copyWith(
          query: previous?.query,
          siteFilter: previous?.siteFilter,
          qualityFilter: previous?.qualityFilter,
        ),
      );
    } catch (error, stackTrace) {
      if (previous == null) state = AsyncValue.error(error, stackTrace);
      rethrow;
    }
  }

  void setQuery(String query) {
    final value = state.valueOrNull;
    if (value != null) state = AsyncValue.data(value.copyWith(query: query));
  }

  void setSite(String? siteId) {
    final value = state.valueOrNull;
    if (value != null) {
      state = AsyncValue.data(
        value.copyWith(siteFilter: siteId, clearSite: siteId == null),
      );
    }
  }

  void setQuality(EstimateQuality? quality) {
    final value = state.valueOrNull;
    if (value != null) {
      state = AsyncValue.data(
        value.copyWith(qualityFilter: quality, clearQuality: quality == null),
      );
    }
  }
}

class EstimateDetailController
    extends StateNotifier<AsyncValue<EstimateDocument>> {
  EstimateDetailController({
    required EstimateRepository repository,
    required this.estimateId,
  }) : _repository = repository,
       super(const AsyncValue.loading());

  final EstimateRepository _repository;
  final String estimateId;

  Future<void> load() async {
    state = const AsyncValue.loading();
    state = await AsyncValue.guard(() => _repository.fetchEstimate(estimateId));
  }
}

class EstimateBriefController extends StateNotifier<EstimateBrief> {
  EstimateBriefController() : super(EstimateBrief.initial());

  void reset() => state = EstimateBrief.initial();
  void setSite(String value) => state = state.copyWith(siteId: value);
  void setName(String value) => state = state.copyWith(name: value);
  void setPlotArea(String value) =>
      state = state.copyWith(plotAreaSqft: double.tryParse(value) ?? 0);
  void setFloors(String value) =>
      state = state.copyWith(floors: int.tryParse(value) ?? 0);
  void setBasement(bool value) => state = state.copyWith(basement: value);
  void setConstructionType(EstimateConstructionType value) =>
      state = state.copyWith(constructionType: value);
  void setQuality(EstimateQuality value) =>
      state = state.copyWith(quality: value);
  void setBudget(String value) =>
      state = state.copyWith(budget: double.tryParse(value) ?? 0);
}

class EstimateActionController extends StateNotifier<EstimateActionState> {
  EstimateActionController({
    required EstimateRepository repository,
    required Future<void> Function(String estimateId) onCreated,
  }) : _repository = repository,
       _onCreated = onCreated,
       super(const EstimateActionState());

  final EstimateRepository _repository;
  final Future<void> Function(String estimateId) _onCreated;

  Future<EstimateDocument?> create(EstimateBrief brief) async {
    state = const EstimateActionState(value: AsyncValue.loading());
    try {
      final estimate = await _repository.create(brief);
      state = EstimateActionState(value: AsyncValue.data(estimate));
      await _onCreated(estimate.id);
      return estimate;
    } catch (error, stackTrace) {
      state = EstimateActionState(value: AsyncValue.error(error, stackTrace));
      return null;
    }
  }
}
