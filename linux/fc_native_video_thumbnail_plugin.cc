#include "include/fc_native_video_thumbnail/fc_native_video_thumbnail_plugin.h"

#include <flutter_linux/flutter_linux.h>
#include <gio/gio.h>
#include <gtk/gtk.h>

#include <csetjmp>
#include <cstring>
#include <vector>

extern "C" {
#include <libavcodec/avcodec.h>
#include <libavformat/avformat.h>
#include <libavutil/imgutils.h>
#include <libavutil/opt.h>
#include <libswscale/swscale.h>
}
#include <jpeglib.h>

#include "fc_native_video_thumbnail_plugin_private.h"

#define FC_NATIVE_VIDEO_THUMBNAIL_PLUGIN(obj) \
  (G_TYPE_CHECK_INSTANCE_CAST((obj), fc_native_video_thumbnail_plugin_get_type(), \
                              FcNativeVideoThumbnailPlugin))

struct _FcNativeVideoThumbnailPlugin {
  GObject parent_instance;
};

G_DEFINE_TYPE(FcNativeVideoThumbnailPlugin, fc_native_video_thumbnail_plugin, g_object_get_type())

static const char* kErrorInvalidArgs = "InvalidArguments";
static const char* kErrorPluginError = "PluginError";

static FlMethodResponse* make_success_bool(bool value) {
  return FL_METHOD_RESPONSE(fl_method_success_response_new(fl_value_new_bool(value)));
}

static FlMethodResponse* make_success_bytes(const uint8_t* data, size_t len) {
  g_autoptr(FlValue) result = fl_value_new_uint8_list(data, len);
  return FL_METHOD_RESPONSE(fl_method_success_response_new(result));
}

static FlMethodResponse* make_error(const char* code, const char* message) {
  return FL_METHOD_RESPONSE(fl_method_error_response_new(code, message, nullptr));
}

static FlMethodResponse* make_null_result() {
  return FL_METHOD_RESPONSE(fl_method_success_response_new(fl_value_new_null()));
}

struct my_jpeg_error_mgr {
  struct jpeg_error_mgr pub;
  jmp_buf setjmp_buffer;
};

static void my_jpeg_error_exit(j_common_ptr cinfo) {
  struct my_jpeg_error_mgr* myerr = (struct my_jpeg_error_mgr*)cinfo->err;
  longjmp(myerr->setjmp_buffer, 1);
}

static int encode_jpeg_to_buffer(const uint8_t* rgb_data,
                                  int width,
                                  int height,
                                  int quality,
                                  uint8_t** out_buffer,
                                  unsigned long* out_size) {
  struct jpeg_compress_struct cinfo;
  struct my_jpeg_error_mgr jerr;
  jpeg_create_compress(&cinfo);
  cinfo.err = jpeg_std_error(&jerr.pub);
  jerr.pub.error_exit = my_jpeg_error_exit;
  if (setjmp(jerr.setjmp_buffer)) {
    jpeg_destroy_compress(&cinfo);
    return -1;
  }

  uint8_t* buf = nullptr;
  unsigned long buf_size = 0;
  jpeg_mem_dest(&cinfo, &buf, &buf_size);

  cinfo.image_width = width;
  cinfo.image_height = height;
  cinfo.input_components = 3;
  cinfo.in_color_space = JCS_RGB;

  jpeg_set_defaults(&cinfo);
  jpeg_set_quality(&cinfo, quality, TRUE);

  jpeg_start_compress(&cinfo, TRUE);

  JSAMPROW row_pointer[1];
  int row_stride = width * 3;
  while (cinfo.next_scanline < cinfo.image_height) {
    row_pointer[0] = const_cast<JSAMPROW>(rgb_data + cinfo.next_scanline * row_stride);
    jpeg_write_scanlines(&cinfo, row_pointer, 1);
  }

  jpeg_finish_compress(&cinfo);
  jpeg_destroy_compress(&cinfo);

  *out_buffer = buf;
  *out_size = buf_size;
  return 0;
}

static int extract_thumbnail(const char* src_file,
                              int max_width,
                              int max_height,
                              int quality,
                              int64_t at_us,
                              uint8_t** out_jpeg,
                              unsigned long* out_jpeg_size) {
  AVFormatContext* format_ctx = avformat_alloc_context();
  if (!format_ctx) return -1;

  int ret = avformat_open_input(&format_ctx, src_file, nullptr, nullptr);
  if (ret < 0) {
    avformat_free_context(format_ctx);
    return -1;
  }

  ret = avformat_find_stream_info(format_ctx, nullptr);
  if (ret < 0) {
    avformat_close_input(&format_ctx);
    return -1;
  }

  int video_stream_index = -1;
  const AVCodec* codec = nullptr;
  for (unsigned int i = 0; i < format_ctx->nb_streams; i++) {
    if (format_ctx->streams[i]->codecpar->codec_type == AVMEDIA_TYPE_VIDEO) {
      video_stream_index = (int)i;
      codec = avcodec_find_decoder(format_ctx->streams[i]->codecpar->codec_id);
      break;
    }
  }

  if (video_stream_index < 0 || !codec) {
    avformat_close_input(&format_ctx);
    return -1;
  }

  AVCodecContext* codec_ctx = avcodec_alloc_context3(codec);
  if (!codec_ctx) {
    avformat_close_input(&format_ctx);
    return -1;
  }

  ret = avcodec_parameters_to_context(codec_ctx, format_ctx->streams[video_stream_index]->codecpar);
  if (ret < 0) {
    avcodec_free_context(&codec_ctx);
    avformat_close_input(&format_ctx);
    return -1;
  }

  ret = avcodec_open2(codec_ctx, codec, nullptr);
  if (ret < 0) {
    avcodec_free_context(&codec_ctx);
    avformat_close_input(&format_ctx);
    return -1;
  }

  if (at_us > 0) {
    int64_t seek_ts = av_rescale_q(at_us, AV_TIME_BASE_Q, format_ctx->streams[video_stream_index]->time_base);
    ret = av_seek_frame(format_ctx, video_stream_index, seek_ts, AVSEEK_FLAG_BACKWARD);
    if (ret < 0) {
      ret = av_seek_frame(format_ctx, video_stream_index, seek_ts, AVSEEK_FLAG_ANY);
      if (ret < 0) {
        avcodec_free_context(&codec_ctx);
        avformat_close_input(&format_ctx);
        return -1;
      }
    }
    avcodec_flush_buffers(codec_ctx);
  }

  AVFrame* frame = av_frame_alloc();
  AVPacket* packet = av_packet_alloc();
  if (!frame || !packet) {
    av_packet_free(&packet);
    av_frame_free(&frame);
    avcodec_free_context(&codec_ctx);
    avformat_close_input(&format_ctx);
    return -1;
  }

  int frame_count = 0;

  while (av_read_frame(format_ctx, packet) >= 0) {
    if (packet->stream_index != video_stream_index) {
      av_packet_unref(packet);
      continue;
    }

    ret = avcodec_send_packet(codec_ctx, packet);
    av_packet_unref(packet);
    if (ret < 0) continue;

    while (ret >= 0) {
      ret = avcodec_receive_frame(codec_ctx, frame);
      if (ret == AVERROR(EAGAIN) || ret == AVERROR_EOF) break;
      if (ret < 0) {
        av_frame_unref(frame);
        av_packet_free(&packet);
        av_frame_free(&frame);
        avcodec_free_context(&codec_ctx);
        avformat_close_input(&format_ctx);
        return -1;
      }

      frame_count++;
      if (frame_count > 500) {
        av_frame_unref(frame);
        break;
      }

      int64_t frame_pts_us = 0;
      if (frame->pts != AV_NOPTS_VALUE) {
        AVRational time_base = format_ctx->streams[video_stream_index]->time_base;
        frame_pts_us = av_rescale_q(frame->pts, time_base, AV_TIME_BASE_Q);
      }

      if (at_us <= 0 || frame_pts_us >= at_us) {
        if (frame->width <= 0 || frame->height <= 0) {
          av_frame_unref(frame);
          continue;
        }

        int src_w = frame->width;
        int src_h = frame->height;

        double scale_w = (double)max_width / src_w;
        double scale_h = (double)max_height / src_h;
        double scale = (scale_w < scale_h) ? scale_w : scale_h;
        if (scale > 1.0) scale = 1.0;

        int thumb_width = (int)(src_w * scale + 0.5);
        int thumb_height = (int)(src_h * scale + 0.5);
        if (thumb_width <= 0) thumb_width = 1;
        if (thumb_height <= 0) thumb_height = 1;

        int rgb_size = av_image_get_buffer_size(AV_PIX_FMT_RGB24, thumb_width, thumb_height, 1);
        uint8_t* rgb_buffer = (uint8_t*)av_malloc(rgb_size);
        if (!rgb_buffer) {
          av_frame_unref(frame);
          av_packet_free(&packet);
          av_frame_free(&frame);
          avcodec_free_context(&codec_ctx);
          avformat_close_input(&format_ctx);
          return -1;
        }

        uint8_t* dst_data[4] = { rgb_buffer, nullptr, nullptr, nullptr };
        int dst_linesize[4] = { thumb_width * 3, 0, 0, 0 };

        SwsContext* sws_ctx = sws_getContext(
            src_w, src_h, (AVPixelFormat)frame->format,
            thumb_width, thumb_height, AV_PIX_FMT_RGB24,
            SWS_BILINEAR, nullptr, nullptr, nullptr);
        if (!sws_ctx) {
          av_free(rgb_buffer);
          av_frame_unref(frame);
          av_packet_free(&packet);
          av_frame_free(&frame);
          avcodec_free_context(&codec_ctx);
          avformat_close_input(&format_ctx);
          return -1;
        }

        sws_scale(sws_ctx, frame->data, frame->linesize, 0, src_h, dst_data, dst_linesize);
        sws_freeContext(sws_ctx);

        ret = encode_jpeg_to_buffer(rgb_buffer, thumb_width, thumb_height, quality,
                                     out_jpeg, out_jpeg_size);
        av_free(rgb_buffer);

        av_frame_unref(frame);
        av_packet_free(&packet);
        av_frame_free(&frame);
        avcodec_free_context(&codec_ctx);
        avformat_close_input(&format_ctx);

        if (ret < 0) return -1;
        return 0;
      }

      av_frame_unref(frame);
    }

    if (frame_count > 500) break;
  }

  av_packet_free(&packet);
  av_frame_free(&frame);
  avcodec_free_context(&codec_ctx);
  avformat_close_input(&format_ctx);

  return -2;
}

static int parse_args(FlValue* args,
                      const char** src_file,
                      int* width,
                      int* height,
                      int* quality,
                      int64_t* at_us) {
  if (fl_value_get_type(args) != FL_VALUE_TYPE_MAP) {
    return -1;
  }

  FlValue* src = fl_value_lookup_string(args, "srcFile");
  if (!src || fl_value_get_type(src) != FL_VALUE_TYPE_STRING) {
    return -1;
  }
  *src_file = fl_value_get_string(src);

  FlValue* w = fl_value_lookup_string(args, "width");
  FlValue* h = fl_value_lookup_string(args, "height");
  if (!w || !h) return -1;

  if (fl_value_get_type(w) == FL_VALUE_TYPE_INT) {
    *width = (int)fl_value_get_int(w);
  } else if (fl_value_get_type(w) == FL_VALUE_TYPE_FLOAT) {
    *width = (int)fl_value_get_float(w);
  } else {
    return -1;
  }

  if (fl_value_get_type(h) == FL_VALUE_TYPE_INT) {
    *height = (int)fl_value_get_int(h);
  } else if (fl_value_get_type(h) == FL_VALUE_TYPE_FLOAT) {
    *height = (int)fl_value_get_float(h);
  } else {
    return -1;
  }

  if (*width <= 0 || *height <= 0) {
    return -1;
  }

  *quality = 90;
  FlValue* q = fl_value_lookup_string(args, "quality");
  if (q && fl_value_get_type(q) == FL_VALUE_TYPE_INT) {
    *quality = (int)fl_value_get_int(q);
    if (*quality < 0) *quality = 0;
    if (*quality > 100) *quality = 100;
  }

  *at_us = -1;
  FlValue* at_us_val = fl_value_lookup_string(args, "atUs");
  if (at_us_val && fl_value_get_type(at_us_val) == FL_VALUE_TYPE_INT) {
    *at_us = fl_value_get_int(at_us_val);
  }

  return 0;
}

typedef struct {
  FlMethodCall* method_call;
  char* src_file;
  char* dest_file;
  int width;
  int height;
  int quality;
  int64_t at_us;
} SaveToFileTaskData;

typedef struct {
  FlMethodCall* method_call;
  char* src_file;
  int width;
  int height;
  int quality;
  int64_t at_us;
} SaveToBytesTaskData;

static void free_save_to_file_task_data(gpointer data) {
  SaveToFileTaskData* task_data = (SaveToFileTaskData*)data;
  if (task_data->method_call) g_object_unref(task_data->method_call);
  g_free(task_data->src_file);
  g_free(task_data->dest_file);
  g_free(task_data);
}

static void free_save_to_bytes_task_data(gpointer data) {
  SaveToBytesTaskData* task_data = (SaveToBytesTaskData*)data;
  if (task_data->method_call) g_object_unref(task_data->method_call);
  g_free(task_data->src_file);
  g_free(task_data);
}

static void save_to_file_thread_func(GTask* task,
                                      gpointer source_object,
                                      gpointer task_data,
                                      GCancellable* cancellable) {
  SaveToFileTaskData* data = (SaveToFileTaskData*)task_data;

  uint8_t* jpeg_data = nullptr;
  unsigned long jpeg_size = 0;
  int result = extract_thumbnail(data->src_file, data->width, data->height, data->quality, data->at_us, &jpeg_data, &jpeg_size);

  FlMethodResponse* response;
  if (result == -2) {
    response = make_success_bool(false);
  } else if (result < 0) {
    response = make_error(kErrorPluginError, "Failed to extract thumbnail.");
  } else {
    FILE* f = fopen(data->dest_file, "wb");
    if (!f) {
      free(jpeg_data);
      response = make_error(kErrorPluginError, "Failed to open destination file.");
    } else {
      size_t written = fwrite(jpeg_data, 1, jpeg_size, f);
      fclose(f);
      free(jpeg_data);
      if (written != jpeg_size) {
        response = make_error(kErrorPluginError, "Failed to write thumbnail to file.");
      } else {
        response = make_success_bool(true);
      }
    }
  }

  g_task_return_pointer(task, response, nullptr);
}

static void save_to_bytes_thread_func(GTask* task,
                                       gpointer source_object,
                                       gpointer task_data,
                                       GCancellable* cancellable) {
  SaveToBytesTaskData* data = (SaveToBytesTaskData*)task_data;

  uint8_t* jpeg_data = nullptr;
  unsigned long jpeg_size = 0;
  int result = extract_thumbnail(data->src_file, data->width, data->height, data->quality, data->at_us, &jpeg_data, &jpeg_size);

  FlMethodResponse* response;
  if (result == -2) {
    response = make_null_result();
  } else if (result < 0) {
    response = make_error(kErrorPluginError, "Failed to extract thumbnail.");
  } else {
    response = make_success_bytes(jpeg_data, jpeg_size);
    free(jpeg_data);
  }

  g_task_return_pointer(task, response, nullptr);
}

static void on_save_to_file_ready(GObject* source, GAsyncResult* result, gpointer user_data) {
  GTask* task = G_TASK(result);
  SaveToFileTaskData* data = (SaveToFileTaskData*)g_task_get_task_data(task);
  g_autoptr(GError) error = nullptr;
  FlMethodResponse* response = (FlMethodResponse*)g_task_propagate_pointer(task, &error);
  if (response) {
    fl_method_call_respond(data->method_call, response, nullptr);
    g_object_unref(response);
  }
}

static void on_save_to_bytes_ready(GObject* source, GAsyncResult* result, gpointer user_data) {
  GTask* task = G_TASK(result);
  SaveToBytesTaskData* data = (SaveToBytesTaskData*)g_task_get_task_data(task);
  g_autoptr(GError) error = nullptr;
  FlMethodResponse* response = (FlMethodResponse*)g_task_propagate_pointer(task, &error);
  if (response) {
    fl_method_call_respond(data->method_call, response, nullptr);
    g_object_unref(response);
  }
}

void save_thumbnail_to_file(FlMethodCall* method_call) {
  FlValue* args = fl_method_call_get_args(method_call);

  const char* src_file = nullptr;
  int width = 0, height = 0, quality = 90;
  int64_t at_us = -1;

  if (parse_args(args, &src_file, &width, &height, &quality, &at_us) < 0) {
    g_autoptr(FlMethodResponse) response = make_error(kErrorInvalidArgs, "Missing or invalid arguments.");
    fl_method_call_respond(method_call, response, nullptr);
    return;
  }

  FlValue* dest = fl_value_lookup_string(args, "destFile");
  if (!dest || fl_value_get_type(dest) != FL_VALUE_TYPE_STRING) {
    g_autoptr(FlMethodResponse) response = make_error(kErrorInvalidArgs, "Missing required argument: destFile.");
    fl_method_call_respond(method_call, response, nullptr);
    return;
  }
  const char* dest_file = fl_value_get_string(dest);

  SaveToFileTaskData* task_data = g_new0(SaveToFileTaskData, 1);
  task_data->method_call = (FlMethodCall*)g_object_ref(method_call);
  task_data->src_file = g_strdup(src_file);
  task_data->dest_file = g_strdup(dest_file);
  task_data->width = width;
  task_data->height = height;
  task_data->quality = quality;
  task_data->at_us = at_us;

  GTask* task = g_task_new(nullptr, nullptr, on_save_to_file_ready, nullptr);
  g_task_set_task_data(task, task_data, free_save_to_file_task_data);
  g_task_run_in_thread(task, save_to_file_thread_func);
  g_object_unref(task);
}

void save_thumbnail_to_bytes(FlMethodCall* method_call) {
  FlValue* args = fl_method_call_get_args(method_call);

  const char* src_file = nullptr;
  int width = 0, height = 0, quality = 90;
  int64_t at_us = -1;

  if (parse_args(args, &src_file, &width, &height, &quality, &at_us) < 0) {
    g_autoptr(FlMethodResponse) response = make_error(kErrorInvalidArgs, "Missing or invalid arguments.");
    fl_method_call_respond(method_call, response, nullptr);
    return;
  }

  SaveToBytesTaskData* task_data = g_new0(SaveToBytesTaskData, 1);
  task_data->method_call = (FlMethodCall*)g_object_ref(method_call);
  task_data->src_file = g_strdup(src_file);
  task_data->width = width;
  task_data->height = height;
  task_data->quality = quality;
  task_data->at_us = at_us;

  GTask* task = g_task_new(nullptr, nullptr, on_save_to_bytes_ready, nullptr);
  g_task_set_task_data(task, task_data, free_save_to_bytes_task_data);
  g_task_run_in_thread(task, save_to_bytes_thread_func);
  g_object_unref(task);
}

static void fc_native_video_thumbnail_plugin_handle_method_call(
    FcNativeVideoThumbnailPlugin* self,
    FlMethodCall* method_call) {
  const gchar* method = fl_method_call_get_name(method_call);

  if (strcmp(method, "saveThumbnailToFile") == 0) {
    save_thumbnail_to_file(method_call);
  } else if (strcmp(method, "saveThumbnailToBytes") == 0) {
    save_thumbnail_to_bytes(method_call);
  } else {
    g_autoptr(FlMethodResponse) response = FL_METHOD_RESPONSE(fl_method_not_implemented_response_new());
    fl_method_call_respond(method_call, response, nullptr);
  }
}

static void fc_native_video_thumbnail_plugin_dispose(GObject* object) {
  G_OBJECT_CLASS(fc_native_video_thumbnail_plugin_parent_class)->dispose(object);
}

static void fc_native_video_thumbnail_plugin_class_init(FcNativeVideoThumbnailPluginClass* klass) {
  G_OBJECT_CLASS(klass)->dispose = fc_native_video_thumbnail_plugin_dispose;
}

static void fc_native_video_thumbnail_plugin_init(FcNativeVideoThumbnailPlugin* self) {}

static void method_call_cb(FlMethodChannel* channel, FlMethodCall* method_call,
                           gpointer user_data) {
  FcNativeVideoThumbnailPlugin* plugin = FC_NATIVE_VIDEO_THUMBNAIL_PLUGIN(user_data);
  fc_native_video_thumbnail_plugin_handle_method_call(plugin, method_call);
}

void fc_native_video_thumbnail_plugin_register_with_registrar(FlPluginRegistrar* registrar) {
  FcNativeVideoThumbnailPlugin* plugin = FC_NATIVE_VIDEO_THUMBNAIL_PLUGIN(
      g_object_new(fc_native_video_thumbnail_plugin_get_type(), nullptr));

  g_autoptr(FlStandardMethodCodec) codec = fl_standard_method_codec_new();
  g_autoptr(FlMethodChannel) channel =
      fl_method_channel_new(fl_plugin_registrar_get_messenger(registrar),
                            "fc_native_video_thumbnail",
                            FL_METHOD_CODEC(codec));
  fl_method_channel_set_method_call_handler(channel, method_call_cb,
                                            g_object_ref(plugin),
                                            g_object_unref);

  g_object_unref(plugin);
}
