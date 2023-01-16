import 'fc_native_video_thumbnail_platform_interface.dart';

class FcNativeVideoThumbnail {
  /// Gets a thumbnail from [srcFile] with the given parameters and saves it to [destFile].
  /// [srcFile] source image path.
  /// [destFile] destination image path.
  /// [width] and [height] max dimensions of generated thumbnail image.
  /// NOTE: Windows doesn't support non-square thumbnail images, only [width] is used in Windows, resulting in a [width]x[width] thumbnail.
  /// [keepAspectRatio] if true, keeps aspect ratio.
  /// [type] specifies image type of destination file. 'png' or 'jpeg'.
  /// [quality] only applies for 'jpeg' type, 1-100 (100 best quality).
  Future<void> getThumbnailFile(
      {required String srcFile,
      required String destFile,
      required int width,
      required int height,
      required bool keepAspectRatio,
      required String type,
      double? quality}) {
    return FcNativeVideoThumbnailPlatform.instance.getThumbnailFile(
        srcFile: srcFile,
        destFile: destFile,
        width: width,
        height: height,
        keepAspectRatio: keepAspectRatio,
        type: type,
        quality: quality);
  }
}
