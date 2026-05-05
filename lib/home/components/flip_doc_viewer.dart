import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../application/home_cubit.dart';

class FlipDocViewer extends StatefulWidget {
  final String filePath;
  final String fileName;

  const FlipDocViewer({
    super.key,
    required this.filePath,
    required this.fileName,
  });

  @override
  State<FlipDocViewer> createState() => _FlipDocViewerState();
}

class _FlipDocViewerState extends State<FlipDocViewer> {
  final PageController _pageController = PageController();
  int _currentPage = 0;
  int? _totalPages;
  bool _isLoading = true;
  Map<int, Uint8List?> _pageCache = {};
  bool _isControlsVisible = true;

  late final HomeCubit _homeCubit;

  @override
  void initState() {
    super.initState();
    _homeCubit = context.read<HomeCubit>();
    _loadDocumentInfo();
  }

  @override
  void dispose() {
    _homeCubit.documentViewer.closeDocument(widget.filePath);
    _pageController.dispose();
    super.dispose();
  }

  Future<void> _loadDocumentInfo() async {
    final totalPages = await _homeCubit.documentViewer.getPageCount(widget.filePath);

    if (mounted) {
      setState(() {
        _totalPages = totalPages ?? 1;
        _isLoading = false;
      });
    }

    await _loadPage(0);
  }

  Future<void> _loadPage(int pageIndex) async {
    if (_pageCache.containsKey(pageIndex)) return;

    final size = MediaQuery.of(context).size;
    final pageData = await _homeCubit.documentViewer.renderPage(
      widget.filePath,
      pageIndex,
      width: size.width.toDouble(),
      height: size.height.toDouble(),
    );

    if (mounted) {
      setState(() {
        _pageCache[pageIndex] = pageData;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: _isControlsVisible
          ? AppBar(
        title: Text(widget.fileName),
        backgroundColor: Colors.black87,
        foregroundColor: Colors.white,
        actions: [
          Center(
            child: Padding(
              padding: const EdgeInsets.all(8.0),
              child: Text(
                '${_currentPage + 1} / ${_totalPages ?? 1}',
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 16,
                ),
              ),
            ),
          ),
          IconButton(
            icon: const Icon(Icons.close),
            onPressed: () => Navigator.pop(context),
          ),
        ],
      )
          : null,
      body: GestureDetector(
        onTap: () {
          setState(() {
            _isControlsVisible = !_isControlsVisible;
          });
        },
        child: Stack(
          children: [
            if (_isLoading)
              const Center(
                child: CircularProgressIndicator(color: Colors.white),
              )
            else
              PageView.builder(
                controller: _pageController,
                onPageChanged: (index) async {
                  setState(() => _currentPage = index);
                  await _loadPage(index);

                  // Preload next and previous pages
                  if (index > 0) await _loadPage(index - 1);
                  if (index < (_totalPages ?? 1) - 1) await _loadPage(index + 1);
                },
                itemCount: _totalPages,
                itemBuilder: (context, index) {
                  final pageData = _pageCache[index];

                  if (pageData == null) {
                    return const Center(
                      child: CircularProgressIndicator(color: Colors.white),
                    );
                  }

                  return Center(
                    child: InteractiveViewer(
                      minScale: 0.5,
                      maxScale: 3.0,
                      child: Image.memory(
                        pageData,
                        fit: BoxFit.contain,
                      ),
                    ),
                  );
                },
              ),

            if (_isControlsVisible && !_isLoading) ...[
              if (_currentPage > 0)
                Positioned(
                  left: 10,
                  top: 0,
                  bottom: 0,
                  child: Center(
                    child: Container(
                      decoration: BoxDecoration(
                        color: Colors.black54,
                        borderRadius: BorderRadius.circular(30),
                      ),
                      child: IconButton(
                        icon: const Icon(Icons.chevron_left, color: Colors.white, size: 40),
                        onPressed: () {
                          _pageController.previousPage(
                            duration: const Duration(milliseconds: 300),
                            curve: Curves.easeInOut,
                          );
                        },
                      ),
                    ),
                  ),
                ),

              if (_currentPage < (_totalPages ?? 1) - 1)
                Positioned(
                  right: 10,
                  top: 0,
                  bottom: 0,
                  child: Center(
                    child: Container(
                      decoration: BoxDecoration(
                        color: Colors.black54,
                        borderRadius: BorderRadius.circular(30),
                      ),
                      child: IconButton(
                        icon: const Icon(Icons.chevron_right, color: Colors.white, size: 40),
                        onPressed: () {
                          _pageController.nextPage(
                            duration: const Duration(milliseconds: 300),
                            curve: Curves.easeInOut,
                          );
                        },
                      ),
                    ),
                  ),
                ),
            ],

            if (!_isControlsVisible && !_isLoading)
              Positioned(
                bottom: 20,
                left: 0,
                right: 0,
                child: Center(
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                    decoration: BoxDecoration(
                      color: Colors.black54,
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Text(
                      '${_currentPage + 1} / ${_totalPages ?? 1}',
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 14,
                      ),
                    ),
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }
}