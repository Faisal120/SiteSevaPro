import 'dart:typed_data';

import 'package:flutter_test/flutter_test.dart';
import 'package:siteseva/core/network/api_service.dart';
import 'package:siteseva/features/design_studio/data/design_studio_cache.dart';
import 'package:siteseva/features/design_studio/data/design_studio_remote_data_source.dart';
import 'package:siteseva/features/design_studio/data/design_studio_repository_impl.dart';
import 'package:siteseva/features/design_studio/models/design_models.dart';

void main() {
  group('DesignStudioRepositoryImpl', () {
    test(
      'loads contractor studio data and caches the complete bundle',
      () async {
        final remote = _FakeDesignRemote();
        final cache = _MemoryDesignCache();
        final repository = DesignStudioRepositoryImpl(
          remote: remote,
          cache: cache,
          userId: 'contractor-1',
          canManage: true,
        );

        final data = await repository.fetchStudio();

        expect(data.designs.single.projectName, 'Orchid Residence');
        expect(data.wallet?.credits, 86);
        expect(data.purchaseConfig?.packs.single.code, 'starter');
        expect(data.purchases.single.status, 'PENDING');
        expect(cache.studios['contractor-1']?.payload['wallet'], isNotNull);
        expect(remote.walletCalls, 1);
      },
    );

    test(
      'filters assigned-role designs without loading company wallet',
      () async {
        final remote = _FakeDesignRemote(
          designs: [_designPayload, _otherDesignPayload],
        );
        final repository = DesignStudioRepositoryImpl(
          remote: remote,
          cache: _MemoryDesignCache(),
          userId: 'supervisor-1',
          canManage: false,
        );

        final data = await repository.fetchStudio();

        expect(data.designs.map((item) => item.id), ['design-1']);
        expect(data.wallet, isNull);
        expect(remote.walletCalls, 0);
      },
    );

    test('returns cached studio only for connectivity failures', () async {
      final cache = _MemoryDesignCache()
        ..studios['client-1'] = CachedDesignStudio(
          payload: {
            'sites': [_sitePayload],
            'designs': [_designPayload],
          },
          cachedAt: DateTime(2026, 8, 6, 10),
        );
      final repository = DesignStudioRepositoryImpl(
        remote: _FakeDesignRemote(
          error: const ApiException('offline', kind: ApiErrorKind.network),
        ),
        cache: cache,
        userId: 'client-1',
        canManage: false,
      );

      final data = await repository.fetchStudio();

      expect(data.isOffline, isTrue);
      expect(data.designs.single.id, 'design-1');
    });

    test('does not mask authorization failures with cached data', () async {
      final cache = _MemoryDesignCache()
        ..studios['client-1'] = CachedDesignStudio(
          payload: {
            'sites': [_sitePayload],
            'designs': [_designPayload],
          },
          cachedAt: DateTime(2026, 8, 6),
        );
      final repository = DesignStudioRepositoryImpl(
        remote: _FakeDesignRemote(
          error: const ApiException(
            'forbidden',
            statusCode: 403,
            kind: ApiErrorKind.authentication,
          ),
        ),
        cache: cache,
        userId: 'client-1',
        canManage: false,
      );

      expect(repository.fetchStudio, throwsA(isA<ApiException>()));
    });

    test(
      'deep-linked assigned design verifies live site access without cache',
      () async {
        final repository = DesignStudioRepositoryImpl(
          remote: _FakeDesignRemote(),
          cache: _MemoryDesignCache(),
          userId: 'supervisor-1',
          canManage: false,
        );

        final design = await repository.fetchDesign('design-1');

        expect(design.siteId, 'site-1');
      },
    );

    test(
      'submits the rich generation contract to the existing endpoint',
      () async {
        final remote = _FakeDesignRemote();
        final repository = DesignStudioRepositoryImpl(
          remote: remote,
          cache: _MemoryDesignCache(),
          userId: 'contractor-1',
          canManage: true,
        );
        const brief = DesignBrief(
          siteId: 'site-1',
          projectName: 'Orchid Residence',
          plotWidth: 40,
          plotLength: 60,
          facing: 'North',
          floors: 2,
          variation: 1,
          floorRequirements: [
            DesignFloorRequirement(floorNumber: 1, parking: true),
            DesignFloorRequirement(floorNumber: 2, balcony: true),
          ],
        );

        await repository.generate(brief);

        expect(remote.lastGeneration?['site_id'], 'site-1');
        expect(remote.lastGeneration?['type'], '2D');
        expect(remote.lastGeneration?['variation'], 1);
        expect(remote.lastGeneration?['floor_requirements'], hasLength(2));
      },
    );

    test('submits a normalized credit purchase reference', () async {
      final remote = _FakeDesignRemote();
      final repository = DesignStudioRepositoryImpl(
        remote: remote,
        cache: _MemoryDesignCache(),
        userId: 'contractor-1',
        canManage: true,
      );

      final purchase = await repository.requestCredits(
        pack: 'starter',
        utr: '  UTR-90812  ',
        note: '  Paid from company account  ',
      );

      expect(purchase.status, 'PENDING');
      expect(remote.lastPurchase?['utr'], 'UTR-90812');
      expect(remote.lastPurchase?['note'], 'Paid from company account');
    });

    test(
      'blocks every design mutation for supervisor and client roles',
      () async {
        final repository = DesignStudioRepositoryImpl(
          remote: _FakeDesignRemote(),
          cache: _MemoryDesignCache(),
          userId: 'client-1',
          canManage: false,
        );

        expect(
          repository.deleteDesign('design-1'),
          throwsA(
            isA<ApiException>().having(
              (error) => error.statusCode,
              'statusCode',
              403,
            ),
          ),
        );
        expect(
          repository.generateThreeD('design-1', 1),
          throwsA(isA<ApiException>()),
        );
        expect(
          repository.generateTechnical(
            'design-1',
            DesignDrawingType.electrical,
          ),
          throwsA(isA<ApiException>()),
        );
      },
    );
  });
}

class _FakeDesignRemote implements DesignStudioRemoteDataSource {
  _FakeDesignRemote({this.designs = const [_designPayload], this.error});

  final List<Map<String, dynamic>> designs;
  final ApiException? error;
  int walletCalls = 0;
  Map<String, dynamic>? lastGeneration;
  Map<String, dynamic>? lastPurchase;

  void _throwIfNeeded() {
    if (error != null) throw error!;
  }

  @override
  Future<void> deleteDesign(String designId) async => _throwIfNeeded();

  @override
  Future<Uint8List> downloadPdf(
    String designId,
    String drawingType,
    int floorNumber,
  ) async => Uint8List.fromList([1, 2, 3]);

  @override
  Future<Map<String, dynamic>> fetchDesign(String designId) async {
    _throwIfNeeded();
    return Map<String, dynamic>.from(_designPayload);
  }

  @override
  Future<List<Map<String, dynamic>>> fetchDesigns() async {
    _throwIfNeeded();
    return designs;
  }

  @override
  Future<Map<String, dynamic>> fetchPurchaseConfig() async {
    _throwIfNeeded();
    return {
      'upi_id': 'billing@siteseva',
      'payee_name': 'SiteSeva Pro',
      'packs': {
        'starter': {'credits': 50, 'amount': 199},
      },
    };
  }

  @override
  Future<List<Map<String, dynamic>>> fetchPurchases() async {
    _throwIfNeeded();
    return [_purchasePayload];
  }

  @override
  Future<List<Map<String, dynamic>>> fetchSites() async {
    _throwIfNeeded();
    return [_sitePayload];
  }

  @override
  Future<List<Map<String, dynamic>>> fetchTransactions() async {
    _throwIfNeeded();
    return [
      {
        'id': 'transaction-1',
        'type': 'DEBIT',
        'credits': -10,
        'description': '2D floor plan',
        'created_at': '2026-08-06T09:00:00Z',
      },
    ];
  }

  @override
  Future<Map<String, dynamic>> fetchWallet() async {
    walletCalls += 1;
    _throwIfNeeded();
    return {'company_id': 'company-1', 'credits': 86};
  }

  @override
  Future<Map<String, dynamic>> generate(Map<String, dynamic> payload) async {
    _throwIfNeeded();
    lastGeneration = payload;
    return Map<String, dynamic>.from(_designPayload);
  }

  @override
  Future<Map<String, dynamic>> generateTechnical(
    String designId,
    String drawingType,
  ) async {
    _throwIfNeeded();
    return Map<String, dynamic>.from(_designPayload);
  }

  @override
  Future<Map<String, dynamic>> generateThreeD(
    String designId,
    int floorNumber,
  ) async {
    _throwIfNeeded();
    return Map<String, dynamic>.from(_designPayload);
  }

  @override
  Future<Map<String, dynamic>> requestPurchase(
    Map<String, dynamic> payload,
  ) async {
    _throwIfNeeded();
    lastPurchase = payload;
    return Map<String, dynamic>.from(_purchasePayload);
  }
}

class _MemoryDesignCache implements DesignStudioCache {
  final studios = <String, CachedDesignStudio>{};
  final designs = <String, CachedDesign>{};

  @override
  Future<CachedDesign?> readDesign(String userId, String designId) async =>
      designs['$userId::$designId'];

  @override
  Future<CachedDesignStudio?> readStudio(String userId) async =>
      studios[userId];

  @override
  Future<void> removeDesign(String userId, String designId) async {
    designs.remove('$userId::$designId');
  }

  @override
  Future<void> writeDesign(
    String userId,
    String designId,
    Map<String, dynamic> payload,
  ) async {
    designs['$userId::$designId'] = CachedDesign(
      payload: payload,
      cachedAt: DateTime.now(),
    );
  }

  @override
  Future<void> writeStudio(String userId, Map<String, dynamic> payload) async {
    studios[userId] = CachedDesignStudio(
      payload: payload,
      cachedAt: DateTime.now(),
    );
  }
}

const _sitePayload = <String, dynamic>{
  'id': 'site-1',
  'name': 'Orchid Residence',
  'location': 'Gurugram',
  'status': 'ACTIVE',
  'progress': 64,
};

const _designPayload = <String, dynamic>{
  'id': 'design-1',
  'site_id': 'site-1',
  'project_name': 'Orchid Residence',
  'design_type': '2D',
  'status': 'COMPLETED',
  'credits_used': 10,
  'created_at': '2026-08-06T09:00:00Z',
  'updated_at': '2026-08-06T09:02:00Z',
  'inputs': {
    'plot_width': 40,
    'plot_length': 60,
    'facing': 'North',
    'floors': 2,
    'variation': 0,
    'floor_requirements': [
      {'floor_number': 1, 'bedrooms': 2, 'bathrooms': 2},
      {'floor_number': 2, 'bedrooms': 3, 'bathrooms': 3},
    ],
  },
  'outputs': {
    'svg': '<svg viewBox="0 0 400 600"></svg>',
    'layout': {
      'svg': '<svg viewBox="0 0 400 600"></svg>',
      'plot': {'width': 40, 'length': 60, 'facing': 'North'},
      'rooms': [],
    },
    'floor_plans': [
      {
        'floor_number': 1,
        'label': 'Ground Floor',
        'layout': {
          'svg': '<svg viewBox="0 0 400 600"></svg>',
          'plot': {'width': 40, 'length': 60, 'facing': 'North'},
          'rooms': [],
        },
      },
      {
        'floor_number': 2,
        'label': 'First Floor',
        'layout': {
          'svg': '<svg viewBox="0 0 400 600"></svg>',
          'plot': {'width': 40, 'length': 60, 'facing': 'North'},
          'rooms': [],
        },
      },
    ],
    'technical_drawings': {},
    'three_d': {},
  },
};

final _otherDesignPayload = <String, dynamic>{
  ..._designPayload,
  'id': 'design-2',
  'site_id': 'site-hidden',
  'project_name': 'Hidden Company Project',
};

const _purchasePayload = <String, dynamic>{
  'id': 'purchase-1',
  'pack': 'starter',
  'credits': 50,
  'amount': 199,
  'utr': 'UTR-90812',
  'status': 'PENDING',
  'created_at': '2026-08-06T10:00:00Z',
};
