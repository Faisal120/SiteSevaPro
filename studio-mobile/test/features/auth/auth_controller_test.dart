import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:siteseva/features/auth/models/auth_user.dart';
import 'package:siteseva/features/auth/models/contractor_application.dart';
import 'package:siteseva/features/auth/providers/auth_provider.dart';
import 'package:siteseva/features/auth/repository/auth_repository.dart';

void main() {
  group('AuthController', () {
    test('restores a backend session', () async {
      final repository = _FakeAuthRepository()..restoredUser = _contractor;
      final controller = AuthController(repository);

      await controller.restore();

      expect(controller.state.valueOrNull?.id, 'user-1');
      expect(controller.state.valueOrNull?.isContractor, isTrue);
    });

    test('passes remember-session preference to repository', () async {
      final repository = _FakeAuthRepository();
      final controller = AuthController(repository);

      await controller.login(
        email: 'owner@siteseva.test',
        password: 'secure-password',
        rememberSession: false,
      );

      expect(repository.lastRememberSession, isFalse);
      expect(controller.state.valueOrNull?.email, 'owner@siteseva.test');
    });

    test('clears authenticated state on logout', () async {
      final repository = _FakeAuthRepository();
      final controller = AuthController(repository);
      await controller.login(
        email: 'owner@siteseva.test',
        password: 'secure-password',
      );

      await controller.logout();

      expect(repository.didSignOut, isTrue);
      expect(controller.state.valueOrNull, isNull);
      expect(controller.state.hasError, isFalse);
    });
  });

  group('role permissions', () {
    test('uses the role returned by the backend', () {
      final supervisor = AuthUser.fromJson({
        ..._contractor.toJson(),
        'id': 'supervisor-1',
        'role': 'SUPERVISOR',
      });
      final client = AuthUser.fromJson({
        ..._contractor.toJson(),
        'id': 'client-1',
        'role': 'CLIENT',
      });

      expect(supervisor.canManageFieldOperations, isTrue);
      expect(supervisor.canManageFinance, isFalse);
      expect(client.canManageFieldOperations, isFalse);
      expect(client.roleLabel, 'Client');
    });
  });
}

const _contractor = AuthUser(
  id: 'user-1',
  email: 'owner@siteseva.test',
  fullName: 'Workspace Owner',
  role: 'CONTRACTOR',
  siteIds: [],
  blocked: false,
);

class _FakeAuthRepository implements AuthRepository {
  AuthUser? restoredUser;
  bool? lastRememberSession;
  bool didSignOut = false;

  @override
  Future<AuthUser?> restoreSession() async => restoredUser;

  @override
  Future<AuthUser> signIn({
    required String email,
    required String password,
    required bool rememberSession,
  }) async {
    lastRememberSession = rememberSession;
    return AuthUser(
      id: _contractor.id,
      email: email,
      fullName: _contractor.fullName,
      role: _contractor.role,
      siteIds: _contractor.siteIds,
      blocked: _contractor.blocked,
    );
  }

  @override
  Future<void> signOut() async => didSignOut = true;

  @override
  Future<ContractorApplication> submitApplication(
    ContractorApplicationInput application,
  ) {
    throw UnimplementedError();
  }
}
