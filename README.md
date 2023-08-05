[![pub package](https://img.shields.io/pub/v/fc_native_video_thumbnail.svg)](https://pub.dev/packages/fc_native_video_thumbnail)

# fc_native_video_thumbnail

A Flutter plugin for creating video thumbnails via native APIs.

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
  /// [srcFile] source video path or Uri (Android only, set [srcFileUri] to true if this is a Uri).
  /// [srcFileUri] if true, [srcFile] is a Uri, otherwise it's a file path. Defaults to false. Android only.
  /// [destFile] destination thumbnail path.
  /// [width] / [height] max dimensions of the destination thumbnail.
  /// Windows doesn't support non-square thumbnail images, only [width] is used in Windows, resulting in a [width]x[width] thumbnail.
  /// [keepAspectRatio] if true, keeps aspect ratio of the destination thumbnail.
  /// iOS/macOS only. Defaults to true on other platforms.
  /// [format] specifies the image format of the destination thumbnail. 'png' or 'jpeg'. Defaults to null(auto).
  /// [quality] only applies to 'jpeg' format. 1-100 (100 best quality).
  final thumbnailGenerated = await plugin.getVideoThumbnail(
            srcFile: srcFile,
            destFile: destFile,
            width: 300,
            height: 300,
            keepAspectRatio: true,
            format: 'jpeg',
            quality: 90);
} catch (err) {
  // Handle platform errors.
}
```
