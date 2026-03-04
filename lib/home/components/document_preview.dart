import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../application/home_cubit.dart';
import '../../application/home_state.dart';
import 'flip_doc_viewer.dart';

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
                onPressed: () async {
                  const assetPath = 'assets/docs/Mohammed_Ibrahim_CV.pdf';

                  // Load document and get file path
                  final filePath = await context
                      .read<HomeCubit>()
                      .documentViewer
                      .loadDocumentFromAssets(assetPath, fileName ?? 'document.pdf');

                  if (filePath != null && context.mounted) {
                    // Navigate to custom document viewer
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => FlipDocViewer(
                          filePath: filePath,
                          fileName: fileName ?? 'Document',
                        ),
                      ),
                    );
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