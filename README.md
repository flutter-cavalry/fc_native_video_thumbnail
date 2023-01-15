# fc_native_video_thumbnail

**Android support is WIP.**

A Flutter plugin for getting video thumbnails with native APIs.

Supported video types:

- Read
  - Platform native videos
- Write (thumbnails)
  - JPEG, PNG

## Usage

```dart
final _plugin = FcNativeVideoThumbnail();

/// Gets a thumbnail from [srcFile] with the given parameters and saves it to [destFile].
/// [srcFile] source image path.
/// [destFile] destination image path.
/// [keepAspectRatio] if true, keeps aspect ratio.
/// [type] specifies image type of destination file. 'png' or 'jpeg'.
/// [quality] only applies for 'jpeg' type, 1-100 (100 best quality).
await _plugin.getThumbnailFile(
          srcFile: srcFile,
          destFile: destFile,
          width: 300,
          height: 300,
          keepAspectRatio: true,
          type: 'jpeg',
          quality: 90)
```
