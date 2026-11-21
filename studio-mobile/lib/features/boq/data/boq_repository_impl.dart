import '../../../core/network/api_service.dart';
import '../../sites/models/site_models.dart';
import '../models/boq_models.dart';
import '../repository/boq_repository.dart';
import 'boq_cache.dart';
import 'boq_remote_data_source.dart';

class BoqRepositoryImpl implements BoqRepository {
  const BoqRepositoryImpl({
    required BoqRemoteDataSource remote,
    required BoqCache cache,
    required String userId,
    required bool canManage,
  }) : _remote = remote,
       _cache = cache,
       _userId = userId,
       _canManage = canManage;

  final BoqRemoteDataSource _remote;
  final BoqCache _cache;
  final String _userId;
  final bool _canManage;

  @override
  Future<BoqStudioData> fetchStudio() async {
    _guardManage();
    try {
      final results = await Future.wait<Object>([
        _remote.fetchBoqs(),
        _remote.fetchSites(),
        _remote.fetchEstimates(),
        _remote.fetchVendors(),
      ]);
      final payload = <String, dynamic>{
        'boqs': results[0],
        'sites': results[1],
        'estimates': results[2],
        'vendors': results[3],
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
  Future<BoqDocument> fetchBoq(String boqId) async {
    _guardManage();
    try {
      final payload = await _remote.fetchBoq(boqId);
      await _cache.writeBoq(_userId, boqId, payload);
      return BoqDocument.fromJson(payload);
    } on ApiException catch (error) {
      if (!error.isConnectivityFailure) rethrow;
      final cached = await _cache.readBoq(_userId, boqId);
      if (cached == null) rethrow;
      return BoqDocument.fromJson(cached.payload);
    }
  }

  @override
  Future<BoqDocument> generate(BoqGenerationBrief brief) async {
    _guardManage();
    final validation = brief.validationMessage;
    if (validation != null) {
      throw ApiException(validation, kind: ApiErrorKind.invalidResponse);
    }
    final payload = await _remote.generate(brief.toApiJson());
    final boq = BoqDocument.fromJson(payload);
    await _cache.writeBoq(_userId, boq.id, payload);
    return boq;
  }

  BoqStudioData _parseStudio(
    Map<String, dynamic> payload,
    DateTime fetchedAt, {
    bool isOffline = false,
  }) => BoqStudioData(
    boqs: _maps(
      payload['boqs'],
    ).map(BoqDocument.fromJson).toList(growable: false),
    sites: _maps(
      payload['sites'],
    ).map(SiteSummary.fromJson).toList(growable: false),
    estimates: _maps(
      payload['estimates'],
    ).map(BoqEstimateSummary.fromJson).toList(growable: false),
    vendors: _maps(
      payload['vendors'],
    ).map(BoqVendorSummary.fromJson).toList(growable: false),
    fetchedAt: fetchedAt,
    isOffline: isOffline,
  );

  void _guardManage() {
    if (_canManage) return;
    throw const ApiException(
      'BOQ generation is available to contractors only.',
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
