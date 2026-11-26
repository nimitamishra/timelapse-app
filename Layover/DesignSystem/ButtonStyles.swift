import SwiftUI

// A ButtonStyle controls how a Button *looks*, separately from what it *does*.
// SwiftUI calls `makeBody` with the button's label and whether it's being
// pressed right now, and we return the styled view.

/// Amber, filled — the main action on a screen ("Board flight").
struct PrimaryButtonStyle: ButtonStyle {
    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .font(.headline)
            .foregroundStyle(Theme.Colors.background)
            .frame(maxWidth: .infinity, minHeight: 54)
            .background(Theme.Colors.amber, in: .rect(cornerRadius: Theme.Radius.button))
            .pressEffect(configuration.isPressed)
    }
}

/// Outlined — secondary actions ("Hold", "Save video").
struct SecondaryButtonStyle: ButtonStyle {
    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .font(.headline.weight(.semibold))
            .foregroundStyle(Theme.Colors.textPrimary)
            .frame(maxWidth: .infinity, minHeight: 54)
            .overlay {
                RoundedRectangle(cornerRadius: Theme.Radius.button)
                    .strokeBorder(Theme.Colors.borderStrong, lineWidth: 1)
            }
            .contentShape(.rect) // makes the empty inside tappable, not just the text
            .pressEffect(configuration.isPressed)
    }
}

private extension View {
    /// Shared "squish" feedback while a finger is down.
    func pressEffect(_ isPressed: Bool) -> some View {
        self
            .opacity(isPressed ? 0.8 : 1)
            .scaleEffect(isPressed ? 0.98 : 1)
            .animation(.easeOut(duration: 0.12), value: isPressed)
    }
}

// These let screens write `.buttonStyle(.cockpitPrimary)`, just like
// Apple's built-in `.buttonStyle(.bordered)`.
extension ButtonStyle where Self == PrimaryButtonStyle {
    static var cockpitPrimary: PrimaryButtonStyle { PrimaryButtonStyle() }
}

extension ButtonStyle where Self == SecondaryButtonStyle {
    static var cockpitSecondary: SecondaryButtonStyle { SecondaryButtonStyle() }
}

#Preview {
    HStack(spacing: Theme.Spacing.s) {
        Button("Hold") {}.buttonStyle(.cockpitSecondary)
        Button("Board flight") {}.buttonStyle(.cockpitPrimary)
    }
    .padding()
    .background(Theme.Colors.background)
}
