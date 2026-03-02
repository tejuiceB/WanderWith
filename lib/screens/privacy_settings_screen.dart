import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:google_fonts/google_fonts.dart';
import '../services/auth_service.dart';
import 'blocked_users_screen.dart';
import 'restricted_users_screen.dart';
import '../theme/theme_extensions.dart';

class PrivacySettingsScreen extends StatefulWidget {
  const PrivacySettingsScreen({super.key});

  @override
  State<PrivacySettingsScreen> createState() => _PrivacySettingsScreenState();
}

class _PrivacySettingsScreenState extends State<PrivacySettingsScreen> {
  bool _isLoading = false;

  @override
  Widget build(BuildContext context) {
    final authService = Provider.of<AuthService>(context);
    final user = authService.userProfile;

    if (user == null) {
       return const Scaffold(body: Center(child: CircularProgressIndicator()));
    }

    return Scaffold(
      backgroundColor: context.appColors.scaffoldBg,
      appBar: AppBar(
        backgroundColor: context.appColors.scaffoldBg,
        elevation: 0,
        scrolledUnderElevation: 0,
        leading: IconButton(
          icon: Icon(Icons.arrow_back, color: context.appColors.textPrimary),
          onPressed: () => Navigator.pop(context),
        ),
        title: Text(
          "Privacy Settings", 
          style: GoogleFonts.outfit(color: context.appColors.textPrimary, fontWeight: FontWeight.bold)
        ),
      ),
      body: Stack(
        children: [
          ListView(
            padding: const EdgeInsets.all(24),
            children: [
               _buildSectionHeader("Account Privacy"),
               _buildSwitchTile(
                 title: "Private Account",
                 subtitle: "When your account is private, only people you approve can see your posts and trips.",
                 value: user.isPrivate,
                 onChanged: (val) => _updateSetting(authService, isPrivate: val),
               ),
               
               const SizedBox(height: 32),
               _buildSectionHeader("Content Visibility"),
               _buildDropdownTile(
                 title: "Who can see my posts?",
                 value: user.postVisibility,
                 items: const [
                   DropdownMenuItem(value: 'public', child: Text("Public")),
                   DropdownMenuItem(value: 'followers', child: Text("Followers Only")),
                 ],
                 onChanged: (val) => _updateSetting(authService, postVisibility: val),
               ),
               _buildDropdownTile(
                 title: "Who can see my trips?",
                 value: user.tripsVisibility,
                 items: const [
                   DropdownMenuItem(value: 'public', child: Text("Everyone")),
                   DropdownMenuItem(value: 'followers', child: Text("Followers Only")),
                   DropdownMenuItem(value: 'private', child: Text("Only Me")),
                 ],
                 onChanged: (val) => _updateSetting(authService, tripsVisibility: val),
               ),
               _buildDropdownTile(
                 title: "Who can see my travel mood?",
                 value: user.travelMoodVisibility,
                 items: const [
                   DropdownMenuItem(value: 'public', child: Text("Public")),
                   DropdownMenuItem(value: 'followers', child: Text("Followers Only")),
                   DropdownMenuItem(value: 'nobody', child: Text("Nobody")),
                 ],
                 onChanged: (val) => _updateSetting(authService, travelMoodVisibility: val),
               ),
               _buildDropdownTile(
                 title: "Who can see my badges?",
                 value: user.badgesVisibility,
                 items: const [
                   DropdownMenuItem(value: 'public', child: Text("Public")),
                   DropdownMenuItem(value: 'followers', child: Text("Followers Only")),
                   DropdownMenuItem(value: 'nobody', child: Text("Nobody")),
                 ],
                 onChanged: (val) => _updateSetting(authService, badgesVisibility: val),
               ),

               const SizedBox(height: 32),
               _buildSectionHeader("Interactions"),
               _buildSwitchTile(
                 title: "Allow follow requests",
                 subtitle: "If disabled, no one will be able to send you new follow requests.",
                 value: user.allowFollowRequests,
                 onChanged: (val) => _updateSetting(authService, allowFollowRequests: val),
               ),
               _buildDropdownTile(
                 title: "Who can message me?",
                 value: user.messagePrivacy,
                 items: const [
                   DropdownMenuItem(value: 'everyone', child: Text("Everyone")),
                   DropdownMenuItem(value: 'followers', child: Text("Followers Only")),
                   DropdownMenuItem(value: 'nobody', child: Text("Nobody")),
                 ],
                 onChanged: (val) => _updateSetting(authService, messagePrivacy: val),
               ),

               const SizedBox(height: 32),
               _buildSectionHeader("Content Controls"),
               _buildDropdownTile(
                 title: "Who can comment on my posts?",
                 value: user.commentPrivacy,
                 items: const [
                   DropdownMenuItem(value: 'everyone', child: Text("Everyone")),
                   DropdownMenuItem(value: 'followers', child: Text("Followers Only")),
                   DropdownMenuItem(value: 'nobody', child: Text("Nobody")),
                 ],
                 onChanged: (val) => _updateSetting(authService, commentPrivacy: val),
               ),
               _buildDropdownTile(
                 title: "Who can invite me to trips?",
                 value: user.tripInvitePrivacy,
                 items: const [
                   DropdownMenuItem(value: 'everyone', child: Text("Everyone")),
                   DropdownMenuItem(value: 'followers', child: Text("Followers Only")),
                   DropdownMenuItem(value: 'nobody', child: Text("Nobody")),
                 ],
                 onChanged: (val) => _updateSetting(authService, tripInvitePrivacy: val),
               ),
               _buildSwitchTile(
                 title: "Hide like count on my posts",
                 subtitle: "Others won't see the number of likes on your posts.",
                 value: user.hideLikeCount,
                 onChanged: (val) => _updateSetting(authService, hideLikeCount: val),
               ),
               _buildSwitchTile(
                 title: "Hide followers / following list",
                 subtitle: "Your followers and following counts will be hidden from your profile.",
                 value: user.hideFollowersList,
                 onChanged: (val) => _updateSetting(authService, hideFollowersList: val),
               ),
               
               const SizedBox(height: 48),
               _buildSectionHeader("Safety"),
               ListTile(
                  contentPadding: EdgeInsets.zero,
                  leading: Icon(Icons.block_outlined, color: context.appColors.textPrimary),
                  title: Text("Blocked Accounts", style: GoogleFonts.inter(fontWeight: FontWeight.w500)),
                  trailing: Icon(Icons.chevron_right, size: 20, color: context.appColors.textSecondary),
                  onTap: () {
                     Navigator.push(context, MaterialPageRoute(builder: (context) => const BlockedUsersScreen()));
                  },
               ),
               ListTile(
                  contentPadding: EdgeInsets.zero,
                  leading: Icon(Icons.visibility_off_outlined, color: context.appColors.textPrimary),
                  title: Text("Restricted Accounts", style: GoogleFonts.inter(fontWeight: FontWeight.w500)),
                  subtitle: Text("Can see your profile but can't interact", style: GoogleFonts.inter(fontSize: 12, color: context.appColors.textSecondary)),
                  trailing: Icon(Icons.chevron_right, size: 20, color: context.appColors.textSecondary),
                  onTap: () {
                     Navigator.push(context, MaterialPageRoute(builder: (context) => const RestrictedUsersScreen()));
                  },
               ),
            ],
          ),
          if (_isLoading)
            Container(
              color: Colors.black12,
              child: const Center(child: CircularProgressIndicator()),
            ),
        ],
      ),
    );
  }

  Future<void> _updateSetting(AuthService auth, {
    bool? isPrivate,
    String? postVisibility,
    String? tripsVisibility,
    bool? allowFollowRequests,
    String? messagePrivacy,
    String? commentPrivacy,
    bool? hideLikeCount,
    bool? hideFollowersList,
    String? tripInvitePrivacy,
    String? travelMoodVisibility,
    String? badgesVisibility,
  }) async {
    setState(() => _isLoading = true);
    try {
      await auth.updatePrivacySettings(
        isPrivate: isPrivate,
        postVisibility: postVisibility,
        tripsVisibility: tripsVisibility,
        allowFollowRequests: allowFollowRequests,
        messagePrivacy: messagePrivacy,
        commentPrivacy: commentPrivacy,
        hideLikeCount: hideLikeCount,
        hideFollowersList: hideFollowersList,
        tripInvitePrivacy: tripInvitePrivacy,
        travelMoodVisibility: travelMoodVisibility,
        badgesVisibility: badgesVisibility,
      );
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text("Error: $e")));
      }
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  Widget _buildSectionHeader(String title) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 16),
      child: Text(
        title.toUpperCase(),
        style: GoogleFonts.inter(fontSize: 12, fontWeight: FontWeight.bold, color: context.appColors.textSecondary, letterSpacing: 1.0),
      ),
    );
  }

  Widget _buildSwitchTile({required String title, required String subtitle, required bool value, required ValueChanged<bool> onChanged}) {
     return Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
           Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                 Text(title, style: GoogleFonts.inter(fontSize: 16, fontWeight: FontWeight.w600)),
                 Switch(
                   value: value, 
                   onChanged: onChanged,
                   activeColor: context.appColors.textPrimary,
                 ),
              ],
           ),
           Text(subtitle, style: GoogleFonts.inter(fontSize: 13, color: context.appColors.textSecondary)),
           const SizedBox(height: 16),
           const Divider(),
           const SizedBox(height: 8),
        ],
     );
  }

  Widget _buildDropdownTile<T>({required String title, required T value, required List<DropdownMenuItem<T>> items, required ValueChanged<T?> onChanged}) {
     return Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
           const SizedBox(height: 8),
           Text(title, style: GoogleFonts.inter(fontSize: 16, fontWeight: FontWeight.w600)),
           const SizedBox(height: 8),
           DropdownButtonFormField<T>(
             value: value,
             items: items,
             onChanged: onChanged,
             decoration: InputDecoration(
                contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                filled: true,
                fillColor: context.appColors.fieldFillBg,
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide.none),
             ),
             dropdownColor: context.appColors.cardBg,
             icon: const Icon(Icons.keyboard_arrow_down_rounded),
           ),
           const SizedBox(height: 16),
           const Divider(),
        ],
     );
  }
}
