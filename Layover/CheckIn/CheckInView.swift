import SwiftUI

/// The "Departures" screen: name your task, estimate it, pick a flight, board.
struct CheckInView: View {
    @State private var model: CheckInModel
    @State private var showingHomePicker = false
    /// When this gets a value, NavigationStack pushes the in-flight screen.
    @State private var boarded: BoardingPass?
    @FocusState private var taskFieldFocused: Bool
    private let onHomeChange: (Airport) -> Void

    init(store: AirportStore, home: Airport, onHomeChange: @escaping (Airport) -> Void) {
        // `@State` owns the model for the life of this screen. We create it
        // once here; `_model` is how you set a @State's starting value in init.
        _model = State(initialValue: CheckInModel(store: store, home: home))
        self.onHomeChange = onHomeChange
    }

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: Theme.Spacing.l) {
                header
                taskCard
                departures
                if let pass = model.draftPass {
                    BoardingPassCard(pass: pass)
                }
            }
            .padding(Theme.Spacing.m)
        }
        .scrollDismissesKeyboard(.interactively)
        .background(Theme.Colors.background)
        // Pins the Board button to the bottom, above the home indicator, while content scrolls.
        .safeAreaInset(edge: .bottom) { boardButton }
        .toolbar(.hidden, for: .navigationBar)
        .navigationDestination(item: $boarded) { pass in
            FlightView(pass: pass, airports: model.store.airports)
        }
        .sheet(isPresented: $showingHomePicker) {
            HomeAirportPicker(store: model.store, currentCode: model.home.iata) { airport in
                model.home = airport
                onHomeChange(airport)
                showingHomePicker = false
            }
        }
    }

    // MARK: Pieces

    private var header: some View {
        HStack(alignment: .firstTextBaseline) {
            Text("Departures")
                .font(.largeTitle.weight(.bold))
                .foregroundStyle(Theme.Colors.textPrimary)
            Spacer()
            Button { showingHomePicker = true } label: {
                HStack(spacing: Theme.Spacing.xs) {
                    Text(model.home.iata).font(.subheadline.monospaced().weight(.bold))
                    Image(systemName: "chevron.down").font(.caption2.weight(.bold))
                }
                .foregroundStyle(Theme.Colors.amber)
                .frame(minHeight: 44)
            }
            .accessibilityLabel("Home airport \(model.home.city). Change")
        }
    }

    private var taskCard: some View {
        CockpitCard {
            VStack(alignment: .leading, spacing: Theme.Spacing.m) {
                VStack(alignment: .leading, spacing: Theme.Spacing.s) {
                    Text("Task").cockpitLabel()
                    TextField("What are you working on?", text: $model.task)
                        .focused($taskFieldFocused)
                        .submitLabel(.done)
                        .foregroundStyle(Theme.Colors.textPrimary)
                        .padding(12)
                        .background(Theme.Colors.background, in: .rect(cornerRadius: 10))
                        .overlay {
                            RoundedRectangle(cornerRadius: 10).strokeBorder(Theme.Colors.border)
                        }
                }
                VStack(alignment: .leading, spacing: Theme.Spacing.s) {
                    Text("Estimate").cockpitLabel()
                    EstimateChips(model: model)
                }
                VStack(alignment: .leading, spacing: Theme.Spacing.s) {
                    Text("Mode").cockpitLabel()
                    ModeToggle(mode: $model.mode)
                }
            }
        }
    }

    private var departures: some View {
        VStack(alignment: .leading, spacing: Theme.Spacing.s) {
            Text("Flights about \(FlightTimeFormat.short(model.estimate)) from \(model.home.iata)")
                .cockpitLabel()
            DeparturesBoard(suggestions: model.suggestions, selectedID: $model.selectedID)
        }
    }

    private var boardButton: some View {
        VStack(spacing: Theme.Spacing.xs) {
            Button("Board flight") {
                taskFieldFocused = false
                boarded = model.boardingPass()
            }
            .buttonStyle(.cockpitPrimary)
            .disabled(!model.canBoard)
            if !model.canBoard {
                Text("Name your task to board")
                    .font(.caption)
                    .foregroundStyle(Theme.Colors.textSecondary)
            }
        }
        .padding(.horizontal, Theme.Spacing.m)
        .padding(.top, Theme.Spacing.s)
        .background(Theme.Colors.background)
    }
}

#Preview {
    let store = try! AirportStore.loadBundled()
    NavigationStack {
        CheckInView(store: store, home: store.airport(code: "SFO")!) { _ in }
    }
}
