import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../application/home_cubit.dart';
import '../../application/home_state.dart';

enum MediaType { video, audio, document, text }

class FeedCard extends StatelessWidget {
  final MediaType type;
  final String title;
  final String? description;
  final String? mediaUrl;
  final String? fileName;

  const FeedCard({
    super.key,
    required this.type,
    required this.title,
    this.description,
    this.mediaUrl,
    this.fileName,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.all(8),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (type != MediaType.text)
            Container(
              height: 150,
              width: double.infinity,
              color: Colors.grey[300],
              child: _buildMediaPreview(context),
            ),

          Padding(
            padding: const EdgeInsets.all(12),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    CircleAvatar(
                      radius: 15,
                      backgroundColor: Colors.blue,
                      child: Text(
                        title[0].toUpperCase(),
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 12,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                    const SizedBox(width: 8),
                    Text(
                      title,
                      style: const TextStyle(
                        fontSize: 15,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 8),

                if (description != null)
                  Text(
                    description!,
                    style: const TextStyle(
                      fontSize: 16,
                      height: 1.4,
                    ),
                  ),

                if (type == MediaType.text && description == null)
                  const Text(
                    'No content',
                    style: TextStyle(
                      fontSize: 16,
                      color: Colors.grey,
                      fontStyle: FontStyle.italic,
                    ),
                  ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildMediaPreview(BuildContext context) {
    switch (type) {
      case MediaType.video:
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
                  if (mediaUrl != null) {
                    if (isPlaying) {
                      context.read<HomeCubit>().pauseVideo();
                    } else {
                      context.read<HomeCubit>().playVideo(mediaUrl!);
                    }
                  }
                },
              );
            },
          ),
        );

      case MediaType.audio:
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
                      if (mediaUrl != null) {
                        if (isPlaying) {
                          context.read<HomeCubit>().pauseAudio();
                        } else {
                          context.read<HomeCubit>().playAudio(mediaUrl!);
                        }
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

      case MediaType.document:
        return Center(
          child: BlocBuilder<HomeCubit, HomeState>(
            builder: (context, state) {
              final docState = state is HomeDocumentState ? state : null;

              if (docState?.isLoading == true) {
                return const Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    CircularProgressIndicator(),
                    SizedBox(height: 8),
                    Text('Loading document...'),
                  ],
                );
              }

              // Show view button
              return Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  IconButton(
                    icon: const Icon(Icons.picture_as_pdf, size: 40, color: Colors.red),
                    onPressed: () {
                      if (mediaUrl != null && fileName != null) {
                        context.read<HomeCubit>().viewDocument(mediaUrl!, fileName!);
                      }
                    },
                  ),
                  const Text('View PDF', style: TextStyle(fontSize: 12)),
                ],
              );
            },
          ),
        );

      case MediaType.text:
        return const SizedBox.shrink();
    }
  }
}