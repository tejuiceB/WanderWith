import 'package:flutter/material.dart';

class SplashScreen extends StatefulWidget {
  final VoidCallback onFinish;
  const SplashScreen({super.key, required this.onFinish});

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen> {
  @override
  void initState() {
    super.initState();
    // Simulate Instagram-like delay (e.g. 2 seconds)
    // In real apps, we often wait for initialization here too.
    Future.delayed(const Duration(seconds: 2), () {
        if (mounted) widget.onFinish();
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
             // Logo
             Image.asset('android/assets/logo.png', width: 100, height: 100),
             const SizedBox(height: 16),
             // App Name
             const Text(
               "WanderWith",
               style: TextStyle(
                 fontSize: 28,
                 fontWeight: FontWeight.bold,
                 color: Colors.black,
                 fontFamily: 'Roboto', // Default to clean san-serif
               ),
             ),
          ],
        ),
      ),
      bottomNavigationBar: const Padding(
        padding: EdgeInsets.only(bottom: 40.0),
        child: Text(
          "One trip. One plan. Everyone synced.",
          textAlign: TextAlign.center,
          style: TextStyle(
            color: Colors.grey, 
            fontSize: 14,
            fontWeight: FontWeight.w500
          ),
        ),
      ),
    );
  }
}
