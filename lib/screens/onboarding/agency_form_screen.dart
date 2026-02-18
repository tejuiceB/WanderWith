import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:go_router/go_router.dart';
import '../../services/auth_service.dart';

class AgencyFormScreen extends StatefulWidget {
  const AgencyFormScreen({super.key});

  @override
  State<AgencyFormScreen> createState() => _AgencyFormScreenState();
}

class _AgencyFormScreenState extends State<AgencyFormScreen> {
  final _formKey = GlobalKey<FormState>();
  final _agencyNameController = TextEditingController();
  final _usernameController = TextEditingController();
  final _contactPersonController = TextEditingController();
  final _emailController = TextEditingController();
  final _locationController = TextEditingController();
  final _descriptionController = TextEditingController();
  bool _isLoading = false;

  @override
  void dispose() {
    _agencyNameController.dispose();
    _usernameController.dispose();
    _contactPersonController.dispose();
    _emailController.dispose();
    _locationController.dispose();
    _descriptionController.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isLoading = true);
    try {
      await AuthService.instance.saveOnboardingData(
        role: 'agency',
        displayName: _agencyNameController.text.trim(),
        username: _usernameController.text.trim(),
        agencyName: _agencyNameController.text.trim(),
        contactPerson: _contactPersonController.text.trim(),
        // Note: phone, license etc can be added if needed, but keeping it clean per user request
        officeLocation: _locationController.text.trim(),
        agencyDescription: _descriptionController.text.trim(),
      );
      
      if (mounted) context.go('/');
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error: ${e.toString()}')),
      );
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new, color: Colors.black),
          onPressed: () => context.pop(),
        ),
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 24.0),
          child: Form(
            key: _formKey,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Register your Agency 🏢',
                  style: GoogleFonts.outfit(
                    fontSize: 28,
                    fontWeight: FontWeight.bold,
                    color: Colors.black,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  'Grow your business with WanderWith.',
                  style: GoogleFonts.inter(
                    fontSize: 16,
                    color: Colors.grey[600],
                  ),
                ),
                const SizedBox(height: 32),
                
                _buildFieldLabel('Agency Name'),
                TextFormField(
                  controller: _agencyNameController,
                  style: GoogleFonts.inter(fontSize: 16),
                  decoration: _inputDecoration('Legal Agency Name'),
                  validator: (v) => v == null || v.isEmpty ? 'Please enter agency name' : null,
                ),
                const SizedBox(height: 20),

                _buildFieldLabel('Agency Handle (Username)'),
                TextFormField(
                  controller: _usernameController,
                  style: GoogleFonts.inter(fontSize: 16),
                  decoration: _inputDecoration('@username'),
                  validator: (v) {
                    if (v == null || v.isEmpty) return 'Please enter a username';
                    if (v.length < 3) return 'Username too short';
                    if (!RegExp(r'^[a-zA-Z0-9._]+$').hasMatch(v)) return 'Invalid characters';
                    return null;
                  },
                ),
                const SizedBox(height: 20),

                _buildFieldLabel('Contact Person'),
                TextFormField(
                  controller: _contactPersonController,
                  style: GoogleFonts.inter(fontSize: 16),
                  decoration: _inputDecoration('First and Last Name'),
                  validator: (v) => v == null || v.isEmpty ? 'Please enter contact person' : null,
                ),
                const SizedBox(height: 20),

                _buildFieldLabel('Agency Location'),
                TextFormField(
                  controller: _locationController,
                  style: GoogleFonts.inter(fontSize: 16),
                  decoration: _inputDecoration('HQ City/Country'),
                  validator: (v) => v == null || v.isEmpty ? 'Please enter location' : null,
                ),
                const SizedBox(height: 20),

                _buildFieldLabel('Short Description'),
                TextFormField(
                  controller: _descriptionController,
                  maxLines: 3,
                  style: GoogleFonts.inter(fontSize: 16),
                  decoration: _inputDecoration('Tell us about your services...'),
                  validator: (v) => v == null || v.isEmpty ? 'Please enter description' : null,
                ),
                const SizedBox(height: 40),

                SizedBox(
                  width: double.infinity,
                  height: 56,
                  child: ElevatedButton(
                    onPressed: _isLoading ? null : _submit,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.blueAccent,
                      foregroundColor: Colors.white,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(16),
                      ),
                      elevation: 0,
                    ),
                    child: _isLoading 
                      ? const CircularProgressIndicator(color: Colors.white)
                      : Text(
                          'Register Agency',
                          style: GoogleFonts.outfit(
                            fontSize: 18,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                  ),
                ),
                const SizedBox(height: 24),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildFieldLabel(String label) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8.0),
      child: Text(
        label,
        style: GoogleFonts.inter(
          fontSize: 14,
          fontWeight: FontWeight.w600,
          color: Colors.grey[700],
        ),
      ),
    );
  }

  InputDecoration _inputDecoration(String hint) {
    return InputDecoration(
      hintText: hint,
      hintStyle: GoogleFonts.inter(color: Colors.grey[400]),
      filled: true,
      fillColor: Colors.grey.shade50,
      contentPadding: const EdgeInsets.all(16),
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: BorderSide(color: Colors.grey.shade200),
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: BorderSide(color: Colors.grey.shade200),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: const BorderSide(color: Colors.blueAccent, width: 2),
      ),
    );
  }
}
