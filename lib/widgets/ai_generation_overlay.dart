import 'package:flutter/material.dart';
import 'dart:ui';

class AIPlanGenerationOverlay extends StatefulWidget {
  final String status;
  const AIPlanGenerationOverlay({super.key, required this.status});

  @override
  State<AIPlanGenerationOverlay> createState() => _AIPlanGenerationOverlayState();
}

class _AIPlanGenerationOverlayState extends State<AIPlanGenerationOverlay> with SingleTickerProviderStateMixin {
  late AnimationController _pulseController;
  late Animation<double> _pulseAnimation;

  @override
  void initState() {
    super.initState();
    _pulseController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 2),
    )..repeat(reverse: true);
    _pulseAnimation = Tween<double>(begin: 1.0, end: 1.1).animate(
      CurvedAnimation(parent: _pulseController, curve: Curves.easeInOut),
    );
  }

  @override
  void dispose() {
    _pulseController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    // Map status strings to progress and icons
    double progress = 0.25;
    IconData icon = Icons.psychology_outlined;
    String mainText = widget.status;
    String subText = "Thinking...";

    if (widget.status.contains("Consulting") || widget.status.contains("Analyzing")) {
      progress = 0.25;
      icon = Icons.psychology_outlined;
      subText = "Understanding your travel preferences...";
    } else if (widget.status.contains("Optimizing") || widget.status.contains("Designing")) {
      progress = 0.50;
      icon = Icons.map_outlined;
      subText = "Finding the best paths through the city...";
    } else if (widget.status.contains("Balancing") || widget.status.contains("Processing")) {
      progress = 0.75;
      icon = Icons.restaurant_menu_outlined;
      subText = "Selecting top-rated spots and hidden gems...";
    } else if (widget.status.contains("Finalizing")) {
      progress = 0.95;
      icon = Icons.auto_awesome_outlined;
      subText = "Wrapping up your perfect itinerary...";
    }

    return Scaffold(
      backgroundColor: Colors.transparent,
      body: Stack(
        children: [
          // Glassmorphism Background
          Positioned.fill(
            child: BackdropFilter(
              filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
              child: Container(
                decoration: BoxDecoration(
                  color: Colors.white.withOpacity(0.85),
                ),
              ),
            ),
          ),
          
          // Animated Background Elements (Gradient Shimmer)
          Positioned.fill(
            child: Opacity(
              opacity: 0.1,
              child: DecoratedBox(
                decoration: BoxDecoration(
                  gradient: RadialGradient(
                    colors: [Colors.blue.shade300, Colors.purple.shade300, Colors.transparent],
                    center: const Alignment(0.5, -0.3),
                    radius: 1.5,
                  ),
                ),
              ),
            ),
          ),

          Center(
            child: SingleChildScrollView(
              padding: const EdgeInsets.symmetric(horizontal: 40, vertical: 80),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  // Animated Icon
                  ScaleTransition(
                    scale: _pulseAnimation,
                    child: Container(
                      width: 100,
                      height: 100,
                      decoration: BoxDecoration(
                        color: Colors.blue.shade50,
                        shape: BoxShape.circle,
                        boxShadow: [
                          BoxShadow(
                            color: Colors.blue.withOpacity(0.1),
                            blurRadius: 20,
                            spreadRadius: 10,
                          ),
                        ],
                      ),
                      child: Icon(
                        icon,
                        size: 48,
                        color: Colors.blue.shade700,
                      ),
                    ),
                  ),
                  const SizedBox(height: 48),
                  
                  // Status Text
                  AnimatedSwitcher(
                    duration: const Duration(milliseconds: 500),
                    child: Column(
                      key: ValueKey(mainText),
                      children: [
                        Text(
                          mainText,
                          textAlign: TextAlign.center,
                          style: const TextStyle(
                            fontSize: 22,
                            fontWeight: FontWeight.bold,
                            color: Colors.black87,
                            letterSpacing: -0.5,
                          ),
                        ),
                        const SizedBox(height: 12),
                        Text(
                          subText,
                          textAlign: TextAlign.center,
                          style: TextStyle(
                            fontSize: 14,
                            color: Colors.grey.shade600,
                            height: 1.5,
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 48),
                  
                  // Progress Bar
                  Column(
                    children: [
                      ClipRRect(
                        borderRadius: BorderRadius.circular(10),
                        child: TweenAnimationBuilder<double>(
                          tween: Tween<double>(begin: 0, end: progress),
                          duration: const Duration(milliseconds: 800),
                          builder: (context, value, _) {
                            return LinearProgressIndicator(
                              value: value,
                              minHeight: 8,
                              backgroundColor: Colors.blue.shade50,
                              valueColor: AlwaysStoppedAnimation<Color>(Colors.blue.shade600),
                            );
                          },
                        ),
                      ),
                      const SizedBox(height: 16),
                      Text(
                        "${(progress * 100).toInt()}% Done",
                        style: TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.bold,
                          color: Colors.blue.shade700,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
          
          // Motivational Quote / Tips at bottom
          Positioned(
            bottom: 60,
            left: 40,
            right: 40,
            child: FadeInTransition(
              child: Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: Colors.blue.shade50),
                ),
                child: Row(
                  children: [
                    Icon(Icons.tips_and_updates_outlined, color: Colors.amber.shade700, size: 20),
                    const SizedBox(width: 12),
                    const Expanded(
                      child: Text(
                        "Did you know? Walking through the city is often the best way to find hidden gems.",
                        style: TextStyle(fontSize: 12, color: Colors.black54),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class FadeInTransition extends StatefulWidget {
  final Widget child;
  const FadeInTransition({super.key, required this.child});

  @override
  State<FadeInTransition> createState() => _FadeInTransitionState();
}

class _FadeInTransitionState extends State<FadeInTransition> with SingleTickerProviderStateMixin {
  late AnimationController _fadeController;
  late Animation<double> _fadeAnimation;

  @override
  void initState() {
    super.initState();
    _fadeController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 1),
    );
    _fadeAnimation = CurvedAnimation(parent: _fadeController, curve: Curves.easeIn);
    _fadeController.forward();
  }

  @override
  void dispose() {
    _fadeController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return FadeTransition(opacity: _fadeAnimation, child: widget.child);
  }
}
