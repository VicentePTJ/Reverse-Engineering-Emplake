import 'dart:math';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../engine/math_engine.dart';

typedef JsonMap = Map<String, dynamic>;

class UserGameProfile {
  final int score;
  final List<String> solvedNumbers;

  const UserGameProfile({
    required this.score,
    required this.solvedNumbers,
  });

  factory UserGameProfile.fromMap(JsonMap? data) {
    if (data == null) {
      return const UserGameProfile(score: 0, solvedNumbers: []);
    }
    final rawList = data['solvedNumbers'] as List<dynamic>? ?? [];
    return UserGameProfile(
      score: (data['score'] as num?)?.toInt() ?? 0,
      solvedNumbers: rawList.map((e) => e.toString()).toList(),
    );
  }
}

class FirestoreService {
  final FirebaseFirestore _db = FirebaseFirestore.instance;

  DocumentReference<JsonMap> _userDoc(String uid) {
    return _db.collection('users').doc(uid);
  }

  /// Lê os dados do usuário no Firestore (pontuação e números já resolvidos)
  Future<UserGameProfile> getUserProfile(User user) async {
    final docRef = _userDoc(user.uid);
    final snapshot = await docRef.get();

    if (!snapshot.exists) {
      await docRef.set({
        'email': user.email ?? '',
        'displayName': user.displayName ?? '',
        'score': 0,
        'solvedNumbers': <String>[],
        'createdAt': FieldValue.serverTimestamp(),
      });
      return const UserGameProfile(score: 0, solvedNumbers: []);
    }

    return UserGameProfile.fromMap(snapshot.data());
  }

  /// Grava o número resolvido e soma a pontuação no documento do usuário no Firestore
  Future<void> saveSolvedNumber({
    required User user,
    required String number,
    required int pointsEarned,
  }) async {
    await _userDoc(user.uid).set({
      'email': user.email ?? '',
      'displayName': user.displayName ?? '',
      'score': FieldValue.increment(pointsEarned),
      'solvedNumbers': FieldValue.arrayUnion([number]),
      'updatedAt': FieldValue.serverTimestamp(),
    }, SetOptions(merge: true));
  }

  /// Calcula pontos ganhos de acordo com a dificuldade
  static int pointsForLevel(DifficultyLevel level) {
    switch (level) {
      case DifficultyLevel.facil:
        return 10;
      case DifficultyLevel.intermediario:
        return 20;
      case DifficultyLevel.avancado:
        return 30;
      case DifficultyLevel.dificil:
        return 50;
    }
  }

  /// Sorteia um número aleatório de 4 dígitos verificando antes se o usuário já o resolveu
  static String pickUnsolvedNumber(List<String> solvedNumbers, {String? excludeCurrent}) {
    final random = Random();
    final solvedSet = solvedNumbers.toSet();

    if (solvedSet.length >= 9000) {
      return '8131';
    }

    String candidate;
    int attempts = 0;
    do {
      candidate = (1000 + random.nextInt(9000)).toString();
      attempts++;
    } while ((solvedSet.contains(candidate) || candidate == excludeCurrent) && attempts < 10000);

    return candidate;
  }
}