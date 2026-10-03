import Foundation
import Combine

/// Presentation owns proposed saves; only the confirmed archive drives either screen.
@MainActor
final class ChapterKnowledgePresentationSession: ObservableObject {
    @Published private(set) var archive = ChapterKnowledgeArchive()
    @Published private(set) var loaded = false
    @Published private(set) var saveFailed = false
    private var unsavedArchive: ChapterKnowledgeArchive?
    private let hooks: ChapterKnowledgeHooks

    init(hooks: ChapterKnowledgeHooks) { self.hooks = hooks }

    var isReadOnly: Bool { loaded && !archive.isSupported }
    var isBlocked: Bool { !loaded || isReadOnly || saveFailed || !archive.pendingEvidence.isEmpty }
    var saveIsConfirmed: Bool { loaded && !isBlocked }

    @discardableResult
    func reload() -> Bool {
        // A return from another screen must never discard this screen's failed proposal.
        guard unsavedArchive == nil else { return false }
        archive = hooks.load()
        loaded = true
        guard archive.isSupported else { return false }
        return persist(archive)
    }

    @discardableResult
    func commit(_ proposed: ChapterKnowledgeArchive) -> Bool {
        guard !isBlocked, proposed.isSupported else { return false }
        return persist(proposed)
    }

    @discardableResult
    func retry() -> Bool {
        guard loaded, !isReadOnly else { return false }
        return persist(unsavedArchive ?? archive)
    }

    @discardableResult
    func confirmBeforeLeaving() -> Bool {
        guard !isBlocked else { return false }
        return persist(archive)
    }

    private func persist(_ proposed: ChapterKnowledgeArchive) -> Bool {
        guard let confirmed = ChapterKnowledgePersistence.saveAndReplay(proposed, hooks: hooks) else {
            unsavedArchive = proposed
            saveFailed = true
            return false
        }
        archive = confirmed
        unsavedArchive = nil
        saveFailed = false
        return confirmed.pendingEvidence.isEmpty
    }
}

/// Coverage follows actual text geometry, including text taller than a phone viewport.
/// Neither an appearance callback nor reaching the bottom alone is a reading receipt.
struct ChapterKnowledgeTextCoverage {
    private var size: CGSize = .zero
    private var ranges: [ClosedRange<CGFloat>] = []

    var isComplete: Bool {
        guard size.height > 0, ranges.count == 1, let range = ranges.first else { return false }
        return range.lowerBound <= 0.5 && range.upperBound >= size.height - 0.5
    }

    mutating func observe(textFrame: CGRect, viewport: CGRect) {
        guard !textFrame.isEmpty, !textFrame.isNull, !viewport.isEmpty, !viewport.isNull,
              textFrame.width.isFinite, textFrame.height.isFinite else { return }
        if abs(size.width - textFrame.width) > 0.5 || abs(size.height - textFrame.height) > 0.5 {
            size = textFrame.size
            ranges = []
        }
        // Horizontally clipped text is never considered presented.
        guard textFrame.minX >= viewport.minX - 0.5, textFrame.maxX <= viewport.maxX + 0.5 else { return }
        let visible = textFrame.intersection(viewport)
        guard !visible.isNull, !visible.isEmpty else { return }
        ranges.append(max(0, visible.minY - textFrame.minY)...min(size.height, visible.maxY - textFrame.minY))
        var merged: [ClosedRange<CGFloat>] = []
        for range in ranges.sorted(by: { $0.lowerBound < $1.lowerBound }) {
            if let last = merged.last, range.lowerBound <= last.upperBound + 0.5 {
                merged[merged.count - 1] = last.lowerBound...max(last.upperBound, range.upperBound)
            } else {
                merged.append(range)
            }
        }
        ranges = merged
    }
}

struct ChapterKnowledgeTeachingPage: Identifiable {
    let id: String
    let text: String
    let claim: ChapterKnowledgeClaim?

    static func pages(beat: ChapterKnowledgeBeat, definition: ChapterKnowledgeDefinition) -> [Self] {
        let claims = beat.claimIDs.compactMap { id in definition.claims.first { $0.id == id } }
        return [Self(id: beat.id + "-text", text: beat.text, claim: nil)] + claims.map {
            Self(id: beat.id + "-fact-" + $0.id, text: $0.statement, claim: $0)
        }
    }
}

#if os(iOS)
import SwiftUI

struct ChapterKnowledgeTeachingView: View {
    @Environment(\.dismiss) private var dismiss
    @Environment(\.scenePhase) private var scenePhase
    @AccessibilityFocusState private var textIsFocused: Bool
    @StateObject private var presentation: ChapterKnowledgePresentationSession
    @State private var pageIndex = 0
    @State private var coverage = ChapterKnowledgeTextCoverage()
    @State private var coveragePageID = ""
    @State private var visitedPageIDs: Set<String> = []
    @State private var sourcesExpanded = false
    @State private var glossaryExpanded = false
    @State private var started = false
    #if DEBUG
    @State private var frameDiagnostic = "No text sample"
    #endif

    let scene: LearnQuizPilotScene
    let definition: ChapterKnowledgeDefinition
    let sessionID: UUID
    let onFinished: () -> Void
    var now: () -> Date
    var startingAtBeatID: String?
    var sourceLookup: (String) -> ChapterKnowledgeSource?

    init(scene: LearnQuizPilotScene, definition: ChapterKnowledgeDefinition, sessionID: UUID,
         hooks: ChapterKnowledgeHooks, onFinished: @escaping () -> Void,
         now: @escaping () -> Date = Date.init, startingAtBeatID: String? = nil,
         sourceLookup: @escaping (String) -> ChapterKnowledgeSource? = { _ in nil }) {
        self.scene = scene
        self.definition = definition
        self.sessionID = sessionID
        self.onFinished = onFinished
        self.now = now
        self.startingAtBeatID = startingAtBeatID
        self.sourceLookup = sourceLookup
        _presentation = StateObject(wrappedValue: ChapterKnowledgePresentationSession(hooks: hooks))
    }

    private var available: Bool {
        scene.id == definition.sceneID && definition.validationIssues.isEmpty && !definition.beats.isEmpty &&
            definition.claims.allSatisfy { $0.reviewStatus == .approved }
    }
    private var beat: ChapterKnowledgeBeat? {
        let savedID = presentation.archive.teachingBySceneID[definition.sceneID]?.activeBeatID
        return definition.beats.first { $0.id == savedID } ?? definition.beats.first
    }
    private var beatIndex: Int { definition.beats.firstIndex { $0.id == beat?.id } ?? 0 }
    private var pages: [ChapterKnowledgeTeachingPage] {
        beat.map { ChapterKnowledgeTeachingPage.pages(beat: $0, definition: definition) } ?? []
    }
    private var page: ChapterKnowledgeTeachingPage? { pages.indices.contains(pageIndex) ? pages[pageIndex] : nil }
    private var pageWasPresented: Bool { coveragePageID == page?.id && coverage.isComplete }
    private var vocabulary: [ChapterKnowledgeClaim] { definition.claims.filter { $0.kind == .vocabulary && $0.reviewStatus == .approved } }

    var body: some View {
        GBLayoutContextReader { context in
            GeometryReader { viewport in
                ScrollViewReader { proxy in
                    ScrollView {
                        VStack(alignment: .leading, spacing: context.sectionSpacing) {
                            Color.clear.frame(height: 1).id("knowledge-teaching-top").accessibilityHidden(true)
                            header
                            ChapterKnowledgeSaveStatus(presentation: presentation, retry: loadAfterRetry)
                            if presentation.isReadOnly || !available {
                                unavailable
                            } else if let beat, let page {
                                readingCard(beat: beat, page: page)
                                details(page: page)
                                readingActions(beat: beat)
                            }
                            Button("Pause for now") {
                                if presentation.isReadOnly || presentation.confirmBeforeLeaving() { dismiss() }
                            }
                            .buttonStyle(.gbSecondary)
                            .disabled(!presentation.isReadOnly && presentation.isBlocked)
                            .accessibilityIdentifier("knowledge-teaching-pause")
                        }
                        .frame(maxWidth: context.maxContentWidth, alignment: .leading)
                        .padding(context.containerPadding)
                        .frame(maxWidth: .infinity)
                    }
                    .accessibilityIdentifier("knowledge-teaching-scroll")
                    .onPreferenceChange(ChapterKnowledgeTextFrameKey.self) { sample in
                        #if DEBUG
                        frameDiagnostic = "sample=\(sample.id) frame=\(sample.frame) viewport=\(viewport.frame(in: .global)) phase=\(scenePhase)"
                        #endif
                        guard scenePhase == .active, available, sample.id == page?.id else { return }
                        if coveragePageID != sample.id {
                            coverage = ChapterKnowledgeTextCoverage()
                            coveragePageID = sample.id
                        }
                        coverage.observe(textFrame: sample.frame, viewport: viewport.frame(in: .global))
                    }
                    .onChange(of: page?.id) {
                        sourcesExpanded = false
                        proxy.scrollTo("knowledge-teaching-top", anchor: .top)
                        textIsFocused = true
                    }
                    .onChange(of: beat?.id) {
                        pageIndex = 0
                        visitedPageIDs = []
                    }
                }
            }
            .background(GBColor.Background.app)
        }
        .navigationTitle("Chapter \(scene.number)")
        .navigationBarTitleDisplayMode(.inline)
        .onAppear { load() }
        .onChange(of: scenePhase) { _, phase in
            if phase == .active { load() }
        }
    }

    private var header: some View {
        VStack(alignment: .leading, spacing: GBSpacing.small) {
            Text(scene.title).gbTitle().accessibilityAddTraits(.isHeader)
            Text("Part \(beatIndex + 1) of \(definition.beats.count) · Card \(pageIndex + 1) of \(pages.count)")
                .gbBody().accessibilityIdentifier("knowledge-teaching-progress")
        }
    }

    private var unavailable: some View {
        Text(presentation.isReadOnly
             ? "Your saved chapter is preserved. Return to your story to keep exploring."
             : "These extra chapter cards are still being checked. You can continue your story.")
            .gbStory().accessibilityIdentifier("knowledge-teaching-unavailable")
    }

    private func readingCard(beat: ChapterKnowledgeBeat, page: ChapterKnowledgeTeachingPage) -> some View {
        GBSurface(style: .elevated) {
            VStack(alignment: .leading, spacing: GBSpacing.medium) {
                Text(beat.title).gbHeadline().accessibilityAddTraits(.isHeader)
                    .accessibilityIdentifier("knowledge-beat-" + beat.id)
                if page.claim == nil {
                    Image(scene.art.assetSlot).resizable().scaledToFit().frame(maxHeight: 180)
                        .accessibilityHidden(true)
                } else {
                    Text(page.claim?.kind == .vocabulary ? "A word to explore" : "Remember this")
                        .gbBody()
                }
                Text(page.text).gbStory().fixedSize(horizontal: false, vertical: true)
                    .accessibilityFocused($textIsFocused)
                    .accessibilityIdentifier(page.claim.map { "knowledge-fact-" + $0.id } ?? "knowledge-beat-text-" + beat.id)
                    .background(GeometryReader { geometry in
                        Color.clear.preference(key: ChapterKnowledgeTextFrameKey.self,
                            value: scenePhase == .active
                                ? ChapterKnowledgeTextFrame(id: page.id, frame: geometry.frame(in: .global))
                                : ChapterKnowledgeTextFrameKey.defaultValue)
                    })
            }
        }
    }

    private func details(page: ChapterKnowledgeTeachingPage) -> some View {
        VStack(alignment: .leading, spacing: GBSpacing.medium) {
            if let claim = page.claim {
                DisclosureGroup("Sources and detail", isExpanded: $sourcesExpanded) {
                    ChapterKnowledgeCitationList(claim: claim, sourceLookup: sourceLookup)
                }
                .accessibilityIdentifier("knowledge-sources-" + claim.id)
            }
            if !vocabulary.isEmpty {
                DisclosureGroup("Words to explore", isExpanded: $glossaryExpanded) {
                    ForEach(vocabulary) { claim in
                        Text(claim.statement).gbStory().padding(.vertical, GBSpacing.xSmall)
                            .accessibilityIdentifier("knowledge-word-" + claim.id)
                    }
                }.accessibilityIdentifier("knowledge-glossary")
            }
        }
    }

    private func readingActions(beat: ChapterKnowledgeBeat) -> some View {
        VStack(alignment: .leading, spacing: GBSpacing.small) {
            if !pageWasPresented {
                Text("Scroll through this card, then continue when you’re ready.").gbBody()
            }
            Button(pageIndex < pages.count - 1 ? "Next card" : (beatIndex < definition.beats.count - 1 ? "Next part" : "Continue to practice")) {
                continueReading(beat: beat)
            }
            .buttonStyle(.gbPrimary(.story))
            .disabled(presentation.isBlocked || !pageWasPresented)
            .accessibilityIdentifier("knowledge-teaching-next")
            #if DEBUG
            .accessibilityValue(ProcessInfo.processInfo.environment["GOB_UI_TEST_SUITE"]?.hasPrefix("gob.ui.knowledge.") == true
                ? "\(frameDiagnostic) current=\(page?.id ?? "") coverage=\(coveragePageID)/\(coverage.isComplete) blocked=\(presentation.isBlocked) active=\(scenePhase)" : "")
            #endif
            if pageIndex > 0 || beatIndex > 0 {
                Button("Previous card") { previousCard() }
                    .buttonStyle(.gbSecondary).disabled(presentation.isBlocked)
                    .accessibilityIdentifier("knowledge-teaching-previous")
            }
        }
    }

    private func load() {
        guard presentation.reload(), available else { return }
        let persistedID = presentation.archive.teachingBySceneID[definition.sceneID]?.activeBeatID
        let resolution = ChapterStoryBeatMigration.resolve(sceneID: definition.sceneID,
            persistedBeatID: !started ? (startingAtBeatID ?? persistedID) : persistedID,
            legacyIndex: 0, availableBeatIDs: definition.beats.map(\.id))
        if let id = resolution.beatID { _ = moveToBeat(id) }
        started = true
    }

    private func loadAfterRetry() {
        if presentation.retry(), !started { load() }
    }

    @discardableResult
    private func moveToBeat(_ id: String) -> Bool {
        guard definition.beats.contains(where: { $0.id == id }) else { return false }
        let previousID = beat?.id
        var next = presentation.archive
        var point = next.teachingBySceneID[definition.sceneID] ?? ChapterKnowledgeTeachingCheckpoint(sceneID: definition.sceneID)
        point.activeBeatID = id
        next.teachingBySceneID[definition.sceneID] = point
        guard presentation.commit(next) else { return false }
        if previousID != id {
            pageIndex = 0
            visitedPageIDs = []
        }
        return true
    }

    private func continueReading(beat: ChapterKnowledgeBeat) {
        guard !presentation.isBlocked, pageWasPresented, let page else { return }
        visitedPageIDs.insert(page.id)
        if pageIndex < pages.count - 1 {
            pageIndex += 1
            return
        }
        guard Set(pages.map(\.id)).isSubset(of: visitedPageIDs) else { return }
        let proposed: ChapterKnowledgeArchive
        if beat.claimIDs.isEmpty {
            var next = presentation.archive
            var point = next.teachingBySceneID[definition.sceneID] ?? ChapterKnowledgeTeachingCheckpoint(sceneID: definition.sceneID)
            point.activeBeatID = beat.id
            point.shownBeatIDs.insert(beat.id)
            next.teachingBySceneID[definition.sceneID] = point
            proposed = next
        } else {
            proposed = ChapterKnowledgeJourney.presentedBeat(beat.id, visibleClaimIDs: Set(beat.claimIDs),
                sessionID: sessionID, archive: presentation.archive, definition: definition, now: now())
        }
        guard presentation.commit(proposed) else { return }
        if beatIndex < definition.beats.count - 1 {
            _ = moveToBeat(definition.beats[beatIndex + 1].id)
        } else if presentation.confirmBeforeLeaving() {
            onFinished()
        }
    }

    private func previousCard() {
        if pageIndex > 0 {
            pageIndex -= 1
        } else if beatIndex > 0 {
            _ = moveToBeat(definition.beats[beatIndex - 1].id)
        }
    }
}

struct ChapterKnowledgeTextFrame: Equatable {
    let id: String
    let frame: CGRect
}

struct ChapterKnowledgeTextFrameKey: PreferenceKey {
    static let defaultValue = ChapterKnowledgeTextFrame(id: "", frame: .zero)
    static func reduce(value: inout ChapterKnowledgeTextFrame, nextValue: () -> ChapterKnowledgeTextFrame) {
        let sample = nextValue()
        if !sample.id.isEmpty { value = sample }
    }
}

struct ChapterKnowledgeSaveStatus: View {
    @ObservedObject var presentation: ChapterKnowledgePresentationSession
    let retry: () -> Void

    var body: some View {
        VStack(alignment: .leading, spacing: GBSpacing.small) {
            if presentation.saveIsConfirmed {
                Label("Saved on this device", systemImage: "checkmark.circle")
                    .font(.footnote).accessibilityIdentifier("knowledge-save-confirmed")
            } else if presentation.loaded && !presentation.isReadOnly {
                Text("This step is still saving. Try saving again before continuing.")
                    .gbBody().accessibilityIdentifier("knowledge-save-error")
                Button("Try saving again", action: retry).buttonStyle(.gbSecondary)
                    .accessibilityIdentifier("knowledge-save-retry")
            }
        }
    }
}

struct ChapterKnowledgeCitationList: View {
    let claim: ChapterKnowledgeClaim
    var sourceLookup: (String) -> ChapterKnowledgeSource? = { _ in nil }
    var body: some View {
        VStack(alignment: .leading, spacing: GBSpacing.small) {
            ForEach(Array(claim.citations.enumerated()), id: \.offset) { _, citation in
                VStack(alignment: .leading, spacing: GBSpacing.xxxSmall) {
                    if let source = sourceLookup(citation.sourceID) {
                        Text(source.title).font(.subheadline).bold()
                        Text(source.publisher).font(.footnote)
                        if let edition = source.edition { Text(edition).font(.footnote) }
                    } else {
                        Text(citation.sourceID).font(.subheadline).bold()
                    }
                    Text(citation.locator).font(.body)
                }.fixedSize(horizontal: false, vertical: true)
            }
        }
        .padding(.vertical, GBSpacing.xSmall)
        .accessibilityIdentifier("knowledge-citation-" + claim.id)
    }
}
#endif
