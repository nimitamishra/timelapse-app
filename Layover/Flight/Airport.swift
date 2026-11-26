import Foundation

/// A point on Earth in degrees. Our own tiny type (instead of Apple's
/// CLLocationCoordinate2D) so it can be Codable and compared with `==`.
///
/// `nonisolated` means "usable from any thread". This project defaults
/// everything to the main thread (good for UI code), but plain data and
/// math like this has no reason to be tied to it.
nonisolated struct Coordinate: Codable, Hashable, Sendable {
    var latitude: Double   // -90 (South Pole) … 90 (North Pole)
    var longitude: Double  // -180 … 180, 0 = Greenwich
}

/// One airport from the bundled OurAirports list.
nonisolated struct Airport: Codable, Hashable, Identifiable, Sendable {
    let iata: String     // "SFO" — what people know and what we show
    let name: String     // "San Francisco International Airport"
    let city: String     // "San Francisco"
    let country: String  // ISO code: "US", "CO", "IN"
    let lat: Double
    let lon: Double

    /// Identifiable lets SwiftUI lists tell airports apart. IATA codes are unique.
    var id: String { iata }

    var coordinate: Coordinate { Coordinate(latitude: lat, longitude: lon) }

    /// "Colombia" from "CO", in the phone's language.
    var countryName: String {
        Locale.current.localizedString(forRegionCode: country) ?? country
    }
}
