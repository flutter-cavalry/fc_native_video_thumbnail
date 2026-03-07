import AVFoundation
import ImageIO
import UniformTypeIdentifiers

#if os(iOS)
  import UIKit
  public typealias PlatformImage = UIImage
#elseif os(macOS)
  import AppKit
  public typealias PlatformImage = NSImage
#endif

private func _generateThumbnailCGImage(
  from url: URL,
  maxSize: CGSize,
  atUs: Int64?
) throws -> CGImage? {

  let asset = AVAsset(url: url)

  guard asset.tracks(withMediaType: .video).count > 0 else {
    return nil
  }

  let generator = AVAssetImageGenerator(asset: asset)

  generator.appliesPreferredTrackTransform = true
  generator.maximumSize = maxSize
  generator.requestedTimeToleranceBefore = .zero
  generator.requestedTimeToleranceAfter = .zero

  // Default to 1 second if atUs is not provided
  let time = CMTimeMake(value: atUs ?? 1_000_000, timescale: 1_000_000)
  return try generator.copyCGImage(at: time, actualTime: nil)
}

private func encodeJPEG(
  cgImage: CGImage,
  compressionQuality: Double
) -> Data? {

  let quality = max(0.0, min(1.0, compressionQuality))

  #if os(macOS)

    let bitmapRep = NSBitmapImageRep(cgImage: cgImage)

    return bitmapRep.representation(
      using: .jpeg,
      properties: [.compressionFactor: quality]
    )

  #else

    let data = NSMutableData()

    guard
      let destination = CGImageDestinationCreateWithData(
        data,
        UTType.jpeg.identifier as CFString,
        1,
        nil
      )
    else {
      return nil
    }

    CGImageDestinationAddImage(
      destination,
      cgImage,
      [
        kCGImageDestinationLossyCompressionQuality: quality
      ] as CFDictionary
    )

    guard CGImageDestinationFinalize(destination) else {
      return nil
    }

    return data as Data

  #endif
}

public func generateThumbnail(
  from url: URL,
  maxSize: CGSize,
  atUs: Int64?
) throws -> PlatformImage? {

  guard
    let cgImage = try _generateThumbnailCGImage(
      from: url,
      maxSize: maxSize,
      atUs: atUs
    )
  else {
    return nil
  }

  #if os(iOS)
    return UIImage(cgImage: cgImage)
  #else
    return NSImage(cgImage: cgImage, size: .zero)
  #endif
}

public func saveThumbnail(
  from url: URL,
  to outputURL: URL,
  maxSize: CGSize,
  atUs: Int64?,
  compressionQuality: Double = 0.9
) throws -> Bool {

  guard
    let cgImage = try _generateThumbnailCGImage(
      from: url,
      maxSize: maxSize,
      atUs: atUs
    )
  else {
    return false
  }

  guard
    let data = encodeJPEG(
      cgImage: cgImage,
      compressionQuality: compressionQuality
    )
  else {
    return false
  }

  try data.write(to: outputURL)
  return true
}

public func thumbnailData(
  from url: URL,
  maxSize: CGSize,
  atUs: Int64?,
  compressionQuality: Double = 0.9
) throws -> Data? {

  guard
    let cgImage = try _generateThumbnailCGImage(
      from: url,
      maxSize: maxSize,
      atUs: atUs
    )
  else {
    return nil
  }

  return encodeJPEG(
    cgImage: cgImage,
    compressionQuality: compressionQuality
  )
}
