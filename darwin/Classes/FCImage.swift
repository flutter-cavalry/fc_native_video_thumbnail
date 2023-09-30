//
//  FCImage.swift
//
//  Created by Mgenware(Liu YuanYuan) on 2023/9/30.
//  https://github.com/flutter-cavalry/fc_native_image_resize/blob/main/darwin/Classes/FCImage.swift
//

import Foundation

#if os(iOS)
import UIKit
typealias PlatformImage = UIImage
#elseif os(macOS)
import AppKit
typealias PlatformImage = NSImage
#endif

enum FCImageOutputFormat {
  case jpeg
  case png
}

class FCImage {
  private let image: PlatformImage
  
  init(image: PlatformImage) {
    self.image = image
  }
  
  init?(path: String) {
#if os(iOS)
    guard let img = UIImage(contentsOfFile: path) else {
      return nil
    }
#elseif os(macOS)
    guard let img = NSImage(contentsOfFile: path) else {
      return nil
    }
#endif
    image = img
  }
  
  func size() -> CGSize {
    return image.size
  }
  
  func resized(to: CGSize, keepAspectRatio: Bool) -> FCImage {
    var resolvedSize = to
    if keepAspectRatio {
      resolvedSize = coerceSize(targetSize: to)
    }
#if os(iOS)
    let format = UIGraphicsImageRendererFormat()
    format.scale = 1
    let rawImg = image.resized(to: resolvedSize)
    return FCImage(image: rawImg)
#elseif os(macOS)
    return FCImage(image: image.resized(to: resolvedSize))
#endif
  }
  
  func saveToJPEGFile(dest: String, quality: Int?) throws {
#if os(iOS)
    let data = image.jpegData(compressionQuality: Double(quality ?? 90) / 100.0)
#elseif os(macOS)
    let data = image.nsImageToData(type: .jpeg, quality: quality)
#endif
    try data?.write(to: URL(fileURLWithPath: dest))
  }
  
  func saveToPNGFile(dest: String) throws {
#if os(iOS)
    let data = image.pngData()
#elseif os(macOS)
    let data = image.nsImageToData(type: .png, quality: nil)
#endif
    try data?.write(to: URL(fileURLWithPath: dest))
  }
  
  private func coerceSize(targetSize: CGSize) -> CGSize {
    let ratio = min(targetSize.width / size().width, targetSize.height / size().height)
    return CGSize(width: floor(size().width * ratio), height: floor(size().height * ratio))
  }
}

#if os(iOS)
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
#elseif os(macOS)
extension NSImage {
  public func resized(to target: CGSize) -> NSImage {
    let scale: CGFloat = NSScreen.main?.backingScaleFactor ?? 1
    let resolvedSize = CGSize(width: target.width / scale, height: target.height / scale)
    let rawImg = NSImage(size: resolvedSize)
    
    rawImg.lockFocus()
    defer {
      rawImg.unlockFocus()
    }
    
    if let ctx = NSGraphicsContext.current {
      ctx.imageInterpolation = .high
      draw(in: NSRect(origin: .zero, size: resolvedSize))
    }
    return rawImg
  }
  
  public func nsImageToData(type: NSBitmapImageRep.FileType, quality: Int?) -> Data? {
    guard let cgImage = cgImage(forProposedRect: nil, context: nil, hints: nil)
    else {
      return nil
    }
    let imageRep = NSBitmapImageRep(cgImage: cgImage)
    
    var opt: [NSBitmapImageRep.PropertyKey : Any] = [:]
    if type == .jpeg {
      opt[NSBitmapImageRep.PropertyKey.compressionFactor] = Double(quality ?? 90) / 100.0
    }
    return imageRep.representation(using: type, properties: opt)
  }
}
#endif
