import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';

import 'pulse_audio_player_platform_interface.dart';

/// An implementation of [PulseAudioPlayerPlatform] that uses method channels.
class MethodChannelPulseAudioPlayer extends PulseAudioPlayerPlatform {
  /// The method channel used to interact with the native platform.
  @visibleForTesting
  final methodChannel = const MethodChannel('pulse_audio_player');

  @override
  Future<String?> getPlatformVersion() async {
    final version = await methodChannel.invokeMethod<String>('getPlatformVersion');
    return version;
  }
}
