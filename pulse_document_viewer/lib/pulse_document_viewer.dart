import 'dart:async';
import 'dart:io';
import 'dart:typed_data';
import 'package:flutter/services.dart';
import 'package:path_provider/path_provider.dart';

class PulseDocumentViewer {
  static const MethodChannel _channel = MethodChannel('pulse_document_viewer');

  final StreamController<DocumentEvent> _eventController =
  StreamController.broadcast();
  Stream<DocumentEvent> get events => _eventController.stream;

  double _downloadProgress = 0.0;
  double get downloadProgress => _downloadProgress;

  bool _isDownloading = false;
  bool get isDownloading => _isDownloading;

  String? _lastFilePath;
  String? get lastFilePath => _lastFilePath;

  PulseDocumentViewer() {
    _channel.setMethodCallHandler(_handleMethodCall);
  }

  Future<void> _handleMethodCall(MethodCall call) async {
    switch (call.method) {
      case 'onProgress':
        _downloadProgress = (call.arguments as double?) ?? 0.0;
        _eventController.add(DocumentEvent.progress);
        break;
      case 'onComplete':
        _isDownloading = false;
        _lastFilePath = call.arguments as String?;
        _eventController.add(DocumentEvent.completed);
        break;
      case 'onError':
        _isDownloading = false;
        _eventController.add(DocumentEvent.error);
        break;
    }
  }

  Future<String?> getTempDir() async {
    try {
      return await _channel.invokeMethod<String>('getTempDir');
    } catch (e) {
      print('Error getting temp dir: $e');
      return null;
    }
  }

  Future<String?> loadDocumentFromAssets(String assetPath, String fileName) async {
    try {
      _isDownloading = true;
      _downloadProgress = 0.0;
      _eventController.add(DocumentEvent.started);

      final tempDir = await getTemporaryDirectory();
      final filePath = '${tempDir.path}/$fileName';

      final file = File(filePath);
      if (await file.exists()) {
        _isDownloading = false;
        _lastFilePath = filePath;
        _eventController.add(DocumentEvent.completed);
        return filePath;
      }

      final byteData = await rootBundle.load(assetPath);
      final buffer = byteData.buffer;
      await file.writeAsBytes(
          buffer.asUint8List(byteData.offsetInBytes, byteData.lengthInBytes)
      );

      _isDownloading = false;
      _downloadProgress = 1.0;
      _lastFilePath = filePath;
      _eventController.add(DocumentEvent.progress);
      _eventController.add(DocumentEvent.completed);

      return filePath;
    } catch (e) {
      _isDownloading = false;
      _eventController.add(DocumentEvent.error);
      print('Error loading document from assets: $e');
      return null;
    }
  }

  // NEW: Get PDF page count
  Future<int?> getPageCount(String filePath) async {
    try {
      return await _channel.invokeMethod<int>(
        'getPageCount',
        {'path': filePath},
      );
    } catch (e) {
      print('Error getting page count: $e');
      return null;
    }
  }

  // NEW: Render a specific page as image
  Future<Uint8List?> renderPage(String filePath, int pageIndex, {double width = 800, double height = 1200}) async {
    try {
      final pageData = await _channel.invokeMethod<Uint8List>(
        'renderPage',
        {
          'path': filePath,
          'pageIndex': pageIndex,
          'width': width.toInt(),
          'height': height.toInt(),
        },
      );
      return pageData;
    } catch (e) {
      print('Error rendering page: $e');
      return null;
    }
  }

  Future<void> closeDocument(String filePath) async {
    try {
      await _channel.invokeMethod('closeDocument', {'path': filePath});
    } catch (e) {
      print('Error closing document: $e');
    }
  }

  Future<String?> downloadDocument(String url, String fileName) async {
    try {
      _isDownloading = true;
      _downloadProgress = 0.0;
      _eventController.add(DocumentEvent.started);

      final filePath = await _channel.invokeMethod<String>(
        'downloadDocument',
        {'url': url, 'fileName': fileName},
      );

      _isDownloading = false;
      _lastFilePath = filePath;

      if (filePath != null) {
        _eventController.add(DocumentEvent.completed);
      } else {
        _eventController.add(DocumentEvent.error);
      }

      return filePath;
    } catch (e) {
      _isDownloading = false;
      _eventController.add(DocumentEvent.error);
      print('Error downloading document: $e');
      return null;
    }
  }

  Future<bool> openDocument(String path) async {
    try {
      final result = await _channel.invokeMethod<bool>(
        'openDocument',
        {'path': path},
      );
      return result ?? false;
    } catch (e) {
      print('Error opening document: $e');
      return false;
    }
  }

  Future<bool> viewDocumentFromAssets(String assetPath, String fileName) async {
    try {
      _eventController.add(DocumentEvent.started);
      final filePath = await loadDocumentFromAssets(assetPath, fileName);

      if (filePath != null) {
        final opened = await openDocument(filePath);
        if (opened) {
          _eventController.add(DocumentEvent.completed);
        }
        return opened;
      }
      return false;
    } catch (e) {
      _eventController.add(DocumentEvent.error);
      print('Error viewing document from assets: $e');
      return false;
    }
  }

  Future<bool> viewDocument(String url, String fileName) async {
    try {
      _eventController.add(DocumentEvent.started);
      final filePath = await downloadDocument(url, fileName);

      if (filePath != null) {
        final opened = await openDocument(filePath);
        if (opened) {
          _eventController.add(DocumentEvent.completed);
        }
        return opened;
      }
      return false;
    } catch (e) {
      _eventController.add(DocumentEvent.error);
      print('Error viewing document: $e');
      return false;
    }
  }

  Future<bool> fileExists(String path) async {
    try {
      return await _channel.invokeMethod<bool>(
        'fileExists',
        {'path': path},
      ) ?? false;
    } catch (e) {
      print('Error checking file: $e');
      return false;
    }
  }

  Future<bool> deleteFile(String path) async {
    try {
      return await _channel.invokeMethod<bool>(
        'deleteFile',
        {'path': path},
      ) ?? false;
    } catch (e) {
      print('Error deleting file: $e');
      return false;
    }
  }

  Future<void> cancelDownload() async {
    try {
      await _channel.invokeMethod('cancelDownload');
      _isDownloading = false;
      _downloadProgress = 0.0;
      _eventController.add(DocumentEvent.cancelled);
    } catch (e) {
      print('Error cancelling download: $e');
    }
  }

  Future<void> dispose() async {
    await _eventController.close();
  }
}

enum DocumentEvent {
  started,
  progress,
  completed,
  error,
  cancelled,
}