import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/theme/app_theme.dart';
import '../../../../core/widgets/app_ui.dart';
import '../../models/finance_models.dart';
import '../../providers/finance_provider.dart';
import '../widgets/finance_creation_sheets.dart';
import '../widgets/finance_widgets.dart';

class FinanceScreen extends ConsumerStatefulWidget {
  const FinanceScreen({super.key, this.initialWorkspace, this.initialSiteId});

  final FinanceWorkspace? initialWorkspace;
  final String? initialSiteId;

  @override
  ConsumerState<FinanceScreen> createState() => _FinanceScreenState();
}

class _FinanceScreenState extends ConsumerState<FinanceScreen> {
  bool _initialApplied = false;

  @override
  Widget build(BuildContext context) {
    final studio = ref.watch(financeStudioControllerProvider);
    final data = studio.valueOrNull;
    if (data != null && !_initialApplied) {
      _initialApplied = true;
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (!mounted) return;
        ref
            .read(financeStudioControllerProvider.notifier)
            .applyInitial(
              workspace: widget.initialWorkspace,
              siteId: widget.initialSiteId,
            );
      });
    }
    return Material(
      color: Theme.of(context).scaffoldBackgroundColor,
      child: SafeArea(
        bottom: false,
        child: Column(
          children: [
            _FinanceHeader(
              data: data,
              onRefresh: _refresh,
              onCreate: data == null ? null : () => _create(data),
            ),
            Expanded(
              child: studio.when(
                loading: () => const FinanceLoadingView(),
                error: (error, _) => _FinanceError(
                  error: error,
                  onRetry: () =>
                      ref.read(financeStudioControllerProvider.notifier).load(),
                ),
                data: _FinanceWorkspaceView.new,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _refresh() async {
    try {
      await ref.read(financeStudioControllerProvider.notifier).refresh();
    } catch (error) {
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('$error')));
      }
    }
  }

  Future<void> _create(FinanceStudioData data) async {
    if (data.isOffline) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Reconnect before changing finance records.'),
        ),
      );
      return;
    }
    final expenseOnly =
        data.isSupervisor || data.workspace == FinanceWorkspace.expenses;
    late final bool created;
    if (expenseOnly) {
      created = await showExpenseCreationSheet(
        context,
        ref,
        data,
        initialSiteId: data.siteFilter,
      );
    } else {
      created = await showPaymentCreationSheet(
        context,
        ref,
        data,
        initialSiteId: data.siteFilter,
      );
    }
    if (created && mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            expenseOnly
                ? 'Field expense synced to the live ledger.'
                : 'Payment synced to the live ledger.',
          ),
        ),
      );
    }
  }
}

class _FinanceHeader extends StatelessWidget {
  const _FinanceHeader({
    required this.data,
    required this.onRefresh,
    required this.onCreate,
  });

  final FinanceStudioData? data;
  final VoidCallback onRefresh;
  final VoidCallback? onCreate;

  @override
  Widget build(BuildContext context) {
    final title = data?.isClient == true
        ? 'Payment History'
        : 'Finance Control';
    final subtitle = switch (data?.audience) {
      FinanceAudience.supervisor =>
        'Assigned-site expenses and receipt evidence.',
      FinanceAudience.client =>
        'Verified receipts recorded by your contractor.',
      _ => 'Project cash-flow, payments and field expenses.',
    };
    final createLabel =
        data?.isSupervisor == true ||
            data?.workspace == FinanceWorkspace.expenses
        ? 'Add expense'
        : 'Record payment';
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 18, 20, 12),
      child: LayoutBuilder(
        builder: (context, constraints) {
          final compact = constraints.maxWidth < 560;
          return Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: Theme.of(context).textTheme.headlineSmall
                          ?.copyWith(
                            fontWeight: FontWeight.w800,
                            letterSpacing: -.9,
                          ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      subtitle,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: Theme.of(
                        context,
                      ).textTheme.bodySmall?.copyWith(color: AppTheme.muted),
                    ),
                  ],
                ),
              ),
              IconButton.filledTonal(
                tooltip: 'Refresh finance',
                onPressed: onRefresh,
                icon: const Icon(Icons.refresh_rounded),
              ),
              if (onCreate != null && data?.isClient != true) ...[
                const SizedBox(width: 8),
                if (compact)
                  IconButton.filled(
                    tooltip: createLabel,
                    onPressed: onCreate,
                    icon: const Icon(Icons.add_rounded),
                    style: IconButton.styleFrom(
                      backgroundColor: AppTheme.orange,
                    ),
                  )
                else
                  FilledButton.icon(
                    onPressed: onCreate,
                    icon: const Icon(Icons.add_rounded),
                    label: Text(createLabel),
                    style: FilledButton.styleFrom(
                      backgroundColor: AppTheme.orange,
                      minimumSize: const Size(0, 48),
                    ),
                  ),
              ],
            ],
          );
        },
      ),
    ).animate().fadeIn(duration: 240.ms);
  }
}

class _FinanceWorkspaceView extends ConsumerWidget {
  const _FinanceWorkspaceView(this.data);
  final FinanceStudioData data;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final controller = ref.read(financeStudioControllerProvider.notifier);
    return RefreshIndicator(
      onRefresh: controller.refresh,
      child: ListView(
        padding: const EdgeInsets.fromLTRB(20, 6, 20, 120),
        children: [
          Center(
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 1240),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  if (data.isOffline) ...[
                    const _OfflineFinanceBanner(),
                    const SizedBox(height: 14),
                  ],
                  FinanceHero(data: data),
                  const SizedBox(height: 18),
                  FinanceWorkspaceTabs(
                    data: data,
                    onChanged: controller.setWorkspace,
                  ),
                  const SizedBox(height: 14),
                  _FinanceFilters(data: data),
                  const SizedBox(height: 18),
                  switch (data.workspace) {
                    FinanceWorkspace.overview => _FinanceOverview(data: data),
                    FinanceWorkspace.payments => _PaymentsWorkspace(data: data),
                    FinanceWorkspace.expenses => _ExpensesWorkspace(data: data),
                  },
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _FinanceFilters extends ConsumerWidget {
  const _FinanceFilters({required this.data});
  final FinanceStudioData data;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final controller = ref.read(financeStudioControllerProvider.notifier);
    return SurfaceCard(
      child: LayoutBuilder(
        builder: (context, constraints) {
          final width = constraints.maxWidth;
          final fieldWidth = width >= 920
              ? (width - 36) / 4
              : width >= 600
              ? (width - 12) / 2
              : width;
          final fields = <Widget>[
            SizedBox(
              width: fieldWidth,
              child: TextFormField(
                key: ValueKey('finance-search-${data.workspace.name}'),
                initialValue: data.query,
                onChanged: controller.setQuery,
                decoration: InputDecoration(
                  hintText: data.workspace == FinanceWorkspace.expenses
                      ? 'Search expense or payer'
                      : 'Search record, party or site',
                  prefixIcon: const Icon(Icons.search_rounded),
                ),
              ),
            ),
            SizedBox(
              width: fieldWidth,
              child: DropdownButtonFormField<String>(
                initialValue: data.siteFilter ?? '',
                isExpanded: true,
                decoration: const InputDecoration(labelText: 'Project site'),
                items: [
                  const DropdownMenuItem(
                    value: '',
                    child: Text('All assigned sites'),
                  ),
                  ...data.sites.map(
                    (site) => DropdownMenuItem(
                      value: site.id,
                      child: Text(
                        site.name,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                  ),
                ],
                onChanged: (value) => controller.setSite(
                  value == null || value.isEmpty ? null : value,
                ),
              ),
            ),
            SizedBox(
              width: fieldWidth,
              child: DropdownButtonFormField<FinancePeriod>(
                initialValue: data.period,
                isExpanded: true,
                decoration: const InputDecoration(
                  labelText: 'Reporting period',
                ),
                items: FinancePeriod.values
                    .map(
                      (period) => DropdownMenuItem(
                        value: period,
                        child: Text(period.label),
                      ),
                    )
                    .toList(),
                onChanged: (value) {
                  if (value != null) controller.setPeriod(value);
                },
              ),
            ),
            if (data.workspace == FinanceWorkspace.payments)
              SizedBox(
                width: fieldWidth,
                child: DropdownButtonFormField<PaymentType?>(
                  initialValue: data.paymentTypeFilter,
                  isExpanded: true,
                  decoration: const InputDecoration(labelText: 'Payment type'),
                  items: [
                    const DropdownMenuItem(
                      value: null,
                      child: Text('All payment types'),
                    ),
                    ...PaymentType.values
                        .where((type) => type != PaymentType.unknown)
                        .map(
                          (type) => DropdownMenuItem(
                            value: type,
                            child: Text(type.label),
                          ),
                        ),
                  ],
                  onChanged: controller.setPaymentType,
                ),
              )
            else if (data.workspace == FinanceWorkspace.expenses)
              SizedBox(
                width: fieldWidth,
                child: DropdownButtonFormField<ExpenseCategory?>(
                  initialValue: data.expenseCategoryFilter,
                  isExpanded: true,
                  decoration: const InputDecoration(
                    labelText: 'Expense category',
                  ),
                  items: [
                    const DropdownMenuItem(
                      value: null,
                      child: Text('All categories'),
                    ),
                    ...ExpenseCategory.values
                        .where(
                          (category) => category != ExpenseCategory.unknown,
                        )
                        .map(
                          (category) => DropdownMenuItem(
                            value: category,
                            child: Text(category.label),
                          ),
                        ),
                  ],
                  onChanged: controller.setExpenseCategory,
                ),
              ),
          ];
          return Wrap(spacing: 12, runSpacing: 12, children: fields);
        },
      ),
    );
  }
}

class _FinanceOverview extends StatelessWidget {
  const _FinanceOverview({required this.data});
  final FinanceStudioData data;

  @override
  Widget build(BuildContext context) => Column(
    crossAxisAlignment: CrossAxisAlignment.stretch,
    children: [
      FinanceMetricGrid(data: data),
      const SizedBox(height: 16),
      LayoutBuilder(
        builder: (context, constraints) {
          final wide = constraints.maxWidth >= 860;
          final chart = CashflowChartCard(data: data);
          final breakdown = ExpenseBreakdownCard(data: data);
          if (!wide) {
            return Column(
              children: [chart, const SizedBox(height: 16), breakdown],
            );
          }
          return Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(flex: 7, child: chart),
              const SizedBox(width: 16),
              Expanded(flex: 4, child: breakdown),
            ],
          );
        },
      ),
      const SizedBox(height: 18),
      _RecentFinance(data: data),
    ],
  );
}

class _RecentFinance extends StatelessWidget {
  const _RecentFinance({required this.data});
  final FinanceStudioData data;

  @override
  Widget build(BuildContext context) {
    if (data.isSupervisor) {
      final records = data.visibleExpenses.take(5).toList();
      return _RecordSection(
        title: 'Recent field expenses',
        subtitle: 'Latest assigned-site spend records.',
        emptyTitle: 'No field expenses yet',
        emptyMessage:
            'New site expenses will appear here after they are recorded.',
        icon: Icons.receipt_long_outlined,
        children: records
            .map(
              (expense) => FinanceRecordCard.expense(
                expense: expense,
                siteName: data.siteName(expense.siteId),
              ),
            )
            .toList(),
      );
    }
    final records = data.visiblePayments.take(5).toList();
    return _RecordSection(
      title: 'Recent ledger activity',
      subtitle: 'Latest receipts and project outflow.',
      emptyTitle: 'No payment activity yet',
      emptyMessage:
          'Live payment records will appear here when they are created.',
      icon: Icons.payments_outlined,
      children: records
          .map(
            (payment) => FinanceRecordCard.payment(
              payment: payment,
              siteName: data.siteName(payment.siteId),
            ),
          )
          .toList(),
    );
  }
}

class _PaymentsWorkspace extends StatelessWidget {
  const _PaymentsWorkspace({required this.data});
  final FinanceStudioData data;

  @override
  Widget build(BuildContext context) => _RecordSection(
    title: data.isClient ? 'Verified payment history' : 'Payment ledger',
    subtitle: data.isClient
        ? 'Read-only receipts recorded against your assigned projects.'
        : 'Client receipts, labour, material and site payment entries.',
    emptyTitle: 'No payments match these filters',
    emptyMessage: data.isClient
        ? 'Contractor-confirmed receipts will appear here.'
        : 'Record a payment to start the project ledger.',
    icon: Icons.account_balance_wallet_outlined,
    children: data.visiblePayments
        .map(
          (payment) => FinanceRecordCard.payment(
            payment: payment,
            siteName: data.siteName(payment.siteId),
          ),
        )
        .toList(),
  );
}

class _ExpensesWorkspace extends StatelessWidget {
  const _ExpensesWorkspace({required this.data});
  final FinanceStudioData data;

  @override
  Widget build(BuildContext context) => _RecordSection(
    title: 'Field expense timeline',
    subtitle: 'Categorized site spend with payer and receipt evidence.',
    emptyTitle: 'No expenses match these filters',
    emptyMessage: 'Add a field expense to create a verified site spend record.',
    icon: Icons.receipt_long_outlined,
    children: data.visibleExpenses
        .map(
          (expense) => FinanceRecordCard.expense(
            expense: expense,
            siteName: data.siteName(expense.siteId),
          ),
        )
        .toList(),
  );
}

class _RecordSection extends StatelessWidget {
  const _RecordSection({
    required this.title,
    required this.subtitle,
    required this.emptyTitle,
    required this.emptyMessage,
    required this.icon,
    required this.children,
  });

  final String title;
  final String subtitle;
  final String emptyTitle;
  final String emptyMessage;
  final IconData icon;
  final List<Widget> children;

  @override
  Widget build(BuildContext context) => Column(
    crossAxisAlignment: CrossAxisAlignment.start,
    children: [
      Text(
        title,
        style: Theme.of(context).textTheme.titleLarge?.copyWith(
          fontWeight: FontWeight.w800,
          letterSpacing: -.5,
        ),
      ),
      const SizedBox(height: 4),
      Text(
        subtitle,
        style: Theme.of(
          context,
        ).textTheme.bodySmall?.copyWith(color: AppTheme.muted),
      ),
      const SizedBox(height: 14),
      if (children.isEmpty)
        EmptyPanel(title: emptyTitle, message: emptyMessage, icon: icon)
      else
        ...children.indexed.map(
          (entry) => Padding(
            padding: const EdgeInsets.only(bottom: 10),
            child: entry.$2
                .animate(delay: (entry.$1.clamp(0, 8) * 45).ms)
                .fadeIn(duration: 220.ms)
                .slideY(begin: .05, end: 0),
          ),
        ),
    ],
  );
}

class _OfflineFinanceBanner extends StatelessWidget {
  const _OfflineFinanceBanner();
  @override
  Widget build(BuildContext context) => Container(
    padding: const EdgeInsets.all(14),
    decoration: BoxDecoration(
      color: AppTheme.orange.withValues(alpha: .09),
      borderRadius: BorderRadius.circular(18),
      border: Border.all(color: AppTheme.orange.withValues(alpha: .18)),
    ),
    child: Row(
      children: [
        const Icon(Icons.cloud_off_rounded, color: AppTheme.orange, size: 20),
        const SizedBox(width: 10),
        Expanded(
          child: Text(
            'Offline snapshot. Finance changes are disabled until the live ledger reconnects.',
            style: Theme.of(
              context,
            ).textTheme.bodySmall?.copyWith(fontWeight: FontWeight.w700),
          ),
        ),
      ],
    ),
  );
}

class _FinanceError extends StatelessWidget {
  const _FinanceError({required this.error, required this.onRetry});
  final Object error;
  final VoidCallback onRetry;

  @override
  Widget build(BuildContext context) => ListView(
    padding: const EdgeInsets.fromLTRB(20, 8, 20, 120),
    children: [
      EmptyPanel(
        title: 'Finance workspace unavailable',
        message: '$error',
        icon: Icons.cloud_off_rounded,
        actionLabel: 'Reconnect',
        onAction: onRetry,
      ),
    ],
  );
}
