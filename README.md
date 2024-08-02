# fc_native_video_thumbnail

[![pub package](https://img.shields.io/pub/v/fc_native_video_thumbnail.svg)](https://pub.dev/packages/fc_native_video_thumbnail)

A Flutter plugin to create video thumbnails via native APIs.

|      | iOS | Android | macOS | Windows |
| ---- | --- | ------- | ----- | ------- |
| Path | ✅  | ✅      | ✅    | ✅      |
| Uri  | -   | ✅      | -     | -       |

## Usage

```dart
final plugin = FcNativeVideoThumbnail();

try {
  /// Gets a thumbnail from [srcFile] with the given options and saves it to [destFile].
  ///
  /// [srcFile] source video path or Uri (Only Android supports Uri).
  /// [srcFileUri] (Android only) if true, [srcFile] is a Uri.
  /// [destFile] destination thumbnail path.
  /// [width] / [height] max dimensions of the destination thumbnail.
  /// Windows doesn't support non-square thumbnail images, only [width] is used in Windows, resulting in a [width]x[width] max thumbnail.
  /// [format] specifies the image format of the destination thumbnail. 'png' or 'jpeg'. Defaults to null(auto).
  /// [quality] only applies to 'jpeg' format. 1-100 (100 best quality). For 'png' the quality is always 100 (lossless PNG).
  ///
  /// Returns if the thumbnail was successfully created.
  final thumbnailGenerated = await plugin.getVideoThumbnail(
            srcFile: srcFile,
            destFile: destFile,
            width: 300,
            height: 300,
            format: 'jpeg',
            quality: 90);
} catch (err) {
  // Handle platform errors.
}
```
