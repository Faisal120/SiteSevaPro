import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/network/api_service.dart';
import '../../../../core/theme/app_theme.dart';
import '../../../../core/widgets/app_ui.dart';
import '../../models/material_models.dart';
import '../../providers/materials_provider.dart';

Future<bool> showMaterialCreationSheet(
  BuildContext context,
  WidgetRef ref,
  MaterialsStudioData data,
) async {
  ref.read(materialCreationBriefProvider.notifier).reset();
  final created = await showModalBottomSheet<bool>(
    context: context,
    isScrollControlled: true,
    backgroundColor: Colors.transparent,
    builder: (_) => const _MaterialCreationSheet(),
  );
  return created == true;
}

class _MaterialCreationSheet extends ConsumerWidget {
  const _MaterialCreationSheet();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final brief = ref.watch(materialCreationBriefProvider);
    final controller = ref.read(materialCreationBriefProvider.notifier);
    final action = ref.watch(materialsActionControllerProvider);
    final studio = ref.watch(materialsStudioControllerProvider).valueOrNull;
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
              constraints: const BoxConstraints(maxWidth: 760),
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
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Add site material',
                              style: Theme.of(context).textTheme.headlineSmall
                                  ?.copyWith(
                                    fontWeight: FontWeight.w800,
                                    letterSpacing: -.8,
                                  ),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              'Creates an exact MaterialIn record on the live workspace.',
                              style: Theme.of(context).textTheme.bodySmall
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
                  DropdownButtonFormField<String>(
                    initialValue: brief.siteId.isEmpty ? null : brief.siteId,
                    isExpanded: true,
                    decoration: const InputDecoration(
                      labelText: 'Project site',
                      prefixIcon: Icon(Icons.apartment_rounded),
                    ),
                    items: (studio?.sites ?? const [])
                        .map(
                          (site) => DropdownMenuItem(
                            value: site.id,
                            child: Text(
                              site.name,
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                        )
                        .toList(),
                    onChanged: (value) {
                      if (value != null) controller.setSite(value);
                    },
                  ),
                  const SizedBox(height: 12),
                  TextFormField(
                    textCapitalization: TextCapitalization.words,
                    onChanged: controller.setName,
                    decoration: const InputDecoration(
                      labelText: 'Material name',
                      hintText: 'Example: OPC 53 Grade Cement',
                      prefixIcon: Icon(Icons.inventory_2_outlined),
                    ),
                  ),
                  const SizedBox(height: 12),
                  LayoutBuilder(
                    builder: (context, constraints) {
                      final category =
                          DropdownButtonFormField<MaterialCategory>(
                            initialValue: brief.category,
                            decoration: const InputDecoration(
                              labelText: 'Category',
                            ),
                            items: MaterialCategory.values
                                .map(
                                  (value) => DropdownMenuItem(
                                    value: value,
                                    child: Text(value.apiValue),
                                  ),
                                )
                                .toList(),
                            onChanged: (value) {
                              if (value != null) controller.setCategory(value);
                            },
                          );
                      final unit = TextFormField(
                        onChanged: controller.setUnit,
                        decoration: const InputDecoration(
                          labelText: 'Unit',
                          hintText: 'bags, kg, cft, nos.',
                        ),
                      );
                      if (constraints.maxWidth >= 560) {
                        return Row(
                          children: [
                            Expanded(child: category),
                            const SizedBox(width: 12),
                            Expanded(child: unit),
                          ],
                        );
                      }
                      return Column(
                        children: [category, const SizedBox(height: 12), unit],
                      );
                    },
                  ),
                  const SizedBox(height: 12),
                  LayoutBuilder(
                    builder: (context, constraints) {
                      final stock = _NumberField(
                        label: 'Opening stock',
                        onChanged: controller.setOpeningStock,
                      );
                      final threshold = _NumberField(
                        label: 'Low-stock threshold',
                        initialValue: '10',
                        onChanged: controller.setThreshold,
                      );
                      final rate = _NumberField(
                        label: 'Rate per unit',
                        prefix: 'INR ',
                        onChanged: controller.setRate,
                      );
                      if (constraints.maxWidth >= 620) {
                        return Row(
                          children: [
                            Expanded(child: stock),
                            const SizedBox(width: 10),
                            Expanded(child: threshold),
                            const SizedBox(width: 10),
                            Expanded(child: rate),
                          ],
                        );
                      }
                      return Column(
                        children: [
                          stock,
                          const SizedBox(height: 12),
                          threshold,
                          const SizedBox(height: 12),
                          rate,
                        ],
                      );
                    },
                  ),
                  const SizedBox(height: 16),
                  const _OpeningStockNotice(),
                  if (error != null) ...[
                    const SizedBox(height: 14),
                    Text(
                      error is ApiException ? error.message : '$error',
                      style: Theme.of(context).textTheme.labelSmall?.copyWith(
                        color: AppTheme.danger,
                        fontWeight: FontWeight.w700,
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
                        : const Icon(Icons.add_rounded),
                    label: Text(
                      action.isLoading
                          ? 'Creating material...'
                          : 'Create material',
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
    MaterialCreationBrief brief,
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
        .createMaterial(brief);
    if (created && context.mounted) Navigator.pop(context, true);
  }
}

class _NumberField extends StatelessWidget {
  const _NumberField({
    required this.label,
    required this.onChanged,
    this.initialValue,
    this.prefix,
  });
  final String label;
  final String? initialValue;
  final String? prefix;
  final ValueChanged<String> onChanged;

  @override
  Widget build(BuildContext context) => TextFormField(
    initialValue: initialValue,
    keyboardType: const TextInputType.numberWithOptions(decimal: true),
    onChanged: onChanged,
    decoration: InputDecoration(labelText: label, prefixText: prefix),
  );
}

class _OpeningStockNotice extends StatelessWidget {
  const _OpeningStockNotice();

  @override
  Widget build(BuildContext context) => SurfaceCard(
    color: AppTheme.navy,
    child: Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Icon(Icons.info_outline_rounded, color: Color(0xFFBFD5FF)),
        const SizedBox(width: 10),
        Expanded(
          child: Text(
            'Opening stock is stored on the material record. Future receipts '
            'and consumption must be recorded through stock movements for an '
            'auditable ledger.',
            style: Theme.of(context).textTheme.labelSmall?.copyWith(
              color: const Color(0xFFBFCBDC),
              height: 1.45,
            ),
          ),
        ),
      ],
    ),
  );
}
