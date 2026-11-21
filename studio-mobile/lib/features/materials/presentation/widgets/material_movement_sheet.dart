import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/network/api_service.dart';
import '../../../../core/theme/app_theme.dart';
import '../../../../core/utils/app_formatters.dart';
import '../../../../core/widgets/app_ui.dart';
import '../../models/material_models.dart';
import '../../providers/materials_provider.dart';
import 'materials_widgets.dart';

Future<bool> showMaterialMovementSheet(
  BuildContext context,
  MaterialItem material,
) async {
  final result = await showModalBottomSheet<bool>(
    context: context,
    isScrollControlled: true,
    backgroundColor: Colors.transparent,
    builder: (_) => _MaterialMovementSheet(material: material),
  );
  return result == true;
}

class _MaterialMovementSheet extends ConsumerWidget {
  const _MaterialMovementSheet({required this.material});
  final MaterialItem material;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final brief = ref.watch(materialMovementBriefProvider(material));
    final controller = ref.read(
      materialMovementBriefProvider(material).notifier,
    );
    final action = ref.watch(materialsActionControllerProvider);
    final data = ref.watch(materialsStudioControllerProvider).valueOrNull;
    final error = action.hasError ? action.error : null;
    return FractionallySizedBox(
      heightFactor: .94,
      child: Material(
        color: Theme.of(context).scaffoldBackgroundColor,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(32)),
        clipBehavior: Clip.antiAlias,
        child: SafeArea(
          top: false,
          child: Center(
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 720),
              child: ListView(
                padding: EdgeInsets.fromLTRB(
                  20,
                  14,
                  20,
                  MediaQuery.viewInsetsOf(context).bottom + 28,
                ),
                children: [
                  Center(
                    child: Container(
                      width: 42,
                      height: 5,
                      decoration: BoxDecoration(
                        color: AppTheme.line,
                        borderRadius: BorderRadius.circular(5),
                      ),
                    ),
                  ),
                  const SizedBox(height: 20),
                  Row(
                    children: [
                      Container(
                        width: 48,
                        height: 48,
                        decoration: BoxDecoration(
                          color: AppTheme.blue.withValues(alpha: .1),
                          borderRadius: BorderRadius.circular(16),
                        ),
                        child: Icon(
                          materialCategoryIcon(material.category),
                          color: AppTheme.blue,
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
                              style: Theme.of(context).textTheme.titleLarge
                                  ?.copyWith(fontWeight: FontWeight.w800),
                            ),
                            Text(
                              '${materialQuantity(material.stock, material.displayUnit)} available  |  ${compactInr(material.rate)}/${material.displayUnit}',
                              style: Theme.of(context).textTheme.labelSmall
                                  ?.copyWith(color: AppTheme.muted),
                            ),
                          ],
                        ),
                      ),
                      IconButton(
                        onPressed: () => Navigator.pop(context),
                        icon: const Icon(Icons.close_rounded),
                      ),
                    ],
                  ),
                  const SizedBox(height: 20),
                  _MovementTypeSwitch(
                    selected: brief.type,
                    onChanged: controller.setType,
                  ),
                  const SizedBox(height: 14),
                  TextFormField(
                    autofocus: true,
                    keyboardType: const TextInputType.numberWithOptions(
                      decimal: true,
                    ),
                    onChanged: controller.setQuantity,
                    decoration: InputDecoration(
                      labelText: 'Quantity',
                      suffixText: material.displayUnit,
                      prefixIcon: const Icon(Icons.numbers_rounded),
                    ),
                  ),
                  if (brief.type == MaterialMovementType.inward) ...[
                    const SizedBox(height: 12),
                    TextFormField(
                      initialValue: brief.rate == 0 ? '' : '${brief.rate}',
                      keyboardType: const TextInputType.numberWithOptions(
                        decimal: true,
                      ),
                      onChanged: controller.setRate,
                      decoration: const InputDecoration(
                        labelText: 'Receipt rate',
                        prefixText: 'INR ',
                      ),
                    ),
                    const SizedBox(height: 12),
                    DropdownButtonFormField<String>(
                      initialValue: brief.vendor.isEmpty ? null : brief.vendor,
                      isExpanded: true,
                      decoration: const InputDecoration(
                        labelText: 'Vendor (optional)',
                        prefixIcon: Icon(Icons.storefront_outlined),
                      ),
                      items: (data?.vendors ?? const [])
                          .map(
                            (vendor) => DropdownMenuItem(
                              value: vendor.displayName,
                              child: Text(vendor.displayName),
                            ),
                          )
                          .toList(),
                      onChanged: (value) => controller.setVendor(value ?? ''),
                    ),
                    const SizedBox(height: 12),
                    TextFormField(
                      keyboardType: TextInputType.url,
                      onChanged: controller.setInvoiceUrl,
                      decoration: const InputDecoration(
                        labelText: 'Invoice document URL (optional)',
                        prefixIcon: Icon(Icons.link_rounded),
                      ),
                    ),
                  ],
                  const SizedBox(height: 12),
                  TextFormField(
                    maxLines: 3,
                    onChanged: controller.setNote,
                    decoration: InputDecoration(
                      labelText: brief.type == MaterialMovementType.inward
                          ? 'Receipt note (optional)'
                          : 'Consumption note (optional)',
                      hintText: brief.type == MaterialMovementType.outward
                          ? 'Work area, activity, or responsible crew'
                          : 'Delivery details or quality note',
                    ),
                  ),
                  const SizedBox(height: 15),
                  _MovementPreview(material: material, brief: brief),
                  if (error != null) ...[
                    const SizedBox(height: 14),
                    Text(
                      error is ApiException ? error.message : '$error',
                      style: Theme.of(context).textTheme.labelSmall?.copyWith(
                        color: AppTheme.danger,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    const SizedBox(height: 5),
                    Text(
                      'The inventory was refreshed after this error. Verify the '
                      'current stock before attempting another submission.',
                      style: Theme.of(context).textTheme.labelSmall?.copyWith(
                        color: AppTheme.muted,
                        height: 1.4,
                      ),
                    ),
                  ],
                  const SizedBox(height: 18),
                  FilledButton.icon(
                    onPressed: action.isLoading
                        ? null
                        : () => _submit(context, ref, brief),
                    icon: action.isLoading
                        ? const SizedBox.square(
                            dimension: 18,
                            child: CircularProgressIndicator(
                              strokeWidth: 2,
                              color: Colors.white,
                            ),
                          )
                        : Icon(
                            brief.type == MaterialMovementType.inward
                                ? Icons.south_west_rounded
                                : Icons.north_east_rounded,
                          ),
                    label: Text(
                      action.isLoading
                          ? 'Submitting movement...'
                          : brief.type == MaterialMovementType.inward
                          ? 'Record receipt'
                          : 'Record consumption',
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

  Future<void> _submit(
    BuildContext context,
    WidgetRef ref,
    MaterialMovementBrief brief,
  ) async {
    final validation = brief.validationMessage;
    if (validation != null) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text(validation)));
      return;
    }
    final created = await ref
        .read(materialsActionControllerProvider.notifier)
        .createMovement(brief);
    if (created && context.mounted) Navigator.pop(context, true);
  }
}

class _MovementTypeSwitch extends StatelessWidget {
  const _MovementTypeSwitch({required this.selected, required this.onChanged});
  final MaterialMovementType selected;
  final ValueChanged<MaterialMovementType> onChanged;

  @override
  Widget build(BuildContext context) => Container(
    padding: const EdgeInsets.all(5),
    decoration: BoxDecoration(
      color: Theme.of(context).cardTheme.color,
      borderRadius: BorderRadius.circular(18),
      border: Border.all(color: AppTheme.line),
    ),
    child: Row(
      children: MaterialMovementType.values.map((type) {
        final active = type == selected;
        final tone = type == MaterialMovementType.inward
            ? AppTheme.success
            : AppTheme.orange;
        return Expanded(
          child: Material(
            color: active ? tone.withValues(alpha: .11) : Colors.transparent,
            borderRadius: BorderRadius.circular(14),
            child: InkWell(
              onTap: () => onChanged(type),
              borderRadius: BorderRadius.circular(14),
              child: Padding(
                padding: const EdgeInsets.symmetric(vertical: 12),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(
                      type == MaterialMovementType.inward
                          ? Icons.south_west_rounded
                          : Icons.north_east_rounded,
                      size: 18,
                      color: active ? tone : AppTheme.muted,
                    ),
                    const SizedBox(width: 7),
                    Flexible(
                      child: Text(
                        type == MaterialMovementType.inward
                            ? 'Receive stock'
                            : 'Issue stock',
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: Theme.of(context).textTheme.labelSmall?.copyWith(
                          color: active ? tone : AppTheme.muted,
                          fontWeight: FontWeight.w800,
                        ),
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
  );
}

class _MovementPreview extends StatelessWidget {
  const _MovementPreview({required this.material, required this.brief});
  final MaterialItem material;
  final MaterialMovementBrief brief;

  @override
  Widget build(BuildContext context) {
    final projected = brief.type == MaterialMovementType.inward
        ? material.stock + brief.quantity
        : material.stock - brief.quantity;
    final tone = projected < 0
        ? AppTheme.danger
        : brief.type == MaterialMovementType.inward
        ? AppTheme.success
        : AppTheme.orange;
    return SurfaceCard(
      color: AppTheme.navy,
      child: Row(
        children: [
          const Icon(Icons.query_stats_rounded, color: Color(0xFFBFD5FF)),
          const SizedBox(width: 11),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Projected stock',
                  style: Theme.of(context).textTheme.labelSmall?.copyWith(
                    color: const Color(0xFFBFCBDC),
                  ),
                ),
                const SizedBox(height: 3),
                Text(
                  materialQuantity(projected, material.displayUnit),
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    color: tone,
                    fontWeight: FontWeight.w800,
                  ),
                ),
              ],
            ),
          ),
          if (brief.type == MaterialMovementType.inward)
            Text(
              compactInr(brief.quantity * brief.rate),
              style: Theme.of(context).textTheme.labelLarge?.copyWith(
                color: Colors.white,
                fontWeight: FontWeight.w800,
              ),
            ),
        ],
      ),
    );
  }
}
