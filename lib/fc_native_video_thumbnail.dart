import 'dart:typed_data';

import 'fc_native_video_thumbnail_platform_interface.dart';

class FcNativeVideoThumbnail {
  /// Generates a thumbnail from [srcFile] and saves it to [destFile].
  ///
  /// [srcFile] is the source video path or URI. Set [srcFileUri] to `true` when
  /// passing a URI; URI sources are supported on Android, iOS, and macOS.
  /// [destFile] is the path where the thumbnail will be saved.
  /// [width] and [height] are the maximum thumbnail dimensions. Windows uses
  /// [width] for both dimensions and returns a square thumbnail.
  /// [format] is currently limited to `jpeg` and defaults to `jpeg`.
  /// [quality] is the JPEG quality from 0 to 100; some platforms may ignore it.
  /// [at] is the time position to capture. Seeking is not supported on Windows.
  ///
  /// Returns `true` when a thumbnail is created, or `false` when none is
  /// available. Throws if thumbnail generation fails.
  Future<bool> saveThumbnailToFile({
    required String srcFile,
    required String destFile,
    required int width,
    required int height,
    String? format,
    bool? srcFileUri,
    FcVideoThumbnailTime? at,
    int? quality,
  }) {
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
      quality: quality,
    );
  }

  /// Generates a thumbnail from [srcFile] and returns it as JPEG bytes.
  ///
  /// [srcFile] is the source video path or URI. Set [srcFileUri] to `true` when
  /// passing a URI; URI sources are supported on Android, iOS, and macOS.
  /// [width] and [height] are the maximum thumbnail dimensions. Windows uses
  /// [width] for both dimensions and returns a square thumbnail.
  /// [format] is currently limited to `jpeg` and defaults to `jpeg`.
  /// [quality] is the JPEG quality from 0 to 100; some platforms may ignore it.
  /// [at] is the time position to capture. Seeking is not supported on Windows.
  ///
  /// Returns the thumbnail bytes, or `null` when no thumbnail is available.
  /// Throws if thumbnail generation fails.
  Future<Uint8List?> saveThumbnailToBytes({
    required String srcFile,
    required int width,
    required int height,
    String? format,
    bool? srcFileUri,
    FcVideoThumbnailTime? at,
    int? quality,
  }) {
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
      quality: quality,
    );
  }
}
