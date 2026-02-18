import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

class SplashScreen extends StatefulWidget {
  final VoidCallback onFinish;
  const SplashScreen({super.key, required this.onFinish});

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen> with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _scaleAnimation;
  late Animation<double> _planeAnimation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 2),
    );

    _scaleAnimation = Tween<double>(begin: 0.8, end: 1.0).animate(
      CurvedAnimation(parent: _controller, curve: Curves.easeOutBack),
    );

    _planeAnimation = Tween<double>(begin: -50, end: 400).animate(
      CurvedAnimation(parent: _controller, curve: Curves.easeInOut),
    );

    _controller.forward();

    Future.delayed(const Duration(seconds: 3), () {
        if (mounted) widget.onFinish();
    });
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: Stack(
        children: [
          // Subtle Plane Animation in background
          AnimatedBuilder(
            animation: _planeAnimation,
            builder: (context, child) {
              return Positioned(
                top: 150,
                right: _planeAnimation.value,
                child: Opacity(
                  opacity: 0.1,
                  child: const Icon(Icons.airplanemode_active, size: 40, color: Colors.blueAccent),
                ),
              );
            },
          ),
          Center(
            child: ScaleTransition(
              scale: _scaleAnimation,
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                   // Official Logo
                   Image.asset(
                     'android/assets/logo.png',
                     width: 120,
                     height: 120,
                   ),
                   const SizedBox(height: 32),
                   // App Name
                   Text(
                     "WanderWith",
                     style: GoogleFonts.outfit(
                       fontSize: 36,
                       fontWeight: FontWeight.bold,
                       color: Colors.black,
                       letterSpacing: -1.5,
                     ),
                   ),
                   const SizedBox(height: 8),
                   Text(
                     "One trip. One plan. Everyone synced.",
                     textAlign: TextAlign.center,
                     style: GoogleFonts.inter(
                       color: Colors.grey[400], 
                       fontSize: 14,
                       fontWeight: FontWeight.w500,
                       letterSpacing: 0.5,
                     ),
                   ),
                ],
              ),
            ),
          ),
          Positioned(
            bottom: 60,
            left: 0,
            right: 0,
            child: Center(
              child: Column(
                children: [
                  const SizedBox(
                    width: 40,
                    height: 2,
                    child: LinearProgressIndicator(
                      backgroundColor: Color(0xFFF5F5F5),
                      valueColor: AlwaysStoppedAnimation<Color>(Colors.blueAccent),
                    ),
                  ),
                  const SizedBox(height: 16),
                  Text(
                    "TRAVEL WITH INTENT",
                    style: GoogleFonts.inter(
                      fontSize: 10,
                      fontWeight: FontWeight.w800,
                      color: Colors.grey[300],
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
  }
}
