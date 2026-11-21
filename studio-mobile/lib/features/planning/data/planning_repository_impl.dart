import '../../../core/network/api_service.dart';
import '../../auth/models/auth_user.dart';
import '../models/planning_models.dart';
import '../repository/planning_repository.dart';
import 'planning_remote_data_source.dart';

class PlanningRepositoryImpl implements PlanningRepository {
  const PlanningRepositoryImpl({required PlanningRemoteDataSource remote, required AuthUser? user}) : _remote = remote, _user = user;
  final PlanningRemoteDataSource _remote;
  final AuthUser? _user;
  @override
  Future<PlanningWorkspaceData> fetchWorkspace() async {
    final user = _user ?? (throw const ApiException('Sign in again to view planning.', statusCode: 401, kind: ApiErrorKind.authentication));
    try { return PlanningWorkspaceData.fromJson(user, await _remote.fetchOverview()); }
    on ApiException catch (error) { if (error.statusCode == 404) return PlanningWorkspaceData.unavailable(user); rethrow; }
  }

  @override
  Future<List<PlanningSite>> fetchSites() async => (await _remote.fetchSites())
      .map(PlanningSite.fromJson)
      .where((site) => site.id.isNotEmpty)
      .toList(growable: false);

  @override
  Future<void> createTask(PlanningCreateInput input) async {
    _requireFieldWrite();
    final validation = input.validationMessage;
    if (validation != null) throw ApiException(validation, kind: ApiErrorKind.invalidResponse);
    await _remote.createTask(input.taskJson());
  }

  @override
  Future<void> createSchedule(PlanningCreateInput input) async {
    _requireFieldWrite();
    final validation = input.validationMessage;
    if (validation != null) throw ApiException(validation, kind: ApiErrorKind.invalidResponse);
    await _remote.createSchedule(input.scheduleJson());
  }

  @override
  Future<void> decideApproval(String approvalId, ApprovalDecisionInput input) async {
    final user = _user;
    if (user == null || (!user.isContractor && !user.isClient)) {
      throw const ApiException('Your role cannot decide approvals.', statusCode: 403, kind: ApiErrorKind.authentication);
    }
    await _remote.decideApproval(approvalId, input.toJson());
  }

  void _requireFieldWrite() {
    final user = _user;
    if (user?.isContractor == true || user?.isSupervisor == true) return;
    throw const ApiException('Only contractors and supervisors can create site planning records.', statusCode: 403, kind: ApiErrorKind.authentication);
  }
}
