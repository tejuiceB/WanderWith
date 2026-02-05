import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../services/auth_service.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  bool _isLoading = false;

  void _handleGoogleSignIn(BuildContext context) async {
    setState(() => _isLoading = true);
    try {
      final authService = Provider.of<AuthService>(context, listen: false);
      await authService.signInWithGoogle();
      // Navigation is handled by the wrapper in main.dart based on auth state
    } catch (e) {
      if (!mounted) return;
      
      String errorMsg = 'Sign in failed';
      final eStr = e.toString().toLowerCase();
      if (eStr.contains('network_error') || eStr.contains('network') || eStr.contains('socket')) {
         errorMsg = 'No internet connection. Please check your network settings.';
      } else {
         errorMsg = 'Sign in failed: ${e.toString().replaceAll("Exception:", "").trim()}';
      }

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(errorMsg)),
      );
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 32.0),
          child: SizedBox(
            width: double.infinity,
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                const Spacer(),
                // Logo
              ClipRRect(
                borderRadius: BorderRadius.circular(20), // Slight round for modern look
                child: Image.asset('android/assets/logo.png', width: 120, height: 120),
              ),
              const SizedBox(height: 32),
              const Text(
                'WanderWith',
                style: TextStyle(
                  fontSize: 36,
                  fontWeight: FontWeight.bold,
                  color: Colors.black87,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                'One trip. One plan. Everyone synced.',
                textAlign: TextAlign.center,
                style: TextStyle(fontSize: 16, color: Colors.grey[600]),
              ),
              const Spacer(), 
              
              if (_isLoading)
                const CircularProgressIndicator()
              else
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton.icon(
                    onPressed: () => _handleGoogleSignIn(context),
                    icon: Padding(
                      padding: const EdgeInsets.only(right: 12.0),
                      // Ideally use a Google Logo asset here
                      child: Icon(Icons.login, color: Colors.grey[800]), 
                    ), 
                    label: const Text('Continue with Google', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600)),
                    style: ElevatedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(vertical: 16),
                      backgroundColor: Colors.white,
                      foregroundColor: Colors.black87,
                      elevation: 1,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                        side: BorderSide(color: Colors.grey.shade300),
                      ),
                    ),
                  ),
                ),
              const SizedBox(height: 48),
            ],
          ),
        ),
      ),
      ),
    );
  }
}
