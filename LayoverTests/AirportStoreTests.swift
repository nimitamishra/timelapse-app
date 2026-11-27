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

    @Test func everyFeaturedCodeExistsInTheData() {
        #expect(store.featuredCodes.count > 100)
        for code in store.featuredCodes {
            #expect(store.airport(code: code) != nil, "\(code) is featured but not in airports.json")
        }
    }

    // The Palo Alto case from CLAUDE.md: SJC and SFO are both close, so both are offered.
    @Test func nearestToPaloAltoOffersSjcSfoAndOak() {
        let paloAlto = Coordinate(latitude: 37.4419, longitude: -122.1430)
        let codes = store.nearest(to: paloAlto, limit: 3).map(\.airport.iata)
        #expect(codes == ["SJC", "SFO", "OAK"])
    }

    @Test func searchByExactCodeComesFirst() {
        #expect(store.search("sfo").first?.iata == "SFO")
    }

    @Test func searchByCityPrefix() {
        #expect(store.search("san fr").first?.iata == "SFO")
    }

    @Test func searchByAirportName() {
        #expect(store.search("kennedy").contains { $0.iata == "JFK" })
    }

    @Test func emptySearchReturnsNothing() {
        #expect(store.search("   ").isEmpty)
    }

    @Test func everyCoordinateIsOnEarth() {
        for airport in store.airports {
            #expect((-90...90).contains(airport.lat), "\(airport.iata) latitude")
            #expect((-180...180).contains(airport.lon), "\(airport.iata) longitude")
        }
    }
}
