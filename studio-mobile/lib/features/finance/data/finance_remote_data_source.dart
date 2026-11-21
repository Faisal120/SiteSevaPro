import '../../../core/media/app_image_picker.dart';
import '../../../core/network/api_service.dart';

abstract interface class FinanceRemoteDataSource {
  Future<List<Map<String, dynamic>>> fetchSites();
  Future<List<Map<String, dynamic>>> fetchPayments({String? siteId});
  Future<Map<String, dynamic>> createPayment(Map<String, dynamic> payload);
  Future<List<Map<String, dynamic>>> fetchExpenses({String? siteId});
  Future<Map<String, dynamic>> createExpense(Map<String, dynamic> payload);
  Future<Map<String, dynamic>> fetchExpenseReport({String? siteId});
  Future<Map<String, dynamic>> uploadAttachment(AppImageAsset asset);
}

class HttpFinanceRemoteDataSource implements FinanceRemoteDataSource {
  const HttpFinanceRemoteDataSource();

  @override
  Future<List<Map<String, dynamic>>> fetchSites() => ApiService.getSites();

  @override
  Future<List<Map<String, dynamic>>> fetchPayments({String? siteId}) =>
      ApiService.getPayments(siteId: siteId);

  @override
  Future<Map<String, dynamic>> createPayment(Map<String, dynamic> payload) =>
      ApiService.createPayment(payload);

  @override
  Future<List<Map<String, dynamic>>> fetchExpenses({String? siteId}) =>
      ApiService.getExpenses(siteId: siteId);

  @override
  Future<Map<String, dynamic>> createExpense(Map<String, dynamic> payload) =>
      ApiService.createExpense(payload);

  @override
  Future<Map<String, dynamic>> fetchExpenseReport({String? siteId}) =>
      ApiService.getExpenseReport(siteId: siteId);

  @override
  Future<Map<String, dynamic>> uploadAttachment(AppImageAsset asset) async {
    final signature = await ApiService.getCloudinarySignature(
      folder: 'siteseva/finance',
    );
    return ApiService.uploadCloudinaryAsset(
      bytes: asset.bytes,
      filename: asset.filename,
      signature: signature,
    );
  }
}
