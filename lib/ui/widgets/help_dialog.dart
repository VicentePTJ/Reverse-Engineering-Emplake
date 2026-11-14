import 'package:flutter/material.dart';

class HelpDialog extends StatelessWidget {
  const HelpDialog({super.key});

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('Como Jogar o Emplake'),
      content: const SingleChildScrollView(
        child: Text(
          '1. Utilize os 4 dígitos fornecidos e os operadores matemáticos disponíveis.\n\n'
          '2. Monte uma equação válida contendo o sinal de igual (=).\n\n'
          '3. Em níveis acima do "Fácil", divisões que resultam em números fracionários geram erro.\n\n'
          '4. Verifique sua equação em formato matemático formatado no painel LaTeX.',
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: const Text('Entendi'),
        ),
      ],
    );
  }
}