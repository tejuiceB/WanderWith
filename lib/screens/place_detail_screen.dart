import 'package:flutter/material.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter_rating_bar/flutter_rating_bar.dart'; // We might need to add this or use simple icons
import 'package:url_launcher/url_launcher.dart';
import '../models/trip_plan.dart';

class PlaceDetailScreen extends StatelessWidget {
  final TripPlanPlace place;

  const PlaceDetailScreen({super.key, required this.place});

  Future<void> _launchMaps() async {
    // Launch Google Maps with navigation to this place
    final uri = Uri.parse("https://www.google.com/maps/search/?api=1&query=${place.latitude},${place.longitude}&query_place_id=${place.googlePlaceId}");
    if (await canLaunchUrl(uri)) {
      await launchUrl(uri);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: CustomScrollView(
        slivers: [
          // 1. Hero Image App Bar
          SliverAppBar(
            expandedHeight: 300,
            pinned: true,
            leading: Padding(
              padding: const EdgeInsets.all(8.0),
              child: CircleAvatar(
                backgroundColor: Colors.black45,
                child: IconButton(
                  icon: const Icon(Icons.arrow_back, color: Colors.white),
                  onPressed: () => Navigator.pop(context),
                ),
              ),
            ),
            flexibleSpace: FlexibleSpaceBar(
              // Title hidden when expanded to avoid text over image issues, shown when collapsed handled by system or custom title logic if needed.
              // We'll put the title in the body for the "Clean Startup" look
              background: Stack(
                fit: StackFit.expand,
                children: [
                   place.imageUrl != null
                    ? CachedNetworkImage(
                        imageUrl: place.imageUrl!,
                        fit: BoxFit.cover,
                        placeholder: (context, url) => Container(color: Colors.grey[300]),
                        errorWidget: (context, url, error) => const Icon(Icons.error),
                      )
                    : Container(color: Colors.grey, child: const Icon(Icons.image, size: 50, color: Colors.white)),
                   // Gradient overlay for text readability if we had text here
                   const DecoratedBox(
                     decoration: BoxDecoration(
                       gradient: LinearGradient(
                         begin: Alignment.topCenter,
                         end: Alignment.bottomCenter,
                         colors: [Colors.transparent, Colors.black26],
                       )
                     ),
                   ),
                ],
              ),
            ),
          ),

          // 2. Content
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.all(24.0), // More padding for premium feel
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Title
                  Text(
                    place.name,
                    style: const TextStyle(fontSize: 28, fontWeight: FontWeight.bold, height: 1.2),
                  ),
                  const SizedBox(height: 8),

                  // Type & Rating
                  Row(
                    children: [
                      Chip(label: Text(place.type), backgroundColor: Colors.blue.shade50),
                      const Spacer(),
                      if (place.rating != null) ...[
                        const Icon(Icons.star, color: Colors.amber, size: 20),
                        const SizedBox(width: 4),
                        Text("${place.rating} / 5.0", style: const TextStyle(fontWeight: FontWeight.bold)),
                      ]
                    ],
                  ),
                  const SizedBox(height: 16),

                  // Actions
                  Row(
                    children: [
                      Expanded(
                        child: ElevatedButton.icon(
                          onPressed: _launchMaps,
                          icon: const Icon(Icons.directions),
                          label: const Text("Get Directions"),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.blue,
                            foregroundColor: Colors.white,
                            padding: const EdgeInsets.symmetric(vertical: 12),
                          ),
                        ),
                      ),
                      const SizedBox(width: 12),
                      OutlinedButton.icon(
                        onPressed: () {
                           // TODO: Save to saved places
                        },
                        icon: const Icon(Icons.bookmark_border),
                        label: const Text("Save"),
                         style: OutlinedButton.styleFrom(
                            padding: const EdgeInsets.symmetric(vertical: 12),
                          ),
                      )
                    ],
                  ),
                  const SizedBox(height: 24),

                  // Description
                  const Text("About this place", style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                  const SizedBox(height: 8),
                  Text(
                    place.description ?? "No description available for this place.",
                    style: const TextStyle(fontSize: 16, height: 1.5, color: Colors.black87),
                  ),

                  const SizedBox(height: 24),
                  
                  // Details Box (Mock data for now since we only fetch basic info)
                  Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: Colors.grey.shade100,
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: const Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text("Community Notes", style: TextStyle(fontWeight: FontWeight.bold)),
                        SizedBox(height: 8),
                        _NoteRow(icon: Icons.access_time, text: "Best time: Early morning"),
                        _NoteRow(icon: Icons.accessibility, text: "Wheelchair accessible"),
                        _NoteRow(icon: Icons.camera_alt, text: "Great for photography"),
                      ],
                    ),
                  )
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _NoteRow extends StatelessWidget {
  final IconData icon;
  final String text;
  const _NoteRow({required this.icon, required this.text});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8.0),
      child: Row(
        children: [
          Icon(icon, size: 16, color: Colors.grey.shade600),
          const SizedBox(width: 8),
          Text(text, style: TextStyle(color: Colors.grey.shade800)),
        ],
      ),
    );
  }
}
