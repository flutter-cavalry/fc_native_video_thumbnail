import Foundation
import AVFoundation

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
    let channel = FlutterMethodChannel(name: "fc_native_video_thumbnail", binaryMessenger: binaryMessenger)
    let instance = FcNativeVideoThumbnailPlugin()
    registrar.addMethodCallDelegate(instance, channel: channel)
  }
  
  public func handle(_ call: FlutterMethodCall, result: @escaping FlutterResult) {
    guard let args = call.arguments as? Dictionary<String, Any> else {
      result(FlutterError(code: "InvalidArgsType", message: "Invalid args type", details: nil))
      return
    }
    switch call.method {
    case "getVideoThumbnail":
      // Arguments are enforced on dart side.
      let srcFile = args["srcFile"] as! String
      let destFile = args["destFile"] as! String
      let width = args["width"] as! Int
      let height = args["height"] as! Int
      let outputString = args["type"] as! String
      let keepAspectRatio = args["keepAspectRatio"] as! Bool
      
      let quality = args["quality"] as? Int;
      let outputType = outputString == "png" ? FCImageOutputFormat.png : FCImageOutputFormat.jpeg
      
      DispatchQueue.global().async {
        do {
          let asset = AVURLAsset(url: URL(fileURLWithPath: srcFile))
          let imageGenerator = AVAssetImageGenerator(asset: asset)
          imageGenerator.appliesPreferredTrackTransform = true
          
          let cgImage = try imageGenerator.copyCGImage(at: .zero,
                                                       actualTime: nil)
          
#if os(iOS)
          let rawImg = UIImage(cgImage: cgImage)
#elseif os(macOS)
          let rawImg = NSImage(cgImage: cgImage, size: CGSize(width: cgImage.width, height: cgImage.height))
#endif
          var img = FCImage(image: rawImg)
          img = img.resized(to: CGSize(width: CGFloat(width), height: CGFloat(height)), keepAspectRatio: keepAspectRatio)
          
          switch outputType {
          case .jpeg:
            try img.saveToJPEGFile(dest: destFile, quality: quality)
          case .png:
            try img.saveToPNGFile(dest: destFile)
          }
          
          DispatchQueue.main.async {
            result(true)
          }
        } catch {
          DispatchQueue.main.async {
            result(FlutterError(code: "PluginError", message: error.localizedDescription, details: nil))
          }
        }
      }
      
    default:
      result(FlutterMethodNotImplemented)
    }
  }
}
