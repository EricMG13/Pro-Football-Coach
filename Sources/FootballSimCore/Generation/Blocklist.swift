import Foundation

/// The maintained denylist of real names and real trade dress, from `CLAUDE.md`'s legal guardrail
/// and `02-GAME-DESIGN.md` §11.3.5.
///
/// **What this is.** A list of things the generator must never produce. It exists so the guardrail
/// is a test rather than a comment — `docs/PORT-LOG.md` records the prior build shipping a
/// `colleges` array commented "Fictional alma maters" that held six real institutions, under a file
/// header asserting no real player was referenced.
///
/// **What this is not.** A definition of compliance. `02` §11.3.5 and `01` §7 both record the gap
/// and it bears repeating at the place someone would assume otherwise: a generated programme whose
/// ratings, conference, geography and history are individually fictional but *jointly* identify a
/// real one is trade-dress adjacent, and nothing here covers statistical or biographical
/// resemblance. That is a review obligation and a counsel question, not a threshold.
///
/// **Maintenance.** Refreshed per release; `docs/PRE-DEPLOYMENT-CHECKLIST.md` carries the item.
/// Entries are compared after normalisation, so a generated "North Western" collides with a real
/// "Northwestern".
public enum Blocklist {
    /// Normalised for comparison: lowercased, non-alphanumerics dropped.
    ///
    /// Without this the list is theatre — "Ohio State", "ohio state" and "Ohio-State" are three
    /// different strings and one blocklist entry.
    public static func normalised(_ name: String) -> String {
        name.lowercased().filter { $0.isLetter || $0.isNumber }
    }

    /// Every blocked entry, as its sequence of normalised words.
    ///
    /// Word *sequences*, not whole strings. The first version normalised each entry to one token,
    /// so "Ohio State" became `ohiostate` and no single word of a longer candidate could ever equal
    /// it — which made every one of the 114 multi-word entries invisible the moment another word
    /// was attached. `blocks("Ohio State")` was true and `blocks("Ohio State Technical")` false.
    ///
    /// The case that settles it: `docs/PORT-LOG.md` names **`Old Dominion Tech`** as one of the six
    /// real institutions the prior build shipped under a comment reading "Fictional alma maters".
    /// The gate written to catch that failure did not catch the string it names.
    /// **Owner decision, 2026-08-12: real location names are permitted, generator included.** The
    /// city list is therefore no longer an entry here — a school in a real city is the point of the
    /// decision, and leaving cities in would refuse "Columbus Technical" along with "Columbus".
    ///
    /// Institutions still are, and that is not a contradiction: eight real cities are refused as
    /// institution names, each because it either is a real programme or contains one — Buffalo,
    /// Cincinnati, Houston, Kansas City, Miami, Pittsburgh, Tulsa, Washington. They are
    /// refused as the name of a school and permitted as the name of the city it plays in, which is
    /// why callers must pick `blocks` or `blocksPlaceName` by what kind of name they hold.
    public static let entries: [[String]] = (institutions + nicknames + conferences + venues
        + people).map(words)

    /// What a *place* name may not be: a venue mark or an identifiable person.
    ///
    /// Not institutions, deliberately. The institution list is largely made of place names, so
    /// checking a city against it would refuse most of the real cities the owner has permitted.
    public static let placeEntries: [[String]] = (venues + people).map(words)

    /// The same entries as single normalised tokens, for the whole-string check.
    public static let names: Set<String> = Set(entries.map { $0.joined() })

    /// `placeEntries` as single normalised tokens.
    public static let placeNames: Set<String> = Set(placeEntries.map { $0.joined() })

    /// The longest entry, in words. Bounds the sliding window; derived rather than inlined, because
    /// `CLAUDE.md` forbids the magic number and because an entry longer than the window would be
    /// silently uncheckable.
    static let longestEntryWords: Int = entries.map(\.count).max() ?? 1

    static let longestPlaceEntryWords: Int = placeEntries.map(\.count).max() ?? 1

    private static func words(_ name: String) -> [String] {
        name.split(whereSeparator: { !$0.isLetter && !$0.isNumber })
            .map { normalised(String($0)) }
            .filter { !$0.isEmpty }
    }

    /// True if any contiguous run of `name`'s words is a blocked entry.
    ///
    /// Word sequences rather than raw substring containment. Substring containment is safe against
    /// today's generator and blocks invented names on sight — "Thibo Jacksonville" contains
    /// `bojackson`, "Newyorkshire" contains `newyork` — and a legal gate that fails on original
    /// names is a gate that gets weakened rather than obeyed.
    public static func blocks(_ name: String) -> Bool {
        contains(name, anyOf: names, longestEntryWords: longestEntryWords)
    }

    /// True if a *place* name is a venue mark or an identifiable person.
    ///
    /// The check a caller wants for a city, a region, or a hometown. Real locations are permitted
    /// by owner decision of 2026-08-12, so this deliberately does not consult the institution list.
    public static func blocksPlaceName(_ name: String) -> Bool {
        contains(name, anyOf: placeNames, longestEntryWords: longestPlaceEntryWords)
    }

    private static func contains(
        _ name: String,
        anyOf blocked: Set<String>,
        longestEntryWords: Int
    ) -> Bool {
        let candidate = words(name)
        guard !candidate.isEmpty else { return false }
        for start in candidate.indices {
            let longest = Swift.min(longestEntryWords, candidate.count - start)
            guard longest > 0 else { continue }
            for length in 1...longest
            where blocked.contains(candidate[start..<(start + length)].joined()) {
                return true
            }
        }
        return false
    }

    // MARK: - Real trade dress

    /// Real programme colour pairs, as `(primary, secondary)` hex.
    ///
    /// A denylist, exactly as the names are. `02` §11.3.5: a generated pair collides when *both*
    /// members sit within ΔE 25 of a real pair's corresponding members, checked in both
    /// orientations. One shared colour is not trade dress — half the sport wears navy.
    public static let tradeDress: [(primary: Colour, secondary: Colour)] = tradeDressHex.map {
        (Colour(hex: $0.0), Colour(hex: $0.1))
    }

    // MARK: - The lists themselves

    private static let institutions = [
        "Alabama", "Auburn", "Arkansas", "Arizona", "Arizona State", "Army", "Air Force",
        "Baylor", "Boise State", "Boston College", "Brigham Young", "Buffalo",
        "California", "Cincinnati", "Clemson", "Colorado", "Colorado State", "Coastal Carolina",
        "Delta State", "Duke", "East Carolina",
        "Florida", "Florida State", "Fresno State", "Georgia", "Georgia Tech", "Gonzaga",
        "Harvard", "Hawaii", "Houston", "Illinois", "Indiana", "Iowa", "Iowa State",
        "Kansas", "Kansas State", "Kent State", "Kentucky",
        "Liberty", "Louisville", "Louisiana State", "Marshall", "Maryland", "Memphis", "Miami",
        "Michigan", "Michigan State", "Minnesota", "Mississippi", "Mississippi State", "Missouri",
        "Navy", "Nebraska", "Nevada", "New Mexico", "North Carolina", "North Carolina State",
        "North Texas", "Northwestern", "Notre Dame",
        "Ohio State", "Oklahoma", "Oklahoma State", "Old Dominion", "Oregon", "Oregon State",
        "Penn State", "Pittsburgh", "Pine Bluff", "Princeton", "Purdue",
        "Rice", "Rockford", "Rutgers",
        "San Diego State", "San Jose State", "South Carolina", "South Florida", "Southern Methodist",
        "Stanford", "Syracuse",
        "Temple", "Tennessee", "Texas", "Texas A&M", "Texas Christian", "Texas Tech", "Toledo",
        "Troy", "Tulane", "Tulsa",
        "Utah", "Utah State", "Vanderbilt", "Villanova", "Virginia", "Virginia Tech",
        "Wake Forest", "Washington", "Washington State", "West Virginia", "Western Reserve",
        "Whitewater", "Wisconsin", "Wyoming", "Yale",
    ]

    private static let nicknames = [
        "Crimson Tide", "Tigers", "Razorbacks", "Wildcats", "Sun Devils", "Bears", "Bruins",
        "Bulldogs", "Buckeyes", "Cardinals", "Cavaliers", "Cornhuskers", "Cougars", "Cowboys",
        "Crimson", "Cyclones", "Ducks", "Eagles", "Fighting Irish", "Gators", "Golden Gophers",
        "Hawkeyes", "Hokies", "Hoosiers", "Horned Frogs", "Hurricanes", "Jayhawks", "Longhorns",
        "Mountaineers", "Nittany Lions", "Panthers", "Rebels", "Red Raiders", "Scarlet Knights",
        "Seminoles", "Sooners", "Spartans", "Tar Heels", "Terrapins", "Trojans", "Utes",
        "Volunteers", "Wolverines", "Yellow Jackets", "Aggies", "Badgers", "Boilermakers",
        "Commodores", "Demon Deacons", "Gamecocks", "Huskies", "Knights", "Minutemen", "Musketeers",
        "Orange", "Owls", "Rams", "Ravens", "Wolfpack",
        // Pro nicknames. A generic animal word is not protectable on its own, but the generator has
        // no need of any of them and a denylist that errs generous costs nothing but a few nouns.
        "Bengals", "Bills", "Broncos", "Browns", "Buccaneers", "Chargers", "Chiefs", "Colts",
        "Commanders", "Dolphins", "Falcons", "Giants", "Jaguars", "Jets", "Lions", "Packers",
        "Patriots", "Raiders", "Ravens", "Saints", "Seahawks", "Steelers", "Texans", "Titans",
        "Vikings", "Wolves", "Bison", "Bobcats", "Broncs", "Cardinal", "Chippewas", "Dukes",
        "Explorers", "Flames", "Friars", "Gaels", "Hilltoppers", "Hornets", "Jaspers", "Lobos",
        "Mavericks", "Mustangs", "Nighthawks", "Pilots", "Roadrunners", "Salukis", "Thundering Herd",
        "Toreros", "Vandals", "Waves", "Zips",
    ]

    private static let conferences = [
        "Southeastern Conference", "Big Ten", "Big Twelve", "Pac-Twelve", "Atlantic Coast",
        "American Athletic", "Mountain West", "Conference USA", "Sun Belt", "Mid-American",
        "Ivy League", "Big Sky", "Big East", "West Coast Conference", "Southland",
    ]

    private static let venues = [
        "Rose Bowl", "Cotton Bowl", "Orange Bowl", "Sugar Bowl", "Fiesta Bowl", "Peach Bowl",
        "Horseshoe", "Big House", "Death Valley", "Autzen", "Kinnick", "Camp Randall",
        "Neyland", "Sanford", "Bryant-Denny", "Kyle Field", "Jordan-Hare", "Beaver Stadium",
        "Lambeau", "Soldier Field", "Arrowhead", "Superdome", "Coliseum",
    ]

    /// Real city names.
    ///
    /// Retained after the 2026-08-12 decision as the **reference for the place boundary**, not as an
    /// entry list: `LegalTests` asserts the boundary from it, so the dual-use count `CLAUDE.md`
    /// quotes cannot drift away from the lists it describes. A list nothing reads would be the dead
    /// flexibility this repository forbids; this one is read by a test.
    public static let realCities = [
        "Atlanta", "Austin", "Baltimore", "Boston", "Buffalo", "Charlotte", "Chicago", "Cincinnati",
        "Cleveland", "Columbus", "Dallas", "Denver", "Detroit", "Green Bay", "Houston",
        "Indianapolis", "Jacksonville", "Kansas City", "Las Vegas", "Los Angeles", "Miami",
        "Milwaukee", "Minneapolis", "Nashville", "New Orleans", "New York", "Oakland",
        "Philadelphia", "Phoenix", "Pittsburgh", "Portland", "Sacramento", "Saint Louis",
        "Salt Lake City", "San Antonio", "San Diego", "San Francisco", "Seattle", "Tampa",
        "Tucson", "Tulsa", "Washington",
    ]

    /// Identifiable people. Deliberately short and deliberately maintained: this is the limb of the
    /// guardrail a denylist serves worst, because any plausible name belongs to someone. The
    /// generator's defence is a morpheme grammar that does not draw from a pool of real names in
    /// the first place; this catches what slips through.
    private static let people = [
        "Nick Saban", "Urban Meyer", "Bill Belichick", "Vince Lombardi", "Bear Bryant",
        "Knute Rockne", "Joe Paterno", "Bobby Bowden", "Tom Osborne", "Woody Hayes",
        "Tom Brady", "Peyton Manning", "Patrick Mahomes", "Joe Montana", "Jerry Rice",
        "Barry Sanders", "Walter Payton", "Lawrence Taylor", "Deion Sanders", "Bo Jackson",
    ]

    private static let tradeDressHex: [(String, String)] = [
        ("9E1B32", "828A8F"), ("BB0000", "666666"), ("0C2340", "C99700"),
        ("841617", "000000"), ("F56600", "522D80"), ("CFB87C", "000000"),
        ("782F40", "CEB888"), ("BA0C2F", "EEEEEE"), ("003057", "B3A369"),
        ("990000", "EEEDEB"), ("FFCD00", "000000"), ("A02142", "000000"),
        ("461D7C", "FDD023"), ("F47321", "005030"), ("00274C", "FFCB05"),
        ("18453B", "FFFFFF"), ("7A0019", "FFCC33"), ("CE1126", "14213D"),
        ("E31837", "0021A5"), ("0021A5", "FA4616"), ("BB0000", "FFFFFF"),
        ("841A2B", "003087"), ("154733", "FEE123"), ("041E42", "FFFFFF"),
        ("003594", "FFFFFF"), ("990000", "FFCC00"), ("BF5700", "FFFFFF"),
        ("4D1979", "C0C0C0"), ("CC0000", "000000"), ("7BAFD4", "13294B"),
        ("CC0033", "000000"), ("D3A625", "0C2340"), ("500000", "FFFFFF"),
        ("EAAA00", "000000"), ("861F41", "E5751F"), ("C41230", "FFFFFF"),
        ("981E32", "5E6A71"), ("002855", "EAAA00"), ("6F263D", "236192"),
    ]
}
