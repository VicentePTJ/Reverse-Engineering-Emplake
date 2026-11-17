import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter/material.dart';
import 'package:model_viewer_plus/model_viewer_plus.dart';
import '../../providers/app_providers.dart';

/// Nomes exatos retornados por availableAnimations no miku.glb:
/// ["Happy", "Idle", "Oops", "T-Pose"]
const String? kMikuIdleAnimationName = 'Idle';
const String? kMikuHappyAnimationName = 'Happy';
const String? kMikuOopsAnimationName = 'Oops';

class HatsuneMikuWidget extends StatelessWidget {
  final MikuMood mood;
  final String speechText;
  final double size;
  final String cameraTarget;
  final String cameraOrbit;
  final String minCameraOrbit;
  final String maxCameraOrbit;
  final String fieldOfView;

  const HatsuneMikuWidget({
    super.key,
    required this.mood,
    required this.speechText,
    this.size = 115,
    // Valores padrão mantidos para preservar o enquadramento atual da tela de login
    this.cameraTarget = '0m 1.35m 0m',
    this.cameraOrbit = '0deg 82deg 1.55m',
    this.minCameraOrbit = '0deg 82deg 0.55m',
    this.maxCameraOrbit = '0deg 82deg 2.2m',
    this.fieldOfView = '32deg',
  });

  Color _borderColorForMood() {
    switch (mood) {
      case MikuMood.happy:
        return Colors.greenAccent.shade400;
      case MikuMood.oops:
        return Colors.pinkAccent;
      case MikuMood.thinking:
        return const Color(0xFF39C5BB);
    }
  }

  String? _animationForMood() {
    switch (mood) {
      case MikuMood.happy:
        return kMikuHappyAnimationName ?? kMikuIdleAnimationName;
      case MikuMood.oops:
        return kMikuOopsAnimationName ?? kMikuIdleAnimationName;
      case MikuMood.thinking:
        return kMikuIdleAnimationName;
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final accentColor = _borderColorForMood();
    final currentAnimation = _animationForMood();

    final screenWidth = MediaQuery.sizeOf(context).width;
    final maxAllowedSize = (screenWidth * 0.42).clamp(120.0, 210.0);
    final stageSize = (size * 1.45).clamp(120.0, maxAllowedSize);

    final modelPath = kIsWeb
        ? 'assets/assets/models/miku.glb'
        : 'assets/models/miku.glb';

    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          width: stageSize,
          height: stageSize,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            color: isDark
                ? const Color(0xFF152A2A)
                : const Color(0xFFE6F9F8),
            border: Border.all(color: accentColor, width: 2.5),
            boxShadow: [
              BoxShadow(
                color: accentColor.withOpacity(0.35),
                blurRadius: 12,
                spreadRadius: 1,
              ),
            ],
          ),
          child: ClipOval(
            child: ModelViewer(
              key: ValueKey('${mood.name}_$currentAnimation'),
              src: modelPath,
              alt: 'Modelo 3D da Hatsune Miku',
              backgroundColor: Colors.transparent,
              ar: false,
              autoPlay: true,
              animationName: currentAnimation,
              animationCrossfadeDuration: 300,
              autoRotate: false,
              cameraControls: true,
              disableZoom: false,
              disablePan: true,
              cameraTarget: cameraTarget,
              cameraOrbit: cameraOrbit,
              minCameraOrbit: minCameraOrbit,
              maxCameraOrbit: maxCameraOrbit,
              fieldOfView: fieldOfView,
            ),
          ),
        ),
        const SizedBox(width: 14),
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
              border: Border.all(color: accentColor, width: 1.5),
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