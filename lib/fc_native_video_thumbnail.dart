import 'fc_native_video_thumbnail_platform_interface.dart';

class FcNativeVideoThumbnail {
  /// Gets a thumbnail from [srcFile] with the given options and saves it to [destFile].
  ///
  /// [srcFile] source video path or Uri (Only Android supports Uri).
  /// [srcFileUri] If true, [srcFile] is a Uri (Android/iOS/macOS only).
  /// [destFile] destination thumbnail path.
  /// [width] / [height] max dimensions of the destination thumbnail.
  /// Windows doesn't support non-square thumbnail images, only [width] is used in Windows, resulting in a [width]x[width] max thumbnail.
  /// [format] specifies the image format of the destination thumbnail. 'png' or 'jpeg'. Defaults to null(auto).
  /// [quality] only applies to 'jpeg' format. 1-100 (100 best quality). For 'png' the quality is always 100 (lossless PNG).
  ///
  /// Returns if the thumbnail was successfully created.
  Future<bool> getVideoThumbnail(
      {required String srcFile,
      required String destFile,
      required int width,
      required int height,
      String? format,
      bool? srcFileUri,
      int? quality}) {
    if (width <= 0 || height <= 0) {
      throw ArgumentError('width and height must be greater than 0');
    }
    return FcNativeVideoThumbnailPlatform.instance.getVideoThumbnail(
        srcFile: srcFile,
        destFile: destFile,
        width: width,
        height: height,
        format: format,
        srcFileUri: srcFileUri,
        quality: quality);
  }
}
