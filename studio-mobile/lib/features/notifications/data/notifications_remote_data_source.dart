import '../../../core/network/api_service.dart';

abstract interface class NotificationsRemoteDataSource {
  Future<List<Map<String, dynamic>>> fetchNotifications();
  Future<int> fetchUnreadCount();
  Future<void> markRead(String notificationId);
  Future<void> markAllRead();
  Future<void> deleteNotification(String notificationId);
}

class HttpNotificationsRemoteDataSource
    implements NotificationsRemoteDataSource {
  const HttpNotificationsRemoteDataSource();

  @override
  Future<List<Map<String, dynamic>>> fetchNotifications() =>
      ApiService.getNotifications();

  @override
  Future<int> fetchUnreadCount() => ApiService.getUnreadNotifications();

  @override
  Future<void> markRead(String notificationId) =>
      ApiService.markNotificationRead(notificationId);

  @override
  Future<void> markAllRead() => ApiService.markAllNotificationsRead();

  @override
  Future<void> deleteNotification(String notificationId) =>
      ApiService.deleteNotification(notificationId);
}
