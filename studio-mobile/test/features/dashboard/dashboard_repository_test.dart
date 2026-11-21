import 'package:flutter_test/flutter_test.dart';
import 'package:siteseva/core/network/api_service.dart';
import 'package:siteseva/features/dashboard/data/dashboard_cache.dart';
import 'package:siteseva/features/dashboard/data/dashboard_remote_data_source.dart';
import 'package:siteseva/features/dashboard/data/dashboard_repository_impl.dart';

void main() {
  group('DashboardRepositoryImpl', () {
    test('loads and caches the role dashboard response', () async {
      final remote = _FakeRemote(payload: _payload);
      final cache = _MemoryCache();
      final repository = DashboardRepositoryImpl(
        remote: remote,
        cache: cache,
        userId: 'contractor-1',
        role: 'CONTRACTOR',
      );

      final dashboard = await repository.fetch();

      expect(dashboard.company.name, 'Buildcraft Projects');
      expect(dashboard.stats.activeSites, 2);
      expect(dashboard.sites.single.progress, 64);
      expect(dashboard.isOffline, isFalse);
      expect(cache.entries['contractor-1'], isNotNull);
    });

    test('returns cached live data when connectivity is unavailable', () async {
      final remote = _FakeRemote(
        error: const ApiException('offline', kind: ApiErrorKind.network),
      );
      final cachedAt = DateTime(2026, 8, 6, 10);
      final cache = _MemoryCache()
        ..entries['client-1'] = CachedDashboard(
          payload: _payload,
          cachedAt: cachedAt,
        );
      final repository = DashboardRepositoryImpl(
        remote: remote,
        cache: cache,
        userId: 'client-1',
        role: 'CLIENT',
      );

      final dashboard = await repository.fetch();

      expect(dashboard.isOffline, isTrue);
      expect(dashboard.fetchedAt, cachedAt);
      expect(dashboard.stats.totalSites, 3);
    });

    test(
      'does not hide server or authentication failures behind cache',
      () async {
        final remote = _FakeRemote(
          error: const ApiException(
            'blocked',
            statusCode: 403,
            kind: ApiErrorKind.authentication,
          ),
        );
        final cache = _MemoryCache()
          ..entries['client-1'] = CachedDashboard(
            payload: _payload,
            cachedAt: DateTime(2026, 8, 6),
          );
        final repository = DashboardRepositoryImpl(
          remote: remote,
          cache: cache,
          userId: 'client-1',
          role: 'CLIENT',
        );

        expect(repository.fetch, throwsA(isA<ApiException>()));
      },
    );

    test(
      'removes contractor-only team alerts for supervisor responses',
      () async {
        final remote = _FakeRemote(payload: _payload);
        final repository = DashboardRepositoryImpl(
          remote: remote,
          cache: _MemoryCache(),
          userId: 'supervisor-1',
          role: 'SUPERVISOR',
        );

        final dashboard = await repository.fetch();

        expect(
          dashboard.alerts.map((alert) => alert.type),
          isNot(contains('TEAM')),
        );
        expect(dashboard.alerts.map((alert) => alert.type), contains('TASK'));
      },
    );
  });
}

const _payload = <String, dynamic>{
  'company': {'id': 'company-1', 'name': 'Buildcraft Projects'},
  'stats': {
    'total_sites': 3,
    'active_sites': 2,
    'completed_sites': 1,
    'labours': 42,
    'today_labours': 31,
    'pending_tasks': 5,
    'completed_tasks': 18,
    'today_reports': 2,
  },
  'sites': [
    {
      'id': 'site-1',
      'name': 'Orchid Residence',
      'location': 'Gurugram',
      'status': 'ACTIVE',
      'progress': 64,
      'budget': 8500000,
    },
  ],
  'alerts': [
    {'type': 'TEAM', 'severity': 'LOW', 'title': 'No Team Members'},
    {'type': 'TASK', 'severity': 'HIGH', 'title': '5 Pending Tasks'},
  ],
};

class _FakeRemote implements DashboardRemoteDataSource {
  const _FakeRemote({this.payload, this.error});

  final Map<String, dynamic>? payload;
  final ApiException? error;

  @override
  Future<Map<String, dynamic>> fetchDashboard() async {
    if (error != null) throw error!;
    return Map<String, dynamic>.from(payload!);
  }
}

class _MemoryCache implements DashboardCache {
  final entries = <String, CachedDashboard>{};

  @override
  Future<void> clear(String userId) async => entries.remove(userId);

  @override
  Future<CachedDashboard?> read(String userId) async => entries[userId];

  @override
  Future<void> write(String userId, Map<String, dynamic> payload) async {
    entries[userId] = CachedDashboard(
      payload: Map<String, dynamic>.from(payload),
      cachedAt: DateTime.now(),
    );
  }
}
