import MapKit
import SwiftUI

/// The in-flight map: the great-circle route, the plane, and both airports.
///
/// Tap to switch between the whole route and following the plane. It takes
/// plain values (not the session), so milestone 6 can reuse it as the overlay
/// on top of your camera.
struct FlightMapView: View {
    let origin: Airport
    let destination: Airport
    let position: Coordinate
    let heading: Double
    let isHolding: Bool

    @State private var isFollowing = false
    /// What the map is looking at. `Map` reads and writes this.
    @State private var camera: MapCameraPosition = .automatic

    /// How high the "follow" camera sits above the plane, in metres. ~1,500 km
    /// shows the coastline and nearby cities sliding past.
    private static let followDistance = 1_500_000.0

    var body: some View {
        Map(position: $camera, interactionModes: []) {
            // Flown so far: solid. Still to go: dashed. `.geodesic` makes MapKit
            // draw each line as a great-circle arc, the same path the plane flies.
            MapPolyline(coordinates: [origin.coordinate.clLocation, position.clLocation],
                        contourStyle: .geodesic)
                .stroke(Theme.Colors.amber, lineWidth: 3)
            MapPolyline(coordinates: [position.clLocation, destination.coordinate.clLocation],
                        contourStyle: .geodesic)
                .stroke(Theme.Colors.amber.opacity(0.55),
                        style: StrokeStyle(lineWidth: 2, lineCap: .round, dash: [4, 6]))

            airportPin(origin)
            airportPin(destination)

            Annotation("Plane", coordinate: position.clLocation, anchor: .center) {
                Image(systemName: "airplane")
                    .font(.title2)
                    .foregroundStyle(Theme.Colors.amber)
                    .shadow(color: Theme.Colors.background, radius: 3)
                    // The SF Symbol points east (90°), so turn it by heading − 90°.
                    .rotationEffect(.degrees(heading - 90))
                    .symbolEffect(.pulse, isActive: isHolding)
            }
            .annotationTitles(.hidden)
        }
        .mapStyle(.standard(elevation: .flat, emphasis: .muted,
                            pointsOfInterest: .excludingAll, showsTraffic: false))
        .onTapGesture {
            isFollowing.toggle()
            withAnimation(.easeInOut(duration: 0.8)) { camera = targetCamera }
        }
        // While following, keep the camera on the plane as it moves.
        .onChange(of: position) {
            if isFollowing { camera = targetCamera }
        }
        .onAppear { camera = targetCamera }
        .overlay(alignment: .topTrailing) { modeChip }
        .clipShape(.rect(cornerRadius: Theme.Radius.card))
        .overlay {
            RoundedRectangle(cornerRadius: Theme.Radius.card)
                .strokeBorder(Theme.Colors.border)
        }
        .accessibilityElement(children: .ignore)
        .accessibilityLabel("Map of the flight from \(origin.city) to \(destination.city)")
        .accessibilityHint(isFollowing ? "Double tap to show the whole route" : "Double tap to follow the plane")
        .accessibilityAddTraits(.isButton)
    }

    // MARK: Pieces

    private var targetCamera: MapCameraPosition {
        if isFollowing {
            return .camera(MapCamera(centerCoordinate: position.clLocation,
                                     distance: Self.followDistance))
        }
        let frame = RouteFraming.frame(from: origin.coordinate, to: destination.coordinate)
        return .region(MKCoordinateRegion(
            center: frame.center.clLocation,
            span: MKCoordinateSpan(latitudeDelta: frame.latitudeSpan,
                                   longitudeDelta: frame.longitudeSpan)))
    }

    private func airportPin(_ airport: Airport) -> some MapContent {
        Annotation(airport.iata, coordinate: airport.coordinate.clLocation, anchor: .center) {
            VStack(spacing: Theme.Spacing.xs) {
                Circle()
                    .fill(Theme.Colors.textPrimary)
                    .frame(width: 8, height: 8)
                Text(airport.iata)
                    .font(Theme.Fonts.label.monospaced())
                    .foregroundStyle(Theme.Colors.textPrimary)
                    .shadow(color: Theme.Colors.background, radius: 2)
            }
            // Shift down so the dot (not the middle of dot + label) sits on the airport.
            .offset(y: 9)
        }
        .annotationTitles(.hidden) // we draw our own label in SF Mono
    }

    private var modeChip: some View {
        Label(isFollowing ? "Following" : "Whole route",
              systemImage: isFollowing ? "location.north.fill" : "map")
            .font(Theme.Fonts.label)
            .foregroundStyle(Theme.Colors.textPrimary)
            .padding(.horizontal, 10)
            .padding(.vertical, 5)
            .background(Theme.Colors.surface.opacity(0.85), in: .capsule)
            .overlay { Capsule().strokeBorder(Theme.Colors.border) }
            .padding(Theme.Spacing.s)
            .allowsHitTesting(false)
    }
}

extension Coordinate {
    /// Our Coordinate → the type MapKit wants.
    var clLocation: CLLocationCoordinate2D {
        CLLocationCoordinate2D(latitude: latitude, longitude: longitude)
    }
}

#Preview {
    let sfo = Airport(iata: "SFO", name: "San Francisco", city: "San Francisco", country: "US",
                      lat: 37.6198, lon: -122.3748)
    let bog = Airport(iata: "BOG", name: "El Dorado", city: "Bogotá", country: "CO",
                      lat: 4.7016, lon: -74.1469)
    let mid = GreatCircle.intermediatePoint(from: sfo.coordinate, to: bog.coordinate, fraction: 0.4)
    return FlightMapView(origin: sfo, destination: bog, position: mid,
                         heading: GreatCircle.initialBearing(from: mid, to: bog.coordinate),
                         isHolding: false)
        .frame(height: 320)
        .padding()
        .background(Theme.Colors.background)
}
