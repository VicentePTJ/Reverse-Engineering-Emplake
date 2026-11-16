import 'dart:async';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../ui/screens/login_screen.dart';
import '../ui/screens/game_screen.dart';
import '../ui/screens/settings_screen.dart';
import '../ui/screens/history_screen.dart';
import '../ui/widgets/main_shell.dart';

class _AuthStateRefreshNotifier extends ChangeNotifier {
  late final StreamSubscription<User?> _subscription;

  _AuthStateRefreshNotifier() {
    _subscription = FirebaseAuth.instance.authStateChanges().listen((_) {
      notifyListeners();
    });
  }

  @override
  void dispose() {
    _subscription.cancel();
    super.dispose();
  }
}

GoRouter createRouter(SharedPreferences prefs) {
  final savedRoute = prefs.getString('last_route') ?? '/game';
  final refreshNotifier = _AuthStateRefreshNotifier();

  return GoRouter(
    initialLocation: FirebaseAuth.instance.currentUser == null ? '/login' : savedRoute,
    refreshListenable: refreshNotifier,
    redirect: (context, state) {
      final isLoggedIn = FirebaseAuth.instance.currentUser != null;
      final isLoggingIn = state.uri.path == '/login';

      if (!isLoggedIn && !isLoggingIn) {
        return '/login';
      }
      if (isLoggedIn && isLoggingIn) {
        return savedRoute == '/login' ? '/game' : savedRoute;
      }
      return null;
    },
    routes: [
      GoRoute(
        path: '/login',
        builder: (context, state) => const LoginScreen(),
      ),
      ShellRoute(
        builder: (context, state, child) {
          prefs.setString('last_route', state.uri.toString());
          return MainShell(child: child);
        },
        routes: [
          GoRoute(
            path: '/game',
            builder: (context, state) => const GameScreen(),
          ),
          GoRoute(
            path: '/settings',
            builder: (context, state) => const SettingsScreen(),
          ),
          GoRoute(
            path: '/history',
            builder: (context, state) => const HistoryScreen(),
          ),
        ],
      ),
    ],
  );
}