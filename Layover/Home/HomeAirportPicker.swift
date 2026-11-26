import SwiftUI

/// "Where do you fly from?" — shown on first launch, and from Check-in's "Change".
///
/// It asks for location right away and lists the nearest few airports, so
/// someone in Palo Alto can pick SJC *or* SFO. Search is always there for
/// choosing anywhere else (or if location is denied).
struct HomeAirportPicker: View {
    let store: AirportStore
    var currentCode: String? = nil
    let onPick: (Airport) -> Void

    @State private var query = ""
    @State private var nearby: [NearbyAirport] = []
    @State private var locationStatus: LocationStatus = .idle

    private enum LocationStatus: Equatable {
        case idle, locating, found, failed(String)
    }

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: Theme.Spacing.l) {
                VStack(alignment: .leading, spacing: Theme.Spacing.xs) {
                    Text("Home base").cockpitLabel()
                    Text("Where do you fly from?")
                        .font(Theme.Fonts.title)
                        .foregroundStyle(Theme.Colors.textPrimary)
                }

                nearbySection
                searchSection
            }
            .padding(Theme.Spacing.m)
        }
        .scrollDismissesKeyboard(.interactively)
        .background(Theme.Colors.background)
        // `.task` runs async work when the view appears and cancels it if the view goes away.
        .task { await locate() }
    }

    // MARK: Nearby (location)

    @ViewBuilder private var nearbySection: some View {
        VStack(alignment: .leading, spacing: Theme.Spacing.s) {
            Text("Near you").cockpitLabel()
            switch locationStatus {
            case .idle, .locating:
                HStack(spacing: Theme.Spacing.s) {
                    ProgressView().tint(Theme.Colors.textSecondary)
                    Text("Finding airports near you…")
                        .foregroundStyle(Theme.Colors.textSecondary)
                }
                .padding(.vertical, Theme.Spacing.s)
            case .failed(let message):
                VStack(alignment: .leading, spacing: Theme.Spacing.s) {
                    Text(message)
                        .font(.callout)
                        .foregroundStyle(Theme.Colors.textSecondary)
                    Button("Try again") { Task { await locate() } }
                        .font(.callout.weight(.semibold))
                        .foregroundStyle(Theme.Colors.amber)
                }
            case .found:
                CockpitCard {
                    VStack(spacing: 0) {
                        ForEach(nearby) { item in
                            Button { onPick(item.airport) } label: {
                                AirportRow(airport: item.airport,
                                           detail: "\(Int(item.distanceKm.rounded())) km",
                                           isSelected: item.airport.iata == currentCode)
                            }
                            .buttonStyle(.plain)
                            if item.id != nearby.last?.id {
                                Divider().overlay(Theme.Colors.border)
                            }
                        }
                    }
                }
            }
        }
    }

    // MARK: Search

    private var searchSection: some View {
        VStack(alignment: .leading, spacing: Theme.Spacing.s) {
            Text("Somewhere else").cockpitLabel()
            HStack(spacing: Theme.Spacing.s) {
                Image(systemName: "magnifyingglass")
                    .foregroundStyle(Theme.Colors.textSecondary)
                    .accessibilityHidden(true)
                TextField("City or code — “Mumbai”, “JFK”", text: $query)
                    .textInputAutocapitalization(.never)
                    .autocorrectionDisabled()
                    .foregroundStyle(Theme.Colors.textPrimary)
                    .accessibilityLabel("Search airports")
            }
            .padding(12)
            .background(Theme.Colors.surface, in: .rect(cornerRadius: 10))
            .overlay {
                RoundedRectangle(cornerRadius: 10).strokeBorder(Theme.Colors.border)
            }

            let results = store.search(query)
            if !results.isEmpty {
                VStack(spacing: 0) {
                    ForEach(results) { airport in
                        Button { onPick(airport) } label: {
                            AirportRow(airport: airport, isSelected: airport.iata == currentCode)
                        }
                        .buttonStyle(.plain)
                        Divider().overlay(Theme.Colors.border)
                    }
                }
            } else if !query.trimmingCharacters(in: .whitespaces).isEmpty {
                Text("No large airports match “\(query)”.")
                    .font(.callout)
                    .foregroundStyle(Theme.Colors.textSecondary)
            }
        }
    }

    // MARK: Location

    private func locate() async {
        locationStatus = .locating
        do {
            let here = try await LocationProvider.currentCoordinate()
            nearby = store.nearest(to: here, limit: 3)
            locationStatus = .found
        } catch LocationProvider.Failure.denied {
            locationStatus = .failed("Location is off for Layover. Search below, or allow it in Settings › Layover › Location.")
        } catch {
            locationStatus = .failed("Couldn't find your location. Search for your airport below.")
        }
    }
}

#Preview {
    HomeAirportPicker(store: try! AirportStore.loadBundled(), currentCode: "SFO") { _ in }
}
