import SwiftUI

/// Temporary screen that shows every design-system piece in one place.
/// Open this file in Xcode and use the preview canvas to tweak Theme
/// values live. It goes away once real screens exist (milestone 3).
struct ThemeGalleryView: View {
    private let swatches: [(name: String, color: Color)] = [
        ("background", Theme.Colors.background),
        ("surface", Theme.Colors.surface),
        ("border", Theme.Colors.border),
        ("text", Theme.Colors.textPrimary),
        ("secondary", Theme.Colors.textSecondary),
        ("amber", Theme.Colors.amber),
        ("green", Theme.Colors.green),
        ("rec", Theme.Colors.recording),
    ]

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: Theme.Spacing.l) {
                Text("Layover design system")
                    .font(Theme.Fonts.title)
                    .foregroundStyle(Theme.Colors.textPrimary)

                section("Colors") {
                    LazyVGrid(columns: Array(repeating: GridItem(.flexible()), count: 4),
                              spacing: Theme.Spacing.s) {
                        ForEach(swatches, id: \.name) { swatch in
                            VStack(spacing: Theme.Spacing.xs) {
                                RoundedRectangle(cornerRadius: 8)
                                    .fill(swatch.color)
                                    .frame(height: 44)
                                    .overlay {
                                        RoundedRectangle(cornerRadius: 8)
                                            .strokeBorder(Theme.Colors.borderStrong, lineWidth: 1)
                                    }
                                Text(swatch.name)
                                    .font(.caption2)
                                    .foregroundStyle(Theme.Colors.textSecondary)
                            }
                        }
                    }
                }

                section("Type") {
                    Text("27:40")
                        .font(Theme.Fonts.timer)
                        .monospacedDigit()
                        .foregroundStyle(Theme.Colors.textPrimary)
                    Text("SFO → BOG")
                        .font(Theme.Fonts.code)
                        .foregroundStyle(Theme.Colors.amber)
                    Text("Cruising over Mexico City · next waypoint Panamá")
                        .font(Theme.Fonts.body)
                        .foregroundStyle(Theme.Colors.textSecondary)
                }

                section("Card + readouts") {
                    CockpitCard {
                        HStack {
                            DataReadout(label: "Alt", value: "37,000 ft")
                            DataReadout(label: "Dist", value: "3,580 km")
                            DataReadout(label: "Frames", value: "553")
                        }
                    }
                }

                section("Buttons") {
                    HStack(spacing: Theme.Spacing.s) {
                        Button("Hold") {}
                            .buttonStyle(.cockpitSecondary)
                        Button("Task done · land") {}
                            .buttonStyle(.cockpitPrimary)
                    }
                }

                section("Split-flap") {
                    SplitFlapText(text: "Arrived")
                }
            }
            .padding(Theme.Spacing.m)
        }
        .background(Theme.Colors.background)
    }

    /// A labelled group. `some View` + @ViewBuilder lets callers pass any views.
    private func section<Content: View>(_ title: String,
                                        @ViewBuilder content: () -> Content) -> some View {
        VStack(alignment: .leading, spacing: Theme.Spacing.s) {
            Text(title).cockpitLabel()
            content()
        }
    }
}

#Preview {
    ThemeGalleryView()
}
