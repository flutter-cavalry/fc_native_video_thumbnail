import 'dart:async';
import 'dart:io';

import 'package:fc_native_video_thumbnail/fc_native_video_thumbnail.dart';
import 'package:file_selector/file_selector.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:image_picker/image_picker.dart';
import 'package:path/path.dart' as p;
import 'package:tmp_path/tmp_path.dart';

void main() {
  runApp(const MyApp());
}

final _plugin = FcNativeVideoThumbnail();

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return const MaterialApp(
      home: MyHome(),
    );
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

  Uint8List? outBytes;
  String? outBytesDimensions;
  String? outBytesError;

  Task(
      {required this.name,
      required this.srcFile,
      required this.width,
      required this.height,
      this.isSrcUri});

  Future<void> run() async {
    await Future.wait([_toFile(), _toBytes()]);
  }

  Future<void> _toFile() async {
    try {
      final destFile = tmpPath() + p.extension(srcFile);
      await _plugin.saveThumbnailToFile(
          srcFile: srcFile,
          destFile: destFile,
          width: width,
          height: height,
          srcFileUri: isSrcUri,
          format: 'jpeg');
      if (await File(destFile).exists()) {
        var imageFile = File(destFile);
        var decodedImage =
            await decodeImageFromList(await imageFile.readAsBytes());
        outFileDimensions =
            'Decoded size: ${decodedImage.width}x${decodedImage.height}';
        outFile = destFile;
      } else {
        outFileError = 'No thumbnail extracted';
      }
    } catch (err) {
      outFileError = err.toString();
    }
  }

  Future<void> _toBytes() async {
    try {
      final bytes = await _plugin.saveThumbnailToBytes(
          srcFile: srcFile,
          width: width,
          height: height,
          srcFileUri: isSrcUri,
          format: 'jpeg');
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
    }
  }
}

class MyHome extends StatefulWidget {
  const MyHome({super.key});

  @override
  State<MyHome> createState() => _MyHomeState();
}

class _MyHomeState extends State<MyHome> {
  final _tasks = <Task>[];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Plugin example app'),
      ),
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
                  onPressed: () => _selectVideo(true),
                  child: const Text('Select video from gallery'),
                ),
              ],
              ElevatedButton(
                onPressed: () => _selectVideo(false),
                child: const Text('Select video from file'),
              ),
              ..._tasks.map((task) {
                return Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  spacing: 8,
                  children: [
                    Text('>>> ${task.name}',
                        style: const TextStyle(
                            fontSize: 16.0, fontWeight: FontWeight.bold)),
                    Text('Out file: ${task.outFile}'),
                    if (task.outFileError != null) ...[
                      Text(task.outFileError!,
                          style: const TextStyle(color: Colors.red)),
                    ],
                    if (task.outFile != null) ...[
                      Text(task.outFileDimensions ?? ''),
                      Image(image: FileImage(File(task.outFile!))),
                    ],
                    Text(
                        'Out bytes: ${task.outBytes != null ? '${task.outBytes!.lengthInBytes} bytes' : 'null'}'),
                    if (task.outBytesError != null) ...[
                      Text(task.outBytesError!,
                          style: const TextStyle(color: Colors.red)),
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

  Future<void> _selectVideo(bool gallery) async {
    try {
      String? srcPath;
      bool srcUri = false;

      if (!gallery) {
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
      });

      final smallVidBytes = await rootBundle.load('res/a.mp4');
      final smallVidPath = '${tmpPath()}_small.mp4';
      await File(smallVidPath).writeAsBytes(smallVidBytes.buffer.asUint8List());

      _tasks.add(Task(
          name: 'Resize to 300x300',
          srcFile: srcPath,
          isSrcUri: srcUri,
          width: 300,
          height: 300));

      // Upscaling task.
      _tasks.add(Task(
          name: 'No upscaling to 1000x1000',
          srcFile: smallVidPath,
          width: 1000,
          height: 1000));

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
