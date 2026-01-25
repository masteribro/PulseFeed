package com.example.pulse_feed

import android.media.MediaPlayer
import io.flutter.embedding.engine.FlutterEngine
import android.util.Log
import io.flutter.plugin.common.MethodChannel
import io.flutter.embedding.android.FlutterActivity

class MainActivity : FlutterActivity() {

    private val CHANNEL = "com.example.pulse_feed/simple_media"

    private var mediaPlayer: MediaPlayer? = null

    override fun configureFlutterEngine(flutterEngine: FlutterEngine) {
        super.configureFlutterEngine(flutterEngine)

        Log.d("MediaPlayer", "Setting up channel: $CHANNEL")

        MethodChannel(flutterEngine.dartExecutor.binaryMessenger, CHANNEL).setMethodCallHandler {
                call, result ->

            Log.d("MediaPlayer", "Method called: ${call.method}")

            when (call.method) {
                "play" -> {
                    val url = call.argument<String>("url")
                    if (url != null) {
                        Log.d("MediaPlayer", "playAudio called with: $url")
                        playAudio(url, result)
                    } else {
                        result.error("NO_URL", "URL is required", null)
                    }
                }

                "pause" -> {
                    if (mediaPlayer?.isPlaying == true) {
                        mediaPlayer?.pause()
                        result.success(true)
                    } else {
                        result.success(false)
                    }
                }

                else -> {
                    result.notImplemented()
                }
            }
        }
    }

    private fun playAudio(url: String, result: MethodChannel.Result) {
        try {
            Log.d("MediaPlayer", "playAudio called with: $url")
            // If already playing, stop it first
            if (mediaPlayer?.isPlaying == true) {
                mediaPlayer?.stop()
            }

            mediaPlayer = MediaPlayer().apply {
                setDataSource(url)
                prepareAsync()

                setOnPreparedListener {
                    Log.d("MediaPlayer", "Media prepared and playing")
                    start()
                    result.success(true)
                }

                setOnErrorListener { mp, what, extra ->
                    Log.e("MediaPlayer", "Error: what=$what, extra=$extra")
                    result.error("PLAYBACK_ERROR", "Failed to play", null)
                    false
                }
            }
        } catch (e: Exception) {
            Log.e("MediaPlayer", "Exception: ${e.message}", e)
            result.error("ERROR", e.message, null)
        }
    }

    override fun onDestroy() {
        mediaPlayer?.release()
        super.onDestroy()
    }
}
