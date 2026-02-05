import 'package:flutter/material.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:provider/provider.dart';
import 'package:skeletonizer/skeletonizer.dart';
import 'package:intl/intl.dart';
import 'package:connectivity_plus/connectivity_plus.dart';
import '../services/auth_service.dart';
import '../services/trip_service.dart';
import '../services/notification_service.dart';
import '../models/trip.dart';
import 'profile_screen.dart';
import 'create_trip_screen.dart';
import 'trip_dashboard_screen.dart';
import 'notifications_screen.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  // Listen for Connectivity Changes
  @override
  void initState() {
     super.initState();
     // Request notification permissions on Android 13+
     _requestPermissions();
  }

  void _requestPermissions() async {
     await Future.delayed(const Duration(seconds: 2));
     final flutterLocalNotificationsPlugin = FlutterLocalNotificationsPlugin();
     final android = flutterLocalNotificationsPlugin.resolvePlatformSpecificImplementation<AndroidFlutterLocalNotificationsPlugin>();
     if (android != null) {
        await android.requestNotificationsPermission();
     }
  }

  Future<void> _refresh() async {
    setState(() {});
    await Future.delayed(const Duration(milliseconds: 500));
  }

  @override
  Widget build(BuildContext context) {
    final authService = Provider.of<AuthService>(context);
    // userProfile is not guaranteed to be non-null immediately, but user object usually is if logged in
    final user = authService.user;
    final userProfile = authService.userProfile;
    final tripService = TripService();

    // Determine current user ID safely
    final uid = user?.id;

    if (uid == null) {
      // If no user ID, show loading or simple unauthorized view
      return const Scaffold(
        body: Center(child: CircularProgressIndicator()),
      );
    }

    return Scaffold(
      appBar: AppBar(
        title: Row(
          children: [
            ClipRRect(
              borderRadius: BorderRadius.circular(8),
              child: Image.asset('android/assets/logo.png', height: 32, width: 32),
            ),
            const SizedBox(width: 8),
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text("WanderWith", style: TextStyle(fontWeight: FontWeight.bold, fontSize: 20)),
                // Text("by WanderWith", style: TextStyle(fontSize: 10, color: Colors.grey)), 
              ],
            ),
          ],
        ),
        actions: [
          // Notification Bell
          StreamBuilder<int>(
            stream: NotificationService().getUnreadCountStream(),
            builder: (context, snapshot) {
              final count = snapshot.data ?? 0;
              return Stack(
                children: [
                   IconButton(
                     icon: const Icon(Icons.notifications_outlined),
                     onPressed: () {
                        Navigator.push(context, MaterialPageRoute(builder: (_) => const NotificationsScreen()));
                     },
                   ),
                   if (count > 0)
                     Positioned(
                       right: 8,
                       top: 8,
                       child: Container(
                         padding: const EdgeInsets.all(2),
                         decoration: BoxDecoration(color: Colors.red, borderRadius: BorderRadius.circular(6)),
                         constraints: const BoxConstraints(minWidth: 14, minHeight: 14),
                         child: Text('$count', style: const TextStyle(color: Colors.white, fontSize: 8), textAlign: TextAlign.center),
                       ),
                     )
                ],
              );
            },
          ),
          // Profile Action
          Padding(
            padding: const EdgeInsets.only(right: 12.0),
            child: GestureDetector(
               onTap: () {
                  Navigator.push(context, MaterialPageRoute(builder: (_) => const ProfileScreen()));
               },
               child: CircleAvatar(
                 radius: 16,
                 backgroundColor: Colors.blueAccent.shade100,
                 backgroundImage: (userProfile?.avatarUrl != null && userProfile!.avatarUrl!.isNotEmpty)
                     ? NetworkImage(userProfile!.avatarUrl!)
                     : null,
                 child: (userProfile?.avatarUrl != null && userProfile!.avatarUrl!.isNotEmpty)
                     ? null
                     : Text(
                         (userProfile?.displayName?.isNotEmpty == true) 
                           ? userProfile!.displayName![0].toUpperCase() 
                           : "U",
                         style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
                       ),
               ),
            ),
          ),
        ],
      ),
      body: Column(
        children: [
          // Connectivity Banner
          StreamBuilder<ConnectivityResult>(
            stream: Connectivity().onConnectivityChanged,
            builder: (context, snapshot) {
              if (snapshot.hasData && snapshot.data == ConnectivityResult.none) {
                return Container(
                  width: double.infinity,
                  color: Colors.redAccent,
                  padding: const EdgeInsets.all(8),
                  child: const Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(Icons.wifi_off, color: Colors.white, size: 16),
                      SizedBox(width: 8),
                      Text(
                        "You are offline. Showing cached data.",
                        style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
                      ),
                    ],
                  ),
                );
              }
              return const SizedBox.shrink();
            },
          ),
          Expanded(
            child: RefreshIndicator(
              onRefresh: _refresh,
              child: StreamBuilder<List<Trip>>(
                stream: tripService.getUserTrips(uid),
                builder: (context, snapshot) {
                // SKELETON LOADING STATE
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return Skeletonizer(
                    enabled: true,
                    child: _buildTripList(context, [
                      // Fake trips for skeleton structure
                      Trip(id: '1', name: 'Loading Trip 1', location: 'Nowhere', createdBy: '', memberIds: []),
                      Trip(id: '2', name: 'Loading Trip 2', location: 'Nowhere', createdBy: '', memberIds: []),
                    ]),
                  );
                }

                // EMPTY STATE
                if (!snapshot.hasData || snapshot.data!.isEmpty) {
                  return ListView(
                    physics: const AlwaysScrollableScrollPhysics(),
                    children: [
                       SizedBox(height: MediaQuery.of(context).size.height * 0.3),
                       Center(
                        child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        const Icon(Icons.flight_outlined, size: 64, color: Colors.grey),
                        const SizedBox(height: 16),
                        const Text("No trips yet. Time to plan one!"),
                        const SizedBox(height: 24),
                        Row(
                           mainAxisSize: MainAxisSize.min,
                           children: [
                              ElevatedButton(
                                 onPressed: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const CreateTripScreen())),
                                 child: const Text("Create First Trip"),
                              ),
                              const SizedBox(width: 12),
                              OutlinedButton(
                                 onPressed: () => _showJoinTripDialog(context, uid),
                                 child: const Text("Join Trip"),
                              ),
                           ],
                        )
                      ],
                    ),
                   ),
                  ],
                 );
                }


                // DATA STATE
                final trips = snapshot.data!;
                final now = DateTime.now();
                // Filter Categories
                
                // Ongoing: Started but not Ended
                final ongoing = trips.where((t) {
                   if (!t.isDateDecided || t.startDate == null || t.endDate == null) return false;
                   // Use DateUtils or simple comparison to check if Today is between Start and End
                   // Strip time for better comparison if needed, but simple comparison works for broad strokes
                   return t.startDate!.isBefore(now.add(const Duration(days: 1))) && t.endDate!.isAfter(now.subtract(const Duration(days: 1)));
                }).toList();

                // Upcoming: Starts in Future OR Undecided dates
                final upcoming = trips.where((t) {
                   // Exclude if already in Ongoing
                   if (ongoing.contains(t)) return false;

                   if (!t.isDateDecided || t.startDate == null) return true; // TBD is upcoming
                   return t.startDate!.isAfter(now);
                }).toList();
                
                // Past: Ended in Past
                final past = trips.where((t) {
                   // Exclude if already in Ongoing
                   if (ongoing.contains(t)) return false;

                   if (!t.isDateDecided || t.endDate == null) return false;
                   return t.endDate!.isBefore(now);
                }).toList();

                return SingleChildScrollView(
                    physics: const AlwaysScrollableScrollPhysics(),
                    padding: const EdgeInsets.all(16),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // Action Buttons
                        Row(
                          children: [
                            Expanded(
                              child: ElevatedButton.icon(
                                onPressed: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const CreateTripScreen())),
                                icon: const Icon(Icons.add),
                                label: const Text("New Trip"),
                                style: ElevatedButton.styleFrom(
                                  padding: const EdgeInsets.symmetric(vertical: 12),
                                  backgroundColor: Colors.blueAccent,
                                  foregroundColor: Colors.white,
                                ),
                              ),
                            ),
                            const SizedBox(width: 16),
                            Expanded(
                              child: OutlinedButton.icon(
                                onPressed: () => _showJoinTripDialog(context, uid),
                                icon: const Icon(Icons.link),
                                label: const Text("Join Trip"),
                                style: OutlinedButton.styleFrom(
                                  padding: const EdgeInsets.symmetric(vertical: 12),
                                ),
                              ),
                            ),
                          ],
                        ),
                        
                        const SizedBox(height: 24),
                        
                        // ONGOING SECTION
                        if (ongoing.isNotEmpty) ...[
                          const Row(
                            children: [
                              Icon(Icons.directions_run, color: Colors.green),
                              SizedBox(width: 8),
                              Text("Ongoing Trips 🚀", style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.green)),
                            ],
                          ),
                          const SizedBox(height: 12),
                          _buildTripList(context, ongoing, isOngoing: true),
                          const SizedBox(height: 24),
                        ],
                        
                        // UPCOMING SECTION
                        if (upcoming.isNotEmpty) ...[
                          const Row(
                            children: [
                              Icon(Icons.calendar_month, color: Colors.blueAccent),
                              SizedBox(width: 8),
                              Text("Upcoming Trips 📅", style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.blueAccent)),
                            ],
                          ),
                          const SizedBox(height: 12),
                          _buildTripList(context, upcoming),
                          const SizedBox(height: 24),
                        ],
                        
                        // PAST SECTION
                        if (past.isNotEmpty) ...[
                          const Row(
                            children: [
                              Icon(Icons.history, color: Colors.grey),
                              SizedBox(width: 8),
                              Text("Past Adventures 🏁", style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.grey)),
                            ],
                          ),
                          const SizedBox(height: 12),
                          _buildTripList(context, past, isPast: true),
                        ],
                      ],
                    ),
                  );
              },
            ),
          ),
          )
        ],
      ),
    );
  }

  Widget _buildTripList(BuildContext context, List<Trip> trips, {bool isOngoing = false, bool isPast = false}) {
    return Column(
      children: trips.map((trip) => Card(
        margin: const EdgeInsets.only(bottom: 12),
        elevation: 2,
        color: isOngoing ? Colors.green.shade50 : (isPast ? Colors.grey.shade100 : Colors.white),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12), side: isOngoing ? const BorderSide(color: Colors.green, width: 2) : BorderSide.none),
        child: ListTile(
          contentPadding: const EdgeInsets.all(16),
          leading: Container(
            height: 50, width: 50,
            decoration: BoxDecoration(
              color: isOngoing ? Colors.green.shade100 : (isPast ? Colors.grey.shade300 : Colors.blueAccent.shade100),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Icon(
              isOngoing ? Icons.flight_takeoff : (isPast ? Icons.photo_album : Icons.map),
              color: isOngoing ? Colors.green.shade800 : (isPast ? Colors.grey.shade700 : Colors.blueAccent),
            ),
          ),
          title: Text(trip.name, style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16, decoration: isPast ? TextDecoration.lineThrough : null, color: isPast ? Colors.grey : null)),
          subtitle: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const SizedBox(height: 4),
              Row(
                children: [
                  Icon(Icons.location_on, size: 14, color: isPast ? Colors.grey : Colors.blueGrey),
                  const SizedBox(width: 4),
                  Text(trip.location, style: TextStyle(color: isPast ? Colors.grey : null)),
                ],
              ),
              const SizedBox(height: 4),
              Text(
                (trip.isDateDecided && trip.startDate != null)
                   ? "${DateFormat('MMM d').format(trip.startDate!)} - ${DateFormat('MMM d').format(trip.endDate!)}"
                   : "Dates TBD ⏳",
                style: const TextStyle(fontSize: 12, color: Colors.grey),
              ),
            ],
          ),
          onTap: () {
            Navigator.push(context, MaterialPageRoute(builder: (_) => TripDashboardScreen(trip: trip)));
          },
        ),
      )).toList(),
    );
  }

  void _showJoinTripDialog(BuildContext context, String uid) {
    final TextEditingController _idController = TextEditingController();
    bool _isLoading = false;

    showDialog(
      context: context, 
      builder: (ctx) => StatefulBuilder(
        builder: (context, setDialogState) {
          return AlertDialog(
            title: const Text("Join a Trip"),
            content: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Text("Paste the Trip ID shared by your friend."),
                const SizedBox(height: 16),
                TextField(
                  controller: _idController,
                  decoration: const InputDecoration(
                    labelText: "Trip ID",
                    border: OutlineInputBorder(),
                  ),
                ),
                if (_isLoading) ...[
                   const SizedBox(height: 16),
                   const CircularProgressIndicator(),
                ]
              ],
            ),
            actions: [
              TextButton(onPressed: () => Navigator.pop(context), child: const Text("Cancel")),
              ElevatedButton(
                onPressed: _isLoading ? null : () async {
                   final tripId = _idController.text.trim();
                   if (tripId.isEmpty) return;

                   setDialogState(() => _isLoading = true);
                   try {
                      await TripService().joinTrip(tripId, uid);
                      if (context.mounted) {
                        Navigator.pop(context);
                        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("Joined trip successfully! 🎉")));
                      }
                   } catch (e) {
                      if (context.mounted) {
                         ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text("Error: ${e.toString()}")));
                      }
                   } finally {
                      if (context.mounted) {
                        setDialogState(() => _isLoading = false);
                      }
                   }
                }, 
                child: const Text("Join")
              ),
            ],
          );
        }
      )
    );
  }
}
