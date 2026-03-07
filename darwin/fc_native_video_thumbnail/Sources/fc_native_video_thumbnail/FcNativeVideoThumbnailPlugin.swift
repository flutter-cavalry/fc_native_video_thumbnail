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
    guard let args = call.arguments as? [String: Any] else {
      result(FlutterError(code: "InvalidArgsType", message: "Invalid args type", details: nil))
      return
    }
    switch call.method {
    case "saveThumbnailToFile":
      let srcFile = args["srcFile"] as! String
      let destFile = args["destFile"] as! String
      let width = args["width"] as! Int
      let height = args["height"] as! Int
      let srcUri = args["srcFileUri"] as? Bool ?? false
      let quality = args["quality"] as? Int
      let atUs = args["atUs"] as? Int64
      let qualityDouble = quality != nil ? Double(quality!) / 100.0 : 0.9

      guard let srcUrl = srcUri ? URL(string: srcFile) : URL(fileURLWithPath: srcFile) else {
        result(FlutterError(code: "PluginError", message: "Invalid source URL", details: nil))
        return
      }
      let destUrl = URL(fileURLWithPath: destFile)

      DispatchQueue.global().async {
        do {
          let generated = try saveThumbnail(
            from: srcUrl,
            to: destUrl,
            maxSize: CGSize(width: width, height: height),
            atUs: atUs,
            compressionQuality: qualityDouble
          )

          DispatchQueue.main.async {
            result(generated)
          }
        } catch {
          DispatchQueue.main.async {
            result(
              FlutterError(code: "PluginError", message: error.localizedDescription, details: nil)
            )
          }
        }
      }
    case "saveThumbnailToBytes":
      let srcFile = args["srcFile"] as! String
      let width = args["width"] as! Int
      let height = args["height"] as! Int
      let srcUri = args["srcFileUri"] as? Bool ?? false
      let quality = args["quality"] as? Int
      let atUs = args["atUs"] as? Int64
      let qualityDouble = quality != nil ? Double(quality!) / 100.0 : 0.9

      guard let srcUrl = srcUri ? URL(string: srcFile) : URL(fileURLWithPath: srcFile) else {
        result(FlutterError(code: "PluginError", message: "Invalid source URL", details: nil))
        return
      }

      DispatchQueue.global().async {
        do {
          let generated = try thumbnailData(
            from: srcUrl,
            maxSize: CGSize(width: width, height: height),
            atUs: atUs,
            compressionQuality: qualityDouble
          )

          DispatchQueue.main.async {
            result(generated)
          }
        } catch {
          DispatchQueue.main.async {
            result(
              FlutterError(code: "PluginError", message: error.localizedDescription, details: nil)
            )
          }
        }
      }

    default:
      result(FlutterMethodNotImplemented)
    }
  }
}
