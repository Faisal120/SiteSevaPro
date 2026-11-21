import 'package:flutter_test/flutter_test.dart';
import 'package:siteseva/core/network/api_service.dart';
import 'package:siteseva/features/crm/data/crm_cache.dart';
import 'package:siteseva/features/crm/data/crm_remote_data_source.dart';
import 'package:siteseva/features/crm/data/crm_repository_impl.dart';
import 'package:siteseva/features/crm/models/crm_models.dart';

void main() {
  group('CrmRepositoryImpl', () {
    test('loads and caches the live overview', () async {
      final remote = _FakeCrmRemote(payload: _overviewPayload);
      final cache = _MemoryCrmCache();
      final repository = _repository(remote: remote, cache: cache);

      final data = await repository.fetchWorkspace();

      expect(data.leads.single.id, 'lead-1');
      expect(data.isOffline, isFalse);
      expect(cache.values['user-1'], isNotNull);
    });

    test('turns a missing backend module into an explicit unavailable state', () async {
      final repository = _repository(
        remote: _FakeCrmRemote(
          error: const ApiException('not found', statusCode: 404),
        ),
        cache: _MemoryCrmCache(),
      );

      final data = await repository.fetchWorkspace();

      expect(data.apiAvailable, isFalse);
      expect(data.apiMessage, contains('not enabled'));
    });

    test('uses cached real data only when the request is offline', () async {
      final cache = _MemoryCrmCache()
        ..values['user-1'] = CachedCrmWorkspace(
          payload: _overviewPayload,
          cachedAt: DateTime(2026, 8, 7, 18),
        );
      final repository = _repository(
        remote: _FakeCrmRemote(
          error: const ApiException('offline', kind: ApiErrorKind.network),
        ),
        cache: cache,
      );

      final data = await repository.fetchWorkspace();

      expect(data.isOffline, isTrue);
      expect(data.fetchedAt, DateTime(2026, 8, 7, 18));
      expect(data.leads.single.id, 'lead-1');
    });

    test('does not mask authorization errors with stale cache', () async {
      final cache = _MemoryCrmCache()
        ..values['user-1'] = CachedCrmWorkspace(
          payload: _overviewPayload,
          cachedAt: DateTime(2026, 8, 7),
        );
      final repository = _repository(
        remote: _FakeCrmRemote(
          error: const ApiException(
            'forbidden',
            statusCode: 403,
            kind: ApiErrorKind.authentication,
          ),
        ),
        cache: cache,
      );

      expect(repository.fetchWorkspace(), throwsA(isA<ApiException>()));
    });

    test('enforces role mutations and forwards live write payloads', () async {
      final remote = _FakeCrmRemote();
      final contractor = _repository(remote: remote, cache: _MemoryCrmCache());
      final supervisor = _repository(
        remote: remote,
        cache: _MemoryCrmCache(),
        role: 'SUPERVISOR',
      );
      const lead = CrmLeadInput(
        name: 'Neha Sharma',
        company: 'Northstar Homes',
        email: '',
        phone: '',
        source: 'referral',
        value: 400000,
      );
      const activity = CrmActivityInput(
        kind: CrmActivityKind.followUp,
        title: 'Confirm site visit',
        description: '',
        contactId: 'client-1',
        scheduledAt: null,
      );

      await contractor.createLead(lead);
      await supervisor.createActivity(activity);

      expect(remote.lastLead, lead.toJson());
      expect(remote.lastActivity, activity.toJson());
      expect(supervisor.createLead(lead), throwsA(isA<ApiException>()));
    });
  });
}

CrmRepositoryImpl _repository({
  required CrmRemoteDataSource remote,
  required CrmCache cache,
  String role = 'CONTRACTOR',
}) => CrmRepositoryImpl(
  remote: remote,
  cache: cache,
  userId: 'user-1',
  role: role,
);

class _FakeCrmRemote implements CrmRemoteDataSource {
  _FakeCrmRemote({this.payload = _overviewPayload, this.error});

  final Map<String, dynamic> payload;
  final ApiException? error;
  Map<String, dynamic>? lastLead;
  Map<String, dynamic>? lastActivity;

  void _throwIfNeeded() {
    if (error != null) throw error!;
  }

  @override
  Future<Map<String, dynamic>> fetchOverview() async {
    _throwIfNeeded();
    return Map<String, dynamic>.from(payload);
  }

  @override
  Future<void> createLead(CrmLeadInput input) async {
    _throwIfNeeded();
    lastLead = input.toJson();
  }

  @override
  Future<void> createContact(CrmContactInput input) async {
    _throwIfNeeded();
  }

  @override
  Future<void> createActivity(CrmActivityInput input) async {
    _throwIfNeeded();
    lastActivity = input.toJson();
  }

  @override
  Future<void> createQuotation(CrmQuotationInput input) async {
    _throwIfNeeded();
  }

  @override
  Future<void> completeActivity(String id) async {
    _throwIfNeeded();
  }
}

class _MemoryCrmCache implements CrmCache {
  final values = <String, CachedCrmWorkspace>{};

  @override
  Future<CachedCrmWorkspace?> read(String userId) async => values[userId];

  @override
  Future<void> write(String userId, Map<String, dynamic> payload) async {
    values[userId] = CachedCrmWorkspace(
      payload: payload,
      cachedAt: DateTime(2026, 8, 8),
    );
  }
}

const _overviewPayload = <String, dynamic>{
  'metrics': {'leads': 1, 'active_clients': 1},
  'leads': [
    {
      'id': 'lead-1',
      'name': 'Neha Sharma',
      'company': 'Northstar Homes',
      'created_at': '2026-08-01T09:00:00Z',
    },
  ],
};
