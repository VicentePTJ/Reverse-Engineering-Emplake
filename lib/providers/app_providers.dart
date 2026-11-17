import 'dart:math';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../engine/math_engine.dart';
import '../models/vocaloid_achievement.dart';
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
  final bool musicEnabled;
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
      musicEnabled: false,
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
  final String? equippedAchievementId;
  final VocaloidAchievement? lastUnlockedAchievement;

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
    this.equippedAchievementId,
    this.lastUnlockedAchievement,
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

  VocaloidAchievement? get equippedAchievement {
    if (equippedAchievementId == null) return null;
    for (final a in kVocaloidAchievements) {
      if (a.id == equippedAchievementId && a.isUnlocked(score)) {
        return a;
      }
    }
    return null;
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
    String? equippedAchievementId,
    VocaloidAchievement? lastUnlockedAchievement,
    bool clearLastUnlocked = false,
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
      equippedAchievementId: equippedAchievementId ?? this.equippedAchievementId,
      lastUnlockedAchievement: clearLastUnlocked
          ? null
          : (lastUnlockedAchievement ?? this.lastUnlockedAchievement),
    );
  }
}

class GameNotifier extends StateNotifier<GameState> {
  final FirestoreService firestoreService;
  final SoundService soundService;
  final SharedPreferences prefs;
  final Ref ref;

  static const String _equippedIconKey = 'equipped_vocaloid_achievement_id';

  GameNotifier(this.firestoreService, this.soundService, this.prefs, this.ref)
      : super(GameState(
          currentNumber: '8131',
          level: DifficultyLevel.facil,
          operatorSlots: _defaultSlots(),
          activeSlotIndex: 1,
          solvedNumbers: const [],
          score: 0,
          equippedAchievementId: prefs.getString(_equippedIconKey),
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

  static List<List<String>> _emptySlots() {
    return [
      [],
      [],
      [],
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

    // Se o usuário já tinha pontos mas nenhum ícone equipado, equipa o primeiro desbloqueado
    String? equipped = state.equippedAchievementId;
    if (equipped == null) {
      for (final a in kVocaloidAchievements) {
        if (a.isUnlocked(profile.score)) {
          equipped = a.id;
          prefs.setString(_equippedIconKey, a.id);
          break;
        }
      }
    }

    state = state.copyWith(
      syncedUserId: uid,
      solvedNumbers: profile.solvedNumbers,
      score: profile.score,
      currentNumber: nextUnsolved,
      operatorSlots: _defaultSlots(),
      activeSlotIndex: 1,
      feedbackStatus: FeedbackStatus.none,
      mikuMood: MikuMood.thinking,
      equippedAchievementId: equipped,
    );
  }

  void equipAchievement(String achievementId) {
    final target = kVocaloidAchievements.where((a) => a.id == achievementId).firstOrNull;
    if (target == null || !target.isUnlocked(state.score)) return;
    _playClick();
    prefs.setString(_equippedIconKey, achievementId);
    state = state.copyWith(equippedAchievementId: achievementId);
  }

  void clearLastUnlockedAchievement() {
    state = state.copyWith(clearLastUnlocked: true);
  }

  void selectSlot(int index) {
    if (state.isAnimating) return;
    if (index >= 0 && index <= 4) {
      _playClick();
      state = state.copyWith(activeSlotIndex: index, feedbackStatus: FeedbackStatus.none);
    }
  }

  void smartInsertOperator(String op) {
    if (state.isAnimating) return;
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
      state = state.copyWith(
        operatorSlots: slots,
        feedbackStatus: FeedbackStatus.none,
        mikuMood: MikuMood.thinking,
      );
      return;
    }

    if (op == '⌈') {
      final openSlot = targetSlot > 3 ? 0 : targetSlot;
      final closeSlot = min(openSlot + 1, 4);
      slots[openSlot].add('⌈');
      slots[closeSlot].insert(0, '⌉');
      state = state.copyWith(
        operatorSlots: slots,
        feedbackStatus: FeedbackStatus.none,
        mikuMood: MikuMood.thinking,
      );
      return;
    }

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
    if (state.isAnimating) return;
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
    if (state.isAnimating) return;
    _playClick();
    final slots = state.operatorSlots.map((s) => List<String>.from(s)).toList();
    final op = slots[fromSlot].removeAt(tokenIndex);
    slots[toSlot].add(op);
    state = state.copyWith(
      operatorSlots: slots,
      activeSlotIndex: toSlot,
      feedbackStatus: FeedbackStatus.none,
      mikuMood: MikuMood.thinking,
    );
  }

  void removeOperatorAt(int slotIndex, int tokenIndex) {
    if (state.isAnimating) return;
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

  void startReturnAnimation({bool isSuccess = false, String? successMsg, int? pointsEarned}) {
    if (!isSuccess) {
      _playClick();
    }
    state = state.copyWith(
      operatorSlots: _emptySlots(),
      isAnimating: true,
      feedbackMessage: isSuccess && successMsg != null ? '$successMsg (+${pointsEarned ?? 0} pts)' : '',
      feedbackStatus: isSuccess ? FeedbackStatus.success : FeedbackStatus.none,
      mikuMood: isSuccess ? MikuMood.happy : MikuMood.thinking,
    );
  }

  void finishClearAnimation() {
    state = state.copyWith(
      operatorSlots: _defaultSlots(),
      activeSlotIndex: 1,
      isAnimating: false,
      feedbackStatus: FeedbackStatus.none,
      feedbackMessage: '',
      mikuMood: MikuMood.thinking,
    );
  }

  void clearFormula() {
    finishClearAnimation();
  }

  void setLevel(DifficultyLevel level) {
    state = state.copyWith(level: level);
    finishClearAnimation();
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

  void resetMikuMood() {
    state = state.copyWith(
      isAnimating: false,
      mikuMood: MikuMood.thinking,
      feedbackStatus: FeedbackStatus.none,
      feedbackMessage: '',
    );
  }

  void skipCurrentNumber() {
    if (!state.isAnimating) {
      _playClick();
    }
    final nextNum = FirestoreService.pickUnsolvedNumber(
      state.solvedNumbers,
      excludeCurrent: state.currentNumber,
    );

    state = state.copyWith(
      currentNumber: nextNum,
      operatorSlots: _defaultSlots(),
      activeSlotIndex: 1,
      isAnimating: false,
      mikuMood: MikuMood.thinking,
      feedbackStatus: FeedbackStatus.none,
      feedbackMessage: '',
    );
  }

  /// Salva a pontuação no Firestore e verifica se uma nova conquista foi desbloqueada
  Future<int> saveSolvedToCloud() async {
    _playSuccess();

    final user = FirebaseAuth.instance.currentUser;
    final solvedNum = state.currentNumber;
    final points = FirestoreService.pointsForLevel(state.level);
    final updatedSolved = state.solvedNumbers.contains(solvedNum)
        ? state.solvedNumbers
        : [...state.solvedNumbers, solvedNum];
    final previousScore = state.score;
    final updatedScore = previousScore + points;

    if (user != null) {
      await firestoreService.saveSolvedNumber(
        user: user,
        number: solvedNum,
        pointsEarned: points,
      );
    }

    // Verifica se cruzou a meta de alguma conquista agora
    VocaloidAchievement? newlyUnlocked;
    for (final achievement in kVocaloidAchievements) {
      if (previousScore < achievement.requiredPoints &&
          updatedScore >= achievement.requiredPoints) {
        newlyUnlocked = achievement;
      }
    }

    String? equipped = state.equippedAchievementId;
    if (newlyUnlocked != null && equipped == null) {
      equipped = newlyUnlocked.id;
      await prefs.setString(_equippedIconKey, equipped);
    }

    state = state.copyWith(
      solvedNumbers: updatedSolved,
      score: updatedScore,
      equippedAchievementId: equipped,
      lastUnlockedAchievement: newlyUnlocked,
    );
    return points;
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
  final prefs = ref.watch(sharedPreferencesProvider);
  return GameNotifier(firestoreService, soundService, prefs, ref);
});