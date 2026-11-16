import 'dart:math';
import 'dart:typed_data';
import 'package:audioplayers/audioplayers.dart';

class SoundService {
  final AudioPlayer _player = AudioPlayer();

  late final Uint8List _clickWav = _buildMelodyWav([
    (freq: 880.0, duration: 0.055), // Nota Lá5 curta (clique suave)
  ], volume: 0.25);

  late final Uint8List _successWav = _buildMelodyWav([
    (freq: 523.25, duration: 0.09), // Dó5
    (freq: 659.25, duration: 0.09), // Mi5
    (freq: 783.99, duration: 0.09), // Sol5
    (freq: 1046.50, duration: 0.22), // Dó6
  ], volume: 0.30);

  late final Uint8List _errorWav = _buildMelodyWav([
    (freq: 260.0, duration: 0.12),
    (freq: 195.0, duration: 0.20),
  ], volume: 0.28);

  Future<void> playClick() async {
    await _playBytes(_clickWav);
  }

  Future<void> playSuccess() async {
    await _playBytes(_successWav);
  }

  Future<void> playError() async {
    await _playBytes(_errorWav);
  }

  Future<void> _playBytes(Uint8List bytes) async {
    try {
      await _player.stop();
      await _player.play(BytesSource(bytes));
    } catch (_) {
      // Ignora bloqueios pontuais de autoplay do navegador
    }
  }

  /// Gera um arquivo WAV PCM 16-bit mono válido em memória
  static Uint8List _buildMelodyWav(
    List<({double freq, double duration})> notes, {
    double volume = 0.3,
  }) {
    const int sampleRate = 22050;
    final samples = <int>[];

    for (final note in notes) {
      final int noteSamples = (sampleRate * note.duration).round();
      for (int i = 0; i < noteSamples; i++) {
        final double t = i / sampleRate;
        // Envelope suave para evitar estalos no início e fim da nota
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

    // Cabeçalho RIFF/WAVE
    _writeAscii(byteData, 0, 'RIFF');
    byteData.setUint32(4, fileSize, Endian.little);
    _writeAscii(byteData, 8, 'WAVE');
    _writeAscii(byteData, 12, 'fmt ');
    byteData.setUint32(16, 16, Endian.little); // Tamanho do chunk PCM
    byteData.setUint16(20, 1, Endian.little); // Formato PCM (1)
    byteData.setUint16(22, 1, Endian.little); // Mono (1 canal)
    byteData.setUint32(24, sampleRate, Endian.little);
    byteData.setUint32(28, sampleRate * 2, Endian.little); // ByteRate
    byteData.setUint16(32, 2, Endian.little); // BlockAlign
    byteData.setUint16(34, 16, Endian.little); // BitsPerSample
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