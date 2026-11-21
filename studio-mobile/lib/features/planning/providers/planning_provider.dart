import 'dart:async';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../auth/providers/auth_provider.dart';
import '../data/planning_remote_data_source.dart';
import '../data/planning_repository_impl.dart';
import '../models/planning_models.dart';
import '../repository/planning_repository.dart';

final planningRemoteDataSourceProvider = Provider<PlanningRemoteDataSource>((ref) => const HttpPlanningRemoteDataSource());
final planningRepositoryProvider = Provider<PlanningRepository>((ref) => PlanningRepositoryImpl(remote: ref.watch(planningRemoteDataSourceProvider), user: ref.watch(authControllerProvider).valueOrNull));
final planningControllerProvider = StateNotifierProvider.autoDispose<
  PlanningController,
  AsyncValue<PlanningWorkspaceData>
>((ref) {
  final controller = PlanningController(ref.watch(planningRepositoryProvider));
  unawaited(controller.load());
  return controller;
});

final planningSitesProvider = FutureProvider.autoDispose<List<PlanningSite>>(
  (ref) => ref.watch(planningRepositoryProvider).fetchSites(),
);

final planningActionControllerProvider = StateNotifierProvider.autoDispose<
  PlanningActionController,
  AsyncValue<bool>
>((ref) => PlanningActionController(
  repository: ref.watch(planningRepositoryProvider),
  onChanged: () => ref.read(planningControllerProvider.notifier).load(),
));

class PlanningController extends StateNotifier<AsyncValue<PlanningWorkspaceData>> {
  PlanningController(this._repository) : super(const AsyncValue.loading());
  final PlanningRepository _repository;
  Future<void> load() async => state = await AsyncValue.guard(_repository.fetchWorkspace);
}

class PlanningActionController extends StateNotifier<AsyncValue<bool>> {
  PlanningActionController({required PlanningRepository repository, required this.onChanged})
      : _repository = repository,
        super(const AsyncValue.data(false));
  final PlanningRepository _repository;
  final Future<void> Function() onChanged;

  Future<bool> createTask(PlanningCreateInput input) => _run(() => _repository.createTask(input));
  Future<bool> createSchedule(PlanningCreateInput input) => _run(() => _repository.createSchedule(input));
  Future<bool> decideApproval(String id, ApprovalDecisionInput input) => _run(() => _repository.decideApproval(id, input));

  Future<bool> _run(Future<void> Function() action) async {
    state = const AsyncValue.loading();
    try {
      await action();
      await onChanged();
      state = const AsyncValue.data(true);
      return true;
    } catch (error, stackTrace) {
      state = AsyncValue.error(error, stackTrace);
      return false;
    }
  }
}
