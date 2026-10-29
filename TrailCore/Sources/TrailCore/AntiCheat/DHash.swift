import Foundation

/// Difference hash (dHash) for spotting repeat uploads of the same photo.
/// The app downsizes the photo to 9x8 greyscale (CoreGraphics); this type holds
/// the pure maths so it can be tested with `swift test`.
public enum DHash {
    public static let width = 9
    public static let height = 8
    public static let duplicateThreshold = 6

    /// Builds a 64-bit hash from a 9x8 greyscale image, row by row.
    /// Returns `nil` if the pixel count is wrong.
    public static func hash(grayscale pixels: [UInt8]) -> UInt64? {
        guard pixels.count == width * height else { return nil }
        var result: UInt64 = 0
        var bit: UInt64 = 0
        for row in 0..<height {
            for col in 0..<(width - 1) {
                let left = pixels[row * width + col]
                let right = pixels[row * width + col + 1]
                if left > right {
                    result |= (1 << bit)
                }
                bit += 1
            }
        }
        return result
    }

    public static func hammingDistance(_ a: UInt64, _ b: UInt64) -> Int {
        (a ^ b).nonzeroBitCount
    }

    /// Distance of 6 or less counts as the same photo.
    public static func isDuplicate(_ hash: UInt64, of known: [UInt64]) -> Bool {
        known.contains { hammingDistance(hash, $0) <= duplicateThreshold }
    }
}
