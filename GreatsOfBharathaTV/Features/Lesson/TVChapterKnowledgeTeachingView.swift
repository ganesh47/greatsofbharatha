import SwiftUI

/// TV pages keep each original narrative and paired fact readable before its durable receipt.
struct TVChapterKnowledgeTeachingView: View {
    @EnvironmentObject private var narrator: GBNarrator
    @EnvironmentObject private var appModel: AppModel
    @Environment(\.dismiss) private var dismiss
    @Environment(\.scenePhase) private var scenePhase
    @StateObject private var presentation: ChapterKnowledgePresentationSession
    @State private var pageIndex = 0
    @State private var visitedPages: Set<String> = []
    @State private var coverage = ChapterKnowledgeTextCoverage()
    @State private var coverageID = ""
    @State private var sourcesExpanded = false
    @State private var started = false
    @FocusState private var focus: String?
    let chapter: TVChapter
    let definition: ChapterKnowledgeDefinition
    let sessionID: UUID
    let onFinished: () -> Void
    var now: () -> Date
    var startingAtBeatID: String?
    var onActiveBeatChanged: (String) -> Void
    var nextIdentifier: String

    init(chapter: TVChapter, definition: ChapterKnowledgeDefinition, sessionID: UUID,
         hooks: ChapterKnowledgeHooks, onFinished: @escaping () -> Void, now: @escaping () -> Date = Date.init,
         startingAtBeatID: String? = nil, onActiveBeatChanged: @escaping (String) -> Void = { _ in },
         nextIdentifier: String = "tv-knowledge-teaching-next") {
        self.chapter = chapter
        self.definition = definition
        self.sessionID = sessionID
        self.onFinished = onFinished
        self.now = now
        self.startingAtBeatID = startingAtBeatID
        self.onActiveBeatChanged = onActiveBeatChanged
        self.nextIdentifier = nextIdentifier
        _presentation = StateObject(wrappedValue: ChapterKnowledgePresentationSession(hooks: hooks))
    }

    private var available: Bool {
        chapter.id == definition.sceneID && definition.validationIssues.isEmpty &&
            definition.claims.allSatisfy { $0.reviewStatus == .approved }
    }
    private var beat: ChapterKnowledgeBeat? {
        let id = presentation.archive.teachingBySceneID[definition.sceneID]?.activeBeatID
        return definition.beats.first { $0.id == id } ?? definition.beats.first
    }
    private var beatIndex: Int { definition.beats.firstIndex { $0.id == beat?.id } ?? 0 }
    private var pages: [TVKnowledgeReadingPage] {
        beat.map { TVKnowledgeReadingPage.pages(beat: $0, definition: definition) } ?? []
    }
    private var page: TVKnowledgeReadingPage? { pages.indices.contains(pageIndex) ? pages[pageIndex] : nil }
    private var pageWasPresented: Bool { page?.id == coverageID && coverage.isComplete }

    var body: some View {
        GeometryReader { viewport in
            ScrollViewReader { proxy in
                ScrollView {
                    VStack(alignment: .leading, spacing: 24) {
                        Color.clear.frame(height: 1).id("tv-knowledge-top").accessibilityHidden(true)
                        header
                        saveStatus
                        if !available || presentation.isReadOnly {
                            Text("Your saved chapter is preserved. Return to your story to keep exploring.")
                                .font(.system(size: 30)).accessibilityIdentifier("tv-knowledge-teaching-unavailable")
                        } else if let beat, let page {
                            readingCard(beat: beat, page: page)
                            sources(page)
                            HStack(spacing: 26) {
                                Button(pageIndex < pages.count - 1 ? "Next card" :
                                    (beatIndex < definition.beats.count - 1 ? "Next part" : "Continue")) { continueReading() }
                                    .disabled(presentation.isBlocked || !pageWasPresented)
                                    .focused($focus, equals: "next").accessibilityIdentifier(nextIdentifier)
                                if pageIndex > 0 || beatIndex > 0 {
                                    Button("Previous card", action: previous)
                                        .disabled(presentation.isBlocked).focused($focus, equals: "previous")
                                        .accessibilityIdentifier("tv-knowledge-teaching-previous")
                                }
                                TVNarrationControls(id: page.id, text: page.text)
                            }.buttonStyle(TVCardButtonStyle()).focusSection()
                            Text("Read each little card, then choose Next. Our firefly guide is make-believe.")
                                .font(.system(size: 23)).foregroundStyle(GBColor.Content.secondary)
                        }
                    }
                    .padding(.horizontal, 76).padding(.vertical, 42)
                    .frame(maxWidth: 1740, alignment: .leading).frame(maxWidth: .infinity)
                }
                .accessibilityIdentifier("tv-knowledge-teaching-scroll")
                .onPreferenceChange(TVKnowledgeTextFrameKey.self) { sample in
                    guard scenePhase == .active, sample.id == page?.id else { return }
                    if coverageID != sample.id { coverageID = sample.id; coverage = ChapterKnowledgeTextCoverage() }
                    coverage.observe(textFrame: sample.frame, viewport: viewport.frame(in: .global))
                }
                .onChange(of: page?.id) {
                    sourcesExpanded = false
                    narrator.stop()
                    proxy.scrollTo("tv-knowledge-top", anchor: .top)
                }
                .onChange(of: pageWasPresented) { _, ready in if ready && !presentation.isBlocked { focus = "next" } }
            }
        }
        .background(TVTheme.background).foregroundStyle(TVTheme.paper)
        .onAppear(perform: load)
        .onChange(of: scenePhase) { _, phase in
            if phase == .active { load() } else { _ = presentation.confirmBeforeLeaving(); narrator.stop() }
        }
        .onExitCommand(perform: pause)
        .onPlayPauseCommand {
            guard appModel.parentSettings.narrationEnabled, let page else { return }
            if narrator.activeCardID != nil { narrator.togglePlayback() } else { narrator.speak(id: page.id, text: page.text) }
        }
        .onDisappear { narrator.stop() }
    }

    private var header: some View {
        HStack(alignment: .top) {
            VStack(alignment: .leading, spacing: 10) {
                Text("Chapter \(chapter.number) · Story").font(.system(size: 24, weight: .semibold))
                Text(chapter.title).font(.system(size: 40, weight: .bold))
                Text("Part \(beatIndex + 1) of \(definition.beats.count) · Card \(pageIndex + 1) of \(pages.count)")
                    .font(.system(size: 24)).accessibilityIdentifier("tv-knowledge-teaching-progress")
            }
            Spacer()
            Button("Pause for now", action: pause).buttonStyle(TVCardButtonStyle())
                .disabled(!presentation.isReadOnly && presentation.isBlocked)
                .accessibilityIdentifier("tv-knowledge-teaching-pause")
        }.focusSection()
    }

    @ViewBuilder private var saveStatus: some View {
        if presentation.saveIsConfirmed {
            Text("Saved on this TV").font(.system(size: 22)).accessibilityIdentifier("tv-knowledge-save-confirmed")
        } else if presentation.loaded && !presentation.isReadOnly {
            Text("This step is still saving. Try saving again before continuing.").font(.system(size: 25))
            Button("Try saving again") { if presentation.retry(), !started { load() } }
                .buttonStyle(TVCardButtonStyle()).focused($focus, equals: "retry")
                .accessibilityIdentifier("tv-knowledge-save-retry")
        }
    }

    private func readingCard(beat: ChapterKnowledgeBeat, page: TVKnowledgeReadingPage) -> some View {
        HStack(alignment: .top, spacing: 38) {
            Image(chapter.plan.imageAsset ?? chapter.pilot.art.assetSlot).resizable().scaledToFit()
                .frame(width: 440, height: 260).accessibilityHidden(true)
            VStack(alignment: .leading, spacing: 18) {
                Text(beat.title).font(.system(size: 30, weight: .bold))
                    .accessibilityIdentifier("tv-knowledge-beat-" + beat.id)
                Text(page.text).font(.system(size: 33)).fixedSize(horizontal: false, vertical: true)
                    .accessibilityIdentifier(page.claim.map { "tv-knowledge-fact-" + $0.id } ?? "tv-knowledge-beat-text-" + page.id)
                    .background(GeometryReader { geometry in
                        Color.clear.preference(key: TVKnowledgeTextFrameKey.self,
                            value: TVKnowledgeTextFrame(id: page.id, frame: geometry.frame(in: .global)))
                    })
            }.frame(maxWidth: .infinity, alignment: .leading)
        }
    }

    @ViewBuilder private func sources(_ page: TVKnowledgeReadingPage) -> some View {
        if let claim = page.claim {
            Button(sourcesExpanded ? "Close sources and detail" : "Sources and detail") { sourcesExpanded.toggle() }
                .buttonStyle(TVCardButtonStyle()).accessibilityIdentifier("tv-knowledge-sources-" + claim.id)
            if sourcesExpanded {
                ForEach(Array(claim.citations.enumerated()), id: \.offset) { _, citation in
                    let source = ChapterKnowledgeSourceCatalog.source(id: citation.sourceID)
                    Text((source?.title ?? citation.sourceID) + " · " + citation.locator)
                        .font(.system(size: 24)).fixedSize(horizontal: false, vertical: true)
                        .accessibilityIdentifier("tv-knowledge-citation-" + claim.id + "-" + citation.sourceID)
                }
            }
        }
    }

    private func load() {
        guard presentation.reload(), available else { return }
        let saved = presentation.archive.teachingBySceneID[definition.sceneID]?.activeBeatID
        let id = !started ? startingAtBeatID ?? saved : saved
        let resolved = ChapterStoryBeatMigration.resolve(sceneID: definition.sceneID, persistedBeatID: id,
            legacyIndex: 0, availableBeatIDs: definition.beats.map(\.id))
        if let beatID = resolved.beatID { _ = activate(beatID) }
        started = true
    }

    @discardableResult private func activate(_ beatID: String) -> Bool {
        let next = ChapterKnowledgeJourney.activateTeachingBeat(beatID, archive: presentation.archive, definition: definition)
        guard presentation.commit(next) else { focus = "retry"; return false }
        pageIndex = 0
        visitedPages = []
        onActiveBeatChanged(beatID)
        return true
    }

    private func continueReading() {
        guard !presentation.isBlocked, pageWasPresented, let beat, let page else { return }
        visitedPages.insert(page.id)
        if pageIndex < pages.count - 1 { pageIndex += 1; return }
        guard Set(pages.map(\.id)).isSubset(of: visitedPages) else { return }
        let next = ChapterKnowledgeJourney.presentedBeat(beat.id, visibleClaimIDs: Set(beat.claimIDs), sessionID: sessionID,
            archive: presentation.archive, definition: definition, now: now())
        guard presentation.commit(next) else { focus = "retry"; return }
        if beatIndex < definition.beats.count - 1 { _ = activate(definition.beats[beatIndex + 1].id) } else if presentation.confirmBeforeLeaving() { narrator.stop(); onFinished() }
    }

    private func previous() {
        if pageIndex > 0 { pageIndex -= 1 } else if beatIndex > 0 { _ = activate(definition.beats[beatIndex - 1].id) }
    }

    private func pause() {
        guard presentation.isReadOnly || presentation.confirmBeforeLeaving() else { focus = "retry"; return }
        narrator.stop()
        dismiss()
    }
}

struct TVKnowledgeReadingPage: Identifiable {
    let id: String
    let text: String
    let claim: ChapterKnowledgeClaim?

    static func pages(beat: ChapterKnowledgeBeat, definition: ChapterKnowledgeDefinition) -> [Self] {
        let original = ChapterKnowledgeTeachingPage.pages(beat: beat, definition: definition)
        return original.flatMap { page in
            // Short caption pages retain every word, including the supplemental glossary.
            let words = page.text.split(whereSeparator: \.isWhitespace).map(String.init)
            return stride(from: 0, to: words.count, by: 55).map { index in
                Self(id: page.id + "-caption-\(index / 55)",
                     text: words[index..<min(index + 55, words.count)].joined(separator: " "), claim: page.claim)
            }
        }
    }
}

struct TVKnowledgeTextFrame: Equatable {
    let id: String
    let frame: CGRect
}

struct TVKnowledgeTextFrameKey: PreferenceKey {
    static let defaultValue = TVKnowledgeTextFrame(id: "", frame: .zero)
    static func reduce(value: inout TVKnowledgeTextFrame, nextValue: () -> TVKnowledgeTextFrame) { value = nextValue() }
}
