import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import '../application/home_cubit.dart';
import '../application/home_state.dart';
import '../data/media_storage.dart';
import 'components/feed_card.dart';

class HomePage extends StatefulWidget {
  const HomePage({super.key});

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  static const String _baseUrl = 'http://localhost:8080';

  String _resolveUrl(String url) {
    if (url.startsWith('/')) return '$_baseUrl$url';
    return url;
  }

  @override
  void initState() {
    super.initState();
    context.read<HomeCubit>().fetchFeed();
  }

  MediaType _toMediaType(String mediaType) {
    switch (mediaType.toLowerCase()) {
      case 'video':
        return MediaType.video;
      case 'audio':
        return MediaType.audio;
      case 'document':
        return MediaType.document;
      default:
        return MediaType.text;
    }
  }

  String _toTitle(MediaStorage item) {
    switch (item.mediaType.toLowerCase()) {
      case 'video':
        return 'VideoChannel';
      case 'audio':
        return 'PodcastDaily';
      case 'document':
        return 'My CV';
      default:
        return 'User${item.id}';
    }
  }

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
        child: BlocBuilder<HomeCubit, HomeState>(
          buildWhen: (previous, current) =>
              current is HomeFeedLoading ||
              current is HomeFeedLoaded,
          builder: (context, state) {
            if (state is HomeFeedLoading) {
              return const Center(child: CircularProgressIndicator());
            }
            if (state is HomeFeedLoaded) {
              final items = state.items;
              return Padding(
                padding: EdgeInsets.only(top: 5.h),
                child: ListView.builder(
                  itemCount: items.length,
                  itemBuilder: (context, index) {
                    final item = items[index];
                    final type = _toMediaType(item.mediaType);
                    return FeedCard(
                      type: type,
                      title: _toTitle(item),
                      description: item.text.isEmpty ? null : item.text,
                      mediaUrl: item.url.isEmpty ? null : _resolveUrl(item.url),
                      fileName: type == MediaType.document
                          ? 'Mohammed_Ibrahim_CV.pdf'
                          : null,
                    );
                  },
                ),
              );
            }
            return const SizedBox.shrink();
          },
        ),
      ),
    );
  }
}
