#include "fc_native_video_thumbnail_plugin.h"

// This must be included before many other Windows headers.
#include <atlimage.h>
#include <comdef.h>
#include <flutter/method_channel.h>
#include <flutter/plugin_registrar_windows.h>
#include <flutter/standard_method_codec.h>
#include <gdiplus.h>
#include <gdiplusimaging.h>
#include <shlwapi.h>
#include <thumbcache.h>
#include <wincodec.h>
#include <windows.h>
#include <wingdi.h>

#include <codecvt>
#include <iostream>
#include <locale>
#include <memory>
#include <sstream>
#include <string>
#include <vector>

const std::string kGetThumbnailFailedExtraction = "Failed extraction";

namespace fc_native_video_thumbnail {

// https://github.com/flutter/plugins/blob/main/packages/camera/camera_windows/windows/camera_plugin.cpp
// Looks for |key| in |map|, returning the associated value if it is present, or
// a nullptr if not.
const flutter::EncodableValue* ValueOrNull(const flutter::EncodableMap& map, const char* key) {
  auto it = map.find(flutter::EncodableValue(key));
  if (it == map.end()) {
    return nullptr;
  }
  return &(it->second);
}

// Looks for |key| in |map|, returning the associated int64 value if it is
// present, or std::nullopt if not.
std::optional<int64_t> GetInt64ValueOrNull(const flutter::EncodableMap& map,
                                           const char* key) {
  auto value = ValueOrNull(map, key);
  if (!value) {
    return std::nullopt;
  }

  if (std::holds_alternative<int32_t>(*value)) {
    return static_cast<int64_t>(std::get<int32_t>(*value));
  }
  auto val64 = std::get_if<int64_t>(value);
  if (!val64) {
    return std::nullopt;
  }
  return *val64;
}

// Converts the given UTF-8 string to UTF-16.
std::wstring Utf16FromUtf8(const std::string& utf8_string) {
  if (utf8_string.empty()) {
    return std::wstring();
  }
  int target_length =
      ::MultiByteToWideChar(CP_UTF8, MB_ERR_INVALID_CHARS, utf8_string.data(),
                            static_cast<int>(utf8_string.length()), nullptr, 0);
  if (target_length == 0) {
    return std::wstring();
  }
  std::wstring utf16_string;
  utf16_string.resize(target_length);
  int converted_length =
      ::MultiByteToWideChar(CP_UTF8, MB_ERR_INVALID_CHARS, utf8_string.data(),
                            static_cast<int>(utf8_string.length()),
                            utf16_string.data(), target_length);
  if (converted_length == 0) {
    return std::wstring();
  }
  return utf16_string;
}

std::string HRESULTToString(HRESULT hr) {
  _com_error error(hr);
  CString cs;
  cs.Format(_T("Error 0x%08x: %s"), hr, error.ErrorMessage());

  std::string res;

#ifdef UNICODE
  int wlen = lstrlenW(cs);
  int len = WideCharToMultiByte(CP_ACP, 0, cs, wlen, NULL, 0, NULL, NULL);
  res.resize(len);
  WideCharToMultiByte(CP_ACP, 0, cs, wlen, &res[0], len, NULL, NULL);
#else
  res = errMsg;
#endif
  return res;
}

std::string ExtractThumbnailBitmap(PCWSTR srcFile, int size, HBITMAP* outBitmap) {
  *outBitmap = NULL;

  IShellItem* pSI;
  HRESULT hr = SHCreateItemFromParsingName(srcFile, NULL, IID_IShellItem, (void**)&pSI);
  if (!SUCCEEDED(hr)) {
    return "`SHCreateItemFromParsingName` failed with " + HRESULTToString(hr);
  }

  IThumbnailCache* pThumbCache;
  hr = CoCreateInstance(CLSID_LocalThumbnailCache,
                        NULL,
                        CLSCTX_INPROC_SERVER,
                        IID_PPV_ARGS(&pThumbCache));

  if (!SUCCEEDED(hr)) {
    pSI->Release();
    return "`CoCreateInstance` failed with " + HRESULTToString(hr);
  }

  ISharedBitmap* pSharedBitmap = NULL;
  hr = pThumbCache->GetThumbnail(pSI,
                                 size,
                                 WTS_EXTRACT | WTS_SCALETOREQUESTEDSIZE,
                                 &pSharedBitmap,
                                 NULL,
                                 NULL);
  pSI->Release();

  if (!SUCCEEDED(hr) || !pSharedBitmap) {
    pThumbCache->Release();
    if (hr == WTS_E_FAILEDEXTRACTION) {
      return kGetThumbnailFailedExtraction;
    }
    return "`GetThumbnail` failed with " + HRESULTToString(hr);
  }

  // Take ownership of the bitmap handle so it stays valid after COM releases.
  hr = pSharedBitmap->Detach(outBitmap);
  pSharedBitmap->Release();
  if (!SUCCEEDED(hr) || !*outBitmap) {
    pThumbCache->Release();
    return "`Detach` failed with " + HRESULTToString(hr);
  }

  pThumbCache->Release();

  return "";
}

std::string SaveThumbnailToFile(PCWSTR srcFile, PCWSTR destFile, int size, REFGUID type) {
  HBITMAP hBitmap;
  auto extractResult = ExtractThumbnailBitmap(srcFile, size, &hBitmap);
  if (extractResult != "") {
    return extractResult;
  }

  // Save the bitmap to a file
  CImage image;
  image.Attach(hBitmap);
  HRESULT hr = image.Save(destFile, type);
  if (!SUCCEEDED(hr)) {
    return "`image.Attach` failed with " + HRESULTToString(hr);
  }
  return "";
}

std::string SaveThumbnailToBytes(PCWSTR srcFile,
                                 int size,
                                 REFGUID type,
                                 std::vector<uint8_t>* outBytes) {
  outBytes->clear();

  HBITMAP hBitmap;
  auto extractResult = ExtractThumbnailBitmap(srcFile, size, &hBitmap);
  if (extractResult != "") {
    return extractResult;
  }

  CImage image;
  image.Attach(hBitmap);

  IStream* stream = nullptr;
  HRESULT hr = CreateStreamOnHGlobal(NULL, TRUE, &stream);
  if (!SUCCEEDED(hr) || !stream) {
    return "`CreateStreamOnHGlobal` failed with " + HRESULTToString(hr);
  }

  hr = image.Save(stream, type);
  if (!SUCCEEDED(hr)) {
    stream->Release();
    return "`image.Save` failed with " + HRESULTToString(hr);
  }

  HGLOBAL imageDataHandle = NULL;
  hr = GetHGlobalFromStream(stream, &imageDataHandle);
  if (!SUCCEEDED(hr) || !imageDataHandle) {
    stream->Release();
    return "`GetHGlobalFromStream` failed with " + HRESULTToString(hr);
  }

  SIZE_T imageSize = GlobalSize(imageDataHandle);
  if (imageSize > 0) {
    auto* imageBytes = reinterpret_cast<uint8_t*>(GlobalLock(imageDataHandle));
    if (!imageBytes) {
      stream->Release();
      return "`GlobalLock` failed.";
    }
    outBytes->assign(imageBytes, imageBytes + imageSize);
    GlobalUnlock(imageDataHandle);
  }

  stream->Release();
  return "";
}

// static
void FcNativeVideoThumbnailPlugin::RegisterWithRegistrar(
    flutter::PluginRegistrarWindows* registrar) {
  auto channel =
      std::make_unique<flutter::MethodChannel<flutter::EncodableValue>>(
          registrar->messenger(), "fc_native_video_thumbnail",
          &flutter::StandardMethodCodec::GetInstance());

  auto plugin = std::make_unique<FcNativeVideoThumbnailPlugin>();

  channel->SetMethodCallHandler(
      [plugin_pointer = plugin.get()](const auto& call, auto result) {
        plugin_pointer->HandleMethodCall(call, std::move(result));
      });

  registrar->AddPlugin(std::move(plugin));
}

FcNativeVideoThumbnailPlugin::FcNativeVideoThumbnailPlugin() {}

FcNativeVideoThumbnailPlugin::~FcNativeVideoThumbnailPlugin() {}

void FcNativeVideoThumbnailPlugin::HandleMethodCall(
    const flutter::MethodCall<flutter::EncodableValue>& method_call,
    std::unique_ptr<flutter::MethodResult<flutter::EncodableValue>> result) {
  const auto& methodName = method_call.method_name();
  if (methodName.compare("saveThumbnailToFile") != 0 &&
      methodName.compare("saveThumbnailToBytes") != 0) {
    result->NotImplemented();
    return;
  }

  const auto* argsPtr = std::get_if<flutter::EncodableMap>(method_call.arguments());
  if (!argsPtr) {
    result->Error("InvalidArguments", "Arguments are required.");
    return;
  }
  auto args = *argsPtr;

  const auto* src_file =
      std::get_if<std::string>(ValueOrNull(args, "srcFile"));
  if (!src_file) {
    result->Error("InvalidArguments", "Missing required argument: srcFile.");
    return;
  }

  auto width = GetInt64ValueOrNull(args, "width");
  if (!width || *width <= 0 || *width > INT_MAX) {
    result->Error("InvalidArguments", "width must be an int in the range (0, INT_MAX].");
    return;
  }

  const auto* outType =
      std::get_if<std::string>(ValueOrNull(args, "format"));
  const auto& imageFormat =
      outType && outType->compare("png") == 0 ? Gdiplus::ImageFormatPNG : Gdiplus::ImageFormatJPEG;

  if (methodName.compare("saveThumbnailToFile") == 0) {
    const auto* dest_file =
        std::get_if<std::string>(ValueOrNull(args, "destFile"));
    if (!dest_file) {
      result->Error("InvalidArguments", "Missing required argument: destFile.");
      return;
    }

    auto operationResult = SaveThumbnailToFile(Utf16FromUtf8(*src_file).c_str(),
                                               Utf16FromUtf8(*dest_file).c_str(),
                                               static_cast<int>(*width),
                                               imageFormat);

    if (operationResult == kGetThumbnailFailedExtraction) {
      result->Success(flutter::EncodableValue(false));
    } else if (operationResult != "") {
      result->Error("PluginError", "Operation failed. " + operationResult);
    } else {
      result->Success(flutter::EncodableValue(true));
    }
  } else if (methodName.compare("saveThumbnailToBytes") == 0) {
    std::vector<uint8_t> imageBytes;
    auto operationResult = SaveThumbnailToBytes(Utf16FromUtf8(*src_file).c_str(),
                                                static_cast<int>(*width),
                                                imageFormat,
                                                &imageBytes);

    if (operationResult == kGetThumbnailFailedExtraction) {
      result->Success(flutter::EncodableValue());
    } else if (operationResult != "") {
      result->Error("PluginError", "Operation failed. " + operationResult);
    } else {
      result->Success(flutter::EncodableValue(imageBytes));
    }
  } else {
    result->NotImplemented();
  }
}

}  // namespace fc_native_video_thumbnail
