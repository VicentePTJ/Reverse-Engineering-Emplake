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
  String get signInPrompt => isPt
      ? 'Entre com E-mail/Senha ou Google para salvar seu progresso'
      : 'Sign in with Email/Password or Google to save your progress';
  String get logout => isPt ? 'Sair da Conta' : 'Sign Out';

  // Níveis
  String get levelFacil => isPt ? 'Fácil' : 'Easy';
  String get levelIntermediario => isPt ? 'Intermediário' : 'Intermediate';
  String get levelAvancado => isPt ? 'Avançado' : 'Advanced';
  String get levelDificil => isPt ? 'Difícil' : 'Hard';

  // Tela do Jogo
  String get levelLabel => isPt ? 'Nível' : 'Level';
  String get scoreLabel => isPt ? 'Pontos' : 'Score';
  String get loadingCloud => isPt ? 'Sincronizando dados com Firestore...' : 'Syncing data with Firestore...';
  String get equationHint => isPt
      ? 'Toque ou arraste os operadores para os espaços entre os números'
      : 'Tap or drag operators into the slots between numbers';
  String get latexPreview => isPt ? 'Renderização LaTeX:' : 'LaTeX Rendering:';
  String get operatorsLabel => isPt ? 'Operadores (Toque ou Arraste):' : 'Operators (Tap or Drag):';
  String get clearAll => isPt ? 'Limpar' : 'Clear';
  String get skip => isPt ? 'Pular' : 'Skip';
  String get verify => isPt ? 'Verificar' : 'Verify';
  String get correctMsg => isPt ? 'Sugoi! Equação correta! Salvo no Firestore!' : 'Sugoi! Correct equation! Saved to Firestore!';
  String get incorrectMsg => isPt ? 'Equação incorreta. Tente novamente!' : 'Incorrect equation. Try again!';
  String get missingEquals => isPt ? 'A equação precisa conter o sinal de igual (=).' : 'The equation must contain an equals sign (=).';
  String get syntaxError => isPt ? 'Erro de sintaxe na expressão.' : 'Syntax error in the expression.';
  String get nonIntegerDiv => isPt
      ? 'Divisão não inteira não é permitida neste nível!'
      : 'Non-integer division is not allowed at this level!';
  String get divByZero => isPt ? 'Divisão por zero não é permitida!' : 'Division by zero is not allowed!';

  // Miku falas
  String get mikuWelcome => isPt ? 'Olá! Faça login para salvar sua pontuação! ♪' : 'Hi! Sign in to save your score! ♪';
  String get mikuThinking => isPt ? 'Coloque os operadores entre os números! ♪' : 'Place operators between the numbers! ♪';
  String get mikuHappy => isPt ? 'Perfeito! Pontos salvos na nuvem! ★' : 'Awesome! Points saved to the cloud! ★';
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
  String get historyTitle => isPt ? 'Números Resolvidos (Firestore)' : 'Solved Numbers (Firestore)';
  String get historyError => isPt ? 'Erro ao carregar dados do Firestore.' : 'Error loading data from Firestore.';
  String get historyEmpty => isPt ? 'Nenhum número resolvido ainda!' : 'No solved numbers yet!';
  String get resolvedNumber => isPt ? 'Número Resolvido' : 'Solved Number';
  String get recordLabel => isPt ? 'Registro' : 'Record';

  // Ajuda
  String get helpTitle => isPt ? 'Como Jogar o Emplake' : 'How to Play Emplake';
  String get helpBody => isPt
      ? '1. Os 4 dígitos do número sorteado ficam fixos na tela e nunca repetem um número que você já resolveu.\n\n'
        '2. Selecione ou arraste operadores para os espaços entre ou ao redor dos dígitos.\n\n'
        '3. Para remover um operador, toque no "x" dele ou limpe tudo.\n\n'
        '4. Monte uma igualdade válida com o sinal (=) para ganhar pontos na sua conta Firebase.\n\n'
        '5. Nos níveis Intermediário, Avançado e Difícil, divisões com resultado decimal geram erro.'
      : '1. The 4 digits stay fixed in order and never repeat a number you have already solved.\n\n'
        '2. Tap or drag operators into the slots between or around the digits.\n\n'
        '3. Tap an operator\'s "x" to remove it individually.\n\n'
        '4. Build a valid equation using (=) to earn points in your Firebase account.\n\n'
        '5. In Intermediate, Advanced, and Hard levels, non-integer divisions trigger an error.';
  String get gotIt => isPt ? 'Entendi' : 'Got it';


  String get mikuMusicTitle => isPt ? 'Música da Hatsune Miku' : 'Hatsune Miku Music';
  String get mikuMusicSubtitle => isPt
      ? 'Música de fundo em loop (inicia desligada)'
      : 'Looping background music (starts off)';
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