# fc_native_video_thumbnail

[![pub package](https://img.shields.io/pub/v/fc_native_video_thumbnail.svg)](https://pub.dev/packages/fc_native_video_thumbnail)

A Flutter plugin to create video thumbnails via native APIs.

|               | iOS | Android | macOS | Windows | Linux |
| ------------- | --- | ------- | ----- | ------- | ----- |
| Source (Path) | ✅  | ✅      | ✅    | ✅      | ✅    |
| Source (Uri)  | ✅  | ✅      | ✅    | -       | -     |
| Seeking       | ✅  | ⚠️      | ✅    | -       | ✅    |

⚠️ Android seeking is only supported when the source file is a Uri.

Linux requires `libavformat`, `libavcodec`, `libavutil`, `libswscale` (FFmpeg) and `libjpeg` installed on the system.

## Usage

- `saveThumbnailToFile` saves the thumbnail to a file path.
  - Returns true if thumbnail was successfully created. Or false if thumbnail is not available.
  - Throws if error happens during thumbnail generation.
- `saveThumbnailToBytes` returns the thumbnail as a byte array.
  - Returns the thumbnail as bytes if successfully created. Or null if thumbnail is not available.
  - Throws if error happens during thumbnail generation.

Example:

```dart
final plugin = FcNativeVideoThumbnail();

try {
  /// Extracts a thumbnail from [srcFile] with the given options and saves it to [destFile].
  ///
  /// [srcFile] source video path or Uri (See [srcFileUri]).
  /// [srcFileUri] If true, [srcFile] is a Uri (Android/iOS/macOS only).
  /// [destFile] thumbnail save path.
  /// [width] / [height] max dimensions of the thumbnail image.
  ///   Windows doesn't support non-square thumbnail images, only [width] is used in Windows, resulting in a [width]x[width] max thumbnail.
  /// [format] only "jpeg" is supported. Defaults to "jpeg".
  /// [quality] a fallback value for the quality of the thumbnail image (0-100). May be ignored by the platform.
  /// [at] the time position of the thumbnail.
  ///   Not supported on Windows, or Android if source file is a path.
  final generated = await plugin.saveThumbnailToFile(
            srcFile: srcFile,
            destFile: destFile,
            width: 300,
            height: 300,
            quality: 90);

  // `saveThumbnailToBytes` has the same options as `saveThumbnailToFile` except `destFile`.
  final thumbnailBytes = await plugin.saveThumbnailToBytes(
            srcFile: srcFile,
            width: 300,
            height: 300,
            quality: 90);
} catch (err) {
  // Handle platform errors.
}
```

### Seeking to a specific time position

```dart
await plugin.saveThumbnailToFile(
            srcFile: srcFile,
            destFile: destFile,
            width: 300,
            height: 300,
            quality: 90,
            // Seek to 13 seconds to create the thumbnail.
            at: FcVideoThumbnailTime(13, .seconds),
// Supported units:
// .seconds
// .milliseconds
// .microseconds
);
```
