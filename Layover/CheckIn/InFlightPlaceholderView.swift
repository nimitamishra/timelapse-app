import SwiftUI

/// Stand-in for the in-flight screen so boarding goes somewhere.
/// Milestone 4 replaces this with the real timer, hold, and landing logic.
struct InFlightPlaceholderView: View {
    let pass: BoardingPass

    var body: some View {
        VStack(alignment: .leading, spacing: Theme.Spacing.l) {
            SplitFlapText(text: "Boarded")
            BoardingPassCard(pass: pass)
            CockpitCard {
                HStack {
                    DataReadout(label: "Dist", value: "\(Int(pass.distanceKm.rounded()).formatted()) km")
                    DataReadout(label: "Flight", value: FlightTimeFormat.clock(pass.flightTime))
                    DataReadout(label: "Mode", value: pass.mode == .real ? "Real" : "×\(Int(FlightMode.compressedMultiplier))")
                }
            }
            Text("The flight itself — timer, holding pattern, tailwind and layovers — arrives in milestone 4.")
                .font(.callout)
                .foregroundStyle(Theme.Colors.textSecondary)
            Spacer()
        }
        .padding(Theme.Spacing.m)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(Theme.Colors.background)
        .navigationTitle(pass.flightNumber)
        .navigationBarTitleDisplayMode(.inline)
        .toolbarBackground(Theme.Colors.background, for: .navigationBar)
    }
}
