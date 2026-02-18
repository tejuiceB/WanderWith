import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import 'package:wander_with/screens/home_screen.dart';
import 'package:wander_with/services/auth_service.dart';

class FeatureWalkthroughScreen extends StatefulWidget {
  final Map<String, dynamic> onboardingData;
  const FeatureWalkthroughScreen({super.key, required this.onboardingData});

  @override
  State<FeatureWalkthroughScreen> createState() => _FeatureWalkthroughScreenState();
}

class _FeatureWalkthroughScreenState extends State<FeatureWalkthroughScreen> {
  final PageController _pageController = PageController();
  int _currentPage = 0;
  bool _isSaving = false;

  final List<Map<String, String>> _features = [
    {
      'title': 'Plan Trips Together',
      'body': 'Create trips, invite friends, and coordinate dates and places in real-time.',
      'icon': 'trip', 
    },
    {
      'title': 'Manage Budget & Expenses',
      'body': 'Track costs, split bills, and vote on budget options effortlessly.',
      'icon': 'money',
    },
    {
      'title': 'AI Travel Guide',
      'body': 'Get instant recommendations and local tips powered by Gemini AI.',
      'icon': 'ai',
    },
  ];

  IconData _getIcon(String key) {
    switch (key) {
      case 'trip': return Icons.map_outlined;
      case 'money': return Icons.attach_money;
      case 'ai': return Icons.auto_awesome;
      default: return Icons.star;
    }
  }

  Future<void> _finish() async {
    setState(() => _isSaving = true);
    try {
      final auth = Provider.of<AuthService>(context, listen: false);
      final d = widget.onboardingData;
      
      await auth.saveOnboardingData(
        role: d['role'],
        displayName: d['displayName'],
        bio: d['bio'],
        city: d['city'],
        interests: d['interests'],
        agencyName: d['agencyName'],
        contactPerson: d['contactPerson'],
        phone: d['phone'],
        officeLocation: d['officeLocation'],
        agencyDescription: d['agencyDescription'],
        website: d['website'],
        licenseNumber: d['licenseNumber'],
      );
      
      await auth.updatePrivacySettings(isPrivate: d['isPrivate']);

      if (mounted) {
        Navigator.pushAndRemoveUntil(
          context,
          MaterialPageRoute(builder: (_) => const HomeScreen()),
          (route) => false,
        );
      }
    } catch (e) {
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text("Error saving profile: $e")));
    } finally {
      if (mounted) setState(() => _isSaving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: SafeArea(
        child: Column(
          children: [
            Align(
               alignment: Alignment.topRight,
               child: TextButton(
                 onPressed: _isSaving ? null : _finish,
                 child: const Text("Skip"),
               ),
            ),
            Expanded(
              child: PageView.builder(
                controller: _pageController,
                itemCount: _features.length,
                onPageChanged: (idx) => setState(() => _currentPage = idx),
                itemBuilder: (context, index) {
                  final item = _features[index];
                  return Padding(
                    padding: const EdgeInsets.all(32.0),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Container(
                          padding: const EdgeInsets.all(32),
                          decoration: BoxDecoration(
                            color: Colors.blueAccent.withOpacity(0.1),
                            shape: BoxShape.circle,
                          ),
                          child: Icon(
                            _getIcon(item['icon']!),
                            size: 80,
                            color: Colors.blueAccent,
                          ),
                        ),
                        const SizedBox(height: 40),
                        Text(
                          item['title']!,
                          textAlign: TextAlign.center,
                          style: GoogleFonts.outfit(
                            fontSize: 28,
                            fontWeight: FontWeight.bold,
                            color: const Color(0xFF1A1A1A),
                          ),
                        ),
                        const SizedBox(height: 16),
                        Text(
                          item['body']!,
                          textAlign: TextAlign.center,
                          style: GoogleFonts.inter(
                            fontSize: 16,
                            color: Colors.grey[600],
                            height: 1.5,
                          ),
                        ),
                      ],
                    ),
                  );
                },
              ),
            ),
            
            // Indicators
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: List.generate(_features.length, (index) {
                return AnimatedContainer(
                  duration: const Duration(milliseconds: 300),
                  margin: const EdgeInsets.symmetric(horizontal: 4),
                  height: 8,
                  width: _currentPage == index ? 24 : 8,
                  decoration: BoxDecoration(
                    color: _currentPage == index ? Colors.blueAccent : Colors.grey[300],
                    borderRadius: BorderRadius.circular(4),
                  ),
                );
              }),
            ),
            
            const SizedBox(height: 32),
            
            Padding(
              padding: const EdgeInsets.all(24.0),
              child: SizedBox(
                width: double.infinity,
                height: 56,
                child: ElevatedButton(
                  onPressed: _isSaving ? null : () {
                    if (_currentPage < _features.length - 1) {
                      _pageController.nextPage(
                        duration: const Duration(milliseconds: 300),
                        curve: Curves.easeInOut,
                      );
                    } else {
                      _finish();
                    }
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.blueAccent,
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                  ),
                  child: _isSaving 
                    ? const SizedBox(width: 24, height: 24, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2))
                    : Text(
                        _currentPage == _features.length - 1 ? 'Go to Home' : 'Next',
                        style: GoogleFonts.inter(fontSize: 18, fontWeight: FontWeight.w600),
                      ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
