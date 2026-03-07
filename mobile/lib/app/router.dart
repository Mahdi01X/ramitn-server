import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../screens/splash/splash_screen.dart';
import '../screens/auth/login_screen.dart';
import '../screens/home/home_screen.dart';
import '../screens/offline/offline_setup_screen.dart';
import '../screens/game/game_table_screen.dart';
import '../screens/lobby/create_room_screen.dart';
import '../screens/lobby/join_room_screen.dart';
import '../screens/lobby/lobby_screen.dart';
import '../screens/online/quick_online_screen.dart';
import '../screens/rules/rules_screen.dart';

final routerProvider = Provider<GoRouter>((ref) {
  return GoRouter(
    initialLocation: '/splash',
    routes: [
      GoRoute(path: '/splash', builder: (_, __) => const SplashScreen()),
      GoRoute(path: '/', builder: (_, __) => const HomeScreen()),
      GoRoute(path: '/login', builder: (_, __) => const LoginScreen()),
      GoRoute(path: '/offline-setup', builder: (_, __) => const OfflineSetupScreen()),
      GoRoute(path: '/game', builder: (_, __) => const GameTableScreen()),
      GoRoute(path: '/create-room', builder: (_, __) => const CreateRoomScreen()),
      GoRoute(path: '/join-room', builder: (_, __) => const JoinRoomScreen()),
      GoRoute(path: '/lobby', builder: (_, __) => const LobbyScreen()),
      GoRoute(path: '/quick-online', builder: (_, __) => const QuickOnlineScreen()),
      GoRoute(path: '/rules', builder: (_, __) => const RulesScreen()),
    ],
  );
});


