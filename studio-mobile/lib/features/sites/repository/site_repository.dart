import '../models/site_models.dart';
import '../models/site_records.dart';

abstract interface class SiteRepository {
  Future<SiteCollection> fetchSites();
  Future<SiteDetail> fetchSite(String siteId);
  Future<SiteDetail> createSite(SiteMutation mutation);
  Future<SiteDetail> updateSite(String siteId, SiteMutation mutation);
  Future<void> deleteSite(String siteId);
  Future<List<SiteAssignee>> fetchTeam();
  Future<void> assignSupervisor(String siteId, String userId);
  Future<void> assignClient(String siteId, String userId);
  Future<List<SiteLabour>> fetchLabour(String siteId);
  Future<List<SiteMaterial>> fetchMaterials(String siteId);
  Future<List<SitePayment>> fetchPayments(String siteId);
  Future<List<SiteReport>> fetchReports(String siteId);
  Future<List<SiteAttendanceDay>> fetchAttendance(String siteId);
}
