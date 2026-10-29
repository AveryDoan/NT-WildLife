import Foundation

public struct RoundedCoordinate: Equatable, Hashable, Codable, Sendable {
    public let latitude: Double
    public let longitude: Double

    public init(latitude: Double, longitude: Double) {
        self.latitude = latitude
        self.longitude = longitude
    }
}

/// Everyone sees rounded locations only. The app never stores a precise position.
public enum LocationPrivacy {
    /// 2 decimal places is about 1.1 km north-south (about 1.1 km east-west near Darwin).
    public static let normalDecimals = 2
    /// 1 decimal place is about 11 km. Used for sensitive species.
    public static let sensitiveDecimals = 1

    public static func round(latitude: Double, longitude: Double, sensitive: Bool) -> RoundedCoordinate? {
        guard latitude.isFinite, longitude.isFinite,
              (-90...90).contains(latitude), (-180...180).contains(longitude) else { return nil }
        let places = sensitive ? sensitiveDecimals : normalDecimals
        let factor = pow(10.0, Double(places))
        return RoundedCoordinate(
            latitude: (latitude * factor).rounded() / factor,
            longitude: (longitude * factor).rounded() / factor
        )
    }

    /// Radius of the circle drawn on the map so people can see the spot is approximate.
    public static func displayRadiusMetres(sensitive: Bool) -> Double {
        sensitive ? 5_500 : 550
    }
}
