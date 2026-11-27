import SwiftUI

/// The airport-style board of suggested flights. Tap a row to pick it.
struct DeparturesBoard: View {
    let suggestions: [DestinationSuggestion]
    @Binding var selectedID: DestinationSuggestion.ID?

    var body: some View {
        VStack(spacing: 0) {
            header
            ForEach(suggestions) { suggestion in
                row(suggestion)
            }
        }
        .overlay(alignment: .top) { Rectangle().fill(Theme.Colors.border).frame(height: 1) }
    }

    private var header: some View {
        HStack(spacing: Theme.Spacing.s) {
            Text("Dest").frame(width: 52, alignment: .leading)
            Text("City").frame(maxWidth: .infinity, alignment: .leading)
            Text("Time").frame(width: 48, alignment: .leading)
            Text("Status").frame(width: 76, alignment: .leading)
        }
        .cockpitLabel()
        .padding(.horizontal, Theme.Spacing.s)
        .padding(.vertical, 10)
        .accessibilityHidden(true) // VoiceOver reads each row in full instead
    }

    private func row(_ s: DestinationSuggestion) -> some View {
        let isSelected = s.id == selectedID
        return Button { selectedID = s.id } label: {
            HStack(spacing: Theme.Spacing.s) {
                Text(s.airport.iata)
                    .font(Theme.Fonts.code)
                    .foregroundStyle(isSelected ? Theme.Colors.amber : Theme.Colors.textPrimary)
                    .frame(width: 52, alignment: .leading)
                VStack(alignment: .leading, spacing: 1) {
                    Text(s.airport.city)
                        .font(.subheadline.weight(.semibold))
                        .foregroundStyle(Theme.Colors.textPrimary)
                        .lineLimit(1)
                    Text(s.airport.countryName)
                        .font(.caption2)
                        .foregroundStyle(Theme.Colors.textSecondary)
                        .lineLimit(1)
                }
                .frame(maxWidth: .infinity, alignment: .leading)
                Text(FlightTimeFormat.clock(s.flightTime))
                    .font(.subheadline.monospaced())
                    .foregroundStyle(Theme.Colors.textPrimary)
                    .frame(width: 48, alignment: .leading)
                Text(isSelected ? "BOARDING" : "ON TIME")
                    .font(.caption2.weight(.bold))
                    .foregroundStyle(isSelected ? Theme.Colors.green : Theme.Colors.textSecondary)
                    .frame(width: 76, alignment: .leading)
            }
            .padding(.horizontal, Theme.Spacing.s)
            .padding(.vertical, 12)
            .background(isSelected ? Theme.Colors.surfaceRaised : .clear, in: .rect(cornerRadius: 8))
            .contentShape(.rect)
        }
        .buttonStyle(.plain)
        .overlay(alignment: .bottom) { Rectangle().fill(Theme.Colors.border).frame(height: 1) }
        .accessibilityElement(children: .ignore)
        .accessibilityLabel("\(s.airport.city), \(s.airport.countryName), \(FlightTimeFormat.short(s.flightTime))")
        .accessibilityAddTraits(isSelected ? [.isButton, .isSelected] : .isButton)
    }
}
