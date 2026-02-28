import 'package:flutter_test/flutter_test.dart';
import 'package:pulse_audio_player/pulse_audio_player.dart';
import 'package:pulse_audio_player/pulse_audio_player_platform_interface.dart';
import 'package:pulse_audio_player/pulse_audio_player_method_channel.dart';
import 'package:plugin_platform_interface/plugin_platform_interface.dart';

class MockPulseAudioPlayerPlatform
    with MockPlatformInterfaceMixin
    implements PulseAudioPlayerPlatform {

  @override
  Future<String?> getPlatformVersion() => Future.value('42');
}

void main() {
  final PulseAudioPlayerPlatform initialPlatform = PulseAudioPlayerPlatform.instance;

  test('$MethodChannelPulseAudioPlayer is the default instance', () {
    expect(initialPlatform, isInstanceOf<MethodChannelPulseAudioPlayer>());
  });

  test('getPlatformVersion', () async {
    PulseAudioPlayer pulseAudioPlayerPlugin = PulseAudioPlayer();
    MockPulseAudioPlayerPlatform fakePlatform = MockPulseAudioPlayerPlatform();
    PulseAudioPlayerPlatform.instance = fakePlatform;

    expect(await pulseAudioPlayerPlugin.getPlatformVersion(), '42');
  });
}
