import '../../../core/network/api_service.dart';
import '../models/site_models.dart';
import '../models/site_records.dart';
import '../repository/site_repository.dart';
import 'site_cache.dart';
import 'site_remote_data_source.dart';

class SiteRepositoryImpl implements SiteRepository {
  const SiteRepositoryImpl({
    required SiteRemoteDataSource remote,
    required SiteCache cache,
    required String userId,
  }) : _remote = remote,
       _cache = cache,
       _userId = userId;

  final SiteRemoteDataSource _remote;
  final SiteCache _cache;
  final String _userId;

  @override
  Future<SiteCollection> fetchSites() async {
    try {
      final payload = await _remote.fetchSites();
      await _cache.writeList(_userId, payload);
      return SiteCollection(
        sites: payload.map(SiteSummary.fromJson).toList(growable: false),
        fetchedAt: DateTime.now(),
      );
    } on ApiException catch (error) {
      if (!error.isConnectivityFailure) rethrow;
      final cached = await _cache.readList(_userId);
      if (cached == null) rethrow;
      return SiteCollection(
        sites: cached.payload.map(SiteSummary.fromJson).toList(growable: false),
        fetchedAt: cached.cachedAt,
        isOffline: true,
      );
    }
  }

  @override
  Future<SiteDetail> fetchSite(String siteId) async {
    try {
      final payload = await _remote.fetchSite(siteId);
      await _cache.writeDetail(_userId, siteId, payload);
      return SiteDetail.fromJson(payload);
    } on ApiException catch (error) {
      if (!error.isConnectivityFailure) rethrow;
      final cached = await _cache.readDetail(_userId, siteId);
      if (cached == null) rethrow;
      return SiteDetail.fromJson(cached.payload);
    }
  }

  @override
  Future<SiteDetail> createSite(SiteMutation mutation) async {
    final payload = await _remote.createSite(mutation.toApiJson());
    final site = SiteDetail.fromJson(payload);
    await _cache.writeDetail(_userId, site.id, payload);
    return site;
  }

  @override
  Future<SiteDetail> updateSite(String siteId, SiteMutation mutation) async {
    final payload = await _remote.updateSite(siteId, mutation.toApiJson());
    await _cache.writeDetail(_userId, siteId, payload);
    return SiteDetail.fromJson(payload);
  }

  @override
  Future<void> deleteSite(String siteId) async {
    await _remote.deleteSite(siteId);
    await _cache.removeSite(_userId, siteId);
  }

  @override
  Future<List<SiteAssignee>> fetchTeam() async =>
      (await _remote.fetchTeam())
          .map(SiteAssignee.fromJson)
          .where((member) => member.id.isNotEmpty)
          .toList(growable: false);

  @override
  Future<void> assignSupervisor(String siteId, String userId) =>
      _remote.assignSupervisor(siteId, userId);

  @override
  Future<void> assignClient(String siteId, String userId) =>
      _remote.assignClient(siteId, userId);

  @override
  Future<List<SiteLabour>> fetchLabour(String siteId) => _records(
    siteId: siteId,
    type: 'labour',
    remote: () => _remote.fetchLabour(siteId),
    parse: SiteLabour.fromJson,
  );

  @override
  Future<List<SiteMaterial>> fetchMaterials(String siteId) => _records(
    siteId: siteId,
    type: 'materials',
    remote: () => _remote.fetchMaterials(siteId),
    parse: SiteMaterial.fromJson,
  );

  @override
  Future<List<SitePayment>> fetchPayments(String siteId) => _records(
    siteId: siteId,
    type: 'payments',
    remote: () => _remote.fetchPayments(siteId),
    parse: SitePayment.fromJson,
  );

  @override
  Future<List<SiteReport>> fetchReports(String siteId) => _records(
    siteId: siteId,
    type: 'reports',
    remote: () => _remote.fetchReports(siteId),
    parse: SiteReport.fromJson,
  );

  @override
  Future<List<SiteAttendanceDay>> fetchAttendance(String siteId) => _records(
    siteId: siteId,
    type: 'attendance',
    remote: () => _remote.fetchAttendance(siteId),
    parse: SiteAttendanceDay.fromJson,
  );

  Future<List<T>> _records<T>({
    required String siteId,
    required String type,
    required Future<List<Map<String, dynamic>>> Function() remote,
    required T Function(Map<String, dynamic>) parse,
  }) async {
    try {
      final payload = await remote();
      await _cache.writeRecords(_userId, siteId, type, payload);
      return payload.map(parse).toList(growable: false);
    } on ApiException catch (error) {
      if (!error.isConnectivityFailure) rethrow;
      final cached = await _cache.readRecords(_userId, siteId, type);
      if (cached == null) rethrow;
      return cached.payload.map(parse).toList(growable: false);
    }
  }
}
