import 'fc_native_video_thumbnail_platform_interface.dart';

class FcNativeVideoThumbnail {
  /// Gets a thumbnail from [srcFile] with the given options and saves it to [destFile].
  /// [srcFile] source video path.
  /// [destFile] destination thumbnail path.
  /// [width] / [height] max dimensions of the destination thumbnail.
  /// NOTE: Windows doesn't support non-square thumbnail images, only [width] is used in Windows, resulting in a [width]x[width] thumbnail.
  /// [keepAspectRatio] if true, keeps aspect ratio of the destination thumbnail.
  /// NOTE: iOS/macOS only. Defaults to true on other platforms.
  /// [type] specifies the image type of the destination thumbnail. 'png' or 'jpeg'.
  /// [quality] only applies to 'jpeg' type. 1-100 (100 best quality).
  Future<void> getVideoThumbnail(
      {required String srcFile,
      required String destFile,
      required int width,
      required int height,
      required bool keepAspectRatio,
      required String type,
      int? quality}) {
    return FcNativeVideoThumbnailPlatform.instance.getVideoThumbnail(
        srcFile: srcFile,
        destFile: destFile,
        width: width,
        height: height,
        keepAspectRatio: keepAspectRatio,
        type: type,
        quality: quality);
  }
}
