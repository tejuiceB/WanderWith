import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../services/travel_mood_service.dart';
import '../theme/app_colors.dart';
import '../theme/theme_extensions.dart';

/// Displays the user's AI-detected travel mood as a compact card.
/// Shows a "Discover your travel mood" CTA if mood hasn't been analyzed yet.
class TravelMoodCard extends StatefulWidget {
  final String? storedMood;
  final bool isCurrentUser;

  const TravelMoodCard({
    super.key,
    this.storedMood,
    this.isCurrentUser = false,
  });

  @override
  State<TravelMoodCard> createState() => _TravelMoodCardState();
}

class _TravelMoodCardState extends State<TravelMoodCard>
    with SingleTickerProviderStateMixin {
  TravelMood? _mood;
  bool _isAnalyzing = false;
  late AnimationController _shimmerController;

  @override
  void initState() {
    super.initState();
    _mood = TravelMood.fromString(widget.storedMood);
    _shimmerController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1500),
    );
  }

  @override
  void dispose() {
    _shimmerController.dispose();
    super.dispose();
  }

  Future<void> _analyzeMood() async {
    setState(() => _isAnalyzing = true);
    _shimmerController.repeat();

    try {
      final mood = await TravelMoodService().analyzeMood();

      _shimmerController.stop();
      if (mounted) {
        setState(() {
          _mood = mood;
          _isAnalyzing = false;
        });
        if (mood == null) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: const Text('Not enough travel data yet — take a trip first!'),
              backgroundColor: Colors.orange.shade700,
              duration: const Duration(seconds: 3),
            ),
          );
        }
      }
    } catch (e) {
      debugPrint('TravelMoodCard: _analyzeMood error: $e');
      _shimmerController.stop();
      if (mounted) {
        setState(() => _isAnalyzing = false);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: const Text('Could not analyze mood. Please try again later.'),
            backgroundColor: Colors.orange.shade700,
            duration: const Duration(seconds: 3),
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final colors = context.appColors;

    if (_mood != null) {
      return _buildMoodDisplay(colors);
    }

    if (!widget.isCurrentUser) return const SizedBox.shrink();

    return _buildDiscoverCTA(colors);
  }

  Widget _buildMoodDisplay(AppColors colors) {
    final mood = _mood!;
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            _moodColor(mood).withOpacity(0.15),
            _moodColor(mood).withOpacity(0.05),
          ],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: _moodColor(mood).withOpacity(0.3)),
      ),
      child: Row(
        children: [
          Container(
            width: 50,
            height: 50,
            decoration: BoxDecoration(
              color: _moodColor(mood).withOpacity(0.2),
              borderRadius: BorderRadius.circular(14),
            ),
            child: Center(
              child: Text(mood.emoji, style: const TextStyle(fontSize: 26)),
            ),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Text(
                      'Travel Mood',
                      style: GoogleFonts.inter(
                        fontSize: 11,
                        fontWeight: FontWeight.w600,
                        color: colors.textMuted,
                        letterSpacing: 0.5,
                      ),
                    ),
                    const SizedBox(width: 6),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 1),
                      decoration: BoxDecoration(
                        color: _moodColor(mood).withOpacity(0.2),
                        borderRadius: BorderRadius.circular(6),
                      ),
                      child: Text(
                        'AI',
                        style: GoogleFonts.inter(
                          fontSize: 9,
                          fontWeight: FontWeight.bold,
                          color: _moodColor(mood),
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 2),
                Text(
                  mood.label,
                  style: GoogleFonts.outfit(
                    fontSize: 17,
                    fontWeight: FontWeight.bold,
                    color: colors.textPrimary,
                  ),
                ),
                Text(
                  mood.description,
                  style: GoogleFonts.inter(
                    fontSize: 12,
                    color: colors.textSecondary,
                  ),
                ),
              ],
            ),
          ),
          if (widget.isCurrentUser)
            IconButton(
              onPressed: _isAnalyzing ? null : _analyzeMood,
              icon: _isAnalyzing
                  ? SizedBox(
                      width: 18,
                      height: 18,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        color: _moodColor(mood),
                      ),
                    )
                  : Icon(Icons.refresh_rounded, color: colors.textMuted, size: 20),
              tooltip: 'Re-analyze',
            ),
        ],
      ),
    );
  }

  Widget _buildDiscoverCTA(AppColors colors) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16),
      child: Material(
        color: AppColors.brand.withOpacity(0.08),
        borderRadius: BorderRadius.circular(16),
        child: InkWell(
          borderRadius: BorderRadius.circular(16),
          onTap: _isAnalyzing ? null : _analyzeMood,
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
            child: Row(
              children: [
                Container(
                  width: 44,
                  height: 44,
                  decoration: BoxDecoration(
                    color: AppColors.brand.withOpacity(0.15),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: _isAnalyzing
                      ? const Center(
                          child: SizedBox(
                            width: 20,
                            height: 20,
                            child: CircularProgressIndicator(strokeWidth: 2, color: AppColors.brand),
                          ),
                        )
                      : const Center(
                          child: Text('🔮', style: TextStyle(fontSize: 22)),
                        ),
                ),
                const SizedBox(width: 14),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        _isAnalyzing ? 'Analyzing your trips…' : 'Discover Your Travel Mood',
                        style: GoogleFonts.outfit(
                          fontSize: 15,
                          fontWeight: FontWeight.bold,
                          color: colors.textPrimary,
                        ),
                      ),
                      Text(
                        _isAnalyzing
                            ? 'AI is scanning your trip history & chat patterns'
                            : 'AI analyzes your trips to reveal your traveler personality',
                        style: GoogleFonts.inter(fontSize: 12, color: colors.textSecondary),
                      ),
                    ],
                  ),
                ),
                if (!_isAnalyzing)
                  Icon(Icons.arrow_forward_ios, size: 14, color: colors.textMuted),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Color _moodColor(TravelMood mood) {
    switch (mood) {
      case TravelMood.adventure: return Colors.orange;
      case TravelMood.relaxation: return Colors.teal;
      case TravelMood.party: return Colors.purple;
      case TravelMood.cultural: return Colors.brown;
      case TravelMood.nature: return Colors.green;
      case TravelMood.romantic: return Colors.pink;
      case TravelMood.family: return Colors.blue;
      case TravelMood.solo: return Colors.indigo;
      case TravelMood.foodie: return Colors.deepOrange;
      case TravelMood.luxury: return Colors.amber.shade800;
    }
  }
}
