import '../../../core/network/api_service.dart';

abstract interface class SiteRemoteDataSource {
  Future<List<Map<String, dynamic>>> fetchSites();
  Future<Map<String, dynamic>> fetchSite(String siteId);
  Future<Map<String, dynamic>> createSite(Map<String, dynamic> payload);
  Future<Map<String, dynamic>> updateSite(
    String siteId,
    Map<String, dynamic> payload,
  );
  Future<void> deleteSite(String siteId);
  Future<List<Map<String, dynamic>>> fetchTeam();
  Future<void> assignSupervisor(String siteId, String userId);
  Future<void> assignClient(String siteId, String userId);
  Future<List<Map<String, dynamic>>> fetchLabour(String siteId);
  Future<List<Map<String, dynamic>>> fetchMaterials(String siteId);
  Future<List<Map<String, dynamic>>> fetchPayments(String siteId);
  Future<List<Map<String, dynamic>>> fetchReports(String siteId);
  Future<List<Map<String, dynamic>>> fetchAttendance(String siteId);
}

class HttpSiteRemoteDataSource implements SiteRemoteDataSource {
  const HttpSiteRemoteDataSource();

  @override
  Future<List<Map<String, dynamic>>> fetchSites() => ApiService.getSites();

  @override
  Future<Map<String, dynamic>> fetchSite(String siteId) =>
      ApiService.getSite(siteId);

  @override
  Future<Map<String, dynamic>> createSite(Map<String, dynamic> payload) =>
      ApiService.createSite(payload);

  @override
  Future<Map<String, dynamic>> updateSite(
    String siteId,
    Map<String, dynamic> payload,
  ) => ApiService.updateSite(siteId, payload);

  @override
  Future<void> deleteSite(String siteId) => ApiService.deleteSite(siteId);

  @override
  Future<List<Map<String, dynamic>>> fetchTeam() => ApiService.getTeam();

  @override
  Future<void> assignSupervisor(String siteId, String userId) =>
      ApiService.assignSiteSupervisor(siteId, userId);

  @override
  Future<void> assignClient(String siteId, String userId) =>
      ApiService.assignSiteClient(siteId, userId);

  @override
  Future<List<Map<String, dynamic>>> fetchLabour(String siteId) =>
      ApiService.getLabour(siteId: siteId);

  @override
  Future<List<Map<String, dynamic>>> fetchMaterials(String siteId) =>
      ApiService.getMaterials(siteId: siteId);

  @override
  Future<List<Map<String, dynamic>>> fetchPayments(String siteId) =>
      ApiService.getPayments(siteId: siteId);

  @override
  Future<List<Map<String, dynamic>>> fetchReports(String siteId) =>
      ApiService.getReports(siteId: siteId);

  @override
  Future<List<Map<String, dynamic>>> fetchAttendance(String siteId) =>
      ApiService.getAttendance(siteId: siteId);
}
