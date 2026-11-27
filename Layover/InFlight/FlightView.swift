import SwiftUI

/// The in-flight cockpit, and the landing screen once the flight ends.
struct FlightView: View {
    @State private var model: FlightModel
    @State private var pendingLanding: FlightOutcome?
    /// scenePhase tells us whether the app is on screen, in the app switcher, or in the background.
    @Environment(\.scenePhase) private var scenePhase
    @Environment(\.dismiss) private var dismiss

    init(pass: BoardingPass, airports: [Airport]) {
        _model = State(initialValue: FlightModel(pass: pass, airports: airports))
    }

    var body: some View {
        Group {
            if let outcome = model.outcome {
                LandingView(pass: model.session.pass, outcome: outcome) { dismiss() }
            } else {
                // TimelineView redraws its content every second with a fresh date.
                // Nothing counts seconds — each redraw asks the session "how long at this moment?"
                TimelineView(.periodic(from: .now, by: 1)) { context in
                    cockpit(now: context.date)
                }
            }
        }
        .background(Theme.Colors.background)
        .toolbar(.hidden, for: .navigationBar)
        .navigationBarBackButtonHidden() // leaving mid-flight only happens by landing
        .onChange(of: scenePhase) { _, phase in
            if phase == .background { model.appLeftForeground() }
        }
        // Keep the screen awake during a flight (it's propped up on your desk).
        .onAppear { UIApplication.shared.isIdleTimerDisabled = true }
        .onDisappear { UIApplication.shared.isIdleTimerDisabled = false }
        // An alert (not a confirmation dialog) so both choices are always visible.
        .alert(
            pendingLanding.map(landingQuestion) ?? "",
            isPresented: Binding(get: { pendingLanding != nil }, set: { if !$0 { pendingLanding = nil } }),
            presenting: pendingLanding
        ) { _ in
            Button("Keep flying", role: .cancel) {}
            Button("Land now") { model.land() }
        }
    }

    // MARK: Cockpit

    private func cockpit(now: Date) -> some View {
        let session = model.session
        let pass = session.pass
        let arrived = session.hasArrived(at: now)

        return VStack(alignment: .leading, spacing: Theme.Spacing.m) {
            HStack {
                Text("\(pass.flightNumber) · \(pass.origin.iata)–\(pass.destination.iata)")
                    .font(.caption.monospaced().weight(.bold))
                    .foregroundStyle(Theme.Colors.textPrimary)
                Spacer()
                statusPill(arrived: arrived)
            }

            FlightMapView(origin: pass.origin,
                          destination: pass.destination,
                          position: session.position(at: now),
                          heading: session.heading(at: now),
                          isHolding: model.isHolding)
                // The top ~40% of the screen (CLAUDE.md: cockpit layout, self view off).
                .containerRelativeFrame(.vertical) { height, _ in height * 0.4 }

            Spacer(minLength: 0)

            HStack(alignment: .bottom) {
                VStack(alignment: .leading, spacing: Theme.Spacing.xs) {
                    Text(pass.task).cockpitLabel().lineLimit(1)
                    Text(FlightTimeFormat.stopwatch(session.focusTime(at: now)))
                        .font(Theme.Fonts.timer)
                        .monospacedDigit()
                        .foregroundStyle(model.isHolding ? Theme.Colors.textSecondary : Theme.Colors.textPrimary)
                        .contentTransition(.numericText())
                        .accessibilityLabel("Focus time \(FlightTimeFormat.short(session.focusTime(at: now)))")
                }
                Spacer()
                VStack(alignment: .trailing, spacing: Theme.Spacing.xs) {
                    Text(arrived ? "Layover" : "ETA").cockpitLabel()
                    Text(arrived ? "+\(FlightTimeFormat.stopwatch(session.overtime(at: now)))"
                                 : "−\(FlightTimeFormat.stopwatch(session.remaining(at: now)))")
                        .font(Theme.Fonts.readout)
                        .monospacedDigit()
                        .foregroundStyle(arrived ? Theme.Colors.green : Theme.Colors.amber)
                }
            }

            CockpitCard {
                HStack {
                    DataReadout(label: "Alt",
                                value: arrived ? "0 ft" : "\(FlightProfile.altitudeFt(progress: session.progress(at: now)).formatted()) ft")
                    DataReadout(label: "Flown",
                                value: "\(Int(session.distanceFlownKm(at: now)).formatted()) km")
                    if arrived {
                        DataReadout(label: "Postcards", value: "\(session.postcards(at: now))",
                                    valueColor: Theme.Colors.green)
                    } else {
                        DataReadout(label: "To go",
                                    value: "\(Int(pass.distanceKm - session.distanceFlownKm(at: now)).formatted()) km")
                    }
                }
            }

            ProgressView(value: session.progress(at: now))
                .tint(arrived ? Theme.Colors.green : Theme.Colors.amber)

            Text(statusLine(now: now, arrived: arrived))
                .font(.callout)
                .foregroundStyle(Theme.Colors.textSecondary)
                .frame(minHeight: 44, alignment: .topLeading)

            HStack(spacing: Theme.Spacing.s) {
                Button(model.isHolding ? "Resume" : "Hold") {
                    model.isHolding ? model.resume() : model.hold()
                }
                .buttonStyle(.cockpitSecondary)
                .frame(maxWidth: 130)

                Button(arrived ? "Task done · end layover" : "Task done · land") {
                    if arrived {
                        model.land()  // reached the estimate: nothing to confirm
                    } else {
                        pendingLanding = model.previewLanding()
                    }
                }
                .buttonStyle(.cockpitPrimary)
            }
        }
        .padding(Theme.Spacing.m)
    }

    private func statusPill(arrived: Bool) -> some View {
        let (text, color): (String, Color) =
            model.isHolding ? ("HOLDING", Theme.Colors.amber)
            : arrived ? ("LAYOVER", Theme.Colors.green)
            : ("CRUISING", Theme.Colors.green)
        return HStack(spacing: 6) {
            Circle().fill(color).frame(width: 8, height: 8)
            Text(text).font(.caption.weight(.bold))
        }
        .foregroundStyle(Theme.Colors.textPrimary)
        .padding(.horizontal, 10)
        .padding(.vertical, 6)
        .overlay { Capsule().strokeBorder(Theme.Colors.border) }
    }

    private func statusLine(now: Date, arrived: Bool) -> String {
        let session = model.session
        let city = session.pass.destination.city
        if model.isHolding {
            return model.wasAutoHeld
                ? "You left the cockpit, so we entered a holding pattern. Tap Resume when you're back to work."
                : "Holding pattern. The clock is paused until you resume."
        }
        if arrived {
            let next = LandingRules.postcardInterval - session.overtime(at: now)
                .truncatingRemainder(dividingBy: LandingRules.postcardInterval)
            return "Landed in \(city), exploring the city. Next postcard in \(FlightTimeFormat.short(next))."
        }
        return "Cruising toward \(city). Land whenever your task is done."
    }

    private func landingQuestion(_ outcome: FlightOutcome) -> String {
        switch outcome.kind {
        case .returnedToGate: "Under 5 minutes, so you'd return to the gate and no flight is logged."
        case .diverted:       "Land early? You'd divert to \(outcome.landedAt.city)."
        case .tailwind:       "Land now? A tailwind gets you to \(outcome.landedAt.city)."
        case .layover:        "Land in \(outcome.landedAt.city)?"
        }
    }
}
