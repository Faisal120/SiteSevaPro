import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/theme/app_theme.dart';
import '../../../../core/widgets/app_ui.dart';
import '../../models/design_models.dart';

Color designStatusColor(DesignStatus status) => switch (status) {
  DesignStatus.completed => AppTheme.success,
  DesignStatus.processing => AppTheme.blue,
  DesignStatus.queued => AppTheme.warning,
  DesignStatus.failed => AppTheme.danger,
};

String designDate(DateTime? date) {
  if (date == null) return 'Date unavailable';
  const months = [
    'Jan',
    'Feb',
    'Mar',
    'Apr',
    'May',
    'Jun',
    'Jul',
    'Aug',
    'Sep',
    'Oct',
    'Nov',
    'Dec',
  ];
  return '${date.day} ${months[date.month - 1]} ${date.year}';
}

class DesignStudioHero extends StatelessWidget {
  const DesignStudioHero({
    super.key,
    required this.data,
    required this.canManage,
    required this.onGenerate,
    required this.onWallet,
  });

  final DesignStudioData data;
  final bool canManage;
  final VoidCallback onGenerate;
  final VoidCallback onWallet;

  @override
  Widget build(BuildContext context) => Container(
    constraints: const BoxConstraints(minHeight: 244),
    clipBehavior: Clip.antiAlias,
    decoration: BoxDecoration(
      borderRadius: BorderRadius.circular(32),
      gradient: const LinearGradient(
        colors: [Color(0xFF07101E), Color(0xFF10284A), Color(0xFF82401D)],
        begin: Alignment.topLeft,
        end: Alignment.bottomRight,
      ),
      boxShadow: const [
        BoxShadow(
          color: Color(0x2608111E),
          blurRadius: 34,
          offset: Offset(0, 16),
        ),
      ],
    ),
    child: Stack(
      children: [
        const Positioned.fill(
          child: CustomPaint(painter: _StudioGridPainter()),
        ),
        Positioned(
          right: -48,
          top: -76,
          child: Container(
            width: 250,
            height: 250,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: AppTheme.orange.withValues(alpha: .13),
              boxShadow: [
                BoxShadow(
                  color: AppTheme.orange.withValues(alpha: .18),
                  blurRadius: 90,
                  spreadRadius: 24,
                ),
              ],
            ),
          ),
        ),
        Padding(
          padding: const EdgeInsets.all(24),
          child: LayoutBuilder(
            builder: (context, constraints) {
              final compact = constraints.maxWidth < 700;
              final content = Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Row(
                    children: [
                      const Icon(
                        Icons.auto_awesome_rounded,
                        color: AppTheme.blueBright,
                        size: 18,
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          'SITESEVA ARCHITECTURAL ENGINE',
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
                    canManage
                        ? 'Turn a site brief into a governed design set.'
                        : 'Review the latest design set for your sites.',
                    style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                      color: Colors.white,
                      fontWeight: FontWeight.w800,
                      letterSpacing: -.9,
                      height: 1.1,
                    ),
                  ),
                  const SizedBox(height: 9),
                  Text(
                    canManage
                        ? 'Generate per-floor plans, furnished 3D concepts and technical drawing layers from one controlled version.'
                        : 'Open assigned versions, inspect every floor and share approved drawing sheets from the field.',
                    style: Theme.of(context).textTheme.bodySmall?.copyWith(
                      color: const Color(0xFFBFCBDC),
                      height: 1.5,
                    ),
                  ),
                  if (canManage) ...[
                    const SizedBox(height: 20),
                    Wrap(
                      spacing: 10,
                      runSpacing: 10,
                      children: [
                        FilledButton.icon(
                          onPressed: onGenerate,
                          icon: const Icon(Icons.architecture_rounded),
                          label: const Text('Start floor plan'),
                          style: FilledButton.styleFrom(
                            minimumSize: const Size(0, 48),
                            backgroundColor: AppTheme.orange,
                          ),
                        ),
                        OutlinedButton.icon(
                          onPressed: onWallet,
                          icon: const Icon(Icons.toll_rounded, size: 18),
                          label: Text('${data.wallet?.credits ?? 0} credits'),
                          style: OutlinedButton.styleFrom(
                            minimumSize: const Size(0, 48),
                            foregroundColor: Colors.white,
                            side: BorderSide(
                              color: Colors.white.withValues(alpha: .28),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ],
                ],
              );
              final metrics = _StudioHeroMetrics(data: data);
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
  ).animate().fadeIn(duration: 320.ms).slideY(begin: .05, end: 0);
}

class _StudioHeroMetrics extends StatelessWidget {
  const _StudioHeroMetrics({required this.data});

  final DesignStudioData data;

  @override
  Widget build(BuildContext context) => Container(
    padding: const EdgeInsets.all(16),
    decoration: BoxDecoration(
      color: Colors.white.withValues(alpha: .075),
      borderRadius: BorderRadius.circular(24),
      border: Border.all(color: Colors.white.withValues(alpha: .12)),
    ),
    child: Row(
      children: [
        _HeroMetric(value: '${data.designs.length}', label: 'Versions'),
        _HeroDivider(),
        _HeroMetric(
          value: '${data.count(DesignStatus.completed)}',
          label: 'Ready',
        ),
        _HeroDivider(),
        _HeroMetric(
          value:
              '${data.count(DesignStatus.processing) + data.count(DesignStatus.queued)}',
          label: 'Queue',
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

class _HeroDivider extends StatelessWidget {
  @override
  Widget build(BuildContext context) => Container(
    width: 1,
    height: 36,
    color: Colors.white.withValues(alpha: .14),
  );
}

class DesignCapabilityGrid extends StatelessWidget {
  const DesignCapabilityGrid({super.key});

  @override
  Widget build(BuildContext context) {
    const capabilities = [
      (
        Icons.grid_4x4_rounded,
        '2D floor plans',
        'Multi-floor briefs with room constraints',
        '10 credits',
      ),
      (
        Icons.view_in_ar_rounded,
        'Furnished 3D',
        'Open-top concept from an approved floor',
        '25 credits',
      ),
      (
        Icons.electrical_services_rounded,
        'Technical layers',
        'Electrical, plumbing and structural sets',
        '5 credits',
      ),
      (
        Icons.picture_as_pdf_rounded,
        'CAD PDF sheets',
        'Authenticated A3 drawing exports',
        'Included',
      ),
    ];
    return LayoutBuilder(
      builder: (context, constraints) {
        final columns = constraints.maxWidth >= 980
            ? 4
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
              height: 154,
              child:
                  SurfaceCard(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              children: [
                                Container(
                                  width: 38,
                                  height: 38,
                                  decoration: BoxDecoration(
                                    color: AppTheme.orange.withValues(
                                      alpha: .11,
                                    ),
                                    borderRadius: BorderRadius.circular(13),
                                  ),
                                  child: Icon(
                                    item.$1,
                                    color: AppTheme.orange,
                                    size: 19,
                                  ),
                                ),
                                const Spacer(),
                                StatusBadge(
                                  label: item.$4,
                                  tone: AppTheme.blue,
                                ),
                              ],
                            ),
                            const Spacer(),
                            Text(
                              item.$2,
                              style: Theme.of(context).textTheme.labelLarge
                                  ?.copyWith(fontWeight: FontWeight.w800),
                            ),
                            const SizedBox(height: 5),
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
                      .animate(delay: (entry.$1 * 50).ms)
                      .fadeIn(duration: 240.ms)
                      .slideY(begin: .06, end: 0),
            );
          }).toList(),
        );
      },
    );
  }
}

class DesignVersionGrid extends StatelessWidget {
  const DesignVersionGrid({
    super.key,
    required this.designs,
    required this.data,
  });

  final List<DesignRecord> designs;
  final DesignStudioData data;

  @override
  Widget build(BuildContext context) {
    if (designs.isEmpty) {
      return const EmptyPanel(
        title: 'No matching design versions',
        message: 'Clear the search or choose another generation status.',
        icon: Icons.layers_clear_rounded,
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
          children: designs.indexed.map((entry) {
            final design = entry.$2;
            return SizedBox(
              width: width,
              height: 332,
              child:
                  DesignVersionCard(
                        design: design,
                        siteName:
                            data.siteFor(design.siteId)?.name ??
                            'Unlinked site',
                      )
                      .animate(delay: (entry.$1 * 45).ms)
                      .fadeIn(duration: 240.ms)
                      .slideY(begin: .06, end: 0),
            );
          }).toList(),
        );
      },
    );
  }
}

class DesignVersionCard extends StatelessWidget {
  const DesignVersionCard({
    super.key,
    required this.design,
    required this.siteName,
  });

  final DesignRecord design;
  final String siteName;

  @override
  Widget build(BuildContext context) {
    final tone = designStatusColor(design.status);
    return SurfaceCard(
      onTap: () => context.go('/design-studio/design/${design.id}'),
      padding: EdgeInsets.zero,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Hero(
            tag: 'design-preview-${design.id}',
            child: Container(
              height: 176,
              padding: const EdgeInsets.all(14),
              decoration: const BoxDecoration(
                color: Color(0xFFF7F8F4),
                borderRadius: BorderRadius.vertical(top: Radius.circular(23)),
              ),
              child: Stack(
                children: [
                  Positioned.fill(
                    child: design.outputs.baseSvg.isNotEmpty
                        ? SvgPicture.string(
                            design.outputs.baseSvg,
                            fit: BoxFit.contain,
                            placeholderBuilder: (_) => const AppSkeleton(),
                          )
                        : CustomPaint(painter: _EmptyPlanPainter(tone: tone)),
                  ),
                  Align(
                    alignment: Alignment.topLeft,
                    child: StatusBadge(label: design.status.label, tone: tone),
                  ),
                ],
              ),
            ),
          ),
          Expanded(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    design.projectName,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: Theme.of(context).textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.w800,
                      letterSpacing: -.4,
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
                      const SizedBox(width: 5),
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
                  Divider(color: AppTheme.line, height: 18),
                  Row(
                    children: [
                      _VersionMeta(
                        label: 'FLOORS',
                        value: design.floorCount == 0
                            ? '-'
                            : '${design.floorCount}',
                      ),
                      _VersionMeta(
                        label: 'CREDITS',
                        value: '${design.creditsUsed}',
                      ),
                      Expanded(
                        child: Text(
                          designDate(design.createdAt),
                          textAlign: TextAlign.end,
                          style: Theme.of(context).textTheme.labelSmall
                              ?.copyWith(color: AppTheme.muted, fontSize: 9),
                        ),
                      ),
                      const SizedBox(width: 5),
                      const Icon(
                        Icons.arrow_forward_rounded,
                        size: 16,
                        color: AppTheme.orange,
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
}

class _VersionMeta extends StatelessWidget {
  const _VersionMeta({required this.label, required this.value});
  final String label;
  final String value;

  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.only(right: 18),
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: Theme.of(context).textTheme.labelSmall?.copyWith(
            color: AppTheme.muted,
            fontSize: 8,
            letterSpacing: .5,
          ),
        ),
        Text(
          value,
          style: Theme.of(
            context,
          ).textTheme.labelMedium?.copyWith(fontWeight: FontWeight.w800),
        ),
      ],
    ),
  );
}

class DesignStudioSkeleton extends StatelessWidget {
  const DesignStudioSkeleton({super.key});

  @override
  Widget build(BuildContext context) => ListView(
    padding: const EdgeInsets.fromLTRB(18, 18, 18, 120),
    children: const [
      AppSkeleton(height: 48),
      SizedBox(height: 18),
      AppSkeleton(height: 244, radius: 32),
      SizedBox(height: 18),
      AppSkeleton(height: 154),
      SizedBox(height: 18),
      AppSkeleton(height: 332),
    ],
  );
}

class DesignOfflineBanner extends StatelessWidget {
  const DesignOfflineBanner({super.key, required this.syncedAt});
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
            'Offline design cache · last synced ${designDate(syncedAt)}',
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

class _StudioGridPainter extends CustomPainter {
  const _StudioGridPainter();

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

class _EmptyPlanPainter extends CustomPainter {
  const _EmptyPlanPainter({required this.tone});
  final Color tone;

  @override
  void paint(Canvas canvas, Size size) {
    final grid = Paint()
      ..color = const Color(0xFFE1E5E8)
      ..strokeWidth = .7;
    for (double x = 0; x < size.width; x += 22) {
      canvas.drawLine(Offset(x, 0), Offset(x, size.height), grid);
    }
    for (double y = 0; y < size.height; y += 22) {
      canvas.drawLine(Offset(0, y), Offset(size.width, y), grid);
    }
    final plan = Paint()
      ..color = tone.withValues(alpha: .55)
      ..strokeWidth = 2
      ..style = PaintingStyle.stroke;
    final rect = Rect.fromCenter(
      center: size.center(Offset.zero),
      width: math.min(size.width * .56, 180),
      height: math.min(size.height * .55, 100),
    );
    canvas.drawRect(rect, plan);
    canvas.drawLine(rect.topCenter, rect.bottomCenter, plan);
    canvas.drawLine(rect.centerLeft, rect.center, plan);
  }

  @override
  bool shouldRepaint(covariant _EmptyPlanPainter oldDelegate) =>
      oldDelegate.tone != tone;
}
