import 'package:flutter/material.dart';
import 'package:curved_navigation_bar/curved_navigation_bar.dart';
import 'package:go_router/go_router.dart';
import 'help_dialog.dart';

class MainShell extends StatelessWidget {
  final Widget child;
  const MainShell({super.key, required this.child});

  int _calculateSelectedIndex(BuildContext context) {
    final String location = GoRouterState.of(context).uri.toString();
    if (location.startsWith('/game')) return 0;
    if (location.startsWith('/history')) return 1;
    if (location.startsWith('/settings')) return 2;
    return 0;
  }

  @override
  Widget build(BuildContext context) {
    final selectedIndex = _calculateSelectedIndex(context);
    final colorScheme = Theme.of(context).colorScheme;

    return Scaffold(
      body: child,
      bottomNavigationBar: CurvedNavigationBar(
        index: selectedIndex,
        height: 56, // Mais compacto para caber tudo sem scroll no navegador
        backgroundColor: Colors.transparent,
        color: colorScheme.primary,
        buttonBackgroundColor: colorScheme.primary,
        animationDuration: const Duration(milliseconds: 300),
        items: [
          Icon(Icons.gamepad, color: colorScheme.onPrimary),
          Icon(Icons.history, color: colorScheme.onPrimary),
          Icon(Icons.settings, color: colorScheme.onPrimary),
          Icon(Icons.help_outline, color: colorScheme.onPrimary),
        ],
        onTap: (index) {
          switch (index) {
            case 0:
              context.go('/game');
              break;
            case 1:
              context.go('/history');
              break;
            case 2:
              context.go('/settings');
              break;
            case 3:
              showDialog(
                context: context,
                builder: (context) => const HelpDialog(),
              );
              break;
          }
        },
      ),
    );
  }
}