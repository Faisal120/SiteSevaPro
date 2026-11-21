import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/theme/app_theme.dart';
import '../../../../core/widgets/app_ui.dart';
import '../../../auth/providers/auth_provider.dart';
import '../../models/workforce_models.dart';
import '../../providers/workforce_provider.dart';
import '../widgets/wallet_settlement_sheet.dart';
import '../widgets/workforce_detail_widgets.dart';

class WorkforceDetailScreen extends ConsumerWidget {
  const WorkforceDetailScreen({super.key, required this.labourId});
  final String labourId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final detail = ref.watch(workforceDetailControllerProvider(labourId));
    final studio = ref.watch(workforceStudioControllerProvider).valueOrNull;
    final canManage =
        ref.watch(authControllerProvider).valueOrNull?.isContractor == true;
    return Material(
      color: Theme.of(context).scaffoldBackgroundColor,
      child: SafeArea(
        bottom: false,
        child: detail.when(
          loading: () => const _DetailSkeleton(),
          error: (error, stackTrace) => _DetailError(
            error: error,
            onBack: () => context.go('/'),
            onRetry: () => ref
                .read(workforceDetailControllerProvider(labourId).notifier)
                .load(),
          ),
          data: (data) {
            final siteName =
                studio?.siteFor(data.member.siteId)?.name ?? 'Assigned project';
            return LayoutBuilder(
              builder: (context, constraints) => ListView(
                key: PageStorageKey('workforce-detail-$labourId'),
                primary: false,
                physics: const BouncingScrollPhysics(),
                padding: EdgeInsets.fromLTRB(
                  constraints.maxWidth >= 900 ? 30 : 18,
                  14,
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
                          _DetailHeader(
                            data: data,
                            canManage: canManage,
                            onBack: () => context.go('/'),
                            onRefresh: () => ref
                                .read(
                                  workforceDetailControllerProvider(
                                    labourId,
                                  ).notifier,
                                )
                                .load(),
                            onDelete: () => _delete(context, ref, data.member),
                          ),
                          if (data.isOffline) ...[
                            const SizedBox(height: 13),
                            WorkforceDetailOfflineBanner(
                              syncedAt: data.fetchedAt,
                            ),
                          ],
                          const SizedBox(height: 16),
                          WorkforceDetailHero(
                                detail: data,
                                siteName: siteName,
                                canSettle: canManage,
                                onSettle: () => _settle(context, ref, data),
                              )
                              .animate()
                              .fadeIn(duration: 300.ms)
                              .slideY(begin: .04, end: 0),
                          const SizedBox(height: 18),
                          _DetailWorkspace(detail: data),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            );
          },
        ),
      ),
    );
  }

  Future<void> _settle(
    BuildContext context,
    WidgetRef ref,
    WorkforceDetail detail,
  ) async {
    final settled = await showWalletSettlementSheet(
      context,
      ref,
      detail: detail,
    );
    if (settled && context.mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Wallet settlement recorded.')),
      );
    }
  }

  Future<void> _delete(
    BuildContext context,
    WidgetRef ref,
    WorkforceMember member,
  ) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Remove workforce profile?'),
        content: Text(
          'Remove ${member.displayName}? Existing attendance and wallet history may remain on the server.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(context, true),
            style: FilledButton.styleFrom(backgroundColor: AppTheme.danger),
            child: const Text('Remove'),
          ),
        ],
      ),
    );
    if (confirmed != true) return;
    final deleted = await ref
        .read(workforceActionControllerProvider.notifier)
        .delete(member.id);
    if (deleted && context.mounted) context.go('/labour');
  }
}

class _DetailHeader extends StatelessWidget {
  const _DetailHeader({
    required this.data,
    required this.canManage,
    required this.onBack,
    required this.onRefresh,
    required this.onDelete,
  });
  final WorkforceDetail data;
  final bool canManage;
  final VoidCallback onBack;
  final VoidCallback onRefresh;
  final VoidCallback onDelete;

  @override
  Widget build(BuildContext context) => Row(
    children: [
      IconButton.filledTonal(
        tooltip: 'Back to home',
        onPressed: onBack,
        icon: const Icon(Icons.arrow_back_rounded),
      ),
      const SizedBox(width: 11),
      Expanded(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              data.member.displayName,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: Theme.of(context).textTheme.titleLarge?.copyWith(
                fontWeight: FontWeight.w800,
                letterSpacing: -.5,
              ),
            ),
            Text(
              'Workforce wallet and ledger',
              style: Theme.of(
                context,
              ).textTheme.labelSmall?.copyWith(color: AppTheme.muted),
            ),
          ],
        ),
      ),
      IconButton(
        tooltip: 'Refresh wallet',
        onPressed: onRefresh,
        icon: const Icon(Icons.refresh_rounded),
      ),
      if (canManage)
        PopupMenuButton<String>(
          tooltip: 'Profile actions',
          onSelected: (value) {
            if (value == 'delete') onDelete();
          },
          itemBuilder: (context) => const [
            PopupMenuItem(value: 'delete', child: Text('Remove profile')),
          ],
        ),
    ],
  );
}

class _DetailWorkspace extends StatelessWidget {
  const _DetailWorkspace({required this.detail});
  final WorkforceDetail detail;

  @override
  Widget build(BuildContext context) => LayoutBuilder(
    builder: (context, constraints) {
      final side = Column(
        children: [
          WorkforceProfilePanel(member: detail.member),
          const SizedBox(height: 12),
          const WorkforceEvidenceNotice(),
        ],
      );
      final main = Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Wallet composition',
            style: Theme.of(context).textTheme.titleLarge?.copyWith(
              fontWeight: FontWeight.w800,
              letterSpacing: -.5,
            ),
          ),
          const SizedBox(height: 12),
          WalletComposition(wallet: detail.wallet),
          const SizedBox(height: 18),
          LabourLedgerTimeline(entries: detail.ledger),
        ],
      );
      if (constraints.maxWidth >= 980) {
        return Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            SizedBox(width: 330, child: side),
            const SizedBox(width: 16),
            Expanded(child: main),
          ],
        );
      }
      return Column(children: [side, const SizedBox(height: 22), main]);
    },
  );
}

class _DetailSkeleton extends StatelessWidget {
  const _DetailSkeleton();

  @override
  Widget build(BuildContext context) => ListView(
    padding: const EdgeInsets.fromLTRB(18, 18, 18, 120),
    children: const [
      AppSkeleton(height: 50),
      SizedBox(height: 16),
      AppSkeleton(height: 220, radius: 32),
      SizedBox(height: 18),
      AppSkeleton(height: 480),
    ],
  );
}

class _DetailError extends StatelessWidget {
  const _DetailError({
    required this.error,
    required this.onBack,
    required this.onRetry,
  });
  final Object error;
  final VoidCallback onBack;
  final VoidCallback onRetry;

  @override
  Widget build(BuildContext context) => ListView(
    padding: const EdgeInsets.all(20),
    children: [
      Align(
        alignment: Alignment.centerLeft,
        child: IconButton.filledTonal(
          onPressed: onBack,
          icon: const Icon(Icons.arrow_back_rounded),
        ),
      ),
      const SizedBox(height: 16),
      EmptyPanel(
        title: 'Workforce wallet unavailable',
        message: '$error',
        icon: Icons.cloud_off_rounded,
        actionLabel: 'Try again',
        onAction: onRetry,
      ),
    ],
  );
}
