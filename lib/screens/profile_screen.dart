import 'dart:io';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:image_picker/image_picker.dart';
import 'package:cached_network_image/cached_network_image.dart';
import '../services/auth_service.dart';
import '../services/trip_service.dart';
import '../models/trip.dart';
import 'trip_dashboard_screen.dart';
import 'privacy_policy_screen.dart';
import 'terms_conditions_screen.dart';
import 'package:skeletonizer/skeletonizer.dart';
import 'package:url_launcher/url_launcher.dart';

class ProfileScreen extends StatefulWidget {
  const ProfileScreen({super.key});

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  final TripService _tripService = TripService();

  @override
  Widget build(BuildContext context) {
    final authService = Provider.of<AuthService>(context);
    final user = authService.user;
    final profile = authService.userProfile;

    if (user == null) return const Center(child: CircularProgressIndicator());

    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        title: const Text("Profile", style: TextStyle(fontWeight: FontWeight.bold)),
        backgroundColor: Colors.white,
        elevation: 0,
        centerTitle: true,
      ),
      body: RefreshIndicator(
        onRefresh: () async {
          await authService.refreshProfile();
          setState(() {});
        },
        child: StreamBuilder<List<Trip>>(
          stream: _tripService.getUserTrips(user.id),
          builder: (context, snapshot) {
            final isLoading = !snapshot.hasData;
            final allTrips = snapshot.data ?? [];
            final hosted = allTrips.where((t) => t.createdBy == user.id).toList();
            final joined = allTrips.where((t) => t.createdBy != user.id).toList();
        
            return SingleChildScrollView(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              physics: const AlwaysScrollableScrollPhysics(),
              child: Column(
                children: [
                  // 1. Profile Header
                  _buildHeader(context, authService, user, profile),
                  
                  const SizedBox(height: 24),
        
                  // 2. Quick Stats Row
                  _buildQuickStats(profile, hosted.length, joined.length),
        
                  const SizedBox(height: 24),
                  const Divider(height: 1),
                  const SizedBox(height: 24),
        
                  // 3. My Trips Sections (Collapsible / Separated)
                  if (isLoading)
                     const Skeletonizer(enabled: true, child: SizedBox(height: 200, width: double.infinity, child: Card()))
                  else
                     Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        _buildTripSectionHeader("Hosted Trips", hosted.length),
                        const SizedBox(height: 12),
                        if (hosted.isEmpty)
                          _buildEmptyState("You haven't hosted any trips yet")
                        else
                          ...hosted.map((t) => _buildCompactTripCard(context, t)),
                          
                        const SizedBox(height: 24),
                        
                        _buildTripSectionHeader("Joined Trips", joined.length),
                        const SizedBox(height: 12),
                        if (joined.isEmpty)
                          _buildEmptyState("You haven't joined any trips yet")
                        else
                          ...joined.map((t) => _buildCompactTripCard(context, t)),
                      ],
                     ),
        
                  const SizedBox(height: 32),
                  const Divider(height: 1),
                  const SizedBox(height: 24),
                  
                  // 4. App & Support
                  const Align(alignment: Alignment.centerLeft, child: Text("App & Support", style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold, color: Colors.grey))),
                  const SizedBox(height: 8),
                  
                  _buildSettingsItem(Icons.feedback_outlined, "Send Feedback", onTap: _sendFeedback),
                  _buildSettingsItem(Icons.privacy_tip_outlined, "Privacy Policy", onTap: () {
                    Navigator.push(context, MaterialPageRoute(builder: (_) => const PrivacyPolicyScreen()));
                  }),
                  _buildSettingsItem(Icons.description_outlined, "Terms & Conditions", onTap: () {
                    Navigator.push(context, MaterialPageRoute(builder: (_) => const TermsConditionsScreen()));
                  }),
                  _buildSettingsItem(Icons.logout, "Logout", onTap: () async {
                       // Pop first to prevent context issues after sign out
                       Navigator.popUntil(context, (route) => route.isFirst);
                       await authService.signOut();
                    }, 
                    isDestructive: true
                  ),
                  
                  const SizedBox(height: 48),
                  // 5. Footer
                  Column(
                    children: [
                      Text("WanderWith • Beta", style: TextStyle(fontWeight: FontWeight.bold, color: Colors.grey.shade400)),
                      Text("v1.0.0", style: TextStyle(color: Colors.grey.shade400, fontSize: 12)),
                    ],
                  ),
                  const SizedBox(height: 32),
                ],
              ),
            );
          }
        ),
      ),
    );
  }

  Widget _buildHeader(BuildContext context, AuthService auth, User user, dynamic profile) {
     final name = profile?.displayName ?? "Traveler";
     final country = profile?.country ?? "World Citizen";
     final email = user.email ?? "";
     final avatarUrl = profile?.avatarUrl;

     return Column(
       children: [
         Stack(
           children: [
             GestureDetector(
               onTap: () => _showAvatarOptions(context, auth),
               child: Container(
                 decoration: BoxDecoration(
                   shape: BoxShape.circle,
                   border: Border.all(color: Colors.grey.shade200, width: 2),
                 ),
                 child: CircleAvatar(
                   radius: 46,
                   backgroundColor: Colors.blue.shade50,
                   backgroundImage: (avatarUrl != null && avatarUrl.isNotEmpty) 
                      ? CachedNetworkImageProvider(avatarUrl) 
                      : null,
                   child: (avatarUrl == null || avatarUrl.isEmpty) 
                      ? Text(name.isNotEmpty ? name[0].toUpperCase() : "T", 
                          style: TextStyle(fontSize: 32, color: Colors.blueAccent.shade200, fontWeight: FontWeight.bold))
                      : null,
                 ),
               ),
             ),
             Positioned(
               bottom: 0,
               right: 4,
               child: Container(
                 padding: const EdgeInsets.all(6),
                 decoration: const BoxDecoration(
                   color: Colors.blueAccent,
                   shape: BoxShape.circle,
                 ),
                 child: const Icon(Icons.camera_alt, color: Colors.white, size: 16),
               ),
             )
           ],
         ),
         const SizedBox(height: 16),
         Text(name, style: const TextStyle(fontSize: 22, fontWeight: FontWeight.bold)),
         const SizedBox(height: 4),
         Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
               const Icon(Icons.location_on, size: 14, color: Colors.grey),
               Text(" $country", style: TextStyle(color: Colors.grey.shade700, fontSize: 14)),
            ]
         ),
         const SizedBox(height: 4),
         Text(email, style: TextStyle(color: Colors.grey.shade500, fontSize: 13)),
         const SizedBox(height: 16),
         
         TextButton.icon(
            onPressed: () => _showEditProfile(context, profile),
            icon: const Icon(Icons.edit, size: 16),
            label: const Text("Edit Profile"),
            style: TextButton.styleFrom(
              foregroundColor: Colors.blueAccent,
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              backgroundColor: Colors.blueAccent.withOpacity(0.1),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20))
            ),
         )
       ],
     );
  }

  Widget _buildQuickStats(dynamic profile, int hostedCount, int joinedCount) {
    final style = profile?.budgetStyle ?? "Style?";
    final vibe = profile?.tripVibe ?? "Vibe?";

    // Using Chip-like layout for a single row
    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
           _buildPill(Icons.wallet, style),
           const SizedBox(width: 8),
           _buildPill(Icons.local_fire_department, vibe),
           const SizedBox(width: 8),
           _buildPill(Icons.map, "$hostedCount Hosted"),
           const SizedBox(width: 8),
           _buildPill(Icons.group, "$joinedCount Joined"),
        ],
      ),
    );
  }

  Widget _buildPill(IconData icon, String label) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        color: Colors.grey.shade100,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: Colors.grey.shade200)
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 14, color: Colors.grey.shade700),
          const SizedBox(width: 6),
          Text(label, style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: Colors.grey.shade800)),
        ],
      ),
    );
  }
  
  Widget _buildTripSectionHeader(String title, int count) {
    return Row(
      children: [
        Text(title, style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
        const SizedBox(width: 8),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
          decoration: BoxDecoration(
            color: Colors.grey.shade200,
            borderRadius: BorderRadius.circular(10)
          ),
          child: Text("$count", style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: Colors.grey.shade700)),
        ),
      ],
    );
  }

  Widget _buildCompactTripCard(BuildContext context, Trip trip) {
    Color statusColor = Colors.orange;
    String statusText = "Planning"; // Default
    
    if (trip.status == 'completed') {
      statusColor = Colors.grey;
      statusText = "Completed";
    } else if (trip.status == 'confirmed') {
      statusColor = Colors.green;
      statusText = "Confirmed";
    }

    return GestureDetector(
      onTap: () {
         Navigator.push(context, MaterialPageRoute(builder: (_) => TripDashboardScreen(trip: trip)));
      },
      child: Container(
        margin: const EdgeInsets.only(bottom: 12),
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: Colors.grey.shade200),
          boxShadow: [
             BoxShadow(color: Colors.black.withOpacity(0.02), blurRadius: 4, offset: const Offset(0, 2))
          ]
        ),
        child: Row(
          children: [
            Container(
              height: 48, width: 48,
              decoration: BoxDecoration(
                 color: statusColor.withOpacity(0.1),
                 borderRadius: BorderRadius.circular(8),
              ),
              child: Center(child: Icon(Icons.flight_takeoff, color: statusColor)),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                   Text(trip.name, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14)),
                   const SizedBox(height: 4),
                   Text("📍 ${trip.location} • ${trip.memberIds.length} members", 
                     style: TextStyle(fontSize: 12, color: Colors.grey.shade600), maxLines: 1, overflow: TextOverflow.ellipsis),
                ],
              ),
            ),
            Container(
               padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
               decoration: BoxDecoration(
                 color: statusColor.withOpacity(0.1),
                 borderRadius: BorderRadius.circular(4),
               ),
               child: Text(statusText, style: TextStyle(fontSize: 10, color: statusColor, fontWeight: FontWeight.bold))
            )
          ],
        ),
      ),
    );
  }

  Widget _buildEmptyState(String msg) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(vertical: 24),
      decoration: BoxDecoration(
         color: Colors.grey.shade50,
         borderRadius: BorderRadius.circular(12),
         border: Border.all(color: Colors.grey.shade200, style: BorderStyle.none) // subtle
      ),
      child: Text(msg, textAlign: TextAlign.center, style: TextStyle(color: Colors.grey.shade500, fontSize: 13, fontStyle: FontStyle.italic)),
    );
  }
  
  Widget _buildSettingsItem(IconData icon, String title, {required VoidCallback onTap, bool isDestructive = false}) {
     return ListTile(
       contentPadding: EdgeInsets.zero,
       dense: true,
       leading: Container(
         padding: const EdgeInsets.all(8),
         decoration: BoxDecoration(color: Colors.grey.shade50, borderRadius: BorderRadius.circular(8)),
         child: Icon(icon, color: isDestructive ? Colors.redAccent : Colors.grey.shade700, size: 18),
       ),
       title: Text(title, style: TextStyle(
          fontWeight: FontWeight.w500, 
          color: isDestructive ? Colors.redAccent : Colors.black87
       )),
       trailing: const Icon(Icons.chevron_right, size: 16, color: Colors.grey),
       onTap: onTap,
     );
  }
  
  void _showAvatarOptions(BuildContext context, AuthService auth) {
     showModalBottomSheet(
        context: context,
        shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(20))),
        builder: (ctx) => SafeArea(
          child: Wrap(
            children: [
               ListTile(
                 leading: const Icon(Icons.camera_alt),
                 title: const Text('Take a photo'),
                 onTap: () {
                    Navigator.pop(ctx);
                    _pickImage(auth, ImageSource.camera);
                 }
               ),
               ListTile(
                 leading: const Icon(Icons.photo_library),
                 title: const Text('Choose from gallery'),
                 onTap: () {
                    Navigator.pop(ctx);
                    _pickImage(auth, ImageSource.gallery);
                 },
               ),
            ],
          ),
        )
     );
  }

  Future<void> _pickImage(AuthService auth, ImageSource source) async {
     final picker = ImagePicker();
     final pickedFile = await picker.pickImage(source: source, imageQuality: 70, maxWidth: 800);
     
     if (pickedFile != null && mounted) {
        // Show loading toast or indicator?
        ScaffoldMessenger.of(context).showSnackBar(
           const SnackBar(content: Text('Updating profile picture...'), duration: Duration(seconds: 1))
        );
        
        try {
           await auth.updateAvatar(File(pickedFile.path));
           if (mounted) {
              ScaffoldMessenger.of(context).showSnackBar(
                 const SnackBar(content: Text('Profile picture updated!'), backgroundColor: Colors.green)
              );
           }
        } catch (e) {
           if (mounted) {
              ScaffoldMessenger.of(context).showSnackBar(
                 SnackBar(content: Text('Failed to update: $e'), backgroundColor: Colors.red)
              );
           }
        }
     }
  }

  void _showEditProfile(BuildContext context, dynamic profile) {
     final cName = TextEditingController(text: profile?.displayName);
     final cCountry = TextEditingController(text: profile?.country);
     String? selectedStyle = profile?.budgetStyle;
     String? selectedVibe = profile?.tripVibe;

     const styles = ["Budget", "Mid-Range", "Luxury"];
     const vibes = ["Chill", "Adventure", "Party", "Cultural", "Foodie"];
     
     bool isSaving = false;

     showDialog(
       context: context, 
       barrierDismissible: false,
       builder: (ctx) => StatefulBuilder(
         builder: (context, setState) {
           return AlertDialog(
             shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
             title: const Text("Edit Profile"),
             content: SingleChildScrollView(
               child: Column(
                 mainAxisSize: MainAxisSize.min,
                 children: [
                   TextField(controller: cName, decoration: const InputDecoration(labelText: "Display Name", prefixIcon: Icon(Icons.person), filled: true, fillColor: Colors.white)),
                   const SizedBox(height: 12),
                   TextField(controller: cCountry, decoration: const InputDecoration(labelText: "Country", prefixIcon: Icon(Icons.map), filled: true, fillColor: Colors.white)),
                   const SizedBox(height: 12),
                   DropdownButtonFormField<String>(
                     value: styles.contains(selectedStyle) ? selectedStyle : null,
                     decoration: const InputDecoration(labelText: "Travel Style", prefixIcon: Icon(Icons.wallet_travel), filled: true, fillColor: Colors.white),
                     items: styles.map((s) => DropdownMenuItem(value: s, child: Text(s))).toList(),
                     onChanged: (val) => setState(() => selectedStyle = val),
                   ),
                   const SizedBox(height: 12),
                   DropdownButtonFormField<String>(
                     value: vibes.contains(selectedVibe) ? selectedVibe : null,
                     decoration: const InputDecoration(labelText: "Travel Vibe", prefixIcon: Icon(Icons.local_fire_department), filled: true, fillColor: Colors.white),
                     items: vibes.map((v) => DropdownMenuItem(value: v, child: Text(v))).toList(),
                     onChanged: (val) => setState(() => selectedVibe = val),
                   )
                 ],
               ),
             ),
             actions: [
                if (!isSaving)
                   TextButton(onPressed: () => Navigator.pop(ctx), child: const Text("Cancel")),
                
                ElevatedButton(
                  onPressed: isSaving ? null : () async {
                     setState(() => isSaving = true);
                     
                     final user = Supabase.instance.client.auth.currentUser;
                     if (user != null) {
                        try {
                           await Supabase.instance.client.from('profiles').update({
                              'display_name': cName.text,
                              'country': cCountry.text,
                              'budget_style': selectedStyle,
                              'trip_vibe': selectedVibe,
                           }).eq('id', user.id);
                           
                           if (context.mounted) {
                              await Provider.of<AuthService>(context, listen: false).refreshProfile();
                           }
                           
                           if (ctx.mounted) Navigator.pop(ctx);
                        } catch (e) {
                           setState(() => isSaving = false);
                        }
                     }
                  }, 
                  child: isSaving 
                    ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white)) 
                    : const Text("Save")
                )
             ],
           );
         }
       )
     );
  }
  
  void _sendFeedback() async {
     final Uri emailLaunchUri = Uri(
       scheme: 'mailto',
       path: 'feedback@wanderwith.app',
       queryParameters: {
         'subject': 'WanderWith Feedback'
       },
     );
     try {
       await launchUrl(emailLaunchUri);
     } catch (e) {
       // ignore
     }
  }
}
