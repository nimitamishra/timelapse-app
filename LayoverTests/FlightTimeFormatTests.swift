import Testing
@testable import Layover

struct FlightTimeFormatTests {
    @Test(arguments: [
        (25 * 60.0, "25m"),
        (60 * 60.0, "1h"),
        (90 * 60.0, "1h 30m"),
        (120 * 60.0, "2h"),
    ])
    func shortFormat(seconds: Double, expected: String) {
        #expect(FlightTimeFormat.short(seconds) == expected)
    }

    @Test(arguments: [
        (46 * 60.0, "0:46"),
        (125 * 60.0, "2:05"),
        (5 * 60.0, "0:05"),
    ])
    func clockFormat(seconds: Double, expected: String) {
        #expect(FlightTimeFormat.clock(seconds) == expected)
    }

    @Test(arguments: [
        (0.0, "00:00"),
        (1_660.0, "27:40"),
        (3_725.0, "1:02:05"),
    ])
    func stopwatchFormat(seconds: Double, expected: String) {
        #expect(FlightTimeFormat.stopwatch(seconds) == expected)
    }
}
