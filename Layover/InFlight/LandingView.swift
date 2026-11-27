import SwiftUI

/// After the flight: what happened, in departure-board style.
struct LandingView: View {
    let pass: BoardingPass
    let outcome: FlightOutcome
    let onDone: () -> Void

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: Theme.Spacing.l) {
                VStack(alignment: .leading, spacing: Theme.Spacing.s) {
                    Text("\(pass.flightNumber) · \(pass.origin.iata) → \(pass.destination.iata)")
                        .cockpitLabel()
                    SplitFlapText(text: flapWord)
                    headlinePill
                }

                if case .layover(_, let postcards) = outcome.kind {
                    postcardCard(count: postcards)
                }

                if outcome.kind == .diverted {
                    CockpitCard {
                        Text("Your plane is waiting in \(outcome.landedAt.city). The rest of the trip to \(pass.destination.city) becomes a connecting flight.")
                            .font(.callout)
                            .foregroundStyle(Theme.Colors.textPrimary)
                    }
                }

                stats
            }
            .padding(Theme.Spacing.m)
        }
        .safeAreaInset(edge: .bottom) {
            Button("Back to departures", action: onDone)
                .buttonStyle(.cockpitPrimary)
                .padding(.horizontal, Theme.Spacing.m)
                .padding(.top, Theme.Spacing.s)
                .background(Theme.Colors.background)
        }
    }

    // MARK: Pieces

    private var flapWord: String {
        switch outcome.kind {
        case .returnedToGate: "At gate"
        case .diverted:       "Diverted"
        case .tailwind:       "Arrived"
        case .layover:        "Layover"
        }
    }

    private var headlinePill: some View {
        let (icon, text, color): (String, String, Color) = switch outcome.kind {
        case .returnedToGate:
            ("arrow.uturn.backward", "Under 5 minutes, so no flight was logged", Theme.Colors.textSecondary)
        case .diverted:
            ("arrow.triangle.branch", "Diverted to \(outcome.landedAt.city)", Theme.Colors.amber)
        case .tailwind:
            ("wind", "Tailwind · task done \(FlightTimeFormat.short(pass.estimate - outcome.focusTime)) early", Theme.Colors.green)
        case .layover(let overtime, _):
            ("mappin.and.ellipse", "Landed on time · explored \(FlightTimeFormat.short(overtime))", Theme.Colors.green)
        }
        return Label(text, systemImage: icon)
            .font(.subheadline.weight(.semibold))
            .foregroundStyle(color)
            .padding(.horizontal, 12)
            .padding(.vertical, 6)
            .background(color.opacity(0.12), in: .capsule)
            .overlay { Capsule().strokeBorder(color.opacity(0.4)) }
    }

    private func postcardCard(count: Int) -> some View {
        CockpitCard {
            HStack(spacing: Theme.Spacing.m) {
                Image(systemName: "photo.on.rectangle.angled")
                    .font(.title)
                    .foregroundStyle(Theme.Colors.amber)
                    .accessibilityHidden(true)
                VStack(alignment: .leading, spacing: 2) {
                    Text(count == 1 ? "1 postcard from \(pass.destination.city)"
                                    : "\(count) postcards from \(pass.destination.city)")
                        .font(.headline)
                        .foregroundStyle(Theme.Colors.textPrimary)
                    Text("One for every 15 minutes you kept exploring.")
                        .font(.caption)
                        .foregroundStyle(Theme.Colors.textSecondary)
                }
            }
        }
    }

    private var stats: some View {
        CockpitCard {
            VStack(spacing: Theme.Spacing.m) {
                HStack {
                    DataReadout(label: "Block time",
                                value: "\(FlightTimeFormat.clock(outcome.focusTime)) / \(FlightTimeFormat.clock(pass.estimate))")
                    DataReadout(label: "Km logged", value: "\(Int(outcome.distanceKm).formatted())")
                }
                HStack {
                    DataReadout(label: "Estimate accuracy",
                                value: outcome.kind == .returnedToGate
                                    ? "—"  // a cancelled takeoff says nothing about your estimate
                                    : String(format: "%.2f×", outcome.focusTime / pass.estimate))
                    DataReadout(label: "Landed at", value: outcome.landedAt.iata, valueColor: Theme.Colors.amber)
                }
            }
        }
    }
}
