import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/theme/app_theme.dart';
import '../../../../core/widgets/app_ui.dart';
import '../../providers/auth_provider.dart';

class SplashScreen extends ConsumerWidget {
  const SplashScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    ref.watch(authControllerProvider);
    return Scaffold(
      backgroundColor: AppTheme.ink,
      body: Stack(
        children: [
          const Positioned(
            top: -100,
            right: -70,
            child: _Glow(size: 285, color: AppTheme.orange),
          ),
          const Positioned(
            bottom: -140,
            left: -100,
            child: _Glow(size: 310, color: Color(0xFF2A3444)),
          ),
          SafeArea(
            child: Padding(
              padding: const EdgeInsets.all(28),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Spacer(),
                  const AppLogo(light: true)
                      .animate()
                      .fadeIn(duration: 420.ms)
                      .slideY(begin: .22, end: 0, curve: Curves.easeOutCubic),
                  const SizedBox(height: 30),
                  Text(
                        'Build with control.\nDeliver with confidence.',
                        style: Theme.of(context).textTheme.displaySmall
                            ?.copyWith(
                              color: Colors.white,
                              fontWeight: FontWeight.w800,
                              height: 1.08,
                              letterSpacing: -1.5,
                            ),
                      )
                      .animate(delay: 120.ms)
                      .fadeIn(duration: 420.ms)
                      .slideY(begin: .16, end: 0),
                  const SizedBox(height: 14),
                  Text(
                    'Your construction workspace, secured and ready for the field.',
                    style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                      color: const Color(0xFFAFBAC9),
                      height: 1.55,
                    ),
                  ).animate(delay: 220.ms).fadeIn(duration: 380.ms),
                  const Spacer(),
                  Semantics(
                    liveRegion: true,
                    label: 'Validating secure session',
                    child: Row(
                      children: [
                        SizedBox.square(
                          dimension: 17,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            color: AppTheme.orangeBright.withValues(alpha: .9),
                          ),
                        ),
                        const SizedBox(width: 12),
                        Text(
                          'VALIDATING SECURE SESSION',
                          style: Theme.of(context).textTheme.labelSmall
                              ?.copyWith(
                                color: const Color(0xFF929FB1),
                                fontSize: 10,
                                fontWeight: FontWeight.w700,
                                letterSpacing: 1.1,
                              ),
                        ),
                      ],
                    ),
                  ).animate(delay: 320.ms).fadeIn(duration: 360.ms),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _Glow extends StatelessWidget {
  const _Glow({required this.size, required this.color});

  final double size;
  final Color color;

  @override
  Widget build(BuildContext context) => Container(
    width: size,
    height: size,
    decoration: BoxDecoration(
      shape: BoxShape.circle,
      color: color.withValues(alpha: .16),
      boxShadow: [
        BoxShadow(
          color: color.withValues(alpha: .26),
          blurRadius: 100,
          spreadRadius: 34,
        ),
      ],
    ),
  );
}
