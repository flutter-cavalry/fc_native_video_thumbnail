import 'package:flutter_test/flutter_test.dart';
import 'package:fc_native_video_thumbnail/fc_native_video_thumbnail.dart';
import 'package:fc_native_video_thumbnail/fc_native_video_thumbnail_platform_interface.dart';
import 'package:fc_native_video_thumbnail/fc_native_video_thumbnail_method_channel.dart';
import 'package:plugin_platform_interface/plugin_platform_interface.dart';

class MockFcNativeVideoThumbnailPlatform
    with MockPlatformInterfaceMixin
    implements FcNativeVideoThumbnailPlatform {

  @override
  Future<String?> getPlatformVersion() => Future.value('42');
}

void main() {
  final FcNativeVideoThumbnailPlatform initialPlatform = FcNativeVideoThumbnailPlatform.instance;

  test('$MethodChannelFcNativeVideoThumbnail is the default instance', () {
    expect(initialPlatform, isInstanceOf<MethodChannelFcNativeVideoThumbnail>());
  });

  test('getPlatformVersion', () async {
    FcNativeVideoThumbnail fcNativeVideoThumbnailPlugin = FcNativeVideoThumbnail();
    MockFcNativeVideoThumbnailPlatform fakePlatform = MockFcNativeVideoThumbnailPlatform();
    FcNativeVideoThumbnailPlatform.instance = fakePlatform;

    expect(await fcNativeVideoThumbnailPlugin.getPlatformVersion(), '42');
  });
}
