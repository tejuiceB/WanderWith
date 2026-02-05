import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'services/auth_service.dart';
import 'services/notification_service.dart'; // Import Notification Service
import 'services/trip_service.dart'; // Import Trip Service for navigation
import 'models/trip.dart'; // Import Trip model
import 'screens/login_screen.dart';
import 'screens/home_screen.dart';
import 'screens/trip_dashboard_screen.dart'; // Import dashboard for navigation
import 'screens/onboarding_profile_screen.dart';
import 'screens/splash_screen.dart'; 
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
  NotificationService().init((type, tripId) async {
      // 1. Navigation Logic
      if (tripId.isNotEmpty) {
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

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => AuthService()),
        ChangeNotifierProvider(create: (_) => PlanProvider()),
      ],
      child: MaterialApp(
        navigatorKey: navigatorKey, // Set global key
        title: 'WanderWith',
        debugShowCheckedModeBanner: false,
        theme: ThemeData(
          colorScheme: ColorScheme.fromSeed(seedColor: Colors.blueAccent),
          useMaterial3: true,
        ),
        home: const AppRoot(), // Change to AppRoot to handle Splash logic
      ),
    );
  }
}

class AppRoot extends StatefulWidget {
  const AppRoot({super.key});

  @override
  State<AppRoot> createState() => _AppRootState();
}

class _AppRootState extends State<AppRoot> {
  bool _showSplash = true;

  @override
  Widget build(BuildContext context) {
     if (_showSplash) {
       return SplashScreen(
         onFinish: () {
           if (mounted) setState(() => _showSplash = false);
         }
       );
     }
     return const AuthWrapper();
  }
}

class AuthWrapper extends StatelessWidget {
  const AuthWrapper({super.key});

  @override
  Widget build(BuildContext context) {
    final authService = Provider.of<AuthService>(context);

    // 1. Check if we are still deciding auth state or loading profile
    //    We check isLoadingProfile (which is true initially and becomes false after fetch)
    if (authService.isLoadingProfile) {
       // Since we have already shown Splash, we can show a Scaffold with just a white background
       // or a small skeleton. But usually splash handles the "initial" heavy lift.
       // Only if splash finishes FAST and this is SLOW do we see this.
       return const Scaffold(
         backgroundColor: Colors.white,
         body: Center(child: CircularProgressIndicator()), // Or Skeleton
       );
    }

    // 2. Not authenticated -> Login
    if (!authService.isAuthenticated) {
      return const LoginScreen();
    } else {
       // 3. Authenticated check status
       
       // Handle rare edge case where profile is still null but not loading (e.g. error)
       // We treat this as "Need to onboard" or "Retry"
       // To be safe, if we have a user but no profile, we go to onboarding.
       
       if (authService.userProfile?.country == null || authService.userProfile!.country!.isEmpty) {
          return const OnboardingProfileScreen();
       }
       
       return const HomeScreen();
    }
  }
}
