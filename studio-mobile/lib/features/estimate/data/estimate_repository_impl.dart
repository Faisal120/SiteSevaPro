import '../../../core/network/api_service.dart';
import '../../sites/models/site_models.dart';
import '../models/estimate_models.dart';
import '../repository/estimate_repository.dart';
import 'estimate_cache.dart';
import 'estimate_remote_data_source.dart';

class EstimateRepositoryImpl implements EstimateRepository {
  const EstimateRepositoryImpl({
    required EstimateRemoteDataSource remote,
    required EstimateCache cache,
    required String userId,
    required bool canManage,
  }) : _remote = remote,
       _cache = cache,
       _userId = userId,
       _canManage = canManage;

  final EstimateRemoteDataSource _remote;
  final EstimateCache _cache;
  final String _userId;
  final bool _canManage;

  @override
  Future<EstimateStudioData> fetchStudio() async {
    _guardManage();
    try {
      final results = await Future.wait<Object>([
        _remote.fetchEstimates(),
        _remote.fetchSites(),
        _remote.fetchBranding(),
      ]);
      final payload = <String, dynamic>{
        'estimates': results[0],
        'sites': results[1],
        'branding': results[2],
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
  Future<EstimateDocument> fetchEstimate(String estimateId) async {
    _guardManage();
    try {
      final payload = await _remote.fetchEstimate(estimateId);
      await _cache.writeEstimate(_userId, estimateId, payload);
      return EstimateDocument.fromJson(payload);
    } on ApiException catch (error) {
      if (!error.isConnectivityFailure) rethrow;
      final cached = await _cache.readEstimate(_userId, estimateId);
      if (cached == null) rethrow;
      return EstimateDocument.fromJson(cached.payload);
    }
  }

  @override
  Future<EstimateDocument> create(EstimateBrief brief) async {
    _guardManage();
    final validation = brief.validationMessage;
    if (validation != null) {
      throw ApiException(validation, kind: ApiErrorKind.invalidResponse);
    }
    final payload = await _remote.create(brief.toApiJson());
    final estimate = EstimateDocument.fromJson(payload);
    await _cache.writeEstimate(_userId, estimate.id, payload);
    return estimate;
  }

  EstimateStudioData _parseStudio(
    Map<String, dynamic> payload,
    DateTime fetchedAt, {
    bool isOffline = false,
  }) => EstimateStudioData(
    estimates: _maps(
      payload['estimates'],
    ).map(EstimateDocument.fromJson).toList(growable: false),
    sites: _maps(
      payload['sites'],
    ).map(SiteSummary.fromJson).toList(growable: false),
    branding: EstimateBranding.fromJson(_map(payload['branding'])),
    fetchedAt: fetchedAt,
    isOffline: isOffline,
  );

  void _guardManage() {
    if (_canManage) return;
    throw const ApiException(
      'Estimate generation is available to contractors only.',
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
