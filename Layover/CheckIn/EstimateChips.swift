import SwiftUI

/// 25m · 45m · 1h · 2h · Custom. Custom opens a wheel picker for any length.
struct EstimateChips: View {
    // `@Bindable` lets this child view change properties of the @Observable model it was given.
    @Bindable var model: CheckInModel
    @State private var showingCustom = false

    var body: some View {
        HStack(spacing: Theme.Spacing.s) {
            ForEach(CheckInModel.quickEstimates, id: \.self) { seconds in
                chip(FlightTimeFormat.short(seconds), isOn: model.estimate == seconds) {
                    model.setEstimate(seconds)
                }
            }
            chip(model.isCustomEstimate ? FlightTimeFormat.short(model.estimate) : "Custom",
                 isOn: model.isCustomEstimate) {
                showingCustom = true
            }
        }
        .sheet(isPresented: $showingCustom) {
            CustomEstimateSheet(initial: model.estimate) { model.setEstimate($0) }
        }
    }

    private func chip(_ title: String, isOn: Bool, action: @escaping () -> Void) -> some View {
        Button(action: action) {
            Text(title)
                .font(.subheadline.weight(.bold).monospacedDigit())
                .lineLimit(1)
                .minimumScaleFactor(0.7)
                .padding(.horizontal, 4)
                .frame(maxWidth: .infinity, minHeight: 44)
                .foregroundStyle(isOn ? Theme.Colors.ticketInk : Theme.Colors.textPrimary)
                .background(isOn ? Theme.Colors.amber : Theme.Colors.background,
                            in: .rect(cornerRadius: 10))
                .overlay {
                    RoundedRectangle(cornerRadius: 10)
                        .strokeBorder(isOn ? .clear : Theme.Colors.border)
                }
        }
        .buttonStyle(.plain)
        .accessibilityAddTraits(isOn ? .isSelected : [])
    }
}

/// Hours + minutes wheels, shown as a short sheet from the bottom.
private struct CustomEstimateSheet: View {
    let onDone: (TimeInterval) -> Void
    @Environment(\.dismiss) private var dismiss
    @State private var hours: Int
    @State private var minutes: Int

    init(initial: TimeInterval, onDone: @escaping (TimeInterval) -> Void) {
        self.onDone = onDone
        let total = Int(initial / 60)
        _hours = State(initialValue: min(total / 60, 12))
        _minutes = State(initialValue: (total % 60) / 5 * 5)
    }

    var body: some View {
        VStack(spacing: Theme.Spacing.m) {
            Text("How long will it take?")
                .font(.headline)
                .foregroundStyle(Theme.Colors.textPrimary)
            HStack(spacing: 0) {
                Picker("Hours", selection: $hours) {
                    ForEach(0...12, id: \.self) { Text("\($0) h").tag($0) }
                }
                Picker("Minutes", selection: $minutes) {
                    ForEach(Array(stride(from: 0, to: 60, by: 5)), id: \.self) { Text("\($0) min").tag($0) }
                }
            }
            .pickerStyle(.wheel)
            Button("Set estimate") {
                onDone(TimeInterval(hours * 3_600 + minutes * 60))
                dismiss()
            }
            .buttonStyle(.cockpitPrimary)
        }
        .padding(Theme.Spacing.m)
        .presentationDetents([.height(360)])
        .presentationBackground(Theme.Colors.surface)
    }
}
