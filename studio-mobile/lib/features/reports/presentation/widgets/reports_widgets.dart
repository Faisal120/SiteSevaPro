import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';

import '../../../../core/theme/app_theme.dart';
import '../../../../core/utils/app_formatters.dart';
import '../../../../core/widgets/app_ui.dart';
import '../../models/report_models.dart';

class ReportsHero extends StatelessWidget {
  const ReportsHero({super.key, required this.data, required this.onCreate});

  final ReportsStudioData data;
  final VoidCallback onCreate;

  @override
  Widget build(BuildContext context) => Container(
    constraints: const BoxConstraints(minHeight: 250),
    clipBehavior: Clip.antiAlias,
    decoration: BoxDecoration(
      borderRadius: BorderRadius.circular(32),
      gradient: const LinearGradient(
        colors: [Color(0xFF07111F), Color(0xFF102E57), Color(0xFF1C5D8C)],
        begin: Alignment.topLeft,
        end: Alignment.bottomRight,
      ),
      boxShadow: const [
        BoxShadow(
          color: Color(0x2B0A0E17),
          blurRadius: 34,
          offset: Offset(0, 16),
        ),
      ],
    ),
    child: Stack(
      children: [
        const Positioned.fill(child: CustomPaint(painter: _ReportGrid())),
        Positioned(
          right: -80,
          top: -115,
          child: Container(
            width: 340,
            height: 340,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: const Color(0xFF68B8F4).withValues(alpha: .09),
              border: Border.all(
                color: Colors.white.withValues(alpha: .05),
                width: 30,
              ),
            ),
          ),
        ),
        Padding(
          padding: const EdgeInsets.all(24),
          child: LayoutBuilder(
            builder: (context, constraints) {
              final compact = constraints.maxWidth < 760;
              final identity = Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Row(
                    children: [
                      const Icon(
                        Icons.fact_check_outlined,
                        size: 18,
                        color: Color(0xFF8FD1FF),
                      ),
                      const SizedBox(width: 8),
                      Text(
                        'VERIFIED FIELD RECORD',
                        style: Theme.of(context).textTheme.labelSmall?.copyWith(
                          color: const Color(0xFFD9ECFA),
                          fontWeight: FontWeight.w800,
                          letterSpacing: .9,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),
                  Text(
                    'Every site day,\nclear and accountable.',
                    style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                      color: Colors.white,
                      fontWeight: FontWeight.w800,
                      letterSpacing: -1,
                      height: 1.08,
                    ),
                  ),
                  const SizedBox(height: 10),
                  Text(
                    data.latestReport == null
                        ? 'Start the first live field record for an assigned project.'
                        : '${data.scopedReports.length} reports connect progress, work, issues and evidence.',
                    style: Theme.of(context).textTheme.bodySmall?.copyWith(
                      color: const Color(0xFFC3D6E6),
                      height: 1.45,
                    ),
                  ),
                  if (data.canCreate) ...[
                    const SizedBox(height: 18),
                    FilledButton.icon(
                      onPressed: onCreate,
                      icon: const Icon(Icons.add_rounded, size: 19),
                      label: const Text('Create daily report'),
                      style: FilledButton.styleFrom(
                        minimumSize: const Size(0, 48),
                      ),
                    ),
                  ],
                ],
              );
              final metrics = _ReportsHeroMetrics(data: data);
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
        ),
      ],
    ),
  ).animate().fadeIn(duration: 340.ms).slideY(begin: .04);
}

class _ReportsHeroMetrics extends StatelessWidget {
  const _ReportsHeroMetrics({required this.data});
  final ReportsStudioData data;

  @override
  Widget build(BuildContext context) => Container(
    padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 22),
    decoration: BoxDecoration(
      color: Colors.white.withValues(alpha: .075),
      borderRadius: BorderRadius.circular(24),
      border: Border.all(color: Colors.white.withValues(alpha: .13)),
    ),
    child: Row(
      children: [
        _HeroMetric(value: '${data.latestProgress}%', label: 'Latest progress'),
        const _HeroDivider(),
        _HeroMetric(
          value: '${data.sevenDayCoverage}%',
          label: '7-day coverage',
        ),
        const _HeroDivider(),
        _HeroMetric(value: '${data.photoCount}', label: 'Site photos'),
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
          style: Theme.of(context).textTheme.titleMedium?.copyWith(
            color: Colors.white,
            fontWeight: FontWeight.w800,
            letterSpacing: -.4,
          ),
        ),
        const SizedBox(height: 5),
        Text(
          label.toUpperCase(),
          textAlign: TextAlign.center,
          style: Theme.of(context).textTheme.labelSmall?.copyWith(
            color: const Color(0xFFBED0DF),
            fontSize: 8,
            fontWeight: FontWeight.w700,
            letterSpacing: .4,
          ),
        ),
      ],
    ),
  );
}

class _HeroDivider extends StatelessWidget {
  const _HeroDivider();
  @override
  Widget build(BuildContext context) => Container(
    width: 1,
    height: 44,
    color: Colors.white.withValues(alpha: .14),
  );
}

class ReportsWorkspaceSwitch extends StatelessWidget {
  const ReportsWorkspaceSwitch({
    super.key,
    required this.value,
    required this.onChanged,
  });

  final ReportsWorkspace value;
  final ValueChanged<ReportsWorkspace> onChanged;

  @override
  Widget build(BuildContext context) => SingleChildScrollView(
    scrollDirection: Axis.horizontal,
    physics: const BouncingScrollPhysics(),
    child: Container(
      padding: const EdgeInsets.all(5),
      decoration: BoxDecoration(
        color: Theme.of(context).cardTheme.color,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: AppTheme.line),
      ),
      child: Row(
        children: ReportsWorkspace.values.map((workspace) {
          final selected = workspace == value;
          return Padding(
            padding: const EdgeInsets.only(right: 3),
            child: Material(
              color: selected ? AppTheme.navy : Colors.transparent,
              borderRadius: BorderRadius.circular(14),
              child: InkWell(
                onTap: () => onChanged(workspace),
                borderRadius: BorderRadius.circular(14),
                child: Padding(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 15,
                    vertical: 10,
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(
                        _workspaceIcon(workspace),
                        size: 17,
                        color: selected ? Colors.white : AppTheme.muted,
                      ),
                      const SizedBox(width: 7),
                      Text(
                        _workspaceLabel(workspace),
                        style: Theme.of(context).textTheme.labelSmall?.copyWith(
                          color: selected ? Colors.white : AppTheme.muted,
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          );
        }).toList(),
      ),
    ),
  );
}

class ReportsLogbook extends StatelessWidget {
  const ReportsLogbook({
    super.key,
    required this.data,
    required this.onOpen,
    required this.onCreate,
  });

  final ReportsStudioData data;
  final ValueChanged<DailyReport> onOpen;
  final VoidCallback onCreate;

  @override
  Widget build(BuildContext context) {
    final reports = data.visibleReports;
    if (reports.isEmpty) {
      return EmptyPanel(
        title: data.reports.isEmpty
            ? 'No field reports yet'
            : 'No matching reports',
        message: data.reports.isEmpty
            ? 'Capture completed work, issues, weather and progress evidence from the site.'
            : 'Adjust the search, project, or reporting period.',
        icon: Icons.description_outlined,
        actionLabel: data.canCreate && !data.isOffline && data.reports.isEmpty
            ? 'Create daily report'
            : null,
        onAction: onCreate,
      );
    }
    return Column(
      children: reports.indexed.map((entry) {
        final report = entry.$2;
        return Padding(
              padding: const EdgeInsets.only(bottom: 12),
              child: DailyReportCard(
                report: report,
                siteName: data.siteName(report.siteId),
                onTap: () => onOpen(report),
              ),
            )
            .animate(delay: (entry.$1.clamp(0, 8) * 45).ms)
            .fadeIn()
            .slideY(begin: .05, curve: Curves.easeOutCubic);
      }).toList(),
    );
  }
}

class DailyReportCard extends StatelessWidget {
  const DailyReportCard({
    super.key,
    required this.report,
    required this.siteName,
    required this.onTap,
  });

  final DailyReport report;
  final String siteName;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) => SurfaceCard(
    onTap: onTap,
    padding: const EdgeInsets.all(17),
    child: LayoutBuilder(
      builder: (context, constraints) {
        final compact = constraints.maxWidth < 620;
        final date = _DateTile(date: report.date);
        final content = Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Expanded(
                  child: Text(
                    siteName,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: Theme.of(context).textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.w800,
                      letterSpacing: -.35,
                    ),
                  ),
                ),
                if (report.weather != null)
                  StatusBadge(
                    label: report.weather!,
                    tone: const Color(0xFF2879B7),
                  ),
              ],
            ),
            const SizedBox(height: 6),
            Text(
              report.narrative,
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                color: AppTheme.muted,
                height: 1.45,
              ),
            ),
            const SizedBox(height: 14),
            Wrap(
              spacing: 8,
              runSpacing: 7,
              children: [
                _ReportStat(
                  icon: Icons.check_circle_outline_rounded,
                  value: '${report.completedTasks.length} completed',
                  tone: AppTheme.success,
                ),
                _ReportStat(
                  icon: Icons.report_problem_outlined,
                  value: '${report.issues.length} issues',
                  tone: report.hasIssues ? AppTheme.danger : AppTheme.muted,
                ),
                _ReportStat(
                  icon: Icons.photo_camera_outlined,
                  value: '${report.media.length} photos',
                  tone: AppTheme.blue,
                ),
              ],
            ),
            const SizedBox(height: 14),
            Row(
              children: [
                Expanded(
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(6),
                    child: LinearProgressIndicator(
                      value: report.progress / 100,
                      minHeight: 6,
                      backgroundColor: AppTheme.line,
                      color: AppTheme.blue,
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                Text(
                  '${report.progress}%',
                  style: Theme.of(context).textTheme.labelLarge?.copyWith(
                    color: AppTheme.blue,
                    fontWeight: FontWeight.w800,
                  ),
                ),
                const SizedBox(width: 4),
                const Icon(Icons.chevron_right_rounded, color: AppTheme.muted),
              ],
            ),
          ],
        );
        if (compact) {
          return Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  date,
                  const SizedBox(width: 12),
                  Expanded(child: content),
                ],
              ),
            ],
          );
        }
        return Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            date,
            const SizedBox(width: 16),
            Expanded(child: content),
          ],
        );
      },
    ),
  );
}

class _DateTile extends StatelessWidget {
  const _DateTile({required this.date});
  final DateTime date;

  @override
  Widget build(BuildContext context) => Container(
    width: 58,
    height: 66,
    decoration: BoxDecoration(
      color: AppTheme.blue.withValues(alpha: .08),
      borderRadius: BorderRadius.circular(18),
      border: Border.all(color: AppTheme.blue.withValues(alpha: .13)),
    ),
    child: Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Text(
          '${date.day}',
          style: Theme.of(context).textTheme.titleLarge?.copyWith(
            color: AppTheme.blue,
            fontWeight: FontWeight.w800,
            letterSpacing: -.6,
          ),
        ),
        Text(
          _month(date).toUpperCase(),
          style: Theme.of(context).textTheme.labelSmall?.copyWith(
            color: AppTheme.muted,
            fontSize: 9,
            fontWeight: FontWeight.w800,
            letterSpacing: .5,
          ),
        ),
      ],
    ),
  );
}

class _ReportStat extends StatelessWidget {
  const _ReportStat({
    required this.icon,
    required this.value,
    required this.tone,
  });

  final IconData icon;
  final String value;
  final Color tone;

  @override
  Widget build(BuildContext context) => Container(
    padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 6),
    decoration: BoxDecoration(
      color: tone.withValues(alpha: .075),
      borderRadius: BorderRadius.circular(10),
    ),
    child: Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(icon, color: tone, size: 14),
        const SizedBox(width: 5),
        Text(
          value,
          style: Theme.of(context).textTheme.labelSmall?.copyWith(
            color: tone,
            fontSize: 9,
            fontWeight: FontWeight.w700,
          ),
        ),
      ],
    ),
  );
}

class ReportsInsights extends StatelessWidget {
  const ReportsInsights({super.key, required this.data});

  final ReportsStudioData data;

  @override
  Widget build(BuildContext context) {
    if (data.scopedReports.isEmpty) {
      return const EmptyPanel(
        title: 'No report intelligence yet',
        message: 'Insights are calculated only from live daily report records.',
        icon: Icons.query_stats_rounded,
      );
    }
    return Column(
      children: [
        _InsightsMetrics(data: data),
        const SizedBox(height: 13),
        LayoutBuilder(
          builder: (context, constraints) {
            final trend = ReportProgressChart(data: data);
            final activity = ReportSiteActivity(data: data);
            if (constraints.maxWidth >= 900) {
              return Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Expanded(flex: 3, child: trend),
                  const SizedBox(width: 13),
                  Expanded(flex: 2, child: activity),
                ],
              );
            }
            return Column(
              children: [trend, const SizedBox(height: 13), activity],
            );
          },
        ),
        const SizedBox(height: 13),
        ReportIssueRegister(data: data),
      ],
    );
  }
}

class _InsightsMetrics extends StatelessWidget {
  const _InsightsMetrics({required this.data});
  final ReportsStudioData data;

  @override
  Widget build(BuildContext context) {
    final entries = [
      (
        'Reports',
        '${data.scopedReports.length}',
        Icons.description_outlined,
        AppTheme.blue,
      ),
      (
        'Completed work',
        '${data.completedWorkCount}',
        Icons.task_alt_rounded,
        AppTheme.success,
      ),
      (
        'Issue mentions',
        '${data.issueCount}',
        Icons.report_problem_outlined,
        AppTheme.danger,
      ),
      (
        'Photo evidence',
        '${data.photoCount}',
        Icons.photo_library_outlined,
        AppTheme.warning,
      ),
    ];
    return LayoutBuilder(
      builder: (context, constraints) {
        final columns = constraints.maxWidth >= 900
            ? 4
            : constraints.maxWidth >= 560
            ? 2
            : 1;
        final width = (constraints.maxWidth - (columns - 1) * 11) / columns;
        return Wrap(
          spacing: 11,
          runSpacing: 11,
          children: entries.indexed.map((entry) {
            final value = entry.$2;
            return SizedBox(
              width: width,
              height: 128,
              child: MetricCard(
                label: value.$1,
                value: value.$2,
                icon: value.$3,
                tone: value.$4,
              ),
            ).animate(delay: (entry.$1 * 45).ms).fadeIn().slideY(begin: .05);
          }).toList(),
        );
      },
    );
  }
}

class ReportProgressChart extends StatelessWidget {
  const ReportProgressChart({super.key, required this.data});

  final ReportsStudioData data;

  @override
  Widget build(BuildContext context) {
    final reports = data.scopedReports.toList()
      ..sort((a, b) => a.date.compareTo(b.date));
    final dates = reports
        .map((item) => apiReportDate(item.date))
        .toSet()
        .toList();
    final tones = [
      AppTheme.blue,
      AppTheme.orange,
      AppTheme.success,
      AppTheme.warning,
    ];
    final siteIds = reports.map((item) => item.siteId).toSet().toList();
    final bars = siteIds.indexed.map((entry) {
      final siteReports = reports.where((item) => item.siteId == entry.$2);
      return LineChartBarData(
        isCurved: true,
        curveSmoothness: .22,
        color: tones[entry.$1 % tones.length],
        barWidth: 3,
        dotData: FlDotData(show: siteReports.length <= 10),
        belowBarData: BarAreaData(
          show: siteIds.length == 1,
          color: tones[entry.$1 % tones.length].withValues(alpha: .08),
        ),
        spots: siteReports
            .map(
              (report) => FlSpot(
                dates.indexOf(apiReportDate(report.date)).toDouble(),
                report.progress.toDouble(),
              ),
            )
            .toList(),
      );
    }).toList();
    return SurfaceCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Reported progress',
            style: Theme.of(
              context,
            ).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w800),
          ),
          const SizedBox(height: 4),
          Text(
            'Cumulative progress recorded by each project log.',
            style: Theme.of(
              context,
            ).textTheme.labelSmall?.copyWith(color: AppTheme.muted),
          ),
          const SizedBox(height: 18),
          SizedBox(
            height: 220,
            child: LineChart(
              LineChartData(
                minY: 0,
                maxY: 100,
                minX: 0,
                maxX: dates.length <= 1 ? 1 : (dates.length - 1).toDouble(),
                gridData: FlGridData(
                  drawVerticalLine: false,
                  horizontalInterval: 25,
                  getDrawingHorizontalLine: (_) =>
                      const FlLine(color: AppTheme.line, strokeWidth: 1),
                ),
                borderData: FlBorderData(show: false),
                lineTouchData: const LineTouchData(enabled: true),
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
                      reservedSize: 34,
                      interval: 25,
                      getTitlesWidget: (value, meta) => Text(
                        '${value.toInt()}%',
                        style: const TextStyle(
                          color: AppTheme.muted,
                          fontSize: 9,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                  ),
                  bottomTitles: AxisTitles(
                    sideTitles: SideTitles(
                      showTitles: true,
                      reservedSize: 28,
                      interval: dates.length <= 5
                          ? 1
                          : (dates.length / 4).ceilToDouble(),
                      getTitlesWidget: (value, meta) {
                        final index = value.toInt();
                        if (index < 0 || index >= dates.length) {
                          return const SizedBox.shrink();
                        }
                        final date = DateTime.tryParse(dates[index]);
                        return Padding(
                          padding: const EdgeInsets.only(top: 7),
                          child: Text(
                            date == null ? '' : '${date.day} ${_month(date)}',
                            style: const TextStyle(
                              color: AppTheme.muted,
                              fontSize: 9,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        );
                      },
                    ),
                  ),
                ),
                lineBarsData: bars,
              ),
              duration: const Duration(milliseconds: 650),
              curve: Curves.easeOutCubic,
            ),
          ),
          if (siteIds.length > 1) ...[
            const SizedBox(height: 10),
            Wrap(
              spacing: 12,
              runSpacing: 7,
              children: siteIds.indexed
                  .map(
                    (entry) => Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Container(
                          width: 8,
                          height: 8,
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            color: tones[entry.$1 % tones.length],
                          ),
                        ),
                        const SizedBox(width: 5),
                        Text(
                          data.siteName(entry.$2),
                          style: Theme.of(context).textTheme.labelSmall
                              ?.copyWith(color: AppTheme.muted, fontSize: 9),
                        ),
                      ],
                    ),
                  )
                  .toList(),
            ),
          ],
        ],
      ),
    );
  }
}

class ReportSiteActivity extends StatelessWidget {
  const ReportSiteActivity({super.key, required this.data});
  final ReportsStudioData data;

  @override
  Widget build(BuildContext context) => SurfaceCard(
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Project activity',
          style: Theme.of(
            context,
          ).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w800),
        ),
        const SizedBox(height: 4),
        Text(
          'Report count and latest server-recorded progress.',
          style: Theme.of(
            context,
          ).textTheme.labelSmall?.copyWith(color: AppTheme.muted),
        ),
        const SizedBox(height: 15),
        ...data.siteActivity.take(6).toList().indexed.map((entry) {
          final activity = entry.$2;
          return Container(
            padding: const EdgeInsets.symmetric(vertical: 11),
            decoration: BoxDecoration(
              border: entry.$1 == data.siteActivity.take(6).length - 1
                  ? null
                  : const Border(bottom: BorderSide(color: AppTheme.line)),
            ),
            child: Row(
              children: [
                Container(
                  width: 38,
                  height: 38,
                  decoration: BoxDecoration(
                    color: AppTheme.blue.withValues(alpha: .08),
                    borderRadius: BorderRadius.circular(13),
                  ),
                  child: const Icon(
                    Icons.apartment_rounded,
                    color: AppTheme.blue,
                    size: 18,
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        activity.site.name,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: Theme.of(context).textTheme.labelLarge?.copyWith(
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                      Text(
                        '${activity.reportCount} reports  |  ${activity.issueCount} issue mentions',
                        style: Theme.of(context).textTheme.labelSmall?.copyWith(
                          color: AppTheme.muted,
                          fontSize: 9,
                        ),
                      ),
                    ],
                  ),
                ),
                Text(
                  '${activity.latestProgress}%',
                  style: Theme.of(context).textTheme.labelLarge?.copyWith(
                    color: AppTheme.blue,
                    fontWeight: FontWeight.w800,
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

class ReportIssueRegister extends StatelessWidget {
  const ReportIssueRegister({super.key, required this.data});
  final ReportsStudioData data;

  @override
  Widget build(BuildContext context) {
    final entries = <(DailyReport, String)>[];
    for (final report in data.scopedReports) {
      for (final issue in report.issues) {
        entries.add((report, issue));
      }
    }
    return SurfaceCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Issue register',
            style: Theme.of(
              context,
            ).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w800),
          ),
          const SizedBox(height: 4),
          Text(
            'Issue mentions recorded in daily reports. Resolution status is not exposed by the API.',
            style: Theme.of(
              context,
            ).textTheme.labelSmall?.copyWith(color: AppTheme.muted),
          ),
          const SizedBox(height: 14),
          if (entries.isEmpty)
            const _ClearIssueState()
          else
            ...entries.take(10).toList().indexed.map((entry) {
              final report = entry.$2.$1;
              return Padding(
                padding: const EdgeInsets.symmetric(vertical: 8),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Container(
                      width: 9,
                      height: 9,
                      margin: const EdgeInsets.only(top: 5),
                      decoration: const BoxDecoration(
                        shape: BoxShape.circle,
                        color: AppTheme.danger,
                      ),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            entry.$2.$2,
                            style: Theme.of(context).textTheme.labelLarge
                                ?.copyWith(fontWeight: FontWeight.w700),
                          ),
                          const SizedBox(height: 2),
                          Text(
                            '${data.siteName(report.siteId)}  |  ${appDate(report.date)}',
                            style: Theme.of(context).textTheme.labelSmall
                                ?.copyWith(color: AppTheme.muted, fontSize: 9),
                          ),
                        ],
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

class _ClearIssueState extends StatelessWidget {
  const _ClearIssueState();
  @override
  Widget build(BuildContext context) => Row(
    children: [
      Container(
        width: 42,
        height: 42,
        decoration: BoxDecoration(
          color: AppTheme.success.withValues(alpha: .09),
          borderRadius: BorderRadius.circular(14),
        ),
        child: const Icon(Icons.check_rounded, color: AppTheme.success),
      ),
      const SizedBox(width: 11),
      Expanded(
        child: Text(
          'No issue mentions in the selected report period.',
          style: Theme.of(
            context,
          ).textTheme.labelLarge?.copyWith(fontWeight: FontWeight.w700),
        ),
      ),
    ],
  );
}

class ReportsMediaGallery extends StatelessWidget {
  const ReportsMediaGallery({
    super.key,
    required this.data,
    required this.onOpenReport,
  });

  final ReportsStudioData data;
  final ValueChanged<DailyReport> onOpenReport;

  @override
  Widget build(BuildContext context) {
    final evidence = data.evidence;
    if (evidence.isEmpty) {
      return const EmptyPanel(
        title: 'No progress evidence',
        message:
            'Secure photos attached to live daily reports will appear here.',
        icon: Icons.photo_library_outlined,
      );
    }
    return LayoutBuilder(
      builder: (context, constraints) {
        final columns = constraints.maxWidth >= 1000
            ? 4
            : constraints.maxWidth >= 650
            ? 3
            : 2;
        final width = (constraints.maxWidth - (columns - 1) * 11) / columns;
        return Wrap(
          spacing: 11,
          runSpacing: 11,
          children: evidence.indexed.map((entry) {
            final item = entry.$2;
            return SizedBox(
                  width: width,
                  child: Material(
                    color: Theme.of(context).cardTheme.color,
                    borderRadius: BorderRadius.circular(20),
                    clipBehavior: Clip.antiAlias,
                    child: InkWell(
                      onTap: () => onOpenReport(item.report),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          AspectRatio(
                            aspectRatio: 1.25,
                            child: Image.network(
                              item.media.url,
                              fit: BoxFit.cover,
                              loadingBuilder: (context, child, progress) =>
                                  progress == null
                                  ? child
                                  : const AppSkeleton(radius: 0),
                              errorBuilder: (context, error, stackTrace) =>
                                  Container(
                                    color: AppTheme.line,
                                    child: const Icon(
                                      Icons.broken_image_outlined,
                                      color: AppTheme.muted,
                                    ),
                                  ),
                            ),
                          ),
                          Padding(
                            padding: const EdgeInsets.all(11),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  item.siteName,
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                  style: Theme.of(context).textTheme.labelLarge
                                      ?.copyWith(fontWeight: FontWeight.w800),
                                ),
                                const SizedBox(height: 3),
                                Text(
                                  appDate(item.report.date),
                                  style: Theme.of(context).textTheme.labelSmall
                                      ?.copyWith(
                                        color: AppTheme.muted,
                                        fontSize: 9,
                                      ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                )
                .animate(delay: (entry.$1.clamp(0, 9) * 40).ms)
                .fadeIn()
                .scale(begin: const Offset(.98, .98));
          }).toList(),
        );
      },
    );
  }
}

class ReportsOfflineBanner extends StatelessWidget {
  const ReportsOfflineBanner({super.key, required this.syncedAt});
  final DateTime syncedAt;

  @override
  Widget build(BuildContext context) => Container(
    padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
    decoration: BoxDecoration(
      color: AppTheme.warning.withValues(alpha: .09),
      borderRadius: BorderRadius.circular(16),
      border: Border.all(color: AppTheme.warning.withValues(alpha: .2)),
    ),
    child: Row(
      children: [
        const Icon(Icons.cloud_off_rounded, color: AppTheme.warning, size: 18),
        const SizedBox(width: 9),
        Expanded(
          child: Text(
            'Offline report cache  |  Last synced ${appDate(syncedAt)}. Reconnect to submit or upload evidence.',
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

class ReportsApiScopeNotice extends StatelessWidget {
  const ReportsApiScopeNotice({super.key});

  @override
  Widget build(BuildContext context) => Container(
    padding: const EdgeInsets.all(14),
    decoration: BoxDecoration(
      color: AppTheme.blue.withValues(alpha: .055),
      borderRadius: BorderRadius.circular(18),
      border: Border.all(color: AppTheme.blue.withValues(alpha: .12)),
    ),
    child: Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Icon(Icons.lock_clock_outlined, color: AppTheme.blue, size: 19),
        const SizedBox(width: 10),
        Expanded(
          child: Text(
            'Live API scope: immutable daily logs, progress, weather, work, issues and secure media. Approvals, comments, PDF export and revision history require backend endpoints.',
            style: Theme.of(context).textTheme.labelSmall?.copyWith(
              color: AppTheme.muted,
              height: 1.45,
              fontWeight: FontWeight.w600,
            ),
          ),
        ),
      ],
    ),
  );
}

class ReportsSkeleton extends StatelessWidget {
  const ReportsSkeleton({super.key});

  @override
  Widget build(BuildContext context) => ListView(
    physics: const NeverScrollableScrollPhysics(),
    padding: const EdgeInsets.fromLTRB(20, 20, 20, 120),
    children: const [
      AppSkeleton(height: 54, radius: 18),
      SizedBox(height: 16),
      AppSkeleton(height: 260, radius: 32),
      SizedBox(height: 20),
      AppSkeleton(height: 54, radius: 18),
      SizedBox(height: 14),
      AppSkeleton(height: 172),
      SizedBox(height: 12),
      AppSkeleton(height: 172),
    ],
  );
}

IconData _workspaceIcon(ReportsWorkspace workspace) => switch (workspace) {
  ReportsWorkspace.logbook => Icons.view_agenda_outlined,
  ReportsWorkspace.insights => Icons.query_stats_rounded,
  ReportsWorkspace.media => Icons.photo_library_outlined,
};

String _workspaceLabel(ReportsWorkspace workspace) => switch (workspace) {
  ReportsWorkspace.logbook => 'Logbook',
  ReportsWorkspace.insights => 'Insights',
  ReportsWorkspace.media => 'Evidence',
};

String _month(DateTime date) => const [
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
][date.month - 1];

class _ReportGrid extends CustomPainter {
  const _ReportGrid();

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = Colors.white.withValues(alpha: .035)
      ..strokeWidth = 1;
    for (double x = 0; x < size.width; x += 32) {
      canvas.drawLine(Offset(x, 0), Offset(x, size.height), paint);
    }
    for (double y = 0; y < size.height; y += 32) {
      canvas.drawLine(Offset(0, y), Offset(size.width, y), paint);
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}
