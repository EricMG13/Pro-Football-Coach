import Foundation

/// Owner-approved names and colours for the canonical 166-team world.
enum CanonicalTeamBranding {
    struct Record {
        let id: UUID
        let name: String
        let nickname: String
        let colours: ColourPair

        init(id: UUID, name: String, nickname: String, primary: Colour, secondary: Colour) {
            self.id = id
            self.name = name
            self.nickname = nickname
            colours = ColourPair(
                primary: primary,
                secondary: secondary,
                onTeam: ColourGenerator.legibleForeground(on: primary).colour
            )
        }
    }

    static let worldSeed: UInt64 = 20_260_812
    private static let recordsByID = Dictionary(uniqueKeysWithValues: records.map { ($0.id, $0) })

    static func apply(
        seed: UInt64,
        programmes: inout [Programme],
        proTeams: inout [ProTeam],
        identities: inout [UUID: TeamIdentity]
    ) {
        guard seed == worldSeed else { return }
        var applied = 0

        for index in programmes.indices {
            guard let record = recordsByID[programmes[index].id] else { continue }
            programmes[index].name = record.name
            programmes[index].nickname = record.nickname
            identities[record.id] = brandedIdentity(record, replacing: identities[record.id])
            applied += 1
        }
        for index in proTeams.indices {
            guard let record = recordsByID[proTeams[index].id] else { continue }
            proTeams[index].name = record.name
            proTeams[index].nickname = record.nickname
            identities[record.id] = brandedIdentity(record, replacing: identities[record.id])
            applied += 1
        }

        precondition(applied == records.count, "canonical team branding no longer matches the world")
    }

    private static func brandedIdentity(_ record: Record, replacing identity: TeamIdentity?) -> TeamIdentity {
        guard let identity else { preconditionFailure("canonical team has no identity") }
        return TeamIdentity(
            colours: record.colours,
            venueName: identity.venueName,
            traditions: identity.traditions,
            homeCityID: identity.homeCityID
        )
    }
}
