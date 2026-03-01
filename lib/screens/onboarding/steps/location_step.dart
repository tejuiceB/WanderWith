import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:geolocator/geolocator.dart';
import 'package:geocoding/geocoding.dart';
import '../../../theme/app_colors.dart';
import '../../../theme/theme_extensions.dart';
import '../../auth/widgets/auth_text_field.dart';

/// Step 3: City / location input with optional "Use my location".
class LocationStep extends StatefulWidget {
  final TextEditingController cityController;
  final ValueChanged<Map<String, dynamic>> onLocationResolved;

  const LocationStep({
    super.key,
    required this.cityController,
    required this.onLocationResolved,
  });

  @override
  State<LocationStep> createState() => _LocationStepState();
}

class _LocationStepState extends State<LocationStep> {
  bool _isLocating = false;
  String? _resolvedLabel;

  Future<void> _useMyLocation() async {
    setState(() {
      _isLocating = true;
      _resolvedLabel = null;
    });

    try {
      LocationPermission perm = await Geolocator.checkPermission();
      if (perm == LocationPermission.denied) {
        perm = await Geolocator.requestPermission();
        if (perm == LocationPermission.denied) {
          throw 'Location permission denied';
        }
      }
      if (perm == LocationPermission.deniedForever) {
        throw 'Location permission permanently denied. Enable it in settings.';
      }

      final position = await Geolocator.getCurrentPosition(
        desiredAccuracy: LocationAccuracy.medium,
      );

      final placemarks = await placemarkFromCoordinates(
        position.latitude,
        position.longitude,
      );

      if (placemarks.isNotEmpty) {
        final p = placemarks.first;
        final city = p.locality ?? p.subAdministrativeArea ?? '';
        final country = p.country ?? '';
        final label = [city, country].where((s) => s.isNotEmpty).join(', ');

        widget.cityController.text = label;
        setState(() => _resolvedLabel = label);
        widget.onLocationResolved({
          'city': city,
          'country': country,
          'latitude': position.latitude,
          'longitude': position.longitude,
        });
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('$e'),
            behavior: SnackBarBehavior.floating,
            backgroundColor: AppColors.error,
          ),
        );
      }
    } finally {
      if (mounted) setState(() => _isLocating = false);
    }
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
            'Where are you based?',
            style: GoogleFonts.outfit(
              fontSize: 28,
              fontWeight: FontWeight.bold,
              color: colors.textPrimary,
            ),
          ),
          const SizedBox(height: 6),
          Text(
            'This helps us connect you with nearby travelers and trips.',
            style: GoogleFonts.inter(
              fontSize: 14,
              color: colors.textSecondary,
              height: 1.4,
            ),
          ),
          const SizedBox(height: 32),

          AuthTextField(
            controller: widget.cityController,
            label: 'City',
            hint: 'e.g. Mumbai, Paris, Tokyo',
            textInputAction: TextInputAction.done,
            prefixIcon: Icon(Icons.location_city_outlined, size: 20, color: colors.textSecondary),
          ),
          const SizedBox(height: 16),

          // Use my location button
          SizedBox(
            width: double.infinity,
            height: 48,
            child: OutlinedButton.icon(
              onPressed: _isLocating ? null : _useMyLocation,
              icon: _isLocating
                  ? const SizedBox(
                      width: 18,
                      height: 18,
                      child: CircularProgressIndicator(strokeWidth: 2, color: AppColors.brand),
                    )
                  : const Icon(Icons.my_location, size: 18),
              label: Text(
                _isLocating ? 'Detecting...' : 'Use my location',
                style: GoogleFonts.inter(fontWeight: FontWeight.w600, fontSize: 14),
              ),
              style: OutlinedButton.styleFrom(
                foregroundColor: AppColors.brand,
                side: BorderSide(color: colors.border, width: 1.5),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              ),
            ),
          ),

          if (_resolvedLabel != null) ...[
            const SizedBox(height: 12),
            Row(
              children: [
                const Icon(Icons.check_circle, size: 16, color: AppColors.success),
                const SizedBox(width: 6),
                Expanded(
                  child: Text(
                    'Detected: $_resolvedLabel',
                    style: GoogleFonts.inter(
                      fontSize: 12,
                      color: AppColors.success,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ),
              ],
            ),
          ],

          const SizedBox(height: 40),

          // Illustration placeholder
          Center(
            child: Column(
              children: [
                Icon(
                  Icons.public,
                  size: 80,
                  color: AppColors.brand.withOpacity(0.1),
                ),
                const SizedBox(height: 8),
                Text(
                  'You can always change this later',
                  style: GoogleFonts.inter(
                    fontSize: 12,
                    color: colors.textMuted,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
