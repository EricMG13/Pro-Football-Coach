import SwiftUI

public struct CoachingHQView: View {
    public let model: CoachingHQReadModel
    public let statusMessage: String?
    public let onCommit: (CoachWorldIntentID) -> Void
    public let onInspect: () -> Void
    public let onDelegate: () -> Void
    public let onContinue: () -> Void
    public let onOpenCorrespondence: (String) -> Void
    public let onNavigate: (CoachWorldScreenID) -> Void

    @Environment(\.colorScheme) private var colorScheme
    @Environment(\.dynamicTypeSize) private var dynamicTypeSize
    @ScaledMetric(relativeTo: .body) private var deskGap = CoachWorldTokens.Space.xs
    @State private var selectedChoiceID: CoachWorldIntentID?
    @State private var showsEvidence = false

    public init(
        model: CoachingHQReadModel,
        statusMessage: String? = nil,
        onCommit: @escaping (CoachWorldIntentID) -> Void,
        onInspect: @escaping () -> Void,
        onDelegate: @escaping () -> Void,
        onContinue: @escaping () -> Void,
        onOpenCorrespondence: @escaping (String) -> Void,
        onNavigate: @escaping (CoachWorldScreenID) -> Void
    ) {
        self.model = model
        self.statusMessage = statusMessage
        self.onCommit = onCommit
        self.onInspect = onInspect
        self.onDelegate = onDelegate
        self.onContinue = onContinue
        self.onOpenCorrespondence = onOpenCorrespondence
        self.onNavigate = onNavigate
        _selectedChoiceID = State(initialValue: nil)
    }

    private var palette: CoachWorldTokens.Palette {
        colorScheme == .dark ? CoachWorldTokens.dark : CoachWorldTokens.light
    }

    public var body: some View {
        VStack(spacing: .zero) {
            if dynamicTypeSize.isAccessibilitySize {
                accessibleLayout
            } else {
                worldStrip
                standardLayout
            }
        }
        .foregroundStyle(palette.contentPrimary.color)
        .background(palette.page.color.ignoresSafeArea())
        .sheet(isPresented: $showsEvidence) {
            evidenceSheet
        }
    }

    private var worldStrip: some View {
        Group {
            if dynamicTypeSize.isAccessibilitySize {
                VStack(spacing: CoachWorldTokens.Space.xs) {
                    VStack(alignment: .leading, spacing: .zero) {
                        Text(model.team.name.uppercased())
                            .font(CoachWorldTokens.TypeRole.headline.weight(.black))
                        Text(accessibleWorldContextLine)
                            .font(CoachWorldTokens.TypeRole.caption)
                            .foregroundStyle(palette.contentSecondary.color)
                    }
                    .accessibilityElement(children: .combine)
                    .accessibilityLabel("\(model.team.name), \(worldContextLine)")
                    worldMenu.frame(maxWidth: .infinity, alignment: .leading)
                    continueButton.frame(maxWidth: .infinity)
                }
            } else {
                HStack(spacing: CoachWorldTokens.Space.sm) {
                    VStack(alignment: .leading, spacing: CoachWorldTokens.Space.xxs) {
                        Text(model.team.name.uppercased())
                            .font(CoachWorldTokens.TypeRole.headline.weight(.black))
                            .lineLimit(1)
                        Text(worldContextLine)
                            .font(CoachWorldTokens.TypeRole.caption)
                            .foregroundStyle(palette.contentSecondary.color)
                    }
                    .accessibilityElement(children: .combine)
                    .accessibilityLabel("\(model.team.name), \(worldContextLine)")

                    Divider().overlay(palette.contentQuiet.color)
                    HStack(spacing: .zero) {
                        route("Office", screen: .coachingHQ, current: true)
                        route("Team", screen: .roster)
                        route("Recruit", screen: .recruitingBoard)
                        route("League", screen: .leagueMap)
                        route("Career", screen: .careerHub)
                    }
                    .frame(maxWidth: .infinity)
                    continueButton
                }
            }
        }
        .padding(.horizontal, CoachWorldTokens.Space.md)
        .padding(.vertical, dynamicTypeSize.isAccessibilitySize ? CoachWorldTokens.Space.xs : .zero)
        .frame(height: dynamicTypeSize.isAccessibilitySize ? nil : HQMetric.worldStripHeight)
        .background(palette.raised.color)
        .overlay(alignment: .bottom) { seam }
        .accessibilitySortPriority(50)
    }

    private var worldMenu: some View {
        Menu("World") {
            Button("Office") { onNavigate(.coachingHQ) }
            Button("Team") { onNavigate(.roster) }
            Button("Recruit") { onNavigate(.recruitingBoard) }
            Button("League") { onNavigate(.leagueMap) }
            Button("Career") { onNavigate(.careerHub) }
        }
        .frame(minWidth: CoachWorldTokens.Shape.minimumTarget,
               minHeight: CoachWorldTokens.Shape.minimumTarget)
    }

    private var continueButton: some View {
        let available = mandatoryCount == 0 && model.decision == nil
        return Button(action: onContinue) {
            Label("Continue · \(mandatoryCount) due", systemImage: "forward.end.fill")
        }
            .buttonStyle(CoachWorldActionButtonStyle(
                role: available ? .live : .secondary,
                palette: palette
            ))
            .disabled(!available)
    }

    private func route(_ title: String, screen: CoachWorldScreenID, current: Bool = false) -> some View {
        CoachWorldRouteButton(
            title: title,
            screen: screen,
            isCurrent: current,
            palette: palette,
            action: { onNavigate(screen) }
        )
    }

    private var standardLayout: some View {
        HStack(spacing: deskGap) {
            identityRail.frame(width: 190)
            decisionFloor.frame(maxWidth: .infinity)
            deskWire.frame(width: 220)
        }
        .padding(.horizontal, CoachWorldTokens.Space.xs)
    }

    private var accessibleLayout: some View {
        ScrollView {
            VStack(spacing: deskGap) {
                decisionFloor
                if let decision = model.decision {
                    decisionActions(decision)
                        .padding(.horizontal, CoachWorldTokens.Space.sm)
                        .background(palette.work.color)
                        .overlay(alignment: .top) { seam }
                }
                worldStrip
                HStack(alignment: .top, spacing: deskGap) {
                    identityRail
                    deskWire
                }
            }
            .padding(CoachWorldTokens.Space.sm)
        }
    }

    private var identityRail: some View {
        VStack(alignment: .leading, spacing: CoachWorldTokens.Space.sm) {
            Text("COACH'S OFFICE · WEEK")
                .font(CoachWorldTokens.TypeRole.caption.weight(.heavy))
                .foregroundStyle(palette.collegeIdentity.color)
            Text("Build Saturday")
                .font(CoachWorldTokens.TypeRole.headline.weight(.black))
                .lineLimit(2)
            Text(model.week.weekLabel.uppercased())
                .font(CoachWorldTokens.TypeRole.title.weight(.black))
                .monospacedDigit()
            if let obligation = model.obligations.first {
                Text(obligation.consequence)
                    .font(CoachWorldTokens.TypeRole.callout)
                    .foregroundStyle(palette.contentSecondary.color)
                    .lineLimit(3)
                    .fixedSize(horizontal: false, vertical: true)
            }
            seam
            if let recommendation = model.staffRecommendation {
                HStack(alignment: .top, spacing: CoachWorldTokens.Space.xs) {
                    CoachWorldBlankPhotoPlate(
                        name: recommendation.staff.name,
                        palette: palette,
                        width: 48,
                        height: 54
                    )
                    VStack(alignment: .leading, spacing: CoachWorldTokens.Space.xxs) {
                        Text(recommendation.staff.name).font(.headline)
                            .lineLimit(2)
                        Text(recommendation.staff.role)
                            .font(.caption)
                            .foregroundStyle(palette.contentSecondary.color)
                            .lineLimit(2)
                            .fixedSize(horizontal: false, vertical: true)
                    }
                }
            }
            Spacer(minLength: 0)
        }
        .padding(CoachWorldTokens.Space.sm)
        .frame(maxWidth: .infinity, minHeight: 170, alignment: .topLeading)
        .coachWorldDeskSurface(
            fill: palette.collegeIdentity.color.opacity(0.10),
            border: palette.contentQuiet.color.opacity(0.45)
        )
        .accessibilitySortPriority(40)
    }

    private var decisionFloor: some View {
        VStack(spacing: .zero) {
            weekPlan
            if let decision = model.decision {
                decisionSurface(decision)
            } else {
                noDecision
            }
        }
        .coachWorldDeskSurface(
            fill: palette.work.color,
            border: palette.contentQuiet.color.opacity(0.45)
        )
        .accessibilitySortPriority(100)
    }

    private var weekPlan: some View {
        Group {
            if dynamicTypeSize.isAccessibilitySize {
                VStack(alignment: .leading, spacing: CoachWorldTokens.Space.xxs) {
                    Text(accessibleCurrentDayLabel)
                        .foregroundStyle(palette.page.color)
                        .padding(.horizontal, CoachWorldTokens.Space.sm)
                        .background(palette.collegeIdentity.color)
                    Text(model.week.nextDeadline)
                        .foregroundStyle(palette.contentSecondary.color)
                }
                .font(CoachWorldTokens.TypeRole.body.weight(.bold))
                .frame(maxWidth: .infinity, minHeight: CoachWorldTokens.Shape.minimumTarget,
                       alignment: .leading)
            } else {
                HStack(spacing: .zero) {
                    ForEach(model.weekPlan, id: \.stableID) { day in
                        Text("\(day.dayLabel)\n\(day.assignment)")
                            .multilineTextAlignment(.center)
                            .font(CoachWorldTokens.TypeRole.caption.weight(.bold))
                            .frame(maxWidth: .infinity,
                                   minHeight: CoachWorldTokens.Shape.minimumTarget)
                            .background(day.isCurrent ? palette.collegeIdentity.color : Color.clear)
                            .foregroundStyle(
                                day.isCurrent ? palette.page.color : palette.contentPrimary.color
                            )
                            .accessibilityLabel("\(day.dayLabel), \(day.assignment)")
                            .accessibilityAddTraits(day.isCurrent ? .isSelected : [])
                            .overlay(alignment: .trailing) { verticalSeam }
                    }
                }
            }
        }
        .overlay(alignment: .bottom) { seam }
    }

    private func decisionSurface(_ decision: CoachingHQReadModel.Decision) -> some View {
        VStack(alignment: .leading, spacing: CoachWorldTokens.Space.xs) {
            Group {
                if dynamicTypeSize.isAccessibilitySize {
                    VStack(alignment: .leading, spacing: CoachWorldTokens.Space.xxs) {
                        HStack(alignment: .firstTextBaseline) {
                            Text("DUE · \(decision.deadline.uppercased())")
                            Spacer()
                            Text("\(unallocatedTimeLabel) unallocated")
                        }
                        .font(CoachWorldTokens.TypeRole.caption.weight(.heavy))
                        .foregroundStyle(palette.collegeIdentity.color)
                        Text(decision.title)
                            .font(CoachWorldTokens.TypeRole.headline.weight(.bold))
                            .fixedSize(horizontal: false, vertical: true)
                        decisionEvidence(decision)
                    }
                } else {
                    HStack(alignment: .top) {
                        VStack(alignment: .leading, spacing: CoachWorldTokens.Space.xxs) {
                            Text("DUE · \(decision.deadline.uppercased())")
                                .font(CoachWorldTokens.TypeRole.caption.weight(.heavy))
                                .foregroundStyle(palette.collegeIdentity.color)
                                .lineLimit(1)
                            Text(decision.title)
                                .font(CoachWorldTokens.TypeRole.headline.weight(.bold))
                                .lineLimit(2)
                                .fixedSize(horizontal: false, vertical: true)
                            decisionEvidence(decision)
                        }
                        Spacer()
                        VStack(alignment: .trailing, spacing: CoachWorldTokens.Space.xxs) {
                            Text(unallocatedTimeLabel)
                                .font(CoachWorldTokens.TypeRole.headline.weight(.black))
                            Text("UNALLOCATED").font(CoachWorldTokens.TypeRole.caption.weight(.heavy))
                        }
                        .foregroundStyle(palette.collegeIdentity.color)
                        .frame(width: 104, alignment: .trailing)
                        .accessibilityLabel("\(unallocatedTimeLabel) unallocated")
                    }
                }
            }

            VStack(spacing: CoachWorldTokens.Space.xs) {
                ForEach(decision.choices, id: \.intentID) { choice in
                    choiceButton(choice)
                }
            }

            if !dynamicTypeSize.isAccessibilitySize {
                decisionActions(decision)
            }
        }
        .padding(CoachWorldTokens.Space.sm)
    }

    @ViewBuilder
    private func decisionEvidence(_ decision: CoachingHQReadModel.Decision) -> some View {
        if let evidence = decision.evidence.first {
            Text(evidence)
                .font(CoachWorldTokens.TypeRole.callout)
                .foregroundStyle(palette.contentSecondary.color)
                .lineLimit(2)
        }
        if let recommendation = model.staffRecommendation {
            Text("\(recommendation.staff.name): \(recommendation.verdict) · \(recommendation.confidence) confidence")
                .font(CoachWorldTokens.TypeRole.caption.weight(.semibold))
                .foregroundStyle(palette.contentSecondary.color)
                .lineLimit(2)
        }
    }

    private func decisionActions(_ decision: CoachingHQReadModel.Decision) -> some View {
        Group {
            if dynamicTypeSize.isAccessibilitySize {
                VStack(alignment: .leading, spacing: CoachWorldTokens.Space.xs) {
                    selectionReceiptView(in: decision)
                    filmButton.frame(maxWidth: .infinity)
                    delegateButton.frame(maxWidth: .infinity)
                    commitButton.frame(maxWidth: .infinity)
                }
            } else {
                HStack(spacing: CoachWorldTokens.Space.xxs) {
                    selectionReceiptView(in: decision)
                    filmButton
                    delegateButton
                    commitButton
                }
            }
        }
        .frame(minHeight: CoachWorldTokens.Shape.minimumTarget)
    }

    private func selectionReceiptView(in decision: CoachingHQReadModel.Decision) -> some View {
        Text(selectionReceipt(in: decision))
            .font(CoachWorldTokens.TypeRole.caption)
            .foregroundStyle(palette.contentSecondary.color)
            .lineLimit(2)
            .frame(maxWidth: .infinity, minHeight: CoachWorldTokens.Shape.minimumTarget,
                   alignment: .leading)
    }

    private var filmButton: some View {
        Button {
            onInspect()
            showsEvidence = true
        } label: {
            Image(systemName: "film")
                .frame(minWidth: CoachWorldTokens.Shape.minimumTarget,
                       minHeight: CoachWorldTokens.Shape.minimumTarget)
        }
        .accessibilityLabel("Inspect film")
        .buttonStyle(CoachWorldActionButtonStyle(role: .secondary, palette: palette))
    }

    private var delegateButton: some View {
        Button(action: onDelegate) {
            Image(systemName: "person.2")
                .frame(minWidth: CoachWorldTokens.Shape.minimumTarget,
                       minHeight: CoachWorldTokens.Shape.minimumTarget)
        }
            .accessibilityLabel("Delegate")
            .buttonStyle(CoachWorldActionButtonStyle(role: .secondary, palette: palette))
    }

    private var commitButton: some View {
        Button {
            if let selectedChoiceID { onCommit(selectedChoiceID) }
        } label: {
            Label("Set work", systemImage: "checkmark")
        }
        .buttonStyle(CoachWorldActionButtonStyle(role: .primary, palette: palette))
        .layoutPriority(1)
        .disabled(selectedChoiceID == nil)
    }

    private func choiceButton(_ choice: CoachWorldActionChoice) -> some View {
        let selected = selectedChoiceID == choice.intentID
        return Button {
            selectedChoiceID = choice.intentID
        } label: {
            HStack(alignment: .firstTextBaseline, spacing: CoachWorldTokens.Space.sm) {
                Image(systemName: selected ? "record.circle.fill" : "circle")
                    .accessibilityHidden(true)
                VStack(alignment: .leading, spacing: CoachWorldTokens.Space.xxs) {
                    HStack {
                        Text(choice.title).font(.headline)
                        Spacer()
                        Text(choice.cost).font(.caption.weight(.bold))
                    }
                    Text(choice.consequence)
                        .font(CoachWorldTokens.TypeRole.callout)
                        .foregroundStyle(palette.contentSecondary.color)
                }
            }
            .padding(.horizontal, CoachWorldTokens.Space.xs)
            .frame(maxWidth: .infinity, minHeight: 54, alignment: .leading)
            .background(
                selected
                    ? palette.collegeIdentity.color.opacity(0.14)
                    : palette.raised.color.opacity(0.5)
            )
            .overlay {
                RoundedRectangle(cornerRadius: CoachWorldTokens.Shape.rowRadius)
                    .stroke(
                        selected
                            ? palette.collegeIdentity.color
                            : palette.contentQuiet.color.opacity(0.65),
                        lineWidth: CoachWorldTokens.Shape.hairline
                    )
            }
            .clipShape(RoundedRectangle(cornerRadius: CoachWorldTokens.Shape.rowRadius))
        }
        .buttonStyle(.plain)
        .disabled(!choice.isAvailable)
        .accessibilityLabel("\(choice.title). Cost: \(choice.cost). Consequence: \(choice.consequence)")
        .accessibilityAddTraits(selected ? .isSelected : [])
    }

    private var deskWire: some View {
        VStack(alignment: .leading, spacing: .zero) {
            HStack {
                Text("YOUR DESK").font(.headline.weight(.black))
                Spacer()
                Text("\(mandatoryCount) DUE")
                    .font(.caption.weight(.heavy))
                    .foregroundStyle(palette.stateWarning.color)
            }
            .padding(.horizontal, CoachWorldTokens.Space.sm)
            .frame(minHeight: CoachWorldTokens.Shape.minimumTarget)
            .overlay(alignment: .bottom) { seam }

            ForEach(model.correspondence, id: \.stableID) { item in
                Button { onOpenCorrespondence(item.stableID) } label: {
                    VStack(alignment: .leading, spacing: CoachWorldTokens.Space.xxs) {
                        Text("\(item.received) · \(item.isUnread ? "ANSWER" : "READ")")
                            .font(.caption.weight(.heavy))
                            .foregroundStyle(palette.collegeIdentity.color)
                        Text(item.subject).font(.callout.weight(.semibold))
                        Text(item.sender.name)
                            .font(.caption)
                            .foregroundStyle(palette.contentSecondary.color)
                    }
                    .frame(maxWidth: .infinity, minHeight: 62, alignment: .leading)
                    .padding(.horizontal, CoachWorldTokens.Space.sm)
                }
                .buttonStyle(.plain)
                .overlay(alignment: .bottom) { seam }
            }

            if let opponent = model.opponent {
                VStack(alignment: .leading, spacing: CoachWorldTokens.Space.xs) {
                    Text("SATURDAY · OPPONENT").font(.caption.weight(.heavy))
                    Text(opponent.name).font(.headline)
                    Text(model.venue?.name ?? "Venue not set")
                        .font(.caption)
                        .foregroundStyle(palette.contentSecondary.color)
                }
                .padding(CoachWorldTokens.Space.sm)
            }
            Spacer(minLength: 0)
        }
        .frame(maxWidth: .infinity, minHeight: 170, alignment: .top)
        .coachWorldDeskSurface(
            fill: palette.raised.color.opacity(0.45),
            border: palette.contentQuiet.color.opacity(0.45)
        )
        .accessibilitySortPriority(30)
    }

    private var noDecision: some View {
        ContentUnavailableView("No mandatory work", systemImage: "checkmark.circle",
                               description: Text(statusMessage ?? model.week.nextDeadline))
            .frame(maxWidth: .infinity, maxHeight: .infinity)
    }

    private var evidenceSheet: some View {
        NavigationStack {
            List {
                if let recommendation = model.staffRecommendation {
                    Section("Staff verdict") {
                        Text(recommendation.verdict).font(.headline)
                        Text(recommendation.reason)
                        Text("Confidence: \(recommendation.confidence)")
                    }
                }
                Section("Evidence") {
                    ForEach(model.decision?.evidence ?? [], id: \.self, content: Text.init)
                }
            }
            .navigationTitle("Opponent film")
            .toolbar { Button("Done") { showsEvidence = false } }
        }
    }

    private var mandatoryCount: Int {
        model.obligations.filter(\.isMandatory).count
    }

    private func selectionReceipt(in decision: CoachingHQReadModel.Decision) -> String {
        if let statusMessage { return statusMessage }
        guard let selectedChoiceID,
              let choice = decision.choices.first(where: { $0.intentID == selectedChoiceID })
        else { return "Choose · unsaved" }
        let shortTitle = choice.title.split(separator: "·").first.map(String.init) ?? choice.title
        return "\(shortTitle) · \(choice.cost) · not saved"
    }

    private var seam: some View {
        Rectangle()
            .fill(palette.contentQuiet.color.opacity(0.45))
            .frame(height: CoachWorldTokens.Shape.hairline)
    }

    private var worldContextLine: String {
        [model.coach.name, model.week.seasonLabel, model.week.weekLabel,
         model.recordLabel, model.rankLabel]
            .compactMap { $0 }
            .joined(separator: " · ")
    }

    private var accessibleWorldContextLine: String {
        [model.week.weekLabel, model.recordLabel, model.rankLabel]
            .compactMap { $0 }
            .joined(separator: " · ")
    }

    private var accessibleCurrentDayLabel: String {
        guard let current = model.weekPlan.first(where: \.isCurrent) else {
            return model.week.currentDay.uppercased()
        }
        return "\(current.dayLabel.uppercased()) · \(current.assignment.uppercased())"
    }

    private var unallocatedTimeLabel: String {
        let minutes = max(model.unallocatedPracticeMinutes, 0)
        let hours = minutes / 60
        let remainder = minutes % 60
        if remainder == 0 { return "\(hours)h" }
        if hours == 0 { return "\(remainder)m" }
        return "\(hours)h \(remainder)m"
    }

    private var verticalSeam: some View {
        Rectangle()
            .fill(palette.contentQuiet.color.opacity(0.45))
            .frame(width: CoachWorldTokens.Shape.hairline)
    }
}

private enum HQMetric {
    static let worldStripHeight: CGFloat = 52
}
