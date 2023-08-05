package com.fluttercavalry.fc_native_video_thumbnail

import android.content.Context
import android.graphics.Bitmap
import android.media.MediaMetadataRetriever
import android.media.ThumbnailUtils
import android.net.Uri
import android.os.Handler
import android.os.Looper
import android.provider.MediaStore
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

  private lateinit var mContext : Context

  override fun onAttachedToEngine(@NonNull flutterPluginBinding: FlutterPlugin.FlutterPluginBinding) {
    val taskQueue =
      flutterPluginBinding.binaryMessenger.makeBackgroundTaskQueue()
    channel = MethodChannel(flutterPluginBinding.binaryMessenger, "fc_native_video_thumbnail", StandardMethodCodec.INSTANCE,
      taskQueue)
    channel.setMethodCallHandler(this)
    mContext = flutterPluginBinding.applicationContext
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
        val srcFileUri = call.argument<Boolean>("srcFileUri") ?: false
        val keepAspectRatio = true

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
          var bitmap: Bitmap?
          if (srcFileUri) {
            val mmr = MediaMetadataRetriever()
            mmr.setDataSource(mContext, Uri.parse(srcFile))
            bitmap = mmr.frameAtTime
          } else {
            bitmap = ThumbnailUtils.createVideoThumbnail(srcFile, MediaStore.Images.Thumbnails.MINI_KIND)
          }

          if (bitmap == null) {
            Handler(Looper.getMainLooper()).post {
              result.success(false)
            }
          } else {
            val oldWidth = bitmap.width
            val oldHeight = bitmap.height
            val newSize: Pair<Int, Int> = if (keepAspectRatio) {
              sizeToFit(oldWidth, oldHeight, width, height)
            } else {
              Pair(oldWidth, oldHeight)
            }
            val newBitmap = Bitmap.createScaledBitmap(bitmap, newSize.first, newSize.second, true)

            val bos = ByteArrayOutputStream()
            newBitmap.compress(fileType, quality, bos)
            val bitmapData = bos.toByteArray()

            val fos = FileOutputStream(destFile)
            fos.write(bitmapData)
            fos.flush()
            fos.close()
            Handler(Looper.getMainLooper()).post {
              result.success(true)
            }
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

  private fun sizeToFit(width: Int, height: Int, maxWidth: Int, maxHeight: Int): Pair<Int, Int> {
    val widthRatio = maxWidth.toDouble() / width
    val heightRatio = maxHeight.toDouble() / height
    val minAspectRatio = kotlin.math.min(widthRatio, heightRatio)
    if (minAspectRatio > 1) {
      return Pair(width, height)
    }
    return Pair((width * minAspectRatio).toInt(), (height * minAspectRatio).toInt())
  }

  override fun onDetachedFromEngine(@NonNull binding: FlutterPlugin.FlutterPluginBinding) {
    channel.setMethodCallHandler(null)
  }
}
