import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import 'package:wander_with/services/auth_service.dart';
import 'feature_walkthrough_screen.dart';

class PrivacySetupScreen extends StatefulWidget {
  final String role;
  final Map<String, dynamic> previousData;
  
  const PrivacySetupScreen({
    super.key, 
    required this.role,
    required this.previousData,
  });

  @override
  State<PrivacySetupScreen> createState() => _PrivacySetupScreenState();
}

class _PrivacySetupScreenState extends State<PrivacySetupScreen> {
  late bool _isPrivate;
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    // Default: Traveler = Private (true), Agency = Public (false)
    _isPrivate = widget.role == 'traveler';
  }

  Future<void> _submit() async {
    // Pass everything to Walkthrough
    final allData = Map<String, dynamic>.from(widget.previousData);
    allData['isPrivate'] = _isPrivate;

    if (mounted) {
       Navigator.pushAndRemoveUntil(
          context,
          MaterialPageRoute(builder: (_) => FeatureWalkthroughScreen(onboardingData: allData)),
          (route) => false,
       );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(24.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Privacy Settings',
                style: GoogleFonts.outfit(
                  fontSize: 32,
                  fontWeight: FontWeight.bold,
                  color: const Color(0xFF1A1A1A),
                ),
              ),
              const SizedBox(height: 16),
              Text(
                'Control who sees your profile and trips.',
                style: GoogleFonts.inter(fontSize: 16, color: Colors.grey[600]),
              ),
              const SizedBox(height: 48),
              
              // Privacy Card
              Container(
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  color: Colors.grey[50],
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(color: Colors.grey[200]!),
                ),
                child: Column(
                  children: [
                    Row(
                      children: [
                        Icon(
                          _isPrivate ? Icons.lock : Icons.public,
                          size: 32,
                          color: _isPrivate ? Colors.teal : Colors.blueAccent,
                        ),
                        const SizedBox(width: 16),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                _isPrivate ? 'Private Profile' : 'Public Profile',
                                style: GoogleFonts.inter(fontSize: 18, fontWeight: FontWeight.w600),
                              ),
                              const SizedBox(height: 4),
                              Text(
                                _isPrivate 
                                  ? 'Only followers can see your posts and trips.' 
                                  : 'Anyone can see your profile and public trips.',
                                style: GoogleFonts.inter(fontSize: 14, color: Colors.grey[600]),
                              ),
                            ],
                          ),
                        ),
                        Switch(
                          value: _isPrivate,
                          onChanged: (val) {
                             if (widget.role == 'agency' && val == true) {
                               // Warn agency about being private?
                               ScaffoldMessenger.of(context).showSnackBar(
                                 const SnackBar(content: Text("Agencies are recommended to be Public to get clients."))
                               );
                             }
                             setState(() => _isPrivate = val);
                          },
                          activeColor: Colors.teal,
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              
              const Spacer(),
              
              SizedBox(
                width: double.infinity,
                height: 56,
                child: ElevatedButton(
                  onPressed: _isLoading ? null : _submit,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.blueAccent,
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                  ),
                  child: _isLoading 
                    ? const CircularProgressIndicator(color: Colors.white)
                    : const Text('Finish Setup', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
