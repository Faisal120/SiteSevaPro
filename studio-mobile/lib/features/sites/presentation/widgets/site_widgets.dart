import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/theme/app_theme.dart';
import '../../../../core/widgets/app_ui.dart';
import '../../models/site_models.dart';

Color siteStatusColor(SiteStatus status) => switch (status) {
  SiteStatus.active => AppTheme.success,
  SiteStatus.planning => AppTheme.blue,
  SiteStatus.onHold => AppTheme.warning,
  SiteStatus.completed => AppTheme.orange,
};

String compactCurrency(double value) {
  if (value >= 10000000) {
    return 'INR ${(value / 10000000).toStringAsFixed(value % 10000000 == 0 ? 0 : 1)} Cr';
  }
  if (value >= 100000) {
    return 'INR ${(value / 100000).toStringAsFixed(value % 100000 == 0 ? 0 : 1)} L';
  }
  if (value >= 1000) {
    return 'INR ${(value / 1000).toStringAsFixed(value % 1000 == 0 ? 0 : 1)} K';
  }
  return 'INR ${value.toStringAsFixed(0)}';
}

String siteDate(DateTime? value) {
  if (value == null || value.millisecondsSinceEpoch == 0) return 'Not set';
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
  return '${value.day} ${months[value.month - 1]} ${value.year}';
}

String relativeActivity(DateTime? value) {
  if (value == null) return 'No activity yet';
  final difference = DateTime.now().difference(value);
  if (difference.isNegative || difference.inMinutes < 1) return 'Just now';
  if (difference.inMinutes < 60) return '${difference.inMinutes}m ago';
  if (difference.inHours < 24) return '${difference.inHours}h ago';
  if (difference.inDays < 7) return '${difference.inDays}d ago';
  return siteDate(value);
}

class SitePortfolioHero extends StatelessWidget {
  const SitePortfolioHero({super.key, required this.collection});

  final SiteCollection collection;

  @override
  Widget build(BuildContext context) => Container(
    constraints: const BoxConstraints(minHeight: 190),
    clipBehavior: Clip.antiAlias,
    decoration: BoxDecoration(
      borderRadius: BorderRadius.circular(32),
      gradient: const LinearGradient(
        colors: [Color(0xFF08111F), Color(0xFF162234), Color(0xFF713317)],
        begin: Alignment.topLeft,
        end: Alignment.bottomRight,
      ),
      boxShadow: const [
        BoxShadow(
          color: Color(0x240A0E17),
          blurRadius: 28,
          offset: Offset(0, 14),
        ),
      ],
    ),
    child: Stack(
      children: [
        const Positioned.fill(child: CustomPaint(painter: _SiteGridPainter())),
        Positioned(
          right: -28,
          top: -62,
          child: Container(
            width: 190,
            height: 190,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: AppTheme.orange.withValues(alpha: .15),
              boxShadow: [
                BoxShadow(
                  color: AppTheme.orange.withValues(alpha: .14),
                  blurRadius: 70,
                  spreadRadius: 18,
                ),
              ],
            ),
          ),
        ),
        Padding(
          padding: const EdgeInsets.all(22),
          child: LayoutBuilder(
            builder: (context, constraints) {
              final compact = constraints.maxWidth < 520;
              final content = Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text(
                    'LIVE PORTFOLIO',
                    style: Theme.of(context).textTheme.labelSmall?.copyWith(
                      color: const Color(0xFFD0D7E3),
                      fontWeight: FontWeight.w800,
                      letterSpacing: 1,
                    ),
                  ),
                  const SizedBox(height: 12),
                  Text(
                    collection.sites.isEmpty
                        ? 'Your first site starts here.'
                        : '${collection.count(SiteStatus.active)} active of ${collection.sites.length} total sites.',
                    style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                      color: Colors.white,
                      fontWeight: FontWeight.w800,
                      height: 1.08,
                      letterSpacing: -.9,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    collection.sites.isEmpty
                        ? 'Create a governed workspace for progress, field records and project communication.'
                        : '${collection.count(SiteStatus.completed)} completed · ${collection.count(SiteStatus.onHold)} on hold',
                    style: Theme.of(context).textTheme.bodySmall?.copyWith(
                      color: const Color(0xFFB9C3D1),
                    ),
                  ),
                ],
              );
              final progress = _PortfolioProgress(
                value: collection.averageProgress / 100,
                label: '${collection.averageProgress.round()}%',
              );
              if (compact) {
                return Row(
                  children: [
                    Expanded(child: content),
                    const SizedBox(width: 16),
                    progress,
                  ],
                );
              }
              return Row(
                children: [
                  Expanded(child: content),
                  const SizedBox(width: 28),
                  progress,
                ],
              );
            },
          ),
        ),
      ],
    ),
  ).animate().fadeIn(duration: 300.ms).slideY(begin: .05, end: 0);
}

class SiteProjectCard extends StatelessWidget {
  const SiteProjectCard({super.key, required this.site});

  final SiteSummary site;

  @override
  Widget build(BuildContext context) {
    final tone = siteStatusColor(site.status);
    return SurfaceCard(
      onTap: () => context.go('/sites/${site.id}'),
      padding: EdgeInsets.zero,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Hero(
            tag: 'site-cover-${site.id}',
            child: Container(
              height: 142,
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                borderRadius: const BorderRadius.vertical(
                  top: Radius.circular(23),
                ),
                gradient: const LinearGradient(
                  colors: [
                    Color(0xFF0A1322),
                    Color(0xFF15283E),
                    Color(0xFF65301C),
                  ],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
                image: site.hasCover
                    ? DecorationImage(
                        image: NetworkImage(site.coverImage!),
                        fit: BoxFit.cover,
                        opacity: .48,
                      )
                    : null,
              ),
              child: Stack(
                children: [
                  const Positioned.fill(
                    child: CustomPaint(painter: _BlueprintPainter()),
                  ),
                  Align(
                    alignment: Alignment.topLeft,
                    child: _DarkStatusBadge(status: site.status),
                  ),
                  Align(
                    alignment: Alignment.bottomRight,
                    child: _MiniProgress(progress: site.progress, tone: tone),
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
                    site.name.isEmpty ? 'Untitled site' : site.name,
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
                        Icons.location_on_outlined,
                        size: 15,
                        color: AppTheme.muted,
                      ),
                      const SizedBox(width: 4),
                      Expanded(
                        child: Text(
                          site.location.isEmpty
                              ? 'Location not provided'
                              : site.location,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: Theme.of(context).textTheme.bodySmall
                              ?.copyWith(color: AppTheme.muted),
                        ),
                      ),
                    ],
                  ),
                  const Spacer(),
                  const Divider(height: 24),
                  Row(
                    children: [
                      Expanded(
                        child: _CardFact(
                          label: 'CLIENT',
                          value: site.clientName ?? 'Not assigned',
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: _CardFact(
                          label: 'ACTIVITY',
                          value: relativeActivity(site.lastActivity),
                        ),
                      ),
                      const SizedBox(width: 8),
                      const Icon(
                        Icons.arrow_forward_rounded,
                        color: AppTheme.orange,
                        size: 18,
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

class SiteOfflineBanner extends StatelessWidget {
  const SiteOfflineBanner({super.key, required this.syncedAt});

  final DateTime syncedAt;

  @override
  Widget build(BuildContext context) => Container(
    padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 11),
    decoration: BoxDecoration(
      color: AppTheme.warning.withValues(alpha: .09),
      borderRadius: BorderRadius.circular(18),
      border: Border.all(color: AppTheme.warning.withValues(alpha: .24)),
    ),
    child: Row(
      children: [
        const Icon(Icons.cloud_off_rounded, color: AppTheme.warning, size: 18),
        const SizedBox(width: 9),
        Expanded(
          child: Text(
            'Offline view · synced ${relativeActivity(syncedAt)}',
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

class SiteListSkeleton extends StatelessWidget {
  const SiteListSkeleton({super.key});

  @override
  Widget build(BuildContext context) => ListView(
    padding: const EdgeInsets.fromLTRB(18, 18, 18, 120),
    children: const [
      AppSkeleton(height: 58, radius: 20),
      SizedBox(height: 18),
      AppSkeleton(height: 190, radius: 32),
      SizedBox(height: 24),
      AppSkeleton(height: 54, radius: 20),
      SizedBox(height: 14),
      AppSkeleton(height: 324, radius: 24),
    ],
  );
}

class SiteRecordError extends StatelessWidget {
  const SiteRecordError({
    super.key,
    required this.error,
    required this.onRetry,
  });

  final Object error;
  final VoidCallback onRetry;

  @override
  Widget build(BuildContext context) => EmptyPanel(
    title: 'Could not load this data',
    message: '$error',
    icon: Icons.cloud_off_rounded,
    actionLabel: 'Retry',
    onAction: onRetry,
  );
}

class _PortfolioProgress extends StatelessWidget {
  const _PortfolioProgress({required this.value, required this.label});

  final double value;
  final String label;

  @override
  Widget build(BuildContext context) => SizedBox.square(
    dimension: 92,
    child: Stack(
      alignment: Alignment.center,
      children: [
        SizedBox.square(
          dimension: 78,
          child: CircularProgressIndicator(
            value: value.clamp(0, 1),
            strokeWidth: 7,
            strokeCap: StrokeCap.round,
            backgroundColor: Colors.white.withValues(alpha: .13),
            color: AppTheme.orangeBright,
          ),
        ),
        Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              label,
              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                color: Colors.white,
                fontWeight: FontWeight.w800,
              ),
            ),
            Text(
              'AVERAGE',
              style: Theme.of(context).textTheme.labelSmall?.copyWith(
                color: const Color(0xFFB7C1CE),
                fontSize: 7,
                fontWeight: FontWeight.w800,
                letterSpacing: .6,
              ),
            ),
          ],
        ),
      ],
    ),
  );
}

class _MiniProgress extends StatelessWidget {
  const _MiniProgress({required this.progress, required this.tone});

  final int progress;
  final Color tone;

  @override
  Widget build(BuildContext context) => Container(
    width: 54,
    height: 54,
    padding: const EdgeInsets.all(7),
    decoration: BoxDecoration(
      shape: BoxShape.circle,
      color: const Color(0xD10A0E17),
      border: Border.all(color: Colors.white.withValues(alpha: .12)),
    ),
    child: Stack(
      alignment: Alignment.center,
      children: [
        CircularProgressIndicator(
          value: progress / 100,
          strokeWidth: 3,
          strokeCap: StrokeCap.round,
          color: tone,
          backgroundColor: Colors.white.withValues(alpha: .14),
        ),
        Text(
          '$progress%',
          style: Theme.of(context).textTheme.labelSmall?.copyWith(
            color: Colors.white,
            fontSize: 9,
            fontWeight: FontWeight.w800,
          ),
        ),
      ],
    ),
  );
}

class _DarkStatusBadge extends StatelessWidget {
  const _DarkStatusBadge({required this.status});

  final SiteStatus status;

  @override
  Widget build(BuildContext context) => Container(
    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
    decoration: BoxDecoration(
      borderRadius: BorderRadius.circular(20),
      color: const Color(0xC90A0E17),
      border: Border.all(color: siteStatusColor(status).withValues(alpha: .7)),
    ),
    child: Text(
      status.label.toUpperCase(),
      style: Theme.of(context).textTheme.labelSmall?.copyWith(
        color: Colors.white,
        fontSize: 9,
        fontWeight: FontWeight.w800,
        letterSpacing: .5,
      ),
    ),
  );
}

class _CardFact extends StatelessWidget {
  const _CardFact({required this.label, required this.value});

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) => Column(
    crossAxisAlignment: CrossAxisAlignment.start,
    children: [
      Text(
        label,
        style: Theme.of(context).textTheme.labelSmall?.copyWith(
          color: AppTheme.muted,
          fontSize: 8,
          fontWeight: FontWeight.w800,
          letterSpacing: .7,
        ),
      ),
      const SizedBox(height: 3),
      Text(
        value,
        maxLines: 1,
        overflow: TextOverflow.ellipsis,
        style: Theme.of(
          context,
        ).textTheme.labelSmall?.copyWith(fontWeight: FontWeight.w800),
      ),
    ],
  );
}

class _SiteGridPainter extends CustomPainter {
  const _SiteGridPainter();

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = Colors.white.withValues(alpha: .035)
      ..strokeWidth = 1;
    for (double x = 0; x < size.width; x += 34) {
      canvas.drawLine(Offset(x, 0), Offset(x, size.height), paint);
    }
    for (double y = 0; y < size.height; y += 34) {
      canvas.drawLine(Offset(0, y), Offset(size.width, y), paint);
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

class _BlueprintPainter extends CustomPainter {
  const _BlueprintPainter();

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.2
      ..color = Colors.white.withValues(alpha: .09);
    final path = Path()
      ..moveTo(size.width * .1, size.height * .78)
      ..lineTo(size.width * .1, size.height * .38)
      ..lineTo(size.width * .38, size.height * .17)
      ..lineTo(size.width * .66, size.height * .34)
      ..lineTo(size.width * .66, size.height * .78)
      ..moveTo(size.width * .24, size.height * .78)
      ..lineTo(size.width * .24, size.height * .51)
      ..lineTo(size.width * .47, size.height * .51)
      ..lineTo(size.width * .47, size.height * .78);
    canvas.drawPath(path, paint);
    final glow = Paint()
      ..shader =
          RadialGradient(
            colors: [
              AppTheme.orange.withValues(alpha: .13),
              Colors.transparent,
            ],
          ).createShader(
            Rect.fromCircle(
              center: Offset(size.width * .85, size.height * .12),
              radius: math.max(size.width, size.height) * .55,
            ),
          );
    canvas.drawRect(Offset.zero & size, glow);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}
