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

    /// Airports whose flight time from `origin` is close to `estimate`,
    /// preferring famous ones.
    ///
    /// Steps:
    /// 1. Work out every airport's flight time in the chosen mode.
    /// 2. Sort by how far that time is from the estimate (closest first).
    /// 3. Famous airports that land inside a "close enough" window jump to
    ///    the front — LAX beats Ontario, CA when both are ~45 min away.
    /// 4. Keep one airport per city, so the board doesn't show
    ///    JFK, LGA and EWR as three "different" trips to New York.
    static func suggestions(
        from origin: Airport,
        estimate: TimeInterval,
        mode: FlightMode,
        airports: [Airport],
        featured: Set<String> = [],
        limit: Int = 5
    ) -> [DestinationSuggestion] {
        let window = closeEnoughWindow(for: estimate)

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
            .sorted { lhs, rhs in
                let lGap = abs(lhs.flightTime - estimate)
                let rGap = abs(rhs.flightTime - estimate)
                let lFamous = featured.contains(lhs.airport.iata) && lGap <= window
                let rFamous = featured.contains(rhs.airport.iata) && rGap <= window
                if lFamous != rFamous { return lFamous }  // famous-and-close first
                return lGap < rGap                        // then closest time
            }

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

    /// How far off the estimate a famous airport may be and still get priority:
    /// 15% of the estimate, but never less than 5 minutes.
    /// (45 min → ±6.75 min; 2 h → ±18 min; 20 min → ±5 min.)
    static func closeEnoughWindow(for estimate: TimeInterval) -> TimeInterval {
        max(5 * 60, estimate * 0.15)
    }
}
