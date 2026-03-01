package com.example.pulse_document_viewer

import android.content.Intent
import android.net.Uri
import android.os.Environment
import android.os.Handler
import android.os.Looper
import android.webkit.MimeTypeMap
import android.util.Log
import androidx.annotation.NonNull
import androidx.core.content.FileProvider
import io.flutter.embedding.engine.plugins.FlutterPlugin
import io.flutter.embedding.engine.plugins.activity.ActivityAware
import io.flutter.embedding.engine.plugins.activity.ActivityPluginBinding
import io.flutter.plugin.common.MethodCall
import io.flutter.plugin.common.MethodChannel
import io.flutter.plugin.common.MethodChannel.MethodCallHandler
import io.flutter.plugin.common.MethodChannel.Result
import android.app.Activity
import java.io.File
import java.io.FileOutputStream
import java.net.HttpURLConnection
import java.net.URL
import java.util.concurrent.Executors
import java.util.concurrent.Future

class PulseDocumentViewerPlugin : FlutterPlugin, MethodCallHandler, ActivityAware {
    private lateinit var channel: MethodChannel
    private lateinit var context: android.content.Context
    private var activity: Activity? = null
    private val mainHandler = Handler(Looper.getMainLooper())

    private var downloadFuture: Future<*>? = null
    private var isDownloadCancelled = false

    override fun onAttachedToEngine(@NonNull binding: FlutterPlugin.FlutterPluginBinding) {
        channel = MethodChannel(binding.binaryMessenger, "pulse_document_viewer")
        channel.setMethodCallHandler(this)
        context = binding.applicationContext
    }

    override fun onMethodCall(@NonNull call: MethodCall, @NonNull result: Result) {
        when (call.method) {
            "getTempDir" -> {
                val tempDir = context.cacheDir.absolutePath
                result.success(tempDir)
            }
            "downloadDocument" -> {
                val url = call.argument<String>("url")
                val fileName = call.argument<String>("fileName")
                if (url != null && fileName != null) {
                    downloadDocument(url, fileName, result)
                } else {
                    result.error("INVALID_ARGUMENTS", "URL and fileName are required", null)
                }
            }
            "openDocument" -> {
                val path = call.argument<String>("path")
                if (path != null) {
                    openDocument(path, result)
                } else {
                    result.error("INVALID_ARGUMENTS", "Path is required", null)
                }
            }
            "fileExists" -> {
                val path = call.argument<String>("path")
                if (path != null) {
                    val file = File(path)
                    result.success(file.exists())
                } else {
                    result.error("INVALID_ARGUMENTS", "Path is required", null)
                }
            }
            "deleteFile" -> {
                val path = call.argument<String>("path")
                if (path != null) {
                    val file = File(path)
                    result.success(file.delete())
                } else {
                    result.error("INVALID_ARGUMENTS", "Path is required", null)
                }
            }
            "cancelDownload" -> {
                isDownloadCancelled = true
                downloadFuture?.cancel(true)
                result.success(true)
            }
            else -> result.notImplemented()
        }
    }

    private fun downloadDocument(url: String, fileName: String, result: Result) {
        val executor = Executors.newSingleThreadExecutor()
        isDownloadCancelled = false

        downloadFuture = executor.submit {
            try {
                val downloadsDir = context.getExternalFilesDir(Environment.DIRECTORY_DOWNLOADS)
                val outputFile = File(downloadsDir, fileName)

                val connection = URL(url).openConnection() as HttpURLConnection
                connection.requestMethod = "GET"
                connection.connect()

                val inputStream = connection.inputStream
                val outputStream = FileOutputStream(outputFile)

                val buffer = ByteArray(4096)
                var bytesRead: Int
                var totalBytes = 0L
                val fileLength = connection.contentLengthLong

                while (inputStream.read(buffer).also { bytesRead = it } != -1 && !isDownloadCancelled) {
                    outputStream.write(buffer, 0, bytesRead)
                    totalBytes += bytesRead

                    // Send progress to Flutter
                    if (fileLength > 0) {
                        val progress = (totalBytes * 100 / fileLength).toInt()
                        mainHandler.post {
                            channel.invokeMethod("onProgress", progress.toDouble() / 100)
                        }
                    }
                }

                outputStream.close()
                inputStream.close()
                connection.disconnect()

                if (isDownloadCancelled) {
                    outputFile.delete()
                    mainHandler.post {
                        channel.invokeMethod("onError", null)
                    }
                } else {
                    mainHandler.post {
                        channel.invokeMethod("onComplete", outputFile.absolutePath)
                    }
                    result.success(outputFile.absolutePath)
                }

            } catch (e: Exception) {
                Log.e("DocumentPlugin", "Download error", e)
                mainHandler.post {
                    channel.invokeMethod("onError", null)
                }
                result.error("DOWNLOAD_ERROR", e.message, null)
            } finally {
                executor.shutdown()
            }
        }
    }

    private fun openDocument(filePath: String, result: Result) {
        val activity = this.activity ?: run {
            result.error("NO_ACTIVITY", "Activity not available", null)
            return
        }

        try {
            Log.d("DocumentPlugin", "Opening file: $filePath")
            val file = File(filePath)

            if (!file.exists()) {
                Log.e("DocumentPlugin", "File does not exist: $filePath")
                result.error("FILE_NOT_FOUND", "File does not exist", null)
                return
            }

            Log.d("DocumentPlugin", "File size: ${file.length()}")

            val uri = FileProvider.getUriForFile(activity,
                "${activity.packageName}.fileprovider", file)
            val mimeType = getMimeType(file.absolutePath) ?: "application/octet-stream"

            Log.d("DocumentPlugin", "URI: $uri, MIME: $mimeType")

            val intent = Intent(Intent.ACTION_VIEW).apply {
                setDataAndType(uri, mimeType)
                addFlags(Intent.FLAG_GRANT_READ_URI_PERMISSION)
                addFlags(Intent.FLAG_ACTIVITY_NEW_TASK)
            }

            activity.startActivity(Intent.createChooser(intent, "Open with"))
            result.success(true)
        } catch (e: Exception) {
            Log.e("DocumentPlugin", "Error opening document", e)
            result.error("OPEN_ERROR", e.message, null)
        }
    }

    private fun getMimeType(url: String): String? {
        val extension = MimeTypeMap.getFileExtensionFromUrl(url)
        return MimeTypeMap.getSingleton().getMimeTypeFromExtension(extension)
    }

    override fun onDetachedFromEngine(@NonNull binding: FlutterPlugin.FlutterPluginBinding) {
        channel.setMethodCallHandler(null)
    }


    override fun onAttachedToActivity(binding: ActivityPluginBinding) {
        activity = binding.activity
    }

    override fun onDetachedFromActivity() {
        activity = null
    }

    override fun onReattachedToActivityForConfigChanges(binding: ActivityPluginBinding) {
        activity = binding.activity
    }

    override fun onDetachedFromActivityForConfigChanges() {
        activity = null
    }
}