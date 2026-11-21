import '../models/planning_models.dart';
abstract interface class PlanningRepository {
  Future<PlanningWorkspaceData> fetchWorkspace();
  Future<List<PlanningSite>> fetchSites();
  Future<void> createTask(PlanningCreateInput input);
  Future<void> createSchedule(PlanningCreateInput input);
  Future<void> decideApproval(String approvalId, ApprovalDecisionInput input);
}
