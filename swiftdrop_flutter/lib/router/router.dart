import 'package:flutter/material.dart';
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
import '../screens/cart_screen.dart';
import '../screens/role_selection_screen.dart';
import '../screens/parcel_booking_screen.dart';
import '../screens/parcel_package_details_screen.dart';
import '../screens/parcel_service_selection_screen.dart';
import '../screens/parcel_summary_screen.dart';
import '../screens/address_selection_screen.dart';
import '../screens/gas_booking_screen.dart';
import '../screens/cosmetics_list_screen.dart';
import '../screens/rider/rider_dashboard_screen.dart';
import '../screens/rider/rider_active_delivery_screen.dart';
import '../screens/rider/rider_navigation_screen.dart';
import '../screens/rider/rider_earnings_screen.dart';
import '../screens/rider/rider_orders_screen.dart';
import '../widgets/main_scaffold.dart';
import '../widgets/rider_scaffold.dart';
import '../models/models.dart';

CustomTransitionPage<void> _fadeTransitionPage(BuildContext context, GoRouterState state, Widget child) {
  return CustomTransitionPage<void>(
    key: state.pageKey,
    child: child,
    transitionsBuilder: (context, animation, secondaryAnimation, child) {
      return FadeTransition(
        opacity: CurveTween(curve: Curves.easeInOut).animate(animation),
        child: child,
      );
    },
  );
}

final routerProvider = Provider<GoRouter>((ref) {
  return GoRouter(
    initialLocation: '/splash',
    errorBuilder: (context, state) => _RouteErrorScreen(uri: state.uri.toString()),
    routes: [
      GoRoute(
        path: '/splash',
        pageBuilder: (context, state) => _fadeTransitionPage(context, state, const SplashScreen()),
      ),
      GoRoute(
        path: '/onboarding',
        pageBuilder: (context, state) => _fadeTransitionPage(context, state, const OnboardingScreen()),
      ),
      GoRoute(
        path: '/auth',
        pageBuilder: (context, state) => _fadeTransitionPage(context, state, const AuthScreen()),
      ),
      GoRoute(
        path: '/role-selection',
        pageBuilder: (context, state) => _fadeTransitionPage(context, state, const RoleSelectionScreen()),
      ),

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
              path: '/orders',
              builder: (_, state) {
                final extra = state.extra as Map<String, dynamic>?;
                final autoOpenId = extra?['autoOpenId'] as String?;
                return OrdersScreen(autoOpenId: autoOpenId);
              }),
          GoRoute(path: '/cart', builder: (_, __) => const CartScreen()),
        ],
      ),

      // Full-screen routes (no bottom nav)
      GoRoute(
        path: '/restaurant/:id',
        pageBuilder: (context, state) {
          final checkout = state.uri.queryParameters['checkout'] == 'true';
          return _fadeTransitionPage(
            context,
            state,
            RestaurantDetailScreen(
              restaurantId: state.pathParameters['id']!,
              autoShowCheckout: checkout,
            ),
          );
        },
      ),
      GoRoute(
        path: '/map',
        pageBuilder: (context, state) => _fadeTransitionPage(context, state, const MapTrackingScreen()),
      ),
      GoRoute(
        path: '/gas-booking',
        pageBuilder: (context, state) => _fadeTransitionPage(context, state, const GasBookingScreen()),
      ),
      GoRoute(
        path: '/cosmetics-list',
        pageBuilder: (context, state) => _fadeTransitionPage(context, state, const CosmeticsListScreen()),
      ),
      GoRoute(
        path: '/address-selection',
        pageBuilder: (context, state) {
          final extra = state.extra as Map<String, dynamic>?;
          return _fadeTransitionPage(
            context,
            state,
            AddressSelectionScreen(
              currentAddress: extra?['address'] as String?,
              currentLat: extra?['lat'] as double?,
              currentLng: extra?['lng'] as double?,
            ),
          );
        },
      ),

      // Parcel routes
      GoRoute(
        path: '/parcel/booking',
        pageBuilder: (context, state) {
          final type = state.uri.queryParameters['type'] ?? 'package';
          return _fadeTransitionPage(context, state, ParcelBookingScreen(pickupType: type));
        },
      ),
      GoRoute(
        path: '/parcel/details',
        pageBuilder: (context, state) => _fadeTransitionPage(context, state, const ParcelPackageDetailsScreen()),
      ),
      GoRoute(
        path: '/parcel/service',
        pageBuilder: (context, state) => _fadeTransitionPage(context, state, const ParcelServiceSelectionScreen()),
      ),
      GoRoute(
        path: '/parcel/summary',
        pageBuilder: (context, state) => _fadeTransitionPage(context, state, const ParcelSummaryScreen()),
      ),

      // Booking History → redirect to orders (same data source)
      GoRoute(
        path: '/booking-history',
        pageBuilder: (context, state) => _fadeTransitionPage(context, state, const OrdersScreen()),
      ),

      // Rider routes
      ShellRoute(
        builder: (_, state, child) => RiderScaffold(child: child),
        routes: [
          GoRoute(
              path: '/rider/dashboard',
              builder: (_, __) => const RiderDashboardScreen()),
          GoRoute(
              path: '/rider/orders',
              builder: (_, __) => const RiderOrdersScreen()),
          GoRoute(
              path: '/rider/active-delivery',
              builder: (_, __) => const RiderActiveDeliveryScreen()),
          GoRoute(
              path: '/rider/navigation',
              pageBuilder: (context, state) => _fadeTransitionPage(context, state, const RiderNavigationScreen())),
          GoRoute(
              path: '/rider/earnings',
              builder: (_, __) => const RiderEarningsScreen()),
        ],
      ),
    ],
    redirect: (context, state) {
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

      final onboardingDone = ref.read(onboardingDoneProvider);
      final user = ref.read(currentUserProvider);
      final role = ref.read(userRoleProvider);

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

class _RouteErrorScreen extends StatelessWidget {
  final String uri;
  const _RouteErrorScreen({required this.uri});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Center(
        child: Padding(
          padding: const EdgeInsets.all(32),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(Icons.explore_off_rounded,
                  size: 64, color: Color(0xFF9AA5B1)),
              const SizedBox(height: 16),
              Text(
                'Page not found',
                style: Theme.of(context).textTheme.titleLarge?.copyWith(
                      fontWeight: FontWeight.w800,
                    ),
              ),
              const SizedBox(height: 8),
              Text(
                'We couldn\'t open "$uri".',
                textAlign: TextAlign.center,
                style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                      color: const Color(0xFF6C7A71),
                    ),
              ),
              const SizedBox(height: 24),
              FilledButton(
                onPressed: () => context.go('/home'),
                child: const Text('Back to Home'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
