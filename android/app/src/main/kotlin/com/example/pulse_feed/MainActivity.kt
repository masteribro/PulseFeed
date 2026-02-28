package com.example.pulse_feed

import android.media.MediaPlayer
import android.net.Uri
import android.os.Environment
import android.widget.MediaController
import android.widget.VideoView
import io.flutter.embedding.engine.FlutterEngine
import android.util.Log
import io.flutter.plugin.common.MethodChannel
import io.flutter.embedding.android.FlutterActivity
import android.content.Intent
import android.webkit.MimeTypeMap
import androidx.core.content.FileProvider
import java.io.File
import java.net.URL
import java.net.HttpURLConnection
import java.io.FileOutputStream

import com.google.android.exoplayer2.ExoPlayer
import com.google.android.exoplayer2.MediaItem
import com.google.android.exoplayer2.ui.StyledPlayerView
import com.google.android.exoplayer2.upstream.DefaultHttpDataSource
import com.google.android.exoplayer2.trackselection.DefaultTrackSelector
import com.google.android.exoplayer2.PlaybackException
import com.google.android.exoplayer2.C

class MainActivity : FlutterActivity() {

    private val AUDIO_CHANNEL = "com.example.pulse_feed/audio"
    private val VIDEO_CHANNEL =  "com.example.pulse_feed/video"
    private val DOCUMENT_CHANNEL = "com.example.pulse_feed/document"

    // Audio player
    private var mediaPlayer: MediaPlayer? = null

    // Video view
    private var videoView: VideoView? = null

    // ExoPlayer variables
    private var exoPlayer: ExoPlayer? = null
    private var playerView: StyledPlayerView? = null
    private var videoDialog: android.app.AlertDialog? = null

    override fun configureFlutterEngine(flutterEngine: FlutterEngine) {
        super.configureFlutterEngine(flutterEngine)

        setupAudioChannel(flutterEngine)
        setupVideoChannel(flutterEngine)
        setupDocumentChannel(flutterEngine)
    }

    // ==================== AUDIO CHANNEL ====================
    private fun setupAudioChannel(flutterEngine: FlutterEngine) {
        MethodChannel(flutterEngine.dartExecutor.binaryMessenger, AUDIO_CHANNEL).setMethodCallHandler { call, result ->
            when (call.method) {
                "play" -> {
                    val url = call.argument<String>("url")
                    if (url != null) {
                        playAudio(url, result)
                    } else {
                        result.error("NO_URL", "URL is required", null)
                    }
                }
                "pause" -> {
                    mediaPlayer?.pause()
                    result.success(true)
                }
                "stop" -> {
                    mediaPlayer?.stop()
                    mediaPlayer?.reset()
                    result.success(true)
                }
                else -> result.notImplemented()
            }
        }
    }

    private fun playAudio(url: String, result: MethodChannel.Result) {
        try {
            // Release previous player
            mediaPlayer?.release()

            mediaPlayer = MediaPlayer().apply {
                setDataSource(url)
                setOnPreparedListener {
                    start()
                    result.success(true)
                }
                setOnErrorListener { _, what, extra ->
                    result.error("PLAYBACK_ERROR", "Error: $what, $extra", null)
                    true
                }
                prepareAsync()
            }
        } catch (e: Exception) {
            result.error("ERROR", e.message, null)
        }
    }

    // ==================== VIDEO CHANNEL WITH EXOPLAYER ====================
    private fun setupVideoChannel(flutterEngine: FlutterEngine) {
        MethodChannel(flutterEngine.dartExecutor.binaryMessenger, VIDEO_CHANNEL).setMethodCallHandler { call, result ->
            when (call.method) {
                "play" -> {
                    val url = call.argument<String>("url")
                    if (url != null) {
                        playVideoWithExoPlayer(url, result)
                    } else {
                        result.error("NO_URL", "URL is required", null)
                    }
                }
                "pause" -> {
                    exoPlayer?.pause()
                    result.success(true)
                }
                "stop" -> {
                    stopExoPlayer()
                    result.success(true)
                }
                else -> result.notImplemented()
            }
        }
    }

    private fun playVideoWithExoPlayer(url: String, result: MethodChannel.Result) {
        Log.d("ExoPlayerDebug", "Starting ExoPlayer with URL: $url")

        try {
            // Release any existing player
            stopExoPlayer()

            // Create a FrameLayout container for the player view
            val container = android.widget.FrameLayout(this).apply {
                layoutParams = android.view.ViewGroup.LayoutParams(
                    android.view.ViewGroup.LayoutParams.MATCH_PARENT,
                    android.view.ViewGroup.LayoutParams.MATCH_PARENT
                )
                setBackgroundColor(android.graphics.Color.BLACK)
            }

            // Create player view - without useSurfaceView
            playerView = StyledPlayerView(this).apply {
                useController = true
                controllerShowTimeoutMs = 3000
                controllerHideOnTouch = true
                resizeMode = 0  // 0 = RESIZE_MODE_FIT
                layoutParams = android.widget.FrameLayout.LayoutParams(
                    android.widget.FrameLayout.LayoutParams.MATCH_PARENT,
                    android.widget.FrameLayout.LayoutParams.MATCH_PARENT
                )
                setBackgroundColor(android.graphics.Color.BLACK)
                // Remove useSurfaceView - it's not needed
            }

            // Add player view to container
            container.addView(playerView)

            // Create track selector
            val trackSelector = DefaultTrackSelector(this).apply {
                setParameters(buildUponParameters().setMaxVideoSize(1920, 1080))
            }

            // Build the player
            exoPlayer = ExoPlayer.Builder(this)
                .setTrackSelector(trackSelector)
                .build()
                .apply {
                    // Set user agent
                    val dataSourceFactory = DefaultHttpDataSource.Factory()
                        .setUserAgent("PulseFeed/1.0")
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
                    addListener(object : com.google.android.exoplayer2.Player.Listener {
                        override fun onPlaybackStateChanged(playbackState: Int) {
                            when (playbackState) {
                                ExoPlayer.STATE_READY -> {
                                    Log.d("ExoPlayerDebug", "Player ready")
                                    runOnUiThread {
                                        // Show dialog after player is ready
                                        val dialogBuilder = android.app.AlertDialog.Builder(this@MainActivity)
                                            .setTitle("Video Player")
                                            .setView(container)
                                            .setCancelable(true)
                                            .setOnDismissListener {
                                                stopExoPlayer()
                                            }

                                        videoDialog = dialogBuilder.create()
                                        videoDialog?.window?.setLayout(
                                            android.view.ViewGroup.LayoutParams.MATCH_PARENT,
                                            android.view.ViewGroup.LayoutParams.MATCH_PARENT
                                        )
                                        videoDialog?.show()
                                        Log.d("ExoPlayerDebug", "Dialog shown")

                                        // Start playing
                                        play()
                                    }
                                    result.success(true)
                                }
                                ExoPlayer.STATE_BUFFERING -> {
                                    Log.d("ExoPlayerDebug", "Buffering...")
                                }
                                ExoPlayer.STATE_ENDED -> {
                                    Log.d("ExoPlayerDebug", "Playback ended")
                                    runOnUiThread {
                                        videoDialog?.dismiss()
                                    }
                                }
                            }
                        }

                        override fun onPlayerError(error: PlaybackException) {
                            Log.e("ExoPlayerDebug", "Player error", error)
                            runOnUiThread {
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
            Log.e("ExoPlayerDebug", "Exception", e)
            result.error("ERROR", e.message, null)
        }
    }

    private fun stopExoPlayer() {
        try {
            exoPlayer?.apply {
                stop()
                release()
            }
            exoPlayer = null
            playerView = null
            videoDialog?.dismiss()
            videoDialog = null
        } catch (e: Exception) {
            Log.e("ExoPlayerDebug", "Error stopping player", e)
        }
    }

    // ==================== DOCUMENT CHANNEL ====================
    private fun setupDocumentChannel(flutterEngine: FlutterEngine) {
        MethodChannel(flutterEngine.dartExecutor.binaryMessenger, DOCUMENT_CHANNEL).setMethodCallHandler { call, result ->
            when (call.method) {
                "getTempDir" -> {
                    // Return temporary directory path
                    val tempDir = cacheDir.absolutePath
                    result.success(tempDir)
                }
                "open" -> {
                    val path = call.argument<String>("path")
                    if (path != null) {
                        openDocument(path, result)
                    } else {
                        result.error("NO_PATH", "File path is required", null)
                    }
                }
                "download" -> {
                    val url = call.argument<String>("url")
                    val fileName = call.argument<String>("fileName")
                    if (url != null && fileName != null) {
                        downloadDocument(url, fileName, result)
                    } else {
                        result.error("INVALID_PARAMS", "URL and fileName required", null)
                    }
                }
                else -> result.notImplemented()
            }
        }
    }

    private fun openDocument(filePath: String, result: MethodChannel.Result) {
        try {
            Log.d("PDFDebug", "Opening file: $filePath")
            val file = File(filePath)

            if (!file.exists()) {
                Log.e("PDFDebug", "File does not exist: $filePath")
                result.error("FILE_NOT_FOUND", "File does not exist", null)
                return
            }

            Log.d("PDFDebug", "File size: ${file.length()}")

            val uri = FileProvider.getUriForFile(this, "$packageName.fileprovider", file)
            val mimeType = getMimeType(file.absolutePath) ?: "application/pdf"

            Log.d("PDFDebug", "URI: $uri, MIME: $mimeType")

            val intent = Intent(Intent.ACTION_VIEW).apply {
                setDataAndType(uri, mimeType)
                addFlags(Intent.FLAG_GRANT_READ_URI_PERMISSION)
                addFlags(Intent.FLAG_ACTIVITY_NEW_TASK)
            }

            startActivity(Intent.createChooser(intent, "Open with"))
            result.success(true)
        } catch (e: Exception) {
            Log.e("PDFDebug", "Error opening document", e)
            result.error("OPEN_ERROR", e.message, null)
        }
    }

    private fun downloadDocument(url: String, fileName: String, result: MethodChannel.Result) {
        Thread {
            try {
                // Create downloads directory
                val downloadsDir = getExternalFilesDir(Environment.DIRECTORY_DOWNLOADS)
                val outputFile = File(downloadsDir, fileName)

                // Download file
                val connection = URL(url).openConnection() as HttpURLConnection
                connection.requestMethod = "GET"
                connection.connect()

                val inputStream = connection.inputStream
                val outputStream = FileOutputStream(outputFile)

                val buffer = ByteArray(4096)
                var bytesRead: Int
                var totalBytes = 0L
                val fileLength = connection.contentLengthLong

                while (inputStream.read(buffer).also { bytesRead = it } != -1) {
                    outputStream.write(buffer, 0, bytesRead)
                    totalBytes += bytesRead

                    // Send progress to Flutter
                    if (fileLength > 0) {
                        val progress = (totalBytes * 100 / fileLength).toInt()
                        MethodChannel(
                            flutterEngine!!.dartExecutor.binaryMessenger,
                            DOCUMENT_CHANNEL
                        ).invokeMethod("onProgress", mapOf(
                            "progress" to progress,
                            "downloaded" to totalBytes,
                            "total" to fileLength
                        ))
                    }
                }

                outputStream.close()
                inputStream.close()
                connection.disconnect()

                // Return file path
                result.success(outputFile.absolutePath)
            } catch (e: Exception) {
                result.error("DOWNLOAD_ERROR", e.message, null)
            }
        }.start()
    }

    private fun getMimeType(url: String): String? {
        val extension = MimeTypeMap.getFileExtensionFromUrl(url)
        return MimeTypeMap.getSingleton().getMimeTypeFromExtension(extension)
    }

    override fun onDestroy() {
        mediaPlayer?.release()
        stopExoPlayer()
        super.onDestroy()
    }
}