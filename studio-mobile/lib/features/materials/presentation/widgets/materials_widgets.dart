import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';

import '../../../../core/theme/app_theme.dart';
import '../../../../core/utils/app_formatters.dart';
import '../../../../core/widgets/app_ui.dart';
import '../../models/material_models.dart';

class MaterialsHero extends StatelessWidget {
  const MaterialsHero({
    super.key,
    required this.data,
    required this.onAddMaterial,
  });

  final MaterialsStudioData data;
  final VoidCallback onAddMaterial;

  @override
  Widget build(BuildContext context) => Container(
    constraints: const BoxConstraints(minHeight: 244),
    clipBehavior: Clip.antiAlias,
    decoration: BoxDecoration(
      borderRadius: BorderRadius.circular(32),
      gradient: const LinearGradient(
        colors: [Color(0xFF071522), Color(0xFF113A58), Color(0xFF0A6E72)],
        begin: Alignment.topLeft,
        end: Alignment.bottomRight,
      ),
      boxShadow: const [
        BoxShadow(
          color: Color(0x290A0E17),
          blurRadius: 34,
          offset: Offset(0, 16),
        ),
      ],
    ),
    child: Stack(
      children: [
        const Positioned.fill(child: CustomPaint(painter: _WarehouseGrid())),
        Positioned(
          right: -70,
          bottom: -105,
          child: Container(
            width: 310,
            height: 310,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: const Color(0xFF31B7AE).withValues(alpha: .11),
              border: Border.all(
                color: Colors.white.withValues(alpha: .05),
                width: 28,
              ),
            ),
          ),
        ),
        Padding(
          padding: const EdgeInsets.all(24),
          child: LayoutBuilder(
            builder: (context, constraints) {
              final compact = constraints.maxWidth < 760;
              final identity = Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Row(
                    children: [
                      const Icon(
                        Icons.inventory_2_outlined,
                        size: 18,
                        color: Color(0xFF86E0D8),
                      ),
                      const SizedBox(width: 8),
                      Text(
                        'LIVE SITE INVENTORY',
                        style: Theme.of(context).textTheme.labelSmall?.copyWith(
                          color: const Color(0xFFD3E7EB),
                          fontWeight: FontWeight.w800,
                          letterSpacing: .9,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),
                  Text(
                    'Know what is on site\nbefore the crew asks.',
                    style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                      color: Colors.white,
                      fontWeight: FontWeight.w800,
                      letterSpacing: -1,
                      height: 1.08,
                    ),
                  ),
                  const SizedBox(height: 10),
                  Text(
                    '${data.materials.length} tracked materials across '
                    '${data.stockedSiteCount} active stock locations.',
                    style: Theme.of(context).textTheme.bodySmall?.copyWith(
                      color: const Color(0xFFC0D2DB),
                      height: 1.45,
                    ),
                  ),
                  const SizedBox(height: 18),
                  FilledButton.icon(
                    onPressed: onAddMaterial,
                    icon: const Icon(Icons.add_rounded, size: 19),
                    label: const Text('Add material'),
                    style: FilledButton.styleFrom(
                      minimumSize: const Size(0, 48),
                    ),
                  ),
                ],
              );
              final metrics = _HeroMetrics(data: data);
              if (compact) {
                return Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [identity, const SizedBox(height: 22), metrics],
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
  ).animate().fadeIn(duration: 330.ms).slideY(begin: .04, end: 0);
}

class _HeroMetrics extends StatelessWidget {
  const _HeroMetrics({required this.data});
  final MaterialsStudioData data;

  @override
  Widget build(BuildContext context) => Container(
    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 21),
    decoration: BoxDecoration(
      color: Colors.white.withValues(alpha: .075),
      borderRadius: BorderRadius.circular(24),
      border: Border.all(color: Colors.white.withValues(alpha: .13)),
    ),
    child: Row(
      children: [
        _HeroMetric(value: compactInr(data.stockValue), label: 'Stock value'),
        const _HeroDivider(),
        _HeroMetric(value: '${data.lowStockCount}', label: 'Low stock'),
        const _HeroDivider(),
        _HeroMetric(value: '${data.movements.length}', label: 'Movements'),
      ],
    ),
  );
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
          style: Theme.of(context).textTheme.titleMedium?.copyWith(
            color: Colors.white,
            fontWeight: FontWeight.w800,
            letterSpacing: -.4,
          ),
        ),
        const SizedBox(height: 5),
        Text(
          label.toUpperCase(),
          textAlign: TextAlign.center,
          style: Theme.of(context).textTheme.labelSmall?.copyWith(
            color: const Color(0xFFBFCFDB),
            fontSize: 8,
            fontWeight: FontWeight.w700,
            letterSpacing: .45,
          ),
        ),
      ],
    ),
  );
}

class _HeroDivider extends StatelessWidget {
  const _HeroDivider();
  @override
  Widget build(BuildContext context) => Container(
    width: 1,
    height: 42,
    color: Colors.white.withValues(alpha: .14),
  );
}

class MaterialsWorkspaceSwitch extends StatelessWidget {
  const MaterialsWorkspaceSwitch({
    super.key,
    required this.data,
    required this.onChanged,
  });

  final MaterialsStudioData data;
  final ValueChanged<MaterialsWorkspace> onChanged;

  @override
  Widget build(BuildContext context) {
    final values = [
      MaterialsWorkspace.inventory,
      MaterialsWorkspace.movements,
      if (data.canManageVendors) MaterialsWorkspace.vendors,
    ];
    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      physics: const BouncingScrollPhysics(),
      child: Container(
        padding: const EdgeInsets.all(5),
        decoration: BoxDecoration(
          color: Theme.of(context).cardTheme.color,
          borderRadius: BorderRadius.circular(18),
          border: Border.all(color: AppTheme.line),
        ),
        child: Row(
          children: values.map((workspace) {
            final selected = workspace == data.workspace;
            return Padding(
              padding: const EdgeInsets.only(right: 3),
              child: Material(
                color: selected ? AppTheme.navy : Colors.transparent,
                borderRadius: BorderRadius.circular(14),
                child: InkWell(
                  onTap: () => onChanged(workspace),
                  borderRadius: BorderRadius.circular(14),
                  child: Padding(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 15,
                      vertical: 10,
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(
                          _workspaceIcon(workspace),
                          size: 17,
                          color: selected ? Colors.white : AppTheme.muted,
                        ),
                        const SizedBox(width: 7),
                        Text(
                          _workspaceLabel(workspace),
                          style: Theme.of(context).textTheme.labelSmall
                              ?.copyWith(
                                color: selected ? Colors.white : AppTheme.muted,
                                fontWeight: FontWeight.w800,
                              ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            );
          }).toList(),
        ),
      ),
    );
  }
}

class MaterialsCapabilityGrid extends StatelessWidget {
  const MaterialsCapabilityGrid({super.key});

  @override
  Widget build(BuildContext context) {
    const entries = [
      (
        Icons.local_shipping_outlined,
        'Site receipts',
        'Inward quantities, vendor, rate and invoice reference.',
        AppTheme.blue,
      ),
      (
        Icons.construction_outlined,
        'Field consumption',
        'Issue stock with quantity guard and auditable notes.',
        AppTheme.success,
      ),
      (
        Icons.notification_important_outlined,
        'Threshold control',
        'Live low-stock and depleted inventory visibility.',
        AppTheme.warning,
      ),
    ];
    return LayoutBuilder(
      builder: (context, constraints) {
        final columns = constraints.maxWidth >= 900
            ? 3
            : constraints.maxWidth >= 600
            ? 2
            : 1;
        final width = (constraints.maxWidth - (columns - 1) * 12) / columns;
        return Wrap(
          spacing: 12,
          runSpacing: 12,
          children: entries.indexed.map((indexed) {
            final entry = indexed.$2;
            return SizedBox(
              width: width,
              child: SurfaceCard(
                child: Row(
                  children: [
                    Container(
                      width: 44,
                      height: 44,
                      decoration: BoxDecoration(
                        color: entry.$4.withValues(alpha: .1),
                        borderRadius: BorderRadius.circular(15),
                      ),
                      child: Icon(entry.$1, color: entry.$4, size: 21),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            entry.$2,
                            style: Theme.of(context).textTheme.labelLarge
                                ?.copyWith(fontWeight: FontWeight.w800),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            entry.$3,
                            style: Theme.of(context).textTheme.labelSmall
                                ?.copyWith(color: AppTheme.muted, height: 1.35),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ).animate(delay: (indexed.$1 * 55).ms).fadeIn().slideY(begin: .05);
          }).toList(),
        );
      },
    );
  }
}

class InventoryGrid extends StatelessWidget {
  const InventoryGrid({
    super.key,
    required this.data,
    required this.onOpen,
    required this.onMovement,
  });

  final MaterialsStudioData data;
  final ValueChanged<MaterialItem> onOpen;
  final ValueChanged<MaterialItem> onMovement;

  @override
  Widget build(BuildContext context) {
    final materials = data.visibleMaterials;
    if (materials.isEmpty) {
      return EmptyPanel(
        title: data.materials.isEmpty
            ? 'No material inventory'
            : 'No matching materials',
        message: data.materials.isEmpty
            ? 'Create the first site material to begin real-time stock control.'
            : 'Adjust the search, project, category, or low-stock filter.',
        icon: Icons.inventory_2_outlined,
      );
    }
    return LayoutBuilder(
      builder: (context, constraints) {
        final columns = constraints.maxWidth >= 1120
            ? 3
            : constraints.maxWidth >= 680
            ? 2
            : 1;
        final width = (constraints.maxWidth - (columns - 1) * 13) / columns;
        return Wrap(
          spacing: 13,
          runSpacing: 13,
          children: materials.indexed.map((indexed) {
            final material = indexed.$2;
            return SizedBox(
                  width: width,
                  child: MaterialInventoryCard(
                    material: material,
                    siteName:
                        data.siteFor(material.siteId)?.name ?? 'Assigned site',
                    onOpen: () => onOpen(material),
                    onMovement: () => onMovement(material),
                  ),
                )
                .animate(delay: (indexed.$1.clamp(0, 7) * 45).ms)
                .fadeIn()
                .slideY(begin: .06, curve: Curves.easeOutCubic);
          }).toList(),
        );
      },
    );
  }
}

class MaterialInventoryCard extends StatelessWidget {
  const MaterialInventoryCard({
    super.key,
    required this.material,
    required this.siteName,
    required this.onOpen,
    required this.onMovement,
  });

  final MaterialItem material;
  final String siteName;
  final VoidCallback onOpen;
  final VoidCallback onMovement;

  @override
  Widget build(BuildContext context) {
    final tone = stockHealthColor(material.health);
    return SurfaceCard(
      onTap: onOpen,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 48,
                height: 48,
                decoration: BoxDecoration(
                  color: tone.withValues(alpha: .09),
                  borderRadius: BorderRadius.circular(16),
                ),
                child: Icon(
                  materialCategoryIcon(material.category),
                  color: tone,
                  size: 22,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      material.displayName,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: Theme.of(context).textTheme.titleSmall?.copyWith(
                        fontWeight: FontWeight.w800,
                        letterSpacing: -.3,
                      ),
                    ),
                    const SizedBox(height: 3),
                    Text(
                      '${material.category.apiValue}  |  $siteName',
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: Theme.of(
                        context,
                      ).textTheme.labelSmall?.copyWith(color: AppTheme.muted),
                    ),
                  ],
                ),
              ),
              StatusBadge(label: stockHealthLabel(material.health), tone: tone),
            ],
          ),
          const SizedBox(height: 20),
          Row(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      materialQuantity(material.stock, material.displayUnit),
                      style: Theme.of(context).textTheme.headlineSmall
                          ?.copyWith(
                            fontWeight: FontWeight.w800,
                            letterSpacing: -.9,
                          ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      'Threshold ${materialQuantity(material.lowStockThreshold, material.displayUnit)}',
                      style: Theme.of(
                        context,
                      ).textTheme.labelSmall?.copyWith(color: AppTheme.muted),
                    ),
                  ],
                ),
              ),
              Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Text(
                    compactInr(material.stockValue),
                    style: Theme.of(context).textTheme.labelLarge?.copyWith(
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                  Text(
                    '${compactInr(material.rate)}/${material.displayUnit}',
                    style: Theme.of(
                      context,
                    ).textTheme.labelSmall?.copyWith(color: AppTheme.muted),
                  ),
                ],
              ),
            ],
          ),
          const SizedBox(height: 15),
          ClipRRect(
            borderRadius: BorderRadius.circular(6),
            child: LinearProgressIndicator(
              value: (material.thresholdCoverage / 2).clamp(0, 1),
              minHeight: 6,
              backgroundColor: AppTheme.line,
              color: tone,
            ),
          ),
          const SizedBox(height: 15),
          Row(
            children: [
              Expanded(
                child: TextButton.icon(
                  onPressed: onMovement,
                  icon: const Icon(Icons.swap_vert_rounded, size: 18),
                  label: const Text('Record movement'),
                ),
              ),
              const Icon(Icons.chevron_right_rounded, color: AppTheme.muted),
            ],
          ),
        ],
      ),
    );
  }
}

class MaterialMovementTimeline extends StatelessWidget {
  const MaterialMovementTimeline({
    super.key,
    required this.movements,
    required this.materialFor,
    required this.siteFor,
  });

  final List<MaterialMovement> movements;
  final MaterialItem? Function(String id) materialFor;
  final String Function(String id) siteFor;

  @override
  Widget build(BuildContext context) {
    if (movements.isEmpty) {
      return const EmptyPanel(
        title: 'No stock movements',
        message: 'Server-recorded receipts and consumption will appear here.',
        icon: Icons.swap_vert_circle_outlined,
      );
    }
    return SurfaceCard(
      padding: EdgeInsets.zero,
      child: Column(
        children: movements.take(100).toList().indexed.map((indexed) {
          final movement = indexed.$2;
          final material = materialFor(movement.materialId);
          final inward = movement.type == MaterialMovementType.inward;
          final tone = inward ? AppTheme.success : AppTheme.orange;
          return Container(
            padding: const EdgeInsets.symmetric(horizontal: 17, vertical: 15),
            decoration: BoxDecoration(
              border: indexed.$1 == movements.take(100).length - 1
                  ? null
                  : const Border(bottom: BorderSide(color: AppTheme.line)),
            ),
            child: Row(
              children: [
                Container(
                  width: 42,
                  height: 42,
                  decoration: BoxDecoration(
                    color: tone.withValues(alpha: .09),
                    borderRadius: BorderRadius.circular(14),
                  ),
                  child: Icon(
                    inward
                        ? Icons.south_west_rounded
                        : Icons.north_east_rounded,
                    color: tone,
                    size: 19,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        material?.displayName ?? 'Material record',
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: Theme.of(context).textTheme.labelLarge?.copyWith(
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                      const SizedBox(height: 3),
                      Text(
                        '${movement.type.label}  |  ${siteFor(movement.siteId)}'
                        '${movement.vendor == null ? '' : '  |  ${movement.vendor}'}',
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: Theme.of(
                          context,
                        ).textTheme.labelSmall?.copyWith(color: AppTheme.muted),
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 10),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    Text(
                      '${inward ? '+' : '-'}${materialQuantity(movement.quantity, material?.displayUnit ?? 'units')}',
                      style: Theme.of(context).textTheme.labelLarge?.copyWith(
                        color: tone,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                    Text(
                      appDate(movement.createdAt, fallback: 'Date unavailable'),
                      style: Theme.of(context).textTheme.labelSmall?.copyWith(
                        color: AppTheme.muted,
                        fontSize: 9,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          );
        }).toList(),
      ),
    );
  }
}

class MaterialVendorGrid extends StatelessWidget {
  const MaterialVendorGrid({
    super.key,
    required this.vendors,
    required this.onDelete,
  });

  final List<MaterialVendor> vendors;
  final ValueChanged<MaterialVendor> onDelete;

  @override
  Widget build(BuildContext context) {
    if (vendors.isEmpty) {
      return const EmptyPanel(
        title: 'No material vendors',
        message: 'Add verified supplier records for receipt attribution.',
        icon: Icons.storefront_outlined,
      );
    }
    return LayoutBuilder(
      builder: (context, constraints) {
        final columns = constraints.maxWidth >= 1050
            ? 3
            : constraints.maxWidth >= 650
            ? 2
            : 1;
        final width = (constraints.maxWidth - (columns - 1) * 12) / columns;
        return Wrap(
          spacing: 12,
          runSpacing: 12,
          children: vendors.indexed.map((indexed) {
            final vendor = indexed.$2;
            return SizedBox(
              width: width,
              child: SurfaceCard(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Container(
                          width: 44,
                          height: 44,
                          decoration: BoxDecoration(
                            color: AppTheme.blue.withValues(alpha: .1),
                            borderRadius: BorderRadius.circular(15),
                          ),
                          alignment: Alignment.center,
                          child: Text(
                            vendor.initials,
                            style: const TextStyle(
                              color: AppTheme.blue,
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
                                vendor.displayName,
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                                style: Theme.of(context).textTheme.labelLarge
                                    ?.copyWith(fontWeight: FontWeight.w800),
                              ),
                              Text(
                                vendor.contact ?? 'Contact not recorded',
                                style: Theme.of(context).textTheme.labelSmall
                                    ?.copyWith(color: AppTheme.muted),
                              ),
                            ],
                          ),
                        ),
                        PopupMenuButton<String>(
                          tooltip: 'Vendor actions',
                          onSelected: (_) => onDelete(vendor),
                          itemBuilder: (context) => const [
                            PopupMenuItem(
                              value: 'delete',
                              child: Text('Remove vendor'),
                            ),
                          ],
                        ),
                      ],
                    ),
                    const SizedBox(height: 14),
                    Wrap(
                      spacing: 6,
                      runSpacing: 6,
                      children: vendor.categories.isEmpty
                          ? const [StatusBadge(label: 'General supplier')]
                          : vendor.categories
                                .take(4)
                                .map((category) => StatusBadge(label: category))
                                .toList(),
                    ),
                    const SizedBox(height: 13),
                    _VendorMeta(
                      icon: Icons.receipt_long_outlined,
                      value: vendor.gst ?? 'GST not recorded',
                    ),
                    const SizedBox(height: 7),
                    _VendorMeta(
                      icon: Icons.event_repeat_outlined,
                      value:
                          vendor.paymentTerms ?? 'Payment terms not recorded',
                    ),
                  ],
                ),
              ),
            ).animate(delay: (indexed.$1 * 45).ms).fadeIn().slideY(begin: .05);
          }).toList(),
        );
      },
    );
  }
}

class _VendorMeta extends StatelessWidget {
  const _VendorMeta({required this.icon, required this.value});
  final IconData icon;
  final String value;

  @override
  Widget build(BuildContext context) => Row(
    children: [
      Icon(icon, size: 15, color: AppTheme.muted),
      const SizedBox(width: 7),
      Expanded(
        child: Text(
          value,
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
          style: Theme.of(
            context,
          ).textTheme.labelSmall?.copyWith(color: AppTheme.muted),
        ),
      ),
    ],
  );
}

class MaterialsApiScopeNotice extends StatelessWidget {
  const MaterialsApiScopeNotice({super.key});

  @override
  Widget build(BuildContext context) => SurfaceCard(
    color: AppTheme.navy,
    child: Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          width: 42,
          height: 42,
          decoration: BoxDecoration(
            color: Colors.white.withValues(alpha: .1),
            borderRadius: BorderRadius.circular(14),
          ),
          child: const Icon(
            Icons.hub_outlined,
            color: Color(0xFFBFD5FF),
            size: 20,
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Connected API scope',
                style: Theme.of(context).textTheme.labelLarge?.copyWith(
                  color: Colors.white,
                  fontWeight: FontWeight.w800,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                'Inventory, receipts, consumption and vendors are live. '
                'Warehouses, purchase orders, transfers, returns, QR/barcode '
                'and delivery evidence remain unavailable until backend '
                'contracts are added.',
                style: Theme.of(context).textTheme.labelSmall?.copyWith(
                  color: const Color(0xFFBFCBDC),
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

class MaterialsOfflineBanner extends StatelessWidget {
  const MaterialsOfflineBanner({super.key, required this.syncedAt});
  final DateTime syncedAt;

  @override
  Widget build(BuildContext context) => Container(
    padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 11),
    decoration: BoxDecoration(
      color: AppTheme.warning.withValues(alpha: .1),
      borderRadius: BorderRadius.circular(16),
      border: Border.all(color: AppTheme.warning.withValues(alpha: .2)),
    ),
    child: Row(
      children: [
        const Icon(Icons.cloud_off_rounded, color: AppTheme.warning, size: 18),
        const SizedBox(width: 9),
        Expanded(
          child: Text(
            'Offline inventory from ${appDate(syncedAt)}. Mutations require a live connection.',
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

class MaterialsSkeleton extends StatelessWidget {
  const MaterialsSkeleton({super.key});

  @override
  Widget build(BuildContext context) => ListView(
    padding: const EdgeInsets.fromLTRB(18, 20, 18, 120),
    children: const [
      AppSkeleton(height: 62),
      SizedBox(height: 18),
      AppSkeleton(height: 252),
      SizedBox(height: 16),
      AppSkeleton(height: 104),
      SizedBox(height: 12),
      AppSkeleton(height: 224),
    ],
  );
}

Color stockHealthColor(StockHealth health) => switch (health) {
  StockHealth.healthy => AppTheme.success,
  StockHealth.low => AppTheme.warning,
  StockHealth.depleted => AppTheme.danger,
};

String stockHealthLabel(StockHealth health) => switch (health) {
  StockHealth.healthy => 'Healthy',
  StockHealth.low => 'Low stock',
  StockHealth.depleted => 'Depleted',
};

IconData materialCategoryIcon(MaterialCategory category) => switch (category) {
  MaterialCategory.cement => Icons.foundation_rounded,
  MaterialCategory.steel => Icons.view_in_ar_rounded,
  MaterialCategory.sand => Icons.landscape_outlined,
  MaterialCategory.bricks => Icons.grid_on_rounded,
  MaterialCategory.electrical => Icons.electrical_services_rounded,
  MaterialCategory.plumbing => Icons.plumbing_rounded,
  MaterialCategory.tiles => Icons.dashboard_customize_outlined,
  MaterialCategory.paint => Icons.format_paint_rounded,
  MaterialCategory.other => Icons.inventory_2_outlined,
};

String materialQuantity(double quantity, String unit) {
  final value = quantity == quantity.roundToDouble()
      ? quantity.toStringAsFixed(0)
      : quantity
            .toStringAsFixed(2)
            .replaceFirst(RegExp(r'0+$'), '')
            .replaceFirst(RegExp(r'\.$'), '');
  return '$value $unit';
}

String _workspaceLabel(MaterialsWorkspace workspace) => switch (workspace) {
  MaterialsWorkspace.inventory => 'Inventory',
  MaterialsWorkspace.movements => 'Movements',
  MaterialsWorkspace.vendors => 'Vendors',
};

IconData _workspaceIcon(MaterialsWorkspace workspace) => switch (workspace) {
  MaterialsWorkspace.inventory => Icons.inventory_2_outlined,
  MaterialsWorkspace.movements => Icons.swap_vert_circle_outlined,
  MaterialsWorkspace.vendors => Icons.storefront_outlined,
};

class _WarehouseGrid extends CustomPainter {
  const _WarehouseGrid();

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = Colors.white.withValues(alpha: .035)
      ..strokeWidth = 1;
    for (double x = 0; x < size.width; x += 38) {
      canvas.drawLine(Offset(x, 0), Offset(x, size.height), paint);
    }
    for (double y = 0; y < size.height; y += 38) {
      canvas.drawLine(Offset(0, y), Offset(size.width, y), paint);
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}
