import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'app/router.dart';
import 'core/constants.dart';
import 'core/theme.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await AppConstants.init();

  // Catch all Flutter framework errors — prevent crashes
  FlutterError.onError = (details) {
    FlutterError.presentError(details);
    debugPrint('🔴 Flutter error: ${details.exceptionAsString()}');
  };

  // Catch async errors that aren't caught anywhere else
  runZonedGuarded(
    () => runApp(const ProviderScope(child: RamiApp())),
    (error, stackTrace) {
      debugPrint('🔴 Uncaught error: $error');
    },
  );
}

class RamiApp extends ConsumerWidget {
  const RamiApp({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final router = ref.watch(routerProvider);

    return MaterialApp.router(
      title: 'RamiTN',
      theme: ramiTheme,
      darkTheme: ramiDarkTheme,
      themeMode: ThemeMode.system,
      routerConfig: router,
      debugShowCheckedModeBanner: false,
    );
  }
}


