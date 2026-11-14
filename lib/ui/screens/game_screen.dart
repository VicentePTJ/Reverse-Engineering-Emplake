import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_math_fork/flutter_math.dart';
import '../../l10n/app_localizations.dart';
import '../../providers/app_providers.dart';
import '../../engine/math_engine.dart';
import '../widgets/hatsune_miku_widget.dart';

class _OperatorDragData {
  final bool isNew;
  final String op;
  final int? fromSlot;
  final int? tokenIndex;

  const _OperatorDragData.newOp(this.op)
      : isNew = true,
        fromSlot = null,
        tokenIndex = null;

  const _OperatorDragData.move({
    required this.op,
    required this.fromSlot,
    required this.tokenIndex,
  }) : isNew = false;
}

class GameScreen extends ConsumerWidget {
  const GameScreen({super.key});

  String _levelName(DifficultyLevel level, AppLocalizations l10n) {
    switch (level) {
      case DifficultyLevel.facil:
        return l10n.levelFacil;
      case DifficultyLevel.intermediario:
        return l10n.levelIntermediario;
      case DifficultyLevel.avancado:
        return l10n.levelAvancado;
      case DifficultyLevel.dificil:
        return l10n.levelDificil;
    }
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final gameState = ref.watch(gameProvider);
    final gameNotifier = ref.read(gameProvider.notifier);
    final l10n = AppLocalizations.of(context);
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final operators = MathEngine.getOperatorsForLevel(gameState.level);
    final digits = gameState.currentNumber.split('');

    String mikuSpeech = l10n.mikuThinking;
    if (gameState.mikuMood == MikuMood.happy) mikuSpeech = l10n.mikuHappy;
    if (gameState.mikuMood == MikuMood.oops) mikuSpeech = l10n.mikuOops;

    return Scaffold(
      appBar: AppBar(
        title: Text('Emplake • ${l10n.levelLabel}: ${_levelName(gameState.level, l10n)}'),
        actions: [
          Padding(
            padding: const EdgeInsets.only(right: 12.0),
            child: DropdownButton<DifficultyLevel>(
              value: gameState.level,
              underline: const SizedBox(),
              items: DifficultyLevel.values.map((lvl) {
                return DropdownMenuItem(
                  value: lvl,
                  child: Text(_levelName(lvl, l10n)),
                );
              }).toList(),
              onChanged: (newLvl) {
                if (newLvl != null) gameNotifier.setLevel(newLvl);
              },
            ),
          ),
        ],
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(16.0),
          child: Center(
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 720),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  HatsuneMikuWidget(
                    mood: gameState.mikuMood,
                    speechText: mikuSpeech,
                    size: 74,
                  ),
                  const SizedBox(height: 12),

                  Text(
                    l10n.equationHint,
                    textAlign: TextAlign.center,
                    style: TextStyle(fontSize: 12, color: colorScheme.onSurfaceVariant),
                  ),
                  const SizedBox(height: 8),

                  // Tabuleiro da Equação: 4 Dígitos Fixos + 5 Slots Interativos/Arrastáveis
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 14),
                    decoration: BoxDecoration(
                      color: colorScheme.surfaceContainerHighest.withOpacity(0.5),
                      borderRadius: BorderRadius.circular(14),
                      border: Border.all(color: colorScheme.outlineVariant),
                    ),
                    child: Wrap(
                      alignment: WrapAlignment.center,
                      crossAxisAlignment: WrapCrossAlignment.center,
                      spacing: 4,
                      runSpacing: 8,
                      children: [
                        for (int i = 0; i <= digits.length; i++) ...[
                          _buildOperatorSlot(
                            context: context,
                            slotIndex: i,
                            slotTokens: gameState.operatorSlots[i],
                            isActive: gameState.activeSlotIndex == i,
                            gameNotifier: gameNotifier,
                          ),
                          if (i < digits.length)
                            _buildFixedDigitTile(context, digits[i]),
                        ],
                      ],
                    ),
                  ),
                  const SizedBox(height: 14),

                  // Renderizador LaTeX
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: colorScheme.surfaceContainerLow,
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: colorScheme.outlineVariant),
                    ),
                    child: Column(
                      children: [
                        Text(
                          l10n.latexPreview,
                          style: TextStyle(fontSize: 12, color: colorScheme.onSurfaceVariant),
                        ),
                        const SizedBox(height: 6),
                        SingleChildScrollView(
                          scrollDirection: Axis.horizontal,
                          child: Math.tex(
                            MathEngine.convertTokensToLaTeX(gameState.fullTokens),
                            textStyle: TextStyle(
                              fontSize: 24,
                              color: colorScheme.onSurface,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 10),

                  // Notificação não bloqueante
                  AnimatedSize(
                    duration: const Duration(milliseconds: 200),
                    child: gameState.feedbackStatus == FeedbackStatus.none
                        ? const SizedBox.shrink()
                        : Container(
                            margin: const EdgeInsets.only(bottom: 10),
                            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                            decoration: BoxDecoration(
                              color: gameState.feedbackStatus == FeedbackStatus.success
                                  ? Colors.green.shade700
                                  : colorScheme.errorContainer,
                              borderRadius: BorderRadius.circular(10),
                            ),
                            child: Row(
                              children: [
                                Icon(
                                  gameState.feedbackStatus == FeedbackStatus.success
                                      ? Icons.check_circle
                                      : Icons.error_outline,
                                  color: gameState.feedbackStatus == FeedbackStatus.success
                                      ? Colors.white
                                      : colorScheme.onErrorContainer,
                                ),
                                const SizedBox(width: 10),
                                Expanded(
                                  child: Text(
                                    gameState.feedbackMessage,
                                    style: TextStyle(
                                      fontWeight: FontWeight.bold,
                                      color: gameState.feedbackStatus == FeedbackStatus.success
                                          ? Colors.white
                                          : colorScheme.onErrorContainer,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ),
                  ),

                  // Teclado de Operadores
                  Text(
                    l10n.operatorsLabel,
                    textAlign: TextAlign.center,
                    style: TextStyle(fontSize: 12, color: colorScheme.onSurfaceVariant),
                  ),
                  const SizedBox(height: 8),
                  AnimatedOpacity(
                    duration: const Duration(milliseconds: 300),
                    opacity: gameState.isAnimating ? 0.2 : 1.0,
                    child: Wrap(
                      spacing: 8,
                      runSpacing: 8,
                      alignment: WrapAlignment.center,
                      children: operators.map((op) {
                        return _buildDraggableOperatorButton(
                          context: context,
                          op: op,
                          onTap: () => gameNotifier.smartInsertOperator(op),
                        );
                      }).toList(),
                    ),
                  ),
                  const SizedBox(height: 20),

                  // Botões de ação
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                    children: [
                      OutlinedButton.icon(
                        icon: const Icon(Icons.refresh),
                        label: Text(l10n.clearAll),
                        onPressed: () => gameNotifier.clearFormula(),
                      ),
                      OutlinedButton.icon(
                        icon: const Icon(Icons.skip_next),
                        label: Text(l10n.skip),
                        onPressed: () => gameNotifier.skipCurrentNumber(),
                      ),
                      FilledButton.icon(
                        icon: const Icon(Icons.check_circle),
                        label: Text(l10n.verify),
                        onPressed: () {
                          try {
                            final isValid = MathEngine.evaluateTokens(
                              gameState.fullTokens,
                              gameState.level,
                              missingEqualsMsg: l10n.missingEquals,
                              syntaxErrorMsg: l10n.syntaxError,
                              nonIntegerDivMsg: l10n.nonIntegerDiv,
                              divByZeroMsg: l10n.divByZero,
                            );

                            if (isValid) {
                              gameNotifier.markCurrentAsSolved(l10n.correctMsg);
                            } else {
                              gameNotifier.setFeedback(
                                l10n.incorrectMsg,
                                FeedbackStatus.error,
                                MikuMood.oops,
                              );
                            }
                          } on FormatException catch (e) {
                            gameNotifier.setFeedback(
                              e.message,
                              FeedbackStatus.error,
                              MikuMood.oops,
                            );
                          }
                        },
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildFixedDigitTile(BuildContext context, String digit) {
    final colorScheme = Theme.of(context).colorScheme;
    return Container(
      width: 44,
      height: 52,
      alignment: Alignment.center,
      decoration: BoxDecoration(
        color: colorScheme.primaryContainer,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: colorScheme.primary, width: 2),
      ),
      child: Text(
        digit,
        style: TextStyle(
          fontSize: 26,
          fontWeight: FontWeight.bold,
          color: colorScheme.onPrimaryContainer,
        ),
      ),
    );
  }

  Widget _buildOperatorSlot({
    required BuildContext context,
    required int slotIndex,
    required List<String> slotTokens,
    required bool isActive,
    required GameNotifier gameNotifier,
  }) {
    final colorScheme = Theme.of(context).colorScheme;

    return DragTarget<_OperatorDragData>(
      onAcceptWithDetails: (details) {
        final data = details.data;
        if (data.isNew) {
          gameNotifier.insertOperatorAtSlot(slotIndex, data.op);
        } else {
          gameNotifier.moveOperator(
            data.fromSlot!,
            data.tokenIndex!,
            slotIndex,
          );
        }
      },
      builder: (context, candidateData, rejectedData) {
        final isHovered = candidateData.isNotEmpty;

        return GestureDetector(
          onTap: () => gameNotifier.selectSlot(slotIndex),
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 150),
            constraints: const BoxConstraints(minWidth: 26, minHeight: 46),
            padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 2),
            decoration: BoxDecoration(
              color: isHovered
                  ? colorScheme.tertiaryContainer
                  : isActive
                      ? colorScheme.secondaryContainer.withOpacity(0.6)
                      : Colors.transparent,
              borderRadius: BorderRadius.circular(8),
              border: Border.all(
                color: isHovered
                    ? colorScheme.tertiary
                    : isActive
                        ? colorScheme.primary
                        : colorScheme.outlineVariant.withOpacity(0.6),
                width: isHovered || isActive ? 2 : 1,
              ),
            ),
            child: slotTokens.isEmpty
                ? Center(
                    child: Text(
                      isActive ? '|' : '·',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                        color: isActive ? colorScheme.primary : colorScheme.outline,
                      ),
                    ),
                  )
                : Wrap(
                    spacing: 4,
                    crossAxisAlignment: WrapCrossAlignment.center,
                    children: List.generate(slotTokens.length, (tokenIdx) {
                      final op = slotTokens[tokenIdx];
                      return Draggable<_OperatorDragData>(
                        data: _OperatorDragData.move(
                          op: op,
                          fromSlot: slotIndex,
                          tokenIndex: tokenIdx,
                        ),
                        feedback: Material(
                          color: Colors.transparent,
                          child: Chip(
                            label: Text(op, style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                            backgroundColor: colorScheme.primary,
                            labelStyle: TextStyle(color: colorScheme.onPrimary),
                          ),
                        ),
                        childWhenDragging: Opacity(
                          opacity: 0.3,
                          child: Chip(label: Text(op)),
                        ),
                        child: InputChip(
                          label: Text(
                            op,
                            style: TextStyle(
                              fontSize: 17,
                              fontWeight: FontWeight.bold,
                              color: colorScheme.onSecondaryContainer,
                            ),
                          ),
                          backgroundColor: colorScheme.secondaryContainer,
                          visualDensity: VisualDensity.compact,
                          onDeleted: () => gameNotifier.removeOperatorAt(slotIndex, tokenIdx),
                          deleteIcon: Icon(
                            Icons.close,
                            size: 16,
                            color: colorScheme.onSecondaryContainer,
                          ),
                        ),
                      );
                    }),
                  ),
          ),
        );
      },
    );
  }

  Widget _buildDraggableOperatorButton({
    required BuildContext context,
    required String op,
    required VoidCallback onTap,
  }) {
    final colorScheme = Theme.of(context).colorScheme;

    final buttonWidget = ElevatedButton(
      style: ElevatedButton.styleFrom(
        minimumSize: const Size(52, 46),
        padding: const EdgeInsets.symmetric(horizontal: 12),
        backgroundColor: op == '=' ? colorScheme.tertiaryContainer : colorScheme.secondaryContainer,
        foregroundColor: op == '=' ? colorScheme.onTertiaryContainer : colorScheme.onSecondaryContainer,
      ),
      onPressed: onTap,
      child: Text(op, style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
    );

    return Draggable<_OperatorDragData>(
      data: _OperatorDragData.newOp(op),
      feedback: Material(
        color: Colors.transparent,
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
          decoration: BoxDecoration(
            color: colorScheme.primary,
            borderRadius: BorderRadius.circular(12),
            boxShadow: const [BoxShadow(blurRadius: 8, color: Colors.black26)],
          ),
          child: Text(
            op,
            style: TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.bold,
              color: colorScheme.onPrimary,
            ),
          ),
        ),
      ),
      child: buttonWidget,
    );
  }
}