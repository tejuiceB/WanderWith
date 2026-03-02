import 'dart:io';
import 'dart:ui';
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
import '../models/user_profile.dart';
import '../services/auth_service.dart';
import '../services/trip_service.dart';
import '../services/analytics_service.dart';
import '../models/trip_extras.dart';
import 'profile_screen.dart';

import '../models/notification.dart';
import '../services/notification_service.dart';
import 'package:flutter_markdown/flutter_markdown.dart';
import '../models/trip_link.dart';
import '../services/url_metadata_service.dart';
import '../services/gemini_service.dart';
import '../services/template_service.dart';
import '../services/export_service.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:timeago/timeago.dart' as timeago;
import 'trip_plan_tab.dart';
import 'ai_guide_screen.dart'; // Add this
import '../services/plan_service.dart'; // Add this
import '../widgets/trip_activity_tab.dart';
import '../widgets/trip_chat_tab.dart';
import '../providers/plan_provider.dart';
import '../theme/app_colors.dart';
import '../theme/theme_extensions.dart';
import '../models/trip_metadata.dart';
import '../models/trip_international_info.dart';
import '../models/expense.dart';
import '../services/expense_service.dart';
import '../models/checklist_item.dart';
import '../config/emergency_numbers.dart';
import '../services/checklist_service.dart';
import '../models/weather_forecast.dart';
import '../services/weather_service.dart';
import 'package:fl_chart/fl_chart.dart';
import 'dart:async';

class TripDashboardScreen extends StatefulWidget {
  final Trip trip;

  const TripDashboardScreen({super.key, required this.trip});

  @override
  State<TripDashboardScreen> createState() => _TripDashboardScreenState();
}

class _TripDashboardScreenState extends State<TripDashboardScreen> {
  late Stream<Trip> _tripStream;
  final NotificationService _notificationService = NotificationService();
  bool _localJoinRequested = false;

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

  void _showSaveAsTemplateDialog(Trip trip) {
    final nameController = TextEditingController(text: trip.name);
    final descController = TextEditingController();
    bool isPublic = false;
    bool isSaving = false;

    showDialog(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (context, setDialogState) => AlertDialog(
          backgroundColor: context.appColors.cardBg,
          surfaceTintColor: context.appColors.cardBg,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
          title: Text('Save as Template', style: GoogleFonts.outfit(fontWeight: FontWeight.bold)),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                'Save this trip\'s structure as a reusable template including checklist and itinerary.',
                style: GoogleFonts.inter(fontSize: 13, color: context.appColors.textSecondary),
              ),
              const SizedBox(height: 16),
              TextField(
                controller: nameController,
                decoration: InputDecoration(
                  labelText: 'Template Name',
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                  filled: true,
                  fillColor: context.appColors.fieldFillBg,
                ),
              ),
              const SizedBox(height: 12),
              TextField(
                controller: descController,
                maxLines: 2,
                decoration: InputDecoration(
                  labelText: 'Description (optional)',
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                  filled: true,
                  fillColor: context.appColors.fieldFillBg,
                ),
              ),
              const SizedBox(height: 12),
              SwitchListTile(
                value: isPublic,
                onChanged: (v) => setDialogState(() => isPublic = v),
                title: Text('Share with community', style: GoogleFonts.inter(fontSize: 14)),
                subtitle: Text('Others can use your template', style: GoogleFonts.inter(fontSize: 12, color: context.appColors.textMuted)),
                dense: true,
                contentPadding: EdgeInsets.zero,
                activeColor: AppColors.brand,
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(ctx),
              child: const Text('Cancel'),
            ),
            ElevatedButton(
              onPressed: isSaving
                  ? null
                  : () async {
                      if (nameController.text.trim().isEmpty) return;
                      setDialogState(() => isSaving = true);
                      try {
                        await TemplateService().saveFromTrip(
                          trip: trip,
                          templateName: nameController.text.trim(),
                          description: descController.text.trim().isEmpty
                              ? null
                              : descController.text.trim(),
                          isPublic: isPublic,
                        );
                        if (mounted) {
                          Navigator.pop(ctx);
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(content: Text('✅ Template saved!')),
                          );
                        }
                      } catch (e) {
                        setDialogState(() => isSaving = false);
                        if (mounted) {
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(content: Text('Error: $e'), backgroundColor: Colors.red),
                          );
                        }
                      }
                    },
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.brand,
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              ),
              child: isSaving
                  ? const SizedBox(height: 18, width: 18, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2))
                  : const Text('Save'),
            ),
          ],
        ),
      ),
    );
  }

  void _showExportOptions(Trip trip) {
    final colors = context.appColors;
    showModalBottomSheet(
      context: context,
      backgroundColor: colors.cardBg,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (ctx) => SafeArea(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(16, 20, 16, 16),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 40, height: 4,
                decoration: BoxDecoration(color: colors.border, borderRadius: BorderRadius.circular(2)),
              ),
              const SizedBox(height: 16),
              Text('Export Trip', style: GoogleFonts.outfit(fontSize: 18, fontWeight: FontWeight.bold)),
              const SizedBox(height: 4),
              Text('Choose a format to share your trip details',
                  style: GoogleFonts.inter(fontSize: 13, color: colors.textSecondary)),
              const SizedBox(height: 20),
              _ExportOptionTile(
                icon: Icons.picture_as_pdf,
                color: Colors.red,
                title: 'Full Trip PDF',
                subtitle: 'Professional multi-page document with cover, itinerary, budget & more',
                onTap: () {
                  Navigator.pop(ctx);
                  _runExport(trip, isPdf: true);
                },
              ),
              const SizedBox(height: 10),
              _ExportOptionTile(
                icon: Icons.checklist_rounded,
                color: AppColors.brand,
                title: 'Checklist Only (PDF)',
                subtitle: 'Printable packing & preparation checklist',
                onTap: () {
                  Navigator.pop(ctx);
                  _runExport(trip, isPdf: true, checklistOnly: true);
                },
              ),
              const SizedBox(height: 10),
              _ExportOptionTile(
                icon: Icons.data_object,
                color: Colors.blueAccent,
                title: 'Export as JSON',
                subtitle: 'Machine-readable data backup of your trip',
                onTap: () {
                  Navigator.pop(ctx);
                  _runExport(trip, isPdf: false);
                },
              ),
              const SizedBox(height: 8),
            ],
          ),
        ),
      ),
    );
  }

  Future<void> _runExport(Trip trip, {required bool isPdf, bool checklistOnly = false}) async {
    final messenger = ScaffoldMessenger.of(context);
    final label = checklistOnly ? 'Checklist PDF' : (isPdf ? 'PDF' : 'JSON');
    messenger.showSnackBar(SnackBar(
      content: Row(children: [
        const SizedBox(height: 18, width: 18, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2)),
        const SizedBox(width: 12),
        Text('Generating $label…'),
      ]),
      duration: const Duration(seconds: 30),
    ));

    try {
      final service = ExportService();
      if (checklistOnly) {
        await service.exportChecklistPdf(trip);
      } else if (isPdf) {
        await service.exportAsPdf(trip);
      } else {
        await service.exportAsJson(trip);
      }
      messenger.hideCurrentSnackBar();
    } catch (e) {
      messenger.hideCurrentSnackBar();
      messenger.showSnackBar(
        SnackBar(content: Text('Export failed: $e'), backgroundColor: Colors.red),
      );
    }
  }

  void _leaveTrip(Trip trip) async {
    final uid = Supabase.instance.client.auth.currentUser?.id;
    if (uid == null) return;

    final confirm = await showDialog<bool>(
        context: context,
        builder: (ctx) => AlertDialog(
              title: const Text("Leave Trip?"),
              content: Text(
                trip.memberIds.length <= 1 
                  ? "Are you sure you want to leave this trip? Since you're the only member, this will delete the trip."
                  : (trip.createdBy == uid 
                      ? "Are you sure you want to leave this trip? Since you're the creator, the trip will be frozen for remaining members (Read-Only)."
                      : "Are you sure you want to leave this trip?")
              ),
              actions: [
                TextButton(
                    onPressed: () => Navigator.pop(ctx, false),
                    child: const Text("Cancel")),
                TextButton(
                    onPressed: () => Navigator.pop(ctx, true),
                    child: const Text("Leave",
                        style: TextStyle(color: Colors.red))),
              ],
            ));

    if (confirm == true) {
      if (!mounted) return;
      
      // Show loading
      showDialog(
        context: context,
        barrierDismissible: false,
        builder: (ctx) => const Center(child: CircularProgressIndicator()),
      );

      try {
        await TripService().leaveTrip(trip.id);
        if (mounted) {
          Navigator.of(context).pop(); // Pop loading
          Navigator.of(context).pop(); // Pop Dashboard
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text("Successfully left the trip")),
          );
        }
      } catch (e) {
        if (mounted) {
          Navigator.of(context).pop(); // Pop loading
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text("Error leaving trip: $e"), backgroundColor: Colors.red),
          );
        }
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    // Get current user ID
    final uid = Supabase.instance.client.auth.currentUser?.id;

    return StreamBuilder<Trip>(
      stream: _tripStream,
      initialData: widget.trip,
      builder: (context, snapshot) {
        final colors = context.appColors;
        final currentTrip = snapshot.data ?? widget.trip;

        // If there's an error AND we somehow don't even have fallback data (though we should via widget.trip)
        if (snapshot.hasError && snapshot.data == null && currentTrip.id.isEmpty) {
             final err = snapshot.error.toString().toLowerCase();
             final isNetworkError = err.contains('socket') || err.contains('host lookup') || err.contains('realtime');

             return Scaffold(
                appBar: AppBar(title: const Text("Offline")),
                body: Center(
                   child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                         Icon(Icons.cloud_off, size: 64, color: colors.textMuted),
                         const SizedBox(height: 16),
                         Text("No Connection", style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: colors.textSecondary)),
                         Padding(
                           padding: const EdgeInsets.all(16.0),
                           child: Text(
                             isNetworkError
                                ? "We can't reach the servers right now. Please check your internet."
                                : "Something went wrong. Please try again.",
                             textAlign: TextAlign.center,
                             style: TextStyle(color: colors.textSecondary)
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
        final isAdmin = uid != null && currentTrip.adminIds.contains(uid);
        final isMember = uid != null && currentTrip.memberIds.contains(uid);

        final isRejected = uid != null && currentTrip.rejectedMembers.contains(uid);

        if (!isMember && uid != null) {
           return FutureBuilder<bool>(
              future: TripService().hasPendingJoinRequest(currentTrip.id, uid),
              builder: (context, pendingSnapshot) {
                 if (pendingSnapshot.connectionState == ConnectionState.waiting) {
                    return const Scaffold(body: Center(child: CircularProgressIndicator()));
                 }
                 
                 final isPending = pendingSnapshot.data ?? false;
                 
                 if (currentTrip.visibility == 'public' || isPending || _localJoinRequested) {
                    return _buildRestrictedPublicView(currentTrip, uid, isPending: isPending || _localJoinRequested, isRejected: isRejected);
                 } else {
                    return _buildPrivateBarrier(currentTrip, uid);
                 }
              }
           );
        }

        return DefaultTabController(
          length: 10,
          child: Scaffold(
            backgroundColor: colors.scaffoldBg,
            body: NestedScrollView(
              headerSliverBuilder: (context, innerBoxIsScrolled) {
                return [
                  if (currentTrip.isDead)
                    SliverToBoxAdapter(
                      child: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                        color: Colors.red.shade50,
                        child: Row(
                          children: [
                            Icon(Icons.info_outline, color: Colors.red.shade700, size: 20),
                            const SizedBox(width: 8),
                            Expanded(
                              child: Text(
                                "This trip is dead (creator left). It is now read-only.",
                                style: GoogleFonts.inter(color: Colors.red.shade900, fontWeight: FontWeight.w600, fontSize: 13),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  SliverAppBar(
                    pinned: true,
                    elevation: 0,
                    backgroundColor: colors.scaffoldBg,
                    centerTitle: false,
                    title: Row(
                      children: [
                        Expanded(
                          child: Text(
                            "${currentTrip.name} ${currentTrip.metadata?['emoji'] ?? '✈️'}",
                            style: GoogleFonts.outfit(
                              color: colors.textPrimary,
                              fontSize: 20,
                              fontWeight: FontWeight.bold,
                            ),
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                        const SizedBox(width: 8),
                        _buildStatusBadge(currentTrip.status, colors),
                      ],
                    ),
                    leading: IconButton(
                      icon: Icon(Icons.arrow_back, color: colors.textPrimary),
                      onPressed: () => Navigator.pop(context),
                    ),
                    actions: [
                      Padding(
                        padding: const EdgeInsets.only(right: 8.0),
                        child: PopupMenuButton<String>(
                          icon: Icon(Icons.more_vert, color: colors.textPrimary),
                          onSelected: (value) {
                            if (value == 'leave') {
                              _leaveTrip(currentTrip);
                            } else if (value == 'refresh') {
                              _refreshData();
                            } else if (value == 'save_template') {
                              _showSaveAsTemplateDialog(currentTrip);
                            } else if (value == 'export') {
                              _showExportOptions(currentTrip);
                            }
                          },
                          itemBuilder: (context) => [
                            if (!currentTrip.isDead)
                              const PopupMenuItem(
                                value: 'refresh',
                                child: Row(
                                  children: [
                                    Icon(Icons.refresh, size: 20, color: Colors.blue),
                                    SizedBox(width: 12),
                                    Text("Refresh Data"),
                                  ],
                                ),
                              ),
                            if (!currentTrip.isDead)
                              const PopupMenuItem(
                                value: 'save_template',
                                child: Row(
                                  children: [
                                    Icon(Icons.bookmark_add_outlined, size: 20, color: Colors.amber),
                                    SizedBox(width: 12),
                                    Text("Save as Template"),
                                  ],
                                ),
                              ),
                            const PopupMenuItem(
                              value: 'export',
                              child: Row(
                                children: [
                                  Icon(Icons.ios_share, size: 20, color: Colors.green),
                                  SizedBox(width: 12),
                                  Text("Export Trip"),
                                ],
                              ),
                            ),
                            const PopupMenuItem(
                              value: 'leave',
                              child: Row(
                                children: [
                                  Icon(Icons.exit_to_app, size: 20, color: Colors.red),
                                  SizedBox(width: 12),
                                  Text("Leave Trip", style: TextStyle(color: Colors.red)),
                                ],
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                    bottom: PreferredSize(
                      preferredSize: const Size.fromHeight(48),
                      child: Container(
                        height: 48,
                        width: double.infinity,
                        padding: const EdgeInsets.symmetric(vertical: 4),
                        decoration: BoxDecoration(
                          color: colors.cardBg,
                          border: Border(bottom: BorderSide(color: colors.border, width: 1)),
                        ),
                        child: TabBar(
                          isScrollable: true,
                          indicatorSize: TabBarIndicatorSize.tab,
                          padding: const EdgeInsets.symmetric(horizontal: 12),
                          dividerColor: Colors.transparent,
                          indicator: BoxDecoration(
                            borderRadius: BorderRadius.circular(20),
                            color: AppColors.brand,
                            boxShadow: [
                              BoxShadow(
                                color: AppColors.brand.withOpacity(0.3),
                                blurRadius: 8,
                                offset: const Offset(0, 4),
                              ),
                            ],
                          ),
                          labelColor: Colors.white,
                          unselectedLabelColor: colors.textSecondary,
                          labelStyle: GoogleFonts.inter(fontWeight: FontWeight.bold, fontSize: 13),
                          unselectedLabelStyle: GoogleFonts.inter(fontWeight: FontWeight.w600, fontSize: 13),
                           tabs: const [
                            Tab(text: "Overview"),
                            Tab(text: "Dates"),
                            Tab(text: "Budget"),
                            Tab(text: "Plan"),
                            Tab(text: "Links"),
                            Tab(text: "Chat"),
                            Tab(text: "Polls"),
                            Tab(text: "Gallery"),
                            Tab(text: "Reviews"),
                            Tab(text: "Expenses"),
                          ],
                        ),
                      ),
                    ),
                  ),
                ];
              },
              body: TabBarView(
                children: [
                  _OverviewTab(trip: currentTrip, onRefresh: _refreshData),
                  _DateTab(trip: currentTrip, onRefresh: _refreshData),
                  _BudgetTab(trip: currentTrip, onRefresh: _refreshData),
                  TripPlanTab(trip: currentTrip),
                  _LinksTab(trip: currentTrip, onRefresh: _refreshData),
                  TripChatTab(trip: currentTrip, onRefresh: _refreshData),
                  _PollsTab(trip: currentTrip, onRefresh: _refreshData),
                  _GalleryTab(trip: currentTrip, onRefresh: _refreshData),
                  _ReviewsTab(trip: currentTrip, onRefresh: _refreshData),
                  _ExpensesTab(trip: currentTrip, onRefresh: _refreshData),
                ],
              ),
            ),
          ),
        );
      }
    );
  }

  Widget _buildRestrictedPublicView(Trip trip, String uid, {bool isPending = false, bool isRejected = false}) {
     final colors = context.appColors;
     final publicTrip = Trip(
        id: trip.id,
        name: trip.name,
        location: trip.location,
        startDate: trip.startDate,
        endDate: trip.endDate,
        isDateDecided: trip.isDateDecided,
        createdBy: trip.createdBy,
        memberIds: trip.memberIds,
        adminIds: trip.adminIds,
        metadata: {...?trip.metadata, 'is_dead': true},
        budgetCurrency: trip.budgetCurrency,
        budgetOptions: trip.budgetOptions,
        budgetVotes: trip.budgetVotes,
        coverImageUrl: trip.coverImageUrl,
        visibility: trip.visibility,
        joinCode: trip.joinCode,
     );

     return DefaultTabController(
       length: 5,
       child: Scaffold(
          appBar: AppBar(title: Text(trip.name), leading: const BackButton()),
          floatingActionButton: isRejected ? null : FloatingActionButton.extended(
            onPressed: isPending ? null : () => _showJoinRequestForm(trip, uid),
            label: Text(isPending ? "Request Pending" : "Request to Join", style: const TextStyle(fontWeight: FontWeight.bold)),
            icon: Icon(isPending ? Icons.access_time : Icons.person_add),
            backgroundColor: isPending ? Colors.grey : AppColors.brand,
            foregroundColor: Colors.white,
          ),
          body: Column(
             children: [
                Padding(
                   padding: const EdgeInsets.all(16.0),
                   child: Column(
                      children: [
                         Text("🌍 ${trip.location}", style: GoogleFonts.outfit(fontSize: 22, fontWeight: FontWeight.bold)),
                         const SizedBox(height: 8),
                         Text(
                           isRejected
                             ? "You can view the read-only plan below." 
                             : isPending 
                               ? "Your join request is pending approval. You can still view the basic plan below."
                               : "This is a public agency-led trip. You can view the basic plan below, but you must join the trip to interact with the crew.", 
                           textAlign: TextAlign.center, 
                           style: TextStyle(fontSize: 13, color: colors.textSecondary)
                         ),
                      ],
                   ),
                ),
                const Divider(height: 1, thickness: 1),
                Container(
                  color: colors.cardBg,
                  child: TabBar(
                    isScrollable: true,
                    indicatorSize: TabBarIndicatorSize.tab,
                    padding: const EdgeInsets.symmetric(horizontal: 12),
                    dividerColor: Colors.transparent,
                    indicator: BoxDecoration(
                      borderRadius: BorderRadius.circular(20),
                      color: AppColors.brand,
                    ),
                    labelColor: Colors.white,
                    unselectedLabelColor: colors.textSecondary,
                    labelStyle: GoogleFonts.inter(fontWeight: FontWeight.bold, fontSize: 13),
                    unselectedLabelStyle: GoogleFonts.inter(fontWeight: FontWeight.w600, fontSize: 13),
                    tabs: const [
                      Tab(text: "Overview"),
                      Tab(text: "Dates"),
                      Tab(text: "Budget"),
                      Tab(text: "Plan"),
                      Tab(text: "Links"),
                    ],
                  ),
                ),
                Expanded(
                  child: TabBarView(
                    children: [
                      _OverviewTab(trip: publicTrip, onRefresh: () async {}),
                      _DateTab(trip: publicTrip, onRefresh: () async {}),
                      _BudgetTab(trip: publicTrip, onRefresh: () async {}),
                      TripPlanTab(trip: publicTrip),
                      _LinksTab(trip: publicTrip, onRefresh: () async {}),
                    ],
                  ),
                ),
             ],
          ),
       ),
     );
  }

  Widget _buildPrivateBarrier(Trip trip, String uid) {
     final colors = context.appColors;
     final codeController = TextEditingController();
     return Scaffold(
        body: Center(
           child: Padding(
              padding: const EdgeInsets.all(32.0),
              child: Column(
                 mainAxisAlignment: MainAxisAlignment.center,
                 children: [
                    const Icon(Icons.lock_rounded, size: 64, color: AppColors.brand),
                    const SizedBox(height: 24),
                    Text("Private Trip", style: GoogleFonts.outfit(fontSize: 24, fontWeight: FontWeight.bold)),
                    const SizedBox(height: 12),
                    Text("This trip is private. Please enter the join code provided by the agency to gain access.", textAlign: TextAlign.center, style: TextStyle(color: colors.textSecondary)),
                    const SizedBox(height: 32),
                    TextField(
                       controller: codeController,
                       decoration: InputDecoration(
                          hintText: "Enter Join Code",
                          border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                          filled: true,
                          fillColor: colors.fieldFillBg,
                       ),
                       textAlign: TextAlign.center,
                       textCapitalization: TextCapitalization.characters,
                    ),
                    const SizedBox(height: 16),
                    ElevatedButton(
                       onPressed: () async {
                          if (codeController.text.trim().toUpperCase() == trip.joinCode) {
                             await TripService().respondToJoinRequestManual(trip.id, uid);
                             _refreshData();
                          } else {
                             ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("Invalid Join Code")));
                          }
                       },
                       child: const Text("Verify & Access"),
                    ),
                    TextButton(onPressed: () => Navigator.pop(context), child: const Text("Go Back")),
                 ],
              ),
           ),
        ),
     );
  }

  void _showJoinRequestForm(Trip trip, String uid) {
     final name = TextEditingController();
     final email = TextEditingController();
     final phone = TextEditingController();

     showModalBottomSheet(
        context: context,
        isScrollControlled: true,
        builder: (ctx) => Padding(
           padding: EdgeInsets.only(bottom: MediaQuery.of(ctx).viewInsets.bottom),
           child: SingleChildScrollView(
              padding: const EdgeInsets.all(24),
              child: Column(
                 mainAxisSize: MainAxisSize.min,
                 children: [
                    Text("Join Request", style: GoogleFonts.outfit(fontSize: 20, fontWeight: FontWeight.bold)),
                    const SizedBox(height: 24),
                    TextField(controller: name, decoration: const InputDecoration(labelText: "Full Name")),
                    const SizedBox(height: 12),
                    TextField(controller: email, decoration: const InputDecoration(labelText: "Email Address")),
                    const SizedBox(height: 12),
                    TextField(controller: phone, decoration: const InputDecoration(labelText: "Phone Number")),
                    const SizedBox(height: 24),
                    ElevatedButton(
                       onPressed: () async {
                          await TripService().submitJoinRequest(
                             tripId: trip.id,
                             userId: uid,
                             fullName: name.text.trim(),
                             email: email.text.trim(),
                             phone: phone.text.trim(),
                          );
                          if (mounted) {
                            setState(() {
                              _localJoinRequested = true;
                            });
                          }
                          if (ctx.mounted) Navigator.pop(ctx);
                          if (mounted) ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("Request submitted!")));
                       },
                       child: const Text("Submit Request"),
                    ),
                 ],
              ),
           ),
        ),
     );
  }

  /// Status badge widget for the dashboard app bar
  Widget _buildStatusBadge(String status, AppColors colors) {
    Color color;
    String label;
    IconData icon;

    switch (status) {
      case 'planning':
        color = Colors.orange;
        label = 'Planning';
        icon = Icons.edit_note;
        break;
      case 'confirmed':
        color = Colors.blue;
        label = 'Confirmed';
        icon = Icons.check_circle;
        break;
      case 'ongoing':
        color = Colors.green;
        label = 'Ongoing';
        icon = Icons.flight_takeoff;
        break;
      case 'completed':
        color = Colors.grey;
        label = 'Completed';
        icon = Icons.flag;
        break;
      case 'dead':
        color = Colors.red;
        label = 'Cancelled';
        icon = Icons.cancel;
        break;
      default:
        color = Colors.orange;
        label = 'Planning';
        icon = Icons.edit_note;
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: color.withOpacity(0.15),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 14, color: color),
          const SizedBox(width: 4),
          Text(label, style: TextStyle(color: color, fontSize: 12, fontWeight: FontWeight.bold)),
        ],
      ),
    );
  }
}


// -----------------------------------------------------------------------------
// 1. OVERVIEW TAB
// -----------------------------------------------------------------------------
class _OverviewTab extends StatefulWidget {
  final Trip trip;
  final Future<void> Function() onRefresh;
  const _OverviewTab({required this.trip, required this.onRefresh});

  @override
  State<_OverviewTab> createState() => _OverviewTabState();
}

class _OverviewTabState extends State<_OverviewTab> with AutomaticKeepAliveClientMixin {
  @override
  bool get wantKeepAlive => true;

  TripMetadata? _metadata;
  bool _metadataLoading = true;
  TripInternationalInfo? _internationalInfo;
  bool _internationalLoading = false;
  bool _isInternational = false;
  bool _domesticLoading = false;
  List<ChecklistItem> _checklistItems = [];
  bool _checklistLoading = true;
  bool _aiChecklistGenerating = false;
  final ChecklistService _checklistService = ChecklistService();

  // Weather
  WeatherForecast? _weatherForecast;
  bool _weatherLoading = true;
  final WeatherService _weatherService = WeatherService();

  @override
  void initState() {
    super.initState();
    _loadMetadata();
    _loadChecklist();
    _loadWeather();
  }

  Future<void> _loadMetadata() async {
    try {
      final tripService = TripService();
      var data = await tripService.getTripMetadata(widget.trip.id);
      if (data == null) {
        // First time — enrich via AI
        data = await tripService.enrichTripMetadata(widget.trip);
      }
      if (mounted) setState(() { _metadata = data; _metadataLoading = false; });

      // After metadata loads, check for international travel
      _loadInternationalInfo(data);
    } catch (e) {
      debugPrint('Error loading trip metadata: $e');
      if (mounted) setState(() => _metadataLoading = false);
    }
  }

  Future<void> _loadInternationalInfo(TripMetadata? metadata) async {
    // Use passport nationality for visa/embassy lookups (priority: passport → country → residence)
    final userCountry = AuthService.instance.userProfile?.nationalityCountry 
        ?? AuthService.instance.userProfile?.country;
    if (userCountry == null || userCountry.isEmpty) return;

    // Determine if trip is international by comparing user country to destination
    // Try metadata country code first, then parse from trip location
    var destCountryCode = metadata?.destinationCountryCode;
    destCountryCode ??= EmergencyNumbersDB.countryCodeFromLocation(widget.trip.location);
    if (destCountryCode == null) return;

    // Check if domestic: compare destination country code with user's country
    // Common patterns: user country might be "India" and dest code "IN", etc.
    final userCountryLower = userCountry.toLowerCase().trim();
    final destLower = destCountryCode.toLowerCase().trim();
    
    // Normalize user country name to code using EmergencyNumbersDB lookup
    final userCode = EmergencyNumbersDB.countryCodeFromLocation(userCountry) ?? userCountryLower;
    final isDomestic = userCode == destLower || userCountryLower == destLower;
    
    if (mounted) setState(() => _isInternational = !isDomestic);
    
    if (isDomestic) {
      // Load domestic travel intelligence if not already enriched
      if (metadata != null && metadata.localTransportTips == null) {
        if (mounted) setState(() => _domesticLoading = true);
        try {
          final tripService = TripService();
          final enriched = await tripService.enrichDomesticInfo(
            widget.trip.id, widget.trip.location,
          );
          if (enriched != null && mounted) {
            setState(() { _metadata = enriched; _domesticLoading = false; });
          } else {
            if (mounted) setState(() => _domesticLoading = false);
          }
        } catch (e) {
          debugPrint('Error loading domestic info: $e');
          if (mounted) setState(() => _domesticLoading = false);
        }
      }
      return;
    }

    if (mounted) setState(() => _internationalLoading = true);

    try {
      final tripService = TripService();
      var info = await tripService.getInternationalInfo(widget.trip.id, userCountry);
      if (info == null) {
        info = await tripService.enrichInternationalInfo(widget.trip, userCountry);
      }
      if (mounted) setState(() { _internationalInfo = info; _internationalLoading = false; });
    } catch (e) {
      debugPrint('Error loading international info: $e');
      if (mounted) setState(() => _internationalLoading = false);
    }
  }

  Future<void> _loadChecklist() async {
    try {
      final visaReq = _isInternational && ((_internationalInfo?.visaRequired == true) ||
          (_metadata?.visaRequired?.toLowerCase().contains('required') == true));
      final items = await _checklistService.generateSmartChecklist(
        trip: widget.trip,
        isInternational: _isInternational,
        visaRequired: visaReq,
      );
      if (mounted) setState(() { _checklistItems = items; _checklistLoading = false; });
    } catch (e) {
      debugPrint('Error loading checklist: $e');
      if (mounted) setState(() => _checklistLoading = false);
    }
  }

  Future<void> _regenerateAIChecklist() async {
    if (_aiChecklistGenerating) return;
    setState(() => _aiChecklistGenerating = true);
    try {
      final visaReq = _isInternational && ((_internationalInfo?.visaRequired == true) ||
          (_metadata?.visaRequired?.toLowerCase().contains('required') == true));
      final items = await _checklistService.generateSmartChecklist(
        trip: widget.trip,
        isInternational: _isInternational,
        visaRequired: visaReq,
        regenerate: true,
      );
      if (mounted) setState(() { _checklistItems = items; _aiChecklistGenerating = false; });
    } catch (e) {
      debugPrint('Error regenerating AI checklist: $e');
      if (mounted) setState(() => _aiChecklistGenerating = false);
    }
  }

  Future<void> _loadWeather() async {
    try {
      final forecast = await _weatherService.getWeatherForTrip(
        tripId: widget.trip.id,
        location: widget.trip.location,
        startDate: widget.trip.startDate,
        endDate: widget.trip.endDate,
      );
      if (mounted) setState(() { _weatherForecast = forecast; _weatherLoading = false; });
    } catch (e) {
      debugPrint('Error loading weather: $e');
      if (mounted) setState(() => _weatherLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    super.build(context); // Required for KeepAlive
    final colors = context.appColors;
    final isDark = context.isDark;
    // Determine trip status
    final now = DateTime.now();
    final isPast = widget.trip.endDate != null && widget.trip.endDate!.isBefore(now);
    
    return Scaffold(
      backgroundColor: Colors.transparent,
      floatingActionButton: widget.trip.isDead ? null : FloatingActionButton.extended(
        onPressed: () => _showAIAssistant(context),
        label: const Text("Plan with AI"),
        icon: const Icon(Icons.auto_awesome),
        backgroundColor: colors.cardBg,
        foregroundColor: Colors.purple,
      ),
      body: RefreshIndicator(
        onRefresh: widget.onRefresh,
        child: SingleChildScrollView(
          physics: const AlwaysScrollableScrollPhysics(),
          padding: EdgeInsets.zero,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Integrated Hero Image (Full Width, Curved Bottom)
              _buildIntegratedHero(context),
              Padding(
                padding: const EdgeInsets.fromLTRB(20, 0, 20, 20),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    if (isPast) _buildPastTripBanner(),
                    
                    // Join Requests for Admins (Relational Table)
                    if (widget.trip.adminIds.contains(Supabase.instance.client.auth.currentUser?.id)) ...[
                       FutureBuilder<List<Map<String, dynamic>>>(
                         future: TripService().getJoinRequests(widget.trip.id),
                         builder: (context, snapshot) {
                            if (!snapshot.hasData || snapshot.data!.isEmpty) {
                               return const SizedBox.shrink();
                            }
                            return Padding(
                               padding: const EdgeInsets.only(top: 20),
                               child: _buildPendingRequests(context, snapshot.data!),
                            );
                         }
                       )
                    ],

                    const SizedBox(height: 12),
                    _buildOverviewStats(context),
                    
                    const SizedBox(height: 24),
                    // Trip Intelligence Card
                    _buildTripIntelligenceCard(),

                    // International Travel Info Card
                    _buildInternationalTravelCard(),

                    // Domestic Travel Intelligence Card
                    if (!_isInternational) _buildDomesticTravelCard(),

                    // Weather Forecast Card
                    if (!widget.trip.isDead) ...[
                      const SizedBox(height: 16),
                      _buildWeatherCard(colors),
                    ],

                    // Travel Checklist
                    if (!widget.trip.isDead) ...[
                      const SizedBox(height: 16),
                      _buildChecklistCard(colors),
                    ],

                    // Emergency Info
                    const SizedBox(height: 16),
                    _buildEmergencyInfoCard(colors),

                    const SizedBox(height: 20),
                    // ABOUT THIS TRIP SECTION
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        _buildSectionHeader("About this Trip"),
                        if (widget.trip.adminIds.contains(Supabase.instance.client.auth.currentUser?.id) && !widget.trip.isDead)
                          IconButton(
                            onPressed: () => _showEditAboutDialog(context),
                            icon: const Icon(Icons.edit, color: AppColors.brand, size: 20),
                            tooltip: "Edit Description",
                          ),
                      ],
                    ),
                    const SizedBox(height: 12),
                    if (widget.trip.about != null && widget.trip.about!.isNotEmpty)
                      Text(
                        widget.trip.about!,
                        style: TextStyle(
                          fontSize: 15,
                          color: colors.textSecondary,
                          height: 1.6,
                        ),
                      )
                    else if (widget.trip.adminIds.contains(Supabase.instance.client.auth.currentUser?.id) && !widget.trip.isDead)
                      InkWell(
                        onTap: () => _showEditAboutDialog(context),
                        borderRadius: BorderRadius.circular(12),
                        child: Container(
                          width: double.infinity,
                          padding: const EdgeInsets.all(16),
                          decoration: BoxDecoration(
                            color: isDark ? AppColors.brand.withOpacity(0.15) : Colors.blue.shade50,
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(color: isDark ? AppColors.brand.withOpacity(0.3) : Colors.blue.shade100, style: BorderStyle.solid),
                          ),
                          child: Column(
                            children: [
                              Icon(Icons.edit_note, color: AppColors.brand, size: 32),
                              const SizedBox(height: 8),
                              Text(
                                "Add a description to tell your crew what this trip is all about.",
                                textAlign: TextAlign.center,
                                style: TextStyle(color: isDark ? colors.textPrimary : Colors.blue.shade800),
                              ),
                            ],
                          ),
                        ),
                      )
                    else
                      Text(
                        "No description provided for this trip yet.",
                        style: TextStyle(fontSize: 15, color: colors.textMuted, fontStyle: FontStyle.italic),
                      ),
                    
                    const SizedBox(height: 32),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        _buildSectionHeader("The Travel Crew"),
                        if ((widget.trip.adminIds.contains(Supabase.instance.client.auth.currentUser?.id) || widget.trip.createdBy == Supabase.instance.client.auth.currentUser?.id) && !widget.trip.isDead)
                          IconButton(
                             onPressed: () {
                               showModalBottomSheet(
                                 context: context,
                                 shape: const RoundedRectangleBorder(
                                   borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
                                 ),
                                 builder: (ctx) => Padding(
                                   padding: const EdgeInsets.symmetric(vertical: 24, horizontal: 16),
                                   child: Column(
                                     mainAxisSize: MainAxisSize.min,
                                     children: [
                                       Container(
                                         width: 40,
                                         height: 5,
                                         decoration: BoxDecoration(
                                           color: colors.textMuted,
                                           borderRadius: BorderRadius.circular(10),
                                         ),
                                       ),
                                       const SizedBox(height: 24),
                                       Text("Invite Members", style: GoogleFonts.outfit(fontSize: 20, fontWeight: FontWeight.bold)),
                                       const SizedBox(height: 8),
                                       Text("How would you like to invite people to this trip?", style: GoogleFonts.inter(color: colors.textSecondary), textAlign: TextAlign.center),
                                       const SizedBox(height: 24),
                                       ListTile(
                                         leading: const CircleAvatar(backgroundColor: AppColors.brand, child: Icon(Icons.link, color: Colors.white)),
                                         title: const Text("Share Invite Link", style: TextStyle(fontWeight: FontWeight.bold)),
                                         subtitle: const Text("Send a direct link that opens the app."),
                                         onTap: () {
                                           Navigator.pop(ctx);
                                           final String webUrl = "https://www.wanderwith.online/join/${widget.trip.id}";
                                           final String appUrl = "wanderwith://wanderwith.online/join/${widget.trip.id}";
                                           Share.share(
                                             "Join my trip on WanderWith! 🎒\n\n"
                                             "Tap to join instantly: $appUrl\n\n"
                                             "Or use the web link: $webUrl"
                                           );
                                         },
                                       ),
                                       const Divider(),
                                       ListTile(
                                         leading: CircleAvatar(backgroundColor: colors.surfaceBg, child: Icon(Icons.copy, color: colors.textSecondary)),
                                         title: const Text("Copy Join Code", style: TextStyle(fontWeight: FontWeight.bold)),
                                         subtitle: const Text("Just copy the raw ID text."),
                                         onTap: () {
                                           Navigator.pop(ctx);
                                           Clipboard.setData(ClipboardData(text: widget.trip.id));
                                           ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("Trip Code copied to clipboard!")));
                                         },
                                       ),
                                     ],
                                   ),
                                 ),
                               );
                             },
                             icon: const Icon(Icons.person_add_outlined, color: AppColors.brand),
                             tooltip: "Invite Members",
                          ),
                      ],
                    ),
                    const SizedBox(height: 16),
                    _buildMembersGrid(context),
                    const SizedBox(height: 100), // FAB Space
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildIntegratedHero(BuildContext context) {
    final colors = context.appColors;
    final isDark = context.isDark;
    return Container(
      width: double.infinity,
      height: 240,
      decoration: BoxDecoration(color: colors.surfaceBg),
      child: Stack(
        fit: StackFit.expand,
        children: [
          // Curved Image
          ClipPath(
            clipper: _HeaderClipper(),
            child: widget.trip.coverImageUrl != null
              ? CachedNetworkImage(
                  imageUrl: widget.trip.coverImageUrl!,
                  fit: BoxFit.cover,
                  placeholder: (c, u) => Container(color: colors.surfaceBg),
                )
              : Container(
                  decoration: const BoxDecoration(
                    gradient: LinearGradient(
                      colors: [Color(0xFF64B5F6), Color(0xFF1E88E5)],
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                    ),
                  ),
                  child: const Center(child: Icon(Icons.flight_takeoff, size: 64, color: Colors.white70)),
                ),
          ),
          // Gradient for text legibility
          ClipPath(
            clipper: _HeaderClipper(),
            child: Container(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: [
                    Colors.black.withOpacity(0.05),
                    Colors.black.withOpacity(0.4),
                  ],
                ),
              ),
            ),
          ),
          // Floating Confirm Badge
          Positioned(
            bottom: 45,
            left: 20,
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
              decoration: BoxDecoration(
                color: isDark ? Colors.black.withOpacity(0.85) : Colors.white.withOpacity(0.95),
                borderRadius: BorderRadius.circular(10),
                boxShadow: [
                  BoxShadow(color: Colors.black.withOpacity(0.1), blurRadius: 8, offset: const Offset(0, 4)),
                ],
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Icon(Icons.check_circle, size: 14, color: Colors.green),
                  const SizedBox(width: 4),
                  Text(
                    "TRIP CONFIRMED",
                    style: GoogleFonts.inter(
                      fontSize: 10,
                      fontWeight: FontWeight.bold,
                      letterSpacing: 0.5,
                      color: isDark ? Colors.white : Colors.black87,
                    ),
                  ),
                ],
              ),
            ),
          ),
          // Location Overlay on Image
          Positioned(
            bottom: 80,
            left: 20,
            child: Text(
              widget.trip.location,
              style: GoogleFonts.outfit(
                fontSize: 24,
                fontWeight: FontWeight.bold,
                color: Colors.white,
                shadows: [const Shadow(color: Colors.black45, blurRadius: 8, offset: Offset(0, 2))],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSectionHeader(String title) {
    final colors = context.appColors;
    return Text(
      title,
      style: GoogleFonts.outfit(
        fontSize: 18,
        fontWeight: FontWeight.bold,
        color: colors.textPrimary,
      ),
    );
  }

  Widget _buildStatusBadge(String text, Color color) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(6),
        border: Border.all(color: color.withOpacity(0.3)),
      ),
      child: Text(
        text,
        style: TextStyle(color: color, fontSize: 10, fontWeight: FontWeight.bold),
      ),
    );
  }

  Widget _buildPastTripBanner() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(12),
      margin: const EdgeInsets.only(top: 20),
      decoration: BoxDecoration(
        color: Colors.amber.shade50,
        borderRadius: BorderRadius.circular(15),
        border: Border.all(color: Colors.amber.shade200),
      ),
      child: Row(
        children: [
          Icon(Icons.history, color: Colors.amber.shade800),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              "This trip has concluded. Relive the memories in the gallery!",
              style: TextStyle(color: Colors.amber.shade900, fontWeight: FontWeight.w500, fontSize: 13),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildOverviewStats(BuildContext context) {
    final days = widget.trip.endDate != null && widget.trip.startDate != null
        ? widget.trip.endDate!.difference(widget.trip.startDate!).inDays + 1
        : 0;

    return Row(
      children: [
        _StatCardV2(
          icon: Icons.calendar_today_outlined,
          label: "Duration",
          value: "$days Days",
          color: AppColors.brand,
        ),
        const SizedBox(width: 12),
        _StatCardV2(
          icon: Icons.people_outline,
          label: "Crew",
          value: "${widget.trip.memberIds.length}",
          color: Colors.deepPurple,
        ),
        const SizedBox(width: 12),
        _StatCardV2(
          icon: Icons.account_balance_wallet_outlined,
          label: "Budget",
          value: widget.trip.estimatedCost > 0 
              ? "${widget.trip.budgetCurrency}${widget.trip.estimatedCost.toInt()}"
              : "TBD",
          color: Colors.teal,
        ),
      ],
    );
  }

  Widget _buildTripIntelligenceCard() {
    final colors = context.appColors;

    if (_metadataLoading) {
      return Container(
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          color: colors.cardBg,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: colors.border),
        ),
        child: Row(
          children: [
            SizedBox(
              width: 18, height: 18,
              child: CircularProgressIndicator(strokeWidth: 2, color: AppColors.brand),
            ),
            const SizedBox(width: 12),
            Text("Loading destination info...",
                style: TextStyle(color: colors.textSecondary, fontSize: 13)),
          ],
        ),
      );
    }

    if (_metadata == null) return const SizedBox.shrink();

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: colors.cardBg,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: colors.border),
        boxShadow: [BoxShadow(color: colors.shadow, blurRadius: 8, offset: const Offset(0, 2))],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(children: [
            const Icon(Icons.travel_explore, color: AppColors.brand, size: 20),
            const SizedBox(width: 8),
            Text("Destination Intel",
                style: GoogleFonts.outfit(fontWeight: FontWeight.bold, fontSize: 16, color: colors.textPrimary)),
          ]),
          const SizedBox(height: 14),
          _intelRow(colors, "🗓 Best Time", "${_metadata!.bestTimeToVisit ?? '-'} ${_metadata!.bestTimeWeatherEmoji ?? ''}"),
          _intelRow(colors, "👥 Crowds", _metadata!.crowdLevel ?? "-"),
          _intelRow(colors, "🌡 Avg Temp", _metadata!.avgTempRange ?? "-"),
          if (_isInternational) ...[
            _intelRow(colors, "🛂 Visa", _metadata!.visaRequired ?? "-"),
            _intelRow(colors, "💱 Currency", _metadata!.currencyCode != null
                ? "${_metadata!.currencyCode} (${_metadata!.currencyName ?? ''})"
                : "-"),
            if (_internationalInfo?.entryRequirements != null)
              _intelRow(colors, "📋 Entry", _internationalInfo!.entryRequirements!),
            if (_internationalInfo?.drivingSide != null)
              _intelRow(colors, "🚗 Driving", "Drives on the ${_internationalInfo!.drivingSide!}"),
          ],
          if (!_isInternational)
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 4),
              child: Row(
                children: [
                  Icon(Icons.home_rounded, size: 15, color: colors.textMuted),
                  const SizedBox(width: 6),
                  Text("Domestic trip — no visa or exchange needed",
                      style: TextStyle(color: colors.textMuted, fontSize: 12, fontStyle: FontStyle.italic)),
                ],
              ),
            ),
          _intelRow(colors, "🕐 Timezone", _metadata!.timezone ?? "-"),
          _intelRow(colors, "🗣 Language", _metadata!.language ?? "-"),
          if (_metadata!.emergencyNumber != null)
            _intelRow(colors, "🚨 Emergency", _metadata!.emergencyNumber!),
        ],
      ),
    );
  }

  Widget _intelRow(AppColors colors, String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label, style: TextStyle(color: colors.textSecondary, fontSize: 13)),
          const SizedBox(width: 12),
          Flexible(
            child: Text(value,
                style: TextStyle(fontWeight: FontWeight.w600, fontSize: 13, color: colors.textPrimary),
                textAlign: TextAlign.end),
          ),
        ],
      ),
    );
  }

  Widget _buildInternationalTravelCard() {
    final colors = context.appColors;

    if (_internationalLoading) {
      return Padding(
        padding: const EdgeInsets.only(top: 16),
        child: Container(
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(
            color: colors.cardBg,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: colors.border),
          ),
          child: Row(
            children: [
              SizedBox(
                width: 18, height: 18,
                child: CircularProgressIndicator(strokeWidth: 2, color: Colors.orange),
              ),
              const SizedBox(width: 12),
              Text("Loading travel requirements...",
                  style: TextStyle(color: colors.textSecondary, fontSize: 13)),
            ],
          ),
        ),
      );
    }

    if (_internationalInfo == null) return const SizedBox.shrink();

    final info = _internationalInfo!;

    return Padding(
      padding: const EdgeInsets.only(top: 16),
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: colors.cardBg,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: colors.border),
          boxShadow: [BoxShadow(color: colors.shadow, blurRadius: 8, offset: const Offset(0, 2))],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header
            Row(children: [
              const Icon(Icons.flight_takeoff, color: Colors.orange, size: 20),
              const SizedBox(width: 8),
              Expanded(
                child: Text("International Travel Info",
                    style: GoogleFonts.outfit(fontWeight: FontWeight.bold, fontSize: 16, color: colors.textPrimary)),
              ),
            ]),
            const SizedBox(height: 4),
            Text("${info.userCountry} → ${info.destCountry}",
                style: TextStyle(color: colors.textMuted, fontSize: 12)),
            const SizedBox(height: 14),

            // Visa Section
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: info.visaRequired
                    ? Colors.red.withOpacity(0.08)
                    : Colors.green.withOpacity(0.08),
                borderRadius: BorderRadius.circular(10),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(children: [
                    Icon(
                      info.visaRequired ? Icons.warning_amber_rounded : Icons.check_circle_outline,
                      color: info.visaRequired ? Colors.red : Colors.green,
                      size: 18,
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        info.visaRequired ? "Visa Required" : "Visa Free / On Arrival",
                        style: TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 14,
                          color: info.visaRequired ? Colors.red : Colors.green,
                        ),
                      ),
                    ),
                  ]),
                  if (info.visaType != null) ...[
                    const SizedBox(height: 6),
                    _intelRow(colors, "Type", info.visaType!),
                  ],
                  if (info.stayDuration != null)
                    _intelRow(colors, "Stay", info.stayDuration!),
                  if (info.processingTime != null)
                    _intelRow(colors, "Processing", info.processingTime!),
                  if (info.visaFeeEstimate != null)
                    _intelRow(colors, "Est. Fee", info.visaFeeEstimate!),
                  if (info.visaRecommendedApplyDate != null)
                    _intelRow(colors, "Apply By", info.visaRecommendedApplyDate!),
                  if (info.visaApplyUrl != null) ...[
                    const SizedBox(height: 6),
                    GestureDetector(
                      onTap: () async {
                        final url = Uri.parse(info.visaApplyUrl!);
                        if (await canLaunchUrl(url)) launchUrl(url, mode: LaunchMode.externalApplication);
                      },
                      child: Text("Apply Online →",
                          style: TextStyle(color: AppColors.brand, fontSize: 13, fontWeight: FontWeight.w600)),
                    ),
                  ],
                ],
              ),
            ),

            // Embassy Section
            if (info.embassyName != null) ...[
              const SizedBox(height: 14),
              Text("🏛 Embassy / Consulate",
                  style: TextStyle(fontWeight: FontWeight.w600, fontSize: 13, color: colors.textPrimary)),
              const SizedBox(height: 6),
              if (info.embassyName != null)
                _intelRow(colors, "Name", info.embassyName!),
              if (info.embassyAddress != null)
                _intelRow(colors, "Address", info.embassyAddress!),
              if (info.embassyPhone != null)
                _intelRow(colors, "Phone", info.embassyPhone!),
              if (info.embassyEmergencyNumber != null)
                _intelRow(colors, "Emergency", info.embassyEmergencyNumber!),
              if (info.embassyEmail != null)
                _intelRow(colors, "Email", info.embassyEmail!),
            ],

            // Emergency Numbers Section
            if (info.localEmergencyNumber != null ||
                info.localPoliceNumber != null ||
                info.localMedicalNumber != null) ...[
              const SizedBox(height: 14),
              Text("🚨 Local Emergency Numbers",
                  style: TextStyle(fontWeight: FontWeight.w600, fontSize: 13, color: colors.textPrimary)),
              const SizedBox(height: 6),
              if (info.localEmergencyNumber != null)
                _intelRow(colors, "Emergency", info.localEmergencyNumber!),
              if (info.localPoliceNumber != null)
                _intelRow(colors, "Police", info.localPoliceNumber!),
              if (info.localMedicalNumber != null)
                _intelRow(colors, "Medical", info.localMedicalNumber!),
            ],

            // K2: Enhanced International Fields
            if (info.passportReminder != null || info.travelInsuranceNote != null || info.entryRequirements != null) ...[
              const SizedBox(height: 14),
              Text("📋 Before You Go",
                  style: TextStyle(fontWeight: FontWeight.w600, fontSize: 13, color: colors.textPrimary)),
              const SizedBox(height: 6),
              if (info.passportReminder != null)
                _intelRow(colors, "🛂 Passport", info.passportReminder!),
              if (info.entryRequirements != null)
                _intelRow(colors, "🏥 Entry Req.", info.entryRequirements!),
              if (info.travelInsuranceNote != null)
                _intelRow(colors, "🛡 Insurance", info.travelInsuranceNote!),
            ],

            if (info.plugType != null || info.simInfo != null || info.drivingSide != null) ...[
              const SizedBox(height: 14),
              Text("🔌 Connectivity & Power",
                  style: TextStyle(fontWeight: FontWeight.w600, fontSize: 13, color: colors.textPrimary)),
              const SizedBox(height: 6),
              if (info.plugType != null)
                _intelRow(colors, "Plug Type", info.plugType!),
              if (info.simInfo != null)
                _intelRow(colors, "SIM / WiFi", info.simInfo!),
              if (info.drivingSide != null)
                _intelRow(colors, "🚗 Drive Side", info.drivingSide!),
            ],

            if (info.tippingCustoms != null) ...[
              const SizedBox(height: 14),
              Text("💰 Tipping Customs",
                  style: TextStyle(fontWeight: FontWeight.w600, fontSize: 13, color: colors.textPrimary)),
              const SizedBox(height: 6),
              Text(info.tippingCustoms!,
                  style: TextStyle(fontSize: 13, color: colors.textSecondary, height: 1.5)),
            ],

            if (info.usefulPhrases != null) ...[
              const SizedBox(height: 14),
              Text("🗣 Useful Phrases",
                  style: TextStyle(fontWeight: FontWeight.w600, fontSize: 13, color: colors.textPrimary)),
              const SizedBox(height: 6),
              Text(info.usefulPhrases!,
                  style: TextStyle(fontSize: 13, color: colors.textSecondary, height: 1.5)),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildDomesticTravelCard() {
    final colors = context.appColors;

    if (_domesticLoading) {
      return Padding(
        padding: const EdgeInsets.only(top: 16),
        child: Container(
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(
            color: colors.cardBg,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: colors.border),
          ),
          child: Row(
            children: [
              SizedBox(
                width: 18, height: 18,
                child: CircularProgressIndicator(strokeWidth: 2, color: Colors.teal),
              ),
              const SizedBox(width: 12),
              Text("Loading local travel tips...",
                  style: TextStyle(color: colors.textSecondary, fontSize: 13)),
            ],
          ),
        ),
      );
    }

    // Check if domestic data has been loaded
    if (_metadata == null ||
        (_metadata!.localTransportTips == null &&
         _metadata!.safetyTips == null &&
         _metadata!.localCustoms == null &&
         _metadata!.localFoodRecommendations == null)) {
      return const SizedBox.shrink();
    }

    return Padding(
      padding: const EdgeInsets.only(top: 16),
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: colors.cardBg,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: colors.border),
          boxShadow: [BoxShadow(color: colors.shadow, blurRadius: 8, offset: const Offset(0, 2))],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(children: [
              const Icon(Icons.explore, color: Colors.teal, size: 20),
              const SizedBox(width: 8),
              Expanded(
                child: Text("Local Travel Tips",
                    style: GoogleFonts.outfit(fontWeight: FontWeight.bold, fontSize: 16, color: colors.textPrimary)),
              ),
            ]),
            const SizedBox(height: 14),

            if (_metadata!.localTransportTips != null) ...[
              _domesticSection(colors, "🚌 Getting Around", _metadata!.localTransportTips!),
              const SizedBox(height: 12),
            ],
            if (_metadata!.simConnectivityInfo != null) ...[
              _domesticSection(colors, "📶 Connectivity", _metadata!.simConnectivityInfo!),
              const SizedBox(height: 12),
            ],
            if (_metadata!.safetyTips != null) ...[
              _domesticSection(colors, "🛡 Safety Tips", _metadata!.safetyTips!),
              const SizedBox(height: 12),
            ],
            if (_metadata!.localCustoms != null) ...[
              _domesticSection(colors, "🙏 Local Customs", _metadata!.localCustoms!),
              const SizedBox(height: 12),
            ],
            if (_metadata!.localFoodRecommendations != null)
              _domesticSection(colors, "🍜 Must-Try Food", _metadata!.localFoodRecommendations!),
          ],
        ),
      ),
    );
  }

  Widget _domesticSection(AppColors colors, String title, String content) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(title,
            style: TextStyle(fontWeight: FontWeight.w600, fontSize: 13, color: colors.textPrimary)),
        const SizedBox(height: 4),
        Text(content,
            style: TextStyle(fontSize: 13, color: colors.textSecondary, height: 1.5)),
      ],
    );
  }

  // ── Weather Forecast Card ──
  Widget _buildWeatherCard(AppColors colors) {
    if (_weatherLoading) {
      return Container(
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          color: colors.cardBg,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: colors.border),
        ),
        child: Row(
          children: [
            const SizedBox(width: 16, height: 16, child: CircularProgressIndicator(strokeWidth: 2)),
            const SizedBox(width: 12),
            Text("Loading weather...", style: TextStyle(color: colors.textSecondary)),
          ],
        ),
      );
    }

    if (_weatherForecast == null) return const SizedBox.shrink();

    final forecast = _weatherForecast!;
    final current = forecast.current;

    return Container(
      decoration: BoxDecoration(
        color: colors.cardBg,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: colors.border),
      ),
      child: Theme(
        data: Theme.of(context).copyWith(dividerColor: Colors.transparent),
        child: ExpansionTile(
          initiallyExpanded: true,
          tilePadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
          childrenPadding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
          title: Row(
            children: [
              const Text("🌤️", style: TextStyle(fontSize: 20)),
              const SizedBox(width: 10),
              Text("Weather", style: GoogleFonts.outfit(fontSize: 16, fontWeight: FontWeight.w600, color: colors.textPrimary)),
              const Spacer(),
              if (current != null)
                Text(
                  "${current.tempC.round()}°C",
                  style: GoogleFonts.inter(fontSize: 16, fontWeight: FontWeight.w700, color: colors.textPrimary),
                ),
            ],
          ),
          subtitle: current != null
            ? Padding(
                padding: const EdgeInsets.only(top: 4),
                child: Text(
                  "${current.condition}  ·  Feels like ${current.feelsLikeC.round()}°C",
                  style: TextStyle(fontSize: 12, color: colors.textSecondary),
                ),
              )
            : null,
          children: [
            // Current conditions row
            if (current != null) ...[
              const SizedBox(height: 8),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceAround,
                children: [
                  _weatherStat(colors, "💧", "${current.humidity}%", "Humidity"),
                  _weatherStat(colors, "💨", "${current.windKph.round()} km/h", "Wind"),
                  _weatherStat(colors, "☀️", current.uv.toStringAsFixed(1), "UV Index"),
                ],
              ),
              const SizedBox(height: 16),
              Divider(color: colors.border, height: 1),
            ],

            // Forecast days
            if (forecast.days.isNotEmpty) ...[
              const SizedBox(height: 12),
              Text("Forecast", style: GoogleFonts.inter(fontSize: 13, fontWeight: FontWeight.w600, color: colors.textSecondary)),
              const SizedBox(height: 8),
              ...forecast.days.map((day) => _buildWeatherDayRow(colors, day)),
            ],

            // Sunrise / Sunset for today
            if (forecast.days.isNotEmpty && forecast.days.first.sunrise.isNotEmpty) ...[
              const SizedBox(height: 12),
              Divider(color: colors.border, height: 1),
              const SizedBox(height: 10),
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text("🌅 ${forecast.days.first.sunrise}", style: TextStyle(fontSize: 12, color: colors.textSecondary)),
                  const SizedBox(width: 20),
                  Text("🌇 ${forecast.days.first.sunset}", style: TextStyle(fontSize: 12, color: colors.textSecondary)),
                ],
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _weatherStat(AppColors colors, String emoji, String value, String label) {
    return Column(
      children: [
        Text(emoji, style: const TextStyle(fontSize: 16)),
        const SizedBox(height: 4),
        Text(value, style: GoogleFonts.inter(fontSize: 14, fontWeight: FontWeight.w600, color: colors.textPrimary)),
        Text(label, style: TextStyle(fontSize: 11, color: colors.textMuted)),
      ],
    );
  }

  Widget _buildWeatherDayRow(AppColors colors, WeatherDay day) {
    final dayName = _shortDayName(day.date);
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: Row(
        children: [
          SizedBox(
            width: 42,
            child: Text(dayName, style: GoogleFonts.inter(fontSize: 13, fontWeight: FontWeight.w500, color: colors.textPrimary)),
          ),
          Text(day.conditionEmoji, style: const TextStyle(fontSize: 18)),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              day.condition,
              style: TextStyle(fontSize: 12, color: colors.textSecondary),
              overflow: TextOverflow.ellipsis,
            ),
          ),
          if (day.chanceOfRain > 0) ...[
            Text("💧${day.chanceOfRain}%", style: TextStyle(fontSize: 11, color: Colors.blue.shade400)),
            const SizedBox(width: 8),
          ],
          Text(
            "${day.minTempC.round()}° / ${day.maxTempC.round()}°",
            style: GoogleFonts.inter(fontSize: 13, fontWeight: FontWeight.w500, color: colors.textPrimary),
          ),
        ],
      ),
    );
  }

  String _shortDayName(DateTime date) {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final target = DateTime(date.year, date.month, date.day);
    final diff = target.difference(today).inDays;
    if (diff == 0) return 'Today';
    if (diff == 1) return 'Tmrw';
    const days = ['Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat', 'Sun'];
    return days[date.weekday - 1];
  }

  Widget _buildChecklistCard(AppColors colors) {
    if (_checklistLoading) {
      return Container(
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          color: colors.cardBg,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: colors.border),
        ),
        child: Row(
          children: [
            const SizedBox(width: 16, height: 16, child: CircularProgressIndicator(strokeWidth: 2)),
            const SizedBox(width: 12),
            Text("Loading checklist...", style: TextStyle(color: colors.textSecondary)),
          ],
        ),
      );
    }

    final checked = _checklistItems.where((i) => i.isChecked).length;
    final total = _checklistItems.length;
    final progress = total > 0 ? checked / total : 0.0;

    // Group items by category
    final grouped = <String, List<ChecklistItem>>{};
    for (final item in _checklistItems) {
      grouped.putIfAbsent(item.category, () => []).add(item);
    }

    return Container(
      decoration: BoxDecoration(
        color: colors.cardBg,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: colors.border),
      ),
      child: Theme(
        data: Theme.of(context).copyWith(dividerColor: Colors.transparent),
        child: ExpansionTile(
          initiallyExpanded: false,
          tilePadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
          childrenPadding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
          title: Row(
            children: [
              const Icon(Icons.checklist_rounded, color: AppColors.brand, size: 22),
              const SizedBox(width: 10),
              Text("Travel Checklist", style: GoogleFonts.outfit(fontSize: 16, fontWeight: FontWeight.w600, color: colors.textPrimary)),
              const Spacer(),
              Text("$checked/$total", style: GoogleFonts.inter(fontSize: 13, color: colors.textSecondary, fontWeight: FontWeight.w500)),
            ],
          ),
          subtitle: Padding(
            padding: const EdgeInsets.only(top: 8),
            child: ClipRRect(
              borderRadius: BorderRadius.circular(4),
              child: LinearProgressIndicator(
                value: progress,
                backgroundColor: colors.border,
                valueColor: AlwaysStoppedAnimation<Color>(
                  progress >= 1.0 ? Colors.green : AppColors.brand,
                ),
                minHeight: 4,
              ),
            ),
          ),
          children: [
            ...grouped.entries.map((entry) {
              return Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const SizedBox(height: 12),
                  Text(
                    "${ChecklistItem.categoryIcon(entry.key)} ${ChecklistItem.categoryLabel(entry.key)}",
                    style: GoogleFonts.inter(fontSize: 13, fontWeight: FontWeight.w600, color: colors.textSecondary),
                  ),
                  ...entry.value.map((item) => _buildChecklistItemTile(colors, item)),
                ],
              );
            }),
            const SizedBox(height: 12),
            // Add custom item button
            InkWell(
              onTap: () => _showAddChecklistItemDialog(colors),
              borderRadius: BorderRadius.circular(10),
              child: Container(
                padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 14),
                decoration: BoxDecoration(
                  border: Border.all(color: AppColors.brand.withOpacity(0.3)),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(Icons.add, size: 18, color: AppColors.brand),
                    const SizedBox(width: 6),
                    Text("Add Item", style: GoogleFonts.inter(fontSize: 13, fontWeight: FontWeight.w600, color: AppColors.brand)),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 8),
            // AI Regenerate button
            InkWell(
              onTap: _aiChecklistGenerating ? null : _regenerateAIChecklist,
              borderRadius: BorderRadius.circular(10),
              child: Container(
                padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 14),
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: [
                      Colors.purple.withOpacity(0.08),
                      AppColors.brand.withOpacity(0.08),
                    ],
                  ),
                  border: Border.all(color: Colors.purple.withOpacity(0.25)),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: _aiChecklistGenerating
                      ? [
                          SizedBox(width: 16, height: 16, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.purple)),
                          const SizedBox(width: 8),
                          Text("Generating...", style: GoogleFonts.inter(fontSize: 13, fontWeight: FontWeight.w600, color: Colors.purple)),
                        ]
                      : [
                          Text("✨", style: TextStyle(fontSize: 15)),
                          const SizedBox(width: 6),
                          Text(
                            _checklistItems.any((i) => i.isAutoGenerated) ? "Regenerate with AI" : "Generate with AI",
                            style: GoogleFonts.inter(fontSize: 13, fontWeight: FontWeight.w600, color: Colors.purple),
                          ),
                        ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildChecklistItemTile(AppColors colors, ChecklistItem item) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 2),
      child: InkWell(
        onLongPress: () => _showAssignItemSheet(colors, item),
        borderRadius: BorderRadius.circular(8),
        child: Row(
          children: [
            SizedBox(
              width: 24,
              height: 24,
              child: Checkbox(
                value: item.isChecked,
                onChanged: (val) async {
                  if (val == null) return;
                  await _checklistService.toggleItem(item.id, val);
                  // Reload
                  final items = await _checklistService.getChecklist(widget.trip.id);
                  if (mounted) setState(() => _checklistItems = items);
                },
                activeColor: AppColors.brand,
                materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
                visualDensity: VisualDensity.compact,
              ),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    item.itemText,
                    style: TextStyle(
                      fontSize: 14,
                      color: item.isChecked ? colors.textMuted : colors.textPrimary,
                      decoration: item.isChecked ? TextDecoration.lineThrough : null,
                    ),
                  ),
                  if (item.assignedTo != null)
                    FutureBuilder<String>(
                      future: _getAssigneeName(item.assignedTo!),
                      builder: (ctx, snap) {
                        if (!snap.hasData) return const SizedBox.shrink();
                        return Text(
                          "→ ${snap.data}",
                          style: TextStyle(fontSize: 11, color: AppColors.brand, fontWeight: FontWeight.w500),
                        );
                      },
                    ),
                ],
              ),
            ),
            if (!item.isAutoGenerated)
              GestureDetector(
                onTap: () async {
                  await _checklistService.deleteItem(item.id);
                  final items = await _checklistService.getChecklist(widget.trip.id);
                  if (mounted) setState(() => _checklistItems = items);
                },
                child: Icon(Icons.close, size: 16, color: colors.textMuted),
              ),
          ],
        ),
      ),
    );
  }

  /// Cache for member profiles to avoid repeated DB calls
  Map<String, String>? _memberNameCache;

  Future<String> _getAssigneeName(String userId) async {
    if (_memberNameCache != null && _memberNameCache!.containsKey(userId)) {
      return _memberNameCache![userId]!;
    }
    try {
      final profile = await Supabase.instance.client
          .from('profiles')
          .select('full_name')
          .eq('id', userId)
          .maybeSingle();
      final name = profile?['full_name'] ?? 'Unknown';
      _memberNameCache ??= {};
      _memberNameCache![userId] = name;
      return name;
    } catch (_) {
      return 'Unknown';
    }
  }

  void _showAssignItemSheet(AppColors colors, ChecklistItem item) async {
    try {
      final profiles = await TripService().getTripMembersProfiles(widget.trip.memberIds);
      if (!mounted) return;

      showModalBottomSheet(
        context: context,
        backgroundColor: colors.surfaceBg,
        shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(20))),
        builder: (ctx) {
          return Padding(
            padding: const EdgeInsets.fromLTRB(16, 16, 16, 32),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Center(
                  child: Container(
                    width: 40, height: 4,
                    decoration: BoxDecoration(color: colors.border, borderRadius: BorderRadius.circular(2)),
                  ),
                ),
                const SizedBox(height: 16),
                Text("Assign Item", style: GoogleFonts.outfit(fontSize: 18, fontWeight: FontWeight.bold, color: colors.textPrimary)),
                Text('"${item.itemText}"', style: TextStyle(fontSize: 13, color: colors.textSecondary)),
                const SizedBox(height: 16),
                // Unassign option
                if (item.assignedTo != null)
                  ListTile(
                    leading: Icon(Icons.person_off_outlined, color: colors.textMuted),
                    title: Text("Unassign", style: TextStyle(color: colors.textPrimary)),
                    onTap: () async {
                      Navigator.pop(ctx);
                      await _checklistService.assignItem(item.id, null);
                      _memberNameCache = null;
                      final items = await _checklistService.getChecklist(widget.trip.id);
                      if (mounted) setState(() => _checklistItems = items);
                    },
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  ),
                ...profiles.map((profile) {
                  final isCurrentAssignee = item.assignedTo == profile.uid;
                  return ListTile(
                    leading: CircleAvatar(
                      radius: 18,
                      backgroundImage: (profile.avatarUrl != null && profile.avatarUrl!.isNotEmpty)
                          ? CachedNetworkImageProvider(profile.avatarUrl!)
                          : null,
                      child: (profile.avatarUrl == null || profile.avatarUrl!.isEmpty)
                          ? Text(profile.fullName[0].toUpperCase(), style: const TextStyle(fontSize: 14))
                          : null,
                    ),
                    title: Text(
                      profile.fullName,
                      style: TextStyle(
                        color: isCurrentAssignee ? AppColors.brand : colors.textPrimary,
                        fontWeight: isCurrentAssignee ? FontWeight.w600 : FontWeight.normal,
                      ),
                    ),
                    trailing: isCurrentAssignee ? Icon(Icons.check_circle, color: AppColors.brand, size: 20) : null,
                    onTap: () async {
                      Navigator.pop(ctx);
                      await _checklistService.assignItem(item.id, profile.uid);
                      _memberNameCache = null;
                      final items = await _checklistService.getChecklist(widget.trip.id);
                      if (mounted) setState(() => _checklistItems = items);
                    },
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  );
                }),
              ],
            ),
          );
        },
      );
    } catch (e) {
      debugPrint('Error loading members for assignment: $e');
    }
  }

  void _showAddChecklistItemDialog(AppColors colors) {
    final controller = TextEditingController();
    String selectedCategory = 'general';
    final categories = ['general', 'documents', 'packing', 'bookings', 'health', 'money'];

    showDialog(
      context: context,
      builder: (ctx) {
        return StatefulBuilder(builder: (ctx, setDialogState) {
          return AlertDialog(
            backgroundColor: colors.surfaceBg,
            title: Text("Add Checklist Item", style: GoogleFonts.outfit(fontWeight: FontWeight.bold)),
            content: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                TextField(
                  controller: controller,
                  decoration: InputDecoration(
                    hintText: "e.g. Buy sunscreen",
                    filled: true,
                    fillColor: colors.cardBg,
                    border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide(color: colors.border)),
                  ),
                ),
                const SizedBox(height: 12),
                Wrap(
                  spacing: 6,
                  runSpacing: 6,
                  children: categories.map((cat) {
                    final isSelected = selectedCategory == cat;
                    return ChoiceChip(
                      label: Text("${ChecklistItem.categoryIcon(cat)} ${ChecklistItem.categoryLabel(cat)}", style: TextStyle(fontSize: 12)),
                      selected: isSelected,
                      selectedColor: AppColors.brand.withOpacity(0.2),
                      backgroundColor: colors.cardBg,
                      onSelected: (_) => setDialogState(() => selectedCategory = cat),
                    );
                  }).toList(),
                ),
              ],
            ),
            actions: [
              TextButton(onPressed: () => Navigator.pop(ctx), child: const Text("Cancel")),
              ElevatedButton(
                style: ElevatedButton.styleFrom(backgroundColor: AppColors.brand),
                onPressed: () async {
                  final text = controller.text.trim();
                  if (text.isEmpty) return;
                  Navigator.pop(ctx);
                  await _checklistService.addItem(
                    tripId: widget.trip.id,
                    itemText: text,
                    category: selectedCategory,
                  );
                  final items = await _checklistService.getChecklist(widget.trip.id);
                  if (mounted) setState(() => _checklistItems = items);
                },
                child: Text("Add", style: TextStyle(color: Colors.white)),
              ),
            ],
          );
        });
      },
    );
  }

  // ── Emergency Info Card ──
  Widget _buildEmergencyInfoCard(AppColors colors) {
    final hasInternational = _internationalInfo != null;
    final countryCode = _metadata?.destinationCountryCode;
    // Robust lookup: try metadata country code first, then parse from trip location
    var staticNumbers = EmergencyNumbersDB.lookup(countryCode);
    staticNumbers ??= EmergencyNumbersDB.lookupFromLocation(widget.trip.location);
    
    // Fallback chain: AI data → static database → metadata emergency number → '112'
    final policeNumber = hasInternational 
        ? (_internationalInfo!.localPoliceNumber ?? staticNumbers?.police ?? _metadata?.emergencyNumber ?? '112')
        : (staticNumbers?.police ?? _metadata?.emergencyNumber ?? '112');
    final ambulanceNumber = hasInternational 
        ? (_internationalInfo!.localMedicalNumber ?? staticNumbers?.ambulance ?? '112')
        : (staticNumbers?.ambulance ?? _metadata?.emergencyNumber ?? '112');
    final emergencyNumber = hasInternational
        ? (_internationalInfo!.localEmergencyNumber ?? staticNumbers?.generalEmergency ?? staticNumbers?.police ?? _metadata?.emergencyNumber ?? '112')
        : (staticNumbers?.generalEmergency ?? staticNumbers?.police ?? _metadata?.emergencyNumber ?? '112');
    
    return Container(
      decoration: BoxDecoration(
        color: colors.cardBg,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: colors.border),
      ),
      child: Theme(
        data: Theme.of(context).copyWith(dividerColor: Colors.transparent),
        child: ExpansionTile(
          tilePadding: const EdgeInsets.symmetric(horizontal: 16),
          title: Row(
            children: [
              Icon(Icons.emergency, color: Colors.red.shade400, size: 22),
              const SizedBox(width: 10),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text("Emergency Info", style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                    Text(
                      widget.trip.location,
                      style: TextStyle(fontSize: 11, color: colors.textMuted),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ],
                ),
              ),
            ],
          ),
          children: [
            Padding(
              padding: const EdgeInsets.only(left: 8, right: 8, bottom: 12),
              child: Column(
                children: [
                  _emergencyRow(colors, "Emergency", emergencyNumber, Icons.sos),
                  _emergencyRow(colors, "Police", policeNumber, Icons.local_police),
                  _emergencyRow(colors, "Ambulance", ambulanceNumber, Icons.local_hospital),
                  if (hasInternational && _isInternational) ...[
                    Divider(color: colors.border, height: 16),
                    Padding(
                      padding: const EdgeInsets.only(left: 16, bottom: 8),
                      child: Align(
                        alignment: Alignment.centerLeft,
                        child: Text("Embassy & Consulate", style: TextStyle(color: colors.textMuted, fontSize: 12, fontWeight: FontWeight.w600)),
                      ),
                    ),
                    if (_internationalInfo!.embassyEmergencyNumber != null)
                      _emergencyRow(colors, "Embassy Emergency", _internationalInfo!.embassyEmergencyNumber!, Icons.account_balance),
                    if (_internationalInfo!.embassyPhone != null)
                      _emergencyRow(colors, "Embassy Phone", _internationalInfo!.embassyPhone!, Icons.phone),
                  ],
                  if (!_isInternational) ...[
                    Divider(color: colors.border, height: 16),
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
                      child: Row(
                        children: [
                          Icon(Icons.info_outline, size: 14, color: colors.textMuted),
                          const SizedBox(width: 6),
                          Text("Local emergency numbers for your destination",
                              style: TextStyle(color: colors.textMuted, fontSize: 11, fontStyle: FontStyle.italic)),
                        ],
                      ),
                    ),
                  ],
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _emergencyRow(AppColors colors, String label, String number, IconData icon) {
    return ListTile(
      dense: true,
      visualDensity: VisualDensity.compact,
      leading: Icon(icon, size: 20, color: Colors.red.shade300),
      title: Text(label, style: const TextStyle(fontSize: 14)),
      trailing: TextButton.icon(
        style: TextButton.styleFrom(
          padding: const EdgeInsets.symmetric(horizontal: 8),
          minimumSize: Size.zero,
          tapTargetSize: MaterialTapTargetSize.shrinkWrap,
        ),
        icon: Icon(Icons.phone, size: 14, color: Colors.teal.shade400),
        label: Text(number, style: TextStyle(color: Colors.teal.shade400, fontWeight: FontWeight.bold, fontSize: 13)),
        onPressed: () async {
          final uri = Uri.parse('tel:$number');
          if (await canLaunchUrl(uri)) {
            launchUrl(uri);
          }
        },
      ),
    );
  }

  void _showEditAboutDialog(BuildContext context) {
    final colors = context.appColors;
    final controller = TextEditingController(text: widget.trip.about ?? "");
    bool isSaving = false;

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(24))),
      builder: (ctx) {
        return StatefulBuilder(
          builder: (context, setState) {
            return Padding(
              padding: EdgeInsets.only(
                bottom: MediaQuery.of(ctx).viewInsets.bottom,
                left: 24,
                right: 24,
                top: 24,
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Center(
                    child: Container(width: 40, height: 4, decoration: BoxDecoration(color: colors.textMuted, borderRadius: BorderRadius.circular(2))),
                  ),
                  const SizedBox(height: 24),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text("About this Trip", style: GoogleFonts.outfit(fontSize: 22, fontWeight: FontWeight.bold)),
                      if (isSaving)
                        const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(strokeWidth: 2))
                      else
                        TextButton(
                          onPressed: () async {
                            final text = controller.text.trim();
                            setState(() => isSaving = true);
                            try {
                              await TripService().updateTripAbout(widget.trip.id, text);
                              if (ctx.mounted) {
                                Navigator.pop(ctx);
                                widget.onRefresh(); // Trigger UI reload to show new text
                              }
                            } catch (e) {
                              if (ctx.mounted) {
                                ScaffoldMessenger.of(ctx).showSnackBar(SnackBar(content: Text("Failed to save: $e"), backgroundColor: Colors.red));
                              }
                            } finally {
                              if (ctx.mounted) setState(() => isSaving = false);
                            }
                          },
                          child: const Text("Save", style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                        ),
                    ],
                  ),
                  const SizedBox(height: 16),
                  TextField(
                    controller: controller,
                    maxLines: 6,
                    minLines: 3,
                    textCapitalization: TextCapitalization.sentences,
                    decoration: InputDecoration(
                      hintText: "Write a short paragraph about the goals, vibe, or important info for this trip...",
                      hintStyle: TextStyle(color: colors.textMuted),
                      border: OutlineInputBorder(borderRadius: BorderRadius.circular(16), borderSide: BorderSide(color: colors.border)),
                      enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(16), borderSide: BorderSide(color: colors.border)),
                      focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(16), borderSide: BorderSide(color: AppColors.brand)),
                      filled: true,
                      fillColor: colors.fieldFillBg,
                    ),
                  ),
                  const SizedBox(height: 24),
                ],
              ),
            );
          },
        );
      },
    );
  }

  Widget _buildMembersGrid(BuildContext context) {
    final isDark = context.isDark;
    return FutureBuilder<List<UserProfile>>(
      future: TripService().getTripMembersProfiles(widget.trip.memberIds),
        builder: (context, snapshot) {
          if (!snapshot.hasData) return const SizedBox(height: 60, child: Center(child: CircularProgressIndicator()));
          final allProfiles = snapshot.data!;
          
          // Filter: only show members who are actually accepted or the owner
          final profiles = allProfiles.where((p) => 
            widget.trip.memberIds.contains(p.uid) || 
            p.uid == widget.trip.createdBy
          ).toList();

          final showProfiles = profiles.take(5).toList();
          final hasMore = profiles.length > 5;
        
        return Wrap(
          spacing: 12,
          runSpacing: 12,
          children: [
            ...showProfiles.map((p) => GestureDetector(
              onTap: () async {
                // Check if profile is actually accessible (not blocked)
                final fullProfile = await AuthService.instance.getOtherUserProfile(p.uid);
                if (fullProfile == null) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text("Profile not available"), behavior: SnackBarBehavior.floating),
                  );
                } else {
                  Navigator.push(context, MaterialPageRoute(builder: (_) => ProfileScreen(userId: p.uid)));
                }
              },
              child: _MemberChipV2(profile: p)
            )),
            if (hasMore)
              InkWell(
                onTap: () => _showManageMembers(context),
                borderRadius: BorderRadius.circular(15),
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                  decoration: BoxDecoration(
                    color: isDark ? AppColors.brand.withOpacity(0.15) : Colors.blue.shade50,
                    borderRadius: BorderRadius.circular(15),
                  ),
                  child: Text(
                    "+${profiles.length - 5} more",
                    style: GoogleFonts.inter(fontSize: 12, fontWeight: FontWeight.bold, color: isDark ? AppColors.brand : Colors.blue.shade700),
                  ),
                ),
              ),
            // Always show a manage button for the creator/admins if they want to invite more
            if (!hasMore)
              IconButton(
                icon: const Icon(Icons.add_circle_outline, color: AppColors.brand, size: 28),
                onPressed: () => _showManageMembers(context),
              ),
          ],
        );
      },
    );
  }


  void _showPendingRequestDetails(BuildContext context, Map<String, dynamic> req, String uid) {
    final colors = context.appColors;
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(24))),
      builder: (ctx) {
        final name = req['full_name'] as String? ?? 'New User';
        final email = req['email'] as String? ?? 'N/A';
        final phone = req['phone'] as String? ?? 'N/A';
        
        return Padding(
          padding: EdgeInsets.only(bottom: MediaQuery.of(ctx).viewInsets.bottom, left: 24, right: 24, top: 24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Center(
                child: Container(width: 40, height: 4, decoration: BoxDecoration(color: colors.textMuted, borderRadius: BorderRadius.circular(2))),
              ),
              const SizedBox(height: 24),
              FutureBuilder<UserProfile?>(
                future: AuthService.instance.getOtherUserProfile(uid),
                builder: (context, snapshot) {
                  final profile = snapshot.data;
                  final hasAvatar = profile?.avatarUrl != null && profile!.avatarUrl!.isNotEmpty;
                  return Row(
                    children: [
                      CircleAvatar(
                        radius: 28, 
                        backgroundColor: Colors.orange.shade100, 
                        backgroundImage: hasAvatar ? CachedNetworkImageProvider(profile.avatarUrl!) : null,
                        child: hasAvatar ? null : Text(name.isNotEmpty ? name[0].toUpperCase() : "?", style: const TextStyle(fontSize: 24, color: Colors.orange, fontWeight: FontWeight.bold))
                      ),
                      const SizedBox(width: 16),
                      Expanded(child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                        children: [
                          Flexible(child: Text(name, style: GoogleFonts.outfit(fontSize: 22, fontWeight: FontWeight.bold), overflow: TextOverflow.ellipsis)),
                          FutureBuilder<UserProfile?>(
                            future: AuthService.instance.getOtherUserProfile(uid),
                            builder: (context, snapshot) {
                              if (snapshot.data?.role == 'agency') {
                                return const Padding(
                                  padding: EdgeInsets.only(left: 6),
                                  child: Icon(Icons.verified, color: AppColors.brand, size: 18),
                                );
                              }
                              return const SizedBox.shrink();
                            },
                          ),
                        ],
                      ),
                          Text("Pending Request", style: TextStyle(color: Colors.orange.shade700, fontWeight: FontWeight.w500)),
                        ],
                      )),
                    ],
                  );
                }
              ),
              const SizedBox(height: 24),
              _buildInfoRow(Icons.email_outlined, "Email", email),
              const SizedBox(height: 16),
              _buildInfoRow(Icons.phone_outlined, "Phone", phone),
              const SizedBox(height: 32),
              SizedBox(
                width: double.infinity,
                child: OutlinedButton.icon(
                  onPressed: () {
                    Navigator.pop(ctx);
                    Navigator.push(context, MaterialPageRoute(builder: (_) => ProfileScreen(userId: uid)));
                  },
                  icon: const Icon(Icons.person),
                  label: const Text("View User Profile"),
                  style: OutlinedButton.styleFrom(padding: const EdgeInsets.symmetric(vertical: 16), shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12))),
                ),
              ),
              const SizedBox(height: 16),
              Row(
                children: [
                  Expanded(child: ElevatedButton.icon(
                    onPressed: () async {
                      Navigator.pop(ctx);
                      await TripService().rejectMember(widget.trip.id, uid);
                      await widget.onRefresh();
                    },
                    icon: const Icon(Icons.cancel),
                    label: const Text("Decline"),
                    style: ElevatedButton.styleFrom(backgroundColor: Colors.red.shade50, foregroundColor: Colors.red, padding: const EdgeInsets.symmetric(vertical: 16), elevation: 0),
                  )),
                  const SizedBox(width: 12),
                  Expanded(child: ElevatedButton.icon(
                    onPressed: () async {
                      Navigator.pop(ctx);
                      await TripService().acceptMember(widget.trip.id, uid);
                      await widget.onRefresh();
                    },
                    icon: const Icon(Icons.check_circle),
                    label: const Text("Approve"),
                    style: ElevatedButton.styleFrom(backgroundColor: Colors.green, foregroundColor: Colors.white, padding: const EdgeInsets.symmetric(vertical: 16)),
                  )),
                ],
              ),
              const SizedBox(height: 32),
            ],
          ),
        );
      }
    );
  }

  Widget _buildInfoRow(IconData icon, String label, String value) {
    final colors = context.appColors;
    return Row(
      children: [
        Container(padding: const EdgeInsets.all(12), decoration: BoxDecoration(color: colors.surfaceBg, borderRadius: BorderRadius.circular(12)), child: Icon(icon, color: colors.textSecondary, size: 20)),
        const SizedBox(width: 16),
        Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Text(label, style: TextStyle(fontSize: 12, color: colors.textMuted)),
          Text(value, style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 15)),
        ]),
      ],
    );
  }

  Widget _buildPendingRequests(BuildContext context, List<Map<String, dynamic>> requests) {
    final colors = context.appColors;
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.orange.shade50,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: Colors.orange.shade100),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
               const Icon(Icons.person_add, color: Colors.orange, size: 20),
               const SizedBox(width: 12),
               Text(
                 "Join Requests (${requests.length})",
                 style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Colors.orange)
               ),
            ],
          ),
          const SizedBox(height: 16),
          Column(
            children: requests.map((req) {
              final name = req['full_name'] as String? ?? 'New User';
              final uid = req['user_id'] as String;

              return ListTile(
                onTap: () => _showPendingRequestDetails(context, req, uid),
                contentPadding: EdgeInsets.zero,
                leading: FutureBuilder<UserProfile?>(
                  future: AuthService.instance.getOtherUserProfile(uid),
                  builder: (context, snapshot) {
                    final profile = snapshot.data;
                    final hasAvatar = profile?.avatarUrl != null && profile!.avatarUrl!.isNotEmpty;
                    return CircleAvatar(
                      backgroundColor: colors.cardBg,
                      backgroundImage: hasAvatar ? CachedNetworkImageProvider(profile!.avatarUrl!) : null,
                      child: hasAvatar ? null : Text(name.isNotEmpty ? name[0].toUpperCase() : "?", style: const TextStyle(color: Colors.orange)),
                    );
                  }
                ),
                title: Row(
                  children: [
                    Flexible(child: Text(name, style: const TextStyle(fontWeight: FontWeight.w600), overflow: TextOverflow.ellipsis)),
                    FutureBuilder<UserProfile?>(
                      future: AuthService.instance.getOtherUserProfile(uid),
                      builder: (context, snapshot) {
                        if (snapshot.data?.role == 'agency') {
                          return const Padding(
                            padding: EdgeInsets.only(left: 4),
                            child: Icon(Icons.verified, color: AppColors.brand, size: 14),
                          );
                        }
                        return const SizedBox.shrink();
                      },
                    ),
                  ],
                ),
                subtitle: const Text("Tap to view details", style: TextStyle(fontSize: 12)),
                trailing: const Icon(Icons.chevron_right, color: Colors.orange),
              );
            }).toList(),
          ),
        ],
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
      final plan = await PlanService().fetchTripPlan(widget.trip.id);

      if (context.mounted) {
        Navigator.pop(context); // Close Loader

        // 2. Navigate to Chat Screen
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (_) => AIGuideScreen(trip: widget.trip, plan: plan),
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
    final isDark = context.isDark;
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text("The Crew"),
        content: SizedBox(
          width: double.maxFinite,
          child: ListView.builder(
            shrinkWrap: true,
            itemCount: widget.trip.memberIds.length,
            itemBuilder: (ctx, i) {
              final uid = widget.trip.memberIds[i];
              return FutureBuilder(
                 future: Supabase.instance.client.from('profiles').select().eq('id', uid).maybeSingle(),
                 builder: (ctx, snap) {
                   if (!snap.hasData) return const ListTile(title: Text("Loading..."));
                   final name = snap.data!['display_name'] ?? 'User';
                   final avatarUrl = snap.data!['avatar_url'];
                   final role = snap.data!['role'];

                   final currentUid = Supabase.instance.client.auth.currentUser?.id;
                   final iAmAdmin = widget.trip.adminIds.contains(currentUid);
                   final iAmOwner = widget.trip.createdBy == currentUid;
                   
                   final targetIsAdmin = widget.trip.adminIds.contains(uid);
                   final targetIsOwner = widget.trip.createdBy == uid;

                   return ListTile(
                     onTap: () {
                       Navigator.pop(ctx);
                       Navigator.push(context, MaterialPageRoute(builder: (_) => ProfileScreen(userId: uid)));
                     },
                     leading: CircleAvatar(
                       backgroundColor: isDark ? AppColors.brand.withOpacity(0.15) : Colors.blue.shade50,
                       backgroundImage: avatarUrl != null ? CachedNetworkImageProvider(avatarUrl) : null,
                       child: avatarUrl == null ? Text(name[0].toUpperCase()) : null,
                     ),
                     title: Row(
                       children: [
                         Flexible(
                           child: Text(
                             name, 
                             style: const TextStyle(fontWeight: FontWeight.w600),
                             overflow: TextOverflow.ellipsis,
                           ),
                         ),
                         if (role == 'agency') ...[
                           const SizedBox(width: 4),
                           const Icon(Icons.verified, color: AppColors.brand, size: 14),
                         ],
                         if (targetIsOwner || targetIsAdmin) ...[
                           const SizedBox(width: 8),
                           Container(
                             padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                             decoration: BoxDecoration(
                               color: targetIsOwner 
                                 ? (isDark ? Colors.orange.withOpacity(0.15) : Colors.orange.shade50) 
                                 : (isDark ? AppColors.brand.withOpacity(0.15) : Colors.blue.shade50),
                               borderRadius: BorderRadius.circular(4),
                             ),
                             child: Text(
                               targetIsOwner ? "OWNER" : "ADMIN",
                               style: TextStyle(
                                 fontSize: 8, 
                                 fontWeight: FontWeight.bold, 
                                 color: targetIsOwner ? Colors.orange.shade700 : Colors.blue.shade700,
                               ),
                             ),
                           ),
                         ],
                       ],
                     ),
                     trailing: (uid == currentUid || targetIsOwner)
                        ? null // Can't manage self or owner
                        : !(iAmOwner || iAmAdmin)
                            ? null // Members can't manage
                            : PopupMenuButton<String>(
                                icon: const Icon(Icons.more_vert, size: 20),
                                onSelected: (value) async {
                                   Navigator.pop(ctx);
                                   if (value == 'promote') {
                                      await TripService().promoteToAdmin(widget.trip.id, uid);
                                      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text("$name is now an Admin")));
                                   } else if (value == 'demote') {
                                      await TripService().demoteFromAdmin(widget.trip.id, uid);
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
                                         await TripService().removeMember(widget.trip.id, uid);
                                         ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text("$name removed.")));
                                      }
                                   }
                                   await widget.onRefresh();
                                },
                                itemBuilder: (BuildContext context) {
                                   List<PopupMenuEntry<String>> choices = [];
                                   
                                   // OWNER PERMISSIONS
                                   if (iAmOwner) {
                                      if (!targetIsAdmin) {
                                         choices.add(const PopupMenuItem(value: 'promote', child: Text("Make Admin")));
                                      } else {
                                         choices.add(const PopupMenuItem(value: 'demote', child: Text("Remove Admin")));
                                      }
                                      choices.add(const PopupMenuItem(value: 'remove', child: Text("Remove from Trip", style: TextStyle(color: Colors.red))));
                                   } 
                                   // ADMIN PERMISSIONS
                                   else if (iAmAdmin) {
                                      if (!targetIsAdmin) {
                                         choices.add(const PopupMenuItem(value: 'remove', child: Text("Remove from Trip", style: TextStyle(color: Colors.red))));
                                      }
                                      // Admins cannot manage other Admins or Owner
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
          TextButton(onPressed: () => Navigator.pop(ctx), child: const Text("Done"))
        ],
      )
    );
  }
}

class _StatCardV2 extends StatelessWidget {
  final IconData icon;
  final String label;
  final String value;
  final Color color;

  const _StatCardV2({required this.icon, required this.label, required this.value, required this.color});

  @override
  Widget build(BuildContext context) {
    final colors = context.appColors;
    return Expanded(
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 8),
        decoration: BoxDecoration(
          color: colors.cardBg,
          borderRadius: BorderRadius.circular(20),
          boxShadow: [
            BoxShadow(color: colors.shadow, blurRadius: 10, offset: const Offset(0, 4)),
          ],
        ),
        child: Column(
          children: [
            Icon(icon, size: 20, color: color),
            const SizedBox(height: 8),
            Text(value, style: GoogleFonts.inter(fontWeight: FontWeight.bold, fontSize: 13)),
            const SizedBox(height: 2),
            Text(label, style: TextStyle(color: colors.textMuted, fontSize: 10)),
          ],
        ),
      ),
    );
  }
}

class _MemberChipV2 extends StatelessWidget {
  final UserProfile profile;
  const _MemberChipV2({required this.profile});

  @override
  Widget build(BuildContext context) {
    final colors = context.appColors;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        color: colors.cardBg,
        borderRadius: BorderRadius.circular(15),
        boxShadow: [
          BoxShadow(color: colors.shadow, blurRadius: 4, offset: const Offset(0, 2)),
        ],
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          CircleAvatar(
            radius: 12,
            backgroundColor: colors.surfaceBg,
            backgroundImage: profile.avatarUrl != null ? CachedNetworkImageProvider(profile.avatarUrl!) : null,
            child: profile.avatarUrl == null ? Text((profile.displayName ?? " ")[0], style: const TextStyle(fontSize: 10)) : null,
          ),
          const SizedBox(width: 8),
          Text(
            profile.displayName ?? "User",
            style: GoogleFonts.inter(fontSize: 12, fontWeight: FontWeight.w600),
          ),
          if (profile.role == 'agency') ...[
            const SizedBox(width: 4),
            const Icon(Icons.verified, color: AppColors.brand, size: 12),
          ],
        ],
      ),
    );
  }
}

class _HeaderClipper extends CustomClipper<Path> {
  @override
  Path getClip(Size size) {
    Path path = Path();
    path.lineTo(0, size.height - 40);
    path.quadraticBezierTo(size.width / 2, size.height, size.width, size.height - 40);
    path.lineTo(size.width, 0);
    path.close();
    return path;
  }

  @override
  bool shouldReclip(CustomClipper<Path> oldClipper) => false;
}

class _MemberAvatar extends StatelessWidget {
  final UserProfile profile;
  final bool isOwner;
  final bool isAdmin;
  final VoidCallback onTap;

  const _MemberAvatar({
    required this.profile,
    required this.isOwner,
    required this.isAdmin,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final colors = context.appColors;
    return GestureDetector(
      onTap: onTap,
      child: Column(
        children: [
          Stack(
            children: [
              CircleAvatar(
                radius: 28,
                backgroundColor: AppColors.brand.withOpacity(0.3),
                backgroundImage: profile.avatarUrl != null
                    ? CachedNetworkImageProvider(profile.avatarUrl!)
                    : null,
                child: profile.avatarUrl == null
                    ? Text(
                        profile.displayName?.isNotEmpty == true
                            ? profile.displayName![0].toUpperCase()
                            : "?",
                        style: const TextStyle(
                            color: Colors.white, fontWeight: FontWeight.bold),
                      )
                    : null,
              ),
              if (isOwner)
                Positioned(
                  bottom: 0,
                  right: 0,
                  child: Container(
                    padding: const EdgeInsets.all(2),
                    decoration: BoxDecoration(
                      color: colors.cardBg,
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(Icons.workspace_premium,
                        size: 14, color: Colors.orange),
                  ),
                )
              else if (isAdmin)
                Positioned(
                  bottom: 0,
                  right: 0,
                  child: Container(
                    padding: const EdgeInsets.all(2),
                    decoration: BoxDecoration(
                      color: colors.cardBg,
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(Icons.shield,
                        size: 14, color: AppColors.brand),
                  ),
                ),
              if (profile.role == 'agency')
                Positioned(
                  top: 0,
                  right: 0,
                  child: Container(
                    padding: const EdgeInsets.all(2),
                    decoration: BoxDecoration(
                      color: colors.cardBg,
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(Icons.verified,
                        size: 14, color: AppColors.brand),
                  ),
                ),
            ],
          ),
          const SizedBox(height: 8),
          SizedBox(
            width: 70,
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Flexible(
                  child: Text(
                    profile.displayName?.split(' ').first ?? 'User',
                    textAlign: TextAlign.center,
                    style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w500),
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
                if (profile.role == 'agency') ...[
                  const SizedBox(width: 2),
                  const Icon(Icons.verified, color: AppColors.brand, size: 10),
                ]
              ],
            ),
          ),
        ],
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

class _DateTabState extends State<_DateTab> with AutomaticKeepAliveClientMixin {
  @override
  bool get wantKeepAlive => true;

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
    String dateRange = "Dates TBD ⏳";
    String duration = "";
    int days = 0;

    if (widget.trip.startDate != null && widget.trip.endDate != null) {
      dateRange = "${DateFormat('MMM d').format(widget.trip.startDate!)} – ${DateFormat('MMM d, y').format(widget.trip.endDate!)}";
      days = widget.trip.endDate!.difference(widget.trip.startDate!).inDays + 1;
      duration = "$days Days Trip";
    }

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [Colors.blue.shade400, Colors.blue.shade700],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(24),
        boxShadow: [
          BoxShadow(
            color: Colors.blue.withOpacity(0.3),
            blurRadius: 15,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      widget.trip.location,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 22,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Row(
                      children: [
                        const Icon(Icons.calendar_today, size: 14, color: Colors.white70),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Text(
                            dateRange,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: const TextStyle(color: Colors.white70, fontSize: 14),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 16),
              const Icon(Icons.flight_takeoff, color: Colors.white30, size: 40),
            ],
          ),
          const SizedBox(height: 20),
          Row(
            children: [
              if (duration.isNotEmpty)
                _buildTimelineBadge(duration, Icons.timer_outlined),
              const SizedBox(width: 10),
              _buildTimelineBadge("${widget.trip.memberIds.length} Traveler${widget.trip.memberIds.length > 1 ? 's' : ''}", Icons.group_outlined),
            ],
          ),
          // Countdown
          _buildCountdown(),
        ],
      ),
    );
  }

  Widget _buildCountdown() {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    String label;
    IconData icon;

    if (widget.trip.startDate == null) {
      label = "Dates not set yet";
      icon = Icons.calendar_today;
    } else {
      final start = DateTime(widget.trip.startDate!.year, widget.trip.startDate!.month, widget.trip.startDate!.day);
      final end = widget.trip.endDate != null
          ? DateTime(widget.trip.endDate!.year, widget.trip.endDate!.month, widget.trip.endDate!.day)
          : start;

      if (today.isBefore(start)) {
        final daysUntil = start.difference(today).inDays;
        if (daysUntil == 0) { label = "Trip starts today!"; icon = Icons.flight_takeoff; }
        else if (daysUntil == 1) { label = "Trip starts tomorrow!"; icon = Icons.flight_takeoff; }
        else { label = "$daysUntil days to go"; icon = Icons.hourglass_bottom; }
      } else if (!today.isAfter(end)) {
        final dayNumber = today.difference(start).inDays + 1;
        final totalDays = end.difference(start).inDays + 1;
        label = "Day $dayNumber of $totalDays";
        icon = Icons.explore;
      } else {
        label = "Trip Completed";
        icon = Icons.check_circle_outline;
      }
    }

    return Padding(
      padding: const EdgeInsets.only(top: 12),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
        decoration: BoxDecoration(
          color: Colors.white.withOpacity(0.15),
          borderRadius: BorderRadius.circular(12),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, color: Colors.white, size: 16),
            const SizedBox(width: 8),
            Text(label, style: const TextStyle(color: Colors.white, fontSize: 13, fontWeight: FontWeight.w600)),
          ],
        ),
      ),
    );
  }

  Widget _buildTimelineBadge(String text, IconData icon) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.2),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, color: Colors.white, size: 14),
          const SizedBox(width: 6),
          Text(
            text,
            style: const TextStyle(color: Colors.white, fontSize: 12, fontWeight: FontWeight.w600),
          ),
        ],
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

  void _showCalendarModal() {
    final isDark = context.isDark;
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) => StatefulBuilder(
        builder: (context, setModalState) {
          return Container(
            height: MediaQuery.of(context).size.height * 0.8,
            decoration: BoxDecoration(
              color: context.appColors.scaffoldBg,
              borderRadius: const BorderRadius.vertical(top: Radius.circular(28)),
            ),
            padding: const EdgeInsets.all(24),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Text("Select Trip Dates", style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold)),
                    IconButton(onPressed: () => Navigator.pop(ctx), icon: const Icon(Icons.close)),
                  ],
                ),
                const SizedBox(height: 20),
                Expanded(
                  child: SingleChildScrollView(
                    child: TableCalendar(
                      firstDay: DateTime.now().subtract(const Duration(days: 365)),
                      lastDay: DateTime.now().add(const Duration(days: 730)),
                      focusedDay: _focusedDay,
                      calendarFormat: _calendarFormat,
                      rangeSelectionMode: _rangeSelectionMode,
                      rangeStartDay: _rangeStart,
                      rangeEndDay: _rangeEnd,
                      onRangeSelected: (start, end, focusedDay) {
                        setModalState(() {
                          _focusedDay = focusedDay;
                          _rangeStart = start;
                          _rangeEnd = end;
                          _rangeSelectionMode = RangeSelectionMode.toggledOn;
                        });
                        setState(() { // Updates the parent state too
                          _rangeStart = start;
                          _rangeEnd = end;
                        });
                      },
                      headerStyle: const HeaderStyle(formatButtonVisible: false, titleCentered: true),
                      calendarStyle: CalendarStyle(
                        rangeHighlightColor: isDark ? AppColors.brand.withOpacity(0.15) : Colors.blue.shade50,
                        rangeStartDecoration: const BoxDecoration(color: Colors.blue, shape: BoxShape.circle),
                        rangeEndDecoration: const BoxDecoration(color: Colors.blue, shape: BoxShape.circle),
                        todayDecoration: BoxDecoration(color: isDark ? AppColors.brand.withOpacity(0.3) : Colors.blue.shade100, shape: BoxShape.circle),
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: 16),
                SizedBox(
                  width: double.infinity,
                  height: 56,
                  child: ElevatedButton(
                    onPressed: (_rangeStart != null && _rangeEnd != null) ? () {
                      _saveDates();
                      Navigator.pop(ctx);
                    } : null,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.blue,
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                    ),
                    child: _isSaving 
                      ? const CircularProgressIndicator(color: Colors.white) 
                      : const Text("Confirm Dates", style: TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.bold)),
                  ),
                ),
              ],
            ),
          );
        }
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    super.build(context); // Required for AutomaticKeepAliveClientMixin
    final isDark = context.isDark;
    final isAdmin = widget.trip.adminIds.contains(Supabase.instance.client.auth.currentUser?.id);

    return RefreshIndicator(
      onRefresh: widget.onRefresh,
      child: SingleChildScrollView(
        physics: const AlwaysScrollableScrollPhysics(),
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildTripSnapshotCard(context),
            const SizedBox(height: 32),
            
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text("Timeline", style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                if (isAdmin && !widget.trip.isDead)
                  TextButton.icon(
                    onPressed: _showCalendarModal,
                    icon: const Icon(Icons.edit_calendar, size: 18),
                    label: const Text("Edit Dates"),
                  ),
              ],
            ),
            const SizedBox(height: 16),

            if (widget.trip.startDate != null && widget.trip.endDate != null) ...[
              // Horizontal Timeline Visualizer
              SingleChildScrollView(
                scrollDirection: Axis.horizontal,
                child: Row(
                  children: List.generate(
                    widget.trip.endDate!.difference(widget.trip.startDate!).inDays + 1,
                    (index) {
                      final dayDate = widget.trip.startDate!.add(Duration(days: index));
                      final isLast = index == widget.trip.endDate!.difference(widget.trip.startDate!).inDays;
                      
                      return Row(
                        children: [
                          Container(
                            padding: const EdgeInsets.all(12),
                            decoration: BoxDecoration(
                              color: isDark ? AppColors.brand.withOpacity(0.15) : Colors.blue.shade50,
                              borderRadius: BorderRadius.circular(16),
                              border: Border.all(color: isDark ? AppColors.brand.withOpacity(0.3) : Colors.blue.shade100),
                            ),
                            child: Text(
                              "${dayDate.day}",
                              style: const TextStyle(fontWeight: FontWeight.bold, color: Colors.blue),
                            ),
                          ),
                          if (!isLast)
                            Container(width: 20, height: 2, color: isDark ? AppColors.brand.withOpacity(0.3) : Colors.blue.shade100),
                        ],
                      );
                    },
                  ),
                ),
              ),
              const SizedBox(height: 32),
              
              const Text("Day-by-Day View", style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
              const SizedBox(height: 16),
              
              ListView.builder(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                itemCount: widget.trip.endDate!.difference(widget.trip.startDate!).inDays + 1,
                itemBuilder: (context, index) {
                  final dayDate = widget.trip.startDate!.add(Duration(days: index));
                  return Container(
                    margin: const EdgeInsets.only(bottom: 12),
                    decoration: BoxDecoration(
                      color: context.appColors.cardBg,
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(color: context.appColors.border),
                    ),
                    child: ListTile(
                      onTap: () {
                        DefaultTabController.of(context).animateTo(3); // Go to Plan Tab
                      },
                      leading: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
                        decoration: BoxDecoration(
                          color: context.appColors.surfaceBg,
                          borderRadius: BorderRadius.circular(10),
                        ),
                        child: Column(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Text("D${index + 1}", style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 12)),
                          ],
                        ),
                      ),
                      title: Text(DateFormat('EEEE, MMM d').format(dayDate)),
                      trailing: Icon(Icons.chevron_right, size: 18, color: context.appColors.textMuted),
                    ),
                  );
                },
              ),
            ] else
              Center(
                child: Padding(
                  padding: const EdgeInsets.symmetric(vertical: 40),
                  child: Column(
                    children: [
                      Icon(Icons.calendar_month_outlined, size: 64, color: context.appColors.textMuted),
                      const SizedBox(height: 16),
                      Text("No dates set yet", style: TextStyle(color: context.appColors.textSecondary, fontSize: 16, fontWeight: FontWeight.bold)),
                      if (isAdmin && !widget.trip.isDead) ...[
                        const SizedBox(height: 8),
                        Text("Set dates to start planning the timeline.", style: TextStyle(color: context.appColors.textSecondary)),
                        const SizedBox(height: 24),
                        ElevatedButton(
                          onPressed: _showCalendarModal,
                          child: const Text("Select Trip Dates"),
                        ),
                      ],
                    ],
                  ),
                ),
              ),
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

class _BudgetTabState extends State<_BudgetTab> with AutomaticKeepAliveClientMixin {
  @override
  bool get wantKeepAlive => true;

  final ExpenseService _expenseService = ExpenseService();
  List<TripExpense> _expenses = [];
  StreamSubscription? _expensesSub;
  Map<String, UserProfile> _profileCache = {};

  @override
  void initState() {
    super.initState();
    _expensesSub = _expenseService.getExpensesStream(widget.trip.id).listen((expenses) {
      if (mounted) setState(() => _expenses = expenses);
    });
    _loadProfiles();
  }

  Future<void> _loadProfiles() async {
    try {
      final profiles = await TripService().getTripMembersProfiles(widget.trip.memberIds);
      if (mounted) {
        setState(() {
          for (final p in profiles) {
            _profileCache[p.uid] = p;
          }
        });
      }
    } catch (_) {}
  }

  String _memberName(String uid) {
    final p = _profileCache[uid];
    return p?.displayName ?? p?.username ?? uid.substring(0, uid.length.clamp(0, 8));
  }

  @override
  void dispose() {
    _expensesSub?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    super.build(context);
    final colors = context.appColors;
    final currency = widget.trip.budgetCurrency;
    final currentUser = Supabase.instance.client.auth.currentUser?.id;
    final isAdmin = currentUser != null && widget.trip.adminIds.contains(currentUser);

    double totalAllocated = widget.trip.budgetAllocations.fold(0, (prev, e) => prev + (e['cost'] is int ? (e['cost'] as int).toDouble() : (e['cost'] as double? ?? 0.0)));
    double remaining = widget.trip.estimatedCost - totalAllocated;
    double progress = widget.trip.estimatedCost > 0 ? (totalAllocated / widget.trip.estimatedCost).clamp(0.0, 1.0) : 0.0;

    return RefreshIndicator(
      onRefresh: widget.onRefresh,
      child: SingleChildScrollView(
        physics: const AlwaysScrollableScrollPhysics(),
        padding: const EdgeInsets.all(20.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Premium Budget Overview Card
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(24),
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [Colors.teal.shade400, Colors.teal.shade700],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
                borderRadius: BorderRadius.circular(24),
                boxShadow: [
                  BoxShadow(
                    color: Colors.teal.withOpacity(0.3),
                    blurRadius: 15,
                    offset: const Offset(0, 8),
                  ),
                ],
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Text(
                              "Total Budget",
                              style: TextStyle(color: Colors.white70, fontSize: 14),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              "$currency ${widget.trip.estimatedCost.toStringAsFixed(0)}",
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: const TextStyle(
                                color: Colors.white,
                                fontSize: 28,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ],
                        ),
                      ),
                      if (isAdmin && !widget.trip.isDead)
                        IconButton(
                          onPressed: _showEditBudgetDialog,
                          icon: const Icon(Icons.edit_note, color: Colors.white, size: 28),
                          padding: EdgeInsets.zero,
                          constraints: const BoxConstraints(),
                        ),
                    ],
                  ),
                  const SizedBox(height: 24),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        "Spent: $currency ${totalAllocated.toStringAsFixed(0)}",
                        style: const TextStyle(color: Colors.white70, fontSize: 12, fontWeight: FontWeight.w500),
                      ),
                      Text(
                        "Remaining: $currency ${remaining.toStringAsFixed(0)}",
                        style: TextStyle(
                          color: remaining < 0 ? Colors.orange.shade200 : Colors.white70, 
                          fontSize: 12, 
                          fontWeight: FontWeight.w500
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  ClipRRect(
                    borderRadius: BorderRadius.circular(10),
                    child: LinearProgressIndicator(
                      value: progress,
                      backgroundColor: Colors.white.withOpacity(0.2),
                      valueColor: AlwaysStoppedAnimation<Color>(remaining < 0 ? Colors.orange : Colors.white),
                      minHeight: 8,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 32),

            // Category Quick-Add / Filter Chips
            const Text("Categories", style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
            const SizedBox(height: 16),
            SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: Row(
                children: [
                  _buildCategoryChip("🏨 Hotels", Colors.blue),
                  _buildCategoryChip("✈️ Flights", Colors.orange),
                  _buildCategoryChip("🍽 Food", Colors.green),
                  _buildCategoryChip("🚗 Transport", Colors.purple),
                  _buildCategoryChip("🎟 Activities", Colors.pink),
                ],
              ),
            ),
            const SizedBox(height: 32),

            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text("Breakdown", style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                if (isAdmin && widget.trip.budgetAllocations.isNotEmpty && !widget.trip.isDead)
                  TextButton.icon(
                    onPressed: _showEditBudgetDialog,
                    icon: const Icon(Icons.add, size: 18),
                    label: const Text("Manage"),
                  ),
              ],
            ),
            const SizedBox(height: 16),

            if (widget.trip.budgetAllocations.isEmpty)
              Center(
                child: Padding(
                  padding: const EdgeInsets.symmetric(vertical: 40),
                  child: Column(
                    children: [
                      Icon(Icons.account_balance_wallet_outlined, size: 64, color: colors.textMuted),
                      const SizedBox(height: 16),
                      Text(
                        "Track your travel expenses smartly ✈️",
                        textAlign: TextAlign.center,
                        style: TextStyle(color: colors.textSecondary, fontSize: 16, fontWeight: FontWeight.bold),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        "Add hotels, flights, food & activities.",
                        textAlign: TextAlign.center,
                        style: TextStyle(color: colors.textSecondary),
                      ),
                      if (isAdmin) ...[
                        const SizedBox(height: 24),
                        ElevatedButton(
                          onPressed: _showEditBudgetDialog,
                          child: const Text("Start Tracking"),
                        ),
                      ],
                    ],
                  ),
                ),
              )
            else
              ListView.separated(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                itemCount: widget.trip.budgetAllocations.length,
                separatorBuilder: (ctx, i) => const SizedBox(height: 12),
                itemBuilder: (ctx, i) {
                   final item = widget.trip.budgetAllocations[i];
                   final cost = item['cost'] is int ? (item['cost'] as int).toDouble() : (item['cost'] as double? ?? 0.0);
                   return Container(
                     decoration: BoxDecoration(
                        color: colors.cardBg,
                        borderRadius: BorderRadius.circular(16),
                        border: Border.all(color: colors.border),
                     ),
                     child: ListTile(
                       contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
                       leading: Container(
                          padding: const EdgeInsets.all(10),
                          decoration: BoxDecoration(
                             color: Colors.teal.shade50,
                             shape: BoxShape.circle,
                          ),
                          child: const Icon(Icons.receipt_long_outlined, color: Colors.teal, size: 20),
                       ),
                       title: Text(item['title'] ?? 'Item', style: const TextStyle(fontWeight: FontWeight.bold)),
                       subtitle: Text("Allocation", style: TextStyle(color: colors.textMuted, fontSize: 12)),
                       trailing: Text(
                         "$currency ${cost.toStringAsFixed(0)}", 
                         style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16, color: Colors.teal)
                       ),
                     ),
                   );
                }
              ),

            // ── Expense Analytics Section ──
            if (_expenses.isNotEmpty) ...[
              const SizedBox(height: 32),
              const Text("Spending by Category", style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
              const SizedBox(height: 16),
              _buildExpensePieChart(colors, currency),
              const SizedBox(height: 32),
              _buildBurnRate(colors, currency),
              const SizedBox(height: 32),
              const Text("Spending by Member", style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
              const SizedBox(height: 16),
              _buildPerMemberSpending(colors, currency),
            ],
          ],
        ),
      ),
    );
  }

  // ── Expense Pie Chart ──
  Widget _buildExpensePieChart(AppColors colors, String currency) {
    final Map<String, double> categoryTotals = {};
    for (final expense in _expenses) {
      categoryTotals[expense.category] = (categoryTotals[expense.category] ?? 0) + expense.amount;
    }
    if (categoryTotals.isEmpty) return const SizedBox.shrink();

    final categoryColors = <String, Color>{
      'food': Colors.green,
      'transport': Colors.blue,
      'accommodation': Colors.orange,
      'activity': Colors.purple,
      'shopping': Colors.pink,
      'general': Colors.teal,
    };

    final total = categoryTotals.values.fold(0.0, (a, b) => a + b);
    final sections = categoryTotals.entries.map((entry) {
      final pct = total > 0 ? (entry.value / total * 100) : 0.0;
      final color = categoryColors[entry.key] ?? Colors.grey;
      return PieChartSectionData(
        value: entry.value,
        title: '${pct.toStringAsFixed(0)}%',
        color: color,
        radius: 60,
        titleStyle: const TextStyle(color: Colors.white, fontSize: 12, fontWeight: FontWeight.bold),
      );
    }).toList();

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: colors.cardBg,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: colors.border),
      ),
      child: Column(
        children: [
          SizedBox(
            height: 200,
            child: PieChart(
              PieChartData(
                sections: sections,
                centerSpaceRadius: 40,
                sectionsSpace: 2,
              ),
            ),
          ),
          const SizedBox(height: 16),
          Wrap(
            spacing: 16,
            runSpacing: 8,
            children: categoryTotals.entries.map((entry) {
              final color = categoryColors[entry.key] ?? Colors.grey;
              return Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Container(width: 12, height: 12, decoration: BoxDecoration(color: color, shape: BoxShape.circle)),
                  const SizedBox(width: 6),
                  Text(
                    '${TripExpense.categoryEmoji(entry.key)} ${entry.key[0].toUpperCase()}${entry.key.substring(1)}',
                    style: TextStyle(fontSize: 12, color: colors.textSecondary),
                  ),
                  const SizedBox(width: 4),
                  Text(
                    '$currency ${entry.value.toStringAsFixed(0)}',
                    style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold),
                  ),
                ],
              );
            }).toList(),
          ),
        ],
      ),
    );
  }

  // ── Budget Burn Rate ──
  Widget _buildBurnRate(AppColors colors, String currency) {
    final totalSpent = _expenses.fold(0.0, (sum, e) => sum + e.amount);
    final totalBudget = widget.trip.estimatedCost;
    final burnProgress = totalBudget > 0 ? (totalSpent / totalBudget).clamp(0.0, 1.0) : 0.0;
    final isOverBudget = totalSpent > totalBudget;

    final tripStart = widget.trip.startDate;
    final now = DateTime.now();
    final daysElapsed = (tripStart != null ? now.difference(tripStart).inDays : 1).clamp(1, 9999);
    final dailyBurnRate = totalSpent / daysElapsed;

    final tripEnd = widget.trip.endDate;
    final totalDays = (tripStart != null && tripEnd != null)
        ? tripEnd.difference(tripStart).inDays.clamp(1, 9999)
        : null;
    final projectedTotal = totalDays != null ? dailyBurnRate * totalDays : null;

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: colors.cardBg,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: colors.border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(
                isOverBudget ? Icons.warning_amber_rounded : Icons.trending_up,
                color: isOverBudget ? Colors.red : Colors.teal,
                size: 20,
              ),
              const SizedBox(width: 8),
              const Text("Budget Burn Rate", style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
            ],
          ),
          const SizedBox(height: 16),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text("Actual Spending", style: TextStyle(color: colors.textSecondary, fontSize: 13)),
              Text(
                "$currency ${totalSpent.toStringAsFixed(0)} / $currency ${totalBudget.toStringAsFixed(0)}",
                style: TextStyle(fontWeight: FontWeight.bold, color: isOverBudget ? Colors.red : null),
              ),
            ],
          ),
          const SizedBox(height: 8),
          ClipRRect(
            borderRadius: BorderRadius.circular(8),
            child: LinearProgressIndicator(
              value: burnProgress,
              backgroundColor: colors.border,
              valueColor: AlwaysStoppedAnimation<Color>(isOverBudget ? Colors.red : Colors.teal),
              minHeight: 10,
            ),
          ),
          const SizedBox(height: 12),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                "Daily avg: $currency ${dailyBurnRate.toStringAsFixed(0)}/day",
                style: TextStyle(color: colors.textMuted, fontSize: 12),
              ),
              if (projectedTotal != null)
                Text(
                  "Projected: $currency ${projectedTotal.toStringAsFixed(0)}",
                  style: TextStyle(
                    color: projectedTotal > totalBudget ? Colors.red.shade300 : Colors.green.shade300,
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                  ),
                ),
            ],
          ),
        ],
      ),
    );
  }

  // ── Per-Member Spending ──
  Widget _buildPerMemberSpending(AppColors colors, String currency) {
    final Map<String, double> memberSpending = {};
    double totalSpent = 0;
    for (final expense in _expenses) {
      memberSpending[expense.paidBy] = (memberSpending[expense.paidBy] ?? 0) + expense.amount;
      totalSpent += expense.amount;
    }
    if (memberSpending.isEmpty) return const SizedBox.shrink();

    final sorted = memberSpending.entries.toList()
      ..sort((a, b) => b.value.compareTo(a.value));

    return Column(
      children: sorted.map((entry) {
        final percentage = totalSpent > 0 ? entry.value / totalSpent : 0.0;
        final name = _memberName(entry.key);
        return Padding(
          padding: const EdgeInsets.only(bottom: 12),
          child: Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: colors.cardBg,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: colors.border),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(name, style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 13)),
                    Text("$currency ${entry.value.toStringAsFixed(0)}", style: const TextStyle(fontWeight: FontWeight.bold)),
                  ],
                ),
                const SizedBox(height: 8),
                ClipRRect(
                  borderRadius: BorderRadius.circular(4),
                  child: LinearProgressIndicator(
                    value: percentage,
                    backgroundColor: colors.border,
                    valueColor: AlwaysStoppedAnimation<Color>(Colors.teal.withOpacity(0.7)),
                    minHeight: 6,
                  ),
                ),
              ],
            ),
          ),
        );
      }).toList(),
    );
  }

  Widget _buildCategoryChip(String label, Color color) {
    return Container(
      margin: const EdgeInsets.only(right: 12),
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
      decoration: BoxDecoration(
        color: color.withOpacity(0.08),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: color.withOpacity(0.2)),
      ),
      child: Text(
        label,
        style: TextStyle(color: color, fontWeight: FontWeight.bold, fontSize: 13),
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
                          border: Border.all(color: context.appColors.border),
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
                            border: Border.all(color: context.isDark ? AppColors.brand.withOpacity(0.3) : Colors.blue),
                            borderRadius: BorderRadius.circular(8),
                            color: context.isDark ? AppColors.brand.withOpacity(0.15) : Colors.blue.shade50
                          ),
                          child: Center(child: Text("+ Add New Item", style: TextStyle(color: context.isDark ? AppColors.brand : Colors.blue, fontWeight: FontWeight.bold))),
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

class _PollsTabState extends State<_PollsTab> with TickerProviderStateMixin, AutomaticKeepAliveClientMixin {
  late Stream<List<TripPoll>> _pollsStream;

  @override
  bool get wantKeepAlive => true;

  @override
  void initState() {
    super.initState();
    _pollsStream = TripService().getPollsStream(widget.trip.id);
  }

  void _showCreatePollBottomSheet() {
    final cQuestion = TextEditingController();
    final List<TextEditingController> cOptions = [
      TextEditingController(),
      TextEditingController()
    ];
    
    DateTime? endsAt;
    bool isAnonymous = false;
    bool allowMultiple = false;
    bool isPinned = false;
    bool showAdvanced = false;

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) => StatefulBuilder(
        builder: (context, setModalState) {
          return Container(
            height: MediaQuery.of(context).size.height * 0.85,
            decoration: BoxDecoration(
              color: context.appColors.scaffoldBg,
              borderRadius: const BorderRadius.vertical(top: Radius.circular(28)),
            ),
            padding: EdgeInsets.only(
              bottom: MediaQuery.of(context).viewInsets.bottom,
              top: 20,
              left: 20,
              right: 20,
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Center(child: Container(width: 40, height: 4, decoration: BoxDecoration(color: context.appColors.textMuted, borderRadius: BorderRadius.circular(2)))),
                const SizedBox(height: 24),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text("Create Poll", style: GoogleFonts.outfit(fontSize: 24, fontWeight: FontWeight.bold)),
                    IconButton(onPressed: () => Navigator.pop(ctx), icon: const Icon(Icons.close)),
                  ],
                ),
                const SizedBox(height: 20),
                Expanded(
                  child: SingleChildScrollView(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        TextField(
                          controller: cQuestion,
                          autofocus: true,
                          style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w500),
                          decoration: const InputDecoration(
                            hintText: "What are we deciding?",
                            border: InputBorder.none,
                          ),
                          maxLines: 2,
                        ),
                        const Divider(),
                        const SizedBox(height: 16),
                        ...cOptions.asMap().entries.map((entry) {
                          final index = entry.key;
                          final controller = entry.value;
                          return Padding(
                            padding: const EdgeInsets.only(bottom: 12),
                            child: Row(
                              children: [
                                Expanded(
                                  child: Container(
                                    padding: const EdgeInsets.symmetric(horizontal: 16),
                                    decoration: BoxDecoration(
                                      color: context.appColors.surfaceBg,
                                      borderRadius: BorderRadius.circular(12),
                                    ),
                                    child: TextField(
                                      controller: controller,
                                      onSubmitted: (_) {
                                        if (index == cOptions.length - 1) {
                                          setModalState(() => cOptions.add(TextEditingController()));
                                        }
                                      },
                                      decoration: InputDecoration(
                                        hintText: "Option ${index + 1}",
                                        border: InputBorder.none,
                                      ),
                                    ),
                                  ),
                                ),
                                if (cOptions.length > 2)
                                  IconButton(
                                    icon: const Icon(Icons.remove_circle_outline, color: Colors.redAccent),
                                    onPressed: () => setModalState(() => cOptions.removeAt(index)),
                                  )
                              ],
                            ),
                          );
                        }),
                        TextButton.icon(
                          onPressed: () => setModalState(() => cOptions.add(TextEditingController())),
                          icon: const Icon(Icons.add),
                          label: const Text("Add Option"),
                        ),
                        const SizedBox(height: 24),
                        InkWell(
                          onTap: () => setModalState(() => showAdvanced = !showAdvanced),
                          child: Row(
                            children: [
                              Text("Advanced Settings", style: TextStyle(color: context.appColors.textSecondary, fontWeight: FontWeight.bold)),
                              const SizedBox(width: 4),
                              Icon(showAdvanced ? Icons.keyboard_arrow_up : Icons.keyboard_arrow_down, size: 20, color: context.appColors.textSecondary),
                            ],
                          ),
                        ),
                        if (showAdvanced) ...[
                          const SizedBox(height: 16),
                          _buildToggleOption(
                            Icons.timer_outlined, "End Time", 
                            endsAt == null ? "None" : DateFormat('MMM d, HH:mm').format(endsAt!),
                            onTap: () async {
                              final date = await showDatePicker(
                                context: context,
                                initialDate: DateTime.now().add(const Duration(hours: 2)),
                                firstDate: DateTime.now(),
                                lastDate: DateTime.now().add(const Duration(days: 30)),
                              );
                              if (date != null) {
                                final time = await showTimePicker(context: context, initialTime: TimeOfDay.now());
                                if (time != null) {
                                  setModalState(() => endsAt = DateTime(date.year, date.month, date.day, time.hour, time.minute));
                                }
                              }
                            }
                          ),
                          _buildSwitchOption(Icons.person_off_outlined, "Anonymous voting", isAnonymous, (v) => setModalState(() => isAnonymous = v)),
                          _buildSwitchOption(Icons.checklist_rtl, "Allow multiple votes", allowMultiple, (v) => setModalState(() => allowMultiple = v)),
                          _buildSwitchOption(Icons.push_pin_outlined, "Pin poll", isPinned, (v) => setModalState(() => isPinned = v)),
                        ],
                      ],
                    ),
                  ),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(vertical: 20),
                  width: double.infinity,
                  child: ElevatedButton(
                    onPressed: () async {
                      if (cQuestion.text.isEmpty) return;
                      final options = cOptions.map((c) => c.text.trim()).where((t) => t.isNotEmpty).toList();
                      if (options.length < 2) return;

                      try {
                        await TripService().createPollRelational(
                          tripId: widget.trip.id,
                          question: cQuestion.text.trim(),
                          options: options,
                          endsAt: endsAt,
                          isAnonymous: isAnonymous,
                          allowMultiple: allowMultiple,
                          isPinned: isPinned,
                        );
                        if (mounted) {
                          Navigator.pop(ctx);
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(
                              content: Text("Poll created successfully! 🗳️"),
                              backgroundColor: Colors.green,
                            ),
                          );
                        }
                      } catch (e) {
                         ScaffoldMessenger.of(context).showSnackBar(
                           SnackBar(
                             content: Text("Error: $e"),
                             backgroundColor: Colors.redAccent,
                           )
                         );
                      }
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.brand,
                      padding: const EdgeInsets.symmetric(vertical: 16),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                    ),
                    child: const Text("Create Poll", style: TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.bold)),
                  ),
                ),
              ],
            ),
          );
        }
      )
    );
  }

  Widget _buildToggleOption(IconData icon, String title, String value, {required VoidCallback onTap}) {
    return ListTile(
      leading: Icon(icon, size: 20),
      title: Text(title, style: const TextStyle(fontSize: 14)),
      trailing: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(value, style: const TextStyle(color: Colors.blue, fontWeight: FontWeight.bold)),
          const Icon(Icons.chevron_right, size: 16, color: Colors.blue),
        ],
      ),
      onTap: onTap,
    );
  }

  Widget _buildSwitchOption(IconData icon, String title, bool value, Function(bool) onChanged) {
    return SwitchListTile(
      secondary: Icon(icon, size: 20),
      title: Text(title, style: const TextStyle(fontSize: 14)),
      value: value,
      onChanged: onChanged,
    );
  }

  @override
  Widget build(BuildContext context) {
    super.build(context);
    final uid = Supabase.instance.client.auth.currentUser?.id;
    final isOwner = widget.trip.createdBy == uid;
    final isAdmin = widget.trip.adminIds.contains(uid);
    final canCreatePoll = isOwner || isAdmin;

    return Scaffold(
      floatingActionButton: (widget.trip.isDead || !canCreatePoll) ? null : FloatingActionButton.extended(
        onPressed: _showCreatePollBottomSheet,
        icon: const Icon(Icons.add),
        label: const Text("New Poll"),
        backgroundColor: AppColors.brand,
        foregroundColor: Colors.white,
      ),
      body: StreamBuilder<List<TripPoll>>(
        stream: _pollsStream,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting && !snapshot.hasData) {
             return const Center(child: CircularProgressIndicator());
          }
          final polls = snapshot.data ?? [];

          if (polls.isEmpty) {
            return RefreshIndicator(
              onRefresh: () async => widget.onRefresh(),
              child: ListView(
                children: [
                  SizedBox(height: MediaQuery.of(context).size.height * 0.2),
                  Center(
                    child: Column(
                      children: [
                        Container(
                          padding: const EdgeInsets.all(24),
                          decoration: BoxDecoration(color: context.isDark ? AppColors.brand.withOpacity(0.15) : Colors.blue.shade50, shape: BoxShape.circle),
                          child: const Icon(Icons.how_to_vote_outlined, size: 48, color: AppColors.brand),
                        ),
                        const SizedBox(height: 24),
                        Text("No active polls", style: GoogleFonts.outfit(fontSize: 20, fontWeight: FontWeight.bold)),
                        const SizedBox(height: 8),
                        Text("Decision making made easy.", style: TextStyle(color: context.appColors.textSecondary)),
                        if (!canCreatePoll) ...[
                          const SizedBox(height: 12),
                          Text("Only trip admins can create polls.", style: TextStyle(color: context.appColors.textMuted, fontSize: 12)),
                        ],
                      ],
                    ),
                  ),
                ],
              ),
            );
          }

          return RefreshIndicator(
            onRefresh: () async => widget.onRefresh(),
            child: ListView.builder(
              padding: const EdgeInsets.all(16),
              itemCount: polls.length,
              itemBuilder: (context, index) => _RelationalPollCard(
                poll: polls[index],
                isAdmin: isAdmin,
                isDead: widget.trip.isDead,
              ),
            ),
          );
        },
      ),
    );
  }
}

class _RelationalPollCard extends StatefulWidget {
  final TripPoll poll;
  final bool isAdmin;
  final bool isDead;

  const _RelationalPollCard({required this.poll, required this.isAdmin, this.isDead = false});

  @override
  State<_RelationalPollCard> createState() => _RelationalPollCardState();
}

class _RelationalPollCardState extends State<_RelationalPollCard> {
  @override
  Widget build(BuildContext context) {
    final colors = context.appColors;
    final isDark = context.isDark;
    final totalVotes = widget.poll.votes.length;
    final uid = Supabase.instance.client.auth.currentUser!.id;
    final myVoteOptionIds = widget.poll.votes.where((v) => v.userId == uid).map((v) => v.optionId).toList();
    final isExpired = widget.poll.isExpired;

    return Card(
      elevation: 0,
      margin: const EdgeInsets.only(bottom: 16),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(20),
        side: BorderSide(color: colors.border),
      ),
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                FutureBuilder<UserProfile?>(
                  future: AuthService.instance.getOtherUserProfile(widget.poll.createdBy),
                  builder: (context, snap) {
                    final profile = snap.data;
                    return CircleAvatar(
                      radius: 12,
                      backgroundImage: profile?.avatarUrl != null ? CachedNetworkImageProvider(profile!.avatarUrl!) : null,
                      child: profile?.avatarUrl == null ? const Icon(Icons.person, size: 12) : null,
                    );
                  },
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: FutureBuilder<UserProfile?>(
                    future: AuthService.instance.getOtherUserProfile(widget.poll.createdBy),
                    builder: (context, snap) {
                      final name = snap.data?.displayName ?? "Someone";
                      return Text("$name created a poll", style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: colors.textSecondary));
                    },
                  ),
                ),
                if (widget.poll.isPinned) const Icon(Icons.push_pin, size: 14, color: AppColors.brand),
                if (widget.isAdmin)
                   IconButton(
                     visualDensity: VisualDensity.compact,
                     icon: const Icon(Icons.more_horiz, size: 20),
                     onPressed: () {
                       _showPollOptions(context);
                     },
                   )
              ],
            ),
            const SizedBox(height: 12),
            Text(widget.poll.question, style: GoogleFonts.outfit(fontSize: 18, fontWeight: FontWeight.bold)),
            const SizedBox(height: 8),
            Row(
              children: [
                Icon(Icons.how_to_vote, size: 14, color: Colors.blue.shade300),
                const SizedBox(width: 6),
                Text("$totalVotes votes", style: TextStyle(fontSize: 12, color: Colors.blue.shade300, fontWeight: FontWeight.bold)),
                if (widget.poll.endsAt != null) ...[
                  const SizedBox(width: 12),
                  Icon(Icons.timer_outlined, size: 14, color: isExpired ? Colors.red : colors.textMuted),
                  const SizedBox(width: 4),
                  Text(
                    isExpired ? "Ended" : "Ends in ${_getTimeRemaining()}", 
                    style: TextStyle(fontSize: 12, color: isExpired ? Colors.red : colors.textMuted)
                  ),
                ]
              ],
            ),
            const SizedBox(height: 20),
            ...widget.poll.options.map((option) {
              final voteCount = widget.poll.votes.where((v) => v.optionId == option.id).length;
              final percent = totalVotes > 0 ? voteCount / totalVotes : 0.0;
              final isSelected = myVoteOptionIds.contains(option.id);

              return GestureDetector(
                onTap: (isExpired || widget.isDead) ? null : () => _handleVote(option.id),
                child: Container(
                  margin: const EdgeInsets.only(bottom: 12),
                  height: 52,
                  width: double.infinity,
                  child: Stack(
                    children: [
                      // Animated Bar Background
                      AnimatedContainer(
                        duration: const Duration(milliseconds: 500),
                        curve: Curves.easeOutCubic,
                        width: MediaQuery.of(context).size.width * percent,
                        decoration: BoxDecoration(
                          color: isSelected 
                            ? (isDark ? AppColors.brand.withOpacity(0.3) : Colors.blue.shade100) 
                            : colors.surfaceBg,
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                      // Content
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 16),
                        decoration: BoxDecoration(
                          border: Border.all(color: isSelected ? AppColors.brand.withOpacity(0.5) : Colors.transparent),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Expanded(
                              child: Text(
                                option.optionText, 
                                style: TextStyle(
                                  fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                                  color: isSelected ? Colors.blue.shade800 : colors.textPrimary,
                                )
                              )
                            ),
                            Text("${(percent * 100).toInt()}%", style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13)),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              );
            }).toList(),
            const SizedBox(height: 8),
            _buildVoterAvatars(),
          ],
        ),
      ),
    );
  }

  String _getTimeRemaining() {
    if (widget.poll.endsAt == null) return "";
    final diff = widget.poll.endsAt!.difference(DateTime.now());
    if (diff.isNegative) return "0m";
    if (diff.inDays > 0) return "${diff.inDays}d";
    if (diff.inHours > 0) return "${diff.inHours}h";
    return "${diff.inMinutes}m";
  }

  Widget _buildVoterAvatars() {
    final colors = context.appColors;
    if (widget.poll.votes.isEmpty) return const SizedBox();
    
    // Get unique voter IDs, up to 3 for display
    final voterIds = widget.poll.votes.map((v) => v.userId).toSet().toList();
    final displayIds = voterIds.take(3).toList();
    final othersCount = voterIds.length - displayIds.length;

    return Row(
      children: [
        SizedBox(
          width: 24.0 * displayIds.length + (othersCount > 0 ? 30 : 0),
          height: 24,
          child: Stack(
            children: [
              ...displayIds.asMap().entries.map((entry) {
                final idx = entry.key;
                final uid = entry.value;
                return Positioned(
                  left: idx * 16.0,
                  child: FutureBuilder<UserProfile?>(
                    future: AuthService.instance.getOtherUserProfile(uid),
                    builder: (context, snap) {
                      final profile = snap.data;
                      return Container(
                        padding: const EdgeInsets.all(1.5),
                        decoration: BoxDecoration(color: colors.cardBg, shape: BoxShape.circle),
                        child: CircleAvatar(
                          radius: 10,
                          backgroundImage: profile?.avatarUrl != null ? CachedNetworkImageProvider(profile!.avatarUrl!) : null,
                          child: profile?.avatarUrl == null ? const Icon(Icons.person, size: 10) : null,
                        ),
                      );
                    },
                  ),
                );
              }),
              if (othersCount > 0)
                Positioned(
                  left: displayIds.length * 16.0,
                  child: Container(
                    padding: const EdgeInsets.all(1.5),
                    decoration: BoxDecoration(color: colors.cardBg, shape: BoxShape.circle),
                    child: CircleAvatar(
                      radius: 10,
                      backgroundColor: colors.surfaceBg,
                      child: Text("+$othersCount", style: TextStyle(fontSize: 8, color: colors.textSecondary, fontWeight: FontWeight.bold)),
                    ),
                  ),
                ),
            ],
          ),
        ),
        const SizedBox(width: 8),
        Text(
          "Voted: ${voterIds.length} members", 
          style: TextStyle(fontSize: 10, color: colors.textSecondary, fontWeight: FontWeight.w500)
        ),
      ],
    );
  }

  void _handleVote(String optionId) async {
    HapticFeedback.lightImpact(); // Add haptic feedback
    try {
      await TripService().votePollRelational(
        pollId: widget.poll.id,
        optionId: optionId,
        allowMultiple: widget.poll.allowMultiple,
      );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text("Failed to vote: $e")));
    }
  }

  void _showPollOptions(BuildContext context) {
    showModalBottomSheet(
      context: context,
      builder: (ctx) => Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const SizedBox(height: 8),
          ListTile(
            leading: const Icon(Icons.delete_outline, color: Colors.red),
            title: const Text("Delete Poll", style: TextStyle(color: Colors.red)),
            onTap: () async {
              Navigator.pop(ctx);
              final confirm = await showDialog<bool>(
                context: context,
                builder: (d) => AlertDialog(
                  title: const Text("Delete Poll"),
                  content: const Text("This cannot be undone."),
                  actions: [
                    TextButton(onPressed: () => Navigator.pop(d, false), child: const Text("Cancel")),
                    TextButton(onPressed: () => Navigator.pop(d, true), child: const Text("Delete", style: TextStyle(color: Colors.red))),
                  ],
                ),
              );
              if (confirm == true) {
                try {
                  await TripService().deletePollRelational(widget.poll.id);
                  if (context.mounted) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(content: Text("Poll deleted successfully! 🗑️"), backgroundColor: Colors.blueAccent)
                    );
                  }
                } catch (e) {
                  if (context.mounted) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(content: Text("Delete failed: $e"), backgroundColor: Colors.redAccent)
                    );
                  }
                }
              }
            },
          ),
          const SizedBox(height: 20),
        ],
      ),
    );
  }
} // End _RelationalPollCardState

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

class _GalleryTabState extends State<_GalleryTab> with AutomaticKeepAliveClientMixin {
  @override
  bool get wantKeepAlive => true;

  final ImagePicker _picker = ImagePicker();
  bool _isUploading = false;
  int _uploadingCount = 0;
  int _totalToUpload = 0;
  late Stream<List<Map<String, dynamic>>> _photosStream;

  // Multi-select state
  bool _isSelectionMode = false;
  final Set<String> _selectedPhotoIds = {};

  @override
  void initState() {
    super.initState();
    _photosStream = TripService().getPhotosStream(widget.trip.id);
  }

  void _toggleSelection(String photoId) {
    setState(() {
      if (_selectedPhotoIds.contains(photoId)) {
        _selectedPhotoIds.remove(photoId);
        if (_selectedPhotoIds.isEmpty) _isSelectionMode = false;
      } else {
        _selectedPhotoIds.add(photoId);
        _isSelectionMode = true;
      }
    });
  }

  void _enterSelectionMode(String photoId) {
    HapticFeedback.heavyImpact();
    setState(() {
      _isSelectionMode = true;
      _selectedPhotoIds.add(photoId);
    });
  }

  Future<void> _deleteSelectedPhotos(List<Map<String, dynamic>> allPhotos) async {
    final toDelete = allPhotos.where((p) => _selectedPhotoIds.contains(p['id'])).toList();
    if (toDelete.isEmpty) return;

    final confirm = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text("Delete ${toDelete.length} Memories?"),
        content: const Text("This will permanently remove these photos from the trip."),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text("Cancel")),
          TextButton(
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text("Delete", style: TextStyle(color: Colors.red, fontWeight: FontWeight.bold)),
          ),
        ],
      ),
    );

    if (confirm == true) {
      try {
        await TripService().deletePhotosBatch(widget.trip.id, toDelete);
        setState(() {
          _isSelectionMode = false;
          _selectedPhotoIds.clear();
        });
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("Memories deleted! 🗑️")));
      } catch (e) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text("Error: $e")));
      }
    }
  }

  Future<void> _pickAndUploadPhotos() async {
    try {
      final List<XFile> images = await _picker.pickMultiImage(imageQuality: 70);
      if (images.isEmpty) return;

      setState(() {
        _isUploading = true;
        _totalToUpload = images.length;
        _uploadingCount = 0;
      });

      await TripService().uploadPhotos(
        widget.trip.id, 
        images,
        onProgress: (completed, total) {
          setState(() {
            _uploadingCount = completed;
          });
        }
      );

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text("Successfully uploaded ${images.length} memories! 📸")));
      }
    } catch (e) {
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text("Upload failed: $e")));
    } finally {
      if (mounted) setState(() => _isUploading = false);
    }
  }

  Map<String, List<Map<String, dynamic>>> _groupPhotosByDay(List<Map<String, dynamic>> photos) {
    final Map<String, List<Map<String, dynamic>>> groups = {};
    for (var photo in photos) {
      final date = photo['created_at'] != null 
          ? DateTime.parse(photo['created_at']).toLocal() 
          : DateTime.now();
      final dateKey = DateFormat('MMM d, y').format(date);
      groups.putIfAbsent(dateKey, () => []).add(photo);
    }
    return groups;
  }

  @override
  Widget build(BuildContext context) {
    super.build(context);
    return Scaffold(
      floatingActionButton: (_isSelectionMode || widget.trip.isDead)
          ? null 
          : FloatingActionButton.extended(
              onPressed: _isUploading ? null : _pickAndUploadPhotos,
              backgroundColor: AppColors.brand,
              icon: _isUploading 
                  ? const SizedBox(width: 24, height: 24, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2)) 
                  : const Icon(Icons.add_a_photo),
              label: Text(_isUploading ? "Uploading $_uploadingCount/$_totalToUpload..." : "Add Photos"),
            ),
      body: StreamBuilder<List<Map<String, dynamic>>>(
        stream: _photosStream,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting && !snapshot.hasData) {
            return const Center(child: CircularProgressIndicator());
          }
          final photos = snapshot.data ?? [];
          if (photos.isEmpty && !_isUploading) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Container(
                    padding: const EdgeInsets.all(24),
                    decoration: BoxDecoration(color: Colors.orange.shade50, shape: BoxShape.circle),
                    child: const Icon(Icons.photo_library_outlined, size: 48, color: Colors.orangeAccent),
                  ),
                  const SizedBox(height: 24),
                  Text("No memories yet", style: GoogleFonts.outfit(fontSize: 20, fontWeight: FontWeight.bold)),
                  const SizedBox(height: 8),
                  Text("Start capturing your trip together.", style: TextStyle(color: context.appColors.textSecondary)),
                ],
              ),
            );
          }

          final groups = _groupPhotosByDay(photos);
          final sortedDateKeys = groups.keys.toList();

          return RefreshIndicator(
            onRefresh: () async => widget.onRefresh(),
            child: CustomScrollView(
              slivers: [
                SliverToBoxAdapter(
                  child: Padding(
                    padding: const EdgeInsets.all(20),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(_isSelectionMode ? "${_selectedPhotoIds.length} Selected" : "Memory Timeline", 
                                style: GoogleFonts.outfit(fontSize: 28, fontWeight: FontWeight.bold)),
                            Text(_isSelectionMode ? "Tap photos to select/deselect" : "All moments from ${widget.trip.location}", 
                                style: TextStyle(color: context.appColors.textSecondary)),
                          ],
                        ),
                        if (_isSelectionMode)
                          Row(
                            children: [
                              IconButton(
                                icon: const Icon(Icons.delete_outline, color: Colors.redAccent),
                                onPressed: () => _deleteSelectedPhotos(photos),
                              ),
                              IconButton(
                                icon: const Icon(Icons.close),
                                onPressed: () => setState(() {
                                  _isSelectionMode = false;
                                  _selectedPhotoIds.clear();
                                }),
                              ),
                            ],
                          ),
                      ],
                    ),
                  ),
                ),
                ...sortedDateKeys.map((dateKey) {
                  final dayPhotos = groups[dateKey]!;
                  return SliverMainAxisGroup(
                    slivers: [
                      SliverToBoxAdapter(
                        child: Padding(
                          padding: const EdgeInsets.fromLTRB(20, 16, 20, 8),
                          child: Text(dateKey, style: GoogleFonts.outfit(fontSize: 18, fontWeight: FontWeight.bold, color: AppColors.brand)),
                        ),
                      ),
                      SliverPadding(
                        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
                        sliver: SliverGrid(
                          gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                            crossAxisCount: 3,
                            crossAxisSpacing: 8,
                            mainAxisSpacing: 8,
                            childAspectRatio: 1,
                          ),
                          delegate: SliverChildBuilderDelegate(
                            (context, index) {
                              final photo = dayPhotos[index];
                              final isSelected = _selectedPhotoIds.contains(photo['id']);
                              return _GalleryGridTile(
                                photo: photo, 
                                allPhotos: photos, 
                                trip: widget.trip,
                                isSelectionMode: _isSelectionMode,
                                isSelected: isSelected,
                                onSelect: () => _toggleSelection(photo['id']),
                                onLongPress: () => _enterSelectionMode(photo['id']),
                              );
                            },
                            childCount: dayPhotos.length,
                            addAutomaticKeepAlives: false,
                            addRepaintBoundaries: true,
                          ),
                        ),
                      ),
                    ],
                  );
                }).toList(),
                const SliverPadding(padding: EdgeInsets.only(bottom: 100)),
              ],
            ),
          );
        },
      ),
    );
  }
}

class _GalleryGridTile extends StatelessWidget {
  final Map<String, dynamic> photo;
  final List<Map<String, dynamic>> allPhotos;
  final Trip trip;
  final bool isSelectionMode;
  final bool isSelected;
  final VoidCallback onSelect;
  final VoidCallback onLongPress;

  const _GalleryGridTile({
    required this.photo, 
    required this.allPhotos, 
    required this.trip,
    required this.isSelectionMode,
    required this.isSelected,
    required this.onSelect,
    required this.onLongPress,
  });

  @override
  Widget build(BuildContext context) {
    final reactions = photo['reactions'] as List<PhotoReaction>? ?? [];
    
    return GestureDetector(
      onTap: isSelectionMode ? onSelect : () {
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (_) => GalleryViewer(
              initialIndex: allPhotos.indexOf(photo),
              allPhotos: allPhotos,
              trip: trip,
            ),
          ),
        );
      },
      onLongPress: isSelectionMode ? null : onLongPress,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: isSelected ? const EdgeInsets.all(4) : EdgeInsets.zero,
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(12),
          color: isSelected ? AppColors.brand.withOpacity(0.3) : Colors.transparent,
        ),
        child: Hero(
          tag: photo['id'], 
          child: Container(
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(isArraySelected(isSelected) ? 8 : 12),
              boxShadow: [BoxShadow(color: Colors.black12, blurRadius: 4, offset: const Offset(0, 2))],
            ),
            clipBehavior: Clip.antiAlias,
            child: Stack(
              fit: StackFit.expand,
              children: [
                CachedNetworkImage(
                  imageUrl: photo['thumbnail_url'] ?? photo['url'],
                  memCacheWidth: 400,
                  fit: BoxFit.cover,
                  placeholder: (context, url) => Container(color: context.appColors.surfaceBg),
                  errorWidget: (context, url, e) => const Icon(Icons.error),
                ),
                if (isSelectionMode)
                  Positioned(
                    top: 4,
                    right: 4,
                    child: Container(
                      decoration: BoxDecoration(
                        color: isSelected ? AppColors.brand : Colors.black26,
                        shape: BoxShape.circle,
                        border: Border.all(color: Colors.white, width: 1.5),
                      ),
                      child: Icon(
                        isSelected ? Icons.check : null,
                        size: 16,
                        color: Colors.white,
                      ),
                    ),
                  ),
                if (!isSelectionMode && reactions.isNotEmpty)
                  Positioned(
                    bottom: 4,
                    right: 4,
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 2),
                      decoration: BoxDecoration(color: Colors.black54, borderRadius: BorderRadius.circular(4)),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Text(reactions.first.reaction, style: const TextStyle(fontSize: 10)),
                          if (reactions.length > 1)
                            Text(" +${reactions.length - 1}", style: const TextStyle(color: Colors.white, fontSize: 8, fontWeight: FontWeight.bold)),
                        ],
                      ),
                    ),
                  ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  bool isArraySelected(bool selected) => selected; // Helper
}

class GalleryViewer extends StatefulWidget {
  final int initialIndex;
  final List<Map<String, dynamic>> allPhotos;
  final Trip trip;

  const GalleryViewer({
    super.key,
    required this.initialIndex,
    required this.allPhotos,
    required this.trip,
  });

  @override
  State<GalleryViewer> createState() => _GalleryViewerState();
}

class _GalleryViewerState extends State<GalleryViewer> {
  late PageController _pageController;
  late int _currentIndex;
  bool _showDetails = true;

  @override
  void initState() {
    super.initState();
    _currentIndex = widget.initialIndex;
    _pageController = PageController(initialPage: widget.initialIndex);
  }

  Future<void> _deletePhoto() async {
    final photo = widget.allPhotos[_currentIndex];
    final uid = Supabase.instance.client.auth.currentUser!.id;
    final isAdmin = widget.trip.adminIds.contains(uid);
    final isOwner = photo['uploader_id'] == uid;

    if (!isAdmin && !isOwner) {
       ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("Only owner or admin can delete memories.")));
       return;
    }

    final confirm = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text("Delete Memory"),
        content: const Text("Are you sure? This will remove the photo from everyone's timeline."),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text("Cancel")),
          TextButton(onPressed: () => Navigator.pop(ctx, true), child: const Text("Delete", style: TextStyle(color: Colors.red))),
        ],
      ),
    );

    if (confirm == true) {
      try {
        await TripService().deletePhoto(widget.trip.id, photo['id'], photo['url'], photo['uploader_id']);
        if (mounted) Navigator.pop(context);
      } catch (e) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text("Delete failed: $e")));
      }
    }
  }

  Future<void> _generateAICaption() async {
    final photo = widget.allPhotos[_currentIndex];
    HapticFeedback.mediumImpact();
    try {
      final caption = await GeminiService().generateImageCaption(photo['url'], widget.trip.location);
      await TripService().updatePhotoCaption(photo['id'], caption);
      setState(() {
         photo['caption'] = caption; // Local update for immediate feedback
      });
    } catch (e) {
       ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("AI failed to caption this moment.")));
    }
  }

  @override
  Widget build(BuildContext context) {
    final currentPhoto = widget.allPhotos[_currentIndex];
    final uid = Supabase.instance.client.auth.currentUser!.id;

    return Scaffold(
      backgroundColor: Colors.black,
      body: Stack(
        children: [
          // Main Image View
          GestureDetector(
            onTap: () => setState(() => _showDetails = !_showDetails),
            child: PhotoViewGallery.builder(
              itemCount: widget.allPhotos.length,
              builder: (context, index) {
                return PhotoViewGalleryPageOptions(
                  imageProvider: CachedNetworkImageProvider(widget.allPhotos[index]['url']),
                  minScale: PhotoViewComputedScale.contained,
                  maxScale: PhotoViewComputedScale.covered * 2,
                  heroAttributes: PhotoViewHeroAttributes(tag: widget.allPhotos[index]['id']),
                );
              },
              pageController: _pageController,
              onPageChanged: (index) => setState(() => _currentIndex = index),
              backgroundDecoration: const BoxDecoration(color: Colors.black),
            ),
          ),

          // Top Bar
          if (_showDetails)
            Positioned(
              top: 0,
              left: 0,
              right: 0,
              child: SafeArea(
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                  child: Row(
                    children: [
                      IconButton(
                        icon: const Icon(Icons.arrow_back, color: Colors.white),
                        onPressed: () => Navigator.pop(context),
                      ),
                      const Spacer(),
                      IconButton(
                        icon: const Icon(Icons.delete_outline, color: Colors.white70),
                        onPressed: _deletePhoto,
                      ),
                      IconButton(
                        icon: const Icon(Icons.share_outlined, color: Colors.white),
                        onPressed: () => Share.share("Checkout this memory from our trip to ${widget.trip.location}! 🌍\n${currentPhoto['url']}"),
                      ),
                    ],
                  ),
                ),
              ),
            ),

          // Bottom Bar Details
          if (_showDetails)
            Positioned(
              bottom: 0,
              left: 0,
              right: 0,
              child: Container(
                padding: const EdgeInsets.all(24),
                decoration: const BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.bottomCenter,
                    end: Alignment.topCenter,
                    colors: [Colors.black87, Colors.transparent],
                  ),
                ),
                child: SafeArea(
                  top: false,
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          FutureBuilder<UserProfile?>(
                            future: AuthService.instance.getOtherUserProfile(currentPhoto['uploader_id']),
                            builder: (context, snap) {
                              final name = snap.data?.displayName ?? "...";
                              return Text("Shared by $name", style: const TextStyle(color: Colors.white70, fontSize: 13, fontWeight: FontWeight.bold));
                            },
                          ),
                          const Spacer(),
                          Text(
                            DateFormat('MMM d, HH:mm').format(DateTime.parse(currentPhoto['created_at']).toLocal()),
                            style: const TextStyle(color: Colors.white38, fontSize: 13),
                          ),
                        ],
                      ),
                      const SizedBox(height: 12),
                      if (currentPhoto['caption'] != null && currentPhoto['caption'].isNotEmpty)
                        Padding(
                          padding: const EdgeInsets.only(bottom: 12),
                          child: Text(
                            currentPhoto['caption'],
                            style: GoogleFonts.outfit(color: Colors.white, fontSize: 18, fontWeight: FontWeight.w500),
                          ),
                        )
                      else
                        TextButton.icon(
                          onPressed: _generateAICaption,
                          icon: const Icon(Icons.auto_awesome, size: 16, color: Colors.orangeAccent),
                          label: const Text("Generate AI Caption", style: TextStyle(color: Colors.orangeAccent)),
                        ),
                      const SizedBox(height: 16),
                      StreamBuilder<List<PhotoReaction>>(
                        stream: TripService().getPhotoReactionsStream(currentPhoto['id']),
                        builder: (context, snapshot) {
                          final reactions = snapshot.data ?? [];
                          return Row(
                            children: [
                              _buildReactionButton('❤️', reactions, currentPhoto['id'], uid),
                              _buildReactionButton('🔥', reactions, currentPhoto['id'], uid),
                              _buildReactionButton('😍', reactions, currentPhoto['id'], uid),
                              _buildReactionButton('📸', reactions, currentPhoto['id'], uid),
                            ],
                          );
                        },
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

  Widget _buildReactionButton(String emoji, List<PhotoReaction> allReactions, String photoId, String uid) {
    final count = allReactions.where((r) => r.reaction == emoji).length;
    final isMe = allReactions.any((r) => r.reaction == emoji && r.userId == uid);

    return Padding(
      padding: const EdgeInsets.only(right: 16),
      child: GestureDetector(
        onTap: () {
          HapticFeedback.lightImpact();
          TripService().togglePhotoReaction(photoId, emoji);
        },
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
          decoration: BoxDecoration(
            color: isMe ? Colors.white24 : Colors.white10,
            borderRadius: BorderRadius.circular(20),
            border: Border.all(color: isMe ? Colors.white54 : Colors.transparent),
          ),
          child: Row(
            children: [
              Text(emoji, style: const TextStyle(fontSize: 14)),
              if (count > 0) ...[
                const SizedBox(width: 4),
                Text("$count", style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 12)),
              ],
            ],
          ),
        ),
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

class _ReviewsTabState extends State<_ReviewsTab> with AutomaticKeepAliveClientMixin {
  @override
  bool get wantKeepAlive => true;

  final _commentController = TextEditingController();
  int _selectedRating = 0;
  bool _isSubmitting = false;

  @override
  Widget build(BuildContext context) {
    super.build(context);
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
                  Icon(Icons.rate_review_outlined, size: 64, color: context.appColors.textMuted),
                  const SizedBox(height: 16),
                  Text(
                    "Reviews will open when the trip ends.",
                    style: TextStyle(fontSize: 18, color: context.appColors.textSecondary),
                  ),
                  if (widget.trip.endDate != null)
                     Padding(
                       padding: const EdgeInsets.only(top: 8.0),
                       child: Text(
                         "Trip ends on: ${DateFormat.yMMMd().format(widget.trip.endDate!)}",
                         style: TextStyle(color: context.appColors.textSecondary),
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
             Icon(Icons.lock_clock, size: 64, color: context.appColors.textMuted),
             const SizedBox(height: 16),
             Text("Reviews Locked", style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: context.appColors.textSecondary)),
             const SizedBox(height: 8),
             Text("Finish the trip to unlock reviews!", style: TextStyle(color: context.appColors.textSecondary)),
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
              Center(child: Text("No reviews yet. Be the first!", style: TextStyle(color: context.appColors.textSecondary)))
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
class _LinksTab extends StatefulWidget {
  final Trip trip;
  final Future<void> Function() onRefresh;
  const _LinksTab({super.key, required this.trip, required this.onRefresh});

  @override
  State<_LinksTab> createState() => _LinksTabState();
}

class _LinksTabState extends State<_LinksTab> with AutomaticKeepAliveClientMixin {
  late Stream<List<TripLink>> _linksStream;

  @override
  bool get wantKeepAlive => true;

  @override
  void initState() {
    super.initState();
    _linksStream = TripService().getTripLinksStream(widget.trip.id);
  }

  Future<void> _launchUrl(BuildContext context, String url) async {
    final uri = Uri.parse(url);
    if (!await launchUrl(uri, mode: LaunchMode.externalApplication)) {
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text("Could not launch $url")));
    }
  }

  void _showAddResourceSheet(BuildContext context) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) => _AddResourceSheet(tripId: widget.trip.id, onAdded: widget.onRefresh),
    );
  }

  void _handlePin(TripLink link, bool value) async {
    try {
      await TripService().toggleLinkPin(link.id, value);
    } catch (e) {
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text("Error: $e")));
    }
  }

  void _confirmDelete(BuildContext context, TripLink link) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (c) => AlertDialog(
        title: const Text("Remove Resource?"),
        content: Text("Delete '${link.title}'?"),
        actions: [
          TextButton(onPressed: () => Navigator.pop(c, false), child: const Text("Cancel")),
          TextButton(onPressed: () => Navigator.pop(c, true), child: const Text("Delete", style: TextStyle(color: Colors.red))),
        ],
      ),
    );

    if (confirm == true) {
      try {
        await TripService().deleteTripLinkRelational(link.id);
      } catch (e) {
        if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text("Error: $e")));
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    super.build(context);
    final currentUser = Supabase.instance.client.auth.currentUser?.id;
    final isAdmin = currentUser != null && widget.trip.adminIds.contains(currentUser);

    return Scaffold(
      backgroundColor: Colors.transparent,
      floatingActionButton: widget.trip.isDead ? null : FloatingActionButton.extended(
        onPressed: () => _showAddResourceSheet(context),
        icon: const Icon(Icons.add_link),
        backgroundColor: AppColors.brand,
        label: const Text("Add Resource"),
      ),
      body: StreamBuilder<List<TripLink>>(
        stream: _linksStream,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }
          
          final links = snapshot.data ?? [];
          
          if (links.isEmpty) {
            return _buildEmptyState(context);
          }

          // Grouping by Category
          final grouped = <String, List<TripLink>>{};
          for (var link in links) {
            final cat = link.category;
            if (!grouped.containsKey(cat)) grouped[cat] = [];
            grouped[cat]!.add(link);
          }

          // Move Pinned to top group or handle it specially?
          // Let's just group them and show Pinned items at the top of each list (already handled by stream order)
          
          final categories = grouped.keys.toList()..sort();

          return RefreshIndicator(
            onRefresh: widget.onRefresh,
            child: ListView(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              children: [
                // Quick Actions Header
                if (!widget.trip.isDead)
                  _buildQuickActions(context),
                if (!widget.trip.isDead)
                  const SizedBox(height: 20),
                
                ...categories.expand((cat) => [
                  Padding(
                    padding: const EdgeInsets.only(left: 4, bottom: 12, top: 12),
                    child: Text(
                      cat.toUpperCase(),
                      style: GoogleFonts.inter(
                        fontSize: 12,
                        fontWeight: FontWeight.bold,
                        color: context.appColors.textMuted,
                        letterSpacing: 1.2,
                      ),
                    ),
                  ),
                  ...grouped[cat]!.map((link) => _LinkCard(
                    link: link,
                    isAdmin: isAdmin,
                    isOwner: link.addedBy == currentUser,
                    isDead: widget.trip.isDead,
                    onTap: () => _launchUrl(context, link.url),
                    onDelete: () => _confirmDelete(context, link),
                    onPin: (val) => _handlePin(link, val),
                  )),
                ]),
                const SizedBox(height: 80), // Space for FAB
              ],
            ),
          );
        },
      ),
    );
  }

  Widget _buildQuickActions(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          "Quick Add",
          style: GoogleFonts.outfit(fontSize: 18, fontWeight: FontWeight.bold),
        ),
        const SizedBox(height: 12),
        SingleChildScrollView(
          scrollDirection: Axis.horizontal,
          child: Row(
            children: [
              _QuickActionChip(icon: Icons.hotel_outlined, label: "Stay", color: Colors.blue, onTap: () => _showAddResourceSheet(context)),
              _QuickActionChip(icon: Icons.flight_takeoff, label: "Flight", color: Colors.purple, onTap: () => _showAddResourceSheet(context)),
              _QuickActionChip(icon: Icons.confirmation_number_outlined, label: "Ticket", color: Colors.orange, onTap: () => _showAddResourceSheet(context)),
              _QuickActionChip(icon: Icons.restaurant_menu, label: "Food", color: Colors.red, onTap: () => _showAddResourceSheet(context)),
              _QuickActionChip(icon: Icons.directions_car_outlined, label: "Transp", color: Colors.teal, onTap: () => _showAddResourceSheet(context)),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildEmptyState(BuildContext context) {
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            padding: const EdgeInsets.all(24),
            decoration: BoxDecoration(color: context.isDark ? AppColors.brand.withOpacity(0.15) : Colors.blue.withOpacity(0.05), shape: BoxShape.circle),
            child: const Icon(Icons.link, size: 64, color: AppColors.brand),
          ),
          const SizedBox(height: 24),
          Text(
            "Trip Resources Hub",
            style: GoogleFonts.outfit(fontSize: 20, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 8),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 40),
            child: Text(
              "Keep all your bookings, tickets, and travel documents in one organized place.",
              textAlign: TextAlign.center,
              style: TextStyle(color: context.appColors.textSecondary, fontSize: 14),
            ),
          ),
        ],
      ),
    );
  }
}

class _QuickActionChip extends StatelessWidget {
  final IconData icon;
  final String label;
  final Color color;
  final VoidCallback onTap;

  const _QuickActionChip({required this.icon, required this.label, required this.color, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(right: 12),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(16),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
          decoration: BoxDecoration(
            color: color.withOpacity(0.08),
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: color.withOpacity(0.15)),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(icon, size: 16, color: color),
              const SizedBox(width: 8),
              Text(
                label,
                style: GoogleFonts.inter(
                  fontSize: 12,
                  fontWeight: FontWeight.w700,
                  color: color,
                  letterSpacing: 0.2,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _LinkCard extends StatelessWidget {
  final TripLink link;
  final bool isAdmin;
  final bool isOwner;
  final bool isDead;
  final VoidCallback onTap;
  final VoidCallback onDelete;
  final Function(bool) onPin;

  const _LinkCard({
    required this.link,
    required this.isAdmin,
    required this.isOwner,
    this.isDead = false,
    required this.onTap,
    required this.onDelete,
    required this.onPin,
  });

  @override
  Widget build(BuildContext context) {
    final catColor = _getCategoryColor(link.category);
    
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: context.appColors.cardBg,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(color: context.appColors.shadow, blurRadius: 10, offset: const Offset(0, 4)),
        ],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(20),
        child: IntrinsicHeight(
          child: Row(
            children: [
              // Category Accent Bar
              Container(width: 6, color: catColor),
              Expanded(
                child: InkWell(
                  onTap: onTap,
                  child: Padding(
                    padding: const EdgeInsets.all(12),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Expanded(
                              child: Text(
                                link.title,
                                style: GoogleFonts.inter(fontWeight: FontWeight.bold, fontSize: 15),
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                              ),
                            ),
                            if (link.isPinned)
                              const Padding(
                                padding: EdgeInsets.only(left: 8),
                                child: Icon(Icons.push_pin, size: 14, color: Colors.orange),
                              ),
                          ],
                        ),
                        Text(
                          link.siteName ?? Uri.parse(link.url).host,
                          style: TextStyle(color: context.appColors.textMuted, fontSize: 12),
                        ),
                        if (link.previewImage != null) ...[
                          const SizedBox(height: 12),
                          ClipRRect(
                            borderRadius: BorderRadius.circular(12),
                            child: CachedNetworkImage(
                              imageUrl: link.previewImage!,
                              height: 120,
                              width: double.infinity,
                              fit: BoxFit.cover,
                              placeholder: (c, u) => Container(color: context.appColors.surfaceBg),
                              errorWidget: (c, u, e) => const SizedBox.shrink(),
                            ),
                          ),
                        ],
                        const SizedBox(height: 12),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Text(
                              "Added ${timeago.format(link.createdAt)}",
                              style: TextStyle(color: context.appColors.textMuted, fontSize: 10),
                            ),
                            Row(
                              children: [
                                if (!isDead && (isAdmin || isOwner))
                                  IconButton(
                                    icon: Icon(link.isPinned ? Icons.push_pin : Icons.push_pin_outlined, 
                                        size: 18, color: link.isPinned ? Colors.orange : context.appColors.textMuted),
                                    onPressed: () => onPin(!link.isPinned),
                                    constraints: const BoxConstraints(),
                                    padding: const EdgeInsets.all(4),
                                  ),
                                if (!isDead && (isAdmin || isOwner))
                                  IconButton(
                                    icon: Icon(Icons.delete_outline, size: 18, color: context.appColors.textMuted),
                                    onPressed: onDelete,
                                    constraints: const BoxConstraints(),
                                    padding: const EdgeInsets.all(4),
                                  ),
                              ],
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Color _getCategoryColor(String cat) {
    switch (cat) {
      case 'Stay': return Colors.blue;
      case 'Flights': return Colors.purple;
      case 'Tickets': return Colors.orange;
      case 'Restaurants': return Colors.red;
      case 'Transport': return Colors.teal;
      case 'Places': return Colors.green;
      case 'Documents': return Colors.grey;
      default: return Colors.blueGrey;
    }
  }
}

class _AddResourceSheet extends StatefulWidget {
  final String tripId;
  final Future<void> Function() onAdded;
  const _AddResourceSheet({required this.tripId, required this.onAdded});

  @override
  State<_AddResourceSheet> createState() => _AddResourceSheetState();
}

class _AddResourceSheetState extends State<_AddResourceSheet> {
  final _cTitle = TextEditingController();
  final _cUrl = TextEditingController();
  String _selectedCategory = 'Other';
  bool _isSaving = false;

  final List<String> _categories = [
    'Stay', 'Flights', 'Tickets', 'Restaurants', 'Transport', 'Places', 'Documents', 'Other'
  ];

  @override
  void initState() {
    super.initState();
    _cUrl.addListener(_autoDetectCategory);
  }

  void _autoDetectCategory() {
    if (_cUrl.text.isNotEmpty) {
      final cat = UrlMetadataService.detectCategory(_cUrl.text);
      if (cat != 'Other' && _selectedCategory == 'Other') {
        setState(() => _selectedCategory = cat);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: EdgeInsets.fromLTRB(20, 20, 20, MediaQuery.of(context).viewInsets.bottom + 20),
      decoration: BoxDecoration(
        color: context.appColors.scaffoldBg,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text("Add Trip Resource", style: GoogleFonts.outfit(fontSize: 20, fontWeight: FontWeight.bold)),
              IconButton(onPressed: () => Navigator.pop(context), icon: const Icon(Icons.close)),
            ],
          ),
          const SizedBox(height: 20),
          DropdownButtonFormField<String>(
            value: _selectedCategory,
            decoration: InputDecoration(
              labelText: "Category",
              prefixIcon: const Icon(Icons.label_outline),
              border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
            ),
            items: _categories.map((c) => DropdownMenuItem(value: c, child: Text(c))).toList(),
            onChanged: (v) => setState(() => _selectedCategory = v!),
          ),
          const SizedBox(height: 16),
          TextField(
            controller: _cTitle,
            decoration: InputDecoration(
              labelText: "Title (e.g. Flight to Amsterdam)",
              prefixIcon: const Icon(Icons.title),
              border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
            ),
          ),
          const SizedBox(height: 16),
          TextField(
            controller: _cUrl,
            decoration: InputDecoration(
              labelText: "URL (https://...)",
              prefixIcon: const Icon(Icons.link),
              border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
            ),
            keyboardType: TextInputType.url,
          ),
          const SizedBox(height: 24),
          SizedBox(
            width: double.infinity,
            height: 54,
            child: ElevatedButton(
              onPressed: _isSaving ? null : _save,
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.brand,
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              ),
              child: _isSaving 
                  ? const CircularProgressIndicator(color: Colors.white) 
                  : const Text("Save Resource", style: TextStyle(fontWeight: FontWeight.bold)),
            ),
          ),
        ],
      ),
    );
  }

  void _save() async {
    if (_cTitle.text.isEmpty || _cUrl.text.isEmpty) return;
    
    setState(() => _isSaving = true);
    
    try {
      String url = _cUrl.text.trim();
      if (!url.startsWith('http')) url = 'https://$url';

      await TripService().addTripLinkRelational(
        tripId: widget.tripId,
        title: _cTitle.text.trim(),
        url: url,
        category: _selectedCategory,
      );
      
      await widget.onAdded();
      if (mounted) Navigator.pop(context);
    } catch (e) {
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text("Error: $e")));
    } finally {
      if (mounted) setState(() => _isSaving = false);
    }
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
      decoration: BoxDecoration(
        color: context.appColors.scaffoldBg,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Row(
                children: [
                  Icon(Icons.auto_awesome, color: AppColors.brand),
                  const SizedBox(width: 8),
                  Text('AI Assistant',
                    style: TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                      color: context.appColors.textPrimary
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
                  Text("Saved AI Summary", style: GoogleFonts.poppins(fontSize: 16, fontWeight: FontWeight.bold, color: AppColors.brand)),
                  const SizedBox(height: 8),
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: context.isDark ? AppColors.brand.withOpacity(0.15) : Colors.blue.shade50,
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Text(_summary!, style: const TextStyle(fontSize: 14)),
                  ),
                  const SizedBox(height: 16),
                  ElevatedButton.icon(
                    onPressed: () => Share.share(_summary!),
                    icon: const Icon(Icons.share),
                    label: const Text("Share Trip Summary"),
                    style: ElevatedButton.styleFrom(backgroundColor: AppColors.brand),
                  ),
                ] else ...[
                  Text("Trip Summary", style: GoogleFonts.poppins(fontSize: 16, fontWeight: FontWeight.bold, color: AppColors.brand)),
                  const SizedBox(height: 8),
                  Text("Generate once and save it for your whole team.", style: TextStyle(color: context.appColors.textSecondary)),
                  const SizedBox(height: 16),
                  ElevatedButton.icon(
                    onPressed: _isGenerating ? null : _generateAndSaveSummary,
                    icon: _isGenerating ? const SizedBox(width: 16, height: 16, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white)) : const Icon(Icons.auto_awesome),
                    label: Text(_isGenerating ? "Generating..." : "Generate & Save"),
                    style: ElevatedButton.styleFrom(backgroundColor: AppColors.brand),
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

// ─────────────────────────────────────────────
//  EXPENSES TAB
// ─────────────────────────────────────────────
class _ExpensesTab extends StatefulWidget {
  final Trip trip;
  final Future<void> Function() onRefresh;
  const _ExpensesTab({required this.trip, required this.onRefresh});

  @override
  State<_ExpensesTab> createState() => _ExpensesTabState();
}

class _ExpensesTabState extends State<_ExpensesTab> with AutomaticKeepAliveClientMixin {
  @override
  bool get wantKeepAlive => true;

  final ExpenseService _expenseService = ExpenseService();
  Map<String, UserProfile> _profileCache = {};
  bool _profilesLoaded = false;

  @override
  void initState() {
    super.initState();
    _loadProfiles();
  }

  Future<void> _loadProfiles() async {
    try {
      final profiles = await TripService().getTripMembersProfiles(widget.trip.memberIds);
      final map = <String, UserProfile>{};
      for (final p in profiles) {
        map[p.uid] = p;
      }
      if (mounted) setState(() { _profileCache = map; _profilesLoaded = true; });
    } catch (_) {
      if (mounted) setState(() => _profilesLoaded = true);
    }
  }

  String _userName(String uid) {
    return _profileCache[uid]?.displayName ?? _profileCache[uid]?.username ?? uid.substring(0, 8);
  }

  @override
  Widget build(BuildContext context) {
    super.build(context);
    final colors = context.appColors;
    final currentUser = Supabase.instance.client.auth.currentUser?.id;
    final currency = widget.trip.budgetCurrency;

    return StreamBuilder<List<TripExpense>>(
      stream: _expenseService.getExpensesStream(widget.trip.id),
      builder: (context, snapshot) {
        final expenses = snapshot.data ?? [];
        final balances = calculateBalances(expenses);
        final debts = simplifyDebts(balances);

        return Scaffold(
          backgroundColor: Colors.transparent,
          floatingActionButton: FloatingActionButton.extended(
            heroTag: 'add_expense',
            onPressed: () => _showAddExpenseSheet(context, currency),
            backgroundColor: AppColors.brand,
            icon: const Icon(Icons.add, color: Colors.white),
            label: Text("Add Expense", style: GoogleFonts.inter(color: Colors.white, fontWeight: FontWeight.bold)),
          ),
          body: RefreshIndicator(
            onRefresh: widget.onRefresh,
            child: expenses.isEmpty && !snapshot.hasError
                ? _buildEmptyState(colors)
                : SingleChildScrollView(
                    physics: const AlwaysScrollableScrollPhysics(),
                    padding: const EdgeInsets.fromLTRB(16, 16, 16, 80),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // Balance Summary Card
                        if (balances.isNotEmpty) _buildBalanceSummary(colors, balances, currency, currentUser),
                        
                        // Simplified Debts
                        if (debts.isNotEmpty) ...[
                          const SizedBox(height: 20),
                          _buildSimplifiedDebts(colors, debts, currency, currentUser),
                        ],

                        // Expense List
                        const SizedBox(height: 20),
                        Text("All Expenses", style: GoogleFonts.outfit(fontSize: 18, fontWeight: FontWeight.bold, color: colors.textPrimary)),
                        const SizedBox(height: 12),
                        ...expenses.map((e) => _buildExpenseCard(colors, e, currency, currentUser)),
                      ],
                    ),
                  ),
          ),
        );
      },
    );
  }

  Widget _buildEmptyState(AppColors colors) {
    return Center(
      child: SingleChildScrollView(
        physics: const AlwaysScrollableScrollPhysics(),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const SizedBox(height: 80),
            Icon(Icons.receipt_long_rounded, size: 64, color: colors.textSecondary.withOpacity(0.4)),
            const SizedBox(height: 16),
            Text("No expenses yet", style: GoogleFonts.outfit(fontSize: 18, fontWeight: FontWeight.w600, color: colors.textSecondary)),
            const SizedBox(height: 8),
            Text("Tap + to add your first expense", style: TextStyle(color: colors.textSecondary.withOpacity(0.7), fontSize: 14)),
          ],
        ),
      ),
    );
  }

  Widget _buildBalanceSummary(AppColors colors, Map<String, double> balances, String currency, String? currentUser) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [Colors.deepPurple.shade400, Colors.deepPurple.shade700],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(20),
        boxShadow: [BoxShadow(color: Colors.deepPurple.withOpacity(0.3), blurRadius: 12, offset: const Offset(0, 6))],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text("Balance Summary", style: GoogleFonts.outfit(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.white)),
          const SizedBox(height: 16),
          ...balances.entries.map((entry) {
            final isCurrentUser = entry.key == currentUser;
            final balance = entry.value;
            final isPositive = balance > 0.01;
            final isNegative = balance < -0.01;
            return Padding(
              padding: const EdgeInsets.only(bottom: 8),
              child: Row(
                children: [
                  Expanded(
                    child: Text(
                      isCurrentUser ? "You" : _userName(entry.key),
                      style: GoogleFonts.inter(
                        color: Colors.white,
                        fontWeight: isCurrentUser ? FontWeight.bold : FontWeight.w500,
                        fontSize: 14,
                      ),
                    ),
                  ),
                  Text(
                    "${isPositive ? '+' : ''}${balance.toStringAsFixed(2)} $currency",
                    style: GoogleFonts.inter(
                      color: isPositive
                          ? Colors.greenAccent
                          : isNegative
                              ? Colors.redAccent.shade100
                              : Colors.white70,
                      fontWeight: FontWeight.bold,
                      fontSize: 14,
                    ),
                  ),
                ],
              ),
            );
          }),
        ],
      ),
    );
  }

  Widget _buildSimplifiedDebts(AppColors colors, List<SimplifiedDebt> debts, String currency, String? currentUser) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text("Settle Up", style: GoogleFonts.outfit(fontSize: 18, fontWeight: FontWeight.bold, color: colors.textPrimary)),
        const SizedBox(height: 12),
        ...debts.map((debt) {
          final isYouOwe = debt.fromUserId == currentUser;
          final isOwedToYou = debt.toUserId == currentUser;
          return Container(
            margin: const EdgeInsets.only(bottom: 10),
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: colors.cardBg,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(
                color: isYouOwe
                    ? Colors.red.withOpacity(0.3)
                    : isOwedToYou
                        ? Colors.green.withOpacity(0.3)
                        : colors.border,
              ),
            ),
            child: Row(
              children: [
                Icon(
                  isYouOwe ? Icons.arrow_upward : Icons.arrow_downward,
                  color: isYouOwe ? Colors.redAccent : Colors.green,
                  size: 20,
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    isYouOwe
                        ? "You owe ${_userName(debt.toUserId)}"
                        : isOwedToYou
                            ? "${_userName(debt.fromUserId)} owes you"
                            : "${_userName(debt.fromUserId)} → ${_userName(debt.toUserId)}",
                    style: GoogleFonts.inter(fontSize: 14, fontWeight: FontWeight.w600, color: colors.textPrimary),
                  ),
                ),
                Text(
                  "${debt.amount.toStringAsFixed(2)} $currency",
                  style: GoogleFonts.inter(
                    fontSize: 15,
                    fontWeight: FontWeight.bold,
                    color: isYouOwe ? Colors.redAccent : Colors.green,
                  ),
                ),
              ],
            ),
          );
        }),
      ],
    );
  }

  Widget _buildExpenseCard(AppColors colors, TripExpense expense, String currency, String? currentUser) {
    final isOwner = expense.paidBy == currentUser;
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: colors.cardBg,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: colors.border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Text(TripExpense.categoryEmoji(expense.category), style: const TextStyle(fontSize: 24)),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(expense.title, style: GoogleFonts.inter(fontSize: 15, fontWeight: FontWeight.w600, color: colors.textPrimary)),
                    const SizedBox(height: 2),
                    Text(
                      "Paid by ${expense.paidBy == currentUser ? 'You' : _userName(expense.paidBy)}",
                      style: TextStyle(fontSize: 12, color: colors.textSecondary),
                    ),
                  ],
                ),
              ),
              Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Text(
                    "${expense.amount.toStringAsFixed(2)} $currency",
                    style: GoogleFonts.inter(fontSize: 16, fontWeight: FontWeight.bold, color: colors.textPrimary),
                  ),
                  Text(
                    DateFormat('MMM d').format(expense.createdAt),
                    style: TextStyle(fontSize: 11, color: colors.textSecondary),
                  ),
                ],
              ),
            ],
          ),
          if (expense.notes != null && expense.notes!.isNotEmpty) ...[
            const SizedBox(height: 8),
            Text(expense.notes!, style: TextStyle(fontSize: 13, color: colors.textSecondary)),
          ],
          if (expense.splits.isNotEmpty) ...[
            const SizedBox(height: 10),
            Divider(color: colors.border, height: 1),
            const SizedBox(height: 10),
            ...expense.splits.map((split) => Padding(
              padding: const EdgeInsets.only(bottom: 4),
              child: Row(
                children: [
                  Text(
                    split.userId == currentUser ? "You" : _userName(split.userId),
                    style: TextStyle(fontSize: 13, color: colors.textSecondary),
                  ),
                  const Spacer(),
                  Text(
                    "${split.amount.toStringAsFixed(2)} $currency",
                    style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: colors.textPrimary),
                  ),
                  const SizedBox(width: 8),
                  if (split.isSettled)
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                      decoration: BoxDecoration(
                        color: Colors.green.withOpacity(0.1),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Text("Settled", style: TextStyle(fontSize: 11, color: Colors.green.shade700, fontWeight: FontWeight.w600)),
                    ),
                ],
              ),
            )),
          ],
          if (isOwner) ...[
            const SizedBox(height: 8),
            Align(
              alignment: Alignment.centerRight,
              child: IconButton(
                icon: Icon(Icons.delete_outline, color: Colors.red.shade300, size: 20),
                onPressed: () async {
                  final confirm = await showDialog<bool>(
                    context: context,
                    builder: (ctx) => AlertDialog(
                      title: const Text("Delete Expense"),
                      content: const Text("Are you sure you want to delete this expense?"),
                      actions: [
                        TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text("Cancel")),
                        TextButton(onPressed: () => Navigator.pop(ctx, true), child: Text("Delete", style: TextStyle(color: Colors.red))),
                      ],
                    ),
                  );
                  if (confirm == true) {
                    await _expenseService.deleteExpense(expense.id);
                  }
                },
              ),
            ),
          ],
        ],
      ),
    );
  }

  void _showAddExpenseSheet(BuildContext context, String currency) {
    final colors = context.appColors;
    final titleController = TextEditingController();
    final amountController = TextEditingController();
    final notesController = TextEditingController();
    String selectedCategory = 'general';
    String splitType = 'equal';
    final currentUser = Supabase.instance.client.auth.currentUser?.id ?? '';
    String paidBy = currentUser;

    final categories = ['general', 'food', 'transport', 'accommodation', 'activity', 'shopping'];

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: colors.surfaceBg,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(24))),
      builder: (ctx) {
        return StatefulBuilder(builder: (ctx, setModalState) {
          return Padding(
            padding: EdgeInsets.fromLTRB(20, 20, 20, MediaQuery.of(ctx).viewInsets.bottom + 20),
            child: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Center(
                    child: Container(width: 40, height: 4, decoration: BoxDecoration(color: colors.border, borderRadius: BorderRadius.circular(2))),
                  ),
                  const SizedBox(height: 16),
                  Text("Add Expense", style: GoogleFonts.outfit(fontSize: 20, fontWeight: FontWeight.bold, color: colors.textPrimary)),
                  const SizedBox(height: 20),
                  // Title
                  TextField(
                    controller: titleController,
                    decoration: InputDecoration(
                      labelText: "Title",
                      hintText: "e.g. Dinner at restaurant",
                      filled: true,
                      fillColor: colors.cardBg,
                      border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide(color: colors.border)),
                      enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide(color: colors.border)),
                    ),
                  ),
                  const SizedBox(height: 14),
                  // Amount
                  TextField(
                    controller: amountController,
                    keyboardType: const TextInputType.numberWithOptions(decimal: true),
                    decoration: InputDecoration(
                      labelText: "Amount ($currency)",
                      hintText: "0.00",
                      filled: true,
                      fillColor: colors.cardBg,
                      border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide(color: colors.border)),
                      enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide(color: colors.border)),
                    ),
                  ),
                  const SizedBox(height: 14),
                  // Category chips
                  Text("Category", style: GoogleFonts.inter(fontSize: 13, fontWeight: FontWeight.w600, color: colors.textSecondary)),
                  const SizedBox(height: 8),
                  Wrap(
                    spacing: 8,
                    runSpacing: 8,
                    children: categories.map((cat) {
                      final isSelected = selectedCategory == cat;
                      return ChoiceChip(
                        label: Text("${TripExpense.categoryEmoji(cat)} ${cat[0].toUpperCase()}${cat.substring(1)}"),
                        selected: isSelected,
                        selectedColor: AppColors.brand.withOpacity(0.2),
                        backgroundColor: colors.cardBg,
                        labelStyle: TextStyle(
                          color: isSelected ? AppColors.brand : colors.textSecondary,
                          fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                        ),
                        onSelected: (val) => setModalState(() => selectedCategory = cat),
                      );
                    }).toList(),
                  ),
                  const SizedBox(height: 14),
                  // Paid by dropdown
                  Text("Paid by", style: GoogleFonts.inter(fontSize: 13, fontWeight: FontWeight.w600, color: colors.textSecondary)),
                  const SizedBox(height: 8),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 12),
                    decoration: BoxDecoration(
                      color: colors.cardBg,
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: colors.border),
                    ),
                    child: DropdownButton<String>(
                      value: paidBy,
                      isExpanded: true,
                      underline: const SizedBox(),
                      dropdownColor: colors.cardBg,
                      items: widget.trip.memberIds.map((uid) {
                        return DropdownMenuItem(
                          value: uid,
                          child: Text(
                            uid == currentUser ? "You" : _userName(uid),
                            style: TextStyle(color: colors.textPrimary),
                          ),
                        );
                      }).toList(),
                      onChanged: (val) => setModalState(() => paidBy = val!),
                    ),
                  ),
                  const SizedBox(height: 14),
                  // Split type
                  Text("Split", style: GoogleFonts.inter(fontSize: 13, fontWeight: FontWeight.w600, color: colors.textSecondary)),
                  const SizedBox(height: 8),
                  Row(
                    children: [
                      Expanded(
                        child: ChoiceChip(
                          label: const Text("Equal"),
                          selected: splitType == 'equal',
                          selectedColor: AppColors.brand.withOpacity(0.2),
                          backgroundColor: colors.cardBg,
                          onSelected: (_) => setModalState(() => splitType = 'equal'),
                        ),
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: ChoiceChip(
                          label: const Text("Others Only"),
                          selected: splitType == 'full',
                          selectedColor: AppColors.brand.withOpacity(0.2),
                          backgroundColor: colors.cardBg,
                          onSelected: (_) => setModalState(() => splitType = 'full'),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 14),
                  // Notes
                  TextField(
                    controller: notesController,
                    maxLines: 2,
                    decoration: InputDecoration(
                      labelText: "Notes (optional)",
                      filled: true,
                      fillColor: colors.cardBg,
                      border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide(color: colors.border)),
                      enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide(color: colors.border)),
                    ),
                  ),
                  const SizedBox(height: 20),
                  // Submit
                  SizedBox(
                    width: double.infinity,
                    height: 50,
                    child: ElevatedButton(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppColors.brand,
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                      ),
                      onPressed: () async {
                        final title = titleController.text.trim();
                        final amount = double.tryParse(amountController.text.trim());
                        if (title.isEmpty || amount == null || amount <= 0) {
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(content: Text("Please enter a valid title and amount")),
                          );
                          return;
                        }
                        Navigator.pop(ctx);
                        try {
                          await _expenseService.addExpense(
                            tripId: widget.trip.id,
                            title: title,
                            amount: amount,
                            currency: currency,
                            category: selectedCategory,
                            paidBy: paidBy,
                            splitType: splitType,
                            splitAmongUserIds: widget.trip.memberIds,
                            notes: notesController.text.trim().isEmpty ? null : notesController.text.trim(),
                          );
                        } catch (e) {
                          if (mounted) {
                            ScaffoldMessenger.of(context).showSnackBar(
                              SnackBar(content: Text("Failed to add expense: $e")),
                            );
                          }
                        }
                      },
                      child: Text("Save Expense", style: GoogleFonts.inter(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 16)),
                    ),
                  ),
                ],
              ),
            ),
          );
        });
      },
    );
  }
}

class _ExportOptionTile extends StatelessWidget {
  final IconData icon;
  final Color color;
  final String title;
  final String subtitle;
  final VoidCallback onTap;

  const _ExportOptionTile({
    required this.icon,
    required this.color,
    required this.title,
    required this.subtitle,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final colors = context.appColors;
    return Material(
      color: colors.fieldFillBg,
      borderRadius: BorderRadius.circular(14),
      child: InkWell(
        borderRadius: BorderRadius.circular(14),
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
          child: Row(
            children: [
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: color.withOpacity(0.12),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Icon(icon, color: color, size: 24),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(title, style: GoogleFonts.inter(fontWeight: FontWeight.w600, fontSize: 14)),
                    const SizedBox(height: 2),
                    Text(subtitle,
                        style: GoogleFonts.inter(fontSize: 12, color: colors.textSecondary)),
                  ],
                ),
              ),
              Icon(Icons.chevron_right, color: colors.textMuted),
            ],
          ),
        ),
      ),
    );
  }
}
