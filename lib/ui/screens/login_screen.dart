import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../l10n/app_localizations.dart';
import '../../providers/app_providers.dart';
import '../widgets/hatsune_miku_widget.dart';

class LoginScreen extends ConsumerWidget {
  const LoginScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final settings = ref.watch(settingsProvider);
    final settingsNotifier = ref.read(settingsProvider.notifier);
    final l10n = AppLocalizations.of(context);

    return Scaffold(
      body: SafeArea(
        child: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(24.0),
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 480),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  HatsuneMikuWidget(
                    mood: MikuMood.happy,
                    speechText: l10n.mikuWelcome,
                    size: 95,
                  ),
                  const SizedBox(height: 20),
                  Text(
                    l10n.appTitle,
                    style: const TextStyle(fontSize: 30, fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 6),
                  Text(
                    l10n.reverseEngineering,
                    style: TextStyle(color: Theme.of(context).colorScheme.secondary),
                  ),
                  const SizedBox(height: 24),

                  // Integrantes do grupo
                  Card(
                    elevation: 2,
                    child: Padding(
                      padding: const EdgeInsets.all(16.0),
                      child: Column(
                        children: [
                          Text(
                            l10n.developedBy,
                            style: const TextStyle(fontWeight: FontWeight.bold),
                          ),
                          const Divider(),
                          const Text('• Aluno 1 - RA: 123456'),
                          const Text('• Aluno 2 - RA: 654321'),
                          const Text('• Aluno 3 - RA: 987654'),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(height: 20),

                  // Seletor de idiomas com bandeiras
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      ChoiceChip(
                        avatar: const Text('🇧🇷', style: TextStyle(fontSize: 18)),
                        label: const Text('Português'),
                        selected: settings.languageCode == 'pt',
                        onSelected: (_) => settingsNotifier.setLanguage('pt'),
                      ),
                      const SizedBox(width: 12),
                      ChoiceChip(
                        avatar: const Text('🇺🇸', style: TextStyle(fontSize: 18)),
                        label: const Text('English'),
                        selected: settings.languageCode == 'en',
                        onSelected: (_) => settingsNotifier.setLanguage('en'),
                      ),
                    ],
                  ),
                  const SizedBox(height: 28),

                  ElevatedButton.icon(
                    style: ElevatedButton.styleFrom(
                      minimumSize: const Size.fromHeight(52),
                      backgroundColor: Theme.of(context).colorScheme.primary,
                      foregroundColor: Theme.of(context).colorScheme.onPrimary,
                    ),
                    icon: const Icon(Icons.login),
                    label: Text(l10n.enterGame, style: const TextStyle(fontSize: 16)),
                    onPressed: () => context.go('/game'),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}