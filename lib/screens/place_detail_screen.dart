import 'package:flutter/material.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:share_plus/share_plus.dart';
import '../models/trip_plan.dart';
import '../models/place_insights.dart';
import '../services/trip_service.dart';
import '../services/google_places_service.dart';
import '../theme/app_colors.dart';
import '../theme/theme_extensions.dart';

class PlaceDetailScreen extends StatefulWidget {
  final TripPlanPlace place;
  final String? tripLocation; // For AI context

  const PlaceDetailScreen({super.key, required this.place, this.tripLocation});

  @override
  State<PlaceDetailScreen> createState() => _PlaceDetailScreenState();
}

class _PlaceDetailScreenState extends State<PlaceDetailScreen> {
  Map<String, dynamic>? _googleDetails;
  PlaceInsights? _insights;
  List<Map<String, dynamic>> _nearbyPlaces = [];
  bool _loadingDetails = true;
  bool _loadingInsights = true;
  bool _loadingNearby = true;

  TripPlanPlace get place => widget.place;

  @override
  void initState() {
    super.initState();
    _loadAllData();
  }

  Future<void> _loadAllData() async {
    // Fetch Google details, AI insights, and nearby places in parallel
    await Future.wait([
      _loadGoogleDetails(),
      _loadAiInsights(),
      _loadNearbyPlaces(),
    ]);
  }

  Future<void> _loadGoogleDetails() async {
    try {
      final details = await GooglePlacesService().getPlaceDetails(place.googlePlaceId);
      if (mounted) setState(() { _googleDetails = details; _loadingDetails = false; });
    } catch (e) {
      if (mounted) setState(() => _loadingDetails = false);
    }
  }

  Future<void> _loadAiInsights({bool forceRefresh = false}) async {
    try {
      final tripService = TripService();
      var insights = forceRefresh ? null : await tripService.getPlaceInsights(place.googlePlaceId);
      if (insights == null || insights.isStale) {
        insights = await tripService.enrichPlaceInsights(
          place.googlePlaceId, place.name, widget.tripLocation, placeType: place.type);
      }
      if (mounted) setState(() { _insights = insights; _loadingInsights = false; });
    } catch (e) {
      if (mounted) setState(() => _loadingInsights = false);
    }
  }

  Future<void> _loadNearbyPlaces() async {
    try {
      final nearby = await GooglePlacesService().searchNearby(
        place.latitude, place.longitude, radius: 2000);
      // Filter out the current place
      final filtered = nearby.where((p) => p['place_id'] != place.googlePlaceId).take(6).toList();
      if (mounted) setState(() { _nearbyPlaces = filtered; _loadingNearby = false; });
    } catch (e) {
      if (mounted) setState(() => _loadingNearby = false);
    }
  }

  Future<void> _launchMaps() async {
    final uri = Uri.parse("https://www.google.com/maps/search/?api=1&query=${place.latitude},${place.longitude}&query_place_id=${place.googlePlaceId}");
    if (await canLaunchUrl(uri)) {
      await launchUrl(uri);
    }
  }

  Future<void> _sharePlace() async {
    final mapsUrl = "https://www.google.com/maps/search/?api=1&query=${place.latitude},${place.longitude}&query_place_id=${place.googlePlaceId}";
    await Share.share('Check out ${place.name}!\n$mapsUrl');
  }

  String get _basicInfo {
    if (place.description == null) return "";
    var desc = place.description!;
    if (desc.contains("✨ AI Insight:")) {
       var endOfInsight = desc.indexOf("\n\n");
       if (endOfInsight != -1) {
          return desc.substring(endOfInsight + 2).trim();
       }
    }
    return desc.trim();
  }

  String? get _communityNotes {
    if (place.aiInsight != null && place.aiInsight!.isNotEmpty) return place.aiInsight;
    if (place.description == null) return null;
    var desc = place.description!;
    if (desc.contains("✨ AI Insight:")) {
       var start = desc.indexOf("✨ AI Insight:") + "✨ AI Insight:".length;
       var end = desc.indexOf("\n\n", start);
       if (end == -1) end = desc.length;
       return desc.substring(start, end).trim();
    }
    return null;
  }

  String _priceLevelString(String? priceLevel) {
    switch (priceLevel) {
      case 'PRICE_LEVEL_FREE': return 'Free';
      case 'PRICE_LEVEL_INEXPENSIVE': return '\$';
      case 'PRICE_LEVEL_MODERATE': return '\$\$';
      case 'PRICE_LEVEL_EXPENSIVE': return '\$\$\$';
      case 'PRICE_LEVEL_VERY_EXPENSIVE': return '\$\$\$\$';
      default: return 'N/A';
    }
  }

  @override
  Widget build(BuildContext context) {
    final colors = context.appColors;
    final isDark = context.isDark;
    return Scaffold(
      backgroundColor: colors.scaffoldBg,
      body: CustomScrollView(
        slivers: [
          // 1. Premium Hero Section with Parallax
          SliverAppBar(
            expandedHeight: 400,
            pinned: true,
            stretch: true,
            leading: Padding(
              padding: const EdgeInsets.all(12.0),
              child: ClipRRect(
                borderRadius: BorderRadius.circular(12),
                child: BackdropFilter(
                  filter: ColorFilter.mode(Colors.black.withOpacity(0.3), BlendMode.darken),
                  child: Container(
                    color: Colors.black26,
                    child: IconButton(
                      icon: const Icon(Icons.arrow_back, color: Colors.white, size: 20),
                      onPressed: () => Navigator.pop(context),
                    ),
                  ),
                ),
              ),
            ),
            backgroundColor: colors.scaffoldBg,
            flexibleSpace: FlexibleSpaceBar(
              stretchModes: const [
                StretchMode.zoomBackground,
                StretchMode.fadeTitle,
              ],
              background: Stack(
                fit: StackFit.expand,
                children: [
                  Hero(
                    tag: 'place-image-${place.id}',
                    child: place.imageUrl != null
                        ? CachedNetworkImage(
                            imageUrl: place.imageUrl!,
                            fit: BoxFit.cover,
                            placeholder: (context, url) => Container(color: Colors.grey.shade100),
                            errorWidget: (context, url, error) => Container(
                              color: Colors.grey.shade200,
                              child: const Icon(Icons.error_outline, color: Colors.grey),
                            ),
                          )
                        : Container(
                            color: Colors.grey.shade200,
                            child: const Icon(Icons.image, size: 100, color: Colors.grey),
                          ),
                  ),
                  const DecoratedBox(
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        begin: Alignment.topCenter,
                        end: Alignment.bottomCenter,
                        colors: [
                          Colors.black26,
                          Colors.transparent,
                          Colors.transparent,
                          Colors.black54,
                        ],
                        stops: [0.0, 0.3, 0.7, 1.0],
                      ),
                    ),
                  ),
                  Positioned(
                    bottom: 24,
                    left: 24,
                    right: 24,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                          decoration: BoxDecoration(
                            color: AppColors.brand,
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: Text(
                            place.type.toUpperCase(),
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 10,
                              fontWeight: FontWeight.bold,
                              letterSpacing: 1.2,
                            ),
                          ),
                        ),
                        const SizedBox(height: 12),
                        Text(
                          place.name,
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 32,
                            fontWeight: FontWeight.bold,
                            letterSpacing: -0.5,
                          ),
                        ),
                        if (_googleDetails?['address'] != null)
                          Padding(
                            padding: const EdgeInsets.only(top: 6),
                            child: Text(
                              _googleDetails!['address'],
                              style: TextStyle(color: Colors.white.withOpacity(0.8), fontSize: 13),
                              maxLines: 2,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),

          // 2. Content Section
          SliverToBoxAdapter(
            child: Container(
              decoration: BoxDecoration(
                color: colors.cardBg,
                borderRadius: const BorderRadius.vertical(top: Radius.circular(32)),
              ),
              child: Padding(
                padding: const EdgeInsets.fromLTRB(24, 32, 24, 40),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Action Buttons Row
                    Row(
                      children: [
                        Expanded(
                          flex: 2,
                          child: ElevatedButton.icon(
                            onPressed: _launchMaps,
                            icon: const Icon(Icons.directions_outlined, size: 20),
                            label: const Text("Get Directions", style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                            style: ElevatedButton.styleFrom(
                              backgroundColor: colors.textPrimary,
                              foregroundColor: colors.scaffoldBg,
                              elevation: 0,
                              padding: const EdgeInsets.symmetric(vertical: 16),
                              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                            ),
                          ),
                        ),
                        const SizedBox(width: 12),
                        Container(
                          decoration: BoxDecoration(
                            color: colors.surfaceBg,
                            borderRadius: BorderRadius.circular(16),
                            border: Border.all(color: colors.border),
                          ),
                          child: IconButton(
                            onPressed: _sharePlace,
                            icon: Icon(Icons.share_outlined, color: colors.textPrimary),
                            padding: const EdgeInsets.all(16),
                            tooltip: "Share",
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 28),

                    // Quick Facts Grid (from Google + AI)
                    _buildQuickFactsGrid(colors),
                    const SizedBox(height: 28),

                    // Opening Hours
                    if (_googleDetails?['opening_hours'] != null)
                      ...[
                        _buildOpeningHours(colors, isDark),
                        const SizedBox(height: 28),
                      ],

                    // Basic Info
                    if (_basicInfo.isNotEmpty) ...[
                      Text("About", style: GoogleFonts.outfit(fontSize: 20, fontWeight: FontWeight.bold, color: colors.textPrimary)),
                      const SizedBox(height: 10),
                      Text(_basicInfo, style: TextStyle(fontSize: 15, color: colors.textSecondary, height: 1.6)),
                      if (_googleDetails?['summary'] != null && (_googleDetails!['summary'] as String).isNotEmpty) ...[
                        const SizedBox(height: 8),
                        Text(_googleDetails!['summary'], style: TextStyle(fontSize: 14, color: colors.textMuted, height: 1.5, fontStyle: FontStyle.italic)),
                      ],
                      const SizedBox(height: 28),
                    ],

                    // Entry & Ticket Details (from AI)
                    if (_insights != null) ...[
                      _buildEntryDetails(colors, isDark),
                      const SizedBox(height: 28),
                    ],

                    // Best Time to Visit (from AI)
                    if (_insights?.bestTimeToVisit != null) ...[
                      _buildBestTimeSection(colors, isDark),
                      const SizedBox(height: 28),
                    ],

                    // Insider Tips (from AI)
                    if (_insights != null && _insights!.insiderTips.isNotEmpty) ...[
                      _buildInsiderTips(colors, isDark),
                      const SizedBox(height: 28),
                    ],

                    // AI Travel Analysis
                    if (_insights != null) ...[
                      _buildAiAnalysis(colors, isDark),
                      const SizedBox(height: 28),
                    ],

                    // Practical Info (new B1 fields)
                    if (_insights != null)
                      ..._buildPracticalInfo(colors, isDark),

                    // Nearby Attractions
                    if (_nearbyPlaces.isNotEmpty) ...[
                      _buildNearbyAttractions(colors),
                      const SizedBox(height: 28),
                    ],

                    // Community Notes
                    if (_communityNotes != null && _communityNotes!.isNotEmpty) ...[
                      _buildCommunityNotes(colors, isDark),
                      const SizedBox(height: 28),
                    ],

                    // Website & Contact
                    if (_googleDetails != null)
                      _buildContactSection(colors, isDark),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  // ── Section Builders ──────────────────────────────────────────────

  Widget _buildQuickFactsGrid(AppColors colors) {
    final rating = _googleDetails?['rating'] ?? place.rating;
    final ratingCount = _googleDetails?['user_rating_count'];
    final priceLevel = _priceLevelString(_googleDetails?['price_level']);
    final duration = _insights?.avgVisitDuration ?? (place.arrivalTime != null ? '~${place.arrivalTime}' : null);
    final crowd = _insights?.crowdLevel;

    final List<Widget> tiles = [];
    if (rating != null) {
      tiles.add(_infoTile(Icons.star_rounded, "Rating",
          "$rating${ratingCount != null ? ' ($ratingCount)' : ''}"));
    }
    if (priceLevel != 'N/A') {
      tiles.add(_infoTile(Icons.payments_rounded, "Price", priceLevel));
    }
    if (_loadingInsights) {
      tiles.add(_infoTile(Icons.timer_rounded, "Duration", "Loading..."));
      tiles.add(_infoTile(Icons.groups_rounded, "Crowds", "Loading..."));
    } else {
      if (duration != null) {
        tiles.add(_infoTile(Icons.timer_rounded, "Duration", duration));
      }
      if (crowd != null) {
        tiles.add(_infoTile(Icons.groups_rounded, "Crowds", crowd));
      }
    }

    if (tiles.isEmpty) return const SizedBox.shrink();

    return Wrap(
      spacing: 12,
      runSpacing: 12,
      children: tiles.map((t) => SizedBox(
        width: (MediaQuery.of(context).size.width - 24 * 2 - 12) / 2,
        child: t,
      )).toList(),
    );
  }

  Widget _buildOpeningHours(AppColors colors, bool isDark) {
    final hours = _googleDetails?['opening_hours'];
    if (hours == null) return const SizedBox.shrink();

    final weekdays = hours['weekdayDescriptions'] as List<dynamic>? ?? [];
    final isOpen = hours['openNow'] as bool? ?? false;

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: colors.surfaceBg,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: colors.border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(Icons.schedule, size: 18, color: AppColors.brand),
              const SizedBox(width: 8),
              Text("Opening Hours", style: GoogleFonts.outfit(fontSize: 16, fontWeight: FontWeight.bold, color: colors.textPrimary)),
              const Spacer(),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                decoration: BoxDecoration(
                  color: isOpen ? Colors.green.withOpacity(0.15) : Colors.red.withOpacity(0.15),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text(
                  isOpen ? "Open Now" : "Closed",
                  style: TextStyle(
                    color: isOpen ? Colors.green : Colors.red,
                    fontSize: 12,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ],
          ),
          if (weekdays.isNotEmpty) ...[
            const SizedBox(height: 12),
            ...weekdays.map((day) => Padding(
              padding: const EdgeInsets.symmetric(vertical: 2),
              child: Text(day.toString(),
                  style: TextStyle(fontSize: 13, color: colors.textSecondary, height: 1.4)),
            )),
          ],
        ],
      ),
    );
  }

  Widget _buildEntryDetails(AppColors colors, bool isDark) {
    final ins = _insights!;
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: colors.surfaceBg,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: colors.border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(children: [
            const Icon(Icons.confirmation_number_outlined, size: 18, color: AppColors.brand),
            const SizedBox(width: 8),
            Text("Entry Details", style: GoogleFonts.outfit(fontSize: 16, fontWeight: FontWeight.bold, color: colors.textPrimary)),
          ]),
          const SizedBox(height: 12),
          _detailRow(colors, "Ticket Required", ins.ticketRequired ? "Yes" : "No",
              icon: ins.ticketRequired ? Icons.check_circle : Icons.cancel,
              iconColor: ins.ticketRequired ? Colors.orange : Colors.green),
          if (ins.ticketPriceEstimate != null)
            _detailRow(colors, "Estimated Price", ins.ticketPriceEstimate!),
          if (ins.onlineBookingRecommended)
            _detailRow(colors, "Online Booking", "Recommended",
                icon: Icons.info_outline, iconColor: AppColors.brand),
          if (ins.onsiteBookingAvailable)
            _detailRow(colors, "Onsite Booking", "Available"),
          if (ins.avgWaitingTime != null)
            _detailRow(colors, "Avg Wait", ins.avgWaitingTime!),
          if (ins.peakHours != null)
            _detailRow(colors, "Peak Hours", ins.peakHours!),
          if (ins.bookingUrl != null) ...[
            const SizedBox(height: 8),
            GestureDetector(
              onTap: () async {
                final url = Uri.parse(ins.bookingUrl!);
                if (await canLaunchUrl(url)) launchUrl(url, mode: LaunchMode.externalApplication);
              },
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                decoration: BoxDecoration(
                  color: AppColors.brand.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(Icons.open_in_new, size: 16, color: AppColors.brand),
                    const SizedBox(width: 8),
                    Text("Book Online", style: TextStyle(color: AppColors.brand, fontWeight: FontWeight.w600, fontSize: 13)),
                  ],
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildBestTimeSection(AppColors colors, bool isDark) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: isDark ? Colors.deepPurple.withOpacity(0.12) : Colors.deepPurple.shade50,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: isDark ? Colors.deepPurple.withOpacity(0.3) : Colors.deepPurple.shade100),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: Colors.deepPurple.withOpacity(0.15),
              borderRadius: BorderRadius.circular(12),
            ),
            child: const Icon(Icons.wb_sunny_outlined, color: Colors.deepPurple, size: 24),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text("Best Time to Visit", style: TextStyle(fontSize: 12, color: colors.textMuted, fontWeight: FontWeight.w500)),
                const SizedBox(height: 2),
                Text(_insights!.bestTimeToVisit!,
                    style: TextStyle(fontSize: 14, fontWeight: FontWeight.w600, color: colors.textPrimary, height: 1.4)),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildInsiderTips(AppColors colors, bool isDark) {
    final tips = _insights!.insiderTips;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(children: [
          const Icon(Icons.lightbulb_outline, color: Colors.amber, size: 20),
          const SizedBox(width: 8),
          Text("Insider Tips", style: GoogleFonts.outfit(fontSize: 20, fontWeight: FontWeight.bold, color: colors.textPrimary)),
        ]),
        const SizedBox(height: 12),
        ...tips.map((tip) => Padding(
          padding: const EdgeInsets.only(bottom: 8),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                margin: const EdgeInsets.only(top: 6),
                width: 6, height: 6,
                decoration: BoxDecoration(color: AppColors.brand, shape: BoxShape.circle),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Text(tip, style: TextStyle(fontSize: 14, color: colors.textSecondary, height: 1.5)),
              ),
            ],
          ),
        )),
      ],
    );
  }

  Widget _buildAiAnalysis(AppColors colors, bool isDark) {
    final ins = _insights!;
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: colors.surfaceBg,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: colors.border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(children: [
            const Icon(Icons.auto_awesome, color: Colors.purple, size: 18),
            const SizedBox(width: 8),
            Expanded(
              child: Text("AI Travel Analysis", style: GoogleFonts.outfit(fontSize: 16, fontWeight: FontWeight.bold, color: colors.textPrimary)),
            ),
            GestureDetector(
              onTap: () {
                setState(() => _loadingInsights = true);
                _loadAiInsights(forceRefresh: true);
              },
              child: Icon(Icons.refresh, size: 18, color: colors.textMuted),
            ),
          ]),
          if (ins.updatedAt != null)
            Padding(
              padding: const EdgeInsets.only(top: 2),
              child: Text(
                "Updated ${_timeAgo(ins.updatedAt!)}",
                style: TextStyle(fontSize: 10, color: colors.textMuted),
              ),
            ),
          const SizedBox(height: 14),
          if (ins.isWorthVisiting != null)
            _analysisRow(colors, "Worth Visiting", ins.isWorthVisiting!, Icons.thumb_up_outlined),
          _analysisChip(colors, "Family Friendly", ins.familyFriendly),
          _analysisChip(colors, "Budget Friendly", ins.budgetFriendly),
          if (ins.safetyRating != null)
            _analysisRow(colors, "Safety", ins.safetyRating!, Icons.shield_outlined),
          if (ins.estimatedCostPerPerson != null)
            _analysisRow(colors, "Cost/Person", ins.estimatedCostPerPerson!, Icons.account_balance_wallet_outlined),
          if (ins.localTips != null && ins.localTips!.isNotEmpty)
            _analysisRow(colors, "Local Tips", ins.localTips!, Icons.emoji_people),
        ],
      ),
    );
  }

  Widget _analysisRow(AppColors colors, String label, String value, IconData icon) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, size: 16, color: AppColors.brand),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(label, style: TextStyle(fontSize: 12, color: colors.textMuted, fontWeight: FontWeight.w500)),
                const SizedBox(height: 2),
                Text(value, style: TextStyle(fontSize: 14, color: colors.textPrimary, height: 1.4)),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _analysisChip(AppColors colors, String label, bool value) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Row(
        children: [
          Icon(value ? Icons.check_circle : Icons.cancel,
              size: 16, color: value ? Colors.green : Colors.red.shade300),
          const SizedBox(width: 10),
          Text(label, style: TextStyle(fontSize: 14, color: colors.textPrimary)),
        ],
      ),
    );
  }

  /// Builds practical info chips (parking, restrooms, photography, wheelchair)
  List<Widget> _buildPracticalInfo(AppColors colors, bool isDark) {
    final ins = _insights!;
    final chips = <Widget>[];
    final googleParking = _googleDetails?['parking'];
    final googleAccessibility = _googleDetails?['accessibility'];

    final hasParkingInfo = ins.parkingAvailable || (googleParking != null);
    final hasAccessibility = ins.wheelchairAccessible ||
        (googleAccessibility != null && googleAccessibility['wheelchairAccessibleEntrance'] == true);

    if (!hasParkingInfo && !ins.nearbyRestrooms && ins.photographyAllowed && !hasAccessibility) {
      return [];
    }

    chips.add(
      Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: colors.surfaceBg,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: colors.border),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(children: [
              const Icon(Icons.info_outline, size: 18, color: AppColors.brand),
              const SizedBox(width: 8),
              Text("Practical Info", style: GoogleFonts.outfit(fontSize: 16, fontWeight: FontWeight.bold, color: colors.textPrimary)),
            ]),
            const SizedBox(height: 12),
            Wrap(
              spacing: 12,
              runSpacing: 8,
              children: [
                if (hasParkingInfo)
                  _practicalChip(colors, Icons.local_parking, "Parking", true),
                if (ins.nearbyRestrooms)
                  _practicalChip(colors, Icons.wc, "Restrooms", true),
                if (!ins.photographyAllowed)
                  _practicalChip(colors, Icons.no_photography, "No Photos", false),
                if (hasAccessibility)
                  _practicalChip(colors, Icons.accessible, "Wheelchair", true),
              ],
            ),
          ],
        ),
      ),
    );
    chips.add(const SizedBox(height: 28));
    return chips;
  }

  Widget _practicalChip(AppColors colors, IconData icon, String label, bool positive) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: (positive ? Colors.green : Colors.red).withOpacity(0.1),
        borderRadius: BorderRadius.circular(10),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 14, color: positive ? Colors.green : Colors.red.shade400),
          const SizedBox(width: 6),
          Text(label, style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: positive ? Colors.green : Colors.red.shade400)),
        ],
      ),
    );
  }

  String _timeAgo(DateTime date) {
    final diff = DateTime.now().difference(date);
    if (diff.inDays > 30) return '${(diff.inDays / 30).floor()} months ago';
    if (diff.inDays > 0) return '${diff.inDays} days ago';
    if (diff.inHours > 0) return '${diff.inHours} hours ago';
    return 'just now';
  }

  Widget _buildNearbyAttractions(AppColors colors) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text("Nearby Attractions", style: GoogleFonts.outfit(fontSize: 20, fontWeight: FontWeight.bold, color: colors.textPrimary)),
        const SizedBox(height: 12),
        SizedBox(
          height: 190,
          child: ListView.builder(
            scrollDirection: Axis.horizontal,
            itemCount: _nearbyPlaces.length,
            itemBuilder: (ctx, i) {
              final p = _nearbyPlaces[i];
              return GestureDetector(
                onTap: () {
                  // Could navigate to another PlaceDetailScreen if we had a TripPlanPlace
                  // For now, open in maps
                  final loc = p['location'];
                  if (loc != null) {
                    final url = Uri.parse("https://www.google.com/maps/search/?api=1&query=${loc['latitude']},${loc['longitude']}&query_place_id=${p['place_id']}");
                    launchUrl(url);
                  }
                },
                child: Container(
                  width: 150,
                  margin: EdgeInsets.only(right: i < _nearbyPlaces.length - 1 ? 12 : 0),
                  decoration: BoxDecoration(
                    color: colors.surfaceBg,
                    borderRadius: BorderRadius.circular(14),
                    border: Border.all(color: colors.border),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      ClipRRect(
                        borderRadius: const BorderRadius.vertical(top: Radius.circular(14)),
                        child: p['image_url'] != null
                            ? CachedNetworkImage(
                                imageUrl: p['image_url'],
                                width: 150, height: 95, fit: BoxFit.cover,
                                memCacheWidth: 300,
                              )
                            : Container(
                                width: 150, height: 95,
                                color: colors.border,
                                child: Icon(Icons.place, color: colors.textMuted),
                              ),
                      ),
                      Expanded(
                        child: Padding(
                          padding: const EdgeInsets.all(8),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Text(p['name'] ?? '',
                                  style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: colors.textPrimary),
                                  maxLines: 2, overflow: TextOverflow.ellipsis),
                              if (p['rating'] != null) ...[
                                const SizedBox(height: 2),
                                Row(children: [
                                  Icon(Icons.star, size: 12, color: Colors.amber.shade600),
                                  const SizedBox(width: 3),
                                  Text("${p['rating']}", style: TextStyle(fontSize: 11, color: colors.textMuted)),
                                ]),
                              ],
                            ],
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              );
            },
          ),
        ),
      ],
    );
  }

  Widget _buildCommunityNotes(AppColors colors, bool isDark) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text("Community Notes", style: GoogleFonts.outfit(fontSize: 20, fontWeight: FontWeight.bold, color: colors.textPrimary)),
        const SizedBox(height: 12),
        Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: isDark ? Colors.amber.withOpacity(0.1) : Colors.amber.shade50,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: isDark ? Colors.amber.withOpacity(0.3) : Colors.amber.shade200),
          ),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Icon(Icons.lightbulb_outline, color: Colors.amber.shade800, size: 20),
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  _communityNotes!,
                  style: TextStyle(
                    fontSize: 15,
                    color: isDark ? Colors.amber.shade200 : Colors.amber.shade900,
                    height: 1.5,
                    fontStyle: FontStyle.italic,
                  ),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildContactSection(AppColors colors, bool isDark) {
    final website = _googleDetails?['website'];
    final phone = _googleDetails?['phone'];
    if (website == null && phone == null) return const SizedBox.shrink();

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: colors.surfaceBg,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: colors.border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text("Contact", style: GoogleFonts.outfit(fontSize: 16, fontWeight: FontWeight.bold, color: colors.textPrimary)),
          const SizedBox(height: 10),
          if (website != null)
            GestureDetector(
              onTap: () async {
                final url = Uri.parse(website);
                if (await canLaunchUrl(url)) launchUrl(url, mode: LaunchMode.externalApplication);
              },
              child: Padding(
                padding: const EdgeInsets.symmetric(vertical: 6),
                child: Row(children: [
                  Icon(Icons.language, size: 18, color: AppColors.brand),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Text(website, style: TextStyle(color: AppColors.brand, fontSize: 13),
                        maxLines: 1, overflow: TextOverflow.ellipsis),
                  ),
                ]),
              ),
            ),
          if (phone != null)
            GestureDetector(
              onTap: () => launchUrl(Uri.parse('tel:$phone')),
              child: Padding(
                padding: const EdgeInsets.symmetric(vertical: 6),
                child: Row(children: [
                  Icon(Icons.phone, size: 18, color: AppColors.brand),
                  const SizedBox(width: 10),
                  Text(phone, style: TextStyle(color: AppColors.brand, fontSize: 13)),
                ]),
              ),
            ),
        ],
      ),
    );
  }

  // ── Helpers ──────────────────────────────────────────────────────

  Widget _detailRow(AppColors colors, String label, String value,
      {IconData? icon, Color? iconColor}) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Row(mainAxisSize: MainAxisSize.min, children: [
            if (icon != null) ...[
              Icon(icon, size: 14, color: iconColor ?? colors.textMuted),
              const SizedBox(width: 6),
            ],
            Text(label, style: TextStyle(color: colors.textSecondary, fontSize: 13)),
          ]),
          const SizedBox(width: 12),
          Flexible(
            child: Text(
              value,
              style: TextStyle(fontWeight: FontWeight.w600, fontSize: 13, color: colors.textPrimary),
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
              textAlign: TextAlign.end,
            ),
          ),
        ],
      ),
    );
  }

  Widget _infoTile(IconData icon, String label, String value) {
    return Builder(
      builder: (context) {
        final colors = context.appColors;
        return Container(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
          decoration: BoxDecoration(
            color: colors.surfaceBg,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: colors.border),
          ),
          child: Row(
            children: [
              Icon(icon, size: 24, color: colors.textPrimary),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      label,
                      style: TextStyle(fontSize: 11, color: colors.textSecondary, fontWeight: FontWeight.w500),
                    ),
                    Text(
                      value,
                      style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold, color: colors.textPrimary),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ],
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}
