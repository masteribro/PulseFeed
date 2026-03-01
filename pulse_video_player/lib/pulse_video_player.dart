import 'dart:async';
import 'package:flutter/services.dart';

class PulseVideoPlayer {
  static const MethodChannel _channel = MethodChannel('pulse_video_player');

  final StreamController<VideoPlaybackEvent> _eventController =
  StreamController.broadcast();
  Stream<VideoPlaybackEvent> get events => _eventController.stream;

  bool _isPlaying = false;
  bool get isPlaying => _isPlaying;

  bool _isBuffering = false;
  bool get isBuffering => _isBuffering;

  Duration? _duration;
  Duration? get duration => _duration;

  Duration? _position;
  Duration? get position => _position;

  PulseVideoPlayer() {
    _channel.setMethodCallHandler(_handleMethodCall);
  }

  Future<void> _handleMethodCall(MethodCall call) async {
    switch (call.method) {
      case 'onDuration':
        _duration = Duration(milliseconds: call.arguments);
        _eventController.add(VideoPlaybackEvent.durationUpdated);
        break;
      case 'onPosition':
        _position = Duration(milliseconds: call.arguments);
        _eventController.add(VideoPlaybackEvent.positionUpdated);
        break;
      case 'onBuffering':
        _isBuffering = call.arguments ?? false;
        _eventController.add(VideoPlaybackEvent.buffering);
        break;
      case 'onCompletion':
        _isPlaying = false;
        _eventController.add(VideoPlaybackEvent.completed);
        break;
      case 'onError':
        _eventController.add(VideoPlaybackEvent.error);
        break;
    }
  }

  /// Play video from URL
  Future<bool> play(String url) async {
    try {
      final result = await _channel.invokeMethod<bool>('play', {'url': url});
      _isPlaying = result ?? false;
      return _isPlaying;
    } catch (e) {
      print('Error playing video: $e');
      return false;
    }
  }

  /// Pause current video
  Future<bool> pause() async {
    try {
      final result = await _channel.invokeMethod<bool>('pause');
      if (result == true) _isPlaying = false;
      return result ?? false;
    } catch (e) {
      print('Error pausing video: $e');
      return false;
    }
  }

  /// Stop current video
  Future<bool> stop() async {
    try {
      final result = await _channel.invokeMethod<bool>('stop');
      if (result == true) {
        _isPlaying = false;
        _position = Duration.zero;
      }
      return result ?? false;
    } catch (e) {
      print('Error stopping video: $e');
      return false;
    }
  }

  /// Seek to position
  Future<bool> seekTo(Duration position) async {
    try {
      final result = await _channel.invokeMethod<bool>(
          'seekTo',
          {'position': position.inMilliseconds}
      );
      return result ?? false;
    } catch (e) {
      print('Error seeking video: $e');
      return false;
    }
  }

  /// Set volume (0.0 to 1.0)
  Future<bool> setVolume(double volume) async {
    try {
      final result = await _channel.invokeMethod<bool>(
          'setVolume',
          {'volume': volume}
      );
      return result ?? false;
    } catch (e) {
      print('Error setting volume: $e');
      return false;
    }
  }

  /// Set playback speed
  Future<bool> setPlaybackSpeed(double speed) async {
    try {
      final result = await _channel.invokeMethod<bool>(
          'setPlaybackSpeed',
          {'speed': speed}
      );
      return result ?? false;
    } catch (e) {
      print('Error setting speed: $e');
      return false;
    }
  }

  /// Set looping
  Future<bool> setLooping(bool loop) async {
    try {
      final result = await _channel.invokeMethod<bool>(
          'setLooping',
          {'loop': loop}
      );
      return result ?? false;
    } catch (e) {
      print('Error setting looping: $e');
      return false;
    }
  }

  /// Dispose the player
  Future<void> dispose() async {
    await _channel.invokeMethod('dispose');
    await _eventController.close();
  }
}

enum VideoPlaybackEvent {
  durationUpdated,
  positionUpdated,
  buffering,
  completed,
  error,
}