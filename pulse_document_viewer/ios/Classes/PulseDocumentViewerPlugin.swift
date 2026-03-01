import Flutter
import UIKit
import QuickLook

public class PulseDocumentViewerPlugin: NSObject, FlutterPlugin, QLPreviewControllerDataSource, QLPreviewControllerDelegate {
    private var channel: FlutterMethodChannel?
    private var documentUrl: URL?
    private var downloadTask: URLSessionDownloadTask?
    private var downloadProgress: Float = 0.0

    public static func register(with registrar: FlutterPluginRegistrar) {
        let channel = FlutterMethodChannel(name: "pulse_document_viewer", binaryMessenger: registrar.messenger())
        let instance = PulseDocumentViewerPlugin()
        instance.channel = channel
        registrar.addMethodCallDelegate(instance, channel: channel)
    }

    public func handle(_ call: FlutterMethodCall, result: @escaping FlutterResult) {
        switch call.method {
        case "getTempDir":
            let tempDir = FileManager.default.temporaryDirectory.path
            result(tempDir)

        case "downloadDocument":
            if let args = call.arguments as? [String: Any],
               let urlString = args["url"] as? String,
               let fileName = args["fileName"] as? String {
                downloadDocument(urlString: urlString, fileName: fileName, result: result)
            } else {
                result(FlutterError(code: "INVALID_ARGUMENTS", message: "URL and fileName are required", details: nil))
            }

        case "openDocument":
            if let args = call.arguments as? [String: Any],
               let path = args["path"] as? String {
                openDocument(path: path, result: result)
            } else {
                result(FlutterError(code: "INVALID_ARGUMENTS", message: "Path is required", details: nil))
            }

        case "fileExists":
            if let args = call.arguments as? [String: Any],
               let path = args["path"] as? String {
                let fileExists = FileManager.default.fileExists(atPath: path)
                result(fileExists)
            } else {
                result(FlutterError(code: "INVALID_ARGUMENTS", message: "Path is required", details: nil))
            }

        case "deleteFile":
            if let args = call.arguments as? [String: Any],
               let path = args["path"] as? String {
                do {
                    try FileManager.default.removeItem(atPath: path)
                    result(true)
                } catch {
                    result(false)
                }
            } else {
                result(FlutterError(code: "INVALID_ARGUMENTS", message: "Path is required", details: nil))
            }

        case "cancelDownload":
            downloadTask?.cancel()
            downloadTask = nil
            result(true)

        default:
            result(FlutterMethodNotImplemented)
        }
    }

    private func getRootViewController() -> UIViewController? {
        if #available(iOS 13.0, *) {
            return getRootViewControllerIOS13()
        } else {
            // iOS 12 and below
            return UIApplication.shared.keyWindow?.rootViewController
        }
    }

    @available(iOS 13.0, *)
    private func getRootViewControllerIOS13() -> UIViewController? {
        guard let windowScene = UIApplication.shared.connectedScenes.first as? UIWindowScene,
              let window = windowScene.windows.first else {
            return nil
        }
        return window.rootViewController
    }

    private func downloadDocument(urlString: String, fileName: String, result: @escaping FlutterResult) {
        guard let url = URL(string: urlString) else {
            result(FlutterError(code: "INVALID_URL", message: "Invalid URL", details: nil))
            return
        }

        let session = URLSession.shared
        downloadTask = session.downloadTask(with: url) { [weak self] localURL, response, error in
            guard let self = self else { return }

            if let error = error {
                DispatchQueue.main.async {
                    self.channel?.invokeMethod("onError", arguments: nil)
                    result(FlutterError(code: "DOWNLOAD_ERROR", message: error.localizedDescription, details: nil))
                }
                return
            }

            guard let localURL = localURL else {
                DispatchQueue.main.async {
                    self.channel?.invokeMethod("onError", arguments: nil)
                    result(FlutterError(code: "NO_FILE", message: "No file downloaded", details: nil))
                }
                return
            }

            // Move file to documents directory
            let documentsURL = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask).first!
            let destinationURL = documentsURL.appendingPathComponent(fileName)

            do {
                if FileManager.default.fileExists(atPath: destinationURL.path) {
                    try FileManager.default.removeItem(at: destinationURL)
                }
                try FileManager.default.moveItem(at: localURL, to: destinationURL)

                DispatchQueue.main.async {
                    self.channel?.invokeMethod("onComplete", arguments: destinationURL.path)
                    result(destinationURL.path)
                }
            } catch {
                DispatchQueue.main.async {
                    self.channel?.invokeMethod("onError", arguments: nil)
                    result(FlutterError(code: "FILE_ERROR", message: error.localizedDescription, details: nil))
                }
            }
        }

        // Add progress observer
        let progressObserver = downloadTask?.progress.observe(\.fractionCompleted) { [weak self] progress, _ in
            self?.downloadProgress = Float(progress.fractionCompleted)
            DispatchQueue.main.async {
                self?.channel?.invokeMethod("onProgress", arguments: Float(progress.fractionCompleted))
            }
        }

        downloadTask?.resume()

        // Store observer to keep it alive
        objc_setAssociatedObject(downloadTask!, "progressObserver", progressObserver, .OBJC_ASSOCIATION_RETAIN)
    }

    private func openDocument(path: String, result: @escaping FlutterResult) {
        let fileURL = URL(fileURLWithPath: path)

        guard FileManager.default.fileExists(atPath: path) else {
            result(FlutterError(code: "FILE_NOT_FOUND", message: "File does not exist", details: nil))
            return
        }

        documentUrl = fileURL

        DispatchQueue.main.async { [weak self] in
            guard let self = self else { return }

            // Get the root view controller using our safe method
            guard let rootViewController = self.getRootViewController() else {
                result(FlutterError(code: "NO_VIEW_CONTROLLER", message: "Could not find root view controller", details: nil))
                return
            }

            let previewController = QLPreviewController()
            previewController.dataSource = self
            previewController.delegate = self

            rootViewController.present(previewController, animated: true) {
                result(true)
            }
        }
    }


    public func numberOfPreviewItems(in controller: QLPreviewController) -> Int {
        return documentUrl != nil ? 1 : 0
    }

    public func previewController(_ controller: QLPreviewController, previewItemAt index: Int) -> QLPreviewItem {
        return documentUrl! as QLPreviewItem
    }


    public func previewControllerDidDismiss(_ controller: QLPreviewController) {
        documentUrl = nil
    }
}