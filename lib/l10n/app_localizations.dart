import 'package:flutter/material.dart';

class AppLocalizations {
  final Locale locale;
  AppLocalizations(this.locale);

  static AppLocalizations of(BuildContext context) {
    return Localizations.of<AppLocalizations>(context, AppLocalizations)!;
  }

  static const LocalizationsDelegate<AppLocalizations> delegate = _AppLocalizationsDelegate();

  bool get isPt => locale.languageCode == 'pt';

  String get appTitle => 'EMPLAKE GAME';
  String get reverseEngineering => isPt ? 'Engenharia Reversa' : 'Reverse Engineering';
  String get developedBy => isPt ? 'Desenvolvido pelo Grupo:' : 'Developed by Group:';
  String get enterGame => isPt ? 'Entrar no Jogo' : 'Enter Game';

  // Níveis
  String get levelFacil => isPt ? 'Fácil' : 'Easy';
  String get levelIntermediario => isPt ? 'Intermediário' : 'Intermediate';
  String get levelAvancado => isPt ? 'Avançado' : 'Advanced';
  String get levelDificil => isPt ? 'Difícil' : 'Hard';

  // Tela do Jogo
  String get levelLabel => isPt ? 'Nível' : 'Level';
  String get equationHint => isPt
      ? 'Toque ou arraste os operadores para os espaços entre os números'
      : 'Tap or drag operators into the slots between numbers';
  String get latexPreview => isPt ? 'Renderização LaTeX:' : 'LaTeX Rendering:';
  String get operatorsLabel => isPt ? 'Operadores (Toque ou Arraste):' : 'Operators (Tap or Drag):';
  String get clearAll => isPt ? 'Limpar' : 'Clear';
  String get skip => isPt ? 'Pular' : 'Skip';
  String get verify => isPt ? 'Verificar' : 'Verify';
  String get correctMsg => isPt ? 'Sugoi! Equação correta!' : 'Sugoi! Correct equation!';
  String get incorrectMsg => isPt ? 'Equação incorreta. Tente novamente!' : 'Incorrect equation. Try again!';
  String get missingEquals => isPt ? 'A equação precisa conter o sinal de igual (=).' : 'The equation must contain an equals sign (=).';
  String get syntaxError => isPt ? 'Erro de sintaxe na expressão.' : 'Syntax error in the expression.';
  String get nonIntegerDiv => isPt
      ? 'Divisão não inteira não é permitida neste nível!'
      : 'Non-integer division is not allowed at this level!';
  String get divByZero => isPt ? 'Divisão por zero não é permitida!' : 'Division by zero is not allowed!';

  // Miku falas
  String get mikuWelcome => isPt ? 'Olá! Vamos resolver desafios matemáticos! ♪' : 'Hi! Let\'s solve math puzzles! ♪';
  String get mikuThinking => isPt ? 'Coloque os operadores entre os números! ♪' : 'Place operators between the numbers! ♪';
  String get mikuHappy => isPt ? 'Perfeito! Você conseguiu! ★' : 'Awesome! You nailed it! ★';
  String get mikuOops => isPt ? 'Quase lá! Confira os parênteses ou divisões! >_<' : 'Almost! Check parentheses or divisions! >_<';

  // Configurações
  String get settingsTitle => isPt ? 'Configurações' : 'Settings';
  String get darkMode => isPt ? 'Tema Escuro' : 'Dark Mode';
  String get soundEffects => isPt ? 'Efeitos de Som' : 'Sound Effects';
  String get soundSubtitle => isPt ? 'Opcional (inicia desligado por usabilidade)' : 'Optional (starts off for usability)';
  String get fontFamily => isPt ? 'Tipo de Fonte' : 'Font Family';
  String get fontSize => isPt ? 'Tamanho da Fonte' : 'Font Size';
  String get seedColor => isPt ? 'Cores Semente e Temas Prontos' : 'Seed Colors & Preset Themes';
  String get mikuTheme => isPt ? 'Tema Hatsune Miku' : 'Hatsune Miku Theme';

  // Histórico
  String get historyTitle => isPt ? 'Números Resolvidos' : 'Solved Numbers';
  String get historyError => isPt ? 'Erro ao carregar histórico.' : 'Error loading history.';
  String get historyEmpty => isPt ? 'Nenhum número resolvido ainda!' : 'No solved numbers yet!';
  String get resolvedNumber => isPt ? 'Número Resolvido' : 'Solved Number';
  String get recordLabel => isPt ? 'Registro' : 'Record';

  // Ajuda
  String get helpTitle => isPt ? 'Como Jogar o Emplake' : 'How to Play Emplake';
  String get helpBody => isPt
      ? '1. Os 4 dígitos do número sorteado ficam fixos na tela.\n\n'
        '2. Selecione ou arraste operadores para os espaços entre ou ao redor dos dígitos.\n\n'
        '3. Para remover um operador, toque no "x" dele ou limpe tudo.\n\n'
        '4. Monte uma igualdade válida com o sinal (=).\n\n'
        '5. Nos níveis Intermediário, Avançado e Difícil, divisões com resultado decimal geram erro.'
      : '1. The 4 digits of the drawn number stay fixed in order.\n\n'
        '2. Tap or drag operators into the slots between or around the digits.\n\n'
        '3. Tap an operator\'s "x" to remove it individually.\n\n'
        '4. Build a valid equation using the equals sign (=).\n\n'
        '5. In Intermediate, Advanced, and Hard levels, non-integer divisions trigger an error.';
  String get gotIt => isPt ? 'Entendi' : 'Got it';
}

class _AppLocalizationsDelegate extends LocalizationsDelegate<AppLocalizations> {
  const _AppLocalizationsDelegate();

  @override
  bool isSupported(Locale locale) => ['pt', 'en'].contains(locale.languageCode);

  @override
  Future<AppLocalizations> load(Locale locale) async => AppLocalizations(locale);

  @override
  bool shouldReload(_AppLocalizationsDelegate old) => false;
}