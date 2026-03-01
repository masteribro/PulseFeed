import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:pulse_feed/home/components/video_preview.dart';
import '../../application/home_cubit.dart';
import '../../application/home_state.dart';
import 'audio_preview.dart';
import 'document_preview.dart';
import 'feed_card.dart'; // for MediaType enum (or move enum to separate file)

class MediaPreview extends StatelessWidget {
  final MediaType type;
  final String? mediaUrl;
  final String? fileName;

  const MediaPreview({
    super.key,
    required this.type,
    this.mediaUrl,
    this.fileName,
  });

  @override
  Widget build(BuildContext context) {
    switch (type) {
      case MediaType.video:
        return VideoPreview(mediaUrl: mediaUrl);

      case MediaType.audio:
        return AudioPreview(mediaUrl: mediaUrl);

      case MediaType.document:
        return DocumentPreview(
          mediaUrl: mediaUrl,
          fileName: fileName,
        );

      case MediaType.text:
        return const SizedBox.shrink();
    }
  }
}