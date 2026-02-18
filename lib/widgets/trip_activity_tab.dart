import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';
import '../services/trip_service.dart';

class TripActivityTab extends StatelessWidget {
  final String tripId;
  const TripActivityTab({super.key, required this.tripId});

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<List<Map<String, dynamic>>>(
      stream: TripService().getTripActivityStream(tripId),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        }
        final activities = snapshot.data ?? [];
        if (activities.isEmpty) {
          return Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(Icons.history_rounded, size: 48, color: Colors.grey.shade300),
                const SizedBox(height: 16),
                Text("No activities yet.", style: GoogleFonts.inter(color: Colors.grey)),
                const SizedBox(height: 12),
                Text("Things like new members, dates, and budget changes will appear here.", 
                  textAlign: TextAlign.center,
                  style: GoogleFonts.inter(color: Colors.grey.shade400, fontSize: 12)),
              ],
            ),
          );
        }

        return ListView.builder(
          padding: const EdgeInsets.all(16),
          itemCount: activities.length,
          itemBuilder: (context, index) {
            final activity = activities[index];
            return Card(
              margin: const EdgeInsets.only(bottom: 12),
              elevation: 0,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12), 
                side: BorderSide(color: Colors.grey.shade100)
              ),
              child: ListTile(
                leading: _buildActivityIcon(activity['type']),
                title: Text(activity['content'], style: GoogleFonts.inter(fontSize: 14)),
                subtitle: Text(
                  DateFormat('MMM d, h:mm a').format(DateTime.parse(activity['created_at'])),
                  style: GoogleFonts.inter(fontSize: 12, color: Colors.grey),
                ),
              ),
            );
          },
        );
      },
    );
  }

  Widget _buildActivityIcon(String type) {
    switch (type) {
      case 'member_joined': return const CircleAvatar(backgroundColor: Colors.blue, child: Icon(Icons.person_add, color: Colors.white, size: 16));
      case 'budget_updated': return const CircleAvatar(backgroundColor: Colors.green, child: Icon(Icons.attach_money, color: Colors.white, size: 16));
      case 'date_updated': return const CircleAvatar(backgroundColor: Colors.orange, child: Icon(Icons.calendar_today, color: Colors.white, size: 16));
      case 'poll_created': return const CircleAvatar(backgroundColor: Colors.purple, child: Icon(Icons.how_to_vote, color: Colors.white, size: 16));
      case 'link_added': return const CircleAvatar(backgroundColor: Colors.cyan, child: Icon(Icons.link, color: Colors.white, size: 16));
      case 'place_added': return const CircleAvatar(backgroundColor: Colors.teal, child: Icon(Icons.place, color: Colors.white, size: 16));
      default: return const CircleAvatar(backgroundColor: Colors.grey, child: Icon(Icons.info, color: Colors.white, size: 16));
    }
  }
}
