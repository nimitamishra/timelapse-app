import SwiftUI

/// SFO ●━━━━━✈┄┄┄┄┄● BOG — a simple route line until the real map (milestone 5).
struct RouteProgressView: View {
    let origin: String
    let destination: String
    let progress: Double
    let isHolding: Bool

    var body: some View {
        VStack(spacing: Theme.Spacing.s) {
            // GeometryReader tells us how wide we are, so we can place the
            // plane at exactly `progress` of the way across.
            GeometryReader { geo in
                let width = geo.size.width
                let planeX = width * progress
                ZStack(alignment: .leading) {
                    // Remaining route: dashed
                    Path { p in
                        p.move(to: CGPoint(x: 0, y: 20))
                        p.addLine(to: CGPoint(x: width, y: 20))
                    }
                    .stroke(Theme.Colors.amber.opacity(0.4), style: StrokeStyle(lineWidth: 2, dash: [4, 6]))
                    // Flown route: solid
                    Rectangle()
                        .fill(Theme.Colors.amber)
                        .frame(width: planeX, height: 3)
                        .offset(y: 0)
                        .position(x: planeX / 2, y: 20)
                    Circle().fill(Theme.Colors.textPrimary).frame(width: 10, height: 10)
                        .position(x: 0, y: 20)
                    Circle().fill(Theme.Colors.textPrimary).frame(width: 10, height: 10)
                        .position(x: width, y: 20)
                    Image(systemName: "airplane")
                        .font(.title2)
                        .foregroundStyle(Theme.Colors.amber)
                        // A gentle pulse while circling in a holding pattern.
                        .symbolEffect(.pulse, isActive: isHolding)
                        .position(x: min(max(planeX, 14), width - 14), y: 20)
                }
            }
            .frame(height: 40)

            HStack {
                Text(origin)
                Spacer()
                Text(destination)
            }
            .font(Theme.Fonts.code)
            .foregroundStyle(Theme.Colors.textPrimary)
        }
        .accessibilityElement(children: .ignore)
        .accessibilityLabel("\(origin) to \(destination), \(Int(progress * 100)) percent of the way")
    }
}

#Preview {
    RouteProgressView(origin: "SFO", destination: "BOG", progress: 0.6, isHolding: false)
        .padding()
        .background(Theme.Colors.background)
}
