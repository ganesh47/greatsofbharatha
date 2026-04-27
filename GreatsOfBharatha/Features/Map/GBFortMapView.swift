import MapKit
import SwiftUI

// ─────────────────────────────────────────────────────────────
// GBFortMapView.swift — Greats of Bharatha
// Reusable single-fort MapKit view with an interactive pin.
// Replaces the abstract lat/lon schematic board.
// ─────────────────────────────────────────────────────────────

struct GBFortMapView: View {
    let place: Place

    @State private var cameraPosition: MapCameraPosition
    @State private var pinTapped = false

    init(place: Place) {
        self.place = place
        _cameraPosition = State(
            initialValue: .region(MKCoordinateRegion(
                center: place.coordinate ?? CLLocationCoordinate2D(latitude: 20.5937, longitude: 78.9629),
                span: MKCoordinateSpan(latitudeDelta: 0.14, longitudeDelta: 0.14)
            ))
        )
    }

    var body: some View {
        Map(position: $cameraPosition) {
            if let coordinate = place.coordinate {
                Annotation(place.name, coordinate: coordinate) {
                    fortPin
                }
            }
        }
        .mapStyle(.standard(elevation: .realistic))
        .clipShape(RoundedRectangle(cornerRadius: GBRadius.hero, style: .continuous))
        .gbShadow(.card)
    }

    private var fortPin: some View {
        Button {
            withAnimation(GBMotion.bounce) { pinTapped = true }
            GBHaptic.pinCorrect()
            Task { @MainActor in
                try? await Task.sleep(nanoseconds: 1_100_000_000)
                withAnimation(GBMotion.spring) { pinTapped = false }
            }
        } label: {
            VStack(spacing: 4) {
                ZStack {
                    Circle()
                        .fill(GBColor.gradient(for: .place))
                        .frame(
                            width: pinTapped ? 68 : 56,
                            height: pinTapped ? 68 : 56
                        )
                        .shadow(
                            color: GBColor.Place.primary.opacity(pinTapped ? 0.55 : 0.25),
                            radius: pinTapped ? 18 : 8
                        )

                    Image(systemName: fortIconName)
                        .font(.system(size: pinTapped ? 30 : 24, weight: .medium))
                        .foregroundStyle(.white)
                }
                .animation(GBMotion.bounce, value: pinTapped)

                Text(place.name)
                    .font(GBFont.ui(size: 12, weight: .bold))
                    .padding(.horizontal, 8)
                    .padding(.vertical, 4)
                    .background(.ultraThinMaterial, in: Capsule())
                    .opacity(pinTapped ? 1 : 0.85)
            }
        }
        .buttonStyle(.plain)
        .accessibilityLabel("Fort pin: \(place.name). Tap to celebrate!")
    }

    private var fortIconName: String {
        switch place.id {
        case "place-shivneri":   return GBIcon.Fort.shivneri
        case "place-torna":      return GBIcon.Fort.torna
        case "place-rajgad":     return GBIcon.Fort.rajgad
        case "place-pratapgad":  return GBIcon.Fort.pratapgad
        case "place-raigad":     return GBIcon.Fort.raigad
        case "place-purandar":   return GBIcon.Fort.purandar
        default:                 return GBIcon.Fort.generic
        }
    }
}

#Preview("Fort Map — Shivneri") {
    GBFortMapView(place: Place(
        id: "place-shivneri",
        name: "Shivneri Fort",
        memoryHook: "Birth Fort",
        primaryEvent: "Birth of Shivaji Maharaj",
        whyItMatters: "The starting point of the whole story",
        regionLabel: "Northern Sahyadri",
        latitude: 19.199,
        longitude: 73.860,
        progress: .readyToLearn,
        isCoreReleasePlace: true
    ))
    .frame(height: 300)
    .padding()
    .background(GBColor.Background.app)
}
