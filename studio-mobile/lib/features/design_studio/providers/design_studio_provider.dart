import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../auth/providers/auth_provider.dart';
import '../data/design_studio_cache.dart';
import '../data/design_studio_remote_data_source.dart';
import '../data/design_studio_repository_impl.dart';
import '../models/design_models.dart';
import '../repository/design_studio_repository.dart';

final designStudioRemoteDataSourceProvider =
    Provider<DesignStudioRemoteDataSource>(
      (ref) => const HttpDesignStudioRemoteDataSource(),
    );

final designStudioCacheProvider = Provider<DesignStudioCache>(
  (ref) => HiveDesignStudioCache(),
);

final designStudioRepositoryProvider = Provider<DesignStudioRepository>((ref) {
  final user = ref.watch(authControllerProvider).valueOrNull;
  return DesignStudioRepositoryImpl(
    remote: ref.watch(designStudioRemoteDataSourceProvider),
    cache: ref.watch(designStudioCacheProvider),
    userId: user?.id ?? '',
    canManage: user?.isContractor == true,
  );
});

final designStudioControllerProvider =
    StateNotifierProvider<DesignStudioController, AsyncValue<DesignStudioData>>(
      (ref) {
        final controller = DesignStudioController(
          ref.watch(designStudioRepositoryProvider),
        );
        unawaited(controller.load());
        return controller;
      },
    );

final designDetailControllerProvider = StateNotifierProvider.autoDispose
    .family<DesignDetailController, AsyncValue<DesignRecord>, String>((
      ref,
      designId,
    ) {
      final controller = DesignDetailController(
        repository: ref.watch(designStudioRepositoryProvider),
        designId: designId,
      );
      unawaited(controller.load());
      return controller;
    });

final designBriefControllerProvider =
    StateNotifierProvider.autoDispose<DesignBriefController, DesignBrief>(
      (ref) => DesignBriefController(),
    );

enum DesignActionPhase {
  idle,
  generating,
  technical,
  threeD,
  exporting,
  purchasing,
  deleting,
}

class DesignActionState {
  const DesignActionState({
    this.phase = DesignActionPhase.idle,
    this.value = const AsyncValue.data(null),
  });

  final DesignActionPhase phase;
  final AsyncValue<Object?> value;

  bool get isLoading => value.isLoading;

  String get message => switch (phase) {
    DesignActionPhase.generating =>
      'Solving room adjacency, circulation and drawing documentation...',
    DesignActionPhase.technical => 'Generating the selected technical layer...',
    DesignActionPhase.threeD => 'Building the furnished open-top 3D concept...',
    DesignActionPhase.exporting => 'Preparing the authenticated PDF sheet...',
    DesignActionPhase.purchasing =>
      'Submitting the UPI reference for verification...',
    DesignActionPhase.deleting => 'Removing this design version...',
    DesignActionPhase.idle => '',
  };
}

final designActionControllerProvider =
    StateNotifierProvider.autoDispose<
      DesignActionController,
      DesignActionState
    >((ref) {
      return DesignActionController(
        repository: ref.watch(designStudioRepositoryProvider),
        onChanged: (designId) async {
          try {
            await ref.read(designStudioControllerProvider.notifier).refresh();
          } catch (_) {
            // A completed mutation should not be reported as failed if refresh fails.
          }
          if (designId != null) {
            ref.invalidate(designDetailControllerProvider(designId));
          }
        },
      );
    });

class DesignStudioController
    extends StateNotifier<AsyncValue<DesignStudioData>> {
  DesignStudioController(this._repository) : super(const AsyncValue.loading());

  final DesignStudioRepository _repository;

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
          statusFilter: previous?.statusFilter,
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

  void setStatus(DesignStatus? status) {
    final value = state.valueOrNull;
    if (value != null) {
      state = AsyncValue.data(
        value.copyWith(statusFilter: status, clearStatus: status == null),
      );
    }
  }
}

class DesignDetailController extends StateNotifier<AsyncValue<DesignRecord>> {
  DesignDetailController({
    required DesignStudioRepository repository,
    required this.designId,
  }) : _repository = repository,
       super(const AsyncValue.loading());

  final DesignStudioRepository _repository;
  final String designId;

  Future<void> load() async {
    state = const AsyncValue.loading();
    state = await AsyncValue.guard(() => _repository.fetchDesign(designId));
  }

  Future<void> refresh() => load();
}

class DesignBriefController extends StateNotifier<DesignBrief> {
  DesignBriefController() : super(DesignBrief.initial());

  void reset([DesignBrief? brief]) => state = brief ?? DesignBrief.initial();
  void setSite(String value) => state = state.copyWith(siteId: value);
  void setProjectName(String value) =>
      state = state.copyWith(projectName: value);
  void setPlotWidth(String value) =>
      state = state.copyWith(plotWidth: double.tryParse(value) ?? 0);
  void setPlotLength(String value) =>
      state = state.copyWith(plotLength: double.tryParse(value) ?? 0);
  void setFacing(String value) => state = state.copyWith(facing: value);
  void setGarden(bool value) => state = state.copyWith(garden: value);

  void setFloors(int floors) {
    final count = floors.clamp(1, 12);
    final requirements = List.generate(count, (index) {
      if (index < state.floorRequirements.length) {
        return state.floorRequirements[index];
      }
      return DesignFloorRequirement(floorNumber: index + 1);
    });
    state = state.copyWith(floors: count, floorRequirements: requirements);
  }

  void updateFloor(
    int floorNumber,
    DesignFloorRequirement Function(DesignFloorRequirement floor) update,
  ) {
    state = state.copyWith(
      floorRequirements: state.floorRequirements
          .map(
            (floor) => floor.floorNumber == floorNumber ? update(floor) : floor,
          )
          .toList(growable: false),
    );
  }
}

class DesignActionController extends StateNotifier<DesignActionState> {
  DesignActionController({
    required DesignStudioRepository repository,
    required Future<void> Function(String? designId) onChanged,
  }) : _repository = repository,
       _onChanged = onChanged,
       super(const DesignActionState());

  final DesignStudioRepository _repository;
  final Future<void> Function(String? designId) _onChanged;

  Future<DesignRecord?> generate(DesignBrief brief) async {
    final result = await _run(
      DesignActionPhase.generating,
      () => _repository.generate(brief),
    );
    if (result is DesignRecord) {
      await _onChanged(result.id);
      return result;
    }
    return null;
  }

  Future<DesignRecord?> generateTechnical(
    String designId,
    DesignDrawingType type,
  ) async {
    final result = await _run(
      DesignActionPhase.technical,
      () => _repository.generateTechnical(designId, type),
    );
    if (result is DesignRecord) {
      await _onChanged(designId);
      return result;
    }
    return null;
  }

  Future<DesignRecord?> generateThreeD(String designId, int floorNumber) async {
    final result = await _run(
      DesignActionPhase.threeD,
      () => _repository.generateThreeD(designId, floorNumber),
    );
    if (result is DesignRecord) {
      await _onChanged(designId);
      return result;
    }
    return null;
  }

  Future<bool> delete(String designId) async {
    final result = await _run(DesignActionPhase.deleting, () async {
      await _repository.deleteDesign(designId);
      return true;
    });
    if (result == true) await _onChanged(null);
    return result == true;
  }

  Future<DesignPurchaseRequest?> requestCredits({
    required String pack,
    required String utr,
    String? note,
  }) async {
    final result = await _run(
      DesignActionPhase.purchasing,
      () => _repository.requestCredits(pack: pack, utr: utr, note: note),
    );
    if (result is DesignPurchaseRequest) {
      await _onChanged(null);
      return result;
    }
    return null;
  }

  Future<T?> export<T>(Future<T> Function() action) async {
    final result = await _run(DesignActionPhase.exporting, action);
    return result is T ? result : null;
  }

  Future<Object?> _run(
    DesignActionPhase phase,
    Future<Object?> Function() action,
  ) async {
    state = DesignActionState(phase: phase, value: const AsyncValue.loading());
    try {
      final result = await action();
      state = DesignActionState(phase: phase, value: AsyncValue.data(result));
      return result;
    } catch (error, stackTrace) {
      state = DesignActionState(
        phase: phase,
        value: AsyncValue.error(error, stackTrace),
      );
      return null;
    }
  }
}
