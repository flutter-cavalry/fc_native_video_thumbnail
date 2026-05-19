## 2.2.0

- Add linux support (thanks to [nulkode](https://github.com/nulkode)).
- Remove the default 1.0 sec seek time on macOS and iOS.

## 2.1.0

- Seeking support on more platforms

## 2.0.0

- **Breaking**: we now have 2 APIs:
  - `saveThumbnailToFile` saves the thumbnail to a file path.
  - `saveThumbnailToBytes` returns the thumbnail as a byte array.
- Upgraded plugin and example projects to latest Flutter project structure.
- Added `at` option to specify the time position of the thumbnail in seconds.

## 1.0.0

- First stable version.

## 0.17.2

- Switch to `Dispatchers.Default`.

## 0.17.0

- Add Swift Package Manager support.

## 0.16.1

- Fix param name regression on Darwin and Windows.

## 0.16.0

- Remove from `Looper` to dispatcher.
- Fix -1 is not a valid option on some devices.

## 0.15.0

- Update to gradle 8

## 0.13.0

- Use `generateCGImageAsynchronously` if available.

## 0.12.0

- Reduce memory footprint on Android.

## 0.11.0

- Support `srcFileUri` on iOS and macOS.
- Don't throw when `WTS_E_FAILEDEXTRACTION` is returned on Windows.

## 0.10.0

- Simply API
- Update Android project

## 0.9.0

- Allow resizing with only width or height.

## 0.8.0

- Fix aspect issues on iOS.

## 0.7.0

- Fix various issues in `FCImage`.

## 0.6.0

- Use a shared project between iOS and macOS.

## 0.5.2

- Fix various issues on example project.

## 0.5.0

- Add support for Android Uri.

## 0.4.0

- Rename `type` to `format`.

## 0.3.0

- Update to Flutter 3.7.

## 0.1.0

- Added Windows and Android support.

## 0.0.1

- Initial release.
