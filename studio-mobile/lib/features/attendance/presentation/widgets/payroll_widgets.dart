import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';

import '../../../../core/theme/app_theme.dart';
import '../../../../core/utils/app_formatters.dart';
import '../../../../core/widgets/app_ui.dart';
import '../../models/workforce_models.dart';

class PayrollHero extends StatelessWidget {
  const PayrollHero({super.key, required this.data});
  final PayrollData data;

  @override
  Widget build(BuildContext context) => Container(
    constraints: const BoxConstraints(minHeight: 210),
    clipBehavior: Clip.antiAlias,
    padding: const EdgeInsets.all(24),
    decoration: BoxDecoration(
      borderRadius: BorderRadius.circular(32),
      gradient: const LinearGradient(
        colors: [Color(0xFF081321), Color(0xFF17314E), Color(0xFF12477F)],
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
    child: LayoutBuilder(
      builder: (context, constraints) {
        final compact = constraints.maxWidth < 720;
        final identity = Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Row(
              children: [
                Icon(
                  Icons.account_balance_wallet_outlined,
                  color: AppTheme.blueBright,
                  size: 18,
                ),
                SizedBox(width: 8),
                Expanded(
                  child: Text(
                    'MONTHLY PAYROLL SNAPSHOT',
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
              payrollMonthLabel(data.month),
              style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                color: Colors.white,
                fontWeight: FontWeight.w800,
                letterSpacing: -.9,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              '${data.records.length} generated payroll records from the live workforce ledger.',
              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                color: const Color(0xFFBFCBDC),
                height: 1.45,
              ),
            ),
          ],
        );
        final metrics = _PayrollMetrics(data: data);
        if (compact) {
          return Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [identity, const SizedBox(height: 22), metrics],
          );
        }
        return Row(
          children: [
            Expanded(flex: 3, child: identity),
            const SizedBox(width: 28),
            Expanded(flex: 2, child: metrics),
          ],
        );
      },
    ),
  ).animate().fadeIn(duration: 320.ms).slideY(begin: .04, end: 0);
}

class _PayrollMetrics extends StatelessWidget {
  const _PayrollMetrics({required this.data});
  final PayrollData data;

  @override
  Widget build(BuildContext context) => Container(
    padding: const EdgeInsets.symmetric(horizontal: 13, vertical: 18),
    decoration: BoxDecoration(
      color: Colors.white.withValues(alpha: .075),
      borderRadius: BorderRadius.circular(24),
      border: Border.all(color: Colors.white.withValues(alpha: .12)),
    ),
    child: Row(
      children: [
        _HeroMetric(
          value: compactInr(data.totalEarned).replaceFirst('INR ', ''),
          label: 'Earned',
        ),
        const _MetricDivider(),
        _HeroMetric(
          value: compactInr(data.totalPaid).replaceFirst('INR ', ''),
          label: 'Paid',
        ),
        const _MetricDivider(),
        _HeroMetric(
          value: compactInr(data.totalBalance).replaceFirst('INR ', ''),
          label: 'Balance',
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

class PayrollRecordGrid extends StatelessWidget {
  const PayrollRecordGrid({super.key, required this.records});
  final List<PayrollRecord> records;

  @override
  Widget build(BuildContext context) {
    if (records.isEmpty) {
      return const EmptyPanel(
        title: 'No payroll generated',
        message:
            'Generate a server payroll snapshot for each workforce member below.',
        icon: Icons.payments_outlined,
      );
    }
    return LayoutBuilder(
      builder: (context, constraints) {
        final columns = constraints.maxWidth >= 980
            ? 3
            : constraints.maxWidth >= 640
            ? 2
            : 1;
        const gap = 12.0;
        final width = (constraints.maxWidth - gap * (columns - 1)) / columns;
        return Wrap(
          spacing: gap,
          runSpacing: gap,
          children: records.indexed.map((indexed) {
            final record = indexed.$2;
            return SizedBox(
              width: width,
              height: 224,
              child: PayrollRecordCard(record: record)
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

class PayrollRecordCard extends StatelessWidget {
  const PayrollRecordCard({super.key, required this.record});
  final PayrollRecord record;

  @override
  Widget build(BuildContext context) => SurfaceCard(
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Container(
              width: 44,
              height: 44,
              decoration: BoxDecoration(
                color: AppTheme.orange.withValues(alpha: .1),
                borderRadius: BorderRadius.circular(15),
              ),
              child: const Icon(
                Icons.receipt_long_outlined,
                color: AppTheme.orange,
                size: 20,
              ),
            ),
            const SizedBox(width: 11),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    record.labourName,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: Theme.of(context).textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.w800,
                      letterSpacing: -.3,
                    ),
                  ),
                  const SizedBox(height: 3),
                  Text(
                    payrollMonthLabel(record.month),
                    style: Theme.of(
                      context,
                    ).textTheme.labelSmall?.copyWith(color: AppTheme.muted),
                  ),
                ],
              ),
            ),
            const StatusBadge(label: 'Generated', tone: AppTheme.success),
          ],
        ),
        const SizedBox(height: 17),
        Row(
          children: [
            Expanded(
              child: _RecordMetric(
                label: 'EARNED',
                value: compactInr(record.earned),
              ),
            ),
            Expanded(
              child: _RecordMetric(
                label: 'PAID',
                value: compactInr(record.paid),
              ),
            ),
            Expanded(
              child: _RecordMetric(
                label: 'ADVANCE',
                value: compactInr(record.advance),
              ),
            ),
          ],
        ),
        const Spacer(),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
          decoration: BoxDecoration(
            color: AppTheme.orange.withValues(alpha: .07),
            borderRadius: BorderRadius.circular(14),
          ),
          child: Row(
            children: [
              Text(
                'PAYABLE BALANCE',
                style: Theme.of(context).textTheme.labelSmall?.copyWith(
                  color: AppTheme.muted,
                  fontSize: 8,
                  fontWeight: FontWeight.w700,
                  letterSpacing: .4,
                ),
              ),
              const Spacer(),
              Text(
                compactInr(record.balance),
                style: Theme.of(context).textTheme.labelLarge?.copyWith(
                  color: AppTheme.orange,
                  fontWeight: FontWeight.w800,
                ),
              ),
            ],
          ),
        ),
      ],
    ),
  );
}

class _RecordMetric extends StatelessWidget {
  const _RecordMetric({required this.label, required this.value});
  final String label;
  final String value;

  @override
  Widget build(BuildContext context) => Column(
    crossAxisAlignment: CrossAxisAlignment.start,
    children: [
      Text(
        value,
        maxLines: 1,
        overflow: TextOverflow.ellipsis,
        style: Theme.of(
          context,
        ).textTheme.labelMedium?.copyWith(fontWeight: FontWeight.w800),
      ),
      const SizedBox(height: 3),
      Text(
        label,
        style: Theme.of(context).textTheme.labelSmall?.copyWith(
          color: AppTheme.muted,
          fontSize: 8,
          fontWeight: FontWeight.w700,
        ),
      ),
    ],
  );
}

class PayrollGenerationQueue extends StatelessWidget {
  const PayrollGenerationQueue({
    super.key,
    required this.members,
    required this.generatedIds,
    required this.busy,
    required this.onGenerate,
  });
  final List<WorkforceMember> members;
  final Set<String> generatedIds;
  final bool busy;
  final ValueChanged<WorkforceMember> onGenerate;

  @override
  Widget build(BuildContext context) {
    if (members.isEmpty) {
      return const EmptyPanel(
        title: 'No workforce profiles',
        message: 'Create workforce profiles before generating payroll.',
        icon: Icons.groups_outlined,
      );
    }
    return SurfaceCard(
      padding: EdgeInsets.zero,
      child: Column(
        children: members.indexed.map((indexed) {
          final member = indexed.$2;
          final generated = generatedIds.contains(member.id);
          return Container(
            padding: const EdgeInsets.symmetric(horizontal: 17, vertical: 13),
            decoration: BoxDecoration(
              border: indexed.$1 == members.length - 1
                  ? null
                  : const Border(bottom: BorderSide(color: AppTheme.line)),
            ),
            child: Row(
              children: [
                Container(
                  width: 39,
                  height: 39,
                  decoration: BoxDecoration(
                    color: (generated ? AppTheme.success : AppTheme.blue)
                        .withValues(alpha: .09),
                    borderRadius: BorderRadius.circular(13),
                  ),
                  alignment: Alignment.center,
                  child: Text(
                    member.initials,
                    style: Theme.of(context).textTheme.labelSmall?.copyWith(
                      color: generated ? AppTheme.success : AppTheme.blue,
                      fontWeight: FontWeight.w800,
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
                        style: Theme.of(context).textTheme.labelLarge?.copyWith(
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                      const SizedBox(height: 3),
                      Text(
                        '${member.displayTrade}  |  ${compactInr(member.dailyWage)}/day',
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: Theme.of(
                          context,
                        ).textTheme.labelSmall?.copyWith(color: AppTheme.muted),
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 10),
                if (generated)
                  const StatusBadge(label: 'Generated', tone: AppTheme.success)
                else
                  TextButton.icon(
                    onPressed: busy ? null : () => onGenerate(member),
                    icon: const Icon(Icons.auto_graph_rounded, size: 17),
                    label: const Text('Generate'),
                  ),
              ],
            ),
          );
        }).toList(),
      ),
    );
  }
}

class PayrollScopeNotice extends StatelessWidget {
  const PayrollScopeNotice({super.key});

  @override
  Widget build(BuildContext context) => SurfaceCard(
    child: Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          width: 40,
          height: 40,
          decoration: BoxDecoration(
            color: AppTheme.warning.withValues(alpha: .1),
            borderRadius: BorderRadius.circular(13),
          ),
          child: const Icon(
            Icons.lock_clock_outlined,
            color: AppTheme.warning,
            size: 19,
          ),
        ),
        const SizedBox(width: 11),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Payroll document scope',
                style: Theme.of(
                  context,
                ).textTheme.labelLarge?.copyWith(fontWeight: FontWeight.w800),
              ),
              const SizedBox(height: 4),
              Text(
                'The backend generates monthly totals only. Review/approval, locking, payslips, signatures, bank batches, statutory deductions and PDF/Excel exports need dedicated endpoints.',
                style: Theme.of(context).textTheme.labelSmall?.copyWith(
                  color: AppTheme.muted,
                  height: 1.45,
                ),
              ),
            ],
          ),
        ),
      ],
    ),
  );
}

class PayrollOfflineBanner extends StatelessWidget {
  const PayrollOfflineBanner({super.key, required this.syncedAt});
  final DateTime syncedAt;

  @override
  Widget build(BuildContext context) => Container(
    padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
    decoration: BoxDecoration(
      color: AppTheme.warning.withValues(alpha: .1),
      borderRadius: BorderRadius.circular(16),
    ),
    child: Row(
      children: [
        const Icon(Icons.cloud_off_rounded, color: AppTheme.warning, size: 19),
        const SizedBox(width: 10),
        Expanded(
          child: Text(
            'Offline payroll cache - last synced ${appDate(syncedAt)}',
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

class PayrollSkeleton extends StatelessWidget {
  const PayrollSkeleton({super.key});

  @override
  Widget build(BuildContext context) => ListView(
    padding: const EdgeInsets.fromLTRB(18, 18, 18, 120),
    children: const [
      AppSkeleton(height: 50),
      SizedBox(height: 16),
      AppSkeleton(height: 58),
      SizedBox(height: 16),
      AppSkeleton(height: 210, radius: 32),
      SizedBox(height: 18),
      AppSkeleton(height: 224),
    ],
  );
}

String payrollMonthLabel(String month) {
  final date = DateTime.tryParse('$month-01');
  if (date == null) return month;
  const months = [
    'January',
    'February',
    'March',
    'April',
    'May',
    'June',
    'July',
    'August',
    'September',
    'October',
    'November',
    'December',
  ];
  return '${months[date.month - 1]} ${date.year}';
}
