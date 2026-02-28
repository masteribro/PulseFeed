package com.example.pulse_audio_player

import android.media.MediaPlayer
import android.net.Uri
import android.os.Handler
import android.os.Looper
import androidx.annotation.NonNull
import io.flutter.embedding.engine.plugins.FlutterPlugin
import io.flutter.plugin.common.MethodCall
import io.flutter.plugin.common.MethodChannel
import io.flutter.plugin.common.MethodChannel.MethodCallHandler
import io.flutter.plugin.common.MethodChannel.Result
import io.flutter.plugin.common.EventChannel
import java.io.IOException

class PulseAudioPlayerPlugin : FlutterPlugin, MethodCallHandler {
    private lateinit var channel: MethodChannel
    private lateinit var context: android.content.Context

    private var mediaPlayer: MediaPlayer? = null
    private val mainHandler = Handler(Looper.getMainLooper())
    private var positionUpdateRunnable: Runnable? = null

    override fun onAttachedToEngine(@NonNull binding: FlutterPlugin.FlutterPluginBinding) {
        channel = MethodChannel(binding.binaryMessenger, "pulse_audio_player")
        channel.setMethodCallHandler(this)
        context = binding.applicationContext
    }

    override fun onMethodCall(@NonNull call: MethodCall, @NonNull result: Result) {
        when (call.method) {
            "play" -> {
                val url = call.argument<String>("url")
                if (url != null) {
                    playAudio(url, result)
                } else {
                    result.error("INVALID_ARGUMENTS", "URL is required", null)
                }
            }
            "pause" -> {
                mediaPlayer?.pause()
                result.success(true)
            }
            "stop" -> {
                stopAudio()
                result.success(true)
            }
            "seekTo" -> {
                val position = call.argument<Int>("position")
                if (position != null) {
                    mediaPlayer?.seekTo(position)
                    result.success(true)
                } else {
                    result.error("INVALID_ARGUMENTS", "Position is required", null)
                }
            }
            "setVolume" -> {
                val volume = call.argument<Double>("volume")
                if (volume != null) {
                    mediaPlayer?.setVolume(volume.toFloat(), volume.toFloat())
                    result.success(true)
                } else {
                    result.error("INVALID_ARGUMENTS", "Volume is required", null)
                }
            }
            "setSpeed" -> {
                result.success(true)
            }
            "dispose" -> {
                disposePlayer()
                result.success(true)
            }
            else -> result.notImplemented()
        }
    }

    private fun playAudio(url: String, result: Result) {
        try {
            disposePlayer()

            mediaPlayer = MediaPlayer().apply {
                setDataSource(url)
                setOnPreparedListener {
                    start()
                    sendDuration()
                    startPositionUpdates()
                    result.success(true)
                }
                setOnErrorListener { _, what, extra ->
                    sendError("Playback error: $what, $extra")
                    result.error("PLAYBACK_ERROR", "Error: $what, $extra", null)
                    true
                }
                setOnCompletionListener {
                    sendCompletion()
                    stopPositionUpdates()
                }
                prepareAsync()
            }
        } catch (e: Exception) {
            result.error("PLAYBACK_ERROR", e.message, null)
        }
    }

    private fun stopAudio() {
        mediaPlayer?.stop()
        mediaPlayer?.reset()
        stopPositionUpdates()
    }

    private fun disposePlayer() {
        stopPositionUpdates()
        mediaPlayer?.release()
        mediaPlayer = null
    }

    private fun sendDuration() {
        mediaPlayer?.duration?.let {
            mainHandler.post {
                channel.invokeMethod("onDuration", it)
            }
        }
    }

    private fun startPositionUpdates() {
        positionUpdateRunnable = object : Runnable {
            override fun run() {
                mediaPlayer?.currentPosition?.let { position ->
                    mainHandler.post {
                        channel.invokeMethod("onPosition", position)
                    }
                }
                mainHandler.postDelayed(this, 500)
            }
        }
        mainHandler.post(positionUpdateRunnable!!)
    }

    private fun stopPositionUpdates() {
        positionUpdateRunnable?.let { mainHandler.removeCallbacks(it) }
        positionUpdateRunnable = null
    }

    private fun sendCompletion() {
        mainHandler.post {
            channel.invokeMethod("onCompletion", null)
        }
    }

    private fun sendError(message: String) {
        mainHandler.post {
            channel.invokeMethod("onError", message)
        }
    }

    override fun onDetachedFromEngine(@NonNull binding: FlutterPlugin.FlutterPluginBinding) {
        disposePlayer()
        channel.setMethodCallHandler(null)
    }
}