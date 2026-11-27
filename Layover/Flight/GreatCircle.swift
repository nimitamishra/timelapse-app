import Foundation

/// Math for routes on a round Earth.
///
/// Planes fly "great circle" routes — the shortest path over a sphere. On a
/// flat map these look curved (SFO → London arcs up over Greenland), but on
/// the globe they're the straightest line possible.
nonisolated enum GreatCircle {
    /// Earth's mean radius. Treating Earth as a perfect sphere is off by
    /// at most ~0.5% — invisible for a focus timer.
    static let earthRadiusKm = 6_371.0

    /// Distance between two points, using the haversine formula.
    ///
    /// The idea: convert both points to angles (radians), work out the
    /// angle between them as seen from Earth's centre, then multiply that
    /// angle by the radius to get an arc length — like measuring a slice of pizza crust.
    static func distanceKm(from a: Coordinate, to b: Coordinate) -> Double {
        let lat1 = a.latitude.radians
        let lat2 = b.latitude.radians
        let dLat = lat2 - lat1
        let dLon = (b.longitude - a.longitude).radians

        // h is the "haversine" of the central angle, a value from 0 to 1.
        let h = sin(dLat / 2) * sin(dLat / 2)
              + cos(lat1) * cos(lat2) * sin(dLon / 2) * sin(dLon / 2)

        // min(1, …) guards against tiny floating-point overshoots above 1.
        let centralAngle = 2 * asin(min(1, sqrt(h)))
        return earthRadiusKm * centralAngle
    }

    /// The point a given fraction of the way along the route
    /// (0 = origin, 0.5 = halfway, 1 = destination). Milestone 5 uses this
    /// to place the plane on the map.
    ///
    /// How: turn both points into 3D positions on a unit sphere, blend them
    /// with weights that keep the result on the sphere's surface
    /// ("spherical interpolation"), then turn the 3D point back into lat/lon.
    static func intermediatePoint(from a: Coordinate, to b: Coordinate, fraction: Double) -> Coordinate {
        let f = min(max(fraction, 0), 1)
        let angle = distanceKm(from: a, to: b) / earthRadiusKm
        // Same point, or exactly opposite sides of Earth (no unique route): nothing to blend.
        guard sin(angle) > 1e-12 else { return f < 0.5 ? a : b }

        let lat1 = a.latitude.radians, lon1 = a.longitude.radians
        let lat2 = b.latitude.radians, lon2 = b.longitude.radians

        let wA = sin((1 - f) * angle) / sin(angle)
        let wB = sin(f * angle) / sin(angle)

        let x = wA * cos(lat1) * cos(lon1) + wB * cos(lat2) * cos(lon2)
        let y = wA * cos(lat1) * sin(lon1) + wB * cos(lat2) * sin(lon2)
        let z = wA * sin(lat1) + wB * sin(lat2)

        return Coordinate(
            latitude: atan2(z, sqrt(x * x + y * y)).degrees,
            longitude: atan2(y, x).degrees
        )
    }

    /// The compass direction to set off in, to fly the great circle from `a`
    /// to `b`: 0° = north, 90° = east, 180° = south, 270° = west.
    ///
    /// "Initial" because on a great circle the heading keeps changing — leaving
    /// New York for London you start out pointing northeast and arrive pointing
    /// southeast. So the map asks again every second from wherever the plane is.
    static func initialBearing(from a: Coordinate, to b: Coordinate) -> Double {
        let lat1 = a.latitude.radians
        let lat2 = b.latitude.radians
        let dLon = (b.longitude - a.longitude).radians
        // East–west part and north–south part of the direction, then the angle between them.
        let east = sin(dLon) * cos(lat2)
        let north = cos(lat1) * sin(lat2) - sin(lat1) * cos(lat2) * cos(dLon)
        let degrees = atan2(east, north).degrees
        return (degrees + 360).truncatingRemainder(dividingBy: 360) // -90° → 270°
    }
}

// Trig functions work in radians (a full circle = 2π); coordinates are in degrees (360).
nonisolated extension Double {
    var radians: Double { self * .pi / 180 }
    var degrees: Double { self * 180 / .pi }
}
