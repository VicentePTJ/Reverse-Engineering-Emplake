import 'package:firebase_auth/firebase_auth.dart' hide EmailAuthProvider;
import 'package:firebase_ui_auth/firebase_ui_auth.dart';
import 'package:firebase_ui_oauth_google/firebase_ui_oauth_google.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../l10n/app_localizations.dart';
import '../../providers/app_providers.dart';
import '../widgets/hatsune_miku_widget.dart';

const String kGoogleWebClientId = 'SEU_WEB_CLIENT_ID.apps.googleusercontent.com';

class LoginScreen extends ConsumerWidget {
  const LoginScreen({super.key});

  Widget _buildLanguageSelector(AppSettings settings, SettingsNotifier notifier) {
    return Wrap(
      alignment: WrapAlignment.center,
      spacing: 12,
      runSpacing: 8,
      children: [
        ChoiceChip(
          avatar: const Text('🇧🇷', style: TextStyle(fontSize: 18)),
          label: const Text('Português'),
          selected: settings.languageCode == 'pt',
          onSelected: (_) => notifier.setLanguage('pt'),
        ),
        ChoiceChip(
          avatar: const Text('🇺🇸', style: TextStyle(fontSize: 18)),
          label: const Text('English'),
          selected: settings.languageCode == 'en',
          onSelected: (_) => notifier.setLanguage('en'),
        ),
      ],
    );
  }

  Widget _buildGroupMembersCard(BuildContext context, AppLocalizations l10n) {
    final colorScheme = Theme.of(context).colorScheme;
    return Card(
      elevation: 1,
      color: colorScheme.surfaceContainerLow,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(14),
        side: BorderSide(color: colorScheme.outlineVariant),
      ),
      child: Padding(
        padding: const EdgeInsets.all(12.0),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              l10n.developedBy,
              textAlign: TextAlign.center,
              style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13),
            ),
            const Divider(height: 12),
            const Text('• Cauã Marques da Silva - RA: 822914', style: TextStyle(fontSize: 12)),
            const Text('• Vicente Pinto Tomás Junior - RA: 822643', style: TextStyle(fontSize: 12)),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final settings = ref.watch(settingsProvider);
    final settingsNotifier = ref.read(settingsProvider.notifier);
    final l10n = AppLocalizations.of(context);
    final colorScheme = Theme.of(context).colorScheme;

    return SignInScreen(
      providers: [
        EmailAuthProvider(),
        GoogleProvider(clientId: kGoogleWebClientId),
      ],
      actions: [
        AuthStateChangeAction<SignedIn>((context, state) {
          context.go('/game');
        }),
        AuthStateChangeAction<UserCreated>((context, state) {
          context.go('/game');
        }),
      ],
      // Painel lateral exibido automaticamente em telas largas (Web / Desktop / Tablet)
      sideBuilder: (context, constraints) {
        return Container(
          color: colorScheme.surfaceContainerLowest,
          padding: const EdgeInsets.all(28.0),
          child: Center(
            child: SingleChildScrollView(
              child: ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 400),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    HatsuneMikuWidget(
                      mood: MikuMood.happy,
                      speechText: l10n.mikuWelcome,
                      size: 100,
                    ),
                    const SizedBox(height: 16),
                    Text(
                      l10n.appTitle,
                      style: const TextStyle(
                        fontSize: 28,
                        fontWeight: FontWeight.bold,
                        letterSpacing: 1.5,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      l10n.reverseEngineering,
                      style: TextStyle(color: colorScheme.secondary, fontWeight: FontWeight.w500),
                    ),
                    const SizedBox(height: 18),
                    _buildGroupMembersCard(context, l10n),
                    const SizedBox(height: 16),
                    _buildLanguageSelector(settings, settingsNotifier),
                  ],
                ),
              ),
            ),
          ),
        );
      },
      // Cabeçalho exibido automaticamente em telas estreitas (Celular)
      headerBuilder: (context, constraints, shrinkOffset) {
        return Padding(
          padding: const EdgeInsets.only(top: 12.0, left: 16.0, right: 16.0),
          child: FittedBox(
            fit: BoxFit.scaleDown,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                HatsuneMikuWidget(
                  mood: MikuMood.happy,
                  speechText: l10n.mikuWelcome,
                  size: 68,
                ),
                const SizedBox(height: 8),
                Text(
                  l10n.appTitle,
                  style: const TextStyle(fontSize: 22, fontWeight: FontWeight.bold),
                ),
              ],
            ),
          ),
        );
      },
      // Rodapé com integrantes do grupo e seletor de idioma no modo mobile
      footerBuilder: (context, action) {
        final isMobileWidth = MediaQuery.of(context).size.width < 800;
        if (!isMobileWidth) return const SizedBox.shrink();

        return Padding(
          padding: const EdgeInsets.only(top: 16.0),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              _buildLanguageSelector(settings, settingsNotifier),
              const SizedBox(height: 14),
              _buildGroupMembersCard(context, l10n),
            ],
          ),
        );
      },
    );
  }
}