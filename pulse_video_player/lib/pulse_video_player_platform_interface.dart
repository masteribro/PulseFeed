import 'package:plugin_platform_interface/plugin_platform_interface.dart';

import 'pulse_video_player_method_channel.dart';

abstract class PulseVideoPlayerPlatform extends PlatformInterface {
  /// Constructs a PulseVideoPlayerPlatform.
  PulseVideoPlayerPlatform() : super(token: _token);

  static final Object _token = Object();

  static PulseVideoPlayerPlatform _instance = MethodChannelPulseVideoPlayer();

  /// The default instance of [PulseVideoPlayerPlatform] to use.
  ///
  /// Defaults to [MethodChannelPulseVideoPlayer].
  static PulseVideoPlayerPlatform get instance => _instance;

  /// Platform-specific implementations should set this with their own
  /// platform-specific class that extends [PulseVideoPlayerPlatform] when
  /// they register themselves.
  static set instance(PulseVideoPlayerPlatform instance) {
    PlatformInterface.verifyToken(instance, _token);
    _instance = instance;
  }

  Future<String?> getPlatformVersion() {
    throw UnimplementedError('platformVersion() has not been implemented.');
  }
}
