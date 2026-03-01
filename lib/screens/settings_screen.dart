import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:url_launcher/url_launcher.dart';
import '../services/auth_service.dart';
import '../providers/theme_provider.dart';
import '../theme/theme_extensions.dart';
import 'privacy_policy_screen.dart';
import 'terms_conditions_screen.dart';
import 'privacy_settings_screen.dart';
import 'archived_posts_screen.dart';

class SettingsScreen extends StatefulWidget {
  const SettingsScreen({super.key});

  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  @override
  Widget build(BuildContext context) {
    final authService = Provider.of<AuthService>(context);
    final colors = context.appColors;

    return Scaffold(
      backgroundColor: colors.scaffoldBg,
      appBar: AppBar(
        backgroundColor: colors.scaffoldBg,
        elevation: 0,
        scrolledUnderElevation: 0,
        leading: IconButton(
          icon: Icon(Icons.arrow_back, color: colors.iconDefault),
          onPressed: () => Navigator.pop(context),
        ),
        title: Text(
          "Settings", 
          style: GoogleFonts.outfit(color: colors.textPrimary, fontWeight: FontWeight.bold)
        ),
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          // Account Info
          _buildSectionHeader(context, "Account Info"),
          _buildSettingsItem(
            context,
            icon: Icons.email_outlined,
            title: "Email",
            subtitle: authService.user?.email ?? 'Not set',
            onTap: () {},
            showChevron: false,
          ),
          _buildSettingsItem(
            context,
            icon: Icons.person_outline,
            title: "Username",
            subtitle: authService.userProfile?.username ?? 'Not set',
            onTap: () {},
            showChevron: false,
          ),
          _buildSettingsItem(
            context,
            icon: Icons.lock_outline,
            title: "Change Password",
            onTap: () => _changePassword(context, authService),
          ),

          const SizedBox(height: 32),
          _buildSectionHeader(context, "Appearance"),
          _buildThemeToggle(context),

          const SizedBox(height: 32),
          _buildSectionHeader(context, "Support"),
          _buildSettingsItem(
            context,
            icon: Icons.email_outlined,
            title: "Contact Support",
            subtitle: "wanderwithplan@gmail.com",
            onTap: () async {
              final uri = Uri(
                scheme: 'mailto',
                path: 'wanderwithplan@gmail.com',
                queryParameters: {'subject': 'WanderWith Support Request'},
              );
              try { await launchUrl(uri); } catch (_) {}
            },
          ),
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
          _buildSectionHeader(context, "Privacy"),
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
          _buildSectionHeader(context, "Account"),
          _buildSettingsItem(
            context,
            icon: Icons.logout, 
            title: "Log Out", 
            onTap: () async {
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
               }
            },
            isDestructive: true
          ),
          _buildSettingsItem(
            context,
            icon: Icons.delete_outline, 
            title: "Delete Account", 
            onTap: () async {
               final confirm = await showDialog<bool>(
                 context: context,
                 builder: (ctx) => AlertDialog(
                   title: const Text("Delete Account permanently?"),
                   content: const Text(
                     "This action is permanent and cannot be undone.\n\n"
                     "All your trips, posts, followers, and social data will be permanently deleted from our servers.",
                     style: TextStyle(fontSize: 14),
                   ),
                   actions: [
                     TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text("Cancel")),
                     TextButton(
                       onPressed: () => Navigator.pop(ctx, true), 
                       child: const Text("DELETE EVERYTHING", style: TextStyle(color: Colors.red, fontWeight: FontWeight.bold))
                     ),
                   ],
                 )
               );

               if (confirm == true) {
                 try {
                   Navigator.popUntil(context, (route) => route.isFirst);
                   await authService.deleteAccount();
                   
                   if (context.mounted) {
                     ScaffoldMessenger.of(context).showSnackBar(
                       const SnackBar(content: Text("Account and data successfully deleted."))
                     );
                   }
                 } catch (e) {
                   if (context.mounted) {
                     ScaffoldMessenger.of(context).showSnackBar(
                       SnackBar(content: Text("Error: $e"))
                     );
                   }
                 }
               }
            },
            isDestructive: true,
            showChevron: false
          ),
          
          const SizedBox(height: 48),
          Center(
            child: Column(
              children: [
                 Text("WanderWith v2.0.0", style: GoogleFonts.inter(color: colors.textMuted, fontSize: 12)),
                 const SizedBox(height: 4),
                 Text("Made with \u2764\ufe0f for Travelers", style: GoogleFonts.inter(color: colors.textMuted, fontSize: 10)),
                 const SizedBox(height: 4),
                 GestureDetector(
                   onTap: () async {
                     try {
                       await launchUrl(Uri.parse('https://play.google.com/store/apps/details?id=com.tejuice.wanderwith'));
                     } catch (_) {}
                   },
                   child: Text("\u2b50 Rate us on Play Store", style: GoogleFonts.inter(color: const Color(0xFF448AFF), fontSize: 11)),
                 ),
              ],
            ),
          )
        ],
      ),
    );
  }

  void _changePassword(BuildContext context, AuthService authService) {
    final currentPasswordController = TextEditingController();
    final newPasswordController = TextEditingController();
    final confirmPasswordController = TextEditingController();

    showDialog(
      context: context,
      builder: (ctx) {
        return AlertDialog(
          title: const Text("Change Password"),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                controller: newPasswordController,
                obscureText: true,
                decoration: const InputDecoration(
                  labelText: "New Password",
                  hintText: "Min 6 characters",
                ),
              ),
              const SizedBox(height: 12),
              TextField(
                controller: confirmPasswordController,
                obscureText: true,
                decoration: const InputDecoration(
                  labelText: "Confirm New Password",
                ),
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(ctx),
              child: const Text("Cancel"),
            ),
            TextButton(
              onPressed: () async {
                final newPass = newPasswordController.text.trim();
                final confirmPass = confirmPasswordController.text.trim();
                if (newPass.length < 6) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text("Password must be at least 6 characters")),
                  );
                  return;
                }
                if (newPass != confirmPass) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text("Passwords don't match")),
                  );
                  return;
                }
                try {
                  await authService.updatePassword(newPass);
                  Navigator.pop(ctx);
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text("Password updated successfully!")),
                  );
                } catch (e) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(content: Text("Error: $e")),
                  );
                }
              },
              child: const Text("Update", style: TextStyle(fontWeight: FontWeight.bold)),
            ),
          ],
        );
      },
    );

    // Dispose controllers when not needed
    // They'll be GC'd when the dialog closes
  }

  Widget _buildSectionHeader(BuildContext context, String title) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8, left: 4),
      child: Text(
        title.toUpperCase(),
        style: GoogleFonts.inter(fontSize: 12, fontWeight: FontWeight.bold, color: context.appColors.textSecondary, letterSpacing: 1.0),
      ),
    );
  }

  Widget _buildSettingsItem(BuildContext context, {required IconData icon, required String title, String? subtitle, required VoidCallback onTap, bool isDestructive = false, bool showChevron = true}) {
    final colors = context.appColors;
    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      decoration: BoxDecoration(
        color: colors.surfaceBg,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: colors.borderSubtle),
      ),
      child: ListTile(
        onTap: onTap,
        leading: Icon(icon, color: isDestructive ? Colors.redAccent : colors.iconDefault, size: 22),
        title: Text(
          title,
          style: GoogleFonts.inter(
            fontWeight: FontWeight.w500,
            color: isDestructive ? Colors.redAccent : colors.textPrimary
          ),
        ),
        subtitle: subtitle != null ? Text(subtitle, style: GoogleFonts.inter(fontSize: 12, color: colors.textSecondary)) : null,
        trailing: showChevron ? Icon(Icons.chevron_right, size: 18, color: colors.iconMuted) : null,
      ),
    );
  }

  Widget _buildThemeToggle(BuildContext context) {
    final themeProvider = Provider.of<ThemeProvider>(context);
    final colors = context.appColors;
    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      decoration: BoxDecoration(
        color: colors.surfaceBg,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: colors.borderSubtle),
      ),
      child: ListTile(
        leading: Icon(
          themeProvider.isDark ? Icons.dark_mode_rounded : Icons.light_mode_rounded,
          color: colors.iconDefault,
          size: 22,
        ),
        title: Text("Dark Mode", style: GoogleFonts.inter(fontWeight: FontWeight.w500, color: colors.textPrimary)),
        trailing: Switch.adaptive(
          value: themeProvider.isDark,
          onChanged: (_) => themeProvider.toggleTheme(),
          activeColor: const Color(0xFF448AFF),
        ),
      ),
    );
  }

  void _sendFeedback() async {
     final Uri emailLaunchUri = Uri(
       scheme: 'mailto',
       path: 'feedback@wanderwith.online',
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
