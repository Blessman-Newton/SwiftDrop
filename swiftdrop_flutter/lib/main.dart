import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:firebase_crashlytics/firebase_crashlytics.dart';
import 'app_bootstrap.dart';
import 'providers/auth_provider.dart';
import 'theme/theme_provider.dart';
import 'theme/app_theme.dart';
import 'router/router.dart';
import 'services/firebase_service.dart';
import 'services/fcm_service.dart';
import 'services/analytics_service.dart';
import 'dart:ui';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  
  await FirebaseService.initialize();

  FlutterError.onError = (errorDetails) {
    FirebaseCrashlytics.instance.recordFlutterFatalError(errorDetails);
  };

  PlatformDispatcher.instance.onError = (error, stack) {
    FirebaseCrashlytics.instance.recordError(error, stack, fatal: true);
    return true;
  };

  await AppBootstrap.load();

  await AnalyticsService().initialize();
  await FCMService().initialize();

  runApp(const ProviderScope(child: DoorushApp()));
}

class DoorushApp extends ConsumerStatefulWidget {
  const DoorushApp({super.key});

  @override
  ConsumerState<DoorushApp> createState() => _DoorushAppState();
}

class _DoorushAppState extends ConsumerState<DoorushApp>
    with WidgetsBindingObserver {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);

    Future.microtask(() {
      if (!mounted) return;
      ref.read(currentUserProvider.notifier).refreshFromApi();
    });
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.paused ||
        state == AppLifecycleState.hidden ||
        state == AppLifecycleState.detached) {
      _rememberCurrentLocation();
    }
  }

  void _rememberCurrentLocation() {
    try {
      final router = ref.read(routerProvider);
      final uri = router.routerDelegate.currentConfiguration.uri;
      if (uri.path.isEmpty) return;
      AppBootstrap.rememberLocation(uri.toString());
    } catch (_) {
    }
  }

  @override
  Widget build(BuildContext context) {
    final router = ref.watch(routerProvider);
    final themeProvider = ref.watch(themeProviderProvider);

    return MaterialApp.router(
      title: 'Doorush',
      debugShowCheckedModeBanner: false,
      theme: AppTheme.light(),
      darkTheme: AppTheme.dark(),
      themeMode: themeProvider.themeMode,
      routerConfig: router,
    );
  }
}
