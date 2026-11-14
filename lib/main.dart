import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:google_fonts/google_fonts.dart';
import 'l10n/app_localizations.dart';
import 'providers/app_providers.dart';
import 'router/app_router.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  final prefs = await SharedPreferences.getInstance();

  runApp(
    ProviderScope(
      overrides: [
        sharedPreferencesProvider.overrideWithValue(prefs),
      ],
      child: const EmplakeApp(),
    ),
  );
}

class EmplakeApp extends ConsumerWidget {
  const EmplakeApp({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final settings = ref.watch(settingsProvider);
    final prefs = ref.watch(sharedPreferencesProvider);
    final router = createRouter(prefs);

    final brightness = settings.isDarkMode ? Brightness.dark : Brightness.light;
    final colorScheme = ColorScheme.fromSeed(
      seedColor: settings.seedColor,
      brightness: brightness,
    );

    final baseTheme = ThemeData(
      useMaterial3: true,
      brightness: brightness,
      colorScheme: colorScheme,
    );

    TextTheme resolvedTextTheme;
    try {
      resolvedTextTheme = GoogleFonts.getTextTheme(
        settings.fontFamily,
        baseTheme.textTheme,
      );
    } catch (_) {
      resolvedTextTheme = baseTheme.textTheme;
    }

    return MaterialApp.router(
      title: 'Emplake Game',
      debugShowCheckedModeBanner: false,
      routerConfig: router,
      locale: Locale(settings.languageCode),
      supportedLocales: const [
        Locale('pt'),
        Locale('en'),
      ],
      localizationsDelegates: const [
        AppLocalizations.delegate,
        GlobalMaterialLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
      ],
      builder: (context, child) {
        return MediaQuery(
          data: MediaQuery.of(context).copyWith(
            textScaler: TextScaler.linear(settings.fontSizeMultiplier),
          ),
          child: child!,
        );
      },
      theme: baseTheme.copyWith(textTheme: resolvedTextTheme),
    );
  }
}