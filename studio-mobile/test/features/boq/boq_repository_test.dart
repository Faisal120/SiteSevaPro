import 'package:flutter_test/flutter_test.dart';
import 'package:siteseva/core/network/api_service.dart';
import 'package:siteseva/features/boq/data/boq_cache.dart';
import 'package:siteseva/features/boq/data/boq_remote_data_source.dart';
import 'package:siteseva/features/boq/data/boq_repository_impl.dart';
import 'package:siteseva/features/boq/models/boq_models.dart';

void main() {
  group('BoqRepositoryImpl', () {
    test('loads and caches the complete contractor BOQ workspace', () async {
      final remote = _FakeBoqRemote();
      final cache = _MemoryBoqCache();
      final repository = BoqRepositoryImpl(
        remote: remote,
        cache: cache,
        userId: 'contractor-1',
        canManage: true,
      );

      final data = await repository.fetchStudio();

      expect(data.boqs.single.name, 'Orchid Tender BOQ');
      expect(data.estimates.single.qualityBand, 'PREMIUM');
      expect(data.vendors.single.gst, '06ABCDE1234F1Z5');
      expect(data.sites.single.name, 'Orchid Residence');
      expect(cache.studios['contractor-1']?.payload['boqs'], isNotNull);
    });

    test('uses cached BOQs only for connectivity failures', () async {
      final cache = _MemoryBoqCache()
        ..studios['contractor-1'] = CachedBoqStudio(
          payload: {
            'boqs': [_boqPayload],
            'sites': [_sitePayload],
            'estimates': [_estimatePayload],
            'vendors': [_vendorPayload],
          },
          cachedAt: DateTime(2026, 8, 6, 10),
        );
      final repository = BoqRepositoryImpl(
        remote: _FakeBoqRemote(
          error: const ApiException('offline', kind: ApiErrorKind.network),
        ),
        cache: cache,
        userId: 'contractor-1',
        canManage: true,
      );

      final data = await repository.fetchStudio();

      expect(data.isOffline, isTrue);
      expect(data.boqs.single.id, 'boq-1');
    });

    test('does not mask backend authorization failures with cache', () async {
      final cache = _MemoryBoqCache()
        ..studios['contractor-1'] = CachedBoqStudio(
          payload: {
            'boqs': [_boqPayload],
            'sites': [_sitePayload],
            'estimates': [_estimatePayload],
            'vendors': [_vendorPayload],
          },
          cachedAt: DateTime(2026, 8, 6),
        );
      final repository = BoqRepositoryImpl(
        remote: _FakeBoqRemote(
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

    test('submits the exact estimate-linked BOQGenerateIn payload', () async {
      final remote = _FakeBoqRemote();
      final repository = BoqRepositoryImpl(
        remote: remote,
        cache: _MemoryBoqCache(),
        userId: 'contractor-1',
        canManage: true,
      );
      const brief = BoqGenerationBrief(
        name: 'Orchid Tender BOQ',
        siteId: 'site-1',
        source: BoqGenerationSource.estimate,
        estimateId: 'estimate-1',
        builtupSqft: 0,
      );

      final generated = await repository.generate(brief);

      expect(generated.id, 'boq-1');
      expect(remote.lastGeneration?['site_id'], 'site-1');
      expect(remote.lastGeneration?['estimate_id'], 'estimate-1');
      expect(remote.lastGeneration?.containsKey('builtup_sqft'), isFalse);
    });

    test('loads an offline cached issued worksheet', () async {
      final cache = _MemoryBoqCache()
        ..documents['contractor-1::boq-1'] = CachedBoq(
          payload: _boqPayload,
          cachedAt: DateTime(2026, 8, 6),
        );
      final repository = BoqRepositoryImpl(
        remote: _FakeBoqRemote(
          error: const ApiException('offline', kind: ApiErrorKind.network),
        ),
        cache: cache,
        userId: 'contractor-1',
        canManage: true,
      );

      final document = await repository.fetchBoq('boq-1');

      expect(document.total, 433000);
      expect(document.itemCount, 3);
    });

    test('blocks BOQ list, detail, and generation for non-contractors', () {
      final repository = BoqRepositoryImpl(
        remote: _FakeBoqRemote(),
        cache: _MemoryBoqCache(),
        userId: 'client-1',
        canManage: false,
      );

      expect(repository.fetchStudio(), throwsA(isA<ApiException>()));
      expect(repository.fetchBoq('boq-1'), throwsA(isA<ApiException>()));
      expect(
        repository.generate(BoqGenerationBrief.initial()),
        throwsA(isA<ApiException>()),
      );
    });
  });
}

class _FakeBoqRemote implements BoqRemoteDataSource {
  _FakeBoqRemote({this.error});
  final ApiException? error;
  Map<String, dynamic>? lastGeneration;

  void _throwIfNeeded() {
    if (error != null) throw error!;
  }

  @override
  Future<List<Map<String, dynamic>>> fetchBoqs() async {
    _throwIfNeeded();
    return [_boqPayload];
  }

  @override
  Future<Map<String, dynamic>> fetchBoq(String boqId) async {
    _throwIfNeeded();
    return Map<String, dynamic>.from(_boqPayload);
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

  @override
  Future<List<Map<String, dynamic>>> fetchVendors() async {
    _throwIfNeeded();
    return [_vendorPayload];
  }

  @override
  Future<Map<String, dynamic>> generate(Map<String, dynamic> payload) async {
    _throwIfNeeded();
    lastGeneration = payload;
    return Map<String, dynamic>.from(_boqPayload);
  }
}

class _MemoryBoqCache implements BoqCache {
  final studios = <String, CachedBoqStudio>{};
  final documents = <String, CachedBoq>{};

  @override
  Future<CachedBoq?> readBoq(String userId, String boqId) async =>
      documents['$userId::$boqId'];

  @override
  Future<CachedBoqStudio?> readStudio(String userId) async => studios[userId];

  @override
  Future<void> writeBoq(
    String userId,
    String boqId,
    Map<String, dynamic> payload,
  ) async {
    documents['$userId::$boqId'] = CachedBoq(
      payload: payload,
      cachedAt: DateTime.now(),
    );
  }

  @override
  Future<void> writeStudio(String userId, Map<String, dynamic> payload) async {
    studios[userId] = CachedBoqStudio(
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

const _estimatePayload = <String, dynamic>{
  'id': 'estimate-1',
  'site_id': 'site-1',
  'name': 'Approved Premium Estimate',
  'builtup_sqft': 4650,
  'total': 8500000,
  'quality_band': 'PREMIUM',
  'created_at': '2026-08-05T09:00:00Z',
};

const _vendorPayload = <String, dynamic>{
  'id': 'vendor-1',
  'name': 'Shree Buildmart',
  'contact': '9876543210',
  'gst': '06ABCDE1234F1Z5',
  'categories': ['Cement', 'Steel'],
};

const _boqPayload = <String, dynamic>{
  'id': 'boq-1',
  'estimate_id': 'estimate-1',
  'site_id': 'site-1',
  'name': 'Orchid Tender BOQ',
  'builtup_sqft': 4650,
  'sections': [
    {
      'name': 'Foundation',
      'subtotal': 142000,
      'items': [
        {
          'desc': 'PCC bed',
          'unit': 'cum',
          'qty': 12,
          'rate': 6500,
          'amount': 78000,
        },
        {
          'desc': 'Earthwork excavation',
          'unit': 'cum',
          'qty': 200,
          'rate': 320,
          'amount': 64000,
        },
      ],
    },
    {
      'name': 'RCC Work',
      'subtotal': 291000,
      'items': [
        {
          'desc': 'Columns and beams',
          'unit': 'cum',
          'qty': 30,
          'rate': 9700,
          'amount': 291000,
        },
      ],
    },
  ],
  'total': 433000,
  'created_by': 'contractor-1',
  'created_at': '2026-08-06T09:00:00Z',
};
