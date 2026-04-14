import SwiftUI

struct PlacesHubView: View {
    @EnvironmentObject private var appModel: AppModel
    let places: [Place]

    var body: some View {
        List {
            Section {
                Text("Learn, pin, reveal, compare, and revisit the core forts.")
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
            }

            Section("Core places") {
                ForEach(places) { place in
                    NavigationLink {
                        PlaceDetailView(place: place, progress: appModel.lessonStore.progress(for: place))
                    } label: {
                        HStack(alignment: .top) {
                            VStack(alignment: .leading, spacing: 6) {
                                Text(place.name)
                                    .font(.headline)
                                Text(place.memoryHook)
                                    .font(.subheadline)
                                    .foregroundStyle(.secondary)
                                Text(place.primaryEvent)
                                    .font(.caption)
                                    .foregroundStyle(.secondary)
                            }
                            Spacer()
                            Text(appModel.lessonStore.progress(for: place).rawValue)
                                .font(.caption2.weight(.semibold))
                                .padding(.horizontal, 8)
                                .padding(.vertical, 6)
                                .background(progressColor(appModel.lessonStore.progress(for: place)).opacity(0.15), in: Capsule())
                                .foregroundStyle(progressColor(appModel.lessonStore.progress(for: place)))
                        }
                        .padding(.vertical, 4)
                    }
                }
            }
        }
        .navigationTitle("Places Hub")
    }

    private func progressColor(_ progress: PlaceProgress) -> Color {
        switch progress {
        case .locked: return .gray
        case .readyToLearn: return .orange
        case .reviewed: return .blue
        case .masteredLightly: return .green
        }
    }
}

struct PlaceDetailView: View {
    let place: Place
    let progress: PlaceProgress

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 20) {
                VStack(alignment: .leading, spacing: 6) {
                    Text(place.name)
                        .font(.largeTitle.bold())
                    Text(place.memoryHook)
                        .font(.title3)
                        .foregroundStyle(.secondary)
                }

                infoRow(title: "Primary event", value: place.primaryEvent)
                infoRow(title: "Why it matters", value: place.whyItMatters)
                infoRow(title: "Region", value: place.regionLabel)
                infoRow(title: "Educational pin", value: String(format: "%.4f, %.4f", place.latitude, place.longitude))
                infoRow(title: "Current progress", value: progress.rawValue)

                VStack(alignment: .leading, spacing: 10) {
                    Text("Pin challenge loop")
                        .font(.headline)
                    Label("Tap near the map region", systemImage: "1.circle")
                    Label("Snap to the nearest candidate fort", systemImage: "2.circle")
                    Label("Confirm or retry with a gentle hint", systemImage: "3.circle")
                    Label("Reveal the true place and compare the guess", systemImage: "4.circle")
                }
            }
            .padding()
        }
        .navigationTitle(place.name)
#if os(iOS)
        .navigationBarTitleDisplayMode(.inline)
#endif
    }

    @ViewBuilder
    private func infoRow(title: String, value: String) -> some View {
        VStack(alignment: .leading, spacing: 8) {
            Text(title)
                .font(.headline)
            Text(value)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding()
        .background(.thinMaterial, in: RoundedRectangle(cornerRadius: 16, style: .continuous))
    }
}
