import 'dart:convert';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_secure_storage/test/test_flutter_secure_storage_platform.dart';
import 'package:flutter_secure_storage_platform_interface/flutter_secure_storage_platform_interface.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:swiftdrop/app_bootstrap.dart';
import 'package:swiftdrop/main.dart';
import 'package:swiftdrop/models/models.dart';
import 'package:swiftdrop/screens/auth_screen.dart';
import 'package:swiftdrop/screens/onboarding_screen.dart';
import 'package:swiftdrop/screens/orders_screen.dart';
import 'package:swiftdrop/screens/splash_screen.dart';
import 'package:swiftdrop/services/api_client.dart';
import 'package:swiftdrop/services/secure_session_store.dart';
import 'package:swiftdrop/widgets/main_scaffold.dart';

/// In-memory stand-in for the platform keystore. Without it every
/// `FlutterSecureStorage` call never completes inside `flutter test`.
final Map<String, String> secureStore = <String, String>{};

/// Seeds the launch state the app reads in `main()` and takes the bootstrap
/// snapshot from it.
Future<void> seedLaunch({
  bool? onboardingDone,
  UserRole? role,
  Map<String, dynamic>? session,
  DateTime? sessionExpiresAt,
  bool? sessionExpectsToken,
  String? lastLocation,
  String? token,
}) async {
  if (token != null) {
    secureStore[SecureSessionStore.storageKey] = token;
  }
  SharedPreferences.setMockInitialValues({
    if (onboardingDone != null) AppBootstrap.onboardingKey: onboardingDone,
    if (role != null) AppBootstrap.roleKey: role.index,
    if (session != null) AppBootstrap.sessionKey: jsonEncode(session),
    if (sessionExpiresAt != null)
      AppBootstrap.sessionExpiryKey: sessionExpiresAt.millisecondsSinceEpoch,
    if (sessionExpectsToken != null)
      AppBootstrap.sessionExpectsTokenKey: sessionExpectsToken,
    if (lastLocation != null) AppBootstrap.lastLocationKey: lastLocation,
  });
  AppBootstrap.resetForTesting();
  ApiClient.resetForTesting();
  await AppBootstrap.load();
}

/// Pumps enough fake time for the router redirect and any page transition to
/// settle. Never uses `pumpAndSettle`: the splash loader and several home
/// widgets run animations that repeat forever.
Future<void> pumpApp(
  WidgetTester tester, {
  Duration span = const Duration(seconds: 1),
}) async {
  await tester.pumpWidget(const ProviderScope(child: DoorushApp()));
  await tester.pump();
  await tester.pump(span);
  await tester.pump(span);
  await tester.pump(span);
}

const _demoUser = User(
  uid: 'u-1',
  email: 'rider@doorush.app',
  displayName: 'Doorush Tester',
);

const _demoToken = 'header.payload.signature';

void main() {
  setUp(() {
    secureStore.clear();
    FlutterSecureStoragePlatform.instance =
        TestFlutterSecureStoragePlatform(secureStore);
  });

  testWidgets('fresh install lands on onboarding, not the login screen',
      (WidgetTester tester) async {
    await seedLaunch();
    expect(AppBootstrap.current.initialLocation, '/splash');

    await pumpApp(tester);

    // The splash intro runs 250ms + 3500ms before handing off to the router.
    await tester.pump(const Duration(milliseconds: 400));
    await tester.pump(const Duration(milliseconds: 4000));
    await tester.pump();
    await tester.pump(const Duration(seconds: 1));

    expect(find.byType(SplashScreen), findsNothing);
    expect(find.byType(OnboardingScreen), findsOneWidget);
    expect(find.byType(AuthScreen), findsNothing);
  });

  testWidgets('returning user resumes the last screen without a login bounce',
      (WidgetTester tester) async {
    await seedLaunch(
      onboardingDone: true,
      role: UserRole.customer,
      session: _demoUser.toMap(),
      sessionExpiresAt: DateTime.now().toUtc().add(const Duration(days: 30)),
      sessionExpectsToken: true,
      lastLocation: '/orders',
      token: _demoToken,
    );
    expect(AppBootstrap.current.initialLocation, '/orders');

    await pumpApp(tester);
    await tester.pump(const Duration(milliseconds: 600));

    expect(find.byType(SplashScreen), findsNothing);
    expect(find.byType(AuthScreen), findsNothing);
    expect(find.byType(MainScaffold), findsOneWidget);
    expect(find.byType(OrdersScreen), findsOneWidget);
  });

  testWidgets('an expired session drops the user onto the login screen',
      (WidgetTester tester) async {
    await seedLaunch(
      onboardingDone: true,
      role: UserRole.customer,
      session: _demoUser.toMap(),
      sessionExpiresAt:
          DateTime.now().toUtc().subtract(const Duration(days: 1)),
      sessionExpectsToken: true,
      lastLocation: '/orders',
      token: _demoToken,
    );

    await pumpApp(tester);
    await tester.pump(const Duration(milliseconds: 600));

    // Still a returning install: no splash replay, straight to the login.
    expect(find.byType(SplashScreen), findsNothing);
    expect(find.byType(AuthScreen), findsOneWidget);
    expect(find.byType(OrdersScreen), findsNothing);
    expect(AppBootstrap.current.user, isNull);
    expect(secureStore, isEmpty);
  });

  testWidgets('role and session are restored together on relaunch',
      (WidgetTester tester) async {
    final expiresAt = DateTime.now().toUtc().add(const Duration(days: 30));
    await seedLaunch(
      onboardingDone: true,
      role: UserRole.rider,
      session: _demoUser.toMap(),
      sessionExpiresAt: expiresAt,
      sessionExpectsToken: true,
      lastLocation: '/rider/dashboard',
      token: _demoToken,
    );

    final boot = AppBootstrap.current;
    expect(boot.role, UserRole.rider);
    expect(boot.user?.uid, _demoUser.uid);
    expect(
      boot.sessionExpiresAt?.millisecondsSinceEpoch,
      expiresAt.millisecondsSinceEpoch,
    );
    expect(boot.initialLocation, '/rider/dashboard');
  });
}
