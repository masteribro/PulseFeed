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
      emit(HomeVideoState(false));
    } catch (e) {
      emit(HomeError('Video error: $e'));
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

  Future<void> downloadDocument(String url, String fileName) async {
    try {
      emit(HomeDocumentState(isLoading: true));

      final filePath = await documentViewer.downloadDocument(url, fileName);

      if (filePath != null) {
        emit(HomeDocumentState(
          isViewing: false,
          filePath: filePath,
        ));
      } else {
        emit(HomeDocumentState(error: 'Failed to download document'));
      }
    } catch (e) {
      emit(HomeError('Download error: $e'));
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

  @override
  Future<void> close() {
    _audioPlayer?.dispose();
    _videoPlayer?.dispose();
    _documentViewer?.dispose();
    return super.close();
  }
}