import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../auth/providers/auth_provider.dart';
import '../data/crm_cache.dart';
import '../data/crm_remote_data_source.dart';
import '../data/crm_repository_impl.dart';
import '../models/crm_models.dart';
import '../repository/crm_repository.dart';

final crmRemoteDataSourceProvider = Provider<CrmRemoteDataSource>(
  (ref) => const HttpCrmRemoteDataSource(),
);

final crmCacheProvider = Provider<CrmCache>((ref) => HiveCrmCache());

final crmRepositoryProvider = Provider<CrmRepository>((ref) {
  final user = ref.watch(authControllerProvider).valueOrNull;
  return CrmRepositoryImpl(
    remote: ref.watch(crmRemoteDataSourceProvider),
    cache: ref.watch(crmCacheProvider),
    userId: user?.id ?? '',
    role: user?.role ?? '',
  );
});

final crmControllerProvider =
    StateNotifierProvider<CrmController, AsyncValue<CrmWorkspaceData>>((ref) {
      final controller = CrmController(ref.watch(crmRepositoryProvider));
      unawaited(controller.load());
      return controller;
    });

final crmActionControllerProvider =
    StateNotifierProvider.autoDispose<CrmActionController, CrmActionState>(
      (ref) => CrmActionController(
        repository: ref.watch(crmRepositoryProvider),
        onChanged: () async {
          await ref.read(crmControllerProvider.notifier).refresh();
        },
      ),
    );

class CrmController extends StateNotifier<AsyncValue<CrmWorkspaceData>> {
  CrmController(this._repository) : super(const AsyncValue.loading());

  final CrmRepository _repository;

  Future<void> load() async {
    state = const AsyncValue.loading();
    state = await AsyncValue.guard(_repository.fetchWorkspace);
  }

  Future<void> refresh() async {
    final previous = state.valueOrNull;
    try {
      final fresh = await _repository.fetchWorkspace();
      state = AsyncValue.data(
        fresh.copyWith(
          workspace: previous?.workspace,
          query: previous?.query,
        ),
      );
    } catch (error, stackTrace) {
      if (previous == null) state = AsyncValue.error(error, stackTrace);
      rethrow;
    }
  }

  void setWorkspace(CrmWorkspace workspace) {
    final data = state.valueOrNull;
    if (data != null) state = AsyncValue.data(data.copyWith(workspace: workspace));
  }

  void setQuery(String query) {
    final data = state.valueOrNull;
    if (data != null) state = AsyncValue.data(data.copyWith(query: query));
  }
}

enum CrmActionPhase { idle, creating, completing }

class CrmActionState {
  const CrmActionState({
    this.phase = CrmActionPhase.idle,
    this.value = const AsyncValue.data(null),
  });

  final CrmActionPhase phase;
  final AsyncValue<Object?> value;

  bool get isLoading => value.isLoading;
}

class CrmActionController extends StateNotifier<CrmActionState> {
  CrmActionController({required CrmRepository repository, required this.onChanged})
    : _repository = repository,
      super(const CrmActionState());

  final CrmRepository _repository;
  final Future<void> Function() onChanged;

  Future<bool> createLead(CrmLeadInput input) async => _run(() async {
    await _repository.createLead(input);
    await onChanged();
  });

  Future<bool> createContact(CrmContactInput input) async => _run(() async {
    await _repository.createContact(input);
    await onChanged();
  });

  Future<bool> createActivity(CrmActivityInput input) async => _run(() async {
    await _repository.createActivity(input);
    await onChanged();
  });

  Future<bool> createQuotation(CrmQuotationInput input) async => _run(() async {
    await _repository.createQuotation(input);
    await onChanged();
  });

  Future<bool> completeActivity(String id) async => _run(
    () async {
      await _repository.completeActivity(id);
      await onChanged();
    },
    phase: CrmActionPhase.completing,
  );

  Future<bool> _run(
    Future<void> Function() action, {
    CrmActionPhase phase = CrmActionPhase.creating,
  }) async {
    state = CrmActionState(phase: phase, value: const AsyncValue.loading());
    try {
      await action();
      state = CrmActionState(phase: phase, value: const AsyncValue.data(true));
      return true;
    } catch (error, stackTrace) {
      state = CrmActionState(
        phase: phase,
        value: AsyncValue.error(error, stackTrace),
      );
      return false;
    }
  }
}
