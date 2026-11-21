import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/theme/app_theme.dart';
import '../../../../core/utils/app_formatters.dart';
import '../../../../core/widgets/app_ui.dart';
import '../../models/workforce_models.dart';

class WorkforcePortfolioHero extends StatelessWidget {
  const WorkforcePortfolioHero({
    super.key,
    required this.data,
    required this.canManage,
    required this.onCreate,
  });
  final WorkforceStudioData data;
  final bool canManage;
  final VoidCallback onCreate;

  @override
  Widget build(BuildContext context) => Container(
    constraints: const BoxConstraints(minHeight: 230),
    clipBehavior: Clip.antiAlias,
    decoration: BoxDecoration(
      borderRadius: BorderRadius.circular(32),
      gradient: const LinearGradient(
        colors: [Color(0xFF071522), Color(0xFF143A5F), Color(0xFF0B6A71)],
        begin: Alignment.topLeft,
        end: Alignment.bottomRight,
      ),
      boxShadow: const [
        BoxShadow(
          color: Color(0x240A0E17),
          blurRadius: 30,
          offset: Offset(0, 15),
        ),
      ],
    ),
    child: Stack(
      children: [
        Positioned(
          right: -56,
          bottom: -92,
          child: Container(
            width: 280,
            height: 280,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: const Color(0xFF55C4D1).withValues(alpha: .08),
              border: Border.all(
                color: Colors.white.withValues(alpha: .04),
                width: 26,
              ),
            ),
          ),
        ),
        Padding(
          padding: const EdgeInsets.all(24),
          child: LayoutBuilder(
            builder: (context, constraints) {
              final compact = constraints.maxWidth < 720;
              final content = Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Row(
                    children: [
                      Icon(
                        Icons.engineering_rounded,
                        color: Color(0xFF9DE6E9),
                        size: 18,
                      ),
                      SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          'CONNECTED FIELD WORKFORCE',
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: TextStyle(
                            color: Color(0xFFD2DEEC),
                            fontSize: 10,
                            fontWeight: FontWeight.w800,
                            letterSpacing: .8,
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 17),
                  Text(
                    'Keep every crew member wage-ready.',
                    style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                      color: Colors.white,
                      fontWeight: FontWeight.w800,
                      letterSpacing: -.9,
                      height: 1.1,
                    ),
                  ),
                  const SizedBox(height: 9),
                  Text(
                    'Project assignments, daily wage exposure and labour wallet balances from one live directory.',
                    style: Theme.of(context).textTheme.bodySmall?.copyWith(
                      color: const Color(0xFFBFCBDC),
                      height: 1.5,
                    ),
                  ),
                  if (canManage) ...[
                    const SizedBox(height: 18),
                    FilledButton.icon(
                      onPressed: onCreate,
                      icon: const Icon(Icons.person_add_alt_1_rounded),
                      label: const Text('Add workforce member'),
                      style: FilledButton.styleFrom(
                        minimumSize: const Size(0, 48),
                      ),
                    ),
                  ],
                ],
              );
              final metrics = _WorkforceHeroMetrics(data: data);
              if (compact) {
                return Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [content, const SizedBox(height: 22), metrics],
                );
              }
              return Row(
                children: [
                  Expanded(flex: 3, child: content),
                  const SizedBox(width: 28),
                  Expanded(flex: 2, child: metrics),
                ],
              );
            },
          ),
        ),
      ],
    ),
  ).animate().fadeIn(duration: 320.ms).slideY(begin: .04, end: 0);
}

class _WorkforceHeroMetrics extends StatelessWidget {
  const _WorkforceHeroMetrics({required this.data});
  final WorkforceStudioData data;

  @override
  Widget build(BuildContext context) => Container(
    padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 18),
    decoration: BoxDecoration(
      color: Colors.white.withValues(alpha: .075),
      borderRadius: BorderRadius.circular(24),
      border: Border.all(color: Colors.white.withValues(alpha: .12)),
    ),
    child: Row(
      children: [
        _HeroMetric(value: '${data.activeCount}', label: 'Active crew'),
        const _MetricDivider(),
        _HeroMetric(
          value: compactInr(data.dailyWageExposure).replaceFirst('INR ', ''),
          label: 'Daily wages',
        ),
        const _MetricDivider(),
        _HeroMetric(
          value: compactInr(
            data.walletSummary.totalBalance,
          ).replaceFirst('INR ', ''),
          label: 'Outstanding',
        ),
      ],
    ),
  );
}

class _HeroMetric extends StatelessWidget {
  const _HeroMetric({required this.value, required this.label});
  final String value;
  final String label;

  @override
  Widget build(BuildContext context) => Expanded(
    child: Column(
      children: [
        Text(
          value,
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
          style: Theme.of(context).textTheme.titleLarge?.copyWith(
            color: Colors.white,
            fontWeight: FontWeight.w800,
          ),
        ),
        const SizedBox(height: 4),
        Text(
          label.toUpperCase(),
          textAlign: TextAlign.center,
          style: Theme.of(context).textTheme.labelSmall?.copyWith(
            color: const Color(0xFFBFCBDC),
            fontSize: 8,
            fontWeight: FontWeight.w700,
            letterSpacing: .4,
          ),
        ),
      ],
    ),
  );
}

class _MetricDivider extends StatelessWidget {
  const _MetricDivider();

  @override
  Widget build(BuildContext context) => Container(
    width: 1,
    height: 38,
    color: Colors.white.withValues(alpha: .14),
  );
}

class WorkforceCapabilityGrid extends StatelessWidget {
  const WorkforceCapabilityGrid({super.key});

  @override
  Widget build(BuildContext context) {
    const capabilities = [
      (
        Icons.assignment_ind_outlined,
        'Wage-ready profiles',
        'Trade, assignment, mobile and verified daily wage',
        AppTheme.blue,
      ),
      (
        Icons.account_balance_wallet_outlined,
        'Ledger connected',
        'Attendance earnings, advances and settlements',
        AppTheme.success,
      ),
      (
        Icons.payments_outlined,
        'Monthly payroll',
        'Server-generated monthly payroll snapshots',
        AppTheme.orange,
      ),
    ];
    return LayoutBuilder(
      builder: (context, constraints) {
        final columns = constraints.maxWidth >= 900
            ? 3
            : constraints.maxWidth >= 560
            ? 2
            : 1;
        const gap = 12.0;
        final width = (constraints.maxWidth - gap * (columns - 1)) / columns;
        return Wrap(
          spacing: gap,
          runSpacing: gap,
          children: capabilities.indexed.map((entry) {
            final item = entry.$2;
            return SizedBox(
              width: width,
              height: 132,
              child:
                  SurfaceCard(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Container(
                              width: 38,
                              height: 38,
                              decoration: BoxDecoration(
                                color: item.$4.withValues(alpha: .1),
                                borderRadius: BorderRadius.circular(13),
                              ),
                              child: Icon(item.$1, color: item.$4, size: 19),
                            ),
                            const Spacer(),
                            Text(
                              item.$2,
                              style: Theme.of(context).textTheme.labelLarge
                                  ?.copyWith(fontWeight: FontWeight.w800),
                            ),
                            const SizedBox(height: 3),
                            Text(
                              item.$3,
                              maxLines: 2,
                              overflow: TextOverflow.ellipsis,
                              style: Theme.of(context).textTheme.labelSmall
                                  ?.copyWith(color: AppTheme.muted),
                            ),
                          ],
                        ),
                      )
                      .animate(delay: (entry.$1 * 50).ms)
                      .fadeIn(duration: 240.ms)
                      .slideY(begin: .05, end: 0),
            );
          }).toList(),
        );
      },
    );
  }
}

class WorkforceGrid extends StatelessWidget {
  const WorkforceGrid({
    super.key,
    required this.data,
    required this.canManage,
    required this.onDelete,
  });
  final WorkforceStudioData data;
  final bool canManage;
  final ValueChanged<WorkforceMember> onDelete;

  @override
  Widget build(BuildContext context) {
    if (data.visibleMembers.isEmpty) {
      return const EmptyPanel(
        title: 'No matching workforce',
        message: 'Clear the search or choose a different project site.',
        icon: Icons.group_off_outlined,
      );
    }
    return LayoutBuilder(
      builder: (context, constraints) {
        final columns = constraints.maxWidth >= 1040
            ? 3
            : constraints.maxWidth >= 680
            ? 2
            : 1;
        const gap = 12.0;
        final width = (constraints.maxWidth - gap * (columns - 1)) / columns;
        return Wrap(
          spacing: gap,
          runSpacing: gap,
          children: data.visibleMembers.indexed.map((indexed) {
            final member = indexed.$2;
            return SizedBox(
              width: width,
              height: 246,
              child:
                  WorkforceCard(
                        member: member,
                        siteName:
                            data.siteFor(member.siteId)?.name ??
                            'Assigned site',
                        wallet: data.walletSummary.walletFor(member.id),
                        canManage: canManage,
                        onDelete: () => onDelete(member),
                      )
                      .animate(delay: (indexed.$1 * 40).ms)
                      .fadeIn(duration: 240.ms)
                      .slideY(begin: .05, end: 0),
            );
          }).toList(),
        );
      },
    );
  }
}

class WorkforceCard extends StatelessWidget {
  const WorkforceCard({
    super.key,
    required this.member,
    required this.siteName,
    required this.wallet,
    required this.canManage,
    required this.onDelete,
  });
  final WorkforceMember member;
  final String siteName;
  final LabourWallet wallet;
  final bool canManage;
  final VoidCallback onDelete;

  @override
  Widget build(BuildContext context) => SurfaceCard(
    onTap: () => context.go('/labour/${member.id}'),
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Hero(
              tag: 'workforce-avatar-${member.id}',
              child: Container(
                width: 48,
                height: 48,
                decoration: BoxDecoration(
                  gradient: const LinearGradient(
                    colors: [Color(0xFF173A5E), Color(0xFF2B648C)],
                  ),
                  borderRadius: BorderRadius.circular(16),
                ),
                alignment: Alignment.center,
                child: Text(
                  member.initials,
                  style: Theme.of(context).textTheme.labelLarge?.copyWith(
                    color: Colors.white,
                    fontWeight: FontWeight.w800,
                  ),
                ),
              ),
            ),
            const SizedBox(width: 11),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    member.displayName,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: Theme.of(context).textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.w800,
                      letterSpacing: -.3,
                    ),
                  ),
                  const SizedBox(height: 3),
                  Text(
                    member.displayTrade,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: Theme.of(
                      context,
                    ).textTheme.labelSmall?.copyWith(color: AppTheme.muted),
                  ),
                ],
              ),
            ),
            if (canManage)
              PopupMenuButton<String>(
                tooltip: 'Workforce actions',
                onSelected: (value) {
                  if (value == 'delete') onDelete();
                },
                itemBuilder: (context) => const [
                  PopupMenuItem(value: 'delete', child: Text('Remove profile')),
                ],
                icon: const Icon(Icons.more_horiz_rounded),
              )
            else
              const Icon(Icons.chevron_right_rounded, color: AppTheme.muted),
          ],
        ),
        const SizedBox(height: 15),
        Row(
          children: [
            const Icon(
              Icons.apartment_rounded,
              color: AppTheme.muted,
              size: 15,
            ),
            const SizedBox(width: 7),
            Expanded(
              child: Text(
                siteName,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: Theme.of(
                  context,
                ).textTheme.labelSmall?.copyWith(color: AppTheme.muted),
              ),
            ),
            StatusBadge(
              label: member.active ? 'Active' : 'Inactive',
              tone: member.active ? AppTheme.success : AppTheme.muted,
            ),
          ],
        ),
        const Spacer(),
        const Divider(height: 1),
        const SizedBox(height: 14),
        Row(
          children: [
            Expanded(
              child: _CardMetric(
                label: 'DAILY WAGE',
                value: compactInr(member.dailyWage),
              ),
            ),
            Container(width: 1, height: 34, color: AppTheme.line),
            Expanded(
              child: Padding(
                padding: const EdgeInsets.only(left: 13),
                child: _CardMetric(
                  label: 'BALANCE',
                  value: compactInr(wallet.balance),
                  tone: wallet.balance > 0 ? AppTheme.orange : AppTheme.success,
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: 13),
        Row(
          children: [
            Icon(
              member.mobile == null
                  ? Icons.phone_disabled_outlined
                  : Icons.phone_outlined,
              color: AppTheme.muted,
              size: 14,
            ),
            const SizedBox(width: 6),
            Expanded(
              child: Text(
                member.mobile ?? 'Mobile not recorded',
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: Theme.of(
                  context,
                ).textTheme.labelSmall?.copyWith(color: AppTheme.muted),
              ),
            ),
          ],
        ),
      ],
    ),
  );
}

class _CardMetric extends StatelessWidget {
  const _CardMetric({
    required this.label,
    required this.value,
    this.tone = AppTheme.ink,
  });
  final String label;
  final String value;
  final Color tone;

  @override
  Widget build(BuildContext context) => Column(
    crossAxisAlignment: CrossAxisAlignment.start,
    children: [
      Text(
        value,
        maxLines: 1,
        overflow: TextOverflow.ellipsis,
        style: Theme.of(context).textTheme.labelLarge?.copyWith(
          color: tone,
          fontWeight: FontWeight.w800,
        ),
      ),
      const SizedBox(height: 3),
      Text(
        label,
        style: Theme.of(context).textTheme.labelSmall?.copyWith(
          color: AppTheme.muted,
          fontSize: 8,
          fontWeight: FontWeight.w700,
          letterSpacing: .45,
        ),
      ),
    ],
  );
}

class WorkforceOfflineBanner extends StatelessWidget {
  const WorkforceOfflineBanner({super.key, required this.syncedAt});
  final DateTime syncedAt;

  @override
  Widget build(BuildContext context) => Container(
    padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
    decoration: BoxDecoration(
      color: AppTheme.warning.withValues(alpha: .1),
      borderRadius: BorderRadius.circular(16),
      border: Border.all(color: AppTheme.warning.withValues(alpha: .25)),
    ),
    child: Row(
      children: [
        const Icon(Icons.cloud_off_rounded, color: AppTheme.warning, size: 19),
        const SizedBox(width: 10),
        Expanded(
          child: Text(
            'Offline workforce cache - last synced ${appDate(syncedAt)}',
            style: Theme.of(context).textTheme.labelSmall?.copyWith(
              color: AppTheme.warning,
              fontWeight: FontWeight.w700,
            ),
          ),
        ),
      ],
    ),
  );
}

class WorkforceSkeleton extends StatelessWidget {
  const WorkforceSkeleton({super.key});

  @override
  Widget build(BuildContext context) => ListView(
    padding: const EdgeInsets.fromLTRB(18, 18, 18, 120),
    children: const [
      AppSkeleton(height: 50),
      SizedBox(height: 16),
      AppSkeleton(height: 230, radius: 32),
      SizedBox(height: 18),
      AppSkeleton(height: 132),
      SizedBox(height: 18),
      AppSkeleton(height: 246),
    ],
  );
}
