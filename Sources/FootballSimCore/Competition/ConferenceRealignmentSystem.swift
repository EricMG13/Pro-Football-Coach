import Foundation

/// Moves the map by swapping programmes between conferences.
///
/// `02` §8 asks for a map the player does not leave as they found it. This is the half of it that
/// changes who plays whom.
///
/// **A swap, not a migration, for a structural reason.** A conference holds 12 to 16 programmes
/// summing to 134, and schedule generation, standings, tiebreaks and whole-root topology integrity
/// all read that shape. A one-way move makes one conference 11 and another 17, so every one of those
/// would have to cope with a size the rules forbid. A swap leaves each conference exactly the size it
/// was, so the map changes while nothing downstream can observe a shape it was not built for.
///
/// The pair taken is the one that most improves **geographic fit** — each programme scored by the
/// distance from its city to the centroid of its conference's cities — and only when the swap lowers
/// the total. Performance and market enter through prestige, which already follows the table.
public enum ConferenceRealignmentSystem {
    public static func process(in state: GameState) -> GameState {
        var next = state
        for _ in 0..<CollegeRules.realignmentSwapsPerSeason {
            guard let swap = bestSwap(in: next) else { break }
            next = applying(swap, to: next)
        }
        return next
    }

    private struct Swap {
        let firstID: UUID
        let secondID: UUID
        let firstConferenceID: UUID
        let secondConferenceID: UUID
    }

    /// The swap that most lowers total distance-to-centroid, or nil when none improves it.
    ///
    /// Declining is as important as swapping: a world already well arranged must settle rather than
    /// shuffle itself forever, which is the difference between realignment pressure and churn.
    private static func bestSwap(in state: GameState) -> Swap? {
        let conferences = state.league.conferences(in: .college)
            .sorted { $0.id.uuidString < $1.id.uuidString }
        guard conferences.count > 1 else { return nil }

        var centroids: [UUID: (x: Int, y: Int)] = [:]
        for conference in conferences {
            let cities = conference.memberIDs.compactMap { city(of: $0, in: state) }
            guard !cities.isEmpty else { continue }
            centroids[conference.id] = (
                x: cities.reduce(0) { $0 + $1.x } / cities.count,
                y: cities.reduce(0) { $0 + $1.y } / cities.count
            )
        }

        var best: Swap?
        var bestGain = 0
        for (index, home) in conferences.enumerated() {
            for away in conferences[(index + 1)...] {
                guard let homeCentroid = centroids[home.id],
                      let awayCentroid = centroids[away.id] else { continue }
                for firstID in home.memberIDs.sorted(by: { $0.uuidString < $1.uuidString }) {
                    guard let firstCity = city(of: firstID, in: state) else { continue }
                    for secondID in away.memberIDs.sorted(by: { $0.uuidString < $1.uuidString }) {
                        guard let secondCity = city(of: secondID, in: state) else { continue }
                        let before = squaredDistance(firstCity, homeCentroid)
                            + squaredDistance(secondCity, awayCentroid)
                        let after = squaredDistance(firstCity, awayCentroid)
                            + squaredDistance(secondCity, homeCentroid)
                        let gain = before - after
                        // Strictly greater, and ties broken by identity, so the choice is the same on
                        // every run rather than the first one the iteration happened to reach.
                        if gain > bestGain {
                            bestGain = gain
                            best = Swap(
                                firstID: firstID,
                                secondID: secondID,
                                firstConferenceID: home.id,
                                secondConferenceID: away.id
                            )
                        }
                    }
                }
            }
        }
        return best
    }

    private static func applying(_ swap: Swap, to state: GameState) -> GameState {
        var next = state
        for index in next.league.conferences.indices {
            let conferenceID = next.league.conferences[index].id
            if conferenceID == swap.firstConferenceID {
                next.league.conferences[index].memberIDs.removeAll { $0 == swap.firstID }
                next.league.conferences[index].memberIDs.append(swap.secondID)
            } else if conferenceID == swap.secondConferenceID {
                next.league.conferences[index].memberIDs.removeAll { $0 == swap.secondID }
                next.league.conferences[index].memberIDs.append(swap.firstID)
            }
            // Membership order is not meaningful, but it is persisted, so it is sorted to keep one
            // world one set of bytes.
            next.league.conferences[index].memberIDs.sort { $0.uuidString < $1.uuidString }
        }
        // The programme's own `conferenceID` is a second copy of the same fact and integrity checks
        // that the two agree, so both move together or neither does.
        _ = next.programmes.update(swap.firstID) { $0.conferenceID = swap.secondConferenceID }
        _ = next.programmes.update(swap.secondID) { $0.conferenceID = swap.firstConferenceID }
        return next
    }

    private static func city(of programmeID: UUID, in state: GameState) -> MapCity? {
        guard let name = state.programmes[programmeID]?.cityName else { return nil }
        return state.map.cities.first { $0.name == name }
    }

    private static func squaredDistance(_ city: MapCity, _ centroid: (x: Int, y: Int)) -> Int {
        let dx = city.x - centroid.x
        let dy = city.y - centroid.y
        return dx * dx + dy * dy
    }
}
