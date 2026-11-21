import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/theme/app_theme.dart';
import '../../../../core/utils/app_formatters.dart';
import '../../../../core/widgets/app_ui.dart';
import '../../models/estimate_models.dart';
import '../../providers/estimate_provider.dart';
import '../widgets/estimate_detail_widgets.dart';

class EstimateDetailScreen extends ConsumerWidget {
  const EstimateDetailScreen({super.key, required this.estimateId});
  final String estimateId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final detail = ref.watch(estimateDetailControllerProvider(estimateId));
    final studio = ref.watch(estimateStudioControllerProvider).valueOrNull;
    return Material(
      color: Theme.of(context).scaffoldBackgroundColor,
      child: SafeArea(
        bottom: false,
        child: detail.when(
          loading: () => const _EstimateDetailSkeleton(),
          error: (error, stackTrace) => _EstimateDetailError(
            error: error,
            onBack: () => context.go('/'),
            onRetry: () => ref
                .read(estimateDetailControllerProvider(estimateId).notifier)
                .load(),
          ),
          data: (document) {
            final siteName =
                studio?.siteFor(document.siteId)?.name ?? 'Project site';
            return LayoutBuilder(
              builder: (context, constraints) => ListView(
                key: PageStorageKey('estimate-detail-$estimateId'),
                primary: false,
                physics: const BouncingScrollPhysics(),
                padding: EdgeInsets.fromLTRB(
                  constraints.maxWidth >= 900 ? 30 : 18,
                  14,
                  constraints.maxWidth >= 900 ? 30 : 18,
                  124,
                ),
                children: [
                  Center(
                    child: ConstrainedBox(
                      constraints: const BoxConstraints(maxWidth: 1320),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          _EstimateDetailHeader(
                            document: document,
                            onBack: () => context.go('/'),
                            onRefresh: () => ref
                                .read(
                                  estimateDetailControllerProvider(
                                    estimateId,
                                  ).notifier,
                                )
                                .load(),
                          ),
                          const SizedBox(height: 16),
                          EstimateDetailHero(
                                document: document,
                                siteName: siteName,
                              )
                              .animate()
                              .fadeIn(duration: 300.ms)
                              .slideY(begin: .04, end: 0),
                          const SizedBox(height: 14),
                          const EstimatePlanningNotice(),
                          const SizedBox(height: 18),
                          _EstimateDetailWorkspace(
                            document: document,
                            branding: studio?.branding,
                            onOpenBranding: () => context.go('/branding'),
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            );
          },
        ),
      ),
    );
  }
}

class _EstimateDetailHeader extends StatelessWidget {
  const _EstimateDetailHeader({
    required this.document,
    required this.onBack,
    required this.onRefresh,
  });
  final EstimateDocument document;
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
              document.name,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: Theme.of(context).textTheme.titleLarge?.copyWith(
                fontWeight: FontWeight.w800,
                letterSpacing: -.5,
              ),
            ),
            Text(
              'Created ${appDate(document.createdAt, fallback: 'date unavailable')}',
              style: Theme.of(
                context,
              ).textTheme.labelSmall?.copyWith(color: AppTheme.muted),
            ),
          ],
        ),
      ),
      IconButton(
        tooltip: 'Refresh estimate',
        onPressed: onRefresh,
        icon: const Icon(Icons.refresh_rounded),
      ),
    ],
  );
}

class _EstimateDetailWorkspace extends StatelessWidget {
  const _EstimateDetailWorkspace({
    required this.document,
    required this.branding,
    required this.onOpenBranding,
  });
  final EstimateDocument document;
  final EstimateBranding? branding;
  final VoidCallback onOpenBranding;

  @override
  Widget build(BuildContext context) => LayoutBuilder(
    builder: (context, constraints) {
      final side = Column(
        children: [
          EstimateCostComposition(document: document),
          const SizedBox(height: 12),
          EstimateAssumptions(document: document),
          const SizedBox(height: 12),
          EstimateBrandingContext(
            branding: branding,
            onConfigure: onOpenBranding,
          ),
        ],
      );
      final main = Column(
        children: [
          EstimateMaterialSchedule(document: document),
          const SizedBox(height: 12),
          EstimateCommercialSummary(document: document),
          const SizedBox(height: 12),
          const EstimateUnavailableActions(),
        ],
      );
      if (constraints.maxWidth >= 980) {
        return Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            SizedBox(width: 330, child: side),
            const SizedBox(width: 16),
            Expanded(child: main),
          ],
        );
      }
      return Column(children: [side, const SizedBox(height: 20), main]);
    },
  );
}

class _EstimateDetailSkeleton extends StatelessWidget {
  const _EstimateDetailSkeleton();

  @override
  Widget build(BuildContext context) => ListView(
    padding: const EdgeInsets.fromLTRB(18, 18, 18, 120),
    children: const [
      AppSkeleton(height: 50),
      SizedBox(height: 16),
      AppSkeleton(height: 210, radius: 32),
      SizedBox(height: 14),
      AppSkeleton(height: 54),
      SizedBox(height: 18),
      AppSkeleton(height: 540),
    ],
  );
}

class _EstimateDetailError extends StatelessWidget {
  const _EstimateDetailError({
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
      Align(
        alignment: Alignment.centerLeft,
        child: IconButton.filledTonal(
          onPressed: onBack,
          icon: const Icon(Icons.arrow_back_rounded),
        ),
      ),
      const SizedBox(height: 16),
      EmptyPanel(
        title: 'Estimate unavailable',
        message: '$error',
        icon: Icons.cloud_off_rounded,
        actionLabel: 'Try again',
        onAction: onRetry,
      ),
    ],
  );
}
