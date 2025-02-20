package com.tbib_downloader.tbib_downloader

import android.os.Environment
import androidx.annotation.NonNull
import io.flutter.embedding.engine.plugins.FlutterPlugin
import io.flutter.plugin.common.MethodCall
import io.flutter.plugin.common.MethodChannel
import io.flutter.plugin.common.MethodChannel.MethodCallHandler
import io.flutter.plugin.common.MethodChannel.Result
import java.io.File

/** TbibDownloaderPlugin */
class TbibDownloaderPlugin: FlutterPlugin, MethodCallHandler {
  /// The MethodChannel that will handle communication between Flutter and native Android
  private lateinit var channel : MethodChannel

  override fun onAttachedToEngine(@NonNull flutterPluginBinding: FlutterPlugin.FlutterPluginBinding) {
    channel = MethodChannel(flutterPluginBinding.binaryMessenger, "tbib_downloader")
    channel.setMethodCallHandler(this)
  }

  override fun onMethodCall(@NonNull call: MethodCall, @NonNull result: Result) {
    when (call.method) {
      "getPlatformVersion" -> {
        result.success("Android ${android.os.Build.VERSION.RELEASE}")
      }
      "getDownloadsDirectory" -> {
        val downloadsPath = getDownloadsDirectory()
        if (downloadsPath != null) {
          result.success(downloadsPath)
        } else {
          result.error("UNAVAILABLE", "Downloads directory not available.", null)
        }
      }
      else -> {
        result.notImplemented()
      }
    }
  }

  private fun getDownloadsDirectory(): String? {
    return try {
      val downloadsDir = Environment.getExternalStoragePublicDirectory(Environment.DIRECTORY_DOWNLOADS)
      downloadsDir.absolutePath
    } catch (e: Exception) {
      e.printStackTrace()
      null
    }
  }

  override fun onDetachedFromEngine(@NonNull binding: FlutterPlugin.FlutterPluginBinding) {
    channel.setMethodCallHandler(null)
  }
}