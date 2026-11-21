import '../../../core/network/api_service.dart';
import '../models/dashboard_data.dart';
import '../repository/dashboard_repository.dart';
import 'dashboard_cache.dart';
import 'dashboard_remote_data_source.dart';

class DashboardRepositoryImpl implements DashboardRepository {
  const DashboardRepositoryImpl({
    required DashboardRemoteDataSource remote,
    required DashboardCache cache,
    required String userId,
    required String role,
  }) : _remote = remote,
       _cache = cache,
       _userId = userId,
       _role = role;

  final DashboardRemoteDataSource _remote;
  final DashboardCache _cache;
  final String _userId;
  final String _role;

  @override
  Future<DashboardData> fetch() async {
    try {
      final payload = await _remote.fetchDashboard();
      final fetchedAt = DateTime.now();
      await _cache.write(_userId, payload);
      return _normalize(DashboardData.fromJson(payload, fetchedAt: fetchedAt));
    } on ApiException catch (error) {
      if (!error.isConnectivityFailure) rethrow;
      final cached = await _cache.read(_userId);
      if (cached == null) rethrow;
      return _normalize(
        DashboardData.fromJson(
          cached.payload,
          fetchedAt: cached.cachedAt,
          isOffline: true,
        ),
      );
    }
  }

  DashboardData _normalize(DashboardData data) {
    if (_role.toUpperCase() == 'CONTRACTOR') return data;
    // The current supervisor/client services call the contractor alert builder,
    // which emits TEAM alerts for intentionally hidden team collections.
    return data.copyWith(
      alerts: data.alerts
          .where((alert) => alert.type.toUpperCase() != 'TEAM')
          .toList(growable: false),
    );
  }
}
