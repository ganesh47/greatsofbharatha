import CoreLocation
import Foundation
import MapKit

struct AppleMapsPlaceHandoff {
    let displayName: String
    let coordinate: CLLocationCoordinate2D?

    var isAvailable: Bool {
        guard let coordinate else { return false }
        return CLLocationCoordinate2DIsValid(coordinate)
    }

    var url: URL? {
        guard isAvailable, let coordinate else { return nil }

        var components = URLComponents(string: "https://maps.apple.com/")
        components?.queryItems = [
            URLQueryItem(name: "ll", value: "\(coordinate.latitude),\(coordinate.longitude)"),
            URLQueryItem(name: "q", value: displayName)
        ]
        return components?.url
    }

    func makeMapItem() -> MKMapItem? {
        guard isAvailable, let coordinate else { return nil }

        let placemark = MKPlacemark(coordinate: coordinate)
        let item = MKMapItem(placemark: placemark)
        item.name = displayName
        return item
    }

    @MainActor
    @discardableResult
    func openInAppleMaps() -> Bool {
        guard let item = makeMapItem() else { return false }
        item.openInMaps(launchOptions: [
            MKLaunchOptionsMapCenterKey: NSValue(mkCoordinate: item.placemark.coordinate),
            MKLaunchOptionsMapSpanKey: NSValue(mkCoordinateSpan: MKCoordinateSpan(latitudeDelta: 0.08, longitudeDelta: 0.08))
        ])
        return true
    }
}
