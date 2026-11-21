import '../models/notification_models.dart';

abstract interface class NotificationsRepository {
  Future<NotificationsInboxData> fetchInbox();
  Future<int> fetchUnreadCount();
  Future<void> markRead(String notificationId);
  Future<void> markAllRead();
  Future<void> deleteNotification(String notificationId);
}
