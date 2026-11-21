import 'package:flutter_test/flutter_test.dart';
import 'package:siteseva/features/notifications/data/notifications_realtime.dart';
import 'package:siteseva/features/notifications/models/notification_models.dart';
import 'package:siteseva/features/notifications/providers/notifications_provider.dart';
import 'package:siteseva/features/notifications/repository/notifications_repository.dart';

void main() {
  test('merges a realtime notification and increments unread count once', () async {
    final realtime = _FakeRealtime(
      payload: {
        'event': 'notification.created',
        'data': {
          'id': 'notification-new',
          'company_id': 'company-1',
          'user_id': null,
          'title': 'Inspection scheduled',
          'message': 'Client inspection starts at 4 PM.',
          'type': 'SITE',
          'priority': 'MEDIUM',
          'read': false,
          'created_at': '2026-08-08T10:00:00Z',
        },
      },
    );
    final statuses = <NotificationRealtimeStatus>[];
    final events = <String>[];
    final controller = NotificationsInboxController(
      _FakeNotificationsRepository(_inbox),
      realtime: realtime,
      pollingInterval: const Duration(days: 1),
      onRealtimeStatus: statuses.add,
      onRealtimeEvent: (notification) => events.add(notification.id),
    );

    await controller.start();
    await Future<void>.delayed(Duration.zero);

    final data = controller.state.value!;
    expect(data.notifications.first.id, 'notification-new');
    expect(data.serverUnreadCount, 2);
    expect(events, ['notification-new']);
    expect(statuses, contains(NotificationRealtimeStatus.connected));
    controller.dispose();
  });

  test('realtime update replaces an existing item without double counting unread',
      () async {
    final realtime = _FakeRealtime(
      payload: {
        'id': 'notification-old',
        'company_id': 'company-1',
        'user_id': 'user-1',
        'title': 'Payment cleared',
        'message': 'Payment has been reviewed.',
        'type': 'PAYMENT',
        'priority': 'MEDIUM',
        'read': true,
        'created_at': '2026-08-08T10:00:00Z',
      },
    );
    final controller = NotificationsInboxController(
      _FakeNotificationsRepository(_inbox),
      realtime: realtime,
      pollingInterval: const Duration(days: 1),
    );

    await controller.start();
    await Future<void>.delayed(Duration.zero);

    final data = controller.state.value!;
    expect(data.notifications.where((item) => item.id == 'notification-old'),
        hasLength(1));
    expect(data.serverUnreadCount, 0);
    controller.dispose();
  });

  test('uses polling status when realtime transport cannot connect', () async {
    final statuses = <NotificationRealtimeStatus>[];
    final controller = NotificationsInboxController(
      _FakeNotificationsRepository(_inbox),
      realtime: _FakeRealtime(throwsOnConnect: true),
      pollingInterval: const Duration(days: 1),
      onRealtimeStatus: statuses.add,
    );

    await controller.start();
    await Future<void>.delayed(Duration.zero);

    expect(statuses, contains(NotificationRealtimeStatus.polling));
    controller.dispose();
  });
}

class _FakeRealtime implements NotificationRealtimeClient {
  _FakeRealtime({this.payload, this.throwsOnConnect = false});

  final Map<String, dynamic>? payload;
  final bool throwsOnConnect;

  @override
  Future<void> connect({
    required NotificationRealtimeEvent onEvent,
    required NotificationRealtimeDisconnect onDisconnected,
  }) async {
    if (throwsOnConnect) throw StateError('socket unavailable');
    if (payload != null) {
      final nested = payload!['data'];
      onEvent(
        nested is Map
            ? Map<String, dynamic>.from(nested)
            : Map<String, dynamic>.from(payload!),
      );
    }
  }

  @override
  Future<void> disconnect() async {}
}

class _FakeNotificationsRepository implements NotificationsRepository {
  const _FakeNotificationsRepository(this.data);

  final NotificationsInboxData data;

  @override
  Future<NotificationsInboxData> fetchInbox() async => data;

  @override
  Future<int> fetchUnreadCount() async => data.serverUnreadCount;

  @override
  Future<void> markRead(String notificationId) async {}

  @override
  Future<void> markAllRead() async {}

  @override
  Future<void> deleteNotification(String notificationId) async {}
}

final _inbox = NotificationsInboxData(
  notifications: [
    SiteNotification.fromJson({
      'id': 'notification-old',
      'company_id': 'company-1',
      'user_id': 'user-1',
      'title': 'Payment submitted',
      'message': 'Payment is pending verification.',
      'type': 'PAYMENT',
      'priority': 'MEDIUM',
      'read': false,
      'created_at': '2026-08-07T10:00:00Z',
    }),
  ],
  serverUnreadCount: 1,
  userId: 'user-1',
  audience: NotificationAudience.contractor,
  fetchedAt: DateTime(2026, 8, 8),
  referenceDate: DateTime(2026, 8, 8),
);
