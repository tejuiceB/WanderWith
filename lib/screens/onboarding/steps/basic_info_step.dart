import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'dart:async';
import 'dart:io';
import '../../../services/auth_service.dart';
import '../../../theme/app_colors.dart';
import '../../../theme/theme_extensions.dart';
import '../../auth/widgets/auth_text_field.dart';
import '../widgets/avatar_picker.dart';

/// Step 2: Name, username, avatar, bio.
class BasicInfoStep extends StatefulWidget {
  final TextEditingController nameController;
  final TextEditingController usernameController;
  final TextEditingController bioController;
  final File? avatarFile;
  final ValueChanged<File> onAvatarPicked;
  final ValueChanged<bool> onUsernameAvailability;
  final bool isUsernameAvailable;
  final bool isCheckingUsername;
  final String? existingAvatarUrl;

  const BasicInfoStep({
    super.key,
    required this.nameController,
    required this.usernameController,
    required this.bioController,
    required this.avatarFile,
    required this.onAvatarPicked,
    required this.onUsernameAvailability,
    required this.isUsernameAvailable,
    required this.isCheckingUsername,
    this.existingAvatarUrl,
  });

  @override
  State<BasicInfoStep> createState() => _BasicInfoStepState();
}

class _BasicInfoStepState extends State<BasicInfoStep> {
  Timer? _debounce;

  @override
  void initState() {
    super.initState();
    widget.usernameController.addListener(_onUsernameChanged);
  }

  @override
  void dispose() {
    _debounce?.cancel();
    widget.usernameController.removeListener(_onUsernameChanged);
    super.dispose();
  }

  void _onUsernameChanged() {
    _debounce?.cancel();
    final username = widget.usernameController.text.trim().toLowerCase();
    if (username.length < 3) {
      widget.onUsernameAvailability(false);
      return;
    }
    _debounce = Timer(const Duration(milliseconds: 500), () async {
      final available = await AuthService.instance.isUsernameAvailable(username);
      widget.onUsernameAvailability(available);
    });
  }

  Widget? _usernameSuffix() {
    final text = widget.usernameController.text.trim();
    if (text.length < 3) return null;
    if (widget.isCheckingUsername) {
      return const SizedBox(
        width: 18,
        height: 18,
        child: CircularProgressIndicator(strokeWidth: 2, color: AppColors.brand),
      );
    }
    return Icon(
      widget.isUsernameAvailable ? Icons.check_circle : Icons.cancel,
      size: 20,
      color: widget.isUsernameAvailable ? AppColors.success : AppColors.error,
    );
  }

  @override
  Widget build(BuildContext context) {
    final colors = context.appColors;
    return SingleChildScrollView(
      padding: const EdgeInsets.symmetric(horizontal: 28),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const SizedBox(height: 12),
          Text(
            'About you',
            style: GoogleFonts.outfit(
              fontSize: 28,
              fontWeight: FontWeight.bold,
              color: colors.textPrimary,
            ),
          ),
          const SizedBox(height: 6),
          Text(
            "Let's set up your profile.",
            style: GoogleFonts.inter(
              fontSize: 14,
              color: colors.textSecondary,
            ),
          ),
          const SizedBox(height: 24),

          // Avatar
          Center(
            child: AvatarPicker(
              imageFile: widget.avatarFile,
              existingUrl: widget.existingAvatarUrl,
              onPicked: widget.onAvatarPicked,
            ),
          ),
          const SizedBox(height: 24),

          // Display name
          AuthTextField(
            controller: widget.nameController,
            label: 'Display Name',
            hint: 'Enter your full name',
            textInputAction: TextInputAction.next,
            prefixIcon: Icon(Icons.person_outline, size: 20, color: colors.textSecondary),
            validator: (val) {
              if (val == null || val.trim().isEmpty) return 'Name is required';
              if (val.trim().length < 2) return 'Name is too short';
              return null;
            },
          ),
          const SizedBox(height: 14),

          // Username
          AuthTextField(
            controller: widget.usernameController,
            label: 'Username',
            hint: 'Choose a unique username',
            textInputAction: TextInputAction.next,
            prefixIcon: Icon(Icons.alternate_email, size: 20, color: colors.textSecondary),
            suffixIcon: _usernameSuffix(),
            validator: (val) {
              if (val == null || val.trim().isEmpty) return 'Username is required';
              if (val.trim().length < 3) return 'At least 3 characters';
              if (!RegExp(r'^[a-zA-Z0-9_]+$').hasMatch(val.trim())) {
                return 'Only letters, numbers, underscores';
              }
              return null;
            },
          ),
          if (widget.usernameController.text.trim().length >= 3 && !widget.isCheckingUsername)
            Padding(
              padding: const EdgeInsets.only(top: 4, left: 4),
              child: Text(
                widget.isUsernameAvailable ? 'Username is available!' : 'Username is taken',
                style: GoogleFonts.inter(
                  fontSize: 11,
                  fontWeight: FontWeight.w500,
                  color: widget.isUsernameAvailable
                      ? AppColors.success
                      : AppColors.error,
                ),
              ),
            ),
          const SizedBox(height: 14),

          // Bio
          AuthTextField(
            controller: widget.bioController,
            label: 'Bio (optional)',
            hint: 'Tell us about yourself...',
            maxLines: 3,
            textInputAction: TextInputAction.newline,
          ),
          const SizedBox(height: 24),
        ],
      ),
    );
  }
}
