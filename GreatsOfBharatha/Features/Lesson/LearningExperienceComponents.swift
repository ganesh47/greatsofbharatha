import SwiftUI

/// Shared hook for SceneLessonView and the active SceneLearnView adapter.
struct ChapterStoryDiscoveryView: View {
    @EnvironmentObject private var appModel: AppModel
    let content: ChapterDiscoveryContent
    private var point: LessonResumePoint? { appModel.lessonStore.resumePoint(for: content.id) }

    var body: some View {
        VStack(alignment: .leading, spacing: GBSpacing.medium) {
            Text(content.teachingText).gbStory().accessibilityIdentifier("chapter-teaching-" + content.id)
            GBGlossaryTray(terms: GBGlossaryTerm.matching(content.teachingText))
            LearningNarrationControls(id: content.id + "-chapter-teaching", text: content.teachingText)
            ChapterDiscoverySection(content: content,
                discoveredDetailIDs: content.openedDiscoveryIDs(in: point?.discoveredDetailIDs ?? []),
                selectedDetailID: content.restoredDiscovery(id: point?.selectedDiscoveryDetailID)?.id) { discovery in
                    ChapterDiscoveryInteraction.open(discovery, content: content, store: appModel.lessonStore)
                }
            ChapterFamilyReflection(content: content)
        }
        .onAppear {
            // Finish an interrupted prepared exposure with its original event identity.
            if let selected = content.restoredDiscovery(id: point?.selectedDiscoveryDetailID),
               !selected.wasOpened(in: point?.discoveredDetailIDs ?? []) {
                ChapterDiscoveryInteraction.open(selected, content: content, store: appModel.lessonStore)
            }
        }
    }
}

struct ChapterDiscoverySection: View {
    @AccessibilityFocusState private var focusedDetailID: String?
    let content: ChapterDiscoveryContent
    let discoveredDetailIDs: Set<String>
    let selectedDetailID: String?
    var onSelect: (ChapterDiscovery) -> Void

    var body: some View {
        VStack(alignment: .leading, spacing: GBSpacing.small) {
            Text("Look closely").gbTitle()
            Text("Choose something that makes you curious. Explore any detail, or continue when you're ready.").gbBody()
            ForEach(content.discoveries) { discovery in
                VStack(alignment: .leading, spacing: GBSpacing.small) {
                    Button {
                        onSelect(discovery)
                        focusedDetailID = discovery.id
                    } label: {
                        Label(discovery.title, systemImage: discovery.symbol)
                            .frame(maxWidth: .infinity, minHeight: GBTouch.button, alignment: .leading)
                    }
                    .buttonStyle(.bordered)
                    .accessibilityIdentifier(discovery.accessibilityID)
                    .accessibilityValue(discoveredDetailIDs.contains(discovery.id) ? "Opened. Read again" : "Ready to discover")
                    .accessibilityHint("Opens a story detail. You can continue without opening every detail.")
                    if selectedDetailID == discovery.id || (selectedDetailID == nil && discoveredDetailIDs.contains(discovery.id)) {
                        Text(discovery.text).gbStory()
                            .accessibilityIdentifier("chapter-discovery-text-" + discovery.id)
                            .accessibilityFocused($focusedDetailID, equals: discovery.id)
                        LearningNarrationControls(id: discovery.id, text: discovery.text)
                    }
                }
                .padding(GBSpacing.small)
                .background(GBColor.Background.app, in: RoundedRectangle(cornerRadius: GBRadius.card))
            }
        }
        .accessibilityIdentifier("chapter-discoveries-" + content.id)
    }
}

/// Talking and modern reflection are optional; no response or learning evidence is recorded.
struct ChapterFamilyReflection: View {
    @State private var showsPrompt = false
    let content: ChapterDiscoveryContent

    var body: some View {
        VStack(alignment: .leading, spacing: GBSpacing.small) {
            Button {
                showsPrompt.toggle()
            } label: {
                Label("Talk together (optional)", systemImage: "person.2.fill")
                    .frame(maxWidth: .infinity, minHeight: GBTouch.button, alignment: .leading)
            }
            .buttonStyle(.bordered)
            .accessibilityIdentifier("chapter-family-reflection-" + content.id)
            .accessibilityValue(showsPrompt ? "Expanded" : "Collapsed")
            if showsPrompt {
                Text(content.familyPrompt).gbStory().accessibilityIdentifier("chapter-family-prompt-" + content.id)
                LearningNarrationControls(id: content.id + "-family-prompt", text: content.familyPrompt)
                Text("Think about your own day").gbHeadline()
                Text("When could care, planning, or steady work help you or someone else?").gbBody()
                Text("This is your own reflection. There is no answer to check, and you can skip it.").font(.caption)
            }
        }
    }
}

struct LearningNarrationControls: View {
    @Environment(\.dynamicTypeSize) private var dynamicTypeSize
    @EnvironmentObject private var appModel: AppModel
    @ObservedObject private var narrator = GBNarrator.shared
    let id: String
    let text: String

    var body: some View {
        VStack(alignment: .leading, spacing: GBSpacing.xSmall) {
            if appModel.parentSettings.narrationEnabled {
                if dynamicTypeSize.isAccessibilitySize {
                    VStack(spacing: GBSpacing.xSmall) { narrationButtons }
                        .buttonStyle(.bordered)
                } else {
                    HStack(spacing: GBSpacing.xSmall) { narrationButtons }
                        .buttonStyle(.bordered)
                }
                if let message = narrator.statusMessage { Text(message).font(.caption) }
            } else {
                Text("Read-aloud is off in parent settings.").font(.caption)
            }
        }
        .onChange(of: appModel.parentSettings.narrationEnabled) { _, enabled in
            if !enabled { narrator.stop() }
        }
        .onChange(of: text) { _, _ in narrator.stop() }
        .onDisappear { narrator.stop() }
    }

    @ViewBuilder private var narrationButtons: some View {
        Button { narrator.speak(id: id, text: text) } label: {
            Label("Listen", systemImage: "speaker.wave.2.fill")
                .fixedSize(horizontal: true, vertical: false)
                .frame(maxWidth: .infinity, minHeight: GBTouch.button)
        }
        .accessibilityIdentifier("listen-" + id)
        Button { narrator.stop() } label: {
            Label("Stop", systemImage: "stop.fill")
                .fixedSize(horizontal: true, vertical: false)
                .frame(maxWidth: .infinity, minHeight: GBTouch.button)
        }
        .disabled(narrator.activeCardID == nil)
        .accessibilityIdentifier("stop-" + id)
    }

}

struct LessonSceneArt: View {
    let plan: SceneLearningPlan
    var body: some View {
        VStack(alignment: .leading, spacing: GBSpacing.xxSmall) {
        Group {
            if let asset = plan.imageAsset {
                Image(asset).resizable().scaledToFit()
            } else {
                ZStack {
                    RoundedRectangle(cornerRadius: GBRadius.hero).fill(GBColor.gradient(for: .story))
                    Image(systemName: plan.artSymbol).font(.system(size: 84)).foregroundStyle(.white)
                }.frame(height: 180)
            }
        }
        .clipShape(RoundedRectangle(cornerRadius: GBRadius.hero))
        .accessibilityHidden(true)
        Text("Story illustration").font(.caption).foregroundStyle(GBColor.Content.secondary)
        }
    }
}

/// Clue recognition uses bundled text and native graphics, and works offline.
struct OfflineFortChallenge: View {
    @Environment(\.dynamicTypeSize) private var dynamicTypeSize
    @EnvironmentObject private var appModel: AppModel
    let target: Place
    let candidates: [Place]
    var authoredClue: ChapterPlaceClue?
    @Binding var solvedPlaceIDs: Set<String>
    @Binding var helpedPlaceIDs: Set<String>
    var onSuccess: (LearningSupport) -> Void
    @State private var feedback: String?
    private var usedHint: Bool { helpedPlaceIDs.contains(target.id) }
    private var clueText: String { authoredClue?.clue ?? "Find the place for this clue: \(target.memoryHook)." }

    private var solved: Bool { solvedPlaceIDs.contains(target.id) }
    var body: some View {
        VStack(alignment: .leading, spacing: GBSpacing.medium) {
            Text("Fort detective").gbTitle()
            Text(clueText)
                .gbStory().accessibilityIdentifier("fort-detective-clue")
            if appModel.parentSettings.assistModeEnabled {
                Text(target.regionLabel).gbBody()
            }
            LearningNarrationControls(id: "fort-clue-" + target.id,
                text: clueText + " Choose a place on the board.")
            if dynamicTypeSize.isAccessibilitySize {
                VStack(spacing: GBSpacing.small) {
                    ForEach(candidates) { place in candidateButton(place) }
                }
            } else {
                Grid(alignment: .leading, horizontalSpacing: GBSpacing.small, verticalSpacing: GBSpacing.small) {
                    ForEach(0..<((candidates.count + 1) / 2), id: \.self) { row in
                        GridRow {
                            candidateButton(candidates[row * 2])
                            if candidates.indices.contains(row * 2 + 1) {
                                candidateButton(candidates[row * 2 + 1])
                            }
                        }
                    }
                }
            }
            if let feedback {
                Text(feedback).gbBody().accessibilityIdentifier("fort-feedback")
            }
            if !solved {
                Button("Help me find it") {
                    helpedPlaceIDs.insert(target.id)
                    feedback = authoredClue?.hint ?? "Look for \(target.name): \(target.memoryHook)."
                }
                .buttonStyle(.bordered)
                .accessibilityIdentifier("fort-clue-help")
            }
        }
        .padding(GBSpacing.medium)
        .background(GBColor.Place.bg, in: RoundedRectangle(cornerRadius: GBRadius.card))
        .accessibilityElement(children: .contain)
        .accessibilityIdentifier("fort-challenge-" + target.id)
        .onAppear {
            if appModel.parentSettings.assistModeEnabled { helpedPlaceIDs.insert(target.id) }
        }
    }

    private func candidateButton(_ place: Place) -> some View {
        Button {
            if place.id == target.id {
                solvedPlaceIDs.insert(target.id)
                feedback = "Found it! \(target.name). " + (authoredClue?.hint ?? target.primaryEvent)
                onSuccess(usedHint || appModel.parentSettings.assistModeEnabled ? .hinted : .independent)
                LessonFeedback.fire(.success)
            } else {
                helpedPlaceIDs.insert(target.id)
                feedback = "Let's look again. \(target.regionLabel). Need a clue?"
            }
        } label: {
            VStack(spacing: GBSpacing.xSmall) {
                Image(systemName: "building.2.crop.circle.fill").font(.largeTitle)
                Text(place.name).gbHeadline()
                Text(place.regionLabel).font(.caption).fixedSize(horizontal: false, vertical: true)
            }
            .frame(maxWidth: .infinity, minHeight: 100)
            .padding(GBSpacing.small)
        }
        .buttonStyle(.bordered)
        .tint(GBColor.Place.primary)
        .disabled(solved)
        .accessibilityIdentifier("fort-choice-" + place.id)
    }

}

struct ParentGateView: View {
    @Environment(\.dismiss) private var dismiss
    var onContinue: () -> Void
    @State private var answer = ""
    @FocusState private var answerFocused: Bool
    @State private var first = Int.random(in: 12...19)
    @State private var second = Int.random(in: 12...19)
    @State private var feedback = ""
    var body: some View {
        NavigationStack {
            Form {
                Section("For a grown-up") {
                    Text("Please ask a grown-up to continue. What is \(first) + \(second)?")
                        .accessibilityIdentifier("parent-gate-question")
                    TextField("Answer", text: $answer)
                        .focused($answerFocused)
                        .submitLabel(.done)
                        .onSubmit { answerFocused = false }
                        .accessibilityIdentifier("parent-gate-answer")
                    if !feedback.isEmpty { Text(feedback) }
                    Button("Continue") {
                        if Int(answer.trimmingCharacters(in: .whitespacesAndNewlines)) == first + second {
                            dismiss()
                            onContinue()
                        } else {
                            feedback = "Ask your grown-up to try again."
                        }
                    }.accessibilityIdentifier("parent-gate-confirm")
                }
            }
            .navigationTitle("Grown-up check")
            .toolbar { ToolbarItem(placement: .cancellationAction) { Button("Cancel") { dismiss() } } }
        }
    }
}

struct GBGlossaryTerm: Identifiable, Hashable {
    let id: String
    let title: String
    let shortMeaning: String
    let detail: String
    let example: String
    let systemImage: String
    let searchTokens: [String]

    static let swarajya = GBGlossaryTerm(
        id: "swarajya",
        title: "Swarajya",
        shortMeaning: "Self-rule",
        detail: "Swarajya means self-rule: people caring for their own land with duty and dignity.",
        example: "In this story, Swarajya is the big idea Shivaji Maharaj worked toward.",
        systemImage: "flag.fill",
        searchTokens: ["swarajya", "self-rule", "self rule"]
    )

    static let capital = GBGlossaryTerm(
        id: "capital",
        title: "Capital",
        shortMeaning: "Main home base",
        detail: "A capital is an important home base where leaders plan, make decisions, and care for the kingdom.",
        example: "Rajgad became an early capital, so it was a key place for planning.",
        systemImage: "building.columns.fill",
        searchTokens: ["capital"]
    )

    static let coronation = GBGlossaryTerm(
        id: "coronation",
        title: "Coronation",
        shortMeaning: "Crowning ceremony",
        detail: "A coronation is a crowning ceremony. It shows that a leader is taking on a big duty.",
        example: "At Raigad, the coronation marked Shivaji Maharaj as Chhatrapati.",
        systemImage: "crown.fill",
        searchTokens: ["coronation", "crowned", "crowning"]
    )

    static let terrain = GBGlossaryTerm(
        id: "terrain",
        title: "Terrain",
        shortMeaning: "Land shape",
        detail: "Terrain means the shape of the land, like hills, forests, valleys, rocks, and paths.",
        example: "At Pratapgad, the steep hill terrain mattered for planning.",
        systemImage: "mountain.2.fill",
        searchTokens: ["terrain", "hill terrain", "land shape"]
    )

    static let chronicle = GBGlossaryTerm(
        id: "chronicle",
        title: "Chronicle",
        shortMeaning: "Story record",
        detail: "A chronicle is a record of important events. In this app, it is your story album of what you learned.",
        example: "A Chronicle card helps you remember a place, event, or big idea.",
        systemImage: "book.closed.fill",
        searchTokens: ["chronicle"]
    )

    static let fort = GBGlossaryTerm(
        id: "fort",
        title: "Fort",
        shortMeaning: "Strong safe place",
        detail: "A fort is a strong place with walls, gates, and lookout points that can help protect people.",
        example: "Many parts of Shivaji Maharaj's story are tied to hill forts.",
        systemImage: "shield.lefthalf.filled",
        searchTokens: ["fort", "forts"]
    )

    static let all: [GBGlossaryTerm] = [.swarajya, .capital, .coronation, .terrain, .chronicle, .fort]

    static func matching(_ text: String) -> [GBGlossaryTerm] {
        let haystack = text.lowercased()
        let matches = all.filter { term in
            term.searchTokens.contains { haystack.contains($0.lowercased()) }
        }
        return uniqued(matches)
    }

    static func uniqued(_ terms: [GBGlossaryTerm]) -> [GBGlossaryTerm] {
        var seen: Set<String> = []
        return terms.filter { term in
            guard !seen.contains(term.id) else { return false }
            seen.insert(term.id)
            return true
        }
    }
}

struct GBGlossaryTray: View {
    let terms: [GBGlossaryTerm]
    var title: String = "Words to know"

    private var visibleTerms: [GBGlossaryTerm] { GBGlossaryTerm.uniqued(terms) }

    var body: some View {
        if !visibleTerms.isEmpty {
            VStack(alignment: .leading, spacing: GBSpacing.xxSmall) {
                Text(title)
                    .font(GBFont.ui(size: 12, weight: .heavy))
                    .textCase(.uppercase)
                    .tracking(1.1)
                    .foregroundStyle(GBColor.Content.tertiary)

                ScrollView(.horizontal, showsIndicators: false) {
                    HStack(spacing: GBSpacing.xxSmall) {
                        ForEach(visibleTerms) { term in
                            GBGlossaryChip(term: term)
                        }
                    }
                    .padding(.vertical, GBSpacing.xxxSmall)
                }
            }
            .accessibilityElement(children: .contain)
        }
    }
}

struct GBGlossaryChip: View {
    let term: GBGlossaryTerm

    @State private var isShowingDefinition = false

    var body: some View {
        Button {
            isShowingDefinition = true
        } label: {
            HStack(spacing: GBSpacing.xxxSmall) {
                Image(systemName: term.systemImage)
                Text(term.title)
                    .font(GBFont.ui(size: 13, weight: .bold))
                Text(term.shortMeaning)
                    .font(GBFont.ui(size: 12, weight: .semibold))
                    .foregroundStyle(GBColor.Content.secondary)
            }
            .padding(.horizontal, GBSpacing.xSmall)
            .padding(.vertical, GBSpacing.xxSmall)
            .background(GBColor.Background.elevated, in: Capsule())
            .overlay(Capsule().stroke(GBColor.Border.panel, lineWidth: 1))
        }
        .buttonStyle(.plain)
        .foregroundStyle(GBColor.Content.primary)
        .accessibilityLabel("Word help: \(term.title)")
        .accessibilityHint("Shows a short meaning for \(term.title).")
        .sheet(isPresented: $isShowingDefinition) {
            GBGlossarySheet(term: term)
        }
    }
}

private struct GBGlossarySheet: View {
    @Environment(\.dismiss) private var dismiss

    let term: GBGlossaryTerm

    var body: some View {
        NavigationStack {
            ScrollView {
            VStack(alignment: .leading, spacing: GBSpacing.medium) {
                Image(systemName: term.systemImage)
                    .font(.system(size: 42, weight: .semibold))
                    .foregroundStyle(GBColor.Chronicle.gold)
                    .accessibilityHidden(true)

                VStack(alignment: .leading, spacing: GBSpacing.xxSmall) {
                    Text(term.title)
                        .font(GBFont.display(size: 30, weight: .bold))
                        .foregroundStyle(GBColor.Content.primary)
                    Text(term.shortMeaning)
                        .font(GBFont.story(size: 20))
                        .foregroundStyle(GBColor.Chronicle.royal)
                }

                Text(term.detail)
                    .font(GBFont.story(size: 18))
                    .foregroundStyle(GBColor.Content.primary)
                    .lineSpacing(4)

                GBSurface(style: .elevated) {
                    VStack(alignment: .leading, spacing: GBSpacing.xxSmall) {
                        Text("In this story")
                            .font(GBFont.ui(size: 13, weight: .heavy))
                            .textCase(.uppercase)
                            .tracking(1.1)
                            .foregroundStyle(GBColor.Content.tertiary)
                        Text(term.example)
                            .font(GBFont.ui(size: 16, weight: .semibold))
                            .foregroundStyle(GBColor.Content.primary)
                    }
                }

                Spacer()
            }
            .padding(GBSpacing.medium)
            }
            .background(GBColor.Background.app)
            .navigationTitle("Word help")
#if os(iOS)
            .navigationBarTitleDisplayMode(.inline)
#endif
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Button("Done") { dismiss() }
                }
            }
        }
        .presentationDetents([.medium, .large])
    }
}
