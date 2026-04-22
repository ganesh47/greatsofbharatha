import Combine
import Foundation

final class ShivajiLessonStore: ObservableObject {
    @Published private(set) var masteryByScene: [String: MasteryState] = [:]
    @Published private(set) var masteryRecordsBySubject: [String: MasteryRecord] = [:]
    @Published private(set) var reviewSchedulesBySubject: [String: ReviewSchedule] = [:]

    private let content: AppContent
    private let defaults: UserDefaults
    private let recordsStorageKey = "shivajiLessonStore.masteryRecords"
    private let reviewStorageKey = "shivajiLessonStore.reviewSchedules"
    private let legacyMasteryStorageKey = "shivajiLessonStore.masteryByScene"

    init(content: AppContent = SampleContent.shivajiVerticalSlice, defaults: UserDefaults = .standard) {
        self.content = content
        self.defaults = defaults
        self.masteryRecordsBySubject = Self.loadRecords(from: defaults, key: recordsStorageKey)
        self.reviewSchedulesBySubject = Self.loadSchedules(from: defaults, key: reviewStorageKey)

        if masteryRecordsBySubject.isEmpty {
            let migratedMastery = Self.loadLegacyMastery(from: defaults, key: legacyMasteryStorageKey)
            masteryRecordsBySubject = migratedMastery.reduce(into: [:]) { partialResult, pair in
                partialResult[pair.key] = MasteryRecord(
                    subjectID: pair.key,
                    subjectType: .scene,
                    state: pair.value,
                    exposureCount: 1,
                    successfulReviewCount: pair.value >= .understood ? 1 : 0,
                    lastReviewedAt: nil,
                    evidenceLog: []
                )
            }
        }

        if reviewSchedulesBySubject.isEmpty {
            reviewSchedulesBySubject = Dictionary(uniqueKeysWithValues: content.activeHeroArc.reviewBlueprints.map { ($0.subjectID, $0) })
        }

        syncLegacySceneMastery()
    }

    func mastery(for sceneID: String) -> MasteryState? {
        masteryByScene[sceneID]
    }

    func masteryRecord(for subjectID: String) -> MasteryRecord? {
        masteryRecordsBySubject[subjectID]
    }

    func recordStoryExposure(for sceneID: String, detail: String = "Scene viewed") {
        updateRecord(subjectID: sceneID, subjectType: .scene, newState: .witnessed, evidenceType: .storyExposure, detail: detail)
    }

    func markScene(_ sceneID: String, mastery: MasteryState) {
        let evidenceType: MasteryEvidenceType = mastery >= .remembered ? .reviewSuccess : (mastery >= .understood ? .recallSuccess : .recallAttempt)
        updateRecord(subjectID: sceneID, subjectType: .scene, newState: mastery, evidenceType: evidenceType, detail: "Scene mastery updated")
    }

    func resetScene(_ sceneID: String) {
        masteryRecordsBySubject.removeValue(forKey: sceneID)
        reviewSchedulesBySubject.removeValue(forKey: sceneID)
        ensureReviewBlueprint(for: sceneID, subjectType: .scene)
        persist()
    }

    func isSceneUnlocked(_ scene: StoryScene) -> Bool {
        guard let sceneIndex = content.scenes.firstIndex(where: { $0.id == scene.id }) else {
            return false
        }
        if sceneIndex == 0 {
            return true
        }

        let previousScene = content.scenes[content.scenes.index(before: sceneIndex)]
        return (mastery(for: previousScene.id) ?? .witnessed) >= .understood
    }

    func isUnlocked(_ reward: ChronicleReward) -> Bool {
        guard let entry = content.activeHeroArc.chronicleEntries.first(where: { $0.id == reward.id }) else {
            return (mastery(for: reward.unlockedBySceneID) ?? .witnessed) >= reward.mastery
        }
        return chronicleUnlockState(for: entry) != .silhouette
    }

    func unlockedRewards(from rewards: [ChronicleReward]) -> [ChronicleReward] {
        rewards.filter { isUnlocked($0) }
    }

    func progress(for place: Place) -> PlaceProgress {
        guard let node = content.activeHeroArc.locationNodes.first(where: { $0.id == place.id }) else {
            return place.progress
        }

        switch locationUnlockState(for: node) {
        case .hidden:
            return .locked
        case .seenInStory, .learnable:
            return .readyToLearn
        case .remembered:
            return .reviewed
        case .placedAccurately, .masteredInReview:
            return .masteredLightly
        }
    }

    func chronicleUnlockState(for entry: ChronicleEntry) -> ChronicleUnlockState {
        let sceneMastery = mastery(for: entry.linkedSceneID) ?? .witnessed
        guard sceneMastery >= entry.unlockRule.requiredMastery else {
            return .silhouette
        }

        if let enhanced = entry.unlockRule.enhancedMastery, sceneMastery >= enhanced {
            return .enriched
        }

        return .unlocked
    }

    func locationUnlockState(for node: LocationNode) -> LocationUnlockState {
        let linkedSceneMasteries = node.linkedSceneIDs.compactMap { mastery(for: $0) }
        let strongestSceneMastery = linkedSceneMasteries.max() ?? .witnessed

        if strongestSceneMastery < .understood {
            let hasUnlockedLinkedScene = node.linkedSceneIDs.contains { sceneID in
                content.scenes.first(where: { $0.id == sceneID }).map(isSceneUnlocked) ?? false
            }
            return hasUnlockedLinkedScene ? .learnable : .hidden
        }

        let record = masteryRecord(for: node.id)
        let locationMastery = record?.state ?? strongestSceneMastery

        if locationMastery >= .placed {
            return .placedAccurately
        }
        if locationMastery >= .remembered || strongestSceneMastery >= .remembered {
            return .remembered
        }
        if strongestSceneMastery >= .understood {
            return .learnable
        }
        return .seenInStory
    }

    func timelineUnlockState(for event: TimelineEvent) -> LocationUnlockState {
        let linkedSceneMasteries = content.activeHeroArc.scenes
            .filter { $0.timelineEventID == event.id }
            .compactMap { mastery(for: $0.id) }
        let strongestMastery = linkedSceneMasteries.max() ?? .witnessed

        if strongestMastery < event.unlockRule.requiredMastery {
            return .hidden
        }
        if let enhanced = event.unlockRule.enhancedMastery, strongestMastery >= enhanced {
            return .placedAccurately
        }
        return .remembered
    }

    func dueReviews(referenceDate: Date = Date()) -> [ReviewSchedule] {
        reviewSchedulesBySubject.values
            .filter { $0.nextDueAt <= referenceDate }
            .sorted { lhs, rhs in lhs.nextDueAt < rhs.nextDueAt }
    }

    var completedScenes: Int {
        content.scenes.filter { (mastery(for: $0.id) ?? .witnessed) >= .understood }.count
    }

    var totalScenes: Int {
        content.scenes.count
    }

    var overallProgress: Double {
        guard totalScenes > 0 else { return 0 }
        return Double(completedScenes) / Double(totalScenes)
    }

    var chronicleHeadline: String {
        switch completedScenes {
        case 0:
            return "Begin the Chronicle"
        case totalScenes:
            return "The first Chronicle page is complete"
        default:
            return "Your Chronicle is taking shape"
        }
    }

    var nextSceneID: String? {
        content.scenes.first(where: { (mastery(for: $0.id) ?? .witnessed) < .understood })?.id
    }

    func applyCaptureSeed(_ profile: CaptureSeedProfile) {
        switch profile {
        case .pristine:
            masteryRecordsBySubject = [:]
            reviewSchedulesBySubject = Dictionary(uniqueKeysWithValues: content.activeHeroArc.reviewBlueprints.map { ($0.subjectID, $0) })
        case .chronicleUnlocked:
            let now = Date()
            masteryRecordsBySubject = [
                "scene-1-shivneri": MasteryRecord(
                    subjectID: "scene-1-shivneri",
                    subjectType: .scene,
                    state: .understood,
                    exposureCount: 1,
                    successfulReviewCount: 1,
                    lastReviewedAt: now,
                    evidenceLog: [MasteryEvidence(type: .recallSuccess, recordedAt: now, detail: "Capture seed")]
                ),
                "scene-2-torna-rajgad": MasteryRecord(
                    subjectID: "scene-2-torna-rajgad",
                    subjectType: .scene,
                    state: .observedClosely,
                    exposureCount: 1,
                    successfulReviewCount: 1,
                    lastReviewedAt: now,
                    evidenceLog: [MasteryEvidence(type: .reviewSuccess, recordedAt: now, detail: "Capture seed")]
                )
            ]
            reviewSchedulesBySubject = Dictionary(uniqueKeysWithValues: content.activeHeroArc.reviewBlueprints.map { ($0.subjectID, $0) })
            if var scene1 = reviewSchedulesBySubject["scene-1-shivneri"] {
                scene1.nextDueAt = now.addingTimeInterval(24 * 60 * 60)
                scene1.intervalIndex = 1
                scene1.stabilityBand = .warming
                reviewSchedulesBySubject[scene1.subjectID] = scene1
            }
        }
        persist()
    }

    private func updateRecord(subjectID: String, subjectType: MasterySubjectType, newState: MasteryState, evidenceType: MasteryEvidenceType, detail: String) {
        let now = Date()
        var record = masteryRecordsBySubject[subjectID] ?? MasteryRecord(
            subjectID: subjectID,
            subjectType: subjectType,
            state: .witnessed,
            exposureCount: 0,
            successfulReviewCount: 0,
            lastReviewedAt: nil,
            evidenceLog: []
        )

        record.state = max(record.state, newState)
        record.exposureCount += 1
        if newState >= .understood {
            record.successfulReviewCount += 1
            record.lastReviewedAt = now
            advanceReviewSchedule(for: subjectID, subjectType: subjectType, referenceDate: now, success: true)
        } else {
            ensureReviewBlueprint(for: subjectID, subjectType: subjectType)
        }
        record.evidenceLog.append(MasteryEvidence(type: evidenceType, recordedAt: now, detail: detail))
        masteryRecordsBySubject[subjectID] = record
        persist()
    }

    private func advanceReviewSchedule(for subjectID: String, subjectType: MasterySubjectType, referenceDate: Date, success: Bool) {
        ensureReviewBlueprint(for: subjectID, subjectType: subjectType)
        guard var schedule = reviewSchedulesBySubject[subjectID] else { return }

        let nextIndex = success ? min(schedule.intervalIndex + 1, max(schedule.cadenceDays.count - 1, 0)) : 0
        schedule.intervalIndex = nextIndex
        let cadenceDay = schedule.cadenceDays.isEmpty ? 0 : schedule.cadenceDays[nextIndex]
        schedule.nextDueAt = Calendar.current.date(byAdding: .day, value: cadenceDay, to: referenceDate) ?? referenceDate
        schedule.stabilityBand = stabilityBand(for: nextIndex)
        reviewSchedulesBySubject[subjectID] = schedule
    }

    private func ensureReviewBlueprint(for subjectID: String, subjectType: MasterySubjectType) {
        if reviewSchedulesBySubject[subjectID] != nil {
            return
        }

        let blueprint = content.activeHeroArc.reviewBlueprints.first(where: { $0.subjectID == subjectID }) ?? ReviewSchedule(
            subjectID: subjectID,
            subjectType: subjectType,
            nextDueAt: .distantFuture,
            intervalIndex: 0,
            stabilityBand: .new,
            difficultyAdjustment: 0,
            cadenceDays: [0, 1, 3, 7, 14]
        )
        reviewSchedulesBySubject[subjectID] = blueprint
    }

    private func stabilityBand(for intervalIndex: Int) -> ReviewStabilityBand {
        switch intervalIndex {
        case 0:
            return .new
        case 1:
            return .warming
        case 2...3:
            return .steady
        default:
            return .durable
        }
    }

    private func syncLegacySceneMastery() {
        masteryByScene = masteryRecordsBySubject.reduce(into: [:]) { partialResult, pair in
            guard pair.value.subjectType == .scene else { return }
            partialResult[pair.key] = pair.value.state
        }
    }

    private func persist() {
        syncLegacySceneMastery()
        defaults.set(masteryByScene.mapValues { $0.rawValue }, forKey: legacyMasteryStorageKey)

        let encoder = JSONEncoder()
        if let recordsData = try? encoder.encode(masteryRecordsBySubject) {
            defaults.set(recordsData, forKey: recordsStorageKey)
        }
        if let scheduleData = try? encoder.encode(reviewSchedulesBySubject) {
            defaults.set(scheduleData, forKey: reviewStorageKey)
        }
    }

    private static func loadRecords(from defaults: UserDefaults, key: String) -> [String: MasteryRecord] {
        guard let data = defaults.data(forKey: key),
              let records = try? JSONDecoder().decode([String: MasteryRecord].self, from: data) else {
            return [:]
        }
        return records
    }

    private static func loadSchedules(from defaults: UserDefaults, key: String) -> [String: ReviewSchedule] {
        guard let data = defaults.data(forKey: key),
              let schedules = try? JSONDecoder().decode([String: ReviewSchedule].self, from: data) else {
            return [:]
        }
        return schedules
    }

    private static func loadLegacyMastery(from defaults: UserDefaults, key: String) -> [String: MasteryState] {
        guard let stored = defaults.dictionary(forKey: key) as? [String: String] else {
            return [:]
        }

        return stored.reduce(into: [:]) { partialResult, pair in
            guard let mastery = MasteryState(rawValue: pair.value) else { return }
            partialResult[pair.key] = mastery
        }
    }
}
