import SwiftUI

struct TVFortBoardView: View {
    @EnvironmentObject private var appModel: AppModel
    @EnvironmentObject private var narrator: GBNarrator
    @State private var selectedPlaceID: String?

    private var selectedPlace: Place? { appModel.content.corePlaces.first { $0.id == selectedPlaceID } }

    var body: some View {
        TVScreen {
            ScrollView {
                VStack(alignment: .leading, spacing: 28) {
                    Text("Explore the fort board").font(.system(size: 52, weight: .bold, design: .serif))
                    TVFireflyGuide(message: "Choose a fort to hear its story. In the chapters, you’ll find places from clues!")
                    HStack(alignment: .top, spacing: 44) {
                        VStack(alignment: .leading, spacing: 26) {
                            Text("Sahyadri hills and the journey beyond").font(.system(size: 29, weight: .semibold, design: .serif))
                            LazyVGrid(columns: [GridItem(.flexible()), GridItem(.flexible())], spacing: 24) {
                                ForEach(appModel.content.corePlaces) { place in
                                    Button {
                                        selectedPlaceID = place.id
                                        narrator.stop()
                                    } label: {
                                        VStack(spacing: 12) {
                                            Image(systemName: "mountain.2.fill").font(.system(size: 42)).foregroundStyle(TVTheme.gold)
                                            Text(place.name)
                                            Text(place.regionLabel).font(.system(size: 23)).lineLimit(2)
                                        }.frame(maxWidth: .infinity, minHeight: 138)
                                    }.buttonStyle(TVCardButtonStyle()).accessibilityIdentifier("tv-map-" + place.id)
                                }
                            }
                        }.frame(maxWidth: .infinity)
                        VStack(alignment: .leading, spacing: 24) {
                            if let place = selectedPlace {
                                Text(place.name).font(.system(size: 40, weight: .bold, design: .serif))
                                Text(place.primaryEvent).font(.system(size: 30)).fixedSize(horizontal: false, vertical: true)
                                Text(place.whyItMatters).font(.system(size: 28)).fixedSize(horizontal: false, vertical: true)
                                TVNarrationControls(id: "map-" + place.id, text: place.name + ". " + place.primaryEvent + ". " + place.whyItMatters)
                                if let scene = appModel.content.scenes.first(where: { $0.mapAnchors.contains(place.id) && appModel.lessonStore.isSceneUnlocked($0) }) {
                                    NavigationLink(value: TVRoute.lesson(scene.id)) { Text("Discover it in the story") }.buttonStyle(TVCardButtonStyle())
                                }
                            } else {
                                Image(systemName: "map.fill").font(.system(size: 100)).foregroundStyle(TVTheme.gold)
                                Text("Every place has a story. Choose one to explore.").font(.system(size: 32, design: .serif))
                            }
                        }.frame(width: 520, alignment: .leading).padding(30)
                            .background(TVTheme.panel, in: RoundedRectangle(cornerRadius: 26))
                    }
                }.padding(12)
            }
        }
        .onPlayPauseCommand { if appModel.parentSettings.narrationEnabled, selectedPlace != nil { narrator.togglePlayback() } }
        .onDisappear { narrator.stop() }
    }
}
