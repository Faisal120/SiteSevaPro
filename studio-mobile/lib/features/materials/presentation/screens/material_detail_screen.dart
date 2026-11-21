import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/theme/app_theme.dart';
import '../../../../core/widgets/app_ui.dart';
import '../../models/material_models.dart';
import '../../providers/materials_provider.dart';
import '../widgets/material_detail_widgets.dart';
import '../widgets/material_movement_sheet.dart';
import '../widgets/materials_widgets.dart';

class MaterialDetailScreen extends ConsumerWidget {
  const MaterialDetailScreen({super.key, required this.materialId});
  final String materialId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final state = ref.watch(materialsStudioControllerProvider);
    return Material(
      color: Theme.of(context).scaffoldBackgroundColor,
      child: SafeArea(
        bottom: false,
        child: state.when(
          loading: () => const MaterialsSkeleton(),
          error: (error, stackTrace) => _DetailError(
            error: error,
            onBack: () => context.go('/'),
            onRetry: () =>
                ref.read(materialsStudioControllerProvider.notifier).load(),
          ),
          data: (data) {
            final material = data.materialFor(materialId);
            if (material == null) {
              return ListView(
                padding: const EdgeInsets.all(20),
                children: [
                  EmptyPanel(
                    title: 'Material record not found',
                    message:
                        'This material is no longer available in the assigned inventory.',
                    icon: Icons.inventory_2_outlined,
                    actionLabel: 'Back to home',
                    onAction: () => context.go('/'),
                  ),
                ],
              );
            }
            final movements = data.movementsFor(material.id);
            final siteName =
                data.siteFor(material.siteId)?.name ?? 'Assigned site';
            return RefreshIndicator(
              color: AppTheme.orange,
              onRefresh: () => ref
                  .read(materialsStudioControllerProvider.notifier)
                  .refresh(),
              child: LayoutBuilder(
                builder: (context, constraints) => ListView(
                  key: PageStorageKey('material-detail-$materialId'),
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
                                    materialsStudioControllerProvider.notifier,
                                  )
                                  .refresh(),
                            ),
                            if (data.isOffline) ...[
                              const SizedBox(height: 13),
                              MaterialsOfflineBanner(syncedAt: data.fetchedAt),
                            ],
                            const SizedBox(height: 16),
                            MaterialDetailHero(
                              material: material,
                              siteName: siteName,
                              movementCount: movements.length,
                              onMovement: () => data.isOffline
                                  ? ScaffoldMessenger.of(context).showSnackBar(
                                      const SnackBar(
                                        content: Text(
                                          'Reconnect before changing live inventory.',
                                        ),
                                      ),
                                    )
                                  : _movement(context, material),
                            ),
                            const SizedBox(height: 22),
                            LayoutBuilder(
                              builder: (context, inner) {
                                final control = MaterialControlPanel(
                                  material: material,
                                );
                                final identity = MaterialIdentityPanel(
                                  material: material,
                                  siteName: siteName,
                                );
                                if (inner.maxWidth >= 780) {
                                  return Row(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      Expanded(child: control),
                                      const SizedBox(width: 13),
                                      Expanded(child: identity),
                                    ],
                                  );
                                }
                                return Column(
                                  children: [
                                    control,
                                    const SizedBox(height: 13),
                                    identity,
                                  ],
                                );
                              },
                            ),
                            const SizedBox(height: 13),
                            const MaterialImmutableNotice(),
                            const SizedBox(height: 27),
                            Text(
                              'Movement ledger',
                              style: Theme.of(context).textTheme.titleLarge
                                  ?.copyWith(
                                    fontWeight: FontWeight.w800,
                                    letterSpacing: -.5,
                                  ),
                            ),
                            const SizedBox(height: 5),
                            Text(
                              'Up to 500 server-recorded stock entries, newest first.',
                              style: Theme.of(context).textTheme.bodySmall
                                  ?.copyWith(color: AppTheme.muted),
                            ),
                            const SizedBox(height: 13),
                            MaterialMovementTimeline(
                              movements: movements,
                              materialFor: data.materialFor,
                              siteFor: (id) =>
                                  data.siteFor(id)?.name ?? 'Assigned site',
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

  Future<void> _movement(BuildContext context, MaterialItem material) async {
    final created = await showMaterialMovementSheet(context, material);
    if (created && context.mounted) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('Stock movement recorded.')));
    }
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
              'Material Detail',
              style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                fontWeight: FontWeight.w800,
                letterSpacing: -.9,
              ),
            ),
            Text(
              'Stock position and auditable movement history.',
              style: Theme.of(
                context,
              ).textTheme.bodySmall?.copyWith(color: AppTheme.muted),
            ),
          ],
        ),
      ),
      IconButton.filledTonal(
        tooltip: 'Refresh material',
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
        title: 'Material detail unavailable',
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
