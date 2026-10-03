import SwiftUI

enum LearningAtlasPresentation {
    case explore, challenge
}

/// Bundled, north-up picture atlas. Geographic anchors share one uniform kilometre scale.
struct LearningAtlasView: View {
    @Environment(\.dynamicTypeSize) private var dynamicTypeSize
    @Environment(\.horizontalSizeClass) private var horizontalSizeClass
    let places: [Place]
    let presentation: LearningAtlasPresentation
    let foundPlaceID: String?
    let initialPlace: Place?
    let selectedPlaceID: String?
    let selectablePlaceIDs: Set<String>?
    let selectionEnabled: Bool
    let identifierPrefix: String
    let onSelect: (Place) -> Void

    @State private var region: LearningMapRegion
    @State private var closeUp = false
    #if os(tvOS)
    @FocusState private var focusedAtlasID: String?
    #endif

    init(places: [Place], presentation: LearningAtlasPresentation = .explore, foundPlaceID: String? = nil, initialPlace: Place? = nil, selectedPlaceID: String? = nil,
         selectablePlaceIDs: Set<String>? = nil, selectionEnabled: Bool = true,
         identifierPrefix: String = "atlas-place-", onSelect: @escaping (Place) -> Void) {
        self.places = places
        self.presentation = presentation
        self.foundPlaceID = foundPlaceID
        self.initialPlace = initialPlace
        self.selectedPlaceID = selectedPlaceID
        self.selectablePlaceIDs = selectablePlaceIDs
        self.selectionEnabled = selectionEnabled
        self.identifierPrefix = identifierPrefix
        self.onSelect = onSelect
        _region = State(initialValue: presentation == .challenge ? .sahyadri : (initialPlace.map { LearningAtlasContent.region(for: $0) } ?? .sahyadri))
        _closeUp = State(initialValue: presentation == .explore && ["place-torna", "place-rajgad"].contains(initialPlace?.id ?? ""))
    }

    private var regionPlaces: [Place] {
        places.filter { LearningAtlasContent.region(for: $0) == region }
    }

    private var visiblePlaces: [Place] {
        regionPlaces.filter { place in
            guard closeUp else { return true }
            return ["place-torna", "place-rajgad"].contains(place.id) || !LearningAtlasContent.hasValidCoordinate(for: place)
        }
    }

    private var answerPlaces: [Place] {
        presentation == .challenge ? places.sorted { $0.name == $1.name ? $0.id < $1.id : $0.name < $1.name } : visiblePlaces
    }

    private func select(_ place: Place) {
        guard presentation != .challenge || foundPlaceID == nil else { return }
        if presentation == .challenge {
            region = LearningAtlasContent.region(for: place)
            closeUp = ["place-torna", "place-rajgad"].contains(place.id)
        }
        onSelect(place)
    }

    private func relationship(for place: Place) -> String? {
        presentation == .explore || foundPlaceID == place.id ? LearningAtlasContent.relationship(for: place) : nil
    }

    private func selectionState(for place: Place) -> GBSelectionState {
        if foundPlaceID == place.id { return .found }
        return selectedPlaceID == place.id ? .selected : .ready
    }

    private func selectionLabel(for place: Place) -> String {
        [place.name, relationship(for: place)].compactMap { $0 }.joined(separator: ". ")
    }

    private var bounds: LearningMapBounds {
        closeUp && region == .sahyadri
            ? LearningMapBounds(minLatitude: 18.16, maxLatitude: 18.39, minLongitude: 73.51, maxLongitude: 73.81)
            : region.bounds
    }

    var body: some View {
        VStack(alignment: .leading, spacing: GBSpacing.small) {
            HStack(alignment: .top) {
                VStack(alignment: .leading, spacing: 4) {
                    Text(closeUp ? "Torna & Rajgad close-up" : region.title).gbTitle()
                    Text("North is up. Places keep their real relative distances.")
                        .font(.subheadline).foregroundStyle(GBColor.Content.secondary)
                }
                Spacer()
                indiaLocator.accessibilityLabel(region == .sahyadri ? "Sahyadri region in western India" : "Agra region in northern India")
            }
            ViewThatFits(in: .horizontal) {
                HStack { regionControls }
                VStack(alignment: .leading) { regionControls }
            }
            if region == .sahyadri {
                Button(closeUp ? "Whole region" : "Torna & Rajgad close-up") { closeUp.toggle() }
                    .font(.subheadline)
                    .buttonStyle(.bordered)
                    .frame(minHeight: controlHeight)
                    .accessibilityIdentifier("atlas-close-up")
                    #if os(tvOS)
                    .focused($focusedAtlasID, equals: "atlas-control-close-up")
                    #endif
            }
            GeometryReader { geometry in
                let projector = LearningMapProjector(bounds: bounds, size: geometry.size, padding: 38)
                ZStack(alignment: .topLeading) {
                    terrain(projector: projector)
                    ForEach(region.settlements) { town in
                        if contains(town.coordinate) {
                            townLabel(town).position(projector.point(for: town.coordinate))
                        }
                    }
                    ForEach(Array(visiblePlaces.enumerated()), id: \.element.id) { index, place in
                        if LearningAtlasContent.hasValidCoordinate(for: place), let latitude = place.latitude, let longitude = place.longitude {
                            if !closeUp && ["place-torna", "place-rajgad"].contains(place.id) {
                                mapMarker(place, number: index + 1)
                                    .position(projector.point(latitude: latitude, longitude: longitude))
                                    .accessibilityHidden(true)
                            } else {
                                Button { select(place) } label: {
                                    mapMarker(place, number: index + 1)
                                        .frame(width: pinTarget, height: pinTarget)
                                        .contentShape(Rectangle())
                                }
                                .buttonStyle(AtlasPictureButtonStyle())
                                .disabled(!canSelect(place))
                                .position(projector.point(latitude: latitude, longitude: longitude))
                                .accessibilityIdentifier("map-pin-" + place.id)
                                .accessibilityLabel(selectionLabel(for: place))
                                .accessibilityValue(presentation == .challenge ? selectionState(for: place).label : (selectedPlaceID == place.id ? "Selected" : "Not selected"))
                                #if os(tvOS)
                                .focused($focusedAtlasID, equals: place.id)
                                #endif
                            }
                        }
                    }
                    VStack(alignment: .leading, spacing: 8) {
                        Label("N", systemImage: "arrow.up").font(.headline.bold())
                            .foregroundStyle(Color(red: 0.15, green: 0.26, blue: 0.17))
                        Spacer()
                        scaleBar(projector: projector)
                    }.padding(12)
                }
                .clipped()
                .background(Color(red: 0.90, green: 0.92, blue: 0.79))
                .clipShape(RoundedRectangle(cornerRadius: GBRadius.card))
            }
            .frame(height: mapHeight)
            .accessibilityElement(children: .contain)
            #if os(tvOS)
            .focusSection()
            .onMoveCommand(perform: moveMapFocus)
            #endif
            Text("● Town or city   ▣ Story place · Pictures are illustrative; marker positions are to scale.")
                .font(.caption).foregroundStyle(GBColor.Content.secondary)
            if visiblePlaces.contains(where: { !LearningAtlasContent.hasValidCoordinate(for: $0) }) {
                Text("A map position is not available for every place. You can still choose its card below.")
                    .font(.caption).foregroundStyle(GBColor.Content.secondary)
            }
            if region == .sahyadri && !closeUp {
                Text("Torna and Rajgad are close neighbours. Open their close-up to see both clearly.")
                    .font(.subheadline)
            }
            // A second route to the same geographic choices provides large, non-overlapping
            // targets for children, VoiceOver and the TV remote without moving map anchors.
            answerLayout {
                ForEach(Array(answerPlaces.enumerated()), id: \.element.id) { index, place in
                    Button { select(place) } label: {
                        if presentation == .challenge {
                            GBSelectionCard(title: place.name, subtitle: relationship(for: place),
                                symbol: Self.emblem(for: place), state: selectionState(for: place), emphasis: .place)
                        } else {
                        HStack(spacing: 12) {
                            Text("\(index + 1)").font(.headline.bold()).frame(width: 30)
                            placePicture(place).frame(width: 46, height: 40)
                            VStack(alignment: .leading, spacing: 3) {
                                Text(place.name).gbHeadline()
                                Text(LearningAtlasContent.relationship(for: place)).font(.caption)
                            }
                            Spacer()
                            if selectedPlaceID == place.id { Image(systemName: "checkmark.circle.fill") }
                        }
                        .frame(maxWidth: .infinity, minHeight: choiceHeight, alignment: .leading)
                        .padding(.horizontal, 12)
                        }
                    }
                    .atlasAnswerStyle(presentation: presentation)
                    .tint(GBColor.Place.primary)
                    .disabled(!canSelect(place))
                    .accessibilityIdentifier(identifierPrefix + place.id)
                    .accessibilityLabel(selectionLabel(for: place))
                    .accessibilityValue(presentation == .challenge ? selectionState(for: place).label : (selectedPlaceID == place.id ? "Selected" : "Not selected"))
                    #if os(tvOS)
                    .focused($focusedAtlasID, equals: "atlas-card-" + place.id)
                    #endif
                }
            }
        }
    }

    private static func emblem(for place: Place) -> String {
        switch place.id {
        case "place-shivneri": "sunrise.fill"
        case "place-torna": "mountain.2.fill"
        case "place-rajgad": "building.columns.fill"
        case "place-pratapgad": "binoculars.fill"
        case "place-purandar": "flag.fill"
        case "place-raigad": "crown.fill"
        case "place-agra": "building.2.fill"
        default: GBIcon.fort
        }
    }

    // Keep all answer identities in the accessibility tree, even below the map.
    // A lazy grid can remove off-screen choices and break remote focus traversal.
    private var answerLayout: AnyLayout {
        if presentation == .challenge && !dynamicTypeSize.isAccessibilitySize {
            return AnyLayout(HStackLayout(alignment: .top, spacing: GBSpacing.small))
        }
        return AnyLayout(VStackLayout(spacing: GBSpacing.small))
    }

    private var mapHeight: CGFloat {
        #if os(tvOS)
        620
        #else
        closeUp ? 340 : horizontalSizeClass == .regular ? 450 : 360
        #endif
    }
    private var choiceHeight: CGFloat {
        #if os(tvOS)
        88
        #else
        64
        #endif
    }
    private var pinTarget: CGFloat {
        #if os(tvOS)
        88
        #else
        56
        #endif
    }

    @ViewBuilder private var regionControls: some View {
        ForEach(LearningMapRegion.allCases, id: \.self) { candidate in
            Button(candidate.title) { region = candidate; closeUp = false }
                .font(.subheadline)
                .buttonStyle(.bordered)
                .tint(region == candidate && !closeUp ? GBColor.Place.primary : GBColor.Content.secondary)
                .frame(minHeight: controlHeight)
                .accessibilityIdentifier("atlas-region-" + candidate.rawValue)
                #if os(tvOS)
                .focused($focusedAtlasID, equals: "atlas-control-" + candidate.rawValue)
                #endif
        }
    }

    #if os(tvOS)
    /// Native focus rays miss diagonally placed geographic pins. Route remote movement
    /// through the same north-up coordinates without moving anchors or submitting answers.
    private func moveMapFocus(_ direction: MoveCommandDirection) {
        let projector = LearningMapProjector(bounds: bounds, size: CGSize(width: 1000, height: mapHeight), padding: 38)
        let points: [(id: String, point: CGPoint)] = visiblePlaces.compactMap { place in
            guard canSelect(place), LearningAtlasContent.hasValidCoordinate(for: place),
                  closeUp || !["place-torna", "place-rajgad"].contains(place.id),
                  let latitude = place.latitude, let longitude = place.longitude else { return nil }
            return (place.id, projector.point(latitude: latitude, longitude: longitude))
        }
        guard let current = points.first(where: { $0.id == focusedAtlasID }) else { return }
        let candidates: [(id: String, score: CGFloat)] = points.compactMap { candidate in
            guard candidate.id != current.id else { return nil }
            let dx = candidate.point.x - current.point.x
            let dy = candidate.point.y - current.point.y
            let along: CGFloat
            let perpendicular: CGFloat
            switch direction {
            case .up: along = -dy; perpendicular = dx
            case .down: along = dy; perpendicular = dx
            case .left: along = -dx; perpendicular = dy
            case .right: along = dx; perpendicular = dy
            default: return nil
            }
            guard along > 0.5 else { return nil }
            return (candidate.id, along * along + perpendicular * perpendicular * 4)
        }
        if let next = candidates.min(by: { $0.score == $1.score ? $0.id < $1.id : $0.score < $1.score }) {
            focusedAtlasID = next.id
        } else if direction == .up {
            focusedAtlasID = region == .sahyadri ? "atlas-control-close-up" : "atlas-control-agra"
        } else if direction == .down, let first = answerPlaces.first(where: { canSelect($0) }) {
            focusedAtlasID = "atlas-card-" + first.id
        }
    }
    #endif
    private var controlHeight: CGFloat {
        #if os(tvOS)
        88
        #else
        44
        #endif
    }

    private func canSelect(_ place: Place) -> Bool {
        selectionEnabled && (selectablePlaceIDs?.contains(place.id) ?? true)
    }

    private func contains(_ coordinate: Coordinate) -> Bool {
        coordinate.latitude >= bounds.minLatitude && coordinate.latitude <= bounds.maxLatitude &&
        coordinate.longitude >= bounds.minLongitude && coordinate.longitude <= bounds.maxLongitude
    }

    private func mapMarker(_ place: Place, number: Int) -> some View {
        ZStack {
            placePicture(place).frame(width: pictureWidth, height: pictureWidth * 0.8)
                .offset(y: -pictureWidth * 0.65)
            Text("\(number)").font(.system(size: mapLabelSize, weight: .heavy))
                .foregroundStyle(.white).frame(width: markerDiameter, height: markerDiameter)
                .background(foundPlaceID == place.id ? GBColor.Accent.success : selectedPlaceID == place.id ? Color.orange : Color(red: 0.16, green: 0.32, blue: 0.21), in: Circle())
            if closeUp || !["place-torna", "place-rajgad"].contains(place.id) {
                let offset = fortLabelOffset(place)
                AtlasLeaderLine(offset: offset).stroke(Color.black.opacity(0.45), lineWidth: 1)
                    .frame(width: 1, height: 1)
                Text(place.name).font(.system(size: mapLabelSize, weight: .bold))
                    .foregroundStyle(Color.black.opacity(0.85))
                    .padding(.horizontal, 5).padding(.vertical, 2)
                    .background(Color.white.opacity(0.88), in: Capsule())
                    .fixedSize().offset(x: offset.width, y: offset.height)
            }
        }
        // The numbered circle, not the illustration or name, is the geographic anchor.
    }

    private var pictureWidth: CGFloat {
        #if os(tvOS)
        52
        #else
        30
        #endif
    }
    private var mapLabelSize: CGFloat {
        #if os(tvOS)
        20
        #else
        12
        #endif
    }
    private var markerDiameter: CGFloat {
        #if os(tvOS)
        30
        #else
        22
        #endif
    }

    @ViewBuilder private func placePicture(_ place: Place) -> some View {
        if place.id == "place-agra" { AtlasCourtPicture() } else { AtlasFortPicture() }
    }

    private func fortLabelOffset(_ place: Place) -> CGSize {
        let multiplier: CGFloat = pictureWidth > 30 ? 1.5 : 1
        let offset: CGSize
        switch place.id {
        case "place-raigad": offset = CGSize(width: -38, height: 20)
        case "place-pratapgad": offset = CGSize(width: -32, height: 25)
        case "place-purandar": offset = CGSize(width: 30, height: 26)
        default: offset = CGSize(width: 0, height: markerDiameter + 1)
        }
        return CGSize(width: offset.width * multiplier, height: offset.height * multiplier)
    }

    private func townLabel(_ town: MapReferenceSettlement) -> some View {
        let offset = townLabelOffset(town.id)
        return ZStack {
            AtlasLeaderLine(offset: offset).stroke(Color.black.opacity(0.4), lineWidth: 1)
                .frame(width: 1, height: 1)
            Circle().fill(Color(red: 0.27, green: 0.24, blue: 0.17)).frame(width: 5, height: 5)
            Text(town.name).font(.system(size: mapLabelSize, weight: .semibold)).foregroundStyle(Color.black.opacity(0.8))
                .padding(3).background(Color.white.opacity(0.75), in: RoundedRectangle(cornerRadius: 4))
                .fixedSize().offset(x: offset.width, y: offset.height)
        }
        .accessibilityElement(children: .ignore)
        .accessibilityLabel(town.name)
        .accessibilityAddTraits(.isStaticText)
    }

    private func townLabelOffset(_ id: String) -> CGSize {
        let multiplier: CGFloat = pictureWidth > 30 ? 1.5 : 1
        let offset: CGSize
        switch id {
        case "town-junnar": offset = CGSize(width: 44, height: -26)
        case "town-mahad": offset = CGSize(width: -34, height: 18)
        case "town-mahabaleshwar": offset = CGSize(width: 64, height: -12)
        case "town-wai": offset = CGSize(width: 30, height: 28)
        case "town-saswad": offset = CGSize(width: 36, height: -19)
        case "town-pune": offset = CGSize(width: 32, height: -18)
        case "town-mathura": offset = CGSize(width: 42, height: -18)
        default: offset = CGSize(width: -35, height: 23)
        }
        return CGSize(width: offset.width * multiplier, height: offset.height * multiplier)
    }

    private func scaleBar(projector: LearningMapProjector) -> some View {
        let kilometres: Double = closeUp ? 5 : region == .agra ? 10 : 25
        return VStack(alignment: .leading, spacing: 3) {
            Rectangle().fill(Color.black.opacity(0.7)).frame(width: projector.points(forKilometres: kilometres), height: 3)
            Text("\(Int(kilometres)) km").font(.caption.bold()).foregroundStyle(.black)
        }.padding(6).background(.white.opacity(0.8), in: RoundedRectangle(cornerRadius: 5))
    }

    private func terrain(projector: LearningMapProjector) -> some View {
        Canvas { context, size in
            func path(_ coordinates: [(Double, Double)]) -> Path {
                Path { path in
                    for (index, coordinate) in coordinates.enumerated() {
                        let point = projector.point(latitude: coordinate.0, longitude: coordinate.1)
                        if index == 0 { path.move(to: point) } else { path.addLine(to: point) }
                    }
                }
            }
            if region == .sahyadri {
                let ridge = [(19.6,73.72),(19.3,73.78),(19.0,73.67),(18.7,73.60),(18.4,73.57),(18.15,73.60),(17.9,73.65),(17.6,73.70)]
                context.stroke(path(ridge), with: .color(Color(red: 0.35, green: 0.53, blue: 0.30).opacity(0.27)), style: StrokeStyle(lineWidth: 90, lineCap: .round, lineJoin: .round))
                context.stroke(path(ridge), with: .color(Color(red: 0.29, green: 0.46, blue: 0.25).opacity(0.25)), style: StrokeStyle(lineWidth: 32, lineCap: .round, lineJoin: .round))
                // Decorative hill silhouettes follow the same georeferenced ridge.
                for coordinate in ridge {
                    let center = projector.point(latitude: coordinate.0, longitude: coordinate.1)
                    let hill = Path { path in
                        path.move(to: CGPoint(x: center.x - 18, y: center.y + 14))
                        path.addLine(to: CGPoint(x: center.x, y: center.y - 15))
                        path.addLine(to: CGPoint(x: center.x + 20, y: center.y + 14)); path.closeSubpath()
                    }
                    context.fill(hill, with: .color(Color(red: 0.40, green: 0.55, blue: 0.31).opacity(0.45)))
                }
            } else {
                let yamuna = [(27.8,77.72),(27.60,77.70),(27.48,77.80),(27.35,77.90),(27.24,78.02),(27.17,78.05),(27.06,78.02),(26.90,78.12)]
                context.stroke(path(yamuna), with: .color(Color(red: 0.24, green: 0.57, blue: 0.72).opacity(0.7)), style: StrokeStyle(lineWidth: 7, lineCap: .round, lineJoin: .round))
            }
            // A fine kilometre-independent border makes the picture read as a printed atlas.
            context.stroke(Path(roundedRect: CGRect(origin: .zero, size: size).insetBy(dx: 1, dy: 1), cornerRadius: 20), with: .color(.black.opacity(0.12)), lineWidth: 2)
        }.accessibilityHidden(true)
    }

    private var indiaLocator: some View {
        Canvas { context, size in
            // Small schematic locator, deliberately separate from the scaled regional atlas.
            let outline: [(CGFloat, CGFloat)] = [(0.27,0.08),(0.46,0.04),(0.55,0.17),(0.85,0.20),(0.74,0.34),(0.61,0.36),(0.57,0.58),(0.44,0.93),(0.31,0.67),(0.24,0.42),(0.12,0.26)]
            let shape = Path { path in
                for (index, point) in outline.enumerated() {
                    let vertex = CGPoint(x: point.0 * size.width, y: point.1 * size.height)
                    if index == 0 { path.move(to: vertex) } else { path.addLine(to: vertex) }
                }; path.closeSubpath()
            }
            context.fill(shape, with: .color(GBColor.Place.primary.opacity(0.22)))
            let point = CGPoint(x: size.width * (region == .sahyadri ? 0.30 : 0.45), y: size.height * (region == .sahyadri ? 0.56 : 0.29))
            context.fill(Path(ellipseIn: CGRect(x: point.x - 4, y: point.y - 4, width: 8, height: 8)), with: .color(.orange))
        }.frame(width: 64, height: 76)
            .overlay(alignment: .bottom) { Text("India").font(.system(size: 9, weight: .bold)) }
    }
}

private struct AtlasLeaderLine: Shape {
    let offset: CGSize
    func path(in rect: CGRect) -> Path {
        Path { path in
            path.move(to: CGPoint(x: rect.midX, y: rect.midY))
            path.addLine(to: CGPoint(x: rect.midX + offset.width, y: rect.midY + offset.height))
        }
    }
}

private struct AtlasPictureButtonStyle: ButtonStyle {
    @Environment(\.isFocused) private var isFocused
    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .background(Color.white.opacity(isFocused ? 0.65 : configuration.isPressed ? 0.35 : 0), in: RoundedRectangle(cornerRadius: 14))
            .overlay { RoundedRectangle(cornerRadius: 14).stroke(isFocused ? Color.orange : .clear, lineWidth: 4) }
            .shadow(color: isFocused ? Color.orange.opacity(0.4) : .clear, radius: 10)
    }
}

private struct AtlasCourtPicture: View {
    var body: some View {
        Canvas { context, size in
            let stone = Color(red: 0.73, green: 0.36, blue: 0.23)
            context.fill(Path(CGRect(x: size.width * 0.12, y: size.height * 0.38, width: size.width * 0.76, height: size.height * 0.54)), with: .color(stone))
            let dome = Path { path in
                path.move(to: CGPoint(x: size.width * 0.25, y: size.height * 0.39))
                path.addQuadCurve(to: CGPoint(x: size.width * 0.75, y: size.height * 0.39), control: CGPoint(x: size.width * 0.50, y: -size.height * 0.15))
                path.closeSubpath()
            }
            context.fill(dome, with: .color(Color(red: 0.93, green: 0.79, blue: 0.60)))
            for fraction in [0.22, 0.45, 0.68] {
                context.fill(Path(roundedRect: CGRect(x: size.width * fraction, y: size.height * 0.56, width: size.width * 0.12, height: size.height * 0.32), cornerRadius: 4), with: .color(Color(red: 0.30, green: 0.16, blue: 0.14)))
            }
            context.fill(Path(CGRect(x: size.width * 0.05, y: size.height * 0.91, width: size.width * 0.90, height: size.height * 0.08)), with: .color(Color(red: 0.46, green: 0.35, blue: 0.27)))
        }.accessibilityHidden(true)
    }
}

private struct AtlasFortPicture: View {
    var body: some View {
        Canvas { context, size in
            let hill = Path { path in
                path.move(to: CGPoint(x: 0, y: size.height)); path.addQuadCurve(to: CGPoint(x: size.width, y: size.height), control: CGPoint(x: size.width / 2, y: -size.height * 0.1)); path.closeSubpath()
            }
            context.fill(hill, with: .color(Color(red: 0.35, green: 0.48, blue: 0.24)))
            let wall = CGRect(x: size.width * 0.20, y: size.height * 0.26, width: size.width * 0.60, height: size.height * 0.42)
            context.fill(Path(wall), with: .color(Color(red: 0.57, green: 0.36, blue: 0.20)))
            for fraction in [0.20, 0.44, 0.68] {
                context.fill(Path(CGRect(x: size.width * fraction, y: size.height * 0.13, width: size.width * 0.12, height: size.height * 0.23)), with: .color(Color(red: 0.65, green: 0.44, blue: 0.25)))
            }
            context.fill(Path(roundedRect: CGRect(x: size.width * 0.43, y: size.height * 0.44, width: size.width * 0.14, height: size.height * 0.24), cornerRadius: 3), with: .color(Color(red: 0.23, green: 0.18, blue: 0.13)))
        }.accessibilityHidden(true)
    }
}


private extension View {
    @ViewBuilder func atlasAnswerStyle(presentation: LearningAtlasPresentation) -> some View {
        if presentation == .challenge {
            buttonStyle(.gbSelection(.place))
        } else {
            buttonStyle(.bordered)
        }
    }
}
