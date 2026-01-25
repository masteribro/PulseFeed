
import 'package:equatable/equatable.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';


part 'home_state.dart';

class HomeCubit extends Cubit<HomeState> {

  HomeCubit()
      : super(HomeInitial());

  static const platform = MethodChannel("com.example.pulse_feed/simple_media");

  Future<void> togglePlayPause(bool isPlaying) async {
    try {
      if (isPlaying) {
        await platform.invokeMethod('pause');
        emit(HomeLoading(isPlaying: false));
      } else {
        await platform.invokeMethod('play', {
          'url': 'https://www.soundhelix.com/examples/mp3/SoundHelix-Song-1.mp3'
        });
        emit(HomeLoading(isPlaying: true));
      }
    } catch (e) {
      print('Error: $e');
    }
  }


}
