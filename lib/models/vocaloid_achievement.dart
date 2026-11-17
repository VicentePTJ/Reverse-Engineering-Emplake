import 'package:flutter/material.dart';

class VocaloidAchievement {
  final String id;
  final String characterName;
  final String seriesCode;
  final String title;
  final String description;
  final int requiredPoints;
  final Color primaryColor;
  final Color secondaryColor;
  final IconData icon;

  const VocaloidAchievement({
    required this.id,
    required this.characterName,
    required this.seriesCode,
    required this.title,
    required this.description,
    required this.requiredPoints,
    required this.primaryColor,
    required this.secondaryColor,
    required this.icon,
  });

  bool isUnlocked(int currentScore) => currentScore >= requiredPoints;
}

const List<VocaloidAchievement> kVocaloidAchievements = [
  VocaloidAchievement(
    id: 'miku',
    characterName: 'Hatsune Miku',
    seriesCode: '01',
    title: 'Primeira Nota',
    description: 'Alcance 10 pontos resolvendo equações.',
    requiredPoints: 10,
    primaryColor: Color(0xFF39C5BB),
    secondaryColor: Color(0xFF0F4C48),
    icon: Icons.music_note_rounded,
  ),
  VocaloidAchievement(
    id: 'teto',
    characterName: 'Kasane Teto',
    seriesCode: '0401',
    title: 'Estrela UTAU',
    description: 'Alcance 30 pontos e desbloqueie a diva UTAU.',
    requiredPoints: 30,
    primaryColor: Color(0xFFE53935),
    secondaryColor: Color(0xFF7F0000),
    icon: Icons.cyclone_rounded,
  ),
  VocaloidAchievement(
    id: 'kagamine',
    characterName: 'Kagamine Rin & Len',
    seriesCode: '02',
    title: 'Sintonia Dupla',
    description: 'Alcance 60 pontos com cálculos em dobro.',
    requiredPoints: 60,
    primaryColor: Color(0xFFFFB300),
    secondaryColor: Color(0xFF7A4F01),
    icon: Icons.bolt_rounded,
  ),
  VocaloidAchievement(
    id: 'luka',
    characterName: 'Megurine Luka',
    seriesCode: '03',
    title: 'Mente Harmônica',
    description: 'Alcance 100 pontos com precisão matemática.',
    requiredPoints: 100,
    primaryColor: Color(0xFFEC407A),
    secondaryColor: Color(0xFF78002E),
    icon: Icons.graphic_eq_rounded,
  ),
  VocaloidAchievement(
    id: 'kaito',
    characterName: 'KAITO',
    seriesCode: '00',
    title: 'Lenda Synth',
    description: 'Alcance 150 pontos e domine todos os desafios.',
    requiredPoints: 150,
    primaryColor: Color(0xFF1E88E5),
    secondaryColor: Color(0xFF0D47A1),
    icon: Icons.auto_awesome_rounded,
  ),
];

/// Widget do iconezinho colecionável da Vocaloid / UTAU
class VocaloidIconBadge extends StatelessWidget {
  final VocaloidAchievement achievement;
  final bool unlocked;
  final double size;
  final bool showCodeTag;

  const VocaloidIconBadge({
    super.key,
    required this.achievement,
    required this.unlocked,
    this.size = 48,
    this.showCodeTag = true,
  });

  @override
  Widget build(BuildContext context) {
    final bgColors = unlocked
        ? [achievement.primaryColor, achievement.secondaryColor]
        : [Colors.grey.shade600, Colors.grey.shade800];

    return SizedBox(
      width: size,
      height: size,
      child: Stack(
        clipBehavior: Clip.none,
        children: [
          Container(
            width: size,
            height: size,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              gradient: LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: bgColors,
              ),
              border: Border.all(
                color: unlocked ? Colors.white.withOpacity(0.85) : Colors.grey.shade500,
                width: size * 0.055,
              ),
              boxShadow: unlocked
                  ? [
                      BoxShadow(
                        color: achievement.primaryColor.withOpacity(0.45),
                        blurRadius: 8,
                        spreadRadius: 1,
                      ),
                    ]
                  : null,
            ),
            child: Icon(
              unlocked ? achievement.icon : Icons.lock_rounded,
              size: size * 0.52,
              color: unlocked ? Colors.white : Colors.grey.shade300,
            ),
          ),
          if (showCodeTag)
            Positioned(
              right: -3,
              bottom: -2,
              child: Container(
                padding: EdgeInsets.symmetric(
                  horizontal: size * 0.09,
                  vertical: size * 0.02,
                ),
                decoration: BoxDecoration(
                  color: unlocked ? achievement.secondaryColor : Colors.grey.shade900,
                  borderRadius: BorderRadius.circular(6),
                  border: Border.all(
                    color: unlocked ? achievement.primaryColor : Colors.grey.shade600,
                    width: 1,
                  ),
                ),
                child: Text(
                  achievement.seriesCode,
                  style: TextStyle(
                    fontSize: (size * 0.21).clamp(8.0, 12.0),
                    fontWeight: FontWeight.w900,
                    color: unlocked ? Colors.white : Colors.grey.shade400,
                    letterSpacing: 0.3,
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }
}