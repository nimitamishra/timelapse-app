import Foundation

/// How a flight ended. Built by `LandingRules` from the game rules in CLAUDE.md.
nonisolated struct FlightOutcome: Equatable, Sendable {
    enum Kind: Equatable, Sendable {
        /// Ended under 5 minutes — like a cancelled takeoff. No flight logged.
        case returnedToGate
        /// Ended below 80% of the estimate — landed at the airport nearest the plane.
        case diverted
        /// Ended at 80–100% of the estimate — arrived anyway.
        case tailwind
        /// Reached the estimate and kept going — landed on time, then explored.
        case layover(overtime: TimeInterval, postcards: Int)
    }

    let kind: Kind
    /// Where you ended up: origin (gate), the divert airport, or the destination.
    let landedAt: Airport
    /// Total focus time, holding patterns excluded.
    let focusTime: TimeInterval
    /// Distance credited to your logbook — based on time actually flown.
    let distanceKm: Double
}

/// The game rules as one pure function: same inputs, same answer, no clocks or UI.
/// That's what makes them easy to test — and easy to change in one place.
nonisolated enum LandingRules {
    static let tailwindThreshold = 0.8                 // ≥ 80% of estimate
    static let returnToGateLimit: TimeInterval = 5 * 60
    static let postcardInterval: TimeInterval = 15 * 60

    static func outcome(for pass: BoardingPass, focusTime: TimeInterval, airports: [Airport]) -> FlightOutcome {
        let fraction = focusTime / pass.estimate
        // "Miles logged = actual time flown": you get the share of the route you flew.
        let flownKm = pass.distanceKm * min(fraction, 1)

        if focusTime < returnToGateLimit {
            return FlightOutcome(kind: .returnedToGate, landedAt: pass.origin, focusTime: focusTime, distanceKm: 0)
        }

        if fraction >= 1 {
            let overtime = focusTime - pass.estimate
            let postcards = Int(overtime / postcardInterval)
            return FlightOutcome(kind: .layover(overtime: overtime, postcards: postcards),
                                 landedAt: pass.destination, focusTime: focusTime, distanceKm: pass.distanceKm)
        }

        if fraction >= tailwindThreshold {
            return FlightOutcome(kind: .tailwind, landedAt: pass.destination, focusTime: focusTime, distanceKm: flownKm)
        }

        let here = GreatCircle.intermediatePoint(from: pass.origin.coordinate,
                                                 to: pass.destination.coordinate,
                                                 fraction: fraction)
        let divertTo = divertAirport(near: here, pass: pass, airports: airports) ?? pass.origin
        return FlightOutcome(kind: .diverted, landedAt: divertTo, focusTime: focusTime, distanceKm: flownKm)
    }

    /// Nearest airport to the plane, skipping the origin and destination cities —
    /// "diverting" back home or onward to where you were going wouldn't be a divert.
    static func divertAirport(near point: Coordinate, pass: BoardingPass, airports: [Airport]) -> Airport? {
        airports
            .filter { $0.city != pass.origin.city && $0.city != pass.destination.city }
            .min { GreatCircle.distanceKm(from: point, to: $0.coordinate)
                 < GreatCircle.distanceKm(from: point, to: $1.coordinate) }
    }
}
