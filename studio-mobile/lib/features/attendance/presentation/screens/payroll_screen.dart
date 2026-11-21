import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/network/api_service.dart';
import '../../../../core/theme/app_theme.dart';
import '../../../../core/widgets/app_ui.dart';
import '../../models/workforce_models.dart';
import '../../providers/workforce_provider.dart';
import '../widgets/payroll_widgets.dart';

class PayrollScreen extends ConsumerWidget {
  const PayrollScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final state = ref.watch(payrollControllerProvider);
    return Material(
      color: Theme.of(context).scaffoldBackgroundColor,
      child: SafeArea(
        bottom: false,
        child: state.when(
          loading: () => const PayrollSkeleton(),
          error: (error, stackTrace) => _PayrollError(
            error: error,
            onRetry: () =>
                ref.read(payrollControllerProvider.notifier).refresh(),
          ),
          data: (data) => RefreshIndicator(
            color: AppTheme.orange,
            onRefresh: () =>
                ref.read(payrollControllerProvider.notifier).refresh(),
            child: LayoutBuilder(
              builder: (context, constraints) => ListView(
                key: const PageStorageKey('payroll-workspace-scroll'),
                primary: false,
                physics: const AlwaysScrollableScrollPhysics(
                  parent: BouncingScrollPhysics(),
                ),
                padding: EdgeInsets.fromLTRB(
                  constraints.maxWidth >= 900 ? 30 : 18,
                  18,
                  constraints.maxWidth >= 900 ? 30 : 18,
                  124,
                ),
                children: [
                  Center(
                    child: ConstrainedBox(
                      constraints: const BoxConstraints(maxWidth: 1280),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          _PayrollHeader(
                            onRefresh: () => ref
                                .read(payrollControllerProvider.notifier)
                                .refresh(),
                          ),
                          if (data.isOffline) ...[
                            const SizedBox(height: 13),
                            PayrollOfflineBanner(syncedAt: data.fetchedAt),
                          ],
                          const SizedBox(height: 16),
                          _MonthCommandBar(month: data.month),
                          const SizedBox(height: 16),
                          PayrollHero(data: data),
                          const SizedBox(height: 16),
                          const PayrollScopeNotice(),
                          const SizedBox(height: 26),
                          Text(
                            'Generated payroll',
                            style: Theme.of(context).textTheme.titleLarge
                                ?.copyWith(
                                  fontWeight: FontWeight.w800,
                                  letterSpacing: -.5,
                                ),
                          ),
                          const SizedBox(height: 5),
                          Text(
                            'Monthly snapshots persisted by the payroll service.',
                            style: Theme.of(context).textTheme.bodySmall
                                ?.copyWith(color: AppTheme.muted),
                          ),
                          const SizedBox(height: 13),
                          PayrollRecordGrid(records: data.records),
                          const SizedBox(height: 28),
                          Text(
                            'Generation queue',
                            style: Theme.of(context).textTheme.titleLarge
                                ?.copyWith(
                                  fontWeight: FontWeight.w800,
                                  letterSpacing: -.5,
                                ),
                          ),
                          const SizedBox(height: 5),
                          Text(
                            'Generate or refresh one workforce payroll snapshot at a time.',
                            style: Theme.of(context).textTheme.bodySmall
                                ?.copyWith(color: AppTheme.muted),
                          ),
                          const SizedBox(height: 13),
                          _GenerationQueue(data: data),
                        ],
                      ),
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
}

class _PayrollHeader extends StatelessWidget {
  const _PayrollHeader({required this.onRefresh});
  final VoidCallback onRefresh;

  @override
  Widget build(BuildContext context) => Row(
    children: [
      Expanded(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Labour Payroll',
              style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                fontWeight: FontWeight.w800,
                letterSpacing: -.9,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              'Monthly earnings, payments and outstanding balances.',
              style: Theme.of(
                context,
              ).textTheme.bodySmall?.copyWith(color: AppTheme.muted),
            ),
          ],
        ),
      ),
      IconButton.filledTonal(
        tooltip: 'Refresh payroll',
        onPressed: onRefresh,
        icon: const Icon(Icons.refresh_rounded),
      ),
    ],
  ).animate().fadeIn(duration: 240.ms);
}

class _MonthCommandBar extends ConsumerWidget {
  const _MonthCommandBar({required this.month});
  final String month;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final current = _monthDate(month);
    final now = DateTime.now();
    final canMoveNext = current.year < now.year || current.month < now.month;
    return SurfaceCard(
      child: Row(
        children: [
          IconButton.filledTonal(
            tooltip: 'Previous month',
            onPressed: () =>
                _loadMonth(ref, DateTime(current.year, current.month - 1)),
            icon: const Icon(Icons.chevron_left_rounded),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                Text(
                  payrollMonthLabel(month),
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.w800,
                  ),
                ),
                const SizedBox(height: 3),
                Text(
                  'Server payroll period',
                  style: Theme.of(
                    context,
                  ).textTheme.labelSmall?.copyWith(color: AppTheme.muted),
                ),
              ],
            ),
          ),
          const SizedBox(width: 10),
          IconButton.filledTonal(
            tooltip: 'Next month',
            onPressed: canMoveNext
                ? () =>
                      _loadMonth(ref, DateTime(current.year, current.month + 1))
                : null,
            icon: const Icon(Icons.chevron_right_rounded),
          ),
        ],
      ),
    );
  }

  void _loadMonth(WidgetRef ref, DateTime value) {
    final month =
        '${value.year.toString().padLeft(4, '0')}-${value.month.toString().padLeft(2, '0')}';
    ref.read(payrollControllerProvider.notifier).load(month);
  }

  DateTime _monthDate(String value) =>
      DateTime.tryParse('$value-01') ?? DateTime.now();
}

class _GenerationQueue extends ConsumerWidget {
  const _GenerationQueue({required this.data});
  final PayrollData data;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final action = ref.watch(payrollActionControllerProvider);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        if (action.hasError) ...[
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(13),
            decoration: BoxDecoration(
              color: AppTheme.danger.withValues(alpha: .08),
              borderRadius: BorderRadius.circular(16),
            ),
            child: Text(
              action.error is ApiException
                  ? (action.error! as ApiException).message
                  : '${action.error}',
              style: Theme.of(context).textTheme.labelSmall?.copyWith(
                color: AppTheme.danger,
                fontWeight: FontWeight.w700,
              ),
            ),
          ),
          const SizedBox(height: 12),
        ],
        PayrollGenerationQueue(
          members: data.members,
          generatedIds: data.generatedLabourIds,
          busy: action.isLoading,
          onGenerate: (member) => _generate(context, ref, member),
        ),
      ],
    );
  }

  Future<void> _generate(
    BuildContext context,
    WidgetRef ref,
    WorkforceMember member,
  ) async {
    final payroll = await ref
        .read(payrollActionControllerProvider.notifier)
        .generate(member.id, data.month);
    if (payroll != null && context.mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Payroll generated for ${member.displayName}.')),
      );
    }
  }
}

class _PayrollError extends StatelessWidget {
  const _PayrollError({required this.error, required this.onRetry});
  final Object error;
  final VoidCallback onRetry;

  @override
  Widget build(BuildContext context) => ListView(
    padding: const EdgeInsets.all(20),
    children: [
      EmptyPanel(
        title: 'Payroll workspace unavailable',
        message: '$error',
        icon: Icons.cloud_off_rounded,
        actionLabel: 'Try again',
        onAction: onRetry,
      ),
    ],
  );
}
