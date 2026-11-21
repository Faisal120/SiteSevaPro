import '../../../core/network/api_service.dart';
import '../../sites/models/site_models.dart';
import '../models/attendance_models.dart';
import '../models/workforce_models.dart';
import '../repository/workforce_repository.dart';
import 'workforce_cache.dart';
import 'workforce_remote_data_source.dart';

class WorkforceRepositoryImpl implements WorkforceRepository {
  const WorkforceRepositoryImpl({
    required WorkforceRemoteDataSource remote,
    required WorkforceCache cache,
    required String userId,
    required bool canViewAttendance,
    required bool canEditAttendance,
    required bool canViewMembers,
    required bool canManageMembers,
    required bool canViewWallet,
    required bool canManageWallet,
  }) : _remote = remote,
       _cache = cache,
       _userId = userId,
       _canViewAttendance = canViewAttendance,
       _canEditAttendance = canEditAttendance,
       _canViewMembers = canViewMembers,
       _canManageMembers = canManageMembers,
       _canViewWallet = canViewWallet,
       _canManageWallet = canManageWallet;

  final WorkforceRemoteDataSource _remote;
  final WorkforceCache _cache;
  final String _userId;
  final bool _canViewAttendance;
  final bool _canEditAttendance;
  final bool _canViewMembers;
  final bool _canManageMembers;
  final bool _canViewWallet;
  final bool _canManageWallet;

  @override
  Future<AttendanceBoardData> fetchAttendance({
    String? siteId,
    required String date,
  }) async {
    _guard(_canViewAttendance, 'Attendance is unavailable for this role.');
    final cacheSiteKey = siteId ?? 'auto';
    try {
      final sitesPayload = await _remote.fetchSites();
      final sites = sitesPayload
          .map(SiteSummary.fromJson)
          .toList(growable: false);
      final selectedSiteId = _selectSite(sites, siteId);
      if (selectedSiteId == null) {
        return AttendanceBoardData(
          sites: sites,
          siteId: null,
          date: date,
          members: const [],
          document: null,
          history: const [],
          draft: null,
          fetchedAt: DateTime.now(),
          canViewMemberDetails: _canViewMembers,
        );
      }
      final results = await Future.wait<Object>([
        if (_canViewMembers)
          _remote.fetchLabour(siteId: selectedSiteId)
        else
          Future.value(const <Map<String, dynamic>>[]),
        _remote.fetchAttendanceDay(siteId: selectedSiteId, date: date),
        _remote.fetchAttendanceHistory(selectedSiteId),
      ]);
      final payload = <String, dynamic>{
        'sites': sitesPayload,
        'site_id': selectedSiteId,
        'date': date,
        'members': results[0],
        'document': results[1],
        'history': results[2],
      };
      await _cache.writeAttendance(_userId, selectedSiteId, date, payload);
      if (siteId == null) {
        await _cache.writeAttendance(_userId, 'auto', date, payload);
      }
      return _parseAttendance(payload, DateTime.now());
    } on ApiException catch (error) {
      if (!error.isConnectivityFailure) rethrow;
      final cached = await _cache.readAttendance(_userId, cacheSiteKey, date);
      if (cached == null) rethrow;
      return _parseAttendance(cached.payload, cached.cachedAt, isOffline: true);
    }
  }

  @override
  Future<AttendanceDocument> saveAttendance(AttendanceDraft draft) async {
    _guard(
      _canEditAttendance,
      'Only contractors and supervisors can mark attendance.',
    );
    final validation = draft.validationMessage;
    if (validation != null) {
      throw ApiException(validation, kind: ApiErrorKind.invalidResponse);
    }
    return AttendanceDocument.fromJson(
      await _remote.markAttendance(draft.toApiJson()),
    );
  }

  @override
  Future<WorkforceStudioData> fetchWorkforce() async {
    _guard(
      _canViewMembers,
      'Workforce profiles are available to contractors and supervisors only.',
    );
    try {
      final results = await Future.wait<Object>([
        _remote.fetchLabour(),
        _remote.fetchSites(),
        if (_canViewWallet)
          _remote.fetchWalletSummary()
        else
          Future.value(<String, dynamic>{}),
      ]);
      final payload = <String, dynamic>{
        'members': results[0],
        'sites': results[1],
        'wallet': results[2],
      };
      await _cache.writeStudio(_userId, payload);
      return _parseStudio(payload, DateTime.now());
    } on ApiException catch (error) {
      if (!error.isConnectivityFailure) rethrow;
      final cached = await _cache.readStudio(_userId);
      if (cached == null) rethrow;
      return _parseStudio(cached.payload, cached.cachedAt, isOffline: true);
    }
  }

  @override
  Future<WorkforceMember> createMember(WorkforceCreationBrief brief) async {
    _guard(
      _canManageMembers,
      'Only contractors can create workforce profiles.',
    );
    final validation = brief.validationMessage;
    if (validation != null) {
      throw ApiException(validation, kind: ApiErrorKind.invalidResponse);
    }
    return WorkforceMember.fromJson(
      await _remote.createLabour(brief.toApiJson()),
    );
  }

  @override
  Future<void> deleteMember(String labourId) async {
    _guard(
      _canManageMembers,
      'Only contractors can remove workforce profiles.',
    );
    if (labourId.isEmpty) {
      throw const ApiException(
        'Workforce member is unavailable.',
        kind: ApiErrorKind.invalidResponse,
      );
    }
    await _remote.deleteLabour(labourId);
  }

  @override
  Future<WorkforceDetail> fetchDetail(String labourId) async {
    _guard(
      _canViewWallet,
      'Workforce wallet details are unavailable for this role.',
    );
    try {
      final payload = await _remote.fetchWorkforceDetail(labourId);
      await _cache.writeDetail(_userId, labourId, payload);
      return WorkforceDetail.fromJson(payload, fetchedAt: DateTime.now());
    } on ApiException catch (error) {
      if (!error.isConnectivityFailure) rethrow;
      final cached = await _cache.readDetail(_userId, labourId);
      if (cached == null) rethrow;
      return WorkforceDetail.fromJson(
        cached.payload,
        fetchedAt: cached.cachedAt,
        isOffline: true,
      );
    }
  }

  @override
  Future<void> settleWallet(WalletSettlementBrief brief) async {
    _guard(_canManageWallet, 'Only contractors can settle workforce wallets.');
    final validation = brief.validationMessage;
    if (validation != null) {
      throw ApiException(validation, kind: ApiErrorKind.invalidResponse);
    }
    await _remote.settleWallet(brief.toApiJson());
  }

  @override
  Future<PayrollData> fetchPayroll(String month) async {
    _guard(_canManageWallet, 'Payroll is available to contractors only.');
    try {
      final results = await Future.wait<Object>([
        _remote.fetchPayroll(month),
        _remote.fetchLabour(),
      ]);
      final payload = <String, dynamic>{
        'month': month,
        'records': results[0],
        'members': results[1],
      };
      await _cache.writePayroll(_userId, month, payload);
      return _parsePayroll(payload, DateTime.now());
    } on ApiException catch (error) {
      if (!error.isConnectivityFailure) rethrow;
      final cached = await _cache.readPayroll(_userId, month);
      if (cached == null) rethrow;
      return _parsePayroll(cached.payload, cached.cachedAt, isOffline: true);
    }
  }

  @override
  Future<PayrollRecord> generatePayroll(String labourId, String month) async {
    _guard(_canManageWallet, 'Payroll is available to contractors only.');
    if (labourId.isEmpty || month.isEmpty) {
      throw const ApiException(
        'Choose a workforce member and payroll month.',
        kind: ApiErrorKind.invalidResponse,
      );
    }
    return PayrollRecord.fromJson(
      await _remote.generatePayroll(labourId, month),
    );
  }

  AttendanceBoardData _parseAttendance(
    Map<String, dynamic> payload,
    DateTime fetchedAt, {
    bool isOffline = false,
  }) {
    final sites = _maps(
      payload['sites'],
    ).map(SiteSummary.fromJson).toList(growable: false);
    final siteId = _nullableString(payload['site_id']);
    final date = '${payload['date'] ?? ''}';
    final members = _maps(
      payload['members'],
    ).map(WorkforceMember.fromJson).toList(growable: false);
    final documentPayload = _map(payload['document']);
    final document = siteId == null
        ? null
        : AttendanceDocument.fromJson({
            'site_id': siteId,
            'date': date,
            ...documentPayload,
          });
    return AttendanceBoardData(
      sites: sites,
      siteId: siteId,
      date: date,
      members: members,
      document: document,
      history: _maps(
        payload['history'],
      ).map(AttendanceDocument.fromJson).toList(growable: false),
      draft: document == null
          ? null
          : AttendanceDraft.fromBoard(
              siteId: siteId!,
              date: date,
              members: members,
              document: document,
            ),
      fetchedAt: fetchedAt,
      canViewMemberDetails: _canViewMembers,
      isOffline: isOffline,
    );
  }

  WorkforceStudioData _parseStudio(
    Map<String, dynamic> payload,
    DateTime fetchedAt, {
    bool isOffline = false,
  }) => WorkforceStudioData(
    members: _maps(
      payload['members'],
    ).map(WorkforceMember.fromJson).toList(growable: false),
    sites: _maps(
      payload['sites'],
    ).map(SiteSummary.fromJson).toList(growable: false),
    walletSummary: WorkforceWalletSummary.fromJson(_map(payload['wallet'])),
    fetchedAt: fetchedAt,
    isOffline: isOffline,
  );

  PayrollData _parsePayroll(
    Map<String, dynamic> payload,
    DateTime fetchedAt, {
    bool isOffline = false,
  }) => PayrollData(
    month: '${payload['month'] ?? ''}',
    records: _maps(
      payload['records'],
    ).map(PayrollRecord.fromJson).toList(growable: false),
    members: _maps(
      payload['members'],
    ).map(WorkforceMember.fromJson).toList(growable: false),
    fetchedAt: fetchedAt,
    isOffline: isOffline,
  );

  String? _selectSite(List<SiteSummary> sites, String? requested) {
    if (sites.isEmpty) return null;
    if (requested == null) return sites.first.id;
    return sites.any((site) => site.id == requested)
        ? requested
        : sites.first.id;
  }

  void _guard(bool allowed, String message) {
    if (allowed) return;
    throw ApiException(
      message,
      statusCode: 403,
      kind: ApiErrorKind.authentication,
    );
  }
}

Map<String, dynamic> _map(Object? value) => value is Map
    ? value.map((key, value) => MapEntry('$key', value))
    : <String, dynamic>{};

List<Map<String, dynamic>> _maps(Object? value) => value is List
    ? value.whereType<Map>().map(_map).toList(growable: false)
    : const [];

String? _nullableString(Object? value) {
  final normalized = '${value ?? ''}'.trim();
  return normalized.isEmpty || normalized == 'null' ? null : normalized;
}
