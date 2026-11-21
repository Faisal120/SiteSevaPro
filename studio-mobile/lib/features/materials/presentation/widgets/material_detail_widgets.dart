import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';

import '../../../../core/theme/app_theme.dart';
import '../../../../core/utils/app_formatters.dart';
import '../../../../core/widgets/app_ui.dart';
import '../../models/material_models.dart';
import 'materials_widgets.dart';

class MaterialDetailHero extends StatelessWidget {
  const MaterialDetailHero({
    super.key,
    required this.material,
    required this.siteName,
    required this.movementCount,
    required this.onMovement,
  });

  final MaterialItem material;
  final String siteName;
  final int movementCount;
  final VoidCallback onMovement;

  @override
  Widget build(BuildContext context) {
    final tone = stockHealthColor(material.health);
    return Container(
      constraints: const BoxConstraints(minHeight: 240),
      clipBehavior: Clip.antiAlias,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(32),
        gradient: const LinearGradient(
          colors: [Color(0xFF071522), Color(0xFF123455), Color(0xFF244E6E)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        boxShadow: const [
          BoxShadow(
            color: Color(0x290A0E17),
            blurRadius: 32,
            offset: Offset(0, 15),
          ),
        ],
      ),
      child: Stack(
        children: [
          Positioned(
            right: -54,
            top: -70,
            child: Container(
              width: 260,
              height: 260,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: tone.withValues(alpha: .1),
                border: Border.all(
                  width: 25,
                  color: Colors.white.withValues(alpha: .04),
                ),
              ),
            ),
          ),
          Padding(
            padding: const EdgeInsets.all(24),
            child: LayoutBuilder(
              builder: (context, constraints) {
                final compact = constraints.maxWidth < 720;
                final identity = Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Row(
                      children: [
                        Icon(
                          materialCategoryIcon(material.category),
                          color: const Color(0xFFBFD5FF),
                          size: 18,
                        ),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Text(
                            '${material.category.apiValue.toUpperCase()}  |  $siteName',
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: Theme.of(context).textTheme.labelSmall
                                ?.copyWith(
                                  color: const Color(0xFFD2DEEC),
                                  fontWeight: FontWeight.w800,
                                  letterSpacing: .7,
                                ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 16),
                    Text(
                      material.displayName,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: Theme.of(context).textTheme.headlineSmall
                          ?.copyWith(
                            color: Colors.white,
                            fontWeight: FontWeight.w800,
                            letterSpacing: -.9,
                            height: 1.08,
                          ),
                    ),
                    const SizedBox(height: 7),
                    Text(
                      '${materialQuantity(material.stock, material.displayUnit)} on hand  |  '
                      '${compactInr(material.stockValue)} stock value',
                      style: Theme.of(context).textTheme.bodySmall?.copyWith(
                        color: const Color(0xFFBFCBDC),
                      ),
                    ),
                    const SizedBox(height: 17),
                    FilledButton.icon(
                      onPressed: onMovement,
                      icon: const Icon(Icons.swap_vert_rounded, size: 19),
                      label: const Text('Record movement'),
                      style: FilledButton.styleFrom(
                        minimumSize: const Size(0, 48),
                      ),
                    ),
                  ],
                );
                final metrics = Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 10,
                    vertical: 20,
                  ),
                  decoration: BoxDecoration(
                    color: Colors.white.withValues(alpha: .075),
                    borderRadius: BorderRadius.circular(24),
                    border: Border.all(
                      color: Colors.white.withValues(alpha: .12),
                    ),
                  ),
                  child: Row(
                    children: [
                      _Metric(
                        value: materialQuantity(
                          material.lowStockThreshold,
                          material.displayUnit,
                        ),
                        label: 'Threshold',
                      ),
                      const _Divider(),
                      _Metric(
                        value: compactInr(material.rate),
                        label: 'Unit rate',
                      ),
                      const _Divider(),
                      _Metric(value: '$movementCount', label: 'Movements'),
                    ],
                  ),
                );
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
    ).animate().fadeIn(duration: 320.ms).slideY(begin: .04);
  }
}

class _Metric extends StatelessWidget {
  const _Metric({required this.value, required this.label});
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
          style: Theme.of(context).textTheme.titleSmall?.copyWith(
            color: Colors.white,
            fontWeight: FontWeight.w800,
          ),
        ),
        const SizedBox(height: 4),
        Text(
          label.toUpperCase(),
          textAlign: TextAlign.center,
          style: Theme.of(context).textTheme.labelSmall?.copyWith(
            color: const Color(0xFFBFCBDC),
            fontSize: 8,
            fontWeight: FontWeight.w700,
          ),
        ),
      ],
    ),
  );
}

class _Divider extends StatelessWidget {
  const _Divider();
  @override
  Widget build(BuildContext context) => Container(
    width: 1,
    height: 40,
    color: Colors.white.withValues(alpha: .14),
  );
}

class MaterialControlPanel extends StatelessWidget {
  const MaterialControlPanel({super.key, required this.material});
  final MaterialItem material;

  @override
  Widget build(BuildContext context) {
    final tone = stockHealthColor(material.health);
    return SurfaceCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Text(
                'Stock control',
                style: Theme.of(
                  context,
                ).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w800),
              ),
              const Spacer(),
              StatusBadge(label: stockHealthLabel(material.health), tone: tone),
            ],
          ),
          const SizedBox(height: 18),
          _ControlRow(
            label: 'Current quantity',
            value: materialQuantity(material.stock, material.displayUnit),
          ),
          const SizedBox(height: 11),
          _ControlRow(
            label: 'Low-stock threshold',
            value: materialQuantity(
              material.lowStockThreshold,
              material.displayUnit,
            ),
          ),
          const SizedBox(height: 11),
          _ControlRow(
            label: 'Rate per ${material.displayUnit}',
            value: compactInr(material.rate),
          ),
          const SizedBox(height: 15),
          ClipRRect(
            borderRadius: BorderRadius.circular(8),
            child: LinearProgressIndicator(
              minHeight: 8,
              value: (material.thresholdCoverage / 2).clamp(0, 1),
              backgroundColor: AppTheme.line,
              color: tone,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            material.health == StockHealth.healthy
                ? 'Stock is above the configured alert threshold.'
                : material.health == StockHealth.low
                ? 'Replenishment should be planned for this item.'
                : 'No usable stock remains for field issue.',
            style: Theme.of(context).textTheme.labelSmall?.copyWith(
              color: tone,
              fontWeight: FontWeight.w700,
            ),
          ),
        ],
      ),
    );
  }
}

class _ControlRow extends StatelessWidget {
  const _ControlRow({required this.label, required this.value});
  final String label;
  final String value;

  @override
  Widget build(BuildContext context) => Row(
    children: [
      Expanded(
        child: Text(
          label,
          style: Theme.of(
            context,
          ).textTheme.labelSmall?.copyWith(color: AppTheme.muted),
        ),
      ),
      Text(
        value,
        style: Theme.of(
          context,
        ).textTheme.labelLarge?.copyWith(fontWeight: FontWeight.w800),
      ),
    ],
  );
}

class MaterialIdentityPanel extends StatelessWidget {
  const MaterialIdentityPanel({
    super.key,
    required this.material,
    required this.siteName,
  });

  final MaterialItem material;
  final String siteName;

  @override
  Widget build(BuildContext context) => SurfaceCard(
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Record identity',
          style: Theme.of(
            context,
          ).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w800),
        ),
        const SizedBox(height: 16),
        _IdentityRow(
          icon: Icons.fingerprint_rounded,
          label: 'Material ID',
          value: material.id,
        ),
        const SizedBox(height: 12),
        _IdentityRow(
          icon: Icons.apartment_outlined,
          label: 'Project site',
          value: siteName,
        ),
        const SizedBox(height: 12),
        _IdentityRow(
          icon: Icons.category_outlined,
          label: 'Category',
          value: material.category.apiValue,
        ),
        const SizedBox(height: 12),
        _IdentityRow(
          icon: Icons.calendar_today_outlined,
          label: 'Created',
          value: appDate(material.createdAt, fallback: 'Not returned'),
        ),
      ],
    ),
  );
}

class _IdentityRow extends StatelessWidget {
  const _IdentityRow({
    required this.icon,
    required this.label,
    required this.value,
  });
  final IconData icon;
  final String label;
  final String value;

  @override
  Widget build(BuildContext context) => Row(
    children: [
      Container(
        width: 34,
        height: 34,
        decoration: BoxDecoration(
          color: AppTheme.blue.withValues(alpha: .08),
          borderRadius: BorderRadius.circular(11),
        ),
        child: Icon(icon, color: AppTheme.blue, size: 17),
      ),
      const SizedBox(width: 10),
      Expanded(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              label,
              style: Theme.of(
                context,
              ).textTheme.labelSmall?.copyWith(color: AppTheme.muted),
            ),
            Text(
              value,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: Theme.of(
                context,
              ).textTheme.labelMedium?.copyWith(fontWeight: FontWeight.w700),
            ),
          ],
        ),
      ),
    ],
  );
}

class MaterialImmutableNotice extends StatelessWidget {
  const MaterialImmutableNotice({super.key});

  @override
  Widget build(BuildContext context) => SurfaceCard(
    child: Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          width: 40,
          height: 40,
          decoration: BoxDecoration(
            color: AppTheme.warning.withValues(alpha: .1),
            borderRadius: BorderRadius.circular(13),
          ),
          child: const Icon(
            Icons.lock_outline_rounded,
            color: AppTheme.warning,
            size: 19,
          ),
        ),
        const SizedBox(width: 11),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Catalogue edits unavailable',
                style: Theme.of(
                  context,
                ).textTheme.labelLarge?.copyWith(fontWeight: FontWeight.w800),
              ),
              const SizedBox(height: 4),
              Text(
                'The backend has no material update or archive endpoint. '
                'Stock can be changed only through auditable movements.',
                style: Theme.of(context).textTheme.labelSmall?.copyWith(
                  color: AppTheme.muted,
                  height: 1.4,
                ),
              ),
            ],
          ),
        ),
      ],
    ),
  );
}
