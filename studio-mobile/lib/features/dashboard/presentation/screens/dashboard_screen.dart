import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/state/app_state.dart';
import '../../../../core/theme/app_theme.dart';
import '../../../../core/widgets/app_ui.dart';
import '../../models/dashboard_data.dart';
import '../../providers/dashboard_provider.dart';
import '../widgets/dashboard_charts.dart';
import '../widgets/dashboard_financials.dart';
import '../widgets/dashboard_primitives.dart';
import '../widgets/dashboard_sections.dart';

class DashboardScreen extends ConsumerWidget {
  const DashboardScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final user = ref.watch(authControllerProvider).valueOrNull;
    final dashboard = ref.watch(dashboardControllerProvider);
    final now = ref.watch(dashboardClockProvider).valueOrNull ?? DateTime.now();
    if (user == null) return const SizedBox.shrink();

    return Material(
      color: Theme.of(context).scaffoldBackgroundColor,
      child: SafeArea(
        bottom: false,
        child: dashboard.when(
          loading: () => const _DashboardLoading(),
          error: (error, stackTrace) => _DashboardError(
            error: error,
            onRetry: () =>
                ref.read(dashboardControllerProvider.notifier).load(),
          ),
          data: (data) => RefreshIndicator(
            color: AppTheme.orange,
            onRefresh: () =>
                ref.read(dashboardControllerProvider.notifier).refresh(),
            child: LayoutBuilder(
              builder: (context, constraints) => ListView(
                physics: const AlwaysScrollableScrollPhysics(
                  parent: BouncingScrollPhysics(),
                ),
                padding: EdgeInsets.fromLTRB(
                  constraints.maxWidth >= 900 ? 30 : 18,
                  18,
                  constraints.maxWidth >= 900 ? 30 : 18,
                  124,
                ),
                children: [
                  Center(
                    child: ConstrainedBox(
                      constraints: const BoxConstraints(maxWidth: 1280),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          DashboardHeader(
                            user: user,
                            company: data.company,
                            now: now,
                          ).animate().fadeIn(duration: 260.ms),
                          if (data.isOffline) ...[
                            const SizedBox(height: 14),
                            DashboardOfflineBanner(syncedAt: data.fetchedAt),
                          ],
                          const SizedBox(height: 20),
                          const DashboardSectionTitle(
                            title: 'Workspace',
                            subtitle: 'Your role-approved SiteSeva tools',
                          ),
                          const SizedBox(height: 11),
                          DashboardQuickActions(user: user),
                          const SizedBox(height: 24),
                          DashboardCampaignCarousel(user: user, data: data),
                          const SizedBox(height: 26),
                          if (user.isContractor) ...[
                            const DashboardSectionTitle(
                              title: 'Financial command',
                              subtitle:
                                  'Collections, costs and receivables from the live payment ledger',
                            ),
                            const SizedBox(height: 12),
                            DashboardFinancialOverview(data: data)
                                .animate()
                                .fadeIn(duration: 300.ms)
                                .slideY(begin: .06, end: 0),
                            const SizedBox(height: 26),
                          ],
                          const DashboardSectionTitle(
                            title: 'Live operations',
                            subtitle:
                                'Role-specific values calculated by FastAPI',
                          ),
                          const SizedBox(height: 12),
                          _MetricsGrid(user: user, data: data),
                          const SizedBox(height: 28),
                          const DashboardSectionTitle(
                            title: 'Portfolio intelligence',
                            subtitle:
                                'Derived only from records returned by FastAPI',
                          ),
                          const SizedBox(height: 12),
                          DashboardInsights(user: user, data: data, now: now),
                          const SizedBox(height: 30),
                          DashboardSectionTitle(
                            title: user.isClient
                                ? 'My projects'
                                : user.isSupervisor
                                ? 'Assigned sites'
                                : 'Current projects',
                            subtitle: 'Live progress from the site portfolio',
                            actionLabel: 'View all',
                            onAction: () => context.go('/sites'),
                          ),
                          const SizedBox(height: 12),
                          DashboardProjects(sites: data.sites, user: user),
                          const SizedBox(height: 30),
                          DashboardChartsSection(data: data),
                          if (data.photos.isNotEmpty) ...[
                            const SizedBox(height: 30),
                            DashboardPhotos(photos: data.photos),
                          ],
                          const SizedBox(height: 30),
                          _OperationalFeed(user: user, data: data),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _MetricsGrid extends StatelessWidget {
  const _MetricsGrid({required this.user, required this.data});

  final UserSession user;
  final DashboardData data;

  @override
  Widget build(BuildContext context) {
    final metrics = _metrics();
    return LayoutBuilder(
      builder: (context, constraints) {
        final columns = constraints.maxWidth >= 980 ? 4 : 2;
        const spacing = 10.0;
        final width =
            (constraints.maxWidth - spacing * (columns - 1)) / columns;
        return Wrap(
          spacing: spacing,
          runSpacing: spacing,
          children: metrics.indexed
              .map(
                (entry) => SizedBox(
                  width: width,
                  height: 126,
                  child:
                      DashboardMetricCard(
                            label: entry.$2.label,
                            value: entry.$2.value,
                            detail: entry.$2.detail,
                            icon: entry.$2.icon,
                            tone: entry.$2.tone,
                          )
                          .animate(delay: (entry.$1 * 55).ms)
                          .fadeIn(duration: 240.ms)
                          .slideY(begin: .08, end: 0),
                ),
              )
              .toList(),
        );
      },
    );
  }

  List<_Metric> _metrics() {
    final stats = data.stats;
    if (user.isClient) {
      return [
        _Metric(
          'My projects',
          '${stats.totalSites}',
          'Assigned to your account',
          Icons.apartment_rounded,
          AppTheme.orange,
        ),
        _Metric(
          'Active',
          '${stats.activeSites}',
          'Currently in progress',
          Icons.trending_up_rounded,
          AppTheme.success,
        ),
        _Metric(
          'Completed',
          '${stats.completedSites}',
          'Delivered projects',
          Icons.verified_outlined,
          AppTheme.blue,
        ),
        _Metric(
          'Payments',
          '${data.payments.length}',
          'Entries shared with you',
          Icons.payments_outlined,
          const Color(0xFF7C5CE7),
        ),
      ];
    }
    if (user.isSupervisor) {
      return [
        _Metric(
          'Assigned sites',
          '${stats.totalSites}',
          '${stats.activeSites} currently active',
          Icons.apartment_rounded,
          AppTheme.orange,
        ),
        _Metric(
          'Present today',
          '${data.todayPresent}',
          '${data.todayAttendance.length} attendance entries',
          Icons.how_to_reg_rounded,
          AppTheme.success,
        ),
        _Metric(
          'Open tasks',
          '${stats.pendingTasks}',
          '${stats.completedTasks} completed',
          Icons.task_alt_rounded,
          AppTheme.warning,
        ),
        _Metric(
          'Reports today',
          '${stats.todayReports}',
          'Submitted daily reports',
          Icons.description_outlined,
          AppTheme.blue,
        ),
      ];
    }
    return [
      _Metric(
        'Collected',
        formatInr(stats.totalRevenue),
        'Client payments received',
        Icons.south_west_rounded,
        AppTheme.success,
      ),
      _Metric(
        'Total spent',
        formatInr(stats.expense),
        'Labour, material and other',
        Icons.north_east_rounded,
        AppTheme.orange,
      ),
      _Metric(
        stats.netProfit < 0 ? 'Net loss' : 'Net profit',
        formatInr(stats.netProfit.abs()),
        stats.netProfit < 0
            ? 'Costs exceed collections'
            : 'After all recorded costs',
        stats.netProfit < 0
            ? Icons.trending_down_rounded
            : Icons.trending_up_rounded,
        stats.netProfit < 0 ? AppTheme.danger : AppTheme.success,
      ),
      _Metric(
        'Outstanding',
        formatInr(stats.pendingPayments),
        'Budget not yet collected',
        Icons.account_balance_wallet_outlined,
        AppTheme.blue,
      ),
      _Metric(
        'Active sites',
        '${stats.activeSites}',
        '${stats.totalSites} sites in portfolio',
        Icons.apartment_rounded,
        AppTheme.orange,
      ),
      _Metric(
        'Labour today',
        '${stats.todayLabours}',
        '${stats.labours} registered workers',
        Icons.groups_2_rounded,
        AppTheme.success,
      ),
      _Metric(
        'Pending tasks',
        '${stats.pendingTasks}',
        '${stats.completedTasks} completed',
        Icons.task_alt_rounded,
        AppTheme.warning,
      ),
      _Metric(
        'Daily reports',
        '${stats.todayReports}',
        'Submitted today',
        Icons.description_outlined,
        AppTheme.blue,
      ),
    ];
  }
}

class _OperationalFeed extends StatelessWidget {
  const _OperationalFeed({required this.user, required this.data});

  final UserSession user;
  final DashboardData data;

  @override
  Widget build(BuildContext context) => LayoutBuilder(
    builder: (context, constraints) {
      final wide = constraints.maxWidth >= 860;
      final primary = user.isClient
          ? DashboardPayments(payments: data.payments)
          : DashboardAlerts(alerts: data.alerts);
      final secondary = DashboardActivityFeed(activities: data.activities);
      if (!wide) {
        return Column(
          children: [
            primary,
            const SizedBox(height: 12),
            secondary,
            if (user.isClient) ...[
              const SizedBox(height: 12),
              DashboardAlerts(alerts: data.alerts),
            ],
          ],
        );
      }
      return Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Expanded(child: primary),
          const SizedBox(width: 12),
          Expanded(child: secondary),
          if (user.isClient) ...[
            const SizedBox(width: 12),
            Expanded(child: DashboardAlerts(alerts: data.alerts)),
          ],
        ],
      );
    },
  );
}

class _DashboardLoading extends StatelessWidget {
  const _DashboardLoading();

  @override
  Widget build(BuildContext context) => ListView(
    physics: const NeverScrollableScrollPhysics(),
    padding: const EdgeInsets.fromLTRB(18, 18, 18, 100),
    children: const [
      AppSkeleton(height: 94, radius: 26),
      SizedBox(height: 20),
      AppSkeleton(height: 102, radius: 20),
      SizedBox(height: 24),
      AppSkeleton(height: 216, radius: 30),
      SizedBox(height: 24),
      Row(
        children: [
          Expanded(child: AppSkeleton(height: 126, radius: 24)),
          SizedBox(width: 10),
          Expanded(child: AppSkeleton(height: 126, radius: 24)),
        ],
      ),
      SizedBox(height: 10),
      Row(
        children: [
          Expanded(child: AppSkeleton(height: 126, radius: 24)),
          SizedBox(width: 10),
          Expanded(child: AppSkeleton(height: 126, radius: 24)),
        ],
      ),
      SizedBox(height: 24),
      AppSkeleton(height: 272, radius: 24),
    ],
  );
}

class _DashboardError extends StatelessWidget {
  const _DashboardError({required this.error, required this.onRetry});

  final Object error;
  final VoidCallback onRetry;

  @override
  Widget build(BuildContext context) => ListView(
    physics: const AlwaysScrollableScrollPhysics(),
    padding: const EdgeInsets.all(20),
    children: [
      const SizedBox(height: 80),
      DashboardEmptyState(
        icon: Icons.cloud_off_rounded,
        title: 'Dashboard unavailable',
        message: error.toString(),
        actionLabel: 'Retry connection',
        onAction: onRetry,
      ),
    ],
  );
}

class _Metric {
  const _Metric(this.label, this.value, this.detail, this.icon, this.tone);

  final String label;
  final String value;
  final String detail;
  final IconData icon;
  final Color tone;
}
