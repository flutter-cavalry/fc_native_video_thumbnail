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

class MyApp extends StatefulWidget {
  const MyApp({super.key});

  @override
  State<MyApp> createState() => _MyAppState();
}

class _MyAppState extends State<MyApp> {
  String? _destImg;
  String? _err;
  String _imgSizeInfo = '';
  final _plugin = FcNativeVideoThumbnail();

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      home: Scaffold(
        appBar: AppBar(
          title: const Text('Plugin example app'),
        ),
        body: Center(
          child: _destImg == null
              ? Text(_err ?? 'Click on the + button to select a video')
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
      setState(() {
        _err = null;
      });
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
      setState(() {
        _err = err.toString();
      });
    }
  }
}
