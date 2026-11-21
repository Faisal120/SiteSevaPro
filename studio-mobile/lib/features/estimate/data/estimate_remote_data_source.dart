import '../../../core/network/api_service.dart';

abstract interface class EstimateRemoteDataSource {
  Future<List<Map<String, dynamic>>> fetchEstimates();
  Future<Map<String, dynamic>> fetchEstimate(String estimateId);
  Future<Map<String, dynamic>> create(Map<String, dynamic> payload);
  Future<List<Map<String, dynamic>>> fetchSites();
  Future<Map<String, dynamic>> fetchBranding();
}

class HttpEstimateRemoteDataSource implements EstimateRemoteDataSource {
  const HttpEstimateRemoteDataSource();

  @override
  Future<List<Map<String, dynamic>>> fetchEstimates() =>
      ApiService.getEstimates();

  @override
  Future<Map<String, dynamic>> fetchEstimate(String estimateId) =>
      ApiService.getEstimate(estimateId);

  @override
  Future<Map<String, dynamic>> create(Map<String, dynamic> payload) =>
      ApiService.createEstimate(payload);

  @override
  Future<List<Map<String, dynamic>>> fetchSites() => ApiService.getSites();

  @override
  Future<Map<String, dynamic>> fetchBranding() => ApiService.getBranding();
}
