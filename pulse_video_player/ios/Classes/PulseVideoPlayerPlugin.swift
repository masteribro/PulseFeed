import Flutter
import UIKit
import AVKit
import AVFoundation

public class PulseVideoPlayerPlugin: NSObject, FlutterPlugin {
    private var player: AVPlayer?
    private var playerViewController: AVPlayerViewController?
    private var channel: FlutterMethodChannel?
    private var positionTimer: Timer?
    private var isPlaying = false

    public static func register(with registrar: FlutterPluginRegistrar) {
        let channel = FlutterMethodChannel(name: "pulse_video_player", binaryMessenger: registrar.messenger())
        let instance = PulseVideoPlayerPlugin()
        instance.channel = channel
        registrar.addMethodCallDelegate(instance, channel: channel)
    }

    public func handle(_ call: FlutterMethodCall, result: @escaping FlutterResult) {
        switch call.method {
        case "play":
            if let args = call.arguments as? [String: Any],
               let urlString = args["url"] as? String {
                playVideo(urlString: urlString, result: result)
            } else {
                result(FlutterError(code: "INVALID_ARGUMENTS", message: "URL is required", details: nil))
            }

        case "pause":
            player?.pause()
            isPlaying = false
            result(true)

        case "stop":
            player?.pause()
            player?.seek(to: .zero)
            isPlaying = false
            stopPositionUpdates()
            playerViewController?.dismiss(animated: true)
            result(true)

        case "seekTo":
            if let args = call.arguments as? [String: Any],
               let position = args["position"] as? Int {
                let time = CMTime(seconds: Double(position) / 1000.0, preferredTimescale: 1000)
                player?.seek(to: time)
                result(true)
            } else {
                result(FlutterError(code: "INVALID_ARGUMENTS", message: "Position is required", details: nil))
            }

        case "setVolume":
            if let args = call.arguments as? [String: Any],
               let volume = args["volume"] as? Double {
                player?.volume = Float(volume)
                result(true)
            } else {
                result(FlutterError(code: "INVALID_ARGUMENTS", message: "Volume is required", details: nil))
            }

        case "setPlaybackSpeed":
            if let args = call.arguments as? [String: Any],
               let speed = args["speed"] as? Double {
                player?.rate = Float(speed)
                result(true)
            } else {
                result(FlutterError(code: "INVALID_ARGUMENTS", message: "Speed is required", details: nil))
            }

        case "setLooping":
            result(true)

        case "dispose":
            dispose()
            result(true)

        default:
            result(FlutterMethodNotImplemented)
        }
    }

    private func getRootViewController() -> UIViewController? {
        if #available(iOS 13.0, *) {
            // iOS 13+ - Use a separate method to avoid compiler issues
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

    private func playVideo(urlString: String, result: @escaping FlutterResult) {
        guard let url = URL(string: urlString) else {
            result(FlutterError(code: "INVALID_URL", message: "Invalid URL", details: nil))
            return
        }

        // Configure audio session
        do {
            try AVAudioSession.sharedInstance().setCategory(.playback, mode: .moviePlayback)
            try AVAudioSession.sharedInstance().setActive(true)
        } catch {
            print("Failed to set audio session category: \(error)")
        }

        // Get root view controller using our safe method
        guard let viewController = getRootViewController() else {
            result(FlutterError(code: "NO_VIEW_CONTROLLER", message: "Could not find root view controller", details: nil))
            return
        }

        // Create and configure player
        player = AVPlayer(url: url)
        playerViewController = AVPlayerViewController()
        playerViewController?.player = player
        playerViewController?.showsPlaybackControls = true

        // Present the video player
        viewController.present(playerViewController!, animated: true) { [weak self] in
            self?.player?.play()
            self?.isPlaying = true
            self?.sendDuration()
            self?.startPositionUpdates()
            result(true)
        }
    }

    private func sendDuration() {
        guard let duration = player?.currentItem?.duration.seconds, !duration.isNaN else { return }
        channel?.invokeMethod("onDuration", arguments: Int(duration * 1000))
    }

    private func startPositionUpdates() {
        positionTimer?.invalidate()
        positionTimer = Timer.scheduledTimer(withTimeInterval: 0.5, repeats: true) { [weak self] _ in
            guard let self = self,
                  let currentTime = self.player?.currentTime().seconds,
                  !currentTime.isNaN else { return }
            self.channel?.invokeMethod("onPosition", arguments: Int(currentTime * 1000))

            // Check if video ended
            if let duration = self.player?.currentItem?.duration.seconds,
               !duration.isNaN,
               currentTime >= duration - 0.1 {
                self.channel?.invokeMethod("onCompletion", arguments: nil)
                self.stopPositionUpdates()
            }
        }
    }

    private func stopPositionUpdates() {
        positionTimer?.invalidate()
        positionTimer = nil
    }

    private func dispose() {
        player?.pause()
        player = nil
        playerViewController?.dismiss(animated: true)
        playerViewController = nil
        stopPositionUpdates()
    }
}