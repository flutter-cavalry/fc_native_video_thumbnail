import AVFoundation
import Foundation

#if os(iOS)
  import Flutter
#elseif os(macOS)
  import FlutterMacOS
#endif

public class FcNativeVideoThumbnailPlugin: NSObject, FlutterPlugin {
  public static func register(with registrar: FlutterPluginRegistrar) {
    #if os(iOS)
      let binaryMessenger = registrar.messenger()
    #elseif os(macOS)
      let binaryMessenger = registrar.messenger
    #endif
    let channel = FlutterMethodChannel(
      name: "fc_native_video_thumbnail", binaryMessenger: binaryMessenger)
    let instance = FcNativeVideoThumbnailPlugin()
    registrar.addMethodCallDelegate(instance, channel: channel)
  }

  public func handle(_ call: FlutterMethodCall, result: @escaping FlutterResult) {
    switch call.method {
    case "saveThumbnailToFile":
      guard
        let args = call.arguments as? [String: Any],
        let srcFile = args["srcFile"] as? String,
        let destFile = args["destFile"] as? String,
        let width = args["width"] as? Int,
        let height = args["height"] as? Int,
        width > 0,
        height > 0
      else {
        result(
          FlutterError(
            code: "InvalidArguments", message: "Missing or invalid thumbnail arguments",
            details: nil))
        return
      }
      let srcUri = args["srcFileUri"] as? Bool ?? false
      let quality = Double((args["quality"] as? Int) ?? 90) / 100.0
      let atUs = (args["atUs"] as? NSNumber)?.int64Value

      guard let srcUrl = srcUri ? URL(string: srcFile) : URL(fileURLWithPath: srcFile) else {
        result(FlutterError(code: "PluginError", message: "Invalid source URL", details: nil))
        return
      }
      let destUrl = URL(fileURLWithPath: destFile)

      Task {
        do {
          let generated = try await saveThumbnail(
            from: srcUrl,
            to: destUrl,
            maxSize: CGSize(width: width, height: height),
            atUs: atUs,
            compressionQuality: quality
          )

          DispatchQueue.main.async {
            result(generated)
          }
        } catch {
          DispatchQueue.main.async {
            result(
              FlutterError(code: "PluginError", message: "\(error)", details: nil)
            )
          }
        }
      }
    case "saveThumbnailToBytes":
      guard
        let args = call.arguments as? [String: Any],
        let srcFile = args["srcFile"] as? String,
        let width = args["width"] as? Int,
        let height = args["height"] as? Int,
        width > 0,
        height > 0
      else {
        result(
          FlutterError(
            code: "InvalidArguments", message: "Missing or invalid thumbnail arguments",
            details: nil))
        return
      }
      let srcUri = args["srcFileUri"] as? Bool ?? false
      let quality = Double((args["quality"] as? Int) ?? 90) / 100.0
      let atUs = (args["atUs"] as? NSNumber)?.int64Value

      guard let srcUrl = srcUri ? URL(string: srcFile) : URL(fileURLWithPath: srcFile) else {
        result(FlutterError(code: "PluginError", message: "Invalid source URL", details: nil))
        return
      }

      Task {
        do {
          let generated = try await thumbnailData(
            from: srcUrl,
            maxSize: CGSize(width: width, height: height),
            atUs: atUs,
            compressionQuality: quality
          )

          DispatchQueue.main.async {
            result(generated)
          }
        } catch {
          DispatchQueue.main.async {
            result(
              FlutterError(code: "PluginError", message: "\(error)", details: nil)
            )
          }
        }
      }

    default:
      result(FlutterMethodNotImplemented)
    }
  }
}
