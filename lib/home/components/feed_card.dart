import 'package:flutter/material.dart';
import 'media_preview.dart';

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
              child: MediaPreview(
                type: type,
                mediaUrl: mediaUrl,
                fileName: fileName,
              ),
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

}