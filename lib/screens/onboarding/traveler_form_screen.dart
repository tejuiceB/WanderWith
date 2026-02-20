import 'dart:async';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:go_router/go_router.dart';
import '../../services/auth_service.dart';

class TravelerFormScreen extends StatefulWidget {
  const TravelerFormScreen({super.key});

  @override
  State<TravelerFormScreen> createState() => _TravelerFormScreenState();
}

class _TravelerFormScreenState extends State<TravelerFormScreen> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _usernameController = TextEditingController();
  final _bioController = TextEditingController();
  final _locationController = TextEditingController();
  final _interestController = TextEditingController();
  List<String> _selectedInterests = [];
  bool _isLoading = false;
  
  // Username check
  bool? _isUsernameAvailable;
  bool _checkingUsername = false;
  Timer? _debounce;

  @override
  void initState() {
    super.initState();
    _usernameController.addListener(_onUsernameChanged);
  }

  void _onUsernameChanged() {
    if (_debounce?.isActive ?? false) _debounce!.cancel();
    
    final username = _usernameController.text.trim();
    if (username.length < 3) {
      setState(() {
        _isUsernameAvailable = null;
        _checkingUsername = false;
      });
      return;
    }

    setState(() => _checkingUsername = true);
    
    _debounce = Timer(const Duration(milliseconds: 500), () async {
      final available = await AuthService.instance.isUsernameAvailable(username);
      if (mounted && _usernameController.text.trim() == username) {
        setState(() {
          _isUsernameAvailable = available;
          _checkingUsername = false;
        });
      }
    });
  }

  @override
  void dispose() {
    _debounce?.cancel();
    _usernameController.removeListener(_onUsernameChanged);
    _nameController.dispose();
    _usernameController.dispose();
    _bioController.dispose();
    _locationController.dispose();
    _interestController.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isLoading = true);
    try {
      final authService = AuthService.instance;
      final locationString = _locationController.text.trim();
      
      // Perform Geocoding
      final geoData = await authService.geocodeLocation(locationString);
      
      await authService.saveOnboardingData(
        role: 'traveler',
        displayName: _nameController.text.trim(),
        username: _usernameController.text.trim(),
        bio: _bioController.text.trim(),
        city: geoData?['city'] ?? locationString,
        country: geoData?['country'],
        latitude: geoData?['latitude'],
        longitude: geoData?['longitude'],
        interests: _selectedInterests,
      );
      
      // Navigate to Home - GoRouter RefreshListenable will catch this
      if (mounted) context.go('/');
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error: ${e.toString()}')),
        );
      }
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
                  'Set up your profile 🎒',
                  style: GoogleFonts.outfit(
                    fontSize: 28,
                    fontWeight: FontWeight.bold,
                    color: Colors.black,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  'Tell the community a bit about yourself.',
                  style: GoogleFonts.inter(
                    fontSize: 16,
                    color: Colors.grey[600],
                  ),
                ),
                const SizedBox(height: 32),
                
                _buildFieldLabel('Full Name'),
                TextFormField(
                  controller: _nameController,
                  style: GoogleFonts.inter(fontSize: 16),
                  decoration: _inputDecoration('e.g. John Doe'),
                  validator: (v) => v == null || v.isEmpty ? 'Please enter your name' : null,
                ),
                const SizedBox(height: 20),

                _buildFieldLabel('Username'),
                TextFormField(
                  controller: _usernameController,
                  style: GoogleFonts.inter(fontSize: 16),
                  decoration: _inputDecoration('e.g. john_travels').copyWith(
                    suffixIcon: _checkingUsername 
                        ? const SizedBox(width: 20, height: 20, child: Padding(padding: EdgeInsets.all(12), child: CircularProgressIndicator(strokeWidth: 2)))
                        : _isUsernameAvailable != null 
                            ? Icon(_isUsernameAvailable! ? Icons.check_circle : Icons.error, color: _isUsernameAvailable! ? Colors.green : Colors.red)
                            : null,
                  ),
                  validator: (v) {
                    if (v == null || v.isEmpty) return 'Please enter a username';
                    if (v.trim().length < 3) return 'Username must be at least 3 characters';
                    if (!RegExp(r'^[a-zA-Z0-9._]+$').hasMatch(v)) return 'Invalid characters (use a-z, 0-9, . , _)';
                    if (_isUsernameAvailable == false) return 'This username is already taken';
                    return null;
                  },
                ),
                if (_isUsernameAvailable == false)
                  Padding(
                    padding: const EdgeInsets.only(top: 8.0, left: 4),
                    child: Text(
                      'This username is already taken. Try another one!',
                      style: GoogleFonts.inter(fontSize: 12, color: Colors.red),
                    ),
                  ),
                const SizedBox(height: 20),

                _buildFieldLabel('Location'),
                TextFormField(
                  controller: _locationController,
                  style: GoogleFonts.inter(fontSize: 16),
                  decoration: _inputDecoration('e.g. New York, USA'),
                  validator: (v) => v == null || v.isEmpty ? 'Please enter your location' : null,
                ),
                const SizedBox(height: 20),

                _buildFieldLabel('Bio (Optional)'),
                TextFormField(
                  controller: _bioController,
                  maxLines: 3,
                  style: GoogleFonts.inter(fontSize: 16),
                  decoration: _inputDecoration('Tell us about your travel style...'),
                ),
                const SizedBox(height: 20),

                _buildFieldLabel('Interests / Travel Style'),
                TextFormField(
                  controller: _interestController,
                  style: GoogleFonts.inter(fontSize: 16),
                  decoration: _inputDecoration('e.g. Hiking, Photography (Press Enter)').copyWith(
                    suffixIcon: IconButton(
                      icon: const Icon(Icons.add),
                      onPressed: () {
                        final text = _interestController.text.trim();
                        if (text.isNotEmpty && !_selectedInterests.contains(text)) {
                          setState(() {
                            _selectedInterests.add(text);
                            _interestController.clear();
                          });
                        }
                      },
                    ),
                  ),
                  onFieldSubmitted: (text) {
                    if (text.trim().isNotEmpty && !_selectedInterests.contains(text.trim())) {
                      setState(() {
                        _selectedInterests.add(text.trim());
                        _interestController.clear();
                      });
                    }
                  },
                ),
                if (_selectedInterests.isNotEmpty)
                  Padding(
                    padding: const EdgeInsets.only(top: 12.0),
                    child: Wrap(
                      spacing: 8,
                      runSpacing: 8,
                      children: _selectedInterests.map((interest) {
                        return Chip(
                          label: Text(interest, style: GoogleFonts.inter(fontSize: 12)),
                          backgroundColor: Colors.blue.shade50,
                          side: BorderSide.none,
                          deleteIcon: const Icon(Icons.close, size: 14),
                          onDeleted: () {
                            setState(() => _selectedInterests.remove(interest));
                          },
                        );
                      }).toList(),
                    ),
                  ),
                const SizedBox(height: 40),

                SizedBox(
                  width: double.infinity,
                  height: 56,
                  child: ElevatedButton(
                    onPressed: _isLoading ? null : _submit,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.black,
                      foregroundColor: Colors.white,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(16),
                      ),
                      elevation: 0,
                    ),
                    child: _isLoading 
                      ? const CircularProgressIndicator(color: Colors.white)
                      : Text(
                          'Complete Setup',
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
