import 'package:go_router/go_router.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../ui/screens/login_screen.dart';
import '../ui/screens/game_screen.dart';
import '../ui/screens/settings_screen.dart';
import '../ui/screens/history_screen.dart';
import '../ui/widgets/main_shell.dart';

GoRouter createRouter(SharedPreferences prefs) {
  final initialLocation = prefs.getString('last_route') ?? '/login';

  return GoRouter(
    initialLocation: initialLocation,
    routes: [
      GoRoute(
        path: '/login',
        builder: (context, state) => const LoginScreen(),
      ),
      ShellRoute(
        builder: (context, state, child) {
          // Grava a rota atual no SharedPreferences
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