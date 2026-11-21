import 'dart:typed_data';

import '../../../core/network/api_service.dart';

abstract interface class DesignStudioRemoteDataSource {
  Future<List<Map<String, dynamic>>> fetchSites();
  Future<List<Map<String, dynamic>>> fetchDesigns();
  Future<Map<String, dynamic>> fetchDesign(String designId);
  Future<Map<String, dynamic>> generate(Map<String, dynamic> payload);
  Future<Map<String, dynamic>> generateTechnical(
    String designId,
    String drawingType,
  );
  Future<Map<String, dynamic>> generateThreeD(String designId, int floorNumber);
  Future<void> deleteDesign(String designId);
  Future<Map<String, dynamic>> fetchWallet();
  Future<List<Map<String, dynamic>>> fetchTransactions();
  Future<Map<String, dynamic>> fetchPurchaseConfig();
  Future<List<Map<String, dynamic>>> fetchPurchases();
  Future<Map<String, dynamic>> requestPurchase(Map<String, dynamic> payload);
  Future<Uint8List> downloadPdf(
    String designId,
    String drawingType,
    int floorNumber,
  );
}

class HttpDesignStudioRemoteDataSource implements DesignStudioRemoteDataSource {
  const HttpDesignStudioRemoteDataSource();

  @override
  Future<List<Map<String, dynamic>>> fetchSites() => ApiService.getSites();

  @override
  Future<List<Map<String, dynamic>>> fetchDesigns() => ApiService.getDesigns();

  @override
  Future<Map<String, dynamic>> fetchDesign(String designId) =>
      ApiService.getDesign(designId);

  @override
  Future<Map<String, dynamic>> generate(Map<String, dynamic> payload) =>
      ApiService.generateMap(payload);

  @override
  Future<Map<String, dynamic>> generateTechnical(
    String designId,
    String drawingType,
  ) => ApiService.generateTechnicalDrawing(designId, drawingType);

  @override
  Future<Map<String, dynamic>> generateThreeD(
    String designId,
    int floorNumber,
  ) => ApiService.generate3dConcept(designId, floorNumber);

  @override
  Future<void> deleteDesign(String designId) =>
      ApiService.deleteDesign(designId);

  @override
  Future<Map<String, dynamic>> fetchWallet() => ApiService.getDesignWallet();

  @override
  Future<List<Map<String, dynamic>>> fetchTransactions() =>
      ApiService.getDesignWalletTransactions();

  @override
  Future<Map<String, dynamic>> fetchPurchaseConfig() =>
      ApiService.getDesignWalletPurchaseConfig();

  @override
  Future<List<Map<String, dynamic>>> fetchPurchases() =>
      ApiService.getMyDesignWalletPurchases();

  @override
  Future<Map<String, dynamic>> requestPurchase(Map<String, dynamic> payload) =>
      ApiService.requestDesignWalletPurchase(payload);

  @override
  Future<Uint8List> downloadPdf(
    String designId,
    String drawingType,
    int floorNumber,
  ) => ApiService.downloadDesignPdf(
    designId,
    drawingType,
    floorNumber: floorNumber,
  );
}
