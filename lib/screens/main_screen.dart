import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import '../services/auth_service.dart';
import '../services/trip_service.dart';
import '../theme/app_colors.dart';
import '../theme/theme_extensions.dart';
import 'home_screen.dart';
import 'my_trips_screen.dart';
import 'create_trip_screen.dart';
import 'create_post_screen.dart';
import 'search_screen.dart';
import 'profile_screen.dart';
import 'template_picker_screen.dart';

class MainScreen extends StatefulWidget {
  const MainScreen({super.key});

  @override
  State<MainScreen> createState() => _MainScreenState();
}

class _MainScreenState extends State<MainScreen> {
  int _currentIndex = 0;
  final PageController _pageController = PageController();

  // Screens for the ViewPager (Index 0, 1, 3, 4)
  // We skip index 2 because that's the "+" button modal
  final List<Widget> _screens = [
    const HomeScreen(),
    const MyTripsScreen(),
    const SizedBox.shrink(), // Placeholder for +
    const SearchScreen(),
    const ProfileScreen(),
  ];

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  void _onItemTapped(int index) {
    if (index == 2) {
      // Center Button Tap -> Show Modal
      _showCreateOptions();
      return;
    }

    setState(() {
      _currentIndex = index;
    });
    // Animate to page
    _pageController.jumpToPage(index);
  }

  void _onPageChanged(int index) {
     if (index == 2) {
        // If they swipe to the "middle" (placeholder), what should happen?
        // Ideally we skip it or show the modal.
        // Let's just update the index.
        // Actually, physically swiping to a "placeholder" page feels weird.
        // User asked for "change by swipe".
        // If we have 5 items in bottom nav, we expect 5 pages.
        // Page 2 is empty/hidden.
        // Better UX: Swipe from Page 1 -> Page 3 directly?
        // Implementing that requires custom physics or just accepting Page 2 exists.
        // Let's keep it simple: Page 2 displays the modal automatically? Or just "create something" screen?
        // The user said: "Center button should NOT open a page. It should open a bottom sheet."
        // This conflicts with "Swipe between tabs".
        // If I swipe from MyTrips (1) -> Right, I hit index 2.
        // I will make index 2 a "Quick Create" page instead of a modal if swiped?
        // No, user insisted on Bottom Sheet.
        // Strategy: We will have 4 actual pages in the PageView.
        // BottomNav has 5 items.
        // We map BottomNav indices to PageView indices.
        // BottomNav: 0, 1, 2(+), 3, 4
        // PageView:  0, 1,      2, 3
     }
     
     setState(() => _currentIndex = index);
  }
  
  // Revised Strategy for "Swipe + Middle Button Modal":
  // It is very hard to combine standard PageView with a "gap" index.
  // We will use a PageView with 5 children, but child 2 is a "redirect" or just empty.
  // Actually, standard apps (Insta/TikTok) with a middle button often DON'T allow swiping across the middle "Create" tab.
  // Users usually swipe Home <-> Explore, but rarely "Left of Home".
  // Let's use `NeverScrollableScrollPhysics` for the PageView if the user taps?
  // User asked for "change by swipe".
  // I will implement a 5-page PageView.
  // Page 2 will simply be a background that invokes the modal immediately when viewed?
  // Or simpler: Page 2 reflects the "Create" experience embedded.
  // User said: "It should open a bottom sheet modal."
  // I will respect the Bottom Sheet constraint.
  // This means swiping to index 2 is awkward.
  // I'll disable swipe for now to ensure quality, and use `IndexedStack` or `PageView` with `NeverScrollableScrollPhysics`.
  // Wait, user specifically said "change by swipe as well".
  // Okay, I will modify the PageView to only have 4 pages, and map the indices.
  // 0 -> 0
  // 1 -> 1
  // 3 -> 2
  // 4 -> 3
  // And the BottomNav manages the visual index.
  
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: PageView(
         controller: _pageController,
         physics: const BouncingScrollPhysics(), 
         onPageChanged: (pIndex) {
            // Map PageView index (0,1,2,3) to BottomNav index (0,1,3,4)
            int navIndex = pIndex;
            if (pIndex >= 2) navIndex = pIndex + 1;
            
            setState(() => _currentIndex = navIndex);
         },
         children: const [
            HomeScreen(),
            MyTripsScreen(),
            SearchScreen(),
            ProfileScreen(),
         ],
      ),
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: _currentIndex,
        onTap: (index) {
           if (index == 2) {
              _showCreateOptions();
           } else {
              setState(() => _currentIndex = index);
              // Map BottomNav index to PageView index
              int pIndex = index;
              if (index > 2) pIndex = index - 1;
              _pageController.jumpToPage(pIndex);
           }
        },
        type: BottomNavigationBarType.fixed,
        backgroundColor: context.appColors.cardBg,
        selectedItemColor: context.appColors.textPrimary,
        unselectedItemColor: context.appColors.textSecondary,
        showSelectedLabels: false,
        showUnselectedLabels: false,
        elevation: 16,
        items: [
           const BottomNavigationBarItem(icon: Icon(Icons.home_outlined), activeIcon: Icon(Icons.home_filled), label: "Home"),
           const BottomNavigationBarItem(icon: Icon(Icons.luggage_outlined), activeIcon: Icon(Icons.luggage), label: "My Trips"),
           BottomNavigationBarItem(
              icon: Container(
                 padding: const EdgeInsets.all(12),
                 decoration: BoxDecoration(
                    color: AppColors.brand,
                    shape: BoxShape.circle,
                    boxShadow: [
                       BoxShadow(color: AppColors.brand.withOpacity(0.3), blurRadius: 8, offset: const Offset(0, 4))
                    ]
                 ),
                 child: const Icon(Icons.add_rounded, color: Colors.white, size: 28),
              ), 
              label: "Create"
           ),
           const BottomNavigationBarItem(icon: Icon(Icons.search_rounded), activeIcon: Icon(Icons.search_rounded, weight: 800), label: "Search"), // Weight doesn't work on legacy icons easily, just same icon
           const BottomNavigationBarItem(icon: Icon(Icons.person_outline), activeIcon: Icon(Icons.person), label: "Profile"),
        ],
      ),
    );
  }

  void _showCreateOptions() {
     showModalBottomSheet(
        context: context,
        backgroundColor: Colors.transparent,
        isScrollControlled: true,
        builder: (context) => Container(
           padding: const EdgeInsets.all(24),
           decoration: BoxDecoration(
              color: context.appColors.cardBg,
              borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
           ),
           child: SingleChildScrollView(
           child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                 Container(width: 40, height: 4, decoration: BoxDecoration(color: context.appColors.border, borderRadius: BorderRadius.circular(2))),
                 const SizedBox(height: 24),
                 Text("Create New", style: GoogleFonts.outfit(fontSize: 20, fontWeight: FontWeight.bold)),
                 const SizedBox(height: 24),
                 
                 // Option 1: Plan a New Trip
                 ListTile(
                    onTap: () {
                       Navigator.pop(context);
                       Navigator.push(context, MaterialPageRoute(builder: (_) => const CreateTripScreen()));
                    },
                    leading: Container(
                       padding: const EdgeInsets.all(12),
                       decoration: BoxDecoration(color: context.isDark ? AppColors.brand.withOpacity(0.15) : Colors.blue.shade50, borderRadius: BorderRadius.circular(12)),
                       child: Icon(Icons.add_location_alt_rounded, color: AppColors.brand),
                    ),
                    title: Text("Plan a New Trip", style: GoogleFonts.inter(fontWeight: FontWeight.bold, fontSize: 16)),
                    subtitle: Text("Start from scratch with AI", style: GoogleFonts.inter(color: context.appColors.textSecondary)),
                    trailing: Icon(Icons.chevron_right, color: context.appColors.textMuted),
                 ),
                 
                 const SizedBox(height: 16),

                 // Option 1.5: Start from Template
                 ListTile(
                    onTap: () {
                       Navigator.pop(context);
                       Navigator.push(context, MaterialPageRoute(builder: (_) => const TemplatePickerScreen()));
                    },
                    leading: Container(
                       padding: const EdgeInsets.all(12),
                       decoration: BoxDecoration(color: context.isDark ? Colors.amber.withOpacity(0.15) : Colors.amber.shade50, borderRadius: BorderRadius.circular(12)),
                       child: Icon(Icons.dashboard_customize_rounded, color: Colors.amber.shade700),
                    ),
                    title: Text("Start from Template", style: GoogleFonts.inter(fontWeight: FontWeight.bold, fontSize: 16)),
                    subtitle: Text("Reuse a saved trip structure", style: GoogleFonts.inter(color: context.appColors.textSecondary)),
                    trailing: Icon(Icons.chevron_right, color: context.appColors.textMuted),
                 ),
                 
                 const SizedBox(height: 16),
                 
                 // Option 2: Create a Post
                 ListTile(
                    onTap: () {
                       Navigator.pop(context);
                       Navigator.push(context, MaterialPageRoute(builder: (_) => const CreatePostScreen()));
                    },
                    leading: Container(
                       padding: const EdgeInsets.all(12),
                       decoration: BoxDecoration(color: Colors.green.shade50, borderRadius: BorderRadius.circular(12)),
                       child: const Icon(Icons.add_photo_alternate_rounded, color: Colors.greenAccent),
                    ),
                    title: Text("Create a Post", style: GoogleFonts.inter(fontWeight: FontWeight.bold, fontSize: 16)),
                    subtitle: Text("Share a travel memory", style: GoogleFonts.inter(color: context.appColors.textSecondary)),
                    trailing: Icon(Icons.chevron_right, color: context.appColors.textMuted),
                 ),
                 
                 const SizedBox(height: 16),
                 
                 // Option 3: Join Existing Trip
                 ListTile(
                    onTap: () {
                       Navigator.pop(context);
                       _showJoinTripDialog();
                    },
                    leading: Container(
                       padding: const EdgeInsets.all(12),
                       decoration: BoxDecoration(color: Colors.purple.shade50, borderRadius: BorderRadius.circular(12)),
                       child: const Icon(Icons.link_rounded, color: Colors.purpleAccent),
                    ),
                    title: Text("Join Existing Trip", style: GoogleFonts.inter(fontWeight: FontWeight.bold, fontSize: 16)),
                    subtitle: Text("Have a code? Enter it here", style: GoogleFonts.inter(color: context.appColors.textSecondary)),
                    trailing: Icon(Icons.chevron_right, color: context.appColors.textMuted),
                 ),
                 
                 const SizedBox(height: 32),
              ],
           ),
           ),
        ),
     );
  }

  void _showJoinTripDialog() {
    final TextEditingController _idController = TextEditingController();
    bool _isLoading = false;

    showDialog(
      context: context, 
      builder: (ctx) => StatefulBuilder(
        builder: (context, setDialogState) {
          return AlertDialog(
            backgroundColor: context.appColors.cardBg,
            surfaceTintColor: context.appColors.cardBg,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
            title: Text("Join a Trip", style: GoogleFonts.outfit(fontWeight: FontWeight.bold)),
            content: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  "Paste the Trip ID shared by your friend.",
                  style: GoogleFonts.inter(color: context.appColors.textSecondary),
                ),
                const SizedBox(height: 16),
                TextField(
                  controller: _idController,
                  decoration: InputDecoration(
                    labelText: "Trip ID",
                    border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                    filled: true,
                    fillColor: context.appColors.fieldFillBg,
                  ),
                ),
                if (_isLoading) ...[
                   const SizedBox(height: 16),
                   const LinearProgressIndicator(borderRadius: BorderRadius.all(Radius.circular(4))),
                ]
              ],
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context), 
                child: Text("Cancel", style: GoogleFonts.inter(fontWeight: FontWeight.w600, color: context.appColors.textSecondary))
              ),
              ElevatedButton(
                onPressed: _isLoading ? null : () async {
                   final tripId = _idController.text.trim();
                   if (tripId.isEmpty) return;
                   final uid = Provider.of<AuthService>(context, listen: false).user?.id;
                   if (uid == null) return;

                   setDialogState(() => _isLoading = true);
                   try {
                      await TripService().joinTrip(tripId, uid);
                      if (context.mounted) {
                        Navigator.pop(context);
                        ScaffoldMessenger.of(context).showSnackBar(SnackBar(
                          content: Text("Join request sent! Waiting for approval. 🎒"),
                          backgroundColor: AppColors.brand,
                        ));
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
                style: ElevatedButton.styleFrom(
                   backgroundColor: AppColors.brand,
                   foregroundColor: Colors.white,
                   shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                ),
                child: const Text("Join")
              ),
            ],
          );
        }
      )
    );
  }
}
