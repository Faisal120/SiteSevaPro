import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/theme/app_theme.dart';
import '../../../../core/utils/app_formatters.dart';
import '../../../../core/widgets/app_ui.dart';
import '../../models/boq_models.dart';

class BoqPortfolioHero extends StatelessWidget {
  const BoqPortfolioHero({
    super.key,
    required this.data,
    required this.onGenerate,
  });

  final BoqStudioData data;
  final VoidCallback onGenerate;

  @override
  Widget build(BuildContext context) => Container(
    constraints: const BoxConstraints(minHeight: 236),
    clipBehavior: Clip.antiAlias,
    decoration: BoxDecoration(
      borderRadius: BorderRadius.circular(32),
      gradient: const LinearGradient(
        colors: [Color(0xFF081321), Color(0xFF152B49), Color(0xFF673218)],
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
        const Positioned.fill(child: CustomPaint(painter: _LedgerPainter())),
        Positioned(
          right: -60,
          top: -78,
          child: Container(
            width: 270,
            height: 270,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: AppTheme.orange.withValues(alpha: .12),
              border: Border.all(
                color: Colors.white.withValues(alpha: .05),
                width: 20,
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
                        Icons.functions_rounded,
                        color: AppTheme.blueBright,
                        size: 18,
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          'PRECONSTRUCTION COST CONTROL',
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
                    'Turn measured scope into a controlled cost baseline.',
                    style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                      color: Colors.white,
                      fontWeight: FontWeight.w800,
                      letterSpacing: -.9,
                      height: 1.1,
                    ),
                  ),
                  const SizedBox(height: 9),
                  Text(
                    'Generate an itemized bill of quantities from a live estimate or verified built-up area, then issue one consistent server-calculated worksheet.',
                    style: Theme.of(context).textTheme.bodySmall?.copyWith(
                      color: const Color(0xFFBFCBDC),
                      height: 1.5,
                    ),
                  ),
                  const SizedBox(height: 20),
                  FilledButton.icon(
                    onPressed: onGenerate,
                    icon: const Icon(Icons.add_chart_rounded),
                    label: const Text('Generate BOQ'),
                    style: FilledButton.styleFrom(
                      minimumSize: const Size(0, 48),
                    ),
                  ),
                ],
              );
              final metrics = _BoqHeroMetrics(data: data);
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

class _BoqHeroMetrics extends StatelessWidget {
  const _BoqHeroMetrics({required this.data});
  final BoqStudioData data;

  @override
  Widget build(BuildContext context) => Container(
    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 18),
    decoration: BoxDecoration(
      color: Colors.white.withValues(alpha: .075),
      borderRadius: BorderRadius.circular(24),
      border: Border.all(color: Colors.white.withValues(alpha: .12)),
    ),
    child: Row(
      children: [
        _HeroMetric(value: '${data.boqs.length}', label: 'BOQs'),
        const _MetricDivider(),
        _HeroMetric(
          value: compactInr(data.documentedValue).replaceFirst('INR ', ''),
          label: 'Value',
        ),
        const _MetricDivider(),
        _HeroMetric(value: '${data.totalItems}', label: 'Items'),
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
          style: Theme.of(context).textTheme.labelSmall?.copyWith(
            color: const Color(0xFFBFCBDC),
            fontSize: 9,
            fontWeight: FontWeight.w700,
            letterSpacing: .6,
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

class BoqCapabilityGrid extends StatelessWidget {
  const BoqCapabilityGrid({super.key, required this.data});
  final BoqStudioData data;

  @override
  Widget build(BuildContext context) {
    final capabilities = [
      (
        Icons.calculate_rounded,
        'Estimate-linked',
        '${data.estimates.length} live estimates available as measured sources',
        AppTheme.orange,
      ),
      (
        Icons.apartment_rounded,
        'Project governed',
        '${data.linkedSiteCount} sites currently carry an issued BOQ',
        AppTheme.blue,
      ),
      (
        Icons.storefront_rounded,
        'Vendor reference',
        '${data.vendors.length} approved company vendors available for rate validation',
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

class BoqDocumentGrid extends StatelessWidget {
  const BoqDocumentGrid({super.key, required this.data});
  final BoqStudioData data;

  @override
  Widget build(BuildContext context) {
    if (data.visibleBoqs.isEmpty) {
      return const EmptyPanel(
        title: 'No matching BOQs',
        message: 'Clear the search or choose a different project site.',
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
          children: data.visibleBoqs.indexed.map((entry) {
            final boq = entry.$2;
            return SizedBox(
              width: width,
              height: 286,
              child:
                  BoqDocumentCard(
                        document: boq,
                        siteName:
                            data.siteFor(boq.siteId)?.name ?? 'Unlinked site',
                        sourceName:
                            data.estimateFor(boq.estimateId)?.name ??
                            'Measured area',
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

class BoqDocumentCard extends StatelessWidget {
  const BoqDocumentCard({
    super.key,
    required this.document,
    required this.siteName,
    required this.sourceName,
  });

  final BoqDocument document;
  final String siteName;
  final String sourceName;

  @override
  Widget build(BuildContext context) => SurfaceCard(
    padding: EdgeInsets.zero,
    onTap: () => context.go('/boq/${document.id}'),
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          height: 90,
          padding: const EdgeInsets.all(16),
          decoration: const BoxDecoration(
            borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
            gradient: LinearGradient(
              colors: [Color(0xFF101D31), Color(0xFF243D5C)],
            ),
          ),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Hero(
                tag: 'boq-mark-${document.id}',
                child: Container(
                  width: 42,
                  height: 42,
                  decoration: BoxDecoration(
                    color: AppTheme.orange,
                    borderRadius: BorderRadius.circular(14),
                  ),
                  child: const Icon(
                    Icons.format_list_numbered_rounded,
                    color: Colors.white,
                    size: 20,
                  ),
                ),
              ),
              const Spacer(),
              StatusBadge(label: 'ISSUED', tone: AppTheme.success),
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
                  document.name,
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
                        style: Theme.of(
                          context,
                        ).textTheme.labelSmall?.copyWith(color: AppTheme.muted),
                      ),
                    ),
                  ],
                ),
                const Spacer(),
                Text(
                  compactInr(document.total),
                  style: Theme.of(context).textTheme.titleLarge?.copyWith(
                    color: AppTheme.orange,
                    fontWeight: FontWeight.w800,
                    letterSpacing: -.5,
                  ),
                ),
                const SizedBox(height: 12),
                Row(
                  children: [
                    _CardMetric(
                      label: 'SECTIONS',
                      value: '${document.sections.length}',
                    ),
                    _CardMetric(label: 'ITEMS', value: '${document.itemCount}'),
                    _CardMetric(
                      label: 'AREA',
                      value: '${document.builtupSqft.round()} sq ft',
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                Row(
                  children: [
                    Expanded(
                      child: Text(
                        sourceName,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: Theme.of(
                          context,
                        ).textTheme.labelSmall?.copyWith(color: AppTheme.muted),
                      ),
                    ),
                    Text(
                      appDate(document.createdAt, fallback: 'Undated'),
                      style: Theme.of(
                        context,
                      ).textTheme.labelSmall?.copyWith(color: AppTheme.muted),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ],
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
          ).textTheme.labelLarge?.copyWith(fontWeight: FontWeight.w800),
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

class BoqOfflineBanner extends StatelessWidget {
  const BoqOfflineBanner({super.key, required this.syncedAt});
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
            'Offline BOQ cache - last synced ${appDate(syncedAt)}',
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

class BoqStudioSkeleton extends StatelessWidget {
  const BoqStudioSkeleton({super.key});

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
      AppSkeleton(height: 286),
    ],
  );
}

class _LedgerPainter extends CustomPainter {
  const _LedgerPainter();

  @override
  void paint(Canvas canvas, Size size) {
    final grid = Paint()
      ..color = Colors.white.withValues(alpha: .035)
      ..strokeWidth = 1;
    const gap = 32.0;
    for (double x = 0; x <= size.width; x += gap) {
      canvas.drawLine(Offset(x, 0), Offset(x, size.height), grid);
    }
    for (double y = 0; y <= size.height; y += gap) {
      canvas.drawLine(Offset(0, y), Offset(size.width, y), grid);
    }
    final line = Paint()
      ..color = Colors.white.withValues(alpha: .07)
      ..strokeWidth = 1.2;
    final maxWidth = math.min(220, size.width * .24);
    for (var index = 0; index < 4; index++) {
      final y = size.height - 34 - index * 14;
      canvas.drawLine(
        Offset(size.width - maxWidth - 28, y),
        Offset(size.width - 28, y),
        line,
      );
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}
