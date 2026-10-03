import CoreGraphics
import XCTest
#if os(tvOS)
@testable import GreatsOfBharathaTV
#else
@testable import Greats_Of_Bharatha
#endif

final class LearningMapTests: XCTestCase {
    func testAllSevenStoryPlacesAndReferenceTownsFitTheirRegions() {
        let places = SampleContent.shivajiVerticalSlice.places
        XCTAssertEqual(places.count, 7)
        for place in places {
            let region = LearningAtlasContent.region(for: place)
            let projector = LearningMapProjector(region: region, size: CGSize(width: 390, height: 480))
            let point = projector.point(latitude: place.latitude!, longitude: place.longitude!)
            XCTAssertTrue(projector.mapRect.contains(point), place.name)
            XCTAssertFalse(LearningAtlasContent.relationship(for: place).isEmpty)
        }
        for region in LearningMapRegion.allCases {
            let projector = LearningMapProjector(region: region, size: CGSize(width: 1920, height: 1080))
            for settlement in region.settlements {
                XCTAssertTrue(projector.mapRect.contains(projector.point(for: settlement.coordinate)), settlement.name)
            }
        }
    }

    func testCardinalDirectionsRoundTripAndScale() {
        for region in LearningMapRegion.allCases {
            let projector = LearningMapProjector(region: region, size: CGSize(width: 800, height: 600))
            let center = Coordinate(latitude: region.bounds.centerLatitude, longitude: region.bounds.centerLongitude)
            let point = projector.point(for: center)
            XCTAssertLessThan(projector.point(latitude: center.latitude + 0.1, longitude: center.longitude).y, point.y)
            XCTAssertGreaterThan(projector.point(latitude: center.latitude, longitude: center.longitude + 0.1).x, point.x)
            let restored = projector.coordinate(for: point)
            XCTAssertEqual(restored.latitude, center.latitude, accuracy: 0.000001)
            XCTAssertEqual(restored.longitude, center.longitude, accuracy: 0.000001)
            XCTAssertEqual(Double(projector.points(forKilometres: 20)) * projector.kilometresPerPoint, 20, accuracy: 0.000001)
        }
    }

    func testPairwiseDistancesKeepUniformScaleAcrossPhoneAndTV() {
        let places = SampleContent.shivajiVerticalSlice.places
        for region in LearningMapRegion.allCases {
            let coordinates = places.filter { LearningAtlasContent.region(for: $0) == region }.map {
                Coordinate(latitude: $0.latitude!, longitude: $0.longitude!)
            } + region.settlements.map(\.coordinate)
            for size in [CGSize(width: 390, height: 480), CGSize(width: 844, height: 390), CGSize(width: 1920, height: 1080)] {
                let projector = LearningMapProjector(region: region, size: size)
                for first in coordinates.indices {
                    for second in coordinates.indices where second > first {
                        let firstPoint = projector.point(for: coordinates[first])
                        let secondPoint = projector.point(for: coordinates[second])
                        let projectedKM = hypot(Double(firstPoint.x - secondPoint.x), Double(firstPoint.y - secondPoint.y)) * projector.kilometresPerPoint
                        let realKM = sphericalDistance(coordinates[first], coordinates[second])
                        XCTAssertEqual(projectedKM, realKM, accuracy: realKM * 0.01)
                    }
                }
            }
        }
    }

    func testCandidatesContainTargetAndTwoNearestUniqueStoryPlacesIncludingAgra() {
        let places = SampleContent.shivajiVerticalSlice.places
        for target in places {
            let candidates = LearningAtlasContent.candidates(for: target, places: places + places)
            XCTAssertEqual(candidates.count, 3)
            XCTAssertTrue(candidates.contains { $0.id == target.id })
            XCTAssertEqual(candidates.map(\.name), candidates.map(\.name).sorted { $0.localizedStandardCompare($1) == .orderedAscending })
            XCTAssertEqual(Set(candidates.map(\.id)).count, 3)
            XCTAssertTrue(candidates.allSatisfy { $0.id.hasPrefix("place-") })
        }
        let torna = places.first { $0.id == "place-torna" }!
        XCTAssertEqual(Set(LearningAtlasContent.candidates(for: torna, places: places).map(\.id)),
            ["place-torna", "place-rajgad", "place-raigad"])
    }

    func testZeroSizeAndCloseUpRemainFinite() {
        let bounds = LearningMapBounds(minLatitude: 18.17, maxLatitude: 18.37, minLongitude: 73.53, maxLongitude: 73.80)
        let projector = LearningMapProjector(bounds: bounds, size: .zero)
        XCTAssertTrue(projector.kilometresPerPoint.isFinite)
        XCTAssertTrue(projector.point(latitude: 18.246, longitude: 73.6822).x.isFinite)
    }

    func testSelectionSeparatesHighlightFromAssessmentAndPreservesSupport() {
        let candidates: Set<String> = ["target", "other"]
        func evaluate(_ selectedID: String?, solved: Bool = false, hinted: Bool = false, assist: Bool = false) -> LearningMapSelectionOutcome {
            LearningMapSelectionEngine.evaluate(targetID: "target", selectedID: selectedID, candidateIDs: candidates,
                alreadySolved: solved, usedHint: hinted, assistModeEnabled: assist)
        }
        XCTAssertEqual(evaluate(nil), .ignored)
        XCTAssertEqual(evaluate("town-pune"), .ignored)
        XCTAssertEqual(evaluate("other"), .retry)
        XCTAssertEqual(evaluate("target"), .success(.independent))
        XCTAssertEqual(evaluate("target", hinted: true), .success(.hinted))
        XCTAssertEqual(evaluate("target", assist: true), .success(.hinted))
        XCTAssertEqual(evaluate("target", solved: true), .ignored)
    }

    func testSahyadriIncludesSixReferenceSettlementsWithPratapgadWestOfHillTown() {
        let towns = LearningMapRegion.sahyadri.settlements
        XCTAssertEqual(towns.count, 6)
        XCTAssertEqual(Set(towns.map(\.id)).count, 6)
        let pratapgad = SampleContent.shivajiVerticalSlice.places.first { $0.id == "place-pratapgad" }!
        let mahabaleshwar = towns.first { $0.id == "town-mahabaleshwar" }!
        XCTAssertLessThan(pratapgad.longitude!, mahabaleshwar.coordinate.longitude)
    }

    func testInvalidAndOutOfRegionCoordinatesUseAccessibleFallback() {
        let example = SampleContent.shivajiVerticalSlice.places[0]
        func place(latitude: Double?, longitude: Double?) -> Place {
            Place(id: example.id, name: example.name, memoryHook: example.memoryHook,
                primaryEvent: example.primaryEvent, whyItMatters: example.whyItMatters,
                regionLabel: example.regionLabel, latitude: latitude, longitude: longitude,
                progress: example.progress, isCoreReleasePlace: example.isCoreReleasePlace)
        }
        XCTAssertTrue(LearningAtlasContent.hasValidCoordinate(for: example))
        XCTAssertFalse(LearningAtlasContent.hasValidCoordinate(for: place(latitude: nil, longitude: 73.8)))
        XCTAssertFalse(LearningAtlasContent.hasValidCoordinate(for: place(latitude: .nan, longitude: 73.8)))
        XCTAssertFalse(LearningAtlasContent.hasValidCoordinate(for: place(latitude: 19, longitude: .infinity)))
        XCTAssertFalse(LearningAtlasContent.hasValidCoordinate(for: place(latitude: 27.1, longitude: 78)))
        XCTAssertTrue(SampleContent.shivajiVerticalSlice.places.allSatisfy(LearningAtlasContent.hasValidCoordinate))
    }

    func testAtlasChoiceCheckpointRoundTripsAndOlderRecordsDecode() throws {
        var point = LessonResumePoint(sceneID: "scene-1-shivneri", phase: .place)
        point.selectedAtlasDiscoveryID = "hill"
        point.selectedPlaceChoiceIDs["place-shivneri"] = "place-torna"
        point.helpedPlaceIDs = ["place-shivneri"]
        let encoder = JSONEncoder()
        let saved = try encoder.encode(point)
        XCTAssertEqual(try JSONDecoder().decode(LessonResumePoint.self, from: saved), point)
        var json = try XCTUnwrap(JSONSerialization.jsonObject(with: saved) as? [String: Any])
        json.removeValue(forKey: "selectedAtlasDiscoveryID")
        json.removeValue(forKey: "selectedPlaceChoiceIDs")
        let old = try JSONDecoder().decode(LessonResumePoint.self, from: JSONSerialization.data(withJSONObject: json))
        XCTAssertNil(old.selectedAtlasDiscoveryID)
        XCTAssertEqual(old.selectedPlaceChoiceIDs, [:])
        XCTAssertEqual(old.helpedPlaceIDs, point.helpedPlaceIDs)
        XCTAssertEqual(old.sessionID, point.sessionID)
        XCTAssertTrue(old.solvedPlaceIDs.isEmpty)
    }

    func testInterruptedCheckedPlacementKeepsItsEvidenceIdentity() {
        let session = UUID()
        let first = LearningMapEvidenceIdentity.eventID(placeID: "place-shivneri", sessionID: session)
        XCTAssertEqual(first, LearningMapEvidenceIdentity.eventID(placeID: "place-shivneri", sessionID: session))
        XCTAssertNotEqual(first, LearningMapEvidenceIdentity.eventID(placeID: "place-torna", sessionID: session))
        XCTAssertNotEqual(first, LearningMapEvidenceIdentity.eventID(placeID: "place-shivneri", sessionID: UUID()))
    }

    func testStandaloneMapChoiceRestoresWithoutCreatingStoryContinuationOrEvidence() throws {
        let suite = "gob.map.fresh." + UUID().uuidString
        let defaults = try XCTUnwrap(UserDefaults(suiteName: suite))
        defer { defaults.removePersistentDomain(forName: suite) }
        let store = ShivajiLessonStore(defaults: defaults, persistencePolicy: .compactTV)
        var point = try XCTUnwrap(store.mapPlaceCheckpoint(for: "place-shivneri"))
        XCTAssertNil(store.latestResumePoint)
        point.selectedPlaceID = "place-torna"
        point.usedHelp = true
        XCTAssertTrue(store.saveMapPlaceCheckpoint(point, for: "place-shivneri"))
        XCTAssertNil(store.latestResumePoint)
        XCTAssertNil(store.masteryRecord(for: "place-shivneri"))
        let restored = ShivajiLessonStore(defaults: defaults, persistencePolicy: .compactTV)
        XCTAssertEqual(restored.mapPlaceCheckpoint(for: "place-shivneri"), point)
        XCTAssertNil(restored.latestResumePoint)
        XCTAssertNil(restored.mapPlaceCheckpoint(for: "unknown-place"))
        point.selectedPlaceID = "town-pune"
        XCTAssertFalse(restored.saveMapPlaceCheckpoint(point, for: "place-shivneri"))
        XCTAssertEqual(restored.mapPlaceCheckpoint(for: "place-shivneri")?.selectedPlaceID, "place-torna")
    }

    func testEarlierCompletedMapActivityPreservesLaterChapterSessionPhaseAndTimestamp() throws {
        let suite = "gob.map.continuation." + UUID().uuidString
        let defaults = try XCTUnwrap(UserDefaults(suiteName: suite))
        defer { defaults.removePersistentDomain(forName: suite) }
        let store = ShivajiLessonStore(defaults: defaults, persistencePolicy: .compactTV)
        let earlierID = "scene-1-shivneri"
        store.recordLearningOutcome(subjectID: earlierID, activity: .recall, wasSuccessful: true, sessionID: UUID())
        store.saveResumePoint(LessonResumePoint(sceneID: earlierID, phase: .reward))
        store.clearResumePoint(for: earlierID)
        let later = LessonResumePoint(sceneID: "scene-2-torna-rajgad", phase: .recall,
            selectedPlaceChoiceIDs: ["place-torna": "place-torna"], updatedAt: Date(timeIntervalSince1970: 100))
        store.saveResumePoint(later)
        var point = try XCTUnwrap(store.mapPlaceCheckpoint(for: "place-shivneri"))
        point.selectedPlaceID = "place-shivneri"
        point.usedHelp = true
        XCTAssertTrue(store.saveMapPlaceCheckpoint(point, for: "place-shivneri"))
        let eventID = LearningMapEvidenceIdentity.eventID(placeID: "place-shivneri", sessionID: point.sessionID)
        XCTAssertTrue(store.recordLearningOutcome(subjectID: "place-shivneri", subjectType: .location,
            activity: .recall, wasSuccessful: true, support: .hinted, eventID: eventID, sessionID: point.sessionID))
        XCTAssertTrue(store.confirmOptionalLearningEvent(eventID, for: .atlas))
        point.wasSolved = true
        point.selectedPlaceID = nil
        XCTAssertTrue(store.saveMapPlaceCheckpoint(point, for: "place-shivneri"))
        let restored = ShivajiLessonStore(defaults: defaults, persistencePolicy: .compactTV)
        XCTAssertNil(restored.resumePoint(for: earlierID))
        XCTAssertEqual(restored.latestResumePoint, later)
        XCTAssertEqual(restored.mapPlaceCheckpoint(for: "place-shivneri"), point)
        XCTAssertEqual(restored.mastery(for: earlierID), .understood)
        XCTAssertEqual(restored.masteryRecord(for: "place-shivneri")?.evidenceLog.last?.support, .hinted)
        XCTAssertTrue(restored.persistenceDiagnostics.isWithinBudget)
    }

    func testStandaloneMapReceiptSurvivesCompactHistoryRotation() throws {
        let suite = "gob.map.receipt." + UUID().uuidString
        let defaults = try XCTUnwrap(UserDefaults(suiteName: suite))
        defer { defaults.removePersistentDomain(forName: suite) }
        let store = ShivajiLessonStore(defaults: defaults, persistencePolicy: .compactTV)
        var point = try XCTUnwrap(store.mapPlaceCheckpoint(for: "place-shivneri"))
        point.selectedPlaceID = "place-shivneri"
        XCTAssertTrue(store.saveMapPlaceCheckpoint(point, for: "place-shivneri"))
        let eventID = LearningMapEvidenceIdentity.eventID(placeID: "place-shivneri", sessionID: point.sessionID)
        XCTAssertTrue(store.recordLearningOutcome(subjectID: "place-shivneri", subjectType: .location,
            activity: .recall, wasSuccessful: true, support: .hinted, eventID: eventID, sessionID: point.sessionID))
        XCTAssertTrue(store.confirmOptionalLearningEvent(eventID, for: .atlas))
        for _ in 0..<270 { store.recordStoryExposure(for: "scene-1-shivneri") }
        let restored = ShivajiLessonStore(defaults: defaults, persistencePolicy: .compactTV)
        XCTAssertTrue(restored.hasRecordedLearningEvent(eventID))
        XCTAssertFalse(restored.recordLearningOutcome(subjectID: "place-shivneri", subjectType: .location,
            activity: .recall, wasSuccessful: true, support: .hinted, eventID: eventID, sessionID: point.sessionID))
        XCTAssertNil(restored.latestResumePoint)
    }

    private func sphericalDistance(_ first: Coordinate, _ second: Coordinate) -> Double {
        let radians = Double.pi / 180
        let haversine = pow(sin((second.latitude - first.latitude) * radians / 2), 2)
            + cos(first.latitude * radians) * cos(second.latitude * radians) * pow(sin((second.longitude - first.longitude) * radians / 2), 2)
        return 2 * LearningMapProjector.earthRadiusKilometres * asin(sqrt(haversine))
    }
}
