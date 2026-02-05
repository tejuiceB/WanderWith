import 'dart:io';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:flutter/services.dart'; // Import for Clipboard
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:image_picker/image_picker.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:share_plus/share_plus.dart';
import 'package:bubble/bubble.dart';
import 'package:table_calendar/table_calendar.dart';
import 'package:photo_view/photo_view.dart';
import 'package:photo_view/photo_view_gallery.dart';
import 'package:skeletonizer/skeletonizer.dart';
import '../models/trip.dart';
import '../services/auth_service.dart';
import '../services/trip_service.dart';
import '../services/analytics_service.dart';

import '../models/notification.dart';
import '../services/notification_service.dart';
import 'package:flutter_markdown/flutter_markdown.dart';
import '../services/gemini_service.dart';
import 'package:url_launcher/url_launcher.dart';
import 'trip_plan_tab.dart';
import 'ai_guide_screen.dart'; // Add this
import '../services/plan_service.dart'; // Add this

class TripDashboardScreen extends StatefulWidget {
  final Trip trip;

  const TripDashboardScreen({super.key, required this.trip});

  @override
  State<TripDashboardScreen> createState() => _TripDashboardScreenState();
}

class _TripDashboardScreenState extends State<TripDashboardScreen> {
  late Stream<Trip> _tripStream;
  final NotificationService _notificationService = NotificationService();

  @override
  void initState() {
    super.initState();
    _tripStream = TripService().getTripStream(widget.trip.id);
    _checkFeedback();
  }

  void _checkFeedback() {
    // Check if feedback is needed soon after loading
    final uid = Supabase.instance.client.auth.currentUser?.id;
    if (uid != null) {
      _notificationService.checkAndNotifyTripFeedback(widget.trip, uid);
    }
  }

  Future<void> _refreshData() async {
    // Force a re-fetch by momentarily updating state or simply awaiting a fetch
    // Since stream handles data, we can just fetch the latest single value to ensure consistency
    // or reset the stream.
    // Simpler: Just await a fetch to update cache? No, streams are push.
    // Effective strategy: Re-initialize stream.
    setState(() {
      _tripStream = TripService().getTripStream(widget.trip.id);
    });
    // Add small delay for UI effect
    await Future.delayed(const Duration(milliseconds: 500));
  }

  void _editTripName(Trip trip) {
    final controller = TextEditingController(text: trip.name);
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text("Rename Trip"),
        content: TextField(
          controller: controller,
          decoration: const InputDecoration(labelText: "Trip Name"),
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: const Text("Cancel")),
          ElevatedButton(
            onPressed: () async {
              Navigator.pop(ctx);
              await TripService().updateTripName(trip.id, controller.text.trim());
              await _refreshData();
            },
            child: const Text("Save"),
          )
        ],
      )
    );
  }

  @override
  Widget build(BuildContext context) {
    // Get current user ID
    final uid = Supabase.instance.client.auth.currentUser?.id;

    return StreamBuilder<Trip>(
      stream: _tripStream,
      initialData: widget.trip,
      builder: (context, snapshot) {
        if (snapshot.hasError) {
             final err = snapshot.error.toString().toLowerCase();
             final isNetworkError = err.contains('socket') || err.contains('host lookup') || err.contains('realtime');
             
             return Scaffold(
                appBar: AppBar(title: const Text("Offline")),
                body: Center(
                   child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                         Icon(Icons.cloud_off, size: 64, color: Colors.grey.shade400),
                         const SizedBox(height: 16),
                         const Text("No Connection", style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: Colors.grey)),
                         Padding(
                           padding: const EdgeInsets.all(16.0), 
                           child: Text(
                             isNetworkError 
                                ? "We can't reach the servers right now. Please check your internet."
                                : "Something went wrong. Please try again.",
                             textAlign: TextAlign.center,
                             style: const TextStyle(color: Colors.grey)
                           )
                         ),
                         ElevatedButton.icon(
                           onPressed: _refreshData, 
                           icon: const Icon(Icons.refresh),
                           label: const Text("Retry Connection")
                         )
                      ]
                   )
                )
             );
        }

        final currentTrip = snapshot.data ?? widget.trip;
        final isAdmin = uid != null && currentTrip.adminIds.contains(uid);
        
        // CHECK PENDING STATUS
        if (uid != null && currentTrip.pendingMembers.contains(uid)) {
           return Scaffold(
             appBar: AppBar(title: const Text("Access Pending")),
             body: Padding(
               padding: const EdgeInsets.all(32.0),
               child: Column(
                 mainAxisAlignment: MainAxisAlignment.center,
                 children: [
                   const Icon(Icons.lock_clock, size: 80, color: Colors.orange),
                   const SizedBox(height: 24),
                   const Text("Your join request is pending.", style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
                   const SizedBox(height: 12),
                   const Text("An admin must approve your request before you can access trip details.", textAlign: TextAlign.center),
                   const SizedBox(height: 32),
                   OutlinedButton(
                     onPressed: () => Navigator.pop(context), 
                     child: const Text("Go Back")
                   )
                 ],
               ),
             ),
           );
        }

        return DefaultTabController(
          length: 9,
          child: Scaffold(
            appBar: AppBar(
              title: GestureDetector(
                onTap: () {
                   if (isAdmin) _editTripName(currentTrip);
                },
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(currentTrip.name),
                    const SizedBox(width: 8),
                    if (isAdmin)
                      const Icon(Icons.edit, size: 16, color: Colors.white70),
                  ],
                ),
              ),
              bottom: const TabBar(
                isScrollable: true,
                tabs: [
                  Tab(text: "Overview", icon: Icon(Icons.info_outline)),
                  Tab(text: "Dates", icon: Icon(Icons.calendar_today)),
                  Tab(text: "Budget", icon: Icon(Icons.attach_money)),
                  Tab(text: "Plan", icon: Icon(Icons.map)),
                  Tab(text: "Links", icon: Icon(Icons.link)),
                  Tab(text: "Chat", icon: Icon(Icons.chat_bubble_outline)),
                  Tab(text: "Polls", icon: Icon(Icons.how_to_vote)),
                  Tab(text: "Gallery", icon: Icon(Icons.photo_library)),
                  Tab(text: "Reviews", icon: Icon(Icons.star)),
                ],
              ),
            ),
            body: TabBarView(
              children: [
                _OverviewTab(trip: currentTrip, onRefresh: _refreshData),
                _DateTab(trip: currentTrip, onRefresh: _refreshData),
                _BudgetTab(trip: currentTrip, onRefresh: _refreshData),
                TripPlanTab(trip: currentTrip),
                _LinksTab(trip: currentTrip, onRefresh: _refreshData),
                _ChatTab(trip: currentTrip, onRefresh: _refreshData),
                _PollsTab(trip: currentTrip, onRefresh: _refreshData),
                _GalleryTab(trip: currentTrip, onRefresh: _refreshData),
                _ReviewsTab(trip: currentTrip, onRefresh: _refreshData),
              ],
            ),
          ),
        );
      }
    );
  }
}

// -----------------------------------------------------------------------------
// 1. OVERVIEW TAB
// -----------------------------------------------------------------------------
class _OverviewTab extends StatelessWidget {
  final Trip trip;
  final Future<void> Function() onRefresh;
  const _OverviewTab({required this.trip, required this.onRefresh});

  @override
  Widget build(BuildContext context) {
    final currentUser = Supabase.instance.client.auth.currentUser?.id;
    final isAdmin = currentUser != null && trip.adminIds.contains(currentUser);
    final pending = trip.pendingMembers;

    // Determine trip status for blocking invites
    final now = DateTime.now();
    final isPast = trip.endDate != null && trip.endDate!.isBefore(now);
    final isOngoing = (trip.startDate != null && trip.endDate != null) && 
                      trip.startDate!.isBefore(now) && trip.endDate!.isAfter(now);
    final bool canInvite = !(isPast || isOngoing);

    return Scaffold(
      backgroundColor: Colors.transparent,
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => _showAIAssistant(context),
        label: const Text("Plan with AI"),
        icon: const Icon(Icons.auto_awesome),
        backgroundColor: Colors.white,
        foregroundColor: Colors.purple,
      ),
      body: RefreshIndicator(
        onRefresh: onRefresh,
      child: SingleChildScrollView(
        physics: const AlwaysScrollableScrollPhysics(),
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [


            // Header Card
            Card(
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                     Row(
                       children: [
                         const Icon(Icons.location_pin, color: Colors.blueAccent),
                         const SizedBox(width: 8),
                         Text(trip.location, style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                       ],
                     ),
                     const SizedBox(height: 12),
                     Row(
                       children: [
                         const Icon(Icons.date_range, color: Colors.blueAccent),
                         const SizedBox(width: 8),
                         Text(
                           (trip.startDate != null && trip.endDate != null)
                               ? "${DateFormat('MMM d').format(trip.startDate!)} - ${DateFormat('MMM d, y').format(trip.endDate!)}"
                               : "Dates TBD ⏳",
                         ),
                       ],
                     ),
                     const SizedBox(height: 12),
                     Wrap(
                       spacing: 8,
                       children: [
                         if (trip.status == 'completed')
                           _buildStatusBadge("COMPLETED", Colors.grey)
                         else if (trip.status == 'confirmed')
                           _buildStatusBadge("CONFIRMED", Colors.green)
                         else
                           _buildStatusBadge("PLANNING", Colors.orange),
                       ],
                     )
                  ],
                ),
              ),
            ),
            
            const SizedBox(height: 24),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                 const Text("Who's Going?", style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                 if (trip.adminIds.contains(Supabase.instance.client.auth.currentUser?.id))
                   TextButton.icon(
                     onPressed: () => _showManageMembers(context),
                     icon: const Icon(Icons.shield, size: 16),
                     label: const Text("Manage")
                   )
              ],
            ),
            const SizedBox(height: 12),
            
            // Member List
            Wrap(
              spacing: 12,
              runSpacing: 12,
              children: trip.memberIds.map((uid) {
                 final isAdmin = trip.adminIds.contains(uid);
                 // Use Supabase to fetch profile data
                 return FutureBuilder(
                   future: Supabase.instance.client
                       .from('profiles')
                       .select()
                       .eq('id', uid)
                       .maybeSingle(),
                   builder: (context, snapshot) {
                     final isLoading = !snapshot.hasData;
                     
                     if (isLoading) {
                       return Skeletonizer(
                         enabled: true,
                         child: Column(
                           children: [
                             const CircleAvatar(
                               radius: 24, 
                               backgroundColor: Colors.grey
                             ),
                             const SizedBox(height: 4),
                             Container(width: 40, height: 10, color: Colors.grey),
                           ],
                         ),
                       );
                     }
                     var data = snapshot.data as Map<String, dynamic>?;
                     String name = data?['display_name'] ?? 'User';
                     // Initials
                     String initials = (name.isNotEmpty) ? name[0].toUpperCase() : "?";
                     
                     return Column(
                       children: [
                         Stack(
                           children: [
                             CircleAvatar(
                               radius: 24,
                               backgroundColor: Colors.blueAccent.shade100,
                               child: Text(initials, style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
                             ),
                             if (isAdmin)
                               Positioned(bottom: 0, right: 0, child: Icon(Icons.shield, size: 16, color: Colors.orange.shade800))
                           ],
                         ),
                         const SizedBox(height: 4),
                         Text(name.split(' ').first, style: const TextStyle(fontSize: 12)),
                       ],
                     );
                   }
                 );
              }).toList(),
            ),
            
            const SizedBox(height: 24),
            if (canInvite)
              SizedBox(
                width: double.infinity,
                child: ElevatedButton.icon(
                  onPressed: () {
                     Clipboard.setData(ClipboardData(text: trip.id));
                     ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text("Trip ID copied: ${trip.id}")));
                  }, 
                  icon: const Icon(Icons.share),
                  label: const Text("Invite Friends (Copy ID)"),
                  style: ElevatedButton.styleFrom(
                    padding: const EdgeInsets.symmetric(vertical: 12),
                  ),
                ),
              )
            else
              Center(
                child: Text(
                  isPast ? "Trip has ended. Invites are closed." : "Trip is ongoing. Invites are closed.",
                  style: const TextStyle(color: Colors.grey, fontStyle: FontStyle.italic),
                ),
              ),
            
            // PENDING REQUESTS SECTION (ADMIN ONLY)
            if (isAdmin && pending.isNotEmpty) ...[
               const SizedBox(height: 24),
               const Divider(),
               const SizedBox(height: 12),
               Card(
                 color: Colors.orange.shade50,
                 elevation: 4,
                 shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                 child: Padding(
                   padding: const EdgeInsets.all(16.0),
                   child: Column(
                     crossAxisAlignment: CrossAxisAlignment.start,
                     children: [
                       Row(
                         children: [
                            const Icon(Icons.person_add, color: Colors.orange),
                            const SizedBox(width: 8),
                            Text("Join Requests (${pending.length})", style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Colors.orange)),
                         ],
                       ),
                       const Divider(),
                       ...pending.map((uid) {
                          // Fetch Profile
                          return FutureBuilder(
                             future: Supabase.instance.client.from('profiles').select().eq('id', uid).maybeSingle(),
                             builder: (context, snapshot) {
                                final name = (snapshot.hasData && snapshot.data != null) 
                                    ? snapshot.data!['display_name'] 
                                    : 'Unknown User';
                                
                                return ListTile(
                                  contentPadding: EdgeInsets.zero,
                                  leading: CircleAvatar(backgroundColor: Colors.white, child: Text(name[0] ?? '?')),
                                  title: Text(name ?? 'Loading...'),
                                  trailing: Row(
                                    mainAxisSize: MainAxisSize.min,
                                    children: [
                                      IconButton(
                                        icon: const Icon(Icons.check_circle, color: Colors.green),
                                        onPressed: () async {
                                          await TripService().acceptMember(trip.id, uid);
                                          await onRefresh();
                                        },
                                      ),
                                      IconButton(
                                        icon: const Icon(Icons.cancel, color: Colors.red),
                                        onPressed: () async {
                                          await TripService().rejectMember(trip.id, uid);
                                          await onRefresh();
                                        },
                                      )
                                    ],
                                  ),
                                );
                             }
                          );
                       }).toList()
                     ],
                   ),
                 ),
               ),
            ],
            
            const SizedBox(height: 32),
            Center(
               child: TextButton.icon(
                 onPressed: () async {
                    // Check if Owner is trying to leave
                    if (trip.createdBy == currentUser) {
                       await showDialog(
                         context: context, 
                         builder: (ctx) => AlertDialog(
                           title: const Text("Cannot Leave Trip"),
                           content: const Text("You are the owner of this trip. You cannot leave unless you delete the trip or transfer ownership."),
                           actions: [
                             TextButton(onPressed: () => Navigator.pop(ctx), child: const Text("OK"))
                           ],
                         )
                       );
                       return;
                    }

                    final confirm = await showDialog<bool>(
                       context: context,
                       builder: (ctx) => AlertDialog(
                          title: const Text("Leave Trip?"),
                          content: const Text("Are you sure you want to leave this trip?"),
                          actions: [
                             TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text("Cancel")),
                             TextButton(onPressed: () => Navigator.pop(ctx, true), child: const Text("Leave", style: TextStyle(color: Colors.red))),
                          ],
                       )
                    );
                    
                    if (confirm == true) {
                       try {
                          await TripService().leaveTrip(trip.id);
                          Navigator.of(context).pop(); 
                       } catch (e) {
                          ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text("Error: $e")));
                       }
                    }
                 },
                 icon: const Icon(Icons.exit_to_app, color: Colors.red),
                 label: const Text("Leave Trip", style: TextStyle(color: Colors.red)),
               )
            ),
          ],
        ),
      ),
      ),
    );
  }

  void _showAIAssistant(BuildContext context) async {
    // Show Loading
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (ctx) => const Center(child: CircularProgressIndicator()),
    );

    try {
      // 1. Fetch Plan Data
      final plan = await PlanService().fetchTripPlan(trip.id);
      
      if (context.mounted) {
        Navigator.pop(context); // Close Loader
        
        // 2. Navigate to Chat Screen
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (_) => AIGuideScreen(trip: trip, plan: plan),
          ),
        );
      }
    } catch (e) {
       if (context.mounted) {
         Navigator.pop(context); // Close Loader
         ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text("Could not start AI Guide: $e")));
       }
    }
  }

  void _showManageMembers(BuildContext context) {
    showDialog(
      context: context, 
      builder: (ctx) => AlertDialog(
        title: const Text("Manage Members"),
        content: SizedBox(
          width: double.maxFinite,
          child: ListView.builder(
            shrinkWrap: true,
            itemCount: trip.memberIds.length,
            itemBuilder: (ctx, i) {
              final uid = trip.memberIds[i];
              return FutureBuilder(
                 future: Supabase.instance.client.from('profiles').select().eq('id', uid).maybeSingle(),
                 builder: (ctx, snap) {
                   if (!snap.hasData) return const ListTile(title: Text("Loading..."));
                   final name = snap.data!['display_name'] ?? 'User';
                   
                   final currentUid = Supabase.instance.client.auth.currentUser?.id;
                   final iAmAdmin = trip.adminIds.contains(currentUid);
                   final iAmCreator = trip.createdBy == currentUid;
                   final targetIsAdmin = trip.adminIds.contains(uid);
                   final targetIsCreator = trip.createdBy == uid;

                   return ListTile(
                     leading: CircleAvatar(child: Text(name[0])),
                     title: Text(name),
                     subtitle: targetIsCreator ? const Text("Owner", style: TextStyle(fontSize: 10, color: Colors.blue)) : 
                               targetIsAdmin ? const Text("Admin", style: TextStyle(fontSize: 10, color: Colors.orange)) : null,
                     trailing: (uid == currentUid || targetIsCreator) 
                        ? null // Can't manage self or creator here
                        : !iAmAdmin 
                            ? null // Non-admins can't manage
                            : PopupMenuButton<String>(
                                icon: const Icon(Icons.more_vert),
                                onSelected: (value) async {
                                   Navigator.pop(ctx);
                                   if (value == 'promote') {
                                      await TripService().promoteToAdmin(trip.id, uid);
                                      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text("$name is now an Admin")));
                                   } else if (value == 'demote') {
                                      await TripService().demoteFromAdmin(trip.id, uid);
                                      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text("$name is no longer an Admin")));
                                   } else if (value == 'remove') {
                                      final confirm = await showDialog<bool>(
                                         context: context, 
                                         builder: (dCtx) => AlertDialog(
                                            title: const Text("Remove Member?"),
                                            content: Text("Are you sure you want to remove $name?"),
                                            actions: [
                                               TextButton(onPressed: () => Navigator.pop(dCtx, false), child: const Text("Cancel")),
                                               TextButton(onPressed: () => Navigator.pop(dCtx, true), child: const Text("Remove", style: TextStyle(color: Colors.red))),
                                            ]
                                         )
                                      );
                                      if (confirm == true) {
                                         await TripService().removeMember(trip.id, uid);
                                         ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text("$name removed.")));
                                      }
                                   }
                                   await onRefresh();
                                },
                                itemBuilder: (BuildContext context) {
                                   List<PopupMenuEntry<String>> choices = [];
                                   if (!targetIsAdmin) {
                                      choices.add(const PopupMenuItem(value: 'promote', child: Text("Promote to Admin")));
                                      choices.add(const PopupMenuItem(value: 'remove', child: Text("Remove from Trip", style: TextStyle(color: Colors.red))));
                                   } else {
                                      // Target is Admin
                                      if (iAmCreator) {
                                         choices.add(const PopupMenuItem(value: 'demote', child: Text("Demote to Member")));
                                         choices.add(const PopupMenuItem(value: 'remove', child: Text("Remove from Trip", style: TextStyle(color: Colors.red))));
                                      }
                                   }
                                   return choices;
                                },
                              )
                   );
                 }
              );
            }
          ),
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: const Text("Close"))
        ],
      )
    );
  }

  Widget _buildStatusBadge(String text, Color color) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: color.withOpacity(0.5))
      ),
      child: Text(text, 
        style: TextStyle(color: color, fontWeight: FontWeight.bold, fontSize: 12),
      ),
    );
  }
}


// -----------------------------------------------------------------------------
// 2. DATES TAB (Calendar View)
// -----------------------------------------------------------------------------
class _DateTab extends StatefulWidget {
  final Trip trip;
  final Future<void> Function() onRefresh;
  const _DateTab({required this.trip, required this.onRefresh});

  @override
  State<_DateTab> createState() => _DateTabState();
}

class _DateTabState extends State<_DateTab> {
  CalendarFormat _calendarFormat = CalendarFormat.month;
  DateTime _focusedDay = DateTime.now();
  DateTime? _selectedDay;
  DateTime? _rangeStart;
  DateTime? _rangeEnd;
  RangeSelectionMode _rangeSelectionMode = RangeSelectionMode.toggledOn;
  bool _isSaving = false;

  @override
  void initState() {
    super.initState();
    _rangeStart = widget.trip.startDate;
    _rangeEnd = widget.trip.endDate;
  }
  
  @override
  void didUpdateWidget(_DateTab oldWidget) {
    super.didUpdateWidget(oldWidget);
    // Sync if server data changes and we are not actively saving/editing
    if (widget.trip.startDate != oldWidget.trip.startDate || widget.trip.endDate != oldWidget.trip.endDate) {
       setState(() {
         _rangeStart = widget.trip.startDate;
         _rangeEnd = widget.trip.endDate;
       });
    }
  }

  Widget _buildTripSnapshotCard(BuildContext context) {
      Color statusColor = Colors.orange;
      String statusText = "Planning";
      
      final now = DateTime.now();
      if (widget.trip.isDateDecided) {
        statusColor = Colors.blue;
        statusText = "Confirmed";
      }
      if (widget.trip.startDate != null) {
         if (now.isAfter(widget.trip.startDate!) && now.isBefore(widget.trip.endDate!)) {
            statusColor = Colors.green;
            statusText = "Live";
         } else if (now.isAfter(widget.trip.endDate!)) {
            statusColor = Colors.grey;
            statusText = "Completed";
         }
      }

      final isFixed = widget.trip.metadata != null && widget.trip.metadata!['isFixedBudget'] == true;
      final budgetText = isFixed ? "Fixed Budget" : "Mixed Votes";
      final members = widget.trip.memberIds.length;
      
      String dateText = "Dates TBD";
      if (widget.trip.startDate != null) {
          dateText = "${DateFormat('MMM d').format(widget.trip.startDate!)} - ${DateFormat('MMM d, y').format(widget.trip.endDate!)}";
      }

      return Card(
        margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        elevation: 4,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
             crossAxisAlignment: CrossAxisAlignment.start,
             children: [
                Row(
                   mainAxisAlignment: MainAxisAlignment.spaceBetween,
                   children: [
                      Expanded(child: Text(widget.trip.location, style: const TextStyle(fontSize: 22, fontWeight: FontWeight.bold))),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                        decoration: BoxDecoration(
                           color: statusColor.withOpacity(0.1),
                           borderRadius: BorderRadius.circular(12),
                           border: Border.all(color: statusColor)
                        ),
                        child: Text(" $statusText ", style: TextStyle(color: statusColor, fontWeight: FontWeight.bold, fontSize: 12)),
                      )
                   ],
                ),
                const SizedBox(height: 12),
                Row(
                   children: [
                      const Icon(Icons.calendar_today, size: 16, color: Colors.grey),
                      const SizedBox(width: 8),
                      Text(dateText, style: const TextStyle(fontSize: 14)),
                   ],
                ),
                const SizedBox(height: 8),
                Row(
                   mainAxisAlignment: MainAxisAlignment.spaceBetween,
                   children: [
                       Row(
                          children: [
                             const Icon(Icons.group, size: 16, color: Colors.grey),
                             const SizedBox(width: 8),
                             Text("$members members", style: const TextStyle(fontSize: 14)),
                          ]
                       ),
                       Row(
                          children: [
                             const Icon(Icons.attach_money, size: 16, color: Colors.grey),
                             const SizedBox(width: 4),
                             Text(budgetText, style: const TextStyle(fontSize: 14, color: Colors.grey)),
                          ]
                       )
                   ],
                )
             ],
          ),
        ),
      );
  }

  Future<void> _saveDates() async {
    if (_rangeStart == null || _rangeEnd == null) return;
    
    setState(() => _isSaving = true);
    try {
      await TripService().updateTripDates(widget.trip.id, _rangeStart!, _rangeEnd!);
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("Dates Updated!")));
      await widget.onRefresh();
    } catch (e) {
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text("Error: $e")));
    } finally {
      if (mounted) setState(() => _isSaving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final isAdmin = widget.trip.adminIds.contains(Supabase.instance.client.auth.currentUser?.id);

    return RefreshIndicator(
      onRefresh: widget.onRefresh,
      child: SingleChildScrollView(
        physics: const AlwaysScrollableScrollPhysics(),
        child: Column(
          children: [
            // 2️⃣ Trip Overview Snapshot Card
            _buildTripSnapshotCard(context),
            const SizedBox(height: 16),
            
            TableCalendar(
              firstDay: DateTime.now().subtract(const Duration(days: 365)),
              lastDay: DateTime.now().add(const Duration(days: 365)),
              focusedDay: _focusedDay,
              calendarFormat: _calendarFormat,
              
              // Range Selection Logic
              rangeSelectionMode: _rangeSelectionMode,
              rangeStartDay: _rangeStart,
              rangeEndDay: _rangeEnd,
              
              onRangeSelected: (start, end, focusedDay) {
                if (!isAdmin) return; // Read-only for non-admins
                
                // Prevent past selection
                if (start != null) {
                   final now = DateTime.now();
                   final today = DateTime(now.year, now.month, now.day);
                   if (start.isBefore(today)) {
                      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("Cannot set trip dates in the past!")));
                      return;
                   }
                }

                setState(() {
                  _selectedDay = null;
                  _focusedDay = focusedDay;
                  _rangeStart = start;
                  _rangeEnd = end;
                  _rangeSelectionMode = RangeSelectionMode.toggledOn;
                });
              },
              
              onFormatChanged: (format) {
                  setState(() {
                    _calendarFormat = format;
                  });
              },
              onPageChanged: (focusedDay) {
                _focusedDay = focusedDay;
              },
            ),
            const SizedBox(height: 16),
            
            // ADMIN CONTROLS
            if (isAdmin) 
               Padding(
                 padding: const EdgeInsets.symmetric(horizontal: 16.0),
                 child: Column(
                   children: [
                     const Text("Admin: Select a date range above to modify."),
                     const SizedBox(height: 8),
                     if (_rangeStart != null && _rangeEnd != null && (_rangeStart != widget.trip.startDate || _rangeEnd != widget.trip.endDate))
                        ElevatedButton.icon(
                          onPressed: _isSaving ? null : _saveDates,
                          icon: _isSaving ? const SizedBox(width: 16, height: 16, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white)) : const Icon(Icons.save),
                          label: const Text("Save New Dates"),
                          style: ElevatedButton.styleFrom(backgroundColor: Colors.blueAccent, foregroundColor: Colors.white),
                        )
                   ],
                 ),
               ),

            if (widget.trip.isDateDecided && widget.trip.startDate != null && widget.trip.endDate != null)
              Padding(
                padding: const EdgeInsets.all(16.0),
                child: Text(
                  "Trip Dates: ${DateFormat('MM/dd').format(widget.trip.startDate!)} - ${DateFormat('MM/dd').format(widget.trip.endDate!)}",
                  style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                ),
              )
            else
              Padding(
                padding: const EdgeInsets.all(16.0),
                child: const Text(
                  "Dates are tentative. Use this calendar to discuss availability!",
                  textAlign: TextAlign.center,
                  style: TextStyle(color: Colors.grey),
                ),
              )
          ],
        ),
      ),
    );
  }
}


// -----------------------------------------------------------------------------
// 3. BUDGET TAB (Fixed / Editable)
// -----------------------------------------------------------------------------
class _BudgetTab extends StatefulWidget {
  final Trip trip;
  final Future<void> Function() onRefresh;
  const _BudgetTab({required this.trip, required this.onRefresh});

  @override
  State<_BudgetTab> createState() => _BudgetTabState();
}

class _BudgetTabState extends State<_BudgetTab> {

  @override
  Widget build(BuildContext context) {
    final currency = widget.trip.budgetCurrency;
    
    final currentUser = Supabase.instance.client.auth.currentUser?.id;
    final isAdmin = currentUser != null && widget.trip.adminIds.contains(currentUser);

    return RefreshIndicator(
      onRefresh: widget.onRefresh,
      child: SingleChildScrollView(
        physics: const AlwaysScrollableScrollPhysics(),
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header with Edit Button
            Card(
              elevation: 4,
              color: Colors.blue.shade50,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              child: Padding(
                padding: const EdgeInsets.all(20.0),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                     Column(
                       crossAxisAlignment: CrossAxisAlignment.start,
                       children: [
                         Text("Total Budget", style: GoogleFonts.poppins(fontSize: 14, color: Colors.blueGrey)),
                         const SizedBox(height: 4),
                         Text("$currency ${widget.trip.estimatedCost.toStringAsFixed(0)}", 
                              style: GoogleFonts.poppins(fontSize: 32, fontWeight: FontWeight.bold, color: Colors.blueAccent)),
                       ],
                     ),
                     if (isAdmin)
                       IconButton.filled(
                         onPressed: _showEditBudgetDialog,
                         icon: const Icon(Icons.edit, size: 20),
                         style: IconButton.styleFrom(backgroundColor: Colors.white, foregroundColor: Colors.blueAccent),
                         tooltip: "Edit Budget",
                       )
                  ],
                ),
              ),
            ),
            const SizedBox(height: 24),

            // Distribution
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text("Expenses Breakdown", style: GoogleFonts.poppins(fontSize: 18, fontWeight: FontWeight.w600)),
                if (isAdmin)
                  TextButton.icon(
                    onPressed: _showEditBudgetDialog, 
                    icon: const Icon(Icons.add_circle_outline, size: 16),
                    label: const Text("Manage"),
                  )
              ],
            ),
            const SizedBox(height: 8),

            if (widget.trip.budgetAllocations.isEmpty)
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(32),
                  decoration: BoxDecoration(
                    color: Colors.grey.shade50,
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: Colors.grey.shade200)
                  ),
                  child: Column(
                    children: [
                      const Icon(Icons.pie_chart_outline, size: 48, color: Colors.grey),
                      const SizedBox(height: 12),
                      const Text("No breakdown added yet.", style: TextStyle(color: Colors.grey)),
                      if (isAdmin)
                        TextButton(onPressed: _showEditBudgetDialog, child: const Text("Add Expenses"))
                    ],
                  ),
                )
            else 
              ListView.separated(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                itemCount: widget.trip.budgetAllocations.length,
                separatorBuilder: (ctx, i) => const Divider(height: 1),
                itemBuilder: (ctx, i) {
                   final item = widget.trip.budgetAllocations[i];
                   final cost = item['cost'] is int ? (item['cost'] as int).toDouble() : (item['cost'] as double? ?? 0.0);
                   return ListTile(
                     contentPadding: EdgeInsets.zero,
                     leading: CircleAvatar(
                        backgroundColor: Colors.blue.shade50,
                        child: const Icon(Icons.category_outlined, color: Colors.blueAccent, size: 20),
                     ),
                     title: Text(item['title'] ?? 'Item', style: const TextStyle(fontWeight: FontWeight.w500)),
                     trailing: Text("$currency ${cost.toStringAsFixed(0)}", style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                   );
                }
              ),
              
            // Summary Calculation
            if (widget.trip.budgetAllocations.isNotEmpty) ...[
               const Divider(height: 32, thickness: 1),
               Builder(
                 builder: (context) {
                    double totalAllocated = widget.trip.budgetAllocations.fold(0, (prev, e) => prev + (e['cost'] is int ? (e['cost'] as int).toDouble() : (e['cost'] as double? ?? 0.0)));
                    double remaining = widget.trip.estimatedCost - totalAllocated;
                    
                    return Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                         const Text("Unallocated / Buffer", style: TextStyle(fontWeight: FontWeight.bold, color: Colors.grey)),
                         Text("$currency ${remaining.toStringAsFixed(0)}", 
                             style: TextStyle(
                               fontWeight: FontWeight.bold, 
                               color: remaining < 0 ? Colors.red : Colors.green,
                               fontSize: 16
                             )
                         ),
                      ],
                    );
                 }
               )
            ]
          ],
        ),
      ),
    );
  }

  void _showEditBudgetDialog() {
     final cTotal = TextEditingController(text: widget.trip.estimatedCost.toInt().toString());
     // Make a deep copy of allocations to edit locally
     List<Map<String, dynamic>> tempAllocations = List.from(
        widget.trip.budgetAllocations.map((e) => Map<String, dynamic>.from(e))
     );
     
     showDialog(
       context: context,
       builder: (ctx) => StatefulBuilder(
         builder: (context, setState) {
           double sum = tempAllocations.fold(0, (prev, e) => prev + (e['cost'] is int ? (e['cost'] as int).toDouble() : (e['cost'] as double? ?? 0.0)));
           
           return AlertDialog(
             title: const Text("Edit Budget"),
             content: SizedBox(
               width: double.maxFinite,
               child: SingleChildScrollView(
                 child: Column(
                   mainAxisSize: MainAxisSize.min,
                   crossAxisAlignment: CrossAxisAlignment.start,
                   children: [
                      const Text("Total Estimated Budget", style: TextStyle(fontWeight: FontWeight.bold)),
                      const SizedBox(height: 4),
                      TextField(
                        controller: cTotal, 
                        keyboardType: TextInputType.number,
                        decoration: InputDecoration(
                          prefixText: "${widget.trip.budgetCurrency} ", 
                          border: const OutlineInputBorder(),
                          prefixIcon: const Icon(Icons.attach_money)
                        ),
                      ),
                      const SizedBox(height: 24),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          const Text("Allocations", style: TextStyle(fontWeight: FontWeight.bold)),
                          Text("Sum: ${sum.toStringAsFixed(0)}", style: TextStyle(color: sum > (double.tryParse(cTotal.text) ?? 0) ? Colors.red : Colors.green, fontWeight: FontWeight.bold)),
                        ],
                      ),
                      const SizedBox(height: 8),
                      // List of items to edit/delete
                      Container(
                        decoration: BoxDecoration(
                          border: Border.all(color: Colors.grey.shade300),
                          borderRadius: BorderRadius.circular(8)
                        ),
                        child: Column(
                          children: [
                            if (tempAllocations.isEmpty)
                               const Padding(padding: EdgeInsets.all(16), child: Text("No items")),
                            ...tempAllocations.asMap().entries.map((entry) {
                               final idx = entry.key;
                               final item = entry.value;
                               return ListTile(
                                 dense: true,
                                 title: Text(item['title']),
                                 trailing: Row(
                                   mainAxisSize: MainAxisSize.min,
                                   children: [
                                      Text(item['cost'].toString(), style: const TextStyle(fontWeight: FontWeight.bold)),
                                      IconButton(icon: const Icon(Icons.close, size: 16, color: Colors.red), onPressed: () {
                                         setState(() => tempAllocations.removeAt(idx));
                                      })
                                   ],
                                 ),
                               );
                            }),
                          ]
                        ),
                      ),
                      
                      const SizedBox(height: 12),
                      // Add new item simple form
                      InkWell(
                        onTap: () async {
                           // Show small dialog to add item
                           final cName = TextEditingController();
                           final cCost = TextEditingController();
                           await showDialog(
                             context: context,
                             builder: (c) => AlertDialog(
                               title: const Text("Add Expense Item"),
                               content: Column(
                                 mainAxisSize: MainAxisSize.min,
                                 children: [
                                   TextField(controller: cName, decoration: const InputDecoration(labelText: "Name (e.g. Hotel)", border: OutlineInputBorder())),
                                   const SizedBox(height: 12),
                                   TextField(controller: cCost, keyboardType: TextInputType.number, decoration: const InputDecoration(labelText: "Cost", border: OutlineInputBorder())),
                                 ],
                               ),
                               actions: [
                                 TextButton(onPressed: () => Navigator.pop(c), child: const Text("Cancel")),
                                 ElevatedButton(onPressed: () {
                                    if(cName.text.isNotEmpty && cCost.text.isNotEmpty) {
                                       setState(() {
                                          tempAllocations.add({
                                            'title': cName.text.trim(),
                                            'cost': double.tryParse(cCost.text) ?? 0.0
                                          });
                                       });
                                       Navigator.pop(c);
                                    }
                                 }, child: const Text("Add"))
                               ],
                             )
                           );
                        },
                        child: Container(
                          width: double.infinity,
                          padding: const EdgeInsets.all(12),
                          decoration: BoxDecoration(
                            border: Border.all(color: Colors.blue),
                            borderRadius: BorderRadius.circular(8),
                            color: Colors.blue.shade50
                          ),
                          child: const Center(child: Text("+ Add New Item", style: TextStyle(color: Colors.blue, fontWeight: FontWeight.bold))),
                        ),
                      )
                   ],
                 ),
               ),
             ),
             actions: [
               TextButton(onPressed: () => Navigator.pop(ctx), child: const Text("Cancel")),
               ElevatedButton(
                 onPressed: () async {
                    try {
                       final cost = double.tryParse(cTotal.text) ?? 0.0;
                       await TripService().updateTripBudget(widget.trip.id, cost, tempAllocations);
                       if (mounted) Navigator.pop(ctx);
                       widget.onRefresh();
                    } catch (e) {
                       ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text("Error: $e")));
                    }
                 }, 
                 child: const Text("Save Changes")
               )
             ],
           );
         }
       )
     );
  }
}

// -----------------------------------------------------------------------------
// 4. CHAT TAB (Real-time Basic - SUPABASE)
// -----------------------------------------------------------------------------
class _ChatTab extends StatefulWidget {
  final Trip trip;
  final Future<void> Function() onRefresh;
  const _ChatTab({required this.trip, required this.onRefresh});

  @override
  State<_ChatTab> createState() => _ChatTabState();
}

class _ChatTabState extends State<_ChatTab> {
  final TextEditingController _msgController = TextEditingController();
  final ScrollController _scrollController = ScrollController();
  late Stream<List<Map<String, dynamic>>> _messagesStream;
  final ImagePicker _chatImagePicker = ImagePicker();
  bool _isUploadingImage = false;

  @override
  void initState() {
    super.initState();
    // Setup Supabase Realtime Stream
    _messagesStream = Supabase.instance.client
        .from('messages')
        .stream(primaryKey: ['id'])
        .eq('trip_id', widget.trip.id)
        .order('created_at', ascending: false) // Reverse order (newest first)
        .map((data) => data);
  }

  void _sendMessage(String uid, String name) async {
    final text = _msgController.text.trim();
    if (text.isEmpty) return;
    
    // Clear immediately for UX
    _msgController.clear();
    
    try {
      await Supabase.instance.client.from('messages').insert({
        'trip_id': widget.trip.id,
        'sender_id': uid,
        'sender_name': name,
        'text': text,
        'message_type': 'text',
        'image_url': null,
        // created_at is default now()
      });
      
      // Auto scroll if needed
      if (_scrollController.hasClients) {
          _scrollController.animateTo(0, duration: const Duration(milliseconds: 300), curve: Curves.easeOut);
      }
      
      // Notify (Fire and forget, don't await blocking UI)
      NotificationService().notifyTripMembers(
        tripId: widget.trip.id,
        title: "New Message from $name",
        body: text,
        type: NotificationType.message,
        excludeUserId: uid
      );

    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text("Failed to send: $e")));
    }
  }

  Future<void> _sendImage(String uid, String name) async {
    if (_isUploadingImage) return;
    try {
      final XFile? image = await _chatImagePicker.pickImage(source: ImageSource.gallery, imageQuality: 70);
      if (image == null) return;

      setState(() => _isUploadingImage = true);

      final fileExt = image.path.split('.').last;
      final fileName = "chat/${widget.trip.id}/$uid/${DateTime.now().millisecondsSinceEpoch}.$fileExt";

      await Supabase.instance.client.storage
          .from('chat_media')
          .upload(fileName, File(image.path));

      final publicUrl = Supabase.instance.client.storage
          .from('chat_media')
          .getPublicUrl(fileName);

      await Supabase.instance.client.from('messages').insert({
        'trip_id': widget.trip.id,
        'sender_id': uid,
        'sender_name': name,
        'text': '',
        'message_type': 'image',
        'image_url': publicUrl,
      });

      if (_scrollController.hasClients) {
        _scrollController.animateTo(0, duration: const Duration(milliseconds: 300), curve: Curves.easeOut);
      }

      NotificationService().notifyTripMembers(
        tripId: widget.trip.id,
        title: "Photo from $name",
        body: "Sent a photo",
        type: NotificationType.message,
        excludeUserId: uid,
      );
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text("Image send failed: $e")));
      }
    } finally {
      if (mounted) setState(() => _isUploadingImage = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    // Supabase User also works with our AuthService provider
    final user = Provider.of<AuthService>(context).user;
    final userProfile = Provider.of<AuthService>(context).userProfile;
    
    if (user == null) return const Center(child: Text("Please Log In"));

    return Column(
      children: [
        Expanded(
          child: StreamBuilder<List<Map<String, dynamic>>>(
            stream: _messagesStream,
            builder: (context, snapshot) {
              final isLoading = snapshot.connectionState == ConnectionState.waiting;
              final messages = snapshot.data ?? (isLoading ? List.generate(5, (index) => {'text': 'Loading messsages...', 'sender_id': 'skeleton', 'sender_name': 'Loading'}) : []);
              
              if (messages.isEmpty && !isLoading) {
                 return RefreshIndicator(
                   onRefresh: widget.onRefresh,
                   child: SingleChildScrollView(
                     physics: const AlwaysScrollableScrollPhysics(),
                     child: SizedBox(
                       height: MediaQuery.of(context).size.height * 0.6,
                       child: Column(
                         mainAxisAlignment: MainAxisAlignment.center,
                         children: [
                             const Icon(Icons.chat_bubble_outline, size: 60, color: Colors.grey),
                             const SizedBox(height: 16),
                             const Text("Start planning together 👋", style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18, color: Colors.grey)),
                             const SizedBox(height: 8),
                             const Text("Share ideas, routes, and excitement!", style: TextStyle(color: Colors.grey))
                         ],
                       ),
                     )
                   )
                 );
              }

              return RefreshIndicator(
                onRefresh: widget.onRefresh,
                child: Skeletonizer(
                  enabled: isLoading,
                  child: ListView.builder(
                    physics: const AlwaysScrollableScrollPhysics(), // Ensure refresh works even if few items
                    controller: _scrollController,
                    reverse: true, // Chat style
                    itemCount: messages.length,
                    itemBuilder: (context, index) {
                      final msg = messages[index];
                      final isMe = msg['sender_id'] == user.id;
                      
                      final msgType = msg['message_type'] ?? 'text';
                      final imageUrl = msg['image_url'] as String?;

                      return Bubble(
                        margin: const BubbleEdges.only(top: 8),
                        alignment: isMe ? Alignment.topRight : Alignment.topLeft,
                        nip: isMe ? BubbleNip.rightTop : BubbleNip.leftTop,
                        color: isMe ? Colors.blue.shade100 : Colors.grey.shade200,
                        child: Column(
                          crossAxisAlignment: isMe ? CrossAxisAlignment.end : CrossAxisAlignment.start,
                          children: [
                            if (!isMe) Text(msg['sender_name'] ?? 'Unknown', style: const TextStyle(fontSize: 10, color: Colors.grey)),
                            if (msgType == 'image' && imageUrl != null)
                              GestureDetector(
                                onTap: () {
                                  showDialog(
                                    context: context,
                                    builder: (_) => Dialog(
                                      child: PhotoView(
                                        imageProvider: CachedNetworkImageProvider(imageUrl),
                                        backgroundDecoration: const BoxDecoration(color: Colors.black),
                                      ),
                                    ),
                                  );
                                },
                                child: ClipRRect(
                                  borderRadius: BorderRadius.circular(12),
                                  child: CachedNetworkImage(
                                    imageUrl: imageUrl,
                                    width: 220,
                                    height: 220,
                                    fit: BoxFit.cover,
                                    placeholder: (context, url) => Container(
                                      width: 220,
                                      height: 220,
                                      color: Colors.grey.shade300,
                                      child: const Center(child: CircularProgressIndicator()),
                                    ),
                                    errorWidget: (context, url, error) => const Icon(Icons.broken_image, size: 48),
                                  ),
                                ),
                              )
                            else
                              Text(msg['text'] ?? '', style: const TextStyle(fontSize: 16)),
                          ],
                        ),
                      );
                    },
                  ),
                ),
              );
            },
          ),
        ),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 8),
          color: Colors.white,
          child: Row(
            children: [
              IconButton(
                icon: _isUploadingImage
                    ? const SizedBox(width: 18, height: 18, child: CircularProgressIndicator(strokeWidth: 2))
                    : const Icon(Icons.photo, color: Colors.blueAccent),
                onPressed: _isUploadingImage
                    ? null
                    : () => _sendImage(user.id, userProfile?.displayName ?? 'User'),
              ),
              Expanded(
                child: TextField(
                  controller: _msgController,
                  decoration: const InputDecoration(
                    hintText: "Message group...",
                    border: OutlineInputBorder(borderRadius: BorderRadius.all(Radius.circular(24))),
                    contentPadding: EdgeInsets.symmetric(horizontal: 16),
                  ),
                ),
              ),
              const SizedBox(width: 8),
              CircleAvatar(
                backgroundColor: Colors.blueAccent,
                child: IconButton(
                  icon: const Icon(Icons.send, color: Colors.white, size: 20),
                  onPressed: () => _sendMessage(user.id, userProfile?.displayName ?? 'User'),
                ),
              )
            ],
          ),
        )
      ],
    );
  }
}

// -----------------------------------------------------------------------------
// 5. POLLS TAB (Real-time)
// -----------------------------------------------------------------------------
class _PollsTab extends StatefulWidget {
  final Trip trip;
  final Future<void> Function() onRefresh;
  const _PollsTab({required this.trip, required this.onRefresh});

  @override
  State<_PollsTab> createState() => _PollsTabState();
}

class _PollsTabState extends State<_PollsTab> {

  void _showCreatePollDialog() {
    final cQuestion = TextEditingController();
    final List<TextEditingController> cOptions = [
      TextEditingController(),
      TextEditingController()
    ];

    showDialog(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (context, setState) {
          return AlertDialog(
            title: const Text("Create Poll"),
            content: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  TextField(
                    controller: cQuestion,
                    decoration: const InputDecoration(labelText: "Question"),
                  ),
                  const SizedBox(height: 16),
                  const Text("Options", style: TextStyle(fontWeight: FontWeight.bold)),
                  ...cOptions.asMap().entries.map((entry) {
                    final index = entry.key;
                    final controller = entry.value;
                    return Row(
                      children: [
                        Expanded(child: TextField(controller: controller, decoration: InputDecoration(labelText: "Option ${index + 1}"))),
                        IconButton(
                          icon: const Icon(Icons.remove_circle, color: Colors.red),
                          onPressed: () {
                             if (cOptions.length > 2) {
                               setState(() {
                                 cOptions.removeAt(index);
                               });
                             }
                          },
                        )
                      ],
                    );
                  }),
                  TextButton.icon(
                    onPressed: () {
                      setState(() {
                        cOptions.add(TextEditingController());
                      });
                    },
                    icon: const Icon(Icons.add),
                    label: const Text("Add Option"),
                  )
                ],
              ),
            ),
            actions: [
              TextButton(onPressed: () => Navigator.pop(ctx), child: const Text("Cancel")),
              ElevatedButton(
                onPressed: () async {
                  if (cQuestion.text.isEmpty) return;
                  final options = cOptions.map((c) => c.text.trim()).where((t) => t.isNotEmpty).toList();
                  if (options.length < 2) {
                     ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("At least 2 options required")));
                     return;
                  }

                  try {
                    final uid = Supabase.instance.client.auth.currentUser!.id;
                    await TripService().createPoll(widget.trip.id, cQuestion.text.trim(), options, uid);
                    if (mounted) Navigator.pop(ctx);
                    widget.onRefresh();
                  } catch (e) {
                    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text("Error: $e")));
                  }
                },
                child: const Text("Create"),
              )
            ],
          );
        }
      )
    );
  }

  @override
  Widget build(BuildContext context) {
    // Rely on updated widget.trip from parent StreamBuilder
    final metadata = widget.trip.metadata ?? {};
    final polls = (metadata['polls'] != null) 
        ? List<Map<String, dynamic>>.from(metadata['polls']) 
        : <Map<String, dynamic>>[];
    
    // Check Admin
    final isAdmin = widget.trip.adminIds.contains(Supabase.instance.client.auth.currentUser?.id);

    return RefreshIndicator(
      onRefresh: widget.onRefresh,
      child: Scaffold(
        floatingActionButton: isAdmin ? FloatingActionButton.extended(
          onPressed: _showCreatePollDialog,
          icon: const Icon(Icons.poll),
          label: const Text("Create Poll"),
        ) : null,
        body: (polls.isEmpty) 
          ? RefreshIndicator( // Added RefreshIndicator to support pull-down on empty state
              onRefresh: widget.onRefresh,
              child: ListView(
                physics: const AlwaysScrollableScrollPhysics(),
                children: [
                    SizedBox(height: MediaQuery.of(context).size.height * 0.3),
                    const Center(
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                           Icon(Icons.poll_outlined, size: 60, color: Colors.grey),
                           SizedBox(height: 16),
                           Text("Create a poll to decide faster", style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18, color: Colors.grey)),
                           SizedBox(height: 8),
                           Text("Resolve conflicts on dates, stays, or food easily.", style: TextStyle(color: Colors.grey))
                        ]
                      )
                    ),
                ],
              ),
            )
          : ListView.builder(
              padding: const EdgeInsets.all(16),
              itemCount: polls.length,
              physics: const AlwaysScrollableScrollPhysics(), // Important for refresh
              itemBuilder: (context, index) {
                final poll = polls[index];
                return _buildPollCard(poll);
              },
            ),
      ),
    );
  }

  Widget _buildPollCard(Map<String, dynamic> poll) {
    final question = poll['question'] ?? 'No Question';
    final options = List<String>.from(poll['options'] ?? []);
    final votes = Map<String, dynamic>.from(poll['votes'] ?? {}); // {uid: optionIndex}
    
    final uid = Supabase.instance.client.auth.currentUser!.id;
    final myVote = votes[uid]; // int index or null
    final isAdmin = widget.trip.adminIds.contains(uid);

    // Calculate totals
    final totalVotes = votes.length;
    final counts = List.filled(options.length, 0);
    votes.values.forEach((v) {
       if (v is int && v < counts.length) counts[v]++;
    });

    return Card(
      margin: const EdgeInsets.only(bottom: 16),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Expanded(child: Text(question, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 18))),
                if (isAdmin)
                   IconButton(
                     visualDensity: VisualDensity.compact,
                     icon: const Icon(Icons.delete_outline, size: 20, color: Colors.grey),
                     onPressed: () async {
                        final confirm = await showDialog<bool>(context: context, builder: (c) => AlertDialog(
                          title: const Text("Delete Poll"),
                          content: const Text("Are you sure? This cannot be undone."),
                          actions: [
                             TextButton(onPressed: () => Navigator.pop(c, false), child: const Text("Cancel")),
                             TextButton(onPressed: () => Navigator.pop(c, true), child: const Text("Delete", style: TextStyle(color: Colors.red))),
                          ]
                       ));
                       
                       if (confirm == true) {
                          try {
                             await TripService().deletePoll(widget.trip.id, poll['id']);
                             widget.onRefresh();
                          } catch (e) {
                             if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text("Error: $e")));
                          }
                       }
                     },
                   )
              ],
            ),
            const SizedBox(height: 4),
            Text("$totalVotes votes", style: const TextStyle(color: Colors.grey, fontSize: 12)),
            const SizedBox(height: 12),
            ...options.asMap().entries.map((entry) {
               final idx = entry.key;
               final text = entry.value;
               final count = counts[idx];
               final percent = totalVotes > 0 ? count / totalVotes : 0.0;
               final isSelected = myVote == idx;

               return InkWell(
                 onTap: () async {
                    // Vote
                    try {
                      await TripService().votePoll(widget.trip.id, poll['id'], uid, idx);
                      await widget.onRefresh();
                    } catch (e) {
                      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text("Failed to vote: $e")));
                    }
                 },
                 child: Container(
                   margin: const EdgeInsets.only(bottom: 8),
                   padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                   decoration: BoxDecoration(
                     border: Border.all(color: isSelected ? Colors.blueAccent : Colors.grey.shade300, width: isSelected ? 2 : 1),
                     borderRadius: BorderRadius.circular(8),
                     color: isSelected ? Colors.blue.shade50 : null,
                   ),
                   child: Column(
                     crossAxisAlignment: CrossAxisAlignment.start,
                     children: [
                       Row(
                         mainAxisAlignment: MainAxisAlignment.spaceBetween,
                         children: [
                           Expanded(child: Text(text, style: TextStyle(fontWeight: isSelected ? FontWeight.bold : FontWeight.normal))),
                           if (isSelected) const Icon(Icons.check_circle, size: 16, color: Colors.blueAccent)
                         ],
                       ),
                       const SizedBox(height: 6),
                       LinearProgressIndicator(value: percent, backgroundColor: Colors.grey.shade200),
                       Align(alignment: Alignment.centerRight, child: Text("${(percent * 100).toInt()}% ($count)", style: const TextStyle(fontSize: 10))),
                       if (isAdmin && count > 0)
                          FutureBuilder(
                            future: _fetchVotersNames(votes, idx),
                            builder: (context, snap) {
                              if (!snap.hasData) return const SizedBox();
                              return Padding(padding: const EdgeInsets.only(top: 4), child: Text("Voters: ${snap.data}", style: const TextStyle(fontSize: 10, color: Colors.grey)));
                            }
                          )
                     ],
                   ),
                 ),
               );
            }).toList()
          ],
        ),
      ),
    );
  }

  Future<String> _fetchVotersNames(Map<String, dynamic> votes, int optionIdx) async {
     final uids = votes.entries.where((e) => e.value == optionIdx).map((e) => e.key).toList();
     if (uids.isEmpty) return "";
     
     final resp = await Supabase.instance.client.from('profiles').select('display_name').filter('id', 'in', uids);
     final names = (resp as List).map((e) => e['display_name'] as String).toList();
     return names.take(3).join(', ') + (names.length > 3 ? " +${names.length - 3}" : "");
  }
} // End _PollsTabState

// -----------------------------------------------------------------------------
// 6. GALLERY & MEMORIES TAB
// -----------------------------------------------------------------------------
class _GalleryTab extends StatefulWidget {
  final Trip trip;
  final Future<void> Function() onRefresh;
  const _GalleryTab({required this.trip, required this.onRefresh});

  @override
  State<_GalleryTab> createState() => _GalleryTabState();
}

class _GalleryTabState extends State<_GalleryTab> {
  final ImagePicker _picker = ImagePicker();
  bool _isUploading = false;
  Future<List<Map<String, dynamic>>>? _photosFuture;

  @override
  void initState() {
    super.initState();
    _loadPhotos();
  }

  void _loadPhotos() {
     setState(() {
        _photosFuture = Supabase.instance.client
          .from('photos')
          .select()
          .eq('trip_id', widget.trip.id)
          .order('created_at', ascending: false);
     });
  }

  Future<void> _manualRefresh() async {
     await widget.onRefresh(); 
     _loadPhotos();
  }

  Future<void> _uploadPhoto() async {
    try {
      final XFile? image = await _picker.pickImage(source: ImageSource.gallery, imageQuality: 70);
      if (image == null) return;

      setState(() => _isUploading = true);
      
      final user = Provider.of<AuthService>(context, listen: false).user;
      if (user == null) throw Exception("Not logged in");

      // 1. Upload to Supabase Storage
      String fileExt = image.path.split('.').last;
      String fileName = "${user.id}/${DateTime.now().millisecondsSinceEpoch}.$fileExt";
      
      await Supabase.instance.client.storage
          .from('trip_photos')
          .upload(fileName, File(image.path));
      
      // 2. Get Public URL
      final String publicUrl = Supabase.instance.client.storage
          .from('trip_photos')
          .getPublicUrl(fileName);

      // 3. Save reference in 'photos' table
      // (This requires a 'photos' table, I will make assumption users run SQL or I'll provide it)
      // If table doesn't exist, this fails. I'll advise user.
      await Supabase.instance.client.from('photos').insert({
          'trip_id': widget.trip.id,
          'url': publicUrl,
          'uploader_id': user.id,
          // created_at is default
      });

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("Photo uploaded 📸")));
        _loadPhotos();
      }
    } catch (e) {
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text("Upload failed: $e")));
    } finally {
      if (mounted) setState(() => _isUploading = false);
    }
  }

  void _shareSummary() {
      // Basic text share for MVP
      String dates = "Dates TBD";
      if (widget.trip.startDate != null) {
        dates = "${DateFormat('MMM d').format(widget.trip.startDate!)} - ${DateFormat('MMM d, y').format(widget.trip.endDate!)}";
      }

      String summary = "✨ Trip Memories: ${widget.trip.location} ✨\n"
                       "📅 $dates\n\n"
                       "Shared via WanderWith App 🌍";
      Share.share(summary);
  }

  @override
  Widget build(BuildContext context) {
    // Lock uploads if planning
    final isLocked = widget.trip.status == 'planning';

    return Scaffold(
      floatingActionButton: isLocked ? null : FloatingActionButton.extended(
        onPressed: _isUploading ? null : _uploadPhoto,
        backgroundColor: Colors.blueAccent,
        icon: _isUploading ? const SizedBox(width: 24, height: 24, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2)) : const Icon(Icons.add_a_photo),
        label: Text(_isUploading ? "Uploading..." : "Add Photo"),
      ),
      body: RefreshIndicator(
        onRefresh: _manualRefresh,
        child: CustomScrollView(
          physics: const AlwaysScrollableScrollPhysics(),
          slivers: [
              SliverToBoxAdapter(
                  child: Padding(
                      padding: const EdgeInsets.all(16.0),
                      child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                              Text("Memories from ${widget.trip.location} ✨", style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
                              const SizedBox(height: 8),
                              if (!isLocked)
                                SizedBox(
                                    width: double.infinity,
                                    child: OutlinedButton.icon(
                                        onPressed: _shareSummary,
                                        icon: const Icon(Icons.ios_share),
                                        label: const Text("Share Trip Summary"),
                                    ),
                                ),
                          ],
                      ),
                  ),
              ),
              if (isLocked)
                 const SliverFillRemaining(
                   child: Center(
                     child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                           Icon(Icons.lock_clock, size: 64, color: Colors.grey),
                           SizedBox(height: 16),
                           Text("Memories Locked", style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18, color: Colors.grey)),
                           SizedBox(height: 8),
                           Text("Confirm trip to start sharing photos!", style: TextStyle(color: Colors.grey))
                        ]
                     )
                   )
                 )
              else
              FutureBuilder<List<Map<String, dynamic>>>(
                  future: _photosFuture,
                  builder: (context, snapshot) {
                      if (snapshot.hasError) return SliverToBoxAdapter(child: Center(child: Text("Error loading photos: ${snapshot.error}")));
                      
                      // Using Skeletonizer for loading state
                      if (snapshot.connectionState == ConnectionState.waiting) {
                          return SliverToBoxAdapter(
                             child: Skeletonizer(
                               enabled: true,
                               child: GridView.builder(
                                 shrinkWrap: true,
                                 physics: const NeverScrollableScrollPhysics(),
                                 gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                                     crossAxisCount: 3, crossAxisSpacing: 2, mainAxisSpacing: 2),
                                 itemCount: 9,
                                 itemBuilder: (ctx, i) => Container(color: Colors.grey[300]),
                               ),
                             )
                          );
                      }
                      
                      var photos = snapshot.data ?? [];
                      if (photos.isEmpty) {
                          return SliverToBoxAdapter(
                              child: Padding(
                                  padding: const EdgeInsets.symmetric(vertical: 64.0, horizontal: 32),
                                  child: Center(
                                    child: Column(
                                      children: [
                                          const Icon(Icons.photo_library_outlined, size: 60, color: Colors.grey),
                                          const SizedBox(height: 16),
                                          const Text("Upload your first memory 📸", style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18, color: Colors.grey)),
                                          const SizedBox(height: 8),
                                          const Text("Keep your trip photos all in one place.", textAlign: TextAlign.center, style: TextStyle(color: Colors.grey)),
                                      ],
                                    ),
                                  ),
                              ),
                          );
                      }

                      return SliverGrid(
                          delegate: SliverChildBuilderDelegate(
                              (context, index) {
                                  var data = photos[index];
                                  final uid = Supabase.instance.client.auth.currentUser!.id;
                                  final isAdmin = widget.trip.adminIds.contains(uid);

                                  return GestureDetector(
                                      onTap: () async {
                                          await Navigator.push(context, MaterialPageRoute(builder: (_) => GalleryViewer(
                                            galleryItems: photos,
                                            initialIndex: index,
                                            currentUserId: uid,
                                            isAdmin: isAdmin,
                                            tripId: widget.trip.id,
                                            onDelete: () { 
                                               _manualRefresh();
                                            },
                                          )));
                                          _loadPhotos(); 
                                      },
                                      child: Hero(
                                          tag: data['url'],
                                          child: CachedNetworkImage(
                                              imageUrl: data['url'],
                                              fit: BoxFit.cover,
                                              placeholder: (context, url) => Skeletonizer(enabled: true, child: Container(color: Colors.grey)),
                                              errorWidget: (context, url, error) => const Icon(Icons.error),
                                          ),
                                      ),
                                  );
                              },
                              childCount: photos.length,
                          ),
                          gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                              crossAxisCount: 3,
                              crossAxisSpacing: 2,
                              mainAxisSpacing: 2,
                          ),
                      );
                  },
              ),
          ],
        ),
      ),
    );
  }
}

class GalleryViewer extends StatefulWidget {
  final List<Map<String, dynamic>> galleryItems;
  final int initialIndex;
  final String currentUserId;
  final bool isAdmin;
  final String tripId;
  final VoidCallback onDelete;

  const GalleryViewer({
    super.key, 
    required this.galleryItems, 
    this.initialIndex = 0,
    required this.currentUserId,
    required this.isAdmin,
    required this.tripId,
    required this.onDelete,
  });

  @override
  State<GalleryViewer> createState() => _GalleryViewerState();
}

class _GalleryViewerState extends State<GalleryViewer> {
  late PageController _pageController;
  late int _currentIndex;

  @override
  void initState() {
    super.initState();
    _currentIndex = widget.initialIndex;
    _pageController = PageController(initialPage: widget.initialIndex);
  }

  Future<void> _handleDelete() async {
     final item = widget.galleryItems[_currentIndex];
     final uploaderId = item['uploader_id'] ?? '';
     
     // Double check permission
     if (!widget.isAdmin && uploaderId != widget.currentUserId) {
        return;
     }

     final confirm = await showDialog<bool>(
       context: context, 
       builder: (c) => AlertDialog(
         title: const Text("Delete Photo"),
         content: const Text("This action cannot be undone."),
         actions: [
            TextButton(onPressed: () => Navigator.pop(c, false), child: const Text("Cancel")),
            TextButton(onPressed: () => Navigator.pop(c, true), child: const Text("Delete", style: TextStyle(color: Colors.red))),
         ]
       )
     );

     if (confirm == true) {
        try {
           final item = widget.galleryItems[_currentIndex];
           await TripService().deletePhoto(widget.tripId, item['id'], item['url'], uploaderId);
           widget.onDelete(); // Refresh list in parent
           if (mounted) Navigator.pop(context); // Close viewer
        } catch (e) {
           ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text("Delete failed: $e")));
        }
     }
  }

  @override
  Widget build(BuildContext context) {
    if (widget.galleryItems.isEmpty) return const SizedBox();
    final currentItem = widget.galleryItems[_currentIndex];

    String dateStr = "";
    if (currentItem['created_at'] != null) {
       final dt = DateTime.parse(currentItem['created_at']);
       dateStr = DateFormat.yMMMd().add_jm().format(dt.toLocal());
    }

    final canDelete = widget.isAdmin || (currentItem['uploader_id'] == widget.currentUserId);

    return Scaffold(
      backgroundColor: Colors.black,
      body: Stack(
        alignment: Alignment.bottomRight,
        children: [
          PhotoViewGallery.builder(
            scrollPhysics: const BouncingScrollPhysics(),
            builder: (BuildContext context, int index) {
              final item = widget.galleryItems[index];
              return PhotoViewGalleryPageOptions(
                imageProvider: CachedNetworkImageProvider(item['url']),
                initialScale: PhotoViewComputedScale.contained,
                minScale: PhotoViewComputedScale.contained * 0.8,
                maxScale: PhotoViewComputedScale.covered * 2,
                heroAttributes: PhotoViewHeroAttributes(tag: item['url']),
              );
            },
            itemCount: widget.galleryItems.length,
            loadingBuilder: (context, event) => const Center(
              child: CircularProgressIndicator(),
            ),
            backgroundDecoration: const BoxDecoration(color: Colors.black),
            pageController: _pageController,
            onPageChanged: (index) {
               setState(() => _currentIndex = index);
            },
          ),
          
                   // Header Bar with Delete
          Positioned(
            top: 0,
            left: 0,
            right: 0,
            child: SafeArea(
              child: Container(
                padding: const EdgeInsets.all(8.0),
                color: Colors.black45, // Slightly darker
                child: Row(
                  children: [
                    IconButton(
                        icon: const Icon(Icons.close, color: Colors.white),
                        onPressed: () => Navigator.pop(context),
                    ),
                    const Spacer(),
                    Text(
                      "${_currentIndex + 1} / ${widget.galleryItems.length}",
                      style: const TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.bold),
                    ),
                    const Spacer(),
                    if (canDelete)
                      IconButton(
                        icon: const Icon(Icons.delete, color: Colors.redAccent),
                        onPressed: _handleDelete,
                      )
                    else 
                      const SizedBox(width: 48)
                  ],
                ),
              ),
            ),
          ),

          // Footer Bar with metadata
          Positioned(
              bottom: 0,
              left: 0,
              right: 0,
              child: Container(
                padding: const EdgeInsets.all(16),
                color: Colors.black54,
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                     if (dateStr.isNotEmpty)
                       Text(
                          dateStr, 
                          style: const TextStyle(color: Colors.white70, fontSize: 12),
                          textAlign: TextAlign.center,
                       ),
                     if (currentItem['uploader_id'] != null)
                        FutureBuilder<Map<String, dynamic>?>(
                           // Naive fetch for uploader name (future optimization: join in query)
                           future: Supabase.instance.client
                               .from('profiles')
                               .select('display_name')
                               .eq('id', currentItem['uploader_id'])
                               .maybeSingle(),
                           builder: (context, snapshot) {
                              if (snapshot.hasData && snapshot.data != null) {
                                 return Padding(
                                   padding: const EdgeInsets.only(top: 4.0),
                                   child: Text(
                                      "Uploaded by ${snapshot.data!['display_name']}",
                                      style: const TextStyle(color: Colors.white, fontSize: 14, fontWeight: FontWeight.bold),
                                   ),
                                 );
                              }
                              return const SizedBox();
                           }
                        )
                  ],
                ),
              ),
           )
        ],
      ),
    );
  }
}

// -----------------------------------------------------------------------------
// 7. REVIEWS TAB
// -----------------------------------------------------------------------------
class _ReviewsTab extends StatefulWidget {
  final Trip trip;
  final Future<void> Function() onRefresh;
  const _ReviewsTab({required this.trip, required this.onRefresh});

  @override
  State<_ReviewsTab> createState() => _ReviewsTabState();
}

class _ReviewsTabState extends State<_ReviewsTab> {
  final _commentController = TextEditingController();
  int _selectedRating = 0;
  bool _isSubmitting = false;

  @override
  Widget build(BuildContext context) {
    // 1. Check if trip is done
    final isTripDone = widget.trip.endDate != null && 
                       widget.trip.endDate!.isBefore(DateTime.now());
    
    if (!isTripDone) {
      return RefreshIndicator(
        onRefresh: widget.onRefresh,
        child: SingleChildScrollView(
          physics: const AlwaysScrollableScrollPhysics(),
          child: SizedBox(
            height: MediaQuery.of(context).size.height * 0.7, // Fill space to allow pull
            child: Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Icon(Icons.rate_review_outlined, size: 64, color: Colors.grey),
                  const SizedBox(height: 16),
                  const Text(
                    "Reviews will open when the trip ends.",
                    style: TextStyle(fontSize: 18, color: Colors.grey),
                  ),
                  if (widget.trip.endDate != null)
                     Padding(
                       padding: const EdgeInsets.only(top: 8.0),
                       child: Text(
                         "Trip ends on: ${DateFormat.yMMMd().format(widget.trip.endDate!)}",
                         style: const TextStyle(color: Colors.grey),
                       ),
                     ),
                ],
              ),
            ),
          ),
        ),
      );
    }

    final uid = Supabase.instance.client.auth.currentUser?.id;
    final reviews = widget.trip.reviews;
    final hasReviewed = uid != null && reviews.containsKey(uid);

    // Lock if not Completed
    if (widget.trip.status != 'completed') {
       return Center(
         child: Column(
           mainAxisAlignment: MainAxisAlignment.center,
           children: [
             Icon(Icons.lock_clock, size: 64, color: Colors.grey.shade400),
             const SizedBox(height: 16),
             const Text("Reviews Locked", style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: Colors.grey)),
             const SizedBox(height: 8),
             const Text("Finish the trip to unlock reviews!", style: TextStyle(color: Colors.grey)),
           ],
         ),
       );
    }

    return RefreshIndicator(
      onRefresh: widget.onRefresh,
      child: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        physics: const AlwaysScrollableScrollPhysics(),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
           // COMPOSER SECTION (Only if user hasn't reviewed)
           if (!hasReviewed && uid != null) ...[
             const Text("Rate this Trip", style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
             const SizedBox(height: 16),
             Card(
               child: Padding(
                 padding: const EdgeInsets.all(16.0),
                 child: Column(
                   children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: List.generate(5, (index) {
                           return IconButton(
                             icon: Icon(
                               index < _selectedRating ? Icons.star : Icons.star,
                               color: index < _selectedRating ? Colors.amber : Colors.grey.shade300,
                               size: 32,
                             ),
                             onPressed: () {
                               setState(() => _selectedRating = index + 1);
                             },
                           );
                        }),
                      ),
                      const SizedBox(height: 16),
                      TextField(
                        controller: _commentController,
                        maxLines: 3,
                        decoration: const InputDecoration(
                          hintText: "What was your favorite memory?",
                          border: OutlineInputBorder(),
                        ),
                      ),
                      const SizedBox(height: 16),
                      SizedBox(
                        width: double.infinity,
                        child: ElevatedButton.icon(
                          onPressed: (_selectedRating == 0 || _isSubmitting) ? null : _submitReview,
                          icon: _isSubmitting 
                             ? const SizedBox(width:20, height:20, child: CircularProgressIndicator(strokeWidth: 2)) 
                             : const Icon(Icons.send),
                          label: const Text("Submit Review"),
                        ),
                      )
                   ],
                 ),
               ),
             ),
             const Divider(height: 48),
           ],

           // REVIEWS LIST SECTION
           const Text("All Reviews", style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
           const SizedBox(height: 16),
           if (reviews.isEmpty)
              const Center(child: Text("No reviews yet. Be the first!", style: TextStyle(color: Colors.grey)))
           else 
              ...reviews.entries.map((entry) {
                 final review = entry.value as Map<String, dynamic>;
                 final rRating = review['rating'] as int;
                 final rComment = review['comment'] as String;
                 
                 return FutureBuilder(
                   future: Supabase.instance.client
                     .from('profiles')
                     .select('display_name, email, avatar_url')
                     .eq('id', entry.key)
                     .maybeSingle(),
                   builder: (context, snapshot) {
                    final data = snapshot.data;
                    final name = (data != null)
                      ? (data['display_name'] ?? data['email'] ?? "Unknown")
                      : "Loading...";
                    final avatarUrl = (data != null) ? data['avatar_url'] : null;

                      return Card(
                        margin: const EdgeInsets.only(bottom: 12),
                        child: ListTile(
                          leading: CircleAvatar(
                             backgroundImage: (avatarUrl != null) ? NetworkImage(avatarUrl) : null,
                             child: (avatarUrl == null) ? Text(name.isNotEmpty ? name[0].toUpperCase() : "?") : null,
                          ),
                          title: Row(
                            children: [
                              Text(name, style: const TextStyle(fontWeight: FontWeight.bold)),
                              const Spacer(),
                              Row(
                                children: List.generate(5, (i) => Icon(
                                  i < rRating ? Icons.star : Icons.star,
                                  size: 16, 
                                  color: i < rRating ? Colors.amber : Colors.grey.shade300
                                )),
                              )
                            ],
                          ),
                          subtitle: Padding(
                            padding: const EdgeInsets.only(top: 8.0),
                            child: Text(rComment),
                          ),
                        ),
                      );
                   },
                 );
              }).toList(),
        ],
      ),
     ),
    );
  }

  Future<void> _submitReview() async {
    setState(() => _isSubmitting = true);
    try {
      final uid = Supabase.instance.client.auth.currentUser!.id;
      final tripService = TripService();
      await tripService.submitReview(
        widget.trip.id, 
        uid, 
        _selectedRating, 
        _commentController.text
      );
      
      if (mounted) {
         ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("Review submitted!")));
      }
    } catch (e) {
      if (mounted) {
         ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text("Error: $e")));
      }
    } finally {
      if (mounted) setState(() => _isSubmitting = false);
    }
  }
}

// -----------------------------------------------------------------------------
// 8. AI ASSISTANT BOTTOM SHEET
// -----------------------------------------------------------------------------
// -----------------------------------------------------------------------------
// 8. LINKS TAB
// -----------------------------------------------------------------------------
class _LinksTab extends StatelessWidget {
  final Trip trip;
  final Future<void> Function() onRefresh;
  const _LinksTab({required this.trip, required this.onRefresh});

  Future<void> _launchUrl(BuildContext context, String url) async {
    final uri = Uri.parse(url);
    if (!await launchUrl(uri, mode: LaunchMode.externalApplication)) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text("Could not launch $url")));
    }
  }

  void _showAddLinkDialog(BuildContext context) {
    final cTitle = TextEditingController();
    final cUrl = TextEditingController();

    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text("Add Important Link"),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: cTitle,
              decoration: const InputDecoration(labelText: "Description (e.g. Hotel Map)"),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: cUrl,
              decoration: const InputDecoration(labelText: "URL (https://...)"),
              keyboardType: TextInputType.url,
            ),
          ],
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: const Text("Cancel")),
          ElevatedButton(
            onPressed: () async {
               if (cTitle.text.isEmpty || cUrl.text.isEmpty) return;
               
               // Basic URL Validation prefix
               String url = cUrl.text.trim();
               if (!url.startsWith('http')) {
                  url = 'https://$url';
               }

               final uid = Supabase.instance.client.auth.currentUser!.id;

               try {
                  Navigator.pop(ctx);
                  await TripService().addTripLink(trip.id, cTitle.text.trim(), url, uid);
                  onRefresh();
               } catch (e) {
                  ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text("Error: $e")));
               }
            },
            child: const Text("Add"),
          )
        ],
      )
    );
  }

  void _confirmDelete(BuildContext context, Map<String, dynamic> link) async {
     final confirm = await showDialog<bool>(
        context: context,
        builder: (c) => AlertDialog(
           title: const Text("Remove Link?"),
           content: Text("Delete '${link['title']}'?"),
           actions: [
              TextButton(onPressed: () => Navigator.pop(c, false), child: const Text("Cancel")),
              TextButton(onPressed: () => Navigator.pop(c, true), child: const Text("Delete", style: TextStyle(color: Colors.red))),
           ],
        )
     );

     if (confirm == true) {
        try {
           await TripService().deleteTripLink(trip.id, link['id']);
           onRefresh();
        } catch(e) {
           ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text("Error: $e")));
        }
     }
  }

  @override
  Widget build(BuildContext context) {
    final currentUser = Supabase.instance.client.auth.currentUser?.id;
    final isAdmin = currentUser != null && trip.adminIds.contains(currentUser);
    
    final metadata = trip.metadata ?? {};
    final links = (metadata['links'] != null)
        ? List<Map<String, dynamic>>.from(metadata['links'])
        : <Map<String, dynamic>>[];

    return Scaffold(
      floatingActionButton: isAdmin ? FloatingActionButton.extended(
        onPressed: () => _showAddLinkDialog(context),
        icon: const Icon(Icons.add_link),
        backgroundColor: Colors.blueAccent,
        label: const Text("Add Link"),
      ) : null,
      body: links.isEmpty
          ? RefreshIndicator(
             onRefresh: onRefresh,
             child: ListView(
               physics: const AlwaysScrollableScrollPhysics(),
               children: [
                   SizedBox(height: MediaQuery.of(context).size.height * 0.3),
                   const Center(
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                           Icon(Icons.link_off, size: 64, color: Colors.grey),
                           SizedBox(height: 16),
                           Text("No links added yet.", style: TextStyle(fontSize: 18, color: Colors.grey)),
                        ],
                      )
                   )
               ],
             ),
          )
          : RefreshIndicator(
             onRefresh: onRefresh,
             child: ListView.separated(
               padding: const EdgeInsets.all(16),
               itemCount: links.length,
               separatorBuilder: (c, i) => const Divider(),
               itemBuilder: (context, index) {
                  final link = links[index];
                  // If metadata is simple, just show. 
                  // link: {id, title, url, added_by, created_at}
                  
                  return ListTile(
                    contentPadding: EdgeInsets.zero,
                    onTap: () => _launchUrl(context, link['url']),
                    leading: CircleAvatar(
                       backgroundColor: Colors.blue.shade50,
                       child: const Icon(Icons.link, color: Colors.blueAccent),
                    ),
                    title: Text(link['title'] ?? 'Link', style: const TextStyle(fontWeight: FontWeight.bold)),
                    subtitle: Text(link['url'] ?? '', maxLines: 1, overflow: TextOverflow.ellipsis, style: const TextStyle(color: Colors.blue, decoration: TextDecoration.underline)),
                    trailing: (isAdmin || link['added_by'] == currentUser) 
                        ? IconButton(
                            icon: const Icon(Icons.delete_outline, color: Colors.grey),
                            onPressed: () => _confirmDelete(context, link),
                          )
                        : const Icon(Icons.open_in_new, size: 16, color: Colors.grey),
                  );
               },
             ),
          ),
    );
  }
}

class _AIBottomSheet extends StatefulWidget {
  final Trip trip;
  const _AIBottomSheet({required this.trip});

  @override
  State<_AIBottomSheet> createState() => _AIBottomSheetState();
}

class _AIBottomSheetState extends State<_AIBottomSheet> {
  bool _isLoading = true;
  bool _isGenerating = false;
  String? _summary;
  String? _error;
  @override
  void initState() {
    super.initState();
    AnalyticsService().logEvent('ai_assistant_opened', parameters: {
       'trip_id': widget.trip.id
    });
    _loadSavedSummary();
  }

  Future<void> _loadSavedSummary() async {
    try {
      final saved = await TripService().getAiSummary(widget.trip.id);
      if (mounted) {
        setState(() {
          _summary = saved;
          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _error = "Could not load saved summary.";
          _isLoading = false;
        });
      }
    }
  }

  Future<void> _generateAndSaveSummary() async {
    setState(() {
      _isGenerating = true;
      _error = null;
    });

    try {
      // Fetch recent messages
      final messages = await Supabase.instance.client
          .from('messages')
          .select('text, sender_name, created_at')
          .eq('trip_id', widget.trip.id)
          .order('created_at', ascending: false)
          .limit(10);

      final recentMessages = (messages as List)
          .map((m) => {
                'text': m['text'] ?? '',
                'sender_name': m['sender_name'] ?? 'Member',
                'created_at': m['created_at']
              })
          .toList();

      final summary = await GeminiService().getTripSummary(
        trip: widget.trip,
        polls: widget.trip.polls,
        recentMessages: recentMessages,
      );

      await TripService().saveAiSummary(widget.trip.id, summary);

      if (mounted) {
        setState(() {
          _summary = summary;
          _isGenerating = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _error = "Could not generate summary. ${e.toString().replaceAll('Exception: ', '')}";
          _isGenerating = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16.0),
      height: MediaQuery.of(context).size.height * 0.75,
      decoration: const BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Row(
                children: [
                  Icon(Icons.auto_awesome, color: Colors.blueAccent.shade200),
                  const SizedBox(width: 8),
                  const Text('AI Assistant', 
                    style: TextStyle(
                      fontSize: 20, 
                      fontWeight: FontWeight.bold,
                      color: Colors.black87
                    )
                  ),
                ],
              ),
              IconButton(
                icon: const Icon(Icons.close),
                onPressed: () => Navigator.pop(context),
              ),
            ],
          ),
          const Divider(),
          Expanded(
            child: ListView(
              padding: const EdgeInsets.all(16),
              children: [
                if (_isLoading)
                  const Center(child: CircularProgressIndicator())
                else if (_summary != null) ...[
                  Text("Saved AI Summary", style: GoogleFonts.poppins(fontSize: 16, fontWeight: FontWeight.bold, color: Colors.blueAccent)),
                  const SizedBox(height: 8),
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: Colors.blue.shade50,
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Text(_summary!, style: const TextStyle(fontSize: 14)),
                  ),
                  const SizedBox(height: 16),
                  ElevatedButton.icon(
                    onPressed: () => Share.share(_summary!),
                    icon: const Icon(Icons.share),
                    label: const Text("Share Trip Summary"),
                    style: ElevatedButton.styleFrom(backgroundColor: Colors.blueAccent),
                  ),
                ] else ...[
                  Text("Trip Summary", style: GoogleFonts.poppins(fontSize: 16, fontWeight: FontWeight.bold, color: Colors.blueAccent)),
                  const SizedBox(height: 8),
                  Text("Generate once and save it for your whole team.", style: TextStyle(color: Colors.grey.shade600)),
                  const SizedBox(height: 16),
                  ElevatedButton.icon(
                    onPressed: _isGenerating ? null : _generateAndSaveSummary,
                    icon: _isGenerating ? const SizedBox(width: 16, height: 16, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white)) : const Icon(Icons.auto_awesome),
                    label: Text(_isGenerating ? "Generating..." : "Generate & Save"),
                    style: ElevatedButton.styleFrom(backgroundColor: Colors.blueAccent),
                  ),
                ],
                if (_error != null) ...[
                  const SizedBox(height: 12),
                  Text(_error!, style: const TextStyle(color: Colors.red)),
                ]
              ],
            ),
          ),
        ],
      ),
    );
  }
}

