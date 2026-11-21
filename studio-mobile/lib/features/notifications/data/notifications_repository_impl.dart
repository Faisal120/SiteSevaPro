import '../../../core/network/api_service.dart';
import '../models/notification_models.dart';
import '../repository/notifications_repository.dart';
import 'notifications_cache.dart';
import 'notifications_remote_data_source.dart';

class NotificationsRepositoryImpl implements NotificationsRepository {
  const NotificationsRepositoryImpl({
    required NotificationsRemoteDataSource remote,
    required NotificationsCache cache,
    required String userId,
    required NotificationAudience audience,
    DateTime Function()? clock,
  }) : _remote = remote,
       _cache = cache,
       _userId = userId,
       _audience = audience,
       _clock = clock ?? DateTime.now;

  final NotificationsRemoteDataSource _remote;
  final NotificationsCache _cache;
  final String _userId;
  final NotificationAudience _audience;
  final DateTime Function() _clock;

  @override
  Future<NotificationsInboxData> fetchInbox() async {
    try {
      final results = await Future.wait<Object>([
        _remote.fetchNotifications(),
        _remote.fetchUnreadCount(),
      ]);
      final payload = <String, dynamic>{
        'notifications': results[0],
        'unread': results[1],
      };
      await _cache.writeInbox(_userId, payload);
      return _parse(payload, _clock());
    } on ApiException catch (error) {
      if (!error.isConnectivityFailure) rethrow;
      final cached = await _cache.readInbox(_userId);
      if (cached == null) rethrow;
      return _parse(
        cached.payload,
        cached.cachedAt,
        referenceDate: _clock(),
        isOffline: true,
      );
    }
  }

  @override
  Future<int> fetchUnreadCount() => _remote.fetchUnreadCount();

  @override
  Future<void> markRead(String notificationId) async {
    final notification = await _accessibleNotification(notificationId);
    if (notification.isRead) return;
    await _remote.markRead(notificationId);
  }

  @override
  Future<void> markAllRead() => _remote.markAllRead();

  @override
  Future<void> deleteNotification(String notificationId) async {
    final notification = await _accessibleNotification(notificationId);
    if (notification.userId == null) {
      throw const ApiException(
        'Company-wide alerts cannot be deleted from a personal inbox.',
        statusCode: 403,
        kind: ApiErrorKind.authentication,
      );
    }
    if (notification.userId != _userId) {
      throw const ApiException(
        'This notification belongs to another account.',
        statusCode: 403,
        kind: ApiErrorKind.authentication,
      );
    }
    await _remote.deleteNotification(notificationId);
  }

  Future<SiteNotification> _accessibleNotification(String id) async {
    if (id.isEmpty) {
      throw const ApiException(
        'Notification is unavailable.',
        kind: ApiErrorKind.invalidResponse,
      );
    }
    final notifications = (await _remote.fetchNotifications())
        .map(SiteNotification.fromJson)
        .where((notification) => notification.id == id)
        .toList(growable: false);
    if (notifications.isEmpty) {
      throw const ApiException(
        'Notification is not available to this account.',
        statusCode: 404,
      );
    }
    final notification = notifications.single;
    if (notification.userId != null && notification.userId != _userId) {
      throw const ApiException(
        'Notification is not available to this account.',
        statusCode: 403,
        kind: ApiErrorKind.authentication,
      );
    }
    return notification;
  }

  NotificationsInboxData _parse(
    Map<String, dynamic> payload,
    DateTime fetchedAt, {
    DateTime? referenceDate,
    bool isOffline = false,
  }) {
    final unique = <String, SiteNotification>{};
    for (final json in _maps(payload['notifications'])) {
      final notification = SiteNotification.fromJson(json);
      if (notification.id.isEmpty) continue;
      if (notification.userId != null && notification.userId != _userId) {
        continue;
      }
      unique[notification.id] = notification;
    }
    final items = unique.values.toList(growable: false)
      ..sort((a, b) => b.createdAt.compareTo(a.createdAt));
    return NotificationsInboxData(
      notifications: items,
      serverUnreadCount: _int(payload['unread']),
      userId: _userId,
      audience: _audience,
      fetchedAt: fetchedAt,
      referenceDate: referenceDate ?? fetchedAt,
      isOffline: isOffline,
    );
  }
}

int _int(Object? value) =>
    value is num ? value.toInt() : int.tryParse('$value') ?? 0;

List<Map<String, dynamic>> _maps(Object? value) => value is List
    ? value
          .whereType<Map>()
          .map((item) => Map<String, dynamic>.from(item))
          .toList(growable: false)
    : const [];
