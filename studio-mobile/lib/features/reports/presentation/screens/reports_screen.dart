import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/theme/app_theme.dart';
import '../../../../core/widgets/app_ui.dart';
import '../../models/report_models.dart';
import '../../providers/reports_provider.dart';
import '../widgets/report_composer_sheet.dart';
import '../widgets/reports_widgets.dart';

class ReportsScreen extends ConsumerStatefulWidget {
  const ReportsScreen({super.key, this.initialSiteId});

  final String? initialSiteId;

  @override
  ConsumerState<ReportsScreen> createState() => _ReportsScreenState();
}

class _ReportsScreenState extends ConsumerState<ReportsScreen> {
  bool initialFilterApplied = false;

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(reportsStudioControllerProvider);
    return Material(
      color: Theme.of(context).scaffoldBackgroundColor,
      child: SafeArea(
        bottom: false,
        child: state.when(
          loading: () => const ReportsSkeleton(),
          error: (error, stackTrace) => _ReportsError(
            error: error,
            onRetry: () =>
                ref.read(reportsStudioControllerProvider.notifier).load(),
          ),
          data: (data) {
            _applyInitialFilter(data);
            return RefreshIndicator(
              color: AppTheme.orange,
              onRefresh: () =>
                  ref.read(reportsStudioControllerProvider.notifier).refresh(),
              child: LayoutBuilder(
                builder: (context, constraints) => ListView(
                  key: const PageStorageKey('reports-studio-scroll'),
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
                            _ReportsHeader(
                              canCreate:
                                  data.canCreate && data.sites.isNotEmpty,
                              onRefresh: () => ref
                                  .read(
                                    reportsStudioControllerProvider.notifier,
                                  )
                                  .refresh(),
                              onCreate: () => _create(data),
                            ),
                            if (data.isOffline) ...[
                              const SizedBox(height: 14),
                              ReportsOfflineBanner(syncedAt: data.fetchedAt),
                            ],
                            const SizedBox(height: 17),
                            ReportsHero(
                              data: data,
                              onCreate: () => _create(data),
                            ),
                            const SizedBox(height: 14),
                            const ReportsApiScopeNotice(),
                            const SizedBox(height: 24),
                            ReportsWorkspaceSwitch(
                              value: data.workspace,
                              onChanged: ref
                                  .read(
                                    reportsStudioControllerProvider.notifier,
                                  )
                                  .setWorkspace,
                            ),
                            const SizedBox(height: 15),
                            _ReportsFilters(data: data),
                            const SizedBox(height: 22),
                            _ReportsWorkspaceContent(
                              data: data,
                              onCreate: () => _create(data),
                              onOpen: (report) =>
                                  context.push('/reports/${report.id}'),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            );
          },
        ),
      ),
    );
  }

  void _applyInitialFilter(ReportsStudioData data) {
    if (initialFilterApplied) return;
    initialFilterApplied = true;
    final siteId = widget.initialSiteId;
    if (siteId == null || data.site(siteId) == null) return;
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) {
        ref.read(reportsStudioControllerProvider.notifier).setSite(siteId);
      }
    });
  }

  Future<void> _create(ReportsStudioData data) async {
    if (!data.canCreate) return;
    if (data.isOffline) {
      _message('Reconnect before submitting a live daily report.');
      return;
    }
    if (data.sites.isEmpty) {
      _message('No assigned project site is available for reporting.');
      return;
    }
    final created = await showDailyReportComposer(
      context,
      ref,
      data,
      initialSiteId: data.siteFilter,
    );
    if (created && mounted) {
      _message('Daily report submitted to the live project record.');
    }
  }

  void _message(String value) => ScaffoldMessenger.of(
    context,
  ).showSnackBar(SnackBar(content: Text(value)));
}

class _ReportsHeader extends StatelessWidget {
  const _ReportsHeader({
    required this.canCreate,
    required this.onRefresh,
    required this.onCreate,
  });

  final bool canCreate;
  final VoidCallback onRefresh;
  final VoidCallback onCreate;

  @override
  Widget build(BuildContext context) => Row(
    children: [
      Expanded(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Daily Reports',
              style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                fontWeight: FontWeight.w800,
                letterSpacing: -.9,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              'Progress, field work, issues and site evidence.',
              style: Theme.of(
                context,
              ).textTheme.bodySmall?.copyWith(color: AppTheme.muted),
            ),
          ],
        ),
      ),
      IconButton.filledTonal(
        tooltip: 'Refresh reports',
        onPressed: onRefresh,
        icon: const Icon(Icons.refresh_rounded),
      ),
      if (canCreate) ...[
        const SizedBox(width: 8),
        IconButton.filled(
          tooltip: 'Create daily report',
          onPressed: onCreate,
          icon: const Icon(Icons.add_rounded),
        ),
      ],
    ],
  ).animate().fadeIn(duration: 240.ms);
}

class _ReportsFilters extends ConsumerWidget {
  const _ReportsFilters({required this.data});
  final ReportsStudioData data;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final controller = ref.read(reportsStudioControllerProvider.notifier);
    final search = TextField(
      enabled: data.workspace == ReportsWorkspace.logbook,
      onChanged: controller.setQuery,
      decoration: InputDecoration(
        hintText: data.workspace == ReportsWorkspace.logbook
            ? 'Search reports, work, issues...'
            : 'Search is available in Logbook',
        prefixIcon: const Icon(Icons.search_rounded),
      ),
    );
    final site = DropdownButtonFormField<String>(
      initialValue: data.siteFilter,
      isExpanded: true,
      decoration: const InputDecoration(
        labelText: 'Project',
        prefixIcon: Icon(Icons.apartment_outlined),
      ),
      items: [
        const DropdownMenuItem<String>(value: '', child: Text('All projects')),
        ...data.sites.map(
          (site) => DropdownMenuItem(
            value: site.id,
            child: Text(
              site.name,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
          ),
        ),
      ],
      onChanged: (value) =>
          controller.setSite(value == null || value.isEmpty ? null : value),
    );
    final period = DropdownButtonFormField<ReportsPeriod>(
      initialValue: data.period,
      isExpanded: true,
      decoration: const InputDecoration(
        labelText: 'Period',
        prefixIcon: Icon(Icons.date_range_outlined),
      ),
      items: ReportsPeriod.values
          .map(
            (value) => DropdownMenuItem(value: value, child: Text(value.label)),
          )
          .toList(),
      onChanged: (value) {
        if (value != null) controller.setPeriod(value);
      },
    );
    return LayoutBuilder(
      builder: (context, constraints) {
        if (constraints.maxWidth >= 760) {
          return Row(
            children: [
              Expanded(flex: 3, child: search),
              const SizedBox(width: 11),
              Expanded(flex: 2, child: site),
              const SizedBox(width: 11),
              Expanded(child: period),
            ],
          );
        }
        return Column(
          children: [
            search,
            const SizedBox(height: 11),
            Row(
              children: [
                Expanded(child: site),
                const SizedBox(width: 10),
                Expanded(child: period),
              ],
            ),
          ],
        );
      },
    );
  }
}

class _ReportsWorkspaceContent extends StatelessWidget {
  const _ReportsWorkspaceContent({
    required this.data,
    required this.onCreate,
    required this.onOpen,
  });

  final ReportsStudioData data;
  final VoidCallback onCreate;
  final ValueChanged<DailyReport> onOpen;

  @override
  Widget build(BuildContext context) => switch (data.workspace) {
    ReportsWorkspace.logbook => ReportsLogbook(
      data: data,
      onOpen: onOpen,
      onCreate: onCreate,
    ),
    ReportsWorkspace.insights => ReportsInsights(data: data),
    ReportsWorkspace.media => ReportsMediaGallery(
      data: data,
      onOpenReport: onOpen,
    ),
  };
}

class _ReportsError extends StatelessWidget {
  const _ReportsError({required this.error, required this.onRetry});
  final Object error;
  final VoidCallback onRetry;

  @override
  Widget build(BuildContext context) => ListView(
    padding: const EdgeInsets.all(20),
    children: [
      EmptyPanel(
        title: 'Daily reports unavailable',
        message: '$error',
        icon: Icons.cloud_off_rounded,
        actionLabel: 'Try again',
        onAction: onRetry,
      ),
    ],
  );
}
