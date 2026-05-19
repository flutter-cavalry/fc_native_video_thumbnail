#include <flutter_linux/flutter_linux.h>
#include <gmock/gmock.h>
#include <gtest/gtest.h>

#include "include/fc_native_video_thumbnail/fc_native_video_thumbnail_plugin.h"

namespace fc_native_video_thumbnail {
namespace test {

TEST(FcNativeVideoThumbnailPlugin, PluginTypeIsValid) {
  GType type = fc_native_video_thumbnail_plugin_get_type();
  ASSERT_NE(type, G_TYPE_INVALID);
  ASSERT_TRUE(g_type_is_a(type, G_TYPE_OBJECT));
}

}  // namespace test
}  // namespace fc_native_video_thumbnail
