import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import 'package:skeletonizer/skeletonizer.dart';
import 'package:cached_network_image/cached_network_image.dart';
import '../models/trip.dart';
import '../services/auth_service.dart';
import '../services/trip_service.dart';
import 'trip_dashboard_screen.dart';
import '../widgets/trip_card.dart';

class MyTripsScreen extends StatefulWidget {
  const MyTripsScreen({super.key});

  @override
  State<MyTripsScreen> createState() => _MyTripsScreenState();
}

class _MyTripsScreenState extends State<MyTripsScreen> with SingleTickerProviderStateMixin {
  late TabController _tabController;
  final TripService _tripService = TripService();

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final user = Provider.of<AuthService>(context).user;
    if (user == null) return const Center(child: CircularProgressIndicator());

    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        title: Text("My Trips", style: GoogleFonts.outfit(fontWeight: FontWeight.bold, color: Colors.black)),
        backgroundColor: Colors.white,
        elevation: 0,
        centerTitle: false,
        bottom: TabBar(
          controller: _tabController,
          labelColor: Colors.black,
          unselectedLabelColor: Colors.grey,
          indicatorColor: Colors.black,
          labelStyle: GoogleFonts.outfit(fontWeight: FontWeight.bold),
          tabs: const [
            Tab(text: "Hosted"),
            Tab(text: "Joined"),
          ],
        ),
      ),
      body: StreamBuilder<List<Trip>>(
        stream: _tripService.getUserTrips(user.id),
        builder: (context, snapshot) {
          final isLoading = snapshot.connectionState == ConnectionState.waiting;
          final allTrips = snapshot.data ?? [];
          
          if (isLoading) {
             return TabBarView(
               controller: _tabController,
               children: [
                  _buildSkeletonList(),
                  _buildSkeletonList(),
               ],
             );
          }

          final hosted = allTrips.where((t) => t.createdBy == user.id).toList();
          final joined = allTrips.where((t) => t.createdBy != user.id).toList();

          return TabBarView(
            controller: _tabController,
            children: [
               _buildTripList(hosted, "You haven't planned any trips yet."),
               _buildTripList(joined, "You haven't joined any trips yet."),
            ],
          );
        },
      ),
    );
  }

  Widget _buildTripList(List<Trip> trips, String emptyMessage) {
    if (trips.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.luggage_outlined, size: 64, color: Colors.grey.shade300),
            const SizedBox(height: 16),
            Text(emptyMessage, style: GoogleFonts.inter(color: Colors.grey.shade500), textAlign: TextAlign.center),
          ],
        ),
      );
    }

    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: trips.length,
      itemBuilder: (context, index) {
        final trip = trips[index];
        return TripCard(
          trip: trip,
          onTap: () => Navigator.push(
            context,
            MaterialPageRoute(builder: (_) => TripDashboardScreen(trip: trip)),
          ),
          showStatus: true,
        );
      },
    );
  }

  Widget _buildSkeletonList() {
    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: 3,
      itemBuilder: (context, index) {
        return Skeletonizer(
          enabled: true,
          child: Container(
            margin: const EdgeInsets.only(bottom: 12),
            height: 80,
            decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(16)),
            child: const ListTile(
               leading: CircleAvatar(),
               title: Text("Loading Trip..."),
               subtitle: Text("Loading Location..."),
            ),
          ),
        );
      },
    );
  }
}
