import SwiftUI

#if DEBUG
struct TeamLogoProofView: View {
    private let palette = CoachWorldTokens.dark
    private let unknown = CoachWorldTeamReference(
        stableID: "00000000-0000-0000-0000-000000000000",
        name: "Fallback Team",
        abbreviation: "FBK",
        primaryColorHex: "#315C8C",
        secondaryColorHex: "#E8B84A"
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
            // States the container intent, like the fallback below. It is intent only: swapping
            // this for `.ignore` changes nothing a query can see, so it is not what makes the
            // identifier resolve. What makes it resolve is the team names -- `CoachWorldTeamLogo`
            // is decorative by default and hides itself, so a container holding only logos has
            // nothing to attach an identifier to, which is exactly how the fallback row below
            // failed. The proof asserts those names, so the real guarantee is checked rather than
            // assumed.
            .accessibilityElement(children: .contain)
            .accessibilityIdentifier("team-logo-asset-proof")
            // Named, like every asset row above it, for the same reason.
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
