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
    final colorScheme = Theme.of(context).colorScheme;

    return Scaffold(
      body: SafeArea(
        child: LayoutBuilder(
          builder: (context, constraints) {
            final isWide = constraints.maxWidth >= 760;
            final isSmallMobile = constraints.maxWidth < 400;

            final brandingSection = Column(
              mainAxisSize: MainAxisSize.min,
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                HatsuneMikuWidget(
                  mood: MikuMood.happy,
                  speechText: l10n.mikuWelcome,
                  size: isWide ? 115 : (isSmallMobile ? 76 : 92),
                ),
                SizedBox(height: isWide ? 24 : 16),
                Text(
                  l10n.appTitle,
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontSize: isWide ? 34 : (isSmallMobile ? 24 : 28),
                    fontWeight: FontWeight.bold,
                    letterSpacing: 1.5,
                  ),
                ),
                const SizedBox(height: 6),
                Text(
                  l10n.reverseEngineering,
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontSize: isWide ? 16 : 14,
                    color: colorScheme.secondary,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ],
            );

            final actionSection = Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                // Card com integrantes do grupo
                Card(
                  elevation: 2,
                  color: colorScheme.surfaceContainerLow,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(14),
                    side: BorderSide(color: colorScheme.outlineVariant),
                  ),
                  child: Padding(
                    padding: EdgeInsets.all(isSmallMobile ? 12.0 : 16.0),
                    child: Column(
                      children: [
                        Text(
                          l10n.developedBy,
                          textAlign: TextAlign.center,
                          style: const TextStyle(fontWeight: FontWeight.bold),
                        ),
                        const Divider(),
                        const Text('• Aluno 1 - RA: 123456', textAlign: TextAlign.center),
                        const SizedBox(height: 4),
                        const Text('• Aluno 2 - RA: 654321', textAlign: TextAlign.center),
                        const SizedBox(height: 4),
                        const Text('• Aluno 3 - RA: 987654', textAlign: TextAlign.center),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 20),

                // Seletor de idiomas com quebra de linha automática para fontes ampliadas
                Wrap(
                  alignment: WrapAlignment.center,
                  spacing: 12,
                  runSpacing: 8,
                  children: [
                    ChoiceChip(
                      avatar: const Text('🇧🇷', style: TextStyle(fontSize: 18)),
                      label: const Text('Português'),
                      selected: settings.languageCode == 'pt',
                      onSelected: (_) => settingsNotifier.setLanguage('pt'),
                    ),
                    ChoiceChip(
                      avatar: const Text('🇺🇸', style: TextStyle(fontSize: 18)),
                      label: const Text('English'),
                      selected: settings.languageCode == 'en',
                      onSelected: (_) => settingsNotifier.setLanguage('en'),
                    ),
                  ],
                ),
                const SizedBox(height: 24),

                // Botão de acesso
                FilledButton.icon(
                  style: FilledButton.styleFrom(
                    minimumSize: const Size.fromHeight(52),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(14),
                    ),
                  ),
                  icon: const Icon(Icons.login),
                  label: Text(
                    l10n.enterGame,
                    style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                  ),
                  onPressed: () => context.go('/game'),
                ),
              ],
            );

            return Center(
              child: SingleChildScrollView(
                padding: EdgeInsets.symmetric(
                  horizontal: isSmallMobile ? 16.0 : 28.0,
                  vertical: 20.0,
                ),
                child: ConstrainedBox(
                  constraints: BoxConstraints(maxWidth: isWide ? 920 : 460),
                  child: isWide
                      ? Row(
                          crossAxisAlignment: CrossAxisAlignment.center,
                          children: [
                            Expanded(flex: 5, child: brandingSection),
                            Padding(
                              padding: const EdgeInsets.symmetric(horizontal: 28.0),
                              child: SizedBox(
                                height: 260,
                                child: VerticalDivider(color: colorScheme.outlineVariant),
                              ),
                            ),
                            Expanded(flex: 5, child: actionSection),
                          ],
                        )
                      : Column(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            brandingSection,
                            const SizedBox(height: 24),
                            actionSection,
                          ],
                        ),
                ),
              ),
            );
          },
        ),
      ),
    );
  }
}