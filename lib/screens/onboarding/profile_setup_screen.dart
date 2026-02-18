import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import 'package:wander_with/services/auth_service.dart';
import 'privacy_setup_screen.dart';

class ProfileSetupScreen extends StatefulWidget {
  final String role; // 'traveler' or 'agency'

  const ProfileSetupScreen({super.key, required this.role});

  @override
  State<ProfileSetupScreen> createState() => _ProfileSetupScreenState();
}

class _ProfileSetupScreenState extends State<ProfileSetupScreen> {
  final _formKey = GlobalKey<FormState>();
  
  // Common Fields
  final TextEditingController _nameController = TextEditingController();
  final TextEditingController _bioController = TextEditingController();
  final TextEditingController _locationController = TextEditingController();
  
  // Traveler Fields
  final List<String> _interests = [];
  final List<String> _availableInterests = [
    'Trekking', 'Luxury', 'Backpacking', 'Solo', 'Cultural', 'Adventure', 'Foodie', 'Nature'
  ];

  // Agency Fields
  final TextEditingController _contactPersonController = TextEditingController();
  final TextEditingController _phoneController = TextEditingController();
  final TextEditingController _emailController = TextEditingController(); // Business Email
  final TextEditingController _websiteController = TextEditingController();
  final TextEditingController _licenseController = TextEditingController();

  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    // Pre-fill name from Auth if available
    final auth = Provider.of<AuthService>(context, listen: false);
    if (auth.user?.userMetadata?['full_name'] != null) {
      _nameController.text = auth.user!.userMetadata!['full_name'];
    }
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;
    
    setState(() => _isLoading = true);

    try {
      final auth = Provider.of<AuthService>(context, listen: false);
      
      // Pass data to next screen instead of saving immediately
      final onboardingData = {
        'role': widget.role,
        'displayName': _nameController.text,
        'bio': _bioController.text,
        'city': _locationController.text,
        'interests': _interests,
        'agencyName': widget.role == 'agency' ? _nameController.text : null,
        'contactPerson': _contactPersonController.text,
        'phone': _phoneController.text,
        'officeLocation': _locationController.text,
        'agencyDescription': widget.role == 'agency' ? _bioController.text : null,
        'website': _websiteController.text,
        'licenseNumber': _licenseController.text,
      };

      if (mounted) {
         Navigator.push(
            context,
            MaterialPageRoute(
               builder: (_) => PrivacySetupScreen(
                 role: widget.role,
                 previousData: onboardingData,
               ),
            )
         );
      }

    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text("Error: $e")));
      }
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final isAgency = widget.role == 'agency';

    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        title: Text(isAgency ? 'Agency Setup' : 'Create Profile'),
        surfaceTintColor: Colors.transparent,
      ),
      body: SafeArea(
        child: Form(
          key: _formKey,
          child: ListView(
            padding: const EdgeInsets.all(24),
            children: [
              Text(
                'Tell us about ${isAgency ? "your agency" : "yourself"}.',
                style: GoogleFonts.outfit(fontSize: 24, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 24),
              
              // --- COMMON / TRAVELER NAME ---
              TextFormField(
                controller: _nameController,
                decoration: InputDecoration(
                  labelText: isAgency ? 'Agency Name' : 'Full Name',
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                  prefixIcon: Icon(isAgency ? Icons.business : Icons.person),
                ),
                validator: (v) => v!.isEmpty ? 'Required' : null,
              ),
              const SizedBox(height: 16),
              
              // --- AGENCY SPECIFIC: CONTACT PERSON ---
              if (isAgency) ...[
                TextFormField(
                  controller: _contactPersonController,
                  decoration: InputDecoration(
                    labelText: 'Contact Person Name',
                    border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                    prefixIcon: const Icon(Icons.person_pin),
                  ),
                   validator: (v) => v!.isEmpty ? 'Required' : null,
                ),
                const SizedBox(height: 16),
                
                TextFormField(
                  controller: _phoneController,
                  keyboardType: TextInputType.phone,
                  decoration: InputDecoration(
                    labelText: 'Phone Number',
                    border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                    prefixIcon: const Icon(Icons.phone),
                  ),
                   validator: (v) => v!.isEmpty ? 'Required' : null,
                ),
                const SizedBox(height: 16),
              ],

              // --- LOCATION ---
              TextFormField(
                controller: _locationController,
                decoration: InputDecoration(
                  labelText: isAgency ? 'Office Location (City/Country)' : 'City/Country',
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                  prefixIcon: const Icon(Icons.location_on),
                  hintText: 'e.g. New York, USA',
                ),
                validator: (v) => v!.isEmpty ? 'Required' : null,
              ),
              const SizedBox(height: 16),

              // --- BIO ---
              TextFormField(
                controller: _bioController,
                maxLines: 3,
                decoration: InputDecoration(
                  labelText: isAgency ? 'Agency Description' : 'Bio',
                  alignLabelWithHint: true,
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                  hintText: isAgency ? 'Describe your services...' : 'What kind of traveler are you?',
                ),
              ),
              const SizedBox(height: 16),

              // --- TRAVELER SPECIFIC: INTERESTS ---
              if (!isAgency) ...[
                Text('Interests', style: GoogleFonts.inter(fontWeight: FontWeight.w600)),
                const SizedBox(height: 8),
                Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: _availableInterests.map((interest) {
                    final selected = _interests.contains(interest);
                    return FilterChip(
                      label: Text(interest), 
                      selected: selected,
                      onSelected: (val) {
                        setState(() {
                          if (val) _interests.add(interest);
                          else _interests.remove(interest);
                        });
                      },
                      selectedColor: Colors.blueAccent.withOpacity(0.2),
                      checkmarkColor: Colors.blueAccent,
                    );
                  }).toList(),
                ),
                const SizedBox(height: 16),
              ],
              
              // --- AGENCY SPECIFIC: WEB & LICENSE ---
              if (isAgency) ...[
                 TextFormField(
                  controller: _websiteController,
                  decoration: InputDecoration(
                    labelText: 'Website (Optional)',
                    border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                    prefixIcon: const Icon(Icons.language),
                  ),
                ),
                const SizedBox(height: 16),
                 TextFormField(
                  controller: _licenseController,
                  decoration: InputDecoration(
                    labelText: 'License Number (Optional)',
                    border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                    prefixIcon: const Icon(Icons.verified_user),
                  ),
                ),
                const SizedBox(height: 16),
              ],

              const SizedBox(height: 24),
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
                    : const Text('Next: Privacy Settings', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
