import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:pulse_audio_player/pulse_audio_player.dart';
import 'package:pulse_document_viewer/pulse_document_viewer.dart';
import 'package:pulse_video_player/pulse_video_player.dart';
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
      await audioPlayer.pause();
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