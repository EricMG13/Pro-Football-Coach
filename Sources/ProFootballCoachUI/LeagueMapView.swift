import SwiftUI

/// League Map, `04` section 8 family 41 — place, distance, regions and rivalry context.
///
/// Team colour appears at mark scale only, which is what `04` section 5's restraint rules permit: a
/// marker is a chip, not a fill, and it is resolved through `CoachWorldTeamIdentity` rather than by
/// reading a hex out of the read model, because that type is canon's sole resolution point for
/// generated colour and is where the legibility gates live. Territory takes no team tint at all —
/// the identity sheet that would price one has not landed, and until it does section 5 says a
/// territory surface uses the neutral map grammar. So regions are named, never washed.
///
/// The markers are positioned `Button`s rather than marks in a `Canvas`. A `Canvas` gives neither
/// hit-testing nor VoiceOver, so a map drawn in one needs 166 hand-computed hit rectangles and a
/// hand-built accessibility tree; positioned buttons give both by construction. The one `Canvas`
/// here draws the rivalry links, which are at most eight lines carrying nothing the detail rail
/// does not also state in words.
public struct LeagueMapView: View {
    public let model: LeagueMapReadModel
    public let statusMessage: String?
    public let onContinue: () -> Void
    public let onNavigate: (CoachWorldScreenID) -> Void
    public let onSelectTeam: (UUID) -> Void

    @Environment(\.dynamicTypeSize) private var dynamicTypeSize
    @State private var selectedPlaceID: String
    @State private var tier: String

    public init(
        model: LeagueMapReadModel,
        statusMessage: String? = nil,
        onContinue: @escaping () -> Void,
        onNavigate: @escaping (CoachWorldScreenID) -> Void,
        onSelectTeam: @escaping (UUID) -> Void = { _ in }
    ) {
        self.model = model
        self.statusMessage = statusMessage
        self.onContinue = onContinue
        self.onNavigate = onNavigate
        self.onSelectTeam = onSelectTeam
        let home = model.places.first(where: \.isControlled)
        _selectedPlaceID = State(
            initialValue: home?.stableID ?? model.places.first?.stableID ?? ""
        )
        // Opens on the tier the coach works in, so the first frame contains their own programme.
        _tier = State(initialValue: home?.tierLabel ?? LeagueMapReadModel.Tier.college)
    }

    private var palette: CoachWorldTokens.Palette {
        CoachWorldTokens.dark
    }

    public var body: some View {
        CoachWorldFloodlitStage(palette: palette) {
            if dynamicTypeSize.isAccessibilitySize {
                accessibleLayout
            } else {
                VStack(spacing: .zero) {
                    worldStrip
                    standardLayout
                }
            }
        }
        .onChange(of: tier) {
            // A selection that has just been filtered off the map would leave the rail describing
            // a place the player cannot see or reach.
            if !visiblePlaces.contains(where: { $0.stableID == selectedPlaceID }) {
                selectedPlaceID = visiblePlaces.first?.stableID ?? ""
            }
        }
    }

    // MARK: - Data

    private var tiers: [String] {
        [LeagueMapReadModel.Tier.college, LeagueMapReadModel.Tier.professional]
    }

    private var visiblePlaces: [LeagueMapReadModel.Place] {
        model.places.filter { $0.tierLabel == tier }
    }

    /// Draw order, so the two markers that must always be reachable are the two on top.
    ///
    /// Known ceiling: at the promise viewport the grid scales to about 0.43, so cities inside one
    /// region sit roughly 20 pt apart while the touch floor is 44 pt (`04` section 7). Targets in a
    /// dense cluster therefore overlap and the topmost wins. The upgrade path is pan and zoom, or a
    /// region filter beside the tier one; neither is built, and the rail's rival list plus the
    /// accessibility-size list are how a covered place is reached today.
    private var orderedPlaces: [LeagueMapReadModel.Place] {
        visiblePlaces.sorted { lhs, rhs in
            rank(lhs) < rank(rhs)
        }
    }

    private func rank(_ place: LeagueMapReadModel.Place) -> Int {
        if place.stableID == selectedPlaceID { return 2 }
        if place.isControlled { return 1 }
        return 0
    }

    private var selectedPlace: LeagueMapReadModel.Place? {
        model.places.first { $0.stableID == selectedPlaceID }
    }

    private var identity: CoachWorldTeamIdentity? {
        CoachWorldTeamIdentity(
            team: model.team,
            behind: palette.raised,
            inks: [palette.contentPrimary, palette.page]
        )
    }

    private var selectionColour: CoachWorldTokens.ColorValue {
        identity?.selectionRule(on: palette.work) ?? palette.collegeIdentity
    }

    private var worldContextLine: String {
        var line = "\(model.seasonLabel) · \(model.weekLabel) · \(model.recordLabel)"
        if let rank = model.rankLabel { line += " · \(rank)" }
        return line
    }

    // MARK: - World strip

    private var worldStrip: some View {
        HStack(spacing: CoachWorldTokens.Space.xs) {
            HStack(spacing: CoachWorldTokens.Space.xs) {
                uniformMark
                VStack(alignment: .leading, spacing: CoachWorldTokens.Space.xxs) {
                    Text(model.team.name.uppercased())
                        .font(CoachWorldTokens.TypeRole.headline.weight(.black))
                        .lineLimit(1)
                    Text(statusMessage ?? worldContextLine)
                        .font(CoachWorldTokens.TypeRole.caption)
                        .foregroundStyle((identity?.onField ?? palette.contentSecondary).color)
                        .lineLimit(1)
                }
            }
            .foregroundStyle(identity?.onField.color ?? palette.contentPrimary.color)
            .padding(.horizontal, CoachWorldTokens.Space.xs)
            .frame(maxHeight: .infinity)
            .background(identity?.field.color ?? palette.raised.color)
            .overlay(alignment: .trailing) {
                // Canon 6.1: a generated field below 3:1 against the surface behind it is spoken
                // by a boundary, because the colour alone cannot be relied on to separate them.
                if identity?.needsBoundary == true { verticalSeam }
            }
            .accessibilityElement(children: .combine)
            .accessibilityLabel("\(model.team.name), \(statusMessage ?? worldContextLine)")

            Divider().overlay(palette.contentQuiet.color)

            HStack(spacing: .zero) {
                route("Office", screen: .coachingHQ)
                route("Team", screen: .roster)
                route("Recruit", screen: .recruitingBoard)
                route("League", screen: .leagueMap, current: true)
                route("Table", screen: .standings)
                route("Schedule", screen: .schedule)
                route("Ranks", screen: .rankingsPlayoffPicture)
                route("Bracket", screen: .bracketPostseason)
                route("Career", screen: .careerHub)
                route("Search", screen: .worldSearch)
            }
            .frame(maxWidth: .infinity)

            Button(action: onContinue) {
                Label("Continue", systemImage: "forward.end.fill")
            }
            .buttonStyle(CoachWorldActionButtonStyle(role: .primary, palette: palette))
        }
        .padding(.horizontal, CoachWorldTokens.Space.sm)
        .frame(height: LeagueMapMetric.worldStripHeight)
        .background(palette.raised.color)
        .overlay(alignment: .bottom) { seam }
        .accessibilitySortPriority(50)
    }

    private var uniformMark: some View {
        Text(model.team.abbreviation)
            .font(CoachWorldTokens.TypeRole.caption.weight(.black))
            .foregroundStyle(markInk.color)
            .padding(.horizontal, CoachWorldTokens.Space.xxs)
            .frame(minWidth: LeagueMapMetric.markWidth, minHeight: LeagueMapMetric.markHeight)
            .background(
                (identity?.accent.color ?? palette.collegeIdentity.color),
                in: RoundedRectangle(cornerRadius: CoachWorldTokens.Shape.rowRadius)
            )
            .accessibilityHidden(true)
    }

    private var markInk: CoachWorldTokens.ColorValue {
        guard let accent = identity?.accent else { return palette.page }
        return accent.mostLegibleInk(from: [palette.page, palette.contentPrimary]) ?? palette.page
    }

    private func route(
        _ title: String,
        screen: CoachWorldScreenID,
        current: Bool = false
    ) -> some View {
        CoachWorldRouteButton(
            title: title,
            isCurrent: current,
            palette: palette,
            selection: selectionColour,
            action: { onNavigate(screen) }
        )
    }

    // MARK: - Standard layout

    private var standardLayout: some View {
        HStack(spacing: .zero) {
            mapSurface
                .frame(maxWidth: .infinity, maxHeight: .infinity)
                .accessibilitySortPriority(100)
            Divider().overlay(palette.contentQuiet.color)
            detailRail
                .frame(width: LeagueMapMetric.railWidth)
                .background(palette.work.color)
                .accessibilitySortPriority(80)
        }
    }

    private var mapSurface: some View {
        VStack(spacing: CoachWorldTokens.Space.xs) {
            tierControl
            if visiblePlaces.isEmpty {
                CoachWorldSystemState(
                    .empty("No places to show. Programmes appear here when a world is loaded."),
                    palette: palette
                )
            } else {
                GeometryReader { frame in
                    let layout = LeagueMapLayout(
                        bounds: frame.size,
                        gridWidth: model.gridWidth,
                        gridHeight: model.gridHeight
                    )
                    ZStack(alignment: .topLeading) {
                        rivalryLinks(layout)
                        ForEach(model.regions) { region in
                            regionLabel(region, layout: layout)
                        }
                        ForEach(orderedPlaces) { place in
                            marker(place, layout: layout)
                        }
                    }
                    .frame(width: frame.size.width, height: frame.size.height)
                }
                placeBrowser
            }
        }
        .padding(CoachWorldTokens.Space.sm)
    }

    /// The map is spatial context; this compact rail is the deterministic escape hatch for
    /// coincident coordinates. Every place remains a real button even when another marker occupies
    /// the same point, so the standard layout has the same reachability guarantee as the AX list.
    private var placeBrowser: some View {
        ScrollView(.horizontal, showsIndicators: false) {
            HStack(spacing: CoachWorldTokens.Space.xs) {
                ForEach(visiblePlaces) { place in
                    placeBrowserButton(place)
                }
            }
        }
        .frame(minHeight: CoachWorldTokens.Shape.minimumTarget)
        .accessibilityLabel("All \(tier) places")
    }

    private func placeNameLabel(_ place: LeagueMapReadModel.Place) -> some View {
        Text(place.team.name)
            .font(CoachWorldTokens.TypeRole.caption.weight(.bold))
            .lineLimit(1)
    }

    private func placeCityLabel(_ place: LeagueMapReadModel.Place) -> some View {
        Text(place.cityName)
            .font(CoachWorldTokens.TypeRole.caption)
            .foregroundStyle(palette.contentSecondary.color)
            .lineLimit(1)
    }

    private func placeBrowserButton(_ place: LeagueMapReadModel.Place) -> some View {
        let selected = place.stableID == selectedPlaceID
        return Button {
            selectedPlaceID = place.stableID
        } label: {
            VStack(alignment: .leading, spacing: CoachWorldTokens.Space.xxs) {
                placeNameLabel(place)
                placeCityLabel(place)
            }
            .frame(width: 132)
            .frame(minHeight: CoachWorldTokens.Shape.minimumTarget, alignment: .leading)
            .padding(.horizontal, CoachWorldTokens.Space.xs)
            .background(
                selected ? palette.raised.color : palette.work.color,
                in: RoundedRectangle(cornerRadius: CoachWorldTokens.Shape.rowRadius)
            )
        }
        .buttonStyle(.plain)
        .accessibilityLabel(placeAccessibilityLabel(place))
        .accessibilityAddTraits(selected ? .isSelected : [])
    }

    private var tierControl: some View {
        Picker("Tier", selection: $tier) {
            ForEach(tiers, id: \.self) { value in
                Text(value).tag(value)
            }
        }
        .pickerStyle(.segmented)
        .accessibilitySortPriority(40)
    }

    /// At most eight lines, from the selected place to its rivals.
    ///
    /// Hidden from VoiceOver because the rail speaks every rival by name, origin and intensity. The
    /// line adds direction across a fictional grid, which is not a fact a sentence can carry and
    /// not a datum lost when it is not spoken.
    private func rivalryLinks(_ layout: LeagueMapLayout) -> some View {
        let origin = selectedPlace
        let visible = Set(visiblePlaces.map(\.stableID))
        let targets = (origin?.rivals ?? []).compactMap { rival in
            visible.contains(rival.stableID)
                ? model.places.first { $0.stableID == rival.stableID }
                : nil
        }
        return Canvas { context, _ in
            guard let origin, visible.contains(origin.stableID) else { return }
            let start = layout.point(x: origin.x, y: origin.y)
            for target in targets {
                var path = Path()
                path.move(to: start)
                path.addLine(to: layout.point(x: target.x, y: target.y))
                context.stroke(
                    path,
                    with: .color(selectionColour.color.opacity(0.45)),
                    lineWidth: CoachWorldTokens.Shape.hairline
                )
            }
        }
        .accessibilityHidden(true)
    }

    /// Placed at the mean of the region's own cities.
    ///
    /// That is label placement, not a claim about an extent: regions have members and a generated
    /// centre in the engine, never a boundary, so an outline here would be a UI invention drawn as
    /// territory.
    private func regionLabel(
        _ region: LeagueMapReadModel.Region,
        layout: LeagueMapLayout
    ) -> some View {
        let members = visiblePlaces.filter { $0.regionID == region.stableID }
        return Text(region.name.uppercased())
            .font(CoachWorldTokens.TypeRole.caption.weight(.heavy))
            .foregroundStyle(palette.contentQuiet.color)
            .position(layout.centre(of: members))
            .opacity(members.isEmpty ? 0 : 1)
            .accessibilityHidden(true)
    }

    private func marker(
        _ place: LeagueMapReadModel.Place,
        layout: LeagueMapLayout
    ) -> some View {
        let isSelected = place.stableID == selectedPlaceID
        // Resolved through the identity type, never from the hex: `04` section 5 makes that the
        // sole resolution point, and it is what refuses team paint when the pair cannot be read.
        let mark = CoachWorldTeamIdentity(
            team: place.team,
            behind: palette.page,
            inks: [palette.contentPrimary, palette.page]
        )
        return Button(action: { selectedPlaceID = place.stableID }) {
            Circle()
                .fill((mark?.field ?? palette.contentSecondary).color)
                // Canon 6.1: every team fill carries a hairline boundary, because a generated
                // colour can land arbitrarily close to the surface behind it.
                .overlay {
                    Circle().stroke(
                        palette.page.color,
                        lineWidth: CoachWorldTokens.Shape.hairline
                    )
                }
                .frame(width: LeagueMapMetric.markerSize, height: LeagueMapMetric.markerSize)
                .overlay {
                    // Selection takes a boundary, never a fill (`04` section 5).
                    if isSelected {
                        Circle()
                            .stroke(selectionColour.color, lineWidth: LeagueMapMetric.selectedRing)
                            .frame(
                                width: LeagueMapMetric.selectedRingSize,
                                height: LeagueMapMetric.selectedRingSize
                            )
                    }
                }
                .overlay {
                    if place.isControlled {
                        Circle()
                            .stroke(
                                palette.contentPrimary.color,
                                lineWidth: CoachWorldTokens.Shape.hairline
                            )
                            .frame(
                                width: LeagueMapMetric.controlledRingSize,
                                height: LeagueMapMetric.controlledRingSize
                            )
                    }
                }
                .frame(
                    width: CoachWorldTokens.Shape.minimumTarget,
                    height: CoachWorldTokens.Shape.minimumTarget
                )
                .contentShape(Circle())
        }
        .buttonStyle(.plain)
        .position(layout.point(x: place.x, y: place.y))
        .accessibilityLabel(placeAccessibilityLabel(place))
        .accessibilityAddTraits(isSelected ? .isSelected : [])
    }

    // MARK: - Detail rail

    @ViewBuilder
    private var detailRail: some View {
        if let place = selectedPlace {
            ScrollView {
                VStack(alignment: .leading, spacing: CoachWorldTokens.Space.sm) {
                    VStack(alignment: .leading, spacing: CoachWorldTokens.Space.xxs) {
                        Text(place.team.name)
                            .font(CoachWorldTokens.TypeRole.title)
                        Text("\(place.cityName) · \(place.regionName)")
                            .font(CoachWorldTokens.TypeRole.body)
                            .foregroundStyle(palette.contentSecondary.color)
                    }
                    .accessibilityElement(children: .combine)

                    fact("Venue", place.venueName)
                    fact("Conference", place.conferenceName ?? "Independent")
                    fact("Tier", place.tierLabel)
                    fact("Prestige", "\(place.prestige)")
                    fact("Market", "\(place.marketSize)")
                    fact("Talent in region", talentDensityLabel(place))
                    Button("Open team profile") {
                        guard let id = UUID(uuidString: place.stableID) else { return }
                        onSelectTeam(id)
                    }
                    .frame(minWidth: CoachWorldTokens.Shape.minimumTarget,
                           minHeight: CoachWorldTokens.Shape.minimumTarget)
                    rivalSection(place)
                }
                .frame(maxWidth: .infinity, alignment: .leading)
                .padding(CoachWorldTokens.Space.sm)
            }
        } else {
            CoachWorldSystemState(
                .empty("No place selected. Choose a programme on the map to read its place."),
                palette: palette
            )
        }
    }

    private func fact(_ name: String, _ value: String) -> some View {
        HStack(alignment: .firstTextBaseline, spacing: CoachWorldTokens.Space.xs) {
            Text(name.uppercased())
                .font(CoachWorldTokens.TypeRole.caption.weight(.heavy))
                .foregroundStyle(palette.contentQuiet.color)
            Spacer(minLength: .zero)
            Text(value)
                .font(CoachWorldTokens.TypeRole.body.weight(.bold))
                .monospacedDigit()
                .multilineTextAlignment(.trailing)
                .lineLimit(dynamicTypeSize.isAccessibilitySize ? nil : 2)
        }
        .accessibilityElement(children: .combine)
        .accessibilityLabel("\(name), \(value)")
    }

    private func talentDensityLabel(_ place: LeagueMapReadModel.Place) -> String {
        model.regions.first { $0.stableID == place.regionID }
            .map { "\($0.talentDensity)" } ?? "Not recorded"
    }

    @ViewBuilder
    private func rivalSection(_ place: LeagueMapReadModel.Place) -> some View {
        Text("Rivals".uppercased())
            .font(CoachWorldTokens.TypeRole.caption.weight(.heavy))
            .foregroundStyle(palette.contentQuiet.color)
        if place.rivals.isEmpty {
            Text("No rivalry recorded")
                .font(CoachWorldTokens.TypeRole.body)
                .foregroundStyle(palette.contentSecondary.color)
        } else {
            ForEach(place.rivals) { rival in
                Button(action: { selectedPlaceID = rival.stableID }) {
                    HStack(spacing: CoachWorldTokens.Space.xs) {
                        VStack(alignment: .leading, spacing: CoachWorldTokens.Space.xxs) {
                            Text(rival.name)
                                .font(CoachWorldTokens.TypeRole.body.weight(.bold))
                                .lineLimit(dynamicTypeSize.isAccessibilitySize ? nil : 1)
                            Text(rival.originLabel)
                                .font(CoachWorldTokens.TypeRole.caption)
                                .foregroundStyle(palette.contentQuiet.color)
                        }
                        Spacer(minLength: .zero)
                        Text("\(rival.intensity)")
                            .font(CoachWorldTokens.TypeRole.body.weight(.bold))
                            .monospacedDigit()
                    }
                    .frame(maxWidth: .infinity, minHeight: CoachWorldTokens.Shape.minimumTarget)
                    .contentShape(Rectangle())
                }
                .buttonStyle(.plain)
                .accessibilityLabel(
                    "\(rival.name), \(rival.originLabel), intensity \(rival.intensity)"
                )
            }
        }
    }

    // MARK: - Accessibility-size layout

    /// At accessibility sizes the spatial rendering is replaced by the same places as a list
    /// grouped by region, which is the structure the map draws: the engine gives a region members
    /// and a centre, and it is that clustering the markers make visible. Every datum a marker
    /// carries — city, region, conference, tier, prestige, market, rivals — is in the rows, so the
    /// composition reflows rather than dropping anything. A 166-marker map in one accessibility
    /// column is not readable at any type size, which is why this is a reflow and not a scale.
    private var accessibleLayout: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: .zero) {
                worldStrip
                tierControl
                    .padding(CoachWorldTokens.Space.sm)
                ForEach(model.regions) { region in
                    let members = visiblePlaces.filter { $0.regionID == region.stableID }
                    if !members.isEmpty {
                        Text("\(region.name) · talent \(region.talentDensity)")
                            .font(CoachWorldTokens.TypeRole.headline)
                            .padding(CoachWorldTokens.Space.sm)
                        ForEach(members) { place in
                            accessiblePlaceRow(place)
                        }
                    }
                }
                if let place = selectedPlace {
                    Text("Rivals of \(place.team.name)")
                        .font(CoachWorldTokens.TypeRole.headline)
                        .padding(CoachWorldTokens.Space.sm)
                    VStack(alignment: .leading, spacing: CoachWorldTokens.Space.sm) {
                        rivalSection(place)
                    }
                    .padding(.horizontal, CoachWorldTokens.Space.sm)
                }
            }
        }
        .accessibilitySortPriority(100)
    }

    private func accessiblePlaceRow(_ place: LeagueMapReadModel.Place) -> some View {
        let isSelected = place.stableID == selectedPlaceID
        return Button(action: { selectedPlaceID = place.stableID }) {
            VStack(alignment: .leading, spacing: CoachWorldTokens.Space.xxs) {
                Text(place.team.name)
                    .font(CoachWorldTokens.TypeRole.body.weight(.bold))
                Text("\(place.cityName) · \(place.conferenceName ?? "Independent")")
                    .font(CoachWorldTokens.TypeRole.caption)
                    .foregroundStyle(palette.contentSecondary.color)
                Text("Prestige \(place.prestige) · market \(place.marketSize)")
                    .font(CoachWorldTokens.TypeRole.caption)
                    .foregroundStyle(palette.contentSecondary.color)
                    .monospacedDigit()
            }
            .frame(
                maxWidth: .infinity,
                minHeight: CoachWorldTokens.Shape.minimumTarget,
                alignment: .leading
            )
            .padding(CoachWorldTokens.Space.sm)
            .contentShape(Rectangle())
        }
        .buttonStyle(.plain)
        .overlay(alignment: .leading) {
            if isSelected {
                Rectangle()
                    .fill(selectionColour.color)
                    .frame(width: LeagueMapMetric.selectedRuleWidth)
                    .accessibilityHidden(true)
            }
        }
        .accessibilityLabel(placeAccessibilityLabel(place))
        .accessibilityAddTraits(isSelected ? .isSelected : [])
    }

    private func placeAccessibilityLabel(_ place: LeagueMapReadModel.Place) -> String {
        var parts = [place.team.name, place.cityName, place.regionName]
        parts.append(place.conferenceName ?? "Independent")
        parts.append("prestige \(place.prestige)")
        parts.append("market \(place.marketSize)")
        if place.isControlled { parts.append("your programme") }
        return parts.joined(separator: ", ")
    }

    // MARK: - Hairlines

    private var seam: some View {
        Rectangle()
            .fill(palette.contentQuiet.color.opacity(CoachWorldTokens.Depth.panelBorderOpacity))
            .frame(height: CoachWorldTokens.Shape.hairline)
            .accessibilityHidden(true)
    }

    private var verticalSeam: some View {
        Rectangle()
            .fill(palette.contentQuiet.color.opacity(CoachWorldTokens.Depth.panelBorderOpacity))
            .frame(width: CoachWorldTokens.Shape.hairline)
            .accessibilityHidden(true)
    }
}

/// Grid units to points, aspect preserved and centred.
///
/// Aspect is preserved because distance is a mechanic (D6) and stretching a 1000x700 grid to fill a
/// 2.17:1 landscape frame would misstate which programmes are near each other — the same reason the
/// engine keeps distance as an integer square. The leftover margin is the map's own empty space.
struct LeagueMapLayout {
    let scale: CGFloat
    let offsetX: CGFloat
    let offsetY: CGFloat

    init(bounds: CGSize, gridWidth: Int, gridHeight: Int) {
        // A zero or negative grid would divide by zero during the first layout pass, when
        // `GeometryReader` can legitimately report an empty size.
        let width = max(CGFloat(gridWidth), 1)
        let height = max(CGFloat(gridHeight), 1)
        scale = max(min(bounds.width / width, bounds.height / height), 0)
        offsetX = (bounds.width - width * scale) / 2
        offsetY = (bounds.height - height * scale) / 2
    }

    func point(x: Int, y: Int) -> CGPoint {
        CGPoint(x: offsetX + CGFloat(x) * scale, y: offsetY + CGFloat(y) * scale)
    }

    func centre(of places: [LeagueMapReadModel.Place]) -> CGPoint {
        guard !places.isEmpty else { return CGPoint(x: offsetX, y: offsetY) }
        let sumX = places.reduce(0) { $0 + $1.x }
        let sumY = places.reduce(0) { $0 + $1.y }
        return point(x: sumX / places.count, y: sumY / places.count)
    }
}

private enum LeagueMapMetric {
    static let worldStripHeight: CGFloat = 48
    static let markWidth: CGFloat = 34
    static let markHeight: CGFloat = 22
    static let railWidth: CGFloat = 260
    static let markerSize: CGFloat = 10
    static let selectedRing: CGFloat = 2
    static let selectedRingSize: CGFloat = 20
    static let controlledRingSize: CGFloat = 16
    static let selectedRuleWidth: CGFloat = 3
}
