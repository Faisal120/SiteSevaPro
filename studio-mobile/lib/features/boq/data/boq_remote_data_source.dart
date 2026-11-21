import '../../../core/network/api_service.dart';

abstract interface class BoqRemoteDataSource {
  Future<List<Map<String, dynamic>>> fetchBoqs();
  Future<Map<String, dynamic>> fetchBoq(String boqId);
  Future<Map<String, dynamic>> generate(Map<String, dynamic> payload);
  Future<List<Map<String, dynamic>>> fetchSites();
  Future<List<Map<String, dynamic>>> fetchEstimates();
  Future<List<Map<String, dynamic>>> fetchVendors();
}

class HttpBoqRemoteDataSource implements BoqRemoteDataSource {
  const HttpBoqRemoteDataSource();

  @override
  Future<List<Map<String, dynamic>>> fetchBoqs() => ApiService.getBoqs();

  @override
  Future<Map<String, dynamic>> fetchBoq(String boqId) =>
      ApiService.getBoq(boqId);

  @override
  Future<Map<String, dynamic>> generate(Map<String, dynamic> payload) =>
      ApiService.generateBoq(payload);

  @override
  Future<List<Map<String, dynamic>>> fetchSites() => ApiService.getSites();

  @override
  Future<List<Map<String, dynamic>>> fetchEstimates() =>
      ApiService.getEstimates();

  @override
  Future<List<Map<String, dynamic>>> fetchVendors() => ApiService.getVendors();
}
