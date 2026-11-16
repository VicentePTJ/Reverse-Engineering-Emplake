import 'dart:math';
import 'dart:typed_data';
import 'package:audioplayers/audioplayers.dart';

class SoundService {
  final AudioPlayer _sfxPlayer = AudioPlayer();
  final AudioPlayer _bgmPlayer = AudioPlayer();

  late final Uint8List _clickWav = _buildMelodyWav([
    (freq: 880.0, duration: 0.055),
  ], volume: 0.25);

  late final Uint8List _successWav = _buildMelodyWav([
    (freq: 523.25, duration: 0.09),
    (freq: 659.25, duration: 0.09),
    (freq: 783.99, duration: 0.09),
    (freq: 1046.50, duration: 0.22),
  ], volume: 0.30);

  late final Uint8List _errorWav = _buildMelodyWav([
    (freq: 260.0, duration: 0.12),
    (freq: 195.0, duration: 0.20),
  ], volume: 0.28);

  /// Melodia sintetizada (tema Ievan Polkka - Hatsune Miku) caso não haja MP3 em assets/audio/
  late final Uint8List _mikuFallbackBgmWav = _buildMelodyWav([
    (freq: 369.99, duration: 0.16), // F#4
    (freq: 369.99, duration: 0.16), // F#4
    (freq: 415.30, duration: 0.16), // G#4
    (freq: 440.00, duration: 0.16), // A4
    (freq: 493.88, duration: 0.24), // B4
    (freq: 415.30, duration: 0.24), // G#4
    (freq: 329.63, duration: 0.24), // E4
    (freq: 329.63, duration: 0.24), // E4
    (freq: 554.37, duration: 0.16), // C#5
    (freq: 493.88, duration: 0.16), // B4
    (freq: 440.00, duration: 0.16), // A4
    (freq: 415.30, duration: 0.16), // G#4
    (freq: 440.00, duration: 0.24), // A4
    (freq: 369.99, duration: 0.36), // F#4
    (freq: 0.0, duration: 0.16),    // Pausa
  ], volume: 0.14);

  Future<void> playClick() async => _playSfxBytes(_clickWav);

  Future<void> playSuccess() async => _playSfxBytes(_successWav);

  Future<void> playError() async => _playSfxBytes(_errorWav);

  /// Inicia a música de fundo em loop
  Future<void> startMikuMusic() async {
    try {
      await _bgmPlayer.setReleaseMode(ReleaseMode.loop);
      await _bgmPlayer.setVolume(0.45);
      // Tenta carregar assets/audio/miku_bgm.mp3 primeiro
      await _bgmPlayer.play(AssetSource('audio/miku_bgm.mp3'));
    } catch (_) {
      // Se o MP3 ainda não existir no projeto, toca a versão sintetizada em loop
      try {
        await _bgmPlayer.setReleaseMode(ReleaseMode.loop);
        await _bgmPlayer.play(BytesSource(_mikuFallbackBgmWav));
      } catch (_) {}
    }
  }

  /// Para a música de fundo
  Future<void> stopMikuMusic() async {
    try {
      await _bgmPlayer.stop();
    } catch (_) {}
  }

  Future<void> _playSfxBytes(Uint8List bytes) async {
    try {
      await _sfxPlayer.stop();
      await _sfxPlayer.play(BytesSource(bytes));
    } catch (_) {}
  }

  static Uint8List _buildMelodyWav(
    List<({double freq, double duration})> notes, {
    double volume = 0.3,
  }) {
    const int sampleRate = 22050;
    final samples = <int>[];

    for (final note in notes) {
      final int noteSamples = (sampleRate * note.duration).round();
      for (int i = 0; i < noteSamples; i++) {
        if (note.freq <= 0) {
          samples.add(0);
          continue;
        }
        final double t = i / sampleRate;
        final double progress = i / noteSamples;
        final double envelope = sin(pi * progress);
        final double value = sin(2 * pi * note.freq * t) * envelope * volume;
        final int pcm = (value * 32767).round().clamp(-32768, 32767);
        samples.add(pcm);
      }
    }

    final int dataSize = samples.length * 2;
    final int fileSize = 36 + dataSize;
    final byteData = ByteData(44 + dataSize);

    _writeAscii(byteData, 0, 'RIFF');
    byteData.setUint32(4, fileSize, Endian.little);
    _writeAscii(byteData, 8, 'WAVE');
    _writeAscii(byteData, 12, 'fmt ');
    byteData.setUint32(16, 16, Endian.little);
    byteData.setUint16(20, 1, Endian.little);
    byteData.setUint16(22, 1, Endian.little);
    byteData.setUint32(24, sampleRate, Endian.little);
    byteData.setUint32(28, sampleRate * 2, Endian.little);
    byteData.setUint16(32, 2, Endian.little);
    byteData.setUint16(34, 16, Endian.little);
    _writeAscii(byteData, 36, 'data');
    byteData.setUint32(40, dataSize, Endian.little);

    for (int i = 0; i < samples.length; i++) {
      byteData.setInt16(44 + i * 2, samples[i], Endian.little);
    }

    return byteData.buffer.asUint8List();
  }

  static void _writeAscii(ByteData data, int offset, String text) {
    for (int i = 0; i < text.length; i++) {
      data.setUint8(offset + i, text.codeUnitAt(i));
    }
  }
}