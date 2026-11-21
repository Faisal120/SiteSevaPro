import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/theme/app_theme.dart';
import '../../../../core/widgets/app_ui.dart';
import '../../providers/reports_provider.dart';
import '../widgets/report_detail_widgets.dart';
import '../widgets/reports_widgets.dart';

class ReportDetailScreen extends ConsumerWidget {
  const ReportDetailScreen({super.key, required this.reportId});

  final String reportId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final state = ref.watch(reportsStudioControllerProvider);
    return Material(
      color: Theme.of(context).scaffoldBackgroundColor,
      child: SafeArea(
        bottom: false,
        child: state.when(
          loading: () => const ReportsSkeleton(),
          error: (error, stackTrace) => _DetailError(
            error: error,
            onBack: () => context.go('/'),
            onRetry: () =>
                ref.read(reportsStudioControllerProvider.notifier).load(),
          ),
          data: (data) {
            final report = data.reports
                .where((item) => item.id == reportId)
                .firstOrNull;
            if (report == null) {
              return ListView(
                padding: const EdgeInsets.all(20),
                children: [
                  EmptyPanel(
                    title: 'Report record not found',
                    message:
                        'This report is not available in the assigned project workspace.',
                    icon: Icons.description_outlined,
                    actionLabel: 'Back to home',
                    onAction: () => context.go('/'),
                  ),
                ],
              );
            }
            final siteName = data.siteName(report.siteId);
            return RefreshIndicator(
              color: AppTheme.orange,
              onRefresh: () =>
                  ref.read(reportsStudioControllerProvider.notifier).refresh(),
              child: LayoutBuilder(
                builder: (context, constraints) => ListView(
                  key: PageStorageKey('report-detail-$reportId'),
                  primary: false,
                  physics: const AlwaysScrollableScrollPhysics(
                    parent: BouncingScrollPhysics(),
                  ),
                  padding: EdgeInsets.fromLTRB(
                    constraints.maxWidth >= 900 ? 30 : 18,
                    14,
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
                            _DetailHeader(
                            onBack: () => context.go('/'),
                              onRefresh: () => ref
                                  .read(
                                    reportsStudioControllerProvider.notifier,
                                  )
                                  .refresh(),
                            ),
                            if (data.isOffline) ...[
                              const SizedBox(height: 13),
                              ReportsOfflineBanner(syncedAt: data.fetchedAt),
                            ],
                            const SizedBox(height: 16),
                            ReportDetailHero(
                              report: report,
                              siteName: siteName,
                            ),
                            const SizedBox(height: 14),
                            ReportImmutableNotice(),
                            const SizedBox(height: 14),
                            LayoutBuilder(
                              builder: (context, inner) {
                                final narrative = ReportNarrativePanel(
                                  report: report,
                                );
                                final record = ReportRecordPanel(
                                  report: report,
                                  siteName: siteName,
                                );
                                if (inner.maxWidth >= 820) {
                                  return Row(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      Expanded(flex: 3, child: narrative),
                                      const SizedBox(width: 13),
                                      Expanded(flex: 2, child: record),
                                    ],
                                  );
                                }
                                return Column(
                                  children: [
                                    narrative,
                                    const SizedBox(height: 13),
                                    record,
                                  ],
                                );
                              },
                            ),
                            const SizedBox(height: 13),
                            LayoutBuilder(
                              builder: (context, inner) {
                                final work = ReportWorkPanel(report: report);
                                final issues = ReportIssuesPanel(
                                  report: report,
                                );
                                if (inner.maxWidth >= 820) {
                                  return Row(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      Expanded(child: work),
                                      const SizedBox(width: 13),
                                      Expanded(child: issues),
                                    ],
                                  );
                                }
                                return Column(
                                  children: [
                                    work,
                                    const SizedBox(height: 13),
                                    issues,
                                  ],
                                );
                              },
                            ),
                            const SizedBox(height: 13),
                            ReportNextPlanPanel(report: report),
                            const SizedBox(height: 13),
                            ReportEvidencePanel(report: report),
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
}

class _DetailHeader extends StatelessWidget {
  const _DetailHeader({required this.onBack, required this.onRefresh});
  final VoidCallback onBack;
  final VoidCallback onRefresh;

  @override
  Widget build(BuildContext context) => Row(
    children: [
      IconButton.filledTonal(
        tooltip: 'Back to home',
        onPressed: onBack,
        icon: const Icon(Icons.arrow_back_rounded),
      ),
      const SizedBox(width: 11),
      Expanded(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Report Detail',
              style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                fontWeight: FontWeight.w800,
                letterSpacing: -.9,
              ),
            ),
            Text(
              'Immutable field narrative and progress evidence.',
              style: Theme.of(
                context,
              ).textTheme.bodySmall?.copyWith(color: AppTheme.muted),
            ),
          ],
        ),
      ),
      IconButton.filledTonal(
        tooltip: 'Refresh report',
        onPressed: onRefresh,
        icon: const Icon(Icons.refresh_rounded),
      ),
    ],
  ).animate().fadeIn(duration: 240.ms);
}

class _DetailError extends StatelessWidget {
  const _DetailError({
    required this.error,
    required this.onBack,
    required this.onRetry,
  });
  final Object error;
  final VoidCallback onBack;
  final VoidCallback onRetry;

  @override
  Widget build(BuildContext context) => ListView(
    padding: const EdgeInsets.all(20),
    children: [
      EmptyPanel(
        title: 'Report detail unavailable',
        message: '$error',
        icon: Icons.cloud_off_rounded,
        actionLabel: 'Try again',
        onAction: onRetry,
      ),
      const SizedBox(height: 10),
      TextButton.icon(
        onPressed: onBack,
        icon: const Icon(Icons.arrow_back_rounded),
        label: const Text('Back to home'),
      ),
    ],
  );
}
