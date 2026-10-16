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
) async throws -> CGImage? {
  let asset = AVAsset(url: url)

  let videoTracks = try await asset.loadTracks(withMediaType: .video)
  guard !videoTracks.isEmpty else {
    return nil
  }

  let generator = AVAssetImageGenerator(asset: asset)

  generator.appliesPreferredTrackTransform = true
  generator.maximumSize = maxSize
  generator.requestedTimeToleranceBefore = .zero
  generator.requestedTimeToleranceAfter = .zero

  let time = CMTimeMake(value: atUs ?? 0, timescale: 1_000_000)
  return try await generator.image(at: time).image
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
) async throws -> PlatformImage? {

  guard
    let cgImage = try await _generateThumbnailCGImage(
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
) async throws -> Bool {

  guard
    let cgImage = try await _generateThumbnailCGImage(
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
) async throws -> Data? {

  guard
    let cgImage = try await _generateThumbnailCGImage(
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
