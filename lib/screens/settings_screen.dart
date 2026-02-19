import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:url_launcher/url_launcher.dart';
import '../services/auth_service.dart';
import 'privacy_policy_screen.dart';
import 'terms_conditions_screen.dart';
import 'privacy_settings_screen.dart';
import 'archived_posts_screen.dart';
import 'login_screen.dart';

class SettingsScreen extends StatelessWidget {
  const SettingsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final authService = Provider.of<AuthService>(context);

    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        scrolledUnderElevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.black87),
          onPressed: () => Navigator.pop(context),
        ),
        title: Text(
          "Settings", 
          style: GoogleFonts.outfit(color: Colors.black87, fontWeight: FontWeight.bold)
        ),
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          _buildSectionHeader("Support"),
          _buildSettingsItem(
            context,
            icon: Icons.feedback_outlined, 
            title: "Send Feedback", 
            onTap: _sendFeedback
          ),
          _buildSettingsItem(
            context,
            icon: Icons.privacy_tip_outlined, 
            title: "Privacy Policy", 
            onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const PrivacyPolicyScreen()))
          ),
          _buildSettingsItem(
            context,
            icon: Icons.description_outlined, 
            title: "Terms & Conditions", 
            onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const TermsConditionsScreen()))
          ),

          const SizedBox(height: 32),
          _buildSectionHeader("Privacy"),
          _buildSettingsItem(
            context,
            icon: Icons.archive_outlined, 
            title: "Archived Posts", 
            onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const ArchivedPostsScreen()))
          ),
          _buildSettingsItem(
            context,
            icon: Icons.lock_outline_rounded, 
            title: "Privacy Settings", 
            onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const PrivacySettingsScreen()))
          ),

          const SizedBox(height: 32),
          _buildSectionHeader("Account"),
          _buildSettingsItem(
            context,
            icon: Icons.logout, 
            title: "Log Out", 
            onTap: () async {
               // Confirm Dialog
               final confirm = await showDialog<bool>(
                 context: context,
                 builder: (ctx) => AlertDialog(
                   title: const Text("Log Out"),
                   content: const Text("Are you sure you want to log out?"),
                   actions: [
                     TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text("Cancel")),
                     TextButton(onPressed: () => Navigator.pop(ctx, true), child: const Text("Log Out", style: TextStyle(color: Colors.red))),
                   ],
                 )
               );

               if (confirm == true) {
                 Navigator.popUntil(context, (route) => route.isFirst);
                 await authService.signOut();
                 // AuthWrapper will handle the rest, but we can also push Login to be safe if needed
               }
            },
            isDestructive: true
          ),
          _buildSettingsItem(
            context,
            icon: Icons.delete_outline, 
            title: "Delete Account", 
            onTap: () {
              ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("Account deletion not implemented in beta.")));
            },
            isDestructive: true,
            showChevron: false
          ),
          
          const SizedBox(height: 48),
          Center(
            child: Column(
              children: [
                 Text("WanderWith v1.0.0", style: GoogleFonts.inter(color: Colors.grey.shade400, fontSize: 12)),
                 const SizedBox(height: 4),
                 Text("Made with ❤️ for Travelers", style: GoogleFonts.inter(color: Colors.grey.shade300, fontSize: 10)),
              ],
            ),
          )
        ],
      ),
    );
  }

  Widget _buildSectionHeader(String title) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8, left: 4),
      child: Text(
        title.toUpperCase(),
        style: GoogleFonts.inter(fontSize: 12, fontWeight: FontWeight.bold, color: Colors.grey.shade500, letterSpacing: 1.0),
      ),
    );
  }

  Widget _buildSettingsItem(BuildContext context, {required IconData icon, required String title, required VoidCallback onTap, bool isDestructive = false, bool showChevron = true}) {
    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      decoration: BoxDecoration(
        color: Colors.grey.shade50,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.grey.shade100),
      ),
      child: ListTile(
        onTap: onTap,
        leading: Icon(icon, color: isDestructive ? Colors.redAccent : Colors.black87, size: 22),
        title: Text(
          title,
          style: GoogleFonts.inter(
            fontWeight: FontWeight.w500,
            color: isDestructive ? Colors.redAccent : Colors.black87
          ),
        ),
        trailing: showChevron ? Icon(Icons.chevron_right, size: 18, color: Colors.grey.shade400) : null,
      ),
    );
  }

  void _sendFeedback() async {
     final Uri emailLaunchUri = Uri(
       scheme: 'mailto',
       path: 'feedback@tejuice.fun',
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
