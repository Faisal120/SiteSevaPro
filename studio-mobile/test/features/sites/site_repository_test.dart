import 'package:flutter_test/flutter_test.dart';
import 'package:siteseva/core/network/api_service.dart';
import 'package:siteseva/features/sites/data/site_cache.dart';
import 'package:siteseva/features/sites/data/site_remote_data_source.dart';
import 'package:siteseva/features/sites/data/site_repository_impl.dart';
import 'package:siteseva/features/sites/models/site_models.dart';

void main() {
  group('SiteRepositoryImpl', () {
    test('loads and caches role-filtered site summaries', () async {
      final remote = _FakeSiteRemote(sites: [_summary]);
      final cache = _MemorySiteCache();
      final repository = SiteRepositoryImpl(
        remote: remote,
        cache: cache,
        userId: 'contractor-1',
      );

      final collection = await repository.fetchSites();

      expect(collection.sites.single.name, 'Orchid Residence');
      expect(collection.isOffline, isFalse);
      expect(cache.lists['contractor-1']?.payload.single['id'], 'site-1');
    });

    test('returns cached sites only for connectivity failures', () async {
      final cache = _MemorySiteCache()
        ..lists['client-1'] = CachedSiteList(
          payload: [_summary],
          cachedAt: DateTime(2026, 8, 6, 10),
        );
      final repository = SiteRepositoryImpl(
        remote: _FakeSiteRemote(
          error: const ApiException('offline', kind: ApiErrorKind.network),
        ),
        cache: cache,
        userId: 'client-1',
      );

      final collection = await repository.fetchSites();

      expect(collection.isOffline, isTrue);
      expect(collection.sites.single.id, 'site-1');
    });

    test('does not hide authorization failures behind cache', () async {
      final cache = _MemorySiteCache()
        ..lists['client-1'] = CachedSiteList(
          payload: [_summary],
          cachedAt: DateTime(2026, 8, 6),
        );
      final repository = SiteRepositoryImpl(
        remote: _FakeSiteRemote(
          error: const ApiException(
            'forbidden',
            statusCode: 403,
            kind: ApiErrorKind.authentication,
          ),
        ),
        cache: cache,
        userId: 'client-1',
      );

      expect(repository.fetchSites, throwsA(isA<ApiException>()));
    });

    test('creates a site using the existing backend contract', () async {
      final remote = _FakeSiteRemote(createdSite: _detail);
      final repository = SiteRepositoryImpl(
        remote: remote,
        cache: _MemorySiteCache(),
        userId: 'contractor-1',
      );

      final site = await repository.createSite(_mutation);

      expect(site.id, 'site-1');
      expect(remote.lastMutation?['name'], 'Orchid Residence');
      expect(remote.lastMutation?['start_date'], '2026-08-06');
      expect(remote.lastMutation?['has_boring'], isTrue);
    });

    test('loads and caches typed site records', () async {
      final remote = _FakeSiteRemote(
        materials: [
          {
            'id': 'material-1',
            'site_id': 'site-1',
            'name': 'OPC Cement',
            'category': 'Cement',
            'unit': 'bags',
            'stock': 8,
            'low_stock_threshold': 10,
            'rate': 420,
          },
        ],
      );
      final cache = _MemorySiteCache();
      final repository = SiteRepositoryImpl(
        remote: remote,
        cache: cache,
        userId: 'supervisor-1',
      );

      final materials = await repository.fetchMaterials('site-1');

      expect(materials.single.isLowStock, isTrue);
      expect(materials.single.stockValue, 3360);
      expect(cache.records['supervisor-1::site-1::materials'], isNotNull);
    });

    test('loads eligible site assignees from the live team endpoint', () async {
      final repository = SiteRepositoryImpl(
        remote: _FakeSiteRemote(
          team: [
            {
              'id': 'supervisor-1',
              'full_name': 'Rohan Singh',
              'role': 'SUPERVISOR',
            },
            {
              'id': 'client-1',
              'full_name': 'Kapoor Family',
              'role': 'CLIENT',
            },
          ],
        ),
        cache: _MemorySiteCache(),
        userId: 'contractor-1',
      );

      final team = await repository.fetchTeam();

      expect(team.where((member) => member.isSupervisor).single.id, 'supervisor-1');
      expect(team.where((member) => member.isClient).single.id, 'client-1');
    });
  });
}

const _summary = <String, dynamic>{
  'id': 'site-1',
  'name': 'Orchid Residence',
  'location': 'Gurugram',
  'status': 'ACTIVE',
  'progress': 64,
  'supervisor_names': ['Anita Rao'],
  'client_name': 'Meera Shah',
};

const _detail = <String, dynamic>{
  'id': 'site-1',
  'company_id': 'company-1',
  'created_by': 'contractor-1',
  'created_at': '2026-08-06T09:00:00Z',
  'name': 'Orchid Residence',
  'location': 'Gurugram',
  'budget': 8500000,
  'start_date': '2026-08-06',
  'end_date': '2027-02-06',
  'status': 'ACTIVE',
  'progress': 0,
  'floors': 3,
  'has_boring': true,
  'has_septic_tank': true,
  'has_soak_pit': true,
  'has_mumty': true,
  'supervisor_ids': [],
  'supervisor_names': [],
  'client_ids': [],
};

final _mutation = SiteMutation(
  name: 'Orchid Residence',
  location: 'Gurugram',
  budget: 8500000,
  startDate: DateTime(2026, 8, 6),
  endDate: DateTime(2027, 2, 6),
  floors: 3,
  hasBoring: true,
  hasSepticTank: true,
  hasSoakPit: true,
  hasMumty: true,
  status: SiteStatus.active,
  progress: 0,
  supervisorIds: const [],
);

class _FakeSiteRemote implements SiteRemoteDataSource {
  _FakeSiteRemote({
    this.sites = const [],
    this.createdSite,
    this.materials = const [],
    this.team = const [],
    this.error,
  });

  final List<Map<String, dynamic>> sites;
  final Map<String, dynamic>? createdSite;
  final List<Map<String, dynamic>> materials;
  final List<Map<String, dynamic>> team;
  final ApiException? error;
  Map<String, dynamic>? lastMutation;

  void _throwIfNeeded() {
    if (error != null) throw error!;
  }

  @override
  Future<Map<String, dynamic>> createSite(Map<String, dynamic> payload) async {
    _throwIfNeeded();
    lastMutation = payload;
    return Map<String, dynamic>.from(createdSite ?? _detail);
  }

  @override
  Future<void> deleteSite(String siteId) async => _throwIfNeeded();

  @override
  Future<List<Map<String, dynamic>>> fetchAttendance(String siteId) async {
    _throwIfNeeded();
    return [];
  }

  @override
  Future<List<Map<String, dynamic>>> fetchLabour(String siteId) async {
    _throwIfNeeded();
    return [];
  }

  @override
  Future<List<Map<String, dynamic>>> fetchMaterials(String siteId) async {
    _throwIfNeeded();
    return materials;
  }

  @override
  Future<List<Map<String, dynamic>>> fetchPayments(String siteId) async {
    _throwIfNeeded();
    return [];
  }

  @override
  Future<List<Map<String, dynamic>>> fetchReports(String siteId) async {
    _throwIfNeeded();
    return [];
  }

  @override
  Future<Map<String, dynamic>> fetchSite(String siteId) async {
    _throwIfNeeded();
    return Map<String, dynamic>.from(_detail);
  }

  @override
  Future<List<Map<String, dynamic>>> fetchSites() async {
    _throwIfNeeded();
    return sites;
  }

  @override
  Future<List<Map<String, dynamic>>> fetchTeam() async {
    _throwIfNeeded();
    return team;
  }

  @override
  Future<Map<String, dynamic>> updateSite(
    String siteId,
    Map<String, dynamic> payload,
  ) async {
    _throwIfNeeded();
    lastMutation = payload;
    return Map<String, dynamic>.from(_detail);
  }

  @override
  Future<void> assignClient(String siteId, String userId) async =>
      _throwIfNeeded();

  @override
  Future<void> assignSupervisor(String siteId, String userId) async =>
      _throwIfNeeded();
}

class _MemorySiteCache implements SiteCache {
  final lists = <String, CachedSiteList>{};
  final details = <String, CachedSiteDetail>{};
  final records = <String, CachedSiteRecords>{};

  @override
  Future<CachedSiteDetail?> readDetail(String userId, String siteId) async =>
      details['$userId::$siteId'];

  @override
  Future<CachedSiteList?> readList(String userId) async => lists[userId];

  @override
  Future<CachedSiteRecords?> readRecords(
    String userId,
    String siteId,
    String type,
  ) async => records['$userId::$siteId::$type'];

  @override
  Future<void> removeSite(String userId, String siteId) async {
    details.remove('$userId::$siteId');
  }

  @override
  Future<void> writeDetail(
    String userId,
    String siteId,
    Map<String, dynamic> payload,
  ) async {
    details['$userId::$siteId'] = CachedSiteDetail(
      payload: payload,
      cachedAt: DateTime.now(),
    );
  }

  @override
  Future<void> writeList(
    String userId,
    List<Map<String, dynamic>> payload,
  ) async {
    lists[userId] = CachedSiteList(payload: payload, cachedAt: DateTime.now());
  }

  @override
  Future<void> writeRecords(
    String userId,
    String siteId,
    String type,
    List<Map<String, dynamic>> payload,
  ) async {
    records['$userId::$siteId::$type'] = CachedSiteRecords(
      payload: payload,
      cachedAt: DateTime.now(),
    );
  }
}
