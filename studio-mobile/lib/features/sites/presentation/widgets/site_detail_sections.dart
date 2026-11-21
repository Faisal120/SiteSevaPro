import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/theme/app_theme.dart';
import '../../../../core/widgets/app_ui.dart';
import '../../../auth/models/auth_user.dart';
import '../../models/site_models.dart';
import '../../models/site_records.dart';
import '../../providers/sites_provider.dart';
import 'site_widgets.dart';

enum SiteWorkspaceTab {
  overview('Overview'),
  reports('Reports'),
  workforce('Workforce'),
  materials('Materials'),
  payments('Payments'),
  attendance('Attendance');

  const SiteWorkspaceTab(this.label);
  final String label;
}

List<SiteWorkspaceTab> siteTabsFor(AuthUser user) {
  if (user.isClient) {
    return const [
      SiteWorkspaceTab.overview,
      SiteWorkspaceTab.reports,
      SiteWorkspaceTab.payments,
    ];
  }
  if (user.isSupervisor) {
    return const [
      SiteWorkspaceTab.overview,
      SiteWorkspaceTab.reports,
      SiteWorkspaceTab.workforce,
      SiteWorkspaceTab.materials,
      SiteWorkspaceTab.attendance,
    ];
  }
  return SiteWorkspaceTab.values;
}

class SiteDetailHero extends StatelessWidget {
  const SiteDetailHero({super.key, required this.site});

  final SiteDetail site;

  @override
  Widget build(BuildContext context) => Hero(
    tag: 'site-cover-${site.id}',
    child: Material(
      color: Colors.transparent,
      child: Container(
        height: 286,
        clipBehavior: Clip.antiAlias,
        padding: const EdgeInsets.all(22),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(32),
          gradient: const LinearGradient(
            colors: [Color(0xFF08111F), Color(0xFF16283B), Color(0xFF733419)],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
          image: site.coverImage?.isNotEmpty == true
              ? DecorationImage(
                  image: NetworkImage(site.coverImage!),
                  fit: BoxFit.cover,
                  opacity: .38,
                )
              : null,
          boxShadow: const [
            BoxShadow(
              color: Color(0x260A0E17),
              blurRadius: 30,
              offset: Offset(0, 14),
            ),
          ],
        ),
        child: Stack(
          children: [
            const Positioned.fill(
              child: CustomPaint(painter: _DetailBlueprintPainter()),
            ),
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    _HeroStatus(status: site.status),
                    const Spacer(),
                    Text(
                      'SITE COMMAND',
                      style: Theme.of(context).textTheme.labelSmall?.copyWith(
                        color: const Color(0xFFCED6E1),
                        fontWeight: FontWeight.w800,
                        letterSpacing: .9,
                      ),
                    ),
                  ],
                ),
                const Spacer(),
                Text(
                  site.name,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                    color: Colors.white,
                    fontWeight: FontWeight.w800,
                    height: 1.08,
                    letterSpacing: -1.1,
                  ),
                ),
                const SizedBox(height: 7),
                Row(
                  children: [
                    const Icon(
                      Icons.location_on_outlined,
                      color: Color(0xFFCAD4E1),
                      size: 16,
                    ),
                    const SizedBox(width: 5),
                    Expanded(
                      child: Text(
                        site.location,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: Theme.of(context).textTheme.bodySmall?.copyWith(
                          color: const Color(0xFFCAD4E1),
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 20),
                Row(
                  children: [
                    Expanded(
                      child: ClipRRect(
                        borderRadius: BorderRadius.circular(9),
                        child: LinearProgressIndicator(
                          value: site.progress / 100,
                          minHeight: 8,
                          color: AppTheme.orangeBright,
                          backgroundColor: Colors.white.withValues(alpha: .16),
                        ),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Text(
                      '${site.progress}%',
                      style: Theme.of(context).textTheme.titleMedium?.copyWith(
                        color: Colors.white,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 17),
                Row(
                  children: [
                    Expanded(
                      child: _HeroFact(
                        label: 'STARTED',
                        value: siteDate(site.startDate),
                      ),
                    ),
                    Expanded(
                      child: _HeroFact(
                        label: 'TARGET',
                        value: siteDate(site.endDate),
                      ),
                    ),
                    Expanded(
                      child: _HeroFact(
                        label: 'FLOORS',
                        value: '${site.floors}',
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ],
        ),
      ),
    ),
  ).animate().fadeIn(duration: 300.ms).slideY(begin: .05, end: 0);
}

class SiteOverviewSection extends StatelessWidget {
  const SiteOverviewSection({
    super.key,
    required this.site,
    required this.user,
  });

  final SiteDetail site;
  final AuthUser user;

  @override
  Widget build(BuildContext context) => LayoutBuilder(
    builder: (context, constraints) {
      final wide = constraints.maxWidth >= 780;
      final project = Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _SectionHeading(
            title: 'Project overview',
            subtitle: 'Verified details from the site contract',
          ),
          const SizedBox(height: 12),
          SurfaceCard(
            child: Column(
              children: [
                if (!user.isSupervisor) ...[
                  _DetailRow(
                    icon: Icons.account_balance_wallet_outlined,
                    label: user.isClient ? 'Project value' : 'Approved budget',
                    value: compactCurrency(site.budget),
                  ),
                  const Divider(height: 26),
                ],
                _DetailRow(
                  icon: Icons.donut_large_rounded,
                  label: 'Work progress',
                  value:
                      '${site.progress}% complete · ${site.completedTasks} completed · ${site.pendingTasks} pending',
                  maxLines: 2,
                ),
                const Divider(height: 26),
                _DetailRow(
                  icon: Icons.groups_2_outlined,
                  label: 'Field team today',
                  value:
                      '${site.todayAttendance} present · ${site.labourCount} assigned labour',
                ),
                if (!user.isClient) ...[
                  const Divider(height: 26),
                  _DetailRow(
                    icon: Icons.inventory_2_outlined,
                    label: 'Material value',
                    value: compactCurrency(site.materialCost),
                  ),
                  const Divider(height: 26),
                  _DetailRow(
                    icon: Icons.account_balance_wallet_outlined,
                    label: 'Recorded site cost',
                    value: compactCurrency(site.totalCost),
                  ),
                ],
                _DetailRow(
                  icon: Icons.calendar_month_outlined,
                  label: 'Delivery window',
                  value:
                      '${siteDate(site.startDate)} to ${siteDate(site.endDate)}',
                ),
                const Divider(height: 26),
                _DetailRow(
                  icon: Icons.notes_rounded,
                  label: 'Project brief',
                  value: site.description ?? 'No project brief added',
                  maxLines: 3,
                ),
                const Divider(height: 26),
                _DetailRow(
                  icon: Icons.update_rounded,
                  label: 'Last activity',
                  value: relativeActivity(site.lastActivity),
                ),
              ],
            ),
          ),
        ],
      );
      final team = Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const _SectionHeading(
            title: 'Project team',
            subtitle: 'Assignments returned by FastAPI',
          ),
          const SizedBox(height: 12),
          SurfaceCard(
            child: Column(
              children: [
                _DetailRow(
                  icon: Icons.engineering_outlined,
                  label: 'Supervisor',
                  value: site.supervisorNames.isEmpty
                      ? 'Not assigned'
                      : site.supervisorNames.join(', '),
                ),
                const Divider(height: 26),
                _DetailRow(
                  icon: Icons.person_outline_rounded,
                  label: 'Client',
                  value: site.clientName ?? 'Not assigned',
                ),
                if (site.clientEmail != null) ...[
                  const Divider(height: 26),
                  _DetailRow(
                    icon: Icons.alternate_email_rounded,
                    label: 'Client email',
                    value: site.clientEmail!,
                  ),
                ],
              ],
            ),
          ),
          const SizedBox(height: 20),
          const _SectionHeading(
            title: 'Infrastructure',
            subtitle: 'Scope used to generate the construction task plan',
          ),
          const SizedBox(height: 12),
          SurfaceCard(
            child: Wrap(
              spacing: 8,
              runSpacing: 8,
              children: [
                _FeaturePill(label: '${site.floors} floors', enabled: true),
                _FeaturePill(label: 'Boring', enabled: site.hasBoring),
                _FeaturePill(label: 'Septic tank', enabled: site.hasSepticTank),
                _FeaturePill(label: 'Soak pit', enabled: site.hasSoakPit),
                _FeaturePill(label: 'Mumty', enabled: site.hasMumty),
              ],
            ),
          ),
        ],
      );
      if (!wide) {
        return Column(children: [project, const SizedBox(height: 24), team]);
      }
      return Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Expanded(child: project),
          const SizedBox(width: 14),
          Expanded(child: team),
        ],
      );
    },
  );
}

class SiteReportsSection extends ConsumerWidget {
  const SiteReportsSection({
    super.key,
    required this.siteId,
    required this.user,
  });

  final String siteId;
  final AuthUser user;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final reports = ref.watch(siteReportsProvider(siteId));
    return _AsyncRecords<SiteReport>(
      value: reports,
      onRetry: () => ref.invalidate(siteReportsProvider(siteId)),
      emptyTitle: 'No site reports yet',
      emptyMessage: user.isClient
          ? 'Your project team has not shared a daily report yet.'
          : 'Submit the first verified site update from the Reports workspace.',
      icon: Icons.description_outlined,
      actionLabel: user.isClient ? null : 'Open reports',
      onAction: user.isClient
          ? null
          : () => context.go('/reports?siteId=$siteId'),
      builder: (reports) => Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _SectionHeading(
            title: 'Verified reports',
            subtitle: '${reports.length} updates ordered by the backend',
            action: user.isClient ? null : 'Add report',
            onAction: user.isClient
                ? null
                : () => context.go('/reports?siteId=$siteId'),
          ),
          const SizedBox(height: 12),
          ...reports.indexed.map(
            (entry) => Padding(
              padding: const EdgeInsets.only(bottom: 10),
              child: _ReportCard(report: entry.$2)
                  .animate(delay: (entry.$1 * 45).ms)
                  .fadeIn(duration: 220.ms)
                  .slideY(begin: .05, end: 0),
            ),
          ),
        ],
      ),
    );
  }
}

class SiteWorkforceSection extends ConsumerWidget {
  const SiteWorkforceSection({super.key, required this.siteId});

  final String siteId;

  @override
  Widget build(
    BuildContext context,
    WidgetRef ref,
  ) => _AsyncRecords<SiteLabour>(
    value: ref.watch(siteLabourProvider(siteId)),
    onRetry: () => ref.invalidate(siteLabourProvider(siteId)),
    emptyTitle: 'No workforce assigned',
    emptyMessage: 'Add labour to this site from the Workforce workspace.',
    icon: Icons.groups_outlined,
    actionLabel: 'Open workforce',
    onAction: () => context.go('/labour?siteId=$siteId'),
    builder: (labour) {
      final active = labour.where((worker) => worker.active).length;
      final trades = labour.map((worker) => worker.trade).toSet().length;
      return Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const _SectionHeading(
            title: 'Site workforce',
            subtitle: 'Live labour assignments for this site',
          ),
          const SizedBox(height: 12),
          _RecordMetrics(
            items: [
              ('ACTIVE', '$active', Icons.groups_2_outlined, AppTheme.success),
              ('TRADES', '$trades', Icons.handyman_outlined, AppTheme.orange),
            ],
          ),
          const SizedBox(height: 12),
          ...labour.map(
            (worker) => Padding(
              padding: const EdgeInsets.only(bottom: 9),
              child: SurfaceCard(
                child: Row(
                  children: [
                    _RecordIcon(icon: Icons.engineering_outlined),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            worker.fullName,
                            style: Theme.of(context).textTheme.labelLarge
                                ?.copyWith(fontWeight: FontWeight.w800),
                          ),
                          const SizedBox(height: 3),
                          Text(
                            worker.trade,
                            style: Theme.of(context).textTheme.bodySmall
                                ?.copyWith(color: AppTheme.muted),
                          ),
                        ],
                      ),
                    ),
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.end,
                      children: [
                        Text(
                          compactCurrency(worker.dailyWage),
                          style: Theme.of(context).textTheme.labelSmall
                              ?.copyWith(fontWeight: FontWeight.w800),
                        ),
                        Text(
                          'daily wage',
                          style: Theme.of(context).textTheme.labelSmall
                              ?.copyWith(color: AppTheme.muted, fontSize: 9),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
          ),
        ],
      );
    },
  );
}

class SiteMaterialsSection extends ConsumerWidget {
  const SiteMaterialsSection({super.key, required this.siteId});

  final String siteId;

  @override
  Widget build(BuildContext context, WidgetRef ref) =>
      _AsyncRecords<SiteMaterial>(
        value: ref.watch(siteMaterialsProvider(siteId)),
        onRetry: () => ref.invalidate(siteMaterialsProvider(siteId)),
        emptyTitle: 'No stock records',
        emptyMessage: 'Create the first site inventory item in Stock.',
        icon: Icons.inventory_2_outlined,
        actionLabel: 'Open stock',
        onAction: () => context.go('/materials?siteId=$siteId'),
        builder: (materials) {
          final lowStock = materials.where((item) => item.isLowStock).length;
          final value = materials.fold<double>(
            0,
            (sum, item) => sum + item.stockValue,
          );
          return Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const _SectionHeading(
                title: 'Material stock',
                subtitle: 'Inventory quantities returned by FastAPI',
              ),
              const SizedBox(height: 12),
              _RecordMetrics(
                items: [
                  (
                    'STOCK VALUE',
                    compactCurrency(value),
                    Icons.inventory_2_outlined,
                    AppTheme.blue,
                  ),
                  (
                    'LOW STOCK',
                    '$lowStock',
                    Icons.warning_amber_rounded,
                    lowStock == 0 ? AppTheme.success : AppTheme.warning,
                  ),
                ],
              ),
              const SizedBox(height: 12),
              ...materials.map(
                (material) => Padding(
                  padding: const EdgeInsets.only(bottom: 9),
                  child: SurfaceCard(
                    child: Row(
                      children: [
                        _RecordIcon(
                          icon: Icons.inventory_2_outlined,
                          tone: material.isLowStock
                              ? AppTheme.warning
                              : AppTheme.blue,
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                material.name,
                                style: Theme.of(context).textTheme.labelLarge
                                    ?.copyWith(fontWeight: FontWeight.w800),
                              ),
                              const SizedBox(height: 3),
                              Text(
                                material.category,
                                style: Theme.of(context).textTheme.bodySmall
                                    ?.copyWith(color: AppTheme.muted),
                              ),
                            ],
                          ),
                        ),
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.end,
                          children: [
                            Text(
                              '${_quantity(material.stock)} ${material.unit}',
                              style: Theme.of(context).textTheme.labelLarge
                                  ?.copyWith(fontWeight: FontWeight.w800),
                            ),
                            Text(
                              material.isLowStock ? 'Low stock' : 'Available',
                              style: Theme.of(context).textTheme.labelSmall
                                  ?.copyWith(
                                    color: material.isLowStock
                                        ? AppTheme.warning
                                        : AppTheme.success,
                                    fontSize: 9,
                                    fontWeight: FontWeight.w700,
                                  ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ],
          );
        },
      );
}

class SitePaymentsSection extends ConsumerWidget {
  const SitePaymentsSection({
    super.key,
    required this.siteId,
    required this.user,
  });

  final String siteId;
  final AuthUser user;

  @override
  Widget build(
    BuildContext context,
    WidgetRef ref,
  ) => _AsyncRecords<SitePayment>(
    value: ref.watch(sitePaymentsProvider(siteId)),
    onRetry: () => ref.invalidate(sitePaymentsProvider(siteId)),
    emptyTitle: 'No payment activity',
    emptyMessage: user.isClient
        ? 'No client payment has been shared for this project.'
        : 'Record the first project transaction in Payments.',
    icon: Icons.payments_outlined,
    actionLabel: user.isClient ? null : 'Open payments',
    onAction: user.isClient
        ? null
        : () => context.go('/payments?siteId=$siteId'),
    builder: (payments) {
      final income = payments
          .where((payment) => payment.isIncome)
          .fold<double>(0, (sum, payment) => sum + payment.amount);
      final outgoing = payments
          .where((payment) => !payment.isIncome)
          .fold<double>(0, (sum, payment) => sum + payment.amount);
      return Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _SectionHeading(
            title: user.isClient ? 'Payment history' : 'Project finance',
            subtitle: user.isClient
                ? 'Client receipts visible to your role'
                : 'Income and expense records for this site',
          ),
          const SizedBox(height: 12),
          _RecordMetrics(
            items: user.isClient
                ? [
                    (
                      'PAID',
                      compactCurrency(income),
                      Icons.south_west_rounded,
                      AppTheme.success,
                    ),
                    (
                      'RECORDS',
                      '${payments.length}',
                      Icons.receipt_long_outlined,
                      AppTheme.orange,
                    ),
                  ]
                : [
                    (
                      'RECEIVED',
                      compactCurrency(income),
                      Icons.south_west_rounded,
                      AppTheme.success,
                    ),
                    (
                      'OUTGOING',
                      compactCurrency(outgoing),
                      Icons.north_east_rounded,
                      AppTheme.warning,
                    ),
                  ],
          ),
          const SizedBox(height: 12),
          ...payments.map(
            (payment) => Padding(
              padding: const EdgeInsets.only(bottom: 9),
              child: SurfaceCard(
                child: Row(
                  children: [
                    _RecordIcon(
                      icon: payment.isIncome
                          ? Icons.south_west_rounded
                          : Icons.north_east_rounded,
                      tone: payment.isIncome
                          ? AppTheme.success
                          : AppTheme.warning,
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            payment.description,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: Theme.of(context).textTheme.labelLarge
                                ?.copyWith(fontWeight: FontWeight.w800),
                          ),
                          const SizedBox(height: 3),
                          Text(
                            '${payment.type.replaceAll('_', ' ')} · ${siteDate(payment.date)}',
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: Theme.of(context).textTheme.bodySmall
                                ?.copyWith(color: AppTheme.muted),
                          ),
                        ],
                      ),
                    ),
                    Text(
                      compactCurrency(payment.amount),
                      style: Theme.of(context).textTheme.labelLarge?.copyWith(
                        color: payment.isIncome
                            ? AppTheme.success
                            : AppTheme.ink,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ],
      );
    },
  );
}

class SiteAttendanceSection extends ConsumerWidget {
  const SiteAttendanceSection({super.key, required this.siteId});

  final String siteId;

  @override
  Widget build(BuildContext context, WidgetRef ref) =>
      _AsyncRecords<SiteAttendanceDay>(
        value: ref.watch(siteAttendanceProvider(siteId)),
        onRetry: () => ref.invalidate(siteAttendanceProvider(siteId)),
        emptyTitle: 'No attendance recorded',
        emptyMessage: 'Mark the first site attendance from Field Attendance.',
        icon: Icons.how_to_reg_outlined,
        actionLabel: 'Open attendance',
        onAction: () => context.go('/attendance?siteId=$siteId'),
        builder: (days) {
          final latest = [...days]..sort((a, b) => b.date.compareTo(a.date));
          return Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const _SectionHeading(
                title: 'Attendance history',
                subtitle: 'Daily workforce presence and overtime',
              ),
              const SizedBox(height: 12),
              ...latest.map(
                (day) => Padding(
                  padding: const EdgeInsets.only(bottom: 9),
                  child: SurfaceCard(
                    child: Row(
                      children: [
                        _RecordIcon(
                          icon: Icons.calendar_month_outlined,
                          tone: AppTheme.success,
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                siteDate(day.date),
                                style: Theme.of(context).textTheme.labelLarge
                                    ?.copyWith(fontWeight: FontWeight.w800),
                              ),
                              const SizedBox(height: 3),
                              Text(
                                '${day.entries.length} attendance entries',
                                style: Theme.of(context).textTheme.bodySmall
                                    ?.copyWith(color: AppTheme.muted),
                              ),
                            ],
                          ),
                        ),
                        _AttendanceValue(
                          value: '${day.present}',
                          label: 'present',
                          tone: AppTheme.success,
                        ),
                        const SizedBox(width: 14),
                        _AttendanceValue(
                          value: '${day.absent}',
                          label: 'absent',
                          tone: AppTheme.danger,
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ],
          );
        },
      );
}

class _AsyncRecords<T> extends StatelessWidget {
  const _AsyncRecords({
    required this.value,
    required this.onRetry,
    required this.emptyTitle,
    required this.emptyMessage,
    required this.icon,
    required this.builder,
    this.actionLabel,
    this.onAction,
  });

  final AsyncValue<List<T>> value;
  final VoidCallback onRetry;
  final String emptyTitle;
  final String emptyMessage;
  final IconData icon;
  final Widget Function(List<T> records) builder;
  final String? actionLabel;
  final VoidCallback? onAction;

  @override
  Widget build(BuildContext context) => value.when(
    loading: () => const Column(
      children: [
        AppSkeleton(height: 120),
        SizedBox(height: 10),
        AppSkeleton(height: 88),
        SizedBox(height: 10),
        AppSkeleton(height: 88),
      ],
    ),
    error: (error, stackTrace) =>
        SiteRecordError(error: error, onRetry: onRetry),
    data: (records) => records.isEmpty
        ? EmptyPanel(
            title: emptyTitle,
            message: emptyMessage,
            icon: icon,
            actionLabel: actionLabel,
            onAction: onAction,
          )
        : builder(records),
  );
}

class _ReportCard extends StatelessWidget {
  const _ReportCard({required this.report});

  final SiteReport report;

  @override
  Widget build(BuildContext context) => SurfaceCard(
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            _RecordIcon(icon: Icons.description_outlined, tone: AppTheme.blue),
            const SizedBox(width: 11),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    siteDate(report.date),
                    style: Theme.of(context).textTheme.labelLarge?.copyWith(
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                  Text(
                    [
                      if (report.weather != null) report.weather!,
                      '${report.progress}% progress',
                    ].join(' · '),
                    style: Theme.of(
                      context,
                    ).textTheme.bodySmall?.copyWith(color: AppTheme.muted),
                  ),
                ],
              ),
            ),
            if (report.media.isNotEmpty)
              _CountPill(
                icon: Icons.photo_library_outlined,
                value: '${report.media.length}',
              ),
          ],
        ),
        if (report.notes != null) ...[
          const SizedBox(height: 13),
          Text(
            report.notes!,
            style: Theme.of(context).textTheme.bodySmall?.copyWith(height: 1.5),
          ),
        ],
        if (report.issues.isNotEmpty || report.completedTasks.isNotEmpty) ...[
          const SizedBox(height: 13),
          Wrap(
            spacing: 7,
            runSpacing: 7,
            children: [
              if (report.completedTasks.isNotEmpty)
                _CountPill(
                  icon: Icons.task_alt_rounded,
                  value: '${report.completedTasks.length} completed',
                  tone: AppTheme.success,
                ),
              if (report.issues.isNotEmpty)
                _CountPill(
                  icon: Icons.warning_amber_rounded,
                  value: '${report.issues.length} issues',
                  tone: AppTheme.warning,
                ),
            ],
          ),
        ],
        if (report.nextDayPlan != null) ...[
          const Divider(height: 24),
          Text(
            'NEXT DAY PLAN',
            style: Theme.of(context).textTheme.labelSmall?.copyWith(
              color: AppTheme.muted,
              fontSize: 8,
              fontWeight: FontWeight.w800,
              letterSpacing: .7,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            report.nextDayPlan!,
            style: Theme.of(context).textTheme.bodySmall,
          ),
        ],
      ],
    ),
  );
}

class _SectionHeading extends StatelessWidget {
  const _SectionHeading({
    required this.title,
    required this.subtitle,
    this.action,
    this.onAction,
  });

  final String title;
  final String subtitle;
  final String? action;
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
              style: Theme.of(context).textTheme.titleLarge?.copyWith(
                fontWeight: FontWeight.w800,
                letterSpacing: -.45,
              ),
            ),
            const SizedBox(height: 3),
            Text(
              subtitle,
              style: Theme.of(
                context,
              ).textTheme.bodySmall?.copyWith(color: AppTheme.muted),
            ),
          ],
        ),
      ),
      if (action != null) TextButton(onPressed: onAction, child: Text(action!)),
    ],
  );
}

class _DetailRow extends StatelessWidget {
  const _DetailRow({
    required this.icon,
    required this.label,
    required this.value,
    this.maxLines = 1,
  });

  final IconData icon;
  final String label;
  final String value;
  final int maxLines;

  @override
  Widget build(BuildContext context) => Row(
    crossAxisAlignment: CrossAxisAlignment.start,
    children: [
      _RecordIcon(icon: icon),
      const SizedBox(width: 11),
      Expanded(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              label.toUpperCase(),
              style: Theme.of(context).textTheme.labelSmall?.copyWith(
                color: AppTheme.muted,
                fontSize: 8,
                fontWeight: FontWeight.w800,
                letterSpacing: .7,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              value,
              maxLines: maxLines,
              overflow: TextOverflow.ellipsis,
              style: Theme.of(context).textTheme.labelMedium?.copyWith(
                fontWeight: FontWeight.w700,
                height: 1.4,
              ),
            ),
          ],
        ),
      ),
    ],
  );
}

class _RecordIcon extends StatelessWidget {
  const _RecordIcon({required this.icon, this.tone = AppTheme.orange});

  final IconData icon;
  final Color tone;

  @override
  Widget build(BuildContext context) => Container(
    width: 40,
    height: 40,
    decoration: BoxDecoration(
      color: tone.withValues(alpha: .1),
      borderRadius: BorderRadius.circular(14),
    ),
    child: Icon(icon, size: 19, color: tone),
  );
}

class _FeaturePill extends StatelessWidget {
  const _FeaturePill({required this.label, required this.enabled});

  final String label;
  final bool enabled;

  @override
  Widget build(BuildContext context) => Container(
    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
    decoration: BoxDecoration(
      color: enabled
          ? AppTheme.success.withValues(alpha: .09)
          : AppTheme.muted.withValues(alpha: .08),
      borderRadius: BorderRadius.circular(14),
      border: Border.all(
        color: enabled
            ? AppTheme.success.withValues(alpha: .18)
            : AppTheme.line,
      ),
    ),
    child: Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(
          enabled ? Icons.check_rounded : Icons.remove_rounded,
          size: 15,
          color: enabled ? AppTheme.success : AppTheme.muted,
        ),
        const SizedBox(width: 5),
        Text(
          label,
          style: Theme.of(context).textTheme.labelSmall?.copyWith(
            color: enabled ? AppTheme.ink : AppTheme.muted,
            fontWeight: FontWeight.w700,
          ),
        ),
      ],
    ),
  );
}

class _RecordMetrics extends StatelessWidget {
  const _RecordMetrics({required this.items});

  final List<(String, String, IconData, Color)> items;

  @override
  Widget build(BuildContext context) => Row(
    children: items.indexed
        .map(
          (entry) => Expanded(
            child: Padding(
              padding: EdgeInsets.only(
                right: entry.$1 == items.length - 1 ? 0 : 10,
              ),
              child: SurfaceCard(
                child: Row(
                  children: [
                    _RecordIcon(icon: entry.$2.$3, tone: entry.$2.$4),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            entry.$2.$1,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: Theme.of(context).textTheme.labelSmall
                                ?.copyWith(
                                  color: AppTheme.muted,
                                  fontSize: 8,
                                  fontWeight: FontWeight.w800,
                                  letterSpacing: .5,
                                ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            entry.$2.$2,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: Theme.of(context).textTheme.titleMedium
                                ?.copyWith(fontWeight: FontWeight.w800),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        )
        .toList(),
  );
}

class _AttendanceValue extends StatelessWidget {
  const _AttendanceValue({
    required this.value,
    required this.label,
    required this.tone,
  });

  final String value;
  final String label;
  final Color tone;

  @override
  Widget build(BuildContext context) => Column(
    crossAxisAlignment: CrossAxisAlignment.end,
    children: [
      Text(
        value,
        style: Theme.of(context).textTheme.titleMedium?.copyWith(
          color: tone,
          fontWeight: FontWeight.w800,
        ),
      ),
      Text(
        label,
        style: Theme.of(
          context,
        ).textTheme.labelSmall?.copyWith(color: AppTheme.muted, fontSize: 8),
      ),
    ],
  );
}

class _CountPill extends StatelessWidget {
  const _CountPill({
    required this.icon,
    required this.value,
    this.tone = AppTheme.blue,
  });

  final IconData icon;
  final String value;
  final Color tone;

  @override
  Widget build(BuildContext context) => Container(
    padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 6),
    decoration: BoxDecoration(
      color: tone.withValues(alpha: .09),
      borderRadius: BorderRadius.circular(12),
    ),
    child: Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(icon, size: 14, color: tone),
        const SizedBox(width: 5),
        Text(
          value,
          style: Theme.of(context).textTheme.labelSmall?.copyWith(
            color: tone,
            fontWeight: FontWeight.w700,
          ),
        ),
      ],
    ),
  );
}

class _HeroStatus extends StatelessWidget {
  const _HeroStatus({required this.status});

  final SiteStatus status;

  @override
  Widget build(BuildContext context) => Container(
    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
    decoration: BoxDecoration(
      borderRadius: BorderRadius.circular(18),
      color: const Color(0xA80A0E17),
      border: Border.all(color: siteStatusColor(status).withValues(alpha: .75)),
    ),
    child: Text(
      status.label.toUpperCase(),
      style: Theme.of(context).textTheme.labelSmall?.copyWith(
        color: Colors.white,
        fontSize: 9,
        fontWeight: FontWeight.w800,
        letterSpacing: .5,
      ),
    ),
  );
}

class _HeroFact extends StatelessWidget {
  const _HeroFact({required this.label, required this.value});

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) => Column(
    crossAxisAlignment: CrossAxisAlignment.start,
    children: [
      Text(
        label,
        style: Theme.of(context).textTheme.labelSmall?.copyWith(
          color: const Color(0xFFAEBAC9),
          fontSize: 8,
          fontWeight: FontWeight.w800,
          letterSpacing: .65,
        ),
      ),
      const SizedBox(height: 3),
      Text(
        value,
        maxLines: 1,
        overflow: TextOverflow.ellipsis,
        style: Theme.of(context).textTheme.labelSmall?.copyWith(
          color: Colors.white,
          fontWeight: FontWeight.w700,
        ),
      ),
    ],
  );
}

class _DetailBlueprintPainter extends CustomPainter {
  const _DetailBlueprintPainter();

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = Colors.white.withValues(alpha: .035)
      ..strokeWidth = 1;
    for (double x = 0; x < size.width; x += 36) {
      canvas.drawLine(Offset(x, 0), Offset(x, size.height), paint);
    }
    for (double y = 0; y < size.height; y += 36) {
      canvas.drawLine(Offset(0, y), Offset(size.width, y), paint);
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

String _quantity(double value) => value == value.roundToDouble()
    ? value.toStringAsFixed(0)
    : value.toStringAsFixed(2);
