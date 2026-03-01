import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import 'package:go_router/go_router.dart';
import '../services/auth_service.dart';
import '../services/trip_service.dart';
import '../theme/app_colors.dart';
import '../theme/theme_extensions.dart';

class JoinTripScreen extends StatefulWidget {
  final String initialCode;

  const JoinTripScreen({super.key, required this.initialCode});

  @override
  State<JoinTripScreen> createState() => _JoinTripScreenState();
}

class _JoinTripScreenState extends State<JoinTripScreen> {
  late TextEditingController _codeController;
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    print("JoinTripScreen initialized with code: ${widget.initialCode}");
    _codeController = TextEditingController(text: widget.initialCode);
  }

  @override
  void dispose() {
    _codeController.dispose();
    super.dispose();
  }

  Future<void> _handleJoin() async {
    final tripId = _codeController.text.trim();
    if (tripId.isEmpty) return;
    
    final uid = Provider.of<AuthService>(context, listen: false).user?.id;
    if (uid == null) {
      if (mounted) {
         ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("You need to be logged in to join a trip.")));
      }
      return;
    }

    setState(() => _isLoading = true);
    try {
      await TripService().joinTrip(tripId, uid);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(
          content: const Text("Join request sent! Waiting for approval. \u{1F392}"),
          backgroundColor: AppColors.brand,
        ));
        // Bounce back to home screen after successfully joining
        context.go('/');
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text("Error: ${e.toString()}")));
      }
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: context.appColors.scaffoldBg,
      appBar: AppBar(
        backgroundColor: context.appColors.scaffoldBg,
        elevation: 0,
        leading: IconButton(
          icon: Icon(Icons.close, color: context.appColors.textPrimary),
          onPressed: () {
            // If they cancel out, jump to home so they aren't stuck on an empty stack
            if (context.canPop()) {
              context.pop();
            } else {
              context.go('/');
            }
          },
        ),
      ),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 24.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Icon(
                Icons.card_travel_outlined,
                size: 80,
                color: AppColors.brand,
              ),
              const SizedBox(height: 24),
              Text(
                "You've Been Invited!",
                textAlign: TextAlign.center,
                style: GoogleFonts.outfit(
                  fontSize: 28,
                  fontWeight: FontWeight.bold,
                  color: context.appColors.textPrimary,
                ),
              ),
              const SizedBox(height: 12),
              Text(
                "Review the trip code below and click Join to request access.",
                textAlign: TextAlign.center,
                style: GoogleFonts.inter(
                  fontSize: 16,
                  color: context.appColors.textSecondary,
                  height: 1.5,
                ),
              ),
              const SizedBox(height: 48),
              TextField(
                controller: _codeController,
                textAlign: TextAlign.center,
                style: GoogleFonts.outfit(
                  fontSize: 22,
                  fontWeight: FontWeight.w600,
                  letterSpacing: 2.0,
                ),
                decoration: InputDecoration(
                  labelText: "Trip Code",
                  floatingLabelAlignment: FloatingLabelAlignment.center,
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(16),
                    borderSide: BorderSide(color: context.appColors.border),
                  ),
                  focusedBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(16),
                    borderSide: BorderSide(color: AppColors.brand, width: 2),
                  ),
                  filled: true,
                  fillColor: context.appColors.fieldFillBg,
                ),
              ),
              const SizedBox(height: 32),
              if (_isLoading)
                const Center(child: CircularProgressIndicator())
              else
                ElevatedButton(
                  onPressed: _handleJoin,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.brand,
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    elevation: 0,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(16),
                    ),
                  ),
                  child: Text(
                    "Join Trip",
                    style: GoogleFonts.inter(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
               const SizedBox(height: 64),
            ],
          ),
        ),
      ),
    );
  }
}
