import 'dart:async';
import 'package:flutter/services.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

part 'hardware_service.g.dart';

enum VolumeButton { up, down }

@Riverpod(keepAlive: true)
class HardwareService extends _$HardwareService {
  static const _channel = MethodChannel('com.example.todo/volume_buttons');

  @override
  Stream<VolumeButton> build() {
    final streamController = StreamController<VolumeButton>();

    _channel.setMethodCallHandler((call) async {
      if (call.method == 'volumeUp') {
        streamController.add(VolumeButton.up);
      } else if (call.method == 'volumeDown') {
        streamController.add(VolumeButton.down);
      }
    });

    ref.onDispose(() {
      _channel.setMethodCallHandler(null);
      streamController.close();
    });

    return streamController.stream;
  }
}
