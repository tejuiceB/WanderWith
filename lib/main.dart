import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart'; // Added
import 'package:skeletonizer/skeletonizer.dart'; // Added
import 'package:share_plus/share_plus.dart'; // Added
import 'package:flutter/services.dart'; // Added for Clipboard
import 'services/auth_service.dart';
import 'services/notification_service.dart'; // Import Notification Service
import 'services/trip_service.dart'; // Import Trip Service for navigation
import 'models/trip.dart'; // Import Trip model
import 'models/user_profile.dart'; // Added for UserProfile
import 'screens/profile_screen.dart'; // Added
import 'screens/login_screen.dart';
import 'screens/main_screen.dart'; // Import MainScreen
import 'screens/home_screen.dart';
import 'screens/trip_dashboard_screen.dart'; // Import dashboard for navigation
import 'screens/onboarding/role_selection_screen.dart';
import 'screens/onboarding/traveler_form_screen.dart';
import 'screens/onboarding/agency_form_screen.dart';
import 'screens/splash_screen.dart'; 
import 'screens/post_detail_screen.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'config/app_env.dart';
import 'providers/plan_provider.dart';

final GlobalKey<NavigatorState> navigatorKey = GlobalKey<NavigatorState>();

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await AppEnv.init();
  
  await Supabase.initialize(
    url: AppEnv.supabaseUrl,
    anonKey: AppEnv.supabaseAnonKey,
  );

  // Initialize Notifications
  NotificationService().init((type, data) async {
      final String? tripId = data['tripId'];
      final String? postId = data['postId'];

      if (type == 'like' || type == 'comment') {
         if (postId != null && postId.isNotEmpty) {
            navigatorKey.currentState?.push(
               MaterialPageRoute(builder: (_) => PostDetailScreen(postId: postId))
            );
         }
      } else if (tripId != null && tripId.isNotEmpty) {
         try {
            // Fetch fresh trip data
            final trip = await TripService().getTrip(tripId);
            
            // Navigate using Global Key
            navigatorKey.currentState?.push(
               MaterialPageRoute(builder: (_) => TripDashboardScreen(trip: trip))
            );
         } catch (e) {
            print("Failed to navigate from notification: $e");
         }
      }
  });

  runApp(const MyApp());
}

// Custom RefreshListenable to notify GoRouter of auth changes
class AuthRefreshListenable extends ChangeNotifier {
  AuthRefreshListenable(AuthService authService) {
    authService.addListener(notifyListeners);
  }
}

final GoRouter _router = GoRouter(
  navigatorKey: navigatorKey,
  // initialLocation: '/', // Let GoRouter handle the initial deep link
  refreshListenable: AuthRefreshListenable(AuthService.instance),
  redirect: (context, state) {
    final authService = AuthService.instance;
    final bool isAuthenticated = authService.isAuthenticated;
    final bool hasShownSplash = authService.hasShownSplash;
    
    final bool isLoggingIn = state.matchedLocation == '/login';
    final bool isOnboarding = state.matchedLocation.startsWith('/onboarding');
    final bool isSplashScreen = state.matchedLocation == '/splash';

    final String location = state.uri.toString();

    // 1. Force Splash if not shown yet
    if (!hasShownSplash && !isSplashScreen) {
      return '/splash?from=${Uri.encodeComponent(location)}';
    }

    // 2. If on splash, don't redirect (let its timer run)
    if (isSplashScreen) return null;

    // 3. Not authenticated -> Redirect to login
    if (!isAuthenticated) {
      if (isLoggingIn) return null;
      return '/login?from=${Uri.encodeComponent(location)}';
    }

    // 4. Authenticated but not onboarded -> Redirect to onboarding
    // Wait for profile to load before deciding!
    if (isAuthenticated) {
       if (authService.isLoadingProfile) return null; // Wait for fetch
       
       if (!authService.hasCompletedOnboarding) {
          if (isOnboarding) return null;
          return '/onboarding';
       }
    }

    // 5. Logged in and complete -> Redirection from Auth Screens to Content
    if (isAuthenticated && authService.hasCompletedOnboarding) {
       if (isLoggingIn || isOnboarding) {
          // Check if there was an intended destination saved during login
          final target = state.uri.queryParameters['from'];
          if (target != null && target.isNotEmpty && target != '/' && target != '/login' && target != '/splash') {
             return Uri.decodeComponent(target);
          }
          return '/';
       }
    }

    return null; 
  },
  routes: [
    GoRoute(
      path: '/splash',
      builder: (context, state) {
        final from = state.uri.queryParameters['from'] ?? '/';
        return SplashScreen(
          onFinish: () {
            AuthService.instance.markSplashShown();
            context.go(Uri.decodeComponent(from));
          },
        );
      },
    ),
    GoRoute(
      path: '/login',
      builder: (context, state) => const LoginScreen(),
    ),
    GoRoute(
      path: '/onboarding',
      builder: (context, state) => const RoleSelectionScreen(),
      routes: [
        GoRoute(
          path: 'traveler',
          builder: (context, state) => const TravelerFormScreen(),
        ),
        GoRoute(
          path: 'agency',
          builder: (context, state) => const AgencyFormScreen(),
        ),
      ],
    ),
    GoRoute(
      path: '/',
      builder: (context, state) => const MainScreen(),
      routes: [
        GoRoute(
          path: 'u/:username',
          builder: (context, state) {
            final username = state.pathParameters['username'];
            return ProfileScreen(username: username);
          },
        ),
        GoRoute(
          path: 'p/:id',
          builder: (context, state) {
            final postId = state.pathParameters['id'];
            return PostDetailScreen(postId: postId ?? '');
          },
        ),
      ],
    ),
  ],
);

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        ChangeNotifierProvider.value(value: AuthService.instance), // Use singleton
        ChangeNotifierProvider(create: (_) => PlanProvider()),
      ],
      child: MaterialApp.router(
        routerConfig: _router,
        title: 'WanderWith',
        debugShowCheckedModeBanner: false,
        theme: ThemeData(
          colorScheme: ColorScheme.fromSeed(seedColor: Colors.blueAccent),
          useMaterial3: true,
        ),
      ),
    );
  }
}

// AppRoot is no longer needed as GoRouter handles the tree
// But we keep it if any splash logic was complex.
// Actually, let's simplify and use the GoRouter directly.
