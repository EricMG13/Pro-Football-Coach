import SwiftUI

#if DEBUG
struct TeamLogoProofView: View {
    private let palette = CoachWorldTokens.dark
    private let unknown = CoachWorldTeamReference(
        stableID: "00000000-0000-0000-0000-000000000000",
        name: "Fallback Team",
        abbreviation: "FBK"
    )

    var body: some View {
        ScrollView {
            LazyVGrid(columns: [GridItem(.adaptive(minimum: 220))]) {
                ForEach(CoachWorldTeamLogoCatalog.proofTeams, id: \.stableID) { team in
                    VStack(alignment: .leading) {
                        Text(team.name)
                        logoRow(team, surface: palette.page)
                            .background(palette.page.color)
                        logoRow(team, surface: palette.raised)
                            .background(palette.raised.color)
                    }
                }
            }
            .accessibilityIdentifier("team-logo-asset-proof")
            // Named, like every asset row above it. `CoachWorldTeamLogo` is decorative by default
            // and hides itself from accessibility, so an unlabelled row holds nothing but hidden
            // elements -- the identifier had no element to attach to and the proof could not be
            // queried at all. The grid above resolves only because it also carries team names.
            VStack(alignment: .leading) {
                Text(unknown.name)
                logoRow(unknown, surface: palette.raised)
            }
            .accessibilityElement(children: .contain)
            .accessibilityIdentifier("team-logo-fallback-proof")
        }
        .padding()
        .background(palette.work.color)
    }

    private func logoRow(
        _ team: CoachWorldTeamReference,
        surface: CoachWorldTokens.ColorValue
    ) -> some View {
        HStack {
            CoachWorldTeamLogo(team: team, size: .compact, surface: surface)
            CoachWorldTeamLogo(team: team, size: .medium, surface: surface)
            CoachWorldTeamLogo(team: team, size: .large, surface: surface)
        }
    }
}
#endif
