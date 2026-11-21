import '../../../core/network/api_service.dart';
import '../../auth/models/auth_user.dart';
import '../models/settings_models.dart';
import '../repository/settings_repository.dart';
import 'settings_remote_data_source.dart';

class SettingsRepositoryImpl implements SettingsRepository {
  const SettingsRepositoryImpl({
    required SettingsRemoteDataSource remote,
    required AuthUser? fallbackUser,
  }) : _remote = remote,
       _fallbackUser = fallbackUser;

  final SettingsRemoteDataSource _remote;
  final AuthUser? _fallbackUser;

  @override
  Future<SettingsWorkspaceData> fetchWorkspace() async {
    try {
      final user = await _remote.fetchCurrentUser();
      Map<String, dynamic> subscription = const {};
      List<Map<String, dynamic>> plans = const [];
      Map<String, dynamic> preferences = const {};
      var subscriptionAvailable = true;
      String? subscriptionMessage;
      try {
        final result = await Future.wait<Object>([
          _remote.fetchSubscription(),
          _remote.fetchSubscriptionPlans(),
          _remote.fetchCompanyPreferences(),
        ]);
        subscription = result[0] as Map<String, dynamic>;
        plans = result[1] as List<Map<String, dynamic>>;
        preferences = result[2] as Map<String, dynamic>;
      } on ApiException catch (error) {
        subscriptionAvailable = false;
        subscriptionMessage = error.statusCode == 404
            ? 'Subscription details are not enabled by the backend yet.'
            : error.message;
      }
      return SettingsWorkspaceData.fromResponses(
        userPayload: user,
        subscriptionPayload: subscription,
        plansPayload: plans,
        preferencesPayload: preferences,
        subscriptionAvailable: subscriptionAvailable,
        subscriptionMessage: subscriptionMessage,
      );
    } on ApiException catch (error) {
      final fallback = _fallbackUser;
      if (fallback != null && error.isConnectivityFailure) {
        return SettingsWorkspaceData.offline(fallback);
      }
      rethrow;
    }
  }

  @override
  Future<void> requestSubscriptionRenewal() =>
      _remote.requestSubscriptionRenewal();

  @override
  Future<void> updateCompanyPreferences(WorkspacePreferences preferences) =>
      _remote.updateCompanyPreferences(preferences.toJson());

  @override
  Future<void> changePassword({
    required String currentPassword,
    required String newPassword,
  }) => _remote.changePassword(
    currentPassword: currentPassword,
    newPassword: newPassword,
  );
}
