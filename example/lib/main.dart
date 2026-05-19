import 'dart:async';
import 'dart:io';

import 'package:fc_native_video_thumbnail/fc_native_video_thumbnail.dart';
import 'package:fc_native_video_thumbnail/fc_native_video_thumbnail_platform_interface.dart';
import 'package:file_selector/file_selector.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:image_picker/image_picker.dart';
import 'package:path/path.dart' as p;
import 'package:saf_util/saf_util.dart';
import 'package:tmp_path/tmp_path.dart';

void main() {
  runApp(const MyApp());
}

final _plugin = FcNativeVideoThumbnail();
final _safUtil = SafUtil();

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return const MaterialApp(home: MyHome());
  }
}

class Task {
  final String name;
  final String srcFile;
  final int width;
  final int height;
  final bool? isSrcUri;

  String? outFile;
  String? outFileDimensions;
  String? outFileError;
  Duration? outFileTime;

  Uint8List? outBytes;
  String? outBytesDimensions;
  String? outBytesError;
  Duration? outBytesTime;

  Task({
    required this.name,
    required this.srcFile,
    required this.width,
    required this.height,
    this.isSrcUri,
  });

  Future<void> run() async {
    await Future.wait([_toFile(), _toBytes()]);
  }

  Future<void> _toFile() async {
    final sw = Stopwatch()..start();
    try {
      final destFile = tmpPath() + p.extension(srcFile);
      await _plugin.saveThumbnailToFile(
        srcFile: srcFile,
        destFile: destFile,
        width: width,
        height: height,
        srcFileUri: isSrcUri,
        format: 'jpeg',
      );
      if (await File(destFile).exists()) {
        var imageFile = File(destFile);
        var decodedImage = await decodeImageFromList(
          await imageFile.readAsBytes(),
        );
        outFileDimensions =
            'Decoded size: ${decodedImage.width}x${decodedImage.height}';
        outFile = destFile;
      } else {
        outFileError = 'No thumbnail extracted';
      }
    } catch (err) {
      outFileError = err.toString();
    } finally {
      sw.stop();
      outFileTime = sw.elapsed;
    }
  }

  Future<void> _toBytes() async {
    final sw = Stopwatch()..start();
    try {
      final bytes = await _plugin.saveThumbnailToBytes(
        srcFile: srcFile,
        width: width,
        height: height,
        srcFileUri: isSrcUri,
        format: 'jpeg',
      );
      if (bytes != null) {
        var decodedImage = await decodeImageFromList(bytes);
        outBytesDimensions =
            'Decoded size: ${decodedImage.width}x${decodedImage.height}';
        outBytes = bytes;
      } else {
        outBytesError = 'No thumbnail extracted';
      }
    } catch (err) {
      outBytesError = err.toString();
    } finally {
      sw.stop();
      outBytesTime = sw.elapsed;
    }
  }
}

class MyHome extends StatefulWidget {
  const MyHome({super.key});

  @override
  State<MyHome> createState() => _MyHomeState();
}

enum _VideoSrc { gallery, files, uri }

class _MyHomeState extends State<MyHome> {
  final _tasks = <Task>[];
  String? _selectedVideoPath;
  bool? _isSrcUri;
  double _seekPosition = 0.0;
  double _maxDuration = 60.0;
  Timer? _debounceTimer;
  Uint8List? _seekThumbnail;
  String? _seekThumbnailError;
  bool _seeking = false;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Plugin example app')),
      body: SingleChildScrollView(
        child: Padding(
          padding: const EdgeInsets.all(10),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            mainAxisSize: MainAxisSize.min,
            spacing: 8,
            children: [
              if (Platform.isAndroid || Platform.isIOS) ...[
                ElevatedButton(
                  onPressed: () => _selectVideo(.gallery),
                  child: const Text('Select video from gallery'),
                ),
              ],
              ElevatedButton(
                onPressed: () => _selectVideo(.files),
                child: const Text('Select video from files'),
              ),
              if (Platform.isAndroid)
                ElevatedButton(
                  onPressed: () => _selectVideo(.uri),
                  child: const Text('Select video from SAF (URI)'),
                ),
              if (!Platform.isWindows && _selectedVideoPath != null) ...[
                const SizedBox(height: 8),
                Text(
                  'Seek to: ${_seekPosition.toStringAsFixed(1)}s',
                  style: const TextStyle(fontWeight: FontWeight.bold),
                ),
                Slider(
                  value: _seekPosition,
                  min: 0,
                  max: _maxDuration,
                  divisions: _maxDuration.toInt() * 10,
                  label: '${_seekPosition.toStringAsFixed(1)}s',
                  onChanged: (value) {
                    setState(() {
                      _seekPosition = value;
                    });
                    _debounceTimer?.cancel();
                    _debounceTimer = Timer(const Duration(milliseconds: 100), () {
                      _generateSeekThumbnail();
                    });
                  },
                ),
                if (_seeking)
                  const SizedBox(
                    width: 300,
                    height: 200,
                    child: Center(child: CircularProgressIndicator()),
                  ),
                if (_seekThumbnail != null)
                  SizedBox(
                    width: 300,
                    height: 200,
                    child: Image.memory(_seekThumbnail!),
                  ),
                if (_seekThumbnailError != null)
                  Text(_seekThumbnailError!, style: const TextStyle(color: Colors.red)),
              ],
              const SizedBox(height: 8),
              ..._tasks.map((task) {
                return Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  spacing: 8,
                  children: [
                    Text(
                      '>>> ${task.name}',
                      style: const TextStyle(
                        fontSize: 16.0,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    Text('Out file: ${task.outFile}'),
                    if (task.outFileTime != null)
                      Text('Time: ${task.outFileTime!.inMilliseconds}ms'),
                    if (task.outFileError != null) ...[
                      Text(
                        task.outFileError!,
                        style: const TextStyle(color: Colors.red),
                      ),
                    ],
                    if (task.outFile != null) ...[
                      Text(task.outFileDimensions ?? ''),
                      Image(image: FileImage(File(task.outFile!))),
                    ],
                    Text(
                      'Out bytes: ${task.outBytes != null ? '${task.outBytes!.lengthInBytes} bytes' : 'null'}',
                    ),
                    if (task.outBytesTime != null)
                      Text('Time: ${task.outBytesTime!.inMilliseconds}ms'),
                    if (task.outBytesError != null) ...[
                      Text(
                        task.outBytesError!,
                        style: const TextStyle(color: Colors.red),
                      ),
                    ],
                    if (task.outBytes != null) ...[
                      Text(task.outBytesDimensions ?? ''),
                      Image.memory(task.outBytes!),
                    ],
                  ],
                );
              }),
            ],
          ),
        ),
      ),
    );
  }

  Future<void> _selectVideo(_VideoSrc src) async {
    try {
      String? srcPath;

      if (src == _VideoSrc.uri) {
        if (Platform.isAndroid) {
          final doc = await _safUtil.pickFile();
          if (doc == null) {
            return;
          }
          srcPath = doc.uri;
        } else {
          throw Exception('Should not reach here');
        }
      } else if (src == _VideoSrc.files) {
        var src = await openFile();
        if (src == null) {
          return;
        }
        srcPath = src.path;
      } else {
        final picker = ImagePicker();
        final xfile = await picker.pickVideo(source: ImageSource.gallery);
        if (xfile == null) {
          return;
        }
        srcPath = xfile.path;
      }

      setState(() {
        _tasks.clear();
        _selectedVideoPath = srcPath;
        _isSrcUri = src == _VideoSrc.uri ? true : null;
        _seekPosition = 0.0;
        _seekThumbnail = null;
        _seekThumbnailError = null;
      });

      final smallVidBytes = await rootBundle.load('res/a.mp4');
      final smallVidPath = '${tmpPath()}_small.mp4';
      await File(smallVidPath).writeAsBytes(smallVidBytes.buffer.asUint8List());

      _tasks.add(
        Task(
          name: 'Resize to 300x300',
          srcFile: srcPath,
          isSrcUri: src == _VideoSrc.uri ? true : null,
          width: 300,
          height: 300,
        ),
      );

      // Upscaling task.
      _tasks.add(
        Task(
          name: 'No upscaling to 1000x1000',
          srcFile: smallVidPath,
          width: 1000,
          height: 1000,
        ),
      );

      await Future.forEach(_tasks, (Task task) async {
        await task.run();
        setState(() {});
      });
    } catch (err) {
      if (!mounted) {
        return;
      }
      await _showErrorAlert(context, err.toString());
    }
  }

  Future<void> _generateSeekThumbnail() async {
    if (_selectedVideoPath == null) return;
    setState(() {
      _seeking = true;
      _seekThumbnail = null;
      _seekThumbnailError = null;
    });
    try {
      final bytes = await _plugin.saveThumbnailToBytes(
        srcFile: _selectedVideoPath!,
        width: 300,
        height: 300,
        srcFileUri: _isSrcUri,
        at: FcVideoThumbnailTime(
          (_seekPosition * 1e6).toInt(),
          FcVideoThumbnailTimeUnit.microseconds,
        ),
      );
      if (bytes != null) {
        setState(() {
          _seekThumbnail = bytes;
        });
      } else {
        setState(() {
          _seekThumbnailError = 'No thumbnail at this position';
        });
      }
    } catch (err) {
      setState(() {
        _seekThumbnailError = err.toString();
      });
    } finally {
      setState(() {
        _seeking = false;
      });
    }
  }

  Future<void> _showErrorAlert(BuildContext context, String msg) async {
    return showDialog<void>(
      context: context,
      builder: (BuildContext context) => AlertDialog(
        title: const SelectableText('Error'),
        content: SelectableText(msg),
        actions: <Widget>[
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('OK'),
          ),
        ],
      ),
    );
  }
}
