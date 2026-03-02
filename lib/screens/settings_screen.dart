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
import 'notification_preferences_screen.dart';

class SettingsScreen extends StatefulWidget {
  const SettingsScreen({super.key});

  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  String _appVersion = '1.0.1+7';

  @override
  void initState() {
    super.initState();
  }

  @override
  Widget build(BuildContext context) {
    final authService = Provider.of<AuthService>(context);
    final colors = context.appColors;
    final isEmailUser = authService.isEmailUser;

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
          // ── Account Info ──────────────────────────
          _buildSectionHeader(context, "Account Info"),
          _buildSettingsItem(
            context,
            icon: Icons.email_outlined,
            title: "Email",
            subtitle: authService.user?.email ?? 'Not set',
            onTap: isEmailUser ? () => _changeEmail(context, authService) : () {},
            showChevron: isEmailUser,
          ),
          _buildSettingsItem(
            context,
            icon: Icons.person_outline,
            title: "Username",
            subtitle: authService.userProfile?.username ?? 'Not set',
            onTap: () {},
            showChevron: false,
          ),

          // ── Security ──────────────────────────────
          const SizedBox(height: 24),
          _buildSectionHeader(context, "Security"),
          if (isEmailUser)
            _buildSettingsItem(
              context,
              icon: Icons.lock_outline,
              title: "Change Password",
              onTap: () => _changePassword(context, authService),
            ),
          if (!isEmailUser)
            _buildSettingsItem(
              context,
              icon: Icons.account_circle_outlined,
              title: "Signed in with Google",
              subtitle: "Password & email managed by Google",
              onTap: () {},
              showChevron: false,
            ),

          // ── Privacy ───────────────────────────────
          const SizedBox(height: 24),
          _buildSectionHeader(context, "Privacy"),
          _buildSettingsItem(
            context,
            icon: Icons.lock_outline_rounded, 
            title: "Privacy Settings", 
            onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const PrivacySettingsScreen()))
          ),
          _buildSettingsItem(
            context,
            icon: Icons.archive_outlined, 
            title: "Archived Posts", 
            onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const ArchivedPostsScreen()))
          ),
          // ── Notifications ─────────────────────────────────
          const SizedBox(height: 24),
          _buildSectionHeader(context, "Notifications"),
          _buildSettingsItem(
            context,
            icon: Icons.notifications_outlined,
            title: "Notification Preferences",
            subtitle: "Categories, language, quiet hours",
            onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const NotificationPreferencesScreen())),
          ),
          // ── Appearance ────────────────────────────
          const SizedBox(height: 24),
          _buildSectionHeader(context, "Appearance"),
          _buildThemeToggle(context),

          // ── Support ───────────────────────────────
          const SizedBox(height: 24),
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

          // ── Danger Zone ───────────────────────────
          const SizedBox(height: 24),
          _buildSectionHeader(context, "Danger Zone"),
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
            onTap: () => _deleteAccountWithAuth(context, authService),
            isDestructive: true,
            showChevron: false
          ),
          
          // ── About ─────────────────────────────────
          const SizedBox(height: 32),
          _buildSectionHeader(context, "About"),
          _buildSettingsItem(
            context,
            icon: Icons.info_outline,
            title: "Version",
            subtitle: "v$_appVersion",
            onTap: () {},
            showChevron: false,
          ),
          _buildSettingsItem(
            context,
            icon: Icons.article_outlined,
            title: "Open Source Licenses",
            onTap: () => showLicensePage(
              context: context,
              applicationName: 'WanderWith',
              applicationVersion: _appVersion,
            ),
          ),
          
          const SizedBox(height: 24),
          Center(
            child: Column(
              children: [
                 Text("Made with \u2764\ufe0f for Travelers", style: GoogleFonts.inter(color: colors.textMuted, fontSize: 11)),
                 const SizedBox(height: 6),
                 GestureDetector(
                   onTap: () async {
                     try {
                       await launchUrl(Uri.parse('https://play.google.com/store/apps/details?id=com.tejuice.wanderwith'));
                     } catch (_) {}
                   },
                   child: Text("\u2b50 Rate us on Play Store", style: GoogleFonts.inter(color: const Color(0xFF448AFF), fontSize: 12, fontWeight: FontWeight.w500)),
                 ),
                 const SizedBox(height: 24),
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
        bool isLoading = false;
        return StatefulBuilder(
          builder: (ctx, setDialogState) {
            return AlertDialog(
              title: const Text("Change Password"),
              content: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  TextField(
                    controller: currentPasswordController,
                    obscureText: true,
                    decoration: const InputDecoration(
                      labelText: "Current Password",
                      prefixIcon: Icon(Icons.lock_outline, size: 20),
                    ),
                  ),
                  const SizedBox(height: 12),
                  TextField(
                    controller: newPasswordController,
                    obscureText: true,
                    decoration: const InputDecoration(
                      labelText: "New Password",
                      hintText: "Min 8 chars, 1 uppercase, 1 number",
                      prefixIcon: Icon(Icons.lock_reset, size: 20),
                    ),
                  ),
                  const SizedBox(height: 12),
                  TextField(
                    controller: confirmPasswordController,
                    obscureText: true,
                    decoration: const InputDecoration(
                      labelText: "Confirm New Password",
                      prefixIcon: Icon(Icons.check_circle_outline, size: 20),
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
                  onPressed: isLoading ? null : () async {
                    final currentPass = currentPasswordController.text.trim();
                    final newPass = newPasswordController.text.trim();
                    final confirmPass = confirmPasswordController.text.trim();

                    if (currentPass.isEmpty) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(content: Text("Please enter your current password")),
                      );
                      return;
                    }
                    if (newPass.length < 8) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(content: Text("Password must be at least 8 characters")),
                      );
                      return;
                    }
                    if (!RegExp(r'[A-Z]').hasMatch(newPass)) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(content: Text("Password must contain at least 1 uppercase letter")),
                      );
                      return;
                    }
                    if (!RegExp(r'[0-9]').hasMatch(newPass)) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(content: Text("Password must contain at least 1 number")),
                      );
                      return;
                    }
                    if (newPass != confirmPass) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(content: Text("Passwords don't match")),
                      );
                      return;
                    }
                    if (currentPass == newPass) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(content: Text("New password must be different from current")),
                      );
                      return;
                    }

                    setDialogState(() => isLoading = true);
                    try {
                      await authService.secureUpdatePassword(currentPass, newPass);
                      Navigator.pop(ctx);
                      if (context.mounted) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(content: Text("Password updated successfully! ✅")),
                        );
                      }
                    } catch (e) {
                      setDialogState(() => isLoading = false);
                      if (context.mounted) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(content: Text(e.toString().replaceAll('Exception: ', ''))),
                        );
                      }
                    }
                  },
                  child: isLoading
                    ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(strokeWidth: 2))
                    : const Text("Update", style: TextStyle(fontWeight: FontWeight.bold)),
                ),
              ],
            );
          },
        );
      },
    );
  }

  void _changeEmail(BuildContext context, AuthService authService) {
    final passwordController = TextEditingController();
    final newEmailController = TextEditingController();

    showDialog(
      context: context,
      builder: (ctx) {
        bool isLoading = false;
        return StatefulBuilder(
          builder: (ctx, setDialogState) {
            return AlertDialog(
              title: const Text("Change Email"),
              content: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    "Current: ${authService.user?.email ?? 'unknown'}",
                    style: TextStyle(fontSize: 13, color: context.appColors.textSecondary),
                  ),
                  const SizedBox(height: 16),
                  TextField(
                    controller: newEmailController,
                    keyboardType: TextInputType.emailAddress,
                    decoration: const InputDecoration(
                      labelText: "New Email Address",
                      prefixIcon: Icon(Icons.email_outlined, size: 20),
                    ),
                  ),
                  const SizedBox(height: 12),
                  TextField(
                    controller: passwordController,
                    obscureText: true,
                    decoration: const InputDecoration(
                      labelText: "Current Password",
                      prefixIcon: Icon(Icons.lock_outline, size: 20),
                      hintText: "Required for verification",
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
                  onPressed: isLoading ? null : () async {
                    final newEmail = newEmailController.text.trim();
                    final password = passwordController.text.trim();

                    if (newEmail.isEmpty || !newEmail.contains('@')) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(content: Text("Please enter a valid email address")),
                      );
                      return;
                    }
                    if (password.isEmpty) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(content: Text("Please enter your password")),
                      );
                      return;
                    }

                    setDialogState(() => isLoading = true);
                    try {
                      await authService.changeEmail(password, newEmail);
                      Navigator.pop(ctx);
                      if (context.mounted) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(content: Text("Confirmation email sent to $newEmail. Please verify to complete the change.")),
                        );
                      }
                    } catch (e) {
                      setDialogState(() => isLoading = false);
                      if (context.mounted) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(content: Text(e.toString().replaceAll('Exception: ', ''))),
                        );
                      }
                    }
                  },
                  child: isLoading
                    ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(strokeWidth: 2))
                    : const Text("Change Email", style: TextStyle(fontWeight: FontWeight.bold)),
                ),
              ],
            );
          },
        );
      },
    );
  }

  void _deleteAccountWithAuth(BuildContext context, AuthService authService) {
    final isEmailUser = authService.isEmailUser;
    final passwordController = TextEditingController();
    final confirmTextController = TextEditingController();

    showDialog(
      context: context,
      builder: (ctx) {
        bool isLoading = false;
        return StatefulBuilder(
          builder: (ctx, setDialogState) {
            return AlertDialog(
              title: const Text("Delete Account Permanently?"),
              content: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    "This action is permanent and cannot be undone.\n\n"
                    "All your trips, posts, followers, and social data will be permanently deleted from our servers.",
                    style: TextStyle(fontSize: 14),
                  ),
                  const SizedBox(height: 16),
                  if (isEmailUser) ...[
                    TextField(
                      controller: passwordController,
                      obscureText: true,
                      decoration: const InputDecoration(
                        labelText: "Enter your password to confirm",
                        prefixIcon: Icon(Icons.lock_outline, size: 20),
                      ),
                    ),
                  ] else ...[
                    const Text(
                      "Type DELETE to confirm:",
                      style: TextStyle(fontWeight: FontWeight.w600, fontSize: 13),
                    ),
                    const SizedBox(height: 8),
                    TextField(
                      controller: confirmTextController,
                      decoration: const InputDecoration(
                        hintText: "DELETE",
                      ),
                    ),
                  ],
                ],
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.pop(ctx),
                  child: const Text("Cancel"),
                ),
                TextButton(
                  onPressed: isLoading ? null : () async {
                    // Verify before proceeding
                    if (isEmailUser) {
                      final password = passwordController.text.trim();
                      if (password.isEmpty) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(content: Text("Please enter your password")),
                        );
                        return;
                      }
                      setDialogState(() => isLoading = true);
                      final verified = await authService.reauthenticate(password);
                      if (!verified) {
                        setDialogState(() => isLoading = false);
                        if (context.mounted) {
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(content: Text("Incorrect password")),
                          );
                        }
                        return;
                      }
                    } else {
                      if (confirmTextController.text.trim() != 'DELETE') {
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(content: Text("Please type DELETE to confirm")),
                        );
                        return;
                      }
                      setDialogState(() => isLoading = true);
                    }

                    try {
                      Navigator.pop(ctx);
                      Navigator.popUntil(context, (route) => route.isFirst);
                      await authService.deleteAccount();
                      if (context.mounted) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(content: Text("Account and data successfully deleted.")),
                        );
                      }
                    } catch (e) {
                      if (context.mounted) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(content: Text("Error: $e")),
                        );
                      }
                    }
                  },
                  child: isLoading
                    ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(strokeWidth: 2))
                    : const Text("DELETE EVERYTHING", style: TextStyle(color: Colors.red, fontWeight: FontWeight.bold)),
                ),
              ],
            );
          },
        );
      },
    );
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
