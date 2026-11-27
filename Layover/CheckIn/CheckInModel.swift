import Foundation
import Observation

/// The Check-in screen's state and logic, kept out of the view so it can be tested.
///
/// `@Observable` makes SwiftUI watch this class: when a property a view
/// reads changes (say `mode`), only the views that read it redraw.
@Observable
final class CheckInModel {
    /// The quick chips: 25m, 45m, 1h, 2h.
    static let quickEstimates: [TimeInterval] = [25 * 60, 45 * 60, 60 * 60, 120 * 60]
    /// Shortest estimate allowed — a 0-minute flight isn't a flight.
    static let minimumEstimate: TimeInterval = 5 * 60

    let store: AirportStore

    // `didSet` runs after the value changes: any input that affects
    // where you can fly recomputes the departures board.
    var home: Airport { didSet { refreshSuggestions() } }
    var estimate: TimeInterval = 45 * 60 { didSet { refreshSuggestions() } }
    var mode: FlightMode = .compressed { didSet { refreshSuggestions() } }
    var task = ""

    /// `private(set)`: views can read the board but only the model changes it.
    private(set) var suggestions: [DestinationSuggestion] = []
    var selectedID: DestinationSuggestion.ID?

    init(store: AirportStore, home: Airport) {
        self.store = store
        self.home = home
        refreshSuggestions() // didSet doesn't run during init, so do it once here
    }

    var selected: DestinationSuggestion? {
        suggestions.first { $0.id == selectedID }
    }

    var isCustomEstimate: Bool {
        !Self.quickEstimates.contains(estimate)
    }

    private var trimmedTask: String {
        task.trimmingCharacters(in: .whitespacesAndNewlines)
    }

    /// You need a task and a destination to board.
    var canBoard: Bool {
        selected != nil && !trimmedTask.isEmpty
    }

    func setEstimate(_ seconds: TimeInterval) {
        estimate = max(Self.minimumEstimate, seconds)
    }

    /// The ticket as it stands right now — shown live while you fill things in.
    var draftPass: BoardingPass? {
        guard let selected else { return nil }
        return BoardingPass(
            origin: home,
            destination: selected.airport,
            distanceKm: selected.distanceKm,
            flightTime: selected.flightTime,
            task: trimmedTask,
            estimate: estimate,
            mode: mode
        )
    }

    /// The final ticket, only once you're allowed to board.
    func boardingPass() -> BoardingPass? {
        canBoard ? draftPass : nil
    }

    private func refreshSuggestions() {
        suggestions = DestinationFinder.suggestions(
            from: home,
            estimate: estimate,
            mode: mode,
            airports: store.airports,
            featured: store.featuredCodes
        )
        // Keep your pick if it's still on the board; otherwise pick the top row.
        if selected == nil {
            selectedID = suggestions.first?.id
        }
    }
}
