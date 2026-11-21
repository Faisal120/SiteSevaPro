import 'dart:typed_data';

import 'package:flutter_test/flutter_test.dart';
import 'package:siteseva/core/network/api_service.dart';
import 'package:siteseva/features/auth/models/auth_user.dart';
import 'package:siteseva/features/profile/data/profile_company_cache.dart';
import 'package:siteseva/features/profile/data/profile_company_remote_data_source.dart';
import 'package:siteseva/features/profile/data/profile_company_repository_impl.dart';
import 'package:siteseva/features/profile/models/profile_models.dart';

const _user = AuthUser(
  id: 'user-1',
  email: 'contractor@example.com',
  fullName: 'Aarav Mehta',
  role: 'CONTRACTOR',
  companyId: 'company-1',
  companyName: 'Buildcraft Projects',
  siteIds: ['site-1'],
  blocked: false,
);

void main() {
  test('fetches live profile, branding and caches the workspace', () async {
    final cache = _MemoryProfileCache();
    final repository = _repository(cache: cache);

    final data = await repository.fetchWorkspace();

    expect(data.user.id, 'user-1');
    expect(data.branding.companyName, 'Buildcraft Projects');
    expect(cache.values['user-1'], isNotNull);
  });

  test('uses only real cached data when the API is offline', () async {
    final cache = _MemoryProfileCache()
      ..values['user-1'] = CachedProfileCompany(
        payload: _payload,
        cachedAt: DateTime(2026, 8, 7, 18),
      );
    final data = await _repository(
      cache: cache,
      remote: _FakeProfileRemote(error: const ApiException('offline', kind: ApiErrorKind.network)),
    ).fetchWorkspace();

    expect(data.isOffline, isTrue);
    expect(data.company.name, 'Buildcraft Projects');
    expect(data.branding.logoUrl, 'https://cdn.example/logo.png');
    expect(data.fetchedAt, DateTime(2026, 8, 7, 18));
  });

  test('keeps profile available when branding endpoint is unavailable', () async {
    final data = await _repository(
      cache: _MemoryProfileCache(),
      remote: _FakeProfileRemote(
        brandingError: const ApiException('missing', statusCode: 404),
      ),
    ).fetchWorkspace();

    expect(data.apiAvailable, isTrue);
    expect(data.brandingApiAvailable, isFalse);
    expect(data.company.name, 'Buildcraft Projects');
    expect(data.brandingApiMessage, contains('not enabled'));
  });

  test('forwards branding saves and logo uploads through the remote source', () async {
    final remote = _FakeProfileRemote();
    final repository = _repository(cache: _MemoryProfileCache(), remote: remote);

    await repository.saveBranding(
      const BrandingUpdate(companyName: 'Updated Projects'),
    );
    await repository.uploadLogo(
      bytes: Uint8List.fromList([1, 2, 3]),
      filename: 'logo.png',
    );

    expect(remote.saveCount, 1);
    expect(remote.uploadCount, 1);
  });
}

ProfileCompanyRepositoryImpl _repository({
  required ProfileCompanyCache cache,
  ProfileCompanyRemoteDataSource? remote,
}) => ProfileCompanyRepositoryImpl(
  remote: remote ?? _FakeProfileRemote(),
  cache: cache,
  userId: 'user-1',
  fallbackUser: _user,
);

final _payload = <String, dynamic>{
  'user': _user.toJson(),
  'company': {
    'id': 'company-1',
    'name': 'Buildcraft Projects',
    'logo_url': 'https://cdn.example/logo.png',
  },
  'branding': {
    'company_name': 'Buildcraft Projects',
    'logo_url': 'https://cdn.example/logo.png',
  },
  'fetched_at': '2026-08-07T18:00:00.000Z',
};

class _FakeProfileRemote implements ProfileCompanyRemoteDataSource {
  _FakeProfileRemote({this.error, this.brandingError});

  final ApiException? error;
  final ApiException? brandingError;
  int saveCount = 0;
  int uploadCount = 0;

  void _throwIfNeeded(ApiException? issue) {
    if (issue != null) throw issue;
  }

  @override
  Future<Map<String, dynamic>> fetchCurrentUser() async {
    _throwIfNeeded(error);
    return _user.toJson();
  }

  @override
  Future<Map<String, dynamic>> fetchBranding() async {
    _throwIfNeeded(error ?? brandingError);
    return {
      'company_name': 'Buildcraft Projects',
      'logo_url': 'https://cdn.example/logo.png',
    };
  }

  @override
  Future<Map<String, dynamic>> updateBranding(Map<String, dynamic> body) async {
    _throwIfNeeded(error);
    saveCount++;
    return {
      'company_name': body['company_name'],
      'logo_url': 'https://cdn.example/logo.png',
    };
  }

  @override
  Future<Map<String, dynamic>> uploadLogo({
    required Uint8List bytes,
    required String filename,
  }) async {
    _throwIfNeeded(error);
    uploadCount++;
    return {
      'company_name': 'Buildcraft Projects',
      'logo_url': 'https://cdn.example/logo-updated.png',
    };
  }
}

class _MemoryProfileCache implements ProfileCompanyCache {
  final values = <String, CachedProfileCompany>{};

  @override
  Future<CachedProfileCompany?> read(String userId) async => values[userId];

  @override
  Future<void> write(String userId, Map<String, dynamic> payload) async {
    values[userId] = CachedProfileCompany(
      payload: payload,
      cachedAt: DateTime(2026, 8, 8),
    );
  }
}
