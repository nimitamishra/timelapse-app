import Foundation
@testable import Layover

/// Shared setup for flight tests: real airports, a fake clock, and an
/// SFO → Bogotá flight with a 45-minute estimate.
enum FlightTestSupport {
    static let store = try! AirportStore.loadBundled()

    /// The fake clock's "takeoff" moment. Tests add minutes to it.
    static let takeoff = Date(timeIntervalSinceReferenceDate: 0)

    static func at(minutes: Double) -> Date {
        takeoff.addingTimeInterval(minutes * 60)
    }

    static func sfoToBogota(estimateMinutes: Double = 45) -> BoardingPass {
        let sfo = store.airport(code: "SFO")!
        let bog = store.airport(code: "BOG")!
        let distance = GreatCircle.distanceKm(from: sfo.coordinate, to: bog.coordinate)
        return BoardingPass(origin: sfo, destination: bog, distanceKm: distance,
                            flightTime: FlightMode.compressed.flightTime(forDistanceKm: distance),
                            task: "Chem problem set", estimate: estimateMinutes * 60, mode: .compressed)
    }
}
