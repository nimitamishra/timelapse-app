import Foundation
import Testing
@testable import Layover

struct DestinationFinderTests {

    private static func airport(_ code: String, _ city: String, _ lat: Double, _ lon: Double) -> Airport {
        Airport(iata: code, name: "\(city) Airport", city: city, country: "US", lat: lat, lon: lon)
    }

    // A small hand-made world so results are predictable.
    private let sfo = airport("SFO", "San Francisco", 37.6198, -122.3748)
    private let oak = airport("OAK", "Oakland", 37.7213, -122.2208)
    private let lax = airport("LAX", "Los Angeles", 33.9425, -118.4080)
    private let bur = airport("BUR", "Los Angeles", 34.2007, -118.3585) // same city as LAX
    private let las = airport("LAS", "Las Vegas", 36.0840, -115.1537)
    private let jfk = airport("JFK", "New York", 40.6394, -73.7793)

    private var world: [Airport] { [sfo, oak, lax, bur, las, jfk] }

    @Test func closestFlightTimeComesFirst() {
        // SFO → LAX is ~543 km ≈ 41 min in real mode.
        let results = DestinationFinder.suggestions(from: sfo, estimate: 41 * 60, mode: .real, airports: world)
        #expect(results.first?.airport.iata == "LAX")
    }

    @Test func neverSuggestsWhereYouAlreadyAre() {
        let results = DestinationFinder.suggestions(from: sfo, estimate: 60, mode: .real, airports: world)
        #expect(!results.contains { $0.airport.iata == "SFO" })
    }

    @Test func showsOnlyOneAirportPerCity() {
        let results = DestinationFinder.suggestions(from: sfo, estimate: 41 * 60, mode: .real, airports: world, limit: 10)
        let cities = results.map(\.airport.city)
        #expect(Set(cities).count == cities.count)
    }

    @Test func respectsTheLimit() {
        let results = DestinationFinder.suggestions(from: sfo, estimate: 3_600, mode: .real, airports: world, limit: 2)
        #expect(results.count == 2)
    }

    @Test func resultsAreSortedByClosenessToEstimate() {
        let estimate: TimeInterval = 50 * 60
        let results = DestinationFinder.suggestions(from: sfo, estimate: estimate, mode: .real, airports: world, limit: 10)
        let gaps = results.map { abs($0.flightTime - estimate) }
        #expect(gaps == gaps.sorted())
    }

    @Test func compressedModeReachesFurther() {
        // 31 minutes compressed ≈ 4,130 km — that's New York, not LA.
        let results = DestinationFinder.suggestions(from: sfo, estimate: 31 * 60, mode: .compressed, airports: world)
        #expect(results.first?.airport.iata == "JFK")
    }

    // MARK: Famous airports (game rule: favor featured airports)
    // From SFO in real mode: LAX ≈ 40.7 min, LAS ≈ 49.9 min.

    @Test func withoutFeaturedListClosestTimeWins() {
        let results = DestinationFinder.suggestions(from: sfo, estimate: 44 * 60, mode: .real, airports: world)
        #expect(results.first?.airport.iata == "LAX") // 3.3 min off vs LAS 5.9 min off
    }

    @Test func famousAirportInsideWindowJumpsAhead() {
        // 44 min → window ±6.6 min. LAS (5.9 min off) is inside it, so it wins.
        let results = DestinationFinder.suggestions(from: sfo, estimate: 44 * 60, mode: .real,
                                                    airports: world, featured: ["LAS"])
        #expect(results.first?.airport.iata == "LAS")
    }

    @Test func famousAirportOutsideWindowDoesNotJumpAhead() {
        // 41 min → window ±6.15 min. LAS is 8.9 min off: too far, so the
        // closest time (LAX, 0.3 min off) stays first.
        let results = DestinationFinder.suggestions(from: sfo, estimate: 41 * 60, mode: .real,
                                                    airports: world, featured: ["LAS"])
        #expect(results.first?.airport.iata == "LAX")
    }

    @Test func windowIsFifteenPercentButAtLeastFiveMinutes() {
        #expect(DestinationFinder.closeEnoughWindow(for: 120 * 60) == 18 * 60)
        #expect(DestinationFinder.closeEnoughWindow(for: 20 * 60) == 5 * 60)
    }

    // Uses the real bundled data: from SFO, a 45-min compressed session
    // should offer flights within ~10 minutes of the estimate.
    @Test func realDataGivesSensibleSuggestions() throws {
        let store = try AirportStore.loadBundled()
        let home = try #require(store.airport(code: "SFO"))
        let results = DestinationFinder.suggestions(from: home, estimate: 45 * 60, mode: .compressed,
                                                    airports: store.airports, featured: store.featuredCodes)
        #expect(results.count == 5)
        for suggestion in results {
            #expect(abs(suggestion.flightTime - 45 * 60) < 10 * 60, "\(suggestion.airport.iata)")
        }
        // With the featured list, the top pick should be a famous airport.
        let top = try #require(results.first)
        #expect(store.isFeatured(top.airport), "\(top.airport.iata)")
    }
}
