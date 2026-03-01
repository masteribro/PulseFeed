import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';

import 'pulse_document_viewer_platform_interface.dart';

/// An implementation of [PulseDocumentViewerPlatform] that uses method channels.
class MethodChannelPulseDocumentViewer extends PulseDocumentViewerPlatform {
  /// The method channel used to interact with the native platform.
  @visibleForTesting
  final methodChannel = const MethodChannel('pulse_document_viewer');

  @override
  Future<String?> getPlatformVersion() async {
    final version = await methodChannel.invokeMethod<String>('getPlatformVersion');
    return version;
  }
}
