import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/theme/app_theme.dart';
import '../../../../core/utils/app_formatters.dart';
import '../../../../core/widgets/app_ui.dart';
import '../../models/ai_wallet_models.dart';
import '../../providers/ai_wallet_provider.dart';

class AiWalletScreen extends ConsumerWidget {
  const AiWalletScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final state = ref.watch(aiWalletControllerProvider);
    return AppPage(
      title: 'AI Credits Wallet',
      subtitle: 'Live design credits, verified purchases and usage ledger.',
      actions: [
        IconButton(
          tooltip: 'Refresh wallet',
          onPressed: () => ref.read(aiWalletControllerProvider.notifier).refresh(),
          icon: const Icon(Icons.refresh_rounded),
        ),
      ],
      child: state.when(
        loading: _loading,
        error: (error, _) => _error(context, ref, error),
        data: (data) => _WalletBody(data: data),
      ),
    );
  }

  Widget _loading() => ListView(
    padding: const EdgeInsets.fromLTRB(20, 4, 20, 120),
    children: const [
      AppSkeleton(height: 218, radius: 28),
      SizedBox(height: 16),
      AppSkeleton(height: 190),
    ],
  );

  Widget _error(BuildContext context, WidgetRef ref, Object error) => ListView(
    padding: const EdgeInsets.all(20),
    children: [
      EmptyPanel(
        title: 'AI wallet unavailable',
        message: '$error',
        icon: Icons.account_balance_wallet_outlined,
        actionLabel: 'Retry',
        onAction: () => ref.read(aiWalletControllerProvider.notifier).load(),
      ),
    ],
  );
}

class _WalletBody extends ConsumerWidget {
  const _WalletBody({required this.data});
  final AiWalletData data;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    if (data.isRestricted) {
      return ListView(
        padding: const EdgeInsets.all(20),
        children: [
          EmptyPanel(
            title: 'Contractor-managed credits',
            message: data.message ?? 'Your role cannot view company AI credit balances.',
            icon: Icons.lock_outline_rounded,
          ).animate().fadeIn(duration: 240.ms).slideY(begin: .04, end: 0),
        ],
      );
    }
    return RefreshIndicator(
      onRefresh: () => ref.read(aiWalletControllerProvider.notifier).refresh(),
      child: LayoutBuilder(
        builder: (context, constraints) => ListView(
          physics: const AlwaysScrollableScrollPhysics(parent: BouncingScrollPhysics()),
          padding: const EdgeInsets.fromLTRB(20, 4, 20, 120),
          children: [
            Center(
              child: ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 980),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    _WalletHero(data: data).animate().fadeIn(duration: 280.ms).slideY(begin: .05, end: 0),
                    if (data.isOffline) ...[
                      const SizedBox(height: 12),
                      _OfflineBanner(syncedAt: data.fetchedAt),
                    ],
                    const SizedBox(height: 18),
                    _PurchaseCard(data: data),
                    const SizedBox(height: 24),
                    const SectionTitle(title: 'Credit activity'),
                    const SizedBox(height: 10),
                    _TransactionList(transactions: data.transactions),
                    const SizedBox(height: 24),
                    const SectionTitle(title: 'Purchase verification'),
                    const SizedBox(height: 10),
                    _PurchaseList(purchases: data.purchases),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _WalletHero extends StatelessWidget {
  const _WalletHero({required this.data});
  final AiWalletData data;

  @override
  Widget build(BuildContext context) => Container(
    padding: const EdgeInsets.all(22),
    decoration: BoxDecoration(
      borderRadius: BorderRadius.circular(30),
      gradient: const LinearGradient(
        begin: Alignment.topLeft,
        end: Alignment.bottomRight,
        colors: [Color(0xFF081425), Color(0xFF123C79), Color(0xFF1966C2)],
      ),
      boxShadow: const [
        BoxShadow(color: Color(0x33101A2D), blurRadius: 28, offset: Offset(0, 16)),
      ],
    ),
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Container(
              width: 48,
              height: 48,
              decoration: BoxDecoration(
                color: Colors.white.withValues(alpha: .14),
                borderRadius: BorderRadius.circular(17),
              ),
              child: const Icon(Icons.auto_awesome_rounded, color: Colors.white),
            ),
            const Spacer(),
            StatusBadge(
              label: data.isOffline ? 'CACHED LEDGER' : 'LIVE LEDGER',
              tone: const Color(0xFFB9D5FF),
            ),
          ],
        ),
        const SizedBox(height: 26),
        Text(
          '${data.wallet?.credits ?? 'Unavailable'}',
          style: Theme.of(context).textTheme.displaySmall?.copyWith(
            color: Colors.white,
            fontWeight: FontWeight.w800,
            letterSpacing: -1.5,
          ),
        ),
        const SizedBox(height: 4),
        Text(
          'AI design credits available',
          style: Theme.of(context).textTheme.bodyMedium?.copyWith(color: const Color(0xFFD4E4FF)),
        ),
        const SizedBox(height: 18),
        Text(
          'Credits are consumed only after an AI generation request is accepted by the backend.',
          style: Theme.of(context).textTheme.labelSmall?.copyWith(color: const Color(0xFFB9D5FF), height: 1.45),
        ),
      ],
    ),
  );
}

class _PurchaseCard extends ConsumerWidget {
  const _PurchaseCard({required this.data});
  final AiWalletData data;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final config = data.purchaseConfig;
    if (config == null || config.packs.isEmpty) {
      return SurfaceCard(
        child: Text(
          'Credit purchases are not configured by the backend for this workspace yet.',
          style: Theme.of(context).textTheme.bodySmall?.copyWith(color: AppTheme.muted),
        ),
      );
    }
    return SurfaceCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const SectionTitle(title: 'Add AI credits'),
          const SizedBox(height: 5),
          Text(
            'Pay to ${config.payeeName} using ${config.upiId}, then submit the verified UPI reference.',
            style: Theme.of(context).textTheme.bodySmall?.copyWith(color: AppTheme.muted, height: 1.45),
          ),
          const SizedBox(height: 14),
          SizedBox(
            width: double.infinity,
            child: FilledButton.icon(
              style: FilledButton.styleFrom(backgroundColor: AppTheme.blue),
              onPressed: () => _showPurchaseSheet(context, ref, config),
              icon: const Icon(Icons.add_card_rounded),
              label: const Text('Submit UPI payment'),
            ),
          ),
        ],
      ),
    );
  }
}

class _TransactionList extends StatelessWidget {
  const _TransactionList({required this.transactions});
  final List<AiCreditTransaction> transactions;

  @override
  Widget build(BuildContext context) {
    if (transactions.isEmpty) {
      return const EmptyPanel(
        title: 'No credit activity yet',
        message: 'Approved purchases and AI generation usage will appear in this live ledger.',
        icon: Icons.receipt_long_outlined,
      );
    }
    return SurfaceCard(
      padding: EdgeInsets.zero,
      child: Column(
        children: transactions.take(20).map((transaction) => _LedgerRow(transaction: transaction)).toList(growable: false),
      ),
    );
  }
}

class _LedgerRow extends StatelessWidget {
  const _LedgerRow({required this.transaction});
  final AiCreditTransaction transaction;

  @override
  Widget build(BuildContext context) {
    final positive = transaction.isCredit;
    final tone = positive ? AppTheme.success : AppTheme.blue;
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: const BoxDecoration(border: Border(bottom: BorderSide(color: AppTheme.line))),
      child: Row(
        children: [
          Container(
            width: 38,
            height: 38,
            decoration: BoxDecoration(color: tone.withValues(alpha: .11), borderRadius: BorderRadius.circular(13)),
            child: Icon(positive ? Icons.add_rounded : Icons.auto_awesome_rounded, color: tone, size: 18),
          ),
          const SizedBox(width: 11),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(transaction.description, maxLines: 1, overflow: TextOverflow.ellipsis, style: Theme.of(context).textTheme.labelLarge?.copyWith(fontWeight: FontWeight.w800)),
                const SizedBox(height: 3),
                Text(appDate(transaction.createdAt, fallback: 'Awaiting timestamp'), style: Theme.of(context).textTheme.labelSmall?.copyWith(color: AppTheme.muted)),
              ],
            ),
          ),
          Text('${positive ? '+' : ''}${transaction.credits}', style: Theme.of(context).textTheme.titleSmall?.copyWith(color: tone, fontWeight: FontWeight.w800)),
        ],
      ),
    );
  }
}

class _PurchaseList extends StatelessWidget {
  const _PurchaseList({required this.purchases});
  final List<AiCreditPurchaseRequest> purchases;

  @override
  Widget build(BuildContext context) {
    if (purchases.isEmpty) {
      return const EmptyPanel(
        title: 'No purchase requests',
        message: 'Submitted UPI references will appear here while the team verifies them.',
        icon: Icons.verified_user_outlined,
      );
    }
    return SurfaceCard(
      padding: EdgeInsets.zero,
      child: Column(
        children: purchases.take(12).map((purchase) => ListTile(
          contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 5),
          leading: const Icon(Icons.receipt_long_outlined, color: AppTheme.blue),
          title: Text('${purchase.credits} credits', style: const TextStyle(fontWeight: FontWeight.w800)),
          subtitle: Text('${compactInr(purchase.amount)} · ${appDate(purchase.createdAt)}'),
          trailing: StatusBadge(label: purchase.status, tone: purchase.isPending ? AppTheme.warning : AppTheme.success),
        )).toList(growable: false),
      ),
    );
  }
}

class _OfflineBanner extends StatelessWidget {
  const _OfflineBanner({required this.syncedAt});
  final DateTime syncedAt;

  @override
  Widget build(BuildContext context) => Container(
    padding: const EdgeInsets.all(12),
    decoration: BoxDecoration(color: AppTheme.warning.withValues(alpha: .1), borderRadius: BorderRadius.circular(16)),
    child: Text('Offline: displaying the wallet last synced on ${appDate(syncedAt)}.', style: Theme.of(context).textTheme.labelSmall?.copyWith(color: AppTheme.warning, fontWeight: FontWeight.w700)),
  );
}

Future<void> _showPurchaseSheet(
  BuildContext context,
  WidgetRef ref,
  AiCreditPurchaseConfig config,
) async {
  final messenger = ScaffoldMessenger.of(context);
  final formKey = GlobalKey<FormState>();
  final utr = TextEditingController();
  final note = TextEditingController();
  AiCreditPack selected = config.packs.first;
  await showModalBottomSheet<void>(
    context: context,
    isScrollControlled: true,
    backgroundColor: Colors.transparent,
    builder: (sheetContext) => StatefulBuilder(
      builder: (context, setSheetState) => Padding(
        padding: EdgeInsets.fromLTRB(16, 0, 16, MediaQuery.viewInsetsOf(context).bottom + 16),
        child: SurfaceCard(
          child: Form(
            key: formKey,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const SectionTitle(title: 'Verify UPI payment'),
                const SizedBox(height: 8),
                Text('Pay ${config.payeeName} at ${config.upiId}. Select the pack you paid for and enter its UTR.', style: Theme.of(context).textTheme.bodySmall?.copyWith(color: AppTheme.muted, height: 1.45)),
                const SizedBox(height: 16),
                DropdownButtonFormField<AiCreditPack>(
                  initialValue: selected,
                  decoration: const InputDecoration(labelText: 'Credit pack'),
                  items: config.packs.map((pack) => DropdownMenuItem(value: pack, child: Text('${pack.credits} credits · ${compactInr(pack.amount)}'))).toList(growable: false),
                  onChanged: (value) => value == null ? null : setSheetState(() => selected = value),
                ),
                const SizedBox(height: 12),
                TextFormField(
                  controller: utr,
                  textCapitalization: TextCapitalization.characters,
                  decoration: const InputDecoration(labelText: 'UPI transaction reference (UTR)'),
                  validator: (value) => value == null || value.trim().length < 4 ? 'Enter a valid UTR.' : null,
                ),
                const SizedBox(height: 12),
                TextField(controller: note, maxLines: 2, decoration: const InputDecoration(labelText: 'Note (optional)')),
                const SizedBox(height: 16),
                SizedBox(width: double.infinity, child: FilledButton(
                  style: FilledButton.styleFrom(backgroundColor: AppTheme.blue),
                  onPressed: () async {
                    if (!formKey.currentState!.validate()) return;
                    try {
                      await ref.read(aiWalletControllerProvider.notifier).requestPurchase(AiCreditPurchaseInput(pack: selected.code, utr: utr.text, note: note.text));
                      if (context.mounted) Navigator.of(context).pop();
                      messenger.showSnackBar(const SnackBar(content: Text('Payment reference submitted for verification.')));
                    } catch (error) {
                      if (sheetContext.mounted) ScaffoldMessenger.of(sheetContext).showSnackBar(SnackBar(content: Text('$error')));
                    }
                  },
                  child: const Text('Submit for verification'),
                )),
              ],
            ),
          ),
        ),
      ),
    ),
  );
  utr.dispose();
  note.dispose();
}
