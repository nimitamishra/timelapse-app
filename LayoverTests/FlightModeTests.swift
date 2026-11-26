import Foundation
import Testing
@testable import Layover

// These tests ARE the game rules from CLAUDE.md. If someone changes the
// speeds by accident, a test fails and tells them.
struct FlightModeTests {
    private let oneHour: TimeInterval = 3_600

    @Test func realModeFlies800KmPerHour() {
        #expect(abs(FlightMode.real.distanceKm(for: oneHour) - 800) < 0.001)
    }

    @Test func compressedModeIsTenTimesReal() {
        #expect(abs(FlightMode.compressed.distanceKm(for: oneHour) - 8_000) < 0.001)
    }

    // A parameterized test: Swift Testing runs it once per mode.
    @Test(arguments: FlightMode.allCases)
    func distanceAndTimeConvertBothWays(mode: FlightMode) {
        let time: TimeInterval = 45 * 60
        let roundTrip = mode.flightTime(forDistanceKm: mode.distanceKm(for: time))
        #expect(abs(roundTrip - time) < 0.001)
    }

    @Test func sfoToJfkTakesAboutFiveHoursInRealMode() {
        let hours = FlightMode.real.flightTime(forDistanceKm: 4_152) / oneHour
        #expect(abs(hours - 5.19) < 0.01)
    }
}
