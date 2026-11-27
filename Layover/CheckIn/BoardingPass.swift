import Foundation

/// Everything decided at Check-in, handed to the flight (milestone 4).
nonisolated struct BoardingPass: Hashable, Identifiable, Sendable {
    let id = UUID()
    let origin: Airport
    let destination: Airport
    let distanceKm: Double
    let flightTime: TimeInterval
    let task: String
    let estimate: TimeInterval
    let mode: FlightMode

    /// "LO 0045" — Layover's airline code plus the estimate in minutes. Just for fun.
    var flightNumber: String {
        String(format: "LO %04d", Int((estimate / 60).rounded()))
    }

    /// A seat that's always the same for the same route, e.g. "14A".
    var seat: String {
        let seed = (origin.iata + destination.iata).unicodeScalars.reduce(0) { $0 + Int($1.value) }
        let letters = ["A", "B", "C", "D", "E", "F"]
        return "\(seed % 30 + 1)\(letters[seed % letters.count])"
    }
}
