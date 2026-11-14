import 'package:flutter/material.dart';
import '../../providers/app_providers.dart';

class HatsuneMikuWidget extends StatelessWidget {
  final MikuMood mood;
  final String speechText;
  final double size;

  const HatsuneMikuWidget({
    super.key,
    required this.mood,
    required this.speechText,
    this.size = 90,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        SizedBox(
          width: size,
          height: size,
          child: CustomPaint(
            painter: _MikuPainter(mood: mood),
          ),
        ),
        const SizedBox(width: 8),
        Flexible(
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
            decoration: BoxDecoration(
              color: isDark
                  ? const Color(0xFF1E3A3A)
                  : const Color(0xFFE0F7F6),
              borderRadius: const BorderRadius.only(
                topLeft: Radius.circular(16),
                topRight: Radius.circular(16),
                bottomRight: Radius.circular(16),
                bottomLeft: Radius.circular(4),
              ),
              border: Border.all(color: const Color(0xFF39C5BB), width: 1.5),
            ),
            child: Text(
              speechText,
              style: TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.w600,
                color: isDark ? const Color(0xFFA7F3EE) : const Color(0xFF0F4C48),
              ),
            ),
          ),
        ),
      ],
    );
  }
}

class _MikuPainter extends CustomPainter {
  final MikuMood mood;
  _MikuPainter({required this.mood});

  @override
  void paint(Canvas canvas, Size size) {
    final w = size.width;
    final h = size.height;

    final mikuTeal = Paint()..color = const Color(0xFF39C5BB);
    final mikuTealDark = Paint()..color = const Color(0xFF238E87);
    final mikuTealLight = Paint()..color = const Color(0xFF88ECE5);
    final skinPaint = Paint()..color = const Color(0xFFFFE5D9);
    final magentaPaint = Paint()..color = const Color(0xFFE6007E);
    final darkGreyPaint = Paint()..color = const Color(0xFF2B2D38);
    final shirtPaint = Paint()..color = const Color(0xFFD8DEE9);

    // 1. Twin-tails (Maria-chiquinhas longas turquesa)
    final leftTail = Path()
      ..moveTo(w * 0.24, h * 0.28)
      ..quadraticBezierTo(w * 0.02, h * 0.48, w * 0.08, h * 0.92)
      ..quadraticBezierTo(w * 0.20, h * 0.85, w * 0.28, h * 0.45)
      ..close();
    canvas.drawPath(leftTail, mikuTealDark);
    canvas.drawPath(leftTail.shift(const Offset(2, -2)), mikuTeal);

    final rightTail = Path()
      ..moveTo(w * 0.76, h * 0.28)
      ..quadraticBezierTo(w * 0.98, h * 0.48, w * 0.92, h * 0.92)
      ..quadraticBezierTo(w * 0.80, h * 0.85, w * 0.72, h * 0.45)
      ..close();
    canvas.drawPath(rightTail, mikuTealDark);
    canvas.drawPath(rightTail.shift(const Offset(-2, -2)), mikuTeal);

    // 2. Roupa e gravata
    final bodyPath = Path()
      ..moveTo(w * 0.32, h * 0.68)
      ..lineTo(w * 0.68, h * 0.68)
      ..lineTo(w * 0.74, h * 0.96)
      ..lineTo(w * 0.26, h * 0.96)
      ..close();
    canvas.drawPath(bodyPath, shirtPaint);

    // Gravata turquesa
    final tiePath = Path()
      ..moveTo(w * 0.47, h * 0.70)
      ..lineTo(w * 0.53, h * 0.70)
      ..lineTo(w * 0.55, h * 0.92)
      ..lineTo(w * 0.50, h * 0.95)
      ..lineTo(w * 0.45, h * 0.92)
      ..close();
    canvas.drawPath(tiePath, mikuTeal);

    // 3. Rosto
    canvas.drawOval(
      Rect.fromCenter(center: Offset(w * 0.50, h * 0.46), width: w * 0.48, height: h * 0.46),
      skinPaint,
    );

    // 4. Cabelo superior e franja
    final hairTop = Path()
      ..moveTo(w * 0.24, h * 0.46)
      ..quadraticBezierTo(w * 0.25, h * 0.12, w * 0.50, h * 0.12)
      ..quadraticBezierTo(w * 0.75, h * 0.12, w * 0.76, h * 0.46)
      ..lineTo(w * 0.68, h * 0.36)
      ..lineTo(w * 0.58, h * 0.42)
      ..lineTo(w * 0.50, h * 0.34)
      ..lineTo(w * 0.42, h * 0.42)
      ..lineTo(w * 0.32, h * 0.36)
      ..close();
    canvas.drawPath(hairTop, mikuTeal);

    // Brilho no cabelo
    canvas.drawArc(
      Rect.fromLTWH(w * 0.34, h * 0.20, w * 0.32, h * 0.10),
      3.14,
      3.14,
      false,
      mikuTealLight..style = PaintingStyle.stroke..strokeWidth = 3,
    );

    // 5. Presilhas pretas com borda magenta
    canvas.drawRect(Rect.fromLTWH(w * 0.20, h * 0.22, w * 0.08, w * 0.08), darkGreyPaint);
    canvas.drawRect(
      Rect.fromLTWH(w * 0.20, h * 0.22, w * 0.08, w * 0.08),
      magentaPaint..style = PaintingStyle.stroke..strokeWidth = 2,
    );

    canvas.drawRect(Rect.fromLTWH(w * 0.72, h * 0.22, w * 0.08, w * 0.08), darkGreyPaint);
    canvas.drawRect(
      Rect.fromLTWH(w * 0.72, h * 0.22, w * 0.08, w * 0.08),
      magentaPaint..style = PaintingStyle.stroke..strokeWidth = 2,
    );

    // 6. Olhos e expressão de acordo com o humor
    final eyePaint = Paint()..color = const Color(0xFF1A7A74);
    final whitePaint = Paint()..color = Colors.white;
    final mouthPaint = Paint()
      ..color = const Color(0xFFD9534F)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2.2
      ..strokeCap = StrokeCap.round;

    if (mood == MikuMood.happy) {
      // Olhos fechados sorrindo (^ ^)
      final happyEye = Paint()
        ..color = const Color(0xFF1A7A74)
        ..style = PaintingStyle.stroke
        ..strokeWidth = 2.5
        ..strokeCap = StrokeCap.round;
      canvas.drawArc(Rect.fromLTWH(w * 0.35, h * 0.44, w * 0.10, h * 0.08), 3.14, 3.14, false, happyEye);
      canvas.drawArc(Rect.fromLTWH(w * 0.55, h * 0.44, w * 0.10, h * 0.08), 3.14, 3.14, false, happyEye);
      // Sorriso aberto
      canvas.drawArc(Rect.fromLTWH(w * 0.44, h * 0.53, w * 0.12, h * 0.09), 0, 3.14, true, Paint()..color = const Color(0xFFFF758F));
    } else if (mood == MikuMood.oops) {
      // Olhos (> <)
      final oopsEye = Paint()
        ..color = const Color(0xFF1A7A74)
        ..style = PaintingStyle.stroke
        ..strokeWidth = 2.3;
      canvas.drawLine(Offset(w * 0.36, h * 0.44), Offset(w * 0.43, h * 0.48), oopsEye);
      canvas.drawLine(Offset(w * 0.43, h * 0.48), Offset(w * 0.36, h * 0.52), oopsEye);
      canvas.drawLine(Offset(w * 0.64, h * 0.44), Offset(w * 0.57, h * 0.48), oopsEye);
      canvas.drawLine(Offset(w * 0.57, h * 0.48), Offset(w * 0.64, h * 0.52), oopsEye);
      canvas.drawOval(Rect.fromCenter(center: Offset(w * 0.50, h * 0.58), width: w * 0.07, height: h * 0.06), mouthPaint);
    } else {
      // Olhos padrão anime turquesa
      canvas.drawOval(Rect.fromCenter(center: Offset(w * 0.40, h * 0.48), width: w * 0.08, height: h * 0.11), eyePaint);
      canvas.drawCircle(Offset(w * 0.39, h * 0.46), w * 0.018, whitePaint);

      canvas.drawOval(Rect.fromCenter(center: Offset(w * 0.60, h * 0.48), width: w * 0.08, height: h * 0.11), eyePaint);
      canvas.drawCircle(Offset(w * 0.59, h * 0.46), w * 0.018, whitePaint);

      // Sorriso suave
      canvas.drawArc(Rect.fromLTWH(w * 0.45, h * 0.54, w * 0.10, h * 0.06), 0.2, 2.7, false, mouthPaint);
    }
  }

  @override
  bool shouldRepaint(covariant _MikuPainter oldDelegate) => oldDelegate.mood != mood;
}