import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/theme/app_theme.dart';
import '../../../auth/models/auth_user.dart';
import '../../../notifications/providers/notifications_provider.dart';
import '../../models/dashboard_data.dart';

class DashboardSurface extends StatelessWidget {
  const DashboardSurface({
    super.key,
    required this.child,
    this.padding = const EdgeInsets.all(18),
    this.onTap,
    this.color,
    this.radius = 24,
  });

  final Widget child;
  final EdgeInsetsGeometry padding;
  final VoidCallback? onTap;
  final Color? color;
  final double radius;

  @override
  Widget build(BuildContext context) {
    final dark = Theme.of(context).brightness == Brightness.dark;
    final borderColor = dark ? const Color(0xFF283244) : AppTheme.line;
    final decoration = BoxDecoration(
      color: color ?? Theme.of(context).cardTheme.color,
      borderRadius: BorderRadius.circular(radius),
      border: Border.all(color: borderColor),
      boxShadow: dark
          ? null
          : const [
              BoxShadow(
                color: Color(0x0C0A0E17),
                blurRadius: 26,
                offset: Offset(0, 10),
              ),
            ],
    );

    if (onTap == null) {
      return Container(padding: padding, decoration: decoration, child: child);
    }
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(radius),
        child: Ink(padding: padding, decoration: decoration, child: child),
      ),
    );
  }
}

class DashboardHeader extends ConsumerWidget {
  const DashboardHeader({
    super.key,
    required this.user,
    required this.company,
    required this.now,
  });

  final AuthUser user;
  final DashboardCompany company;
  final DateTime now;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final companyName = company.name.isNotEmpty
        ? company.name
        : user.companyName ?? 'SiteSeva Pro';
    final firstName = user.name.trim().split(' ').firstOrNull ?? '';
    final unread = ref.watch(notificationUnreadCountProvider).valueOrNull ?? 0;
    final plan = company.plan ?? user.plan;
    final location = [
      company.city,
      company.state,
    ].whereType<String>().where((value) => value.isNotEmpty).join(', ');
    return DashboardSurface(
      padding: const EdgeInsets.all(14),
      radius: 26,
      child: LayoutBuilder(
        builder: (context, constraints) {
          final compact = constraints.maxWidth < 620;
          final identity = Row(
            children: [
              _CompanyMark(company: company, fallbackName: companyName),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      _greeting(now, firstName),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: Theme.of(context).textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.w800,
                        letterSpacing: -.55,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      companyName,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: Theme.of(context).textTheme.labelSmall?.copyWith(
                        color: AppTheme.muted,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          );
          final actions = Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              _HeaderAction(
                tooltip: 'Notifications',
                icon: Icons.notifications_none_rounded,
                badge: unread,
                onTap: () => context.go('/notifications'),
              ),
              const SizedBox(width: 8),
              _ProfileButton(
                initials: _initials(user.name),
                onTap: () => context.go('/settings'),
              ),
            ],
          );
          final metadata = Wrap(
            spacing: 7,
            runSpacing: 7,
            children: [
              _HeaderMetaChip(
                icon: Icons.verified_user_outlined,
                label: user.roleLabel,
                emphasized: true,
              ),
              if (plan != null && plan.isNotEmpty)
                _HeaderMetaChip(
                  icon: Icons.workspace_premium_outlined,
                  label: plan,
                ),
              if (location.isNotEmpty)
                _HeaderMetaChip(
                  icon: Icons.location_on_outlined,
                  label: location,
                ),
              _HeaderMetaChip(
                icon: Icons.schedule_rounded,
                label: _formatDateTime(now),
              ),
            ],
          );
          if (compact) {
            return Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Row(
                  children: [
                    Expanded(child: identity),
                    const SizedBox(width: 10),
                    actions,
                  ],
                ),
                const SizedBox(height: 13),
                metadata,
              ],
            );
          }
          return Row(
            children: [
              Expanded(flex: 3, child: identity),
              const SizedBox(width: 20),
              Flexible(flex: 4, child: metadata),
              const SizedBox(width: 18),
              actions,
            ],
          );
        },
      ),
    );
  }
}

class _HeaderMetaChip extends StatelessWidget {
  const _HeaderMetaChip({
    required this.icon,
    required this.label,
    this.emphasized = false,
  });

  final IconData icon;
  final String label;
  final bool emphasized;

  @override
  Widget build(BuildContext context) {
    final dark = Theme.of(context).brightness == Brightness.dark;
    final foreground = emphasized
        ? (dark ? AppTheme.blueBright : AppTheme.blue)
        : (dark ? const Color(0xFFB4C0D3) : AppTheme.muted);
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 7),
      decoration: BoxDecoration(
        color: emphasized
            ? AppTheme.blue.withValues(alpha: dark ? .16 : .09)
            : dark
            ? const Color(0xFF182235)
            : AppTheme.canvas,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: emphasized
              ? AppTheme.blue.withValues(alpha: dark ? .3 : .16)
              : dark
              ? const Color(0xFF2B374C)
              : AppTheme.line,
        ),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 13, color: foreground),
          const SizedBox(width: 5),
          Text(
            label,
            style: Theme.of(context).textTheme.labelSmall?.copyWith(
              color: foreground,
              fontSize: 9,
              fontWeight: FontWeight.w800,
            ),
          ),
        ],
      ),
    );
  }
}

class _HeaderAction extends StatelessWidget {
  const _HeaderAction({
    required this.tooltip,
    required this.icon,
    required this.badge,
    required this.onTap,
  });

  final String tooltip;
  final IconData icon;
  final int badge;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final dark = Theme.of(context).brightness == Brightness.dark;
    return Tooltip(
      message: tooltip,
      child: Semantics(
        button: true,
        label: tooltip,
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(15),
          child: Container(
            width: 42,
            height: 42,
            alignment: Alignment.center,
            decoration: BoxDecoration(
              color: dark ? const Color(0xFF182235) : AppTheme.canvas,
              borderRadius: BorderRadius.circular(15),
              border: Border.all(
                color: dark ? const Color(0xFF2B374C) : AppTheme.line,
              ),
            ),
            child: Stack(
              clipBehavior: Clip.none,
              children: [
                Icon(icon, color: dark ? Colors.white : AppTheme.ink, size: 20),
                if (badge > 0)
                  Positioned(
                    right: -8,
                    top: -8,
                    child: Container(
                      constraints: const BoxConstraints(minWidth: 17),
                      height: 17,
                      padding: const EdgeInsets.symmetric(horizontal: 4),
                      alignment: Alignment.center,
                      decoration: BoxDecoration(
                        color: AppTheme.orange,
                        borderRadius: BorderRadius.circular(9),
                        border: Border.all(color: Colors.white, width: 1.5),
                      ),
                      child: Text(
                        badge > 99 ? '99+' : '$badge',
                        style: Theme.of(context).textTheme.labelSmall?.copyWith(
                          color: Colors.white,
                          fontSize: 8,
                          fontWeight: FontWeight.w800,
                          height: 1,
                        ),
                      ),
                    ),
                  ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _ProfileButton extends StatelessWidget {
  const _ProfileButton({required this.initials, required this.onTap});

  final String initials;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) => Semantics(
    button: true,
    label: 'Open profile',
    child: InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(15),
      child: Container(
        width: 42,
        height: 42,
        alignment: Alignment.center,
        decoration: BoxDecoration(
          gradient: const LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [Color(0xFF0A0E17), Color(0xFF174A91)],
          ),
          borderRadius: BorderRadius.circular(15),
          boxShadow: const [
            BoxShadow(
              color: Color(0x260B3A77),
              blurRadius: 14,
              offset: Offset(0, 6),
            ),
          ],
        ),
        child: Text(
          initials,
          style: Theme.of(context).textTheme.labelSmall?.copyWith(
            color: Colors.white,
            fontWeight: FontWeight.w800,
          ),
        ),
      ),
    ),
  );
}

class DashboardSectionTitle extends StatelessWidget {
  const DashboardSectionTitle({
    super.key,
    required this.title,
    this.subtitle,
    this.actionLabel,
    this.onAction,
  });

  final String title;
  final String? subtitle;
  final String? actionLabel;
  final VoidCallback? onAction;

  @override
  Widget build(BuildContext context) => Row(
    crossAxisAlignment: CrossAxisAlignment.end,
    children: [
      Expanded(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              title,
              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.w800,
                letterSpacing: -.35,
              ),
            ),
            if (subtitle != null) ...[
              const SizedBox(height: 3),
              Text(
                subtitle!,
                style: Theme.of(
                  context,
                ).textTheme.labelSmall?.copyWith(color: AppTheme.muted),
              ),
            ],
          ],
        ),
      ),
      if (actionLabel != null && onAction != null)
        TextButton.icon(
          onPressed: onAction,
          iconAlignment: IconAlignment.end,
          icon: const Icon(Icons.arrow_forward_rounded, size: 16),
          label: Text(actionLabel!),
          style: TextButton.styleFrom(
            foregroundColor: AppTheme.orange,
            textStyle: const TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w800,
            ),
          ),
        ),
    ],
  );
}

class DashboardMetricCard extends StatelessWidget {
  const DashboardMetricCard({
    super.key,
    required this.label,
    required this.value,
    required this.detail,
    required this.icon,
    required this.tone,
  });

  final String label;
  final String value;
  final String detail;
  final IconData icon;
  final Color tone;

  @override
  Widget build(BuildContext context) => DashboardSurface(
    padding: const EdgeInsets.all(16),
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Expanded(
              child: Text(
                label.toUpperCase(),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: Theme.of(context).textTheme.labelSmall?.copyWith(
                  color: AppTheme.muted,
                  fontWeight: FontWeight.w800,
                  letterSpacing: .55,
                ),
              ),
            ),
            Container(
              width: 34,
              height: 34,
              decoration: BoxDecoration(
                color: tone.withValues(alpha: .11),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Icon(icon, color: tone, size: 18),
            ),
          ],
        ),
        const Spacer(),
        Text(
          value,
          style: Theme.of(context).textTheme.headlineSmall?.copyWith(
            fontWeight: FontWeight.w800,
            letterSpacing: -.9,
          ),
        ),
        const SizedBox(height: 3),
        Text(
          detail,
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
          style: Theme.of(
            context,
          ).textTheme.labelSmall?.copyWith(color: AppTheme.muted),
        ),
      ],
    ),
  );
}

class DashboardOfflineBanner extends StatelessWidget {
  const DashboardOfflineBanner({super.key, required this.syncedAt});

  final DateTime syncedAt;

  @override
  Widget build(BuildContext context) => Container(
    width: double.infinity,
    padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 11),
    decoration: BoxDecoration(
      color: AppTheme.warning.withValues(alpha: .09),
      borderRadius: BorderRadius.circular(18),
      border: Border.all(color: AppTheme.warning.withValues(alpha: .2)),
    ),
    child: Row(
      children: [
        const Icon(Icons.cloud_off_rounded, color: AppTheme.warning, size: 18),
        const SizedBox(width: 10),
        Expanded(
          child: Text(
            'Offline view • Last synced ${formatRelativeTime(syncedAt)}',
            style: Theme.of(context).textTheme.labelSmall?.copyWith(
              color: AppTheme.warning,
              fontWeight: FontWeight.w700,
            ),
          ),
        ),
      ],
    ),
  ).animate().fadeIn(duration: 220.ms).slideY(begin: -.08, end: 0);
}

class DashboardEmptyState extends StatelessWidget {
  const DashboardEmptyState({
    super.key,
    required this.icon,
    required this.title,
    required this.message,
    this.actionLabel,
    this.onAction,
  });

  final IconData icon;
  final String title;
  final String message;
  final String? actionLabel;
  final VoidCallback? onAction;

  @override
  Widget build(BuildContext context) => DashboardSurface(
    child: Padding(
      padding: const EdgeInsets.symmetric(vertical: 14),
      child: Column(
        children: [
          Container(
            width: 48,
            height: 48,
            decoration: BoxDecoration(
              color: AppTheme.orange.withValues(alpha: .09),
              borderRadius: BorderRadius.circular(18),
            ),
            child: Icon(icon, color: AppTheme.orange),
          ),
          const SizedBox(height: 13),
          Text(
            title,
            textAlign: TextAlign.center,
            style: Theme.of(
              context,
            ).textTheme.labelLarge?.copyWith(fontWeight: FontWeight.w800),
          ),
          const SizedBox(height: 5),
          Text(
            message,
            textAlign: TextAlign.center,
            style: Theme.of(context).textTheme.bodySmall?.copyWith(
              color: AppTheme.muted,
              height: 1.45,
            ),
          ),
          if (actionLabel != null && onAction != null) ...[
            const SizedBox(height: 14),
            TextButton(onPressed: onAction, child: Text(actionLabel!)),
          ],
        ],
      ),
    ),
  );
}

class _CompanyMark extends StatelessWidget {
  const _CompanyMark({required this.company, required this.fallbackName});

  final DashboardCompany company;
  final String fallbackName;

  @override
  Widget build(BuildContext context) {
    final logoUrl = company.logoUrl;
    return Container(
      width: 48,
      height: 48,
      clipBehavior: Clip.antiAlias,
      alignment: Alignment.center,
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [Color(0xFF0A0E17), Color(0xFF11376C)],
        ),
        borderRadius: BorderRadius.circular(16),
        boxShadow: const [
          BoxShadow(
            color: Color(0x200A0E17),
            blurRadius: 14,
            offset: Offset(0, 6),
          ),
        ],
      ),
      child: logoUrl == null
          ? Text(
              fallbackName.isEmpty ? 'S' : fallbackName[0].toUpperCase(),
              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                color: Colors.white,
                fontWeight: FontWeight.w800,
              ),
            )
          : Image.network(
              logoUrl,
              fit: BoxFit.cover,
              width: 48,
              height: 48,
              errorBuilder: (context, error, stackTrace) => const Icon(
                Icons.architecture_rounded,
                color: AppTheme.orangeBright,
              ),
            ),
    );
  }
}

String formatCompactNumber(num value) {
  if (value.abs() >= 10000000) {
    return '${_trimNumber(value / 10000000)}Cr';
  }
  if (value.abs() >= 100000) return '${_trimNumber(value / 100000)}L';
  if (value.abs() >= 1000) return '${_trimNumber(value / 1000)}K';
  return value.round().toString();
}

String formatInr(num value) => '\u20B9${formatCompactNumber(value)}';

String formatFullInr(num value) {
  final isNegative = value < 0;
  final rounded = value.abs().round().toString();
  if (rounded.length <= 3) return '${isNegative ? '-' : ''}\u20B9$rounded';

  final lastThree = rounded.substring(rounded.length - 3);
  var remaining = rounded.substring(0, rounded.length - 3);
  final groups = <String>[];
  while (remaining.length > 2) {
    groups.insert(0, remaining.substring(remaining.length - 2));
    remaining = remaining.substring(0, remaining.length - 2);
  }
  if (remaining.isNotEmpty) groups.insert(0, remaining);
  return '${isNegative ? '-' : ''}\u20B9${groups.join(',')},$lastThree';
}

String formatShortDate(DateTime? date) {
  if (date == null) return '';
  const months = [
    'Jan',
    'Feb',
    'Mar',
    'Apr',
    'May',
    'Jun',
    'Jul',
    'Aug',
    'Sep',
    'Oct',
    'Nov',
    'Dec',
  ];
  return '${date.day} ${months[date.month - 1]} ${date.year}';
}

String formatRelativeTime(DateTime? date) {
  if (date == null) return 'recently';
  final difference = DateTime.now().difference(date);
  if (difference.isNegative) return formatShortDate(date);
  if (difference.inMinutes < 1) return 'just now';
  if (difference.inMinutes < 60) return '${difference.inMinutes}m ago';
  if (difference.inHours < 24) return '${difference.inHours}h ago';
  if (difference.inDays < 7) return '${difference.inDays}d ago';
  return formatShortDate(date);
}

String _trimNumber(num value) {
  final rounded = value.toStringAsFixed(value >= 10 ? 0 : 1);
  return rounded.endsWith('.0')
      ? rounded.substring(0, rounded.length - 2)
      : rounded;
}

String _greeting(DateTime now, String firstName) {
  final greeting = now.hour < 12
      ? 'Good morning'
      : now.hour < 17
      ? 'Good afternoon'
      : 'Good evening';
  return firstName.isEmpty ? greeting : '$greeting, $firstName';
}

String _formatDateTime(DateTime date) {
  const weekdays = ['Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat', 'Sun'];
  final minute = date.minute.toString().padLeft(2, '0');
  final hour = date.hour % 12 == 0 ? 12 : date.hour % 12;
  final period = date.hour < 12 ? 'AM' : 'PM';
  return '${weekdays[date.weekday - 1]}, ${date.day} • $hour:$minute $period';
}

String _initials(String name) {
  final parts = name
      .trim()
      .split(RegExp(r'\s+'))
      .where((part) => part.isNotEmpty)
      .toList();
  if (parts.isEmpty) return 'SS';
  if (parts.length == 1) return parts.first.substring(0, 1).toUpperCase();
  return '${parts.first[0]}${parts.last[0]}'.toUpperCase();
}
