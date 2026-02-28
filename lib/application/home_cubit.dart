import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:pulse_audio_player/pulse_audio_player.dart';
import 'dart:io';
import 'home_state.dart';

class HomeCubit extends Cubit<HomeState> {
  HomeCubit() : super(HomeInitial());

  static const audioChannel = MethodChannel('com.example.pulse_feed/audio');
  static const videoChannel = MethodChannel('com.example.pulse_feed/video');
  static const documentChannel = MethodChannel('com.example.pulse_feed/document');

  PulseAudioPlayer audioPlayer = PulseAudioPlayer();

  Future<void> playAudio(String url) async {
    try {
      await audioPlayer.play(url);
      emit(HomeAudioState(true));
    } catch (e) {
      emit(HomeError('Audio error: $e'));
    }
  }

  Future<void> pauseAudio() async {
    try {
      await audioPlayer.pause() ;
      emit(HomeAudioState(false));
    } catch (e) {
      emit(HomeError('Audio error: $e'));
    }
  }

  Future<void> stopAudio() async {
    try {
      await audioPlayer.stop();
      emit(HomeAudioState(false));
    } catch (e) {
      emit(HomeError('Audio error: $e'));
    }
  }

  Future<void> playVideo(String url) async {
    try {
      await videoChannel.invokeMethod('play', {'url': url});
      emit(HomeVideoState(true));
    } catch (e) {
      emit(HomeError('Video error: $e'));
    }
  }

  Future<void> pauseVideo() async {
    try {
      await videoChannel.invokeMethod('pause');
      emit(HomeVideoState(false));
    } catch (e) {
      emit(HomeError('Video error: $e'));
    }
  }

  Future<void> stopVideo() async {
    try {
      await videoChannel.invokeMethod('stop');
      emit(HomeVideoState(false));
    } catch (e) {
      emit(HomeError('Video error: $e'));
    }
  }

  Future<void> viewDocument(String url, String fileName) async {
    try {
      emit(HomeDocumentState(isLoading: true));

      // Download the file
      final filePath = await _downloadFile(url, fileName);

      if (filePath != null) {
        // Open the document
        await documentChannel.invokeMethod('open', {'path': filePath});
        emit(HomeDocumentState(isViewing: true, filePath: filePath));
      } else {
        emit(HomeDocumentState(error: 'Failed to download document. Please check the URL.'));
      }
    } catch (e) {
      emit(HomeError('Document error: $e'));
    }
  }

  Future<String?> _downloadFile(String url, String fileName) async {
    try {
      // Get temporary directory path from Android
      final tempDir = await documentChannel.invokeMethod<String>('getTempDir');
      if (tempDir == null) return null;

      final file = File('$tempDir/$fileName');

      // Download file
      final httpClient = HttpClient();
      final request = await httpClient.getUrl(Uri.parse(url));
      final response = await request.close();

      if (response.statusCode == 200) {
        await response.pipe(file.openWrite());
        return file.path;
      } else {
        print('Download failed with status: ${response.statusCode}');
        return null;
      }
    } catch (e) {
      print('Download error: $e');
      return null;
    }
  }

  Future<void> downloadDocument(String url, String fileName) async {
    try {
      emit(HomeDocumentState(isLoading: true));

      final filePath = await documentChannel.invokeMethod<String>(
        'download',
        {'url': url, 'fileName': fileName},
      );

      if (filePath != null) {
        emit(HomeDocumentState(
          isViewing: true,
          filePath: filePath,
        ));

        // Open the downloaded document
        await documentChannel.invokeMethod('open', {'path': filePath});
      }
    } catch (e) {
      emit(HomeError('Download error: $e'));
    }
  }

  Future<void> openDocument(String path) async {
    try {
      await documentChannel.invokeMethod('open', {'path': path});
    } catch (e) {
      emit(HomeError('Open error: $e'));
    }
  }
}