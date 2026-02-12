import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../application/home_cubit.dart';
import 'components/feed_card.dart';

class HomePage extends StatefulWidget {
  const HomePage({super.key});

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: BlocBuilder<HomeCubit, HomeState>(
          builder: (context, state) {
            final bool isPlaying =
            state is HomeLoading ? state.isPlaying : false;
            return Column(
              mainAxisAlignment: MainAxisAlignment.center,
        children: [
          FeedCard(),
          IconButton(
            onPressed: () {
              context
                  .read<HomeCubit>()
                  .togglePlayPause(isPlaying);
            },
            icon: Icon(
              isPlaying ? Icons.pause_circle_filled : Icons.play_circle_filled,
              size: 100,
              color: isPlaying ? Colors.red : Colors.green,
            ),
          ),

          const SizedBox(height: 20),

          // Status Text
          Text(
            isPlaying ? 'Playing...' : 'Tap to play',
            style: const TextStyle(fontSize: 20),
          ),
        ],
      );})

    );
  }
}