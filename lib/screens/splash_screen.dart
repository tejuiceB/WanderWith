import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'dart:ui' as ui;
import '../theme/theme_extensions.dart';

class SplashScreen extends StatefulWidget {
  final VoidCallback onFinish;
  const SplashScreen({super.key, required this.onFinish});

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen>
    with TickerProviderStateMixin {
  late AnimationController _pathController;
  late AnimationController _contentController;
  late AnimationController _pulseController;

  // Path drawing progress (0→1)
  late Animation<double> _pathProgress;

  // Pin drop animations (staggered per pin)
  late Animation<double> _pin1Anim;
  late Animation<double> _pin2Anim;
  late Animation<double> _pin3Anim;

  // Content fade-in
  late Animation<double> _logoOpacity;
  late Animation<double> _logoScale;
  late Animation<double> _titleOpacity;
  late Animation<Offset> _titleSlide;
  late Animation<double> _taglineOpacity;
  late Animation<double> _bottomOpacity;

  // Pulse for pins
  late Animation<double> _pulseAnim;

  // Map fade-in
  late Animation<double> _mapOpacity;

  @override
  void initState() {
    super.initState();

    // Path and airplane animation: 2.5s
    _pathController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 2500),
    );

    _pathProgress = Tween<double>(begin: 0, end: 1).animate(
      CurvedAnimation(parent: _pathController, curve: Curves.easeInOut),
    );

    // Pins drop in staggered after path reaches them
    _pin1Anim = Tween<double>(begin: 0, end: 1).animate(
      CurvedAnimation(
        parent: _pathController,
        curve: const Interval(0.05, 0.20, curve: Curves.elasticOut),
      ),
    );
    _pin2Anim = Tween<double>(begin: 0, end: 1).animate(
      CurvedAnimation(
        parent: _pathController,
        curve: const Interval(0.35, 0.55, curve: Curves.elasticOut),
      ),
    );
    _pin3Anim = Tween<double>(begin: 0, end: 1).animate(
      CurvedAnimation(
        parent: _pathController,
        curve: const Interval(0.70, 0.90, curve: Curves.elasticOut),
      ),
    );

    // Content shows after path finishes
    _contentController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1200),
    );

    _logoOpacity = Tween<double>(begin: 0, end: 1).animate(
      CurvedAnimation(parent: _contentController, curve: const Interval(0.0, 0.35, curve: Curves.easeOut)),
    );
    _logoScale = Tween<double>(begin: 0.6, end: 1).animate(
      CurvedAnimation(parent: _contentController, curve: const Interval(0.0, 0.40, curve: Curves.elasticOut)),
    );
    _titleOpacity = Tween<double>(begin: 0, end: 1).animate(
      CurvedAnimation(parent: _contentController, curve: const Interval(0.20, 0.50, curve: Curves.easeOut)),
    );
    _titleSlide = Tween<Offset>(begin: const Offset(0, 0.3), end: Offset.zero).animate(
      CurvedAnimation(parent: _contentController, curve: const Interval(0.20, 0.50, curve: Curves.easeOutCubic)),
    );
    _taglineOpacity = Tween<double>(begin: 0, end: 1).animate(
      CurvedAnimation(parent: _contentController, curve: const Interval(0.40, 0.70, curve: Curves.easeOut)),
    );
    _bottomOpacity = Tween<double>(begin: 0, end: 1).animate(
      CurvedAnimation(parent: _contentController, curve: const Interval(0.60, 1.0, curve: Curves.easeOut)),
    );

    // Gentle pulse loop for pins
    _pulseController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1500),
    )..repeat(reverse: true);
    _pulseAnim = Tween<double>(begin: 0.6, end: 1.0).animate(
      CurvedAnimation(parent: _pulseController, curve: Curves.easeInOut),
    );

    // Map fades in during first half of path animation
    _mapOpacity = Tween<double>(begin: 0, end: 1).animate(
      CurvedAnimation(
        parent: _pathController,
        curve: const Interval(0.0, 0.4, curve: Curves.easeOut),
      ),
    );

    // Sequence: path draws → content fades in → finish
    _pathController.forward().then((_) {
      _contentController.forward();
    });

    Future.delayed(const Duration(milliseconds: 4200), () {
      if (mounted) widget.onFinish();
    });
  }

  @override
  void dispose() {
    _pathController.dispose();
    _contentController.dispose();
    _pulseController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final size = MediaQuery.of(context).size;

    return Scaffold(
      body: AnimatedBuilder(
        animation: Listenable.merge([_pathController, _contentController, _pulseController]),
        builder: (context, child) {
          return Container(
            width: double.infinity,
            height: double.infinity,
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: context.isDark
                  ? [const Color(0xFF0F0F0F), const Color(0xFF141414), const Color(0xFF0F0F0F)]
                  : [const Color(0xFFF8FBFF), const Color(0xFFFFFFFF), const Color(0xFFFFF8F0)],
                stops: const [0.0, 0.5, 1.0],
              ),
            ),
            child: Stack(
              children: [
                // Transparent world map background
                Positioned.fill(
                  child: Opacity(
                    opacity: _mapOpacity.value,
                    child: Image.asset(
                      'android/assets/map.png',
                      width: size.width,
                      height: size.height,
                      fit: BoxFit.contain,
                    ),
                  ),
                ),

                // Route path + airplane
                CustomPaint(
                  size: size,
                  painter: _RoutePainter(
                    progress: _pathProgress.value,
                    pinAnimations: [_pin1Anim.value, _pin2Anim.value, _pin3Anim.value],
                    pulseValue: _pulseAnim.value,
                  ),
                ),

                // Main content (centered)
                Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      // Logo
                      Opacity(
                        opacity: _logoOpacity.value,
                        child: Transform.scale(
                          scale: _logoScale.value,
                          child: Container(
                            padding: const EdgeInsets.all(18),
                            decoration: BoxDecoration(
                            color: context.appColors.cardBg,
                              shape: BoxShape.circle,
                              boxShadow: [
                                BoxShadow(
                                  color: const Color(0xFF448AFF).withOpacity(0.10),
                                  blurRadius: 40,
                                  spreadRadius: 2,
                                  offset: const Offset(0, 8),
                                ),
                                BoxShadow(
                                  color: Colors.black.withOpacity(0.04),
                                  blurRadius: 20,
                                  offset: const Offset(0, 4),
                                ),
                              ],
                            ),
                            child: Image.asset(
                              'android/assets/logo.png',
                              width: 80,
                              height: 80,
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(height: 28),

                      // Title
                      SlideTransition(
                        position: _titleSlide,
                        child: FadeTransition(
                          opacity: _titleOpacity,
                          child: Text(
                            "WanderWith",
                            style: GoogleFonts.outfit(
                              fontSize: 36,
                              fontWeight: FontWeight.bold,
                              color: context.appColors.textPrimary,
                              letterSpacing: -1.5,
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(height: 8),

                      // Tagline
                      FadeTransition(
                        opacity: _taglineOpacity,
                        child: Text(
                          "One trip. One plan. Everyone synced.",
                          textAlign: TextAlign.center,
                          style: GoogleFonts.inter(
                            color: context.appColors.textSecondary,
                            fontSize: 14,
                            fontWeight: FontWeight.w500,
                            letterSpacing: 0.3,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),

                // Bottom branding
                Positioned(
                  bottom: 60,
                  left: 0,
                  right: 0,
                  child: Opacity(
                    opacity: _bottomOpacity.value,
                    child: Column(
                      children: [
                        Container(
                          width: 40,
                          height: 2,
                          decoration: BoxDecoration(
                            borderRadius: BorderRadius.circular(1),
                            gradient: const LinearGradient(
                              colors: [Color(0xFF448AFF), Color(0xFFFF7043)],
                            ),
                          ),
                        ),
                        const SizedBox(height: 16),
                        Text(
                          "TRAVEL WITH INTENT",
                          style: GoogleFonts.inter(
                            fontSize: 10,
                            fontWeight: FontWeight.w800,
                            color: context.appColors.textMuted,
                            letterSpacing: 3,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          );
        },
      ),
    );
  }
}

/// Custom painter that draws: a curved route path, pulsing map pins, and an airplane along the path.
class _RoutePainter extends CustomPainter {
  final double progress;
  final List<double> pinAnimations;
  final double pulseValue;

  _RoutePainter({
    required this.progress,
    required this.pinAnimations,
    required this.pulseValue,
  });

  @override
  void paint(Canvas canvas, Size size) {
    // 3 waypoints (relative to canvas)
    final p1 = Offset(size.width * 0.15, size.height * 0.22);
    final p2 = Offset(size.width * 0.75, size.height * 0.35);
    final p3 = Offset(size.width * 0.50, size.height * 0.78);

    // Control points for smooth cubic bezier
    final cp1a = Offset(size.width * 0.35, size.height * 0.15);
    final cp1b = Offset(size.width * 0.65, size.height * 0.22);
    final cp2a = Offset(size.width * 0.90, size.height * 0.55);
    final cp2b = Offset(size.width * 0.65, size.height * 0.75);

    // Build full path
    final fullPath = Path()
      ..moveTo(p1.dx, p1.dy)
      ..cubicTo(cp1a.dx, cp1a.dy, cp1b.dx, cp1b.dy, p2.dx, p2.dy)
      ..cubicTo(cp2a.dx, cp2a.dy, cp2b.dx, cp2b.dy, p3.dx, p3.dy);

    // Draw dashed background path (faint)
    final bgPaint = Paint()
      ..color = const Color(0xFFE0E8F0)
      ..strokeWidth = 2
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round;
    _drawDashedPath(canvas, fullPath, bgPaint, 8, 6);

    // Draw progress portion of path
    if (progress > 0) {
      final metrics = fullPath.computeMetrics().first;
      final totalLength = metrics.length;
      final drawLength = totalLength * progress;
      final subPath = metrics.extractPath(0, drawLength);

      final routePaint = Paint()
        ..shader = ui.Gradient.linear(
          p1,
          p3,
          [const Color(0xFF448AFF), const Color(0xFFFF7043)],
        )
        ..strokeWidth = 3
        ..style = PaintingStyle.stroke
        ..strokeCap = StrokeCap.round;
      canvas.drawPath(subPath, routePaint);

      // Draw airplane at the tip of the path
      final tangent = metrics.getTangentForOffset(drawLength);
      if (tangent != null) {
        _drawAirplane(canvas, tangent.position, tangent.angle);
      }
    }

    // Draw pins
    final pins = [p1, p2, p3];
    final pinColors = [
      const Color(0xFF448AFF),
      const Color(0xFFFF7043),
      const Color(0xFF4CAF50),
    ];

    for (int i = 0; i < pins.length; i++) {
      if (pinAnimations[i] > 0) {
        _drawPin(canvas, pins[i], pinColors[i], pinAnimations[i]);
      }
    }
  }

  void _drawPin(Canvas canvas, Offset pos, Color color, double anim) {
    // Pulse ring
    final pulseRadius = 14.0 * pulseValue;
    final pulsePaint = Paint()
      ..color = color.withOpacity(0.12 * anim)
      ..style = PaintingStyle.fill;
    canvas.drawCircle(pos, pulseRadius, pulsePaint);

    // Pin shadow
    canvas.drawCircle(
      pos + const Offset(0, 2),
      7 * anim,
      Paint()..color = color.withOpacity(0.2 * anim),
    );

    // Pin circle
    canvas.drawCircle(
      pos,
      6 * anim,
      Paint()..color = color,
    );

    // Inner white dot
    canvas.drawCircle(
      pos,
      2.5 * anim,
      Paint()..color = Colors.white,
    );
  }

  void _drawAirplane(Canvas canvas, Offset position, double angle) {
    canvas.save();
    canvas.translate(position.dx, position.dy);
    canvas.rotate(angle);

    final paint = Paint()
      ..color = const Color(0xFF448AFF)
      ..style = PaintingStyle.fill;

    // Simple airplane shape
    final plane = Path()
      ..moveTo(10, 0)
      ..lineTo(-6, -5)
      ..lineTo(-4, 0)
      ..lineTo(-6, 5)
      ..close();

    canvas.drawPath(plane, paint);

    // Small wing accent
    canvas.drawCircle(const Offset(-2, 0), 2, Paint()..color = Colors.white.withOpacity(0.8));

    canvas.restore();
  }

  void _drawDashedPath(Canvas canvas, Path path, Paint paint, double dashLen, double gapLen) {
    for (final metric in path.computeMetrics()) {
      double distance = 0;
      while (distance < metric.length) {
        final end = (distance + dashLen).clamp(0.0, metric.length);
        canvas.drawPath(metric.extractPath(distance, end), paint);
        distance += dashLen + gapLen;
      }
    }
  }

  @override
  bool shouldRepaint(covariant _RoutePainter oldDelegate) {
    return oldDelegate.progress != progress ||
        oldDelegate.pulseValue != pulseValue;
  }
}


