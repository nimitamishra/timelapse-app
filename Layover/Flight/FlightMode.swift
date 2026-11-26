import Foundation

/// How focus time turns into distance. These numbers come straight from
/// the game rules in CLAUDE.md — change them there first, then here.
nonisolated enum FlightMode: String, Codable, CaseIterable, Sendable {
    /// True to life: an hour of focus flies you 800 km.
    case real
    /// 10× real speed, so short sessions still reach exciting places.
    case compressed

    static let realSpeedKmPerHour = 800.0
    static let compressedMultiplier = 10.0

    /// Speed in km per second of focus. Everything else derives from this one number.
    var kmPerSecond: Double {
        let real = Self.realSpeedKmPerHour / 3_600
        switch self {
        case .real:       return real
        case .compressed: return real * Self.compressedMultiplier
        }
    }

    /// How far you get in a given amount of focus time.
    /// `TimeInterval` is Apple's name for a number of seconds.
    func distanceKm(for focusTime: TimeInterval) -> Double {
        focusTime * kmPerSecond
    }

    /// How long a route takes to fly.
    func flightTime(forDistanceKm distance: Double) -> TimeInterval {
        distance / kmPerSecond
    }
}
