import Foundation
import Testing
@testable import Layover

// The fake clock in action: `at(minutes: 30)` is "30 minutes after takeoff",
// so a 75-minute flight runs in a millisecond.
struct FlightSessionTests {
    private let airports = FlightTestSupport.store.airports
    private func at(_ minutes: Double) -> Date { FlightTestSupport.at(minutes: minutes) }

    private func newFlight() -> FlightSession {
        FlightSession(pass: FlightTestSupport.sfoToBogota(), takeoff: FlightTestSupport.takeoff)
    }

    @Test func focusTimeCountsWhileCruising() {
        let flight = newFlight()
        #expect(flight.focusTime(at: at(10)) == 10 * 60)
    }

    @Test func holdingPausesTheClock() {
        var flight = newFlight()
        flight.hold(at: at(10))
        #expect(flight.phase == .holding)
        #expect(flight.focusTime(at: at(25)) == 10 * 60, "15 minutes of holding don't count")
        flight.resume(at: at(25))
        #expect(flight.focusTime(at: at(30)) == 15 * 60)
    }

    @Test func impossibleMovesDoNothing() {
        var flight = newFlight()
        flight.resume(at: at(5))               // can't resume while cruising
        #expect(flight.phase == .cruising)
        flight.hold(at: at(10))
        flight.hold(at: at(20))                // can't hold twice
        flight.resume(at: at(20))
        #expect(flight.focusTime(at: at(20)) == 10 * 60)
    }

    @Test func landingFreezesEverything() {
        var flight = newFlight()
        let outcome = flight.land(at: at(40), airports: airports)
        #expect(outcome.kind == .tailwind)
        #expect(flight.phase == .landed(outcome))
        #expect(flight.focusTime(at: at(100)) == 40 * 60, "the clock stops at landing")
        flight.hold(at: at(50))
        flight.resume(at: at(55))
        #expect(flight.phase == .landed(outcome))
    }

    @Test func landingTwiceKeepsTheFirstResult() {
        var flight = newFlight()
        let first = flight.land(at: at(40), airports: airports)
        let second = flight.land(at: at(90), airports: airports)
        #expect(first == second)
    }

    @Test func landingWhileHoldingUsesOnlyFocusTime() {
        var flight = newFlight()
        flight.hold(at: at(20))
        let outcome = flight.land(at: at(60), airports: airports)
        #expect(outcome.focusTime == 20 * 60)
        #expect(outcome.kind == .diverted)
    }

    // Game rule: the plane lands exactly at your estimate.
    @Test func planeArrivesExactlyAtTheEstimate() {
        let flight = newFlight()
        #expect(flight.progress(at: at(22.5)) == 0.5)
        #expect(flight.progress(at: at(45)) == 1)
        #expect(flight.hasArrived(at: at(45)))
        #expect(!flight.hasArrived(at: at(44.9)))
    }

    @Test func planeStaysAtTheDestinationDuringALayover() {
        let flight = newFlight()
        #expect(flight.progress(at: at(80)) == 1)
        let bog = FlightTestSupport.store.airport(code: "BOG")!
        #expect(GreatCircle.distanceKm(from: flight.position(at: at(80)), to: bog.coordinate) < 0.01)
        #expect(flight.overtime(at: at(80)) == 35 * 60)
        #expect(flight.postcards(at: at(80)) == 2)
    }

    @Test func planePointsTowardBogota() {
        let flight = newFlight()
        // Bogotá is south-east of San Francisco.
        for minutes in [0.0, 22.5, 45, 80] {
            let heading = flight.heading(at: at(minutes))
            #expect(heading > 90 && heading < 180, "\(minutes) min: \(heading)°")
        }
    }

    @Test func planeStartsAtTheOrigin() {
        let flight = newFlight()
        let sfo = FlightTestSupport.store.airport(code: "SFO")!
        #expect(GreatCircle.distanceKm(from: flight.position(at: at(0)), to: sfo.coordinate) < 0.01)
    }
}

struct FlightProfileTests {
    @Test(arguments: [
        (0.0, 0),
        (0.05, 18_500),  // halfway up the climb
        (0.5, 37_000),   // cruising
        (0.95, 18_500),  // halfway down
        (1.0, 0),        // on the ground
    ])
    func altitudeFollowsClimbCruiseDescent(progress: Double, feet: Int) {
        #expect(FlightProfile.altitudeFt(progress: progress) == feet)
    }
}

// Leaving the app = holding pattern (game rule).
@MainActor
struct FlightModelTests {
    private func newModel() -> FlightModel {
        FlightModel(pass: FlightTestSupport.sfoToBogota(),
                    airports: FlightTestSupport.store.airports,
                    takeoff: FlightTestSupport.takeoff)
    }

    @Test func leavingTheAppEntersAHoldingPattern() {
        let model = newModel()
        model.appLeftForeground(at: FlightTestSupport.at(minutes: 10))
        #expect(model.isHolding)
        #expect(model.wasAutoHeld)
        model.resume(at: FlightTestSupport.at(minutes: 20))
        #expect(!model.isHolding)
        #expect(!model.wasAutoHeld)
    }

    @Test func leavingWhileAlreadyHoldingIsNotMarkedAutomatic() {
        let model = newModel()
        model.hold(at: FlightTestSupport.at(minutes: 10))
        model.appLeftForeground(at: FlightTestSupport.at(minutes: 11))
        #expect(!model.wasAutoHeld)
    }

    @Test func previewDoesNotActuallyLand() {
        let model = newModel()
        let preview = model.previewLanding(at: FlightTestSupport.at(minutes: 22.5))
        #expect(preview.kind == .diverted)
        #expect(model.outcome == nil)
    }
}
