# fc_native_video_thumbnail

[![pub package](https://img.shields.io/pub/v/fc_native_video_thumbnail.svg)](https://pub.dev/packages/fc_native_video_thumbnail)

A Flutter plugin for generating video thumbnails with native platform APIs.

|               | iOS | Android | macOS | Windows | Linux |
| ------------- | --- | ------- | ----- | ------- | ----- |
| Source (Path) | ✅  | ✅      | ✅    | ✅      | ✅    |
| Source (Uri)  | ✅  | ✅      | ✅    | -       | -     |
| Seeking       | ✅  | ✅      | ✅    | -       | ✅    |

Linux requires FFmpeg (`libavformat`, `libavcodec`, `libavutil`, and `libswscale`) and `libjpeg` to be installed on the system.

## Usage

- `saveThumbnailToFile` writes the thumbnail to a file. It returns `true` when a thumbnail is created and `false` when none is available. It throws if generation fails.
- `saveThumbnailToBytes` returns the thumbnail as bytes, or `null` when none is available. It throws if generation fails.

Example:

```dart
final plugin = FcNativeVideoThumbnail();

try {
  final generated = await plugin.saveThumbnailToFile(
    srcFile: srcFile,
    destFile: destFile,
    width: 300,
    height: 300,
    quality: 90,
  );

  final thumbnailBytes = await plugin.saveThumbnailToBytes(
    srcFile: srcFile,
    width: 300,
    height: 300,
    quality: 90,
  );
} catch (err) {
  // Handle thumbnail generation errors.
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
  at: FcVideoThumbnailTime(13, .seconds),
);
```

Supported time units are `.seconds`, `.milliseconds`, and `.microseconds`.
