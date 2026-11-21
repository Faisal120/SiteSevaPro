import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/theme/app_theme.dart';
import '../../../../core/widgets/app_ui.dart';
import '../../models/boq_models.dart';
import '../../providers/boq_provider.dart';
import '../widgets/boq_generation_sheet.dart';
import '../widgets/boq_widgets.dart';

class BoqScreen extends ConsumerWidget {
  const BoqScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final state = ref.watch(boqStudioControllerProvider);
    return Material(
      color: Theme.of(context).scaffoldBackgroundColor,
      child: SafeArea(
        bottom: false,
        child: state.when(
          loading: () => const BoqStudioSkeleton(),
          error: (error, stackTrace) => _BoqError(
            error: error,
            onRetry: () =>
                ref.read(boqStudioControllerProvider.notifier).load(),
          ),
          data: (data) => RefreshIndicator(
            color: AppTheme.orange,
            onRefresh: () =>
                ref.read(boqStudioControllerProvider.notifier).refresh(),
            child: LayoutBuilder(
              builder: (context, constraints) => ListView(
                key: const PageStorageKey('boq-studio-scroll'),
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
                          _BoqHeader(
                            onGenerate: () =>
                                _openGenerator(context, ref, data),
                            onRefresh: () => ref
                                .read(boqStudioControllerProvider.notifier)
                                .refresh(),
                          ),
                          if (data.isOffline) ...[
                            const SizedBox(height: 14),
                            BoqOfflineBanner(syncedAt: data.fetchedAt),
                          ],
                          const SizedBox(height: 18),
                          BoqPortfolioHero(
                            data: data,
                            onGenerate: () =>
                                _openGenerator(context, ref, data),
                          ),
                          const SizedBox(height: 26),
                          Text(
                            'Connected cost workflow',
                            style: Theme.of(context).textTheme.titleLarge
                                ?.copyWith(
                                  fontWeight: FontWeight.w800,
                                  letterSpacing: -.5,
                                ),
                          ),
                          const SizedBox(height: 5),
                          Text(
                            'Only live capabilities currently available from the SiteSeva BOQ service.',
                            style: Theme.of(context).textTheme.bodySmall
                                ?.copyWith(color: AppTheme.muted),
                          ),
                          const SizedBox(height: 14),
                          BoqCapabilityGrid(data: data),
                          const SizedBox(height: 28),
                          _BoqFilters(data: data),
                          const SizedBox(height: 22),
                          Row(
                            children: [
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      'Issued BOQs',
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
                                      '${data.visibleBoqs.length} of ${data.boqs.length} worksheets shown',
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
                                  label: const Text('Generate BOQ'),
                                  style: FilledButton.styleFrom(
                                    minimumSize: const Size(0, 52),
                                  ),
                                ),
                            ],
                          ),
                          const SizedBox(height: 14),
                          if (data.boqs.isEmpty)
                            EmptyPanel(
                              title: 'No BOQs issued yet',
                              message:
                                  'Generate the first server-calculated BOQ from an approved estimate or verified built-up area.',
                              icon: Icons.format_list_numbered_rounded,
                              actionLabel: 'Generate BOQ',
                              onAction: () =>
                                  _openGenerator(context, ref, data),
                            )
                          else
                            BoqDocumentGrid(data: data),
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
    BoqStudioData data,
  ) async {
    final boqId = await showBoqGenerationSheet(context, ref, data: data);
    if (boqId != null && context.mounted) context.go('/boq/$boqId');
  }
}

class _BoqHeader extends StatelessWidget {
  const _BoqHeader({required this.onGenerate, required this.onRefresh});
  final VoidCallback onGenerate;
  final VoidCallback onRefresh;

  @override
  Widget build(BuildContext context) => Row(
    children: [
      Expanded(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Bill of Quantities',
              style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                fontWeight: FontWeight.w800,
                letterSpacing: -.9,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              'Measured scope, unit rates and issued project baselines.',
              style: Theme.of(
                context,
              ).textTheme.bodySmall?.copyWith(color: AppTheme.muted),
            ),
          ],
        ),
      ),
      IconButton.filledTonal(
        tooltip: 'Refresh BOQs',
        onPressed: onRefresh,
        icon: const Icon(Icons.refresh_rounded),
      ),
      const SizedBox(width: 8),
      IconButton.filled(
        tooltip: 'Generate BOQ',
        onPressed: onGenerate,
        icon: const Icon(Icons.add_rounded),
        style: IconButton.styleFrom(backgroundColor: AppTheme.orange),
      ),
    ],
  ).animate().fadeIn(duration: 240.ms);
}

class _BoqFilters extends ConsumerWidget {
  const _BoqFilters({required this.data});
  final BoqStudioData data;

  @override
  Widget build(BuildContext context, WidgetRef ref) => Column(
    crossAxisAlignment: CrossAxisAlignment.start,
    children: [
      TextField(
        onChanged: ref.read(boqStudioControllerProvider.notifier).setQuery,
        decoration: const InputDecoration(
          hintText: 'Search BOQ, project, location or source estimate',
          prefixIcon: Icon(Icons.search_rounded),
        ),
      ),
      const SizedBox(height: 12),
      SizedBox(
        height: 38,
        child: ListView(
          scrollDirection: Axis.horizontal,
          children: [
            _SiteFilterChip(
              label: 'All projects',
              selected: data.siteFilter == null,
              onTap: () =>
                  ref.read(boqStudioControllerProvider.notifier).setSite(null),
            ),
            ...data.sites.map(
              (site) => _SiteFilterChip(
                label: site.name,
                selected: data.siteFilter == site.id,
                onTap: () => ref
                    .read(boqStudioControllerProvider.notifier)
                    .setSite(site.id),
              ),
            ),
          ],
        ),
      ),
    ],
  );
}

class _SiteFilterChip extends StatelessWidget {
  const _SiteFilterChip({
    required this.label,
    required this.selected,
    required this.onTap,
  });
  final String label;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.only(right: 8),
    child: Material(
      color: selected
          ? AppTheme.orange.withValues(alpha: .1)
          : Theme.of(context).cardTheme.color,
      borderRadius: BorderRadius.circular(14),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(14),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 13, vertical: 9),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(14),
            border: Border.all(
              color: selected ? AppTheme.orange : AppTheme.line,
            ),
          ),
          child: Text(
            label,
            style: Theme.of(context).textTheme.labelSmall?.copyWith(
              color: selected ? AppTheme.orange : AppTheme.muted,
              fontWeight: FontWeight.w800,
            ),
          ),
        ),
      ),
    ),
  );
}

class _BoqError extends StatelessWidget {
  const _BoqError({required this.error, required this.onRetry});
  final Object error;
  final VoidCallback onRetry;

  @override
  Widget build(BuildContext context) => ListView(
    padding: const EdgeInsets.all(20),
    children: [
      EmptyPanel(
        title: 'BOQ workspace unavailable',
        message: '$error',
        icon: Icons.cloud_off_rounded,
        actionLabel: 'Try again',
        onAction: onRetry,
      ),
    ],
  );
}
