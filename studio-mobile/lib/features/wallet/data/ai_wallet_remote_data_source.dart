import '../../../core/network/api_service.dart';

abstract interface class AiWalletRemoteDataSource {
  Future<Map<String, dynamic>> fetchWallet();
  Future<List<Map<String, dynamic>>> fetchTransactions();
  Future<Map<String, dynamic>> fetchPurchaseConfig();
  Future<List<Map<String, dynamic>>> fetchPurchases();
  Future<Map<String, dynamic>> requestPurchase(Map<String, dynamic> payload);
}

class HttpAiWalletRemoteDataSource implements AiWalletRemoteDataSource {
  const HttpAiWalletRemoteDataSource();

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
}
