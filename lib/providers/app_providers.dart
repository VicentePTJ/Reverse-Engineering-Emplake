import 'dart:math';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../engine/math_engine.dart';
import '../services/firestore_service.dart';
import '../services/sound_service.dart';

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
  final bool musicEnabled; // <--- Novo campo
  final String languageCode;

  AppSettings({
    required this.isDarkMode,
    required this.fontFamily,
    required this.fontSizeMultiplier,
    required this.seedColor,
    required this.soundEnabled,
    required this.musicEnabled,
    required this.languageCode,
  });

AppSettings copyWith({
    bool? isDarkMode,
    String? fontFamily,
    double? fontSizeMultiplier,
    Color? seedColor,
    bool? soundEnabled,
    bool? musicEnabled,
    String? languageCode,
  }) {
    return AppSettings(
      isDarkMode: isDarkMode ?? this.isDarkMode,
      fontFamily: fontFamily ?? this.fontFamily,
      fontSizeMultiplier: fontSizeMultiplier ?? this.fontSizeMultiplier,
      seedColor: seedColor ?? this.seedColor,
      soundEnabled: soundEnabled ?? this.soundEnabled,
      musicEnabled: musicEnabled ?? this.musicEnabled,
      languageCode: languageCode ?? this.languageCode,
    );
  }
}

class SettingsNotifier extends StateNotifier<AppSettings> {
  final SharedPreferences prefs;
  final SoundService soundService;

  SettingsNotifier(this.prefs, this.soundService) : super(_loadInitial(prefs));

  static AppSettings _loadInitial(SharedPreferences prefs) {
    final savedFont = prefs.getString('fontFamily') ?? 'Roboto';
    final safeFont = kAvailableGoogleFonts.contains(savedFont) ? savedFont : 'Roboto';

    return AppSettings(
      isDarkMode: prefs.getBool('isDarkMode') ?? false,
      fontFamily: safeFont,
      fontSizeMultiplier: prefs.getDouble('fontSizeMultiplier') ?? 1.0,
      seedColor: Color(prefs.getInt('seedColor') ?? kMikuTeal.value),
      soundEnabled: prefs.getBool('soundEnabled') ?? false,
      musicEnabled: false, // Sempre inicia desligada ao abrir o app (usabilidade)
      languageCode: prefs.getString('languageCode') ?? 'pt',
    );
  }

  void toggleMusic(bool enabled) {
    state = state.copyWith(musicEnabled: enabled);
    if (enabled) {
      soundService.startMikuMusic();
    } else {
      soundService.stopMikuMusic();
    }
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
    // Toca um som imediato ao ativar para confirmar o funcionamento no navegador
    if (enabled) {
      soundService.playClick();
    }
  }

  void setLanguage(String code) {
    prefs.setString('languageCode', code);
    state = state.copyWith(languageCode: code);
  }
}

enum FeedbackStatus { none, success, error }

enum MikuMood { thinking, happy, oops }

class GameState {
  final String? syncedUserId;
  final String currentNumber;
  final DifficultyLevel level;
  final List<List<String>> operatorSlots;
  final int activeSlotIndex;
  final List<String> solvedNumbers;
  final int score;
  final bool isAnimating;
  final String feedbackMessage;
  final FeedbackStatus feedbackStatus;
  final MikuMood mikuMood;

  GameState({
    this.syncedUserId,
    required this.currentNumber,
    required this.level,
    required this.operatorSlots,
    this.activeSlotIndex = 1,
    required this.solvedNumbers,
    this.score = 0,
    this.isAnimating = false,
    this.feedbackMessage = '',
    this.feedbackStatus = FeedbackStatus.none,
    this.mikuMood = MikuMood.thinking,
  });

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
    String? syncedUserId,
    String? currentNumber,
    DifficultyLevel? level,
    List<List<String>>? operatorSlots,
    int? activeSlotIndex,
    List<String>? solvedNumbers,
    int? score,
    bool? isAnimating,
    String? feedbackMessage,
    FeedbackStatus? feedbackStatus,
    MikuMood? mikuMood,
  }) {
    return GameState(
      syncedUserId: syncedUserId ?? this.syncedUserId,
      currentNumber: currentNumber ?? this.currentNumber,
      level: level ?? this.level,
      operatorSlots: operatorSlots ?? this.operatorSlots,
      activeSlotIndex: activeSlotIndex ?? this.activeSlotIndex,
      solvedNumbers: solvedNumbers ?? this.solvedNumbers,
      score: score ?? this.score,
      isAnimating: isAnimating ?? this.isAnimating,
      feedbackMessage: feedbackMessage ?? this.feedbackMessage,
      feedbackStatus: feedbackStatus ?? this.feedbackStatus,
      mikuMood: mikuMood ?? this.mikuMood,
    );
  }
}

class GameNotifier extends StateNotifier<GameState> {
  final FirestoreService firestoreService;
  final SoundService soundService;
  final Ref ref;

  GameNotifier(this.firestoreService, this.soundService, this.ref)
      : super(GameState(
          currentNumber: '8131',
          level: DifficultyLevel.facil,
          operatorSlots: _defaultSlots(),
          activeSlotIndex: 1,
          solvedNumbers: const [],
          score: 0,
        ));

  static List<List<String>> _defaultSlots() {
    return [
      [],
      [],
      ['='],
      [],
      [],
    ];
  }

  bool get _isSoundEnabled => ref.read(settingsProvider).soundEnabled;

  void _playClick() {
    if (_isSoundEnabled) soundService.playClick();
  }

  void _playSuccess() {
    if (_isSoundEnabled) soundService.playSuccess();
  }

  void _playError() {
    if (_isSoundEnabled) soundService.playError();
  }

  void syncFromFirestore(String uid, UserGameProfile profile) {
    if (state.syncedUserId == uid) return;

    final nextUnsolved = profile.solvedNumbers.contains(state.currentNumber)
        ? FirestoreService.pickUnsolvedNumber(profile.solvedNumbers)
        : state.currentNumber;

    state = state.copyWith(
      syncedUserId: uid,
      solvedNumbers: profile.solvedNumbers,
      score: profile.score,
      currentNumber: nextUnsolved,
      operatorSlots: _defaultSlots(),
      activeSlotIndex: 1,
      feedbackStatus: FeedbackStatus.none,
      mikuMood: MikuMood.thinking,
    );
  }

  void selectSlot(int index) {
    if (index >= 0 && index <= 4) {
      _playClick();
      state = state.copyWith(activeSlotIndex: index, feedbackStatus: FeedbackStatus.none);
    }
  }

  void smartInsertOperator(String op) {
    _playClick();
    final slots = state.operatorSlots.map((s) => List<String>.from(s)).toList();
    int targetSlot = state.activeSlotIndex;

    if (op == '=') {
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

    if (op == '(') {
      final openSlot = targetSlot > 3 ? 0 : targetSlot;
      final closeSlot = min(openSlot + 2, 4);
      slots[openSlot].add('(');
      slots[closeSlot].insert(0, ')');
      state = state.copyWith(operatorSlots: slots, feedbackStatus: FeedbackStatus.none, mikuMood: MikuMood.thinking);
      return;
    }

    if (op == '|') {
      final openSlot = targetSlot > 3 ? 0 : targetSlot;
      final closeSlot = min(openSlot + 2, 4);
      slots[openSlot].add('|');
      slots[closeSlot].insert(0, '|');
      state = state.copyWith(operatorSlots: slots, feedbackStatus: FeedbackStatus.none, mikuMood: MikuMood.thinking);
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

    if (op == '√' || op == '∛') {
      final prefixSlot = targetSlot == 4 ? 3 : targetSlot;
      slots[prefixSlot].add(op);
      state = state.copyWith(operatorSlots: slots, feedbackStatus: FeedbackStatus.none, mikuMood: MikuMood.thinking);
      return;
    }

    if (op == '!') {
      final postSlot = targetSlot == 0 ? 1 : targetSlot;
      slots[postSlot].add('!');
      state = state.copyWith(operatorSlots: slots, feedbackStatus: FeedbackStatus.none, mikuMood: MikuMood.thinking);
      return;
    }

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

  void insertOperatorAtSlot(int slotIndex, String op) {
    _playClick();
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

  void moveOperator(int fromSlot, int tokenIndex, int toSlot) {
    _playClick();
    final slots = state.operatorSlots.map((s) => List<String>.from(s)).toList();
    final op = slots[fromSlot].removeAt(tokenIndex);
    slots[toSlot].add(op);
    state = state.copyWith(
      operatorSlots: slots,
      activeSlotIndex: toSlot,
      feedbackStatus: FeedbackStatus.none,
    );
  }

  void removeOperatorAt(int slotIndex, int tokenIndex) {
    _playClick();
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
    _playClick();
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
    if (status == FeedbackStatus.error) {
      _playError();
    }
    state = state.copyWith(
      feedbackMessage: message,
      feedbackStatus: status,
      mikuMood: mood,
    );
  }

  void skipCurrentNumber() {
    _playClick();
    final nextNum = FirestoreService.pickUnsolvedNumber(
      state.solvedNumbers,
      excludeCurrent: state.currentNumber,
    );

    state = state.copyWith(
      currentNumber: nextNum,
      operatorSlots: _defaultSlots(),
      activeSlotIndex: 1,
      feedbackStatus: FeedbackStatus.none,
      mikuMood: MikuMood.thinking,
    );
  }

  Future<void> markCurrentAsSolved(String successMsg) async {
    // Toca imediatamente dentro do gesto de clique do usuário (evita bloqueio do navegador)
    _playSuccess();

    final user = FirebaseAuth.instance.currentUser;
    final solvedNum = state.currentNumber;
    final points = FirestoreService.pointsForLevel(state.level);
    final updatedSolved = state.solvedNumbers.contains(solvedNum)
        ? state.solvedNumbers
        : [...state.solvedNumbers, solvedNum];
    final updatedScore = state.score + points;

    if (user != null) {
      await firestoreService.saveSolvedNumber(
        user: user,
        number: solvedNum,
        pointsEarned: points,
      );
    }

    state = state.copyWith(
      solvedNumbers: updatedSolved,
      score: updatedScore,
      feedbackMessage: '$successMsg (+$points pts)',
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

final firestoreServiceProvider = Provider<FirestoreService>((ref) => FirestoreService());

final soundServiceProvider = Provider<SoundService>((ref) => SoundService());

final settingsProvider = StateNotifierProvider<SettingsNotifier, AppSettings>((ref) {
  final prefs = ref.watch(sharedPreferencesProvider);
  final soundService = ref.watch(soundServiceProvider);
  return SettingsNotifier(prefs, soundService);
});

final gameProvider = StateNotifierProvider<GameNotifier, GameState>((ref) {
  final firestoreService = ref.watch(firestoreServiceProvider);
  final soundService = ref.watch(soundServiceProvider);
  return GameNotifier(firestoreService, soundService, ref);
});