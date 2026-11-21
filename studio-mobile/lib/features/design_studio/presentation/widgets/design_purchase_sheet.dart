import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/theme/app_theme.dart';
import '../../../../core/widgets/app_ui.dart';
import '../../models/design_models.dart';
import '../../providers/design_studio_provider.dart';
import 'design_studio_widgets.dart';

Future<void> showDesignPurchaseSheet(
  BuildContext context,
  WidgetRef ref, {
  required DesignStudioData data,
}) => showModalBottomSheet<void>(
  context: context,
  isScrollControlled: true,
  useSafeArea: true,
  backgroundColor: Colors.transparent,
  barrierColor: AppTheme.ink.withValues(alpha: .55),
  builder: (_) => _DesignPurchaseSheet(data: data),
);

class _DesignPurchaseSheet extends ConsumerStatefulWidget {
  const _DesignPurchaseSheet({required this.data});
  final DesignStudioData data;

  @override
  ConsumerState<_DesignPurchaseSheet> createState() =>
      _DesignPurchaseSheetState();
}

class _DesignPurchaseSheetState extends ConsumerState<_DesignPurchaseSheet> {
  final utr = TextEditingController();
  final note = TextEditingController();
  String? selectedPack;
  bool submitted = false;

  @override
  void initState() {
    super.initState();
    selectedPack = widget.data.purchaseConfig?.packs.firstOrNull?.code;
  }

  @override
  void dispose() {
    utr.dispose();
    note.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final action = ref.watch(designActionControllerProvider);
    final config = widget.data.purchaseConfig;
    return Align(
      alignment: Alignment.bottomCenter,
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 680),
        child: Container(
          height: MediaQuery.sizeOf(context).height * .9,
          clipBehavior: Clip.antiAlias,
          decoration: BoxDecoration(
            color: Theme.of(context).scaffoldBackgroundColor,
            borderRadius: const BorderRadius.vertical(top: Radius.circular(32)),
          ),
          child: Column(
            children: [
              Padding(
                padding: const EdgeInsets.fromLTRB(20, 16, 12, 10),
                child: Row(
                  children: [
                    Container(
                      width: 44,
                      height: 44,
                      decoration: BoxDecoration(
                        color: AppTheme.orange.withValues(alpha: .12),
                        borderRadius: BorderRadius.circular(16),
                      ),
                      child: const Icon(
                        Icons.toll_rounded,
                        color: AppTheme.orange,
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Design credits',
                            style: Theme.of(context).textTheme.titleLarge
                                ?.copyWith(fontWeight: FontWeight.w800),
                          ),
                          Text(
                            '${widget.data.wallet?.credits ?? 0} available · verified UPI purchase',
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
              ),
              if (action.isLoading) const LinearProgressIndicator(minHeight: 3),
              Expanded(
                child: ListView(
                  padding: const EdgeInsets.fromLTRB(20, 14, 20, 30),
                  children: [
                    if (submitted) ...[
                      const EmptyPanel(
                        title: 'Verification request submitted',
                        message:
                            'Your credits will be added after the SiteSeva team verifies the UPI transaction reference.',
                        icon: Icons.verified_rounded,
                      ),
                      const SizedBox(height: 18),
                    ],
                    if (config == null)
                      const EmptyPanel(
                        title: 'Purchase configuration unavailable',
                        message:
                            'The backend did not provide verified payment packs. Refresh the studio and retry.',
                        icon: Icons.payments_outlined,
                      )
                    else ...[
                      SurfaceCard(
                        child: Row(
                          children: [
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    config.payeeName,
                                    style: Theme.of(context)
                                        .textTheme
                                        .labelLarge
                                        ?.copyWith(fontWeight: FontWeight.w800),
                                  ),
                                  const SizedBox(height: 5),
                                  Text(
                                    config.upiId,
                                    style: Theme.of(context).textTheme.bodySmall
                                        ?.copyWith(color: AppTheme.muted),
                                  ),
                                ],
                              ),
                            ),
                            IconButton.filledTonal(
                              tooltip: 'Copy UPI ID',
                              onPressed: () async {
                                await Clipboard.setData(
                                  ClipboardData(text: config.upiId),
                                );
                                if (context.mounted) {
                                  ScaffoldMessenger.of(context).showSnackBar(
                                    const SnackBar(
                                      content: Text('UPI ID copied'),
                                    ),
                                  );
                                }
                              },
                              icon: const Icon(Icons.copy_rounded),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 18),
                      Text(
                        'Choose a pack',
                        style: Theme.of(context).textTheme.titleMedium
                            ?.copyWith(fontWeight: FontWeight.w800),
                      ),
                      const SizedBox(height: 10),
                      ...config.packs.map(
                        (pack) => Padding(
                          padding: const EdgeInsets.only(bottom: 10),
                          child: _CreditPackTile(
                            pack: pack,
                            selected: selectedPack == pack.code,
                            onTap: action.isLoading
                                ? null
                                : () =>
                                      setState(() => selectedPack = pack.code),
                          ),
                        ),
                      ),
                      const SizedBox(height: 8),
                      TextField(
                        controller: utr,
                        enabled: !action.isLoading,
                        textCapitalization: TextCapitalization.characters,
                        decoration: const InputDecoration(
                          labelText: 'UPI transaction reference (UTR)',
                          prefixIcon: Icon(Icons.receipt_long_rounded),
                        ),
                      ),
                      const SizedBox(height: 12),
                      TextField(
                        controller: note,
                        enabled: !action.isLoading,
                        maxLength: 280,
                        maxLines: 3,
                        decoration: const InputDecoration(
                          labelText: 'Note (optional)',
                          alignLabelWithHint: true,
                        ),
                      ),
                      if (action.value.hasError) ...[
                        const SizedBox(height: 4),
                        Text(
                          '${action.value.error}',
                          style: Theme.of(context).textTheme.labelSmall
                              ?.copyWith(
                                color: AppTheme.danger,
                                fontWeight: FontWeight.w700,
                              ),
                        ),
                      ],
                      const SizedBox(height: 12),
                      FilledButton.icon(
                        onPressed: action.isLoading || selectedPack == null
                            ? null
                            : _submit,
                        icon: const Icon(Icons.verified_user_rounded),
                        label: Text(
                          action.isLoading
                              ? 'Submitting reference...'
                              : 'Submit for verification',
                        ),
                      ),
                    ],
                    const SizedBox(height: 26),
                    Text(
                      'Purchase history',
                      style: Theme.of(context).textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                    const SizedBox(height: 10),
                    if (widget.data.purchases.isEmpty)
                      const EmptyPanel(
                        title: 'No credit requests yet',
                        message:
                            'Submitted UPI references and their verification status will appear here.',
                        icon: Icons.history_rounded,
                      )
                    else
                      ...widget.data.purchases.map(
                        (request) => Padding(
                          padding: const EdgeInsets.only(bottom: 10),
                          child: SurfaceCard(
                            child: Row(
                              children: [
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        '${request.pack} · ${request.credits} credits',
                                        style: Theme.of(context)
                                            .textTheme
                                            .labelLarge
                                            ?.copyWith(
                                              fontWeight: FontWeight.w800,
                                            ),
                                      ),
                                      const SizedBox(height: 4),
                                      Text(
                                        'INR ${request.amount} · ${designDate(request.createdAt)}',
                                        style: Theme.of(context)
                                            .textTheme
                                            .labelSmall
                                            ?.copyWith(color: AppTheme.muted),
                                      ),
                                    ],
                                  ),
                                ),
                                StatusBadge(
                                  label: request.status,
                                  tone: request.status == 'APPROVED'
                                      ? AppTheme.success
                                      : request.status == 'REJECTED'
                                      ? AppTheme.danger
                                      : AppTheme.warning,
                                ),
                              ],
                            ),
                          ),
                        ),
                      ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Future<void> _submit() async {
    final result = await ref
        .read(designActionControllerProvider.notifier)
        .requestCredits(pack: selectedPack!, utr: utr.text, note: note.text);
    if (result != null && mounted) {
      setState(() => submitted = true);
      utr.clear();
      note.clear();
    }
  }
}

class _CreditPackTile extends StatelessWidget {
  const _CreditPackTile({
    required this.pack,
    required this.selected,
    required this.onTap,
  });
  final DesignCreditPack pack;
  final bool selected;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) => Material(
    color: selected
        ? AppTheme.orange.withValues(alpha: .08)
        : Theme.of(context).cardTheme.color,
    borderRadius: BorderRadius.circular(20),
    child: InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(20),
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: selected ? AppTheme.orange : AppTheme.line,
            width: selected ? 1.5 : 1,
          ),
        ),
        child: Row(
          children: [
            Icon(
              selected ? Icons.radio_button_checked : Icons.radio_button_off,
              color: selected ? AppTheme.orange : AppTheme.muted,
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    pack.code,
                    style: Theme.of(context).textTheme.labelLarge?.copyWith(
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                  Text(
                    '${pack.credits} generation credits',
                    style: Theme.of(
                      context,
                    ).textTheme.labelSmall?.copyWith(color: AppTheme.muted),
                  ),
                ],
              ),
            ),
            Text(
              'INR ${pack.amount}',
              style: Theme.of(
                context,
              ).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w800),
            ),
          ],
        ),
      ),
    ),
  );
}
