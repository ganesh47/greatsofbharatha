import SwiftUI
import UIKit

struct TVLessonView: View {
    let sceneID: String
    var restartOnEntry = false
    @EnvironmentObject private var appModel: AppModel
    @EnvironmentObject private var narrator: GBNarrator
    @Environment(\.dismiss) private var dismiss
    @Environment(\.scenePhase) private var scenePhase
    @State private var activeSceneID = ""
    @State private var checkpoint = TVActivityCheckpoint()
    @State private var sessionID = UUID()
    @State private var restoredSceneID: String?
    @State private var discovery: TVDiscovery?
    @State private var helpText: String?
    @State private var feedback: String?
    @State private var matchState = ChronicleMatchState()
    @State private var sequenceState = TVSequenceState(cardCount: 3)
    @State private var keepsakeSelected = false
    @FocusState private var focus: String?

    private var chapter: TVChapter? { TVLearningContent.chapter(sceneID: activeSceneID.isEmpty ? sceneID : activeSceneID) }

    var body: some View {
        ScrollView {
            if let chapter {
                VStack(alignment: .leading, spacing: isMatchingPuzzle ? 18 : 28) {
                    HStack(alignment: .firstTextBaseline) {
                        Text("Chapter \(chapter.number) · \(stageTitle)").font(.system(size: 24, weight: .semibold)).foregroundStyle(GBColor.Content.secondary)
                        Spacer()
                        Text("Choose with Select · Back puts a choice away").font(.system(size: 22)).foregroundStyle(GBColor.Content.secondary)
                    }
                    Text(chapter.title).font(.system(size: 42, weight: .bold)).foregroundStyle(GBColor.Content.primary)
                    if let discovery {
                        discoveryDetail(discovery)
                    } else if let helpText {
                        TVFireflyGuide(message: helpText)
                        TVNarrationControls(id: chapter.id + "-help", text: helpText)
                        Button("Back to the adventure") { self.helpText = nil; restoreFocus() }
                            .buttonStyle(TVCardButtonStyle()).accessibilityIdentifier("tv-help-close")
                    } else {
                        stageContent(chapter)
                    }
                }
                .padding(.horizontal, 86).padding(.vertical, 45)
                .frame(maxWidth: 1740).frame(maxWidth: .infinity)
            } else {
                Text("This chapter is unavailable. Return to the adventure map.").font(.system(size: 32))
            }
        }
        .background(TVTheme.background)
        .foregroundStyle(TVTheme.paper)
        .onAppear {
            if restartOnEntry, restoredSceneID == nil, let chapter { restartChapter(chapter) } else { loadChapter() }
        }
        .onChange(of: activeSceneID) { _, _ in loadChapter() }
        .onChange(of: scenePhase) { _, phase in if phase != .active { saveCheckpoint(); narrator.stop() } }
        .onDisappear { saveCheckpoint(); narrator.stop() }
        .onPlayPauseCommand(perform: playPause)
        .onExitCommand(perform: handleBack)
        .navigationTitle("Learning adventure")
    }

    private var stageTitle: String {
        switch checkpoint.stage {
        case .story: "Story"
        case .discover: "Discover"
        case .place: "Fort detective"
        case .recall: "Try your memory"
        case .puzzle: "Little puzzle"
        case .keepsake: "Keepsake album"
        }
    }

    private var isMatchingPuzzle: Bool {
        guard checkpoint.stage == .puzzle, let chapter else { return false }
        if case .match = chapter.puzzle { return true }
        return false
    }

    @ViewBuilder private func stageContent(_ chapter: TVChapter) -> some View {
        switch checkpoint.stage {
        case .story: story(chapter)
        case .discover: discoveries(chapter)
        case .place: place(chapter)
        case .recall: recall(chapter)
        case .puzzle: puzzle(chapter)
        case .keepsake: keepsake(chapter)
        }
    }

    private func story(_ chapter: TVChapter) -> some View {
        let index = min(max(checkpoint.storyBeatIndex, 0), chapter.storyBeats.count - 1)
        let beat = chapter.storyBeats[index]
        return VStack(alignment: .leading, spacing: 28) {
            HStack(alignment: .top, spacing: 40) {
                chapterArt(chapter).frame(width: 660, height: 365)
                VStack(alignment: .leading, spacing: 22) {
                    Text(beat.title).font(.system(size: 32, weight: .bold))
                    Text(beat.text).font(.system(size: 30)).fixedSize(horizontal: false, vertical: true)
                }.frame(maxWidth: .infinity, alignment: .leading)
            }
            TVFireflyGuide(message: "I'm a make-believe firefly guide. We can listen, look, and try together. Read each little part, then choose Next.")
            HStack(spacing: 28) {
                Button(index == chapter.storyBeats.count - 1 ? "Let's discover" : "Next little part") {
                    guard checkpoint.stage == .story, checkpoint.storyBeatIndex == index else { return }
                    complete("story-beat-\(index)", activity: .storyExposure, successful: false, detail: "TV story: " + beat.title)
                    narrator.stop()
                    if index < chapter.storyBeats.count - 1 {
                        checkpoint.storyBeatIndex += 1
                        saveCheckpoint()
                    } else { move(to: .discover) }
                }
                .buttonStyle(TVCardButtonStyle()).focused($focus, equals: "story-next")
                .accessibilityIdentifier("tv-lesson-story-next")
                TVNarrationControls(id: beat.id, text: beat.text)
                Spacer(minLength: 0)
            }
            .focusSection()
        }
    }

    private func discoveries(_ chapter: TVChapter) -> some View {
        VStack(alignment: .leading, spacing: 28) {
            TVFireflyGuide(message: "Pick something that makes you curious. You can explore any of these, or continue when you're ready.")
            HStack(alignment: .top, spacing: 26) {
                ForEach(chapter.discoveries) { detail in
                    Button {
                        discovery = detail
                        focus = "discovery-close"
                        narrator.stop()
                        complete("discovery-" + detail.id, activity: .storyExposure, successful: false, detail: detail.text)
                        checkpoint.discoveredDetailIDs.insert(detail.id)
                        saveCheckpoint()
                    } label: {
                        VStack(alignment: .leading, spacing: 18) {
                            Image(systemName: detail.symbol).font(.system(size: 46))
                            Text(detail.title).font(.system(size: 30, weight: .bold))
                            Text(checkpoint.discoveredDetailIDs.contains(detail.id) ? "Look again" : "Discover").font(.system(size: 24))
                        }.frame(maxWidth: .infinity, minHeight: 185, alignment: .leading)
                    }
                    .buttonStyle(TVCardButtonStyle()).focused($focus, equals: detail.id)
                    .accessibilityIdentifier("tv-discovery-" + detail.id)
                }
            }
            Button("Become a fort detective") { move(to: .place) }
                .buttonStyle(TVCardButtonStyle()).focused($focus, equals: "discovery-continue")
                .accessibilityIdentifier("tv-discovery-continue")
        }
    }

    private func discoveryDetail(_ detail: TVDiscovery) -> some View {
        VStack(alignment: .leading, spacing: 28) {
            Label(detail.title, systemImage: detail.symbol).font(.system(size: 42, weight: .bold))
            Text(detail.text).font(.system(size: 34)).fixedSize(horizontal: false, vertical: true)
            TVNarrationControls(id: detail.id, text: detail.text)
            Button("Back to discoveries") { discovery = nil; narrator.stop(); focus = detail.id }
                .buttonStyle(TVCardButtonStyle()).focused($focus, equals: "discovery-close")
                .accessibilityIdentifier("tv-discovery-close")
        }
    }

    @ViewBuilder private func place(_ chapter: TVChapter) -> some View {
        if let clue = chapter.placeClues.first(where: { !checkpoint.solvedPlaceIDs.contains($0.id) }) {
            VStack(alignment: .leading, spacing: 26) {
                TVFireflyGuide(message: "Here is a clue from our story. Choose the place it belongs to.")
                Text(clue.clue).font(.system(size: 34, weight: .semibold))
                TVNarrationControls(id: chapter.id + "-clue-" + clue.id, text: clue.clue)
                HStack(spacing: 28) {
                    ForEach(placeChoices(for: clue), id: \.id) { candidate in
                        Button { choosePlace(candidate.id, clue: clue) } label: {
                            Label(candidate.name, systemImage: candidate.id == "place-agra" ? "building.columns.fill" : "mountain.2.fill")
                                .font(.system(size: 31, weight: .bold)).frame(maxWidth: .infinity, minHeight: 112)
                        }
                        .buttonStyle(TVCardButtonStyle()).focused($focus, equals: candidate.id)
                        .accessibilityIdentifier("tv-fort-" + candidate.id)
                    }
                }
                if let feedback { Text(feedback).font(.system(size: 28)).accessibilityIdentifier("tv-fort-feedback") }
                Button("Give me a clue") {
                    checkpoint.helpedActivityIDs.insert("place-" + clue.id)
                    checkpoint.hintLevels["place-" + clue.id, default: 0] += 1
                    feedback = clue.hint
                    saveCheckpoint()
                }.buttonStyle(TVCardButtonStyle()).accessibilityIdentifier("tv-fort-help")
                if checkpoint.hintLevels["place-" + clue.id, default: 0] > 0 {
                    Button("Choose \(clue.answer) with help") {
                        checkpoint.hintLevels["place-" + clue.id] = 2
                        checkpoint.helpedActivityIDs.insert("place-rescued-" + clue.id)
                        choosePlace(clue.id, clue: clue)
                    }.buttonStyle(TVCardButtonStyle()).accessibilityIdentifier("tv-fort-rescue")
                }
            }
        } else {
            VStack(alignment: .leading, spacing: 26) {
                Text("Places found. \(chapter.placeClues.map(\.answer).joined(separator: " and ")) belongs in this chapter.")
                    .font(.system(size: 34, weight: .semibold)).accessibilityIdentifier("tv-fort-feedback")
                Button("Try my memory") { move(to: .recall) }
                    .buttonStyle(TVCardButtonStyle()).focused($focus, equals: "fort-continue")
                    .accessibilityIdentifier("tv-fort-continue")
            }
        }
    }

    private func recall(_ chapter: TVChapter) -> some View {
        let isDone = checkpoint.completedActivityIDs.contains("recall")
        return VStack(alignment: .leading, spacing: 26) {
            TVFireflyGuide(message: "Choose an answer, then choose Check my answer. Help is always here.")
            Text(chapter.pilot.quiz.question).font(.system(size: 34, weight: .semibold))
            TVNarrationControls(id: chapter.id + "-recall", text: chapter.pilot.quiz.question)
            HStack(spacing: 28) {
                ForEach(chapter.plan.choices) { choice in
                    Button {
                        checkpoint.selectedTileID = checkpoint.selectedTileID == choice.id ? nil : choice.id
                        saveCheckpoint()
                        if checkpoint.selectedTileID != nil { focus = "recall-check" }
                    } label: {
                        HStack {
                            if checkpoint.selectedTileID == choice.id { Image(systemName: "checkmark.circle") }
                            Text(choice.title).font(.system(size: 29, weight: .semibold))
                        }.frame(maxWidth: .infinity, minHeight: 90)
                    }
                    .buttonStyle(TVCardButtonStyle()).focused($focus, equals: choice.id).disabled(isDone)
                    .accessibilityIdentifier("tv-recall-" + choice.id)
                    .accessibilityValue(checkpoint.selectedTileID == choice.id ? "Selected" : "Available")
                }
            }
            if let feedback { Text(feedback).font(.system(size: 28)).accessibilityIdentifier("tv-recall-feedback") }
            if isDone {
                Text(chapter.pilot.quiz.challenge.feedback.success).font(.system(size: 28)).accessibilityIdentifier("tv-recall-success")
                Button("Play the little puzzle") { move(to: .puzzle) }
                    .buttonStyle(TVCardButtonStyle()).focused($focus, equals: "recall-continue")
                    .accessibilityIdentifier("tv-recall-continue")
            } else {
                HStack(spacing: 26) {
                    Button("Check my answer") { checkRecall(chapter) }
                        .buttonStyle(TVCardButtonStyle()).focused($focus, equals: "recall-check")
                        .disabled(checkpoint.selectedTileID == nil).accessibilityIdentifier("tv-recall-check")
                    Button("Help me remember") { recallHelp(chapter) }
                        .buttonStyle(TVCardButtonStyle()).accessibilityIdentifier("tv-recall-help")
                    if checkpoint.hintLevels["recall", default: 0] >= chapter.pilot.quiz.hintLadder.count {
                        Button("Choose the answer with help") {
                            checkpoint.hintLevels["recall"] = chapter.pilot.quiz.hintLadder.count + 1
                            checkpoint.helpedActivityIDs.insert("recall-rescued")
                            checkpoint.selectedTileID = chapter.plan.correctChoice?.id
                            checkRecall(chapter)
                        }.buttonStyle(TVCardButtonStyle()).accessibilityIdentifier("tv-recall-rescue")
                    }
                }
            }
        }
    }

    @ViewBuilder private func puzzle(_ chapter: TVChapter) -> some View {
        VStack(alignment: .leading, spacing: isMatchingPuzzle ? 16 : 26) {
            switch chapter.puzzle {
            case .match(let pairs):
                TVMatchPuzzle(pairs: pairs,
                              presentation: ChronicleMatchPresentation(pairs: pairs,
                                  kind: chapter.number == 1 ? .peopleAndPlaces : (chapter.number == 2 ? .fortsAndMemoryClues : nil)),
                              state: $matchState,
                              helped: checkpoint.helpedActivityIDs.contains("puzzle"),
                              hintLevel: checkpoint.hintLevels["puzzle", default: 0],
                              onChange: { updateMatch(pairs) }, onHelp: { matchHelp(pairs) }, onRescue: { matchRescue(pairs) })
            case .order(let cards):
                TVFireflyGuide(message: "Our little puzzle uses what the story taught. Choose a card and its place in the story.")
                TVSequencePuzzle(cards: cards, state: $sequenceState, onChange: { updateSequence(cards) })
            }
            if puzzleComplete(chapter) {
                Text("We made the puzzle together. Your keepsake is ready.").font(.system(size: 30, weight: .semibold))
                    .accessibilityIdentifier("tv-puzzle-success")
                Button("Place my keepsake") { move(to: .keepsake) }
                    .buttonStyle(TVCardButtonStyle()).focused($focus, equals: "puzzle-continue")
                    .accessibilityIdentifier("tv-puzzle-continue")
            }
        }
    }

    private func keepsake(_ chapter: TVChapter) -> some View {
        let placed = checkpoint.completedActivityIDs.contains("album")
        return VStack(alignment: .leading, spacing: 24) {
            HStack(alignment: .top, spacing: 40) {
                ZStack(alignment: .bottomTrailing) {
                    chapterArt(chapter)
                    if placed {
                        Label(chapter.pilot.chronicleEntry.subtitle, systemImage: chapter.plan.artSymbol)
                            .font(.system(size: 26, weight: .bold)).padding(20)
                            .background(GBColor.Chronicle.goldBg, in: RoundedRectangle(cornerRadius: 18)).padding(20)
                    }
                }.frame(width: 700, height: 380)
                VStack(alignment: .leading, spacing: 26) {
                    Text(chapter.pilot.chronicleEntry.title).font(.system(size: 34, weight: .bold))
                    Text(chapter.pilot.chronicleEntry.meaning).font(.system(size: 28))
                    if !placed {
                        Button(keepsakeSelected ? "Keepsake selected" : "Select my keepsake") {
                            keepsakeSelected.toggle()
                            focus = keepsakeSelected ? "keepsake-place" : "keepsake-select"
                        }.buttonStyle(TVCardButtonStyle()).focused($focus, equals: "keepsake-select")
                            .accessibilityIdentifier("tv-keepsake-select")
                        Button("Place it in this scene") {
                            guard keepsakeSelected else { return }
                            complete("album", subjectID: chapter.scene.rewardID, subjectType: .chronicle,
                                     activity: .albumPlacement, successful: true, support: .selfReported,
                                     detail: "Placed earned TV keepsake in its chapter scene")
                            keepsakeSelected = false
                            saveCheckpoint()
                            focus = "all-done"
                        }.buttonStyle(TVCardButtonStyle()).focused($focus, equals: "keepsake-place")
                            .disabled(!keepsakeSelected).accessibilityIdentifier("tv-keepsake-place")
                    } else {
                        Text("Your keepsake is at home in the album.").font(.system(size: 28, weight: .semibold))
                            .accessibilityIdentifier("tv-keepsake-success")
                    }
                }.frame(maxWidth: .infinity, alignment: .leading)
            }
            if placed {
                TVFireflyGuide(message: "A story to share if you want: " + chapter.familyPrompt)
                HStack(spacing: 26) {
                    Button("All done") { narrator.stop(); dismiss() }.buttonStyle(TVCardButtonStyle())
                        .focused($focus, equals: "all-done").accessibilityIdentifier("tv-all-done")
                    Button("Explore again") { restartChapter(chapter) }.buttonStyle(TVCardButtonStyle())
                        .accessibilityIdentifier("tv-explore-again")
                    if let next = TVLearningContent.chapters.first(where: { $0.number == chapter.number + 1 }) {
                        Button("Next adventure") { narrator.stop(); activeSceneID = next.id }
                            .buttonStyle(TVCardButtonStyle()).accessibilityIdentifier("tv-next-chapter")
                    } else {
                        NavigationLink("Next adventure", value: TVRoute.map)
                            .buttonStyle(TVCardButtonStyle()).accessibilityIdentifier("tv-next-chapter")
                    }
                    if chapter.number == 3 || chapter.number == 6 {
                        NavigationLink { TVTimelineView() } label: { Text("Put our story in order") }
                            .buttonStyle(TVCardButtonStyle()).accessibilityIdentifier("tv-open-timeline")
                    }
                }
            } else { TVFireflyGuide(message: "Select the keepsake, then choose its place in the scene. Every kind of successful learning earns it, including learning with help.") }
        }
    }

    private func chapterArt(_ chapter: TVChapter) -> some View {
        Image(chapter.plan.imageAsset ?? chapter.pilot.art.assetSlot).resizable().scaledToFit()
            .background(GBColor.Background.surface, in: RoundedRectangle(cornerRadius: 22))
            .clipShape(RoundedRectangle(cornerRadius: 22))
            .accessibilityLabel("Illustration for " + chapter.title)
    }

    private func placeChoices(for clue: TVPlaceClue) -> [Place] {
        let distractors = ["place-rajgad", "place-shivneri", "place-raigad", "place-purandar", "place-agra"]
            .filter { $0 != clue.id }.prefix(2)
        return ([clue.id] + distractors).compactMap { id in appModel.content.places.first(where: { $0.id == id }) }.sorted { $0.name < $1.name }
    }

    private func choosePlace(_ id: String, clue: TVPlaceClue) {
        guard !checkpoint.solvedPlaceIDs.contains(clue.id) else { return }
        let key = "place-" + clue.id
        if id == clue.id {
            let support: LearningSupport = checkpoint.helpedActivityIDs.contains("place-rescued-" + clue.id) ? .rescued : (checkpoint.helpedActivityIDs.contains(key) ? .hinted : .independent)
            complete(key, subjectID: clue.id, subjectType: .location, activity: .mapPlacement, successful: true,
                     support: support, promptType: .eventToPlaceMatch, detail: clue.clue)
            checkpoint.solvedPlaceIDs.insert(clue.id)
            feedback = "Yes. " + clue.hint
            saveCheckpoint()
            restoreFocus()
        } else {
            checkpoint.helpedActivityIDs.insert(key)
            checkpoint.hintLevels[key, default: 0] += 1
            feedback = "Let's try another place. " + clue.hint
            appModel.lessonStore.recordLearningOutcome(subjectID: clue.id, subjectType: .location, activity: .mapPlacement,
                                                       wasSuccessful: false, support: .hinted, promptType: .eventToPlaceMatch,
                                                       detail: "TV place retry", sessionID: sessionID)
            saveCheckpoint()
        }
    }

    private func checkRecall(_ chapter: TVChapter) {
        guard !checkpoint.completedActivityIDs.contains("recall"),
              let choice = chapter.plan.choices.first(where: { $0.id == checkpoint.selectedTileID }) else { return }
        let level = checkpoint.hintLevels["recall", default: 0]
        let quiz = ChronicleQuizState(revealedHintCount: level,
                                      recognitionRescueUnlocked: checkpoint.helpedActivityIDs.contains("recall-rescued") || level > chapter.pilot.quiz.hintLadder.count)
        let result = ChronicleQuizEngine.evaluate(state: quiz, challenge: chapter.pilot.quiz.challenge, selectedAnswer: choice.title)
        let support: LearningSupport = result.nextState.recognitionRescueUnlocked ? .rescued : (level > 0 || checkpoint.helpedActivityIDs.contains("recall") ? .hinted : .independent)
        feedback = result.feedback
        if result.isCorrect {
            let prior = TVLearningContent.hasCheckedLearning(chapter, store: appModel.lessonStore)
            complete("recall", activity: prior ? .review : .recall, successful: true, support: support,
                     promptType: .openPrompt, detail: "Checked TV recognition")
            focus = "recall-continue"
        } else {
            checkpoint.helpedActivityIDs.insert("recall")
            if result.nextState.recognitionRescueUnlocked { checkpoint.helpedActivityIDs.insert("recall-rescued") }
            checkpoint.hintLevels["recall"] = result.nextState.revealedHintCount
            appModel.lessonStore.recordLearningOutcome(subjectID: chapter.id, activity: .recall, wasSuccessful: false,
                                                       support: support, detail: "TV recognition retry", sessionID: sessionID)
            checkpoint.selectedTileID = nil
            restoreFocus()
        }
        saveCheckpoint()
    }

    private func recallHelp(_ chapter: TVChapter) {
        checkpoint.helpedActivityIDs.insert("recall")
        let level = checkpoint.hintLevels["recall", default: 0]
        checkpoint.hintLevels["recall"] = min(level + 1, chapter.pilot.quiz.hintLadder.count + 1)
        feedback = chapter.pilot.quiz.hintLadder[min(level, chapter.pilot.quiz.hintLadder.count - 1)]
        saveCheckpoint()
    }

    private func updateMatch(_ pairs: [ChronicleMatchPair]) {
        checkpoint.matchedPairIDs = matchState.completedPairIDs
        checkpoint.selectedTileID = matchState.selectedTileID
        if case .mismatched = matchState.lastOutcome {
            checkpoint.helpedActivityIDs.insert("puzzle")
            checkpoint.hintLevels["puzzle", default: 0] += 1
        }
        if matchState.completedPairIDs.count == pairs.count {
            let support: LearningSupport = checkpoint.helpedActivityIDs.contains("puzzle-rescued") ? .rescued : (checkpoint.helpedActivityIDs.contains("puzzle") ? .hinted : .independent)
            complete("puzzle", activity: .match, successful: true, support: support,
                     promptType: .eventToPlaceMatch, detail: "Completed TV authored matching set")
            focus = "puzzle-continue"
        }
        saveCheckpoint()
    }

    private func requestedMatchPair(_ pairs: [ChronicleMatchPair]) -> ChronicleMatchPair? {
        if let selected = ChronicleMatchEngine.tiles(for: pairs).first(where: { $0.id == matchState.selectedTileID }),
           !matchState.completedPairIDs.contains(selected.pairID) {
            return pairs.first(where: { $0.id == selected.pairID })
        }
        return pairs.first(where: { !matchState.completedPairIDs.contains($0.id) })
    }

    private func matchHelp(_ pairs: [ChronicleMatchPair]) {
        guard let pair = requestedMatchPair(pairs) else { return }
        checkpoint.helpedActivityIDs.insert("puzzle")
        checkpoint.hintLevels["puzzle", default: 0] += 1
        matchState.lastOutcome = .mismatched(clue: "Choose \(pair.leftText), then \(pair.rightText). " + pair.teachingClue)
        saveCheckpoint()
    }

    private func matchRescue(_ pairs: [ChronicleMatchPair]) {
        guard let pair = requestedMatchPair(pairs) else { return }
        checkpoint.hintLevels["puzzle"] = max(checkpoint.hintLevels["puzzle", default: 0], 2)
        checkpoint.helpedActivityIDs.insert("puzzle")
        checkpoint.helpedActivityIDs.insert("puzzle-rescued")
        matchState.completedPairIDs.insert(pair.id)
        matchState.selectedTileID = nil
        matchState.lastOutcome = .matched(pairID: pair.id, feedback: "We placed this pair together. " + pair.teachingClue, completedSet: matchState.completedPairIDs.count == pairs.count)
        updateMatch(pairs)
    }

    private func updateSequence(_ cards: [TVSequenceCard]) {
        checkpoint.sequenceSlots = sequenceState.slots
        checkpoint.selectedTileID = sequenceState.selectedCardID
        checkpoint.hintLevels["puzzle"] = sequenceState.hintLevel
        if sequenceState.helped { checkpoint.helpedActivityIDs.insert("puzzle") }
        if sequenceState.rescued { checkpoint.helpedActivityIDs.insert("puzzle-rescued") }
        if TVSequenceEngine.isComplete(state: sequenceState, cards: cards) {
            let support: LearningSupport = sequenceState.rescued ? .rescued : (sequenceState.helped ? .hinted : .independent)
            for card in cards {
                complete("order-" + card.id, subjectID: card.id, subjectType: .timeline, activity: .timelinePlacement,
                         successful: true, support: support, promptType: .sequenceSlot, detail: "TV ordered three taught story events")
            }
            checkpoint.completedActivityIDs.insert("puzzle")
            focus = "puzzle-continue"
        }
        saveCheckpoint()
    }

    private func puzzleComplete(_ chapter: TVChapter) -> Bool {
        switch chapter.puzzle {
        case .match(let pairs): pairs.allSatisfy { checkpoint.matchedPairIDs.contains($0.id) }
        case .order(let cards): TVSequenceEngine.isComplete(state: sequenceState, cards: cards)
        }
    }

    private func complete(_ key: String, subjectID: String? = nil, subjectType: MasterySubjectType = .scene,
                          activity: LearningActivityKind, successful: Bool, support: LearningSupport = .independent,
                          promptType: RecallPromptType = .openPrompt, detail: String) {
        guard let chapter, !checkpoint.completedActivityIDs.contains(key) else { return }
        let eventID = checkpoint.eventID(for: key)
        saveCheckpoint()
        let id = subjectID ?? chapter.id
        let recorded = appModel.lessonStore.recordLearningOutcome(subjectID: id, subjectType: subjectType, activity: activity,
                                                                  wasSuccessful: successful, support: support, promptType: promptType,
                                                                  detail: detail, eventID: eventID, sessionID: sessionID)
        let alreadyRecorded = appModel.lessonStore.masteryRecord(for: id)?.evidenceLog.contains { $0.eventID == eventID } == true
        if recorded || alreadyRecorded { checkpoint.completedActivityIDs.insert(key) }
        saveCheckpoint()
    }

    private func move(to stage: TVActivityStage) {
        narrator.stop()
        checkpoint.selectedTileID = nil
        checkpoint.stage = stage
        feedback = nil
        helpText = nil
        if stage == .recall, appModel.parentSettings.assistModeEnabled,
           checkpoint.hintLevels["recall", default: 0] == 0, let chapter {
            recallHelp(chapter)
        }
        saveCheckpoint()
        restoreFocus()
    }

    private func loadChapter() {
        guard let chapter, restoredSceneID != chapter.id else { return }
        restoredSceneID = chapter.id
        narrator.stop()
        let point = appModel.lessonStore.resumePoint(for: chapter.id)
        sessionID = point?.sessionID ?? UUID()
        checkpoint = point?.tvCheckpoint ?? TVActivityCheckpoint()
        checkpoint.storyBeatIndex = min(checkpoint.storyBeatIndex, chapter.storyBeats.count - 1)
        feedback = nil
        discovery = nil
        helpText = nil
        keepsakeSelected = false
        if case .match(let pairs) = chapter.puzzle {
            checkpoint.matchedPairIDs.formIntersection(Set(pairs.map(\.id)))
            let selected = ChronicleMatchEngine.tiles(for: pairs).first {
                $0.id == checkpoint.selectedTileID && !checkpoint.matchedPairIDs.contains($0.pairID)
            }
            if checkpoint.stage == .puzzle { checkpoint.selectedTileID = selected?.id }
            matchState = ChronicleMatchState(selectedTileID: checkpoint.stage == .puzzle ? selected?.id : nil,
                                             completedPairIDs: checkpoint.matchedPairIDs)
        } else { matchState = ChronicleMatchState() }
        if case .order(let cards) = chapter.puzzle {
            let stored = checkpoint.sequenceSlots.count == cards.count ? checkpoint.sequenceSlots : Array(repeating: nil, count: cards.count)
            let slots = stored.enumerated().map { index, id in id == cards[index].id ? id : nil }
            sequenceState = TVSequenceState(slots: slots, selectedCardID: checkpoint.selectedTileID,
                                            hintLevel: checkpoint.hintLevels["puzzle", default: 0], helped: checkpoint.helpedActivityIDs.contains("puzzle"),
                                            rescued: checkpoint.helpedActivityIDs.contains("puzzle-rescued"))
        }
        if appModel.parentSettings.assistModeEnabled && checkpoint.stage == .recall && checkpoint.hintLevels["recall", default: 0] == 0 {
            recallHelp(chapter)
        }
        saveCheckpoint()
        restoreFocus()
    }

    private func restartChapter(_ chapter: TVChapter) {
        narrator.stop()
        checkpoint = TVActivityCheckpoint()
        preserveTimeline(from: appModel.lessonStore.resumePoint(for: chapter.id)?.tvCheckpoint)
        sessionID = UUID()
        restoredSceneID = nil
        var point = LessonResumePoint(sceneID: chapter.id, sessionID: sessionID)
        point.tvCheckpoint = checkpoint
        appModel.lessonStore.saveResumePoint(point)
        loadChapter()
    }

    private func saveCheckpoint() {
        guard let chapter, restoredSceneID == chapter.id else { return }
        var point = appModel.lessonStore.resumePoint(for: chapter.id) ?? LessonResumePoint(sceneID: chapter.id, sessionID: sessionID)
        preserveTimeline(from: point.tvCheckpoint)
        point.sessionID = sessionID
        point.tvCheckpoint = checkpoint
        point.storyCardIndex = checkpoint.storyBeatIndex
        point.recallCompleted = checkpoint.completedActivityIDs.contains("recall")
        point.revealedHintLevel = checkpoint.hintLevels["recall", default: 0]
        point.recognitionRescueUnlocked = checkpoint.helpedActivityIDs.contains("recall-rescued")
        point.completedMatchPairIDs = checkpoint.matchedPairIDs
        point.discoveredDetailIDs = checkpoint.discoveredDetailIDs
        point.solvedPlaceIDs = checkpoint.solvedPlaceIDs
        point.phase = checkpoint.stage == .story || checkpoint.stage == .discover ? .story : (checkpoint.stage == .place ? .place : (checkpoint.stage == .recall ? .recall : .reward))
        point.updatedAt = Date()
        appModel.lessonStore.saveResumePoint(point)
    }

    /// A timeline can be played while this lesson remains on the navigation stack.
    /// Merge its separate checkpoint before saving, so returning from it cannot erase its progress.
    private func preserveTimeline(from prior: TVActivityCheckpoint?) {
        guard let prior else { return }
        checkpoint.timelineCheckpoint = prior.timelineCheckpoint
        checkpoint.completedActivityIDs = Set(checkpoint.completedActivityIDs.filter { !$0.hasPrefix("timeline-") })
        checkpoint.helpedActivityIDs = Set(checkpoint.helpedActivityIDs.filter { !$0.hasPrefix("timeline-") })
        checkpoint.completionEventIDs = checkpoint.completionEventIDs.filter { !$0.key.hasPrefix("timeline-") }
        checkpoint.completedActivityIDs.formUnion(prior.completedActivityIDs.filter { $0.hasPrefix("timeline-") })
        checkpoint.helpedActivityIDs.formUnion(prior.helpedActivityIDs.filter { $0.hasPrefix("timeline-") })
        for (key, id) in prior.completionEventIDs where key.hasPrefix("timeline-") { checkpoint.completionEventIDs[key] = id }
    }

    private func restoreFocus() {
        guard let chapter else { return }
        switch checkpoint.stage {
        case .story: focus = "story-next"
        case .discover: focus = chapter.discoveries.first?.id
        case .place:
            if let clue = chapter.placeClues.first(where: { !checkpoint.solvedPlaceIDs.contains($0.id) }) {
                focus = placeChoices(for: clue).first?.id
            } else { focus = "fort-continue" }
        case .recall: focus = checkpoint.completedActivityIDs.contains("recall") ? "recall-continue" : (checkpoint.selectedTileID == nil ? chapter.plan.choices.first?.id : "recall-check")
        case .puzzle: focus = checkpoint.completedActivityIDs.contains("puzzle") ? "puzzle-continue" : nil
        case .keepsake: focus = checkpoint.completedActivityIDs.contains("album") ? "all-done" : "keepsake-select"
        }
    }

    private func handleBack() {
        narrator.stop()
        if discovery != nil { let id = discovery?.id; discovery = nil; focus = id; return }
        if helpText != nil { helpText = nil; restoreFocus(); return }
        if keepsakeSelected { keepsakeSelected = false; focus = "keepsake-select"; return }
        if checkpoint.selectedTileID != nil {
            checkpoint.selectedTileID = nil
            matchState.selectedTileID = nil
            matchState.lastOutcome = .ignored
            sequenceState.selectedCardID = nil
            saveCheckpoint()
            restoreFocus()
            return
        }
        saveCheckpoint()
        dismiss()
    }

    private func playPause() {
        guard !UIAccessibility.isVoiceOverRunning else { narrator.stop(); return }
        guard appModel.parentSettings.narrationEnabled, let chapter else { return }
        if narrator.activeCardID != nil { narrator.togglePlayback(); return }
        let text: String
        if let discovery { text = discovery.text } else if let helpText { text = helpText } else {
            switch checkpoint.stage {
            case .story: text = chapter.storyBeats[min(checkpoint.storyBeatIndex, chapter.storyBeats.count - 1)].text
            case .discover: text = "Choose a discovery, or continue to become a fort detective."
            case .place: text = feedback ?? chapter.placeClues.first(where: { !checkpoint.solvedPlaceIDs.contains($0.id) })?.clue ?? "Places found. Let's try your memory."
            case .recall: text = feedback ?? chapter.pilot.quiz.question
            case .puzzle:
                if case .match(let pairs) = chapter.puzzle {
                    text = ChronicleMatchPresentation(pairs: pairs).feedback(for: matchState)
                } else { text = sequenceState.feedback ?? "Choose a story card, then its place in the story." }
            case .keepsake: text = chapter.pilot.chronicleEntry.meaning
            }
        }
        narrator.speak(id: chapter.id + "-visible-" + checkpoint.stage.rawValue, text: text)
    }
}
