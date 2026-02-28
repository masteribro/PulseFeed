import 'package:plugin_platform_interface/plugin_platform_interface.dart';

import 'pulse_audio_player_method_channel.dart';

abstract class PulseAudioPlayerPlatform extends PlatformInterface {
  /// Constructs a PulseAudioPlayerPlatform.
  PulseAudioPlayerPlatform() : super(token: _token);

  static final Object _token = Object();

  static PulseAudioPlayerPlatform _instance = MethodChannelPulseAudioPlayer();

  /// The default instance of [PulseAudioPlayerPlatform] to use.
  ///
  /// Defaults to [MethodChannelPulseAudioPlayer].
  static PulseAudioPlayerPlatform get instance => _instance;

  /// Platform-specific implementations should set this with their own
  /// platform-specific class that extends [PulseAudioPlayerPlatform] when
  /// they register themselves.
  static set instance(PulseAudioPlayerPlatform instance) {
    PlatformInterface.verifyToken(instance, _token);
    _instance = instance;
  }

  Future<String?> getPlatformVersion() {
    throw UnimplementedError('platformVersion() has not been implemented.');
  }
}
