import 'package:flutter/material.dart';

import '../../../../core/theme/app_theme.dart';
import '../../models/dashboard_data.dart';
import 'dashboard_primitives.dart';

class DashboardFinancialOverview extends StatelessWidget {
  const DashboardFinancialOverview({super.key, required this.data});

  final DashboardData data;

  @override
  Widget build(BuildContext context) {
    final stats = data.stats;
    final isLoss = stats.netProfit < 0;
    final balance = isLoss ? stats.netLoss : stats.netProfit;
    final heading = isLoss ? 'Net loss' : 'Net profit';
    final accent = isLoss ? AppTheme.danger : AppTheme.success;
    final hasPayments = stats.totalRevenue > 0 || stats.expense > 0;

    return Container(
      clipBehavior: Clip.antiAlias,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(30),
        gradient: const LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [Color(0xFF07101F), Color(0xFF0A2851), Color(0xFF0A5AB4)],
          stops: [0, .64, 1],
        ),
        boxShadow: const [
          BoxShadow(
            color: Color(0x24112744),
            blurRadius: 30,
            offset: Offset(0, 14),
          ),
        ],
      ),
      child: Stack(
        children: [
          Positioned(
            right: -46,
            top: -52,
            child: Container(
              width: 184,
              height: 184,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: accent.withValues(alpha: .16),
              ),
            ),
          ),
          Padding(
            padding: const EdgeInsets.all(20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 10,
                        vertical: 7,
                      ),
                      decoration: BoxDecoration(
                        color: Colors.white.withValues(alpha: .11),
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(
                          color: Colors.white.withValues(alpha: .14),
                        ),
                      ),
                      child: const Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(
                            Icons.account_balance_wallet_outlined,
                            size: 14,
                            color: Color(0xFFD7E6FF),
                          ),
                          SizedBox(width: 6),
                          Text(
                            'LIVE FINANCIAL POSITION',
                            style: TextStyle(
                              color: Color(0xFFD7E6FF),
                              fontSize: 9,
                              fontWeight: FontWeight.w800,
                              letterSpacing: .7,
                            ),
                          ),
                        ],
                      ),
                    ),
                    const Spacer(),
                    Text(
                      hasPayments ? 'Payment ledger' : 'No ledger entries',
                      style: Theme.of(context).textTheme.labelSmall?.copyWith(
                        color: const Color(0xFFB5C8E2),
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 22),
                Text(
                  heading,
                  style: Theme.of(context).textTheme.labelLarge?.copyWith(
                    color: const Color(0xFFB5C8E2),
                    fontWeight: FontWeight.w700,
                  ),
                ),
                const SizedBox(height: 5),
                Text(
                  formatFullInr(balance),
                  style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                    color: Colors.white,
                    fontWeight: FontWeight.w800,
                    letterSpacing: -1.1,
                  ),
                ),
                const SizedBox(height: 5),
                Text(
                  isLoss
                      ? 'Costs recorded are higher than collections.'
                      : 'Collections minus labour, material and other costs.',
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    color: const Color(0xFFC0D1E7),
                  ),
                ),
                const SizedBox(height: 22),
                LayoutBuilder(
                  builder: (context, constraints) {
                    final compact = constraints.maxWidth < 430;
                    final statsWidgets = [
                      _FinancialValue(
                        label: 'Collected',
                        value: stats.totalRevenue,
                        color: AppTheme.success,
                      ),
                      _FinancialValue(
                        label: 'Total spent',
                        value: stats.expense,
                        color: AppTheme.orangeBright,
                      ),
                      _FinancialValue(
                        label: 'Outstanding',
                        value: stats.pendingPayments,
                        color: const Color(0xFFB9D4FF),
                      ),
                    ];
                    if (compact) {
                      return Column(
                        children: statsWidgets
                            .map(
                              (item) => Padding(
                                padding: const EdgeInsets.only(bottom: 10),
                                child: item,
                              ),
                            )
                            .toList(),
                      );
                    }
                    return Row(
                      children: statsWidgets
                          .map((item) => Expanded(child: item))
                          .toList(),
                    );
                  },
                ),
                const SizedBox(height: 12),
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.symmetric(
                    horizontal: 12,
                    vertical: 11,
                  ),
                  decoration: BoxDecoration(
                    color: Colors.white.withValues(alpha: .07),
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(
                      color: Colors.white.withValues(alpha: .1),
                    ),
                  ),
                  child: Wrap(
                    alignment: WrapAlignment.spaceBetween,
                    runSpacing: 9,
                    children: [
                      _CostBreakdown(
                        label: 'Labour',
                        value: stats.labourExpense,
                      ),
                      _CostBreakdown(
                        label: 'Material',
                        value: stats.materialExpense,
                      ),
                      _CostBreakdown(label: 'Other', value: stats.otherExpense),
                      _CostBreakdown(label: 'Budget', value: stats.totalBudget),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _FinancialValue extends StatelessWidget {
  const _FinancialValue({
    required this.label,
    required this.value,
    required this.color,
  });

  final String label;
  final double value;
  final Color color;

  @override
  Widget build(BuildContext context) => Column(
    crossAxisAlignment: CrossAxisAlignment.start,
    children: [
      Text(
        label.toUpperCase(),
        style: const TextStyle(
          color: Color(0xFFB5C8E2),
          fontSize: 9,
          fontWeight: FontWeight.w800,
          letterSpacing: .55,
        ),
      ),
      const SizedBox(height: 5),
      Text(
        formatFullInr(value),
        style: Theme.of(context).textTheme.titleSmall?.copyWith(
          color: color,
          fontWeight: FontWeight.w800,
          letterSpacing: -.25,
        ),
      ),
    ],
  );
}

class _CostBreakdown extends StatelessWidget {
  const _CostBreakdown({required this.label, required this.value});

  final String label;
  final double value;

  @override
  Widget build(BuildContext context) => SizedBox(
    width: 130,
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: const TextStyle(color: Color(0xFFB5C8E2), fontSize: 10),
        ),
        const SizedBox(height: 2),
        Text(
          formatFullInr(value),
          style: const TextStyle(
            color: Colors.white,
            fontSize: 12,
            fontWeight: FontWeight.w800,
          ),
        ),
      ],
    ),
  );
}
