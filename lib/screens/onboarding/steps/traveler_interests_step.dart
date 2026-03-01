import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../../theme/app_colors.dart';
import '../../../theme/theme_extensions.dart';
import '../widgets/interest_card.dart';

/// 25 curated travel interests displayed Reddit-style with pastel cards.
class TravelerInterestsStep extends StatelessWidget {
  final List<String> selectedInterests;
  final ValueChanged<String> onToggle;

  const TravelerInterestsStep({
    super.key,
    required this.selectedInterests,
    required this.onToggle,
  });

  static const List<_InterestItem> allInterests = [
    _InterestItem('Beach & Islands', Icons.beach_access_rounded, Color(0xFF42A5F5)),
    _InterestItem('Mountains', Icons.terrain_rounded, Color(0xFF66BB6A)),
    _InterestItem('City Breaks', Icons.location_city_rounded, Color(0xFFAB47BC)),
    _InterestItem('Road Trips', Icons.directions_car_rounded, Color(0xFFEF5350)),
    _InterestItem('Backpacking', Icons.hiking_rounded, Color(0xFF8D6E63)),
    _InterestItem('Luxury Travel', Icons.diamond_outlined, Color(0xFFFFB300)),
    _InterestItem('Adventure Sports', Icons.paragliding_rounded, Color(0xFFFF7043)),
    _InterestItem('Wildlife & Safari', Icons.pets_rounded, Color(0xFF26A69A)),
    _InterestItem('Food & Culinary', Icons.restaurant_rounded, Color(0xFFEC407A)),
    _InterestItem('Photography', Icons.camera_alt_rounded, Color(0xFF7E57C2)),
    _InterestItem('Historical Sites', Icons.account_balance_rounded, Color(0xFF78909C)),
    _InterestItem('Nightlife', Icons.nightlife_rounded, Color(0xFFE040FB)),
    _InterestItem('Spiritual', Icons.self_improvement_rounded, Color(0xFFFF8A65)),
    _InterestItem('Camping', Icons.cabin_rounded, Color(0xFF4CAF50)),
    _InterestItem('Scuba Diving', Icons.scuba_diving_rounded, Color(0xFF0097A7)),
    _InterestItem('Skiing & Snow', Icons.downhill_skiing_rounded, Color(0xFF42A5F5)),
    _InterestItem('Cruises', Icons.sailing_rounded, Color(0xFF5C6BC0)),
    _InterestItem('Festivals', Icons.celebration_rounded, Color(0xFFFFA726)),
    _InterestItem('Solo Travel', Icons.person_rounded, Color(0xFF26C6DA)),
    _InterestItem('Couples', Icons.favorite_rounded, Color(0xFFEF5350)),
    _InterestItem('Family Trips', Icons.family_restroom_rounded, Color(0xFF66BB6A)),
    _InterestItem('Budget Travel', Icons.savings_rounded, Color(0xFF9CCC65)),
    _InterestItem('Digital Nomad', Icons.laptop_mac_rounded, Color(0xFF7986CB)),
    _InterestItem('Art & Culture', Icons.palette_rounded, Color(0xFFAB47BC)),
    _InterestItem('Wellness & Spa', Icons.spa_rounded, Color(0xFF80CBC4)),
  ];

  @override
  Widget build(BuildContext context) {
    final colors = context.appColors;
    final isDark = context.isDark;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 28),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const SizedBox(height: 12),
              Text(
                'What excites you?',
                style: GoogleFonts.outfit(
                  fontSize: 28,
                  fontWeight: FontWeight.bold,
                  color: colors.textPrimary,
                ),
              ),
              const SizedBox(height: 6),
              Text(
                'Pick at least 3 interests to personalize your feed.',
                style: GoogleFonts.inter(
                  fontSize: 14,
                  color: colors.textSecondary,
                ),
              ),
              const SizedBox(height: 6),
              AnimatedContainer(
                duration: const Duration(milliseconds: 300),
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                decoration: BoxDecoration(
                  color: selectedInterests.length >= 3
                      ? (isDark ? AppColors.success.withOpacity(0.15) : const Color(0xFFE8F5E9))
                      : (isDark ? AppColors.warning.withOpacity(0.15) : const Color(0xFFFFF3E0)),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Text(
                  '${selectedInterests.length} selected${selectedInterests.length < 3 ? " (${3 - selectedInterests.length} more needed)" : " ✓"}',
                  style: GoogleFonts.inter(
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                    color: selectedInterests.length >= 3
                        ? AppColors.success
                        : (isDark ? AppColors.warning : const Color(0xFFE65100)),
                  ),
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 16),
        Expanded(
          child: GridView.builder(
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 4),
            gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: 3,
              crossAxisSpacing: 10,
              mainAxisSpacing: 10,
              childAspectRatio: 0.92,
            ),
            itemCount: allInterests.length,
            itemBuilder: (context, index) {
              final item = allInterests[index];
              final isSelected = selectedInterests.contains(item.label);
              return InterestCard(
                label: item.label,
                icon: item.icon,
                pastelColor: item.color,
                isSelected: isSelected,
                onTap: () => onToggle(item.label),
              );
            },
          ),
        ),
      ],
    );
  }
}

class _InterestItem {
  final String label;
  final IconData icon;
  final Color color;
  const _InterestItem(this.label, this.icon, this.color);
}
