import SwiftUI

// The app's first screen. For milestone 1 it shows the theme gallery;
// milestone 3 turns it into the Check-in screen.
struct ContentView: View {
    var body: some View {
        ThemeGalleryView()
    }
}

// Lets Xcode draw this view live in the canvas while you edit.
#Preview {
    ContentView()
}
