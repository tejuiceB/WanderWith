import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'dart:math';

class SplashScreen extends StatefulWidget {
  final VoidCallback onFinish;
  const SplashScreen({super.key, required this.onFinish});

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen>
    with TickerProviderStateMixin {
  late AnimationController _mainController;
  late AnimationController _floatController;

  // Phase 1: Logo
  late Animation<double> _logoOpacity;
  late Animation<double> _logoScale;

  // Phase 2: Title
  late Animation<double> _titleOpacity;
  late Animation<Offset> _titleSlide;

  // Phase 3: Tagline
  late Animation<double> _taglineOpacity;
  late Animation<Offset> _taglineSlide;

  // Phase 4: Bottom branding
  late Animation<double> _bottomOpacity;

  // Floating decorative circles
  late Animation<double> _floatAnimation;

  @override
  void initState() {
    super.initState();

    // Main staggered animation controller (2.5s total animation)
    _mainController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 2500),
    );

    // Looping float controller for decorative elements
    _floatController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 4),
    )..repeat(reverse: true);

    _floatAnimation = Tween<double>(begin: 0, end: 1).animate(
      CurvedAnimation(parent: _floatController, curve: Curves.easeInOut),
    );

    // Phase 1: Logo — 0ms to 600ms
    _logoOpacity = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(
        parent: _mainController,
        curve: const Interval(0.0, 0.24, curve: Curves.easeOut),
      ),
    );
    _logoScale = Tween<double>(begin: 0.5, end: 1.0).animate(
      CurvedAnimation(
        parent: _mainController,
        curve: const Interval(0.0, 0.28, curve: Curves.elasticOut),
      ),
    );

    // Phase 2: Title — 400ms to 1000ms
    _titleOpacity = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(
        parent: _mainController,
        curve: const Interval(0.16, 0.40, curve: Curves.easeOut),
      ),
    );
    _titleSlide = Tween<Offset>(
      begin: const Offset(0, 0.3),
      end: Offset.zero,
    ).animate(
      CurvedAnimation(
        parent: _mainController,
        curve: const Interval(0.16, 0.40, curve: Curves.easeOutCubic),
      ),
    );

    // Phase 3: Tagline — 700ms to 1300ms
    _taglineOpacity = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(
        parent: _mainController,
        curve: const Interval(0.28, 0.52, curve: Curves.easeOut),
      ),
    );
    _taglineSlide = Tween<Offset>(
      begin: const Offset(0, 0.2),
      end: Offset.zero,
    ).animate(
      CurvedAnimation(
        parent: _mainController,
        curve: const Interval(0.28, 0.52, curve: Curves.easeOutCubic),
      ),
    );

    // Phase 4: Bottom branding — 1000ms to 1600ms
    _bottomOpacity = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(
        parent: _mainController,
        curve: const Interval(0.40, 0.64, curve: Curves.easeOut),
      ),
    );

    _mainController.forward();

    Future.delayed(const Duration(seconds: 3), () {
      if (mounted) widget.onFinish();
    });
  }

  @override
  void dispose() {
    _mainController.dispose();
    _floatController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final size = MediaQuery.of(context).size;

    return Scaffold(
      body: AnimatedBuilder(
        animation: Listenable.merge([_mainController, _floatController]),
        builder: (context, child) {
          return Container(
            width: double.infinity,
            height: double.infinity,
            decoration: const BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
                colors: [
                  Color(0xFFF8FBFF), // Very light blue-white
                  Colors.white,
                  Color(0xFFF0F4FA), // Soft blue-gray at bottom
                ],
                stops: [0.0, 0.5, 1.0],
              ),
            ),
            child: Stack(
              children: [
                // Floating decorative circles
                ..._buildFloatingCircles(size),

                // Main content
                Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      // Logo with fade + scale
                      Opacity(
                        opacity: _logoOpacity.value,
                        child: Transform.scale(
                          scale: _logoScale.value,
                          child: Container(
                            padding: const EdgeInsets.all(20),
                            decoration: BoxDecoration(
                              color: Colors.white,
                              shape: BoxShape.circle,
                              boxShadow: [
                                BoxShadow(
                                  color: const Color(0xFF4A90D9)
                                      .withOpacity(0.08 * _logoOpacity.value),
                                  blurRadius: 40,
                                  spreadRadius: 5,
                                  offset: const Offset(0, 8),
                                ),
                                BoxShadow(
                                  color: Colors.black
                                      .withOpacity(0.04 * _logoOpacity.value),
                                  blurRadius: 20,
                                  offset: const Offset(0, 4),
                                ),
                              ],
                            ),
                            child: Image.asset(
                              'android/assets/logo.png',
                              width: 100,
                              height: 100,
                            ),
                          ),
                        ),
                      ),

                      const SizedBox(height: 36),

                      // App name with slide + fade
                      SlideTransition(
                        position: _titleSlide,
                        child: FadeTransition(
                          opacity: _titleOpacity,
                          child: Text(
                            "WanderWith",
                            style: GoogleFonts.outfit(
                              fontSize: 38,
                              fontWeight: FontWeight.bold,
                              color: const Color(0xFF1A1A2E),
                              letterSpacing: -1.5,
                            ),
                          ),
                        ),
                      ),

                      const SizedBox(height: 10),

                      // Tagline with slide + fade
                      SlideTransition(
                        position: _taglineSlide,
                        child: FadeTransition(
                          opacity: _taglineOpacity,
                          child: Text(
                            "One trip. One plan. Everyone synced.",
                            textAlign: TextAlign.center,
                            style: GoogleFonts.inter(
                              color: const Color(0xFF8E99A4),
                              fontSize: 15,
                              fontWeight: FontWeight.w500,
                              letterSpacing: 0.3,
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),

                // Bottom branding with fade
                Positioned(
                  bottom: 60,
                  left: 0,
                  right: 0,
                  child: Opacity(
                    opacity: _bottomOpacity.value,
                    child: Column(
                      children: [
                        // Animated progress line
                        Container(
                          width: 40,
                          height: 2,
                          decoration: BoxDecoration(
                            borderRadius: BorderRadius.circular(1),
                            gradient: const LinearGradient(
                              colors: [
                                Color(0xFF4A90D9),
                                Color(0xFF7BB3F0),
                              ],
                            ),
                          ),
                        ),
                        const SizedBox(height: 16),
                        Text(
                          "TRAVEL WITH INTENT",
                          style: GoogleFonts.inter(
                            fontSize: 10,
                            fontWeight: FontWeight.w800,
                            color: const Color(0xFFBCC5CE),
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

  List<Widget> _buildFloatingCircles(Size size) {
    final circles = <_FloatingCircle>[
      _FloatingCircle(
        x: size.width * 0.15,
        y: size.height * 0.12,
        radius: 60,
        color: const Color(0xFF4A90D9),
        opacity: 0.04,
        driftX: 8,
        driftY: 12,
        phase: 0.0,
      ),
      _FloatingCircle(
        x: size.width * 0.85,
        y: size.height * 0.20,
        radius: 40,
        color: const Color(0xFF7BB3F0),
        opacity: 0.05,
        driftX: -6,
        driftY: 10,
        phase: 0.3,
      ),
      _FloatingCircle(
        x: size.width * 0.70,
        y: size.height * 0.75,
        radius: 80,
        color: const Color(0xFF4A90D9),
        opacity: 0.03,
        driftX: -10,
        driftY: -8,
        phase: 0.6,
      ),
      _FloatingCircle(
        x: size.width * 0.20,
        y: size.height * 0.80,
        radius: 50,
        color: const Color(0xFF7BB3F0),
        opacity: 0.04,
        driftX: 10,
        driftY: -12,
        phase: 0.2,
      ),
      _FloatingCircle(
        x: size.width * 0.50,
        y: size.height * 0.06,
        radius: 35,
        color: const Color(0xFF9BC4F5),
        opacity: 0.05,
        driftX: -5,
        driftY: 8,
        phase: 0.5,
      ),
    ];

    return circles.map((c) {
      // Create a phase-shifted animation value
      final t = (_floatAnimation.value + c.phase) % 1.0;
      final easedT = sin(t * pi); // Smooth oscillation

      return Positioned(
        left: c.x + c.driftX * easedT,
        top: c.y + c.driftY * easedT,
        child: Opacity(
          opacity: c.opacity * _logoOpacity.value, // Fade in with logo
          child: Container(
            width: c.radius,
            height: c.radius,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: c.color,
            ),
          ),
        ),
      );
    }).toList();
  }
}

class _FloatingCircle {
  final double x, y, radius, opacity, driftX, driftY, phase;
  final Color color;

  const _FloatingCircle({
    required this.x,
    required this.y,
    required this.radius,
    required this.color,
    required this.opacity,
    required this.driftX,
    required this.driftY,
    required this.phase,
  });
}
