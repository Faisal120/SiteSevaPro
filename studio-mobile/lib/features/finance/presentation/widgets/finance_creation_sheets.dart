import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/media/app_image_picker.dart';
import '../../../../core/theme/app_theme.dart';
import '../../../../core/utils/app_formatters.dart';
import '../../../../core/widgets/app_ui.dart';
import '../../models/finance_models.dart';
import '../../providers/finance_provider.dart';

Future<bool> showPaymentCreationSheet(
  BuildContext context,
  WidgetRef ref,
  FinanceStudioData data, {
  String? initialSiteId,
}) async {
  ref
      .read(paymentBriefProvider.notifier)
      .reset(data, initialSiteId: initialSiteId);
  ref.read(financeActionControllerProvider.notifier).clearError();
  return await showModalBottomSheet<bool>(
        context: context,
        isScrollControlled: true,
        backgroundColor: Colors.transparent,
        builder: (_) => _PaymentCreationSheet(data: data),
      ) ??
      false;
}

Future<bool> showExpenseCreationSheet(
  BuildContext context,
  WidgetRef ref,
  FinanceStudioData data, {
  String? initialSiteId,
}) async {
  ref
      .read(expenseBriefProvider.notifier)
      .reset(data, initialSiteId: initialSiteId);
  ref.read(financeActionControllerProvider.notifier).clearError();
  return await showModalBottomSheet<bool>(
        context: context,
        isScrollControlled: true,
        backgroundColor: Colors.transparent,
        builder: (_) => _ExpenseCreationSheet(data: data),
      ) ??
      false;
}

class _PaymentCreationSheet extends ConsumerStatefulWidget {
  const _PaymentCreationSheet({required this.data});
  final FinanceStudioData data;

  @override
  ConsumerState<_PaymentCreationSheet> createState() =>
      _PaymentCreationSheetState();
}

class _PaymentCreationSheetState extends ConsumerState<_PaymentCreationSheet> {
  final _amount = TextEditingController();
  final _description = TextEditingController();
  final _party = TextEditingController();

  @override
  void dispose() {
    _amount.dispose();
    _description.dispose();
    _party.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final brief = ref.watch(paymentBriefProvider);
    final action = ref.watch(financeActionControllerProvider);
    final controller = ref.read(paymentBriefProvider.notifier);
    return _SheetFrame(
      title: 'Record payment',
      subtitle: 'Create an auditable project cash-flow entry.',
      busy: action.isLoading,
      error: action.hasError ? '${action.error}' : null,
      primaryLabel: 'Save payment',
      onSubmit: () => _submit(brief),
      children: [
        _SiteField(
          sites: widget.data.sites,
          value: brief.siteId,
          onChanged: controller.setSite,
        ),
        const SizedBox(height: 12),
        DropdownButtonFormField<PaymentType>(
          initialValue: brief.type,
          decoration: const InputDecoration(labelText: 'Payment type'),
          items: PaymentType.values
              .where((type) => type != PaymentType.unknown)
              .map(
                (type) =>
                    DropdownMenuItem(value: type, child: Text(type.label)),
              )
              .toList(),
          onChanged: (value) {
            if (value != null) controller.setType(value);
          },
        ),
        const SizedBox(height: 12),
        TextField(
          controller: _amount,
          keyboardType: const TextInputType.numberWithOptions(decimal: true),
          onChanged: controller.setAmount,
          decoration: const InputDecoration(
            labelText: 'Amount',
            prefixText: 'INR  ',
          ),
        ),
        const SizedBox(height: 12),
        TextField(
          controller: _description,
          onChanged: controller.setDescription,
          decoration: const InputDecoration(
            labelText: 'Description',
            hintText: 'Client milestone receipt or site payment',
          ),
        ),
        const SizedBox(height: 12),
        TextField(
          controller: _party,
          onChanged: controller.setParty,
          decoration: const InputDecoration(
            labelText: 'Party (optional)',
            hintText: 'Client, vendor or payee',
          ),
        ),
        const SizedBox(height: 12),
        _DateField(
          value: brief.date,
          referenceDate: widget.data.referenceDate,
          onChanged: controller.setDate,
        ),
        const SizedBox(height: 12),
        _AttachmentField(
          label: 'Invoice attachment',
          value: brief.invoiceUrl,
          busy: action.isLoading,
          onPick: () => _pickAttachment(controller.setInvoiceUrl),
          onRemove: () => controller.setInvoiceUrl(''),
        ),
      ],
    );
  }

  Future<void> _pickAttachment(ValueChanged<String> setUrl) async {
    final asset = await _chooseImage(context, ref);
    if (asset == null) return;
    final url = await ref
        .read(financeActionControllerProvider.notifier)
        .uploadAttachment(asset);
    if (url != null) setUrl(url);
  }

  Future<void> _submit(PaymentBrief brief) async {
    final validation = brief.validationMessage(widget.data.referenceDate);
    if (validation != null) {
      _message(context, validation);
      return;
    }
    final saved = await ref
        .read(financeActionControllerProvider.notifier)
        .createPayment(brief);
    if (saved && mounted) Navigator.pop(context, true);
  }
}

class _ExpenseCreationSheet extends ConsumerStatefulWidget {
  const _ExpenseCreationSheet({required this.data});
  final FinanceStudioData data;

  @override
  ConsumerState<_ExpenseCreationSheet> createState() =>
      _ExpenseCreationSheetState();
}

class _ExpenseCreationSheetState extends ConsumerState<_ExpenseCreationSheet> {
  final _amount = TextEditingController();
  final _description = TextEditingController();
  final _paidBy = TextEditingController();

  @override
  void dispose() {
    _amount.dispose();
    _description.dispose();
    _paidBy.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final brief = ref.watch(expenseBriefProvider);
    final action = ref.watch(financeActionControllerProvider);
    final controller = ref.read(expenseBriefProvider.notifier);
    return _SheetFrame(
      title: 'Add field expense',
      subtitle:
          'Capture category, payer and receipt against the assigned site.',
      busy: action.isLoading,
      error: action.hasError
          ? '${action.error}\nServer state was refreshed. Check the expense timeline before retrying.'
          : null,
      primaryLabel: 'Save expense',
      onSubmit: () => _submit(brief),
      children: [
        _SiteField(
          sites: widget.data.sites,
          value: brief.siteId,
          onChanged: controller.setSite,
        ),
        const SizedBox(height: 12),
        DropdownButtonFormField<ExpenseCategory>(
          initialValue: brief.category,
          decoration: const InputDecoration(labelText: 'Expense category'),
          items: ExpenseCategory.values
              .where((category) => category != ExpenseCategory.unknown)
              .map(
                (category) => DropdownMenuItem(
                  value: category,
                  child: Text(category.label),
                ),
              )
              .toList(),
          onChanged: (value) {
            if (value != null) controller.setCategory(value);
          },
        ),
        const SizedBox(height: 12),
        TextField(
          controller: _amount,
          keyboardType: const TextInputType.numberWithOptions(decimal: true),
          onChanged: controller.setAmount,
          decoration: const InputDecoration(
            labelText: 'Amount',
            prefixText: 'INR  ',
          ),
        ),
        const SizedBox(height: 12),
        TextField(
          controller: _description,
          onChanged: controller.setDescription,
          decoration: const InputDecoration(
            labelText: 'Description',
            hintText: 'Diesel for excavator or site transport',
          ),
        ),
        const SizedBox(height: 12),
        TextField(
          controller: _paidBy,
          onChanged: controller.setPaidBy,
          decoration: const InputDecoration(
            labelText: 'Paid by (optional)',
            hintText: 'Name of the field payer',
          ),
        ),
        const SizedBox(height: 12),
        _DateField(
          value: brief.date,
          referenceDate: widget.data.referenceDate,
          onChanged: controller.setDate,
        ),
        const SizedBox(height: 12),
        _AttachmentField(
          label: 'Receipt evidence',
          value: brief.receiptUrl,
          busy: action.isLoading,
          onPick: () => _pickAttachment(controller.setReceiptUrl),
          onRemove: () => controller.setReceiptUrl(''),
        ),
      ],
    );
  }

  Future<void> _pickAttachment(ValueChanged<String> setUrl) async {
    final asset = await _chooseImage(context, ref);
    if (asset == null) return;
    final url = await ref
        .read(financeActionControllerProvider.notifier)
        .uploadAttachment(asset);
    if (url != null) setUrl(url);
  }

  Future<void> _submit(ExpenseBrief brief) async {
    final validation = brief.validationMessage(widget.data.referenceDate);
    if (validation != null) {
      _message(context, validation);
      return;
    }
    final saved = await ref
        .read(financeActionControllerProvider.notifier)
        .createExpense(brief);
    if (saved && mounted) Navigator.pop(context, true);
  }
}

class _SheetFrame extends StatelessWidget {
  const _SheetFrame({
    required this.title,
    required this.subtitle,
    required this.children,
    required this.busy,
    required this.primaryLabel,
    required this.onSubmit,
    this.error,
  });

  final String title;
  final String subtitle;
  final List<Widget> children;
  final bool busy;
  final String primaryLabel;
  final VoidCallback onSubmit;
  final String? error;

  @override
  Widget build(BuildContext context) => SafeArea(
    top: false,
    child: Padding(
      padding: EdgeInsets.fromLTRB(
        12,
        32,
        12,
        MediaQuery.viewInsetsOf(context).bottom + 12,
      ),
      child: Container(
        constraints: const BoxConstraints(maxWidth: 720, maxHeight: 820),
        margin: const EdgeInsets.symmetric(horizontal: 0),
        decoration: BoxDecoration(
          color: Theme.of(context).scaffoldBackgroundColor,
          borderRadius: BorderRadius.circular(32),
          boxShadow: const [
            BoxShadow(
              color: Color(0x33071120),
              blurRadius: 40,
              offset: Offset(0, 20),
            ),
          ],
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(22, 20, 12, 12),
              child: Row(
                children: [
                  Container(
                    width: 42,
                    height: 42,
                    decoration: BoxDecoration(
                      color: AppTheme.blue.withValues(alpha: .1),
                      borderRadius: BorderRadius.circular(15),
                    ),
                    child: const Icon(
                      Icons.account_balance_wallet_outlined,
                      color: AppTheme.blue,
                      size: 20,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          title,
                          style: Theme.of(context).textTheme.titleLarge
                              ?.copyWith(fontWeight: FontWeight.w800),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          subtitle,
                          style: Theme.of(context).textTheme.bodySmall
                              ?.copyWith(color: AppTheme.muted),
                        ),
                      ],
                    ),
                  ),
                  IconButton(
                    onPressed: busy ? null : () => Navigator.pop(context),
                    icon: const Icon(Icons.close_rounded),
                  ),
                ],
              ),
            ),
            const Divider(height: 1),
            Flexible(
              child: SingleChildScrollView(
                padding: const EdgeInsets.all(22),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    if (error != null) ...[
                      Container(
                        padding: const EdgeInsets.all(14),
                        decoration: BoxDecoration(
                          color: AppTheme.danger.withValues(alpha: .08),
                          borderRadius: BorderRadius.circular(18),
                        ),
                        child: Text(
                          error!,
                          style: Theme.of(context).textTheme.bodySmall
                              ?.copyWith(color: AppTheme.danger, height: 1.4),
                        ),
                      ),
                      const SizedBox(height: 14),
                    ],
                    ...children,
                    const SizedBox(height: 22),
                    FilledButton.icon(
                      onPressed: busy ? null : onSubmit,
                      icon: busy
                          ? const SizedBox.square(
                              dimension: 18,
                              child: CircularProgressIndicator(
                                strokeWidth: 2,
                                color: Colors.white,
                              ),
                            )
                          : const Icon(Icons.check_rounded),
                      label: Text(busy ? 'Saving securely...' : primaryLabel),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    ),
  );
}

class _SiteField extends StatelessWidget {
  const _SiteField({
    required this.sites,
    required this.value,
    required this.onChanged,
  });
  final List<dynamic> sites;
  final String value;
  final ValueChanged<String> onChanged;

  @override
  Widget build(BuildContext context) => DropdownButtonFormField<String>(
    initialValue: value.isEmpty ? null : value,
    isExpanded: true,
    decoration: const InputDecoration(labelText: 'Project site'),
    items: sites
        .map(
          (site) => DropdownMenuItem<String>(
            value: site.id as String,
            child: Text(
              site.name as String,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
          ),
        )
        .toList(),
    onChanged: (value) {
      if (value != null) onChanged(value);
    },
  );
}

class _DateField extends StatelessWidget {
  const _DateField({
    required this.value,
    required this.referenceDate,
    required this.onChanged,
  });
  final DateTime value;
  final DateTime referenceDate;
  final ValueChanged<DateTime> onChanged;

  @override
  Widget build(BuildContext context) => InkWell(
    onTap: () async {
      final selected = await showDatePicker(
        context: context,
        initialDate: value,
        firstDate: DateTime(referenceDate.year - 5),
        lastDate: referenceDate,
      );
      if (selected != null) onChanged(selected);
    },
    borderRadius: BorderRadius.circular(18),
    child: InputDecorator(
      decoration: const InputDecoration(
        labelText: 'Record date',
        suffixIcon: Icon(Icons.calendar_today_outlined),
      ),
      child: Text(appDate(value)),
    ),
  );
}

class _AttachmentField extends StatelessWidget {
  const _AttachmentField({
    required this.label,
    required this.value,
    required this.busy,
    required this.onPick,
    required this.onRemove,
  });
  final String label;
  final String value;
  final bool busy;
  final VoidCallback onPick;
  final VoidCallback onRemove;

  @override
  Widget build(BuildContext context) => SurfaceCard(
    padding: const EdgeInsets.all(14),
    color: AppTheme.blue.withValues(alpha: .035),
    child: Row(
      children: [
        Container(
          width: 40,
          height: 40,
          decoration: BoxDecoration(
            color: AppTheme.blue.withValues(alpha: .1),
            borderRadius: BorderRadius.circular(14),
          ),
          child: Icon(
            value.isEmpty
                ? Icons.add_photo_alternate_outlined
                : Icons.verified_rounded,
            color: value.isEmpty ? AppTheme.blue : AppTheme.success,
            size: 20,
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                label,
                style: Theme.of(
                  context,
                ).textTheme.labelMedium?.copyWith(fontWeight: FontWeight.w800),
              ),
              const SizedBox(height: 2),
              Text(
                value.isEmpty
                    ? 'Camera or photo library  |  Max 10 MB'
                    : 'Secure upload attached',
                style: Theme.of(
                  context,
                ).textTheme.bodySmall?.copyWith(color: AppTheme.muted),
              ),
            ],
          ),
        ),
        if (value.isNotEmpty)
          IconButton(
            tooltip: 'Remove attachment',
            onPressed: busy ? null : onRemove,
            icon: const Icon(Icons.close_rounded),
          )
        else
          TextButton(
            onPressed: busy ? null : onPick,
            child: Text(busy ? 'Uploading...' : 'Attach'),
          ),
      ],
    ),
  );
}

Future<AppImageAsset?> _chooseImage(BuildContext context, WidgetRef ref) async {
  final source = await showModalBottomSheet<String>(
    context: context,
    backgroundColor: Colors.transparent,
    builder: (context) => SafeArea(
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: SurfaceCard(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              ListTile(
                leading: const Icon(Icons.camera_alt_outlined),
                title: const Text('Take a photo'),
                onTap: () => Navigator.pop(context, 'camera'),
              ),
              ListTile(
                leading: const Icon(Icons.photo_library_outlined),
                title: const Text('Choose from library'),
                onTap: () => Navigator.pop(context, 'gallery'),
              ),
            ],
          ),
        ),
      ),
    ),
  );
  if (source == null) return null;
  try {
    final picker = ref.read(financeImagePickerProvider);
    if (source == 'camera') return picker.pickCamera();
    final assets = await picker.pickGallery(limit: 1);
    return assets.isEmpty ? null : assets.first;
  } catch (error) {
    if (context.mounted) _message(context, '$error');
    return null;
  }
}

void _message(BuildContext context, String message) => ScaffoldMessenger.of(
  context,
).showSnackBar(SnackBar(content: Text(message)));
