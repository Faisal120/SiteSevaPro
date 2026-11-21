import '../../../core/network/api_service.dart';

abstract interface class SettingsRemoteDataSource {
  Future<Map<String, dynamic>> fetchCurrentUser();
  Future<Map<String, dynamic>> fetchSubscription();
  Future<List<Map<String, dynamic>>> fetchSubscriptionPlans();
  Future<Map<String, dynamic>> fetchCompanyPreferences();
  Future<void> updateCompanyPreferences(Map<String, dynamic> preferences);
  Future<void> requestSubscriptionRenewal();
  Future<void> changePassword({
    required String currentPassword,
    required String newPassword,
  });
}

class HttpSettingsRemoteDataSource implements SettingsRemoteDataSource {
  const HttpSettingsRemoteDataSource();

  @override
  Future<Map<String, dynamic>> fetchCurrentUser() =>
      ApiService.getCurrentUser();

  @override
  Future<Map<String, dynamic>> fetchSubscription() =>
      ApiService.getCurrentSubscription();

  @override
  Future<List<Map<String, dynamic>>> fetchSubscriptionPlans() =>
      ApiService.getSubscriptionPlans();

  @override
  Future<Map<String, dynamic>> fetchCompanyPreferences() =>
      ApiService.getCompanyPreferences();

  @override
  Future<void> updateCompanyPreferences(
    Map<String, dynamic> preferences,
  ) async {
    await ApiService.updateCompanyPreferences(preferences);
  }

  @override
  Future<void> requestSubscriptionRenewal() async {
    await ApiService.requestSubscriptionRenewal();
  }

  @override
  Future<void> changePassword({
    required String currentPassword,
    required String newPassword,
  }) => ApiService.changePassword(
    currentPassword: currentPassword,
    newPassword: newPassword,
  );
}
