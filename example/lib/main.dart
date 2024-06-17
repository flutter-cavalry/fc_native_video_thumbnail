import 'dart:io';

import 'package:fc_native_video_thumbnail/fc_native_video_thumbnail.dart';
import 'package:file_selector/file_selector.dart';
import 'package:flutter/material.dart';
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
  final bool keepAspectRatio;

  String? destFile;
  String? destImgSize;
  String? error;

  Task(
      {required this.name,
      required this.srcFile,
      required this.width,
      required this.height,
      required this.keepAspectRatio});

  Future<void> run() async {
    try {
      var plugin = FcNativeVideoThumbnail();
      final destFile = tmpPath() + p.extension(srcFile);
      await plugin.getVideoThumbnail(
          srcFile: srcFile,
          destFile: destFile,
          width: width,
          height: height,
          keepAspectRatio: keepAspectRatio,
          srcFileUri: Platform.isAndroid,
          format: 'jpeg');
      this.destFile = destFile;
      var imageFile = File(destFile);
      var decodedImage = await decodeImageFromList(imageFile.readAsBytesSync());
      destImgSize =
          'Decoded size: ${decodedImage.width}x${decodedImage.height}';
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

      _tasks.add(Task(
          name: 'Resize to 300x300 (keepAspectRatio: true)',
          srcFile: srcPath,
          width: 300,
          height: 300,
          keepAspectRatio: true));
      _tasks.add(Task(
          name: 'Resize to 300x300 (keepAspectRatio: false)',
          srcFile: srcPath,
          width: 300,
          height: 300,
          keepAspectRatio: false));
      _tasks.add(Task(
          name: 'Resize to 300x',
          srcFile: srcPath,
          width: 300,
          height: -1,
          keepAspectRatio: true));
      _tasks.add(Task(
          name: 'Resize to x300',
          srcFile: srcPath,
          width: -1,
          height: 300,
          keepAspectRatio: true));

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
