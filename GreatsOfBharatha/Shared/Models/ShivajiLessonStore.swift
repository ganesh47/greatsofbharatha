import Combine
import Compression
import Foundation

/// Injectable so migrations and the TV storage ceiling can be exercised in either test target.
struct LessonPersistencePolicy: Equatable {
    let maximumDefaultsBytes: Int?
    let recentEvidenceLimit: Int
    let recentEventLimit: Int
    let evidenceDetailLimit: Int
    let recoveryLimitBytes: Int

    static let standard = LessonPersistencePolicy(maximumDefaultsBytes: nil, recentEvidenceLimit: .max,
        recentEventLimit: 0, evidenceDetailLimit: .max, recoveryLimitBytes: .max)
    static let compactTV = LessonPersistencePolicy(maximumDefaultsBytes: 256 * 1024, recentEvidenceLimit: 8,
        recentEventLimit: 256, evidenceDetailLimit: 160, recoveryLimitBytes: 16 * 1024)
    static var platformDefault: LessonPersistencePolicy {
#if os(tvOS)
        .compactTV
#else
        .standard
#endif
    }
}

struct LessonPersistenceDiagnostics: Equatable {
    var snapshotBytes = 0
    var appOwnedDefaultsBytes = 0
    var limitBytes: Int?
    var statusMessage: String?
    var isWithinBudget: Bool { limitBytes.map { appOwnedDefaultsBytes <= $0 } ?? true }
}

final class ShivajiLessonStore: ObservableObject {
    @Published private(set) var masteryByScene: [String: MasteryState] = [:]
    @Published private(set) var masteryRecordsBySubject: [String: MasteryRecord] = [:]
    @Published private(set) var reviewSchedulesBySubject: [String: ReviewSchedule] = [:]

    @Published private(set) var resumePointsByScene: [String: LessonResumePoint] = [:]
    @Published private(set) var persistenceDiagnostics = LessonPersistenceDiagnostics()

    private let content: AppContent
    private let defaults: UserDefaults
    private let persistencePolicy: LessonPersistencePolicy
    private var recentEventIDs: [UUID] = []
    private var pendingRecoveryData: Data?
    private let recordsStorageKey = "shivajiLessonStore.masteryRecords"
    private let reviewStorageKey = "shivajiLessonStore.reviewSchedules"
    private let snapshotStorageKey = "shivajiLessonStore.snapshot.v1"
    private let legacyMasteryStorageKey = "shivajiLessonStore.masteryByScene"

    init(content: AppContent = SampleContent.shivajiVerticalSlice, defaults: UserDefaults = .standard,
         persistencePolicy: LessonPersistencePolicy = .platformDefault) {
        self.content = content
        self.defaults = defaults
        self.persistencePolicy = persistencePolicy
        self.masteryRecordsBySubject = Self.loadRecords(from: defaults, key: recordsStorageKey)
        self.reviewSchedulesBySubject = Self.loadSchedules(from: defaults, key: reviewStorageKey)
        var loadedSnapshot = false
        if let data = defaults.data(forKey: snapshotStorageKey) {
            if let snapshot = Self.decodeSnapshot(data), (1...2).contains(snapshot.schemaVersion) {
                loadedSnapshot = true
                masteryRecordsBySubject = snapshot.records
                reviewSchedulesBySubject = snapshot.schedules
                resumePointsByScene = snapshot.resumePoints
                recentEventIDs = snapshot.recentEventIDs
            } else {
                if persistencePolicy.maximumDefaultsBytes != nil {
                    // A bounded, healthy recovery retains earned learning facts even if the main write is damaged.
                    if let recovery = defaults.data(forKey: snapshotStorageKey + ".recovery"),
                       let snapshot = Self.decodeSnapshot(recovery), (1...2).contains(snapshot.schemaVersion) {
                        loadedSnapshot = true
                        masteryRecordsBySubject = snapshot.records
                        reviewSchedulesBySubject = snapshot.schedules
                        resumePointsByScene = snapshot.resumePoints
                        recentEventIDs = snapshot.recentEventIDs
                    } else {
                        pendingRecoveryData = Data(data.prefix(persistencePolicy.recoveryLimitBytes))
                    }
                } else {
                    // Preserve existing iOS fallback and recovery behavior.
                    defaults.set(data, forKey: snapshotStorageKey + ".recovery")
                }
            }
        }

        if !loadedSnapshot && masteryRecordsBySubject.isEmpty {
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

        // Preserve earned pre-evidence records when a new exposure is appended. Historical
        // support and session are unknown, so this imported fact cannot claim an independent revisit.
        for (id, var record) in masteryRecordsBySubject where record.state >= .understood && record.evidenceLog.isEmpty {
            record.evidenceLog.append(MasteryEvidence(type: .recallSuccess,
                recordedAt: record.lastReviewedAt ?? .distantPast, detail: "Imported saved mastery; support unknown",
                support: .selfReported))
            masteryRecordsBySubject[id] = record
        }

        if reviewSchedulesBySubject.isEmpty {
            reviewSchedulesBySubject = Dictionary(uniqueKeysWithValues: content.activeHeroArc.reviewBlueprints.map { ($0.subjectID, $0) })
        }

        syncLegacySceneMastery()
        if persistencePolicy.maximumDefaultsBytes != nil {
            // Import first, then remove duplicate legacy writes and compact even before the first new activity.
            persist()
        } else {
            updatePersistenceDiagnostics()
        }
    }

    func mastery(for sceneID: String) -> MasteryState? {
        masteryByScene[sceneID]
    }

    func masteryRecord(for subjectID: String) -> MasteryRecord? {
        masteryRecordsBySubject[subjectID]
    }

    func refreshPersistenceDiagnostics() {
        updatePersistenceDiagnostics()
    }

    @discardableResult
    func recordStoryExposure(for sceneID: String, detail: String = "Scene viewed", eventID: UUID = UUID(), sessionID: UUID? = nil, at date: Date = Date()) -> Bool {
        recordLearningOutcome(subjectID: sceneID, activity: .storyExposure, wasSuccessful: false, detail: detail, eventID: eventID, sessionID: sessionID, at: date)
    }

    /// Compatibility entry point for explicit imports/admin state. Child activity uses typed outcomes below.
    func markScene(_ sceneID: String, mastery: MasteryState) {
        let evidenceType: MasteryEvidenceType = mastery >= .remembered ? .reviewSuccess : (mastery >= .understood ? .recallSuccess : .recallAttempt)
        updateRecord(subjectID: sceneID, subjectType: .scene, newState: mastery, evidenceType: evidenceType, detail: "Imported scene mastery")
    }

    @discardableResult
    func recordRecallOutcome(
        subjectID: String,
        subjectType: MasterySubjectType = .scene,
        promptType: RecallPromptType,
        wasSuccessful: Bool,
        mastery: MasteryState,
        detail: String,
        support: LearningSupport = .independent,
        eventID: UUID = UUID(),
        sessionID: UUID? = nil,
        at date: Date = Date()
    ) -> Bool {
        let activity: LearningActivityKind
        switch promptType {
        case .mapPlacement: activity = subjectType == .location ? .mapPlacement : .recall
        case .sequenceSlot: activity = subjectType == .timeline ? .timelinePlacement : .recall
        case .eventToPlaceMatch: activity = subjectType == .location ? .mapPlacement : .match
        case .openPrompt, .compareFromMemory: activity = .recall
        }
        return recordLearningOutcome(subjectID: subjectID, subjectType: subjectType, activity: activity,
                                     wasSuccessful: wasSuccessful, support: support, mastery: mastery,
                                     promptType: promptType, detail: detail, eventID: eventID, sessionID: sessionID, at: date)
    }

    /// One persisted evidence boundary for normal lessons and pilot activities. IDs must be canonical.
    // Optional provenance arguments keep existing view adapters source compatible.
    @discardableResult
    // swiftlint:disable:next function_parameter_count
    func recordLearningOutcome(
        subjectID: String,
        subjectType: MasterySubjectType = .scene,
        activity: LearningActivityKind,
        wasSuccessful: Bool,
        support: LearningSupport = .independent,
        mastery: MasteryState = .understood,
        promptType: RecallPromptType = .openPrompt,
        detail: String = "",
        eventID: UUID = UUID(),
        sessionID: UUID? = nil,
        at date: Date = Date()
    ) -> Bool {
        guard isKnownSubject(subjectID, type: subjectType), !hasRecorded(eventID: eventID) else { return false }
        guard activity != .mapPlacement || subjectType == .location,
              activity != .timelinePlacement || subjectType == .timeline else { return false }
        var record = masteryRecordsBySubject[subjectID] ?? emptyRecord(subjectID, type: subjectType)
        var evidenceType: MasteryEvidenceType = .recallAttempt
        var awardedMastery: MasteryState = .witnessed

        switch activity {
        case .storyExposure:
            evidenceType = .storyExposure
            record.exposureCount += 1
        case .recall:
            if wasSuccessful {
                awardedMastery = subjectType == .scene && record.evidenceLog.contains(where: { $0.type == .matchSuccess })
                    ? .observedClosely : .understood
                evidenceType = .recallSuccess
            }
        case .match:
            if wasSuccessful {
                awardedMastery = record.evidenceLog.contains(where: { $0.type == .recallSuccess || $0.type == .reviewSuccess })
                    ? .observedClosely : .witnessed
                evidenceType = .matchSuccess
            }
        case .mapPlacement:
            if wasSuccessful {
                awardedMastery = support == .independent ? .placed : .understood
                evidenceType = .mapPlacementSuccess
            }
        case .timelinePlacement:
            if wasSuccessful {
                awardedMastery = support == .independent ? .placed : .understood
                evidenceType = .timelinePlacementSuccess
            }
        case .review:
            if wasSuccessful && support == .independent && isDistinctReview(record, sessionID: sessionID, at: date) {
                awardedMastery = subjectType == .scene ? .remembered : max(record.state, .remembered)
                evidenceType = .reviewSuccess
            } else if support == .selfReported {
                evidenceType = .selfReportedReview
            } else if wasSuccessful {
                awardedMastery = .understood
                evidenceType = .recallSuccess
            }
        case .albumPlacement:
            evidenceType = .chronicleReflection
        }

        record.state = max(record.state, awardedMastery)
        if wasSuccessful && activity != .storyExposure && activity != .albumPlacement && support != .selfReported {
            record.successfulReviewCount += 1
            record.lastReviewedAt = date
        }
        record.evidenceLog.append(MasteryEvidence(type: evidenceType, recordedAt: date, detail: detail,
                                                  eventID: eventID, activity: activity, support: support,
                                                  sessionID: sessionID, promptType: promptType))
        masteryRecordsBySubject[subjectID] = record
        rememberEventID(eventID)
        if activity != .storyExposure && activity != .albumPlacement {
            let response: LearningReviewResponse = !wasSuccessful || support == .rescued ? .teachAgain : (support == .hinted ? .neededClue : .knewIt)
            _ = scheduleReview(subjectID: subjectID, subjectType: subjectType, response: response, promptType: promptType,
                               eventID: eventID, sessionID: sessionID, at: date)
        }
        persist()
        return true
    }

    func reviewSchedule(for subjectID: String) -> ReviewSchedule? {
        reviewSchedulesBySubject[subjectID]
    }

    @discardableResult
    func recordReviewResponse(
        subjectID: String,
        subjectType: MasterySubjectType = .scene,
        response: LearningReviewResponse,
        promptType: RecallPromptType = .openPrompt,
        eventID: UUID = UUID(),
        sessionID: UUID? = nil,
        at date: Date = Date()
    ) -> LearningReviewSchedulingResult? {
        guard isKnownSubject(subjectID, type: subjectType), !hasRecorded(eventID: eventID) else { return nil }
        var record = masteryRecordsBySubject[subjectID] ?? emptyRecord(subjectID, type: subjectType)
        record.evidenceLog.append(MasteryEvidence(type: .selfReportedReview, recordedAt: date,
            detail: "Self-reported review: \(response.rawValue)", eventID: eventID, activity: .review,
            support: .selfReported, sessionID: sessionID, promptType: promptType, reviewResponse: response))
        masteryRecordsBySubject[subjectID] = record
        rememberEventID(eventID)
        let result = scheduleReview(subjectID: subjectID, subjectType: subjectType, response: response, promptType: promptType,
                                    eventID: eventID, sessionID: sessionID, at: date)
        persist()
        return result
    }

    func saveResumePoint(_ point: LessonResumePoint) {
        guard isKnownSubject(point.sceneID, type: .scene) else { return }
        resumePointsByScene[point.sceneID] = point
        persist()
    }

    func resumePoint(for sceneID: String) -> LessonResumePoint? { resumePointsByScene[sceneID] }

    var latestResumePoint: LessonResumePoint? {
        resumePointsByScene.values.max { $0.updatedAt == $1.updatedAt ? $0.sceneID < $1.sceneID : $0.updatedAt < $1.updatedAt }
    }

    func clearResumePoint(for sceneID: String) {
        resumePointsByScene.removeValue(forKey: sceneID)
        persist()
    }

    func chronicleProgress(for entry: ChronicleEntry) -> ChronicleRewardProgress {
        guard let record = masteryRecord(for: entry.linkedSceneID) else { return ChronicleProgressEngine.initialProgress(for: entry) }
        var events: [ChronicleProgressEvent] = record.exposureCount > 0 ? [.lessonSeen] : []
        if record.evidenceLog.contains(where: { $0.type == .recallSuccess || $0.type == .reviewSuccess }) {
            events.append(.recallCorrect)
            if record.evidenceLog.contains(where: { $0.type == .matchSuccess }) { events.append(.matchCompleted) }
            if record.evidenceLog.contains(where: { $0.type == .reviewSuccess && $0.activity == .review && $0.support == .independent }) {
                events.append(.reviewCorrect)
            }
        } else if record.state >= .understood && record.evidenceLog.isEmpty {
            // Imported pre-evidence mastery still retains its earned album.
            events.append(.recallCorrect)
        }
        return ChronicleProgressEngine.progress(for: entry, evidence: events, at: record.evidenceLog.last?.recordedAt ?? Date())
    }

    func resetScene(_ sceneID: String) {
        masteryRecordsBySubject.removeValue(forKey: sceneID)
        resumePointsByScene.removeValue(forKey: sceneID)
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

    func isPreviewed(_ reward: ChronicleReward) -> Bool {
        guard let entry = content.activeHeroArc.chronicleEntries.first(where: { $0.id == reward.id }) else {
            return masteryRecord(for: reward.unlockedBySceneID) != nil
        }
        return isPreviewedChronicleEntry(entry)
    }

    func isUnlocked(_ reward: ChronicleReward) -> Bool {
        guard let entry = content.activeHeroArc.chronicleEntries.first(where: { $0.id == reward.id }) else {
            guard let mastery = mastery(for: reward.unlockedBySceneID) else { return false }
            return mastery >= max(reward.mastery, .understood)
        }
        switch chronicleUnlockState(for: entry) {
        case .silhouette:
            return false
        case .unlocked, .enriched:
            return true
        }
    }

    func unlockedRewards(from rewards: [ChronicleReward]) -> [ChronicleReward] {
        rewards.filter { isUnlocked($0) }
    }

    func previewedRewards(from rewards: [ChronicleReward]) -> [ChronicleReward] {
        rewards.filter { isPreviewed($0) && !isUnlocked($0) }
    }

    func enrichedRewards(from rewards: [ChronicleReward]) -> [ChronicleReward] {
        rewards.filter { reward in
            guard let entry = content.activeHeroArc.chronicleEntries.first(where: { $0.id == reward.id }) else {
                return false
            }
            return chronicleUnlockState(for: entry) == .enriched
        }
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
        guard let sceneMastery = mastery(for: entry.linkedSceneID) else {
            return .silhouette
        }

        let hasRecall = masteryRecord(for: entry.linkedSceneID).map { record in
            record.evidenceLog.isEmpty || record.evidenceLog.contains { $0.type == .recallSuccess || $0.type == .reviewSuccess }
        } ?? false
        let unlockMastery = max(entry.unlockRule.requiredMastery, .understood)
        guard hasRecall, sceneMastery >= unlockMastery else {
            return .silhouette
        }

        if let enhanced = entry.unlockRule.enhancedMastery, sceneMastery >= max(enhanced, unlockMastery) {
            return .enriched
        }

        return .unlocked
    }

    func isPreviewedChronicleEntry(_ entry: ChronicleEntry) -> Bool {
        guard let record = masteryRecord(for: entry.linkedSceneID) else {
            return false
        }
        return record.exposureCount > 0 || !record.evidenceLog.isEmpty
    }

    func locationUnlockState(for node: LocationNode) -> LocationUnlockState {
        // Scene recall makes geography available; only a place action establishes place memory.
        if let record = masteryRecord(for: node.id) {
            if record.state >= .placed { return .placedAccurately }
            if record.state >= .understood { return .remembered }
        }
        let linkedSceneMasteries = node.linkedSceneIDs.compactMap { mastery(for: $0) }
        if (linkedSceneMasteries.max() ?? .witnessed) >= .understood { return .learnable }
        let hasUnlockedLinkedScene = node.linkedSceneIDs.contains { sceneID in
            content.scenes.first(where: { $0.id == sceneID }).map(isSceneUnlocked) ?? false
        }
        return hasUnlockedLinkedScene ? .learnable : .hidden
    }

    func timelineUnlockState(for event: TimelineEvent) -> LocationUnlockState {
        let linkedSceneMasteries = content.activeHeroArc.scenes
            .filter { $0.timelineEventID == event.id }
            .compactMap { mastery(for: $0.id) }
        let strongestMastery = linkedSceneMasteries.max() ?? .witnessed

        if strongestMastery < event.unlockRule.requiredMastery {
            return .hidden
        }
        if let record = masteryRecord(for: event.id), record.state >= .placed {
            return .placedAccurately
        }
        return .remembered
    }

    func dueReviews(referenceDate: Date = Date()) -> [ReviewSchedule] {
        SpacedReviewScheduler.dueReviews(from: reviewSchedulesBySubject.values.filter { isLearnedSubject($0.subjectID) }, now: referenceDate)
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


    var totalTimelineEvents: Int {
        content.activeHeroArc.timelineEvents.count
    }

    var unlockedTimelineCount: Int {
        content.activeHeroArc.timelineEvents.filter { timelineUnlockState(for: $0) != .hidden }.count
    }

    var masteredTimelineCount: Int {
        content.activeHeroArc.timelineEvents.filter { timelineUnlockState(for: $0) == .placedAccurately }.count
    }

    var dueReviewCount: Int {
        dueReviews().count
    }

    func upcomingReviews(limit: Int = 3, referenceDate: Date = Date()) -> [ReviewSchedule] {
        reviewSchedulesBySubject.values
            .filter { isLearnedSubject($0.subjectID) && $0.nextDueAt > referenceDate }
            .sorted { lhs, rhs in lhs.nextDueAt == rhs.nextDueAt ? lhs.subjectID < rhs.subjectID : lhs.nextDueAt < rhs.nextDueAt }
            .prefix(max(limit, 0))
            .map { $0 }
    }

    var timelineHeadline: String {
        switch (unlockedTimelineCount, masteredTimelineCount, dueReviewCount) {
        case (0, _, _):
            return "Unlock the first moment in order"
        case let (unlocked, mastered, _) where unlocked == totalTimelineEvents && mastered == totalTimelineEvents:
            return "The whole hero journey now holds together"
        case let (_, mastered, _) where mastered > 0:
            return "Your timeline confidence is growing"
        case let (_, _, due) where due > 0:
            return "A quick review run is ready"
        default:
            return "Order is starting to stick"
        }
    }

    var totalCorePlaces: Int {
        content.corePlaces.count
    }

    var readyOrBetterPlaceCount: Int {
        content.corePlaces.filter { progress(for: $0) != .locked }.count
    }

    var masteredPlaceCount: Int {
        content.corePlaces.filter { progress(for: $0) == .masteredLightly }.count
    }

    var parentProgressHeadline: String {
        switch (completedScenes, unlockedChronicleCount, masteredPlaceCount, dueReviewCount) {
        case (0, 0, 0, 0):
            return "The learning journey is ready to begin"
        case let (scenes, chronicle, places, _) where scenes == totalScenes && chronicle == totalChronicleEntries && places == totalCorePlaces:
            return "All chapters completed, with each core place found"
        case let (_, _, _, due) where due > 0:
            return "A short revisit is ready to strengthen memory"
        case let (_, chronicle, _, _) where chronicle > 0:
            return "A keepsake was earned through a recall activity"
        default:
            return "Some story or practice activities have been started"
        }
    }

    var retrievalExplanation: String {
        if dueReviewCount > 0 {
            return "A previously started subject is due for another short practice activity."
        }
        if unlockedChronicleCount > 0 {
            return "Keepsakes were earned by correct answers. The evidence records whether clues were used."
        }
        return "Lessons offer gentle recall with clues and another try. Progress records the activities completed."
    }

    var totalChronicleEntries: Int {
        content.activeHeroArc.chronicleEntries.count
    }

    var previewedChronicleCount: Int {
        content.activeHeroArc.chronicleEntries.filter(isPreviewedChronicleEntry).count
    }

    var unlockedChronicleCount: Int {
        content.activeHeroArc.chronicleEntries.filter { chronicleUnlockState(for: $0) != .silhouette }.count
    }

    var enrichedChronicleCount: Int {
        content.activeHeroArc.chronicleEntries.filter { chronicleUnlockState(for: $0) == .enriched }.count
    }

    var chronicleHeadline: String {
        let previewedCount = previewedChronicleCount
        let unlockedCount = unlockedChronicleCount
        let enrichedCount = enrichedChronicleCount

        switch (previewedCount, unlockedCount, enrichedCount) {
        case (0, 0, 0):
            return "Begin the Chronicle"
        case (_, 0, _):
            return "Your first keepsake is taking shape"
        case let (_, unlocked, enriched) where unlocked == totalChronicleEntries && enriched == totalChronicleEntries:
            return "Your Chronicle shelf glows with meaning"
        case let (_, unlocked, _) where unlocked == totalChronicleEntries:
            return "The first Chronicle page is complete"
        case let (_, _, enriched) where enriched > 0:
            return "Your Chronicle is deepening"
        default:
            return "Your Chronicle is taking shape"
        }
    }

    var nextSceneID: String? {
        content.scenes.first(where: { (mastery(for: $0.id) ?? .witnessed) < .understood })?.id
    }

    func applyCaptureSeed(_ profile: CaptureSeedProfile) {
#if DEBUG
        guard defaults !== UserDefaults.standard else { return }
        resumePointsByScene = [:]
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
#endif
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
        _ = scheduleReview(subjectID: subjectID, subjectType: subjectType, response: success ? .knewIt : .teachAgain,
                           promptType: .openPrompt, at: referenceDate)
    }

    private func scheduleReview(subjectID: String, subjectType: MasterySubjectType, response: LearningReviewResponse,
                                promptType: RecallPromptType, eventID: UUID? = nil, sessionID: UUID? = nil,
                                at date: Date) -> LearningReviewSchedulingResult? {
        ensureReviewBlueprint(for: subjectID, subjectType: subjectType)
        guard let schedule = reviewSchedulesBySubject[subjectID] else { return nil }
        let history = masteryRecordsBySubject[subjectID]?.evidenceLog.compactMap(\.promptType) ?? [promptType]
        // Several cards/activity modes can teach one subject in a single sitting. They cannot
        // simulate several spaced revisits by advancing the interval repeatedly.
        if response == .knewIt, let sessionID {
            let alreadyPracticed = masteryRecordsBySubject[subjectID]?.evidenceLog.contains { evidence in
                guard evidence.sessionID == sessionID, evidence.eventID != eventID,
                      evidence.support != .rescued else { return false }
                switch evidence.type {
                case .recallSuccess, .reviewSuccess, .matchSuccess, .mapPlacementSuccess, .timelinePlacementSuccess:
                    return true
                case .selfReportedReview:
                    return evidence.reviewResponse == .knewIt || evidence.reviewResponse == .neededClue
                default: return false
                }
            } ?? false
            if alreadyPracticed {
                return LearningReviewSchedulingResult(schedule: schedule,
                    nextPromptType: SpacedReviewScheduler.nextPromptType(after: history), shouldReviewInCurrentSession: false)
            }
        }
        let result = SpacedReviewScheduler.schedule(schedule, after: response, promptHistory: history, now: date)
        reviewSchedulesBySubject[subjectID] = result.schedule
        return result
    }

    private func hasRecorded(eventID: UUID) -> Bool {
        if recentEventIDs.contains(eventID) { return true }
        if resumePointsByScene.values.contains(where: { point in
            guard let checkpoint = point.tvCheckpoint else { return false }
            return checkpoint.completedActivityIDs.contains { checkpoint.completionEventIDs[$0] == eventID }
        }) { return true }
        return masteryRecordsBySubject.values.contains { $0.evidenceLog.contains { $0.eventID == eventID } }
    }

    private func rememberEventID(_ eventID: UUID) {
        guard persistencePolicy.maximumDefaultsBytes != nil else { return }
        recentEventIDs.removeAll { $0 == eventID }
        recentEventIDs.append(eventID)
        recentEventIDs = Array(recentEventIDs.suffix(persistencePolicy.recentEventLimit))
    }

    private func isLearnedSubject(_ subjectID: String) -> Bool {
        guard let record = masteryRecordsBySubject[subjectID] else { return false }
        return record.exposureCount > 0 || !record.evidenceLog.isEmpty || record.state >= .understood
    }

    private func isKnownSubject(_ id: String, type: MasterySubjectType) -> Bool {
        switch type {
        case .scene: return content.scenes.contains { $0.id == id }
        case .location: return content.activeHeroArc.locationNodes.contains { $0.id == id }
        case .timeline: return content.activeHeroArc.timelineEvents.contains { $0.id == id }
        case .chronicle: return content.activeHeroArc.chronicleEntries.contains { $0.id == id }
        }
    }

    private func emptyRecord(_ subjectID: String, type: MasterySubjectType) -> MasteryRecord {
        MasteryRecord(subjectID: subjectID, subjectType: type, state: .witnessed, exposureCount: 0,
                      successfulReviewCount: 0, lastReviewedAt: nil, evidenceLog: [])
    }

    private func isDistinctReview(_ record: MasteryRecord, sessionID: UUID?, at date: Date) -> Bool {
        guard let previous = record.evidenceLog.last(where: {
            $0.type == .recallSuccess || $0.type == .reviewSuccess
                || (record.subjectType != .scene && ($0.type == .mapPlacementSuccess || $0.type == .timelinePlacementSuccess))
        }),
              date > previous.recordedAt else { return false }
        if let sessionID, let previousSession = previous.sessionID { return sessionID != previousSession }
        // Legacy callbacks without session IDs require a later calendar day to establish a revisit.
        return !Calendar.current.isDate(date, inSameDayAs: previous.recordedAt)
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

    private func syncLegacySceneMastery() {
        masteryByScene = masteryRecordsBySubject.reduce(into: [:]) { partialResult, pair in
            guard pair.value.subjectType == .scene else { return }
            partialResult[pair.key] = pair.value.state
        }
    }

    private func persist() {
        syncLegacySceneMastery()
        if let limit = persistencePolicy.maximumDefaultsBytes {
            persistCompactSnapshot(limit: limit)
            return
        }
        defaults.set(masteryByScene.mapValues { $0.rawValue }, forKey: legacyMasteryStorageKey)
        let encoder = JSONEncoder()
        let snapshot = LessonStoreSnapshot(schemaVersion: 1, records: masteryRecordsBySubject,
                                           schedules: reviewSchedulesBySubject, resumePoints: resumePointsByScene)
        if let data = try? encoder.encode(snapshot) { defaults.set(data, forKey: snapshotStorageKey) }
        if let recordsData = try? encoder.encode(masteryRecordsBySubject) {
            defaults.set(recordsData, forKey: recordsStorageKey)
        }
        if let scheduleData = try? encoder.encode(reviewSchedulesBySubject) {
            defaults.set(scheduleData, forKey: reviewStorageKey)
        }
        updatePersistenceDiagnostics()
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


// TV-only storage compaction is separate from the learning outcome boundary.
extension ShivajiLessonStore {
    private func persistCompactSnapshot(limit: Int) {
        let encoder = JSONEncoder()
        var records = masteryRecordsBySubject
        for (id, var record) in records {
            record.evidenceLog = compactEvidence(record.evidenceLog, recentLimit: persistencePolicy.recentEvidenceLimit)
            records[id] = record
        }
        var points = resumePointsByScene.mapValues { boundedResumePoint($0, collectionLimit: 32) }
        var snapshot = LessonStoreSnapshot(schemaVersion: 2, records: records,
            schedules: reviewSchedulesBySubject, resumePoints: points, recentEventIDs: recentEventIDs)
        guard var data = try? encoder.encode(snapshot) else { return }

        // Count the resulting full defaults domain before writing, including parent settings and recovery.
        var prospective = appOwnedDefaults()
        prospective.removeValue(forKey: recordsStorageKey)
        prospective.removeValue(forKey: reviewStorageKey)
        prospective.removeValue(forKey: legacyMasteryStorageKey)
        let recoveryKey = snapshotStorageKey + ".recovery"
        if let pendingRecoveryData { prospective[recoveryKey] = pendingRecoveryData }
        if let recovery = prospective[recoveryKey] as? Data, recovery.count > persistencePolicy.recoveryLimitBytes {
            prospective[recoveryKey] = Data(recovery.prefix(persistencePolicy.recoveryLimitBytes))
        }
        prospective[snapshotStorageKey] = data
        // Keep small room for the fixed parent settings record, including a future toggle.
        let writeBudget = max(limit - 1024, 0)
        if Self.defaultsByteCount(prospective) > writeBudget {
            for (id, var record) in records {
                record.evidenceLog = compactEvidence(record.evidenceLog, recentLimit: 0)
                records[id] = record
            }
            points = points.mapValues { boundedResumePoint($0, collectionLimit: 16) }
            snapshot = LessonStoreSnapshot(schemaVersion: 2, records: records,
                schedules: reviewSchedulesBySubject, resumePoints: points, recentEventIDs: recentEventIDs)
            guard let smallerData = try? encoder.encode(snapshot) else { return }
            data = smallerData
            prospective[snapshotStorageKey] = data
        }
        if Self.defaultsByteCount(prospective) > writeBudget {
            prospective.removeValue(forKey: recoveryKey)
        }
        guard Self.defaultsByteCount(prospective) <= writeBudget else {
            updatePersistenceDiagnostics(status: "The saved journey is safe. This activity could not be saved within the TV storage limit.")
            return
        }

        // No legacy copies are written on TV. Publish precisely the compact facts that were saved.
        masteryRecordsBySubject = records
        resumePointsByScene = points
        defaults.removeObject(forKey: recordsStorageKey)
        defaults.removeObject(forKey: reviewStorageKey)
        defaults.removeObject(forKey: legacyMasteryStorageKey)
        if let recovery = prospective[recoveryKey] as? Data {
            defaults.set(recovery, forKey: recoveryKey)
        } else {
            defaults.removeObject(forKey: recoveryKey)
        }
        defaults.set(data, forKey: snapshotStorageKey)
        pendingRecoveryData = nil
        // Recovery is a small semantic backup rather than another full history. It is never truncated mid-encoding.
        if let recovery = recoveryData(for: snapshot), recovery.count <= persistencePolicy.recoveryLimitBytes {
            prospective[recoveryKey] = recovery
            if Self.defaultsByteCount(prospective) <= writeBudget { defaults.set(recovery, forKey: recoveryKey) }
        }
        updatePersistenceDiagnostics()
    }

    private func compactEvidence(_ evidence: [MasteryEvidence], recentLimit: Int) -> [MasteryEvidence] {
        var indices = Set(evidence.indices.suffix(max(recentLimit, 0)))
        // These witnesses drive earned album state, placement, and independent later review.
        for type in MasteryEvidenceType.allCases {
            if let index = evidence.lastIndex(where: { $0.type == type }) { indices.insert(index) }
        }
        if let index = evidence.lastIndex(where: {
            $0.type == .reviewSuccess && $0.activity == .review && $0.support == .independent
        }) { indices.insert(index) }
        // A later assisted answer must not erase the witness that established independent recall or placement.
        for type in [MasteryEvidenceType.recallSuccess, .matchSuccess, .mapPlacementSuccess, .timelinePlacementSuccess] {
            if let index = evidence.lastIndex(where: { $0.type == type && $0.support == .independent }) {
                indices.insert(index)
            }
        }
        // Distinct-review checks must still see the latest qualifying recall/placement and its session.
        if let index = evidence.lastIndex(where: {
            $0.type == .recallSuccess || $0.type == .reviewSuccess
                || $0.type == .mapPlacementSuccess || $0.type == .timelinePlacementSuccess
        }) { indices.insert(index) }
        return indices.sorted().map { index in
            let item = evidence[index]
            return MasteryEvidence(type: item.type, recordedAt: item.recordedAt,
                detail: String(item.detail.prefix(persistencePolicy.evidenceDetailLimit)), eventID: item.eventID,
                activity: item.activity, support: item.support, sessionID: item.sessionID,
                promptType: item.promptType, reviewResponse: item.reviewResponse)
        }
    }

    private func boundedResumePoint(_ original: LessonResumePoint, collectionLimit: Int) -> LessonResumePoint {
        var point = original
        func bounded(_ values: Set<String>) -> Set<String> {
            Set(values.sorted().prefix(collectionLimit).map { String($0.prefix(160)) })
        }
        point.completedMatchPairIDs = bounded(point.completedMatchPairIDs)
        point.discoveredDetailIDs = bounded(point.discoveredDetailIDs)
        point.solvedPlaceIDs = bounded(point.solvedPlaceIDs)
        point.helpedPlaceIDs = bounded(point.helpedPlaceIDs)
        if var checkpoint = point.tvCheckpoint {
            checkpoint.storyBeatIndex = max(checkpoint.storyBeatIndex, 0)
            checkpoint.discoveredDetailIDs = bounded(checkpoint.discoveredDetailIDs)
            checkpoint.solvedPlaceIDs = bounded(checkpoint.solvedPlaceIDs)
            checkpoint.helpedActivityIDs = bounded(checkpoint.helpedActivityIDs)
            checkpoint.matchedPairIDs = bounded(checkpoint.matchedPairIDs)
            checkpoint.completedActivityIDs = bounded(checkpoint.completedActivityIDs)
            checkpoint.hintLevels = Dictionary(uniqueKeysWithValues: checkpoint.hintLevels.keys.sorted()
                .prefix(collectionLimit).map { ($0, min(max(checkpoint.hintLevels[$0] ?? 0, 0), 3)) })
            checkpoint.sequenceSlots = Array(checkpoint.sequenceSlots.prefix(16)).map { $0.map { String($0.prefix(160)) } }
            // Completed IDs outrank allocated IDs so replays cannot re-award compacted evidence.
            let eventKeys = checkpoint.completionEventIDs.keys.sorted {
                let left = checkpoint.completedActivityIDs.contains($0)
                let right = checkpoint.completedActivityIDs.contains($1)
                return left == right ? $0 < $1 : left
            }
            checkpoint.completionEventIDs = Dictionary(uniqueKeysWithValues: eventKeys.prefix(collectionLimit)
                .compactMap { key in checkpoint.completionEventIDs[key].map { (key, $0) } })
            checkpoint.selectedTileID = checkpoint.selectedTileID.map { String($0.prefix(160)) }
            if var timeline = checkpoint.timelineCheckpoint {
                timeline.mode = timeline.mode == "full" ? "full" : "opening"
                timeline.roundIndex = min(max(timeline.roundIndex, 0), 6)
                timeline.slots = Array(timeline.slots.prefix(3)).map { $0.map { String($0.prefix(160)) } }
                timeline.selectedCardID = timeline.selectedCardID.map { String($0.prefix(160)) }
                timeline.hintLevel = min(max(timeline.hintLevel, 0), 3)
                timeline.helpedRoundIndices = Set(timeline.helpedRoundIndices.filter { (0...6).contains($0) })
                timeline.completedRoundIndices = Set(timeline.completedRoundIndices.filter { (0...6).contains($0) })
                checkpoint.timelineCheckpoint = timeline
            }
            point.tvCheckpoint = checkpoint
        }
        return point
    }

    private func recoveryData(for snapshot: LessonStoreSnapshot) -> Data? {
        var records = snapshot.records
        for (id, var record) in records {
            record.evidenceLog = compactEvidence(record.evidenceLog, recentLimit: 0).map { item in
                MasteryEvidence(type: item.type, recordedAt: item.recordedAt, detail: "", activity: item.activity,
                    support: item.support, sessionID: item.sessionID, promptType: item.promptType,
                    reviewResponse: item.reviewResponse)
            }
            records[id] = record
        }
        let recovery = LessonStoreSnapshot(schemaVersion: 2, records: records, schedules: snapshot.schedules,
            resumePoints: snapshot.resumePoints, recentEventIDs: Array(snapshot.recentEventIDs.suffix(32)))
        let encoder = PropertyListEncoder()
        encoder.outputFormat = .binary
        guard let raw = try? encoder.encode(recovery) else { return nil }
        return LessonRecoveryCodec.encode(raw)
    }

    private func appOwnedDefaults() -> [String: Any] {
        defaults.dictionaryRepresentation().filter { key, _ in
            key.hasPrefix("shivajiLessonStore.") || key.hasPrefix("greatsOfBharatha.")
        }
    }

    private static func defaultsByteCount(_ values: [String: Any]) -> Int {
        (try? PropertyListSerialization.data(fromPropertyList: values, format: .binary, options: 0).count) ?? Int.max
    }

    private func updatePersistenceDiagnostics(status: String? = nil) {
        persistenceDiagnostics = LessonPersistenceDiagnostics(
            snapshotBytes: defaults.data(forKey: snapshotStorageKey)?.count ?? 0,
            appOwnedDefaultsBytes: Self.defaultsByteCount(appOwnedDefaults()),
            limitBytes: persistencePolicy.maximumDefaultsBytes, statusMessage: status)
    }

    private static func decodeSnapshot(_ data: Data) -> LessonStoreSnapshot? {
        if LessonRecoveryCodec.isEncodedRecovery(data) {
            guard let decoded = LessonRecoveryCodec.decode(data) else { return nil }
            return try? PropertyListDecoder().decode(LessonStoreSnapshot.self, from: decoded)
        }
        return (try? JSONDecoder().decode(LessonStoreSnapshot.self, from: data))
            ?? (try? PropertyListDecoder().decode(LessonStoreSnapshot.self, from: data))
    }
}

/// The recovery cap includes all current chapter checkpoints. Repeated keys compress;
/// UUIDs and authored evidence remain intact rather than dropping the latest saved chapter.
private enum LessonRecoveryCodec {
    private static let magic = Data("GBR2".utf8)
    private static let maximumDecodedBytes = 256 * 1024
    private static let maximumEncodedBytes = 16 * 1024
    private static let headerBytes = 8

    static func isEncodedRecovery(_ data: Data) -> Bool { data.starts(with: magic) }

    static func encode(_ raw: Data) -> Data? {
        guard !raw.isEmpty, raw.count <= maximumDecodedBytes,
              let compressed = try? (raw as NSData).compressed(using: .lzfse) as Data else { return nil }
        var encoded = magic
        var count = UInt32(raw.count).bigEndian
        withUnsafeBytes(of: &count) { encoded.append(contentsOf: $0) }
        encoded.append(compressed)
        return encoded.count <= maximumEncodedBytes ? encoded : nil
    }

    static func decode(_ encoded: Data) -> Data? {
        guard encoded.count > headerBytes, encoded.count <= maximumEncodedBytes,
              isEncodedRecovery(encoded) else { return nil }
        let expectedCount = encoded.dropFirst(magic.count).prefix(4).reduce(0) { ($0 << 8) | Int($1) }
        guard expectedCount > 0, expectedCount <= maximumDecodedBytes else { return nil }
        let payload = Data(encoded.dropFirst(headerBytes))
        // One extra byte detects output larger than its declared size without an unbounded allocation.
        var decoded = Data(count: expectedCount + 1)
        let written = decoded.withUnsafeMutableBytes { output in
            payload.withUnsafeBytes { input in
                guard let destination = output.bindMemory(to: UInt8.self).baseAddress,
                      let source = input.bindMemory(to: UInt8.self).baseAddress else { return 0 }
                return compression_decode_buffer(destination, expectedCount + 1, source, payload.count, nil, COMPRESSION_LZFSE)
            }
        }
        guard written == expectedCount else { return nil }
        decoded.removeLast()
        return decoded
    }
}


private struct LessonStoreSnapshot: Codable {
    let schemaVersion: Int
    let records: [String: MasteryRecord]
    let schedules: [String: ReviewSchedule]
    let resumePoints: [String: LessonResumePoint]
    var recentEventIDs: [UUID] = []

    private enum CodingKeys: String, CodingKey {
        case schemaVersion, records, schedules, resumePoints, recentEventIDs
    }

    init(schemaVersion: Int, records: [String: MasteryRecord], schedules: [String: ReviewSchedule],
         resumePoints: [String: LessonResumePoint], recentEventIDs: [UUID] = []) {
        self.schemaVersion = schemaVersion
        self.records = records
        self.schedules = schedules
        self.resumePoints = resumePoints
        self.recentEventIDs = recentEventIDs
    }

    init(from decoder: Decoder) throws {
        let values = try decoder.container(keyedBy: CodingKeys.self)
        schemaVersion = try values.decode(Int.self, forKey: .schemaVersion)
        records = try values.decode([String: MasteryRecord].self, forKey: .records)
        schedules = try values.decode([String: ReviewSchedule].self, forKey: .schedules)
        resumePoints = try values.decodeIfPresent([String: LessonResumePoint].self, forKey: .resumePoints) ?? [:]
        recentEventIDs = try values.decodeIfPresent([UUID].self, forKey: .recentEventIDs) ?? []
    }
}
