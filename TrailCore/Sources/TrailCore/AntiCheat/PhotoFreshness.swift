import Foundation

public enum PhotoFreshness: Equatable, Sendable {
    /// Taken within the last 72 hours.
    case recent
    /// Taken more than 72 hours ago.
    case stale
    /// No readable capture time, or a time in the future (clock skew or edited metadata).
    case unknown

    public static let maxAge: TimeInterval = 72 * 60 * 60
    /// Allowed difference between the phone's clock and the photo's time.
    static let futureTolerance: TimeInterval = 5 * 60

    public static func classify(capturedAt: Date?, now: Date) -> PhotoFreshness {
        guard let capturedAt else { return .unknown }
        let age = now.timeIntervalSince(capturedAt)
        if age < -futureTolerance { return .unknown }
        return age <= maxAge ? .recent : .stale
    }
}
