import XCTest
@testable import Greats_Of_Bharatha

final class GreatsOfBharathaTests: XCTestCase {
    func testSampleContentHasCanonicalSixSceneArc() {
        let model = AppModel()
        XCTAssertEqual(model.content.scenes.map(\.id), [
            "scene-1-shivneri",
            "scene-2-torna-rajgad",
            "scene-3-pratapgad-turning-point",
            "scene-4-purandar-agra",
            "scene-5-rajgad-recovery",
            "scene-6-raigad-coronation",
        ])
        XCTAssertEqual(model.content.scenes.first?.title, "Shivneri, where Shivaji Maharaj's story begins")
        XCTAssertEqual(model.content.scenes.first?.recallPrompt.answer, "Shivneri Fort")
        XCTAssertEqual(model.content.activeHeroArc.timelineEvents.map(\.id), [
            "timeline-born-at-shivneri",
            "timeline-early-forts",
            "timeline-pratapgad-turning-point",
            "timeline-pressure-at-purandar",
            "timeline-agra-and-return",
            "timeline-comeback-and-rebuilding",
            "timeline-raigad-coronation",
        ])
        XCTAssertEqual(Set(model.content.corePlaces.map(\.id)), [
            "place-shivneri",
            "place-torna",
            "place-rajgad",
            "place-pratapgad",
            "place-raigad",
        ])
    }

    func testSampleContentChronicleAndReviewBlueprintCoverage() {
        let heroArc = SampleContent.shivajiHeroArc

        XCTAssertEqual(heroArc.chronicleEntries.count, 18)
        XCTAssertEqual(Set(heroArc.chronicleEntries.map(\.linkedSceneID)), Set(heroArc.scenes.map(\.id)))
        XCTAssertEqual(Set(heroArc.locationNodes.map(\.id)), [
            "place-shivneri",
            "place-torna",
            "place-rajgad",
            "place-pratapgad",
            "place-purandar",
            "place-agra",
            "place-raigad",
        ])
        XCTAssertEqual(Set(heroArc.reviewBlueprints.filter { $0.subjectType == .scene }.map(\.subjectID)), Set(heroArc.scenes.map(\.id)))
        XCTAssertTrue(heroArc.reviewBlueprints.contains { $0.subjectID == "timeline-agra-and-return" && $0.subjectType == .timeline })
        XCTAssertTrue(heroArc.reviewBlueprints.contains { $0.subjectID == "place-raigad" && $0.subjectType == .location })
    }

    func testLessonStorePreviewsChronicleRewardsBeforeUnlockingThem() {
        let defaults = UserDefaults(suiteName: #function)!
        defaults.removePersistentDomain(forName: #function)
        let store = ShivajiLessonStore(defaults: defaults)

        XCTAssertEqual(store.completedScenes, 0)
        XCTAssertEqual(store.nextSceneID, "scene-1-shivneri")
        XCTAssertFalse(store.isPreviewed(SampleContent.birthFortCard))
        XCTAssertFalse(store.isUnlocked(SampleContent.birthFortCard))

        let guidanceEntry = SampleContent.shivajiHeroArc.chronicleEntry(withID: "reward-jijabai-guidance-badge")
        XCTAssertNotNil(guidanceEntry)
        XCTAssertEqual(store.chronicleUnlockState(for: guidanceEntry!), .silhouette)

        store.recordStoryExposure(for: "scene-1-shivneri")

        XCTAssertTrue(store.isPreviewed(SampleContent.birthFortCard))
        XCTAssertFalse(store.isUnlocked(SampleContent.birthFortCard))
        XCTAssertEqual(store.chronicleUnlockState(for: guidanceEntry!), .silhouette)
        XCTAssertEqual(store.chronicleHeadline, "Your first keepsake is taking shape")

        store.markScene("scene-1-shivneri", mastery: .understood)

        XCTAssertEqual(store.completedScenes, 1)
        XCTAssertEqual(store.nextSceneID, "scene-2-torna-rajgad")
        XCTAssertTrue(store.isUnlocked(SampleContent.birthFortCard))
        XCTAssertEqual(store.chronicleUnlockState(for: guidanceEntry!), .unlocked)
    }

    func testLessonStoreTracksEnrichedChronicleState() {
        let defaults = UserDefaults(suiteName: #function)!
        defaults.removePersistentDomain(forName: #function)
        let store = ShivajiLessonStore(defaults: defaults)

        let guidanceEntry = SampleContent.shivajiHeroArc.chronicleEntry(withID: "reward-jijabai-guidance-badge")!

        store.markScene("scene-1-shivneri", mastery: .observedClosely)

        XCTAssertEqual(store.chronicleUnlockState(for: guidanceEntry), .enriched)
        XCTAssertEqual(store.unlockedChronicleCount, 3)
        XCTAssertEqual(store.enrichedChronicleCount, 2)
        XCTAssertEqual(store.chronicleHeadline, "Your Chronicle is deepening")
    }

    func testRecallEngineRevealsHintLadderBeforeRecognitionRescue() {
        let challenge = RecallChallenge(
            id: "scene-1-recall",
            promptType: .openPrompt,
            prompt: "Which fort is the birth place?",
            correctAnswers: ["Shivneri Fort"],
            hintLadder: [
                RecallHint(level: 1, title: "Anchor hint", body: "Think about the Birth Fort."),
                RecallHint(level: 2, title: "Place hint", body: "It is near Junnar."),
                RecallHint(level: 3, title: "Category hint", body: "It is a hill fort."),
            ],
            feedback: RecallFeedback(success: "Yes.", recovery: "Use recognition rescue."),
            masteryContribution: .remembered
        )

        var state = LessonRecallState()
        state = LessonRecallEngine.revealNextHint(from: state, challenge: challenge)
        XCTAssertEqual(state.revealedHintLevel, 1)
        XCTAssertFalse(state.recognitionRescueUnlocked)
        XCTAssertEqual(LessonRecallEngine.currentHint(for: state, challenge: challenge)?.title, "Anchor hint")

        state = LessonRecallEngine.revealNextHint(from: state, challenge: challenge)
        state = LessonRecallEngine.revealNextHint(from: state, challenge: challenge)
        XCTAssertEqual(state.revealedHintLevel, 3)
        XCTAssertFalse(state.recognitionRescueUnlocked)

        state = LessonRecallEngine.revealNextHint(from: state, challenge: challenge)
        XCTAssertTrue(state.recognitionRescueUnlocked)
        XCTAssertEqual(state.feedbackText, "Use recognition rescue.")
    }

    func testRecallEngineAwardsSuccessMasteryForTypedAnswer() {
        let challenge = RecallChallenge(
            id: "scene-2-recall",
            promptType: .openPrompt,
            prompt: "Which fort became an early capital?",
            correctAnswers: ["Rajgad"],
            hintLadder: [RecallHint(level: 1, title: "Meaning hint", body: "It came after Torna.")],
            feedback: RecallFeedback(success: "Yes. Rajgad became an early capital.", recovery: "Almost."),
            masteryContribution: .understood
        )

        let evaluation = LessonRecallEngine.submit(
            state: LessonRecallState(),
            challenge: challenge,
            typedAnswer: "Rajgad",
            selectedChoiceTitle: nil,
            successMastery: .observedClosely
        )

        XCTAssertTrue(evaluation.wasSuccessful)
        XCTAssertEqual(evaluation.masteryAwarded, .observedClosely)
        XCTAssertEqual(evaluation.feedbackText, "Yes. Rajgad became an early capital.")
    }

    func testStoreRecordRecallOutcomeAdvancesReviewSchedule() {
        let defaults = UserDefaults(suiteName: #function)!
        defaults.removePersistentDomain(forName: #function)
        let store = ShivajiLessonStore(defaults: defaults)

        store.recordRecallOutcome(
            subjectID: "scene-1-shivneri",
            promptType: .openPrompt,
            wasSuccessful: true,
            mastery: .remembered,
            detail: "Test recall success"
        )

        XCTAssertEqual(store.mastery(for: "scene-1-shivneri"), .remembered)
        let record = store.masteryRecord(for: "scene-1-shivneri")
        XCTAssertEqual(record?.successfulReviewCount, 1)
        XCTAssertEqual(record?.evidenceLog.last?.type, .reviewSuccess)

        let dueReviews = store.dueReviews(referenceDate: .distantFuture)
        let schedule = dueReviews.first { $0.subjectID == "scene-1-shivneri" }
        XCTAssertNotNil(schedule)
        XCTAssertEqual(schedule?.intervalIndex, 1)
        XCTAssertEqual(schedule?.stabilityBand, .warming)
    }
    func testTimelineProgressAndUpcomingReviewsReflectStoredMastery() {
        let defaults = UserDefaults(suiteName: #function)!
        defaults.removePersistentDomain(forName: #function)
        let store = ShivajiLessonStore(defaults: defaults)

        XCTAssertEqual(store.totalTimelineEvents, 7)
        XCTAssertEqual(store.unlockedTimelineCount, 0)
        XCTAssertEqual(store.timelineHeadline, "Unlock the first moment in order")
        XCTAssertEqual(store.dueReviewCount, 0)
        XCTAssertEqual(store.upcomingReviews(limit: 2).count, 2)

        store.markScene("scene-1-shivneri", mastery: .understood)
        XCTAssertEqual(store.unlockedTimelineCount, 1)
        XCTAssertEqual(store.masteredTimelineCount, 0)
        XCTAssertEqual(store.timelineHeadline, "Order is starting to stick")

        store.recordRecallOutcome(
            subjectID: "scene-1-shivneri",
            promptType: .openPrompt,
            wasSuccessful: true,
            mastery: .placed,
            detail: "Strengthen first scene"
        )

        XCTAssertEqual(store.masteredTimelineCount, 1)
        XCTAssertEqual(store.timelineHeadline, "Your timeline confidence is growing")
    }

    func testParentProgressHelpersReflectRetrievalState() {
        let defaults = UserDefaults(suiteName: #function)!
        defaults.removePersistentDomain(forName: #function)
        let store = ShivajiLessonStore(defaults: defaults)

        XCTAssertEqual(store.totalCorePlaces, 5)
        XCTAssertEqual(store.masteredPlaceCount, 0)
        XCTAssertEqual(store.parentProgressHeadline, "The learning journey is ready to begin")
        XCTAssertTrue(store.retrievalExplanation.contains("gentle recall"))

        store.markScene("scene-1-shivneri", mastery: .understood)
        store.recordRecallOutcome(
            subjectID: "place-shivneri",
            subjectType: .location,
            promptType: .mapPlacement,
            wasSuccessful: true,
            mastery: .placed,
            detail: "Place mastered"
        )

        XCTAssertEqual(store.masteredPlaceCount, 1)
        XCTAssertTrue(store.parentProgressHeadline.contains("Meaning is starting to stick") || store.parentProgressHeadline.contains("Story, place, and review"))
    }

    func testAppModelExposesParentSettingsHooks() {
        let model = AppModel()
        XCTAssertTrue(model.parentSettings.assistModeEnabled)
        XCTAssertTrue(model.parentSettings.narrationEnabled)
        XCTAssertTrue(model.parentSettings.calmTransitionsEnabled)

        model.parentSettings.narrationEnabled = false
        XCTAssertFalse(model.parentSettings.narrationEnabled)
    }

    func testCorePlacesExposeMapExplorerCoordinatesAndAppleMapsLinks() {
        for place in SampleContent.shivajiVerticalSlice.corePlaces {
            XCTAssertEqual(place.coordinate.latitude, place.latitude, accuracy: 0.0001)
            XCTAssertEqual(place.coordinate.longitude, place.longitude, accuracy: 0.0001)

            let url = try XCTUnwrap(place.appleMapsURL)
            let components = try XCTUnwrap(URLComponents(url: url, resolvingAgainstBaseURL: false))
            let queryItems = components.queryItems ?? []

            XCTAssertEqual(components.host, "maps.apple.com")
            XCTAssertEqual(queryItems.first(where: { $0.name == "ll" })?.value, "\(place.latitude),\(place.longitude)")
            XCTAssertEqual(queryItems.first(where: { $0.name == "q" })?.value, place.name)
        }
    }

    func testCorePlacesProduceStableExplorerViewport() {
        let corePlaces = SampleContent.shivajiVerticalSlice.corePlaces
        let focusPlace = try! XCTUnwrap(corePlaces.first(where: { $0.id == "place-raigad" }))
        let viewport = Place.explorerViewport(for: focusPlace, nearbyPlaces: corePlaces)

        XCTAssertGreaterThan(viewport.latitudeDelta, 0)
        XCTAssertGreaterThan(viewport.longitudeDelta, 0)
        XCTAssertGreaterThanOrEqual(viewport.latitudeDelta, 0.4)
        XCTAssertGreaterThanOrEqual(viewport.longitudeDelta, 0.4)
        XCTAssertLessThanOrEqual(abs(viewport.centerLatitude - focusPlace.latitude), viewport.latitudeDelta)
        XCTAssertLessThanOrEqual(abs(viewport.centerLongitude - focusPlace.longitude), viewport.longitudeDelta)
    }

}
