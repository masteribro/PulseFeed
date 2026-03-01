package com.example.pulse_video_player

import android.net.Uri
import android.os.Handler
import android.os.Looper
import android.view.ViewGroup
import android.widget.FrameLayout
import android.app.AlertDialog
import android.graphics.Color
import android.util.Log
import androidx.annotation.NonNull

import com.google.android.exoplayer2.ExoPlayer
import com.google.android.exoplayer2.MediaItem
import com.google.android.exoplayer2.PlaybackException
import com.google.android.exoplayer2.Player
import com.google.android.exoplayer2.ui.StyledPlayerView
import com.google.android.exoplayer2.upstream.DefaultHttpDataSource
import com.google.android.exoplayer2.trackselection.DefaultTrackSelector
import com.google.android.exoplayer2.ui.AspectRatioFrameLayout

import io.flutter.embedding.engine.plugins.FlutterPlugin
import io.flutter.embedding.engine.plugins.activity.ActivityAware
import io.flutter.embedding.engine.plugins.activity.ActivityPluginBinding
import io.flutter.plugin.common.MethodCall
import io.flutter.plugin.common.MethodChannel
import io.flutter.plugin.common.MethodChannel.MethodCallHandler
import io.flutter.plugin.common.MethodChannel.Result
import android.app.Activity

class PulseVideoPlayerPlugin : FlutterPlugin, MethodCallHandler, ActivityAware {
    private lateinit var channel: MethodChannel
    private lateinit var context: android.content.Context
    private var activity: Activity? = null
    private val mainHandler = Handler(Looper.getMainLooper())

    private var exoPlayer: ExoPlayer? = null
    private var playerView: StyledPlayerView? = null
    private var videoDialog: AlertDialog? = null
    private var positionUpdateRunnable: Runnable? = null

    override fun onAttachedToEngine(@NonNull binding: FlutterPlugin.FlutterPluginBinding) {
        channel = MethodChannel(binding.binaryMessenger, "pulse_video_player")
        channel.setMethodCallHandler(this)
        context = binding.applicationContext
    }

    override fun onMethodCall(@NonNull call: MethodCall, @NonNull result: Result) {
        when (call.method) {
            "play" -> {
                val url = call.argument<String>("url")
                if (url != null) {
                    playVideo(url, result)
                } else {
                    result.error("INVALID_ARGUMENTS", "URL is required", null)
                }
            }
            "pause" -> {
                exoPlayer?.pause()
                result.success(true)
            }
            "stop" -> {
                stopVideo()
                result.success(true)
            }
            "seekTo" -> {
                val position = call.argument<Int>("position")
                if (position != null) {
                    exoPlayer?.seekTo(position.toLong())
                    result.success(true)
                } else {
                    result.error("INVALID_ARGUMENTS", "Position is required", null)
                }
            }
            "setVolume" -> {
                val volume = call.argument<Double>("volume")
                if (volume != null) {
                    exoPlayer?.volume = volume.toFloat()
                    result.success(true)
                } else {
                    result.error("INVALID_ARGUMENTS", "Volume is required", null)
                }
            }
            "setPlaybackSpeed" -> {
                val speed = call.argument<Double>("speed")
                if (speed != null) {
                    exoPlayer?.setPlaybackSpeed(speed.toFloat())
                    result.success(true)
                } else {
                    result.error("INVALID_ARGUMENTS", "Speed is required", null)
                }
            }
            "setLooping" -> {
                val loop = call.argument<Boolean>("loop")
                if (loop != null) {
                    exoPlayer?.repeatMode = if (loop) Player.REPEAT_MODE_ONE else Player.REPEAT_MODE_OFF
                    result.success(true)
                } else {
                    result.error("INVALID_ARGUMENTS", "Loop value is required", null)
                }
            }
            "dispose" -> {
                disposePlayer()
                result.success(true)
            }
            else -> result.notImplemented()
        }
    }

    private fun playVideo(url: String, result: Result) {
        Log.d("VideoPlugin", "Starting ExoPlayer with URL: $url")

        val activity = this.activity
        if (activity == null) {
            Log.e("VideoPlugin", "Activity is null")
            result.error("NO_ACTIVITY", "Activity not available", null)
            return
        }

        try {
            // Release any existing player
            stopVideo()

            // Create a FrameLayout container for the player view
            val container = FrameLayout(activity).apply {
                layoutParams = ViewGroup.LayoutParams(
                    ViewGroup.LayoutParams.MATCH_PARENT,
                    ViewGroup.LayoutParams.MATCH_PARENT
                )
                setBackgroundColor(Color.BLACK)
            }

            // Create player view
            playerView = StyledPlayerView(activity).apply {
                useController = true
                controllerShowTimeoutMs = 3000
                controllerHideOnTouch = true
                resizeMode = AspectRatioFrameLayout.RESIZE_MODE_FIT
                layoutParams = FrameLayout.LayoutParams(
                    FrameLayout.LayoutParams.MATCH_PARENT,
                    FrameLayout.LayoutParams.MATCH_PARENT
                )
                setBackgroundColor(Color.BLACK)
            }

            // Add player view to container
            container.addView(playerView)

            // Create track selector
            val trackSelector = DefaultTrackSelector(activity).apply {
                setParameters(buildUponParameters().setMaxVideoSize(1920, 1080))
            }

            // Build the player
            exoPlayer = ExoPlayer.Builder(activity)
                .setTrackSelector(trackSelector)
                .build()
                .apply {
                    // Set user agent
                    val dataSourceFactory = DefaultHttpDataSource.Factory()
                        .setUserAgent("PulseVideoPlayer/1.0")
                        .setAllowCrossProtocolRedirects(true)

                    // Create media item
                    val mediaItem = MediaItem.Builder()
                        .setUri(Uri.parse(url))
                        .setMimeType("video/mp4")
                        .build()

                    setMediaItem(mediaItem)

                    // Set volume to ensure audio is heard
                    volume = 1.0f

                    // Add listener
                    addListener(object : Player.Listener {
                        override fun onPlaybackStateChanged(playbackState: Int) {
                            when (playbackState) {
                                ExoPlayer.STATE_READY -> {
                                    Log.d("VideoPlugin", "Player ready")
                                    sendDuration()
                                    startPositionUpdates()
                                    activity.runOnUiThread {
                                        // Show dialog after player is ready
                                        val dialogBuilder = AlertDialog.Builder(activity)
                                            .setTitle("Video Player")
                                            .setView(container)
                                            .setCancelable(true)
                                            .setOnDismissListener {
                                                stopVideo()
                                            }

                                        videoDialog = dialogBuilder.create()
                                        videoDialog?.window?.setLayout(
                                            ViewGroup.LayoutParams.MATCH_PARENT,
                                            ViewGroup.LayoutParams.MATCH_PARENT
                                        )
                                        videoDialog?.show()
                                        Log.d("VideoPlugin", "Dialog shown")

                                        // Start playing
                                        play()
                                    }
                                    result.success(true)
                                }
                                ExoPlayer.STATE_BUFFERING -> {
                                    Log.d("VideoPlugin", "Buffering...")
                                    sendBuffering(true)
                                }
                                ExoPlayer.STATE_ENDED -> {
                                    Log.d("VideoPlugin", "Playback ended")
                                    sendCompletion()
                                    activity.runOnUiThread {
                                        videoDialog?.dismiss()
                                    }
                                }
                            }
                        }

                        override fun onPlayerError(error: PlaybackException) {
                            Log.e("VideoPlugin", "Player error", error)
                            sendError(error.message ?: "Unknown error")
                            activity.runOnUiThread {
                                videoDialog?.dismiss()
                            }
                            result.error("VIDEO_ERROR", error.message, null)
                        }
                    })

                    // Prepare player
                    prepare()
                }

            // Attach player to view
            playerView?.player = exoPlayer

        } catch (e: Exception) {
            Log.e("VideoPlugin", "Exception", e)
            result.error("ERROR", e.message ?: "Unknown error", null)
        }
    }

    private fun stopVideo() {
        try {
            stopPositionUpdates()
            exoPlayer?.apply {
                stop()
                release()
            }
            exoPlayer = null
            playerView = null
            videoDialog?.dismiss()
            videoDialog = null
        } catch (e: Exception) {
            Log.e("VideoPlugin", "Error stopping player", e)
        }
    }

    private fun disposePlayer() {
        stopVideo()
    }

    private fun sendDuration() {
        exoPlayer?.duration?.let {
            mainHandler.post {
                channel.invokeMethod("onDuration", it)
            }
        }
    }

    private fun startPositionUpdates() {
        positionUpdateRunnable = object : Runnable {
            override fun run() {
                exoPlayer?.currentPosition?.let { position ->
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

    private fun sendBuffering(isBuffering: Boolean) {
        mainHandler.post {
            channel.invokeMethod("onBuffering", isBuffering)
        }
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

    // ActivityAware implementation
    override fun onAttachedToActivity(binding: ActivityPluginBinding) {
        activity = binding.activity
    }

    override fun onDetachedFromActivity() {
        activity = null
        disposePlayer()
    }

    override fun onReattachedToActivityForConfigChanges(binding: ActivityPluginBinding) {
        activity = binding.activity
    }

    override fun onDetachedFromActivityForConfigChanges() {
        activity = null
        disposePlayer()
    }
}