import Foundation
import Testing
@testable import Layover

// Each test is one game rule from CLAUDE.md, for an SFO → Bogotá flight
// estimated at 45 minutes (80% = 36:00, 5-minute gate limit, postcards every 15 min).
struct LandingRulesTests {
    private let pass = FlightTestSupport.sfoToBogota()
    private let airports = FlightTestSupport.store.airports

    private func outcome(minutes: Double) -> FlightOutcome {
        LandingRules.outcome(for: pass, focusTime: minutes * 60, airports: airports)
    }

    // MARK: Returned to gate (under 5 minutes)

    @Test func underFiveMinutesReturnsToGateWithNoMiles() {
        let o = outcome(minutes: 4 + 59.0 / 60)
        #expect(o.kind == .returnedToGate)
        #expect(o.landedAt.iata == "SFO")
        #expect(o.distanceKm == 0)
    }

    @Test func exactlyFiveMinutesIsAFlight() {
        #expect(outcome(minutes: 5).kind != .returnedToGate)
    }

    // MARK: Diverted (below 80%)

    @Test func halfwayDivertsToVeracruz() {
        // Halfway along SFO → BOG the plane is over the Gulf of Mexico; Veracruz is nearest.
        let o = outcome(minutes: 22.5)
        #expect(o.kind == .diverted)
        #expect(o.landedAt.iata == "VER")
    }

    @Test func divertNeverLandsAtOriginOrDestinationCity() {
        for minutes in stride(from: 5.0, to: 36, by: 3) {
            let o = outcome(minutes: minutes)
            #expect(o.landedAt.city != "San Francisco", "\(minutes) min")
            #expect(o.landedAt.city != pass.destination.city, "\(minutes) min")
        }
    }

    @Test func divertedMilesMatchTimeFlown() {
        let o = outcome(minutes: 30)
        #expect(abs(o.distanceKm - pass.distanceKm * 30 / 45) < 0.001)
    }

    @Test func justUnderEightyPercentStillDiverts() {
        #expect(outcome(minutes: 35 + 59.0 / 60).kind == .diverted)
    }

    // MARK: Tailwind (80–100%)

    @Test func exactlyEightyPercentIsATailwind() {
        let o = outcome(minutes: 36)
        #expect(o.kind == .tailwind)
        #expect(o.landedAt.iata == "BOG")
    }

    @Test func tailwindLogsOnlyTheMilesYouFlew() {
        let o = outcome(minutes: 40)
        #expect(o.kind == .tailwind)
        #expect(abs(o.distanceKm - pass.distanceKm * 40 / 45) < 0.001)
    }

    // MARK: Layover (at or past the estimate)

    @Test func reachingTheEstimateIsALayoverWithNoPostcardsYet() {
        let o = outcome(minutes: 45)
        #expect(o.kind == .layover(overtime: 0, postcards: 0))
        #expect(o.landedAt.iata == "BOG")
        #expect(abs(o.distanceKm - pass.distanceKm) < 0.001)
    }

    @Test(arguments: [
        (59.0, 0),   // 14 min over
        (60.0, 1),   // 15 min over
        (74.9, 1),   // just under 30 min over
        (75.0, 2),   // 30 min over
    ])
    func onePostcardPerFifteenMinutesOver(minutes: Double, postcards: Int) {
        guard case .layover(_, let earned) = outcome(minutes: minutes).kind else {
            Issue.record("expected a layover")
            return
        }
        #expect(earned == postcards)
    }
}
