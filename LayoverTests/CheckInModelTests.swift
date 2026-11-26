import Testing
@testable import Layover

// The model lives on the main thread (like all UI state), so its tests do too.
@MainActor
struct CheckInModelTests {
    private let store: AirportStore
    private let model: CheckInModel

    init() throws {
        store = try AirportStore.loadBundled()
        model = CheckInModel(store: store, home: try #require(store.airport(code: "SFO")))
    }

    @Test func startsWithTheTopFlightSelected() {
        #expect(!model.suggestions.isEmpty)
        #expect(model.selectedID == model.suggestions.first?.id)
    }

    @Test func cannotBoardWithoutATask() {
        #expect(!model.canBoard)
        #expect(model.boardingPass() == nil)
        model.task = "   "
        #expect(!model.canBoard, "whitespace isn't a task")
    }

    @Test func boardingPassCarriesYourChoices() throws {
        model.task = "  Chem problem set "
        let pass = try #require(model.boardingPass())
        #expect(pass.task == "Chem problem set")
        #expect(pass.origin.iata == "SFO")
        #expect(pass.destination == model.selected?.airport)
        #expect(pass.estimate == model.estimate)
        #expect(pass.mode == model.mode)
    }

    @Test func switchingModeChangesTheBoard() {
        let compressed = model.suggestions.map(\.id)
        model.mode = .real
        #expect(model.suggestions.map(\.id) != compressed)
        #expect(model.selected != nil, "a flight is still selected after the board changes")
    }

    @Test func yourPickSurvivesWhenItIsStillOnTheBoard() throws {
        let second = try #require(model.suggestions.dropFirst().first)
        model.selectedID = second.id
        model.task = "Reading" // unrelated change
        #expect(model.selectedID == second.id)
    }

    @Test func estimateHasAFiveMinuteMinimum() {
        model.setEstimate(0)
        #expect(model.estimate == 5 * 60)
    }

    @Test func customEstimateIsDetected() {
        model.setEstimate(45 * 60)
        #expect(!model.isCustomEstimate)
        model.setEstimate(50 * 60)
        #expect(model.isCustomEstimate)
    }

    @Test func changingHomeRecomputesFromTheNewAirport() throws {
        model.home = try #require(store.airport(code: "LHR"))
        #expect(!model.suggestions.contains { $0.airport.city == "London" })
        #expect(model.draftPass?.origin.iata == "LHR")
    }
}
