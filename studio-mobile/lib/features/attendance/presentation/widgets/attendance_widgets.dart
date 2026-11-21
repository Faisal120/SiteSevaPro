import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';

import '../../../../core/theme/app_theme.dart';
import '../../../../core/utils/app_formatters.dart';
import '../../../../core/widgets/app_ui.dart';
import '../../models/attendance_models.dart';
import '../../models/workforce_models.dart';

Color attendanceStatusColor(AttendanceStatus status) => switch (status) {
  AttendanceStatus.present => AppTheme.success,
  AttendanceStatus.halfDay => AppTheme.warning,
  AttendanceStatus.absent => AppTheme.danger,
  AttendanceStatus.leave => AppTheme.blue,
};

class AttendanceHero extends StatelessWidget {
  const AttendanceHero({super.key, required this.data, required this.canEdit});
  final AttendanceBoardData data;
  final bool canEdit;

  @override
  Widget build(BuildContext context) {
    final document = data.document;
    return Container(
      constraints: const BoxConstraints(minHeight: 224),
      clipBehavior: Clip.antiAlias,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(32),
        gradient: const LinearGradient(
          colors: [Color(0xFF071522), Color(0xFF123454), Color(0xFF245077)],
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
          const Positioned.fill(child: CustomPaint(painter: _FieldGrid())),
          Positioned(
            right: -60,
            top: -80,
            child: Container(
              width: 270,
              height: 270,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: AppTheme.blueBright.withValues(alpha: .1),
                border: Border.all(
                  color: Colors.white.withValues(alpha: .04),
                  width: 24,
                ),
              ),
            ),
          ),
          Padding(
            padding: const EdgeInsets.all(24),
            child: LayoutBuilder(
              builder: (context, constraints) {
                final compact = constraints.maxWidth < 720;
                final identity = Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Row(
                      children: [
                        Icon(
                          document?.isMarked == true
                              ? Icons.verified_rounded
                              : Icons.edit_calendar_outlined,
                          color: document?.isMarked == true
                              ? const Color(0xFF8CE0C2)
                              : const Color(0xFFBFD5FF),
                          size: 18,
                        ),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Text(
                            document?.isMarked == true
                                ? 'SERVER-MARKED ATTENDANCE'
                                : canEdit
                                ? 'FIELD ATTENDANCE DRAFT'
                                : 'ATTENDANCE NOT SUBMITTED',
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: Theme.of(context).textTheme.labelSmall
                                ?.copyWith(
                                  color: const Color(0xFFD2DEEC),
                                  fontWeight: FontWeight.w800,
                                  letterSpacing: .8,
                                ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 17),
                    Text(
                      data.selectedSite?.name ?? 'Field attendance',
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: Theme.of(context).textTheme.headlineSmall
                          ?.copyWith(
                            color: Colors.white,
                            fontWeight: FontWeight.w800,
                            letterSpacing: -.9,
                            height: 1.1,
                          ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      '${data.date}  |  ${data.selectedSite?.location ?? 'Assigned project'}',
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: Theme.of(context).textTheme.bodySmall?.copyWith(
                        color: const Color(0xFFBFCBDC),
                        height: 1.45,
                      ),
                    ),
                  ],
                );
                final metrics = _AttendanceHeroMetrics(data: data);
                if (compact) {
                  return Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [identity, const SizedBox(height: 23), metrics],
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
    ).animate().fadeIn(duration: 320.ms).slideY(begin: .04, end: 0);
  }
}

class _AttendanceHeroMetrics extends StatelessWidget {
  const _AttendanceHeroMetrics({required this.data});
  final AttendanceBoardData data;

  @override
  Widget build(BuildContext context) {
    final document = data.document;
    final marked = document?.isMarked == true;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 18),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: .075),
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: Colors.white.withValues(alpha: .12)),
      ),
      child: Row(
        children: [
          _HeroMetric(
            value: marked ? '${document!.checkedInCount}' : '--',
            label: 'Checked in',
          ),
          const _MetricDivider(),
          _HeroMetric(
            value: marked
                ? '${(document!.attendanceRate * 100).round()}%'
                : '--',
            label: 'Attendance',
          ),
          const _MetricDivider(),
          _HeroMetric(
            value: marked
                ? _hours(document!.overtimeHours)
                : data.canViewMemberDetails
                ? '${data.members.length}'
                : '--',
            label: marked ? 'Overtime' : 'Registered',
          ),
        ],
      ),
    );
  }
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
            letterSpacing: .45,
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

class AttendanceDraftSummary extends StatelessWidget {
  const AttendanceDraftSummary({super.key, required this.draft});
  final AttendanceDraft draft;

  @override
  Widget build(BuildContext context) {
    final metrics = [
      ('Present', '${draft.presentCount}', AppTheme.success),
      ('Half day', '${draft.halfDayCount}', AppTheme.warning),
      ('Absent', '${draft.absentCount}', AppTheme.danger),
      ('Leave', '${draft.leaveCount}', AppTheme.blue),
      ('Overtime', _hours(draft.overtimeHours), const Color(0xFF0F7C8A)),
      ('Advances', compactInr(draft.advances), AppTheme.orange),
    ];
    return LayoutBuilder(
      builder: (context, constraints) {
        final columns = constraints.maxWidth >= 900
            ? 6
            : constraints.maxWidth >= 540
            ? 3
            : 2;
        const gap = 10.0;
        final width = (constraints.maxWidth - gap * (columns - 1)) / columns;
        return Wrap(
          spacing: gap,
          runSpacing: gap,
          children: metrics.indexed.map((entry) {
            final metric = entry.$2;
            return SizedBox(
              width: width,
              height: 88,
              child:
                  SurfaceCard(
                        padding: const EdgeInsets.all(13),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Container(
                              width: 8,
                              height: 8,
                              decoration: BoxDecoration(
                                color: metric.$3,
                                shape: BoxShape.circle,
                              ),
                            ),
                            const Spacer(),
                            Text(
                              metric.$2,
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: Theme.of(context).textTheme.titleMedium
                                  ?.copyWith(fontWeight: FontWeight.w800),
                            ),
                            Text(
                              metric.$1.toUpperCase(),
                              style: Theme.of(context).textTheme.labelSmall
                                  ?.copyWith(
                                    color: AppTheme.muted,
                                    fontSize: 8,
                                    fontWeight: FontWeight.w700,
                                    letterSpacing: .45,
                                  ),
                            ),
                          ],
                        ),
                      )
                      .animate(delay: (entry.$1 * 35).ms)
                      .fadeIn(duration: 220.ms)
                      .slideY(begin: .05, end: 0),
            );
          }).toList(),
        );
      },
    );
  }
}

class AttendanceWorkerGrid extends StatelessWidget {
  const AttendanceWorkerGrid({
    super.key,
    required this.data,
    required this.canEdit,
    required this.onStatus,
    required this.onOvertime,
    required this.onAdvance,
  });
  final AttendanceBoardData data;
  final bool canEdit;
  final void Function(String labourId, AttendanceStatus status) onStatus;
  final void Function(String labourId, String value) onOvertime;
  final void Function(String labourId, String value) onAdvance;

  @override
  Widget build(BuildContext context) {
    final entries = data.draft?.orderedEntries ?? const <AttendanceEntry>[];
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
          children: entries.indexed.map((indexed) {
            final entry = indexed.$2;
            final member = data.memberFor(entry.labourId);
            return SizedBox(
              width: width,
              child:
                  AttendanceWorkerCard(
                        entry: entry,
                        member: member,
                        privacyIndex: indexed.$1 + 1,
                        canEdit: canEdit,
                        onStatus: (status) => onStatus(entry.labourId, status),
                        onOvertime: (value) =>
                            onOvertime(entry.labourId, value),
                        onAdvance: (value) => onAdvance(entry.labourId, value),
                      )
                      .animate(delay: (indexed.$1 * 35).ms)
                      .fadeIn(duration: 230.ms)
                      .slideY(begin: .04, end: 0),
            );
          }).toList(),
        );
      },
    );
  }
}

class AttendanceWorkerCard extends StatelessWidget {
  const AttendanceWorkerCard({
    super.key,
    required this.entry,
    required this.member,
    required this.privacyIndex,
    required this.canEdit,
    required this.onStatus,
    required this.onOvertime,
    required this.onAdvance,
  });
  final AttendanceEntry entry;
  final WorkforceMember? member;
  final int privacyIndex;
  final bool canEdit;
  final ValueChanged<AttendanceStatus> onStatus;
  final ValueChanged<String> onOvertime;
  final ValueChanged<String> onAdvance;

  @override
  Widget build(BuildContext context) {
    final tone = attendanceStatusColor(entry.status);
    final name = member?.displayName ?? 'Workforce member $privacyIndex';
    final trade = member?.displayTrade ?? 'Member details restricted';
    return SurfaceCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 44,
                height: 44,
                decoration: BoxDecoration(
                  color: tone.withValues(alpha: .1),
                  borderRadius: BorderRadius.circular(15),
                ),
                alignment: Alignment.center,
                child: Text(
                  member?.initials ?? '$privacyIndex',
                  style: Theme.of(context).textTheme.labelLarge?.copyWith(
                    color: tone,
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
                      name,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: Theme.of(context).textTheme.labelLarge?.copyWith(
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                    const SizedBox(height: 3),
                    Text(
                      trade,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: Theme.of(
                        context,
                      ).textTheme.labelSmall?.copyWith(color: AppTheme.muted),
                    ),
                  ],
                ),
              ),
              StatusBadge(label: entry.status.label, tone: tone),
            ],
          ),
          const SizedBox(height: 15),
          Wrap(
            spacing: 6,
            runSpacing: 6,
            children: AttendanceStatus.values
                .map(
                  (status) => _StatusChoice(
                    status: status,
                    selected: entry.status == status,
                    enabled: canEdit,
                    onTap: () => onStatus(status),
                  ),
                )
                .toList(),
          ),
          const SizedBox(height: 13),
          Row(
            children: [
              Expanded(
                child: TextFormField(
                  key: ValueKey('ot-${entry.labourId}'),
                  initialValue: _inputNumber(entry.overtimeHours),
                  enabled: canEdit,
                  keyboardType: const TextInputType.numberWithOptions(
                    decimal: true,
                  ),
                  onChanged: onOvertime,
                  decoration: const InputDecoration(
                    labelText: 'Overtime',
                    suffixText: 'hrs',
                    contentPadding: EdgeInsets.symmetric(
                      horizontal: 12,
                      vertical: 12,
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 9),
              Expanded(
                child: TextFormField(
                  key: ValueKey('advance-${entry.labourId}'),
                  initialValue: _inputNumber(entry.advance),
                  enabled: canEdit,
                  keyboardType: const TextInputType.numberWithOptions(
                    decimal: true,
                  ),
                  onChanged: onAdvance,
                  decoration: const InputDecoration(
                    labelText: 'Advance',
                    prefixText: 'INR ',
                    contentPadding: EdgeInsets.symmetric(
                      horizontal: 12,
                      vertical: 12,
                    ),
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _StatusChoice extends StatelessWidget {
  const _StatusChoice({
    required this.status,
    required this.selected,
    required this.enabled,
    required this.onTap,
  });
  final AttendanceStatus status;
  final bool selected;
  final bool enabled;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final tone = attendanceStatusColor(status);
    return Material(
      color: selected ? tone.withValues(alpha: .1) : Colors.transparent,
      borderRadius: BorderRadius.circular(11),
      child: InkWell(
        onTap: enabled ? onTap : null,
        borderRadius: BorderRadius.circular(11),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 7),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(11),
            border: Border.all(color: selected ? tone : AppTheme.line),
          ),
          child: Text(
            status.label,
            style: Theme.of(context).textTheme.labelSmall?.copyWith(
              color: selected ? tone : AppTheme.muted,
              fontSize: 9,
              fontWeight: FontWeight.w800,
            ),
          ),
        ),
      ),
    );
  }
}

class AttendanceHistory extends StatelessWidget {
  const AttendanceHistory({super.key, required this.history});
  final List<AttendanceDocument> history;

  @override
  Widget build(BuildContext context) {
    if (history.isEmpty) {
      return const EmptyPanel(
        title: 'No attendance history',
        message: 'Submitted attendance days will appear here from the server.',
        icon: Icons.history_toggle_off_rounded,
      );
    }
    return SurfaceCard(
      padding: EdgeInsets.zero,
      child: Column(
        children: history.take(8).toList().indexed.map((indexed) {
          final document = indexed.$2;
          final isLast = indexed.$1 == history.take(8).length - 1;
          return Container(
            padding: const EdgeInsets.symmetric(horizontal: 17, vertical: 14),
            decoration: BoxDecoration(
              border: isLast
                  ? null
                  : const Border(bottom: BorderSide(color: AppTheme.line)),
            ),
            child: Row(
              children: [
                Container(
                  width: 39,
                  height: 39,
                  decoration: BoxDecoration(
                    color: AppTheme.blue.withValues(alpha: .09),
                    borderRadius: BorderRadius.circular(13),
                  ),
                  child: const Icon(
                    Icons.calendar_today_outlined,
                    color: AppTheme.blue,
                    size: 18,
                  ),
                ),
                const SizedBox(width: 11),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        document.date,
                        style: Theme.of(context).textTheme.labelLarge?.copyWith(
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                      const SizedBox(height: 3),
                      Text(
                        '${document.entries.length} workforce  |  ${_hours(document.overtimeHours)} overtime',
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: Theme.of(
                          context,
                        ).textTheme.labelSmall?.copyWith(color: AppTheme.muted),
                      ),
                    ],
                  ),
                ),
                Text(
                  '${(document.attendanceRate * 100).round()}%',
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    color: AppTheme.success,
                    fontWeight: FontWeight.w800,
                  ),
                ),
              ],
            ),
          );
        }).toList(),
      ),
    );
  }
}

class AttendanceOfflineBanner extends StatelessWidget {
  const AttendanceOfflineBanner({super.key, required this.syncedAt});
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

class HalfDayPayrollWarning extends StatelessWidget {
  const HalfDayPayrollWarning({super.key});

  @override
  Widget build(BuildContext context) => Container(
    padding: const EdgeInsets.all(14),
    decoration: BoxDecoration(
      color: AppTheme.warning.withValues(alpha: .08),
      borderRadius: BorderRadius.circular(18),
      border: Border.all(color: AppTheme.warning.withValues(alpha: .2)),
    ),
    child: Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Icon(
          Icons.warning_amber_rounded,
          color: AppTheme.warning,
          size: 20,
        ),
        const SizedBox(width: 10),
        Expanded(
          child: Text(
            'Half-day status is recorded by the attendance API, but automated earnings require server rate-map alignment. Review payroll before settlement.',
            style: Theme.of(context).textTheme.labelSmall?.copyWith(
              color: AppTheme.warning,
              fontWeight: FontWeight.w700,
              height: 1.45,
            ),
          ),
        ),
      ],
    ),
  );
}

class AttendanceCapabilityNotice extends StatelessWidget {
  const AttendanceCapabilityNotice({super.key});

  @override
  Widget build(BuildContext context) => SurfaceCard(
    child: Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          width: 40,
          height: 40,
          decoration: BoxDecoration(
            color: AppTheme.blue.withValues(alpha: .09),
            borderRadius: BorderRadius.circular(13),
          ),
          child: const Icon(
            Icons.location_off_outlined,
            color: AppTheme.blue,
            size: 19,
          ),
        ),
        const SizedBox(width: 11),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Identity and location verification',
                style: Theme.of(
                  context,
                ).textTheme.labelLarge?.copyWith(fontWeight: FontWeight.w800),
              ),
              const SizedBox(height: 4),
              Text(
                'GPS, geofencing, face attendance and photo identity remain unavailable until the backend stores verifiable capture evidence.',
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

class AttendanceSkeleton extends StatelessWidget {
  const AttendanceSkeleton({super.key});

  @override
  Widget build(BuildContext context) => ListView(
    padding: const EdgeInsets.fromLTRB(18, 18, 18, 120),
    children: const [
      AppSkeleton(height: 50),
      SizedBox(height: 16),
      AppSkeleton(height: 68),
      SizedBox(height: 16),
      AppSkeleton(height: 224, radius: 32),
      SizedBox(height: 18),
      AppSkeleton(height: 88),
      SizedBox(height: 18),
      AppSkeleton(height: 260),
    ],
  );
}

String _hours(double value) => '${_inputNumber(value)}h';

String _inputNumber(double value) => value == value.roundToDouble()
    ? value.round().toString()
    : value.toStringAsFixed(1);

class _FieldGrid extends CustomPainter {
  const _FieldGrid();

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = Colors.white.withValues(alpha: .035)
      ..strokeWidth = 1;
    const gap = 32.0;
    for (double x = 0; x <= size.width; x += gap) {
      canvas.drawLine(Offset(x, 0), Offset(x, size.height), paint);
    }
    for (double y = 0; y <= size.height; y += gap) {
      canvas.drawLine(Offset(0, y), Offset(size.width, y), paint);
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}
