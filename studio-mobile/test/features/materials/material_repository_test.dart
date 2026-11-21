import 'package:flutter_test/flutter_test.dart';
import 'package:siteseva/core/network/api_service.dart';
import 'package:siteseva/features/materials/data/materials_cache.dart';
import 'package:siteseva/features/materials/data/materials_remote_data_source.dart';
import 'package:siteseva/features/materials/data/materials_repository_impl.dart';
import 'package:siteseva/features/materials/models/material_models.dart';

void main() {
  group('MaterialsRepositoryImpl', () {
    test(
      'loads and caches contractor inventory, movements, and vendors',
      () async {
        final remote = _FakeMaterialsRemote();
        final cache = _MemoryMaterialsCache();
        final repository = _repository(remote: remote, cache: cache);

        final data = await repository.fetchStudio();

        expect(data.materials.single.name, 'OPC 53 Grade Cement');
        expect(data.movements.single.id, 'movement-1');
        expect(data.vendors.single.name, 'Shree Cement Supply');
        expect(data.sites.single.name, 'Orchid Residence');
        expect(data.canManageVendors, isTrue);
        expect(remote.unscopedMovementRequests, 1);
        expect(remote.vendorRequests, 1);
        expect(cache.studios['contractor-1'], isNotNull);
      },
    );

    test(
      'supervisor fetches movements per assigned site and skips vendors',
      () async {
        final remote = _FakeMaterialsRemote(
          sites: [_sitePayload, _secondSitePayload],
        );
        final repository = _repository(
          remote: remote,
          cache: _MemoryMaterialsCache(),
          canManageVendors: false,
          restrictMovements: true,
        );

        final data = await repository.fetchStudio();

        expect(remote.unscopedMovementRequests, 0);
        expect(remote.movementSiteRequests, ['site-1', 'site-2']);
        expect(remote.vendorRequests, 0);
        expect(data.canManageVendors, isFalse);
        expect(data.movements.length, 2);
      },
    );

    test('uses cached studio only for connectivity failure', () async {
      final cache = _MemoryMaterialsCache()
        ..studios['contractor-1'] = CachedMaterialsStudio(
          payload: _cachedStudio,
          cachedAt: DateTime(2026, 8, 6, 9),
        );
      final repository = _repository(
        remote: _FakeMaterialsRemote(
          error: const ApiException('offline', kind: ApiErrorKind.network),
        ),
        cache: cache,
      );

      final data = await repository.fetchStudio();

      expect(data.isOffline, isTrue);
      expect(data.materials.single.id, 'material-1');
      expect(data.fetchedAt, DateTime(2026, 8, 6, 9));
    });

    test('does not mask authorization errors with cached inventory', () async {
      final cache = _MemoryMaterialsCache()
        ..studios['contractor-1'] = CachedMaterialsStudio(
          payload: _cachedStudio,
          cachedAt: DateTime(2026, 8, 6),
        );
      final repository = _repository(
        remote: _FakeMaterialsRemote(
          error: const ApiException(
            'forbidden',
            statusCode: 403,
            kind: ApiErrorKind.authentication,
          ),
        ),
        cache: cache,
      );

      expect(repository.fetchStudio(), throwsA(isA<ApiException>()));
    });

    test('validates assignment and submits exact MaterialIn payload', () async {
      final remote = _FakeMaterialsRemote();
      final repository = _repository(
        remote: remote,
        cache: _MemoryMaterialsCache(),
      );
      const brief = MaterialCreationBrief(
        siteId: 'site-1',
        name: 'OPC 53 Grade Cement',
        category: MaterialCategory.cement,
        unit: 'bags',
        openingStock: 84,
        lowStockThreshold: 10,
        rate: 550,
      );

      final created = await repository.createMaterial(brief);

      expect(created.id, 'material-1');
      expect(remote.lastMaterial, brief.toApiJson());
      expect(
        repository.createMaterial(brief.copyWith(siteId: 'site-unknown')),
        throwsA(isA<ApiException>()),
      );
    });

    test('submits exact MaterialTxnIn payload', () async {
      final remote = _FakeMaterialsRemote();
      final repository = _repository(
        remote: remote,
        cache: _MemoryMaterialsCache(),
      );
      final material = MaterialItem.fromJson(_materialPayload);
      final brief = MaterialMovementBrief.initial(material).copyWith(
        type: MaterialMovementType.outward,
        quantity: 12,
        note: 'Issued for slab casting',
      );

      final movement = await repository.createMovement(brief);

      expect(movement.id, 'movement-1');
      expect(remote.lastMovement, brief.toApiJson());
    });

    test(
      'creates and deletes vendors using exact contractor contracts',
      () async {
        final remote = _FakeMaterialsRemote();
        final repository = _repository(
          remote: remote,
          cache: _MemoryMaterialsCache(),
        );
        const brief = MaterialVendorBrief(
          name: 'Shree Cement Supply',
          contact: '9876543210',
          gst: '06ABCDE1234F1Z5',
          address: 'Gurugram, Haryana',
          paymentTerms: 'Net 30 days',
          categories: ['Cement'],
        );

        final vendor = await repository.createVendor(brief);
        await repository.deleteVendor(vendor.id);

        expect(remote.lastVendor, brief.toApiJson());
        expect(remote.deletedVendorId, 'vendor-1');
      },
    );

    test('blocks stock and vendor operations outside role capabilities', () {
      final repository = _repository(
        remote: _FakeMaterialsRemote(),
        cache: _MemoryMaterialsCache(),
        canView: false,
        canManageStock: false,
        canManageVendors: false,
      );
      final material = MaterialItem.fromJson(_materialPayload);

      expect(repository.fetchStudio(), throwsA(isA<ApiException>()));
      expect(
        repository.createMaterial(MaterialCreationBrief.initial()),
        throwsA(isA<ApiException>()),
      );
      expect(
        repository.createMovement(MaterialMovementBrief.initial(material)),
        throwsA(isA<ApiException>()),
      );
      expect(
        repository.createVendor(MaterialVendorBrief.initial()),
        throwsA(isA<ApiException>()),
      );
      expect(repository.deleteVendor('vendor-1'), throwsA(isA<ApiException>()));
    });
  });
}

MaterialsRepositoryImpl _repository({
  required MaterialsRemoteDataSource remote,
  required MaterialsCache cache,
  bool canView = true,
  bool canManageStock = true,
  bool canManageVendors = true,
  bool restrictMovements = false,
}) => MaterialsRepositoryImpl(
  remote: remote,
  cache: cache,
  userId: 'contractor-1',
  canView: canView,
  canManageStock: canManageStock,
  canManageVendors: canManageVendors,
  restrictMovementsToAssignedSites: restrictMovements,
);

class _FakeMaterialsRemote implements MaterialsRemoteDataSource {
  _FakeMaterialsRemote({this.error, this.sites = const [_sitePayload]});

  final ApiException? error;
  final List<Map<String, dynamic>> sites;
  int unscopedMovementRequests = 0;
  int vendorRequests = 0;
  final movementSiteRequests = <String>[];
  Map<String, dynamic>? lastMaterial;
  Map<String, dynamic>? lastMovement;
  Map<String, dynamic>? lastVendor;
  String? deletedVendorId;

  void _throwIfNeeded() {
    if (error != null) throw error!;
  }

  @override
  Future<Map<String, dynamic>> createMaterial(
    Map<String, dynamic> payload,
  ) async {
    _throwIfNeeded();
    lastMaterial = payload;
    return Map<String, dynamic>.from(_materialPayload);
  }

  @override
  Future<Map<String, dynamic>> createMovement(
    Map<String, dynamic> payload,
  ) async {
    _throwIfNeeded();
    lastMovement = payload;
    return Map<String, dynamic>.from(_movementPayload);
  }

  @override
  Future<Map<String, dynamic>> createVendor(
    Map<String, dynamic> payload,
  ) async {
    _throwIfNeeded();
    lastVendor = payload;
    return Map<String, dynamic>.from(_vendorPayload);
  }

  @override
  Future<void> deleteVendor(String vendorId) async {
    _throwIfNeeded();
    deletedVendorId = vendorId;
  }

  @override
  Future<List<Map<String, dynamic>>> fetchMaterials({String? siteId}) async {
    _throwIfNeeded();
    return [_materialPayload];
  }

  @override
  Future<List<Map<String, dynamic>>> fetchMovements({String? siteId}) async {
    _throwIfNeeded();
    if (siteId == null) {
      unscopedMovementRequests += 1;
      return [_movementPayload];
    }
    movementSiteRequests.add(siteId);
    return [
      {..._movementPayload, 'id': 'movement-$siteId', 'site_id': siteId},
    ];
  }

  @override
  Future<List<Map<String, dynamic>>> fetchSites() async {
    _throwIfNeeded();
    return sites;
  }

  @override
  Future<List<Map<String, dynamic>>> fetchVendors() async {
    _throwIfNeeded();
    vendorRequests += 1;
    return [_vendorPayload];
  }
}

class _MemoryMaterialsCache implements MaterialsCache {
  final studios = <String, CachedMaterialsStudio>{};

  @override
  Future<CachedMaterialsStudio?> readStudio(String userId) async =>
      studios[userId];

  @override
  Future<void> writeStudio(String userId, Map<String, dynamic> payload) async {
    studios[userId] = CachedMaterialsStudio(
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

const _secondSitePayload = <String, dynamic>{
  'id': 'site-2',
  'name': 'Lakeview Villas',
  'location': 'Noida Extension',
  'status': 'ACTIVE',
  'progress': 39,
};

const _materialPayload = <String, dynamic>{
  'id': 'material-1',
  'company_id': 'company-1',
  'site_id': 'site-1',
  'name': 'OPC 53 Grade Cement',
  'category': 'Cement',
  'unit': 'bags',
  'stock': 84,
  'low_stock_threshold': 10,
  'rate': 550,
  'created_at': '2026-08-01T08:00:00Z',
};

const _movementPayload = <String, dynamic>{
  'id': 'movement-1',
  'company_id': 'company-1',
  'material_id': 'material-1',
  'site_id': 'site-1',
  'type': 'INWARD',
  'quantity': 50,
  'rate': 565,
  'vendor': 'Shree Cement Supply',
  'note': 'Gate receipt GR-108',
  'invoice_url': 'https://cdn.example.test/invoice-108.pdf',
  'created_by': 'supervisor-1',
  'created_at': '2026-08-06T09:30:00Z',
};

const _vendorPayload = <String, dynamic>{
  'id': 'vendor-1',
  'company_id': 'company-1',
  'name': 'Shree Cement Supply',
  'contact': '9876543210',
  'gst': '06ABCDE1234F1Z5',
  'address': 'Gurugram, Haryana',
  'payment_terms': 'Net 30 days',
  'categories': ['Cement'],
  'created_at': '2026-08-01T10:00:00Z',
};

const _cachedStudio = <String, dynamic>{
  'sites': [_sitePayload],
  'materials': [_materialPayload],
  'movements': [_movementPayload],
  'vendors': [_vendorPayload],
};
