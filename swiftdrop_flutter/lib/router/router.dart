import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../providers/providers.dart';
import '../providers/auth_provider.dart';
import '../screens/splash_screen.dart';
import '../screens/onboarding_screen.dart';
import '../screens/auth_screen.dart';
import '../screens/home_screen.dart';
import '../screens/food_delivery_screen.dart';
import '../screens/restaurant_detail_screen.dart';
import '../screens/map_tracking_screen.dart';
import '../screens/profile_screen.dart';
import '../screens/orders_screen.dart';
import '../screens/role_selection_screen.dart';
import '../screens/parcel_booking_screen.dart';
import '../screens/parcel_package_details_screen.dart';
import '../screens/parcel_service_selection_screen.dart';
import '../screens/parcel_summary_screen.dart';
import '../screens/rider/rider_dashboard_screen.dart';
import '../screens/rider/rider_active_delivery_screen.dart';
import '../screens/rider/rider_navigation_screen.dart';
import '../screens/rider/rider_earnings_screen.dart';
import '../widgets/main_scaffold.dart';
import '../widgets/rider_scaffold.dart';
import '../models/models.dart';

final routerProvider = Provider<GoRouter>((ref) {
  return GoRouter(
    initialLocation: '/splash',
    routes: [
      GoRoute(path: '/splash', builder: (_, __) => const SplashScreen()),
      GoRoute(
          path: '/onboarding', builder: (_, __) => const OnboardingScreen()),
      GoRoute(path: '/auth', builder: (_, __) => const AuthScreen()),
      GoRoute(
          path: '/role-selection',
          builder: (_, __) => const RoleSelectionScreen()),

      // Customer routes
      ShellRoute(
        builder: (_, state, child) => MainScaffold(child: child),
        routes: [
          GoRoute(path: '/home', builder: (_, __) => const HomeScreen()),
          GoRoute(
              path: '/food-delivery',
              builder: (_, __) => const FoodDeliveryScreen()),
          GoRoute(
              path: '/profile', builder: (_, __) => const ProfileScreen()),
          GoRoute(
              path: '/orders', builder: (_, __) => const OrdersScreen()),
        ],
      ),

      // Full-screen routes (no bottom nav)
      GoRoute(
        path: '/restaurant/:id',
        builder: (_, state) => RestaurantDetailScreen(
          restaurantId: state.pathParameters['id']!,
        ),
      ),
      GoRoute(path: '/map', builder: (_, __) => const MapTrackingScreen()),

      // Parcel routes
      GoRoute(
          path: '/parcel/booking',
          builder: (_, __) => const ParcelBookingScreen()),
      GoRoute(
          path: '/parcel/details',
          builder: (_, __) => const ParcelPackageDetailsScreen()),
      GoRoute(
          path: '/parcel/service',
          builder: (_, __) => const ParcelServiceSelectionScreen()),
      GoRoute(
          path: '/parcel/summary',
          builder: (_, __) => const ParcelSummaryScreen()),

      // Booking History → redirect to orders (same data source)
      GoRoute(
          path: '/booking-history',
          builder: (_, __) => const OrdersScreen()),

      // Rider routes
      ShellRoute(
        builder: (_, state, child) => RiderScaffold(child: child),
        routes: [
          GoRoute(
              path: '/rider/dashboard',
              builder: (_, __) => const RiderDashboardScreen()),
          GoRoute(
              path: '/rider/active-delivery',
              builder: (_, __) => const RiderActiveDeliveryScreen()),
          GoRoute(
              path: '/rider/navigation',
              builder: (_, __) => const RiderNavigationScreen()),
          GoRoute(
              path: '/rider/earnings',
              builder: (_, __) => const RiderEarningsScreen()),
        ],
      ),
    ],
    redirect: (context, state) {
      final onboardingDone = ref.read(onboardingDoneProvider);
      final user = ref.read(currentUserProvider);
      final role = ref.read(userRoleProvider);

      final location = state.matchedLocation;

      // Always allow these screens without redirect
      final allowedLocations = [
        '/splash',
        '/onboarding',
        '/role-selection',
        '/auth',
      ];
      if (allowedLocations.contains(location)) {
        return null;
      }

      // Step 1: First time user - no onboarding done
      if (!onboardingDone) return '/onboarding';

      // Step 2: Onboarding done, no role selected yet
      if (role == null) return '/role-selection';

      // Step 3: Role selected but not logged in (guest goes directly to home)
      if (user == null) {
        if (role == UserRole.guest) return '/home';
        return '/auth';
      }

      // Step 4: Logged in - check role access
      if (role == UserRole.rider && !location.startsWith('/rider')) {
        return '/rider/dashboard';
      }
      if (role != UserRole.rider && location.startsWith('/rider')) {
        return '/home';
      }

      // Allow access
      return null;
    },
  );
});
