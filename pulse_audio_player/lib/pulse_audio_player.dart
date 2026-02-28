import 'dart:async';
import 'package:flutter/services.dart';

class PulseAudioPlayer {
  static const MethodChannel _channel = MethodChannel('pulse_audio_player');

  final StreamController<AudioPlaybackEvent> _eventController =
  StreamController.broadcast();
  Stream<AudioPlaybackEvent> get events => _eventController.stream;

  bool _isPlaying = false;
  bool get isPlaying => _isPlaying;

  Duration? _duration;
  Duration? get duration => _duration;

  Duration? _position;
  Duration? get position => _position;

  PulseAudioPlayer() {
    _channel.setMethodCallHandler(_handleMethodCall);
  }

  Future<void> _handleMethodCall(MethodCall call) async {
    switch (call.method) {
      case 'onDuration':
        _duration = Duration(milliseconds: call.arguments);
        _eventController.add(AudioPlaybackEvent.durationUpdated);
        break;
      case 'onPosition':
        _position = Duration(milliseconds: call.arguments);
        _eventController.add(AudioPlaybackEvent.positionUpdated);
        break;
      case 'onCompletion':
        _isPlaying = false;
        _eventController.add(AudioPlaybackEvent.completed);
        break;
      case 'onError':
        _eventController.add(AudioPlaybackEvent.error);
        break;
    }
  }

  Future<bool> play(String url) async {
    try {
      final result = await _channel.invokeMethod<bool>('play', {'url': url});
      _isPlaying = result ?? false;
      return _isPlaying;
    } catch (e) {
      print('Error playing audio: $e');
      return false;
    }
  }

  Future<bool> pause() async {
    try {
      final result = await _channel.invokeMethod<bool>('pause');
      if (result == true) _isPlaying = false;
      return result ?? false;
    } catch (e) {
      print('Error pausing audio: $e');
      return false;
    }
  }

  Future<bool> stop() async {
    try {
      final result = await _channel.invokeMethod<bool>('stop');
      if (result == true) {
        _isPlaying = false;
        _position = Duration.zero;
      }
      return result ?? false;
    } catch (e) {
      print('Error stopping audio: $e');
      return false;
    }
  }


  /// Dispose the player
  Future<void> dispose() async {
    await _channel.invokeMethod('dispose');
    await _eventController.close();
  }
}

enum AudioPlaybackEvent {
  durationUpdated,
  positionUpdated,
  completed,
  error,
}