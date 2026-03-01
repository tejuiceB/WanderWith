import 'dart:io';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../../theme/app_colors.dart';
import '../../../theme/theme_extensions.dart';

/// Final step: summary of all onboarding data before submission.
class ReviewStep extends StatelessWidget {
  final String role;
  final String displayName;
  final String? username;
  final String? bio;
  final String? city;
  final List<String> interests;
  final bool isPrivate;
  final File? avatarFile;
  final String? existingAvatarUrl;
  // Agency
  final String? agencyName;
  final String? contactPerson;
  final String? phone;
  final String? description;
  final String? website;
  final String? licenseNumber;
  final int? yearEstablished;
  final List<String> specializations;

  const ReviewStep({
    super.key,
    required this.role,
    required this.displayName,
    this.username,
    this.bio,
    this.city,
    this.interests = const [],
    this.isPrivate = true,
    this.avatarFile,
    this.existingAvatarUrl,
    this.agencyName,
    this.contactPerson,
    this.phone,
    this.description,
    this.website,
    this.licenseNumber,
    this.yearEstablished,
    this.specializations = const [],
  });

  @override
  Widget build(BuildContext context) {
    final bool isAgency = role == 'agency';
    final colors = context.appColors;
    final isDark = context.isDark;

    return SingleChildScrollView(
      padding: const EdgeInsets.symmetric(horizontal: 28),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const SizedBox(height: 12),
          Text(
            'Review your profile',
            style: GoogleFonts.outfit(
              fontSize: 28,
              fontWeight: FontWeight.bold,
              color: colors.textPrimary,
            ),
          ),
          const SizedBox(height: 6),
          Text(
            "Everything look good? You can always edit later.",
            style: GoogleFonts.inter(fontSize: 14, color: colors.textSecondary),
          ),
          const SizedBox(height: 24),

          // Profile card
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: colors.cardBg,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: colors.border),
              boxShadow: [
                BoxShadow(
                  color: colors.shadow,
                  blurRadius: 12,
                  offset: const Offset(0, 4),
                ),
              ],
            ),
            child: Column(
              children: [
                // Avatar + name
                Row(
                  children: [
                    CircleAvatar(
                      radius: 32,
                      backgroundColor: colors.surfaceBg,
                      backgroundImage: avatarFile != null
                          ? FileImage(avatarFile!)
                          : existingAvatarUrl != null
                              ? NetworkImage(existingAvatarUrl!) as ImageProvider
                              : null,
                      child: avatarFile == null && existingAvatarUrl == null
                          ? Icon(Icons.person, size: 28, color: colors.textMuted)
                          : null,
                    ),
                    const SizedBox(width: 14),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            displayName,
                            style: GoogleFonts.outfit(
                              fontSize: 18,
                              fontWeight: FontWeight.w700,
                              color: colors.textPrimary,
                            ),
                          ),
                          if (username != null && username!.isNotEmpty)
                            Text(
                              '@$username',
                              style: GoogleFonts.inter(
                                fontSize: 13,
                                color: colors.textSecondary,
                              ),
                            ),
                        ],
                      ),
                    ),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                      decoration: BoxDecoration(
                        color: isAgency
                            ? (isDark ? AppColors.orange.withOpacity(0.15) : const Color(0xFFFFF3E0))
                            : (isDark ? AppColors.brand.withOpacity(0.15) : const Color(0xFFE3F2FD)),
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: Text(
                        isAgency ? 'Agency' : 'Traveler',
                        style: GoogleFonts.inter(
                          fontSize: 11,
                          fontWeight: FontWeight.w700,
                          color: isAgency
                              ? (isDark ? AppColors.orange : const Color(0xFFE65100))
                              : (isDark ? AppColors.brand : const Color(0xFF1565C0)),
                        ),
                      ),
                    ),
                  ],
                ),
                if (bio != null && bio!.isNotEmpty) ...[
                  const SizedBox(height: 12),
                  Text(
                    bio!,
                    style: GoogleFonts.inter(
                      fontSize: 13,
                      color: colors.textSecondary,
                      height: 1.4,
                    ),
                    maxLines: 3,
                    overflow: TextOverflow.ellipsis,
                  ),
                ],
              ],
            ),
          ),
          const SizedBox(height: 16),

          // Details card
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: colors.surfaceBg,
              borderRadius: BorderRadius.circular(14),
            ),
            child: Column(
              children: [
                if (city != null && city!.isNotEmpty)
                  _DetailRow(icon: Icons.location_on_outlined, label: 'Location', value: city!),
                _DetailRow(
                  icon: isPrivate ? Icons.lock_outline : Icons.public,
                  label: 'Privacy',
                  value: isPrivate ? 'Private account' : 'Public account',
                ),
                if (isAgency && agencyName != null && agencyName!.isNotEmpty)
                  _DetailRow(icon: Icons.business_outlined, label: 'Agency', value: agencyName!),
                if (isAgency && contactPerson != null && contactPerson!.isNotEmpty)
                  _DetailRow(icon: Icons.person_outline, label: 'Contact', value: contactPerson!),
                if (isAgency && phone != null && phone!.isNotEmpty)
                  _DetailRow(icon: Icons.phone_outlined, label: 'Phone', value: phone!),
                if (isAgency && website != null && website!.isNotEmpty)
                  _DetailRow(icon: Icons.language, label: 'Website', value: website!),
                if (isAgency && yearEstablished != null)
                  _DetailRow(icon: Icons.calendar_today_outlined, label: 'Established', value: '$yearEstablished'),
              ],
            ),
          ),

          // Interests / Specializations
          if ((!isAgency && interests.isNotEmpty) || (isAgency && specializations.isNotEmpty)) ...[
            const SizedBox(height: 16),
            Text(
              isAgency ? 'Specializations' : 'Interests',
              style: GoogleFonts.inter(
                fontSize: 13,
                fontWeight: FontWeight.w600,
                color: colors.textSecondary,
              ),
            ),
            const SizedBox(height: 8),
            Wrap(
              spacing: 6,
              runSpacing: 6,
              children: (isAgency ? specializations : interests).map((item) {
                return Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                  decoration: BoxDecoration(
                    color: isDark ? AppColors.brand.withOpacity(0.15) : const Color(0xFFE3F2FD),
                    borderRadius: BorderRadius.circular(16),
                  ),
                  child: Text(
                    item,
                    style: GoogleFonts.inter(
                      fontSize: 11,
                      fontWeight: FontWeight.w600,
                      color: isDark ? AppColors.brand : const Color(0xFF1565C0),
                    ),
                  ),
                );
              }).toList(),
            ),
          ],

          const SizedBox(height: 32),
        ],
      ),
    );
  }
}

class _DetailRow extends StatelessWidget {
  final IconData icon;
  final String label;
  final String value;

  const _DetailRow({required this.icon, required this.label, required this.value});

  @override
  Widget build(BuildContext context) {
    final colors = context.appColors;
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: Row(
        children: [
          Icon(icon, size: 18, color: colors.textSecondary),
          const SizedBox(width: 10),
          SizedBox(
            width: 80,
            child: Text(
              label,
              style: GoogleFonts.inter(
                fontSize: 12,
                color: colors.textSecondary,
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
          Expanded(
            child: Text(
              value,
              style: GoogleFonts.inter(
                fontSize: 13,
                color: colors.textPrimary,
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
