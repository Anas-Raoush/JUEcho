import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:juecho/common/constants/app_colors.dart';

/// Animated brand/splash widget that renders:
/// - A central SVG logo
/// - Three animated "echo" rings radiating outward behind the logo
///
/// Animation model:
/// - A single repeating AnimationController drives the whole effect.
/// - The controller value (0.0 -> 1.0) is used as:
///   -> input to EchoPainter to animate ring radius/opacity/stroke width
///   -> input to a derived fade animation for subtle logo fade-in/pulse
///
/// Rendering model:
/// - Uses AnimatedBuilder to rebuild the Stack each tick without manual setState.
/// - Background rings are painted via CustomPaint (EchoPainter).
/// - Logo is rendered via SvgPicture with FadeTransition.
class LogoWithEcho extends StatefulWidget {
  const LogoWithEcho({super.key});

  @override
  State<LogoWithEcho> createState() => _LogoWithEchoState();
}

class _LogoWithEchoState extends State<LogoWithEcho>
    with SingleTickerProviderStateMixin {
  /// Drives the echo animation loop (0.0 -> 1.0, repeating).
  late final AnimationController _ctrl;

  /// Derived opacity animation for the logo.
  /// Uses the first portion of the controller timeline to create a soft fade/pulse.
  late final Animation<double> _fade;

  @override
  void initState() {
    super.initState();

    _ctrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1600),
    )..repeat();

    _fade = Tween<double>(begin: 0.5, end: 1.0).animate(
      CurvedAnimation(
        parent: _ctrl,
        curve: const Interval(
          0.0,
          0.45,
          curve: Curves.easeOut,
        ),
      ),
    );
  }

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _ctrl,
      builder: (context, _) {
        return Stack(
          alignment: Alignment.center,
          children: [
            SizedBox(
              width: 220,
              height: 220,
              child: CustomPaint(
                painter: EchoPainter(
                  progress: _ctrl.value,
                  color: AppColors.primary,
                ),
              ),
            ),
            FadeTransition(
              opacity: _fade,
              child: SvgPicture.asset(
                'assets/images/JUEcho_BGR.svg',
                width: 140,
              ),
            ),
          ],
        );
      },
    );
  }
}

/// EchoPainter
///
/// CustomPainter responsible for drawing the animated "echo" rings.
///
/// Inputs:
/// - progress: global animation progress in range 0.0..1.0
/// - color: base ring color (alpha adjusted per ring)
///
/// Behavior per frame:
/// - Paints exactly three rings with phase offsets:
///   -> ring0 uses progress + 0/3
///   -> ring1 uses progress + 1/3
///   -> ring2 uses progress + 2/3
/// - Each ring:
///   -> expands from 60% of max radius to 100% of max radius
///   -> fades out as it expands
///   -> decreases stroke width as it expands
///
/// This painter is pure with respect to time:
/// - It does not manage animation state
/// - It redraws based on the provided progress value
class EchoPainter extends CustomPainter {
  EchoPainter({
    required this.progress,
    required this.color,
  });

  /// Global animation progress for the frame (0.0..1.0).
  final double progress;

  /// Base color for rings. Alpha is calculated per ring.
  final Color color;

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    final maxR = size.shortestSide * 0.5;

    for (int i = 0; i < 3; i++) {
      final p = (progress + i / 3.0) % 1.0;

      final radius = _lerp(maxR * 0.6, maxR, p);
      final opacity = (1.0 - p) * 0.75;

      final paint = Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = _lerp(3.0, 1.0, p)
        ..color = color.withAlpha((opacity * 255).round());

      canvas.drawCircle(center, radius, paint);
    }
  }

  @override
  bool shouldRepaint(covariant EchoPainter oldDelegate) {
    return oldDelegate.progress != progress || oldDelegate.color != color;
  }

  double _lerp(double a, double b, double t) => a + (b - a) * t;
}