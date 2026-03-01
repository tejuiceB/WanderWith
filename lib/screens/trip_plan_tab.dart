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
import '../widgets/ai_generation_overlay.dart';
import '../widgets/timeline_itinerary_item.dart';
import '../widgets/add_place_bottom_sheet.dart';
import '../theme/app_colors.dart';
import '../theme/theme_extensions.dart';

class TripPlanTab extends StatefulWidget {
  final Trip trip;
  const TripPlanTab({super.key, required this.trip});

  @override
  State<TripPlanTab> createState() => _TripPlanTabState();
}

class _TripPlanTabState extends State<TripPlanTab> with AutomaticKeepAliveClientMixin {
  late GoogleMapController _mapController;
  
  @override
  bool get wantKeepAlive => true;
  
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<PlanProvider>().loadPlan(widget.trip.id);
    });
  }

  @override
  Widget build(BuildContext context) {
    super.build(context);
    // Determine Permissions
    final uid = Supabase.instance.client.auth.currentUser?.id;
    final bool canEdit = uid != null && (widget.trip.adminIds.contains(uid) || widget.trip.createdBy == uid) && !widget.trip.isDead;

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
                        Text("No plan generated yet.", style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: context.appColors.textPrimary)),
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
              initialChildSize: 0.5,
              minChildSize: 0.4,
              maxChildSize: 0.95, 
              snap: true, 
              builder: (context, scrollController) {
                return Container(
                  decoration: BoxDecoration(
                    color: context.appColors.cardBg,
                    borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
                    boxShadow: [BoxShadow(color: context.appColors.shadow, blurRadius: 10, spreadRadius: 2)],
                  ),
                  child: CustomScrollView(
                    controller: scrollController,
                    slivers: [
                      SliverToBoxAdapter(
                        child: Column(
                          children: [
                            const SizedBox(height: 12),
                            // Handle
                            Container(width: 40, height: 4, decoration: BoxDecoration(color: context.appColors.border, borderRadius: BorderRadius.circular(2))),
                            const SizedBox(height: 12),
                            
                            // Day Selector Header
                            Padding(
                              padding: const EdgeInsets.symmetric(horizontal: 20),
                              child: Row(
                                children: [
                                  Text(
                                    "Trip Timeline",
                                    style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: context.appColors.textPrimary),
                                  ),
                                  const Spacer(),
                                  Icon(Icons.more_horiz, color: context.appColors.textSecondary),
                                ],
                              ),
                            ),
                            const SizedBox(height: 16),

                            // Premium Day Selector
                            SingleChildScrollView(
                              scrollDirection: Axis.horizontal,
                              padding: const EdgeInsets.symmetric(horizontal: 16),
                              child: Row(
                                children: [
                                  for (int i = 0; i < provider.days.length; i++)
                                    Padding(
                                      padding: const EdgeInsets.only(right: 12.0),
                                      child: InkWell(
                                        onTap: () {
                                          provider.selectDay(i);
                                          _moveCameraToDay(provider);
                                        },
                                        borderRadius: BorderRadius.circular(12),
                                        child: AnimatedContainer(
                                          duration: const Duration(milliseconds: 300),
                                          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
                                          decoration: BoxDecoration(
                                            color: provider.selectedDayIndex == i ? AppColors.brand : (context.isDark ? AppColors.brand.withOpacity(0.1) : Colors.blue.shade50.withOpacity(0.5)),
                                            borderRadius: BorderRadius.circular(12),
                                            boxShadow: provider.selectedDayIndex == i ? [
                                              BoxShadow(
                                                color: AppColors.brand.withOpacity(0.3),
                                                blurRadius: 8,
                                                offset: const Offset(0, 4),
                                              )
                                            ] : [],
                                          ),
                                          child: Text(
                                            "Day ${provider.days[i].dayNumber}",
                                            style: TextStyle(
                                              color: provider.selectedDayIndex == i ? Colors.white : AppColors.brand,
                                              fontWeight: FontWeight.bold,
                                              fontSize: 14,
                                            ),
                                          ),
                                        ),
                                      ),
                                    )
                                ],
                              ),
                            ),
                            const SizedBox(height: 16),
                            // Summary / Story Header
                            if (provider.currentDay != null)
                              Padding(
                                padding: const EdgeInsets.symmetric(horizontal: 20.0),
                                child: Container(
                                  padding: const EdgeInsets.all(16),
                                  decoration: BoxDecoration(
                                    color: context.isDark ? AppColors.brand.withOpacity(0.08) : Colors.blue.shade50.withOpacity(0.3),
                                    borderRadius: BorderRadius.circular(16),
                                    border: Border.all(color: context.isDark ? context.appColors.border : Colors.blue.shade50),
                                  ),
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        "Day ${provider.currentDay!.dayNumber} Summary",
                                        style: TextStyle(
                                          fontSize: 12,
                                          fontWeight: FontWeight.bold,
                                          color: AppColors.brand,
                                          letterSpacing: 1.2,
                                        ),
                                      ),
                                      const SizedBox(height: 6),
                                      Text(
                                         provider.currentDay!.summary ?? '',
                                         style: TextStyle(
                                           fontSize: 14,
                                           color: context.appColors.textSecondary,
                                           height: 1.4,
                                         ),
                                         maxLines: 3,
                                         overflow: TextOverflow.ellipsis,
                                      ),
                                    ],
                                  ),
                                ),
                              ),
                            const SizedBox(height: 12),
                          ],
                        ),
                      ),

                      if (provider.currentDay != null)
                        SliverReorderableList(
                          itemCount: provider.currentDay!.places.length,
                          onReorder: (oldIndex, newIndex) {
                             if (!canEdit) return; // Guard
                             if (newIndex > provider.currentDay!.places.length) newIndex = provider.currentDay!.places.length;
                             if (oldIndex < newIndex) newIndex -= 1;
                             provider.reorderPlace(provider.selectedDayIndex, oldIndex, newIndex);
                          },
                          proxyDecorator: (child, index, animation) {
                             return Material(
                               elevation: 5,
                               borderRadius: BorderRadius.circular(12),
                               child: child,
                             );
                          },
                          itemBuilder: (context, index) {
                            final place = provider.currentDay!.places[index];
                            return ReorderableDelayedDragStartListener(
                              key: ValueKey(place.id),
                              index: index,
                              enabled: canEdit,
                              child: Dismissible(
                                key: ValueKey("${place.id}_dismiss"),
                                direction: canEdit ? DismissDirection.endToStart : DismissDirection.none,
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
                                child: TimelineItineraryItem(
                                  place: place,
                                  index: index,
                                  isLast: index == provider.currentDay!.places.length - 1,
                                  canEdit: canEdit,
                                  onTap: () {
                                    provider.selectPlace(index);
                                    _moveCameraToPlace(provider, place.latLng);
                                    
                                    showModalBottomSheet(
                                      context: context,
                                      isScrollControlled: true,
                                      useRootNavigator: true,
                                      useSafeArea: true,
                                      enableDrag: true,
                                      backgroundColor: context.appColors.cardBg,
                                      clipBehavior: Clip.antiAlias,
                                      shape: const RoundedRectangleBorder(
                                        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
                                      ),
                                      builder: (_) => PlaceDetailScreen(place: place, tripLocation: widget.trip.location),
                                    );
                                  },
                                ),
                              ),
                            );
                          },
                        ),
                      
                      if (canEdit && provider.currentDay != null)
                        SliverToBoxAdapter(
                          child: Column(
                            key: const ValueKey('footer'),
                            children: [
                              const SizedBox(height: 16),
                              OutlinedButton.icon(
                                  onPressed: () {
                                      if (provider.currentDay != null) {
                                        showModalBottomSheet(
                                          context: context,
                                          isScrollControlled: true,
                                          backgroundColor: Colors.transparent,
                                          builder: (context) => AddPlaceBottomSheet(
                                            trip: widget.trip,
                                            dayId: provider.currentDay!.id,
                                            dayNumber: provider.currentDay!.dayNumber,
                                          ),
                                        );
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
                          ),
                        ),
                    ],
                  ),
                );
              },
            ),
            
            // Premium AI Generation Overlay
            if (provider.isLoading)
              Positioned.fill(
                child: AIPlanGenerationOverlay(status: provider.loadingStatus),
              ),
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

  void _moveCameraToPlace(PlanProvider provider, LatLng position) {
    _mapController.animateCamera(
      CameraUpdate.newCameraPosition(
        CameraPosition(target: position, zoom: 15),
      ),
    );
  }
}
