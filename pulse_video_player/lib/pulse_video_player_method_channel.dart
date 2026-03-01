import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';

import 'pulse_video_player_platform_interface.dart';

/// An implementation of [PulseVideoPlayerPlatform] that uses method channels.
class MethodChannelPulseVideoPlayer extends PulseVideoPlayerPlatform {
  /// The method channel used to interact with the native platform.
  @visibleForTesting
  final methodChannel = const MethodChannel('pulse_video_player');

  @override
  Future<String?> getPlatformVersion() async {
    final version = await methodChannel.invokeMethod<String>('getPlatformVersion');
    return version;
  }
}
