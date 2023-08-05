import 'fc_native_video_thumbnail_platform_interface.dart';

class FcNativeVideoThumbnail {
  /// Gets a thumbnail from [srcFile] with the given options and saves it to [destFile].
  ///
  /// [srcFile] source video path or Uri (Android only, set [srcFileUri] to true if this is a Uri).
  /// [srcFileUri] if true, [srcFile] is a Uri, otherwise it's a file path. Defaults to false. Android only.
  /// [destFile] destination thumbnail path.
  /// [width] / [height] max dimensions of the destination thumbnail.
  /// Windows doesn't support non-square thumbnail images, only [width] is used in Windows, resulting in a [width]x[width] thumbnail.
  /// [keepAspectRatio] if true, keeps aspect ratio of the destination thumbnail.
  /// iOS/macOS only. Defaults to true on other platforms.
  /// [format] specifies the image format of the destination thumbnail. 'png' or 'jpeg'. Defaults to null(auto).
  /// [quality] only applies to 'jpeg' format. 1-100 (100 best quality).
  Future<bool> getVideoThumbnail(
      {required String srcFile,
      required String destFile,
      required int width,
      required int height,
      required bool keepAspectRatio,
      String? format,
      bool? srcFileUri,
      int? quality}) {
    return FcNativeVideoThumbnailPlatform.instance.getVideoThumbnail(
        srcFile: srcFile,
        destFile: destFile,
        width: width,
        height: height,
        keepAspectRatio: keepAspectRatio,
        format: format,
        srcFileUri: srcFileUri,
        quality: quality);
  }
}
