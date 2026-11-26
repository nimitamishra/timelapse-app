import Foundation

/// One row on the Check-in screen's departures board.
nonisolated struct DestinationSuggestion: Identifiable, Hashable, Sendable {
    let airport: Airport
    let distanceKm: Double
    let flightTime: TimeInterval

    var id: String { airport.id }
}

/// Answers: "I think this task takes 45 minutes — where can I fly?"
nonisolated enum DestinationFinder {

    /// Airports whose flight time from `origin` is closest to `estimate`.
    ///
    /// Steps:
    /// 1. Work out every airport's flight time in the chosen mode.
    /// 2. Sort by how far that time is from the estimate (closest first).
    /// 3. Keep one airport per city, so the board doesn't show
    ///    JFK, LGA and EWR as three "different" trips to New York.
    static func suggestions(
        from origin: Airport,
        estimate: TimeInterval,
        mode: FlightMode,
        airports: [Airport],
        limit: Int = 5
    ) -> [DestinationSuggestion] {
        let candidates = airports
            .filter { $0.iata != origin.iata && $0.city != origin.city }
            .map { airport in
                let distance = GreatCircle.distanceKm(from: origin.coordinate, to: airport.coordinate)
                return DestinationSuggestion(
                    airport: airport,
                    distanceKm: distance,
                    flightTime: mode.flightTime(forDistanceKm: distance)
                )
            }
            .sorted { abs($0.flightTime - estimate) < abs($1.flightTime - estimate) }

        var seenCities = Set<String>()
        var results: [DestinationSuggestion] = []
        for suggestion in candidates where results.count < limit {
            let cityKey = "\(suggestion.airport.city)|\(suggestion.airport.country)"
            if seenCities.insert(cityKey).inserted {
                results.append(suggestion)
            }
        }
        return results
    }
}
