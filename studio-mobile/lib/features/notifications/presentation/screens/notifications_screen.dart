import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/theme/app_theme.dart';
import '../../../../core/widgets/app_ui.dart';
import '../../models/notification_models.dart';
import '../../providers/notifications_provider.dart';
import '../widgets/notifications_widgets.dart';

class NotificationsScreen extends ConsumerWidget {
  const NotificationsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    ref.listen<SiteNotification?>(notificationRealtimeEventProvider, (
      previous,
      next,
    ) {
      if (next == null || previous?.id == next.id) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('New update: ${next.displayTitle}')),
      );
    });
    final inbox = ref.watch(notificationsInboxControllerProvider);
    final data = inbox.valueOrNull;
    final action = ref.watch(notificationsActionControllerProvider);
    return Material(
      color: Theme.of(context).scaffoldBackgroundColor,
      child: SafeArea(
        bottom: false,
        child: Column(
          children: [
            _NotificationsHeader(
              unreadCount: data?.serverUnreadCount ?? 0,
              busy: action.isLoading,
              realtimeStatus: ref.watch(notificationRealtimeStatusProvider),
              onRefresh: () => _refresh(context, ref),
              onMarkAll:
                  data?.canMutate == true && (data?.serverUnreadCount ?? 0) > 0
                  ? () => _markAll(context, ref)
                  : null,
            ),
            Expanded(
              child: inbox.when(
                loading: () => const NotificationsLoadingView(),
                error: (error, _) => _NotificationsError(
                  error: error,
                  onRetry: () => ref
                      .read(notificationsInboxControllerProvider.notifier)
                      .load(),
                ),
                data: (data) => _NotificationsInbox(data: data),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _refresh(BuildContext context, WidgetRef ref) async {
    try {
      await ref.read(notificationsInboxControllerProvider.notifier).refresh();
      ref.invalidate(notificationUnreadCountProvider);
    } catch (error) {
      if (context.mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('$error')));
      }
    }
  }

  Future<void> _markAll(BuildContext context, WidgetRef ref) async {
    final marked = await ref
        .read(notificationsActionControllerProvider.notifier)
        .markAllRead();
    if (marked && context.mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('All loaded notifications marked read.')),
      );
    }
  }
}

class _NotificationsHeader extends StatelessWidget {
  const _NotificationsHeader({
    required this.unreadCount,
    required this.busy,
    required this.realtimeStatus,
    required this.onRefresh,
    required this.onMarkAll,
  });

  final int unreadCount;
  final bool busy;
  final NotificationRealtimeStatus realtimeStatus;
  final VoidCallback onRefresh;
  final VoidCallback? onMarkAll;

  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.fromLTRB(20, 18, 20, 12),
    child: LayoutBuilder(
      builder: (context, constraints) {
        final compact = constraints.maxWidth < 560;
        final controls = [
          IconButton.filledTonal(
            tooltip: 'Refresh notifications',
            onPressed: busy ? null : onRefresh,
            icon: const Icon(Icons.refresh_rounded),
          ),
          if (onMarkAll != null) ...[
            const SizedBox(width: 8),
            if (compact)
              IconButton.filled(
                tooltip: 'Mark all read',
                onPressed: busy ? null : onMarkAll,
                icon: const Icon(Icons.done_all_rounded),
              )
            else
              FilledButton.icon(
                onPressed: busy ? null : onMarkAll,
                icon: const Icon(Icons.done_all_rounded),
                label: Text('Mark $unreadCount read'),
                style: FilledButton.styleFrom(minimumSize: const Size(0, 48)),
              ),
          ],
        ];
        final heading = Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Notifications',
              style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                fontWeight: FontWeight.w800,
                letterSpacing: -.9,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              'Operational updates, exceptions and approvals.',
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
              style: Theme.of(
                context,
              ).textTheme.bodySmall?.copyWith(color: AppTheme.muted),
            ),
            const SizedBox(height: 8),
            NotificationRealtimeBadge(status: realtimeStatus),
          ],
        );
        final actionControls = Wrap(
          spacing: 8,
          runSpacing: 8,
          alignment: WrapAlignment.end,
          children: controls,
        );
        if (constraints.maxWidth < 450) {
          return Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              heading,
              const SizedBox(height: 12),
              Align(alignment: Alignment.centerRight, child: actionControls),
            ],
          );
        }
        return Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Expanded(child: heading),
            const SizedBox(width: 8),
            Flexible(fit: FlexFit.loose, child: actionControls),
          ],
        );
      },
    ),
  ).animate().fadeIn(duration: 240.ms);
}

class _NotificationsInbox extends ConsumerWidget {
  const _NotificationsInbox({required this.data});
  final NotificationsInboxData data;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final controller = ref.read(notificationsInboxControllerProvider.notifier);
    return RefreshIndicator(
      onRefresh: controller.refresh,
      child: ListView(
        physics: const AlwaysScrollableScrollPhysics(
          parent: BouncingScrollPhysics(),
        ),
        padding: const EdgeInsets.fromLTRB(20, 6, 20, 120),
        children: [
          Center(
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 1120),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  if (data.isOffline) ...[
                    const _NotificationsOfflineBanner(),
                    const SizedBox(height: 14),
                  ],
                  NotificationsHero(data: data),
                  const SizedBox(height: 18),
                  NotificationsWorkspaceTabs(
                    data: data,
                    onChanged: controller.setWorkspace,
                  ),
                  const SizedBox(height: 14),
                  _NotificationsFilters(data: data),
                  const SizedBox(height: 20),
                  if (data.groups.isEmpty)
                    EmptyPanel(
                      title: _emptyTitle(data.workspace),
                      message: _emptyMessage(data.workspace),
                      icon: data.workspace == NotificationWorkspace.attention
                          ? Icons.verified_outlined
                          : Icons.notifications_none_rounded,
                    )
                  else
                    ...data.groups.indexed.map(
                      (groupEntry) => _NotificationGroupSection(
                        group: groupEntry.$2,
                        groupIndex: groupEntry.$1,
                      ),
                    ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  String _emptyTitle(NotificationWorkspace workspace) => switch (workspace) {
    NotificationWorkspace.inbox => 'Your operations inbox is clear',
    NotificationWorkspace.unread => 'No unread updates',
    NotificationWorkspace.attention => 'No high-priority exceptions',
  };

  String _emptyMessage(NotificationWorkspace workspace) => switch (workspace) {
    NotificationWorkspace.inbox =>
      'Site, attendance, material and payment events will appear here.',
    NotificationWorkspace.unread =>
      'New operational updates will appear as they arrive from the server.',
    NotificationWorkspace.attention =>
      'High-priority construction exceptions will be collected here.',
  };
}

class _NotificationsFilters extends ConsumerWidget {
  const _NotificationsFilters({required this.data});
  final NotificationsInboxData data;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final controller = ref.read(notificationsInboxControllerProvider.notifier);
    return SurfaceCard(
      child: LayoutBuilder(
        builder: (context, constraints) {
          final fieldWidth = constraints.maxWidth >= 820
              ? (constraints.maxWidth - 24) / 3
              : constraints.maxWidth >= 560
              ? (constraints.maxWidth - 12) / 2
              : constraints.maxWidth;
          return Wrap(
            spacing: 12,
            runSpacing: 12,
            children: [
              SizedBox(
                width: fieldWidth,
                child: TextFormField(
                  key: ValueKey('notification-search-${data.workspace.name}'),
                  initialValue: data.query,
                  onChanged: controller.setQuery,
                  decoration: const InputDecoration(
                    hintText: 'Search title, message or type',
                    prefixIcon: Icon(Icons.search_rounded),
                  ),
                ),
              ),
              SizedBox(
                width: fieldWidth,
                child: DropdownButtonFormField<SiteNotificationType?>(
                  initialValue: data.typeFilter,
                  isExpanded: true,
                  decoration: const InputDecoration(labelText: 'Update type'),
                  items: [
                    const DropdownMenuItem(
                      value: null,
                      child: Text('All update types'),
                    ),
                    ...data.availableTypes.map(
                      (type) => DropdownMenuItem(
                        value: type,
                        child: Text(type.label),
                      ),
                    ),
                  ],
                  onChanged: controller.setType,
                ),
              ),
              SizedBox(
                width: fieldWidth,
                child: DropdownButtonFormField<NotificationPeriod>(
                  initialValue: data.period,
                  isExpanded: true,
                  decoration: const InputDecoration(labelText: 'Time range'),
                  items: NotificationPeriod.values
                      .map(
                        (period) => DropdownMenuItem(
                          value: period,
                          child: Text(period.label),
                        ),
                      )
                      .toList(),
                  onChanged: (value) {
                    if (value != null) controller.setPeriod(value);
                  },
                ),
              ),
            ],
          );
        },
      ),
    );
  }
}

class _NotificationGroupSection extends StatelessWidget {
  const _NotificationGroupSection({
    required this.group,
    required this.groupIndex,
  });
  final NotificationGroup group;
  final int groupIndex;

  @override
  Widget build(BuildContext context) => Padding(
    padding: EdgeInsets.only(bottom: groupIndex == 0 ? 8 : 20),
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Text(
              group.label,
              style: Theme.of(
                context,
              ).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w800),
            ),
            const SizedBox(width: 8),
            StatusBadge(label: '${group.items.length}'),
          ],
        ),
        const SizedBox(height: 12),
        ...group.items.indexed.map(
          (entry) => Padding(
            padding: const EdgeInsets.only(bottom: 10),
            child: NotificationTimelineCard(notification: entry.$2)
                .animate(
                  delay: ((groupIndex * 80) + entry.$1.clamp(0, 8) * 42).ms,
                )
                .fadeIn(duration: 220.ms)
                .slideY(begin: .05, end: 0),
          ),
        ),
      ],
    ),
  );
}

class _NotificationsOfflineBanner extends StatelessWidget {
  const _NotificationsOfflineBanner();
  @override
  Widget build(BuildContext context) => Container(
    padding: const EdgeInsets.all(14),
    decoration: BoxDecoration(
      color: AppTheme.orange.withValues(alpha: .09),
      borderRadius: BorderRadius.circular(18),
      border: Border.all(color: AppTheme.orange.withValues(alpha: .18)),
    ),
    child: Row(
      children: [
        const Icon(Icons.cloud_off_rounded, color: AppTheme.orange, size: 20),
        const SizedBox(width: 10),
        Expanded(
          child: Text(
            'Offline snapshot. Read and delete actions are disabled until reconnection.',
            style: Theme.of(
              context,
            ).textTheme.bodySmall?.copyWith(fontWeight: FontWeight.w700),
          ),
        ),
      ],
    ),
  );
}

class _NotificationsError extends StatelessWidget {
  const _NotificationsError({required this.error, required this.onRetry});
  final Object error;
  final VoidCallback onRetry;
  @override
  Widget build(BuildContext context) => ListView(
    padding: const EdgeInsets.fromLTRB(20, 8, 20, 120),
    children: [
      EmptyPanel(
        title: 'Notifications unavailable',
        message: '$error',
        icon: Icons.cloud_off_rounded,
        actionLabel: 'Reconnect',
        onAction: onRetry,
      ),
    ],
  );
}
