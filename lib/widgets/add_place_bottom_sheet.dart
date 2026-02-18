import 'dart:async';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/plan_provider.dart';
import '../models/trip.dart';

class AddPlaceBottomSheet extends StatefulWidget {
  final Trip trip;
  final String dayId;
  final int dayNumber;

  const AddPlaceBottomSheet({
    super.key,
    required this.trip,
    required this.dayId,
    required this.dayNumber,
  });

  @override
  State<AddPlaceBottomSheet> createState() => _AddPlaceBottomSheetState();
}

class _AddPlaceBottomSheetState extends State<AddPlaceBottomSheet> {
  final TextEditingController _searchController = TextEditingController();
  Timer? _debounce;

  @override
  void initState() {
    super.initState();
    // Initial fetch for suggestions
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final provider = Provider.of<PlanProvider>(context, listen: false);
      provider.fetchSuggestions(widget.trip, widget.dayNumber);
      provider.clearPreview();
      provider.clearSearch();
    });
  }

  @override
  void dispose() {
    _searchController.dispose();
    _debounce?.cancel();
    super.dispose();
  }

  void _onSearchChanged(String query) {
    if (_debounce?.isActive ?? false) _debounce?.cancel();
    _debounce = Timer(const Duration(milliseconds: 300), () {
      Provider.of<PlanProvider>(context, listen: false).getAutocomplete(query);
    });
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      height: MediaQuery.of(context).size.height * 0.85,
      decoration: const BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      child: Column(
        children: [
          // Handle
          const SizedBox(height: 12),
          Container(width: 40, height: 4, decoration: BoxDecoration(color: Colors.grey[300], borderRadius: BorderRadius.circular(2))),
          
          // Sticky Top: Search Bar
          Padding(
            padding: const EdgeInsets.all(20.0),
            child: TextField(
              controller: _searchController,
              onChanged: _onSearchChanged,
              decoration: InputDecoration(
                hintText: "Search places, cafes, museums...",
                prefixIcon: const Icon(Icons.search, color: Colors.blue),
                suffixIcon: _searchController.text.isNotEmpty 
                    ? IconButton(
                        icon: const Icon(Icons.clear), 
                        onPressed: () {
                          _searchController.clear();
                          Provider.of<PlanProvider>(context, listen: false).clearSearch();
                        }
                      ) 
                    : null,
                filled: true,
                fillColor: Colors.blue.shade50.withOpacity(0.5),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(20),
                  borderSide: BorderSide.none,
                ),
                contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
              ),
            ),
          ),

          Expanded(
            child: Consumer<PlanProvider>(
              builder: (context, provider, child) {
                // If we are showing a preview
                if (provider.previewPlace != null) {
                  return _buildPreviewCard(provider);
                }

                // If we are searching
                if (_searchController.text.isNotEmpty) {
                  return _buildAutocompleteList(provider);
                }

                // Default: Suggestions view
                return _buildSuggestionsView(provider);
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildAutocompleteList(PlanProvider provider) {
    if (provider.isSearching) {
      return const Center(child: CircularProgressIndicator());
    }

    if (provider.autocompleteSuggestions.isEmpty) {
      return const Center(child: Text("No places found. Try another search."));
    }

    return ListView.builder(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      itemCount: provider.autocompleteSuggestions.length,
      itemBuilder: (context, index) {
        final item = provider.autocompleteSuggestions[index];
        return ListTile(
          leading: const CircleAvatar(
            backgroundColor: Colors.blue,
            child: Icon(Icons.location_on, color: Colors.white, size: 20),
          ),
          title: Text(item['main_text'] ?? ''),
          subtitle: Text(item['description'] ?? '', maxLines: 1, overflow: TextOverflow.ellipsis),
          onTap: () => provider.getPlaceDetailsForPreview(item['place_id']),
        );
      },
    );
  }

  Widget _buildSuggestionsView(PlanProvider provider) {
    return SingleChildScrollView(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // AI Suggestions Section
          if (provider.aiSuggestions.isNotEmpty) ...[
            _buildSectionHeader("✨ Suggested for Day ${widget.dayNumber}", "Based on your vibe"),
            SizedBox(
              height: 180,
              child: ListView.builder(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                scrollDirection: Axis.horizontal,
                itemCount: provider.aiSuggestions.length,
                itemBuilder: (context, index) {
                  final rec = provider.aiSuggestions[index];
                  return _buildSuggestionCard(
                    rec['name'] ?? '', 
                    rec['reason'] ?? '', 
                    const Icon(Icons.auto_awesome, color: Colors.amber),
                    onTap: () => provider.getAutocomplete(rec['name']!), // Trigger search for this place
                  );
                },
              ),
            ),
          ],

          // Nearby Suggestions Section
          if (provider.nearbyPlaces.isNotEmpty) ...[
            _buildSectionHeader("📍 Nearby Spots", "Close to your other stops"),
            SizedBox(
              height: 220,
              child: ListView.builder(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                scrollDirection: Axis.horizontal,
                itemCount: provider.nearbyPlaces.length,
                itemBuilder: (context, index) {
                  final place = provider.nearbyPlaces[index];
                  return _buildPlaceCard(place, provider);
                },
              ),
            ),
          ],

          const SizedBox(height: 40),
        ],
      ),
    );
  }

  Widget _buildSectionHeader(String title, String subtitle) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 10, 20, 12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(title, style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.black87)),
          Text(subtitle, style: TextStyle(fontSize: 13, color: Colors.grey.shade600)),
        ],
      ),
    );
  }

  Widget _buildSuggestionCard(String title, String subtitle, Widget icon, {required VoidCallback onTap}) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: 160,
        margin: const EdgeInsets.only(right: 12),
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: Colors.blue.shade50),
          boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.03), blurRadius: 10, offset: const Offset(0, 4))],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            icon,
            const SizedBox(height: 12),
            Text(title, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14), maxLines: 2, overflow: TextOverflow.ellipsis),
            const SizedBox(height: 4),
            Text(subtitle, style: TextStyle(fontSize: 11, color: Colors.grey.shade600), maxLines: 3, overflow: TextOverflow.ellipsis),
          ],
        ),
      ),
    );
  }

  Widget _buildPlaceCard(Map<String, dynamic> place, PlanProvider provider) {
    return GestureDetector(
      onTap: () => provider.getPlaceDetailsForPreview(place['place_id']),
      child: Container(
        width: 200,
        margin: const EdgeInsets.only(right: 12),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(20),
          boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: 10, offset: const Offset(0, 4))],
        ),
        clipBehavior: Clip.antiAlias,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Expanded(
              child: Stack(
                children: [
                  place['image_url'] != null 
                      ? Image.network(place['image_url'], width: double.infinity, fit: BoxFit.cover)
                      : Container(color: Colors.blue.shade100, child: const Center(child: Icon(Icons.image, color: Colors.white))),
                  if (place['rating'] != null)
                    Positioned(
                      top: 10, right: 10,
                      child: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                        decoration: BoxDecoration(color: Colors.black54, borderRadius: BorderRadius.circular(12)),
                        child: Row(
                          children: [
                            const Icon(Icons.star, color: Colors.amber, size: 12),
                            const SizedBox(width: 4),
                            Text("${place['rating']}", style: const TextStyle(color: Colors.white, fontSize: 10, fontWeight: FontWeight.bold)),
                          ],
                        ),
                      ),
                    ),
                ],
              ),
            ),
            Padding(
              padding: const EdgeInsets.all(12.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(place['name'], style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14), maxLines: 1, overflow: TextOverflow.ellipsis),
                  Text(place['type'] ?? '', style: TextStyle(fontSize: 12, color: Colors.grey.shade600)),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildPreviewCard(PlanProvider provider) {
    final place = provider.previewPlace!;
    return SingleChildScrollView(
      padding: const EdgeInsets.all(24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              IconButton(onPressed: () => provider.clearPreview(), icon: const Icon(Icons.arrow_back)),
              const Spacer(),
              const Text("Preview Place", style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18)),
              const Spacer(),
              const SizedBox(width: 48), // Balance for arrow back
            ],
          ),
          const SizedBox(height: 20),
          ClipRRect(
            borderRadius: BorderRadius.circular(24),
            child: place['image_url'] != null 
                ? Image.network(place['image_url'], height: 200, width: double.infinity, fit: BoxFit.cover)
                : Container(height: 200, color: Colors.blue.shade50),
          ),
          const SizedBox(height: 24),
          Text(place['name'] ?? '', style: const TextStyle(fontSize: 24, fontWeight: FontWeight.bold)),
          const SizedBox(height: 8),
          Row(
            children: [
              const Icon(Icons.star, color: Colors.amber, size: 20),
              const SizedBox(width: 4),
              Text("${place['rating'] ?? 'N/A'}", style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
              if (place['user_rating_count'] != null)
                Text(" (${place['user_rating_count']} reviews)", style: TextStyle(color: Colors.grey.shade600)),
            ],
          ),
          const SizedBox(height: 16),
          if (place['summary'] != null)
             Text(place['summary'], style: TextStyle(fontSize: 15, color: Colors.grey.shade800, height: 1.5)),
          const SizedBox(height: 24),
          
          _buildDetailRow(Icons.location_on, "Address", place['address'] ?? 'Unknown address'),
          _buildDetailRow(Icons.category, "Category", place['type'] ?? 'General'),
          
          const SizedBox(height: 32),
          SizedBox(
            width: double.infinity,
            height: 56,
            child: ElevatedButton(
              onPressed: provider.isLoading ? null : () async {
                try {
                  await provider.addPlace(widget.dayId, place);
                  if (mounted) {
                    Navigator.pop(context);
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        content: Text("✨ ${place['name']} added to your plan!"),
                        backgroundColor: Colors.green.shade600,
                        behavior: SnackBarBehavior.floating,
                      ),
                    );
                  }
                } catch (e) {
                  if (mounted) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        content: Text("Failed to add place: $e"),
                        backgroundColor: Colors.red.shade600,
                      ),
                    );
                  }
                }
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.blue.shade600,
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
              ),
              child: const Text("Add to Timeline", style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
            ),
          ),
          const SizedBox(height: 12),
          Center(
            child: TextButton(
              onPressed: () => provider.clearPreview(), 
              child: const Text("Cancel")
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDetailRow(IconData icon, String label, String value) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 16.0),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, size: 20, color: Colors.blue),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(label, style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: Colors.grey)),
                const SizedBox(height: 2),
                Text(value, style: const TextStyle(fontSize: 14, color: Colors.black87)),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
