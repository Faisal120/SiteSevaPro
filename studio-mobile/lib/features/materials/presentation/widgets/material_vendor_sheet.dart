import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/network/api_service.dart';
import '../../../../core/theme/app_theme.dart';
import '../../models/material_models.dart';
import '../../providers/materials_provider.dart';

Future<bool> showMaterialVendorSheet(
  BuildContext context,
  WidgetRef ref,
) async {
  ref.read(materialVendorBriefProvider.notifier).reset();
  final created = await showModalBottomSheet<bool>(
    context: context,
    isScrollControlled: true,
    backgroundColor: Colors.transparent,
    builder: (_) => const _MaterialVendorSheet(),
  );
  return created == true;
}

class _MaterialVendorSheet extends ConsumerWidget {
  const _MaterialVendorSheet();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final brief = ref.watch(materialVendorBriefProvider);
    final controller = ref.read(materialVendorBriefProvider.notifier);
    final action = ref.watch(materialsActionControllerProvider);
    final error = action.hasError ? action.error : null;
    return FractionallySizedBox(
      heightFactor: .9,
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
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Add material vendor',
                              style: Theme.of(context).textTheme.headlineSmall
                                  ?.copyWith(
                                    fontWeight: FontWeight.w800,
                                    letterSpacing: -.8,
                                  ),
                            ),
                            Text(
                              'Contractor-owned supplier record from VendorIn.',
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
                  TextFormField(
                    textCapitalization: TextCapitalization.words,
                    onChanged: controller.setName,
                    decoration: const InputDecoration(
                      labelText: 'Vendor name',
                      prefixIcon: Icon(Icons.storefront_outlined),
                    ),
                  ),
                  const SizedBox(height: 12),
                  LayoutBuilder(
                    builder: (context, constraints) {
                      final contact = TextFormField(
                        keyboardType: TextInputType.phone,
                        onChanged: controller.setContact,
                        decoration: const InputDecoration(
                          labelText: 'Contact (optional)',
                        ),
                      );
                      final gst = TextFormField(
                        textCapitalization: TextCapitalization.characters,
                        onChanged: controller.setGst,
                        decoration: const InputDecoration(
                          labelText: 'GSTIN (optional)',
                        ),
                      );
                      if (constraints.maxWidth >= 560) {
                        return Row(
                          children: [
                            Expanded(child: contact),
                            const SizedBox(width: 12),
                            Expanded(child: gst),
                          ],
                        );
                      }
                      return Column(
                        children: [contact, const SizedBox(height: 12), gst],
                      );
                    },
                  ),
                  const SizedBox(height: 12),
                  TextFormField(
                    onChanged: controller.setPaymentTerms,
                    decoration: const InputDecoration(
                      labelText: 'Payment terms (optional)',
                      hintText: 'Example: Net 30 days',
                    ),
                  ),
                  const SizedBox(height: 12),
                  TextFormField(
                    maxLines: 3,
                    textCapitalization: TextCapitalization.words,
                    onChanged: controller.setAddress,
                    decoration: const InputDecoration(
                      labelText: 'Address (optional)',
                    ),
                  ),
                  const SizedBox(height: 18),
                  Text(
                    'Supply categories',
                    style: Theme.of(context).textTheme.labelLarge?.copyWith(
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                  const SizedBox(height: 9),
                  Wrap(
                    spacing: 7,
                    runSpacing: 7,
                    children: MaterialCategory.values.map((category) {
                      final selected = brief.categories.contains(
                        category.apiValue,
                      );
                      return FilterChip(
                        selected: selected,
                        label: Text(category.apiValue),
                        onSelected: (_) {
                          final values = [...brief.categories];
                          selected
                              ? values.remove(category.apiValue)
                              : values.add(category.apiValue);
                          controller.setCategories(values);
                        },
                      );
                    }).toList(),
                  ),
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
                  const SizedBox(height: 20),
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
                        : const Icon(Icons.add_business_rounded),
                    label: Text(
                      action.isLoading ? 'Creating vendor...' : 'Create vendor',
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
    MaterialVendorBrief brief,
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
        .createVendor(brief);
    if (created && context.mounted) Navigator.pop(context, true);
  }
}
