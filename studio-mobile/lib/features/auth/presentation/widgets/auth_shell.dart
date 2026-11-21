import 'dart:ui';

import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';

import '../../../../core/theme/app_theme.dart';
import '../../../../core/widgets/app_ui.dart';

class AuthShell extends StatelessWidget {
  const AuthShell({super.key, required this.child, this.formMaxWidth = 460});

  final Widget child;
  final double formMaxWidth;

  @override
  Widget build(BuildContext context) => Scaffold(
    body: LayoutBuilder(
      builder: (context, constraints) {
        final wide = constraints.maxWidth >= 940;
        return Row(
          children: [
            if (wide)
              const Expanded(flex: 10, child: AuthBrandPanel())
            else
              const SizedBox.shrink(),
            Expanded(
              flex: wide ? 11 : 1,
              child: Stack(
                children: [
                  const Positioned.fill(child: _FormBackground()),
                  SafeArea(
                    child: SingleChildScrollView(
                      padding: EdgeInsets.fromLTRB(
                        wide ? 48 : 22,
                        wide ? 44 : 24,
                        wide ? 48 : 22,
                        32,
                      ),
                      child: Center(
                        child: ConstrainedBox(
                          constraints: BoxConstraints(maxWidth: formMaxWidth),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              if (!wide) ...[
                                const AppLogo(),
                                const SizedBox(height: 44),
                              ],
                              child,
                            ],
                          ),
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        );
      },
    ),
  );
}

class AuthBrandPanel extends StatelessWidget {
  const AuthBrandPanel({super.key});

  @override
  Widget build(BuildContext context) => ColoredBox(
    color: AppTheme.ink,
    child: Stack(
      children: [
        const Positioned.fill(child: _BlueprintGrid()),
        const Positioned(
          top: -105,
          right: -85,
          child: _Glow(size: 320, color: AppTheme.orange),
        ),
        const Positioned(
          left: -120,
          bottom: -130,
          child: _Glow(size: 360, color: Color(0xFF293343)),
        ),
        SafeArea(
          child: Padding(
            padding: const EdgeInsets.all(48),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const AppLogo(light: true),
                const Spacer(),
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 12,
                    vertical: 8,
                  ),
                  decoration: BoxDecoration(
                    color: AppTheme.orange.withValues(alpha: .13),
                    borderRadius: BorderRadius.circular(32),
                    border: Border.all(
                      color: AppTheme.orange.withValues(alpha: .3),
                    ),
                  ),
                  child: Text(
                    'CONSTRUCTION OPERATING SYSTEM',
                    style: Theme.of(context).textTheme.labelSmall?.copyWith(
                      color: AppTheme.orangeBright,
                      fontWeight: FontWeight.w800,
                      letterSpacing: 1,
                    ),
                  ),
                ).animate().fadeIn(duration: 350.ms).slideY(begin: .15, end: 0),
                const SizedBox(height: 22),
                Text(
                      'One decisive view\nfrom office to site.',
                      style: Theme.of(context).textTheme.displaySmall?.copyWith(
                        color: Colors.white,
                        fontWeight: FontWeight.w800,
                        height: 1.08,
                        letterSpacing: -1.6,
                      ),
                    )
                    .animate(delay: 80.ms)
                    .fadeIn(duration: 420.ms)
                    .slideY(begin: .12, end: 0),
                const SizedBox(height: 18),
                Text(
                  'Plan work, coordinate people, control material and keep clients informed through one role-aware workspace.',
                  style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    color: const Color(0xFFB5BECC),
                    height: 1.65,
                  ),
                ).animate(delay: 150.ms).fadeIn(duration: 420.ms),
                const SizedBox(height: 32),
                const Wrap(
                  spacing: 10,
                  runSpacing: 10,
                  children: [
                    _Capability(
                      icon: Icons.apartment_rounded,
                      label: 'Site control',
                    ),
                    _Capability(
                      icon: Icons.groups_2_rounded,
                      label: 'Field teams',
                    ),
                    _Capability(
                      icon: Icons.auto_awesome_rounded,
                      label: 'AI planning',
                    ),
                  ],
                ).animate(delay: 220.ms).fadeIn(duration: 420.ms),
                const Spacer(),
                Row(
                  children: [
                    const Icon(
                      Icons.lock_outline_rounded,
                      size: 16,
                      color: Color(0xFF8F9BAD),
                    ),
                    const SizedBox(width: 9),
                    Expanded(
                      child: Text(
                        'Encrypted session storage • Role-based access • Secure API',
                        style: Theme.of(context).textTheme.labelSmall?.copyWith(
                          color: const Color(0xFF8F9BAD),
                          height: 1.4,
                        ),
                      ),
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

class AuthErrorBanner extends StatelessWidget {
  const AuthErrorBanner({super.key, required this.message});

  final String message;

  @override
  Widget build(BuildContext context) => Container(
    width: double.infinity,
    padding: const EdgeInsets.all(14),
    decoration: BoxDecoration(
      color: AppTheme.danger.withValues(alpha: .08),
      borderRadius: BorderRadius.circular(18),
      border: Border.all(color: AppTheme.danger.withValues(alpha: .22)),
    ),
    child: Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Icon(
          Icons.error_outline_rounded,
          color: AppTheme.danger,
          size: 19,
        ),
        const SizedBox(width: 10),
        Expanded(
          child: Text(
            message,
            style: Theme.of(context).textTheme.bodySmall?.copyWith(
              color: AppTheme.danger,
              height: 1.45,
              fontWeight: FontWeight.w600,
            ),
          ),
        ),
      ],
    ),
  ).animate().fadeIn(duration: 220.ms).slideY(begin: -.08, end: 0);
}

class AuthPrimaryButton extends StatefulWidget {
  const AuthPrimaryButton({
    super.key,
    required this.label,
    required this.icon,
    required this.onPressed,
    this.loading = false,
  });

  final String label;
  final IconData icon;
  final VoidCallback? onPressed;
  final bool loading;

  @override
  State<AuthPrimaryButton> createState() => _AuthPrimaryButtonState();
}

class _AuthPrimaryButtonState extends State<AuthPrimaryButton> {
  bool _pressed = false;

  @override
  Widget build(BuildContext context) => Listener(
    onPointerDown: widget.onPressed == null
        ? null
        : (_) => setState(() => _pressed = true),
    onPointerUp: widget.onPressed == null
        ? null
        : (_) => setState(() => _pressed = false),
    onPointerCancel: widget.onPressed == null
        ? null
        : (_) => setState(() => _pressed = false),
    child: AnimatedScale(
      scale: _pressed ? .975 : 1,
      duration: const Duration(milliseconds: 120),
      curve: Curves.easeOutCubic,
      child: FilledButton.icon(
        onPressed: widget.onPressed,
        icon: widget.loading
            ? const SizedBox.square(
                dimension: 18,
                child: CircularProgressIndicator(
                  color: Colors.white,
                  strokeWidth: 2,
                ),
              )
            : Icon(widget.icon),
        label: Text(widget.label),
      ),
    ),
  );
}

class _Capability extends StatelessWidget {
  const _Capability({required this.icon, required this.label});

  final IconData icon;
  final String label;

  @override
  Widget build(BuildContext context) => ClipRRect(
    borderRadius: BorderRadius.circular(18),
    child: BackdropFilter(
      filter: ImageFilter.blur(sigmaX: 14, sigmaY: 14),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 13, vertical: 11),
        decoration: BoxDecoration(
          color: Colors.white.withValues(alpha: .07),
          borderRadius: BorderRadius.circular(18),
          border: Border.all(color: Colors.white.withValues(alpha: .1)),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, color: AppTheme.orangeBright, size: 17),
            const SizedBox(width: 8),
            Text(
              label,
              style: Theme.of(context).textTheme.labelMedium?.copyWith(
                color: Colors.white,
                fontWeight: FontWeight.w700,
              ),
            ),
          ],
        ),
      ),
    ),
  );
}

class _FormBackground extends StatelessWidget {
  const _FormBackground();

  @override
  Widget build(BuildContext context) {
    final dark = Theme.of(context).brightness == Brightness.dark;
    return DecoratedBox(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topRight,
          end: Alignment.bottomLeft,
          colors: dark
              ? const [Color(0xFF141B27), Color(0xFF0A0E17)]
              : const [Color(0xFFF1F7FF), Color(0xFFF4F7FB), Colors.white],
          stops: const [0, .48, 1],
        ),
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
      color: color.withValues(alpha: .14),
      boxShadow: [
        BoxShadow(
          color: color.withValues(alpha: .22),
          blurRadius: 110,
          spreadRadius: 38,
        ),
      ],
    ),
  );
}

class _BlueprintGrid extends StatelessWidget {
  const _BlueprintGrid();

  @override
  Widget build(BuildContext context) => CustomPaint(painter: _GridPainter());
}

class _GridPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = Colors.white.withValues(alpha: .035)
      ..strokeWidth = 1;
    const step = 34.0;
    for (var x = 0.0; x < size.width; x += step) {
      canvas.drawLine(Offset(x, 0), Offset(x, size.height), paint);
    }
    for (var y = 0.0; y < size.height; y += step) {
      canvas.drawLine(Offset(0, y), Offset(size.width, y), paint);
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}
