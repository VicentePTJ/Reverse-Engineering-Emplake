import 'dart:math' as math;
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_math_fork/flutter_math.dart';
import 'package:flutter_spinkit/flutter_spinkit.dart';
import 'package:go_router/go_router.dart';
import '../../l10n/app_localizations.dart';
import '../../providers/app_providers.dart';
import '../../engine/math_engine.dart';
import '../../services/firestore_service.dart';
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

class _FlyingOperator {
  final String op;
  final Offset start;
  final Offset end;

  const _FlyingOperator({
    required this.op,
    required this.start,
    required this.end,
  });
}

class GameScreen extends ConsumerStatefulWidget {
  const GameScreen({super.key});

  @override
  ConsumerState<GameScreen> createState() => _GameScreenState();
}

class _GameScreenState extends ConsumerState<GameScreen> with SingleTickerProviderStateMixin {
  Future<UserGameProfile>? _profileFuture;
  String? _loadedUid;

  final GlobalKey _rootStackKey = GlobalKey();
  final GlobalKey _keyboardAreaKey = GlobalKey();
  final Map<String, GlobalKey> _keyboardButtonKeys = {};
  final Map<String, GlobalKey> _slotChipKeys = {};

  late final AnimationController _flyController;
  late final Animation<double> _flyAnimation;
  List<_FlyingOperator> _flyingOperators = [];
  VoidCallback? _onFlyComplete;

  @override
  void initState() {
    super.initState();
    _flyController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1400),
      animationBehavior: AnimationBehavior.preserve, // Impede o Windows de acelerar para 5%
    );
    _flyAnimation = CurvedAnimation(
      parent: _flyController,
      curve: Curves.easeInOutQuart,
    );

    _flyController.addStatusListener((status) {
      if (status == AnimationStatus.completed) {
        final callback = _onFlyComplete;
        _onFlyComplete = null;
        if (mounted) {
          setState(() {
            _flyingOperators = [];
          });
        }
        callback?.call();
      }
    });
  }

  @override
  void dispose() {
    _flyController.dispose();
    super.dispose();
  }

  GlobalKey _getKeyboardKey(String op) {
    return _keyboardButtonKeys.putIfAbsent(op, () => GlobalKey());
  }

  GlobalKey _getSlotChipKey(int slotIndex, int tokenIndex) {
    return _slotChipKeys.putIfAbsent('$slotIndex-$tokenIndex', () => GlobalKey());
  }

  void _ensureUserFuture(User? user) {
    if (user != null && _loadedUid != user.uid) {
      _loadedUid = user.uid;
      _profileFuture = ref.read(firestoreServiceProvider).getUserProfile(user);
    }
  }

  /// Captura a posição atual de todos os operadores na resposta e anima o retorno até seus botões
  void _animateOperatorsHome({
    required bool isSuccess,
    String? successMsg,
    int? pointsEarned,
    required VoidCallback onComplete,
  }) {
    final gameState = ref.read(gameProvider);
    final gameNotifier = ref.read(gameProvider.notifier);

    if (gameState.isAnimating) return;

    final stackRenderBox = _rootStackKey.currentContext?.findRenderObject() as RenderBox?;
    final fallbackBox = _keyboardAreaKey.currentContext?.findRenderObject() as RenderBox?;

    final captured = <_FlyingOperator>[];

    if (stackRenderBox != null) {
      for (int sIdx = 0; sIdx < gameState.operatorSlots.length; sIdx++) {
        final slot = gameState.operatorSlots[sIdx];
        for (int tIdx = 0; tIdx < slot.length; tIdx++) {
          final op = slot[tIdx];
          final chipKey = _slotChipKeys['$sIdx-$tIdx'];
          final chipBox = chipKey?.currentContext?.findRenderObject() as RenderBox?;

          GlobalKey? targetKey = _keyboardButtonKeys[op];
          if (targetKey?.currentContext == null && op == ')') {
            targetKey = _keyboardButtonKeys['('];
          }
          final targetBox = (targetKey?.currentContext?.findRenderObject() as RenderBox?) ?? fallbackBox;

          if (chipBox != null && targetBox != null) {
            final startGlobal = chipBox.localToGlobal(Offset.zero);
            final endGlobal = targetBox.localToGlobal(Offset.zero);

            final startLocal = stackRenderBox.globalToLocal(startGlobal);
            final endButtonTopLeft = stackRenderBox.globalToLocal(endGlobal);

            final centeredEnd = Offset(
              endButtonTopLeft.dx + (targetBox.size.width - chipBox.size.width) / 2,
              endButtonTopLeft.dy + (targetBox.size.height - chipBox.size.height) / 2,
            );

            captured.add(_FlyingOperator(
              op: op,
              start: startLocal,
              end: centeredEnd,
            ));
          }
        }
      }
    }

    if (captured.isEmpty) {
      gameNotifier.startReturnAnimation(
        isSuccess: isSuccess,
        successMsg: successMsg,
        pointsEarned: pointsEarned,
      );
      Future.delayed(const Duration(milliseconds: 600), () {
        if (mounted) onComplete();
      });
      return;
    }

    _onFlyComplete = onComplete;
    setState(() {
      _flyingOperators = captured;
    });

    gameNotifier.startReturnAnimation(
      isSuccess: isSuccess,
      successMsg: successMsg,
      pointsEarned: pointsEarned,
    );

    _flyController.forward(from: 0.0);
  }

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
  Widget build(BuildContext context) {
    final user = FirebaseAuth.instance.currentUser;
    _ensureUserFuture(user);

    final gameState = ref.watch(gameProvider);
    final gameNotifier = ref.read(gameProvider.notifier);
    final settings = ref.watch(settingsProvider);
    final l10n = AppLocalizations.of(context);
    final colorScheme = Theme.of(context).colorScheme;

    return Stack(
      key: _rootStackKey,
      children: [
        Scaffold(
          appBar: AppBar(
            toolbarHeight: 50,
            title: Row(
              children: [
                Flexible(
                  child: Text(
                    'Emplake • ${_levelName(gameState.level, l10n)}',
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
                const SizedBox(width: 12),
                Chip(
                  avatar: const Icon(Icons.star, size: 16, color: Colors.amber),
                  label: Text(
                    '${gameState.score} ${l10n.scoreLabel}',
                    style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 12),
                  ),
                  visualDensity: VisualDensity.compact,
                ),
              ],
            ),
            actions: [
              DropdownButton<DifficultyLevel>(
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
              IconButton(
                icon: Icon(
                  settings.musicEnabled ? Icons.music_note : Icons.music_off,
                  color: settings.musicEnabled ? kMikuTeal : null,
                ),
                tooltip: l10n.mikuMusicTitle,
                onPressed: () {
                  ref.read(settingsProvider.notifier).toggleMusic(!settings.musicEnabled);
                },
              ),
              IconButton(
                icon: const Icon(Icons.logout),
                tooltip: l10n.logout,
                onPressed: () async {
                  await FirebaseAuth.instance.signOut();
                  if (context.mounted) context.go('/login');
                },
              ),
            ],
          ),
          body: SafeArea(
            child: FutureBuilder<UserGameProfile>(
              future: _profileFuture,
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return Center(
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        SpinKitFadingCircle(
                          color: colorScheme.primary,
                          size: 64.0,
                        ),
                        const SizedBox(height: 16),
                        Text(l10n.loadingCloud),
                      ],
                    ),
                  );
                }

                if (snapshot.hasData && user != null) {
                  WidgetsBinding.instance.addPostFrameCallback((_) {
                    if (mounted) {
                      gameNotifier.syncFromFirestore(user.uid, snapshot.data!);
                    }
                  });
                }

                final operators = MathEngine.getOperatorsForLevel(gameState.level);
                final digits = gameState.currentNumber.split('');

                String mikuSpeech = l10n.mikuThinking;
                if (gameState.mikuMood == MikuMood.happy) mikuSpeech = l10n.mikuHappy;
                if (gameState.mikuMood == MikuMood.oops) mikuSpeech = l10n.mikuOops;

                return LayoutBuilder(
                  builder: (context, constraints) {
                    final isSmallScreen = constraints.maxWidth < 600;
                    final isCompactHeight = constraints.maxHeight < 520;
                    final needsVerticalScroll = isSmallScreen || isCompactHeight;

                    final boardItems = <Widget>[
                      for (int i = 0; i <= digits.length; i++) ...[
                        _buildOperatorSlot(
                          context: context,
                          slotIndex: i,
                          slotTokens: gameState.operatorSlots[i],
                          isActive: gameState.activeSlotIndex == i && !gameState.isAnimating,
                          isSmallScreen: isSmallScreen,
                          gameNotifier: gameNotifier,
                        ),
                        if (i < digits.length)
                          _buildFixedDigitTile(
                            context,
                            digits[i],
                            isSmallScreen: isSmallScreen,
                          ),
                      ],
                    ];

                    final content = Center(
                      child: ConstrainedBox(
                        constraints: const BoxConstraints(maxWidth: 960),
                        child: Padding(
                          padding: EdgeInsets.symmetric(
                            horizontal: isSmallScreen ? 12.0 : 20.0,
                            vertical: isSmallScreen ? 12.0 : 8.0,
                          ),
                          child: Column(
                            mainAxisSize: needsVerticalScroll ? MainAxisSize.min : MainAxisSize.max,
                            mainAxisAlignment: needsVerticalScroll
                                ? MainAxisAlignment.start
                                : MainAxisAlignment.spaceEvenly,
                            crossAxisAlignment: CrossAxisAlignment.stretch,
                            children: [
                              Center(
                                child: HatsuneMikuWidget(
                                  mood: gameState.mikuMood,
                                  speechText: mikuSpeech,
                                  size: isSmallScreen || isCompactHeight ? 56 : 66,
                                ),
                              ),
                              if (needsVerticalScroll) const SizedBox(height: 12),

                              // Tabuleiro Responsivo
                              Column(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  Text(
                                    l10n.equationHint,
                                    textAlign: TextAlign.center,
                                    style: TextStyle(fontSize: 12, color: colorScheme.onSurfaceVariant),
                                  ),
                                  const SizedBox(height: 6),
                                  Container(
                                    width: double.infinity,
                                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                                    decoration: BoxDecoration(
                                      color: colorScheme.surfaceContainerHighest.withOpacity(0.45),
                                      borderRadius: BorderRadius.circular(14),
                                      border: Border.all(color: colorScheme.outlineVariant),
                                    ),
                                    child: isSmallScreen
                                        ? Wrap(
                                            alignment: WrapAlignment.center,
                                            crossAxisAlignment: WrapCrossAlignment.center,
                                            spacing: 6,
                                            runSpacing: 8,
                                            children: boardItems,
                                          )
                                        : Center(
                                            child: SingleChildScrollView(
                                              scrollDirection: Axis.horizontal,
                                              child: Row(
                                                mainAxisSize: MainAxisSize.min,
                                                crossAxisAlignment: CrossAxisAlignment.center,
                                                children: [
                                                  for (int idx = 0; idx < boardItems.length; idx++) ...[
                                                    boardItems[idx],
                                                    if (idx < boardItems.length - 1)
                                                      const SizedBox(width: 6),
                                                  ],
                                                ],
                                              ),
                                            ),
                                          ),
                                  ),
                                ],
                              ),
                              if (needsVerticalScroll) const SizedBox(height: 12),

                              // Renderizador LaTeX
                              Container(
                                padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                                decoration: BoxDecoration(
                                  color: colorScheme.surfaceContainerLow,
                                  borderRadius: BorderRadius.circular(12),
                                  border: Border.all(color: colorScheme.outlineVariant),
                                ),
                                child: Column(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    Text(
                                      l10n.latexPreview,
                                      style: TextStyle(fontSize: 11, color: colorScheme.onSurfaceVariant),
                                    ),
                                    const SizedBox(height: 4),
                                    SingleChildScrollView(
                                      scrollDirection: Axis.horizontal,
                                      child: Math.tex(
                                        MathEngine.convertTokensToLaTeX(gameState.fullTokens),
                                        textStyle: TextStyle(
                                          fontSize: isSmallScreen ? 20 : 22,
                                          color: colorScheme.onSurface,
                                        ),
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                              if (needsVerticalScroll) const SizedBox(height: 12),

                              // Banner de Feedback Inline
                              if (gameState.feedbackStatus != FeedbackStatus.none) ...[
                                Container(
                                  padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                                  decoration: BoxDecoration(
                                    color: gameState.feedbackStatus == FeedbackStatus.success
                                        ? Colors.green.shade700
                                        : colorScheme.errorContainer,
                                    borderRadius: BorderRadius.circular(10),
                                  ),
                                  child: Row(
                                    mainAxisAlignment: MainAxisAlignment.center,
                                    children: [
                                      Icon(
                                        gameState.feedbackStatus == FeedbackStatus.success
                                            ? Icons.check_circle
                                            : Icons.error_outline,
                                        size: 18,
                                        color: gameState.feedbackStatus == FeedbackStatus.success
                                            ? Colors.white
                                            : colorScheme.onErrorContainer,
                                      ),
                                      const SizedBox(width: 8),
                                      Flexible(
                                        child: Text(
                                          gameState.feedbackMessage,
                                          style: TextStyle(
                                            fontSize: 13,
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
                                if (needsVerticalScroll) const SizedBox(height: 12),
                              ],

                              // Teclado de Operadores (Destino da animação de retorno)
                              Column(
                                key: _keyboardAreaKey,
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  Text(
                                    l10n.operatorsLabel,
                                    textAlign: TextAlign.center,
                                    style: TextStyle(fontSize: 12, color: colorScheme.onSurfaceVariant),
                                  ),
                                  const SizedBox(height: 6),
                                  Wrap(
                                    spacing: 8,
                                    runSpacing: 8,
                                    alignment: WrapAlignment.center,
                                    children: operators.map((op) {
                                      return _buildDraggableOperatorButton(
                                        context: context,
                                        op: op,
                                        buttonKey: _getKeyboardKey(op),
                                        onTap: () => gameNotifier.smartInsertOperator(op),
                                      );
                                    }).toList(),
                                  ),
                                ],
                              ),
                              if (needsVerticalScroll) const SizedBox(height: 16),

                              // Botões de Ação
                              Wrap(
                                alignment: WrapAlignment.center,
                                spacing: 16,
                                runSpacing: 10,
                                children: [
                                  OutlinedButton.icon(
                                    icon: const Icon(Icons.refresh, size: 18),
                                    label: Text(l10n.clearAll),
                                    onPressed: gameState.isAnimating
                                        ? null
                                        : () {
                                            _animateOperatorsHome(
                                              isSuccess: false,
                                              onComplete: () => gameNotifier.finishClearAnimation(),
                                            );
                                          },
                                  ),
                                  OutlinedButton.icon(
                                    icon: const Icon(Icons.skip_next, size: 18),
                                    label: Text(l10n.skip),
                                    onPressed: gameState.isAnimating
                                        ? null
                                        : () => gameNotifier.skipCurrentNumber(),
                                  ),
                                  FilledButton.icon(
                                    icon: const Icon(Icons.check_circle, size: 18),
                                    label: Text(l10n.verify),
                                    onPressed: gameState.isAnimating
                                        ? null
                                        : () async {
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
                                                final points = await gameNotifier.saveSolvedToCloud();
                                                if (!mounted) return;
                                                _animateOperatorsHome(
                                                  isSuccess: true,
                                                  successMsg: l10n.correctMsg,
                                                  pointsEarned: points,
                                                  onComplete: () => gameNotifier.skipCurrentNumber(),
                                                );
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
                    );

                    if (needsVerticalScroll) {
                      return SingleChildScrollView(child: content);
                    }
                    return SizedBox(
                      height: constraints.maxHeight,
                      child: content,
                    );
                  },
                );
              },
            ),
          ),
        ),

        // Camada de Animação: Operadores voando suavemente de volta aos seus botões
        if (_flyingOperators.isNotEmpty)
          Positioned.fill(
            child: IgnorePointer(
              child: AnimatedBuilder(
                animation: _flyAnimation,
                builder: (context, child) {
                  final t = _flyAnimation.value;
                  final arcOffset = -28.0 * math.sin(t * math.pi);
                  final scale = 1.0 + 0.16 * math.sin(t * math.pi);

                  return Stack(
                    children: _flyingOperators.map((item) {
                      final dx = item.start.dx + (item.end.dx - item.start.dx) * t;
                      final dy = item.start.dy + (item.end.dy - item.start.dy) * t + arcOffset;

                      return Positioned(
                        left: dx,
                        top: dy,
                        child: Transform.scale(
                          scale: scale,
                          child: Material(
                            color: Colors.transparent,
                            child: Container(
                              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                              decoration: BoxDecoration(
                                color: colorScheme.primary,
                                borderRadius: BorderRadius.circular(18),
                                boxShadow: [
                                  BoxShadow(
                                    color: colorScheme.primary.withOpacity(0.45),
                                    blurRadius: 10,
                                    offset: const Offset(0, 4),
                                  ),
                                ],
                              ),
                              child: Text(
                                item.op,
                                style: TextStyle(
                                  fontSize: 17,
                                  fontWeight: FontWeight.bold,
                                  color: colorScheme.onPrimary,
                                ),
                              ),
                            ),
                          ),
                        ),
                      );
                    }).toList(),
                  );
                },
              ),
            ),
          ),
      ],
    );
  }

  Widget _buildFixedDigitTile(
    BuildContext context,
    String digit, {
    required bool isSmallScreen,
  }) {
    final colorScheme = Theme.of(context).colorScheme;
    return Container(
      width: isSmallScreen ? 38 : 42,
      height: isSmallScreen ? 42 : 46,
      alignment: Alignment.center,
      decoration: BoxDecoration(
        color: colorScheme.primaryContainer,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: colorScheme.primary, width: 2),
      ),
      child: Text(
        digit,
        style: TextStyle(
          fontSize: isSmallScreen ? 21 : 24,
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
    required bool isSmallScreen,
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

        final tokenChips = List.generate(slotTokens.length, (tokenIdx) {
          final op = slotTokens[tokenIdx];
          final chipKey = _getSlotChipKey(slotIndex, tokenIdx);

          return Padding(
            key: chipKey,
            padding: EdgeInsets.only(
              right: !isSmallScreen && tokenIdx < slotTokens.length - 1 ? 4 : 0,
            ),
            child: Draggable<_OperatorDragData>(
              data: _OperatorDragData.move(
                op: op,
                fromSlot: slotIndex,
                tokenIndex: tokenIdx,
              ),
              feedback: Material(
                color: Colors.transparent,
                child: Chip(
                  label: Text(
                    op,
                    style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                  ),
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
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    color: colorScheme.onSecondaryContainer,
                  ),
                ),
                backgroundColor: colorScheme.secondaryContainer,
                visualDensity: VisualDensity.compact,
                padding: const EdgeInsets.symmetric(horizontal: 2),
                onDeleted: () => gameNotifier.removeOperatorAt(slotIndex, tokenIdx),
                deleteIcon: Icon(
                  Icons.close,
                  size: 15,
                  color: colorScheme.onSecondaryContainer,
                ),
              ),
            ),
          );
        });

        return GestureDetector(
          onTap: () => gameNotifier.selectSlot(slotIndex),
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 150),
            constraints: BoxConstraints(
              minWidth: isSmallScreen ? 28 : 32,
              minHeight: isSmallScreen ? 40 : 44,
            ),
            padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
            decoration: BoxDecoration(
              color: isHovered
                  ? colorScheme.tertiaryContainer
                  : isActive
                      ? colorScheme.secondaryContainer.withOpacity(0.55)
                      : Colors.transparent,
              borderRadius: BorderRadius.circular(10),
              border: Border.all(
                color: isHovered
                    ? colorScheme.tertiary
                    : isActive
                        ? colorScheme.primary
                        : colorScheme.outlineVariant.withOpacity(0.7),
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
                : isSmallScreen
                    ? Wrap(
                        spacing: 4,
                        runSpacing: 4,
                        crossAxisAlignment: WrapCrossAlignment.center,
                        children: tokenChips,
                      )
                    : Row(
                        mainAxisSize: MainAxisSize.min,
                        crossAxisAlignment: CrossAxisAlignment.center,
                        children: tokenChips,
                      ),
          ),
        );
      },
    );
  }

  Widget _buildDraggableOperatorButton({
    required BuildContext context,
    required String op,
    required GlobalKey buttonKey,
    required VoidCallback onTap,
  }) {
    final colorScheme = Theme.of(context).colorScheme;

    final buttonWidget = ElevatedButton(
      key: buttonKey,
      style: ElevatedButton.styleFrom(
        shape: const StadiumBorder(),
        minimumSize: const Size(46, 40),
        padding: const EdgeInsets.symmetric(horizontal: 12),
        backgroundColor: op == '=' ? colorScheme.tertiaryContainer : colorScheme.secondaryContainer,
        foregroundColor: op == '=' ? colorScheme.onTertiaryContainer : colorScheme.onSecondaryContainer,
      ),
      onPressed: onTap,
      child: Text(op, style: const TextStyle(fontSize: 17, fontWeight: FontWeight.bold)),
    );

    return Draggable<_OperatorDragData>(
      data: _OperatorDragData.newOp(op),
      feedback: Material(
        color: Colors.transparent,
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
          decoration: BoxDecoration(
            color: colorScheme.primary,
            borderRadius: BorderRadius.circular(20),
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