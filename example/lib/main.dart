import 'dart:io';

import 'package:fc_native_video_thumbnail/fc_native_video_thumbnail.dart';
import 'package:file_picker/file_picker.dart';
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
        onPressed: _selectImage,
        tooltip: 'Select an image',
        child: const Icon(Icons.add),
      ),
    );
  }

  Future<void> _selectImage() async {
    try {
      var result = await FilePicker.platform.pickFiles();
      if (result == null) {
        return;
      }
      var src = result.files.single.path!;
      var dest = tmpPath() + p.extension(src);
      await _plugin.getVideoThumbnail(
          srcFile: src,
          destFile: dest,
          width: 300,
          height: 300,
          keepAspectRatio: true,
          type: 'jpeg');
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
