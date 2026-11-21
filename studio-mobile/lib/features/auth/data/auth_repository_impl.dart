import '../../../core/network/api_service.dart';
import '../../../core/storage/secure_session_storage.dart';
import '../models/auth_user.dart';
import '../models/contractor_application.dart';
import '../repository/auth_repository.dart';
import 'auth_remote_data_source.dart';

class AuthRepositoryImpl implements AuthRepository {
  const AuthRepositoryImpl({
    required AuthRemoteDataSource remote,
    required SessionStorage storage,
  }) : _remote = remote,
       _storage = storage;

  final AuthRemoteDataSource _remote;
  final SessionStorage _storage;

  @override
  Future<AuthUser> signIn({
    required String email,
    required String password,
    required bool rememberSession,
  }) async {
    final response = await _remote.signIn(email: email, password: password);
    final token = response['token'] as String?;
    final rawUser = response['user'];
    if (token == null || token.isEmpty || rawUser is! Map) {
      await signOut();
      throw const ApiException(
        'The login response did not contain a valid session.',
        kind: ApiErrorKind.invalidResponse,
      );
    }

    final user = AuthUser.fromJson(Map<String, dynamic>.from(rawUser));
    _validateUser(user);
    _remote.setToken(token);
    if (rememberSession) {
      await _storage.write(token: token, user: user);
    } else {
      await _storage.clear();
    }
    return user;
  }

  @override
  Future<AuthUser?> restoreSession() async {
    final stored = await _storage.read();
    if (stored == null) return null;

    _remote.setToken(stored.token);
    try {
      final user = AuthUser.fromJson(await _remote.currentUser());
      _validateUser(user);
      await _storage.write(token: stored.token, user: user);
      return user;
    } on ApiException catch (error) {
      if (error.isConnectivityFailure) return stored.user;
      await signOut();
      if (error.isAuthenticationFailure) return null;
      rethrow;
    }
  }

  @override
  Future<void> signOut() async {
    _remote.setToken(null);
    await _storage.clear();
  }

  @override
  Future<ContractorApplication> submitApplication(
    ContractorApplicationInput application,
  ) async {
    final response = await _remote.submitApplication(application);
    return ContractorApplication.fromJson(response);
  }

  void _validateUser(AuthUser user) {
    if (user.id.isEmpty || user.email.isEmpty || !user.isSupportedMobileRole) {
      throw const ApiException(
        'This account does not have a valid SiteSeva workspace role.',
        kind: ApiErrorKind.authentication,
      );
    }
    if (user.blocked) {
      throw const ApiException(
        'This account is blocked. Contact your workspace administrator.',
        statusCode: 403,
        kind: ApiErrorKind.authentication,
      );
    }
  }
}
