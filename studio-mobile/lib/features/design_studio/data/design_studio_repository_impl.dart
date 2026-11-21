import 'dart:typed_data';

import '../../../core/network/api_service.dart';
import '../../sites/models/site_models.dart';
import '../models/design_models.dart';
import '../repository/design_studio_repository.dart';
import 'design_studio_cache.dart';
import 'design_studio_remote_data_source.dart';

class DesignStudioRepositoryImpl implements DesignStudioRepository {
  const DesignStudioRepositoryImpl({
    required DesignStudioRemoteDataSource remote,
    required DesignStudioCache cache,
    required String userId,
    required bool canManage,
  }) : _remote = remote,
       _cache = cache,
       _userId = userId,
       _canManage = canManage;

  final DesignStudioRemoteDataSource _remote;
  final DesignStudioCache _cache;
  final String _userId;
  final bool _canManage;

  @override
  Future<DesignStudioData> fetchStudio() async {
    try {
      final results = await Future.wait<Object>([
        _remote.fetchSites(),
        _remote.fetchDesigns(),
        if (_canManage) _remote.fetchWallet(),
        if (_canManage) _remote.fetchTransactions(),
        if (_canManage) _remote.fetchPurchaseConfig(),
        if (_canManage) _remote.fetchPurchases(),
      ]);
      final sites = results[0] as List<Map<String, dynamic>>;
      final allDesigns = results[1] as List<Map<String, dynamic>>;
      final accessibleIds = sites.map((site) => '${site['id']}').toSet();
      final designs = _canManage
          ? allDesigns
          : allDesigns
                .where(
                  (design) => accessibleIds.contains('${design['site_id']}'),
                )
                .toList(growable: false);
      final payload = <String, dynamic>{
        'sites': sites,
        'designs': designs,
        if (_canManage) 'wallet': results[2],
        if (_canManage) 'transactions': results[3],
        if (_canManage) 'purchase_config': results[4],
        if (_canManage) 'purchases': results[5],
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
  Future<DesignRecord> fetchDesign(String designId) async {
    try {
      final payload = await _remote.fetchDesign(designId);
      await _guardRead(payload);
      await _cache.writeDesign(_userId, designId, payload);
      return DesignRecord.fromJson(payload);
    } on ApiException catch (error) {
      if (!error.isConnectivityFailure) rethrow;
      final cached = await _cache.readDesign(_userId, designId);
      if (cached == null) rethrow;
      return DesignRecord.fromJson(cached.payload);
    }
  }

  @override
  Future<DesignRecord> generate(DesignBrief brief) async {
    _guardManage();
    final validation = brief.validationMessage;
    if (validation != null) {
      throw ApiException(validation, kind: ApiErrorKind.invalidResponse);
    }
    final payload = await _remote.generate(brief.toApiJson());
    final design = DesignRecord.fromJson(payload);
    await _cache.writeDesign(_userId, design.id, payload);
    return design;
  }

  @override
  Future<DesignRecord> generateTechnical(
    String designId,
    DesignDrawingType type,
  ) async {
    _guardManage();
    if (!type.isTechnical) {
      throw const ApiException(
        'Choose a technical drawing type.',
        kind: ApiErrorKind.invalidResponse,
      );
    }
    final payload = await _remote.generateTechnical(designId, type.apiValue);
    await _cache.writeDesign(_userId, designId, payload);
    return DesignRecord.fromJson(payload);
  }

  @override
  Future<DesignRecord> generateThreeD(String designId, int floorNumber) async {
    _guardManage();
    final payload = await _remote.generateThreeD(designId, floorNumber);
    await _cache.writeDesign(_userId, designId, payload);
    return DesignRecord.fromJson(payload);
  }

  @override
  Future<void> deleteDesign(String designId) async {
    _guardManage();
    await _remote.deleteDesign(designId);
    await _cache.removeDesign(_userId, designId);
  }

  @override
  Future<DesignPurchaseRequest> requestCredits({
    required String pack,
    required String utr,
    String? note,
  }) async {
    _guardManage();
    final normalizedUtr = utr.trim();
    if (normalizedUtr.length < 4) {
      throw const ApiException(
        'Enter the UPI transaction reference.',
        kind: ApiErrorKind.invalidResponse,
      );
    }
    final payload = await _remote.requestPurchase({
      'pack': pack,
      'utr': normalizedUtr,
      if (note?.trim().isNotEmpty == true) 'note': note!.trim(),
    });
    return DesignPurchaseRequest.fromJson(payload);
  }

  @override
  Future<Uint8List> downloadPdf(
    String designId,
    DesignDrawingType type,
    int floorNumber,
  ) => _remote.downloadPdf(designId, type.apiValue, floorNumber);

  DesignStudioData _parseStudio(
    Map<String, dynamic> payload,
    DateTime fetchedAt, {
    bool isOffline = false,
  }) => DesignStudioData(
    sites: _maps(
      payload['sites'],
    ).map(SiteSummary.fromJson).toList(growable: false),
    designs: _maps(
      payload['designs'],
    ).map(DesignRecord.fromJson).toList(growable: false),
    wallet: payload['wallet'] is Map
        ? DesignWallet.fromJson(_map(payload['wallet']))
        : null,
    transactions: _maps(
      payload['transactions'],
    ).map(DesignTransaction.fromJson).toList(growable: false),
    purchaseConfig: payload['purchase_config'] is Map
        ? DesignPurchaseConfig.fromJson(_map(payload['purchase_config']))
        : null,
    purchases: _maps(
      payload['purchases'],
    ).map(DesignPurchaseRequest.fromJson).toList(growable: false),
    fetchedAt: fetchedAt,
    isOffline: isOffline,
  );

  Future<void> _guardRead(Map<String, dynamic> design) async {
    if (_canManage) return;
    final cached = await _cache.readStudio(_userId);
    final siteId = '${design['site_id'] ?? ''}';
    var sites = _maps(cached?.payload['sites']);
    if (sites.isEmpty) {
      sites = await _remote.fetchSites();
    }
    final allowed = sites.any((site) => '${site['id']}' == siteId);
    if (!allowed) {
      throw const ApiException(
        'This design is not assigned to your projects.',
        statusCode: 403,
        kind: ApiErrorKind.authentication,
      );
    }
  }

  void _guardManage() {
    if (_canManage) return;
    throw const ApiException(
      'Only contractors can create or modify designs.',
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
