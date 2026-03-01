import 'dart:io';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:go_router/go_router.dart';
import '../../services/auth_service.dart';
import '../../theme/app_colors.dart';
import '../../theme/theme_extensions.dart';
import 'widgets/onboarding_progress_bar.dart';
import 'steps/role_step.dart';
import 'steps/basic_info_step.dart';
import 'steps/location_step.dart';
import 'steps/traveler_interests_step.dart';
import 'steps/agency_details_step.dart';
import 'steps/agency_specializations_step.dart';
import 'steps/privacy_step.dart';
import 'steps/review_step.dart';

class OnboardingWizardScreen extends StatefulWidget {
  const OnboardingWizardScreen({super.key});

  @override
  State<OnboardingWizardScreen> createState() => _OnboardingWizardScreenState();
}

class _OnboardingWizardScreenState extends State<OnboardingWizardScreen> {
  final PageController _pageController = PageController();
  int _currentPage = 0;
  bool _isSaving = false;

  // --- Shared data ---
  String? _role;

  // Basic info
  final _nameController = TextEditingController();
  final _usernameController = TextEditingController();
  final _bioController = TextEditingController();
  File? _avatarFile;
  bool _isUsernameAvailable = false;
  bool _isCheckingUsername = false;

  // Location
  final _cityController = TextEditingController();
  double? _latitude;
  double? _longitude;
  String? _country;

  // Traveler interests
  List<String> _selectedInterests = [];

  // Agency details
  final _agencyNameController = TextEditingController();
  final _contactPersonController = TextEditingController();
  final _phoneController = TextEditingController();
  final _descriptionController = TextEditingController();
  final _websiteController = TextEditingController();
  final _licenseController = TextEditingController();
  final _yearController = TextEditingController();
  List<String> _selectedSpecializations = [];

  // Privacy
  bool _isPrivate = true;

  @override
  void initState() {
    super.initState();
    // Pre-fill from existing profile if available (e.g. Google sign-in)
    final profile = AuthService.instance.userProfile;
    if (profile != null) {
      _nameController.text = profile.displayName ?? '';
      _usernameController.text = profile.username ?? '';
      _bioController.text = profile.bio ?? '';
    }

    // Listen to text changes so _canProceed re-evaluates and button updates
    _nameController.addListener(_onFieldChanged);
    _usernameController.addListener(_onFieldChanged);
    _cityController.addListener(_onFieldChanged);
    _agencyNameController.addListener(_onFieldChanged);
  }

  void _onFieldChanged() {
    setState(() {}); // Triggers _canProceed re-evaluation
  }

  @override
  void dispose() {
    _nameController.removeListener(_onFieldChanged);
    _usernameController.removeListener(_onFieldChanged);
    _cityController.removeListener(_onFieldChanged);
    _agencyNameController.removeListener(_onFieldChanged);
    _pageController.dispose();
    _nameController.dispose();
    _usernameController.dispose();
    _bioController.dispose();
    _cityController.dispose();
    _agencyNameController.dispose();
    _contactPersonController.dispose();
    _phoneController.dispose();
    _descriptionController.dispose();
    _websiteController.dispose();
    _licenseController.dispose();
    _yearController.dispose();
    super.dispose();
  }

  // --- Step definitions based on role ---
  List<_StepDef> get _steps {
    final isAgency = _role == 'agency';
    return [
      const _StepDef('Choose Role', 'ROLE'),
      const _StepDef('Basic Info', 'BASIC_INFO'),
      const _StepDef('Location', 'LOCATION'),
      if (!isAgency) const _StepDef('Interests', 'INTERESTS'),
      if (isAgency) const _StepDef('Agency Details', 'AGENCY_DETAILS'),
      if (isAgency) const _StepDef('Specializations', 'AGENCY_SPECS'),
      const _StepDef('Privacy', 'PRIVACY'),
      const _StepDef('Review', 'REVIEW'),
    ];
  }

  int get _totalSteps => _steps.length;

  String get _currentStepLabel {
    if (_currentPage < _steps.length) return _steps[_currentPage].label;
    return '';
  }

  // --- Navigation ---
  void _goNext() {
    if (_currentPage < _totalSteps - 1) {
      _pageController.nextPage(
        duration: const Duration(milliseconds: 350),
        curve: Curves.easeInOut,
      );
    }
  }

  void _goBack() {
    if (_currentPage > 0) {
      _pageController.previousPage(
        duration: const Duration(milliseconds: 350),
        curve: Curves.easeInOut,
      );
    }
  }

  // --- Validation per step ---
  bool get _canProceed {
    if (_currentPage >= _steps.length) return false;
    final stepId = _steps[_currentPage].id;

    switch (stepId) {
      case 'ROLE':
        return _role != null;
      case 'BASIC_INFO':
        return _nameController.text.trim().length >= 2 &&
            _usernameController.text.trim().length >= 3 &&
            _isUsernameAvailable;
      case 'LOCATION':
        return _cityController.text.trim().isNotEmpty;
      case 'INTERESTS':
        return _selectedInterests.length >= 3;
      case 'AGENCY_DETAILS':
        return _agencyNameController.text.trim().isNotEmpty;
      case 'AGENCY_SPECS':
        return true; // Optional
      case 'PRIVACY':
        return true; // Always valid — default set
      case 'REVIEW':
        return true;
      default:
        return false;
    }
  }

  bool get _isLastStep => _currentPage == _totalSteps - 1;

  // --- Save ---
  Future<void> _completeOnboarding() async {
    setState(() => _isSaving = true);

    try {
      final authService = AuthService.instance;

      // Upload avatar if picked
      if (_avatarFile != null) {
        await authService.updateAvatar(_avatarFile!);
      }

      // Geocode city if lat/lng not already set
      if (_latitude == null && _cityController.text.trim().isNotEmpty) {
        final geo = await authService.geocodeLocation(_cityController.text.trim());
        if (geo != null) {
          _latitude = geo['latitude'];
          _longitude = geo['longitude'];
          _country = geo['country'];
        }
      }

      await authService.saveOnboardingData(
        role: _role!,
        displayName: _nameController.text.trim(),
        username: _usernameController.text.trim().toLowerCase(),
        bio: _bioController.text.trim().isEmpty ? null : _bioController.text.trim(),
        city: _cityController.text.trim().isEmpty ? null : _cityController.text.trim(),
        interests: _role == 'traveler' ? _selectedInterests : null,
        latitude: _latitude,
        longitude: _longitude,
        country: _country,
        // Agency
        agencyName: _role == 'agency' ? _agencyNameController.text.trim() : null,
        contactPerson: _role == 'agency' ? _contactPersonController.text.trim() : null,
        phone: _role == 'agency' ? _phoneController.text.trim() : null,
        agencyDescription: _role == 'agency' ? _descriptionController.text.trim() : null,
        website: _role == 'agency' ? _websiteController.text.trim() : null,
        licenseNumber: _role == 'agency' ? _licenseController.text.trim() : null,
        yearEstablished: _role == 'agency' && _yearController.text.isNotEmpty
            ? int.tryParse(_yearController.text.trim())
            : null,
        specializations: _role == 'agency' ? _selectedSpecializations : null,
        isPrivate: _isPrivate,
      );

      // GoRouter redirect handles navigation to '/' automatically
      // (triggered by notifyListeners() inside saveOnboardingData).
      // Only navigate explicitly if still mounted (as a fallback).
      if (mounted) {
        // Small delay to let GoRouter redirect process first
        await Future.delayed(const Duration(milliseconds: 100));
        if (mounted) context.go('/');
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to save: $e'),
            backgroundColor: AppColors.error,
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    } finally {
      if (mounted) setState(() => _isSaving = false);
    }
  }

  // --- Build steps ---
  Widget _buildStep(String stepId) {
    switch (stepId) {
      case 'ROLE':
        return RoleStep(
          selectedRole: _role,
          onRoleSelected: (role) {
            setState(() {
              _role = role;
              // Reset page controller since step count changes with role
            });
            // Auto-advance after small delay
            Future.delayed(const Duration(milliseconds: 300), _goNext);
          },
        );
      case 'BASIC_INFO':
        return BasicInfoStep(
          nameController: _nameController,
          usernameController: _usernameController,
          bioController: _bioController,
          avatarFile: _avatarFile,
          onAvatarPicked: (file) => setState(() => _avatarFile = file),
          isUsernameAvailable: _isUsernameAvailable,
          isCheckingUsername: _isCheckingUsername,
          onUsernameAvailability: (available) {
            setState(() {
              _isUsernameAvailable = available;
              _isCheckingUsername = false;
            });
          },
          existingAvatarUrl: AuthService.instance.userProfile?.avatarUrl,
        );
      case 'LOCATION':
        return LocationStep(
          cityController: _cityController,
          onLocationResolved: (data) {
            _latitude = data['latitude'];
            _longitude = data['longitude'];
            _country = data['country'];
          },
        );
      case 'INTERESTS':
        return TravelerInterestsStep(
          selectedInterests: _selectedInterests,
          onToggle: (interest) {
            setState(() {
              if (_selectedInterests.contains(interest)) {
                _selectedInterests.remove(interest);
              } else {
                _selectedInterests.add(interest);
              }
            });
          },
        );
      case 'AGENCY_DETAILS':
        return AgencyDetailsStep(
          agencyNameController: _agencyNameController,
          contactPersonController: _contactPersonController,
          phoneController: _phoneController,
          descriptionController: _descriptionController,
          websiteController: _websiteController,
          licenseController: _licenseController,
          yearController: _yearController,
        );
      case 'AGENCY_SPECS':
        return AgencySpecializationsStep(
          selectedSpecializations: _selectedSpecializations,
          onToggle: (spec) {
            setState(() {
              if (_selectedSpecializations.contains(spec)) {
                _selectedSpecializations.remove(spec);
              } else {
                _selectedSpecializations.add(spec);
              }
            });
          },
        );
      case 'PRIVACY':
        return PrivacyStep(
          isPrivate: _isPrivate,
          onChanged: (val) => setState(() => _isPrivate = val),
        );
      case 'REVIEW':
        return ReviewStep(
          role: _role!,
          displayName: _nameController.text.trim(),
          username: _usernameController.text.trim(),
          bio: _bioController.text.trim(),
          city: _cityController.text.trim(),
          interests: _selectedInterests,
          isPrivate: _isPrivate,
          avatarFile: _avatarFile,
          existingAvatarUrl: AuthService.instance.userProfile?.avatarUrl,
          agencyName: _agencyNameController.text.trim(),
          contactPerson: _contactPersonController.text.trim(),
          phone: _phoneController.text.trim(),
          description: _descriptionController.text.trim(),
          website: _websiteController.text.trim(),
          licenseNumber: _licenseController.text.trim(),
          yearEstablished: int.tryParse(_yearController.text.trim()),
          specializations: _selectedSpecializations,
        );
      default:
        return const SizedBox.shrink();
    }
  }

  @override
  Widget build(BuildContext context) {
    final steps = _steps;
    final colors = context.appColors;

    return Scaffold(
      backgroundColor: colors.scaffoldBg,
      body: SafeArea(
        child: Column(
          children: [
            // Top: progress bar + back
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 12, 16, 0),
              child: Column(
                children: [
                  Row(
                    children: [
                      if (_currentPage > 0)
                        GestureDetector(
                          onTap: _goBack,
                          child: Container(
                            width: 36,
                            height: 36,
                            decoration: BoxDecoration(
                              color: colors.surfaceBg,
                              borderRadius: BorderRadius.circular(10),
                            ),
                            child: Icon(Icons.arrow_back_ios_new, size: 16, color: colors.textSecondary),
                          ),
                        )
                      else
                        const SizedBox(width: 36),
                      const Spacer(),
                      // Skip button (only on optional steps)
                      if (_currentPage > 0 && !_isLastStep && _steps[_currentPage].id != 'BASIC_INFO')
                        TextButton(
                          onPressed: _goNext,
                          child: Text(
                            'Skip',
                            style: GoogleFonts.inter(
                              fontSize: 14,
                              color: colors.textSecondary,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  OnboardingProgressBar(
                    currentStep: _currentPage,
                    totalSteps: _totalSteps,
                    stepLabel: _currentStepLabel,
                  ),
                ],
              ),
            ),
            const SizedBox(height: 8),

            // Pages
            Expanded(
              child: PageView.builder(
                controller: _pageController,
                physics: const NeverScrollableScrollPhysics(),
                onPageChanged: (i) => setState(() => _currentPage = i),
                itemCount: steps.length,
                itemBuilder: (context, index) {
                  if (index < steps.length) {
                    return _buildStep(steps[index].id);
                  }
                  return const SizedBox.shrink();
                },
              ),
            ),

            // Bottom: Next / Complete button
            if (_currentPage > 0 || _role != null)
              Padding(
                padding: const EdgeInsets.fromLTRB(28, 8, 28, 16),
                child: SizedBox(
                  width: double.infinity,
                  height: 52,
                  child: ElevatedButton(
                    onPressed: (_canProceed && !_isSaving)
                        ? (_isLastStep ? _completeOnboarding : _goNext)
                        : null,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.brand,
                      disabledBackgroundColor: colors.border,
                      foregroundColor: Colors.white,
                      disabledForegroundColor: colors.textMuted,
                      elevation: 0,
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                    ),
                    child: _isSaving
                        ? const SizedBox(
                            width: 22,
                            height: 22,
                            child: CircularProgressIndicator(strokeWidth: 2.5, color: Colors.white),
                          )
                        : Text(
                            _isLastStep ? 'Complete Setup' : 'Continue',
                            style: GoogleFonts.inter(
                              fontSize: 16,
                              fontWeight: FontWeight.w600,
                            ),
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

class _StepDef {
  final String label;
  final String id;
  const _StepDef(this.label, this.id);
}
