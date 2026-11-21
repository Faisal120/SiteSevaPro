import '../../../core/network/api_service.dart';
import '../models/report_models.dart';

abstract interface class ReportsRemoteDataSource {
  Future<List<Map<String, dynamic>>> fetchSites();
  Future<List<Map<String, dynamic>>> fetchReports({String? siteId});
  Future<Map<String, dynamic>> createReport(Map<String, dynamic> payload);
  Future<Map<String, dynamic>> uploadPhoto(ReportPhotoUpload upload);
}

class HttpReportsRemoteDataSource implements ReportsRemoteDataSource {
  const HttpReportsRemoteDataSource();

  @override
  Future<List<Map<String, dynamic>>> fetchSites() => ApiService.getSites();

  @override
  Future<List<Map<String, dynamic>>> fetchReports({String? siteId}) =>
      ApiService.getReports(siteId: siteId);

  @override
  Future<Map<String, dynamic>> createReport(Map<String, dynamic> payload) =>
      ApiService.createReport(payload);

  @override
  Future<Map<String, dynamic>> uploadPhoto(ReportPhotoUpload upload) async {
    final signature = await ApiService.getCloudinarySignature(
      folder: 'siteseva/reports',
    );
    return ApiService.uploadCloudinaryAsset(
      bytes: upload.bytes,
      filename: upload.filename,
      signature: signature,
    );
  }
}
