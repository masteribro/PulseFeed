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

          return Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              IconButton(
                icon: Icon(
                  isPlaying ? Icons.pause : Icons.play_arrow,
                  size: 40,
                ),
                onPressed: () {
                  if (mediaUrl == null) return;

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