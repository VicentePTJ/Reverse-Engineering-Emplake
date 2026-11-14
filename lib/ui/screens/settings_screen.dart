import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../l10n/app_localizations.dart';
import '../../providers/app_providers.dart';

class _ThemePreset {
  final String name;
  final Color color;
  const _ThemePreset(this.name, this.color);
}

class SettingsScreen extends ConsumerWidget {
  const SettingsScreen({super.key});

  String _fontLabel(String fontKey) {
    switch (fontKey) {
      case 'EB Garamond':
        return 'Garamond (EB Garamond)';
      case 'Lato':
        return 'Helvetica (Lato)';
      case 'Courier Prime':
        return 'Courier (Courier Prime)';
      default:
        return fontKey;
    }
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final settings = ref.watch(settingsProvider);
    final notifier = ref.read(settingsProvider.notifier);
    final l10n = AppLocalizations.of(context);

    final presetColors = <_ThemePreset>[
      _ThemePreset(l10n.mikuTheme, kMikuTeal),
      const _ThemePreset('Azul / Blue', Colors.blue),
      const _ThemePreset('Roxo / Purple', Colors.purple),
      const _ThemePreset('Laranja / Orange', Colors.orange),
      const _ThemePreset('Rosa / Pink', Colors.pink),
    ];

    return Scaffold(
      appBar: AppBar(title: Text(l10n.settingsTitle)),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          SwitchListTile(
            title: Text(l10n.darkMode),
            value: settings.isDarkMode,
            onChanged: (val) => notifier.toggleTheme(val),
          ),
          SwitchListTile(
            title: Text(l10n.soundEffects),
            subtitle: Text(l10n.soundSubtitle),
            value: settings.soundEnabled,
            onChanged: (val) => notifier.toggleSound(val),
          ),
          const Divider(),

          ListTile(
            title: Text('${l10n.fontSize}: ${(settings.fontSizeMultiplier * 100).round()}%'),
            subtitle: Slider(
              min: 0.85,
              max: 1.30,
              divisions: 9,
              value: settings.fontSizeMultiplier.clamp(0.85, 1.30),
              onChanged: (val) => notifier.setFontSize(val),
            ),
          ),
          const Divider(),

          ListTile(title: Text(l10n.fontFamily)),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16.0),
            child: DropdownButtonFormField<String>(
              value: kAvailableGoogleFonts.contains(settings.fontFamily)
                  ? settings.fontFamily
                  : 'Roboto',
              decoration: const InputDecoration(border: OutlineInputBorder()),
              items: kAvailableGoogleFonts
                  .map((f) => DropdownMenuItem(value: f, child: Text(_fontLabel(f))))
                  .toList(),
              onChanged: (val) {
                if (val != null) notifier.setFontFamily(val);
              },
            ),
          ),
          const SizedBox(height: 20),

          ListTile(title: Text(l10n.seedColor)),
          Wrap(
            spacing: 12,
            runSpacing: 12,
            alignment: WrapAlignment.center,
            children: presetColors.map((preset) {
              final isSelected = settings.seedColor.value == preset.color.value;

              return ChoiceChip(
                avatar: CircleAvatar(backgroundColor: preset.color, radius: 10),
                label: Text(preset.name),
                selected: isSelected,
                onSelected: (_) => notifier.setSeedColor(preset.color),
              );
            }).toList(),
          ),
        ],
      ),
    );
  }
}