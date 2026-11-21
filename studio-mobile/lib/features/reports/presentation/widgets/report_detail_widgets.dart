import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';

import '../../../../core/theme/app_theme.dart';
import '../../../../core/utils/app_formatters.dart';
import '../../../../core/widgets/app_ui.dart';
import '../../models/report_models.dart';

class ReportDetailHero extends StatelessWidget {
  const ReportDetailHero({
    super.key,
    required this.report,
    required this.siteName,
  });

  final DailyReport report;
  final String siteName;

  @override
  Widget build(BuildContext context) => Container(
    constraints: const BoxConstraints(minHeight: 235),
    clipBehavior: Clip.antiAlias,
    decoration: BoxDecoration(
      borderRadius: BorderRadius.circular(32),
      gradient: const LinearGradient(
        colors: [Color(0xFF07111F), Color(0xFF163B68), Color(0xFF246D9B)],
        begin: Alignment.topLeft,
        end: Alignment.bottomRight,
      ),
      boxShadow: const [
        BoxShadow(
          color: Color(0x2A0A0E17),
          blurRadius: 32,
          offset: Offset(0, 15),
        ),
      ],
    ),
    child: Stack(
      children: [
        Positioned(
          right: -60,
          bottom: -110,
          child: Container(
            width: 300,
            height: 300,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: Colors.white.withValues(alpha: .045),
              border: Border.all(
                color: Colors.white.withValues(alpha: .05),
                width: 26,
              ),
            ),
          ),
        ),
        Padding(
          padding: const EdgeInsets.all(24),
          child: LayoutBuilder(
            builder: (context, constraints) {
              final compact = constraints.maxWidth < 660;
              final identity = Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Row(
                    children: [
                      const Icon(
                        Icons.verified_outlined,
                        color: Color(0xFF91D4FF),
                        size: 18,
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          'DAILY FIELD RECORD  |  ${appDate(report.date).toUpperCase()}',
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: Theme.of(context).textTheme.labelSmall
                              ?.copyWith(
                                color: const Color(0xFFD5E7F4),
                                fontWeight: FontWeight.w800,
                                letterSpacing: .65,
                              ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 17),
                  Text(
                    siteName,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                      color: Colors.white,
                      fontWeight: FontWeight.w800,
                      letterSpacing: -.9,
                      height: 1.08,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    report.weather == null
                        ? 'Weather was not recorded for this report.'
                        : '${report.weather} conditions recorded by the field team.',
                    style: Theme.of(context).textTheme.bodySmall?.copyWith(
                      color: const Color(0xFFC4D7E5),
                    ),
                  ),
                ],
              );
              final progress = _ReportProgressRing(progress: report.progress);
              if (compact) {
                return Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [identity, const SizedBox(height: 24), progress],
                );
              }
              return Row(
                children: [
                  Expanded(child: identity),
                  const SizedBox(width: 28),
                  progress,
                ],
              );
            },
          ),
        ),
      ],
    ),
  ).animate().fadeIn(duration: 330.ms).slideY(begin: .04);
}

class _ReportProgressRing extends StatelessWidget {
  const _ReportProgressRing({required this.progress});
  final int progress;

  @override
  Widget build(BuildContext context) => Container(
    width: 145,
    padding: const EdgeInsets.symmetric(vertical: 17),
    decoration: BoxDecoration(
      color: Colors.white.withValues(alpha: .075),
      borderRadius: BorderRadius.circular(24),
      border: Border.all(color: Colors.white.withValues(alpha: .13)),
    ),
    child: Column(
      children: [
        SizedBox.square(
          dimension: 82,
          child: Stack(
            alignment: Alignment.center,
            children: [
              CircularProgressIndicator(
                value: progress / 100,
                strokeWidth: 8,
                strokeCap: StrokeCap.round,
                backgroundColor: Colors.white.withValues(alpha: .13),
                color: const Color(0xFF8FD1FF),
              ),
              Text(
                '$progress%',
                style: Theme.of(context).textTheme.titleMedium?.copyWith(
                  color: Colors.white,
                  fontWeight: FontWeight.w800,
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 10),
        Text(
          'REPORTED PROGRESS',
          style: Theme.of(context).textTheme.labelSmall?.copyWith(
            color: const Color(0xFFBED0DF),
            fontSize: 8,
            fontWeight: FontWeight.w800,
            letterSpacing: .45,
          ),
        ),
      ],
    ),
  );
}

class ReportNarrativePanel extends StatelessWidget {
  const ReportNarrativePanel({super.key, required this.report});
  final DailyReport report;

  @override
  Widget build(BuildContext context) => SurfaceCard(
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const _PanelTitle(
          icon: Icons.notes_rounded,
          title: 'Site narrative',
          subtitle: 'Field context captured with this immutable record.',
          tone: AppTheme.blue,
        ),
        const SizedBox(height: 16),
        Text(
          report.notes ?? 'No general notes were submitted.',
          style: Theme.of(context).textTheme.bodyMedium?.copyWith(
            height: 1.55,
            color: report.notes == null ? AppTheme.muted : null,
          ),
        ),
      ],
    ),
  );
}

class ReportWorkPanel extends StatelessWidget {
  const ReportWorkPanel({super.key, required this.report});
  final DailyReport report;

  @override
  Widget build(BuildContext context) => SurfaceCard(
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const _PanelTitle(
          icon: Icons.task_alt_rounded,
          title: 'Completed work',
          subtitle: 'Activities declared complete by the report author.',
          tone: AppTheme.success,
        ),
        const SizedBox(height: 14),
        if (report.completedTasks.isEmpty)
          const _PanelEmpty(label: 'No completed work items were listed.')
        else
          ...report.completedTasks.indexed.map(
            (entry) => _DetailListItem(
              index: entry.$1 + 1,
              value: entry.$2,
              tone: AppTheme.success,
            ),
          ),
      ],
    ),
  );
}

class ReportIssuesPanel extends StatelessWidget {
  const ReportIssuesPanel({super.key, required this.report});
  final DailyReport report;

  @override
  Widget build(BuildContext context) => SurfaceCard(
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const _PanelTitle(
          icon: Icons.report_problem_outlined,
          title: 'Issues recorded',
          subtitle:
              'Observations only; the API does not expose resolution status.',
          tone: AppTheme.danger,
        ),
        const SizedBox(height: 14),
        if (report.issues.isEmpty)
          const _PanelEmpty(label: 'No issues were mentioned in this report.')
        else
          ...report.issues.indexed.map(
            (entry) => _DetailListItem(
              index: entry.$1 + 1,
              value: entry.$2,
              tone: AppTheme.danger,
            ),
          ),
      ],
    ),
  );
}

class ReportNextPlanPanel extends StatelessWidget {
  const ReportNextPlanPanel({super.key, required this.report});
  final DailyReport report;

  @override
  Widget build(BuildContext context) => SurfaceCard(
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const _PanelTitle(
          icon: Icons.next_plan_outlined,
          title: 'Next-day plan',
          subtitle: 'The handoff captured for the next field shift.',
          tone: AppTheme.warning,
        ),
        const SizedBox(height: 16),
        Text(
          report.nextDayPlan ?? 'No next-day plan was submitted.',
          style: Theme.of(context).textTheme.bodyMedium?.copyWith(
            height: 1.55,
            color: report.nextDayPlan == null ? AppTheme.muted : null,
          ),
        ),
      ],
    ),
  );
}

class ReportEvidencePanel extends StatelessWidget {
  const ReportEvidencePanel({super.key, required this.report});
  final DailyReport report;

  @override
  Widget build(BuildContext context) => SurfaceCard(
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const _PanelTitle(
          icon: Icons.photo_library_outlined,
          title: 'Progress evidence',
          subtitle: 'Secure media URLs stored with the daily report.',
          tone: AppTheme.blue,
        ),
        const SizedBox(height: 15),
        if (report.media.isEmpty)
          const _PanelEmpty(label: 'No photo evidence was attached.')
        else
          LayoutBuilder(
            builder: (context, constraints) {
              final columns = constraints.maxWidth >= 760
                  ? 3
                  : constraints.maxWidth >= 430
                  ? 2
                  : 1;
              final width =
                  (constraints.maxWidth - (columns - 1) * 10) / columns;
              return Wrap(
                spacing: 10,
                runSpacing: 10,
                children: report.media.indexed
                    .map(
                      (entry) => SizedBox(
                        width: width,
                        child: ClipRRect(
                          borderRadius: BorderRadius.circular(18),
                          child: AspectRatio(
                            aspectRatio: 1.35,
                            child: Image.network(
                              entry.$2.url,
                              fit: BoxFit.cover,
                              loadingBuilder: (context, child, progress) =>
                                  progress == null
                                  ? child
                                  : const AppSkeleton(radius: 18),
                              errorBuilder: (context, error, stackTrace) =>
                                  Container(
                                    color: AppTheme.line,
                                    alignment: Alignment.center,
                                    child: const Icon(
                                      Icons.broken_image_outlined,
                                      color: AppTheme.muted,
                                    ),
                                  ),
                            ),
                          ),
                        ),
                      ),
                    )
                    .toList(),
              );
            },
          ),
      ],
    ),
  );
}

class ReportRecordPanel extends StatelessWidget {
  const ReportRecordPanel({
    super.key,
    required this.report,
    required this.siteName,
  });

  final DailyReport report;
  final String siteName;

  @override
  Widget build(BuildContext context) => SurfaceCard(
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const _PanelTitle(
          icon: Icons.fingerprint_rounded,
          title: 'Record identity',
          subtitle: 'Server-issued identifiers for this field record.',
          tone: AppTheme.blue,
        ),
        const SizedBox(height: 15),
        _RecordRow(label: 'Project', value: siteName),
        _RecordRow(label: 'Report date', value: appDate(report.date)),
        _RecordRow(label: 'Report ID', value: report.id),
        if (report.createdBy != null)
          _RecordRow(label: 'Created by ID', value: report.createdBy!),
        if (report.createdAt != null)
          _RecordRow(label: 'Submitted', value: appDate(report.createdAt)),
      ],
    ),
  );
}

class ReportImmutableNotice extends StatelessWidget {
  const ReportImmutableNotice({super.key});

  @override
  Widget build(BuildContext context) => Container(
    padding: const EdgeInsets.all(14),
    decoration: BoxDecoration(
      color: AppTheme.warning.withValues(alpha: .075),
      borderRadius: BorderRadius.circular(18),
      border: Border.all(color: AppTheme.warning.withValues(alpha: .18)),
    ),
    child: Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Icon(
          Icons.lock_outline_rounded,
          color: AppTheme.warning,
          size: 19,
        ),
        const SizedBox(width: 10),
        Expanded(
          child: Text(
            'Immutable field record. The current backend has no report edit, delete, approval, signature, comment, or revision-history endpoint.',
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

class _PanelTitle extends StatelessWidget {
  const _PanelTitle({
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.tone,
  });

  final IconData icon;
  final String title;
  final String subtitle;
  final Color tone;

  @override
  Widget build(BuildContext context) => Row(
    crossAxisAlignment: CrossAxisAlignment.start,
    children: [
      Container(
        width: 42,
        height: 42,
        decoration: BoxDecoration(
          color: tone.withValues(alpha: .09),
          borderRadius: BorderRadius.circular(14),
        ),
        child: Icon(icon, color: tone, size: 19),
      ),
      const SizedBox(width: 11),
      Expanded(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              title,
              style: Theme.of(
                context,
              ).textTheme.labelLarge?.copyWith(fontWeight: FontWeight.w800),
            ),
            const SizedBox(height: 2),
            Text(
              subtitle,
              style: Theme.of(context).textTheme.labelSmall?.copyWith(
                color: AppTheme.muted,
                height: 1.35,
              ),
            ),
          ],
        ),
      ),
    ],
  );
}

class _DetailListItem extends StatelessWidget {
  const _DetailListItem({
    required this.index,
    required this.value,
    required this.tone,
  });

  final int index;
  final String value;
  final Color tone;

  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.symmetric(vertical: 7),
    child: Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          width: 25,
          height: 25,
          alignment: Alignment.center,
          decoration: BoxDecoration(
            color: tone.withValues(alpha: .09),
            borderRadius: BorderRadius.circular(9),
          ),
          child: Text(
            '$index',
            style: Theme.of(context).textTheme.labelSmall?.copyWith(
              color: tone,
              fontSize: 9,
              fontWeight: FontWeight.w800,
            ),
          ),
        ),
        const SizedBox(width: 10),
        Expanded(
          child: Text(
            value,
            style: Theme.of(
              context,
            ).textTheme.bodySmall?.copyWith(height: 1.45),
          ),
        ),
      ],
    ),
  );
}

class _PanelEmpty extends StatelessWidget {
  const _PanelEmpty({required this.label});
  final String label;

  @override
  Widget build(BuildContext context) => Container(
    width: double.infinity,
    padding: const EdgeInsets.all(14),
    decoration: BoxDecoration(
      color: AppTheme.line.withValues(alpha: .38),
      borderRadius: BorderRadius.circular(14),
    ),
    child: Text(
      label,
      style: Theme.of(
        context,
      ).textTheme.labelSmall?.copyWith(color: AppTheme.muted),
    ),
  );
}

class _RecordRow extends StatelessWidget {
  const _RecordRow({required this.label, required this.value});
  final String label;
  final String value;

  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.symmetric(vertical: 7),
    child: Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        SizedBox(
          width: 104,
          child: Text(
            label,
            style: Theme.of(
              context,
            ).textTheme.labelSmall?.copyWith(color: AppTheme.muted),
          ),
        ),
        Expanded(
          child: Text(
            value,
            style: Theme.of(
              context,
            ).textTheme.labelSmall?.copyWith(fontWeight: FontWeight.w700),
          ),
        ),
      ],
    ),
  );
}
