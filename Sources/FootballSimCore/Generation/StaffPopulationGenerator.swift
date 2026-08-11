import Foundation

public struct StaffPopulation: Sendable, Equatable {
    public let staff: [Staff]
    public let staffIDsByOrganisation: [UUID: [UUID]]

    public init(staff: [Staff], staffIDsByOrganisation: [UUID: [UUID]]) {
        self.staff = staff
        self.staffIDsByOrganisation = staffIDsByOrganisation
    }
}

public enum StaffPopulationGenerator {
    private struct Slot {
        let role: StaffRole
        let positionGroup: PositionGroup?
    }

    public static func generate(
        seed: UInt64,
        programmes: [Programme],
        proTeams: [ProTeam]
    ) -> StaffPopulation {
        var staff: [Staff] = []
        var idsByOrganisation: [UUID: [UUID]] = [:]
        let organisations: [(UUID, Rating)] = programmes.map { ($0.id, $0.prestige) }
            + proTeams.map { ($0.id, $0.prestige) }
        for (organisationID, prestige) in organisations.sorted(by: {
            $0.0.uuidString < $1.0.uuidString
        }) {
            let organisationSeed = SeededRandom.derive(
                from: seed,
                scope: .personnel,
                identifier: organisationID
            )
            var organisationStaff: [Staff] = []
            for (index, slot) in slots.enumerated() {
                var rng = SeededRandom(seed: SeededRandom.derive(
                    from: organisationSeed,
                    scope: .personnel,
                    ordinal: index
                ))
                let name = NameGrammar.personName(using: &rng)
                let baseline = 48 + (prestige.value - SharedRules.ratingRange.lowerBound) * 32 / 59
                var ratings: [CoachAttribute: Rating] = [:]
                for attribute in CoachAttribute.allCases {
                    ratings[attribute] = Rating(baseline + rng.int(in: -12...12))
                }
                organisationStaff.append(Staff(
                    id: rng.uuid(),
                    firstName: name.given,
                    lastName: name.family,
                    role: slot.role,
                    age: rng.int(in: PeopleRules.staffAgeRange),
                    reputation: Rating(baseline + rng.int(in: -8...8)),
                    positionGroup: slot.positionGroup,
                    ratings: ratings,
                    preferredOffense: offensivePreference(role: slot.role, using: &rng),
                    preferredDefense: defensivePreference(role: slot.role, using: &rng)
                ))
            }
            staff.append(contentsOf: organisationStaff)
            idsByOrganisation[organisationID] = organisationStaff.map(\.id)
        }
        return StaffPopulation(staff: staff, staffIDsByOrganisation: idsByOrganisation)
    }

    public static func replacement(
        rootSeed: UInt64,
        season: Int,
        organisationID: UUID,
        prestige: Rating,
        role: StaffRole,
        positionGroup: PositionGroup?,
        ordinal: Int
    ) -> Staff {
        let organisationSeed = SeededRandom.derive(
            from: rootSeed,
            scope: .personnel,
            identifier: organisationID
        )
        let seasonSeed = SeededRandom.derive(
            from: organisationSeed,
            scope: .season,
            ordinal: season
        )
        var rng = SeededRandom(seed: SeededRandom.derive(
            from: seasonSeed,
            scope: .scheduler,
            ordinal: ordinal
        ))
        let name = NameGrammar.personName(using: &rng)
        let baseline = 48 + (prestige.value - SharedRules.ratingRange.lowerBound) * 32 / 59
        var ratings: [CoachAttribute: Rating] = [:]
        for attribute in CoachAttribute.allCases {
            ratings[attribute] = Rating(baseline + rng.int(in: -12...12))
        }
        return Staff(
            id: rng.uuid(),
            firstName: name.given,
            lastName: name.family,
            role: role,
            age: rng.int(in: 28...42),
            reputation: Rating(baseline + rng.int(in: -8...8)),
            positionGroup: positionGroup,
            ratings: ratings,
            preferredOffense: offensivePreference(role: role, using: &rng),
            preferredDefense: defensivePreference(role: role, using: &rng)
        )
    }

    private static let slots: [Slot] = [
        Slot(role: .headCoach, positionGroup: nil),
        Slot(role: .offensiveCoordinator, positionGroup: nil),
        Slot(role: .defensiveCoordinator, positionGroup: nil),
        Slot(role: .specialTeamsCoordinator, positionGroup: nil),
        Slot(role: .strengthCoordinator, positionGroup: nil),
    ] + PositionGroup.allCases.map { Slot(role: .positionCoach, positionGroup: $0) }

    private static func offensivePreference(
        role: StaffRole,
        using rng: inout SeededRandom
    ) -> OffensiveScheme? {
        guard role == .headCoach || role == .offensiveCoordinator else { return nil }
        return OffensiveScheme.allCases[rng.int(in: 0...(OffensiveScheme.allCases.count - 1))]
    }

    private static func defensivePreference(
        role: StaffRole,
        using rng: inout SeededRandom
    ) -> DefensiveScheme? {
        guard role == .headCoach || role == .defensiveCoordinator else { return nil }
        return DefensiveScheme.allCases[rng.int(in: 0...(DefensiveScheme.allCases.count - 1))]
    }
}
