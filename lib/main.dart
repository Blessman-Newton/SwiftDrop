import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'theme/theme_provider.dart';
import 'theme/app_theme.dart';
import 'router/router.dart';

void main() {
  WidgetsFlutterBinding.ensureInitialized();
  runApp(const ProviderScope(child: SwiftDropApp()));
}

class SwiftDropApp extends ConsumerWidget {
  const SwiftDropApp({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final router = ref.watch(routerProvider);
    final themeProvider = ref.watch(themeProviderProvider);

    return MaterialApp.router(
      title: 'SwiftDrop',
      debugShowCheckedModeBanner: false,
      theme: AppTheme.light(),
      darkTheme: AppTheme.dark(),
      themeMode: themeProvider.themeMode,
      routerConfig: router,
    );
  }
}
