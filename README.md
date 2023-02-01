[![pub package](https://img.shields.io/pub/v/fc_native_video_thumbnail.svg)](https://pub.dev/packages/fc_native_video_thumbnail)

# fc_native_video_thumbnail

A Flutter plugin for creating video thumbnails via native APIs.

| iOS | Android | macOS | Windows |
| --- | ------- | ----- | ------- |
| ✅  | ✅      | ✅    | ✅      |

## Usage

```dart
  final plugin = FcNativeVideoThumbnail();

  ///
  /// Gets a thumbnail from [srcFile] with the given options and saves it to [destFile].
  ///
  /// [srcFile] source video path.
  /// [destFile] destination thumbnail path.
  /// [width] / [height] max dimensions of the destination thumbnail.
  /// NOTE: Windows doesn't support non-square thumbnail images, only [width] is used in Windows, resulting in a [width]x[width] thumbnail.
  /// [keepAspectRatio] if true, keeps aspect ratio of the destination thumbnail.
  /// NOTE: iOS/macOS only. Defaults to true on other platforms.
  /// [type] specifies the image type of the destination thumbnail. 'png' or 'jpeg'.
  /// [quality] only applies to 'jpeg' type. 1-100 (100 best quality).
  await plugin.getVideoThumbnail(
            srcFile: srcFile,
            destFile: destFile,
            width: 300,
            height: 300,
            keepAspectRatio: true,
            type: 'jpeg',
            quality: 90);
```
