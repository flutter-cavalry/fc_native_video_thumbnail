package com.fluttercavalry.fc_native_video_thumbnail

import android.content.Context
import android.graphics.Bitmap
import android.media.MediaMetadataRetriever
import android.media.MediaMetadataRetriever.OPTION_CLOSEST_SYNC
import android.media.ThumbnailUtils
import android.net.Uri
import android.os.Build
import android.provider.MediaStore
import android.util.Size
import androidx.core.net.toUri
import io.flutter.embedding.engine.plugins.FlutterPlugin
import io.flutter.plugin.common.MethodCall
import io.flutter.plugin.common.MethodChannel
import io.flutter.plugin.common.MethodChannel.MethodCallHandler
import io.flutter.plugin.common.MethodChannel.Result
import kotlinx.coroutines.CoroutineScope
import kotlinx.coroutines.Dispatchers
import kotlinx.coroutines.launch
import java.io.ByteArrayOutputStream
import java.io.File
import java.io.FileOutputStream
import kotlin.math.roundToInt

/** FcNativeVideoThumbnailPlugin */
class FcNativeVideoThumbnailPlugin :
    FlutterPlugin,
    MethodCallHandler {
    // / The MethodChannel that will the communication between Flutter and native Android
    // /
    // / This local reference serves to register the plugin with the Flutter Engine and unregister it
    // / when the Flutter Engine is detached from the Activity
    private lateinit var channel: MethodChannel

    private lateinit var mContext: Context

    override fun onAttachedToEngine(flutterPluginBinding: FlutterPlugin.FlutterPluginBinding) {
        channel = MethodChannel(flutterPluginBinding.binaryMessenger, "fc_native_video_thumbnail")
        channel.setMethodCallHandler(this)
        mContext = flutterPluginBinding.applicationContext
    }

    override fun onMethodCall(
        call: MethodCall,
        result: Result,
    ) {
        val saveToFile = call.method == "saveThumbnailToFile"
        val saveToBytes = call.method == "saveThumbnailToBytes"
        if (!saveToFile && !saveToBytes) {
            result.notImplemented()
            return
        }

        CoroutineScope(Dispatchers.Default).launch {
            try {
                val srcFile = call.argument<String>("srcFile")!!
                val destFile = call.argument<String>("destFile")
                val width = call.argument<Int>("width")!!
                val height = call.argument<Int>("height")!!
                val srcFileUri = call.argument<Boolean>("srcFileUri") ?: false
                var quality = call.argument<Int?>("quality") ?: 90
                if (quality < 0) {
                    quality = 0
                } else if (quality > 100) {
                    quality = 100
                }
                val atUs = call.argument<Number>("atUs")?.toLong()

                var bitmap: Bitmap?
                var scaled = false
                var mmr: MediaMetadataRetriever? = null
                try {
                    mmr = MediaMetadataRetriever()
                    if (srcFileUri) {
                        mmr.setDataSource(mContext, srcFile.toUri())
                    } else {
                        mmr.setDataSource(mContext, srcFile.toUri())
                    }
                    val fullSize = getVideoDisplaySize(mmr)
                    var newSize = fullSize ?: Pair(width, height)
                    if (fullSize != null) {
                        newSize = sizeToFit(fullSize.first, fullSize.second, width, height)
                    }

                    if (Build.VERSION.SDK_INT >= 27) {
                        if (atUs != null) {
                            bitmap = mmr.getScaledFrameAtTime(atUs, OPTION_CLOSEST_SYNC, newSize.first, newSize.second)
                            scaled = true
                        } else {
                            bitmap = mmr.getScaledFrameAtTime(-1, OPTION_CLOSEST_SYNC, newSize.first, newSize.second)
                            scaled = true
                        }
                    } else {
                        bitmap = mmr.getFrameAtTime(atUs ?: -1, OPTION_CLOSEST_SYNC)
                    }
                } catch (err: Exception) {
                    // If we fail to retrieve the thumbnail, we return null or false instead of throwing an error.
                    bitmap = null
                } finally {
                    mmr?.release()
                }

                if (bitmap == null) {
                    launch(Dispatchers.Main) {
                        result.success(if (saveToBytes) null else false)
                    }
                    return@launch
                }

                val oldWidth = bitmap.width
                val oldHeight = bitmap.height

                // In older Android versions, the retrieved thumbnail may not be scaled to the requested size, so we need to scale it ourselves.
                if (!scaled && oldWidth != width && oldHeight != height) {
                    val newSize = sizeToFit(oldWidth, oldHeight, width, height)
                    bitmap = Bitmap.createScaledBitmap(bitmap, newSize.first, newSize.second, true)
                }
                if (saveToBytes) {
                    val output = ByteArrayOutputStream()
                    bitmap.compress(Bitmap.CompressFormat.JPEG, quality, output)
                    launch(Dispatchers.Main) {
                        result.success(output.toByteArray())
                    }
                } else {
                    FileOutputStream(destFile).use { out ->
                        bitmap.compress(Bitmap.CompressFormat.JPEG, quality, out)
                    }
                    launch(Dispatchers.Main) {
                        result.success(true)
                    }
                }
            } catch (err: Exception) {
                launch(Dispatchers.Main) {
                    result.error("PluginError", err.message, null)
                }
            }
        }
    }

    private fun sizeToFit(
        width: Int,
        height: Int,
        maxWidth: Int,
        maxHeight: Int,
    ): Pair<Int, Int> {
        val widthRatio = maxWidth.toDouble() / width
        val heightRatio = maxHeight.toDouble() / height
        val minAspectRatio = kotlin.math.min(widthRatio, heightRatio)
        if (minAspectRatio >= 1) {
            return Pair(width, height)
        }
        return Pair((width * minAspectRatio).roundToInt(), (height * minAspectRatio).roundToInt())
    }

    override fun onDetachedFromEngine(binding: FlutterPlugin.FlutterPluginBinding) {
        channel.setMethodCallHandler(null)
    }
}

fun getVideoDisplaySize(retriever: MediaMetadataRetriever): Pair<Int, Int>? {
    val rawWidth =
        retriever.extractMetadata(MediaMetadataRetriever.METADATA_KEY_VIDEO_WIDTH)?.toIntOrNull()
    val rawHeight =
        retriever.extractMetadata(MediaMetadataRetriever.METADATA_KEY_VIDEO_HEIGHT)?.toIntOrNull()
    val rotation =
        retriever.extractMetadata(MediaMetadataRetriever.METADATA_KEY_VIDEO_ROTATION)?.toIntOrNull() ?: 0

    if (rawWidth == null || rawHeight == null) return null
    // Normalize orientation
    return if (rotation == 90 || rotation == 270) {
        Pair(rawHeight, rawWidth)
    } else {
        Pair(rawWidth, rawHeight)
    }
}
