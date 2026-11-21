import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/theme/app_theme.dart';
import '../../../../core/widgets/app_ui.dart';
import '../../models/material_models.dart';
import '../../providers/materials_provider.dart';
import '../widgets/material_creation_sheet.dart';
import '../widgets/material_movement_sheet.dart';
import '../widgets/material_vendor_sheet.dart';
import '../widgets/materials_widgets.dart';

class MaterialsScreen extends ConsumerWidget {
  const MaterialsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final state = ref.watch(materialsStudioControllerProvider);
    return Material(
      color: Theme.of(context).scaffoldBackgroundColor,
      child: SafeArea(
        bottom: false,
        child: state.when(
          loading: () => const MaterialsSkeleton(),
          error: (error, stackTrace) => _MaterialsError(
            error: error,
            onRetry: () =>
                ref.read(materialsStudioControllerProvider.notifier).load(),
          ),
          data: (data) => RefreshIndicator(
            color: AppTheme.orange,
            onRefresh: () =>
                ref.read(materialsStudioControllerProvider.notifier).refresh(),
            child: LayoutBuilder(
              builder: (context, constraints) => ListView(
                key: const PageStorageKey('materials-studio-scroll'),
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
                          _MaterialsHeader(
                            onRefresh: () => ref
                                .read(
                                  materialsStudioControllerProvider.notifier,
                                )
                                .refresh(),
                            onAdd: () => _addMaterial(context, ref, data),
                          ),
                          if (data.isOffline) ...[
                            const SizedBox(height: 14),
                            MaterialsOfflineBanner(syncedAt: data.fetchedAt),
                          ],
                          const SizedBox(height: 17),
                          MaterialsHero(
                            data: data,
                            onAddMaterial: () =>
                                _addMaterial(context, ref, data),
                          ),
                          const SizedBox(height: 18),
                          const MaterialsApiScopeNotice(),
                          const SizedBox(height: 26),
                          Text(
                            'Connected stock workflow',
                            style: Theme.of(context).textTheme.titleLarge
                                ?.copyWith(
                                  fontWeight: FontWeight.w800,
                                  letterSpacing: -.5,
                                ),
                          ),
                          const SizedBox(height: 5),
                          Text(
                            'Capabilities backed by the active material, transaction and vendor APIs.',
                            style: Theme.of(context).textTheme.bodySmall
                                ?.copyWith(color: AppTheme.muted),
                          ),
                          const SizedBox(height: 13),
                          const MaterialsCapabilityGrid(),
                          const SizedBox(height: 26),
                          Row(
                            children: [
                              Expanded(
                                child: MaterialsWorkspaceSwitch(
                                  data: data,
                                  onChanged: ref
                                      .read(
                                        materialsStudioControllerProvider
                                            .notifier,
                                      )
                                      .setWorkspace,
                                ),
                              ),
                              if (data.workspace ==
                                  MaterialsWorkspace.vendors) ...[
                                const SizedBox(width: 10),
                                FilledButton.icon(
                                  onPressed: () => _addVendor(context, ref),
                                  icon: const Icon(Icons.add_business_rounded),
                                  label: constraints.maxWidth >= 620
                                      ? const Text('Add vendor')
                                      : const SizedBox.shrink(),
                                  style: FilledButton.styleFrom(
                                    minimumSize: const Size(50, 50),
                                  ),
                                ),
                              ],
                            ],
                          ),
                          const SizedBox(height: 15),
                          _MaterialsFilters(data: data),
                          const SizedBox(height: 24),
                          _WorkspaceContent(
                            data: data,
                            onOpen: (material) =>
                                context.push('/materials/${material.id}'),
                            onMovement: (material) => data.isOffline
                                ? _offlineNotice(context)
                                : _movement(context, material),
                            onDeleteVendor: (vendor) =>
                                _deleteVendor(context, ref, vendor),
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

  Future<void> _addMaterial(
    BuildContext context,
    WidgetRef ref,
    MaterialsStudioData data,
  ) async {
    if (data.isOffline) {
      _offlineNotice(context);
      return;
    }
    final created = await showMaterialCreationSheet(context, ref, data);
    if (created && context.mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Material added to live inventory.')),
      );
    }
  }

  Future<void> _movement(BuildContext context, MaterialItem material) async {
    final created = await showMaterialMovementSheet(context, material);
    if (created && context.mounted) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('Stock movement recorded.')));
    }
  }

  Future<void> _addVendor(BuildContext context, WidgetRef ref) async {
    final created = await showMaterialVendorSheet(context, ref);
    if (created && context.mounted) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('Material vendor created.')));
    }
  }

  Future<void> _deleteVendor(
    BuildContext context,
    WidgetRef ref,
    MaterialVendor vendor,
  ) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Remove vendor?'),
        content: Text(
          '${vendor.displayName} will be removed from the contractor vendor directory.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Remove'),
          ),
        ],
      ),
    );
    if (confirmed != true) return;
    final deleted = await ref
        .read(materialsActionControllerProvider.notifier)
        .deleteVendor(vendor.id);
    if (deleted && context.mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('${vendor.displayName} was removed.')),
      );
    }
  }

  void _offlineNotice(BuildContext context) =>
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Reconnect before changing live inventory.'),
        ),
      );
}

class _MaterialsHeader extends StatelessWidget {
  const _MaterialsHeader({required this.onRefresh, required this.onAdd});
  final VoidCallback onRefresh;
  final VoidCallback onAdd;

  @override
  Widget build(BuildContext context) => Row(
    children: [
      Expanded(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Materials & Stock',
              style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                fontWeight: FontWeight.w800,
                letterSpacing: -.9,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              'Site inventory, field consumption and supplier context.',
              style: Theme.of(
                context,
              ).textTheme.bodySmall?.copyWith(color: AppTheme.muted),
            ),
          ],
        ),
      ),
      IconButton.filledTonal(
        tooltip: 'Refresh stock',
        onPressed: onRefresh,
        icon: const Icon(Icons.refresh_rounded),
      ),
      const SizedBox(width: 8),
      IconButton.filled(
        tooltip: 'Add material',
        onPressed: onAdd,
        icon: const Icon(Icons.add_rounded),
        style: IconButton.styleFrom(backgroundColor: AppTheme.orange),
      ),
    ],
  ).animate().fadeIn(duration: 240.ms);
}

class _MaterialsFilters extends ConsumerWidget {
  const _MaterialsFilters({required this.data});
  final MaterialsStudioData data;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final controller = ref.read(materialsStudioControllerProvider.notifier);
    final hint = switch (data.workspace) {
      MaterialsWorkspace.inventory => 'Search material, category or site',
      MaterialsWorkspace.movements => 'Search material, vendor or note',
      MaterialsWorkspace.vendors => 'Search vendor, GST or category',
    };
    return SurfaceCard(
      child: LayoutBuilder(
        builder: (context, constraints) {
          final search = TextFormField(
            key: ValueKey('materials-search-${data.workspace.name}'),
            initialValue: data.query,
            onChanged: controller.setQuery,
            decoration: InputDecoration(
              hintText: hint,
              prefixIcon: const Icon(Icons.search_rounded),
            ),
          );
          final site = DropdownButtonFormField<String>(
            initialValue: data.siteFilter,
            isExpanded: true,
            decoration: const InputDecoration(labelText: 'Project site'),
            items: [
              const DropdownMenuItem(value: '', child: Text('All sites')),
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
            onChanged: (value) => controller.setSite(
              value == null || value.isEmpty ? null : value,
            ),
          );
          if (data.workspace == MaterialsWorkspace.vendors) return search;
          if (constraints.maxWidth >= 760) {
            return Row(
              children: [
                Expanded(flex: 2, child: search),
                const SizedBox(width: 10),
                Expanded(child: site),
                if (data.workspace == MaterialsWorkspace.inventory) ...[
                  const SizedBox(width: 10),
                  _InventoryFilterActions(data: data),
                ],
              ],
            );
          }
          return Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              search,
              const SizedBox(height: 10),
              site,
              if (data.workspace == MaterialsWorkspace.inventory) ...[
                const SizedBox(height: 10),
                _InventoryFilterActions(data: data),
              ],
            ],
          );
        },
      ),
    );
  }
}

class _InventoryFilterActions extends ConsumerWidget {
  const _InventoryFilterActions({required this.data});
  final MaterialsStudioData data;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final controller = ref.read(materialsStudioControllerProvider.notifier);
    return Wrap(
      spacing: 7,
      runSpacing: 7,
      children: [
        PopupMenuButton<String>(
          tooltip: 'Filter category',
          onSelected: (value) => controller.setCategory(
            value == 'ALL'
                ? null
                : MaterialCategory.values.firstWhere(
                    (category) => category.apiValue == value,
                  ),
          ),
          itemBuilder: (context) => [
            const PopupMenuItem(value: 'ALL', child: Text('All categories')),
            ...MaterialCategory.values.map(
              (category) => PopupMenuItem(
                value: category.apiValue,
                child: Text(category.apiValue),
              ),
            ),
          ],
          child: _FilterChipSurface(
            icon: Icons.category_outlined,
            label: data.categoryFilter?.apiValue ?? 'Category',
            selected: data.categoryFilter != null,
          ),
        ),
        InkWell(
          onTap: controller.toggleLowStock,
          borderRadius: BorderRadius.circular(14),
          child: _FilterChipSurface(
            icon: Icons.warning_amber_rounded,
            label: 'Low stock',
            selected: data.lowStockOnly,
          ),
        ),
      ],
    );
  }
}

class _FilterChipSurface extends StatelessWidget {
  const _FilterChipSurface({
    required this.icon,
    required this.label,
    required this.selected,
  });
  final IconData icon;
  final String label;
  final bool selected;

  @override
  Widget build(BuildContext context) => Container(
    height: 48,
    padding: const EdgeInsets.symmetric(horizontal: 12),
    decoration: BoxDecoration(
      color: selected
          ? AppTheme.blue.withValues(alpha: .09)
          : Colors.transparent,
      borderRadius: BorderRadius.circular(14),
      border: Border.all(color: selected ? AppTheme.blue : AppTheme.line),
    ),
    child: Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(icon, size: 17, color: selected ? AppTheme.blue : AppTheme.muted),
        const SizedBox(width: 7),
        Text(
          label,
          style: Theme.of(context).textTheme.labelSmall?.copyWith(
            color: selected ? AppTheme.blue : AppTheme.muted,
            fontWeight: FontWeight.w800,
          ),
        ),
      ],
    ),
  );
}

class _WorkspaceContent extends StatelessWidget {
  const _WorkspaceContent({
    required this.data,
    required this.onOpen,
    required this.onMovement,
    required this.onDeleteVendor,
  });
  final MaterialsStudioData data;
  final ValueChanged<MaterialItem> onOpen;
  final ValueChanged<MaterialItem> onMovement;
  final ValueChanged<MaterialVendor> onDeleteVendor;

  @override
  Widget build(BuildContext context) => switch (data.workspace) {
    MaterialsWorkspace.inventory => InventoryGrid(
      data: data,
      onOpen: onOpen,
      onMovement: onMovement,
    ),
    MaterialsWorkspace.movements => MaterialMovementTimeline(
      movements: data.visibleMovements,
      materialFor: data.materialFor,
      siteFor: (id) => data.siteFor(id)?.name ?? 'Assigned site',
    ),
    MaterialsWorkspace.vendors => MaterialVendorGrid(
      vendors: data.visibleVendors,
      onDelete: onDeleteVendor,
    ),
  };
}

class _MaterialsError extends StatelessWidget {
  const _MaterialsError({required this.error, required this.onRetry});
  final Object error;
  final VoidCallback onRetry;

  @override
  Widget build(BuildContext context) => ListView(
    padding: const EdgeInsets.all(20),
    children: [
      EmptyPanel(
        title: 'Stock workspace unavailable',
        message: '$error',
        icon: Icons.cloud_off_rounded,
        actionLabel: 'Try again',
        onAction: onRetry,
      ),
    ],
  );
}
