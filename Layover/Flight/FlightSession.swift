import Foundation

/// One flight, from takeoff to landing — a small state machine.
///
///     cruising ⇄ holding
///        │          │
///        └──► landed ◄┘
///
/// Each state allows only certain moves (`hold` only while cruising, nothing
/// after landing), so impossible situations like "paused after landing" can't happen.
///
/// **Time comes from timestamps, not a ticking counter.** We store when the
/// current stretch of focus began plus the total of earlier stretches, and
/// compute focus time from the clock whenever asked. A counter would drift
/// and freeze when iOS suspends the app; timestamps are always right. Every
/// method takes `now`, so tests can pass fake times and "fast-forward" an hour instantly.
nonisolated struct FlightSession: Sendable {
    enum Phase: Equatable, Sendable {
        case cruising
        case holding
        case landed(FlightOutcome)
    }

    let pass: BoardingPass
    private(set) var phase: Phase = .cruising
    /// Focus time from stretches that have already ended (before a hold).
    private var banked: TimeInterval = 0
    /// When the current stretch of focus started; nil while holding or landed.
    private var stretchStart: Date?

    init(pass: BoardingPass, takeoff: Date) {
        self.pass = pass
        self.stretchStart = takeoff
    }

    // MARK: Moves

    mutating func hold(at now: Date) {
        guard phase == .cruising, let start = stretchStart else { return }
        banked += now.timeIntervalSince(start)
        stretchStart = nil
        phase = .holding
    }

    mutating func resume(at now: Date) {
        guard phase == .holding else { return }
        stretchStart = now
        phase = .cruising
    }

    /// Ends the flight and applies the landing rules. Landing twice returns the first result.
    @discardableResult
    mutating func land(at now: Date, airports: [Airport]) -> FlightOutcome {
        if case .landed(let outcome) = phase { return outcome }
        let total = focusTime(at: now)
        let outcome = LandingRules.outcome(for: pass, focusTime: total, airports: airports)
        banked = total
        stretchStart = nil
        phase = .landed(outcome)
        return outcome
    }

    // MARK: Questions (all derived from the clock)

    func focusTime(at now: Date) -> TimeInterval {
        banked + (stretchStart.map { max(0, now.timeIntervalSince($0)) } ?? 0)
    }

    /// 0 at takeoff, 1 at your estimate. The plane lands exactly when you
    /// planned, so its speed is your estimate, not the route's raw flight time.
    func progress(at now: Date) -> Double {
        min(1, focusTime(at: now) / pass.estimate)
    }

    func remaining(at now: Date) -> TimeInterval {
        max(0, pass.estimate - focusTime(at: now))
    }

    /// Past your estimate and still going = exploring on a layover.
    func overtime(at now: Date) -> TimeInterval {
        max(0, focusTime(at: now) - pass.estimate)
    }

    func hasArrived(at now: Date) -> Bool {
        focusTime(at: now) >= pass.estimate
    }

    func distanceFlownKm(at now: Date) -> Double {
        pass.distanceKm * progress(at: now)
    }

    /// Where the plane is right now, on the great-circle route.
    func position(at now: Date) -> Coordinate {
        GreatCircle.intermediatePoint(from: pass.origin.coordinate,
                                      to: pass.destination.coordinate,
                                      fraction: progress(at: now))
    }

    /// Postcards earned so far on a layover.
    func postcards(at now: Date) -> Int {
        Int(overtime(at: now) / LandingRules.postcardInterval)
    }
}

/// A believable altitude for the readout: climb over the first 10% of the
/// flight, cruise at 37,000 ft, descend over the last 10%, 0 once landed.
nonisolated enum FlightProfile {
    static let cruiseAltitudeFt = 37_000.0

    static func altitudeFt(progress: Double) -> Int {
        let p = min(max(progress, 0), 1)
        let factor: Double
        switch p {
        case ..<0.1:  factor = p / 0.1
        case 0.9...:  factor = (1 - p) / 0.1
        default:      factor = 1
        }
        return Int((cruiseAltitudeFt * factor / 100).rounded()) * 100 // to the nearest 100 ft
    }
}
