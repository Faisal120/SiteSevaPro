enum NotificationAudience { contractor, supervisor, client }

enum NotificationWorkspace { inbox, unread, attention }

enum NotificationPeriod {
  sevenDays('7 days', 7),
  thirtyDays('30 days', 30),
  all('All time', null);

  const NotificationPeriod(this.label, this.days);
  final String label;
  final int? days;
}

enum SiteNotificationType {
  site('SITE', 'Sites'),
  payment('PAYMENT', 'Payments'),
  material('MATERIAL', 'Materials'),
  attendance('ATTENDANCE', 'Attendance'),
  task('TASK', 'Tasks'),
  labour('LABOUR', 'Labour'),
  wallet('WALLET', 'AI credits'),
  subscription('SUBSCRIPTION', 'Subscription'),
  system('SYSTEM', 'System'),
  info('INFO', 'Information'),
  unknown('UNKNOWN', 'Other');

  const SiteNotificationType(this.apiValue, this.label);
  final String apiValue;
  final String label;

  static SiteNotificationType fromApi(Object? value) {
    final normalized = '$value'.trim().toUpperCase();
    return SiteNotificationType.values.firstWhere(
      (type) => type.apiValue == normalized,
      orElse: () => SiteNotificationType.unknown,
    );
  }
}

enum SiteNotificationPriority {
  low('LOW', 'Routine'),
  medium('MEDIUM', 'Important'),
  high('HIGH', 'Needs attention');

  const SiteNotificationPriority(this.apiValue, this.label);
  final String apiValue;
  final String label;

  static SiteNotificationPriority fromApi(Object? value) {
    final normalized = '$value'.trim().toUpperCase();
    return SiteNotificationPriority.values.firstWhere(
      (priority) => priority.apiValue == normalized,
      orElse: () => SiteNotificationPriority.medium,
    );
  }
}

class SiteNotification {
  const SiteNotification({
    required this.id,
    required this.companyId,
    required this.title,
    required this.message,
    required this.type,
    required this.priority,
    required this.isRead,
    required this.createdAt,
    this.userId,
    this.siteId,
    this.labourId,
    this.actionUrl,
  });

  factory SiteNotification.fromJson(Map<String, dynamic> json) =>
      SiteNotification(
        id: '${json['id'] ?? json['_id'] ?? ''}',
        companyId: '${json['company_id'] ?? ''}',
        userId: _nullableString(json['user_id']),
        siteId: _nullableString(json['site_id']),
        labourId: _nullableString(json['labour_id']),
        title: '${json['title'] ?? json['subject'] ?? ''}'.trim(),
        message: '${json['message'] ?? json['body'] ?? ''}'.trim(),
        type: SiteNotificationType.fromApi(json['type']),
        priority: SiteNotificationPriority.fromApi(json['priority']),
        actionUrl: _nullableString(json['action_url']),
        isRead: json['read'] == true || json['is_read'] == true,
        createdAt:
            _date(json['created_at'] ?? json['created'] ?? json['timestamp']) ??
                DateTime.fromMillisecondsSinceEpoch(0),
      );

  final String id;
  final String companyId;
  final String? userId;
  final String? siteId;
  final String? labourId;
  final String title;
  final String message;
  final SiteNotificationType type;
  final SiteNotificationPriority priority;
  final String? actionUrl;
  final bool isRead;
  final DateTime createdAt;

  bool get isUnread => !isRead;
  bool get isBroadcast => userId == null;
  bool get needsAttention => priority == SiteNotificationPriority.high;
  String get displayTitle => title.isEmpty ? type.label : title;
  String get displayMessage => message.isEmpty
      ? 'A new ${type.label.toLowerCase()} update is available.'
      : message;

  SiteNotification copyWith({bool? isRead}) => SiteNotification(
    id: id,
    companyId: companyId,
    userId: userId,
    siteId: siteId,
    labourId: labourId,
    title: title,
    message: message,
    type: type,
    priority: priority,
    actionUrl: actionUrl,
    isRead: isRead ?? this.isRead,
    createdAt: createdAt,
  );

  Map<String, dynamic> toJson() => {
    'id': id,
    'company_id': companyId,
    'user_id': userId,
    'site_id': siteId,
    'labour_id': labourId,
    'title': title,
    'message': message,
    'type': type.apiValue,
    'priority': priority.apiValue,
    'action_url': actionUrl,
    'read': isRead,
    'created_at': createdAt.toUtc().toIso8601String(),
  };
}

class NotificationGroup {
  const NotificationGroup({required this.label, required this.items});
  final String label;
  final List<SiteNotification> items;
}

class NotificationsInboxData {
  const NotificationsInboxData({
    required this.notifications,
    required this.serverUnreadCount,
    required this.userId,
    required this.audience,
    required this.fetchedAt,
    required this.referenceDate,
    this.isOffline = false,
    this.workspace = NotificationWorkspace.inbox,
    this.period = NotificationPeriod.thirtyDays,
    this.query = '',
    this.typeFilter,
  });

  final List<SiteNotification> notifications;
  final int serverUnreadCount;
  final String userId;
  final NotificationAudience audience;
  final DateTime fetchedAt;
  final DateTime referenceDate;
  final bool isOffline;
  final NotificationWorkspace workspace;
  final NotificationPeriod period;
  final String query;
  final SiteNotificationType? typeFilter;

  int get unreadInLoadedFeed =>
      notifications.where((notification) => notification.isUnread).length;
  int get attentionCount => notifications
      .where(
        (notification) => notification.isUnread && notification.needsAttention,
      )
      .length;
  int get companyAlertCount =>
      notifications.where((notification) => notification.isBroadcast).length;
  bool get canMutate => !isOffline;

  bool canDelete(SiteNotification notification) =>
      canMutate &&
      userId.isNotEmpty &&
      notification.userId != null &&
      notification.userId == userId;

  String? destinationFor(SiteNotification notification) {
    final encodedSite = notification.siteId == null
        ? null
        : Uri.encodeComponent(notification.siteId!);
    final encodedLabour = notification.labourId == null
        ? null
        : Uri.encodeComponent(notification.labourId!);
    return switch (notification.type) {
      SiteNotificationType.site =>
        encodedSite == null ? '/sites' : '/sites/$encodedSite',
      SiteNotificationType.payment =>
        audience == NotificationAudience.supervisor
            ? null
            : encodedSite == null
            ? '/payments'
            : '/payments?siteId=$encodedSite',
      SiteNotificationType.material =>
        audience == NotificationAudience.client ? null : '/materials',
      SiteNotificationType.attendance => '/attendance',
      SiteNotificationType.labour =>
        audience == NotificationAudience.client
            ? null
            : encodedLabour == null
            ? '/labour'
            : '/labour/$encodedLabour',
      SiteNotificationType.wallet =>
        audience == NotificationAudience.contractor ? '/design-studio' : null,
      SiteNotificationType.subscription =>
        audience == NotificationAudience.contractor ? '/subscription' : null,
      SiteNotificationType.task =>
        encodedSite == null ? '/sites' : '/sites/$encodedSite',
      SiteNotificationType.system ||
      SiteNotificationType.info ||
      SiteNotificationType.unknown => null,
    };
  }

  List<SiteNotification> get visibleNotifications {
    final normalized = query.trim().toLowerCase();
    final referenceDay = _day(referenceDate);
    final start = period.days == null
        ? null
        : referenceDay.subtract(Duration(days: period.days! - 1));
    final result = notifications
        .where((notification) {
          if (workspace == NotificationWorkspace.unread &&
              notification.isRead) {
            return false;
          }
          if (workspace == NotificationWorkspace.attention &&
              (!notification.isUnread || !notification.needsAttention)) {
            return false;
          }
          if (typeFilter != null && notification.type != typeFilter)
            return false;
          final createdDay = _day(notification.createdAt);
          if (start != null && createdDay.isBefore(start)) return false;
          if (createdDay.isAfter(referenceDay)) return false;
          if (normalized.isEmpty) return true;
          return notification.displayTitle.toLowerCase().contains(normalized) ||
              notification.displayMessage.toLowerCase().contains(normalized) ||
              notification.type.label.toLowerCase().contains(normalized);
        })
        .toList(growable: false);
    result.sort((a, b) => b.createdAt.compareTo(a.createdAt));
    return result;
  }

  List<NotificationGroup> get groups {
    final today = _day(referenceDate);
    final yesterday = today.subtract(const Duration(days: 1));
    final buckets = <String, List<SiteNotification>>{};
    for (final notification in visibleNotifications) {
      final created = _day(notification.createdAt);
      final label = created == today
          ? 'Today'
          : created == yesterday
          ? 'Yesterday'
          : created.year == today.year && created.month == today.month
          ? 'Earlier this month'
          : 'Older';
      buckets.putIfAbsent(label, () => []).add(notification);
    }
    return ['Today', 'Yesterday', 'Earlier this month', 'Older']
        .where((label) => buckets[label]?.isNotEmpty == true)
        .map((label) => NotificationGroup(label: label, items: buckets[label]!))
        .toList(growable: false);
  }

  List<SiteNotificationType> get availableTypes {
    final types = notifications.map((item) => item.type).toSet().toList();
    types.sort((a, b) => a.label.compareTo(b.label));
    return types;
  }

  NotificationsInboxData copyWith({
    List<SiteNotification>? notifications,
    int? serverUnreadCount,
    DateTime? fetchedAt,
    DateTime? referenceDate,
    bool? isOffline,
    NotificationWorkspace? workspace,
    NotificationPeriod? period,
    String? query,
    SiteNotificationType? typeFilter,
    bool clearType = false,
  }) => NotificationsInboxData(
    notifications: notifications ?? this.notifications,
    serverUnreadCount: serverUnreadCount ?? this.serverUnreadCount,
    userId: userId,
    audience: audience,
    fetchedAt: fetchedAt ?? this.fetchedAt,
    referenceDate: referenceDate ?? this.referenceDate,
    isOffline: isOffline ?? this.isOffline,
    workspace: workspace ?? this.workspace,
    period: period ?? this.period,
    query: query ?? this.query,
    typeFilter: clearType ? null : typeFilter ?? this.typeFilter,
  );
}

DateTime _day(DateTime value) => DateTime(value.year, value.month, value.day);

DateTime? _date(Object? value) =>
    value == null ? null : DateTime.tryParse('$value')?.toLocal();

String? _nullableString(Object? value) {
  final normalized = '$value'.trim();
  return value == null || normalized.isEmpty || normalized == 'null'
      ? null
      : normalized;
}
