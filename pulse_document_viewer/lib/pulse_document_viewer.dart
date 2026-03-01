import 'dart:async';
import 'package:flutter/services.dart';

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

  /// Get the temporary directory path
  Future<String?> getTempDir() async {
    try {
      return await _channel.invokeMethod<String>('getTempDir');
    } catch (e) {
      print('Error getting temp dir: $e');
      return null;
    }
  }

  /// Download a document from URL
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

  /// Open a document from file path
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

  /// Convenience method: download and open a document
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

  /// Check if a file exists
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

  /// Delete a file
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

  /// Cancel current download
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

  /// Dispose the document viewer
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
