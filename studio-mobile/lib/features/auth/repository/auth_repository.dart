import '../models/auth_user.dart';
import '../models/contractor_application.dart';

abstract interface class AuthRepository {
  Future<AuthUser> signIn({
    required String email,
    required String password,
    required bool rememberSession,
  });

  Future<AuthUser?> restoreSession();
  Future<void> signOut();
  Future<ContractorApplication> submitApplication(
    ContractorApplicationInput application,
  );
}
