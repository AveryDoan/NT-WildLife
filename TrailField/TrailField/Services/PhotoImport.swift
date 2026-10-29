import CoreGraphics
import CoreLocation
import Foundation
import ImageIO
import TrailCore
import UIKit
import UniformTypeIdentifiers

/// A photo ready for checking and identifying. The stored JPEG has no EXIF or GPS.
struct ImportedPhoto: @unchecked Sendable {
    enum Source { case library, camera }

    let source: Source
    let image: CGImage
    let jpegData: Data
    /// `nil` when the photo has no readable capture time (counts in the guide only).
    let capturedAt: Date?
    /// From the photo's own metadata, if it has any. Rounded before it is ever saved.
    let embeddedLocation: CLLocationCoordinate2D?
    let hash: UInt64?
}

enum PhotoImport {
    nonisolated static let maxPixelSize = 1280

    /// Photos picked with PhotosPicker. Reads EXIF DateTimeOriginal with CGImageSource,
    /// which needs no extra photo-library permission.
    nonisolated static func fromLibrary(data: Data, timeZone: TimeZone = .current) -> ImportedPhoto? {
        build(data: data, source: .library, capturedAtOverride: nil, timeZone: timeZone)
    }

    /// Camera shots use the current time (the photo was only just taken).
    nonisolated static func fromCamera(image: UIImage, now: Date = .now) -> ImportedPhoto? {
        guard let data = image.jpegData(compressionQuality: 0.9) else { return nil }
        return build(data: data, source: .camera, capturedAtOverride: now, timeZone: .current)
    }

    nonisolated private static func build(
        data: Data, source: ImportedPhoto.Source, capturedAtOverride: Date?, timeZone: TimeZone
    ) -> ImportedPhoto? {
        guard let imageSource = CGImageSourceCreateWithData(data as CFData, nil) else { return nil }

        let options: [CFString: Any] = [
            kCGImageSourceCreateThumbnailFromImageAlways: true,
            kCGImageSourceCreateThumbnailWithTransform: true,
            kCGImageSourceThumbnailMaxPixelSize: maxPixelSize,
        ]
        guard let image = CGImageSourceCreateThumbnailAtIndex(imageSource, 0, options as CFDictionary) else { return nil }

        let properties = CGImageSourceCopyPropertiesAtIndex(imageSource, 0, nil) as? [CFString: Any]
        let exif = properties?[kCGImagePropertyExifDictionary] as? [CFString: Any]
        let capturedAt = capturedAtOverride ?? ExifDate.parse(
            exif?[kCGImagePropertyExifDateTimeOriginal] as? String,
            offset: exif?["OffsetTimeOriginal" as CFString] as? String,
            assumedZone: timeZone
        )

        return ImportedPhoto(
            source: source,
            image: image,
            jpegData: encodeJPEG(image) ?? data,
            capturedAt: capturedAt,
            embeddedLocation: coordinate(from: properties?[kCGImagePropertyGPSDictionary] as? [CFString: Any]),
            hash: ImageHasher.dHash(of: image)
        )
    }

    /// Re-encoding from the decoded pixels drops all metadata, including GPS.
    nonisolated private static func encodeJPEG(_ image: CGImage) -> Data? {
        let output = NSMutableData()
        guard let destination = CGImageDestinationCreateWithData(output, UTType.jpeg.identifier as CFString, 1, nil) else {
            return nil
        }
        CGImageDestinationAddImage(destination, image, [kCGImageDestinationLossyCompressionQuality: 0.8] as CFDictionary)
        return CGImageDestinationFinalize(destination) ? output as Data : nil
    }

    nonisolated private static func coordinate(from gps: [CFString: Any]?) -> CLLocationCoordinate2D? {
        guard let gps,
              let lat = gps[kCGImagePropertyGPSLatitude] as? Double,
              let lon = gps[kCGImagePropertyGPSLongitude] as? Double else { return nil }
        let latRef = gps[kCGImagePropertyGPSLatitudeRef] as? String
        let lonRef = gps[kCGImagePropertyGPSLongitudeRef] as? String
        let coordinate = CLLocationCoordinate2D(
            latitude: latRef == "S" ? -lat : lat,
            longitude: lonRef == "W" ? -lon : lon
        )
        return CLLocationCoordinate2DIsValid(coordinate) ? coordinate : nil
    }
}

enum ImageHasher {
    /// Downscales to 9x8 greyscale with CoreGraphics; TrailCore does the hashing maths.
    nonisolated static func dHash(of image: CGImage) -> UInt64? {
        var pixels = [UInt8](repeating: 0, count: DHash.width * DHash.height)
        let drawn = pixels.withUnsafeMutableBytes { buffer -> Bool in
            guard let context = CGContext(
                data: buffer.baseAddress,
                width: DHash.width, height: DHash.height,
                bitsPerComponent: 8, bytesPerRow: DHash.width,
                space: CGColorSpaceCreateDeviceGray(),
                bitmapInfo: CGImageAlphaInfo.none.rawValue
            ) else { return false }
            context.interpolationQuality = .high
            context.draw(image, in: CGRect(x: 0, y: 0, width: DHash.width, height: DHash.height))
            return true
        }
        return drawn ? DHash.hash(grayscale: pixels) : nil
    }
}
