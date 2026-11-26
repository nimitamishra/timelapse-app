import CoreLocation

/// Asks iOS for the phone's location, once.
///
/// Location goes through Apple's CoreLocation framework. Two modern pieces:
/// - `CLServiceSession` tells iOS "this app needs location while it's open".
///   The first time, iOS shows the permission prompt using the message we
///   set in the project's Info.plist settings.
/// - `CLLocationUpdate.liveUpdates()` is a stream of location readings we
///   loop over with `for try await`; we stop at the first real one.
///
/// The location never leaves the phone — we only use it to find nearby airports.
enum LocationProvider {
    enum Failure: Error {
        case denied       // the person tapped "Don't Allow" (or it's off in Settings)
        case unavailable  // no reading, e.g. no GPS signal
    }

    static func currentCoordinate() async throws -> Coordinate {
        let session = CLServiceSession(authorization: .whenInUse)
        defer { session.invalidate() }

        for try await update in CLLocationUpdate.liveUpdates() {
            if update.authorizationDenied || update.authorizationDeniedGlobally {
                throw Failure.denied
            }
            if let location = update.location {
                return Coordinate(latitude: location.coordinate.latitude,
                                  longitude: location.coordinate.longitude)
            }
            // Other updates (e.g. "waiting for permission") — keep listening.
        }
        throw Failure.unavailable
    }
}
