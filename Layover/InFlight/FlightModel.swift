import Foundation
import Observation

/// Connects the pure `FlightSession` to the screen: button taps, leaving the app.
@Observable
final class FlightModel {
    private(set) var session: FlightSession
    /// True when the app put you in a holding pattern because you left it —
    /// the screen shows a "welcome back" note instead of a plain "Holding".
    private(set) var wasAutoHeld = false
    private let airports: [Airport]

    init(pass: BoardingPass, airports: [Airport], takeoff: Date = .now) {
        self.session = FlightSession(pass: pass, takeoff: takeoff)
        self.airports = airports
    }

    var outcome: FlightOutcome? {
        if case .landed(let outcome) = session.phase { return outcome }
        return nil
    }

    var isHolding: Bool { session.phase == .holding }

    func hold(at now: Date = .now) {
        session.hold(at: now)
        wasAutoHeld = false
    }

    func resume(at now: Date = .now) {
        session.resume(at: now)
        wasAutoHeld = false
    }

    /// Game rule: leaving the app mid-flight enters a holding pattern.
    func appLeftForeground(at now: Date = .now) {
        guard session.phase == .cruising else { return }
        session.hold(at: now)
        wasAutoHeld = true
    }

    /// What *would* happen if you landed now — shown in the "land early?" question.
    func previewLanding(at now: Date = .now) -> FlightOutcome {
        var copy = session  // structs are copied, so this doesn't touch the real flight
        return copy.land(at: now, airports: airports)
    }

    func land(at now: Date = .now) {
        session.land(at: now, airports: airports)
    }
}
