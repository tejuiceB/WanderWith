import 'package:flutter/material.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:url_launcher/url_launcher.dart';
import '../models/trip_plan.dart';

class PlaceDetailScreen extends StatelessWidget {
  final TripPlanPlace place;

  const PlaceDetailScreen({super.key, required this.place});

  Future<void> _launchMaps() async {
    final uri = Uri.parse("https://www.google.com/maps/search/?api=1&query=${place.latitude},${place.longitude}&query_place_id=${place.googlePlaceId}");
    if (await canLaunchUrl(uri)) {
      await launchUrl(uri);
    }
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

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
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
            backgroundColor: Colors.white,
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
                            color: Colors.blue.shade600,
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
              decoration: const BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.vertical(top: Radius.circular(32)),
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
                              backgroundColor: Colors.black87,
                              foregroundColor: Colors.white,
                              elevation: 0,
                              padding: const EdgeInsets.symmetric(vertical: 16),
                              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                            ),
                          ),
                        ),
                        const SizedBox(width: 12),
                        Container(
                          decoration: BoxDecoration(
                            color: Colors.grey.shade100,
                            borderRadius: BorderRadius.circular(16),
                            border: Border.all(color: Colors.grey.shade200),
                          ),
                          child: IconButton(
                            onPressed: () {},
                            icon: const Icon(Icons.add_circle_outline, color: Colors.black87),
                            padding: const EdgeInsets.all(16),
                          ),
                        ),
                        const SizedBox(width: 12),
                        Container(
                          decoration: BoxDecoration(
                            color: Colors.grey.shade100,
                            borderRadius: BorderRadius.circular(16),
                            border: Border.all(color: Colors.grey.shade200),
                          ),
                          child: IconButton(
                            onPressed: () {},
                            icon: const Icon(Icons.bookmark_border, color: Colors.black87),
                            padding: const EdgeInsets.all(16),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 32),

                    // Beautiful Info Overview
                    if (_basicInfo.isNotEmpty) ...[
                      Text(
                        "Basic Info",
                        style: TextStyle(
                          fontSize: 22,
                          fontWeight: FontWeight.bold,
                          color: Colors.grey.shade900,
                        ),
                      ),
                      const SizedBox(height: 12),
                      Text(
                        _basicInfo,
                        style: TextStyle(
                          fontSize: 16,
                          color: Colors.grey.shade700,
                          height: 1.6,
                        ),
                      ),
                      const SizedBox(height: 32),
                    ],

                    if (_communityNotes != null && _communityNotes!.isNotEmpty) ...[
                      Text(
                        "Community Notes",
                        style: TextStyle(
                          fontSize: 22,
                          fontWeight: FontWeight.bold,
                          color: Colors.grey.shade900,
                        ),
                      ),
                      const SizedBox(height: 12),
                      Container(
                        padding: const EdgeInsets.all(16),
                        decoration: BoxDecoration(
                          color: Colors.amber.shade50,
                          borderRadius: BorderRadius.circular(16),
                          border: Border.all(color: Colors.amber.shade200),
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
                                  color: Colors.amber.shade900,
                                  height: 1.5,
                                  fontStyle: FontStyle.italic,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 32),
                    ],

                    Text(
                      "Details",
                      style: TextStyle(
                        fontSize: 22,
                        fontWeight: FontWeight.bold,
                        color: Colors.grey.shade900,
                      ),
                    ),
                    const SizedBox(height: 16),

                    // Info Grid
                    GridView.count(
                      crossAxisCount: 2,
                      shrinkWrap: true,
                      physics: const NeverScrollableScrollPhysics(),
                      mainAxisSpacing: 12,
                      crossAxisSpacing: 12,
                      childAspectRatio: 2.5,
                      children: [
                        _infoTile(Icons.star_rounded, "Rating", "${place.rating ?? 'N/A'}/5.0"),
                        _infoTile(Icons.access_time_filled_rounded, "Best Time", "Morning"),
                        _infoTile(Icons.timer_rounded, "Duration", "1.5 - 2h"),
                        _infoTile(Icons.payments_rounded, "Price", "Moderate"),
                      ],
                    ),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _infoTile(IconData icon, String label, String value) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      decoration: BoxDecoration(
        color: Colors.grey.shade50,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.grey.shade200),
      ),
      child: Row(
        children: [
          Icon(icon, size: 24, color: Colors.black87),
          const SizedBox(width: 12),
          Column(
            mainAxisAlignment: MainAxisAlignment.center,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                label,
                style: TextStyle(fontSize: 11, color: Colors.grey.shade600, fontWeight: FontWeight.w500),
              ),
              Text(
                value,
                style: const TextStyle(fontSize: 14, fontWeight: FontWeight.bold, color: Colors.black87),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
