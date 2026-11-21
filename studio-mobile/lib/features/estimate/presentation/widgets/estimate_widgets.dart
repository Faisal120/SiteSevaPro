import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/theme/app_theme.dart';
import '../../../../core/utils/app_formatters.dart';
import '../../../../core/widgets/app_ui.dart';
import '../../models/estimate_models.dart';

Color estimateQualityColor(EstimateQuality quality) => switch (quality) {
  EstimateQuality.economy => AppTheme.warning,
  EstimateQuality.basic => const Color(0xFF0F7C8A),
  EstimateQuality.standard => AppTheme.blue,
  EstimateQuality.premium => AppTheme.orange,
  EstimateQuality.luxury => const Color(0xFF9A5D28),
};

class EstimatePortfolioHero extends StatelessWidget {
  const EstimatePortfolioHero({
    super.key,
    required this.data,
    required this.onCreate,
  });
  final EstimateStudioData data;
  final VoidCallback onCreate;

  @override
  Widget build(BuildContext context) => Container(
    constraints: const BoxConstraints(minHeight: 236),
    clipBehavior: Clip.antiAlias,
    decoration: BoxDecoration(
      borderRadius: BorderRadius.circular(32),
      gradient: const LinearGradient(
        colors: [Color(0xFF081321), Color(0xFF17314E), Color(0xFF733817)],
        begin: Alignment.topLeft,
        end: Alignment.bottomRight,
      ),
      boxShadow: const [
        BoxShadow(
          color: Color(0x250A0E17),
          blurRadius: 30,
          offset: Offset(0, 15),
        ),
      ],
    ),
    child: Stack(
      children: [
        const Positioned.fill(child: CustomPaint(painter: _EstimateGrid())),
        Positioned(
          right: -76,
          top: -94,
          child: Container(
            width: 300,
            height: 300,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: AppTheme.orange.withValues(alpha: .1),
              border: Border.all(
                color: Colors.white.withValues(alpha: .04),
                width: 22,
              ),
            ),
          ),
        ),
        Padding(
          padding: const EdgeInsets.all(24),
          child: LayoutBuilder(
            builder: (context, constraints) {
              final compact = constraints.maxWidth < 720;
              final content = Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Row(
                    children: [
                      const Icon(
                        Icons.calculate_rounded,
                        color: AppTheme.blueBright,
                        size: 18,
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          'PROJECT FEASIBILITY ENGINE',
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: Theme.of(context).textTheme.labelSmall
                              ?.copyWith(
                                color: const Color(0xFFD2DBE8),
                                fontWeight: FontWeight.w800,
                                letterSpacing: .9,
                              ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),
                  Text(
                    'Build budget confidence before mobilization.',
                    style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                      color: Colors.white,
                      fontWeight: FontWeight.w800,
                      letterSpacing: -.9,
                      height: 1.1,
                    ),
                  ),
                  const SizedBox(height: 9),
                  Text(
                    'Convert project assumptions and an approved budget into a server-calculated cost mix, rate benchmark and material quantity plan.',
                    style: Theme.of(context).textTheme.bodySmall?.copyWith(
                      color: const Color(0xFFBFCBDC),
                      height: 1.5,
                    ),
                  ),
                  const SizedBox(height: 20),
                  FilledButton.icon(
                    onPressed: onCreate,
                    icon: const Icon(Icons.add_chart_rounded),
                    label: const Text('Create estimate'),
                    style: FilledButton.styleFrom(
                      minimumSize: const Size(0, 48),
                    ),
                  ),
                ],
              );
              final metrics = _EstimateMetrics(data: data);
              if (compact) {
                return Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [content, const SizedBox(height: 22), metrics],
                );
              }
              return Row(
                children: [
                  Expanded(flex: 3, child: content),
                  const SizedBox(width: 30),
                  Expanded(flex: 2, child: metrics),
                ],
              );
            },
          ),
        ),
      ],
    ),
  ).animate().fadeIn(duration: 320.ms).slideY(begin: .04, end: 0);
}

class _EstimateMetrics extends StatelessWidget {
  const _EstimateMetrics({required this.data});
  final EstimateStudioData data;

  @override
  Widget build(BuildContext context) => Container(
    padding: const EdgeInsets.symmetric(horizontal: 15, vertical: 18),
    decoration: BoxDecoration(
      color: Colors.white.withValues(alpha: .075),
      borderRadius: BorderRadius.circular(24),
      border: Border.all(color: Colors.white.withValues(alpha: .12)),
    ),
    child: Row(
      children: [
        _HeroMetric(value: '${data.estimates.length}', label: 'Plans'),
        const _MetricDivider(),
        _HeroMetric(
          value: compactInr(data.portfolioValue).replaceFirst('INR ', ''),
          label: 'Value',
        ),
        const _MetricDivider(),
        _HeroMetric(
          value: compactInr(data.averageRate).replaceFirst('INR ', ''),
          label: 'Avg / sq ft',
        ),
      ],
    ),
  );
}

class _HeroMetric extends StatelessWidget {
  const _HeroMetric({required this.value, required this.label});
  final String value;
  final String label;

  @override
  Widget build(BuildContext context) => Expanded(
    child: Column(
      children: [
        Text(
          value,
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
          style: Theme.of(context).textTheme.titleLarge?.copyWith(
            color: Colors.white,
            fontWeight: FontWeight.w800,
          ),
        ),
        const SizedBox(height: 4),
        Text(
          label.toUpperCase(),
          textAlign: TextAlign.center,
          style: Theme.of(context).textTheme.labelSmall?.copyWith(
            color: const Color(0xFFBFCBDC),
            fontSize: 8,
            fontWeight: FontWeight.w700,
            letterSpacing: .5,
          ),
        ),
      ],
    ),
  );
}

class _MetricDivider extends StatelessWidget {
  const _MetricDivider();

  @override
  Widget build(BuildContext context) => Container(
    width: 1,
    height: 38,
    color: Colors.white.withValues(alpha: .14),
  );
}

class EstimateCapabilityGrid extends StatelessWidget {
  const EstimateCapabilityGrid({super.key, required this.data});
  final EstimateStudioData data;

  @override
  Widget build(BuildContext context) {
    final capabilities = [
      (
        Icons.account_balance_wallet_outlined,
        'Server cost mix',
        'Material, labour and overhead allocation from the approved budget',
        AppTheme.orange,
      ),
      (
        Icons.inventory_2_outlined,
        'Material plan',
        'Cement, steel, sand, aggregate and brick quantities',
        AppTheme.blue,
      ),
      (
        Icons.branding_watermark_outlined,
        'Branding context',
        data.branding.companyName.isEmpty
            ? 'Company document branding is not configured'
            : '${data.branding.companyName} branding is connected',
        AppTheme.success,
      ),
    ];
    return LayoutBuilder(
      builder: (context, constraints) {
        final columns = constraints.maxWidth >= 900
            ? 3
            : constraints.maxWidth >= 560
            ? 2
            : 1;
        const gap = 12.0;
        final width = (constraints.maxWidth - gap * (columns - 1)) / columns;
        return Wrap(
          spacing: gap,
          runSpacing: gap,
          children: capabilities.indexed.map((entry) {
            final item = entry.$2;
            return SizedBox(
              width: width,
              height: 138,
              child:
                  SurfaceCard(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Container(
                              width: 38,
                              height: 38,
                              decoration: BoxDecoration(
                                color: item.$4.withValues(alpha: .1),
                                borderRadius: BorderRadius.circular(13),
                              ),
                              child: Icon(item.$1, color: item.$4, size: 19),
                            ),
                            const Spacer(),
                            Text(
                              item.$2,
                              style: Theme.of(context).textTheme.labelLarge
                                  ?.copyWith(fontWeight: FontWeight.w800),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              item.$3,
                              maxLines: 2,
                              overflow: TextOverflow.ellipsis,
                              style: Theme.of(context).textTheme.labelSmall
                                  ?.copyWith(color: AppTheme.muted),
                            ),
                          ],
                        ),
                      )
                      .animate(delay: (entry.$1 * 55).ms)
                      .fadeIn(duration: 260.ms)
                      .slideY(begin: .05, end: 0),
            );
          }).toList(),
        );
      },
    );
  }
}

class EstimateDocumentGrid extends StatelessWidget {
  const EstimateDocumentGrid({super.key, required this.data});
  final EstimateStudioData data;

  @override
  Widget build(BuildContext context) {
    if (data.visibleEstimates.isEmpty) {
      return const EmptyPanel(
        title: 'No matching estimates',
        message: 'Clear the search or choose another project or quality band.',
        icon: Icons.filter_alt_off_rounded,
      );
    }
    return LayoutBuilder(
      builder: (context, constraints) {
        final columns = constraints.maxWidth >= 1020
            ? 3
            : constraints.maxWidth >= 650
            ? 2
            : 1;
        const gap = 12.0;
        final width = (constraints.maxWidth - gap * (columns - 1)) / columns;
        return Wrap(
          spacing: gap,
          runSpacing: gap,
          children: data.visibleEstimates.indexed.map((entry) {
            final estimate = entry.$2;
            return SizedBox(
              width: width,
              height: 312,
              child:
                  EstimateDocumentCard(
                        estimate: estimate,
                        siteName:
                            data.siteFor(estimate.siteId)?.name ??
                            'Unlinked site',
                      )
                      .animate(delay: (entry.$1 * 45).ms)
                      .fadeIn(duration: 250.ms)
                      .slideY(begin: .05, end: 0),
            );
          }).toList(),
        );
      },
    );
  }
}

class EstimateDocumentCard extends StatelessWidget {
  const EstimateDocumentCard({
    super.key,
    required this.estimate,
    required this.siteName,
  });
  final EstimateDocument estimate;
  final String siteName;

  @override
  Widget build(BuildContext context) {
    final tone = estimateQualityColor(estimate.quality);
    return SurfaceCard(
      padding: EdgeInsets.zero,
      onTap: () => context.go('/estimates/${estimate.id}'),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            height: 88,
            padding: const EdgeInsets.all(16),
            decoration: const BoxDecoration(
              borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
              gradient: LinearGradient(
                colors: [Color(0xFF101D31), Color(0xFF26425F)],
              ),
            ),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Hero(
                  tag: 'estimate-mark-${estimate.id}',
                  child: Container(
                    width: 42,
                    height: 42,
                    decoration: BoxDecoration(
                      color: AppTheme.orange,
                      borderRadius: BorderRadius.circular(14),
                    ),
                    child: const Icon(
                      Icons.calculate_rounded,
                      color: Colors.white,
                      size: 20,
                    ),
                  ),
                ),
                const Spacer(),
                StatusBadge(label: estimate.quality.label, tone: tone),
              ],
            ),
          ),
          Expanded(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    estimate.name,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: Theme.of(context).textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.w800,
                      letterSpacing: -.3,
                    ),
                  ),
                  const SizedBox(height: 6),
                  Row(
                    children: [
                      const Icon(
                        Icons.apartment_rounded,
                        size: 14,
                        color: AppTheme.muted,
                      ),
                      const SizedBox(width: 6),
                      Expanded(
                        child: Text(
                          siteName,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: Theme.of(context).textTheme.labelSmall
                              ?.copyWith(color: AppTheme.muted),
                        ),
                      ),
                    ],
                  ),
                  const Spacer(),
                  Text(
                    compactInr(estimate.total),
                    style: Theme.of(context).textTheme.titleLarge?.copyWith(
                      color: AppTheme.orange,
                      fontWeight: FontWeight.w800,
                      letterSpacing: -.5,
                    ),
                  ),
                  const SizedBox(height: 5),
                  Text(
                    '${compactInr(estimate.ratePerSqft)} per sq ft',
                    style: Theme.of(
                      context,
                    ).textTheme.labelSmall?.copyWith(color: AppTheme.muted),
                  ),
                  const SizedBox(height: 12),
                  _CostMixBar(estimate: estimate),
                  const SizedBox(height: 13),
                  Row(
                    children: [
                      _CardMetric(
                        label: 'BUILT-UP',
                        value: '${estimate.builtupSqft.round()} sq ft',
                      ),
                      _CardMetric(
                        label: 'FLOORS',
                        value: '${estimate.input.floors}',
                      ),
                      _CardMetric(
                        label: 'TYPE',
                        value: estimate.input.constructionType.label,
                      ),
                    ],
                  ),
                  const SizedBox(height: 11),
                  Text(
                    appDate(estimate.createdAt, fallback: 'Undated'),
                    style: Theme.of(
                      context,
                    ).textTheme.labelSmall?.copyWith(color: AppTheme.muted),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _CostMixBar extends StatelessWidget {
  const _CostMixBar({required this.estimate});
  final EstimateDocument estimate;

  @override
  Widget build(BuildContext context) => ClipRRect(
    borderRadius: BorderRadius.circular(6),
    child: SizedBox(
      height: 7,
      child: Row(
        children: [
          Expanded(
            flex: (estimate.materialShare() * 1000)
                .round()
                .clamp(1, 1000)
                .toInt(),
            child: Container(color: AppTheme.orange),
          ),
          Expanded(
            flex: (estimate.labourShare() * 1000)
                .round()
                .clamp(1, 1000)
                .toInt(),
            child: Container(color: AppTheme.blue),
          ),
          Expanded(
            flex: (estimate.overheadShare() * 1000)
                .round()
                .clamp(1, 1000)
                .toInt(),
            child: Container(color: AppTheme.success),
          ),
        ],
      ),
    ),
  );
}

class _CardMetric extends StatelessWidget {
  const _CardMetric({required this.label, required this.value});
  final String label;
  final String value;

  @override
  Widget build(BuildContext context) => Expanded(
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          value,
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
          style: Theme.of(
            context,
          ).textTheme.labelMedium?.copyWith(fontWeight: FontWeight.w800),
        ),
        const SizedBox(height: 2),
        Text(
          label,
          style: Theme.of(context).textTheme.labelSmall?.copyWith(
            color: AppTheme.muted,
            fontSize: 8,
            letterSpacing: .4,
          ),
        ),
      ],
    ),
  );
}

class EstimateOfflineBanner extends StatelessWidget {
  const EstimateOfflineBanner({super.key, required this.syncedAt});
  final DateTime syncedAt;

  @override
  Widget build(BuildContext context) => Container(
    padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
    decoration: BoxDecoration(
      color: AppTheme.warning.withValues(alpha: .1),
      borderRadius: BorderRadius.circular(16),
      border: Border.all(color: AppTheme.warning.withValues(alpha: .25)),
    ),
    child: Row(
      children: [
        const Icon(Icons.cloud_off_rounded, color: AppTheme.warning, size: 19),
        const SizedBox(width: 10),
        Expanded(
          child: Text(
            'Offline estimate cache - last synced ${appDate(syncedAt)}',
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

class EstimateStudioSkeleton extends StatelessWidget {
  const EstimateStudioSkeleton({super.key});

  @override
  Widget build(BuildContext context) => ListView(
    padding: const EdgeInsets.fromLTRB(18, 18, 18, 120),
    children: const [
      AppSkeleton(height: 48),
      SizedBox(height: 18),
      AppSkeleton(height: 236, radius: 32),
      SizedBox(height: 18),
      AppSkeleton(height: 138),
      SizedBox(height: 18),
      AppSkeleton(height: 300),
    ],
  );
}

class _EstimateGrid extends CustomPainter {
  const _EstimateGrid();

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = Colors.white.withValues(alpha: .035)
      ..strokeWidth = 1;
    const gap = 32.0;
    for (double x = 0; x <= size.width; x += gap) {
      canvas.drawLine(Offset(x, 0), Offset(x, size.height), paint);
    }
    for (double y = 0; y <= size.height; y += gap) {
      canvas.drawLine(Offset(0, y), Offset(size.width, y), paint);
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}
