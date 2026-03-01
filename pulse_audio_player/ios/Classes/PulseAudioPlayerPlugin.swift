import Flutter
import UIKit
import AVFoundation

public class PulseAudioPlayerPlugin: NSObject, FlutterPlugin {
    private var audioPlayer: AVAudioPlayer?
    private var channel: FlutterMethodChannel?
    private var positionTimer: Timer?

    public static func register(with registrar: FlutterPluginRegistrar) {
        let channel = FlutterMethodChannel(name: "pulse_audio_player", binaryMessenger: registrar.messenger())
        let instance = PulseAudioPlayerPlugin()
        instance.channel = channel
        registrar.addMethodCallDelegate(instance, channel: channel)
    }

    public func handle(_ call: FlutterMethodCall, result: @escaping FlutterResult) {
        switch call.method {
        case "play":
            if let args = call.arguments as? [String: Any],
               let urlString = args["url"] as? String {
                playAudio(urlString: urlString, result: result)
            } else {
                result(FlutterError(code: "INVALID_ARGUMENTS", message: "URL is required", details: nil))
            }

        case "pause":
            audioPlayer?.pause()
            result(true)

        case "stop":
            audioPlayer?.stop()
            audioPlayer?.currentTime = 0
            stopPositionUpdates()
            result(true)

        case "seekTo":
            if let args = call.arguments as? [String: Any],
               let position = args["position"] as? Int {
                audioPlayer?.currentTime = TimeInterval(position) / 1000.0
                result(true)
            } else {
                result(FlutterError(code: "INVALID_ARGUMENTS", message: "Position is required", details: nil))
            }

        case "setVolume":
            if let args = call.arguments as? [String: Any],
               let volume = args["volume"] as? Double {
                audioPlayer?.volume = Float(volume)
                result(true)
            } else {
                result(FlutterError(code: "INVALID_ARGUMENTS", message: "Volume is required", details: nil))
            }

        case "setSpeed":
            // Speed control would require AVAudioEngine for playback rate
            result(true)

        case "dispose":
            dispose()
            result(true)

        default:
            result(FlutterMethodNotImplemented)
        }
    }

    private func playAudio(urlString: String, result: @escaping FlutterResult) {
        guard let url = URL(string: urlString) else {
            result(FlutterError(code: "INVALID_URL", message: "Invalid URL", details: nil))
            return
        }

        // Configure audio session
        do {
            try AVAudioSession.sharedInstance().setCategory(.playback, mode: .default)
            try AVAudioSession.sharedInstance().setActive(true)
        } catch {
            print("Failed to set audio session category: \(error)")
        }

        // Download and play audio
        URLSession.shared.dataTask(with: url) { [weak self] data, response, error in
            guard let self = self else { return }

            if let error = error {
                DispatchQueue.main.async {
                    result(FlutterError(code: "DOWNLOAD_ERROR", message: error.localizedDescription, details: nil))
                }
                return
            }

            guard let data = data else {
                DispatchQueue.main.async {
                    result(FlutterError(code: "NO_DATA", message: "No audio data received", details: nil))
                }
                return
            }

            do {
                self.audioPlayer = try AVAudioPlayer(data: data)
                self.audioPlayer?.prepareToPlay()
                self.audioPlayer?.play()

                self.sendDuration()
                self.startPositionUpdates()

                DispatchQueue.main.async {
                    result(true)
                }
            } catch {
                DispatchQueue.main.async {
                    result(FlutterError(code: "PLAYBACK_ERROR", message: error.localizedDescription, details: nil))
                }
            }
        }.resume()
    }

    private func sendDuration() {
        guard let duration = audioPlayer?.duration else { return }
        channel?.invokeMethod("onDuration", arguments: Int(duration * 1000))
    }

    private func startPositionUpdates() {
        positionTimer?.invalidate()
        positionTimer = Timer.scheduledTimer(withTimeInterval: 0.5, repeats: true) { [weak self] _ in
            guard let self = self,
                  let currentTime = self.audioPlayer?.currentTime else { return }
            self.channel?.invokeMethod("onPosition", arguments: Int(currentTime * 1000))
        }
    }

    private func stopPositionUpdates() {
        positionTimer?.invalidate()
        positionTimer = nil
    }

    private func dispose() {
        audioPlayer?.stop()
        audioPlayer = nil
        stopPositionUpdates()
    }
}