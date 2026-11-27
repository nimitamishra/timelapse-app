import Testing
@testable import Layover

// Known airports, written out here so these tests don't depend on the JSON file.
private let sfo = Coordinate(latitude: 37.6198, longitude: -122.3748)
private let jfk = Coordinate(latitude: 40.6394, longitude: -73.7793)
private let lax = Coordinate(latitude: 33.9425, longitude: -118.4080)
private let lhr = Coordinate(latitude: 51.4707, longitude: -0.4599)

struct GreatCircleTests {

    // Real-world distances (published flight distances) with a 1% tolerance.
    @Test func sfoToJfkIsAbout4150Km() {
        let d = GreatCircle.distanceKm(from: sfo, to: jfk)
        #expect(abs(d - 4_152) < 42)
    }

    @Test func sfoToLaxIsAbout543Km() {
        let d = GreatCircle.distanceKm(from: sfo, to: lax)
        #expect(abs(d - 543) < 6)
    }

    @Test func distanceIsTheSameInBothDirections() {
        #expect(GreatCircle.distanceKm(from: sfo, to: jfk) == GreatCircle.distanceKm(from: jfk, to: sfo))
    }

    @Test func distanceToYourselfIsZero() {
        #expect(GreatCircle.distanceKm(from: sfo, to: sfo) == 0)
    }

    @Test func routeStartsAtOriginAndEndsAtDestination() {
        let start = GreatCircle.intermediatePoint(from: jfk, to: lhr, fraction: 0)
        let end = GreatCircle.intermediatePoint(from: jfk, to: lhr, fraction: 1)
        #expect(GreatCircle.distanceKm(from: start, to: jfk) < 0.01)
        #expect(GreatCircle.distanceKm(from: end, to: lhr) < 0.01)
    }

    @Test func halfwayPointIsHalfwayAlongTheRoute() {
        let total = GreatCircle.distanceKm(from: jfk, to: lhr)
        let mid = GreatCircle.intermediatePoint(from: jfk, to: lhr, fraction: 0.5)
        #expect(abs(GreatCircle.distanceKm(from: jfk, to: mid) - total / 2) < 1)
        #expect(abs(GreatCircle.distanceKm(from: mid, to: lhr) - total / 2) < 1)
    }

    // The fun one: a great circle bulges toward the pole. Halfway from
    // New York to London you're further north than London itself.
    @Test func newYorkToLondonCurvesNorth() {
        let mid = GreatCircle.intermediatePoint(from: jfk, to: lhr, fraction: 0.5)
        #expect(mid.latitude > lhr.latitude)
        #expect(mid.latitude > jfk.latitude)
    }

    // MARK: Heading

    // Straight up and down a line of longitude, or along the equator: easy answers.
    @Test(arguments: [
        (Coordinate(latitude: 10, longitude: 0), 0.0),     // north
        (Coordinate(latitude: 0, longitude: 10), 90.0),    // east
        (Coordinate(latitude: -10, longitude: 0), 180.0),  // south
        (Coordinate(latitude: 0, longitude: -10), 270.0),  // west
    ])
    func compassPoints(to target: Coordinate, expected: Double) {
        let origin = Coordinate(latitude: 0, longitude: 0)
        #expect(abs(GreatCircle.initialBearing(from: origin, to: target) - expected) < 0.001)
    }

    // Published initial course New York → London is about 51°: northeast, not due east.
    @Test func newYorkToLondonSetsOffNortheast() {
        #expect(abs(GreatCircle.initialBearing(from: jfk, to: lhr) - 51) < 2)
    }

    // ...and the plane arrives pointing southeast-ish, because the route curves.
    @Test func headingTurnsAlongTheRoute() {
        let nearLondon = GreatCircle.intermediatePoint(from: jfk, to: lhr, fraction: 0.99)
        #expect(GreatCircle.initialBearing(from: nearLondon, to: lhr) > 100)
    }

    // Crossing the date line (Tokyo → SFO) must still point east, not swing round west.
    @Test func crossingTheDateLineStillHeadsEast() {
        let tokyo = Coordinate(latitude: 35.55, longitude: 139.78)
        let heading = GreatCircle.initialBearing(from: tokyo, to: sfo)
        #expect(heading > 0 && heading < 90)
    }
}
