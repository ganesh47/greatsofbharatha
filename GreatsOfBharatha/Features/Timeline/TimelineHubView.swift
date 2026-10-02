import SwiftUI

/// The coordinator supplies durable storage and the checked-placement adapter.
/// The no-argument initializer remains useful for the existing isolated capture route.
struct TimelineHubView: View {
    @EnvironmentObject private var appModel: AppModel
    @Environment(\.scenePhase) private var scenePhase
    @State private var checkpoint: TimelineActivityCheckpoint
    @State private var loaded = false
    @State private var showingRecap = false

    private let initialCheckpoint: TimelineActivityCheckpoint?
    private let onCheckpointChange: ((TimelineActivityCheckpoint) -> Void)?
    private let onPlacementChecked: ((TimelinePlacementCheck) -> Bool)?

    init(checkpoint: TimelineActivityCheckpoint? = nil,
         onCheckpointChange: ((TimelineActivityCheckpoint) -> Void)? = nil,
         onPlacementChecked: ((TimelinePlacementCheck) -> Bool)? = nil) {
        initialCheckpoint = checkpoint
        _checkpoint = State(initialValue: checkpoint ?? TimelineActivityCheckpoint())
        self.onCheckpointChange = onCheckpointChange
        self.onPlacementChecked = onPlacementChecked
    }

    private var allRounds: [TimelineActivityRound] {
        TimelineActivityCatalog.allRounds(events: appModel.content.activeHeroArc.timelineEvents)
    }

    private var checkedSceneIDs: Set<String> {
        Set(appModel.content.scenes.compactMap { scene in
            let evidence = appModel.lessonStore.masteryRecord(for: scene.id)?.evidenceLog ?? []
            return TimelineActivityCatalog.hasCheckedLearning(evidence: evidence) ? scene.id : nil
        })
    }

    private var rounds: [TimelineActivityRound] {
        TimelineActivityCatalog.availableRounds(events: appModel.content.activeHeroArc.timelineEvents, checkedSceneIDs: checkedSceneIDs)
    }

    private var currentRound: TimelineActivityRound? {
        rounds.first { $0.id == checkpoint.currentRoundID }
    }

    private var progress: TimelineRoundProgress {
        checkpoint.rounds[checkpoint.currentRoundID] ?? TimelineRoundProgress()
    }

    private var completedRoundCount: Int {
        rounds.filter { TimelineActivityEngine.isComplete(round: $0, checkpoint: checkpoint) }.count
    }

    private var allAvailableComplete: Bool {
        !rounds.isEmpty && completedRoundCount == rounds.count
    }

    var body: some View {
        GBLayoutContextReader { context in
            ScrollView {
                VStack(alignment: .leading, spacing: context.sectionSpacing) {
                    heading
                    if let round = currentRound {
                        if showingRecap || !progress.teachingSeen {
                            recap(round: round)
                        } else if allAvailableComplete {
                            completion
                        } else {
                            activity(round: round)
                        }
                    } else {
                        lockedIntroduction
                    }
                }
                .frame(maxWidth: context.maxContentWidth, alignment: .leading)
                .padding(context.containerPadding)
                .frame(maxWidth: .infinity)
            }
            .background(GBColor.Background.app)
        }
        .navigationTitle("Story timeline")
        .onAppear(perform: restore)
        .onDisappear(perform: save)
        .onChange(of: scenePhase) { _, phase in if phase != .active { save() } }
        .onChange(of: checkedSceneIDs) { _, _ in
            checkpoint = TimelineActivityEngine.restored(checkpoint, allRounds: allRounds, availableRounds: rounds)
            saveAndDeliverChecks()
        }
    }

    private var heading: some View {
        GBSurface(style: .elevated) {
            VStack(alignment: .leading, spacing: GBSpacing.xSmall) {
                Label("Shivaji Maharaj's journey", systemImage: GBIcon.timeline)
                    .font(.caption.weight(.semibold)).foregroundStyle(GBColor.Story.primary)
                Text("Put the story in order").gbTitle().foregroundStyle(GBColor.Content.primary)
                Text("Remember what came first, what came next, and how the little parts connect.")
                    .gbBody().foregroundStyle(GBColor.Content.secondary)
                if !rounds.isEmpty {
                    Text("\(completedRoundCount) of \(rounds.count) parts checked")
                        .gbCaption().accessibilityIdentifier("timeline-round-progress")
                    ProgressView(value: Double(completedRoundCount), total: Double(rounds.count))
                        .tint(GBColor.Place.primary)
                }
            }
        }
    }

    private var lockedIntroduction: some View {
        GBSurface {
            VStack(alignment: .leading, spacing: GBSpacing.small) {
                Label("A little story recap is coming", systemImage: "book.closed")
                    .font(.headline)
                Text("Learn the first three chapters and check an answer in each. Then put that part of the story in order here.")
                    .gbBody()
                Text("Looking at cards and saying you remember them are useful practice. The ordering activity opens after checked answers.")
                    .gbCaption().foregroundStyle(GBColor.Content.secondary)
            }
            .accessibilityIdentifier("timeline-locked")
        }
    }

    private func recap(round: TimelineActivityRound) -> some View {
        VStack(alignment: .leading, spacing: GBSpacing.small) {
            GBSectionHeader(eyebrow: "Look back together", title: "Three moments in the story",
                            subtitle: "Read this little part before you try. Story order comes before exact dates.")
            ForEach(round.cards) { card in
                GBSurface {
                    VStack(alignment: .leading, spacing: GBSpacing.xxSmall) {
                        Label(card.title, systemImage: card.symbol).font(.headline)
                        Text(card.teachingText).gbBody()
                        if let scene = appModel.content.activeHeroArc.scene(withID: card.sceneID) {
                            Text(scene.childSafeSummary).gbBody()
                            Text(scene.meaningStatement).gbBody().foregroundStyle(GBColor.Content.secondary)
                        }
                        if let yearLabel = card.yearLabel {
                            Text(yearLabel).gbCaption().foregroundStyle(GBColor.Content.secondary)
                        }
                    }
                    .accessibilityElement(children: .combine)
                }
            }
            Button(progress.teachingSeen ? "Return to the order" : "Ready to put them in order") {
                if !progress.teachingSeen { TimelineActivityEngine.begin(round: round, checkpoint: &checkpoint) }
                showingRecap = false
                save()
            }
            .buttonStyle(.gbPrimary)
            .accessibilityIdentifier("timeline-start")
        }
    }

    private func activity(round: TimelineActivityRound) -> some View {
        VStack(alignment: .leading, spacing: GBSpacing.small) {
            Text("Tap a story card, then tap First, Then, or After that. Cards that belong stay in place.")
                .gbBody().accessibilityIdentifier("timeline-instructions")
            Text("Choose a card").gbHeadline().accessibilityAddTraits(.isHeader)
            // A fixed mixed order keeps all choices available and avoids teaching the answer by layout.
            ForEach([round.cards[2], round.cards[0], round.cards[1]]) { card in
                choice(card: card, round: round)
            }
            Text("Choose its place").gbHeadline().accessibilityAddTraits(.isHeader)
                .padding(.top, GBSpacing.xSmall)
            if let selected = round.cards.first(where: { $0.id == progress.selectedCardID }) {
                Text("Selected: " + selected.title).gbBody().foregroundStyle(GBColor.Story.primary)
                    .accessibilityIdentifier("timeline-selected-card")
            }
            ForEach(round.cards.indices, id: \.self) { index in
                slot(index: index, round: round)
            }
            if let feedback = progress.feedback {
                Label(feedback, systemImage: "leaf.fill")
                    .font(.body).foregroundStyle(GBColor.Content.primary)
                    .padding(GBSpacing.small)
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .background(GBColor.Place.bg, in: RoundedRectangle(cornerRadius: GBRadius.card))
                    .accessibilityIdentifier("timeline-feedback")
            }
            if TimelineActivityEngine.isComplete(round: round, checkpoint: checkpoint) {
                Button("Next part of the story") {
                    TimelineActivityEngine.advance(rounds: rounds, checkpoint: &checkpoint)
                    saveAndDeliverChecks()
                }
                .buttonStyle(.gbPrimary)
                .accessibilityIdentifier("timeline-next")
            } else {
                Button("Give me a clue") {
                    TimelineActivityEngine.hint(round: round, checkpoint: &checkpoint)
                    save()
                }
                .buttonStyle(.gbSecondary)
                .frame(minHeight: GBTouch.button)
                .accessibilityIdentifier("timeline-hint")
            }
            Button("Look at these story cards again") {
                if !TimelineActivityEngine.isComplete(round: round, checkpoint: checkpoint) {
                    TimelineActivityEngine.hint(round: round, checkpoint: &checkpoint)
                }
                showingRecap = true
                save()
            }
            .buttonStyle(.gbSecondary)
            .frame(minHeight: GBTouch.button)
            .accessibilityIdentifier("timeline-recap")
        }
    }

    private func choice(card: TimelineActivityCard, round: TimelineActivityRound) -> some View {
        let placed = progress.slots.contains(card.id)
        let selected = progress.selectedCardID == card.id
        return Button {
            TimelineActivityEngine.select(cardID: card.id, round: round, checkpoint: &checkpoint)
            save()
        } label: {
            HStack(spacing: GBSpacing.small) {
                Image(systemName: placed ? "checkmark.circle.fill" : card.symbol)
                    .font(.title2).foregroundStyle(placed ? GBColor.Place.primary : GBColor.Story.primary)
                Text(card.title).gbHeadline().multilineTextAlignment(.leading)
                Spacer(minLength: GBSpacing.xxSmall)
                if selected { Image(systemName: "hand.tap.fill").foregroundStyle(GBColor.Story.primary) }
            }
            .foregroundStyle(GBColor.Content.primary)
            .padding(GBSpacing.small)
            .frame(maxWidth: .infinity, minHeight: GBTouch.primary, alignment: .leading)
            .background(selected ? GBColor.Story.bg : GBColor.Background.surface, in: RoundedRectangle(cornerRadius: GBRadius.card))
            .overlay(RoundedRectangle(cornerRadius: GBRadius.card).stroke(selected ? GBColor.Story.primary : GBColor.Border.panel,
                                                                        lineWidth: selected ? 3 : 1))
        }
        .buttonStyle(.plain)
        .disabled(placed)
        .accessibilityLabel(card.title)
        .accessibilityValue(placed ? "Checked and placed" : (selected ? "Selected" : "Available"))
        .accessibilityHint(placed ? "This correct card stays in place." : "Select this card, then choose its place in the story.")
        .accessibilityAddTraits(selected ? [.isSelected] : [])
        .accessibilityIdentifier("timeline-card-" + card.id)
    }

    private func slot(index: Int, round: TimelineActivityRound) -> some View {
        let placedID = progress.slots.indices.contains(index) ? progress.slots[index] : nil
        let placedCard = round.cards.first { $0.id == placedID }
        let title = TimelineActivityEngine.slotTitle(index)
        return Button {
            let check = TimelineActivityEngine.place(slotIndex: index, round: round, checkpoint: &checkpoint)
            if check != nil { GBHaptic.pinCorrect() }
            saveAndDeliverChecks()
        } label: {
            HStack(alignment: .center, spacing: GBSpacing.small) {
                Image(systemName: placedCard == nil ? "circle.dashed" : "checkmark.circle.fill")
                    .foregroundStyle(placedCard == nil ? GBColor.Story.primary : GBColor.Place.primary)
                VStack(alignment: .leading, spacing: GBSpacing.xxxSmall) {
                    Text(title).gbHeadline()
                    Text(placedCard?.title ?? (progress.selectedCardID == nil ? "Choose a card first" : "Tap to place your card"))
                        .gbBody().multilineTextAlignment(.leading)
                }
                Spacer(minLength: 0)
            }
            .foregroundStyle(GBColor.Content.primary)
            .padding(GBSpacing.small)
            .frame(maxWidth: .infinity, minHeight: GBTouch.primary, alignment: .leading)
            .background(placedCard == nil ? GBColor.Background.surface : GBColor.Place.bg, in: RoundedRectangle(cornerRadius: GBRadius.card))
            .overlay(RoundedRectangle(cornerRadius: GBRadius.card).stroke(GBColor.Border.panel, lineWidth: 1))
        }
        .buttonStyle(.plain)
        .disabled(placedCard != nil || progress.selectedCardID == nil)
        .accessibilityLabel(title + (placedCard.map { ", " + $0.title } ?? ", empty"))
        .accessibilityValue(placedCard == nil ? "Waiting for a card" : "Checked and placed")
        .accessibilityHint("Place the selected story card here.")
        .accessibilityIdentifier("timeline-slot-\(index)")
    }

    private var completion: some View {
        GBSurface {
            VStack(alignment: .leading, spacing: GBSpacing.small) {
                Label(rounds.count == allRounds.count ? "The journey belongs together" : "The opening story belongs together",
                      systemImage: "book.closed.fill")
                    .font(.title2.weight(.bold)).foregroundStyle(GBColor.Place.primary)
                    .accessibilityIdentifier("timeline-success")
                Text("You checked the order of these story cards. Retell this part with someone if you want.")
                    .gbBody()
                if rounds.count < allRounds.count {
                    Text("After checked answers in all six chapters, the next parts connect Purandar, Agra and return, recovery, and Raigad.")
                        .gbBody()
                }
                if checkpoint.rounds.values.contains(where: { $0.support != .independent }) {
                    Text("We used clues along the way. This records order checked with help.")
                        .gbCaption().foregroundStyle(GBColor.Content.secondary)
                } else {
                    Text("This records checked story order. A later revisit can help you remember it again.")
                        .gbCaption().foregroundStyle(GBColor.Content.secondary)
                }
                Button("Look back at these story cards") { showingRecap = true }
                    .buttonStyle(.gbSecondary)
                    .frame(minHeight: GBTouch.button)
                    .accessibilityIdentifier("timeline-complete-recap")
            }
        }
    }

    private func restore() {
        guard !loaded else { return }
        loaded = true
        checkpoint = TimelineActivityEngine.restored(initialCheckpoint, allRounds: allRounds, availableRounds: rounds)
        saveAndDeliverChecks()
    }

    private func save() {
        guard loaded, !rounds.isEmpty else { return }
        onCheckpointChange?(checkpoint)
    }

    private func saveAndDeliverChecks() {
        save()
        guard loaded, let onPlacementChecked else { return }
        // Save-before-check closes the crash window; a retry always uses the same eventID.
        for check in TimelineActivityEngine.pendingChecks(rounds: rounds, checkpoint: checkpoint) where onPlacementChecked(check) {
            TimelineActivityEngine.acknowledge(check, checkpoint: &checkpoint)
        }
        save()
    }
}
