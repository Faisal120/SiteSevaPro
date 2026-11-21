import 'package:flutter_test/flutter_test.dart';
import 'package:siteseva/core/network/api_service.dart';
import 'package:siteseva/features/notifications/data/notifications_cache.dart';
import 'package:siteseva/features/notifications/data/notifications_remote_data_source.dart';
import 'package:siteseva/features/notifications/data/notifications_repository_impl.dart';
import 'package:siteseva/features/notifications/models/notification_models.dart';

void main() {
  group('NotificationsRepositoryImpl', () {
    test(
      'loads, normalizes, and caches server inbox with unread count',
      () async {
        final remote = _FakeNotificationsRemote();
        final cache = _MemoryNotificationsCache();
        final repository = _repository(remote: remote, cache: cache);

        final data = await repository.fetchInbox();

        expect(data.notifications.length, 2);
        expect(data.serverUnreadCount, 2);
        expect(
          data.notifications.last.message,
          'Payment is pending verification.',
        );
        expect(remote.unreadRequests, 1);
        expect(cache.inboxes['user-1'], isNotNull);
      },
    );

    test('removes notifications targeted to another company user', () async {
      final remote = _FakeNotificationsRemote(includeLeakedUser: true);
      final repository = _repository(
        remote: remote,
        cache: _MemoryNotificationsCache(),
      );

      final data = await repository.fetchInbox();

      expect(data.notifications.map((item) => item.id).toSet(), {
        'notification-material',
        'notification-payment',
      });
    });

    test('uses cache only for connectivity failure', () async {
      final cache = _MemoryNotificationsCache()
        ..inboxes['user-1'] = CachedNotificationsInbox(
          payload: _cachedPayload,
          cachedAt: DateTime(2026, 8, 6, 9),
        );
      final repository = _repository(
        remote: _FakeNotificationsRemote(
          error: const ApiException('offline', kind: ApiErrorKind.network),
        ),
        cache: cache,
      );

      final data = await repository.fetchInbox();

      expect(data.isOffline, isTrue);
      expect(data.notifications.length, 2);
      expect(data.fetchedAt, DateTime(2026, 8, 6, 9));
    });

    test('does not hide authorization failure behind cache', () async {
      final cache = _MemoryNotificationsCache()
        ..inboxes['user-1'] = CachedNotificationsInbox(
          payload: _cachedPayload,
          cachedAt: DateTime(2026, 8, 6),
        );
      final repository = _repository(
        remote: _FakeNotificationsRemote(
          error: const ApiException(
            'forbidden',
            statusCode: 403,
            kind: ApiErrorKind.authentication,
          ),
        ),
        cache: cache,
      );

      expect(repository.fetchInbox(), throwsA(isA<ApiException>()));
    });

    test(
      'validates accessibility before marking an unread item read',
      () async {
        final remote = _FakeNotificationsRemote();
        final repository = _repository(
          remote: remote,
          cache: _MemoryNotificationsCache(),
        );

        await repository.markRead('notification-payment');

        expect(remote.markedRead, ['notification-payment']);
        expect(
          repository.markRead('notification-missing'),
          throwsA(isA<ApiException>()),
        );
      },
    );

    test('skips network mutation for an already-read notification', () async {
      final remote = _FakeNotificationsRemote(paymentRead: true);
      final repository = _repository(
        remote: remote,
        cache: _MemoryNotificationsCache(),
      );

      await repository.markRead('notification-payment');

      expect(remote.markedRead, isEmpty);
    });

    test(
      'blocks broadcast delete and permits current-user targeted delete',
      () async {
        final remote = _FakeNotificationsRemote();
        final repository = _repository(
          remote: remote,
          cache: _MemoryNotificationsCache(),
        );

        expect(
          repository.deleteNotification('notification-material'),
          throwsA(isA<ApiException>()),
        );
        await repository.deleteNotification('notification-payment');
        expect(remote.deleted, ['notification-payment']);
      },
    );

    test('uses exact mark-all endpoint and exposes unread endpoint', () async {
      final remote = _FakeNotificationsRemote();
      final repository = _repository(
        remote: remote,
        cache: _MemoryNotificationsCache(),
      );

      await repository.markAllRead();
      final count = await repository.fetchUnreadCount();

      expect(remote.markAllRequests, 1);
      expect(count, 2);
    });
  });
}

NotificationsRepositoryImpl _repository({
  required NotificationsRemoteDataSource remote,
  required NotificationsCache cache,
}) => NotificationsRepositoryImpl(
  remote: remote,
  cache: cache,
  userId: 'user-1',
  audience: NotificationAudience.contractor,
  clock: () => DateTime(2026, 8, 7, 12),
);

class _FakeNotificationsRemote implements NotificationsRemoteDataSource {
  _FakeNotificationsRemote({
    this.error,
    this.includeLeakedUser = false,
    this.paymentRead = false,
  });

  final ApiException? error;
  final bool includeLeakedUser;
  final bool paymentRead;
  int unreadRequests = 0;
  int markAllRequests = 0;
  final markedRead = <String>[];
  final deleted = <String>[];

  void _throwIfNeeded() {
    if (error != null) throw error!;
  }

  @override
  Future<List<Map<String, dynamic>>> fetchNotifications() async {
    _throwIfNeeded();
    return [
      Map<String, dynamic>.from(_materialPayload),
      {..._paymentPayload, 'read': paymentRead},
      if (includeLeakedUser)
        {..._paymentPayload, 'id': 'notification-leaked', 'user_id': 'user-2'},
    ];
  }

  @override
  Future<int> fetchUnreadCount() async {
    _throwIfNeeded();
    unreadRequests++;
    return 2;
  }

  @override
  Future<void> markRead(String notificationId) async {
    _throwIfNeeded();
    markedRead.add(notificationId);
  }

  @override
  Future<void> markAllRead() async {
    _throwIfNeeded();
    markAllRequests++;
  }

  @override
  Future<void> deleteNotification(String notificationId) async {
    _throwIfNeeded();
    deleted.add(notificationId);
  }
}

class _MemoryNotificationsCache implements NotificationsCache {
  final inboxes = <String, CachedNotificationsInbox>{};

  @override
  Future<CachedNotificationsInbox?> readInbox(String userId) async =>
      inboxes[userId];

  @override
  Future<void> writeInbox(String userId, Map<String, dynamic> payload) async {
    inboxes[userId] = CachedNotificationsInbox(
      payload: payload,
      cachedAt: DateTime(2026, 8, 7, 12),
    );
  }
}

const _materialPayload = <String, dynamic>{
  'id': 'notification-material',
  'company_id': 'company-1',
  'user_id': null,
  'site_id': 'site-1',
  'title': 'Low Stock Alert',
  'message': 'OPC cement stock is only 4 bags.',
  'type': 'MATERIAL',
  'priority': 'HIGH',
  'read': false,
  'created_at': '2026-08-07T08:30:00Z',
};

const _paymentPayload = <String, dynamic>{
  'id': 'notification-payment',
  'company_id': 'company-1',
  'user_id': 'user-1',
  'site_id': 'site-1',
  'title': 'Payment submitted',
  'body': 'Payment is pending verification.',
  'type': 'SUBSCRIPTION',
  'read': false,
  'created_at': '2026-08-06T10:00:00Z',
};

const _cachedPayload = <String, dynamic>{
  'notifications': [_materialPayload, _paymentPayload],
  'unread': 2,
};
