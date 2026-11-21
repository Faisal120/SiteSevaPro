import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/theme/app_theme.dart';
import '../../../../core/utils/app_formatters.dart';
import '../../../../core/widgets/app_ui.dart';
import '../../models/notification_models.dart';
import '../../providers/notifications_provider.dart';

class NotificationRealtimeBadge extends StatelessWidget {
  const NotificationRealtimeBadge({super.key, required this.status});

  final NotificationRealtimeStatus status;

  @override
  Widget build(BuildContext context) {
    final tone = switch (status) {
      NotificationRealtimeStatus.connected => AppTheme.success,
      NotificationRealtimeStatus.connecting => AppTheme.blue,
      NotificationRealtimeStatus.polling => AppTheme.orange,
      NotificationRealtimeStatus.offline => AppTheme.muted,
    };
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 5),
      decoration: BoxDecoration(
        color: tone.withValues(alpha: .09),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: tone.withValues(alpha: .18)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 6,
            height: 6,
            decoration: BoxDecoration(color: tone, shape: BoxShape.circle),
          ),
          const SizedBox(width: 6),
          Text(
            status.label,
            style: Theme.of(context).textTheme.labelSmall?.copyWith(
              color: tone,
              fontWeight: FontWeight.w800,
              fontSize: 9,
            ),
          ),
        ],
      ),
    );
  }
}

class NotificationsHero extends StatelessWidget {
  const NotificationsHero({super.key, required this.data});
  final NotificationsInboxData data;

  @override
  Widget build(BuildContext context) => Container(
    constraints: const BoxConstraints(minHeight: 210),
    decoration: BoxDecoration(
      borderRadius: BorderRadius.circular(32),
      gradient: const LinearGradient(
        begin: Alignment.topLeft,
        end: Alignment.bottomRight,
        colors: [Color(0xFF071326), Color(0xFF0C2C58), Color(0xFF0F64CE)],
      ),
      boxShadow: const [
        BoxShadow(
          color: Color(0x2C0B56B7),
          blurRadius: 34,
          offset: Offset(0, 18),
        ),
      ],
    ),
    child: ClipRRect(
      borderRadius: BorderRadius.circular(32),
      child: Stack(
        children: [
          Positioned(
            right: -55,
            top: -70,
            child: Container(
              width: 220,
              height: 220,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                border: Border.all(
                  color: Colors.white.withValues(alpha: .08),
                  width: 34,
                ),
              ),
            ),
          ),
          Padding(
            padding: const EdgeInsets.all(26),
            child: LayoutBuilder(
              builder: (context, constraints) {
                final narrow = constraints.maxWidth < 620;
                final summary = Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text(
                      'OPERATIONS INBOX',
                      style: Theme.of(context).textTheme.labelSmall?.copyWith(
                        color: Colors.white70,
                        fontWeight: FontWeight.w800,
                        letterSpacing: 1.4,
                      ),
                    ),
                    const SizedBox(height: 14),
                    Text(
                      '${data.serverUnreadCount}',
                      style: Theme.of(context).textTheme.displaySmall?.copyWith(
                        color: Colors.white,
                        fontWeight: FontWeight.w800,
                        letterSpacing: -2,
                      ),
                    ),
                    const SizedBox(height: 5),
                    Text(
                      data.serverUnreadCount == 1
                          ? 'unread update needs your review'
                          : 'unread updates need your review',
                      style: Theme.of(
                        context,
                      ).textTheme.bodySmall?.copyWith(color: Colors.white70),
                    ),
                  ],
                );
                final stats = Wrap(
                  spacing: 9,
                  runSpacing: 9,
                  children: [
                    _HeroStat(
                      label: 'ATTENTION',
                      value: '${data.attentionCount}',
                      icon: Icons.priority_high_rounded,
                      tone: AppTheme.blueBright,
                    ),
                    _HeroStat(
                      label: 'COMPANY',
                      value: '${data.companyAlertCount}',
                      icon: Icons.groups_2_outlined,
                      tone: const Color(0xFF79D7FF),
                    ),
                    _HeroStat(
                      label: 'LOADED',
                      value: '${data.notifications.length}',
                      icon: Icons.inbox_outlined,
                      tone: const Color(0xFF83E6AD),
                    ),
                  ],
                );
                if (narrow) {
                  return Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [summary, const SizedBox(height: 22), stats],
                  );
                }
                return Row(
                  children: [
                    Expanded(child: summary),
                    Flexible(child: stats),
                  ],
                );
              },
            ),
          ),
        ],
      ),
    ),
  ).animate().fadeIn(duration: 360.ms).slideY(begin: .07, end: 0);
}

class _HeroStat extends StatelessWidget {
  const _HeroStat({
    required this.label,
    required this.value,
    required this.icon,
    required this.tone,
  });
  final String label;
  final String value;
  final IconData icon;
  final Color tone;

  @override
  Widget build(BuildContext context) => Container(
    width: 104,
    padding: const EdgeInsets.all(13),
    decoration: BoxDecoration(
      color: Colors.white.withValues(alpha: .09),
      borderRadius: BorderRadius.circular(20),
      border: Border.all(color: Colors.white.withValues(alpha: .1)),
    ),
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Icon(icon, size: 17, color: tone),
        const SizedBox(height: 9),
        Text(
          value,
          style: Theme.of(context).textTheme.titleLarge?.copyWith(
            color: Colors.white,
            fontWeight: FontWeight.w800,
          ),
        ),
        Text(
          label,
          style: Theme.of(context).textTheme.labelSmall?.copyWith(
            color: Colors.white60,
            fontSize: 9,
            fontWeight: FontWeight.w800,
            letterSpacing: .7,
          ),
        ),
      ],
    ),
  );
}

class NotificationsWorkspaceTabs extends StatelessWidget {
  const NotificationsWorkspaceTabs({
    super.key,
    required this.data,
    required this.onChanged,
  });

  final NotificationsInboxData data;
  final ValueChanged<NotificationWorkspace> onChanged;

  @override
  Widget build(BuildContext context) => SingleChildScrollView(
    scrollDirection: Axis.horizontal,
    child: Row(
      children: NotificationWorkspace.values
          .map((workspace) {
            final label = switch (workspace) {
              NotificationWorkspace.inbox => 'All updates',
              NotificationWorkspace.unread =>
                'Unread ${data.serverUnreadCount}',
              NotificationWorkspace.attention =>
                'Attention ${data.attentionCount}',
            };
            final icon = switch (workspace) {
              NotificationWorkspace.inbox => Icons.inbox_outlined,
              NotificationWorkspace.unread => Icons.mark_email_unread_outlined,
              NotificationWorkspace.attention => Icons.priority_high_rounded,
            };
            return Padding(
              padding: const EdgeInsets.only(right: 8),
              child: ChoiceChip(
                selected: data.workspace == workspace,
                onSelected: (_) => onChanged(workspace),
                avatar: Icon(icon, size: 17),
                label: Text(label),
              ),
            );
          })
          .toList(growable: false),
    ),
  );
}

class NotificationTimelineCard extends StatelessWidget {
  const NotificationTimelineCard({super.key, required this.notification});

  final SiteNotification notification;

  @override
  Widget build(BuildContext context) {
    final tone = notificationTone(notification.type);
    return SurfaceCard(
      onTap: () => context.push('/notifications/${notification.id}'),
      color: notification.isUnread
          ? tone.withValues(alpha: .035)
          : Theme.of(context).cardTheme.color,
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Stack(
            clipBehavior: Clip.none,
            children: [
              Container(
                width: 48,
                height: 48,
                decoration: BoxDecoration(
                  color: tone.withValues(alpha: .11),
                  borderRadius: BorderRadius.circular(16),
                ),
                child: Icon(
                  notificationIcon(notification.type),
                  color: tone,
                  size: 21,
                ),
              ),
              if (notification.isUnread)
                Positioned(
                  right: -2,
                  top: -2,
                  child: Container(
                    width: 10,
                    height: 10,
                    decoration: BoxDecoration(
                      color: notification.needsAttention
                          ? AppTheme.orange
                          : AppTheme.blue,
                      shape: BoxShape.circle,
                      border: Border.all(color: Colors.white, width: 2),
                    ),
                  ),
                ),
            ],
          ),
          const SizedBox(width: 13),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Expanded(
                      child: Text(
                        notification.displayTitle,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: Theme.of(context).textTheme.labelLarge?.copyWith(
                          fontWeight: notification.isUnread
                              ? FontWeight.w800
                              : FontWeight.w700,
                        ),
                      ),
                    ),
                    if (notification.isBroadcast) const _CompanyBadge(),
                  ],
                ),
                const SizedBox(height: 5),
                Text(
                  notification.displayMessage,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    color: AppTheme.muted,
                    height: 1.4,
                  ),
                ),
                const SizedBox(height: 9),
                Wrap(
                  spacing: 9,
                  runSpacing: 5,
                  crossAxisAlignment: WrapCrossAlignment.center,
                  children: [
                    Text(
                      notification.type.label,
                      style: Theme.of(context).textTheme.labelSmall?.copyWith(
                        color: tone,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                    Text(
                      relativeNotificationTime(notification.createdAt),
                      style: Theme.of(
                        context,
                      ).textTheme.labelSmall?.copyWith(color: AppTheme.muted),
                    ),
                    if (notification.needsAttention)
                      Text(
                        'HIGH PRIORITY',
                        style: Theme.of(context).textTheme.labelSmall?.copyWith(
                          color: AppTheme.orange,
                          fontSize: 9,
                          fontWeight: FontWeight.w800,
                          letterSpacing: .5,
                        ),
                      ),
                  ],
                ),
              ],
            ),
          ),
          const SizedBox(width: 6),
          const Padding(
            padding: EdgeInsets.only(top: 13),
            child: Icon(
              Icons.chevron_right_rounded,
              size: 20,
              color: AppTheme.muted,
            ),
          ),
        ],
      ),
    );
  }
}

class _CompanyBadge extends StatelessWidget {
  const _CompanyBadge();
  @override
  Widget build(BuildContext context) => Container(
    margin: const EdgeInsets.only(left: 7),
    padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 4),
    decoration: BoxDecoration(
      color: AppTheme.blue.withValues(alpha: .08),
      borderRadius: BorderRadius.circular(10),
    ),
    child: Text(
      'COMPANY',
      style: Theme.of(context).textTheme.labelSmall?.copyWith(
        color: AppTheme.blue,
        fontSize: 8,
        fontWeight: FontWeight.w800,
        letterSpacing: .5,
      ),
    ),
  );
}

class NotificationsLoadingView extends StatelessWidget {
  const NotificationsLoadingView({super.key});
  @override
  Widget build(BuildContext context) => ListView(
    padding: const EdgeInsets.fromLTRB(20, 8, 20, 120),
    children: const [
      AppSkeleton(height: 210, radius: 32),
      SizedBox(height: 16),
      AppSkeleton(height: 50, radius: 18),
      SizedBox(height: 14),
      AppSkeleton(height: 112),
      SizedBox(height: 10),
      AppSkeleton(height: 112),
    ],
  );
}

IconData notificationIcon(SiteNotificationType type) => switch (type) {
  SiteNotificationType.site => Icons.apartment_rounded,
  SiteNotificationType.payment => Icons.payments_outlined,
  SiteNotificationType.material => Icons.inventory_2_outlined,
  SiteNotificationType.attendance => Icons.fact_check_outlined,
  SiteNotificationType.task => Icons.task_alt_rounded,
  SiteNotificationType.labour => Icons.groups_2_outlined,
  SiteNotificationType.wallet => Icons.auto_awesome_outlined,
  SiteNotificationType.subscription => Icons.workspace_premium_outlined,
  SiteNotificationType.system => Icons.settings_suggest_outlined,
  SiteNotificationType.info => Icons.info_outline_rounded,
  SiteNotificationType.unknown => Icons.notifications_none_rounded,
};

Color notificationTone(SiteNotificationType type) => switch (type) {
  SiteNotificationType.payment => AppTheme.success,
  SiteNotificationType.material => AppTheme.orange,
  SiteNotificationType.attendance => const Color(0xFF14B8A6),
  SiteNotificationType.wallet => const Color(0xFF0EA5E9),
  SiteNotificationType.subscription => const Color(0xFFD97706),
  SiteNotificationType.task => const Color(0xFF8B5CF6),
  SiteNotificationType.labour => const Color(0xFF64748B),
  SiteNotificationType.site => AppTheme.blue,
  SiteNotificationType.system ||
  SiteNotificationType.info ||
  SiteNotificationType.unknown => AppTheme.muted,
};

String relativeNotificationTime(DateTime value, {DateTime? now}) {
  final reference = now ?? DateTime.now();
  final difference = reference.difference(value);
  if (difference.isNegative || difference.inMinutes < 1) return 'Just now';
  if (difference.inMinutes < 60) return '${difference.inMinutes}m ago';
  if (difference.inHours < 24) return '${difference.inHours}h ago';
  if (difference.inDays < 7) return '${difference.inDays}d ago';
  return appDate(value);
}
