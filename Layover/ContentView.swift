import SwiftUI

/// Decides which screen to show:
/// no home airport yet → the home picker; otherwise → Check-in.
struct ContentView: View {
    /// `@AppStorage` saves a small value on the phone (in UserDefaults) and
    /// redraws the view when it changes. Empty string = not chosen yet.
    @AppStorage("homeAirportCode") private var homeCode = ""
    @State private var store: AirportStore? = try? AirportStore.loadBundled()

    var body: some View {
        if let store {
            if let home = store.airport(code: homeCode) {
                // NavigationStack lets Check-in push the next screen on top of itself.
                NavigationStack {
                    CheckInView(store: store, home: home) { homeCode = $0.iata }
                }
            } else {
                HomeAirportPicker(store: store) { homeCode = $0.iata }
            }
        } else {
            // Only happens if the airport files are missing from the app — a build problem.
            ContentUnavailableView("Airport data missing", systemImage: "exclamationmark.triangle")
        }
    }
}

#Preview {
    ContentView()
}
