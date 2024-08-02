import 'dart:io';

import 'package:fc_native_video_thumbnail/fc_native_video_thumbnail.dart';
import 'package:file_selector/file_selector.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'dart:async';

import 'package:tmp_path/tmp_path.dart';
import 'package:path/path.dart' as p;

void main() {
  runApp(const MyApp());
}

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

  String? destFile;
  String? destImgSize;
  String? error;

  Task(
      {required this.name,
      required this.srcFile,
      required this.width,
      required this.height,
      this.isSrcUri});

  Future<void> run() async {
    try {
      var plugin = FcNativeVideoThumbnail();
      final destFile = tmpPath() + p.extension(srcFile);
      await plugin.getVideoThumbnail(
          srcFile: srcFile,
          destFile: destFile,
          width: width,
          height: height,
          srcFileUri: isSrcUri,
          format: 'jpeg');
      if (await File(destFile).exists()) {
        var imageFile = File(destFile);
        var decodedImage =
            await decodeImageFromList(imageFile.readAsBytesSync());
        destImgSize =
            'Decoded size: ${decodedImage.width}x${decodedImage.height}';
        this.destFile = destFile;
      } else {
        error = 'No thumbnail extracted';
      }
    } catch (err) {
      error = err.toString();
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
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text('Click on the + button to select a video'),
              const SizedBox(height: 8.0),
              ..._tasks.map((task) {
                return Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const SizedBox(height: 8.0),
                    Text('>>> ${task.name}',
                        style: const TextStyle(
                            fontSize: 16.0, fontWeight: FontWeight.bold)),
                    if (task.error != null) ...[
                      const SizedBox(height: 8.0),
                      Text(task.error!,
                          style: const TextStyle(color: Colors.red)),
                    ],
                    if (task.destFile != null) ...[
                      const SizedBox(height: 8.0),
                      Text('Dest image: ${task.destFile}'),
                      const SizedBox(height: 8.0),
                      Text(task.destImgSize ?? ''),
                      const SizedBox(height: 8.0),
                      Image(image: FileImage(File(task.destFile!))),
                    ],
                  ],
                );
              }),
            ],
          ),
        ),
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: _selectVideo,
        tooltip: 'Select an video',
        child: const Icon(Icons.add),
      ),
    );
  }

  Future<void> _selectVideo() async {
    try {
      final List<XTypeGroup> acceptedTypeGroups = Platform.isIOS
          ? [
              const XTypeGroup(uniformTypeIdentifiers: ['public.item'])
            ]
          : [];
      var src = await openFile(acceptedTypeGroups: acceptedTypeGroups);
      if (src == null) {
        return;
      }
      final srcPath = src.path;
      setState(() {
        _tasks.clear();
      });

      final smallVidBytes = await rootBundle.load('res/a.mp4');
      final smallVidPath = '${tmpPath()}_small.mp4';
      await File(smallVidPath).writeAsBytes(smallVidBytes.buffer.asUint8List());

      _tasks.add(Task(
          name: 'Resize to 300x300',
          srcFile: srcPath,
          width: 300,
          height: 300));

      if (Platform.isAndroid) {
        _tasks.add(Task(
            name: '(URI) Resize to 300x300',
            isSrcUri: true,
            srcFile: srcPath,
            width: 300,
            height: 300));
      }

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
