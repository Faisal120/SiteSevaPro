import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/network/api_service.dart';
import '../../../../core/theme/app_theme.dart';
import '../../../../core/widgets/app_ui.dart';
import '../../../auth/providers/auth_provider.dart';
import '../../models/attendance_models.dart';
import '../../providers/workforce_provider.dart';
import '../widgets/attendance_widgets.dart';

class AttendanceScreen extends ConsumerWidget {
  const AttendanceScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final state = ref.watch(attendanceBoardControllerProvider);
    final user = ref.watch(authControllerProvider).valueOrNull;
    final canEdit = user?.isContractor == true || user?.isSupervisor == true;
    return Material(
      color: Theme.of(context).scaffoldBackgroundColor,
      child: SafeArea(
        bottom: false,
        child: state.when(
          loading: () => const AttendanceSkeleton(),
          error: (error, stackTrace) => _AttendanceError(
            error: error,
            onRetry: () =>
                ref.read(attendanceBoardControllerProvider.notifier).load(),
          ),
          data: (data) => RefreshIndicator(
            color: AppTheme.orange,
            onRefresh: () =>
                ref.read(attendanceBoardControllerProvider.notifier).refresh(),
            child: LayoutBuilder(
              builder: (context, constraints) => ListView(
                key: const PageStorageKey('attendance-workspace-scroll'),
                primary: false,
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
                          _AttendanceHeader(
                            canEdit: canEdit,
                            onRefresh: () => ref
                                .read(
                                  attendanceBoardControllerProvider.notifier,
                                )
                                .refresh(),
                          ),
                          if (data.isOffline) ...[
                            const SizedBox(height: 14),
                            AttendanceOfflineBanner(syncedAt: data.fetchedAt),
                          ],
                          const SizedBox(height: 16),
                          _AttendanceCommandBar(data: data),
                          if (!data.hasSite) ...[
                            const SizedBox(height: 18),
                            const EmptyPanel(
                              title: 'No project sites assigned',
                              message:
                                  'Attendance becomes available when this role is assigned to a live project site.',
                              icon: Icons.apartment_outlined,
                            ),
                          ] else ...[
                            const SizedBox(height: 16),
                            AttendanceHero(data: data, canEdit: canEdit),
                            const SizedBox(height: 18),
                            const AttendanceCapabilityNotice(),
                            if (data.draft?.halfDayCount case final count?
                                when count > 0) ...[
                              const SizedBox(height: 12),
                              const HalfDayPayrollWarning(),
                            ],
                            const SizedBox(height: 26),
                            _BoardHeading(data: data, canEdit: canEdit),
                            const SizedBox(height: 13),
                            if (!data.hasWorkforce)
                              EmptyPanel(
                                title: data.isMarked
                                    ? 'No entries on this attendance day'
                                    : 'No workforce available',
                                message: data.canViewMemberDetails
                                    ? 'Add workforce profiles to this project before marking attendance.'
                                    : 'No attendance entries were submitted for this date.',
                                icon: Icons.groups_outlined,
                              )
                            else ...[
                              AttendanceDraftSummary(draft: data.draft!),
                              const SizedBox(height: 16),
                              AttendanceWorkerGrid(
                                data: data,
                                canEdit: canEdit,
                                onStatus: ref
                                    .read(
                                      attendanceBoardControllerProvider
                                          .notifier,
                                    )
                                    .setStatus,
                                onOvertime: ref
                                    .read(
                                      attendanceBoardControllerProvider
                                          .notifier,
                                    )
                                    .setOvertime,
                                onAdvance: ref
                                    .read(
                                      attendanceBoardControllerProvider
                                          .notifier,
                                    )
                                    .setAdvance,
                              ),
                              if (canEdit) ...[
                                const SizedBox(height: 16),
                                _AttendanceSavePanel(draft: data.draft!),
                              ],
                            ],
                            const SizedBox(height: 28),
                            Text(
                              'Recent attendance',
                              style: Theme.of(context).textTheme.titleLarge
                                  ?.copyWith(
                                    fontWeight: FontWeight.w800,
                                    letterSpacing: -.5,
                                  ),
                            ),
                            const SizedBox(height: 5),
                            Text(
                              'Up to 60 server-recorded days for the selected project.',
                              style: Theme.of(context).textTheme.bodySmall
                                  ?.copyWith(color: AppTheme.muted),
                            ),
                            const SizedBox(height: 13),
                            AttendanceHistory(history: data.history),
                          ],
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

class _AttendanceHeader extends StatelessWidget {
  const _AttendanceHeader({required this.canEdit, required this.onRefresh});
  final bool canEdit;
  final VoidCallback onRefresh;

  @override
  Widget build(BuildContext context) => Row(
    children: [
      Expanded(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Field Attendance',
              style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                fontWeight: FontWeight.w800,
                letterSpacing: -.9,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              canEdit
                  ? 'Crew presence, overtime, advances and payroll linkage.'
                  : 'Read-only attendance visibility for assigned projects.',
              style: Theme.of(
                context,
              ).textTheme.bodySmall?.copyWith(color: AppTheme.muted),
            ),
          ],
        ),
      ),
      IconButton.filledTonal(
        tooltip: 'Refresh attendance',
        onPressed: onRefresh,
        icon: const Icon(Icons.refresh_rounded),
      ),
    ],
  ).animate().fadeIn(duration: 240.ms);
}

class _AttendanceCommandBar extends ConsumerWidget {
  const _AttendanceCommandBar({required this.data});
  final AttendanceBoardData data;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final controller = ref.read(attendanceBoardControllerProvider.notifier);
    return SurfaceCard(
      child: LayoutBuilder(
        builder: (context, constraints) {
          final siteSelector = DropdownButtonFormField<String>(
            key: ValueKey('attendance-site-${data.siteId}'),
            initialValue: data.siteId,
            isExpanded: true,
            decoration: const InputDecoration(
              labelText: 'Project site',
              prefixIcon: Icon(Icons.apartment_rounded),
            ),
            items: data.sites
                .map(
                  (site) => DropdownMenuItem(
                    value: site.id,
                    child: Text(
                      site.name,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                )
                .toList(),
            onChanged: (value) {
              if (value != null) controller.selectSite(value);
            },
          );
          final dateSelector = OutlinedButton.icon(
            onPressed: () => _pickDate(context, controller, data.date),
            icon: const Icon(Icons.calendar_month_rounded, size: 19),
            label: Text(data.date),
            style: OutlinedButton.styleFrom(minimumSize: const Size(0, 58)),
          );
          if (constraints.maxWidth >= 620) {
            return Row(
              children: [
                Expanded(child: siteSelector),
                const SizedBox(width: 12),
                SizedBox(width: 210, child: dateSelector),
              ],
            );
          }
          return Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [siteSelector, const SizedBox(height: 10), dateSelector],
          );
        },
      ),
    );
  }

  Future<void> _pickDate(
    BuildContext context,
    AttendanceBoardController controller,
    String value,
  ) async {
    final initial = DateTime.tryParse(value) ?? DateTime.now();
    final selected = await showDatePicker(
      context: context,
      initialDate: initial,
      firstDate: DateTime.now().subtract(const Duration(days: 365)),
      lastDate: DateTime.now(),
      helpText: 'Choose attendance date',
    );
    if (selected != null) await controller.selectDate(selected);
  }
}

class _BoardHeading extends ConsumerWidget {
  const _BoardHeading({required this.data, required this.canEdit});
  final AttendanceBoardData data;
  final bool canEdit;

  @override
  Widget build(BuildContext context, WidgetRef ref) => Row(
    crossAxisAlignment: CrossAxisAlignment.end,
    children: [
      Expanded(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              data.isMarked ? 'Submitted crew sheet' : 'Crew attendance draft',
              style: Theme.of(context).textTheme.titleLarge?.copyWith(
                fontWeight: FontWeight.w800,
                letterSpacing: -.5,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              data.isMarked
                  ? 'Edit and resubmit to replace this date on the server.'
                  : canEdit
                  ? 'Review every crew member before submitting.'
                  : 'No submitted workforce details are available.',
              style: Theme.of(
                context,
              ).textTheme.bodySmall?.copyWith(color: AppTheme.muted),
            ),
          ],
        ),
      ),
      if (canEdit && data.hasWorkforce)
        PopupMenuButton<AttendanceStatus>(
          tooltip: 'Bulk attendance',
          onSelected: ref
              .read(attendanceBoardControllerProvider.notifier)
              .markAll,
          itemBuilder: (context) => AttendanceStatus.values
              .map(
                (status) => PopupMenuItem(
                  value: status,
                  child: Text('Mark all ${status.label.toLowerCase()}'),
                ),
              )
              .toList(),
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 9),
            decoration: BoxDecoration(
              color: AppTheme.orange.withValues(alpha: .09),
              borderRadius: BorderRadius.circular(14),
            ),
            child: const Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(Icons.done_all_rounded, color: AppTheme.orange, size: 18),
                SizedBox(width: 7),
                Text(
                  'Mark all',
                  style: TextStyle(
                    color: AppTheme.orange,
                    fontSize: 11,
                    fontWeight: FontWeight.w800,
                  ),
                ),
              ],
            ),
          ),
        ),
    ],
  );
}

class _AttendanceSavePanel extends ConsumerWidget {
  const _AttendanceSavePanel({required this.draft});
  final AttendanceDraft draft;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final action = ref.watch(attendanceActionControllerProvider);
    final error = action.hasError ? action.error : null;
    return SurfaceCard(
      color: AppTheme.navy,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 42,
                height: 42,
                decoration: BoxDecoration(
                  color: Colors.white.withValues(alpha: .1),
                  borderRadius: BorderRadius.circular(14),
                ),
                child: const Icon(
                  Icons.cloud_upload_outlined,
                  color: Color(0xFFBFD5FF),
                  size: 20,
                ),
              ),
              const SizedBox(width: 11),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Submit attendance to payroll ledger',
                      style: Theme.of(context).textTheme.labelLarge?.copyWith(
                        color: Colors.white,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                    const SizedBox(height: 3),
                    Text(
                      '${draft.entries.length} entries for ${draft.date}',
                      style: Theme.of(context).textTheme.labelSmall?.copyWith(
                        color: const Color(0xFFBFCBDC),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          if (error != null) ...[
            const SizedBox(height: 13),
            Text(
              error is ApiException ? error.message : '$error',
              style: Theme.of(context).textTheme.labelSmall?.copyWith(
                color: const Color(0xFFFFB3B9),
                fontWeight: FontWeight.w700,
              ),
            ),
          ],
          const SizedBox(height: 15),
          FilledButton.icon(
            onPressed: action.isLoading ? null : () => _save(context, ref),
            icon: action.isLoading
                ? const SizedBox.square(
                    dimension: 18,
                    child: CircularProgressIndicator(
                      strokeWidth: 2,
                      color: Colors.white,
                    ),
                  )
                : const Icon(Icons.check_rounded),
            label: Text(
              action.isLoading ? 'Submitting attendance...' : 'Submit day',
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _save(BuildContext context, WidgetRef ref) async {
    final validation = draft.validationMessage;
    if (validation != null) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text(validation)));
      return;
    }
    final saved = await ref
        .read(attendanceActionControllerProvider.notifier)
        .save(draft);
    if (saved != null && context.mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Attendance submitted successfully.')),
      );
    }
  }
}

class _AttendanceError extends StatelessWidget {
  const _AttendanceError({required this.error, required this.onRetry});
  final Object error;
  final VoidCallback onRetry;

  @override
  Widget build(BuildContext context) => ListView(
    padding: const EdgeInsets.all(20),
    children: [
      EmptyPanel(
        title: 'Attendance workspace unavailable',
        message: '$error',
        icon: Icons.cloud_off_rounded,
        actionLabel: 'Try again',
        onAction: onRetry,
      ),
    ],
  );
}
