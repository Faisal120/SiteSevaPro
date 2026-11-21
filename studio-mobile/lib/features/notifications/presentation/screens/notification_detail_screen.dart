import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/theme/app_theme.dart';
import '../../../../core/utils/app_formatters.dart';
import '../../../../core/widgets/app_ui.dart';
import '../../models/notification_models.dart';
import '../../providers/notifications_provider.dart';
import '../widgets/notifications_widgets.dart';

class NotificationDetailScreen extends ConsumerStatefulWidget {
  const NotificationDetailScreen({super.key, required this.notificationId});
  final String notificationId;

  @override
  ConsumerState<NotificationDetailScreen> createState() =>
      _NotificationDetailScreenState();
}

class _NotificationDetailScreenState
    extends ConsumerState<NotificationDetailScreen> {
  bool _readRequested = false;

  @override
  Widget build(BuildContext context) {
    final inbox = ref.watch(notificationsInboxControllerProvider);
    return Material(
      color: Theme.of(context).scaffoldBackgroundColor,
      child: AppPage(
        title: 'Notification Detail',
        subtitle: 'Operational context and verified server metadata.',
        child: inbox.when(
          loading: () => ListView(
            padding: const EdgeInsets.fromLTRB(20, 6, 20, 120),
            children: const [
              AppSkeleton(height: 240, radius: 32),
              SizedBox(height: 14),
              AppSkeleton(height: 260),
            ],
          ),
          error: (error, _) => ListView(
            padding: const EdgeInsets.fromLTRB(20, 6, 20, 120),
            children: [
              EmptyPanel(
                title: 'Notification unavailable',
                message: '$error',
                icon: Icons.cloud_off_rounded,
                actionLabel: 'Reconnect',
                onAction: () => ref
                    .read(notificationsInboxControllerProvider.notifier)
                    .load(),
              ),
            ],
          ),
          data: (data) {
            SiteNotification? notification;
            for (final item in data.notifications) {
              if (item.id == widget.notificationId) notification = item;
            }
            if (notification == null) return const _MissingNotification();
            if (notification.isUnread && !_readRequested && !data.isOffline) {
              _readRequested = true;
              WidgetsBinding.instance.addPostFrameCallback((_) {
                if (!mounted) return;
                ref
                    .read(notificationsActionControllerProvider.notifier)
                    .markRead(notification!.id);
              });
            }
            return _NotificationDetailBody(
              data: data,
              notification: notification,
              onDelete: data.canDelete(notification)
                  ? () => _delete(data, notification!)
                  : null,
            );
          },
        ),
      ),
    );
  }

  Future<void> _delete(
    NotificationsInboxData data,
    SiteNotification notification,
  ) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete notification?'),
        content: Text(
          '${notification.displayTitle} will be removed from your inbox.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(context, true),
            style: FilledButton.styleFrom(backgroundColor: AppTheme.danger),
            child: const Text('Delete'),
          ),
        ],
      ),
    );
    if (confirmed != true || !mounted) return;
    final deleted = await ref
        .read(notificationsActionControllerProvider.notifier)
        .deleteNotification(notification.id);
    if (deleted && mounted) context.go('/notifications');
  }
}

class _NotificationDetailBody extends StatelessWidget {
  const _NotificationDetailBody({
    required this.data,
    required this.notification,
    required this.onDelete,
  });

  final NotificationsInboxData data;
  final SiteNotification notification;
  final VoidCallback? onDelete;

  @override
  Widget build(BuildContext context) {
    final tone = notificationTone(notification.type);
    final destination = data.destinationFor(notification);
    return ListView(
      padding: const EdgeInsets.fromLTRB(20, 6, 20, 120),
      children: [
        Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 900),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Container(
                  padding: const EdgeInsets.all(28),
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(32),
                    gradient: const LinearGradient(
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                      colors: [Color(0xFF071326), Color(0xFF0F3568)],
                    ),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Container(
                            width: 52,
                            height: 52,
                            decoration: BoxDecoration(
                              color: Colors.white.withValues(alpha: .1),
                              borderRadius: BorderRadius.circular(18),
                            ),
                            child: Icon(
                              notificationIcon(notification.type),
                              color: Colors.white,
                              size: 23,
                            ),
                          ),
                          const SizedBox(width: 12),
                          StatusBadge(
                            label: notification.priority.label,
                            tone: notification.needsAttention
                                ? AppTheme.orange
                                : tone,
                          ),
                          const Spacer(),
                          if (notification.isBroadcast)
                            const Icon(
                              Icons.groups_2_outlined,
                              color: Colors.white70,
                            ),
                        ],
                      ),
                      const SizedBox(height: 24),
                      Text(
                        notification.displayTitle,
                        style: Theme.of(context).textTheme.headlineSmall
                            ?.copyWith(
                              color: Colors.white,
                              fontWeight: FontWeight.w800,
                              letterSpacing: -.8,
                            ),
                      ),
                      const SizedBox(height: 10),
                      Text(
                        notification.displayMessage,
                        style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                          color: Colors.white.withValues(alpha: .78),
                          height: 1.55,
                        ),
                      ),
                      const SizedBox(height: 18),
                      Text(
                        '${notification.type.label}  •  ${relativeNotificationTime(notification.createdAt)}',
                        style: Theme.of(context).textTheme.labelSmall?.copyWith(
                          color: Colors.white60,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ],
                  ),
                ).animate().fadeIn(duration: 320.ms).slideY(begin: .06, end: 0),
                const SizedBox(height: 16),
                SurfaceCard(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Record context',
                        style: Theme.of(context).textTheme.titleMedium
                            ?.copyWith(fontWeight: FontWeight.w800),
                      ),
                      const SizedBox(height: 14),
                      _DetailRow(label: 'Type', value: notification.type.label),
                      _DetailRow(
                        label: 'Priority',
                        value: notification.priority.label,
                      ),
                      _DetailRow(
                        label: 'Audience',
                        value: notification.isBroadcast
                            ? 'Company-wide'
                            : 'Your account',
                      ),
                      _DetailRow(
                        label: 'Created',
                        value: appDate(notification.createdAt),
                      ),
                      _DetailRow(
                        label: 'Site ID',
                        value: notification.siteId ?? 'Not linked',
                      ),
                      _DetailRow(
                        label: 'Record ID',
                        value: notification.id,
                        last: true,
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 16),
                if (destination != null)
                  FilledButton.icon(
                    onPressed: () => context.go(destination),
                    icon: const Icon(Icons.arrow_forward_rounded),
                    label: Text(_actionLabel(notification.type)),
                  ),
                if (onDelete != null) ...[
                  const SizedBox(height: 10),
                  OutlinedButton.icon(
                    onPressed: data.isOffline ? null : onDelete,
                    icon: const Icon(Icons.delete_outline_rounded),
                    label: const Text('Delete from my inbox'),
                    style: OutlinedButton.styleFrom(
                      foregroundColor: AppTheme.danger,
                    ),
                  ),
                ],
                if (notification.isBroadcast) ...[
                  const SizedBox(height: 14),
                  Text(
                    'Company-wide alerts are shared operational records and cannot be deleted from a personal inbox.',
                    style: Theme.of(context).textTheme.bodySmall?.copyWith(
                      color: AppTheme.muted,
                      height: 1.45,
                    ),
                  ),
                ],
              ],
            ),
          ),
        ),
      ],
    );
  }

  String _actionLabel(SiteNotificationType type) => switch (type) {
    SiteNotificationType.site || SiteNotificationType.task => 'Open project',
    SiteNotificationType.payment => 'Open payments',
    SiteNotificationType.material => 'Open stock control',
    SiteNotificationType.attendance => 'Open attendance',
    SiteNotificationType.labour => 'Open workforce',
    SiteNotificationType.wallet => 'Open AI Studio',
    SiteNotificationType.subscription => 'Open subscription',
    SiteNotificationType.system ||
    SiteNotificationType.info ||
    SiteNotificationType.unknown => 'Open related workspace',
  };
}

class _DetailRow extends StatelessWidget {
  const _DetailRow({
    required this.label,
    required this.value,
    this.last = false,
  });
  final String label;
  final String value;
  final bool last;

  @override
  Widget build(BuildContext context) => Container(
    padding: const EdgeInsets.symmetric(vertical: 12),
    decoration: BoxDecoration(
      border: last
          ? null
          : const Border(bottom: BorderSide(color: AppTheme.line)),
    ),
    child: Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        SizedBox(
          width: 92,
          child: Text(
            label,
            style: Theme.of(
              context,
            ).textTheme.bodySmall?.copyWith(color: AppTheme.muted),
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: SelectableText(
            value,
            textAlign: TextAlign.right,
            style: Theme.of(
              context,
            ).textTheme.bodySmall?.copyWith(fontWeight: FontWeight.w700),
          ),
        ),
      ],
    ),
  );
}

class _MissingNotification extends StatelessWidget {
  const _MissingNotification();
  @override
  Widget build(BuildContext context) => ListView(
    padding: const EdgeInsets.fromLTRB(20, 6, 20, 120),
    children: const [
      EmptyPanel(
        title: 'Notification not found',
        message: 'This notification is no longer available to your account.',
        icon: Icons.notifications_off_outlined,
      ),
    ],
  );
}
