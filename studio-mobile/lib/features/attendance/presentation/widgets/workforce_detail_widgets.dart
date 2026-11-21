import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';

import '../../../../core/theme/app_theme.dart';
import '../../../../core/utils/app_formatters.dart';
import '../../../../core/widgets/app_ui.dart';
import '../../models/workforce_models.dart';

Color ledgerTypeColor(LabourLedgerType type) => switch (type) {
  LabourLedgerType.earning => AppTheme.success,
  LabourLedgerType.bonus => const Color(0xFF0F7C8A),
  LabourLedgerType.advance => AppTheme.warning,
  LabourLedgerType.payment => AppTheme.blue,
  LabourLedgerType.deduction => AppTheme.danger,
  LabourLedgerType.unknown => AppTheme.muted,
};

class WorkforceDetailHero extends StatelessWidget {
  const WorkforceDetailHero({
    super.key,
    required this.detail,
    required this.siteName,
    required this.canSettle,
    required this.onSettle,
  });
  final WorkforceDetail detail;
  final String siteName;
  final bool canSettle;
  final VoidCallback onSettle;

  @override
  Widget build(BuildContext context) {
    final member = detail.member;
    return Container(
      constraints: const BoxConstraints(minHeight: 220),
      clipBehavior: Clip.antiAlias,
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(32),
        gradient: const LinearGradient(
          colors: [Color(0xFF071522), Color(0xFF173A5E), Color(0xFF0B6A71)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        boxShadow: const [
          BoxShadow(
            color: Color(0x240A0E17),
            blurRadius: 30,
            offset: Offset(0, 15),
          ),
        ],
      ),
      child: LayoutBuilder(
        builder: (context, constraints) {
          final compact = constraints.maxWidth < 720;
          final identity = Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Row(
                children: [
                  Hero(
                    tag: 'workforce-avatar-${member.id}',
                    child: Container(
                      width: 54,
                      height: 54,
                      decoration: BoxDecoration(
                        color: Colors.white.withValues(alpha: .12),
                        borderRadius: BorderRadius.circular(18),
                        border: Border.all(
                          color: Colors.white.withValues(alpha: .14),
                        ),
                      ),
                      alignment: Alignment.center,
                      child: Text(
                        member.initials,
                        style: Theme.of(context).textTheme.titleMedium
                            ?.copyWith(
                              color: Colors.white,
                              fontWeight: FontWeight.w800,
                            ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  StatusBadge(
                    label: member.active ? 'Active crew' : 'Inactive',
                    tone: member.active ? AppTheme.success : AppTheme.muted,
                  ),
                ],
              ),
              const SizedBox(height: 17),
              Text(
                member.displayName,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
                style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                  color: Colors.white,
                  fontWeight: FontWeight.w800,
                  letterSpacing: -.9,
                  height: 1.1,
                ),
              ),
              const SizedBox(height: 7),
              Text(
                '${member.displayTrade}  |  $siteName',
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
                style: Theme.of(
                  context,
                ).textTheme.bodySmall?.copyWith(color: const Color(0xFFBFCBDC)),
              ),
            ],
          );
          final wallet = _HeroWallet(
            detail: detail,
            canSettle: canSettle,
            onSettle: onSettle,
          );
          if (compact) {
            return Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [identity, const SizedBox(height: 22), wallet],
            );
          }
          return Row(
            children: [
              Expanded(flex: 3, child: identity),
              const SizedBox(width: 28),
              Expanded(flex: 2, child: wallet),
            ],
          );
        },
      ),
    );
  }
}

class _HeroWallet extends StatelessWidget {
  const _HeroWallet({
    required this.detail,
    required this.canSettle,
    required this.onSettle,
  });
  final WorkforceDetail detail;
  final bool canSettle;
  final VoidCallback onSettle;

  @override
  Widget build(BuildContext context) => Container(
    padding: const EdgeInsets.all(17),
    decoration: BoxDecoration(
      color: Colors.white.withValues(alpha: .075),
      borderRadius: BorderRadius.circular(24),
      border: Border.all(color: Colors.white.withValues(alpha: .12)),
    ),
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'WALLET BALANCE',
          style: Theme.of(context).textTheme.labelSmall?.copyWith(
            color: const Color(0xFFBFCBDC),
            fontSize: 8,
            fontWeight: FontWeight.w800,
            letterSpacing: .6,
          ),
        ),
        const SizedBox(height: 6),
        Text(
          compactInr(detail.wallet.balance),
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
          style: Theme.of(context).textTheme.headlineSmall?.copyWith(
            color: Colors.white,
            fontWeight: FontWeight.w800,
            letterSpacing: -.7,
          ),
        ),
        if (canSettle) ...[
          const SizedBox(height: 13),
          FilledButton.icon(
            onPressed: onSettle,
            icon: const Icon(Icons.payments_outlined, size: 18),
            label: const Text('Settle wallet'),
            style: FilledButton.styleFrom(minimumSize: const Size(0, 44)),
          ),
        ],
      ],
    ),
  );
}

class WalletComposition extends StatelessWidget {
  const WalletComposition({super.key, required this.wallet});
  final LabourWallet wallet;

  @override
  Widget build(BuildContext context) {
    final metrics = [
      ('Earned', wallet.earned, AppTheme.success, Icons.trending_up_rounded),
      ('Paid', wallet.paid, AppTheme.blue, Icons.payments_outlined),
      ('Advance', wallet.advance, AppTheme.warning, Icons.fast_forward_rounded),
      ('Bonus', wallet.bonus, const Color(0xFF0F7C8A), Icons.stars_outlined),
      (
        'Deduction',
        wallet.deduction,
        AppTheme.danger,
        Icons.remove_circle_outline,
      ),
      (
        'Balance',
        wallet.balance,
        AppTheme.orange,
        Icons.account_balance_wallet_outlined,
      ),
    ];
    return LayoutBuilder(
      builder: (context, constraints) {
        final columns = constraints.maxWidth >= 700 ? 3 : 2;
        const gap = 10.0;
        final width = (constraints.maxWidth - gap * (columns - 1)) / columns;
        return Wrap(
          spacing: gap,
          runSpacing: gap,
          children: metrics.indexed.map((indexed) {
            final metric = indexed.$2;
            return SizedBox(
              width: width,
              height: 112,
              child:
                  SurfaceCard(
                        padding: const EdgeInsets.all(14),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Icon(metric.$4, color: metric.$3, size: 19),
                            const Spacer(),
                            Text(
                              compactInr(metric.$2),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: Theme.of(context).textTheme.titleMedium
                                  ?.copyWith(
                                    color: metric.$3,
                                    fontWeight: FontWeight.w800,
                                  ),
                            ),
                            Text(
                              metric.$1.toUpperCase(),
                              style: Theme.of(context).textTheme.labelSmall
                                  ?.copyWith(
                                    color: AppTheme.muted,
                                    fontSize: 8,
                                    fontWeight: FontWeight.w700,
                                    letterSpacing: .4,
                                  ),
                            ),
                          ],
                        ),
                      )
                      .animate(delay: (indexed.$1 * 35).ms)
                      .fadeIn(duration: 220.ms)
                      .slideY(begin: .05, end: 0),
            );
          }).toList(),
        );
      },
    );
  }
}

class WorkforceProfilePanel extends StatelessWidget {
  const WorkforceProfilePanel({super.key, required this.member});
  final WorkforceMember member;

  @override
  Widget build(BuildContext context) => SurfaceCard(
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const _PanelTitle(
          icon: Icons.badge_outlined,
          title: 'Workforce profile',
          message: 'Identity and project context from the labour service',
        ),
        const SizedBox(height: 17),
        _InfoRow(label: 'Trade', value: member.displayTrade),
        _InfoRow(label: 'Daily wage', value: compactInr(member.dailyWage)),
        _InfoRow(label: 'Mobile', value: member.mobile ?? 'Not recorded'),
        _InfoRow(label: 'Address', value: member.address ?? 'Not recorded'),
        _InfoRow(
          label: 'Aadhaar',
          value: _maskedAadhaar(member.aadhaar),
          isLast: true,
        ),
      ],
    ),
  );
}

class LabourLedgerTimeline extends StatelessWidget {
  const LabourLedgerTimeline({super.key, required this.entries});
  final List<LabourLedgerEntry> entries;

  @override
  Widget build(BuildContext context) {
    if (entries.isEmpty) {
      return const EmptyPanel(
        title: 'No wallet activity',
        message:
            'Attendance earnings, advances and settlements will appear here.',
        icon: Icons.receipt_long_outlined,
      );
    }
    final visible = entries.take(50).toList(growable: false);
    return SurfaceCard(
      padding: EdgeInsets.zero,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(18, 18, 18, 13),
            child: _PanelTitle(
              icon: Icons.receipt_long_outlined,
              title: 'Wallet ledger',
              message: entries.length > visible.length
                  ? 'Latest 50 of ${entries.length} server entries'
                  : '${entries.length} server entries',
            ),
          ),
          const Divider(height: 1),
          ...visible.indexed.map(
            (indexed) => _LedgerRow(
              entry: indexed.$2,
              isLast: indexed.$1 == visible.length - 1,
              index: indexed.$1,
            ),
          ),
        ],
      ),
    );
  }
}

class _LedgerRow extends StatelessWidget {
  const _LedgerRow({
    required this.entry,
    required this.isLast,
    required this.index,
  });
  final LabourLedgerEntry entry;
  final bool isLast;
  final int index;

  @override
  Widget build(BuildContext context) {
    final tone = ledgerTypeColor(entry.type);
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 14),
      decoration: BoxDecoration(
        border: isLast
            ? null
            : const Border(bottom: BorderSide(color: AppTheme.line)),
      ),
      child: Row(
        children: [
          Container(
            width: 39,
            height: 39,
            decoration: BoxDecoration(
              color: tone.withValues(alpha: .09),
              borderRadius: BorderRadius.circular(13),
            ),
            child: Icon(
              entry.addsToBalance
                  ? Icons.south_west_rounded
                  : Icons.north_east_rounded,
              color: tone,
              size: 18,
            ),
          ),
          const SizedBox(width: 11),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  entry.note ?? entry.type.label,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: Theme.of(
                    context,
                  ).textTheme.labelLarge?.copyWith(fontWeight: FontWeight.w800),
                ),
                const SizedBox(height: 3),
                Text(
                  '${entry.date}${entry.paymentMode == null ? '' : '  |  ${entry.paymentMode}'}',
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: Theme.of(
                    context,
                  ).textTheme.labelSmall?.copyWith(color: AppTheme.muted),
                ),
              ],
            ),
          ),
          const SizedBox(width: 10),
          Text(
            '${entry.addsToBalance ? '+' : '-'}${compactInr(entry.amount).replaceFirst('INR ', '')}',
            style: Theme.of(context).textTheme.labelLarge?.copyWith(
              color: tone,
              fontWeight: FontWeight.w800,
            ),
          ),
        ],
      ),
    ).animate(delay: (index * 25).ms).fadeIn().slideX(begin: .02, end: 0);
  }
}

class WorkforceEvidenceNotice extends StatelessWidget {
  const WorkforceEvidenceNotice({super.key});

  @override
  Widget build(BuildContext context) => SurfaceCard(
    child: Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          width: 40,
          height: 40,
          decoration: BoxDecoration(
            color: AppTheme.warning.withValues(alpha: .1),
            borderRadius: BorderRadius.circular(13),
          ),
          child: const Icon(
            Icons.policy_outlined,
            color: AppTheme.warning,
            size: 19,
          ),
        ),
        const SizedBox(width: 11),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Verification scope',
                style: Theme.of(
                  context,
                ).textTheme.labelLarge?.copyWith(fontWeight: FontWeight.w800),
              ),
              const SizedBox(height: 4),
              Text(
                'Face identity, GPS history, performance scoring, payment receipts, settlement approval and reversal are not present in the current backend contracts.',
                style: Theme.of(context).textTheme.labelSmall?.copyWith(
                  color: AppTheme.muted,
                  height: 1.45,
                ),
              ),
            ],
          ),
        ),
      ],
    ),
  );
}

class WorkforceDetailOfflineBanner extends StatelessWidget {
  const WorkforceDetailOfflineBanner({super.key, required this.syncedAt});
  final DateTime syncedAt;

  @override
  Widget build(BuildContext context) => Container(
    padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
    decoration: BoxDecoration(
      color: AppTheme.warning.withValues(alpha: .1),
      borderRadius: BorderRadius.circular(16),
    ),
    child: Row(
      children: [
        const Icon(Icons.cloud_off_rounded, color: AppTheme.warning, size: 19),
        const SizedBox(width: 10),
        Expanded(
          child: Text(
            'Offline wallet cache - last synced ${appDate(syncedAt)}',
            style: Theme.of(context).textTheme.labelSmall?.copyWith(
              color: AppTheme.warning,
              fontWeight: FontWeight.w700,
            ),
          ),
        ),
      ],
    ),
  );
}

class _PanelTitle extends StatelessWidget {
  const _PanelTitle({
    required this.icon,
    required this.title,
    required this.message,
  });
  final IconData icon;
  final String title;
  final String message;

  @override
  Widget build(BuildContext context) => Row(
    crossAxisAlignment: CrossAxisAlignment.start,
    children: [
      Container(
        width: 40,
        height: 40,
        decoration: BoxDecoration(
          color: AppTheme.blue.withValues(alpha: .09),
          borderRadius: BorderRadius.circular(13),
        ),
        child: Icon(icon, color: AppTheme.blue, size: 19),
      ),
      const SizedBox(width: 11),
      Expanded(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              title,
              style: Theme.of(
                context,
              ).textTheme.labelLarge?.copyWith(fontWeight: FontWeight.w800),
            ),
            const SizedBox(height: 3),
            Text(
              message,
              style: Theme.of(
                context,
              ).textTheme.labelSmall?.copyWith(color: AppTheme.muted),
            ),
          ],
        ),
      ),
    ],
  );
}

class _InfoRow extends StatelessWidget {
  const _InfoRow({
    required this.label,
    required this.value,
    this.isLast = false,
  });
  final String label;
  final String value;
  final bool isLast;

  @override
  Widget build(BuildContext context) => Container(
    padding: const EdgeInsets.symmetric(vertical: 10),
    decoration: BoxDecoration(
      border: isLast
          ? null
          : const Border(bottom: BorderSide(color: AppTheme.line)),
    ),
    child: Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Expanded(
          child: Text(
            label,
            style: Theme.of(
              context,
            ).textTheme.labelSmall?.copyWith(color: AppTheme.muted),
          ),
        ),
        const SizedBox(width: 10),
        Flexible(
          child: Text(
            value,
            textAlign: TextAlign.right,
            style: Theme.of(
              context,
            ).textTheme.labelSmall?.copyWith(fontWeight: FontWeight.w800),
          ),
        ),
      ],
    ),
  );
}

String _maskedAadhaar(String? value) {
  final digits = value?.replaceAll(RegExp(r'\D'), '') ?? '';
  if (digits.length < 4) return 'Not recorded';
  return 'XXXX XXXX ${digits.substring(digits.length - 4)}';
}
