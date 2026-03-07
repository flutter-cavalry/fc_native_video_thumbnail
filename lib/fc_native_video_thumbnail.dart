import 'dart:typed_data';

import 'fc_native_video_thumbnail_platform_interface.dart';

class FcNativeVideoThumbnail {
  /// Extracts a thumbnail from [srcFile] with the given options and saves it to [destFile].
  ///
  /// [srcFile] source video path or Uri (See [srcFileUri]).
  /// [srcFileUri] If true, [srcFile] is a Uri (Android/iOS/macOS only).
  /// [destFile] destination thumbnail path.
  /// [width] / [height] max dimensions of the destination thumbnail.
  ///   Windows doesn't support non-square thumbnail images, only [width] is used in Windows, resulting in a [width]x[width] max thumbnail.
  /// [format] only "jpeg" is supported. Defaults to "jpeg".
  /// [quality] a fallback value for the quality of the thumbnail image (0-100). May be ignored by the platform.
  /// [at] the time position of the thumbnail in seconds.
  ///   Defaults to 1 on iOS/macOS.
  ///   Ignored on Windows/Android.
  ///
  /// Returns true if thumbnail was successfully created. Or false if thumbnail is not available.
  /// Throws if error happens during thumbnail generation.
  Future<bool> saveThumbnailToFile(
      {required String srcFile,
      required String destFile,
      required int width,
      required int height,
      String? format,
      bool? srcFileUri,
      double? at,
      int? quality}) {
    if (width <= 0 || height <= 0) {
      throw ArgumentError('width and height must be greater than 0');
    }
    return FcNativeVideoThumbnailPlatform.instance.saveThumbnailToFile(
        srcFile: srcFile,
        destFile: destFile,
        width: width,
        height: height,
        format: format,
        srcFileUri: srcFileUri,
        at: at,
        quality: quality);
  }

  /// Extracts a thumbnail from [srcFile] with the given options and returns it as bytes.
  ///
  /// [srcFile] source video path or Uri (See [srcFileUri]).
  /// [srcFileUri] If true, [srcFile] is a Uri (Android/iOS/macOS only).
  /// [width] / [height] max dimensions of the destination thumbnail.
  /// Windows doesn't support non-square thumbnail images, only [width] is used in Windows, resulting in a [width]x[width] max thumbnail.
  /// [format] only "jpeg" is supported. Defaults to "jpeg".
  /// [quality] a fallback value for the quality of the thumbnail image (0-100). May be ignored by the platform.
  /// [at] the time position of the thumbnail in seconds.
  ///   Defaults to 1 on iOS/macOS.
  ///   Ignored on Windows/Android.
  ///
  /// Returns the thumbnail as bytes if successfully created. Or null if thumbnail is not available.
  /// Throws if error happens during thumbnail generation.
  Future<Uint8List?> saveThumbnailToBytes(
      {required String srcFile,
      required int width,
      required int height,
      String? format,
      bool? srcFileUri,
      double? at,
      int? quality}) {
    if (width <= 0 || height <= 0) {
      throw ArgumentError('width and height must be greater than 0');
    }
    return FcNativeVideoThumbnailPlatform.instance.saveThumbnailToBytes(
        srcFile: srcFile,
        width: width,
        height: height,
        format: format,
        srcFileUri: srcFileUri,
        at: at,
        quality: quality);
  }
}
