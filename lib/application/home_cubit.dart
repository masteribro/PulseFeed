import 'dart:convert';
import 'dart:developer' as dev;
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:http/http.dart' as http;
import 'package:pulse_audio_player/pulse_audio_player.dart';
import 'package:pulse_document_viewer/pulse_document_viewer.dart';
import 'package:pulse_video_player/pulse_video_player.dart';
import '../data/media_storage.dart';
import 'home_state.dart';

class HomeCubit extends Cubit<HomeState> {
  HomeCubit() : super(HomeInitial());

  PulseAudioPlayer? _audioPlayer;
  PulseVideoPlayer? _videoPlayer;
  PulseDocumentViewer? _documentViewer;
  String? _currentVideoUrl;

  // Getters with lazy initialization
  PulseAudioPlayer get audioPlayer {
    _audioPlayer ??= PulseAudioPlayer();
    return _audioPlayer!;
  }

  PulseVideoPlayer get videoPlayer {
    _videoPlayer ??= PulseVideoPlayer();
    return _videoPlayer!;
  }

  PulseDocumentViewer get documentViewer {
    _documentViewer ??= PulseDocumentViewer();
    return _documentViewer!;
  }

  Future<void> fetchFeed() async {
    emit(HomeFeedLoading());
    try {
      final response = await http.get(
        Uri.parse('http://localhost:8080/api/v1/media-data'),
      );
      if (response.statusCode == 200) {
        final List<dynamic> data = jsonDecode(response.body);
        final pretty = const JsonEncoder.withIndent('  ').convert(data);
        dev.log('\n$pretty', name: 'GET /api/v1/media-data');
        final items = data.map((e) => MediaStorage.fromJson(e as Map<String, dynamic>)).toList();
        emit(HomeFeedLoaded(items));
      } else {
        dev.log('Status: ${response.statusCode}\n${response.body}', name: 'GET /api/v1/media-data ERROR');
        emit(HomeError('Failed to load feed: ${response.statusCode}'));
      }
    } catch (e) {
      emit(HomeError('Failed to load feed: $e'));
    }
  }

  Future<void> playAudio(String url) async {
    print('[HomeCubit] playAudio called with url: $url');
    try {
      emit(HomeAudioState(false, isLoading: true));
      final result = await audioPlayer.play(url);
      print('[HomeCubit] audioPlayer.play returned: $result');
      emit(HomeAudioState(true));
      print('[HomeCubit] emitted HomeAudioState(true)');
    } catch (e, st) {
      print('[HomeCubit] playAudio error: $e\n$st');
      emit(HomeError('Audio error: $e'));
    }
  }

  Future<void> pauseAudio() async {
    print('[HomeCubit] pauseAudio called');
    try {
      final result = await audioPlayer.pause();
      print('[HomeCubit] audioPlayer.pause returned: $result');
      emit(HomeAudioState(false));
    } catch (e, st) {
      print('[HomeCubit] pauseAudio error: $e\n$st');
      emit(HomeError('Audio error: $e'));
    }
  }

  Future<void> stopAudio() async {
    print('[HomeCubit] stopAudio called');
    try {
      final result = await audioPlayer.stop();
      print('[HomeCubit] audioPlayer.stop returned: $result');
      emit(HomeAudioState(false));
    } catch (e, st) {
      print('[HomeCubit] stopAudio error: $e\n$st');
      emit(HomeError('Audio error: $e'));
    }
  }



  Future<void> playVideo(String url) async {
    try {
      _currentVideoUrl = url;
      await videoPlayer.play(url);
      emit(HomeVideoState(true));
    } catch (e) {
      emit(HomeError('Video error: $e'));
    }
  }

  Future<void> pauseVideo() async {
    try {
      await videoPlayer.pause();
      emit(HomeVideoState(false));
    } catch (e) {
      emit(HomeError('Video error: $e'));
    }
  }

  Future<void> stopVideo() async {
    try {
      await videoPlayer.stop();
      _currentVideoUrl = null;
      emit(HomeVideoState(false));
    } catch (e) {
      emit(HomeError('Video error: $e'));
    }
  }

  Future<void> viewDocumentFromAssets(String assetPath, String fileName) async {
    try {
      emit(HomeDocumentState(isLoading: true));

      final filePath = await documentViewer.loadDocumentFromAssets(assetPath, fileName);

      if (filePath != null) {
        final opened = await documentViewer.openDocument(filePath);

        if (opened) {
          emit(HomeDocumentState(isViewing: true, filePath: filePath));
        } else {
          emit(HomeDocumentState(error: 'Failed to open document'));
        }
      } else {
        emit(HomeDocumentState(error: 'Failed to load document from assets.'));
      }
    } catch (e) {
      emit(HomeError('Document error: $e'));
    }
  }

  Future<void> viewDocument(String url, String fileName) async {
    try {
      emit(HomeDocumentState(isLoading: true));

      final filePath = await documentViewer.downloadDocument(url, fileName);

      if (filePath != null) {
        final opened = await documentViewer.openDocument(filePath);

        if (opened) {
          emit(HomeDocumentState(isViewing: true, filePath: filePath));
        } else {
          emit(HomeDocumentState(error: 'Failed to open document'));
        }
      } else {
        emit(HomeDocumentState(error: 'Failed to download document. Please check the URL.'));
      }
    } catch (e) {
      emit(HomeError('Document error: $e'));
    }
  }

  Future<String?> downloadDocumentFromUrl(String url, String fileName) async {
    try {
      emit(HomeDocumentState(isLoading: true));
      final filePath = await documentViewer.downloadDocument(url, fileName);
      emit(HomeDocumentState(isLoading: false));
      return filePath;
    } catch (e) {
      emit(HomeError('Document error: $e'));
      return null;
    }
  }

  Future<void> loadDocumentFromAssets(String assetPath, String fileName) async {
    try {
      emit(HomeDocumentState(isLoading: true));

      final filePath = await documentViewer.loadDocumentFromAssets(assetPath, fileName);

      if (filePath != null) {
        emit(HomeDocumentState(
          isViewing: false,
          filePath: filePath,
        ));
      } else {
        emit(HomeDocumentState(error: 'Failed to load document from assets'));
      }
    } catch (e) {
      emit(HomeError('Load error: $e'));
    }
  }

  Future<void> openDocument(String path) async {
    try {
      final opened = await documentViewer.openDocument(path);
      if (opened) {
        emit(HomeDocumentState(isViewing: true, filePath: path));
      } else {
        emit(HomeError('Failed to open document'));
      }
    } catch (e) {
      emit(HomeError('Open error: $e'));
    }
  }

  // Video control methods...
  Future<void> seekVideo(Duration position) async {
    try {
      await videoPlayer.seekTo(position);
    } catch (e) {
      emit(HomeError('Video seek error: $e'));
    }
  }

  Future<void> setVideoVolume(double volume) async {
    try {
      await videoPlayer.setVolume(volume);
    } catch (e) {
      emit(HomeError('Video volume error: $e'));
    }
  }

  Future<void> setVideoSpeed(double speed) async {
    try {
      await videoPlayer.setPlaybackSpeed(speed);
    } catch (e) {
      emit(HomeError('Video speed error: $e'));
    }
  }

  @override
  Future<void> close() {
    _audioPlayer?.dispose();
    _videoPlayer?.dispose();
    _documentViewer?.dispose();
    return super.close();
  }
}