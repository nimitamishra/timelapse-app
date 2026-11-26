import SwiftUI

/// The paper ticket: route, task and estimate, with a tear-off seat stub.
struct BoardingPassCard: View {
    let pass: BoardingPass

    var body: some View {
        HStack(spacing: 0) {
            VStack(alignment: .leading, spacing: Theme.Spacing.s) {
                Text("Boarding pass · \(pass.flightNumber)")
                    .font(.caption2.weight(.bold))
                    .textCase(.uppercase)
                    .tracking(1)
                    .foregroundStyle(Theme.Colors.ticketInkMuted)
                HStack(spacing: Theme.Spacing.s) {
                    Text(pass.origin.iata)
                    Image(systemName: "airplane")
                        .font(.body)
                        .accessibilityLabel("to")
                    Text(pass.destination.iata)
                }
                .font(.system(.title, design: .monospaced, weight: .bold))
                .foregroundStyle(Theme.Colors.ticketInk)
                Text("\(pass.task.isEmpty ? "Your task" : pass.task) · est. \(FlightTimeFormat.short(pass.estimate))")
                    .font(.caption)
                    .foregroundStyle(Theme.Colors.ticketInkMuted)
                    .lineLimit(1)
            }
            .padding(Theme.Spacing.m)
            .frame(maxWidth: .infinity, alignment: .leading)

            PerforationLine()
                .stroke(Theme.Colors.ticketPerforation, style: StrokeStyle(lineWidth: 2, dash: [4, 4]))
                .frame(width: 2)
                .padding(.vertical, Theme.Spacing.s)
                .accessibilityHidden(true)

            VStack(spacing: 2) {
                Text("Seat").font(.caption2.weight(.bold)).textCase(.uppercase)
                    .foregroundStyle(Theme.Colors.ticketInkMuted)
                Text(pass.seat).font(.system(.title2, design: .monospaced, weight: .bold))
                    .foregroundStyle(Theme.Colors.ticketInk)
            }
            .frame(width: 84)
        }
        // Shapes (like the perforation) grow to fill all the space offered;
        // this keeps the ticket only as tall as its text.
        .fixedSize(horizontal: false, vertical: true)
        .background(Theme.Colors.ticketPaper, in: .rect(cornerRadius: Theme.Radius.card))
        .accessibilityElement(children: .combine)
    }
}

/// A vertical line we can dash — Shapes can be stroked with any style.
/// `nonisolated`: SwiftUI may draw shapes off the main thread, and this
/// one is pure geometry, so it's safe anywhere.
private nonisolated struct PerforationLine: Shape {
    func path(in rect: CGRect) -> Path {
        Path { p in
            p.move(to: CGPoint(x: rect.midX, y: rect.minY))
            p.addLine(to: CGPoint(x: rect.midX, y: rect.maxY))
        }
    }
}
