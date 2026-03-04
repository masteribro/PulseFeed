import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import '../application/home_cubit.dart';
import '../application/home_state.dart';
import 'components/feed_card.dart';

class HomePage extends StatelessWidget {
  HomePage({super.key});

  final List<Map<String, dynamic>> items = [
    {
      'type': MediaType.video,
      'title': 'VideoChannel',
      'description': 'Watch this cute cat doing tricks 🐱 #Cats #Funny',
      'mediaUrl': 'http://commondatastorage.googleapis.com/gtv-videos-bucket/sample/BigBuckBunny.mp4',
    },
    {
      'type': MediaType.audio,
      'title': 'PodcastDaily',
      'description': 'Start your day with this amazing podcast ☀️ #MorningMotivation',
      'mediaUrl': 'https://www.soundhelix.com/examples/mp3/SoundHelix-Song-1.mp3',
    },
    {
      'type': MediaType.document,
      'title': 'TechDocs',
      'description': 'Important notes from today\'s meeting 📄 #Work',
      'mediaUrl': 'https://www.w3.org/WAI/ER/tests/xhtml/testfiles/resources/pdf/dummy.pdf',
      'fileName': 'meeting_notes.pdf',
    },
    {
      'type': MediaType.text,
      'title': 'DailyThoughts',
      'description': 'Just finished building this awesome app! 🚀\n\nFeeling proud of what we\'ve accomplished. The journey of learning Flutter has been amazing.\n\n#FlutterDev #MobileApps #CodingLife',
    },
    {
      'type': MediaType.text,
      'title': 'WeatherUpdate',
      'description': 'Beautiful sunny day here in California! ☀️ 75°F and perfect for coding.',
    },
    {
      'type': MediaType.text,
      'title': 'TechNews',
      'description': 'Breaking: New Flutter version just dropped! Check out the amazing new features 🔥',
    },
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Pulse Feed'),
        centerTitle: false,
        backgroundColor: Colors.white,
        foregroundColor: Colors.black,
        elevation: 0,
      ),
      body: BlocListener<HomeCubit, HomeState>(
        listener: (context, state) {
          if (state is HomeError) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(content: Text(state.message)),
            );
          }
        },
        child: Padding(
          padding:  EdgeInsets.only(top: 5.h),
          child: ListView.builder(
            itemCount: items.length,
            itemBuilder: (context, index) {
              final item = items[index];
              return FeedCard(
                type: item['type'],
                title: item['title'],
                description: item['description'],
                mediaUrl: item['mediaUrl'],
                fileName: item['fileName'],
              );
            },
          ),
        ),
      ),
    );
  }
}