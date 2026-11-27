import SwiftUI

// The app's entry point. `@main` tells iOS "start here".
// An `App` describes the app's scenes — on iPhone, that's one window.
@main
struct LayoverApp: App {
    var body: some Scene {
        WindowGroup {
            ContentView()
                .tint(Theme.Colors.amber) // back buttons, links, cursors
        }
    }
}
