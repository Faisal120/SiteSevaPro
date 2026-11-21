import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/network/api_service.dart';
import '../../auth/providers/auth_provider.dart';
import '../data/notifications_cache.dart';
import '../data/notifications_remote_data_source.dart';
import '../data/notifications_realtime.dart';
import '../data/notifications_repository_impl.dart';
import '../models/notification_models.dart';
import '../repository/notifications_repository.dart';

enum NotificationRealtimeStatus { connecting, connected, polling, offline }

extension NotificationRealtimeStatusLabel on NotificationRealtimeStatus {
  String get label => switch (this) {
    NotificationRealtimeStatus.connecting => 'Connecting live updates',
    NotificationRealtimeStatus.connected => 'Live updates connected',
    NotificationRealtimeStatus.polling => 'Polling fallback active',
    NotificationRealtimeStatus.offline => 'Offline snapshot',
  };

  bool get isLive => this == NotificationRealtimeStatus.connected;
}

final notificationsRemoteDataSourceProvider =
    Provider<NotificationsRemoteDataSource>(
      (ref) => const HttpNotificationsRemoteDataSource(),
    );

final notificationsCacheProvider = Provider<NotificationsCache>(
  (ref) => HiveNotificationsCache(),
);

final notificationRealtimeClientProvider = Provider<NotificationRealtimeClient>(
  (ref) => HttpNotificationRealtimeClient(),
);

final notificationRealtimeStatusProvider = StateProvider<
  NotificationRealtimeStatus
>((ref) => NotificationRealtimeStatus.connecting);

final notificationRealtimeEventProvider = StateProvider<SiteNotification?>(
  (ref) => null,
);

final notificationsRepositoryProvider = Provider<NotificationsRepository>((
  ref,
) {
  final user = ref.watch(authControllerProvider).valueOrNull;
  final audience = user?.isSupervisor == true
      ? NotificationAudience.supervisor
      : user?.isClient == true
      ? NotificationAudience.client
      : NotificationAudience.contractor;
  return NotificationsRepositoryImpl(
    remote: ref.watch(notificationsRemoteDataSourceProvider),
    cache: ref.watch(notificationsCacheProvider),
    userId: user?.id ?? '',
    audience: audience,
  );
});

final notificationUnreadCountProvider = FutureProvider.autoDispose<int>((
  ref,
) async {
  final refreshTimer = Timer.periodic(const Duration(seconds: 45), (_) {
    ref.invalidateSelf();
  });
  ref.onDispose(refreshTimer.cancel);
  final user = ref.watch(authControllerProvider).valueOrNull;
  if (user == null || ApiService.token?.isNotEmpty != true) return 0;
  return ref.watch(notificationsRepositoryProvider).fetchUnreadCount();
});

final notificationsInboxControllerProvider =
    StateNotifierProvider<
      NotificationsInboxController,
      AsyncValue<NotificationsInboxData>
    >((ref) {
      final controller = NotificationsInboxController(
        ref.watch(notificationsRepositoryProvider),
        realtime: ref.watch(notificationRealtimeClientProvider),
        onRealtimeStatus: (status) =>
            ref.read(notificationRealtimeStatusProvider.notifier).state =
                status,
        onRealtimeEvent: (notification) =>
            ref.read(notificationRealtimeEventProvider.notifier).state =
                notification,
      );
      unawaited(controller.start());
      return controller;
    });

final notificationsActionControllerProvider =
    StateNotifierProvider.autoDispose<
      NotificationsActionController,
      AsyncValue<void>
    >((ref) {
      return NotificationsActionController(
        repository: ref.watch(notificationsRepositoryProvider),
        refreshInbox: () =>
            ref.read(notificationsInboxControllerProvider.notifier).refresh(),
        refreshUnread: () => ref.invalidate(notificationUnreadCountProvider),
      );
    });

class NotificationsInboxController
    extends StateNotifier<AsyncValue<NotificationsInboxData>> {
  NotificationsInboxController(
    this._repository, {
    Duration pollingInterval = const Duration(seconds: 45),
    NotificationRealtimeClient? realtime,
    void Function(NotificationRealtimeStatus status)? onRealtimeStatus,
    void Function(SiteNotification notification)? onRealtimeEvent,
  }) : _pollingInterval = pollingInterval,
       _realtime = realtime,
       _onRealtimeStatus = onRealtimeStatus,
       _onRealtimeEvent = onRealtimeEvent,
       super(const AsyncValue.loading());

  final NotificationsRepository _repository;
  final Duration _pollingInterval;
  final NotificationRealtimeClient? _realtime;
  final void Function(NotificationRealtimeStatus status)? _onRealtimeStatus;
  final void Function(SiteNotification notification)? _onRealtimeEvent;
  Timer? _poller;
  Timer? _reconnectTimer;
  var _reconnectAttempt = 0;
  var _disposed = false;

  Future<void> start() async {
    await load();
    _poller ??= Timer.periodic(_pollingInterval, (_) => _poll());
    unawaited(_connectRealtime());
  }

  Future<void> load() async {
    state = const AsyncValue.loading();
    state = await AsyncValue.guard(_repository.fetchInbox);
  }

  Future<void> refresh() async {
    final previous = state.valueOrNull;
    try {
      final fresh = await _repository.fetchInbox();
      state = AsyncValue.data(
        fresh.copyWith(
          workspace: previous?.workspace,
          period: previous?.period,
          query: previous?.query,
          typeFilter: previous?.typeFilter,
          clearType: previous?.typeFilter == null,
        ),
      );
    } catch (error, stackTrace) {
      if (previous == null) state = AsyncValue.error(error, stackTrace);
      rethrow;
    }
  }

  Future<void> _poll() async {
    if (state.valueOrNull?.isOffline == true) return;
    try {
      await refresh();
    } catch (_) {
      // Foreground polling is best effort; pull-to-refresh remains available.
    }
  }

  Future<void> _connectRealtime() async {
    final realtime = _realtime;
    if (_disposed) return;
    if (realtime == null) {
      _setRealtimeStatus(NotificationRealtimeStatus.polling);
      return;
    }
    _setRealtimeStatus(NotificationRealtimeStatus.connecting);
    try {
      await realtime.connect(
        onEvent: _mergeRealtimeEvent,
        onDisconnected: _handleRealtimeDisconnect,
      );
      if (_disposed) return;
      _reconnectAttempt = 0;
      _setRealtimeStatus(NotificationRealtimeStatus.connected);
    } catch (_) {
      _setRealtimeStatus(
        state.valueOrNull?.isOffline == true
            ? NotificationRealtimeStatus.offline
            : NotificationRealtimeStatus.polling,
      );
      _scheduleRealtimeReconnect();
    }
  }

  void _handleRealtimeDisconnect(Object? error) {
    if (_disposed) return;
    _setRealtimeStatus(
      state.valueOrNull?.isOffline == true
          ? NotificationRealtimeStatus.offline
          : NotificationRealtimeStatus.polling,
    );
    _scheduleRealtimeReconnect();
  }

  void _scheduleRealtimeReconnect() {
    if (_disposed || _realtime == null || _reconnectTimer != null) return;
    final exponent = _reconnectAttempt.clamp(0, 5);
    final delay = Duration(seconds: 2 << exponent);
    _reconnectAttempt++;
    _reconnectTimer = Timer(delay, () {
      _reconnectTimer = null;
      unawaited(_connectRealtime());
    });
  }

  void _mergeRealtimeEvent(Map<String, dynamic> payload) {
    if (_disposed) return;
    final incoming = SiteNotification.fromJson(payload);
    final current = state.valueOrNull;
    if (incoming.id.isEmpty || current == null) return;
    if (incoming.userId != null && incoming.userId != current.userId) return;
    final companyIds = current.notifications
        .map((item) => item.companyId)
        .where((id) => id.isNotEmpty)
        .toSet();
    if (companyIds.isNotEmpty &&
        incoming.companyId.isNotEmpty &&
        !companyIds.contains(incoming.companyId)) {
      return;
    }
    SiteNotification? previous;
    for (final notification in current.notifications) {
      if (notification.id == incoming.id) previous = notification;
    }
    final notifications = [
      incoming,
      ...current.notifications.where((item) => item.id != incoming.id),
    ]..sort((a, b) => b.createdAt.compareTo(a.createdAt));
    final unreadDelta = (incoming.isUnread ? 1 : 0) -
        (previous?.isUnread == true ? 1 : 0);
    state = AsyncValue.data(
      current.copyWith(
        notifications: notifications,
        serverUnreadCount: (current.serverUnreadCount + unreadDelta).clamp(
          0,
          1 << 31,
        ),
        fetchedAt: DateTime.now(),
        referenceDate: DateTime.now(),
        isOffline: false,
      ),
    );
    _onRealtimeEvent?.call(incoming);
  }

  void _setRealtimeStatus(NotificationRealtimeStatus status) {
    if (!_disposed) _onRealtimeStatus?.call(status);
  }

  void setWorkspace(NotificationWorkspace workspace) {
    final data = state.valueOrNull;
    if (data != null) {
      state = AsyncValue.data(data.copyWith(workspace: workspace, query: ''));
    }
  }

  void setPeriod(NotificationPeriod period) {
    final data = state.valueOrNull;
    if (data != null) state = AsyncValue.data(data.copyWith(period: period));
  }

  void setQuery(String query) {
    final data = state.valueOrNull;
    if (data != null) state = AsyncValue.data(data.copyWith(query: query));
  }

  void setType(SiteNotificationType? type) {
    final data = state.valueOrNull;
    if (data == null) return;
    state = AsyncValue.data(
      data.copyWith(typeFilter: type, clearType: type == null),
    );
  }

  @override
  void dispose() {
    _disposed = true;
    _poller?.cancel();
    _reconnectTimer?.cancel();
    unawaited(_realtime?.disconnect());
    super.dispose();
  }
}

class NotificationsActionController extends StateNotifier<AsyncValue<void>> {
  NotificationsActionController({
    required NotificationsRepository repository,
    required Future<void> Function() refreshInbox,
    required void Function() refreshUnread,
  }) : _repository = repository,
       _refreshInbox = refreshInbox,
       _refreshUnread = refreshUnread,
       super(const AsyncValue.data(null));

  final NotificationsRepository _repository;
  final Future<void> Function() _refreshInbox;
  final void Function() _refreshUnread;

  Future<bool> markRead(String notificationId) =>
      _mutate(() => _repository.markRead(notificationId));

  Future<bool> markAllRead() => _mutate(_repository.markAllRead);

  Future<bool> deleteNotification(String notificationId) =>
      _mutate(() => _repository.deleteNotification(notificationId));

  Future<bool> _mutate(Future<void> Function() operation) async {
    state = const AsyncValue.loading();
    try {
      await operation();
      state = const AsyncValue.data(null);
      try {
        await _refreshInbox();
        _refreshUnread();
      } catch (_) {
        // The mutation is committed; synchronization can retry independently.
      }
      return true;
    } catch (error, stackTrace) {
      state = AsyncValue.error(error, stackTrace);
      return false;
    }
  }

  void clearError() => state = const AsyncValue.data(null);
}
