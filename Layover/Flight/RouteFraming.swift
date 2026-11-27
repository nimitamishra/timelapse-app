import Foundation

/// Works out the map view that fits a whole route: a centre point plus how
/// many degrees tall and wide the view should be.
///
/// Two traps this avoids:
/// - **The curve bulges.** A great circle can swing well north of both
///   airports (New York → London peaks over the Atlantic near 52°N), so we
///   frame points sampled along the whole route, not just the two ends.
/// - **The date line.** Tokyo is at +140° and San Francisco at −122°. Naively
///   that's 262° apart — a view of the whole planet the wrong way round. So we
///   "unwrap" longitudes to stay within 180° of the origin (−122° becomes
///   +238°), measure, then wrap the centre back into −180…180.
nonisolated enum RouteFraming {
    struct Frame: Equatable, Sendable {
        var center: Coordinate
        var latitudeSpan: Double   // degrees, top to bottom
        var longitudeSpan: Double  // degrees, left to right
    }

    /// Extra room around the route so the airports aren't on the very edge.
    static let padding = 1.4
    /// Never zoom in closer than this, even for a hop like SFO → LAX.
    static let minimumSpan = 4.0

    static func frame(from a: Coordinate, to b: Coordinate, samples: Int = 32) -> Frame {
        let points = (0...samples).map {
            GreatCircle.intermediatePoint(from: a, to: b, fraction: Double($0) / Double(samples))
        }
        let lats = points.map(\.latitude)
        let lons = points.map { unwrap($0.longitude, near: a.longitude) }

        let minLat = lats.min()!, maxLat = lats.max()!
        let minLon = lons.min()!, maxLon = lons.max()!

        return Frame(
            center: Coordinate(latitude: (minLat + maxLat) / 2,
                               longitude: wrap((minLon + maxLon) / 2)),
            latitudeSpan: min(max((maxLat - minLat) * padding, minimumSpan), 170),
            longitudeSpan: min(max((maxLon - minLon) * padding, minimumSpan), 360)
        )
    }

    /// Shift `longitude` by whole turns so it's within 180° of `reference`.
    private static func unwrap(_ longitude: Double, near reference: Double) -> Double {
        var l = longitude
        while l - reference > 180 { l -= 360 }
        while l - reference < -180 { l += 360 }
        return l
    }

    /// Bring any longitude back into −180…180.
    private static func wrap(_ longitude: Double) -> Double {
        var l = longitude.truncatingRemainder(dividingBy: 360)
        if l > 180 { l -= 360 }
        if l < -180 { l += 360 }
        return l
    }
}
