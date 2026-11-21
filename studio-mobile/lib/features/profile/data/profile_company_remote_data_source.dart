import 'dart:typed_data';

import '../../../core/network/api_service.dart';

abstract interface class ProfileCompanyRemoteDataSource {
  Future<Map<String, dynamic>> fetchCurrentUser();
  Future<Map<String, dynamic>> fetchBranding();
  Future<Map<String, dynamic>> updateBranding(Map<String, dynamic> body);
  Future<Map<String, dynamic>> uploadLogo({
    required Uint8List bytes,
    required String filename,
  });
}

class HttpProfileCompanyRemoteDataSource
    implements ProfileCompanyRemoteDataSource {
  const HttpProfileCompanyRemoteDataSource();

  @override
  Future<Map<String, dynamic>> fetchCurrentUser() => ApiService.getCurrentUser();

  @override
  Future<Map<String, dynamic>> fetchBranding() => ApiService.getBranding();

  @override
  Future<Map<String, dynamic>> updateBranding(Map<String, dynamic> body) =>
      ApiService.updateBranding(body);

  @override
  Future<Map<String, dynamic>> uploadLogo({
    required Uint8List bytes,
    required String filename,
  }) => ApiService.uploadBrandingLogo(bytes: bytes, filename: filename);
}
