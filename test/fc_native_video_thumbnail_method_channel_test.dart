import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:fc_native_video_thumbnail/fc_native_video_thumbnail_method_channel.dart';

void main() {
  MethodChannelFcNativeVideoThumbnail platform = MethodChannelFcNativeVideoThumbnail();
  const MethodChannel channel = MethodChannel('fc_native_video_thumbnail');

  TestWidgetsFlutterBinding.ensureInitialized();

  setUp(() {
    channel.setMockMethodCallHandler((MethodCall methodCall) async {
      return '42';
    });
  });

  tearDown(() {
    channel.setMockMethodCallHandler(null);
  });

  test('getPlatformVersion', () async {
    expect(await platform.getPlatformVersion(), '42');
  });
}
