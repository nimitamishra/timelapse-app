import SwiftUI

// Placeholder first screen. Milestone 1 replaces this with the
// night-cockpit theme; milestone 3 turns it into the Check-in screen.
struct ContentView: View {
    var body: some View {
        VStack(spacing: 12) {
            Image(systemName: "airplane.departure")
                .font(.system(size: 48))
                .foregroundStyle(.tint)
            Text("Layover")
                .font(.largeTitle.bold())
            Text("Cleared for takeoff.")
                .foregroundStyle(.secondary)
        }
    }
}

// Lets Xcode draw this view live in the canvas while you edit.
#Preview {
    ContentView()
}
