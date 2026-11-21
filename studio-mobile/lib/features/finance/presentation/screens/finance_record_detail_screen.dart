import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/theme/app_theme.dart';
import '../../../../core/utils/app_formatters.dart';
import '../../../../core/widgets/app_ui.dart';
import '../../models/finance_models.dart';
import '../../providers/finance_provider.dart';

enum FinanceRecordKind { payment, expense }

class FinanceRecordDetailScreen extends ConsumerWidget {
  const FinanceRecordDetailScreen({
    super.key,
    required this.recordId,
    required this.kind,
  });

  final String recordId;
  final FinanceRecordKind kind;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final studio = ref.watch(financeStudioControllerProvider);
    return AppPage(
      title: kind == FinanceRecordKind.payment
          ? 'Payment Detail'
          : 'Expense Detail',
      subtitle: 'Server-issued record identity and project audit context.',
      actions: [
        IconButton(
          tooltip: 'Refresh record',
          onPressed: () =>
              ref.read(financeStudioControllerProvider.notifier).refresh(),
          icon: const Icon(Icons.refresh_rounded),
        ),
      ],
      child: studio.when(
        loading: () => ListView(
          padding: const EdgeInsets.fromLTRB(20, 6, 20, 120),
          children: const [
            AppSkeleton(height: 220, radius: 32),
            SizedBox(height: 14),
            AppSkeleton(height: 240),
          ],
        ),
        error: (error, _) => ListView(
          padding: const EdgeInsets.fromLTRB(20, 6, 20, 120),
          children: [
            EmptyPanel(
              title: 'Record unavailable',
              message: '$error',
              icon: Icons.cloud_off_rounded,
              actionLabel: 'Reconnect',
              onAction: () =>
                  ref.read(financeStudioControllerProvider.notifier).load(),
            ),
          ],
        ),
        data: (data) => _DetailBody(data: data, recordId: recordId, kind: kind),
      ),
    );
  }
}

class _DetailBody extends StatelessWidget {
  const _DetailBody({
    required this.data,
    required this.recordId,
    required this.kind,
  });

  final FinanceStudioData data;
  final String recordId;
  final FinanceRecordKind kind;

  @override
  Widget build(BuildContext context) {
    PaymentRecord? payment;
    ExpenseRecord? expense;
    if (kind == FinanceRecordKind.payment) {
      for (final item in data.payments) {
        if (item.id == recordId) payment = item;
      }
    } else {
      for (final item in data.expenses) {
        if (item.id == recordId) expense = item;
      }
    }
    if (payment == null && expense == null) {
      return ListView(
        padding: const EdgeInsets.fromLTRB(20, 6, 20, 120),
        children: const [
          EmptyPanel(
            title: 'Record not found',
            message:
                'This finance record is not available to the signed-in role.',
            icon: Icons.lock_outline_rounded,
          ),
        ],
      );
    }
    final amount = payment?.amount ?? expense!.amount;
    final date = payment?.date ?? expense!.date;
    final description =
        payment?.displayDescription ?? expense!.displayDescription;
    final category = payment?.type.label ?? expense!.category.label;
    final siteId = payment?.siteId ?? expense!.siteId;
    final attachment = payment?.invoiceUrl ?? expense!.receiptUrl;
    final isInflow = payment?.isInflow == true;
    final partyLabel = payment != null ? 'Party' : 'Paid by';
    final party = payment?.party ?? expense?.paidBy;
    final createdBy = payment?.createdBy ?? expense?.createdBy;
    final createdAt = payment?.createdAt ?? expense?.createdAt;
    return ListView(
      padding: const EdgeInsets.fromLTRB(20, 6, 20, 120),
      children: [
        Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 920),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Container(
                  padding: const EdgeInsets.all(28),
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(32),
                    gradient: const LinearGradient(
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                      colors: [Color(0xFF07172F), Color(0xFF0E3266)],
                    ),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          StatusBadge(
                            label: category,
                            tone: isInflow ? AppTheme.success : AppTheme.orange,
                          ),
                          const Spacer(),
                          const Icon(
                            Icons.verified_user_outlined,
                            color: Colors.white70,
                            size: 21,
                          ),
                        ],
                      ),
                      const SizedBox(height: 22),
                      Text(
                        '${isInflow ? '+' : '-'}${compactInr(amount)}',
                        style: Theme.of(context).textTheme.displaySmall
                            ?.copyWith(
                              color: Colors.white,
                              fontWeight: FontWeight.w800,
                              letterSpacing: -2,
                            ),
                      ),
                      const SizedBox(height: 9),
                      Text(
                        description,
                        style: Theme.of(context).textTheme.titleMedium
                            ?.copyWith(
                              color: Colors.white,
                              fontWeight: FontWeight.w700,
                            ),
                      ),
                      const SizedBox(height: 6),
                      Text(
                        '${data.siteName(siteId)}  |  ${appDate(date)}',
                        style: Theme.of(
                          context,
                        ).textTheme.bodySmall?.copyWith(color: Colors.white70),
                      ),
                    ],
                  ),
                ).animate().fadeIn(duration: 320.ms).slideY(begin: .06, end: 0),
                const SizedBox(height: 16),
                SurfaceCard(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Audit details',
                        style: Theme.of(context).textTheme.titleMedium
                            ?.copyWith(fontWeight: FontWeight.w800),
                      ),
                      const SizedBox(height: 16),
                      _DetailRow(
                        label: 'Project site',
                        value: data.siteName(siteId),
                      ),
                      _DetailRow(label: 'Record date', value: appDate(date)),
                      _DetailRow(label: 'Classification', value: category),
                      _DetailRow(
                        label: partyLabel,
                        value: party ?? 'Not supplied',
                      ),
                      _DetailRow(label: 'Record ID', value: recordId),
                      _DetailRow(
                        label: 'Created by',
                        value: createdBy ?? 'Server account',
                      ),
                      _DetailRow(
                        label: 'Created at',
                        value: createdAt == null
                            ? 'Not supplied by API'
                            : appDate(createdAt),
                        last: true,
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 16),
                SurfaceCard(
                  child: Row(
                    children: [
                      Container(
                        width: 46,
                        height: 46,
                        decoration: BoxDecoration(
                          color:
                              (attachment == null
                                      ? AppTheme.muted
                                      : AppTheme.blue)
                                  .withValues(alpha: .1),
                          borderRadius: BorderRadius.circular(16),
                        ),
                        child: Icon(
                          attachment == null
                              ? Icons.link_off_rounded
                              : Icons.attachment_rounded,
                          color: attachment == null
                              ? AppTheme.muted
                              : AppTheme.blue,
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              payment != null
                                  ? 'Invoice attachment'
                                  : 'Receipt evidence',
                              style: Theme.of(context).textTheme.labelLarge
                                  ?.copyWith(fontWeight: FontWeight.w800),
                            ),
                            const SizedBox(height: 3),
                            Text(
                              attachment == null
                                  ? 'No secure attachment was supplied.'
                                  : 'Secure Cloudinary URL is linked to this record.',
                              style: Theme.of(context).textTheme.bodySmall
                                  ?.copyWith(color: AppTheme.muted),
                            ),
                          ],
                        ),
                      ),
                      if (attachment != null)
                        TextButton.icon(
                          onPressed: () async {
                            await Clipboard.setData(
                              ClipboardData(text: attachment),
                            );
                            if (context.mounted) {
                              ScaffoldMessenger.of(context).showSnackBar(
                                const SnackBar(
                                  content: Text(
                                    'Secure attachment link copied.',
                                  ),
                                ),
                              );
                            }
                          },
                          icon: const Icon(Icons.copy_rounded, size: 17),
                          label: const Text('Copy link'),
                        ),
                    ],
                  ),
                ),
                const SizedBox(height: 14),
                Text(
                  'This view reports recorded cash movement only. It is not a GST invoice, bank reconciliation, or accrued-profit statement.',
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    color: AppTheme.muted,
                    height: 1.45,
                  ),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }
}

class _DetailRow extends StatelessWidget {
  const _DetailRow({
    required this.label,
    required this.value,
    this.last = false,
  });
  final String label;
  final String value;
  final bool last;

  @override
  Widget build(BuildContext context) => Container(
    padding: const EdgeInsets.symmetric(vertical: 12),
    decoration: BoxDecoration(
      border: last
          ? null
          : const Border(bottom: BorderSide(color: AppTheme.line)),
    ),
    child: Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        SizedBox(
          width: 112,
          child: Text(
            label,
            style: Theme.of(
              context,
            ).textTheme.bodySmall?.copyWith(color: AppTheme.muted),
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: SelectableText(
            value,
            textAlign: TextAlign.right,
            style: Theme.of(
              context,
            ).textTheme.bodySmall?.copyWith(fontWeight: FontWeight.w700),
          ),
        ),
      ],
    ),
  );
}
