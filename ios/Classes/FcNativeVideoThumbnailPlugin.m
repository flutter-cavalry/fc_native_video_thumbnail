#import "FcNativeVideoThumbnailPlugin.h"
#if __has_include(<fc_native_video_thumbnail/fc_native_video_thumbnail-Swift.h>)
#import <fc_native_video_thumbnail/fc_native_video_thumbnail-Swift.h>
#else
// Support project import fallback if the generated compatibility header
// is not copied when this plugin is created as a library.
// https://forums.swift.org/t/swift-static-libraries-dont-copy-generated-objective-c-header/19816
#import "fc_native_video_thumbnail-Swift.h"
#endif

@implementation FcNativeVideoThumbnailPlugin
+ (void)registerWithRegistrar:(NSObject<FlutterPluginRegistrar>*)registrar {
  [SwiftFcNativeVideoThumbnailPlugin registerWithRegistrar:registrar];
}
@end
