import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:juecho/common/constants/app_colors.dart';

/// Splash / brand widget that shows:
/// - A central SVG logo
/// - Three animated "echo" rings radiating out from the logo
///
/// The echo effect is driven by a looping [AnimationController].
/// The logo itself has a subtle fade-in / pulsing animation.
class LogoWithEcho extends StatefulWidget {
  const LogoWithEcho({super.key});

  @override
  State<LogoWithEcho> createState() => _LogoWithEchoState();
}

class _LogoWithEchoState extends State<LogoWithEcho>
    with SingleTickerProviderStateMixin {
  /// Controls the overall progress of the echo animation.
  ///
  /// `_ctrl.value` goes from 0.0 -> 1.0 repeatedly (because of `.repeat()`),
  /// and that single value is used to derive:
  /// - how far each ring has expanded (radius)
  /// - how visible each ring is (opacity)
  /// - how thick each ring’s stroke is (strokeWidth)
  late final AnimationController _ctrl;

  /// Controls the fade animation for the SVG logo in the center.
  ///
  /// This is derived from the same [_ctrl] controller, but only uses
  /// the first portion of the animation curve (0%–45% of the controller’s
  /// timeline), to create a soft fade-in / pulsing effect.
  late final Animation<double> _fade;

  @override
  void initState() {
    super.initState();

    // Single, repeating controller that drives both:
    // - the echo rings (via _ctrl.value passed into EchoPainter)
    // - the logo fade (via _fade)
    _ctrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1600),
    )..repeat(); // Loop indefinitely for a continuous echo effect.

    // Fade the logo from 50% to 100% opacity over the first ~45%
    // of the controller’s duration, with a smooth ease-out curve.
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
    // Always dispose animation controllers to avoid memory leaks.
    _ctrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    // AnimatedBuilder rebuilds this subtree whenever _ctrl ticks.
    // This keeps the CustomPaint (rings) and FadeTransition (logo)
    // in sync with the animation without manually calling setState().
    return AnimatedBuilder(
      animation: _ctrl,
      builder: (context, _) {
        return Stack( // For widget overlapping.
          alignment: Alignment.center,
          children: [
            // Background echo rings.
            SizedBox(
              width: 220,
              height: 220,
              child: CustomPaint(
                painter: EchoPainter(
                  // The raw controller value (0.0–1.0) is interpreted
                  // by EchoPainter as the "global" animation progress.
                  progress: _ctrl.value,
                  color: AppColors.primary,
                ),
              ),
            ),

            // Foreground logo with a subtle fade animation.
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

/// Custom painter responsible for drawing the animated "echo" rings.
///
/// Given a [progress] value from 0.0 to 1.0:
/// - Three rings are drawn, each with a phase offset so they appear
///   to trail one another like ripples.
/// - Each ring:
///   - starts closer to the center and expands outward,
///   - fades out as it grows,
///   - becomes thinner (stroke width decreases) as it expands.
class EchoPainter extends CustomPainter {
  EchoPainter({
    required this.progress,
    required this.color,
  });

  /// Global animation progress (0.0–1.0), typically from an AnimationController.
  ///
  /// The painter does not manage time itself; it’s a pure function of:
  /// - [progress]
  /// - [size] (provided by the CustomPaint)
  final double progress;

  /// Base color used for the echo rings.
  ///
  /// The actual painted color varies per ring because we adjust the alpha
  /// channel based on each ring’s local progress.
  final Color color;

  @override
  void paint(Canvas canvas, Size size) {
    // Center point of the canvas; all rings are drawn around this.
    final center = Offset(size.width / 2, size.height / 2);

    // Maximum radius allowed for the rings (half of the shortest side),
    // so they always fit within the bounds.
    final maxR = size.shortestSide * 0.5;

    // We draw exactly three rings per frame.
    // Each ring uses the same animation curve, but with a phase offset
    // so they appear staggered in time rather than overlapping.
    for (int i = 0; i < 3; i++) {
      // Local progress for this specific ring.
      //
      // `i / 3.0` creates an offset of:
      // - 0.0 for the first ring
      // - ~0.33 for the second
      // - ~0.66 for the third
      //
      // Adding that to [progress] and applying `% 1.0` wraps the value
      // back into [0.0, 1.0), so each ring cycles smoothly.
      final p = (progress + i / 3.0) % 1.0;

      // Radius interpolates from 60% of maxR to 100% of maxR as `p` goes 0->1.
      // This makes each ring grow outward over its life cycle.
      final radius = _lerp(maxR * 0.6, maxR, p);

      // Opacity goes from 75% down to 0% as `p` goes 0->1.
      // Newer rings are more visible; older, larger rings fade out.
      final opacity = (1.0 - p) * 0.75;

      // Configure the paint for this ring.
      final paint = Paint()
      // Stroke only (no filled circle).
        ..style = PaintingStyle.stroke
      // Stroke width shrinks from 3 to 1 as the ring expands
      // to reinforce the dissipating-wave feel.
        ..strokeWidth = _lerp(3.0, 1.0, p)
      // Apply per-ring alpha based on [opacity].
        ..color = color.withAlpha((opacity * 255).round());

      // Draw the ring for this frame. Because Flutter’s painting is
      // stateless between frames, we always draw exactly three circles
      // each time paint() is called.
      canvas.drawCircle(center, radius, paint);
    }
  }

  @override
  bool shouldRepaint(covariant EchoPainter oldDelegate) {
    // Repaint whenever the animation progress changes.
    // This keeps the rings in sync with the controller driving `progress`.
    return oldDelegate.progress != progress || oldDelegate.color != color;
  }

  /// Linear interpolation between [a] and [b] for a given [t] in [0.0, 1.0].
  ///
  /// Commonly used to smoothly animate numeric values:
  /// - radius (startRadius -> endRadius)
  /// - stroke width (thick -> thin)
  double _lerp(double a, double b, double t) => a + (b - a) * t;
}
