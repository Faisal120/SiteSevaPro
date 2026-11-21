import '../../../core/network/api_service.dart';
import '../../sites/models/site_models.dart';
import '../models/report_models.dart';
import '../repository/reports_repository.dart';
import 'reports_cache.dart';
import 'reports_remote_data_source.dart';

class ReportsRepositoryImpl implements ReportsRepository {
  const ReportsRepositoryImpl({
    required ReportsRemoteDataSource remote,
    required ReportsCache cache,
    required String userId,
    required bool canView,
    required bool canCreate,
    required bool restrictToAssignedSites,
    DateTime Function()? clock,
  }) : _remote = remote,
       _cache = cache,
       _userId = userId,
       _canView = canView,
       _canCreate = canCreate,
       _restrictToAssignedSites = restrictToAssignedSites,
       _clock = clock ?? DateTime.now;

  final ReportsRemoteDataSource _remote;
  final ReportsCache _cache;
  final String _userId;
  final bool _canView;
  final bool _canCreate;
  final bool _restrictToAssignedSites;
  final DateTime Function() _clock;

  @override
  Future<ReportsStudioData> fetchStudio() async {
    _guard(_canView, 'Daily reports are unavailable for this account.');
    try {
      final sitesPayload = await _remote.fetchSites();
      final reportsPayload = await _fetchRoleScopedReports(sitesPayload);
      final payload = <String, dynamic>{
        'sites': sitesPayload,
        'reports': reportsPayload,
      };
      await _cache.writeStudio(_userId, payload);
      return _parse(payload, _clock());
    } on ApiException catch (error) {
      if (!error.isConnectivityFailure) rethrow;
      final cached = await _cache.readStudio(_userId);
      if (cached == null) rethrow;
      return _parse(
        cached.payload,
        cached.cachedAt,
        referenceDate: _clock(),
        isOffline: true,
      );
    }
  }

  @override
  Future<DailyReport> createReport(DailyReportBrief brief) async {
    _guard(
      _canCreate,
      'Only contractors and supervisors can submit daily reports.',
    );
    final validation = brief.validationMessage;
    if (validation != null) _invalid(validation);

    final sites = (await _remote.fetchSites())
        .map(SiteSummary.fromJson)
        .toList(growable: false);
    SiteSummary? selectedSite;
    for (final site in sites) {
      if (site.id == brief.siteId) selectedSite = site;
    }
    if (selectedSite == null) {
      throw const ApiException(
        'The selected project is not assigned to this account.',
        statusCode: 403,
        kind: ApiErrorKind.authentication,
      );
    }
    final currentBrief = brief.copyWith(
      currentSiteProgress: selectedSite.progress,
    );
    final currentValidation = currentBrief.validationMessage;
    if (currentValidation != null) _invalid(currentValidation);

    final existing = (await _remote.fetchReports(
      siteId: brief.siteId,
    )).map(DailyReport.fromJson);
    if (existing.any(
      (report) => apiReportDate(report.date) == apiReportDate(brief.date),
    )) {
      throw const ApiException(
        'A daily report already exists for this site and date.',
        statusCode: 409,
      );
    }
    return DailyReport.fromJson(
      await _remote.createReport(currentBrief.toApiJson()),
    );
  }

  @override
  Future<ReportMedia> uploadPhoto(ReportPhotoUpload upload) async {
    _guard(
      _canCreate,
      'Only contractors and supervisors can attach report evidence.',
    );
    final validation = upload.validationMessage;
    if (validation != null) _invalid(validation);
    final media = ReportMedia.fromJson(await _remote.uploadPhoto(upload));
    if (media.url.isEmpty || !media.url.startsWith('https://')) {
      throw const ApiException(
        'The media service did not return a secure photo URL.',
        kind: ApiErrorKind.invalidResponse,
      );
    }
    return media;
  }

  Future<List<Map<String, dynamic>>> _fetchRoleScopedReports(
    List<Map<String, dynamic>> sitesPayload,
  ) async {
    if (!_restrictToAssignedSites) return _remote.fetchReports();
    final siteIds = sitesPayload
        .map((site) => '${site['id'] ?? ''}')
        .where((id) => id.isNotEmpty)
        .toList(growable: false);
    if (siteIds.isEmpty) return const [];
    final pages = await Future.wait(
      siteIds.map((siteId) => _remote.fetchReports(siteId: siteId)),
    );
    final unique = <String, Map<String, dynamic>>{};
    for (final report in pages.expand((page) => page)) {
      final id = '${report['id'] ?? ''}';
      final key = id.isEmpty
          ? '${report['site_id']}::${report['date']}::${report['created_at']}'
          : id;
      unique[key] = report;
    }
    return unique.values.toList(growable: false);
  }

  ReportsStudioData _parse(
    Map<String, dynamic> payload,
    DateTime fetchedAt, {
    DateTime? referenceDate,
    bool isOffline = false,
  }) {
    final sites = _list(payload['sites'])
        .map(SiteSummary.fromJson)
        .where((site) => site.id.isNotEmpty)
        .toList(growable: false);
    final assignedIds = sites.map((site) => site.id).toSet();
    var reports = _list(payload['reports'])
        .map(DailyReport.fromJson)
        .where((report) => report.id.isNotEmpty && report.siteId.isNotEmpty)
        .toList(growable: false);
    if (_restrictToAssignedSites) {
      reports = reports
          .where((report) => assignedIds.contains(report.siteId))
          .toList(growable: false);
    }
    return ReportsStudioData(
      reports: reports,
      sites: sites,
      fetchedAt: fetchedAt,
      referenceDate: referenceDate ?? fetchedAt,
      canCreate: _canCreate,
      isOffline: isOffline,
    );
  }

  void _guard(bool allowed, String message) {
    if (!allowed) {
      throw ApiException(
        message,
        statusCode: 403,
        kind: ApiErrorKind.authentication,
      );
    }
  }

  Never _invalid(String message) => throw ApiException(
    message,
    statusCode: 422,
    kind: ApiErrorKind.invalidResponse,
  );
}

List<Map<String, dynamic>> _list(Object? value) => value is List
    ? value
          .whereType<Map>()
          .map((item) => Map<String, dynamic>.from(item))
          .toList(growable: false)
    : const [];
