import SwiftUI

/// One airport in a list: big amber code, city and country, optional detail on the right.
struct AirportRow: View {
    let airport: Airport
    var detail: String? = nil
    var isSelected = false

    var body: some View {
        HStack(spacing: Theme.Spacing.m) {
            Text(airport.iata)
                .font(Theme.Fonts.code)
                .foregroundStyle(Theme.Colors.amber)
                .frame(width: 56, alignment: .leading)
            VStack(alignment: .leading, spacing: 2) {
                Text(airport.city)
                    .font(.body.weight(.semibold))
                    .foregroundStyle(Theme.Colors.textPrimary)
                Text("\(airport.name) · \(airport.countryName)")
                    .font(.caption)
                    .foregroundStyle(Theme.Colors.textSecondary)
                    .lineLimit(1)
            }
            Spacer(minLength: Theme.Spacing.s)
            if let detail {
                Text(detail)
                    .font(.caption.monospaced())
                    .foregroundStyle(Theme.Colors.textSecondary)
            }
            if isSelected {
                Image(systemName: "checkmark")
                    .foregroundStyle(Theme.Colors.green)
                    .accessibilityHidden(true)
            }
        }
        .padding(.vertical, Theme.Spacing.s + 2)
        .contentShape(.rect)
        .accessibilityElement(children: .combine)
        .accessibilityAddTraits(isSelected ? .isSelected : [])
    }
}
