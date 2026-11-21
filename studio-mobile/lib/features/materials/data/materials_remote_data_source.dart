import '../../../core/network/api_service.dart';

abstract interface class MaterialsRemoteDataSource {
  Future<List<Map<String, dynamic>>> fetchSites();
  Future<List<Map<String, dynamic>>> fetchMaterials({String? siteId});
  Future<Map<String, dynamic>> createMaterial(Map<String, dynamic> payload);
  Future<List<Map<String, dynamic>>> fetchMovements({String? siteId});
  Future<Map<String, dynamic>> createMovement(Map<String, dynamic> payload);
  Future<List<Map<String, dynamic>>> fetchVendors();
  Future<Map<String, dynamic>> createVendor(Map<String, dynamic> payload);
  Future<void> deleteVendor(String vendorId);
}

class HttpMaterialsRemoteDataSource implements MaterialsRemoteDataSource {
  const HttpMaterialsRemoteDataSource();

  @override
  Future<Map<String, dynamic>> createMaterial(Map<String, dynamic> payload) =>
      ApiService.createMaterial(payload);

  @override
  Future<Map<String, dynamic>> createMovement(Map<String, dynamic> payload) =>
      ApiService.createMaterialTransaction(payload);

  @override
  Future<Map<String, dynamic>> createVendor(Map<String, dynamic> payload) =>
      ApiService.createVendor(payload);

  @override
  Future<void> deleteVendor(String vendorId) =>
      ApiService.deleteVendor(vendorId);

  @override
  Future<List<Map<String, dynamic>>> fetchMaterials({String? siteId}) =>
      ApiService.getMaterials(siteId: siteId);

  @override
  Future<List<Map<String, dynamic>>> fetchMovements({String? siteId}) =>
      ApiService.getMaterialTransactions(siteId: siteId);

  @override
  Future<List<Map<String, dynamic>>> fetchSites() => ApiService.getSites();

  @override
  Future<List<Map<String, dynamic>>> fetchVendors() => ApiService.getVendors();
}
