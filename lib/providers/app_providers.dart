import 'dart:math';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../engine/math_engine.dart';

const Color kMikuTeal = Color(0xFF39C5BB);

const List<String> kAvailableGoogleFonts = [
  'Roboto',
  'EB Garamond',
  'Lato',
  'Courier Prime',
  'Poppins',
  'Lora',
];

class AppSettings {
  final bool isDarkMode;
  final String fontFamily;
  final double fontSizeMultiplier;
  final Color seedColor;
  final bool soundEnabled;
  final String languageCode;

  AppSettings({
    required this.isDarkMode,
    required this.fontFamily,
    required this.fontSizeMultiplier,
    required this.seedColor,
    required this.soundEnabled,
    required this.languageCode,
  });

  AppSettings copyWith({
    bool? isDarkMode,
    String? fontFamily,
    double? fontSizeMultiplier,
    Color? seedColor,
    bool? soundEnabled,
    String? languageCode,
  }) {
    return AppSettings(
      isDarkMode: isDarkMode ?? this.isDarkMode,
      fontFamily: fontFamily ?? this.fontFamily,
      fontSizeMultiplier: fontSizeMultiplier ?? this.fontSizeMultiplier,
      seedColor: seedColor ?? this.seedColor,
      soundEnabled: soundEnabled ?? this.soundEnabled,
      languageCode: languageCode ?? this.languageCode,
    );
  }
}

class SettingsNotifier extends StateNotifier<AppSettings> {
  final SharedPreferences prefs;

  SettingsNotifier(this.prefs) : super(_loadInitial(prefs));

  static AppSettings _loadInitial(SharedPreferences prefs) {
    final savedFont = prefs.getString('fontFamily') ?? 'Roboto';
    final safeFont = kAvailableGoogleFonts.contains(savedFont) ? savedFont : 'Roboto';

    return AppSettings(
      isDarkMode: prefs.getBool('isDarkMode') ?? false,
      fontFamily: safeFont,
      fontSizeMultiplier: prefs.getDouble('fontSizeMultiplier') ?? 1.0,
      seedColor: Color(prefs.getInt('seedColor') ?? kMikuTeal.value),
      soundEnabled: prefs.getBool('soundEnabled') ?? false,
      languageCode: prefs.getString('languageCode') ?? 'pt',
    );
  }

  void toggleTheme(bool isDark) {
    prefs.setBool('isDarkMode', isDark);
    state = state.copyWith(isDarkMode: isDark);
  }

  void setSeedColor(Color color) {
    prefs.setInt('seedColor', color.value);
    state = state.copyWith(seedColor: color);
  }

  void setFontFamily(String family) {
    final safeFont = kAvailableGoogleFonts.contains(family) ? family : 'Roboto';
    prefs.setString('fontFamily', safeFont);
    state = state.copyWith(fontFamily: safeFont);
  }

  void setFontSize(double scale) {
    prefs.setDouble('fontSizeMultiplier', scale);
    state = state.copyWith(fontSizeMultiplier: scale);
  }

  void toggleSound(bool enabled) {
    prefs.setBool('soundEnabled', enabled);
    state = state.copyWith(soundEnabled: enabled);
  }

  void setLanguage(String code) {
    prefs.setString('languageCode', code);
    state = state.copyWith(languageCode: code);
  }
}

enum FeedbackStatus { none, success, error }

enum MikuMood { thinking, happy, oops }

class GameState {
  final String currentNumber;
  final DifficultyLevel level;
  /// 5 slots ao redor dos 4 dígitos: [antes D0, entre D0-D1, entre D1-D2, entre D2-D3, depois D3]
  final List<List<String>> operatorSlots;
  final int activeSlotIndex;
  final List<String> solvedNumbers;
  final bool isAnimating;
  final String feedbackMessage;
  final FeedbackStatus feedbackStatus;
  final MikuMood mikuMood;

  GameState({
    required this.currentNumber,
    required this.level,
    required this.operatorSlots,
    this.activeSlotIndex = 1,
    required this.solvedNumbers,
    this.isAnimating = false,
    this.feedbackMessage = '',
    this.feedbackStatus = FeedbackStatus.none,
    this.mikuMood = MikuMood.thinking,
  });

  /// Monta a lista linear completa intercalando os 5 slots com os 4 dígitos fixos
  List<String> get fullTokens {
    final digits = currentNumber.split('');
    final result = <String>[];
    for (int i = 0; i < digits.length; i++) {
      result.addAll(operatorSlots[i]);
      result.add(digits[i]);
    }
    result.addAll(operatorSlots[digits.length]);
    return result;
  }

  GameState copyWith({
    String? currentNumber,
    DifficultyLevel? level,
    List<List<String>>? operatorSlots,
    int? activeSlotIndex,
    List<String>? solvedNumbers,
    bool? isAnimating,
    String? feedbackMessage,
    FeedbackStatus? feedbackStatus,
    MikuMood? mikuMood,
  }) {
    return GameState(
      currentNumber: currentNumber ?? this.currentNumber,
      level: level ?? this.level,
      operatorSlots: operatorSlots ?? this.operatorSlots,
      activeSlotIndex: activeSlotIndex ?? this.activeSlotIndex,
      solvedNumbers: solvedNumbers ?? this.solvedNumbers,
      isAnimating: isAnimating ?? this.isAnimating,
      feedbackMessage: feedbackMessage ?? this.feedbackMessage,
      feedbackStatus: feedbackStatus ?? this.feedbackStatus,
      mikuMood: mikuMood ?? this.mikuMood,
    );
  }
}

class GameNotifier extends StateNotifier<GameState> {
  final SharedPreferences prefs;
  final Ref ref;

  GameNotifier(this.prefs, this.ref)
      : super(GameState(
          currentNumber: '8131',
          level: DifficultyLevel.facil,
          operatorSlots: _defaultSlots(),
          activeSlotIndex: 1,
          solvedNumbers: prefs.getStringList('solvedNumbers') ?? [],
        ));

  static List<List<String>> _defaultSlots() {
    // O sinal de '=' já inicia posicionado no meio (slot 2)
    return [
      [],
      [],
      ['='],
      [],
      [],
    ];
  }

  void _playClickIfEnabled() {
    if (ref.read(settingsProvider).soundEnabled) {
      SystemSound.play(SystemSoundType.click);
    }
  }

  void selectSlot(int index) {
    if (index >= 0 && index <= 4) {
      state = state.copyWith(activeSlotIndex: index, feedbackStatus: FeedbackStatus.none);
    }
  }

  /// Inserção automática inteligente no slot ativo (ao tocar em um operador)
  void smartInsertOperator(String op) {
    _playClickIfEnabled();
    final slots = state.operatorSlots.map((s) => List<String>.from(s)).toList();
    int targetSlot = state.activeSlotIndex;

    if (op == '=') {
      // Remove '=' anterior e coloca no slot ativo (ou no slot 2 se estiver nas pontas)
      for (final s in slots) {
        s.remove('=');
      }
      final eqSlot = (targetSlot == 0 || targetSlot == 4) ? 2 : targetSlot;
      slots[eqSlot].add('=');
      state = state.copyWith(
        operatorSlots: slots,
        feedbackStatus: FeedbackStatus.none,
        mikuMood: MikuMood.thinking,
      );
      return;
    }

    // Operadores de agrupamento inserem o par automaticamente ao redor do dígito seguinte
    if (op == '(') {
      final openSlot = targetSlot > 3 ? 0 : targetSlot;
      final closeSlot = min(openSlot + 2, 4);
      slots[openSlot].add('(');
      slots[closeSlot].insert(0, ')');
      state = state.copyWith(
        operatorSlots: slots,
        feedbackStatus: FeedbackStatus.none,
        mikuMood: MikuMood.thinking,
      );
      return;
    }

    if (op == '|') {
      final openSlot = targetSlot > 3 ? 0 : targetSlot;
      final closeSlot = min(openSlot + 2, 4);
      slots[openSlot].add('|');
      slots[closeSlot].insert(0, '|');
      state = state.copyWith(
        operatorSlots: slots,
        feedbackStatus: FeedbackStatus.none,
        mikuMood: MikuMood.thinking,
      );
      return;
    }

    if (op == '⌊') {
      final openSlot = targetSlot > 3 ? 0 : targetSlot;
      final closeSlot = min(openSlot + 1, 4);
      slots[openSlot].add('⌊');
      slots[closeSlot].insert(0, '⌋');
      state = state.copyWith(operatorSlots: slots, feedbackStatus: FeedbackStatus.none);
      return;
    }

    if (op == '⌈') {
      final openSlot = targetSlot > 3 ? 0 : targetSlot;
      final closeSlot = min(openSlot + 1, 4);
      slots[openSlot].add('⌈');
      slots[closeSlot].insert(0, '⌉');
      state = state.copyWith(operatorSlots: slots, feedbackStatus: FeedbackStatus.none);
      return;
    }

    // Prefixos (√, ∛) entram antes do dígito
    if (op == '√' || op == '∛') {
      final prefixSlot = targetSlot == 4 ? 3 : targetSlot;
      slots[prefixSlot].add(op);
      state = state.copyWith(
        operatorSlots: slots,
        feedbackStatus: FeedbackStatus.none,
        mikuMood: MikuMood.thinking,
      );
      return;
    }

    // Pós-fixo (!) entra depois de um dígito
    if (op == '!') {
      final postSlot = targetSlot == 0 ? 1 : targetSlot;
      slots[postSlot].add('!');
      state = state.copyWith(
        operatorSlots: slots,
        feedbackStatus: FeedbackStatus.none,
        mikuMood: MikuMood.thinking,
      );
      return;
    }

    // Operadores binários (+, -, *, /, **) entram no meio dos números e avançam o cursor sozinhos
    int binarySlot = targetSlot;
    if (binarySlot == 0 && op != '-') binarySlot = 1;
    if (binarySlot == 4) binarySlot = 3;

    slots[binarySlot].add(op);
    final nextSlot = binarySlot < 3 ? binarySlot + 1 : 1;

    state = state.copyWith(
      operatorSlots: slots,
      activeSlotIndex: nextSlot,
      feedbackStatus: FeedbackStatus.none,
      mikuMood: MikuMood.thinking,
    );
  }

  /// Inserção direta via Drag & Drop em qualquer slot escolhido pelo usuário
  void insertOperatorAtSlot(int slotIndex, String op) {
    _playClickIfEnabled();
    final slots = state.operatorSlots.map((s) => List<String>.from(s)).toList();

    if (op == '=') {
      for (final s in slots) {
        s.remove('=');
      }
    }

    slots[slotIndex].add(op);
    state = state.copyWith(
      operatorSlots: slots,
      activeSlotIndex: slotIndex,
      feedbackStatus: FeedbackStatus.none,
      mikuMood: MikuMood.thinking,
    );
  }

  /// Move um operador já posicionado de um slot para outro via Drag & Drop
  void moveOperator(int fromSlot, int tokenIndex, int toSlot) {
    _playClickIfEnabled();
    final slots = state.operatorSlots.map((s) => List<String>.from(s)).toList();
    final op = slots[fromSlot].removeAt(tokenIndex);
    slots[toSlot].add(op);
    state = state.copyWith(
      operatorSlots: slots,
      activeSlotIndex: toSlot,
      feedbackStatus: FeedbackStatus.none,
    );
  }

  /// Remove um operador individualmente
  void removeOperatorAt(int slotIndex, int tokenIndex) {
    _playClickIfEnabled();
    final slots = state.operatorSlots.map((s) => List<String>.from(s)).toList();
    if (tokenIndex >= 0 && tokenIndex < slots[slotIndex].length) {
      slots[slotIndex].removeAt(tokenIndex);
      state = state.copyWith(
        operatorSlots: slots,
        activeSlotIndex: slotIndex,
        feedbackStatus: FeedbackStatus.none,
        mikuMood: MikuMood.thinking,
      );
    }
  }

  void clearFormula() {
    _playClickIfEnabled();
    state = state.copyWith(
      operatorSlots: _defaultSlots(),
      activeSlotIndex: 1,
      isAnimating: true,
      feedbackStatus: FeedbackStatus.none,
      mikuMood: MikuMood.thinking,
    );
    Future.delayed(const Duration(milliseconds: 300), () {
      if (mounted) {
        state = state.copyWith(isAnimating: false);
      }
    });
  }

  void setLevel(DifficultyLevel level) {
    state = state.copyWith(level: level);
    clearFormula();
  }

  void setFeedback(String message, FeedbackStatus status, MikuMood mood) {
    state = state.copyWith(
      feedbackMessage: message,
      feedbackStatus: status,
      mikuMood: mood,
    );
  }

  void skipCurrentNumber() {
    _playClickIfEnabled();
    final random = Random();
    String nextNum;
    do {
      nextNum = (1000 + random.nextInt(9000)).toString();
    } while (state.solvedNumbers.contains(nextNum));

    state = state.copyWith(
      currentNumber: nextNum,
      operatorSlots: _defaultSlots(),
      activeSlotIndex: 1,
      feedbackStatus: FeedbackStatus.none,
      mikuMood: MikuMood.thinking,
    );
  }

  void markCurrentAsSolved(String successMsg) {
    final updated = [...state.solvedNumbers, state.currentNumber];
    prefs.setStringList('solvedNumbers', updated);

    state = state.copyWith(
      solvedNumbers: updated,
      feedbackMessage: successMsg,
      feedbackStatus: FeedbackStatus.success,
      mikuMood: MikuMood.happy,
      isAnimating: true,
    );

    Future.delayed(const Duration(milliseconds: 1200), () {
      if (mounted) {
        state = state.copyWith(isAnimating: false);
        skipCurrentNumber();
      }
    });
  }
}

final sharedPreferencesProvider = Provider<SharedPreferences>((ref) => throw UnimplementedError());

final settingsProvider = StateNotifierProvider<SettingsNotifier, AppSettings>((ref) {
  final prefs = ref.watch(sharedPreferencesProvider);
  return SettingsNotifier(prefs);
});

final gameProvider = StateNotifierProvider<GameNotifier, GameState>((ref) {
  final prefs = ref.watch(sharedPreferencesProvider);
  return GameNotifier(prefs, ref);
});