import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../application/home_cubit.dart';

class VideoController extends StatelessWidget {
  final Duration duration;
  final Duration position;

  const VideoController({
    super.key,
    required this.duration,
    required this.position,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      color: Colors.black.withOpacity(0.5),
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Row(
            children: [
              Text(
                _formatDuration(position),
                style: const TextStyle(color: Colors.white, fontSize: 10),
              ),
              Expanded(
                child: Slider(
                  value: position.inMilliseconds.toDouble(),
                  min: 0,
                  max: duration.inMilliseconds.toDouble(),
                  activeColor: Colors.blue,
                  inactiveColor: Colors.grey,
                  onChanged: (value) {
                    final newPosition = Duration(milliseconds: value.toInt());
                    context.read<HomeCubit>().seekVideo(newPosition);
                  },
                ),
              ),
              Text(
                _formatDuration(duration),
                style: const TextStyle(color: Colors.white, fontSize: 10),
              ),
            ],
          ),

          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              IconButton(
                icon: Icon(
                  context.read<HomeCubit>().videoPlayer.isPlaying
                      ? Icons.pause
                      : Icons.play_arrow,
                  color: Colors.white,
                  size: 30,
                ),
                onPressed: () {
                  if (context.read<HomeCubit>().videoPlayer.isPlaying) {
                    context.read<HomeCubit>().pauseVideo();
                  }
                },
              ),
              IconButton(
                icon: const Icon(Icons.stop, color: Colors.white, size: 30),
                onPressed: () {
                  context.read<HomeCubit>().stopVideo();
                },
              ),
              IconButton(
                icon: const Icon(Icons.volume_up, color: Colors.white, size: 30),
                onPressed: () {
                  _showVolumeControl(context);
                },
              ),
              IconButton(
                icon: const Icon(Icons.speed, color: Colors.white, size: 30),
                onPressed: () {
                  _showSpeedControl(context);
                },
              ),
            ],
          ),
        ],
      ),
    );
  }

  String _formatDuration(Duration duration) {
    String twoDigits(int n) => n.toString().padLeft(2, '0');
    final minutes = duration.inMinutes.remainder(60);
    final seconds = duration.inSeconds.remainder(60);
    return '${twoDigits(minutes)}:${twoDigits(seconds)}';
  }

  void _showVolumeControl(BuildContext context) {
    double volume = context.read<HomeCubit>().videoPlayer.isPlaying ? 1.0 : 1.0;

    showModalBottomSheet(
      context: context,
      builder: (context) => Container(
        padding: const EdgeInsets.all(16),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Text('Volume', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
            const SizedBox(height: 16),
            StatefulBuilder(
              builder: (context, setState) {
                return Column(
                  children: [
                    Slider(
                      value: volume,
                      min: 0,
                      max: 1,
                      divisions: 10,
                      onChanged: (value) {
                        setState(() => volume = value);
                      },
                      onChangeEnd: (value) {
                        context.read<HomeCubit>().setVideoVolume(value);
                      },
                    ),
                    Text('${(volume * 100).toInt()}%'),
                  ],
                );
              },
            ),
          ],
        ),
      ),
    );
  }

  void _showSpeedControl(BuildContext context) {
    final speeds = [0.25, 0.5, 0.75, 1.0, 1.25, 1.5, 1.75, 2.0];

    showModalBottomSheet(
      context: context,
      builder: (context) => Container(
        padding: const EdgeInsets.all(16),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Text('Playback Speed', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
            const SizedBox(height: 16),
            ...speeds.map((speed) {
              return ListTile(
                title: Text('${speed}x'),
                onTap: () {
                  context.read<HomeCubit>().setVideoSpeed(speed);
                  Navigator.pop(context);
                },
              );
            }).toList(),
          ],
        ),
      ),
    );
  }
}