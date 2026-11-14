import 'dart:math';

enum DifficultyLevel { facil, intermediario, avancado, dificil }

class MathEngine {
  /// Operadores permitidos por nível de complexidade
  static List<String> getOperatorsForLevel(DifficultyLevel level) {
    switch (level) {
      case DifficultyLevel.facil:
        return ['+', '-', '*', '/', '(', ')', '=', '√', '∛', '!', '**', '|', '⌊', '⌋', '⌈', '⌉'];
      case DifficultyLevel.intermediario:
        return ['+', '-', '*', '/', '(', ')', '=', '√', '∛', '!', '**', '|'];
      case DifficultyLevel.avancado:
        return ['+', '-', '*', '/', '(', ')', '=', '√', '!', '|'];
      case DifficultyLevel.dificil:
        return ['+', '-', '*', '/', '(', ')', '=', '|'];
    }
  }

  /// Converte a lista de tokens da fórmula em sintaxe LaTeX limpa
  static String convertTokensToLaTeX(List<String> tokens) {
    if (tokens.isEmpty) return r'\text{...}';

    final buffer = StringBuffer();
    int i = 0;
    bool openPipe = false;

    while (i < tokens.length) {
      final t = tokens[i];

      if (t == '√' || t == '∛') {
        final cmd = t == '√' ? r'\sqrt' : r'\sqrt[3]';
        if (i + 1 < tokens.length && tokens[i + 1] == '(') {
          // Captura o grupo entre parênteses para colocar dentro de \sqrt{...}
          int depth = 0;
          int j = i + 1;
          final inner = <String>[];
          while (j < tokens.length) {
            if (tokens[j] == '(') depth++;
            if (tokens[j] == ')') depth--;
            if (j > i + 1 && depth > 0) inner.add(tokens[j]);
            if (depth == 0) break;
            j++;
          }
          buffer.write('$cmd{${convertTokensToLaTeX(inner)}}');
          i = j + 1;
          continue;
        } else if (i + 1 < tokens.length) {
          buffer.write('$cmd{${tokens[i + 1]}}');
          i += 2;
          continue;
        } else {
          buffer.write('$cmd{\\square}');
        }
      } else if (t == '**') {
        if (i + 1 < tokens.length) {
          buffer.write('^{${tokens[i + 1]}}');
          i += 2;
          continue;
        } else {
          buffer.write('^{\\square}');
        }
      } else if (t == '*') {
        buffer.write(r' \times ');
      } else if (t == '⌊') {
        buffer.write(r'\lfloor ');
      } else if (t == '⌋') {
        buffer.write(r' \rfloor');
      } else if (t == '⌈') {
        buffer.write(r'\lceil ');
      } else if (t == '⌉') {
        buffer.write(r' \rceil');
      } else if (t == '|') {
        buffer.write(openPipe ? r'\right|' : r'\left|');
        openPipe = !openPipe;
      } else if (t == '=') {
        buffer.write(' = ');
      } else {
        buffer.write(t);
      }
      i++;
    }

    return buffer.toString();
  }

  /// Avalia a igualdade completa a partir da lista de tokens
  static bool evaluateTokens(
    List<String> tokens,
    DifficultyLevel level, {
    required String missingEqualsMsg,
    required String syntaxErrorMsg,
    required String nonIntegerDivMsg,
    required String divByZeroMsg,
  }) {
    final equalsIndices = <int>[];
    for (int i = 0; i < tokens.length; i++) {
      if (tokens[i] == '=') equalsIndices.add(i);
    }

    if (equalsIndices.length != 1) {
      throw FormatException(missingEqualsMsg);
    }

    final eqIndex = equalsIndices.first;
    final leftTokens = tokens.sublist(0, eqIndex);
    final rightTokens = tokens.sublist(eqIndex + 1);

    if (leftTokens.isEmpty || rightTokens.isEmpty) {
      throw FormatException(syntaxErrorMsg);
    }

    final leftVal = _RecursiveParser(
      _mergeDigits(leftTokens),
      level: level,
      syntaxErrorMsg: syntaxErrorMsg,
      nonIntegerDivMsg: nonIntegerDivMsg,
      divByZeroMsg: divByZeroMsg,
    ).parse();

    final rightVal = _RecursiveParser(
      _mergeDigits(rightTokens),
      level: level,
      syntaxErrorMsg: syntaxErrorMsg,
      nonIntegerDivMsg: nonIntegerDivMsg,
      divByZeroMsg: divByZeroMsg,
    ).parse();

    return (leftVal - rightVal).abs() < 1e-9;
  }

  /// Agrupa dígitos adjacentes sem operador no meio (ex: ['1', '2'] -> ['12'])
  static List<String> _mergeDigits(List<String> rawTokens) {
    final merged = <String>[];
    final digitRegex = RegExp(r'^\d$');

    for (final token in rawTokens) {
      if (digitRegex.hasMatch(token) &&
          merged.isNotEmpty &&
          RegExp(r'^\d+$').hasMatch(merged.last)) {
        merged[merged.length - 1] = merged.last + token;
      } else {
        merged.add(token);
      }
    }
    return merged;
  }
}

class _RecursiveParser {
  final List<String> tokens;
  final DifficultyLevel level;
  final String syntaxErrorMsg;
  final String nonIntegerDivMsg;
  final String divByZeroMsg;
  int pos = 0;

  _RecursiveParser(
    this.tokens, {
    required this.level,
    required this.syntaxErrorMsg,
    required this.nonIntegerDivMsg,
    required this.divByZeroMsg,
  });

  String? get current => pos < tokens.length ? tokens[pos] : null;

  double parse() {
    if (tokens.isEmpty) throw FormatException(syntaxErrorMsg);
    final result = _parseAddSub();
    if (pos != tokens.length) {
      throw FormatException(syntaxErrorMsg);
    }
    return result;
  }

  double _parseAddSub() {
    double left = _parseMulDiv();
    while (current == '+' || current == '-') {
      final op = tokens[pos++];
      final right = _parseMulDiv();
      if (op == '+') {
        left += right;
      } else {
        left -= right;
      }
    }
    return left;
  }

  double _parseMulDiv() {
    double left = _parsePower();
    while (current == '*' || current == '/') {
      final op = tokens[pos++];
      final right = _parsePower();
      if (op == '*') {
        left *= right;
      } else {
        if (right.abs() < 1e-12) {
          throw FormatException(divByZeroMsg);
        }
        final res = left / right;
        if (level != DifficultyLevel.facil && (res - res.roundToDouble()).abs() > 1e-9) {
          throw FormatException(nonIntegerDivMsg);
        }
        left = res;
      }
    }
    return left;
  }

  double _parsePower() {
    double base = _parseUnary();
    if (current == '**') {
      pos++;
      final exp = _parsePower(); // Associativo à direita
      base = pow(base, exp).toDouble();
    }
    return base;
  }

  double _parseUnary() {
    if (current == '-') {
      pos++;
      return -_parseUnary();
    }
    if (current == '+') {
      pos++;
      return _parseUnary();
    }
    if (current == '√') {
      pos++;
      final val = _parseUnary();
      if (val < 0) throw FormatException(syntaxErrorMsg);
      return sqrt(val);
    }
    if (current == '∛') {
      pos++;
      final val = _parseUnary();
      return val < 0 ? -pow(-val, 1 / 3).toDouble() : pow(val, 1 / 3).toDouble();
    }
    return _parsePostfix();
  }

  double _parsePostfix() {
    double val = _parsePrimary();
    while (current == '!') {
      pos++;
      if (val < 0 || (val - val.roundToDouble()).abs() > 1e-9 || val > 20) {
        throw FormatException(syntaxErrorMsg);
      }
      val = _factorial(val.round()).toDouble();
    }
    return val;
  }

  double _parsePrimary() {
    final token = current;
    if (token == null) throw FormatException(syntaxErrorMsg);

    if (token == '(') {
      pos++;
      final val = _parseAddSub();
      if (current != ')') throw FormatException(syntaxErrorMsg);
      pos++;
      return val;
    }

    if (token == '|') {
      pos++;
      final val = _parseAddSub();
      if (current != '|') throw FormatException(syntaxErrorMsg);
      pos++;
      return val.abs();
    }

    if (token == '⌊') {
      pos++;
      final val = _parseAddSub();
      if (current != '⌋') throw FormatException(syntaxErrorMsg);
      pos++;
      return val.floorToDouble();
    }

    if (token == '⌈') {
      pos++;
      final val = _parseAddSub();
      if (current != '⌉') throw FormatException(syntaxErrorMsg);
      pos++;
      return val.ceilToDouble();
    }

    final parsedNum = double.tryParse(token);
    if (parsedNum != null) {
      pos++;
      return parsedNum;
    }

    throw FormatException(syntaxErrorMsg);
  }

  int _factorial(int n) {
    int res = 1;
    for (int i = 2; i <= n; i++) {
      res *= i;
    }
    return res;
  }
}