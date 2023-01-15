import Cocoa
import FlutterMacOS

public class FcNativeVideoThumbnailPlugin: NSObject, FlutterPlugin {
  public static func register(with registrar: FlutterPluginRegistrar) {
    let channel = FlutterMethodChannel(name: "fc_native_video_thumbnail", binaryMessenger: registrar.messenger)
    let instance = FcNativeVideoThumbnailPlugin()
    registrar.addMethodCallDelegate(instance, channel: channel)
  }

  public func handle(_ call: FlutterMethodCall, result: @escaping FlutterResult) {
      guard let args = call.arguments as? Dictionary<String, Any> else {
          result(FlutterError(code: "InvalidArgsType", message: "Invalid args type", details: nil))
          return
      }
      switch call.method {
      case "getThumbnailFile":
          // Arguments are enforced on dart side.
          let srcFile = args["srcFile"] as! String
          let destFile = args["destFile"] as! String
          let width = args["width"] as! Int
          let height = args["height"] as! Int
          let outputString = args["type"] as! String
          let keepAspectRatio = args["keepAspectRatio"] as! Bool
          
          let quality = args["quality"] as? Int;
          let outputType = outputString == "png" ? OutputType.png : OutputType.jpeg
          
          DispatchQueue.global().async {
              do {
                  try ImageUtil.getThumbnailFile(src: srcFile, dest: destFile, width: CGFloat(width), height: CGFloat(height), keepAspectRatio: keepAspectRatio, outType: outputType, quality: quality)
                  DispatchQueue.main.async {
                      result(nil)
                  }
              } catch ResizeError.invalidSrc {
                  DispatchQueue.main.async {
                      result(FlutterError(code: "InvalidSrc", message: "", details: nil))
                  }
              } catch {
                  DispatchQueue.main.async {
                      result(FlutterError(code: "Err", message: error.localizedDescription, details: nil))
                  }
              }
          }
          
      default:
          result(FlutterMethodNotImplemented)
      }
  }
}
