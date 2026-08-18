import SwiftUI

public struct LegacyHistoryView: View, CoachWorldChromedSurface {
    /// The shared management chrome (`04` section 6.1c). Nil renders on the bare stage, which is
    /// what this surface did before conversion.
    public var chrome: FloodlitChromeReadModel?
    public var onNavigateChrome: ((CoachWorldIntentID) -> Void)?


    public let model: LegacyHistoryReadModel
    public let focus: CoachWorldScreenID
    public let statusMessage: String?
    public let onClose: () -> Void
    public let onNavigate: (CoachWorldScreenID) -> Void


    public init(model: LegacyHistoryReadModel, focus: CoachWorldScreenID,
                statusMessage: String? = nil, onClose: @escaping () -> Void,
                onNavigate: @escaping (CoachWorldScreenID) -> Void) {
        self.model = model
        self.focus = focus
        self.statusMessage = statusMessage
        self.onClose = onClose
        self.onNavigate = onNavigate
    }

    private var palette: CoachWorldTokens.Palette {
        CoachWorldTokens.dark
    }

    public var body: some View {
        CoachWorldFloodlitStage(palette: palette, chrome: chrome, onNavigate: onNavigateChrome) {
            VStack(spacing: .zero) {
                topBar
                if let statusMessage {
                    Text(statusMessage).foregroundStyle(palette.stateWarning.color)
                        .frame(maxWidth: .infinity, alignment: .leading)
                        .padding(.horizontal, CoachWorldTokens.Space.md)
                }
                ScrollView {
                    VStack(alignment: .leading, spacing: CoachWorldTokens.Space.md) {
                        section
                    }
                    .padding(CoachWorldTokens.Space.md)
                }
            }
        }
    }

    private var topBar: some View {
        HStack(spacing: CoachWorldTokens.Space.sm) {
            Button("History", action: onClose)
                .frame(minWidth: CoachWorldTokens.Shape.minimumTarget,
                       minHeight: CoachWorldTokens.Shape.minimumTarget)
            VStack(alignment: .leading, spacing: .zero) {
                Text(focus.canonicalName).font(CoachWorldTokens.TypeRole.headline.weight(.black))
                Text(model.team.name + " · " + model.seasonLabel)
                    .font(CoachWorldTokens.TypeRole.caption)
                    .foregroundStyle(palette.contentSecondary.color)
            }
            Spacer()
            Menu("Views") {
                Button("Record book") { onNavigate(.recordBook) }
                Button("Rivalries") { onNavigate(.rivalries) }
                Button("Career line") { onNavigate(.careerLine) }
                Button("Coaching tree") { onNavigate(.coachingTree) }
                Button("Statistics & leaders") { onNavigate(.statisticsLeaders) }
                Button("Awards & honours") { onNavigate(.awardsHonours) }
                Button("Realignment event") { onNavigate(.realignmentEvent) }
            }
            .frame(minWidth: CoachWorldTokens.Shape.minimumTarget,
                   minHeight: CoachWorldTokens.Shape.minimumTarget)
        }
        .padding(.horizontal, CoachWorldTokens.Space.sm)
        .background(palette.raised.color)
    }

    @ViewBuilder private var section: some View {
        switch focus {
        case .recordBook: records
        case .rivalries: rivalries
        case .careerLine: careerLine
        case .coachingTree: coachingTree
        default: records
        }
    }

    private var records: some View {
        VStack(alignment: .leading, spacing: CoachWorldTokens.Space.xs) {
            Text("Durable records").font(CoachWorldTokens.TypeRole.headline.weight(.black))
            if model.records.isEmpty {
                CoachWorldSystemState(.empty("No team records recorded."), palette: palette)
            }
            ForEach(model.records) { row in
                HStack {
                    Text(row.title).frame(maxWidth: .infinity, alignment: .leading)
                    Text(String(row.value)).monospacedDigit().fontWeight(.bold)
                    Text(row.team.name + " vs " + row.opponent.name)
                        .font(CoachWorldTokens.TypeRole.caption)
                        .foregroundStyle(palette.contentSecondary.color)
                }
                .frame(minHeight: CoachWorldTokens.Shape.minimumTarget)
                .accessibilityElement(children: .combine)
                .accessibilityLabel("\(row.title), \(row.value), \(row.team.name) versus \(row.opponent.name), \(row.gameLabel)")
            }
        }
    }

    private var rivalries: some View {
        VStack(alignment: .leading, spacing: CoachWorldTokens.Space.xs) {
            Text("Rivalries").font(CoachWorldTokens.TypeRole.headline.weight(.black))
            if model.rivalries.isEmpty {
                CoachWorldSystemState(.empty("No rivalry recorded."), palette: palette)
            }
            ForEach(model.rivalries) { row in
                HStack {
                    VStack(alignment: .leading) {
                        Text(row.opponent.name).fontWeight(.bold)
                        Text(row.origin + " · " + String(row.meetings.count) + " notable meetings")
                            .font(CoachWorldTokens.TypeRole.caption)
                            .foregroundStyle(palette.contentSecondary.color)
                    }
                    Spacer()
                    Text(String(row.intensity)).monospacedDigit()
                }
                .frame(minHeight: CoachWorldTokens.Shape.minimumTarget)
                .accessibilityElement(children: .combine)
                .accessibilityLabel("Rivalry with \(row.opponent.name), \(row.origin), intensity \(row.intensity), \(row.meetings.count) notable meetings")
            }
        }
    }

    private var careerLine: some View {
        VStack(alignment: .leading, spacing: CoachWorldTokens.Space.xs) {
            Text("Career line").font(CoachWorldTokens.TypeRole.headline.weight(.black))
            if model.careerLine.isEmpty {
                CoachWorldSystemState(.empty("No recorded assignments."), palette: palette)
            }
            ForEach(model.careerLine) { row in
                HStack {
                    Text("Season \(row.season)").monospacedDigit().frame(width: 105, alignment: .leading)
                    Text(row.role).frame(maxWidth: .infinity, alignment: .leading)
                    Text(row.organisation.name).foregroundStyle(palette.contentSecondary.color)
                }
                .frame(minHeight: CoachWorldTokens.Shape.minimumTarget)
                .accessibilityElement(children: .combine)
                .accessibilityLabel("Season \(row.season), \(row.role), \(row.organisation.name)")
            }
        }
    }

    private var coachingTree: some View {
        VStack(alignment: .leading, spacing: CoachWorldTokens.Space.xs) {
            Text("Coaching tree").font(CoachWorldTokens.TypeRole.headline.weight(.black))
            if model.coachingTree.isEmpty {
                CoachWorldSystemState(.empty("No recorded coaching relationships."), palette: palette)
            }
            ForEach(model.coachingTree) { branch in
                VStack(alignment: .leading, spacing: .zero) {
                    Text(branch.mentorName).fontWeight(.bold)
                    ForEach(branch.disciples, id: \.self) { disciple in
                        Text("↳ " + disciple).font(CoachWorldTokens.TypeRole.caption)
                    }
                }
                .frame(maxWidth: .infinity, minHeight: CoachWorldTokens.Shape.minimumTarget, alignment: .leading)
                .accessibilityElement(children: .combine)
                .accessibilityLabel("Mentor \(branch.mentorName), \(branch.disciples.joined(separator: ", "))")
            }
        }
    }
}
