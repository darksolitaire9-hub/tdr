import 'dart:math';
import 'dart:typed_data';

import 'package:audioplayers/audioplayers.dart';

enum AudioEffect {
  check,   // Pencil scratch
  delete,  // Paper rustle
  create,  // Wood knock
  select,  // Pebble drop
}

class AudioService {
  static bool enabled = true;

  static final _player = AudioPlayer();
  static final Map<AudioEffect, Uint8List> _cache = {};

  static Future<void> play(AudioEffect effect) async {
    if (!enabled) return;
    
    _cache[effect] ??= _buildWav(_generateSamples(effect));
    
    try {
      await _player.play(BytesSource(_cache[effect]!));
    } catch (_) {
      // Silently ignore playback errors
    }
  }

  static Int16List _generateSamples(AudioEffect effect) {
    switch (effect) {
      case AudioEffect.check:
        // Pencil scratch: white noise with modulation and decay
        return _generateNoise(durationMs: 120, modFreq: 3000, gain: 0.3);
      case AudioEffect.delete:
        // Paper rustle: longer, lower noise burst
        return _generateNoise(durationMs: 300, modFreq: 800, gain: 0.25, decayK: 4.0);
      case AudioEffect.create:
        // Wood knock: resonant sine pulse
        return _generateTone(durationMs: 100, freq: 220, gain: 0.5, resonance: 0.2);
      case AudioEffect.select:
        // Pebble drop: high pitch clack
        return _generateTone(durationMs: 60, freq: 880, gain: 0.4, resonance: 0.1);
    }
  }

  static Int16List _generateNoise({
    required int durationMs,
    required double modFreq,
    required double gain,
    double decayK = 6.0,
  }) {
    const sampleRate = 44100;
    final numSamples = (sampleRate * durationMs) ~/ 1000;
    final rng = Random();
    final samples = Int16List(numSamples);

    for (var i = 0; i < numSamples; i++) {
      final noise = rng.nextDouble() * 2 - 1;
      final modulation = sin(2 * pi * modFreq * i / sampleRate);
      final envelope = exp(-decayK * i / numSamples);
      final value = noise * modulation * envelope * gain * 32767;
      samples[i] = value.clamp(-32768.0, 32767.0).toInt();
    }
    return samples;
  }

  static Int16List _generateTone({
    required int durationMs,
    required double freq,
    required double gain,
    double resonance = 0.0,
  }) {
    const sampleRate = 44100;
    final numSamples = (sampleRate * durationMs) ~/ 1000;
    final samples = Int16List(numSamples);
    final rng = Random();

    for (var i = 0; i < numSamples; i++) {
      final t = i / sampleRate;
      final sine = sin(2 * pi * freq * t);
      final noise = (rng.nextDouble() * 2 - 1) * resonance;
      final envelope = exp(-8.0 * i / numSamples);
      final value = (sine + noise) * envelope * gain * 32767;
      samples[i] = value.clamp(-32768.0, 32767.0).toInt();
    }
    return samples;
  }

  static Uint8List _buildWav(Int16List samples) {
    const sampleRate     = 44100;
    const numChannels    = 1;
    const bitsPerSample  = 16;
    final dataBytes      = samples.length * 2;
    final buf            = ByteData(44 + dataBytes);
    var o = 0;

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
    buf.setUint32(o, 16, Endian.little);             o += 4;
    buf.setUint16(o, 1, Endian.little);              o += 2;
    buf.setUint16(o, numChannels, Endian.little);    o += 2;
    buf.setUint32(o, sampleRate, Endian.little);     o += 4;
    buf.setUint32(o, sampleRate * numChannels * bitsPerSample ~/ 8, Endian.little); o += 4;
    buf.setUint16(o, numChannels * bitsPerSample ~/ 8, Endian.little); o += 2;
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

