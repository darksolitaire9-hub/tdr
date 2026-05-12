import 'dart:math';
import 'dart:typed_data';

import 'package:audioplayers/audioplayers.dart';

class AudioService {
  static bool enabled = true;

  static final _player = AudioPlayer();
  static Uint8List? _cachedWav;

  static Future<void> playCheck() async {
    if (!enabled) return;
    _cachedWav ??= _buildWav(_generateSamples());
    try {
      await _player.play(BytesSource(_cachedWav!));
    } catch (_) {
      // Silently ignore playback errors (no audio hardware, etc.)
    }
  }

  // 180ms of white noise with 3 kHz modulation and exponential decay.
  static Int16List _generateSamples() {
    const sampleRate  = 44100;
    const numSamples  = (sampleRate * 180) ~/ 1000; // ≈ 7938 samples
    const modFreq     = 3000.0;
    const gain        = 0.35;
    const decayK      = 5.0; // exp(-5) ≈ 0.0067 at tail

    final rng     = Random();
    final samples = Int16List(numSamples);

    for (var i = 0; i < numSamples; i++) {
      final noise      = rng.nextDouble() * 2 - 1;
      final modulation = sin(2 * pi * modFreq * i / sampleRate);
      final envelope   = exp(-decayK * i / numSamples);
      final value      = noise * modulation * envelope * gain * 32767;
      samples[i]       = value.clamp(-32768.0, 32767.0).toInt();
    }
    return samples;
  }

  static Uint8List _buildWav(Int16List samples) {
    const sampleRate     = 44100;
    const numChannels    = 1;
    const bitsPerSample  = 16;
    final  dataBytes     = samples.length * 2;
    final  buf           = ByteData(44 + dataBytes);
    var    o             = 0;

    void str(String s) {
      for (var i = 0; i < s.length; i++) {
        buf.setUint8(o + i, s.codeUnitAt(i));
      }
      o += s.length;
    }

    str('RIFF');
    buf.setUint32(o, 36 + dataBytes, Endian.little); o += 4;
    str('WAVE');
    str('fmt ');
    buf.setUint32(o, 16, Endian.little);             o += 4; // chunk size
    buf.setUint16(o, 1, Endian.little);              o += 2; // PCM
    buf.setUint16(o, numChannels, Endian.little);    o += 2;
    buf.setUint32(o, sampleRate, Endian.little);     o += 4;
    buf.setUint32(
        o, sampleRate * numChannels * bitsPerSample ~/ 8, Endian.little);
    o += 4;
    buf.setUint16(
        o, numChannels * bitsPerSample ~/ 8, Endian.little);
    o += 2;
    buf.setUint16(o, bitsPerSample, Endian.little);  o += 2;
    str('data');
    buf.setUint32(o, dataBytes, Endian.little);      o += 4;
    for (final s in samples) {
      buf.setInt16(o, s, Endian.little);
      o += 2;
    }
    return buf.buffer.asUint8List();
  }
}

