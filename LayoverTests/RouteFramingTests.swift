import Testing
@testable import Layover

private let sfo = Coordinate(latitude: 37.6198, longitude: -122.3748)
private let lax = Coordinate(latitude: 33.9425, longitude: -118.4080)
private let jfk = Coordinate(latitude: 40.6394, longitude: -73.7793)
private let lhr = Coordinate(latitude: 51.4707, longitude: -0.4599)
private let hnd = Coordinate(latitude: 35.5523, longitude: 139.7798) // Tokyo Haneda

struct RouteFramingTests {
    /// Is `point` inside the frame? (Handles a frame that straddles the date line.)
    private func contains(_ frame: RouteFraming.Frame, _ point: Coordinate) -> Bool {
        var dLon = point.longitude - frame.center.longitude
        while dLon > 180 { dLon -= 360 }
        while dLon < -180 { dLon += 360 }
        return abs(point.latitude - frame.center.latitude) <= frame.latitudeSpan / 2
            && abs(dLon) <= frame.longitudeSpan / 2
    }

    @Test func bothAirportsAreInView() {
        let frame = RouteFraming.frame(from: sfo, to: jfk)
        #expect(contains(frame, sfo))
        #expect(contains(frame, jfk))
    }

    @Test func theNorthwardBulgeIsInView() {
        let frame = RouteFraming.frame(from: jfk, to: lhr)
        let top = GreatCircle.intermediatePoint(from: jfk, to: lhr, fraction: 0.5)
        #expect(contains(frame, top))
    }

    @Test func dateLineRouteIsFramedOverThePacific() {
        let frame = RouteFraming.frame(from: hnd, to: sfo)
        // Centred over the Pacific (near ±180°), not over Europe/Africa (near 0°).
        #expect(abs(frame.center.longitude) > 150)
        #expect(frame.longitudeSpan < 180)
        #expect(contains(frame, hnd))
        #expect(contains(frame, sfo))
    }

    @Test func shortHopsDontZoomInTooFar() {
        let frame = RouteFraming.frame(from: sfo, to: lax)
        #expect(frame.latitudeSpan >= RouteFraming.minimumSpan)
        #expect(frame.longitudeSpan >= RouteFraming.minimumSpan)
    }
}
