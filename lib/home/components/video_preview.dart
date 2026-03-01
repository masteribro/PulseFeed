import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../application/home_cubit.dart';
import '../../application/home_state.dart';

class VideoPreview extends StatelessWidget {
  final String? mediaUrl;

  const VideoPreview({super.key, this.mediaUrl});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: BlocBuilder<HomeCubit, HomeState>(
        builder: (context, state) {
          final isPlaying = state is HomeVideoState && state.isPlaying;

          return IconButton(
            icon: Icon(
              isPlaying ? Icons.pause_circle : Icons.play_circle,
              size: 50,
              color: Colors.white,
            ),
            onPressed: () {
              if (mediaUrl == null) return;

              if (isPlaying) {
                context.read<HomeCubit>().pauseVideo();
              } else {
                context.read<HomeCubit>().playVideo(mediaUrl!);
              }
            },
          );
        },
      ),
    );
  }
}