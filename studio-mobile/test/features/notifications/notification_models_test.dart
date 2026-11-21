import 'package:flutter_test/flutter_test.dart';
import 'package:siteseva/features/notifications/models/notification_models.dart';

void main() {
  group('Notification models', () {
    test('parses canonical notification schema', () {
      final notification = SiteNotification.fromJson(_materialPayload);

      expect(notification.id, 'notification-material');
      expect(notification.type, SiteNotificationType.material);
      expect(notification.priority, SiteNotificationPriority.high);
      expect(notification.message, 'OPC cement stock is only 4 bags.');
      expect(notification.isUnread, isTrue);
      expect(notification.isBroadcast, isTrue);
    });

    test('normalizes legacy body and additional backend event types', () {
      final info = SiteNotification.fromJson({
        ..._materialPayload,
        'id': 'notification-info',
        'message': null,
        'body': 'Your account has been approved.',
        'type': 'INFO',
        'priority': null,
      });
      final subscription = SiteNotification.fromJson({
        ..._materialPayload,
        'id': 'notification-subscription',
        'type': 'SUBSCRIPTION',
      });

      expect(info.message, 'Your account has been approved.');
      expect(info.type, SiteNotificationType.info);
      expect(info.priority, SiteNotificationPriority.medium);
      expect(subscription.type, SiteNotificationType.subscription);
    });

    test('derives safe role-aware routes instead of trusting action_url', () {
      final malicious = SiteNotification.fromJson({
        ..._paymentPayload,
        'action_url': 'https://malicious.example/steal-session',
      });
      final contractor = _studio(
        audience: NotificationAudience.contractor,
        notifications: [malicious],
      );
      final supervisor = _studio(
        audience: NotificationAudience.supervisor,
        notifications: [malicious],
      );
      final client = _studio(
        audience: NotificationAudience.client,
        notifications: [SiteNotification.fromJson(_materialPayload)],
      );

      expect(contractor.destinationFor(malicious), '/payments?siteId=site-1');
      expect(supervisor.destinationFor(malicious), isNull);
      expect(
        client.destinationFor(SiteNotification.fromJson(_materialPayload)),
        isNull,
      );
    });

    test('filters unread high-priority updates and groups by server dates', () {
      final data = _studio(
        audience: NotificationAudience.contractor,
        notifications: [
          SiteNotification.fromJson(_materialPayload),
          SiteNotification.fromJson(_paymentPayload),
          SiteNotification.fromJson({
            ..._paymentPayload,
            'id': 'notification-read',
            'read': true,
            'created_at': '2026-08-05T08:00:00Z',
          }),
        ],
      ).copyWith(workspace: NotificationWorkspace.attention);

      expect(data.visibleNotifications.map((item) => item.id), [
        'notification-material',
      ]);
      expect(data.groups.single.label, 'Today');
      expect(data.attentionCount, 1);
    });

    test('searches title, body, and type within selected period', () {
      final data = _studio(
        audience: NotificationAudience.contractor,
        notifications: [
          SiteNotification.fromJson(_materialPayload),
          SiteNotification.fromJson(_paymentPayload),
        ],
      ).copyWith(query: 'foundation', typeFilter: SiteNotificationType.payment);

      expect(data.visibleNotifications.single.id, 'notification-payment');
      expect(
        data.copyWith(period: NotificationPeriod.sevenDays).groups,
        isNotEmpty,
      );
    });

    test('allows deletion only for the current user targeted notification', () {
      final targeted = SiteNotification.fromJson(_paymentPayload);
      final broadcast = SiteNotification.fromJson(_materialPayload);
      final data = _studio(
        audience: NotificationAudience.contractor,
        notifications: [targeted, broadcast],
      );

      expect(data.canDelete(targeted), isTrue);
      expect(data.canDelete(broadcast), isFalse);
      expect(data.copyWith(isOffline: true).canDelete(targeted), isFalse);
    });
  });
}

NotificationsInboxData _studio({
  required NotificationAudience audience,
  required List<SiteNotification> notifications,
}) => NotificationsInboxData(
  notifications: notifications,
  serverUnreadCount: notifications.where((item) => item.isUnread).length,
  userId: 'user-1',
  audience: audience,
  fetchedAt: DateTime(2026, 8, 7, 12),
  referenceDate: DateTime(2026, 8, 7, 12),
);

const _materialPayload = <String, dynamic>{
  'id': 'notification-material',
  'company_id': 'company-1',
  'user_id': null,
  'site_id': 'site-1',
  'title': 'Low Stock Alert',
  'message': 'OPC cement stock is only 4 bags.',
  'type': 'MATERIAL',
  'priority': 'HIGH',
  'action_url': '/materials',
  'read': false,
  'created_at': '2026-08-07T08:30:00Z',
};

const _paymentPayload = <String, dynamic>{
  'id': 'notification-payment',
  'company_id': 'company-1',
  'user_id': 'user-1',
  'site_id': 'site-1',
  'title': 'Payment Received',
  'message': 'Foundation milestone payment received.',
  'type': 'PAYMENT',
  'priority': 'MEDIUM',
  'action_url': '/payments/site-1',
  'read': false,
  'created_at': '2026-08-06T10:00:00Z',
};
