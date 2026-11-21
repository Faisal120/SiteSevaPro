import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/network/api_service.dart';
import '../../../../core/theme/app_theme.dart';
import '../../../../core/utils/app_formatters.dart';
import '../../models/workforce_models.dart';
import '../../providers/workforce_provider.dart';

Future<bool> showWalletSettlementSheet(
  BuildContext context,
  WidgetRef ref, {
  required WorkforceDetail detail,
}) async {
  ref.read(walletSettlementBriefProvider(detail.member.id).notifier).reset();
  return await showModalBottomSheet<bool>(
        context: context,
        isScrollControlled: true,
        useSafeArea: true,
        backgroundColor: Colors.transparent,
        builder: (context) => _WalletSettlementSheet(detail: detail),
      ) ??
      false;
}

class _WalletSettlementSheet extends ConsumerWidget {
  const _WalletSettlementSheet({required this.detail});
  final WorkforceDetail detail;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final member = detail.member;
    final brief = ref.watch(walletSettlementBriefProvider(member.id));
    final editor = ref.read(walletSettlementBriefProvider(member.id).notifier);
    final action = ref.watch(walletActionControllerProvider);
    return FractionallySizedBox(
      heightFactor: .78,
      child: Material(
        color: Theme.of(context).scaffoldBackgroundColor,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(32)),
        clipBehavior: Clip.antiAlias,
        child: Column(
          children: [
            const SizedBox(height: 10),
            Container(
              width: 42,
              height: 4,
              decoration: BoxDecoration(
                color: AppTheme.line,
                borderRadius: BorderRadius.circular(4),
              ),
            ),
            Expanded(
              child: Center(
                child: ConstrainedBox(
                  constraints: const BoxConstraints(maxWidth: 680),
                  child: ListView(
                    physics: const BouncingScrollPhysics(),
                    padding: const EdgeInsets.fromLTRB(20, 18, 20, 34),
                    children: [
                      Row(
                        children: [
                          Container(
                            width: 48,
                            height: 48,
                            decoration: BoxDecoration(
                              gradient: const LinearGradient(
                                colors: [AppTheme.blue, AppTheme.blueBright],
                              ),
                              borderRadius: BorderRadius.circular(16),
                            ),
                            child: const Icon(
                              Icons.payments_outlined,
                              color: Colors.white,
                            ),
                          ),
                          const SizedBox(width: 13),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  'Settle workforce wallet',
                                  style: Theme.of(context).textTheme.titleLarge
                                      ?.copyWith(fontWeight: FontWeight.w800),
                                ),
                                const SizedBox(height: 3),
                                Text(
                                  member.displayName,
                                  style: Theme.of(context).textTheme.bodySmall
                                      ?.copyWith(color: AppTheme.muted),
                                ),
                              ],
                            ),
                          ),
                          IconButton(
                            tooltip: 'Close',
                            onPressed: action.isLoading
                                ? null
                                : () => Navigator.pop(context, false),
                            icon: const Icon(Icons.close_rounded),
                          ),
                        ],
                      ),
                      const SizedBox(height: 22),
                      Container(
                        padding: const EdgeInsets.all(16),
                        decoration: BoxDecoration(
                          gradient: const LinearGradient(
                            colors: [Color(0xFF101A2D), Color(0xFF1E3654)],
                          ),
                          borderRadius: BorderRadius.circular(22),
                        ),
                        child: Row(
                          children: [
                            Expanded(
                              child: _SummaryValue(
                                label: 'CURRENT BALANCE',
                                value: compactInr(detail.wallet.balance),
                              ),
                            ),
                            Container(
                              width: 1,
                              height: 38,
                              color: Colors.white.withValues(alpha: .12),
                            ),
                            Expanded(
                              child: Padding(
                                padding: const EdgeInsets.only(left: 15),
                                child: _SummaryValue(
                                  label: 'PAID TO DATE',
                                  value: compactInr(detail.wallet.paid),
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 18),
                      TextField(
                        enabled: !action.isLoading,
                        onChanged: editor.setAmount,
                        keyboardType: const TextInputType.numberWithOptions(
                          decimal: true,
                        ),
                        decoration: const InputDecoration(
                          labelText: 'Settlement amount',
                          hintText: '5000',
                          prefixText: 'INR  ',
                          prefixIcon: Icon(Icons.currency_rupee_rounded),
                        ),
                      ),
                      const SizedBox(height: 13),
                      DropdownButtonFormField<LabourPaymentMode>(
                        initialValue: brief.paymentMode,
                        isExpanded: true,
                        decoration: const InputDecoration(
                          labelText: 'Payment mode',
                          prefixIcon: Icon(Icons.account_balance_outlined),
                        ),
                        items: LabourPaymentMode.values
                            .map(
                              (mode) => DropdownMenuItem(
                                value: mode,
                                child: Text(mode.label),
                              ),
                            )
                            .toList(),
                        onChanged: action.isLoading
                            ? null
                            : (value) {
                                if (value != null) editor.setPaymentMode(value);
                              },
                      ),
                      const SizedBox(height: 13),
                      TextField(
                        enabled: !action.isLoading,
                        onChanged: editor.setRemarks,
                        textCapitalization: TextCapitalization.sentences,
                        maxLines: 2,
                        decoration: const InputDecoration(
                          labelText: 'Remarks (optional)',
                          hintText: 'August wage settlement',
                          prefixIcon: Icon(Icons.notes_rounded),
                        ),
                      ),
                      const SizedBox(height: 16),
                      Container(
                        padding: const EdgeInsets.all(14),
                        decoration: BoxDecoration(
                          color: AppTheme.blue.withValues(alpha: .07),
                          borderRadius: BorderRadius.circular(18),
                          border: Border.all(
                            color: AppTheme.blue.withValues(alpha: .16),
                          ),
                        ),
                        child: Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Icon(
                              Icons.verified_user_outlined,
                              color: AppTheme.blue,
                              size: 19,
                            ),
                            const SizedBox(width: 10),
                            Expanded(
                              child: Text(
                                'Submission creates a server ledger payment and recomputes this wallet. The current endpoint does not provide approval, receipt or reversal workflows.',
                                style: Theme.of(context).textTheme.labelSmall
                                    ?.copyWith(
                                      color: AppTheme.muted,
                                      height: 1.45,
                                    ),
                              ),
                            ),
                          ],
                        ),
                      ),
                      if (action.hasError) ...[
                        const SizedBox(height: 13),
                        Text(
                          action.error is ApiException
                              ? (action.error! as ApiException).message
                              : '${action.error}',
                          style: Theme.of(context).textTheme.labelSmall
                              ?.copyWith(
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
                            : const Icon(Icons.check_rounded),
                        label: Text(
                          action.isLoading
                              ? 'Recording settlement...'
                              : 'Record settlement',
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _submit(
    BuildContext context,
    WidgetRef ref,
    WalletSettlementBrief brief,
  ) async {
    final validation = brief.validationMessage;
    if (validation != null) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text(validation)));
      return;
    }
    final settled = await ref
        .read(walletActionControllerProvider.notifier)
        .settle(brief);
    if (settled && context.mounted) Navigator.pop(context, true);
  }
}

class _SummaryValue extends StatelessWidget {
  const _SummaryValue({required this.label, required this.value});
  final String label;
  final String value;

  @override
  Widget build(BuildContext context) => Column(
    crossAxisAlignment: CrossAxisAlignment.start,
    children: [
      Text(
        value,
        maxLines: 1,
        overflow: TextOverflow.ellipsis,
        style: Theme.of(context).textTheme.titleMedium?.copyWith(
          color: Colors.white,
          fontWeight: FontWeight.w800,
        ),
      ),
      const SizedBox(height: 4),
      Text(
        label,
        style: Theme.of(context).textTheme.labelSmall?.copyWith(
          color: const Color(0xFFBFCBDC),
          fontSize: 8,
          fontWeight: FontWeight.w700,
          letterSpacing: .4,
        ),
      ),
    ],
  );
}
