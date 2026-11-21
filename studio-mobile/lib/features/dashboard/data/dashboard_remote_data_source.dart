import '../../../core/network/api_service.dart';

abstract interface class DashboardRemoteDataSource {
  Future<Map<String, dynamic>> fetchDashboard();
}

class HttpDashboardRemoteDataSource implements DashboardRemoteDataSource {
  const HttpDashboardRemoteDataSource();

  @override
  Future<Map<String, dynamic>> fetchDashboard() => ApiService.getDashboard();
}
