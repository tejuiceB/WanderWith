import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart'; // Added
import 'package:skeletonizer/skeletonizer.dart'; // Added
import 'package:share_plus/share_plus.dart'; // Added
import 'package:flutter/services.dart'; // Added for Clipboard
import 'services/auth_service.dart';
import 'services/network_service.dart';
import 'local/local_db.dart';
import 'providers/theme_provider.dart';
import 'theme/app_theme.dart';
import 'services/notification_service.dart'; // Import Notification Service
import 'services/trip_service.dart'; // Import Trip Service for navigation
import 'models/trip.dart'; // Import Trip model
import 'models/user_profile.dart'; // Added for UserProfile
import 'screens/profile_screen.dart';
import 'screens/auth/login_screen.dart';
import 'screens/auth/signup_screen.dart';
import 'screens/auth/otp_verification_screen.dart';
import 'screens/auth/forgot_password_screen.dart';
import 'screens/auth/reset_password_screen.dart';
import 'screens/main_screen.dart';
import 'screens/home_screen.dart';
import 'screens/trip_dashboard_screen.dart';
import 'screens/onboarding/onboarding_wizard_screen.dart';
import 'screens/splash_screen.dart';
import 'screens/post_detail_screen.dart';
import 'screens/follow_requests_screen.dart';
import 'screens/join_trip_screen.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'config/app_env.dart';
import 'providers/plan_provider.dart';

final GlobalKey<NavigatorState> navigatorKey = GlobalKey<NavigatorState>();

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await AppEnv.init();

  // Initialize local database for offline support
  await LocalDb.initialize();

  // Initialize network monitoring
  await NetworkService.instance.initialize();
  
  // Try Supabase init — don't fail if offline
  try {
    await Supabase.initialize(
      url: AppEnv.supabaseUrl,
      anonKey: AppEnv.supabaseAnonKey,
      authOptions: const FlutterAuthClientOptions(
        authFlowType: AuthFlowType.pkce,
      ),
    );
  } catch (e) {
    debugPrint('Supabase init failed (offline?): $e');
  }

  // Load saved theme preference before building the app
  final savedDarkMode = await ThemeProvider.loadSavedTheme();

  // Initialize Notifications
  NotificationService().init((type, data) async {
      final String? tripId = data['tripId'];
      final String? postId = data['postId'];
      final String? senderId = data['senderId']; // We need to ensure senderId is in the metadata

      if (type == 'like' || type == 'comment') {
         if (postId != null && postId.isNotEmpty) {
            navigatorKey.currentState?.push(
               MaterialPageRoute(builder: (_) => PostDetailScreen(postId: postId))
            );
         }
      } else if (type == 'follow_request') {
         navigatorKey.currentState?.push(
            MaterialPageRoute(builder: (_) => const FollowRequestsScreen())
         );
      } else if (type == 'follow_accepted') {
         // Optionally route to sender's profile if we pass senderId in metadata
         if (senderId != null && senderId.isNotEmpty) {
             navigatorKey.currentState?.push(
                MaterialPageRoute(builder: (_) => ProfileScreen(userId: senderId))
             );
         } else {
             navigatorKey.currentState?.push(
                MaterialPageRoute(builder: (_) => const ProfileScreen())
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

  runApp(MyApp(initialDarkMode: savedDarkMode));
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
    
    final bool isAuthScreen = state.matchedLocation == '/login' ||
        state.matchedLocation == '/signup' ||
        state.matchedLocation == '/verify-otp' ||
        state.matchedLocation == '/forgot-password' ||
        state.matchedLocation == '/reset-password';
    final bool isOnboarding = state.matchedLocation.startsWith('/onboarding');
    final bool isSplashScreen = state.matchedLocation == '/splash';

    final String location = state.uri.toString();

    // 1. Force Splash if not shown yet
    if (!hasShownSplash && !isSplashScreen) {
      return '/splash?from=${Uri.encodeComponent(location)}';
    }

    // 2. If on splash, don't redirect (let its timer run)
    if (isSplashScreen) return null;

    // 3. Handle password recovery — Supabase SDK detected recovery session
    if (authService.isPasswordRecovery) {
      if (state.matchedLocation == '/reset-password') return null;
      return '/reset-password';
    }

    // 4. Allow staying on reset-password screen
    if (state.matchedLocation == '/reset-password') return null;

    // 5. Not authenticated -> Redirect to login
    if (!isAuthenticated) {
      if (isAuthScreen) return null;
      return '/login?from=${Uri.encodeComponent(location)}';
    }

    // 5. Authenticated but not onboarded -> Redirect to onboarding
    if (isAuthenticated) {
       if (authService.isLoadingProfile) return null; // Wait for fetch
       
       if (!authService.hasCompletedOnboarding) {
          if (isOnboarding) return null;
          return '/onboarding';
       }
    }

    // 6. Logged in and complete -> Redirect away from auth/onboarding screens
    //    BUT never redirect away from /reset-password if in recovery mode
    if (isAuthenticated && authService.hasCompletedOnboarding) {
       if ((isAuthScreen && state.matchedLocation != '/reset-password') || isOnboarding) {
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
      path: '/signup',
      builder: (context, state) => const SignupScreen(),
    ),
    GoRoute(
      path: '/verify-otp',
      builder: (context, state) {
        final email = state.uri.queryParameters['email'] ?? '';
        return OtpVerificationScreen(email: email);
      },
    ),
    GoRoute(
      path: '/forgot-password',
      builder: (context, state) => const ForgotPasswordScreen(),
    ),
    GoRoute(
      path: '/reset-password',
      builder: (context, state) => const ResetPasswordScreen(),
    ),
    GoRoute(
      path: '/onboarding',
      builder: (context, state) => const OnboardingWizardScreen(),
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
        GoRoute(
          path: 'join/:code',
          builder: (context, state) {
            final code = state.pathParameters['code'];
            return JoinTripScreen(initialCode: code ?? '');
          },
        ),
        GoRoute(
          path: 'trip/:id',
          builder: (context, state) {
            final tripId = state.pathParameters['id'] ?? '';
            return _TripDeepLinkLoader(tripId: tripId);
          },
        ),
      ],
    ),
  ],
);

class MyApp extends StatelessWidget {
  final bool initialDarkMode;
  const MyApp({super.key, required this.initialDarkMode});

  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        ChangeNotifierProvider.value(value: AuthService.instance), // Use singleton
        ChangeNotifierProvider.value(value: NetworkService.instance), // Network monitoring
        ChangeNotifierProvider(create: (_) => PlanProvider()),
        ChangeNotifierProvider(create: (_) => ThemeProvider(initialDarkMode: initialDarkMode)),
      ],
      child: Consumer<ThemeProvider>(
        builder: (context, themeProvider, _) => MaterialApp.router(
          routerConfig: _router,
          title: 'WanderWith',
          debugShowCheckedModeBanner: false,
          theme: AppTheme.light,
          darkTheme: AppTheme.dark,
          themeMode: themeProvider.themeMode,
        ),
      ),
    );
  }
}

// AppRoot is no longer needed as GoRouter handles the tree
// But we keep it if any splash logic was complex.
// Actually, let's simplify and use the GoRouter directly.

/// Loader widget for deep-linked trip URLs.
/// Fetches the [Trip] by ID, then shows [TripDashboardScreen].
class _TripDeepLinkLoader extends StatefulWidget {
  final String tripId;
  const _TripDeepLinkLoader({required this.tripId});

  @override
  State<_TripDeepLinkLoader> createState() => _TripDeepLinkLoaderState();
}

class _TripDeepLinkLoaderState extends State<_TripDeepLinkLoader> {
  late Future<Trip> _future;

  @override
  void initState() {
    super.initState();
    _future = TripService().getTrip(widget.tripId);
  }

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<Trip>(
      future: _future,
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Scaffold(
            body: Center(child: CircularProgressIndicator()),
          );
        }
        if (snapshot.hasError || !snapshot.hasData) {
          return Scaffold(
            appBar: AppBar(title: const Text('Trip Not Found')),
            body: Center(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Icon(Icons.error_outline, size: 64, color: Colors.grey),
                  const SizedBox(height: 16),
                  Text(
                    'Could not load this trip.',
                    style: Theme.of(context).textTheme.titleMedium,
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'It may have been deleted or you don\'t have access.',
                    style: Theme.of(context).textTheme.bodySmall,
                  ),
                  const SizedBox(height: 24),
                  FilledButton.icon(
                    onPressed: () => context.go('/'),
                    icon: const Icon(Icons.home),
                    label: const Text('Go Home'),
                  ),
                ],
              ),
            ),
          );
        }
        return TripDashboardScreen(trip: snapshot.data!);
      },
    );
  }
}
