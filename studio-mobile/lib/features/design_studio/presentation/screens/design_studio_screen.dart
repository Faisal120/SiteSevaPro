import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/state/app_state.dart';
import '../../../../core/theme/app_theme.dart';
import '../../../../core/widgets/app_ui.dart';
import '../../models/design_models.dart';
import '../../providers/design_studio_provider.dart';
import '../widgets/design_brief_sheet.dart';
import '../widgets/design_studio_widgets.dart';

class DesignStudioScreen extends ConsumerWidget {
  const DesignStudioScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final state = ref.watch(designStudioControllerProvider);
    final user = ref.watch(authControllerProvider).valueOrNull;
    final canManage = user?.isContractor == true;
    return Material(
      color: Theme.of(context).scaffoldBackgroundColor,
      child: SafeArea(
        bottom: false,
        child: state.when(
          loading: () => const DesignStudioSkeleton(),
          error: (error, stackTrace) => _DesignStudioError(
            error: error,
            onRetry: () =>
                ref.read(designStudioControllerProvider.notifier).load(),
          ),
          data: (data) => RefreshIndicator(
            color: AppTheme.orange,
            onRefresh: () =>
                ref.read(designStudioControllerProvider.notifier).refresh(),
            child: LayoutBuilder(
              builder: (context, constraints) => ListView(
                key: const PageStorageKey('design-studio-scroll'),
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
                          _StudioHeader(
                            canManage: canManage,
                            onCreate: () => _openBrief(context, ref, data),
                            onRefresh: () => ref
                                .read(designStudioControllerProvider.notifier)
                                .refresh(),
                          ),
                          if (data.isOffline) ...[
                            const SizedBox(height: 14),
                            DesignOfflineBanner(syncedAt: data.fetchedAt),
                          ],
                          const SizedBox(height: 18),
                          DesignStudioHero(
                            data: data,
                            canManage: canManage,
                            onGenerate: () => _openBrief(context, ref, data),
                            onWallet: () => context.go('/wallet'),
                          ),
                          const SizedBox(height: 24),
                          Text(
                            'Production workflow',
                            style: Theme.of(context).textTheme.titleLarge
                                ?.copyWith(
                                  fontWeight: FontWeight.w800,
                                  letterSpacing: -.5,
                                ),
                          ),
                          const SizedBox(height: 5),
                          Text(
                            'Capabilities currently connected to the SiteSeva backend.',
                            style: Theme.of(context).textTheme.bodySmall
                                ?.copyWith(color: AppTheme.muted),
                          ),
                          const SizedBox(height: 14),
                          const DesignCapabilityGrid(),
                          const SizedBox(height: 28),
                          _DesignSearchAndFilters(data: data),
                          const SizedBox(height: 22),
                          Row(
                            children: [
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      canManage
                                          ? 'Design versions'
                                          : 'Assigned design sets',
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
                                      '${data.visibleDesigns.length} of ${data.designs.length} versions shown',
                                      style: Theme.of(context)
                                          .textTheme
                                          .bodySmall
                                          ?.copyWith(color: AppTheme.muted),
                                    ),
                                  ],
                                ),
                              ),
                              if (canManage && constraints.maxWidth >= 640)
                                FilledButton.icon(
                                  onPressed: () =>
                                      _openBrief(context, ref, data),
                                  icon: const Icon(Icons.add_rounded),
                                  label: const Text('New floor plan'),
                                  style: FilledButton.styleFrom(
                                    minimumSize: const Size(0, 52),
                                  ),
                                ),
                            ],
                          ),
                          const SizedBox(height: 14),
                          if (data.designs.isEmpty)
                            EmptyPanel(
                              title: canManage
                                  ? 'No design versions yet'
                                  : 'No designs assigned yet',
                              message: canManage
                                  ? 'Start with a real site brief. Generated floor plans and subsequent revisions will be stored here.'
                                  : 'Design versions linked to your assigned sites will appear here for review.',
                              icon: Icons.architecture_rounded,
                              actionLabel: canManage
                                  ? 'Start floor plan'
                                  : null,
                              onAction: canManage
                                  ? () => _openBrief(context, ref, data)
                                  : null,
                            )
                          else
                            DesignVersionGrid(
                              designs: data.visibleDesigns,
                              data: data,
                            ),
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

  Future<void> _openBrief(
    BuildContext context,
    WidgetRef ref,
    DesignStudioData data,
  ) async {
    final designId = await showDesignBriefSheet(context, ref, data: data);
    if (designId != null && context.mounted) {
      context.go('/design-studio/design/$designId');
    }
  }
}

class _StudioHeader extends StatelessWidget {
  const _StudioHeader({
    required this.canManage,
    required this.onCreate,
    required this.onRefresh,
  });

  final bool canManage;
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
              'AI Design Studio',
              style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                fontWeight: FontWeight.w800,
                letterSpacing: -.9,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              canManage
                  ? 'Generate, govern and issue architectural concepts.'
                  : 'Review approved concepts for your project sites.',
              style: Theme.of(
                context,
              ).textTheme.bodySmall?.copyWith(color: AppTheme.muted),
            ),
          ],
        ),
      ),
      IconButton.filledTonal(
        tooltip: 'Refresh studio',
        onPressed: onRefresh,
        icon: const Icon(Icons.refresh_rounded),
      ),
      if (canManage) ...[
        const SizedBox(width: 8),
        IconButton.filled(
          tooltip: 'Generate floor plan',
          onPressed: onCreate,
          icon: const Icon(Icons.add_rounded),
          style: IconButton.styleFrom(backgroundColor: AppTheme.orange),
        ),
      ],
    ],
  ).animate().fadeIn(duration: 240.ms);
}

class _DesignSearchAndFilters extends ConsumerWidget {
  const _DesignSearchAndFilters({required this.data});
  final DesignStudioData data;

  @override
  Widget build(BuildContext context, WidgetRef ref) => Column(
    crossAxisAlignment: CrossAxisAlignment.start,
    children: [
      TextField(
        onChanged: ref.read(designStudioControllerProvider.notifier).setQuery,
        decoration: const InputDecoration(
          hintText: 'Search project, site or design type',
          prefixIcon: Icon(Icons.search_rounded),
        ),
      ),
      const SizedBox(height: 12),
      SizedBox(
        height: 38,
        child: ListView(
          scrollDirection: Axis.horizontal,
          children: [
            _StatusFilter(
              label: 'All ${data.designs.length}',
              selected: data.statusFilter == null,
              onTap: () => ref
                  .read(designStudioControllerProvider.notifier)
                  .setStatus(null),
            ),
            ...DesignStatus.values.map(
              (status) => _StatusFilter(
                label: '${status.label} ${data.count(status)}',
                selected: data.statusFilter == status,
                onTap: () => ref
                    .read(designStudioControllerProvider.notifier)
                    .setStatus(status),
              ),
            ),
          ],
        ),
      ),
    ],
  );
}

class _StatusFilter extends StatelessWidget {
  const _StatusFilter({
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
    child: ChoiceChip(
      label: Text(label),
      selected: selected,
      onSelected: (_) => onTap(),
      selectedColor: AppTheme.orange.withValues(alpha: .12),
      side: BorderSide(color: selected ? AppTheme.orange : AppTheme.line),
      labelStyle: TextStyle(
        color: selected ? AppTheme.orange : AppTheme.muted,
        fontSize: 11,
        fontWeight: FontWeight.w700,
      ),
    ),
  );
}

class _DesignStudioError extends StatelessWidget {
  const _DesignStudioError({required this.error, required this.onRetry});
  final Object error;
  final VoidCallback onRetry;

  @override
  Widget build(BuildContext context) => ListView(
    physics: const AlwaysScrollableScrollPhysics(),
    padding: const EdgeInsets.all(20),
    children: [
      const SizedBox(height: 70),
      EmptyPanel(
        title: 'Design Studio is unavailable',
        message: '$error',
        icon: Icons.cloud_off_rounded,
        actionLabel: 'Try again',
        onAction: onRetry,
      ),
    ],
  );
}
