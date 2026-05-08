import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../application/home_cubit.dart';
import '../../application/home_state.dart';

class AudioPreview extends StatelessWidget {
  final String? mediaUrl;

  const AudioPreview({super.key, this.mediaUrl});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: BlocBuilder<HomeCubit, HomeState>(
        builder: (context, state) {
          final isPlaying = state is HomeAudioState && state.isPlaying;
          final isLoading = state is HomeAudioState && state.isLoading;

          return Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              if (isLoading)
                const SizedBox(
                  width: 40,
                  height: 40,
                  child: Padding(
                    padding: EdgeInsets.all(8),
                    child: CircularProgressIndicator(strokeWidth: 2.5),
                  ),
                ),
              if (!isLoading)
              IconButton(
                icon: Icon(
                  isPlaying ? Icons.pause : Icons.play_arrow,
                  size: 40,
                ),
                onPressed: () {
                  print('[AudioPreview] play/pause tapped | mediaUrl: $mediaUrl | isPlaying: $isPlaying');
                  if (mediaUrl == null) {
                    print('[AudioPreview] mediaUrl is null, aborting');
                    return;
                  }

                  if (isPlaying) {
                    context.read<HomeCubit>().pauseAudio();
                  } else {
                    context.read<HomeCubit>().playAudio(mediaUrl!);
                  }
                },
              ),
              IconButton(
                icon: const Icon(Icons.stop, size: 40),
                onPressed: () {
                  context.read<HomeCubit>().stopAudio();
                },
              ),
            ],
          );
        },
      ),
    );
  }
}