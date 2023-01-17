package com.fluttercavalry.fc_native_video_thumbnail

import android.graphics.Bitmap
import android.media.ThumbnailUtils
import android.os.Handler
import android.os.Looper
import android.util.Size
import androidx.annotation.NonNull

import io.flutter.embedding.engine.plugins.FlutterPlugin
import io.flutter.plugin.common.MethodCall
import io.flutter.plugin.common.MethodChannel
import io.flutter.plugin.common.MethodChannel.MethodCallHandler
import io.flutter.plugin.common.MethodChannel.Result
import io.flutter.plugin.common.StandardMethodCodec
import java.io.ByteArrayOutputStream
import java.io.File
import java.io.FileOutputStream

/** FcNativeVideoThumbnailPlugin */
class FcNativeVideoThumbnailPlugin: FlutterPlugin, MethodCallHandler {
  /// The MethodChannel that will the communication between Flutter and native Android
  ///
  /// This local reference serves to register the plugin with the Flutter Engine and unregister it
  /// when the Flutter Engine is detached from the Activity
  private lateinit var channel : MethodChannel

  override fun onAttachedToEngine(@NonNull flutterPluginBinding: FlutterPlugin.FlutterPluginBinding) {
    val taskQueue =
      flutterPluginBinding.binaryMessenger.makeBackgroundTaskQueue()
    channel = MethodChannel(flutterPluginBinding.binaryMessenger, "fc_native_video_thumbnail", StandardMethodCodec.INSTANCE,
      taskQueue)
    channel.setMethodCallHandler(this)
  }

  override fun onMethodCall(@NonNull call: MethodCall, @NonNull result: Result) {
    when (call.method) {
      "getVideoThumbnail" -> {
        // Arguments are enforced on dart side.
        val srcFile = call.argument<String>("srcFile")!!
        val destFile = call.argument<String>("destFile")!!
        val width = call.argument<Int>("width")!!
        val height = call.argument<Int>("height")!!
        val fileTypeString = call.argument<String>("type")!!
        var quality = call.argument<Int?>("quality") ?: 90
        if (quality < 0) {
          quality = 0;
        } else if (quality > 100) {
          quality = 100;
        }
        val fileType: Bitmap.CompressFormat
        if (fileTypeString == "png") {
          fileType = Bitmap.CompressFormat.PNG
          // Always use lossless PNG.
          quality = 100
        } else {
          fileType = Bitmap.CompressFormat.JPEG
        }
        try {
          val bitmap = ThumbnailUtils.createVideoThumbnail(File(srcFile), Size(width, height), null)
          val bos = ByteArrayOutputStream()
          bitmap.compress(fileType, quality, bos)
          val bitmapData = bos.toByteArray()

          val fos = FileOutputStream(destFile)
          fos.write(bitmapData)
          fos.flush()
          fos.close()
          Handler(Looper.getMainLooper()).post {
            result.success(null)
          }
        } catch (err: Exception) {
          Handler(Looper.getMainLooper()).post {
            result.error("Err", err.message, null)
          }
        }
      }
      else -> result.notImplemented()
    }
  }

  override fun onDetachedFromEngine(@NonNull binding: FlutterPlugin.FlutterPluginBinding) {
    channel.setMethodCallHandler(null)
  }
}
