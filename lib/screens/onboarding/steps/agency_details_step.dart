import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../../theme/theme_extensions.dart';
import '../../auth/widgets/auth_text_field.dart';

/// Agency-only step: Agency name, contact person, phone, description, website, license, year established.
class AgencyDetailsStep extends StatelessWidget {
  final TextEditingController agencyNameController;
  final TextEditingController contactPersonController;
  final TextEditingController phoneController;
  final TextEditingController descriptionController;
  final TextEditingController websiteController;
  final TextEditingController licenseController;
  final TextEditingController yearController;

  const AgencyDetailsStep({
    super.key,
    required this.agencyNameController,
    required this.contactPersonController,
    required this.phoneController,
    required this.descriptionController,
    required this.websiteController,
    required this.licenseController,
    required this.yearController,
  });

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
            'Agency details',
            style: GoogleFonts.outfit(
              fontSize: 28,
              fontWeight: FontWeight.bold,
              color: colors.textPrimary,
            ),
          ),
          const SizedBox(height: 6),
          Text(
            'Tell travelers about your agency.',
            style: GoogleFonts.inter(fontSize: 14, color: colors.textSecondary),
          ),
          const SizedBox(height: 24),

          AuthTextField(
            controller: agencyNameController,
            label: 'Agency Name',
            hint: 'e.g. WanderWay Travels',
            textInputAction: TextInputAction.next,
            prefixIcon: Icon(Icons.business_outlined, size: 20, color: colors.textSecondary),
            validator: (v) => (v == null || v.trim().isEmpty) ? 'Agency name is required' : null,
          ),
          const SizedBox(height: 14),

          AuthTextField(
            controller: contactPersonController,
            label: 'Contact Person',
            hint: 'Full name of primary contact',
            textInputAction: TextInputAction.next,
            prefixIcon: Icon(Icons.person_outline, size: 20, color: colors.textSecondary),
          ),
          const SizedBox(height: 14),

          AuthTextField(
            controller: phoneController,
            label: 'Phone Number',
            hint: '+91 98765 43210',
            keyboardType: TextInputType.phone,
            textInputAction: TextInputAction.next,
            prefixIcon: Icon(Icons.phone_outlined, size: 20, color: colors.textSecondary),
          ),
          const SizedBox(height: 14),

          AuthTextField(
            controller: descriptionController,
            label: 'Description',
            hint: 'What makes your agency special?',
            maxLines: 3,
            textInputAction: TextInputAction.newline,
          ),
          const SizedBox(height: 14),

          AuthTextField(
            controller: websiteController,
            label: 'Website (optional)',
            hint: 'https://youragency.com',
            keyboardType: TextInputType.url,
            textInputAction: TextInputAction.next,
            prefixIcon: Icon(Icons.language_outlined, size: 20, color: colors.textSecondary),
          ),
          const SizedBox(height: 14),

          AuthTextField(
            controller: licenseController,
            label: 'License Number (optional)',
            hint: 'Travel agency license ID',
            textInputAction: TextInputAction.next,
            prefixIcon: Icon(Icons.badge_outlined, size: 20, color: colors.textSecondary),
          ),
          const SizedBox(height: 14),

          AuthTextField(
            controller: yearController,
            label: 'Year Established (optional)',
            hint: 'e.g. 2015',
            keyboardType: TextInputType.number,
            textInputAction: TextInputAction.done,
            prefixIcon: Icon(Icons.calendar_today_outlined, size: 20, color: colors.textSecondary),
            validator: (v) {
              if (v != null && v.isNotEmpty) {
                final year = int.tryParse(v);
                if (year == null || year < 1900 || year > DateTime.now().year) {
                  return 'Enter a valid year';
                }
              }
              return null;
            },
          ),
          const SizedBox(height: 24),
        ],
      ),
    );
  }
}
