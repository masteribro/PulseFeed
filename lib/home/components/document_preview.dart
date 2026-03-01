import 'dart:ui';

import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../application/home_cubit.dart';
import '../../application/home_state.dart';

class DocumentPreview extends StatelessWidget {
  final String? mediaUrl;
  final String? fileName;

  const DocumentPreview({super.key,
    this.mediaUrl,
    this.fileName,
  });

  @override
  Widget build(BuildContext context) {
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

          return Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              IconButton(
                icon: const Icon(
                  Icons.picture_as_pdf,
                  size: 40,
                  color: Colors.red,
                ),
                onPressed: () {
                  if (mediaUrl != null && fileName != null) {
                    context
                        .read<HomeCubit>()
                        .viewDocument(mediaUrl!, fileName!);
                  }
                },
              ),
              const Text(
                'View PDF',
                style: TextStyle(fontSize: 12),
              ),
            ],
          );
        },
      ),
    );
  }
}