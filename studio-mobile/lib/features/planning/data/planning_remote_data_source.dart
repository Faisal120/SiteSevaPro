import '../../../core/network/api_service.dart';

abstract interface class PlanningRemoteDataSource {
  Future<Map<String, dynamic>> fetchOverview();
  Future<List<Map<String, dynamic>>> fetchSites();
  Future<Map<String, dynamic>> createTask(Map<String, dynamic> payload);
  Future<Map<String, dynamic>> createSchedule(Map<String, dynamic> payload);
  Future<Map<String, dynamic>> decideApproval(
    String approvalId,
    Map<String, dynamic> payload,
  );
}
class HttpPlanningRemoteDataSource implements PlanningRemoteDataSource {
  const HttpPlanningRemoteDataSource();
  @override
  Future<Map<String, dynamic>> fetchOverview() => ApiService.getPlanningOverview();
  @override
  Future<List<Map<String, dynamic>>> fetchSites() => ApiService.getSites();
  @override
  Future<Map<String, dynamic>> createTask(Map<String, dynamic> payload) =>
      ApiService.createPlanningTask(payload);
  @override
  Future<Map<String, dynamic>> createSchedule(Map<String, dynamic> payload) =>
      ApiService.createPlanningSchedule(payload);
  @override
  Future<Map<String, dynamic>> decideApproval(String approvalId, Map<String, dynamic> payload) =>
      ApiService.decidePlanningApproval(approvalId, payload);
}
