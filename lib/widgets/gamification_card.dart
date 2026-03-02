import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../services/gamification_service.dart';
import '../theme/app_colors.dart';
import '../theme/theme_extensions.dart';

/// Displays the user's earned badges and next milestone progress.
/// For the current user, includes a "Check for new badges" action.
class GamificationCard extends StatefulWidget {
  final List<dynamic> badgesEarned;
  final Map<String, dynamic> gamificationStats;
  final bool isCurrentUser;

  const GamificationCard({
    super.key,
    required this.badgesEarned,
    required this.gamificationStats,
    this.isCurrentUser = false,
  });

  @override
  State<GamificationCard> createState() => _GamificationCardState();
}

class _GamificationCardState extends State<GamificationCard> {
  bool _isAnalyzing = false;
  late List<dynamic> _badges;
  late Map<String, dynamic> _stats;

  @override
  void initState() {
    super.initState();
    _badges = List.from(widget.badgesEarned);
    _stats = Map.from(widget.gamificationStats);
  }

  Set<String> get _earnedKeys {
    return GamificationService().earnedBadgeKeys(_badges);
  }

  Future<void> _checkBadges() async {
    setState(() => _isAnalyzing = true);

    try {
      final newBadges = await GamificationService().analyzeAndUpdate();

      if (mounted) {
        // Refresh data
        final data = await GamificationService().getCachedStats();
        setState(() {
          _badges = data['badges'] as List? ?? [];
          _stats = data['stats'] as Map<String, dynamic>? ?? {};
          _isAnalyzing = false;
        });

        if (newBadges.isNotEmpty && mounted) {
          _showNewBadgeDialog(newBadges);
        }
      }
    } catch (e) {
      debugPrint('GamificationCard: _checkBadges error: $e');
      if (mounted) {
        setState(() => _isAnalyzing = false);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: const Text('Could not check badges. Please try again later.'),
            backgroundColor: Colors.orange.shade700,
            duration: const Duration(seconds: 3),
          ),
        );
      }
    }
  }

  void _showNewBadgeDialog(List<TravelBadge> badges) {
    final colors = context.appColors;
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: colors.surfaceBg,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: Text(
          badges.length == 1 ? 'Badge Unlocked! 🎉' : '${badges.length} Badges Unlocked! 🎉',
          style: GoogleFonts.outfit(fontWeight: FontWeight.bold, color: colors.textPrimary),
          textAlign: TextAlign.center,
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: badges.map((b) => Padding(
            padding: const EdgeInsets.symmetric(vertical: 8),
            child: Row(
              children: [
                Text(b.emoji, style: const TextStyle(fontSize: 32)),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(b.label, style: GoogleFonts.outfit(
                        fontSize: 16, fontWeight: FontWeight.bold, color: colors.textPrimary,
                      )),
                      Text(b.description, style: GoogleFonts.inter(
                        fontSize: 12, color: colors.textSecondary,
                      )),
                    ],
                  ),
                ),
              ],
            ),
          )).toList(),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: Text('Awesome!', style: GoogleFonts.outfit(
              color: AppColors.brand, fontWeight: FontWeight.bold,
            )),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final colors = context.appColors;
    final earned = _earnedKeys;
    final milestones = GamificationService().getNextMilestones(_stats, earned);

    // Hide if no badges and not current user (nothing to show)
    if (earned.isEmpty && milestones.isEmpty && !widget.isCurrentUser) {
      return const SizedBox.shrink();
    }

    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: colors.surfaceBg,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: colors.border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header
          Row(
            children: [
              const Text('🏆', style: TextStyle(fontSize: 20)),
              const SizedBox(width: 8),
              Text(
                'Travel Badges',
                style: GoogleFonts.outfit(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                  color: colors.textPrimary,
                ),
              ),
              if (earned.isNotEmpty) ...[
                const SizedBox(width: 8),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                  decoration: BoxDecoration(
                    color: AppColors.brand.withOpacity(0.15),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Text(
                    '${earned.length}/${TravelBadge.values.length}',
                    style: GoogleFonts.inter(
                      fontSize: 11,
                      fontWeight: FontWeight.bold,
                      color: AppColors.brand,
                    ),
                  ),
                ),
              ],
              const Spacer(),
              if (widget.isCurrentUser)
                _isAnalyzing
                    ? const SizedBox(
                        width: 20,
                        height: 20,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          color: AppColors.brand,
                        ),
                      )
                    : GestureDetector(
                        onTap: _checkBadges,
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(Icons.refresh_rounded,
                                size: 16, color: colors.textMuted),
                            const SizedBox(width: 4),
                            Text(
                              'Check',
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
          const SizedBox(height: 14),

          // Earned badges — horizontal scroll
          if (earned.isNotEmpty) ...[
            SizedBox(
              height: 72,
              child: ListView.separated(
                scrollDirection: Axis.horizontal,
                itemCount: earned.length,
                separatorBuilder: (_, __) => const SizedBox(width: 10),
                itemBuilder: (_, i) {
                  final badge =
                      TravelBadge.fromString(earned.elementAt(i));
                  if (badge == null) return const SizedBox.shrink();
                  return _BadgeChip(badge: badge, colors: colors);
                },
              ),
            ),
          ] else if (widget.isCurrentUser) ...[
            // CTA for users with no badges yet
            GestureDetector(
              onTap: _isAnalyzing ? null : _checkBadges,
              child: Container(
                padding: const EdgeInsets.symmetric(vertical: 12),
                decoration: BoxDecoration(
                  color: AppColors.brand.withOpacity(0.06),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Center(
                  child: Text(
                    _isAnalyzing
                        ? 'Scanning your adventures…'
                        : 'Tap to check your first badge! 🎒',
                    style: GoogleFonts.inter(
                      fontSize: 13,
                      color: AppColors.brand,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ),
              ),
            ),
          ],

          // Next milestones
          if (milestones.isNotEmpty) ...[
            const SizedBox(height: 14),
            Text(
              'Next Milestones',
              style: GoogleFonts.inter(
                fontSize: 12,
                fontWeight: FontWeight.w600,
                color: colors.textMuted,
                letterSpacing: 0.3,
              ),
            ),
            const SizedBox(height: 8),
            ...milestones.map(
                (m) => _MilestoneRow(milestone: m, colors: colors)),
          ],
        ],
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Badge Chip
// ─────────────────────────────────────────────────────────────────────────────

class _BadgeChip extends StatelessWidget {
  final TravelBadge badge;
  final AppColors colors;

  const _BadgeChip({required this.badge, required this.colors});

  @override
  Widget build(BuildContext context) {
    return Tooltip(
      message: '${badge.label} — ${badge.description}',
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 48,
            height: 48,
            decoration: BoxDecoration(
              color: _badgeColor(badge).withOpacity(0.15),
              borderRadius: BorderRadius.circular(14),
              border: Border.all(
                  color: _badgeColor(badge).withOpacity(0.4), width: 1.5),
            ),
            child: Center(
              child: Text(badge.emoji, style: const TextStyle(fontSize: 22)),
            ),
          ),
          const SizedBox(height: 4),
          SizedBox(
            width: 56,
            child: Text(
              badge.label,
              textAlign: TextAlign.center,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: GoogleFonts.inter(
                fontSize: 9,
                fontWeight: FontWeight.w600,
                color: colors.textSecondary,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Color _badgeColor(TravelBadge b) {
    switch (b) {
      case TravelBadge.firstTrip:
        return Colors.green;
      case TravelBadge.explorer:
        return Colors.blue;
      case TravelBadge.globetrotter:
        return Colors.indigo;
      case TravelBadge.wanderlustLegend:
        return Colors.purple;
      case TravelBadge.placeHopper:
        return Colors.orange;
      case TravelBadge.crossCountry:
        return Colors.brown;
      case TravelBadge.groupLeader:
        return Colors.teal;
      case TravelBadge.socialButterfly:
        return Colors.pink;
      case TravelBadge.budgetPro:
        return Colors.amber;
      case TravelBadge.memoryMaker:
        return Colors.red;
      case TravelBadge.earlyPlanner:
        return Colors.cyan;
      case TravelBadge.chatChampion:
        return Colors.deepPurple;
    }
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Milestone Progress Row
// ─────────────────────────────────────────────────────────────────────────────

class _MilestoneRow extends StatelessWidget {
  final MilestoneProgress milestone;
  final AppColors colors;

  const _MilestoneRow({required this.milestone, required this.colors});

  @override
  Widget build(BuildContext context) {
    final badge = milestone.badge;
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Row(
        children: [
          Text(badge.emoji, style: const TextStyle(fontSize: 16)),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      badge.label,
                      style: GoogleFonts.inter(
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                        color: colors.textPrimary,
                      ),
                    ),
                    Text(
                      '${milestone.currentValue}/${badge.threshold}',
                      style: GoogleFonts.inter(
                        fontSize: 11,
                        color: colors.textMuted,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 4),
                ClipRRect(
                  borderRadius: BorderRadius.circular(4),
                  child: LinearProgressIndicator(
                    value: milestone.progress,
                    minHeight: 5,
                    backgroundColor: colors.border,
                    valueColor:
                        const AlwaysStoppedAnimation<Color>(AppColors.brand),
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
