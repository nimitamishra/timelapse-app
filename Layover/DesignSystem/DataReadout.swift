import SwiftUI

/// A small label over a monospace value, like a cockpit instrument:
///     ALT
///     37,000 ft
struct DataReadout: View {
    let label: String
    let value: String
    var valueColor: Color = Theme.Colors.textPrimary

    var body: some View {
        VStack(alignment: .leading, spacing: Theme.Spacing.xs) {
            Text(label).cockpitLabel()
            Text(value)
                .font(Theme.Fonts.readout)
                .monospacedDigit() // every digit same width, so changing numbers don't jiggle
                .foregroundStyle(valueColor)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        // VoiceOver reads "ALT, 37,000 ft" as one item instead of two.
        .accessibilityElement(children: .combine)
    }
}

#Preview {
    HStack {
        DataReadout(label: "Alt", value: "37,000 ft")
        DataReadout(label: "Dist", value: "3,580 km")
        DataReadout(label: "ETA", value: "−18:20", valueColor: Theme.Colors.amber)
    }
    .padding()
    .background(Theme.Colors.background)
}
