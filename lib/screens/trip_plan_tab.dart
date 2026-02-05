import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:provider/provider.dart';
import 'package:supabase_flutter/supabase_flutter.dart'; // Import Supabase
import '../models/trip.dart';
import '../models/trip_plan.dart';
import '../providers/plan_provider.dart';
import 'place_detail_screen.dart';

class TripPlanTab extends StatefulWidget {
  final Trip trip;
  const TripPlanTab({super.key, required this.trip});

  @override
  State<TripPlanTab> createState() => _TripPlanTabState();
}

class _TripPlanTabState extends State<TripPlanTab> {
  late GoogleMapController _mapController;
  
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<PlanProvider>().loadPlan(widget.trip.id);
    });
  }

  @override
  Widget build(BuildContext context) {
    // Determine Permissions
    final uid = Supabase.instance.client.auth.currentUser?.id;
    final bool canEdit = uid != null && (widget.trip.adminIds.contains(uid) || widget.trip.createdBy == uid);

    return Consumer<PlanProvider>(
      builder: (context, provider, child) {
        
        // 1. Initial Fetch (Avoid Map Flash)
        // If loading, has no data, and is NOT in 'Generative' mode (meaning just DB check), show simple spinner.
        // We know it's generative if status is NOT "Loading..."
        if (provider.isLoading && provider.days.isEmpty && provider.loadingStatus == "Loading...") {
             return const Center(child: CircularProgressIndicator());
        }

        // 2. Empty / Initial State (No Plan Generated)
        if (provider.days.isEmpty && !provider.isLoading) {
            return Center(
                child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                        const Icon(Icons.map_outlined, size: 80, color: Colors.grey),
                        const SizedBox(height: 16),
                        const Text("No plan generated yet.", style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                         const SizedBox(height: 8),
                         Padding(
                           padding: const EdgeInsets.symmetric(horizontal: 32.0),
                           child: Text(
                             canEdit 
                               ? "Let AI assist you in creating the perfect itinerary based on your preferences."
                               : "The trip organizer has not created a plan yet.",
                             textAlign: TextAlign.center, 
                             style: const TextStyle(color: Colors.grey)
                           ),
                        ),
                        const SizedBox(height: 24),
                        if (canEdit)
                          ElevatedButton.icon(
                              onPressed: () async {
                                try {
                                  await provider.generatePlan(widget.trip);
                                } catch (e) {
                                  if (context.mounted) {
                                    ScaffoldMessenger.of(context).showSnackBar(
                                      SnackBar(
                                        content: Text("Failed: ${e.toString().replaceAll('Exception:', '')}"),
                                        backgroundColor: Colors.red,
                                        behavior: SnackBarBehavior.floating,
                                        duration: const Duration(seconds: 5),
                                      )
                                    );
                                  }
                                }
                              },
                              icon: const Icon(Icons.auto_awesome),
                              label: const Text("Generate AI Plan"),
                              style: ElevatedButton.styleFrom(
                                  padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                              ),
                          )
                    ],
                )
            );
        }

        // 3. Main Interface (Map + List + Loading Overlay)
        return Stack(
          children: [
            // Google Map (Full Screen)
            Positioned.fill(
              child: GoogleMap(
                initialCameraPosition: _getCameraPos(provider),
                markers: provider.markers,
                polylines: provider.polylines,
                onMapCreated: (controller) => _mapController = controller,
                // Enable all gestures
                zoomGesturesEnabled: true,
                scrollGesturesEnabled: true,
                rotateGesturesEnabled: true,
                tiltGesturesEnabled: true,
                zoomControlsEnabled: true, 
                myLocationButtonEnabled: false,
                compassEnabled: true,
                padding: const EdgeInsets.only(bottom: 300),
                // IMPORTANT: Claim gestures from the parent TabBarView
                gestureRecognizers: <Factory<OneSequenceGestureRecognizer>>{
                  Factory<OneSequenceGestureRecognizer>(() => EagerGestureRecognizer()),
                },
              ),
            ),

            // Draggable Sheet
            DraggableScrollableSheet(
              initialChildSize: 0.45,
              minChildSize: 0.25,
              maxChildSize: 0.95, 
              snap: true, 
              builder: (context, scrollController) {
                return Container(
                  decoration: const BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
                    boxShadow: [BoxShadow(color: Colors.black12, blurRadius: 10, spreadRadius: 2)],
                  ),
                  child: Column(
                    children: [
                      const SizedBox(height: 12),
                      // Handle
                      Container(width: 40, height: 4, decoration: BoxDecoration(color: Colors.grey[300], borderRadius: BorderRadius.circular(2))),
                      const SizedBox(height: 12),
                      
                      // Day Selector
                      SingleChildScrollView(
                        scrollDirection: Axis.horizontal,
                        padding: const EdgeInsets.symmetric(horizontal: 16),
                        child: Row(
                          children: [
                            for (int i = 0; i < provider.days.length; i++)
                              Padding(
                                padding: const EdgeInsets.only(right: 8.0),
                                child: ChoiceChip(
                                  label: Text("Day ${provider.days[i].dayNumber}"),
                                  selected: provider.selectedDayIndex == i,
                                  onSelected: (selected) {
                                    if(selected) {
                                       provider.selectDay(i);
                                       _moveCameraToDay(provider);
                                    }
                                  },
                                ),
                              )
                          ],
                        ),
                      ),
                      const SizedBox(height: 8),
                      // Summary
                      if (provider.currentDay != null)
                        Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 16.0),
                          child: Text(
                             provider.currentDay!.summary ?? '',
                             style: const TextStyle(fontStyle: FontStyle.italic, color: Colors.grey),
                             maxLines: 2,
                             overflow: TextOverflow.ellipsis,
                          ),
                        ),
                      const Divider(),

                      // List
                      Expanded(
                        child: provider.currentDay == null ? const SizedBox() : ReorderableListView.builder(
                          buildDefaultDragHandles: canEdit, // Only admins can drag
                          proxyDecorator: (child, index, animation) {
                             return Material(
                               elevation: 5,
                               borderRadius: BorderRadius.circular(12),
                               child: child,
                             );
                          },
                          scrollController: scrollController, 
                          itemCount: provider.currentDay!.places.length + (canEdit ? 1 : 0), // +1 for Footer only if Admin
                          onReorder: (oldIndex, newIndex) {
                             if (!canEdit) return; // Guard
                             if (newIndex >= provider.currentDay!.places.length) return; // Don't move below footer
                             if (oldIndex >= provider.currentDay!.places.length) return; // Don't move footer
                             provider.reorderPlace(provider.selectedDayIndex, oldIndex, newIndex);
                          },
                          itemBuilder: (context, index) {
                            if (canEdit && index == provider.currentDay!.places.length) {
                                // FOOTER: Add Place & Regenerate (Admin Only)
                                return Column(
                                  key: const ValueKey('footer'),
                                  children: [
                                    const SizedBox(height: 16),
                                    OutlinedButton.icon(
                                        onPressed: () {
                                            if (provider.currentDay != null) {
                                              _showAddPlaceDialog(context, provider);
                                            }
                                        },
                                        icon: const Icon(Icons.add_location_alt),
                                        label: const Text("Add a Place manually"),
                                    ),
                                    const SizedBox(height: 24),
                                    if (!provider.isLoading)
                                      TextButton.icon(
                                          onPressed: () async {
                                            try { await provider.generatePlan(widget.trip); } 
                                            catch (e) { if(context.mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text("Failed: $e"), backgroundColor: Colors.red)); }
                                          },
                                          icon: const Icon(Icons.refresh),
                                          label: const Text("Regenerate Plan"),
                                      ),
                                    const SizedBox(height: 40),
                                  ],
                                );
                            }

                            final place = provider.currentDay!.places[index];
                            return Dismissible(
                              key: ValueKey(place.id),
                              direction: canEdit ? DismissDirection.endToStart : DismissDirection.none, // Disable for non-admin
                              background: Container(
                                decoration: BoxDecoration(color: Colors.red, borderRadius: BorderRadius.circular(12)),
                                alignment: Alignment.centerRight, 
                                padding: const EdgeInsets.only(right: 20), 
                                child: const Icon(Icons.delete, color: Colors.white)
                              ),
                              confirmDismiss: (direction) async {
                                return await showDialog(
                                  context: context,
                                  builder: (ctx) => AlertDialog(
                                    title: const Text("Remove Place?"),
                                    content: Text("Are you sure you want to remove ${place.name} from the plan?"),
                                    actions: [
                                      TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text("Cancel")),
                                      TextButton(onPressed: () => Navigator.pop(ctx, true), child: const Text("Remove", style: TextStyle(color: Colors.red))),
                                    ],
                                  )
                                );
                              },
                              onDismissed: (direction) {
                                  provider.deletePlace(provider.selectedDayIndex, index);
                              },
                              child: _buildPlaceCard(context, place, index + 1, canEdit),
                            );
                          },
                        ),
                      ),
                    ],
                  ),
                );
              },
            ),
            
            // Loading Overlay (Only for AI Generation process)
            if(provider.isLoading)
              Container(
                color: Colors.black54,
                child: Center(
                    child: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 24),
                        margin: const EdgeInsets.symmetric(horizontal: 40),
                        decoration: BoxDecoration(
                            color: Colors.white,
                            borderRadius: BorderRadius.circular(16),
                            boxShadow: const [BoxShadow(color: Colors.black26, blurRadius: 10, offset: Offset(0, 4))]
                        ),
                        child: Column(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                                const CircularProgressIndicator(),
                                const SizedBox(height: 20),
                                Text(
                                    provider.loadingStatus,
                                    textAlign: TextAlign.center,
                                    style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w600, color: Colors.black87),
                                ),
                                const SizedBox(height: 8),
                                const Text(
                                    "Please wait while AI builds your plan.",
                                    textAlign: TextAlign.center,
                                    style: TextStyle(fontSize: 12, color: Colors.grey),
                                )
                            ],
                        ),
                    )
                ),
              )
          ],
        );
      },
    );
  }

  CameraPosition _getCameraPos(PlanProvider provider) {
    if (provider.days.isNotEmpty && provider.currentDay != null && provider.currentDay!.places.isNotEmpty) {
      return CameraPosition(target: provider.currentDay!.places[0].latLng, zoom: 12);
    }
    return const CameraPosition(target: LatLng(0, 0), zoom: 2);
  }

  void _moveCameraToDay(PlanProvider provider) {
      if (provider.currentDay != null && provider.currentDay!.places.isNotEmpty) {
           _mapController.animateCamera(CameraUpdate.newLatLngZoom(provider.currentDay!.places[0].latLng, 12));
      }
  }

  Widget _buildPlaceCard(BuildContext context, TripPlanPlace place, int number, bool canEdit) {
    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: InkWell(
        onTap: () {
            showModalBottomSheet(
              context: context,
              isScrollControlled: true,
              useRootNavigator: true,
              enableDrag: true,
              backgroundColor: Colors.transparent, // Let screen handle it
              builder: (_) => Container(
                 height: MediaQuery.of(context).size.height * 0.9, // 90% height
                 decoration: const BoxDecoration(
                   color: Colors.white,
                   borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
                 ),
                 clipBehavior: Clip.antiAlias,
                 child: PlaceDetailScreen(place: place),
              )
            );
        },
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.all(12.0),
          child: Row(
            children: [
               // Thumbnail with Number Overlay
               Stack(
                 children: [
                   ClipRRect(
                     borderRadius: BorderRadius.circular(8),
                     child: place.imageUrl != null 
                        ? CachedNetworkImage(imageUrl: place.imageUrl!, width: 70, height: 70, fit: BoxFit.cover, errorWidget: (_,__,___)=>Container(width: 70, height: 70, color: Colors.grey[200]))
                        : Container(width: 70, height: 70, color: Colors.grey[200], child: const Icon(Icons.image, color: Colors.grey)),
                   ),
                   Positioned(
                     top: 0, left: 0,
                     child: Container(
                       padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                       decoration: const BoxDecoration(color: Colors.blueAccent, borderRadius: BorderRadius.only(topLeft: Radius.circular(8), bottomRight: Radius.circular(8))),
                       child: Text("$number", style: const TextStyle(color: Colors.white, fontSize: 12, fontWeight: FontWeight.bold)),
                     ),
                   )
                 ],
               ),
               const SizedBox(width: 16),
               
               // Info
               Expanded(
                 child: Column(
                   crossAxisAlignment: CrossAxisAlignment.start,
                   children: [
                     Text(place.name, maxLines: 2, overflow: TextOverflow.ellipsis, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                     const SizedBox(height: 4),
                     Text(place.type, style: TextStyle(color: Colors.grey[600], fontSize: 12)),
                     const SizedBox(height: 6),
                     Row(
                       children: [
                          Icon(Icons.directions_car, size: 14, color: Colors.blue[700]),
                          const SizedBox(width: 4),
                          // Placeholder for travel time (e.g., "15 min") - Future Calculation
                          Text(place.arrivalTime != null ? "${place.arrivalTime} Arrival" : "Travel info...", style: TextStyle(fontSize: 12, color: Colors.blue[700], fontWeight: FontWeight.w500)),
                          if (place.rating != null) ...[
                              const SizedBox(width: 10),
                              Icon(Icons.star, size: 14, color: Colors.amber[700]),
                              const SizedBox(width: 2),
                              Text("${place.rating}", style: TextStyle(fontSize: 12, color: Colors.amber[800])),
                          ]
                       ],
                     )
                   ],
                 ),
               ),
               
               // Drag Handle (Hide if not editable)
               if (canEdit)
                 const Icon(Icons.drag_handle, color: Colors.grey),
            ],
          ),
        ),
      ),
    );
  }

  Future<void> _showAddPlaceDialog(BuildContext context, PlanProvider provider) async {
    final TextEditingController _controller = TextEditingController();
    
    return showDialog(
      context: context,
      builder: (ctx) {
        bool _isAdding = false;
        
        return StatefulBuilder(
          builder: (context, setState) {
            return AlertDialog(
              title: const Text("Add Place"),
              content: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  TextField(
                    controller: _controller,
                    decoration: const InputDecoration(
                      labelText: "Place Name",
                      hintText: "e.g., 'Eiffel Tower' or a restaurant",
                      border: OutlineInputBorder(),
                    ),
                  ),
                  if (_isAdding)
                    const Padding(
                      padding: EdgeInsets.only(top: 16.0),
                      child: Center(child: CircularProgressIndicator()),
                    ),
                ],
              ),
              actions: [
                TextButton(
                  onPressed: _isAdding ? null : () => Navigator.pop(ctx), 
                  child: const Text("Cancel")
                ),
                ElevatedButton(
                  onPressed: _isAdding ? null : () async {
                    if (_controller.text.trim().isEmpty) return;
                    
                    setState(() { _isAdding = true; });
                    
                    try {
                       await provider.addPlace(provider.currentDay!.id, _controller.text.trim());
                       if(ctx.mounted) {
                         Navigator.pop(ctx);
                         ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("Place added!")));
                       }
                    } catch (e) {
                       if(ctx.mounted) {
                          setState(() { _isAdding = false; });
                          ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text("Failed: $e"), backgroundColor: Colors.red));
                       }
                    }
                  }, 
                  child: const Text("Add")
                ),
              ],
            );
          }
        );
      }
    );
  }
}
