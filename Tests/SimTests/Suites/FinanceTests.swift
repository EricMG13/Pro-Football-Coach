import Foundation
import FootballSimCore

func runFinanceTests() {
    suite("Money and facilities") {
        test("revenue follows standing") {
            // Derived from prestige rather than stored, because revenue is a consequence of
            // standing and a second number would be one more thing to keep in step with it.
            let poor = OrganisationFinances.annualRevenue(prestige: Rating(40), tier: .college)
            let rich = OrganisationFinances.annualRevenue(prestige: Rating(99), tier: .college)
            expect(rich > poor, "prestige was worth nothing at the gate")
            expect(poor > 0, "a floor-prestige programme takes in nothing at all")
            expect(OrganisationFinances.annualRevenue(prestige: Rating(70), tier: .pro)
                       > OrganisationFinances.annualRevenue(prestige: Rating(70), tier: .college),
                   "the professional tier is no richer than the college one")
        }

        test("a budget that goes negative is a budget nothing enforces") {
            var finances = OrganisationFinances(facilities: Rating(70), reserves: 1_000)
            expect(finances.spend(400), "a legal spend was refused")
            expectEqual(finances.reserves, 600)
            expect(!finances.spend(10_000), "an unaffordable spend went through")
            expectEqual(finances.reserves, 600, "a refused spend still moved the money")
            expect(!finances.spend(-5), "a negative spend was treated as income")
            finances.credit(400)
            expectEqual(finances.reserves, 1_000)
        }

        test("nil finances mean not generated yet, never broke") {
            // GameState demands an exact schema match with no migration path, so a save written
            // before money existed has to read as an ordinary programme rather than a bankrupt one.
            let state = GameState.bootstrap(seed: 92_001)
            let programme = state.programmes[state.programmes.ids[0]]!
            let derived = programme.finances(defaultingFor: .college)
            expect(derived.reserves > 0, "a programme with no stored finances read as broke")
            expectEqual(derived.facilities, programme.resources,
                        "facilities did not default to what the programme was generated with")
            let team = state.proTeams[state.proTeams.ids[0]]!
            expect(team.finances(defaultingFor: .pro).reserves > 0,
                   "a club with no stored finances read as broke")
        }

        test("a wage is what the market thinks of somebody") {
            let star = FinanceRules.salary(reputation: Rating(95), role: .headCoach)
            let journeyman = FinanceRules.salary(reputation: Rating(45), role: .headCoach)
            expect(star > journeyman, "reputation was worth nothing, so continuity is free")
            expect(FinanceRules.salary(reputation: Rating(70), role: .headCoach)
                       > FinanceRules.salary(reputation: Rating(70), role: .positionCoach),
                   "a head coach costs no more than a position coach")
            for role in StaffRole.allCases {
                expect(role.baseSalary > 0, "\(role.rawValue) is unpaid")
            }
        }

        test("facilities help, and help less than coaching") {
            // A facility bonus that outweighed a position coach would make the staff decorative.
            expect(FinanceRules.facilityDevelopmentBonus > 0, "facilities are worth nothing")
            expect(FinanceRules.facilityDevelopmentBonus < 2,
                   "facilities outweigh a competent position coach")
            expect(DevelopmentReason.allCases.contains(.facilities),
                   "development cannot say the buildings helped")
        }
    }
}
