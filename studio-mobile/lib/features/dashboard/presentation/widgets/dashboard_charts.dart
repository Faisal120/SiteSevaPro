import 'dart:math' as math;

import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';

import '../../../../core/theme/app_theme.dart';
import '../../models/dashboard_data.dart';
import 'dashboard_primitives.dart';

class DashboardChartsSection extends StatelessWidget {
  const DashboardChartsSection({super.key, required this.data});

  final DashboardData data;

  @override
  Widget build(BuildContext context) {
    final cards = <Widget>[
      if (data.projectProgress.isNotEmpty)
        _ProgressChart(points: data.projectProgress),
      if (data.charts.attendance.isNotEmpty)
        _AttendanceChart(points: data.charts.attendance),
      if (data.charts.cashflow.isNotEmpty)
        _CashflowChart(points: data.charts.cashflow),
      if (data.charts.expenseBreakdown.isNotEmpty)
        _ExpenseChart(points: data.charts.expenseBreakdown),
    ];
    if (cards.isEmpty) return const SizedBox.shrink();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const DashboardSectionTitle(
          title: 'Performance',
          subtitle: 'Visualised directly from the dashboard response',
        ),
        const SizedBox(height: 12),
        LayoutBuilder(
          builder: (context, constraints) {
            final twoColumns = constraints.maxWidth >= 860;
            final width = twoColumns
                ? (constraints.maxWidth - 12) / 2
                : constraints.maxWidth;
            return Wrap(
              spacing: 12,
              runSpacing: 12,
              children: cards.indexed
                  .map(
                    (entry) => SizedBox(
                      width: width,
                      height: 294,
                      child: entry.$2
                          .animate(delay: (entry.$1 * 70).ms)
                          .fadeIn(duration: 280.ms)
                          .slideY(begin: .05, end: 0),
                    ),
                  )
                  .toList(),
            );
          },
        ),
      ],
    );
  }
}

class _ProgressChart extends StatelessWidget {
  const _ProgressChart({required this.points});

  final List<DashboardProgressPoint> points;

  @override
  Widget build(BuildContext context) {
    final visible = points.take(7).toList();
    return _ChartCard(
      title: 'Site progress',
      subtitle: 'Completion percentage by project',
      child: BarChart(
        BarChartData(
          minY: 0,
          maxY: 100,
          alignment: BarChartAlignment.spaceAround,
          gridData: FlGridData(
            show: true,
            drawVerticalLine: false,
            horizontalInterval: 25,
            getDrawingHorizontalLine: (value) => FlLine(
              color: AppTheme.line.withValues(alpha: .8),
              strokeWidth: 1,
            ),
          ),
          borderData: FlBorderData(show: false),
          barTouchData: BarTouchData(
            touchTooltipData: BarTouchTooltipData(
              getTooltipColor: (_) => AppTheme.ink,
              getTooltipItem: (group, groupIndex, rod, rodIndex) =>
                  BarTooltipItem(
                    '${visible[group.x].name}\n${rod.toY.round()}%',
                    const TextStyle(
                      color: Colors.white,
                      fontSize: 11,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
            ),
          ),
          titlesData: FlTitlesData(
            topTitles: const AxisTitles(
              sideTitles: SideTitles(showTitles: false),
            ),
            rightTitles: const AxisTitles(
              sideTitles: SideTitles(showTitles: false),
            ),
            leftTitles: AxisTitles(
              sideTitles: SideTitles(
                showTitles: true,
                reservedSize: 30,
                interval: 25,
                getTitlesWidget: (value, meta) => Text(
                  '${value.round()}',
                  style: const TextStyle(color: AppTheme.muted, fontSize: 9),
                ),
              ),
            ),
            bottomTitles: AxisTitles(
              sideTitles: SideTitles(
                showTitles: true,
                reservedSize: 34,
                getTitlesWidget: (value, meta) {
                  final index = value.toInt();
                  if (index < 0 || index >= visible.length) {
                    return const SizedBox.shrink();
                  }
                  return Padding(
                    padding: const EdgeInsets.only(top: 8),
                    child: Text(
                      _shortLabel(visible[index].name),
                      style: const TextStyle(
                        color: AppTheme.muted,
                        fontSize: 8,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  );
                },
              ),
            ),
          ),
          barGroups: visible.indexed
              .map(
                (entry) => BarChartGroupData(
                  x: entry.$1,
                  barRods: [
                    BarChartRodData(
                      toY: entry.$2.progress,
                      width: 17,
                      color: AppTheme.orange,
                      borderRadius: const BorderRadius.vertical(
                        top: Radius.circular(6),
                      ),
                      backDrawRodData: BackgroundBarChartRodData(
                        show: true,
                        toY: 100,
                        color: AppTheme.orange.withValues(alpha: .07),
                      ),
                    ),
                  ],
                ),
              )
              .toList(),
        ),
        duration: const Duration(milliseconds: 700),
        curve: Curves.easeOutCubic,
      ),
    );
  }
}

class _AttendanceChart extends StatelessWidget {
  const _AttendanceChart({required this.points});

  final List<DashboardAttendancePoint> points;

  @override
  Widget build(BuildContext context) {
    final visible = points.length > 7
        ? points.sublist(points.length - 7)
        : points;
    final maximum = visible.fold<int>(
      0,
      (current, point) => math.max(current, point.present + point.absent),
    );
    final maxY = math.max(5, maximum).toDouble();
    return _ChartCard(
      title: 'Attendance',
      subtitle: 'Present and absent records by day',
      legend: const [
        _LegendItem('Present', AppTheme.success),
        _LegendItem('Absent', AppTheme.danger),
      ],
      child: BarChart(
        BarChartData(
          minY: 0,
          maxY: maxY,
          alignment: BarChartAlignment.spaceAround,
          gridData: FlGridData(
            show: true,
            drawVerticalLine: false,
            horizontalInterval: math.max(1, (maxY / 4).ceil()).toDouble(),
            getDrawingHorizontalLine: (value) => FlLine(
              color: AppTheme.line.withValues(alpha: .8),
              strokeWidth: 1,
            ),
          ),
          borderData: FlBorderData(show: false),
          titlesData: _compactTitles(
            visible.map((point) => _dayLabel(point.date)).toList(),
          ),
          barGroups: visible.indexed
              .map(
                (entry) => BarChartGroupData(
                  x: entry.$1,
                  barsSpace: 3,
                  barRods: [
                    BarChartRodData(
                      toY: entry.$2.present.toDouble(),
                      width: 8,
                      color: AppTheme.success,
                      borderRadius: const BorderRadius.vertical(
                        top: Radius.circular(4),
                      ),
                    ),
                    BarChartRodData(
                      toY: entry.$2.absent.toDouble(),
                      width: 8,
                      color: AppTheme.danger,
                      borderRadius: const BorderRadius.vertical(
                        top: Radius.circular(4),
                      ),
                    ),
                  ],
                ),
              )
              .toList(),
        ),
        duration: const Duration(milliseconds: 700),
        curve: Curves.easeOutCubic,
      ),
    );
  }
}

class _CashflowChart extends StatelessWidget {
  const _CashflowChart({required this.points});

  final List<DashboardCashflowPoint> points;

  @override
  Widget build(BuildContext context) {
    final visible = points.length > 6
        ? points.sublist(points.length - 6)
        : points;
    final maximum = visible.fold<double>(
      0,
      (current, point) =>
          math.max(current, math.max(point.income, point.expense)),
    );
    final maxY = maximum <= 0 ? 1.0 : maximum * 1.18;
    return _ChartCard(
      title: 'Cash flow',
      subtitle: 'Income and expense from payment records',
      legend: const [
        _LegendItem('Income', AppTheme.success),
        _LegendItem('Expense', AppTheme.orange),
      ],
      child: BarChart(
        BarChartData(
          minY: 0,
          maxY: maxY,
          alignment: BarChartAlignment.spaceAround,
          gridData: FlGridData(
            show: true,
            drawVerticalLine: false,
            horizontalInterval: maxY / 4,
            getDrawingHorizontalLine: (value) => FlLine(
              color: AppTheme.line.withValues(alpha: .8),
              strokeWidth: 1,
            ),
          ),
          borderData: FlBorderData(show: false),
          titlesData: _compactTitles(
            visible.map((point) => _monthLabel(point.month)).toList(),
            moneyAxis: true,
          ),
          barGroups: visible.indexed
              .map(
                (entry) => BarChartGroupData(
                  x: entry.$1,
                  barsSpace: 3,
                  barRods: [
                    BarChartRodData(
                      toY: entry.$2.income,
                      width: 9,
                      color: AppTheme.success,
                      borderRadius: const BorderRadius.vertical(
                        top: Radius.circular(4),
                      ),
                    ),
                    BarChartRodData(
                      toY: entry.$2.expense,
                      width: 9,
                      color: AppTheme.orange,
                      borderRadius: const BorderRadius.vertical(
                        top: Radius.circular(4),
                      ),
                    ),
                  ],
                ),
              )
              .toList(),
        ),
        duration: const Duration(milliseconds: 750),
        curve: Curves.easeOutCubic,
      ),
    );
  }
}

class _ExpenseChart extends StatelessWidget {
  const _ExpenseChart({required this.points});

  final List<DashboardValuePoint> points;

  @override
  Widget build(BuildContext context) {
    final visible = [...points]..sort((a, b) => b.value.compareTo(a.value));
    final limited = visible.take(5).toList();
    final total = limited.fold<double>(0, (sum, point) => sum + point.value);
    const tones = [
      AppTheme.orange,
      AppTheme.success,
      AppTheme.blue,
      Color(0xFF7C5CE7),
      AppTheme.warning,
    ];
    return _ChartCard(
      title: 'Material value',
      subtitle: 'Cost distribution by inventory category',
      child: Row(
        children: [
          Expanded(
            child: PieChart(
              PieChartData(
                centerSpaceRadius: 38,
                sectionsSpace: 3,
                startDegreeOffset: -90,
                sections: limited.indexed
                    .map(
                      (entry) => PieChartSectionData(
                        value: entry.$2.value,
                        color: tones[entry.$1 % tones.length],
                        radius: 28,
                        showTitle: false,
                      ),
                    )
                    .toList(),
              ),
              duration: const Duration(milliseconds: 750),
              curve: Curves.easeOutCubic,
            ),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  formatInr(total),
                  style: Theme.of(
                    context,
                  ).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.w800),
                ),
                const SizedBox(height: 12),
                ...limited.indexed.map(
                  (entry) => Padding(
                    padding: const EdgeInsets.only(bottom: 8),
                    child: Row(
                      children: [
                        Container(
                          width: 7,
                          height: 7,
                          decoration: BoxDecoration(
                            color: tones[entry.$1 % tones.length],
                            shape: BoxShape.circle,
                          ),
                        ),
                        const SizedBox(width: 7),
                        Expanded(
                          child: Text(
                            entry.$2.name,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: Theme.of(context).textTheme.labelSmall
                                ?.copyWith(color: AppTheme.muted),
                          ),
                        ),
                        Text(
                          total <= 0
                              ? '0%'
                              : '${((entry.$2.value / total) * 100).round()}%',
                          style: Theme.of(context).textTheme.labelSmall
                              ?.copyWith(fontWeight: FontWeight.w800),
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _ChartCard extends StatelessWidget {
  const _ChartCard({
    required this.title,
    required this.subtitle,
    required this.child,
    this.legend = const [],
  });

  final String title;
  final String subtitle;
  final Widget child;
  final List<_LegendItem> legend;

  @override
  Widget build(BuildContext context) => DashboardSurface(
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: Theme.of(context).textTheme.labelLarge?.copyWith(
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                  const SizedBox(height: 3),
                  Text(
                    subtitle,
                    style: Theme.of(
                      context,
                    ).textTheme.labelSmall?.copyWith(color: AppTheme.muted),
                  ),
                ],
              ),
            ),
            if (legend.isNotEmpty)
              Wrap(
                spacing: 8,
                children: legend
                    .map(
                      (item) => Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Container(
                            width: 6,
                            height: 6,
                            decoration: BoxDecoration(
                              color: item.color,
                              shape: BoxShape.circle,
                            ),
                          ),
                          const SizedBox(width: 4),
                          Text(
                            item.label,
                            style: Theme.of(context).textTheme.labelSmall
                                ?.copyWith(color: AppTheme.muted, fontSize: 8),
                          ),
                        ],
                      ),
                    )
                    .toList(),
              ),
          ],
        ),
        const SizedBox(height: 18),
        Expanded(child: child),
      ],
    ),
  );
}

class _LegendItem {
  const _LegendItem(this.label, this.color);

  final String label;
  final Color color;
}

FlTitlesData _compactTitles(List<String> labels, {bool moneyAxis = false}) =>
    FlTitlesData(
      topTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
      rightTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
      leftTitles: AxisTitles(
        sideTitles: SideTitles(
          showTitles: true,
          reservedSize: 34,
          getTitlesWidget: (value, meta) => Text(
            moneyAxis ? formatCompactNumber(value) : '${value.round()}',
            style: const TextStyle(color: AppTheme.muted, fontSize: 8),
          ),
        ),
      ),
      bottomTitles: AxisTitles(
        sideTitles: SideTitles(
          showTitles: true,
          reservedSize: 30,
          getTitlesWidget: (value, meta) {
            final index = value.toInt();
            if (index < 0 || index >= labels.length) {
              return const SizedBox.shrink();
            }
            return Padding(
              padding: const EdgeInsets.only(top: 7),
              child: Text(
                labels[index],
                style: const TextStyle(
                  color: AppTheme.muted,
                  fontSize: 8,
                  fontWeight: FontWeight.w600,
                ),
              ),
            );
          },
        ),
      ),
    );

String _shortLabel(String value) {
  final trimmed = value.trim();
  if (trimmed.isEmpty) return 'Site';
  final first = trimmed.split(RegExp(r'\s+')).first;
  return first.length <= 7 ? first : '${first.substring(0, 6)}…';
}

String _dayLabel(String value) {
  final parsed = DateTime.tryParse(value);
  if (parsed != null) return '${parsed.day}/${parsed.month}';
  return value.length <= 5 ? value : value.substring(value.length - 5);
}

String _monthLabel(String value) {
  final parsed = DateTime.tryParse('$value-01');
  if (parsed == null) return value;
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
  return months[parsed.month - 1];
}
