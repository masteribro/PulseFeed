import 'package:plugin_platform_interface/plugin_platform_interface.dart';

import 'pulse_document_viewer_method_channel.dart';

abstract class PulseDocumentViewerPlatform extends PlatformInterface {
  /// Constructs a PulseDocumentViewerPlatform.
  PulseDocumentViewerPlatform() : super(token: _token);

  static final Object _token = Object();

  static PulseDocumentViewerPlatform _instance = MethodChannelPulseDocumentViewer();

  /// The default instance of [PulseDocumentViewerPlatform] to use.
  ///
  /// Defaults to [MethodChannelPulseDocumentViewer].
  static PulseDocumentViewerPlatform get instance => _instance;

  /// Platform-specific implementations should set this with their own
  /// platform-specific class that extends [PulseDocumentViewerPlatform] when
  /// they register themselves.
  static set instance(PulseDocumentViewerPlatform instance) {
    PlatformInterface.verifyToken(instance, _token);
    _instance = instance;
  }

  Future<String?> getPlatformVersion() {
    throw UnimplementedError('platformVersion() has not been implemented.');
  }
}
