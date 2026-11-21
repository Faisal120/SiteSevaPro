import 'package:flutter_test/flutter_test.dart';
import 'package:siteseva/core/network/api_service.dart';
import 'package:siteseva/features/estimate/data/estimate_cache.dart';
import 'package:siteseva/features/estimate/data/estimate_remote_data_source.dart';
import 'package:siteseva/features/estimate/data/estimate_repository_impl.dart';
import 'package:siteseva/features/estimate/models/estimate_models.dart';

void main() {
  group('EstimateRepositoryImpl', () {
    test(
      'loads and caches the complete contractor estimate workspace',
      () async {
        final remote = _FakeEstimateRemote();
        final cache = _MemoryEstimateCache();
        final repository = EstimateRepositoryImpl(
          remote: remote,
          cache: cache,
          userId: 'contractor-1',
          canManage: true,
        );

        final data = await repository.fetchStudio();

        expect(data.estimates.single.name, 'Orchid Premium Feasibility');
        expect(data.sites.single.name, 'Orchid Residence');
        expect(data.branding.companyName, 'Buildcraft Projects');
        expect(cache.studios['contractor-1']?.payload['estimates'], isNotNull);
      },
    );

    test('uses cached estimates only for connectivity failures', () async {
      final cache = _MemoryEstimateCache()
        ..studios['contractor-1'] = CachedEstimateStudio(
          payload: {
            'estimates': [_estimatePayload],
            'sites': [_sitePayload],
            'branding': _brandingPayload,
          },
          cachedAt: DateTime(2026, 8, 6, 10),
        );
      final repository = EstimateRepositoryImpl(
        remote: _FakeEstimateRemote(
          error: const ApiException('offline', kind: ApiErrorKind.network),
        ),
        cache: cache,
        userId: 'contractor-1',
        canManage: true,
      );

      final data = await repository.fetchStudio();

      expect(data.isOffline, isTrue);
      expect(data.estimates.single.id, 'estimate-1');
    });

    test('does not mask backend authorization failures with cache', () async {
      final cache = _MemoryEstimateCache()
        ..studios['contractor-1'] = CachedEstimateStudio(
          payload: {
            'estimates': [_estimatePayload],
            'sites': [_sitePayload],
            'branding': _brandingPayload,
          },
          cachedAt: DateTime(2026, 8, 6),
        );
      final repository = EstimateRepositoryImpl(
        remote: _FakeEstimateRemote(
          error: const ApiException(
            'forbidden',
            statusCode: 403,
            kind: ApiErrorKind.authentication,
          ),
        ),
        cache: cache,
        userId: 'contractor-1',
        canManage: true,
      );

      expect(repository.fetchStudio, throwsA(isA<ApiException>()));
    });

    test(
      'submits the exact EstimateIn payload and caches the result',
      () async {
        final remote = _FakeEstimateRemote();
        final cache = _MemoryEstimateCache();
        final repository = EstimateRepositoryImpl(
          remote: remote,
          cache: cache,
          userId: 'contractor-1',
          canManage: true,
        );
        const brief = EstimateBrief(
          siteId: 'site-1',
          name: 'Orchid Premium Feasibility',
          plotAreaSqft: 2400,
          floors: 2,
          basement: true,
          constructionType: EstimateConstructionType.residential,
          quality: EstimateQuality.premium,
          budget: 8500000,
        );

        final created = await repository.create(brief);

        expect(created.id, 'estimate-1');
        expect(remote.lastCreate, brief.toApiJson());
        expect(cache.documents['contractor-1::estimate-1'], isNotNull);
      },
    );

    test('loads an offline cached estimate document', () async {
      final cache = _MemoryEstimateCache()
        ..documents['contractor-1::estimate-1'] = CachedEstimate(
          payload: _estimatePayload,
          cachedAt: DateTime(2026, 8, 6),
        );
      final repository = EstimateRepositoryImpl(
        remote: _FakeEstimateRemote(
          error: const ApiException('offline', kind: ApiErrorKind.network),
        ),
        cache: cache,
        userId: 'contractor-1',
        canManage: true,
      );

      final document = await repository.fetchEstimate('estimate-1');

      expect(document.total, 8500000);
      expect(document.materials.bricksPcs, 54720);
    });

    test('blocks estimate list, detail, and creation for non-contractors', () {
      final repository = EstimateRepositoryImpl(
        remote: _FakeEstimateRemote(),
        cache: _MemoryEstimateCache(),
        userId: 'client-1',
        canManage: false,
      );

      expect(repository.fetchStudio(), throwsA(isA<ApiException>()));
      expect(
        repository.fetchEstimate('estimate-1'),
        throwsA(isA<ApiException>()),
      );
      expect(
        repository.create(EstimateBrief.initial()),
        throwsA(isA<ApiException>()),
      );
    });
  });
}

class _FakeEstimateRemote implements EstimateRemoteDataSource {
  _FakeEstimateRemote({this.error});
  final ApiException? error;
  Map<String, dynamic>? lastCreate;

  void _throwIfNeeded() {
    if (error != null) throw error!;
  }

  @override
  Future<Map<String, dynamic>> create(Map<String, dynamic> payload) async {
    _throwIfNeeded();
    lastCreate = payload;
    return Map<String, dynamic>.from(_estimatePayload);
  }

  @override
  Future<Map<String, dynamic>> fetchBranding() async {
    _throwIfNeeded();
    return Map<String, dynamic>.from(_brandingPayload);
  }

  @override
  Future<Map<String, dynamic>> fetchEstimate(String estimateId) async {
    _throwIfNeeded();
    return Map<String, dynamic>.from(_estimatePayload);
  }

  @override
  Future<List<Map<String, dynamic>>> fetchEstimates() async {
    _throwIfNeeded();
    return [_estimatePayload];
  }

  @override
  Future<List<Map<String, dynamic>>> fetchSites() async {
    _throwIfNeeded();
    return [_sitePayload];
  }
}

class _MemoryEstimateCache implements EstimateCache {
  final studios = <String, CachedEstimateStudio>{};
  final documents = <String, CachedEstimate>{};

  @override
  Future<CachedEstimate?> readEstimate(
    String userId,
    String estimateId,
  ) async => documents['$userId::$estimateId'];

  @override
  Future<CachedEstimateStudio?> readStudio(String userId) async =>
      studios[userId];

  @override
  Future<void> writeEstimate(
    String userId,
    String estimateId,
    Map<String, dynamic> payload,
  ) async {
    documents['$userId::$estimateId'] = CachedEstimate(
      payload: payload,
      cachedAt: DateTime.now(),
    );
  }

  @override
  Future<void> writeStudio(String userId, Map<String, dynamic> payload) async {
    studios[userId] = CachedEstimateStudio(
      payload: payload,
      cachedAt: DateTime.now(),
    );
  }
}

const _sitePayload = <String, dynamic>{
  'id': 'site-1',
  'name': 'Orchid Residence',
  'location': 'Sector 57, Gurugram',
  'status': 'ACTIVE',
  'progress': 64,
};

const _brandingPayload = <String, dynamic>{
  'company_name': 'Buildcraft Projects',
  'gst_number': '06ABCDE1234F1Z5',
  'email': 'projects@buildcraft.test',
};

const _estimatePayload = <String, dynamic>{
  'id': 'estimate-1',
  'company_id': 'company-1',
  'site_id': 'site-1',
  'name': 'Orchid Premium Feasibility',
  'input': {
    'site_id': 'site-1',
    'name': 'Orchid Premium Feasibility',
    'plot_area_sqft': 2400,
    'floors': 2,
    'basement': true,
    'construction_type': 'RESIDENTIAL',
    'quality': 'PREMIUM',
    'budget': 8500000,
  },
  'builtup_sqft': 6840,
  'rate_per_sqft': 1242.69,
  'quality_band': 'PREMIUM',
  'type_factor': 1,
  'materials': {
    'cement_bags': 2900.16,
    'steel_kg': 30096,
    'sand_cft': 5814,
    'aggregate_cft': 4446,
    'bricks_pcs': 54720,
  },
  'material_cost': 5100000,
  'labour_cost': 2210000,
  'overhead': 1190000,
  'total': 8500000,
  'created_by': 'contractor-1',
  'created_at': '2026-08-06T09:00:00Z',
};
