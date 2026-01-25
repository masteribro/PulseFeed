import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import 'components/feed_card.dart';

class HomePage extends StatefulWidget {
  const HomePage({super.key, required this.title});


  final String title;

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  static const platform = MethodChannel("com.example.pulse_feed/simple_media");
  bool isPlaying = false;

  Future<void> togglePlayPause() async {
    try {
      if (isPlaying) {
        await platform.invokeMethod('pause');
        setState(() => isPlaying = false);
      } else {
        await platform.invokeMethod('play', {
          'url': 'https://www.soundhelix.com/examples/mp3/SoundHelix-Song-1.mp3'
        });
        setState(() => isPlaying = true);
      }
    } catch (e) {
      print('Error: $e');
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          FeedCard(),
          IconButton(
            onPressed: togglePlayPause,
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
      ),

    );
  }
}