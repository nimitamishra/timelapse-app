import SwiftUI

/// Departure-board letters, each in its own tile with the split line
/// across the middle. Static for now — the flip animation comes in polish.
struct SplitFlapText: View {
    let text: String

    var body: some View {
        HStack(spacing: Theme.Spacing.xs) {
            // `enumerated()` pairs each letter with its position. We use the
            // position as the id because letters repeat ("ARRIVED" has two R's)
            // and SwiftUI needs every item in a ForEach to be unique.
            ForEach(Array(text.uppercased().enumerated()), id: \.offset) { _, letter in
                Text(String(letter))
                    .font(Theme.Fonts.flap)
                    .foregroundStyle(Theme.Colors.textPrimary)
                    .frame(width: 36, height: 48)
                    .background(Theme.Colors.surface, in: .rect(cornerRadius: Theme.Radius.flap))
                    .overlay {
                        Rectangle() // the hinge line of a real flap display
                            .fill(Theme.Colors.background)
                            .frame(height: 1)
                    }
                    .overlay {
                        RoundedRectangle(cornerRadius: Theme.Radius.flap)
                            .strokeBorder(Theme.Colors.border, lineWidth: 1)
                    }
            }
        }
        // Read the word, not "A, R, R, I, V, E, D".
        .accessibilityElement(children: .ignore)
        .accessibilityLabel(text)
    }
}

#Preview {
    SplitFlapText(text: "Arrived")
        .padding()
        .background(Theme.Colors.background)
}
