import Testing
@testable import Layover

// Checks the bundled airports.json is loadable and sane.
struct AirportStoreTests {
    private let store: AirportStore

    // Swift Testing creates a fresh instance for every test, so this runs each time.
    init() throws {
        store = try AirportStore.loadBundled()
    }

    @Test func loadsOverAThousandAirports() {
        #expect(store.airports.count > 1_000)
    }

    @Test func everyCodeIsUnique() {
        let codes = store.airports.map(\.iata)
        #expect(Set(codes).count == codes.count)
    }

    @Test func findsSanFranciscoByCode() throws {
        let sfo = try #require(store.airport(code: "SFO"))
        #expect(sfo.city == "San Francisco")
        #expect(sfo.country == "US")
    }

    @Test func lookupIgnoresCase() {
        #expect(store.airport(code: "jfk")?.iata == "JFK")
    }

    @Test func everyCoordinateIsOnEarth() {
        for airport in store.airports {
            #expect((-90...90).contains(airport.lat), "\(airport.iata) latitude")
            #expect((-180...180).contains(airport.lon), "\(airport.iata) longitude")
        }
    }
}
