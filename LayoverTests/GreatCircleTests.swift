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
}
