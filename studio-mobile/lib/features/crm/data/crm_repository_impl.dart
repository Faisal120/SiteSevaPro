import '../../../core/network/api_service.dart';
import '../models/crm_models.dart';
import '../repository/crm_repository.dart';
import 'crm_cache.dart';
import 'crm_remote_data_source.dart';

class CrmRepositoryImpl implements CrmRepository {
  CrmRepositoryImpl({
    required CrmRemoteDataSource remote,
    required CrmCache cache,
    required String userId,
    required String role,
  }) : _remote = remote,
       _cache = cache,
       _userId = userId,
       _permissions = CrmPermissions(role: role);

  final CrmRemoteDataSource _remote;
  final CrmCache _cache;
  final String _userId;
  final CrmPermissions _permissions;

  @override
  Future<CrmWorkspaceData> fetchWorkspace() async {
    try {
      final payload = await _remote.fetchOverview();
      await _cache.write(_userId, payload);
      return CrmWorkspaceData.fromJson(payload);
    } on ApiException catch (error) {
      if (error.statusCode == 404) {
        return CrmWorkspaceData.unavailable(fetchedAt: DateTime.now());
      }
      if (!error.isConnectivityFailure) rethrow;
      final cached = await _cache.read(_userId);
      if (cached == null) rethrow;
      return CrmWorkspaceData.fromJson(
        cached.payload,
        fetchedAt: cached.cachedAt,
        isOffline: true,
      );
    }
  }

  @override
  Future<void> createLead(CrmLeadInput input) async {
    _require(_permissions.canWriteLeads);
    await _remote.createLead(input);
  }

  @override
  Future<void> createContact(CrmContactInput input) async {
    _require(_permissions.canWriteContacts);
    await _remote.createContact(input);
  }

  @override
  Future<void> createActivity(CrmActivityInput input) async {
    _require(_permissions.canWriteActivities);
    await _remote.createActivity(input);
  }

  @override
  Future<void> createQuotation(CrmQuotationInput input) async {
    _require(_permissions.canWriteQuotations);
    await _remote.createQuotation(input);
  }

  @override
  Future<void> completeActivity(String id) async {
    _require(_permissions.canWriteActivities);
    if (id.trim().isEmpty) {
      throw const ApiException(
        'Activity is unavailable.',
        kind: ApiErrorKind.invalidResponse,
      );
    }
    await _remote.completeActivity(id);
  }

  void _require(bool allowed) {
    if (!allowed) {
      throw const ApiException(
        'Your role has read-only access to this CRM workspace.',
        statusCode: 403,
        kind: ApiErrorKind.authentication,
      );
    }
  }
}
