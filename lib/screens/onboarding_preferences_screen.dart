import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../services/auth_service.dart';
import 'home_screen.dart';

class OnboardingPreferencesScreen extends StatefulWidget {
  final String name;
  final String country;

  const OnboardingPreferencesScreen({
    super.key,
    required this.name,
    required this.country,
  });

  @override
  State<OnboardingPreferencesScreen> createState() => _OnboardingPreferencesScreenState();
}

class _OnboardingPreferencesScreenState extends State<OnboardingPreferencesScreen> {
  String? _selectedBudget;
  String? _selectedVibe;
  bool _isSaving = false;

  final List<String> _budgetOptions = ['Budget', 'Mid-Range', 'Luxury'];
  final List<String> _vibeOptions = ['Chill', 'Adventure', 'Party'];

  Future<void> _finish() async {
    if (_selectedBudget == null || _selectedVibe == null) return;

    setState(() => _isSaving = true);
    
    try {
      // Pass data to service
      // We await this to ensure data is saved before moving on.
      // Optimistic UI causes issues if save fails silently (e.g. permissions).
      await Provider.of<AuthService>(context, listen: false).saveUserProfile(
        country: widget.country,
        budgetStyle: _selectedBudget!,
        tripVibe: _selectedVibe!,
        displayName: widget.name,
      );

      // Force navigation to Home and clear stack
      if (mounted) {
         Navigator.of(context).pushAndRemoveUntil(
           MaterialPageRoute(builder: (_) => const HomeScreen()), 
           (route) => false
         );
      }

    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("Error saving profile: $e")),
      );
    } finally {
      if (mounted) setState(() => _isSaving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text("Travel Style")),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              "How do you like to travel?",
              style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 8),
            const Text("Don't worry, you can change this per trip."),
            
            const SizedBox(height: 32),
            const Text("Typical Budget", style: TextStyle(fontWeight: FontWeight.w600, fontSize: 18)),
            const SizedBox(height: 12),
            Wrap(
              spacing: 12,
              children: _budgetOptions.map((option) {
                final isSelected = _selectedBudget == option;
                return ChoiceChip(
                  label: Text(option),
                  selected: isSelected,
                  onSelected: (selected) {
                    setState(() => _selectedBudget = selected ? option : null);
                  },
                );
              }).toList(),
            ),

            const SizedBox(height: 32),
            const Text("Typical Vibe", style: TextStyle(fontWeight: FontWeight.w600, fontSize: 18)),
            const SizedBox(height: 12),
            Wrap(
              spacing: 12,
              children: _vibeOptions.map((option) {
                final isSelected = _selectedVibe == option;
                return ChoiceChip(
                  label: Text(option),
                  selected: isSelected,
                  onSelected: (selected) {
                    setState(() => _selectedVibe = selected ? option : null);
                  },
                );
              }).toList(),
            ),

            const SizedBox(height: 48),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: _isSaving ? null : _finish,
                style: ElevatedButton.styleFrom(
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  backgroundColor: Colors.blueAccent,
                  foregroundColor: Colors.white,
                ),
                child: _isSaving 
                  ? const SizedBox(width: 24, height: 24, child: CircularProgressIndicator(color: Colors.white))
                  : const Text("Complete Profile"),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
