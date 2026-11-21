import 'dart:math' as math;

import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/theme/app_theme.dart';
import '../../../../core/utils/app_formatters.dart';
import '../../../../core/widgets/app_ui.dart';
import '../../models/finance_models.dart';

class FinanceHero extends StatelessWidget {
  const FinanceHero({super.key, required this.data});
  final FinanceStudioData data;

  @override
  Widget build(BuildContext context) {
    final content = switch (data.audience) {
      FinanceAudience.contractor => (
        eyebrow: 'RECORDED CASH FLOW',
        title: compactInr(data.netRecordedCashflow),
        subtitle:
            '${compactInr(data.recordedInflow)} received  |  ${compactInr(data.recordedOutflow)} paid',
        icon: Icons.account_balance_wallet_outlined,
      ),
      FinanceAudience.supervisor => (
        eyebrow: 'FIELD EXPENSE CONTROL',
        title: compactInr(data.recordedOutflow),
        subtitle:
            '${data.visibleExpenses.length} verified entries across ${data.sites.length} assigned sites',
        icon: Icons.receipt_long_rounded,
      ),
      FinanceAudience.client => (
        eyebrow: 'PAYMENTS RECEIVED',
        title: compactInr(data.recordedInflow),
        subtitle:
            '${data.visiblePayments.length} contractor-confirmed receipts in this period',
        icon: Icons.verified_rounded,
      ),
    };
    return Container(
      constraints: const BoxConstraints(minHeight: 220),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(32),
        gradient: const LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [Color(0xFF07172F), Color(0xFF0E3266), Color(0xFF1264CE)],
        ),
        boxShadow: const [
          BoxShadow(
            color: Color(0x300B56B7),
            blurRadius: 34,
            offset: Offset(0, 18),
          ),
        ],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(32),
        child: Stack(
          children: [
            const Positioned(
              right: -48,
              top: -68,
              child: _HeroOrb(size: 220, opacity: .09),
            ),
            const Positioned(
              right: 140,
              bottom: -86,
              child: _HeroOrb(size: 170, opacity: .06),
            ),
            Padding(
              padding: const EdgeInsets.all(28),
              child: LayoutBuilder(
                builder: (context, constraints) {
                  final narrow = constraints.maxWidth < 620;
                  final text = Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Container(
                            width: 8,
                            height: 8,
                            decoration: const BoxDecoration(
                              color: Color(0xFF68D89B),
                              shape: BoxShape.circle,
                            ),
                          ),
                          const SizedBox(width: 8),
                          Text(
                            content.eyebrow,
                            style: Theme.of(context).textTheme.labelSmall
                                ?.copyWith(
                                  color: Colors.white70,
                                  fontWeight: FontWeight.w800,
                                  letterSpacing: 1.3,
                                ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 16),
                      FittedBox(
                        fit: BoxFit.scaleDown,
                        alignment: Alignment.centerLeft,
                        child: Text(
                          content.title,
                          style: Theme.of(context).textTheme.displaySmall
                              ?.copyWith(
                                color: Colors.white,
                                fontWeight: FontWeight.w800,
                                letterSpacing: -2,
                              ),
                        ),
                      ),
                      const SizedBox(height: 10),
                      Text(
                        content.subtitle,
                        style: Theme.of(context).textTheme.bodySmall?.copyWith(
                          color: Colors.white70,
                          height: 1.45,
                        ),
                      ),
                      const SizedBox(height: 20),
                      _HeroPeriod(period: data.period),
                    ],
                  );
                  if (narrow) return text;
                  return Row(
                    children: [
                      Expanded(child: text),
                      Container(
                        width: 110,
                        height: 110,
                        decoration: BoxDecoration(
                          color: Colors.white.withValues(alpha: .09),
                          borderRadius: BorderRadius.circular(32),
                          border: Border.all(
                            color: Colors.white.withValues(alpha: .13),
                          ),
                        ),
                        child: Icon(
                          content.icon,
                          color: Colors.white,
                          size: 43,
                        ),
                      ),
                    ],
                  );
                },
              ),
            ),
          ],
        ),
      ),
    ).animate().fadeIn(duration: 380.ms).slideY(begin: .08, end: 0);
  }
}

class _HeroOrb extends StatelessWidget {
  const _HeroOrb({required this.size, required this.opacity});
  final double size;
  final double opacity;
  @override
  Widget build(BuildContext context) => Container(
    width: size,
    height: size,
    decoration: BoxDecoration(
      shape: BoxShape.circle,
      border: Border.all(
        color: Colors.white.withValues(alpha: opacity),
        width: 32,
      ),
    ),
  );
}

class _HeroPeriod extends StatelessWidget {
  const _HeroPeriod({required this.period});
  final FinancePeriod period;
  @override
  Widget build(BuildContext context) => Container(
    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
    decoration: BoxDecoration(
      color: Colors.white.withValues(alpha: .1),
      borderRadius: BorderRadius.circular(18),
      border: Border.all(color: Colors.white.withValues(alpha: .12)),
    ),
    child: Text(
      '${period.label}  |  Live ledger records',
      style: Theme.of(context).textTheme.labelSmall?.copyWith(
        color: Colors.white,
        fontWeight: FontWeight.w700,
      ),
    ),
  );
}

class FinanceWorkspaceTabs extends StatelessWidget {
  const FinanceWorkspaceTabs({
    super.key,
    required this.data,
    required this.onChanged,
  });
  final FinanceStudioData data;
  final ValueChanged<FinanceWorkspace> onChanged;

  @override
  Widget build(BuildContext context) => SingleChildScrollView(
    scrollDirection: Axis.horizontal,
    child: Row(
      children: data.availableWorkspaces
          .map((workspace) {
            final selected = workspace == data.workspace;
            final label = switch (workspace) {
              FinanceWorkspace.overview => 'Overview',
              FinanceWorkspace.payments =>
                data.isClient ? 'Payment history' : 'Payments',
              FinanceWorkspace.expenses => 'Field expenses',
            };
            final icon = switch (workspace) {
              FinanceWorkspace.overview => Icons.space_dashboard_outlined,
              FinanceWorkspace.payments => Icons.swap_vert_circle_outlined,
              FinanceWorkspace.expenses => Icons.receipt_long_outlined,
            };
            return Padding(
              padding: const EdgeInsets.only(right: 8),
              child: ChoiceChip(
                selected: selected,
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

class FinanceMetricGrid extends StatelessWidget {
  const FinanceMetricGrid({super.key, required this.data});
  final FinanceStudioData data;

  @override
  Widget build(BuildContext context) {
    final metrics = data.isSupervisor
        ? [
            (
              'Field spend',
              compactInr(data.recordedOutflow),
              Icons.payments_outlined,
              AppTheme.orange,
            ),
            (
              'Entries',
              '${data.visibleExpenses.length}',
              Icons.receipt_long_outlined,
              AppTheme.blue,
            ),
            (
              'Assigned sites',
              '${data.sites.length}',
              Icons.apartment_rounded,
              AppTheme.success,
            ),
          ]
        : [
            (
              'Received',
              compactInr(data.recordedInflow),
              Icons.south_west_rounded,
              AppTheme.success,
            ),
            (
              'Paid',
              compactInr(data.recordedOutflow),
              Icons.north_east_rounded,
              AppTheme.orange,
            ),
            (
              'Net recorded',
              compactInr(data.netRecordedCashflow),
              Icons.account_balance_outlined,
              AppTheme.blue,
            ),
          ];
    return LayoutBuilder(
      builder: (context, constraints) {
        final columns = constraints.maxWidth >= 880
            ? 3
            : constraints.maxWidth >= 520
            ? 2
            : 1;
        final width = (constraints.maxWidth - (columns - 1) * 12) / columns;
        return Wrap(
          spacing: 12,
          runSpacing: 12,
          children: metrics.indexed
              .map((entry) {
                final metric = entry.$2;
                return SizedBox(
                      width: width,
                      height: 132,
                      child: MetricCard(
                        label: metric.$1,
                        value: metric.$2,
                        icon: metric.$3,
                        tone: metric.$4,
                      ),
                    )
                    .animate(delay: (entry.$1 * 60).ms)
                    .fadeIn(duration: 260.ms)
                    .slideY(begin: .08, end: 0);
              })
              .toList(growable: false),
        );
      },
    );
  }
}

class CashflowChartCard extends StatelessWidget {
  const CashflowChartCard({super.key, required this.data});
  final FinanceStudioData data;

  @override
  Widget build(BuildContext context) {
    final trend = data.trend;
    final maxValue = trend.fold<double>(
      0,
      (value, point) => math.max(value, math.max(point.inflow, point.outflow)),
    );
    final maxY = maxValue <= 0 ? 1.0 : maxValue * 1.18;
    return SurfaceCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      data.isSupervisor
                          ? 'Expense velocity'
                          : 'Cash-flow activity',
                      style: Theme.of(context).textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      'Calculated from dated server ledger records.',
                      style: Theme.of(
                        context,
                      ).textTheme.bodySmall?.copyWith(color: AppTheme.muted),
                    ),
                  ],
                ),
              ),
              if (!data.isSupervisor)
                const _ChartLegend(color: AppTheme.success, label: 'Received'),
              const SizedBox(width: 12),
              const _ChartLegend(color: AppTheme.orange, label: 'Paid'),
            ],
          ),
          const SizedBox(height: 24),
          SizedBox(
            height: 240,
            child: LineChart(
              LineChartData(
                minY: 0,
                maxY: maxY,
                borderData: FlBorderData(show: false),
                gridData: FlGridData(
                  drawVerticalLine: false,
                  horizontalInterval: maxY / 4,
                  getDrawingHorizontalLine: (_) =>
                      const FlLine(color: AppTheme.line, strokeWidth: 1),
                ),
                titlesData: FlTitlesData(
                  topTitles: const AxisTitles(
                    sideTitles: SideTitles(showTitles: false),
                  ),
                  rightTitles: const AxisTitles(
                    sideTitles: SideTitles(showTitles: false),
                  ),
                  leftTitles: const AxisTitles(
                    sideTitles: SideTitles(showTitles: false),
                  ),
                  bottomTitles: AxisTitles(
                    sideTitles: SideTitles(
                      showTitles: true,
                      reservedSize: 26,
                      interval: math.max(1, (trend.length / 4).floorToDouble()),
                      getTitlesWidget: (value, meta) {
                        final index = value.round();
                        if (index < 0 || index >= trend.length) {
                          return const SizedBox.shrink();
                        }
                        final date = trend[index].date;
                        return Padding(
                          padding: const EdgeInsets.only(top: 8),
                          child: Text(
                            '${date.day}/${date.month}',
                            style: Theme.of(context).textTheme.labelSmall
                                ?.copyWith(color: AppTheme.muted),
                          ),
                        );
                      },
                    ),
                  ),
                ),
                lineTouchData: LineTouchData(
                  touchTooltipData: LineTouchTooltipData(
                    getTooltipItems: (spots) => spots
                        .map(
                          (spot) => LineTooltipItem(
                            compactInr(spot.y),
                            const TextStyle(
                              color: Colors.white,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                        )
                        .toList(),
                  ),
                ),
                lineBarsData: [
                  if (!data.isSupervisor)
                    _line(
                      trend.indexed
                          .map(
                            (entry) =>
                                FlSpot(entry.$1.toDouble(), entry.$2.inflow),
                          )
                          .toList(),
                      AppTheme.success,
                    ),
                  _line(
                    trend.indexed
                        .map(
                          (entry) =>
                              FlSpot(entry.$1.toDouble(), entry.$2.outflow),
                        )
                        .toList(),
                    AppTheme.orange,
                  ),
                ],
              ),
              duration: const Duration(milliseconds: 720),
              curve: Curves.easeOutCubic,
            ),
          ),
        ],
      ),
    );
  }

  LineChartBarData _line(List<FlSpot> spots, Color color) => LineChartBarData(
    spots: spots,
    isCurved: true,
    curveSmoothness: .22,
    color: color,
    barWidth: 3,
    dotData: const FlDotData(show: false),
    belowBarData: BarAreaData(
      show: true,
      gradient: LinearGradient(
        begin: Alignment.topCenter,
        end: Alignment.bottomCenter,
        colors: [color.withValues(alpha: .18), color.withValues(alpha: 0)],
      ),
    ),
  );
}

class _ChartLegend extends StatelessWidget {
  const _ChartLegend({required this.color, required this.label});
  final Color color;
  final String label;
  @override
  Widget build(BuildContext context) => Row(
    mainAxisSize: MainAxisSize.min,
    children: [
      Container(
        width: 8,
        height: 8,
        decoration: BoxDecoration(color: color, shape: BoxShape.circle),
      ),
      const SizedBox(width: 5),
      Text(label, style: Theme.of(context).textTheme.labelSmall),
    ],
  );
}

class ExpenseBreakdownCard extends StatelessWidget {
  const ExpenseBreakdownCard({super.key, required this.data});
  final FinanceStudioData data;

  @override
  Widget build(BuildContext context) {
    final categories = data.visibleCategorySummary;
    final total = categories.fold<double>(0, (sum, item) => sum + item.total);
    return SurfaceCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Field expense mix',
            style: Theme.of(
              context,
            ).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w800),
          ),
          const SizedBox(height: 4),
          Text(
            'Category split from verified expense entries.',
            style: Theme.of(
              context,
            ).textTheme.bodySmall?.copyWith(color: AppTheme.muted),
          ),
          const SizedBox(height: 20),
          if (categories.isEmpty)
            const EmptyPanel(
              title: 'No category spend',
              message: 'No expense entries match the current filters.',
              icon: Icons.donut_small_outlined,
            )
          else
            ...categories.take(5).map((item) {
              final share = total <= 0 ? 0.0 : item.total / total;
              return Padding(
                padding: const EdgeInsets.only(bottom: 15),
                child: Column(
                  children: [
                    Row(
                      children: [
                        Expanded(
                          child: Text(
                            item.category.label,
                            style: Theme.of(context).textTheme.labelMedium
                                ?.copyWith(fontWeight: FontWeight.w700),
                          ),
                        ),
                        Text(
                          compactInr(item.total),
                          style: Theme.of(context).textTheme.labelMedium
                              ?.copyWith(fontWeight: FontWeight.w800),
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),
                    ClipRRect(
                      borderRadius: BorderRadius.circular(8),
                      child: LinearProgressIndicator(
                        minHeight: 7,
                        value: share,
                        color: _categoryColor(item.category),
                        backgroundColor: AppTheme.line,
                      ),
                    ),
                  ],
                ),
              );
            }),
        ],
      ),
    );
  }
}

class FinanceRecordCard extends StatelessWidget {
  const FinanceRecordCard.payment({
    super.key,
    required this.payment,
    required this.siteName,
  }) : expense = null;

  const FinanceRecordCard.expense({
    super.key,
    required this.expense,
    required this.siteName,
  }) : payment = null;

  final PaymentRecord? payment;
  final ExpenseRecord? expense;
  final String siteName;

  @override
  Widget build(BuildContext context) {
    final isPayment = payment != null;
    final inflow = payment?.isInflow == true;
    final tone = isPayment && inflow ? AppTheme.success : AppTheme.orange;
    final amount = payment?.amount ?? expense!.amount;
    final title = payment?.displayDescription ?? expense!.displayDescription;
    final date = payment?.date ?? expense!.date;
    final label = payment?.type.label ?? expense!.category.label;
    final attached = payment?.hasAttachment ?? expense!.hasReceipt;
    return SurfaceCard(
      onTap: () => context.push(
        isPayment ? '/payments/${payment!.id}' : '/expenses/${expense!.id}',
      ),
      child: Row(
        children: [
          Container(
            width: 48,
            height: 48,
            decoration: BoxDecoration(
              color: tone.withValues(alpha: .11),
              borderRadius: BorderRadius.circular(16),
            ),
            child: Icon(
              inflow ? Icons.south_west_rounded : Icons.north_east_rounded,
              color: tone,
              size: 21,
            ),
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
                        title,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: Theme.of(context).textTheme.labelLarge?.copyWith(
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                    ),
                    if (attached)
                      const Padding(
                        padding: EdgeInsets.only(left: 6),
                        child: Icon(
                          Icons.attachment_rounded,
                          size: 16,
                          color: AppTheme.blue,
                        ),
                      ),
                  ],
                ),
                const SizedBox(height: 5),
                Text(
                  '$label  |  $siteName  |  ${appDate(date)}',
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: Theme.of(
                    context,
                  ).textTheme.bodySmall?.copyWith(color: AppTheme.muted),
                ),
              ],
            ),
          ),
          const SizedBox(width: 12),
          Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Text(
                '${inflow ? '+' : '-'}${compactInr(amount)}',
                style: Theme.of(context).textTheme.labelLarge?.copyWith(
                  color: tone,
                  fontWeight: FontWeight.w800,
                ),
              ),
              const SizedBox(height: 5),
              const Icon(
                Icons.chevron_right_rounded,
                size: 18,
                color: AppTheme.muted,
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class FinanceLoadingView extends StatelessWidget {
  const FinanceLoadingView({super.key});
  @override
  Widget build(BuildContext context) => ListView(
    padding: const EdgeInsets.fromLTRB(20, 10, 20, 120),
    children: const [
      AppSkeleton(height: 220, radius: 32),
      SizedBox(height: 18),
      AppSkeleton(height: 50, radius: 18),
      SizedBox(height: 18),
      AppSkeleton(height: 132),
      SizedBox(height: 12),
      AppSkeleton(height: 280),
    ],
  );
}

Color _categoryColor(ExpenseCategory category) => switch (category) {
  ExpenseCategory.fuel => const Color(0xFFF59E0B),
  ExpenseCategory.transport => const Color(0xFF2F80ED),
  ExpenseCategory.equipment => const Color(0xFF14B8A6),
  ExpenseCategory.food => const Color(0xFF8B5CF6),
  ExpenseCategory.misc || ExpenseCategory.unknown => const Color(0xFF64748B),
};
