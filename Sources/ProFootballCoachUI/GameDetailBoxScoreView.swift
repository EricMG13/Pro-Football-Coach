import SwiftUI

/// Detailed game/box-score family backed by the immutable post-game evidence projection.
public struct GameDetailBoxScoreView: View {
    public let model: AftermathReadModel
    public let onClose: () -> Void
    @Environment(\.colorScheme) private var colorScheme
    @Environment(\.dynamicTypeSize) private var dynamicTypeSize

    public init(model: AftermathReadModel, onClose: @escaping () -> Void) {
        self.model = model
        self.onClose = onClose
    }

    public var body: some View {
        let palette = colorScheme == .dark ? CoachWorldTokens.dark : CoachWorldTokens.light
        if dynamicTypeSize.isAccessibilitySize {
            content(palette: palette).accessibilitySortPriority(100)
        } else {
            content(palette: palette).accessibilitySortPriority(100)
        }
    }

    private func content(palette: CoachWorldTokens.Palette) -> some View {
        ScrollView {
            VStack(alignment: .leading, spacing: CoachWorldTokens.Space.md) {
                Button("Back to aftermath", action: onClose)
                    .frame(minWidth: CoachWorldTokens.Shape.minimumTarget,
                           minHeight: CoachWorldTokens.Shape.minimumTarget)
                Text("GAME DETAIL / BOX SCORE")
                    .font(CoachWorldTokens.TypeRole.caption.weight(.heavy))
                Text(model.headline)
                    .font(CoachWorldTokens.TypeRole.title.weight(.black))
                Text("\(model.away.team.abbreviation) \(model.away.score) · \(model.home.team.abbreviation) \(model.home.score)")
                    .font(CoachWorldTokens.TypeRole.display.weight(.black))
                    .monospacedDigit()
                Text(model.resultLabel)
                    .font(CoachWorldTokens.TypeRole.headline.weight(.bold))
                evidenceSection("Game evidence", rows: model.evidence,
                                empty: "No detailed game evidence recorded.")
                evidenceSection("Controlled call-ins", rows: model.callIns,
                                empty: "No controlled call-ins recorded.")
                evidenceSection("Injuries", rows: model.injuries,
                                empty: "No injury evidence recorded.")
                if !model.grades.isEmpty {
                    Text("PLAYER GRADES")
                        .font(CoachWorldTokens.TypeRole.caption.weight(.heavy))
                    ForEach(model.grades) { grade in
                        HStack {
                            VStack(alignment: .leading) {
                                Text(grade.player.name).font(.headline.weight(.bold))
                                Text("\(grade.position) · \(grade.evidence)")
                                    .font(.caption)
                                    .foregroundStyle(palette.contentSecondary.color)
                            }
                            Spacer()
                            Text(String(grade.rating))
                                .font(CoachWorldTokens.TypeRole.headline.weight(.black))
                                .monospacedDigit()
                        }
                        .padding(CoachWorldTokens.Space.sm)
                        .background(.thinMaterial,
                                    in: RoundedRectangle(cornerRadius: CoachWorldTokens.Shape.surfaceRadius))
                        .accessibilityElement(children: .combine)
                        .accessibilityLabel("\(grade.player.name), \(grade.position), grade \(grade.rating), \(grade.evidence)")
                    }
                }
            }
            .padding(CoachWorldTokens.Space.lg)
        }
        .foregroundStyle(palette.contentPrimary.color)
        .background(palette.page.color.ignoresSafeArea())
    }

    private func evidenceSection(_ title: String, rows: [String], empty: String) -> some View {
        VStack(alignment: .leading, spacing: CoachWorldTokens.Space.xs) {
            Text(title.uppercased())
                .font(CoachWorldTokens.TypeRole.caption.weight(.heavy))
            if rows.isEmpty {
                Text(empty).foregroundStyle(.secondary)
            } else {
                ForEach(Array(rows.enumerated()), id: \.offset) { _, row in
                    Text(row).font(CoachWorldTokens.TypeRole.body)
                }
            }
        }
    }
}
