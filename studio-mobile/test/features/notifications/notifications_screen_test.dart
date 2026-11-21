import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:siteseva/core/theme/app_theme.dart';
import 'package:siteseva/features/notifications/models/notification_models.dart';
import 'package:siteseva/features/notifications/presentation/screens/notification_detail_screen.dart';
import 'package:siteseva/features/notifications/presentation/screens/notifications_screen.dart';
import 'package:siteseva/features/notifications/providers/notifications_provider.dart';
import 'package:siteseva/features/notifications/repository/notifications_repository.dart';

void main() {
  testWidgets('desktop inbox renders live operations notification center', (
    tester,
  ) async {
    await _pump(
      tester,
      size: const Size(1440, 1050),
      data: _contractorInbox,
      child: const NotificationsScreen(),
    );

    expect(find.text('Notifications'), findsOneWidget);
    expect(find.text('OPERATIONS INBOX'), findsOneWidget);
    expect(find.text('All updates'), findsOneWidget);
    expect(find.text('Unread 2'), findsOneWidget);
    expect(find.text('Attention 1'), findsOneWidget);
    expect(find.text('Low Stock Alert'), findsOneWidget);
    expect(find.text('Payment submitted'), findsOneWidget);
    expect(find.text('Mark 2 read'), findsOneWidget);
    _expectNoFlutterException(tester);
  });

  testWidgets('mobile inbox settles without responsive overflow', (
    tester,
  ) async {
    await _pump(
      tester,
      size: const Size(390, 844),
      data: _contractorInbox,
      child: const NotificationsScreen(),
    );

    expect(find.byTooltip('Mark all read'), findsOneWidget);
    expect(find.text('OPERATIONS INBOX'), findsOneWidget);
    expect(find.text('Low Stock Alert'), findsOneWidget);
    _expectNoFlutterException(tester);
  });

  testWidgets('attention workspace contains only unread high priority events', (
    tester,
  ) async {
    await _pump(
      tester,
      size: const Size(1100, 900),
      data: _contractorInbox.copyWith(
        workspace: NotificationWorkspace.attention,
      ),
      child: const NotificationsScreen(),
    );

    expect(find.text('Low Stock Alert'), findsOneWidget);
    expect(find.text('Payment submitted'), findsNothing);
    expect(find.text('HIGH PRIORITY'), findsOneWidget);
    _expectNoFlutterException(tester);
  });

  testWidgets('offline inbox shows snapshot protection and hides mark all', (
    tester,
  ) async {
    await _pump(
      tester,
      size: const Size(390, 844),
      data: _contractorInbox.copyWith(isOffline: true),
      child: const NotificationsScreen(),
    );

    expect(find.textContaining('Offline snapshot'), findsOneWidget);
    expect(find.byTooltip('Mark all read'), findsNothing);
    _expectNoFlutterException(tester);
  });

  testWidgets('targeted notification detail exposes safe action and delete', (
    tester,
  ) async {
    await _pump(
      tester,
      size: const Size(1100, 1000),
      data: _contractorInbox,
      child: const NotificationDetailScreen(
        notificationId: 'notification-payment',
      ),
    );

    expect(find.text('Notification Detail'), findsOneWidget);
    expect(find.text('Record context'), findsOneWidget);
    expect(find.text('Payment is pending verification.'), findsOneWidget);
    expect(find.text('Open subscription'), findsOneWidget);
    expect(find.text('Delete from my inbox'), findsOneWidget);
    _expectNoFlutterException(tester);
  });

  testWidgets('company broadcast detail cannot be deleted', (tester) async {
    await _pump(
      tester,
      size: const Size(390, 900),
      data: _contractorInbox,
      child: const NotificationDetailScreen(
        notificationId: 'notification-material',
      ),
    );

    expect(find.text('Company-wide'), findsOneWidget);
    expect(find.text('Open stock control'), findsOneWidget);
    expect(find.text('Delete from my inbox'), findsNothing);
    expect(find.textContaining('shared operational records'), findsOneWidget);
    _expectNoFlutterException(tester);
  });

  testWidgets('supervisor cannot deep link into payment finance', (
    tester,
  ) async {
    final supervisorPayment = SiteNotification.fromJson({
      ..._paymentPayload,
      'type': 'PAYMENT',
      'title': 'Payment received',
    });
    final data = NotificationsInboxData(
      notifications: [supervisorPayment],
      serverUnreadCount: 1,
      userId: 'user-1',
      audience: NotificationAudience.supervisor,
      fetchedAt: DateTime(2026, 8, 7, 12),
      referenceDate: DateTime(2026, 8, 7, 12),
    );
    await _pump(
      tester,
      size: const Size(390, 900),
      data: data,
      child: const NotificationDetailScreen(
        notificationId: 'notification-payment',
      ),
    );

    expect(find.text('Payment received'), findsOneWidget);
    expect(find.text('Open payments'), findsNothing);
    _expectNoFlutterException(tester);
  });
}

Future<void> _pump(
  WidgetTester tester, {
  required Size size,
  required NotificationsInboxData data,
  required Widget child,
}) async {
  tester.view.physicalSize = size;
  tester.view.devicePixelRatio = 1;
  addTearDown(tester.view.resetPhysicalSize);
  addTearDown(tester.view.resetDevicePixelRatio);
  final repository = _FakeNotificationsRepository(data);
  await tester.pumpWidget(
    ProviderScope(
      overrides: [
        notificationsRepositoryProvider.overrideWithValue(repository),
        notificationsInboxControllerProvider.overrideWith(
          (ref) => _LoadedNotificationsController(data, repository),
        ),
      ],
      child: MaterialApp(theme: AppTheme.light(), home: child),
    ),
  );
  await tester.pump(const Duration(milliseconds: 900));
  await tester.pump(const Duration(milliseconds: 900));
}

void _expectNoFlutterException(WidgetTester tester) {
  final exception = tester.takeException();
  if (exception case final FlutterError error) {
    debugPrint(error.toStringDeep());
  }
  expect(exception, isNull);
}

class _LoadedNotificationsController extends NotificationsInboxController {
  _LoadedNotificationsController(
    NotificationsInboxData data,
    NotificationsRepository repository,
  ) : super(repository) {
    state = AsyncValue.data(data);
  }
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

final _material = SiteNotification.fromJson(_materialPayload);
final _payment = SiteNotification.fromJson(_paymentPayload);

final _contractorInbox = NotificationsInboxData(
  notifications: [_material, _payment],
  serverUnreadCount: 2,
  userId: 'user-1',
  audience: NotificationAudience.contractor,
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
