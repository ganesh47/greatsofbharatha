import SwiftUI

struct TVHomeView: View {
    @EnvironmentObject private var appModel: AppModel
    @EnvironmentObject private var narrator: GBNarrator
    @State private var path: [TVRoute] = []
    @FocusState private var focusedAction: String?

    private var continuation: StoryScene {
        let scenes = appModel.content.scenes
        let unfinished = scenes.filter { appModel.lessonStore.isSceneUnlocked($0) }
            .compactMap { appModel.lessonStore.resumePoint(for: $0.id) }.filter {
            $0.tvCheckpoint?.completedActivityIDs.contains("album") != true
        }.max { $0.updatedAt < $1.updatedAt }
        if let point = unfinished, let scene = scenes.first(where: { $0.id == point.sceneID }) { return scene }
        if let due = appModel.lessonStore.dueReviews().first(where: { $0.subjectType == .scene }),
           let scene = scenes.first(where: { $0.id == due.subjectID }) { return scene }
        return scenes.first(where: { appModel.lessonStore.isSceneUnlocked($0) && !hasRecall($0) }) ?? scenes[0]
    }

    private func hasRecall(_ scene: StoryScene) -> Bool {
        guard let chapter = TVLearningContent.chapter(sceneID: scene.id) else { return false }
        return TVLearningContent.hasCheckedLearning(chapter, store: appModel.lessonStore)
    }

    var body: some View {
        NavigationStack(path: $path) {
            TVScreen {
                ScrollView {
                    VStack(alignment: .leading, spacing: 32) {
                        HStack(alignment: .top, spacing: 48) {
                            VStack(alignment: .leading, spacing: 22) {
                                Text("GREATS OF BHARATHA").font(.system(size: 24, weight: .bold, design: .rounded)).tracking(3).foregroundStyle(TVTheme.gold)
                                Text("Your fort adventure").font(.system(size: 56, weight: .bold, design: .serif))
                                Text("Discover Shivaji Maharaj through stories, places, and little puzzles.")
                                    .font(.system(size: 30, design: .rounded)).fixedSize(horizontal: false, vertical: true)
                                NavigationLink(value: continuationRoute) {
                                    Label(continueLabel, systemImage: "play.fill")
                                }
                                .buttonStyle(TVCardButtonStyle())
                                .focused($focusedAction, equals: "continue")
                                .accessibilityIdentifier("tv-home-continue")
                            }.frame(maxWidth: .infinity, alignment: .leading)
                            TVChapterArt(scene: continuation).frame(width: 630, height: 300).clipShape(RoundedRectangle(cornerRadius: 28))
                        }
                        TVFireflyGuide(message: "I’m your storybook helper. Move to choose, then click to explore. You can ask for a clue whenever you like!")
                        HStack(spacing: 24) {
                            destination("My Album", symbol: "book.closed.fill", route: .album, id: "tv-home-album")
                            destination("Fort board", symbol: "map.fill", route: .map, id: "tv-home-map")
                            destination("Story timeline", symbol: "clock.fill", route: .timeline, id: "tv-home-timeline")
                            destination("Grown-ups", symbol: "gearshape.fill", route: .parent, id: "tv-home-parent")
                        }
                        Text("Six chapters to discover").font(.system(size: 36, weight: .bold, design: .serif))
                        LazyVGrid(columns: [GridItem(.flexible()), GridItem(.flexible()), GridItem(.flexible())], spacing: 28) {
                            ForEach(appModel.content.scenes) { scene in
                                chapter(scene)
                            }
                        }
                    }.padding(12)
                }
            }
            .defaultFocus($focusedAction, "continue")
            .navigationDestination(for: TVRoute.self) { route in
                switch route {
                case .lesson(let sceneID): TVLessonView(sceneID: sceneID)
                case .replay(let sceneID): TVLessonView(sceneID: sceneID, restartOnEntry: true)
                case .album: TVAlbumView()
                case .map: TVFortBoardView()
                case .timeline: TVTimelineView()
                case .parent: TVParentView()
                }
            }
            .onChange(of: path) { _, _ in narrator.clearCurrent() }
        }
    }

    private var continuationRoute: TVRoute {
        if appModel.lessonStore.resumePoint(for: continuation.id)?.tvCheckpoint?.completedActivityIDs.contains("album") == true {
            return .replay(continuation.id)
        }
        return .lesson(continuation.id)
    }

    private var continueLabel: String {
        if let point = appModel.lessonStore.resumePoint(for: continuation.id), point.tvCheckpoint?.completedActivityIDs.contains("album") != true { return "Continue: " + continuation.title }
        return (hasRecall(continuation) ? "Explore again: " : "Start: ") + continuation.title
    }

    private func destination(_ title: String, symbol: String, route: TVRoute, id: String) -> some View {
        NavigationLink(value: route) { Label(title, systemImage: symbol).frame(maxWidth: .infinity) }
            .buttonStyle(TVCardButtonStyle()).accessibilityIdentifier(id)
    }

    private func chapter(_ scene: StoryScene) -> some View {
        let unlocked = appModel.lessonStore.isSceneUnlocked(scene)
        let started = appModel.lessonStore.masteryRecord(for: scene.id) != nil
        let route: TVRoute = appModel.lessonStore.resumePoint(for: scene.id)?.tvCheckpoint?.completedActivityIDs.contains("album") == true ? .replay(scene.id) : .lesson(scene.id)
        return NavigationLink(value: route) {
            VStack(alignment: .leading, spacing: 16) {
                TVChapterArt(scene: scene).frame(height: 170).clipShape(RoundedRectangle(cornerRadius: 14))
                Text("Chapter \(scene.number)").font(.system(size: 23, weight: .bold)).foregroundStyle(TVTheme.gold)
                Text(scene.title).font(.system(size: 30, weight: .bold, design: .rounded)).lineLimit(2)
                Label(hasRecall(scene) ? "Story fact recognised" : (started ? "Started" : (unlocked ? "Ready to discover" : "Discover the earlier chapter first")),
                      systemImage: hasRecall(scene) ? "checkmark.seal" : (unlocked ? "book" : "lock"))
                    .font(.system(size: 23)).fixedSize(horizontal: false, vertical: true)
            }.frame(maxWidth: .infinity, alignment: .leading)
        }
        .buttonStyle(TVCardButtonStyle()).disabled(!unlocked)
        .accessibilityIdentifier("tv-home-chapter-" + scene.id)
    }
}
