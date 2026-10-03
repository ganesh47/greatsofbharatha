import CoreGraphics
import Foundation

struct LearningMapBounds: Equatable {
    let minLatitude: Double
    let maxLatitude: Double
    let minLongitude: Double
    let maxLongitude: Double

    var centerLatitude: Double { (minLatitude + maxLatitude) / 2 }
    var centerLongitude: Double { (minLongitude + maxLongitude) / 2 }
}

struct MapReferenceSettlement: Identifiable, Equatable {
    let id: String
    let name: String
    let coordinate: Coordinate
}

enum LearningMapRegion: String, CaseIterable, Identifiable {
    case sahyadri
    case agra

    var id: String { rawValue }
    var title: String { self == .sahyadri ? "Sahyadri forts" : "Around Agra" }

    var bounds: LearningMapBounds {
        switch self {
        case .sahyadri:
            LearningMapBounds(minLatitude: 17.70, maxLatitude: 19.45, minLongitude: 73.10, maxLongitude: 74.25)
        case .agra:
            LearningMapBounds(minLatitude: 26.95, maxLatitude: 27.70, minLongitude: 77.35, maxLongitude: 78.35)
        }
    }

    // Approximate reference locations, not navigation destinations. See coordinate provenance.
    var settlements: [MapReferenceSettlement] {
        switch self {
        case .sahyadri:
            [
                MapReferenceSettlement(id: "town-pune", name: "Pune", coordinate: Coordinate(latitude: 18.50, longitude: 73.8833)),
                MapReferenceSettlement(id: "town-junnar", name: "Junnar", coordinate: Coordinate(latitude: 19.20, longitude: 73.9333)),
                MapReferenceSettlement(id: "town-saswad", name: "Saswad", coordinate: Coordinate(latitude: 18.35, longitude: 74.0167)),
                MapReferenceSettlement(id: "town-mahad", name: "Mahad", coordinate: Coordinate(latitude: 18.0833, longitude: 73.4167)),
                MapReferenceSettlement(id: "town-mahabaleshwar", name: "Mahabaleshwar", coordinate: Coordinate(latitude: 17.92, longitude: 73.66)),
                MapReferenceSettlement(id: "town-wai", name: "Wai", coordinate: Coordinate(latitude: 17.95, longitude: 73.89))
            ]
        case .agra:
            [
                MapReferenceSettlement(id: "town-mathura", name: "Mathura", coordinate: Coordinate(latitude: 27.50, longitude: 77.67)),
                MapReferenceSettlement(id: "town-fatehpur-sikri", name: "Fatehpur Sikri", coordinate: Coordinate(latitude: 27.094, longitude: 77.664))
            ]
        }
    }
}

/// Local equirectangular projection, corrected at the region's central latitude.
/// One shared scale preserves relative distances across screen sizes (within 1% locally).
struct LearningMapProjector {
    static let earthRadiusKilometres = 6_371.0088
    let bounds: LearningMapBounds
    let mapRect: CGRect
    let kilometresPerPoint: Double
    private let longitudeKilometresPerDegree: Double
    private let latitudeKilometresPerDegree: Double

    init(region: LearningMapRegion, size: CGSize, padding: CGFloat = 24) {
        self.init(bounds: region.bounds, size: size, padding: padding)
    }

    init(bounds: LearningMapBounds, size: CGSize, padding: CGFloat = 24) {
        self.bounds = bounds
        latitudeKilometresPerDegree = Self.earthRadiusKilometres * .pi / 180
        longitudeKilometresPerDegree = latitudeKilometresPerDegree * cos(bounds.centerLatitude * .pi / 180)
        let widthKM = max((bounds.maxLongitude - bounds.minLongitude) * longitudeKilometresPerDegree, 0.0001)
        let heightKM = max((bounds.maxLatitude - bounds.minLatitude) * latitudeKilometresPerDegree, 0.0001)
        let safePadding = max(padding, 0)
        let usableWidth = max(Double(size.width - safePadding * 2), 1)
        let usableHeight = max(Double(size.height - safePadding * 2), 1)
        let scale = min(usableWidth / widthKM, usableHeight / heightKM)
        kilometresPerPoint = 1 / scale
        let width = widthKM * scale
        let height = heightKM * scale
        mapRect = CGRect(x: (Double(size.width) - width) / 2, y: (Double(size.height) - height) / 2, width: width, height: height)
    }

    func point(for coordinate: Coordinate) -> CGPoint {
        point(latitude: coordinate.latitude, longitude: coordinate.longitude)
    }

    func point(latitude: Double, longitude: Double) -> CGPoint {
        CGPoint(
            x: mapRect.minX + (longitude - bounds.minLongitude) * longitudeKilometresPerDegree / kilometresPerPoint,
            y: mapRect.minY + (bounds.maxLatitude - latitude) * latitudeKilometresPerDegree / kilometresPerPoint
        )
    }

    func coordinate(for point: CGPoint) -> Coordinate {
        Coordinate(
            latitude: bounds.maxLatitude - Double(point.y - mapRect.minY) * kilometresPerPoint / latitudeKilometresPerDegree,
            longitude: bounds.minLongitude + Double(point.x - mapRect.minX) * kilometresPerPoint / longitudeKilometresPerDegree
        )
    }

    func points(forKilometres kilometres: Double) -> CGFloat {
        CGFloat(kilometres / kilometresPerPoint)
    }
}

enum LearningAtlasContent {
    static func hasValidCoordinate(for place: Place) -> Bool {
        guard let latitude = place.latitude, let longitude = place.longitude,
              latitude.isFinite, longitude.isFinite else { return false }
        let bounds = region(for: place).bounds
        return (bounds.minLatitude...bounds.maxLatitude).contains(latitude)
            && (bounds.minLongitude...bounds.maxLongitude).contains(longitude)
    }

    static func region(for place: Place) -> LearningMapRegion {
        place.id == "place-agra" ? .agra : .sahyadri
    }

    static func relationship(for place: Place) -> String {
        switch place.id {
        case "place-shivneri": "Shivneri is near Junnar, north of Pune."
        case "place-torna": "Torna is southwest of Pune, just west of Rajgad."
        case "place-rajgad": "Rajgad is southwest of Pune, just east of Torna."
        case "place-pratapgad": "Pratapgad is west of Mahabaleshwar and Wai, south of the other story forts."
        case "place-purandar": "Purandar is south of Saswad and southeast of Pune."
        case "place-raigad": "Raigad is north of Mahad and west of Rajgad."
        case "place-agra": "Agra is southeast of Mathura, far north of the Sahyadri forts."
        default: place.regionLabel
        }
    }

    /// Same canonical identities as the lesson; reference towns never become quiz answers.
    static func candidates(for target: Place, places: [Place]) -> [Place] {
        var seen: Set<String> = [target.id]
        let others = places.filter { seen.insert($0.id).inserted }.sorted { left, right in
            let leftDistance = distance(from: target, to: left)
            let rightDistance = distance(from: target, to: right)
            return leftDistance == rightDistance ? left.id < right.id : leftDistance < rightDistance
        }
        return ([target] + others.prefix(2)).sorted { left, right in
            let order = left.name.localizedStandardCompare(right.name)
            return order == .orderedSame ? left.id < right.id : order == .orderedAscending
        }
    }

    private static func distance(from first: Place, to second: Place) -> Double {
        guard let lat1 = first.latitude, let lon1 = first.longitude,
              let lat2 = second.latitude, let lon2 = second.longitude,
              lat1.isFinite, lon1.isFinite, lat2.isFinite, lon2.isFinite else { return .infinity }
        let radians = Double.pi / 180
        let haversine = pow(sin((lat2 - lat1) * radians / 2), 2)
            + cos(lat1 * radians) * cos(lat2 * radians) * pow(sin((lon2 - lon1) * radians / 2), 2)
        return LearningMapProjector.earthRadiusKilometres * 2 * asin(sqrt(min(max(haversine, 0), 1)))
    }
}

enum LearningMapSelectionOutcome: Equatable {
    case ignored
    case retry
    case success(LearningSupport)
}

enum LearningMapSelectionEngine {
    static func evaluate(
        targetID: String,
        selectedID: String?,
        candidateIDs: Set<String>,
        alreadySolved: Bool,
        usedHint: Bool,
        assistModeEnabled: Bool
    ) -> LearningMapSelectionOutcome {
        guard !alreadySolved, let selectedID, candidateIDs.contains(selectedID) else { return .ignored }
        guard selectedID == targetID else { return .retry }
        return .success(usedHint || assistModeEnabled ? .hinted : .independent)
    }
}
