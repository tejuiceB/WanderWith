import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../../theme/app_colors.dart';
import '../../../theme/theme_extensions.dart';

/// Agency-only step: pick specialization areas.
class AgencySpecializationsStep extends StatelessWidget {
  final List<String> selectedSpecializations;
  final ValueChanged<String> onToggle;

  const AgencySpecializationsStep({
    super.key,
    required this.selectedSpecializations,
    required this.onToggle,
  });

  static const List<_Spec> allSpecializations = [
    _Spec('Adventure Tours', Icons.paragliding_rounded, Color(0xFFFF7043)),
    _Spec('Cultural Tours', Icons.museum_rounded, Color(0xFFAB47BC)),
    _Spec('Luxury Packages', Icons.diamond_outlined, Color(0xFFFFB300)),
    _Spec('Budget Travel', Icons.savings_rounded, Color(0xFF66BB6A)),
    _Spec('Honeymoon', Icons.favorite_rounded, Color(0xFFEF5350)),
    _Spec('Group Tours', Icons.groups_rounded, Color(0xFF42A5F5)),
    _Spec('Corporate Travel', Icons.business_center_rounded, Color(0xFF78909C)),
    _Spec('Wildlife Safari', Icons.pets_rounded, Color(0xFF26A69A)),
    _Spec('Pilgrimage', Icons.temple_hindu_rounded, Color(0xFFFF8A65)),
    _Spec('Cruise Packages', Icons.sailing_rounded, Color(0xFF5C6BC0)),
    _Spec('Trekking & Hiking', Icons.hiking_rounded, Color(0xFF8D6E63)),
    _Spec('International', Icons.public_rounded, Color(0xFF26C6DA)),
  ];

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
            'Your specializations',
            style: GoogleFonts.outfit(
              fontSize: 28,
              fontWeight: FontWeight.bold,
              color: colors.textPrimary,
            ),
          ),
          const SizedBox(height: 6),
          Text(
            'Select the trip types your agency focuses on.',
            style: GoogleFonts.inter(fontSize: 14, color: colors.textSecondary),
          ),
          const SizedBox(height: 6),
          Text(
            '${selectedSpecializations.length} selected',
            style: GoogleFonts.inter(
              fontSize: 12,
              fontWeight: FontWeight.w600,
              color: AppColors.brand,
            ),
          ),
          const SizedBox(height: 20),

          Wrap(
            spacing: 10,
            runSpacing: 10,
            children: allSpecializations.map((spec) {
              final isSelected = selectedSpecializations.contains(spec.label);
              return GestureDetector(
                onTap: () => onToggle(spec.label),
                child: AnimatedContainer(
                  duration: const Duration(milliseconds: 200),
                  padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                  decoration: BoxDecoration(
                    color: isSelected
                        ? spec.color.withOpacity(0.15)
                        : colors.fieldFillBg,
                    borderRadius: BorderRadius.circular(24),
                    border: Border.all(
                      color: isSelected
                          ? spec.color.withOpacity(0.6)
                          : colors.border,
                      width: isSelected ? 2 : 1.5,
                    ),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(
                        spec.icon,
                        size: 18,
                        color: isSelected ? spec.color : colors.textSecondary,
                      ),
                      const SizedBox(width: 6),
                      Text(
                        spec.label,
                        style: GoogleFonts.inter(
                          fontSize: 13,
                          fontWeight: isSelected ? FontWeight.w700 : FontWeight.w500,
                          color: isSelected
                              ? colors.textPrimary
                              : colors.textSecondary,
                        ),
                      ),
                      if (isSelected) ...[
                        const SizedBox(width: 4),
                        Icon(Icons.check_circle, size: 16, color: spec.color),
                      ],
                    ],
                  ),
                ),
              );
            }).toList(),
          ),
          const SizedBox(height: 24),
        ],
      ),
    );
  }
}

class _Spec {
  final String label;
  final IconData icon;
  final Color color;
  const _Spec(this.label, this.icon, this.color);
}
