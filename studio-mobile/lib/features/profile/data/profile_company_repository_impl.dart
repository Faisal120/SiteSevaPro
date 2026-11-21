import 'dart:typed_data';

import '../../../core/network/api_service.dart';
import '../../auth/models/auth_user.dart';
import '../models/profile_models.dart';
import '../repository/profile_company_repository.dart';
import 'profile_company_cache.dart';
import 'profile_company_remote_data_source.dart';

class ProfileCompanyRepositoryImpl implements ProfileCompanyRepository {
  const ProfileCompanyRepositoryImpl({
    required ProfileCompanyRemoteDataSource remote,
    required ProfileCompanyCache cache,
    required String userId,
    required AuthUser? fallbackUser,
  }) : _remote = remote,
       _cache = cache,
       _userId = userId,
       _fallbackUser = fallbackUser;

  final ProfileCompanyRemoteDataSource _remote;
  final ProfileCompanyCache _cache;
  final String _userId;
  final AuthUser? _fallbackUser;

  @override
  Future<ProfileCompanyData> fetchWorkspace() async {
    try {
      final userPayload = await _remote.fetchCurrentUser();
      Map<String, dynamic> brandingPayload = const {};
      bool brandingAvailable = true;
      String? brandingMessage;
      try {
        brandingPayload = await _remote.fetchBranding();
      } on ApiException catch (error) {
        brandingAvailable = false;
        brandingMessage = _brandingMessage(error);
      }
      final data = ProfileCompanyData.fromResponses(
        userPayload: userPayload,
        brandingPayload: brandingPayload,
        brandingApiAvailable: brandingAvailable,
        brandingApiMessage: brandingMessage,
      );
      await _cache.write(_userId, data.toJson());
      return data;
    } on ApiException catch (error) {
      final cached = await _cache.read(_userId);
      if (cached != null && error.isConnectivityFailure) {
        return ProfileCompanyData.fromJson(
          cached.payload,
          fetchedAt: cached.cachedAt,
          isOffline: true,
          apiMessage: 'Showing the last synced profile from ${_relative(cached.cachedAt)}.',
        );
      }
      final fallbackUser = _fallbackUser;
      if (fallbackUser != null && error.isConnectivityFailure) {
        return ProfileCompanyData.unavailable(
          user: fallbackUser,
          message: 'Profile is available from this device, but live profile data could not be reached.',
        );
      }
      rethrow;
    }
  }

  @override
  Future<ProfileCompanyData> saveBranding(BrandingUpdate input) async {
    final response = await _remote.updateBranding(input.toJson());
    final userPayload = await _remote.fetchCurrentUser();
    final data = ProfileCompanyData.fromResponses(
      userPayload: userPayload,
      brandingPayload: response,
    );
    await _cache.write(_userId, data.toJson());
    return data;
  }

  @override
  Future<ProfileCompanyData> uploadLogo({
    required Uint8List bytes,
    required String filename,
  }) async {
    final response = await _remote.uploadLogo(bytes: bytes, filename: filename);
    final userPayload = await _remote.fetchCurrentUser();
    final data = ProfileCompanyData.fromResponses(
      userPayload: userPayload,
      brandingPayload: response,
    );
    await _cache.write(_userId, data.toJson());
    return data;
  }
}

String _brandingMessage(ApiException error) {
  if (error.statusCode == 404) {
    return 'Branding API is not enabled for this workspace.';
  }
  if (error.isConnectivityFailure) {
    return 'Branding could not be synced. Retry when the connection is restored.';
  }
  return error.message;
}

String _relative(DateTime time) {
  final age = DateTime.now().difference(time);
  if (age.inMinutes < 2) return 'just now';
  if (age.inHours < 1) return '${age.inMinutes} minutes ago';
  if (age.inDays < 1) return '${age.inHours} hours ago';
  return '${age.inDays} days ago';
}
