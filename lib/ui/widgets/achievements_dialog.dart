import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../models/vocaloid_achievement.dart';
import '../../providers/app_providers.dart';

class AchievementsDialog extends ConsumerWidget {
  const AchievementsDialog({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final gameState = ref.watch(gameProvider);
    final gameNotifier = ref.read(gameProvider.notifier);
    final colorScheme = Theme.of(context).colorScheme;

    final score = gameState.score;
    final unlockedCount = kVocaloidAchievements.where((a) => a.isUnlocked(score)).length;

    VocaloidAchievement? nextLocked;
    for (final a in kVocaloidAchievements) {
      if (!a.isUnlocked(score)) {
        nextLocked = a;
        break;
      }
    }

    final progress = nextLocked == null
        ? 1.0
        : (score / nextLocked.requiredPoints).clamp(0.0, 1.0);

    return AlertDialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      titlePadding: const EdgeInsets.fromLTRB(20, 20, 16, 8),
      title: Row(
        children: [
          const Icon(Icons.emoji_events_rounded, color: Colors.amber, size: 28),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Conquistas Vocaloid & UTAU',
                  style: TextStyle(fontSize: 17, fontWeight: FontWeight.bold),
                ),
                Text(
                  '$unlockedCount de ${kVocaloidAchievements.length} ícones desbloqueados ($score pts)',
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.normal,
                    color: colorScheme.onSurfaceVariant,
                  ),
                ),
              ],
            ),
          ),
          IconButton(
            icon: const Icon(Icons.close),
            onPressed: () => Navigator.of(context).pop(),
          ),
        ],
      ),
      content: SizedBox(
        width: 440,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Barra de progresso para a próxima conquista
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: colorScheme.surfaceContainerHighest.withOpacity(0.5),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        nextLocked != null
                            ? 'Próximo: ${nextLocked.characterName}'
                            : 'Coleção completa!',
                        style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold),
                      ),
                      Text(
                        nextLocked != null
                            ? '$score / ${nextLocked.requiredPoints} pts'
                            : '100%',
                        style: TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.w600,
                          color: colorScheme.primary,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 6),
                  ClipRRect(
                    borderRadius: BorderRadius.circular(6),
                    child: LinearProgressIndicator(
                      value: progress,
                      minHeight: 8,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 12),

            // Lista das 5 conquistas
            Flexible(
              child: ListView.separated(
                shrinkWrap: true,
                itemCount: kVocaloidAchievements.length,
                separatorBuilder: (_, __) => const SizedBox(height: 8),
                itemBuilder: (context, index) {
                  final item = kVocaloidAchievements[index];
                  final unlocked = item.isUnlocked(score);
                  final isEquipped = gameState.equippedAchievementId == item.id;

                  return Container(
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                    decoration: BoxDecoration(
                      color: unlocked
                          ? item.primaryColor.withOpacity(0.10)
                          : colorScheme.surfaceContainerLow,
                      borderRadius: BorderRadius.circular(14),
                      border: Border.all(
                        color: isEquipped
                            ? item.primaryColor
                            : unlocked
                                ? item.primaryColor.withOpacity(0.45)
                                : colorScheme.outlineVariant,
                        width: isEquipped ? 2 : 1,
                      ),
                    ),
                    child: Row(
                      children: [
                        VocaloidIconBadge(
                          achievement: item,
                          unlocked: unlocked,
                          size: 48,
                        ),
                        const SizedBox(width: 14),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Row(
                                children: [
                                  Flexible(
                                    child: Text(
                                      item.characterName,
                                      style: TextStyle(
                                        fontWeight: FontWeight.bold,
                                        fontSize: 14,
                                        color: unlocked
                                            ? colorScheme.onSurface
                                            : colorScheme.onSurfaceVariant,
                                      ),
                                    ),
                                  ),
                                  const SizedBox(width: 6),
                                  Container(
                                    padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 1),
                                    decoration: BoxDecoration(
                                      color: unlocked
                                          ? item.primaryColor.withOpacity(0.2)
                                          : colorScheme.surfaceContainerHighest,
                                      borderRadius: BorderRadius.circular(6),
                                    ),
                                    child: Text(
                                      '${item.requiredPoints} pts',
                                      style: TextStyle(
                                        fontSize: 10,
                                        fontWeight: FontWeight.bold,
                                        color: unlocked
                                            ? item.primaryColor
                                            : colorScheme.onSurfaceVariant,
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 2),
                              Text(
                                '${item.title} • ${item.description}',
                                style: TextStyle(
                                  fontSize: 11.5,
                                  color: colorScheme.onSurfaceVariant,
                                ),
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(width: 8),
                        if (unlocked)
                          isEquipped
                              ? Chip(
                                  label: const Text(
                                    'Equipado',
                                    style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold),
                                  ),
                                  backgroundColor: item.primaryColor.withOpacity(0.22),
                                  side: BorderSide(color: item.primaryColor),
                                  visualDensity: VisualDensity.compact,
                                )
                              : OutlinedButton(
                                  style: OutlinedButton.styleFrom(
                                    padding: const EdgeInsets.symmetric(horizontal: 10),
                                    minimumSize: const Size(0, 32),
                                    side: BorderSide(color: item.primaryColor),
                                  ),
                                  onPressed: () => gameNotifier.equipAchievement(item.id),
                                  child: const Text('Equipar', style: TextStyle(fontSize: 11)),
                                )
                        else
                          Icon(Icons.lock_outline, size: 18, color: colorScheme.outline),
                      ],
                    ),
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }
}