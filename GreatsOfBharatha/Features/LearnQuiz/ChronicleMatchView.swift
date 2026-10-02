import SwiftUI
#if os(iOS)
import UIKit
#endif

struct ChronicleMatchView: View {
    @EnvironmentObject private var appModel: AppModel
    @EnvironmentObject private var navigation: LearnNavigationCoordinator
    @Environment(\.dismiss) private var dismiss
    @Environment(\.dynamicTypeSize) private var dynamicTypeSize
    @Environment(\.accessibilityReduceMotion) private var reduceMotion
    @ScaledMetric(relativeTo: .body) private var minimumPanelWidth: CGFloat = 160
    let scenes: [LearnQuizPilotScene]
    var sessionID = UUID()
    var usesLegacyPresentation = false
    @State private var completedSceneIDs: Set<String> = []
    @State private var restored = false
    @State private var matchState = ChronicleMatchState()
    @State private var highlightedPairID: String?
    @State private var celebrationID = UUID()

    private var pairs: [ChronicleMatchPair] { scenes.flatMap(\.matchPairs) }
    private var presentation: ChronicleMatchPresentation { ChronicleMatchPresentation(pairs: pairs) }
    private var tiles: [ChronicleMatchTile] { ChronicleMatchEngine.tiles(for: pairs) }
    private var leftTiles: [ChronicleMatchTile] { tiles.filter { $0.side == .left } }
    private var rightTiles: [ChronicleMatchTile] { Array(tiles.filter { $0.side == .right }.reversed()) }
    private var isComplete: Bool { !pairs.isEmpty && pairs.allSatisfy { matchState.completedPairIDs.contains($0.id) } }
    private var reduceMovement: Bool { reduceMotion || appModel.parentSettings.calmTransitionsEnabled }
    private var selectedTile: ChronicleMatchTile? { tiles.first { $0.id == matchState.selectedTileID } }
    private var instructionsText: String { isComplete ? "Here are the partners you found." : presentation.instruction }
    private var narrationText: String {
        guard isComplete else { return presentation.instruction }
        return instructionsText + " " + pairs.compactMap { pair in
            leftTiles.first(where: { $0.pairID == pair.id }).map {
                presentation.displayText(for: $0) + " belongs with " + pair.rightText + "."
            }
        }.joined(separator: " ")
    }

    var body: some View {
        GBLayoutContextReader { context in
            GeometryReader { geometry in
                let availableWidth = min(geometry.size.width, context.maxContentWidth ?? geometry.size.width) - 2 * context.containerPadding
                let horizontal = !dynamicTypeSize.isAccessibilitySize && availableWidth >= 2 * minimumPanelWidth + 24
                ScrollView {
                    VStack(alignment: .leading, spacing: GBSpacing.small) {
                        header
                        MatchingReplayControls(text: narrationText)
                        MatchingGuideFeedback(message: feedbackText, celebrating: highlightedPairID != nil,
                                              reduceMovement: reduceMovement)
                        if isComplete {
                            completedAssociations
                            completionCard
                        } else {
                            cancelSelection
                        }
                        matchBoard(horizontal: horizontal)
                        if !isComplete { completedAssociations }
                    }
                    .frame(maxWidth: context.maxContentWidth, alignment: .leading)
                    .padding(context.containerPadding)
                    .frame(maxWidth: .infinity)
                }
                .accessibilityIdentifier("matching-scroll")
                .safeAreaInset(edge: .bottom, spacing: 0) {
                    if isComplete { doneBar }
                }
                .background(GBColor.Background.app)
            }
        }
        .onAppear(perform: restoreCheckpoint)
        .onDisappear {
            GBNarrator.shared.stop()
            highlightedPairID = nil
            celebrationID = UUID()
        }
        .onChange(of: reduceMovement) { _, reduced in
            if reduced { highlightedPairID = nil; celebrationID = UUID() }
        }
        .task(id: celebrationID) {
            guard highlightedPairID != nil else { return }
            try? await Task.sleep(for: .milliseconds(600))
            guard !Task.isCancelled else { return }
            highlightedPairID = nil
        }
        .navigationTitle("Match the story")
#if os(iOS)
        .navigationBarTitleDisplayMode(.inline)
#endif
    }

    private var header: some View {
        VStack(alignment: .leading, spacing: GBSpacing.xxSmall) {
            Text(isComplete ? "You found every pair!" : "Find the story partners")
                .gbTitle().foregroundStyle(GBColor.Content.primary)
            Text(instructionsText)
                .font(GBFont.ui(size: 15)).foregroundStyle(GBColor.Content.secondary)
        }
    }

    @ViewBuilder
    private func matchBoard(horizontal: Bool) -> some View {
        if horizontal {
            HStack(alignment: .top, spacing: 12) {
                panel(title: presentation.leftTitle, instruction: presentation.leftInstruction, tiles: leftTiles, isLeft: true)
                Rectangle().fill(GBColor.Border.emphasis).frame(width: 1)
                    .accessibilityHidden(true)
                panel(title: presentation.rightTitle, instruction: presentation.rightInstruction, tiles: rightTiles, isLeft: false)
            }
            .fixedSize(horizontal: false, vertical: true)
            .accessibilityElement(children: .contain)
            .accessibilityIdentifier("matching-board-horizontal")
        } else {
            VStack(spacing: GBSpacing.small) {
                panel(title: presentation.leftTitle, instruction: presentation.leftInstruction, tiles: leftTiles, isLeft: true)
                Divider().accessibilityHidden(true)
                panel(title: presentation.rightTitle, instruction: presentation.rightInstruction, tiles: rightTiles, isLeft: false)
            }
            .accessibilityElement(children: .contain)
            .accessibilityIdentifier("matching-board-stacked")
        }
    }

    private func panel(title: String, instruction: String, tiles: [ChronicleMatchTile], isLeft: Bool) -> some View {
        VStack(alignment: .leading, spacing: GBSpacing.xSmall) {
            Text(title).font(GBFont.ui(size: 17, weight: .heavy)).accessibilityAddTraits(.isHeader)
            Text(instruction).font(GBFont.ui(size: 11)).foregroundStyle(GBColor.Content.secondary)
            ForEach(tiles) { tile in matchTile(tile) }
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(GBSpacing.xSmall)
        .background(isLeft ? GBColor.Place.bg : GBColor.Chronicle.goldBg,
                    in: RoundedRectangle(cornerRadius: GBRadius.card))
        .overlay(RoundedRectangle(cornerRadius: GBRadius.card).stroke(GBColor.Border.emphasis))
    }

    private func matchTile(_ tile: ChronicleMatchTile) -> some View {
        let selected = matchState.selectedTileID == tile.id
        let matched = matchState.completedPairIDs.contains(tile.pairID)
        let status = matched ? "Matched" : (selected ? "Selected" : "Available")
        return Button { select(tile) } label: {
            VStack(alignment: .leading, spacing: GBSpacing.xxSmall) {
                Text(presentation.displayText(for: tile))
                    .font(GBFont.ui(size: 15, weight: .heavy))
                    .fixedSize(horizontal: false, vertical: true)
                if matched || selected {
                    Label(status, systemImage: matched ? "checkmark.circle.fill" : "hand.tap.fill")
                        .font(GBFont.ui(size: 11, weight: .bold))
                } else {
                    // Reserve the status line so selecting does not move partners.
                    Text(" ").font(GBFont.ui(size: 11, weight: .bold)).accessibilityHidden(true)
                }
            }
            .frame(maxWidth: .infinity, minHeight: 64, alignment: .leading)
            .padding(GBSpacing.xSmall)
            .foregroundStyle(GBColor.Content.primary)
            .background(matched ? GBColor.Background.elevated : GBColor.Background.surface,
                        in: RoundedRectangle(cornerRadius: GBRadius.card))
            .overlay(RoundedRectangle(cornerRadius: GBRadius.card)
                .stroke(matched ? GBColor.Place.primary : (selected ? GBColor.Chronicle.gold : GBColor.Border.emphasis),
                        lineWidth: selected || matched ? 2 : 1))
            .offset(y: selected && !reduceMovement ? -3 : 0)
            .animation(reduceMovement ? nil : GBMotion.quick, value: selected)
        }
        .buttonStyle(.plain)
        .accessibilityElement(children: .ignore)
        .accessibilityLabel(presentation.displayText(for: tile))
        .accessibilityValue(status)
        .accessibilityHint(matched ? "This pair is already matched." : "Choose this card, then its partner in the other panel.")
        .accessibilityAddTraits(selected ? [.isSelected, .isButton] : .isButton)
        .accessibilityIdentifier("match-tile-" + tile.id)
    }

    private var cancelSelection: some View {
        Button {
            matchState.selectedTileID = nil
            matchState.lastOutcome = .ignored
            saveMatchCheckpoint()
            announce("Card put back. Choose a card from either panel.")
        } label: {
            Label("Put this card back", systemImage: "arrow.uturn.backward")
                .font(GBFont.ui(size: 15)).frame(minHeight: GBTouch.button)
        }
        .buttonStyle(.bordered)
        .disabled(selectedTile == nil)
        .accessibilityIdentifier("matching-cancel-selection")
    }

    private var feedbackText: String {
        switch matchState.lastOutcome {
        case .mismatched(let clue):
            return clue + " Try another partner."
        case .matched(_, let feedback, _):
            return feedback
        case .selected(let tile):
            return presentation.displayText(for: tile) + " is selected. Find its partner."
        case .ignored, nil:
            if let selectedTile {
                return presentation.displayText(for: selectedTile) + " is selected. Find its partner."
            }
            return isComplete ? "Every pair belongs together. Tell the story with your family." : "I’ll help you find the partners. You can change your chosen card."
        }
    }

    @ViewBuilder private var completedAssociations: some View {
        let completed = pairs.filter { matchState.completedPairIDs.contains($0.id) }
        if !completed.isEmpty {
            VStack(alignment: .leading, spacing: GBSpacing.xSmall) {
                Text("Partners you found").font(GBFont.ui(size: 17, weight: .heavy)).accessibilityAddTraits(.isHeader)
                ForEach(completed) { pair in
                    VStack(alignment: .leading, spacing: GBSpacing.xxSmall) {
                        if let left = leftTiles.first(where: { $0.pairID == pair.id }) {
                            Text(presentation.displayText(for: left)).font(GBFont.ui(size: 15, weight: .heavy))
                        }
                        HStack(spacing: GBSpacing.xxSmall) {
                            Rectangle().frame(height: highlightedPairID == pair.id ? 3 : 1)
                            Image(systemName: "link").font(.caption.weight(.bold))
                            Rectangle().frame(height: highlightedPairID == pair.id ? 3 : 1)
                        }
                        .foregroundStyle(GBColor.Place.primary.opacity(highlightedPairID == pair.id ? 1 : 0.5))
                        .frame(height: 18)
                        .accessibilityHidden(true)
                        Label(pair.rightText, systemImage: "link")
                            .font(GBFont.ui(size: 15)).foregroundStyle(GBColor.Content.secondary)
                    }
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .padding(GBSpacing.xSmall)
                    .background(GBColor.Background.elevated, in: RoundedRectangle(cornerRadius: GBRadius.card))
                    .overlay(RoundedRectangle(cornerRadius: GBRadius.card)
                        .stroke(GBColor.Place.primary, lineWidth: highlightedPairID == pair.id ? 3 : 1))
                    .animation(reduceMovement ? nil : .easeOut(duration: 0.4), value: highlightedPairID)
                    .accessibilityElement(children: .combine)
                    .accessibilityIdentifier("matching-recap-" + pair.id)
                }
            }
        }
    }

    private var completionCard: some View {
        Text("All pairs matched. Your Chronicle remembers this activity.")
            .font(GBFont.ui(size: 15, weight: .semibold))
            .foregroundStyle(GBColor.Content.primary)
            .accessibilityIdentifier("matching-completion")
    }

    private var doneBar: some View {
        Button("Done") {
            if usesLegacyPresentation { dismiss() }
            navigation.returnHome()
        }
            .buttonStyle(.gbPrimary(.place))
            .accessibilityIdentifier("matching-done")
            .padding(.horizontal, GBSpacing.small)
            .padding(.vertical, GBSpacing.xSmall)
            .frame(maxWidth: .infinity)
            .background(GBColor.Background.app)
    }

    private func select(_ tile: ChronicleMatchTile) {
        matchState = ChronicleMatchEngine.select(tileID: tile.id, state: matchState, pairs: pairs)
        saveMatchCheckpoint()
        recordCompletedScenes()
        switch matchState.lastOutcome {
        case .matched(let pairID, _, _):
            announce(feedbackText)
            guard !reduceMovement else { return }
            highlightedPairID = pairID
            celebrationID = UUID()
        case .selected, .mismatched:
            announce(feedbackText)
        case .ignored, nil:
            break
        }
    }

    private func restoreCheckpoint() {
        guard !restored else { return }
        restored = true
        var selectedCandidates: [(Date, String)] = []
        for scene in scenes {
            guard let point = appModel.lessonStore.resumePoint(for: scene.id) else { continue }
            let scenePairIDs = Set(scene.matchPairs.map(\.id))
            matchState.completedPairIDs.formUnion(point.completedMatchPairIDs.intersection(scenePairIDs))
            matchState.mismatchCount = max(matchState.mismatchCount, point.matchMismatchCount)
            if let selectedID = point.selectedMatchTileID,
               tiles.contains(where: { $0.id == selectedID && scenePairIDs.contains($0.pairID) }) {
                selectedCandidates.append((point.updatedAt, selectedID))
            }
            if appModel.lessonStore.masteryRecord(for: scene.id)?.evidenceLog.contains(where: {
                $0.eventID == point.matchEventID && $0.type == .matchSuccess
            }) == true { completedSceneIDs.insert(scene.id) }
        }
        matchState.selectedTileID = selectedCandidates.sorted { $0.0 > $1.0 }.first(where: { candidate in
            tiles.contains { $0.id == candidate.1 && !matchState.completedPairIDs.contains($0.pairID) }
        })?.1
        saveMatchCheckpoint()
        recordCompletedScenes()
    }

    private func saveMatchCheckpoint() {
        for scene in scenes {
            var point = appModel.lessonStore.resumePoint(for: scene.id) ?? LessonResumePoint(sceneID: scene.id, phase: .story, sessionID: sessionID)
            point.preferredActivity = .match
            point.completedMatchPairIDs = Set(scene.matchPairs.map(\.id)).intersection(matchState.completedPairIDs)
            point.matchMismatchCount = matchState.mismatchCount
            point.selectedMatchTileID = selectedTile.flatMap { tile in scene.matchPairs.contains { $0.id == tile.pairID } ? tile.id : nil }
            point.updatedAt = Date()
            appModel.lessonStore.saveResumePoint(point)
        }
    }

    private func recordCompletedScenes() {
        for scene in scenes where !completedSceneIDs.contains(scene.id) {
            guard !scene.matchPairs.isEmpty,
                  scene.matchPairs.allSatisfy({ matchState.completedPairIDs.contains($0.id) }) else { continue }
            completedSceneIDs.insert(scene.id)
            appModel.lessonStore.recordLearningOutcome(subjectID: scene.id, activity: .match,
                wasSuccessful: true, support: matchState.mismatchCount == 0 ? .independent : .hinted,
                mastery: .observedClosely, promptType: .eventToPlaceMatch,
                detail: "Completed authored matching set",
                eventID: appModel.lessonStore.resumePoint(for: scene.id)?.matchEventID ?? UUID(),
                sessionID: appModel.lessonStore.resumePoint(for: scene.id)?.sessionID ?? sessionID)
            LessonFeedback.fire(.success)
        }
    }

    private func announce(_ message: String) {
#if os(iOS)
        guard UIAccessibility.isVoiceOverRunning else { return }
        GBNarrator.shared.stop()
        UIAccessibility.post(notification: .announcement, argument: message)
#endif
    }
}

#Preview("Chronicle Match") {
    LearnNavigationStack { ChronicleMatchView(scenes: LearnQuizPilotData.scenes) }
        .environmentObject(AppModel(defaults: UserDefaults(suiteName: "gob.preview.matching")!))
}
