import '../models/settings_models.dart';

abstract interface class SettingsRepository {
  Future<SettingsWorkspaceData> fetchWorkspace();
  Future<void> requestSubscriptionRenewal();
  Future<void> updateCompanyPreferences(WorkspacePreferences preferences);
  Future<void> changePassword({
    required String currentPassword,
    required String newPassword,
  });
}
