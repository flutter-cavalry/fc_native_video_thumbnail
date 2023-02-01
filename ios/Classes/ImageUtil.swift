import Foundation
import UIKit
import AVFoundation

enum ResizeError: Error {
  case invalidSrc
}

enum OutputType {
  case jpeg
  case png
}

class ImageUtil {
  static func getVideoThumbnail(src: String, dest: String, width: CGFloat, height: CGFloat, keepAspectRatio: Bool, outType: OutputType, quality: Int?) throws {
    let asset = AVURLAsset(url: URL(fileURLWithPath: src))
    let imageGenerator = AVAssetImageGenerator(asset: asset)
    imageGenerator.appliesPreferredTrackTransform = true
    
    let cgImage = try imageGenerator.copyCGImage(at: .zero,
                                                 actualTime: nil)
    
    let img = UIImage(cgImage: cgImage)
    let oldSize = img.size
    let newSize = keepAspectRatio ? _sizeToFit(originalSize: oldSize, maxSize: CGSize(width: width, height: height)) : CGSize(width: width, height: height)
    
    let resizedImg = img.resized(to: newSize)
    if outType == .jpeg {
      try resizedImg.jpegData(compressionQuality: Double(quality ?? 90) / 100.0)?.write(to: URL(fileURLWithPath: dest))
    } else {
      try resizedImg.pngData()?.write(to: URL(fileURLWithPath: dest))
    }
  }
  
  static func _sizeToFit(originalSize: CGSize, maxSize: CGSize) -> CGSize {
    let widthRatio = maxSize.width / originalSize.width;
    let heightRatio = maxSize.height / originalSize.height;
    let minAspectRatio = min(widthRatio, heightRatio);
    if (minAspectRatio > 1) {
      return originalSize;
    }
    return CGSize(width: floor(originalSize.width * minAspectRatio), height: floor(originalSize.height * minAspectRatio))
  }
}

extension UIImage {
  public func resized(to target: CGSize) -> UIImage {
    let format = UIGraphicsImageRendererFormat()
    format.scale = 1
    let renderer = UIGraphicsImageRenderer(size: target, format: format)
    return renderer.image { _ in
      self.draw(in: CGRect(origin: .zero, size: target))
    }
  }
}
