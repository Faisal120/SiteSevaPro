import '../../../core/network/api_service.dart';
import '../../sites/models/site_models.dart';
import '../models/material_models.dart';
import '../repository/materials_repository.dart';
import 'materials_cache.dart';
import 'materials_remote_data_source.dart';

class MaterialsRepositoryImpl implements MaterialsRepository {
  const MaterialsRepositoryImpl({
    required MaterialsRemoteDataSource remote,
    required MaterialsCache cache,
    required String userId,
    required bool canView,
    required bool canManageStock,
    required bool canManageVendors,
    required bool restrictMovementsToAssignedSites,
  }) : _remote = remote,
       _cache = cache,
       _userId = userId,
       _canView = canView,
       _canManageStock = canManageStock,
       _canManageVendors = canManageVendors,
       _restrictMovementsToAssignedSites = restrictMovementsToAssignedSites;

  final MaterialsRemoteDataSource _remote;
  final MaterialsCache _cache;
  final String _userId;
  final bool _canView;
  final bool _canManageStock;
  final bool _canManageVendors;
  final bool _restrictMovementsToAssignedSites;

  @override
  Future<MaterialsStudioData> fetchStudio() async {
    _guard(
      _canView,
      'Stock control is available to contractors and supervisors only.',
    );
    try {
      final sitesPayload = await _remote.fetchSites();
      final materialsFuture = _remote.fetchMaterials();
      final movementsFuture = _fetchMovements(sitesPayload);
      final vendorsFuture = _canManageVendors
          ? _remote.fetchVendors()
          : Future.value(const <Map<String, dynamic>>[]);
      final results = await Future.wait<Object>([
        materialsFuture,
        movementsFuture,
        vendorsFuture,
      ]);
      final payload = <String, dynamic>{
        'sites': sitesPayload,
        'materials': results[0],
        'movements': results[1],
        'vendors': results[2],
      };
      await _cache.writeStudio(_userId, payload);
      return _parse(payload, DateTime.now());
    } on ApiException catch (error) {
      if (!error.isConnectivityFailure) rethrow;
      final cached = await _cache.readStudio(_userId);
      if (cached == null) rethrow;
      return _parse(cached.payload, cached.cachedAt, isOffline: true);
    }
  }

  @override
  Future<MaterialItem> createMaterial(MaterialCreationBrief brief) async {
    _guard(
      _canManageStock,
      'Only contractors and supervisors can create material records.',
    );
    final validation = brief.validationMessage;
    if (validation != null) _invalid(validation);
    await _validateAssignedSite(brief.siteId);
    return MaterialItem.fromJson(
      await _remote.createMaterial(brief.toApiJson()),
    );
  }

  @override
  Future<MaterialMovement> createMovement(MaterialMovementBrief brief) async {
    _guard(
      _canManageStock,
      'Only contractors and supervisors can record stock movement.',
    );
    final validation = brief.validationMessage;
    if (validation != null) _invalid(validation);
    await _validateAssignedSite(brief.siteId);
    return MaterialMovement.fromJson(
      await _remote.createMovement(brief.toApiJson()),
    );
  }

  @override
  Future<MaterialVendor> createVendor(MaterialVendorBrief brief) async {
    _guard(
      _canManageVendors,
      'Vendor management is available to contractors only.',
    );
    final validation = brief.validationMessage;
    if (validation != null) _invalid(validation);
    return MaterialVendor.fromJson(
      await _remote.createVendor(brief.toApiJson()),
    );
  }

  @override
  Future<void> deleteVendor(String vendorId) async {
    _guard(
      _canManageVendors,
      'Vendor management is available to contractors only.',
    );
    if (vendorId.isEmpty) _invalid('Vendor is unavailable.');
    await _remote.deleteVendor(vendorId);
  }

  Future<List<Map<String, dynamic>>> _fetchMovements(
    List<Map<String, dynamic>> sitesPayload,
  ) async {
    if (!_restrictMovementsToAssignedSites) {
      return _remote.fetchMovements();
    }
    final siteIds = sitesPayload
        .map((site) => '${site['id'] ?? ''}')
        .where((id) => id.isNotEmpty)
        .toList(growable: false);
    if (siteIds.isEmpty) return const [];
    final pages = await Future.wait(
      siteIds.map((siteId) => _remote.fetchMovements(siteId: siteId)),
    );
    final unique = <String, Map<String, dynamic>>{};
    for (final movement in pages.expand((page) => page)) {
      final id = '${movement['id'] ?? ''}';
      unique[id.isEmpty ? movement.toString() : id] = movement;
    }
    return unique.values.toList(growable: false);
  }

  Future<void> _validateAssignedSite(String siteId) async {
    final sites = (await _remote.fetchSites())
        .map(SiteSummary.fromJson)
        .toList(growable: false);
    if (!sites.any((site) => site.id == siteId)) {
      throw const ApiException(
        'The selected project is not assigned to this account.',
        statusCode: 403,
        kind: ApiErrorKind.authentication,
      );
    }
  }

  MaterialsStudioData _parse(
    Map<String, dynamic> payload,
    DateTime fetchedAt, {
    bool isOffline = false,
  }) => MaterialsStudioData(
    materials: _maps(
      payload['materials'],
    ).map(MaterialItem.fromJson).toList(growable: false),
    movements: _maps(
      payload['movements'],
    ).map(MaterialMovement.fromJson).toList(growable: false),
    vendors: _maps(
      payload['vendors'],
    ).map(MaterialVendor.fromJson).toList(growable: false),
    sites: _maps(
      payload['sites'],
    ).map(SiteSummary.fromJson).toList(growable: false),
    fetchedAt: fetchedAt,
    canManageVendors: _canManageVendors,
    isOffline: isOffline,
  );

  void _guard(bool allowed, String message) {
    if (allowed) return;
    throw ApiException(
      message,
      statusCode: 403,
      kind: ApiErrorKind.authentication,
    );
  }

  Never _invalid(String message) =>
      throw ApiException(message, kind: ApiErrorKind.invalidResponse);
}

List<Map<String, dynamic>> _maps(Object? value) => value is List
    ? value
          .whereType<Map>()
          .map((item) => item.map((key, value) => MapEntry('$key', value)))
          .toList(growable: false)
    : const [];
