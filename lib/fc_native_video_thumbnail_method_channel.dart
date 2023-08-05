import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';

import 'fc_native_video_thumbnail_platform_interface.dart';

/// An implementation of [FcNativeVideoThumbnailPlatform] that uses method channels.
class MethodChannelFcNativeVideoThumbnail
    extends FcNativeVideoThumbnailPlatform {
  /// The method channel used to interact with the native platform.
  @visibleForTesting
  final methodChannel = const MethodChannel('fc_native_video_thumbnail');

  @override
  Future<bool> getVideoThumbnail(
      {required String srcFile,
      required String destFile,
      required int width,
      required int height,
      required bool keepAspectRatio,
      String? format,
      bool? srcFileUri,
      int? quality}) async {
    var formatValue =
        format ?? (srcFile.toLowerCase().endsWith('.png') ? 'png' : 'jpeg');
    return (await methodChannel.invokeMethod<bool?>('getVideoThumbnail', {
          'srcFile': srcFile,
          'srcFileUri': srcFileUri,
          'destFile': destFile,
          'width': width,
          'height': height,
          'keepAspectRatio': keepAspectRatio,
          'type': formatValue,
          'quality': quality,
        })) ??
        false;
  }
}
