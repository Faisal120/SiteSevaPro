import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../auth/providers/auth_provider.dart';
import '../data/boq_cache.dart';
import '../data/boq_remote_data_source.dart';
import '../data/boq_repository_impl.dart';
import '../models/boq_models.dart';
import '../repository/boq_repository.dart';

final boqRemoteDataSourceProvider = Provider<BoqRemoteDataSource>(
  (ref) => const HttpBoqRemoteDataSource(),
);

final boqCacheProvider = Provider<BoqCache>((ref) => HiveBoqCache());

final boqRepositoryProvider = Provider<BoqRepository>((ref) {
  final user = ref.watch(authControllerProvider).valueOrNull;
  return BoqRepositoryImpl(
    remote: ref.watch(boqRemoteDataSourceProvider),
    cache: ref.watch(boqCacheProvider),
    userId: user?.id ?? '',
    canManage: user?.isContractor == true,
  );
});

final boqStudioControllerProvider =
    StateNotifierProvider<BoqStudioController, AsyncValue<BoqStudioData>>((
      ref,
    ) {
      final controller = BoqStudioController(ref.watch(boqRepositoryProvider));
      unawaited(controller.load());
      return controller;
    });

final boqDetailControllerProvider = StateNotifierProvider.autoDispose
    .family<BoqDetailController, AsyncValue<BoqDocument>, String>((ref, boqId) {
      final controller = BoqDetailController(
        repository: ref.watch(boqRepositoryProvider),
        boqId: boqId,
      );
      unawaited(controller.load());
      return controller;
    });

final boqGenerationBriefProvider =
    StateNotifierProvider.autoDispose<
      BoqGenerationBriefController,
      BoqGenerationBrief
    >((ref) => BoqGenerationBriefController());

class BoqActionState {
  const BoqActionState({this.value = const AsyncValue.data(null)});
  final AsyncValue<BoqDocument?> value;

  bool get isLoading => value.isLoading;
}

final boqActionControllerProvider =
    StateNotifierProvider.autoDispose<BoqActionController, BoqActionState>((
      ref,
    ) {
      return BoqActionController(
        repository: ref.watch(boqRepositoryProvider),
        onGenerated: (boqId) async {
          try {
            await ref.read(boqStudioControllerProvider.notifier).refresh();
          } catch (_) {
            // A successful generation remains successful if the refresh is offline.
          }
          ref.invalidate(boqDetailControllerProvider(boqId));
        },
      );
    });

class BoqStudioController extends StateNotifier<AsyncValue<BoqStudioData>> {
  BoqStudioController(this._repository) : super(const AsyncValue.loading());

  final BoqRepository _repository;

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
}

class BoqDetailController extends StateNotifier<AsyncValue<BoqDocument>> {
  BoqDetailController({required BoqRepository repository, required this.boqId})
    : _repository = repository,
      super(const AsyncValue.loading());

  final BoqRepository _repository;
  final String boqId;

  Future<void> load() async {
    state = const AsyncValue.loading();
    state = await AsyncValue.guard(() => _repository.fetchBoq(boqId));
  }
}

class BoqGenerationBriefController extends StateNotifier<BoqGenerationBrief> {
  BoqGenerationBriefController() : super(BoqGenerationBrief.initial());

  void reset() => state = BoqGenerationBrief.initial();
  void setName(String value) => state = state.copyWith(name: value);
  void setSite(String value) =>
      state = state.copyWith(siteId: value, estimateId: '');
  void setSource(BoqGenerationSource value) => state = state.copyWith(
    source: value,
    estimateId: value == BoqGenerationSource.estimate ? state.estimateId : '',
  );
  void setEstimate(String value) => state = state.copyWith(estimateId: value);
  void setBuiltup(String value) =>
      state = state.copyWith(builtupSqft: double.tryParse(value) ?? 0);
}

class BoqActionController extends StateNotifier<BoqActionState> {
  BoqActionController({
    required BoqRepository repository,
    required Future<void> Function(String boqId) onGenerated,
  }) : _repository = repository,
       _onGenerated = onGenerated,
       super(const BoqActionState());

  final BoqRepository _repository;
  final Future<void> Function(String boqId) _onGenerated;

  Future<BoqDocument?> generate(BoqGenerationBrief brief) async {
    state = const BoqActionState(value: AsyncValue.loading());
    try {
      final document = await _repository.generate(brief);
      state = BoqActionState(value: AsyncValue.data(document));
      await _onGenerated(document.id);
      return document;
    } catch (error, stackTrace) {
      state = BoqActionState(value: AsyncValue.error(error, stackTrace));
      return null;
    }
  }
}
