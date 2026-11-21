import 'package:flutter_test/flutter_test.dart';
import 'package:siteseva/core/network/api_service.dart';
import 'package:siteseva/core/storage/secure_session_storage.dart';
import 'package:siteseva/features/auth/data/auth_remote_data_source.dart';
import 'package:siteseva/features/auth/data/auth_repository_impl.dart';
import 'package:siteseva/features/auth/models/auth_user.dart';
import 'package:siteseva/features/auth/models/contractor_application.dart';

void main() {
  group('AuthRepositoryImpl', () {
    test(
      'persists valid login response when remember session is enabled',
      () async {
        final remote = _FakeRemoteDataSource();
        final storage = _MemorySessionStorage();
        final repository = AuthRepositoryImpl(remote: remote, storage: storage);

        final user = await repository.signIn(
          email: 'owner@siteseva.test',
          password: 'password',
          rememberSession: true,
        );

        expect(user.role, 'CONTRACTOR');
        expect(storage.session?.token, 'jwt-token');
        expect(storage.session?.user.id, 'user-1');
      },
    );

    test('does not persist login when remember session is disabled', () async {
      final remote = _FakeRemoteDataSource();
      final storage = _MemorySessionStorage(
        session: const StoredSession(token: 'old-token', user: _contractor),
      );
      final repository = AuthRepositoryImpl(remote: remote, storage: storage);

      await repository.signIn(
        email: 'owner@siteseva.test',
        password: 'password',
        rememberSession: false,
      );

      expect(storage.session, isNull);
      expect(remote.token, 'jwt-token');
    });

    test('validates a stored token with auth me', () async {
      final remote = _FakeRemoteDataSource();
      final storage = _MemorySessionStorage(
        session: const StoredSession(token: 'stored-token', user: _contractor),
      );
      final repository = AuthRepositoryImpl(remote: remote, storage: storage);

      final user = await repository.restoreSession();

      expect(remote.token, 'stored-token');
      expect(remote.currentUserCalls, 1);
      expect(user?.id, 'user-1');
    });

    test(
      'uses encrypted cached identity when the network is unavailable',
      () async {
        final remote = _FakeRemoteDataSource(
          currentUserError: const ApiException(
            'offline',
            kind: ApiErrorKind.network,
          ),
        );
        final storage = _MemorySessionStorage(
          session: const StoredSession(
            token: 'stored-token',
            user: _contractor,
          ),
        );
        final repository = AuthRepositoryImpl(remote: remote, storage: storage);

        final user = await repository.restoreSession();

        expect(user?.id, _contractor.id);
        expect(storage.session, isNotNull);
      },
    );

    test('clears an invalid stored session', () async {
      final remote = _FakeRemoteDataSource(
        currentUserError: const ApiException(
          'Invalid token',
          statusCode: 401,
          kind: ApiErrorKind.authentication,
        ),
      );
      final storage = _MemorySessionStorage(
        session: const StoredSession(token: 'expired-token', user: _contractor),
      );
      final repository = AuthRepositoryImpl(remote: remote, storage: storage);

      final user = await repository.restoreSession();

      expect(user, isNull);
      expect(storage.session, isNull);
      expect(remote.token, isNull);
    });

    test(
      'submits contractor application to the existing API contract',
      () async {
        final remote = _FakeRemoteDataSource();
        final repository = AuthRepositoryImpl(
          remote: remote,
          storage: _MemorySessionStorage(),
        );
        const input = ContractorApplicationInput(
          companyName: 'Buildcraft Projects',
          ownerName: 'Aarav Mehta',
          mobile: '9876543210',
          email: 'aarav@buildcraft.test',
          officeAddress: 'Sector 1',
          city: 'Gurugram',
          state: 'Haryana',
        );

        final result = await repository.submitApplication(input);

        expect(remote.submittedApplication, same(input));
        expect(result.id, 'application-1');
        expect(result.status, 'PENDING');
      },
    );
  });
}

const _contractor = AuthUser(
  id: 'user-1',
  email: 'owner@siteseva.test',
  fullName: 'Workspace Owner',
  role: 'CONTRACTOR',
  companyId: 'company-1',
  companyName: 'Buildcraft Projects',
  plan: 'PREMIUM',
  siteIds: ['site-1'],
  blocked: false,
);

class _MemorySessionStorage implements SessionStorage {
  _MemorySessionStorage({this.session});

  StoredSession? session;

  @override
  Future<void> clear() async => session = null;

  @override
  Future<StoredSession?> read() async => session;

  @override
  Future<void> write({required String token, required AuthUser user}) async {
    session = StoredSession(token: token, user: user);
  }
}

class _FakeRemoteDataSource extends AuthRemoteDataSource {
  _FakeRemoteDataSource({this.currentUserError});

  final ApiException? currentUserError;
  String? token;
  int currentUserCalls = 0;
  ContractorApplicationInput? submittedApplication;

  @override
  Future<Map<String, dynamic>> signIn({
    required String email,
    required String password,
  }) async => {'token': 'jwt-token', 'user': _contractor.toJson()};

  @override
  Future<Map<String, dynamic>> currentUser() async {
    currentUserCalls += 1;
    if (currentUserError != null) throw currentUserError!;
    return _contractor.toJson();
  }

  @override
  Future<Map<String, dynamic>> submitApplication(
    ContractorApplicationInput application,
  ) async {
    submittedApplication = application;
    return {
      'id': 'application-1',
      'company_name': application.companyName,
      'owner_name': application.ownerName,
      'email': application.email,
      'status': 'PENDING',
      'created_at': '2026-08-06T10:00:00Z',
    };
  }

  @override
  void setToken(String? token) => this.token = token;
}
