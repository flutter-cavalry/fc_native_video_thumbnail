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

class MyHome extends StatefulWidget {
  const MyHome({super.key});

  @override
  State<MyHome> createState() => _MyHomeState();
}

class _MyHomeState extends State<MyHome> {
  String? _destImg;
  String _imgSizeInfo = '';
  final _plugin = FcNativeVideoThumbnail();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Plugin example app'),
      ),
      body: Center(
        child: _destImg == null
            ? const Text('Click on the + button to select a video')
            : Column(
                children: [
                  SelectableText(_destImg!),
                  Text(_imgSizeInfo),
                  Image(image: FileImage(File(_destImg!)))
                ],
              ),
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: _selectVideo,
        tooltip: 'Select an image',
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
      var dest = tmpPath() + p.extension(src.name);
      final hasThumbnail = await _plugin.getVideoThumbnail(
          srcFile: src.path,
          destFile: dest,
          width: 300,
          height: 300,
          srcFileUri: Platform.isAndroid,
          keepAspectRatio: true);
      if (!hasThumbnail) {
        await _showErrorAlert(context, 'No thumbnail generated');
        return;
      }
      var imageFile = File(dest);
      var decodedImage = await decodeImageFromList(imageFile.readAsBytesSync());
      setState(() {
        _destImg = dest;
        _imgSizeInfo =
            'Decoded size: ${decodedImage.width}x${decodedImage.height}';
      });
    } catch (err) {
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
