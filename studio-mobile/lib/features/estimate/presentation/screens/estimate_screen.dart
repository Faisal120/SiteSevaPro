import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/theme/app_theme.dart';
import '../../../../core/widgets/app_ui.dart';
import '../../models/estimate_models.dart';
import '../../providers/estimate_provider.dart';
import '../widgets/estimate_generation_sheet.dart';
import '../widgets/estimate_widgets.dart';

class EstimateScreen extends ConsumerWidget {
  const EstimateScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final state = ref.watch(estimateStudioControllerProvider);
    return Material(
      color: Theme.of(context).scaffoldBackgroundColor,
      child: SafeArea(
        bottom: false,
        child: state.when(
          loading: () => const EstimateStudioSkeleton(),
          error: (error, stackTrace) => _EstimateError(
            error: error,
            onRetry: () =>
                ref.read(estimateStudioControllerProvider.notifier).load(),
          ),
          data: (data) => RefreshIndicator(
            color: AppTheme.orange,
            onRefresh: () =>
                ref.read(estimateStudioControllerProvider.notifier).refresh(),
            child: LayoutBuilder(
              builder: (context, constraints) => ListView(
                key: const PageStorageKey('estimate-studio-scroll'),
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
                          _EstimateHeader(
                            onCreate: () => _openGenerator(context, ref, data),
                            onRefresh: () => ref
                                .read(estimateStudioControllerProvider.notifier)
                                .refresh(),
                          ),
                          if (data.isOffline) ...[
                            const SizedBox(height: 14),
                            EstimateOfflineBanner(syncedAt: data.fetchedAt),
                          ],
                          const SizedBox(height: 18),
                          EstimatePortfolioHero(
                            data: data,
                            onCreate: () => _openGenerator(context, ref, data),
                          ),
                          const SizedBox(height: 26),
                          Text(
                            'Connected feasibility workflow',
                            style: Theme.of(context).textTheme.titleLarge
                                ?.copyWith(
                                  fontWeight: FontWeight.w800,
                                  letterSpacing: -.5,
                                ),
                          ),
                          const SizedBox(height: 5),
                          Text(
                            'Live capabilities currently supplied by the SiteSeva estimate service.',
                            style: Theme.of(context).textTheme.bodySmall
                                ?.copyWith(color: AppTheme.muted),
                          ),
                          const SizedBox(height: 14),
                          EstimateCapabilityGrid(data: data),
                          const SizedBox(height: 28),
                          _EstimateFilters(data: data),
                          const SizedBox(height: 22),
                          Row(
                            children: [
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      'Project estimates',
                                      style: Theme.of(context)
                                          .textTheme
                                          .titleLarge
                                          ?.copyWith(
                                            fontWeight: FontWeight.w800,
                                            letterSpacing: -.5,
                                          ),
                                    ),
                                    const SizedBox(height: 4),
                                    Text(
                                      '${data.visibleEstimates.length} of ${data.estimates.length} plans shown',
                                      style: Theme.of(context)
                                          .textTheme
                                          .bodySmall
                                          ?.copyWith(color: AppTheme.muted),
                                    ),
                                  ],
                                ),
                              ),
                              if (constraints.maxWidth >= 640)
                                FilledButton.icon(
                                  onPressed: () =>
                                      _openGenerator(context, ref, data),
                                  icon: const Icon(Icons.add_rounded),
                                  label: const Text('Create estimate'),
                                  style: FilledButton.styleFrom(
                                    minimumSize: const Size(0, 52),
                                  ),
                                ),
                            ],
                          ),
                          const SizedBox(height: 14),
                          if (data.estimates.isEmpty)
                            EmptyPanel(
                              title: 'No estimates created yet',
                              message:
                                  'Create the first server-calculated feasibility plan for a live project site.',
                              icon: Icons.calculate_outlined,
                              actionLabel: 'Create estimate',
                              onAction: () =>
                                  _openGenerator(context, ref, data),
                            )
                          else
                            EstimateDocumentGrid(data: data),
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

  Future<void> _openGenerator(
    BuildContext context,
    WidgetRef ref,
    EstimateStudioData data,
  ) async {
    final estimateId = await showEstimateGenerationSheet(
      context,
      ref,
      data: data,
    );
    if (estimateId != null && context.mounted) {
      context.go('/estimates/$estimateId');
    }
  }
}

class _EstimateHeader extends StatelessWidget {
  const _EstimateHeader({required this.onCreate, required this.onRefresh});
  final VoidCallback onCreate;
  final VoidCallback onRefresh;

  @override
  Widget build(BuildContext context) => Row(
    children: [
      Expanded(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Project Estimator',
              style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                fontWeight: FontWeight.w800,
                letterSpacing: -.9,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              'Budget feasibility, cost allocation and material planning.',
              style: Theme.of(
                context,
              ).textTheme.bodySmall?.copyWith(color: AppTheme.muted),
            ),
          ],
        ),
      ),
      IconButton.filledTonal(
        tooltip: 'Refresh estimates',
        onPressed: onRefresh,
        icon: const Icon(Icons.refresh_rounded),
      ),
      const SizedBox(width: 8),
      IconButton.filled(
        tooltip: 'Create estimate',
        onPressed: onCreate,
        icon: const Icon(Icons.add_rounded),
        style: IconButton.styleFrom(backgroundColor: AppTheme.orange),
      ),
    ],
  ).animate().fadeIn(duration: 240.ms);
}

class _EstimateFilters extends ConsumerWidget {
  const _EstimateFilters({required this.data});
  final EstimateStudioData data;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final controller = ref.read(estimateStudioControllerProvider.notifier);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        TextField(
          onChanged: controller.setQuery,
          decoration: const InputDecoration(
            hintText: 'Search estimate, project, location, type or quality',
            prefixIcon: Icon(Icons.search_rounded),
          ),
        ),
        const SizedBox(height: 12),
        SizedBox(
          height: 38,
          child: ListView(
            scrollDirection: Axis.horizontal,
            children: [
              _FilterChip(
                label: 'All projects',
                selected: data.siteFilter == null,
                onTap: () => controller.setSite(null),
              ),
              ...data.sites.map(
                (site) => _FilterChip(
                  label: site.name,
                  selected: data.siteFilter == site.id,
                  onTap: () => controller.setSite(site.id),
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 8),
        SizedBox(
          height: 38,
          child: ListView(
            scrollDirection: Axis.horizontal,
            children: [
              _FilterChip(
                label: 'All quality bands',
                selected: data.qualityFilter == null,
                onTap: () => controller.setQuality(null),
              ),
              ...EstimateQuality.values.map(
                (quality) => _FilterChip(
                  label: quality.label,
                  selected: data.qualityFilter == quality,
                  tone: estimateQualityColor(quality),
                  onTap: () => controller.setQuality(quality),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}

class _FilterChip extends StatelessWidget {
  const _FilterChip({
    required this.label,
    required this.selected,
    required this.onTap,
    this.tone = AppTheme.orange,
  });
  final String label;
  final bool selected;
  final VoidCallback onTap;
  final Color tone;

  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.only(right: 8),
    child: Material(
      color: selected
          ? tone.withValues(alpha: .1)
          : Theme.of(context).cardTheme.color,
      borderRadius: BorderRadius.circular(14),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(14),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 13, vertical: 9),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(14),
            border: Border.all(color: selected ? tone : AppTheme.line),
          ),
          child: Text(
            label,
            style: Theme.of(context).textTheme.labelSmall?.copyWith(
              color: selected ? tone : AppTheme.muted,
              fontWeight: FontWeight.w800,
            ),
          ),
        ),
      ),
    ),
  );
}

class _EstimateError extends StatelessWidget {
  const _EstimateError({required this.error, required this.onRetry});
  final Object error;
  final VoidCallback onRetry;

  @override
  Widget build(BuildContext context) => ListView(
    padding: const EdgeInsets.all(20),
    children: [
      EmptyPanel(
        title: 'Estimate workspace unavailable',
        message: '$error',
        icon: Icons.cloud_off_rounded,
        actionLabel: 'Try again',
        onAction: onRetry,
      ),
    ],
  );
}
