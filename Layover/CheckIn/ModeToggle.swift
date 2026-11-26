import SwiftUI

/// Real | ×10 — the cockpit-styled segmented control.
struct ModeToggle: View {
    @Binding var mode: FlightMode

    var body: some View {
        HStack(spacing: 0) {
            segment("Real", .real)
            segment("×\(Int(FlightMode.compressedMultiplier))", .compressed)
        }
        .frame(height: 44)
        .overlay {
            RoundedRectangle(cornerRadius: 10).strokeBorder(Theme.Colors.border)
        }
        .clipShape(.rect(cornerRadius: 10))
    }

    private func segment(_ title: String, _ value: FlightMode) -> some View {
        let isOn = mode == value
        return Button { mode = value } label: {
            Text(title)
                .font(.subheadline.weight(.bold))
                .frame(maxWidth: .infinity, maxHeight: .infinity)
                .foregroundStyle(isOn ? Theme.Colors.ticketInk : Theme.Colors.textSecondary)
                .background(isOn ? Theme.Colors.amber : .clear)
                .contentShape(.rect)
        }
        .buttonStyle(.plain)
        .accessibilityLabel(value == .real ? "Real time" : "Compressed, ten times faster")
        .accessibilityAddTraits(isOn ? .isSelected : [])
    }
}
