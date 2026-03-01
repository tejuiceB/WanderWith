import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:cached_network_image/cached_network_image.dart';
import '../models/trip.dart';
import '../theme/app_colors.dart';
import '../theme/theme_extensions.dart';

class TripCard extends StatelessWidget {
  final Trip trip;
  final VoidCallback onTap;
  final Widget? trailing;
  final bool showStatus;

  const TripCard({
    super.key,
    required this.trip,
    required this.onTap,
    this.trailing,
    this.showStatus = true,
  });

  @override
  Widget build(BuildContext context) {
    final colors = context.appColors;
    final isDark = context.isDark;
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: colors.cardBg,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: colors.border),
        boxShadow: [
          BoxShadow(
            color: colors.shadow,
            blurRadius: 8,
            offset: const Offset(0, 2),
          )
        ],
      ),
      child: ListTile(
        contentPadding: const EdgeInsets.all(16),
        onTap: onTap,
        leading: ClipRRect(
          borderRadius: BorderRadius.circular(12),
          child: Container(
            width: 56,
            height: 56,
            decoration: BoxDecoration(color: isDark ? AppColors.brand.withOpacity(0.15) : Colors.blue.shade50),
            child: (trip.coverImageUrl != null && trip.coverImageUrl!.isNotEmpty)
                ? CachedNetworkImage(
                    imageUrl: trip.coverImageUrl!,
                    fit: BoxFit.cover,
                    placeholder: (context, url) => const Center(
                      child: CircularProgressIndicator(strokeWidth: 2),
                    ),
                    errorWidget: (context, url, error) => Icon(
                      Icons.flight_takeoff,
                      color: AppColors.brand,
                    ),
                  )
                : Icon(Icons.flight_takeoff, color: AppColors.brand),
          ),
        ),
        title: Text(
          trip.name,
          style: GoogleFonts.outfit(
            fontWeight: FontWeight.bold,
            fontSize: 16,
          ),
        ),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const SizedBox(height: 4),
            Row(
              children: [
                Icon(Icons.location_on, size: 14, color: colors.textSecondary),
                const SizedBox(width: 4),
                Expanded(
                  child: Text(
                    trip.location,
                    style: GoogleFonts.inter(
                      fontSize: 13,
                      color: colors.textSecondary,
                    ),
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
              ],
            ),
            if (showStatus) ...[
              const SizedBox(height: 4),
              _buildStatusBadge(),
            ],
          ],
        ),
        trailing: trailing ?? Icon(Icons.chevron_right, color: colors.textSecondary),
      ),
    );
  }

  Widget _buildStatusBadge() {
    Color badgeColor;
    String statusText;
    IconData icon;

    switch (trip.status) {
      case 'planning':
        badgeColor = Colors.orange;
        statusText = 'Planning';
        icon = Icons.edit_note;
        break;
      case 'confirmed':
        badgeColor = Colors.blue;
        statusText = 'Confirmed';
        icon = Icons.check_circle;
        break;
      case 'ongoing':
        badgeColor = Colors.green;
        statusText = 'Ongoing';
        icon = Icons.flight_takeoff;
        break;
      case 'completed':
        badgeColor = Colors.grey;
        statusText = 'Completed';
        icon = Icons.flag;
        break;
      case 'dead':
        badgeColor = Colors.red;
        statusText = 'Cancelled';
        icon = Icons.cancel;
        break;
      default:
        badgeColor = Colors.orange;
        statusText = 'Planning';
        icon = Icons.edit_note;
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(
        color: badgeColor.withOpacity(0.12),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 12, color: badgeColor),
          const SizedBox(width: 4),
          Text(
            statusText,
            style: TextStyle(
              color: badgeColor,
              fontSize: 11,
              fontWeight: FontWeight.bold,
            ),
          ),
        ],
      ),
    );
  }
}
