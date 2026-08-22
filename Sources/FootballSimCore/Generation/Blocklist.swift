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
    ///
    /// `marks` joined the institution-kind limbs on 2026-08-13: leagues, governing bodies,
    /// postseason systems, rivalry trophies, broadcasts and competitors' products. None of them is
    /// an institution, a nickname, a conference, a venue or a person, so before it existed each was
    /// a name nothing checked.
    public static let entries: [[String]] = (institutions + nicknames + conferences + venues
        + people + marks).map(words)

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
        "Akron", "Butler",
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
        // Added 2026-08-13. Every one of these was a live word in `NameGrammar`'s nickname pools
        // when it was added here, so the generator was emitting real college nicknames and both
        // legal tests were green: the nickname limb was an FBS-and-NFL slice, and none of these
        // schools is in that slice. Same shape as "Crimson", which was caught only because Harvard
        // happened to be listed, and as the Southern and Frontier Conferences, which were caught by
        // reading rather than by a gate. Sharpest of them is Beacons — Valparaiso is Division I.
        //
        // "Storm" was a nickname *adjective*, which is why it read as safe: it never appeared alone
        // in a generated name. It does not have to. Simpson College plays Division III football as
        // the Storm, and "Storm Wardens" contains it.
        "Foresters", "Marauders", "Herons", "Otters", "Beacons", "Drovers", "Harriers", "Storm",
    ]

    /// Conference marks, in every form the mark is actually written in.
    ///
    /// The numeral forms are not decoration. `normalised` keeps digits and drops nothing else, so
    /// "Big Twelve" and "Big 12" are two different tokens and the entry for one does not block the
    /// other — the list held the spelled form of three conferences whose own brand is the numeral.
    /// Acronyms are here for the same reason: a mark is infringed in the form it is used in, and
    /// "SEC" is the form almost everyone uses.
    ///
    /// The block beginning at `Southern Conference` is the non-FBS slice, added 2026-08-13, and it
    /// is the larger of the two additions by some way. `NameGrammar` records
    /// removing "Southern" and "Frontier" from the region pool because crossed with "Conference"
    /// they spell two real bodies — and the removal was the whole fix, so the blocklist still did
    /// not know either name was real. A pool word removed protects today's pool; a blocklist entry
    /// protects every pool after it.
    private static let conferences = [
        "Southeastern Conference", "Big Ten", "Big Twelve", "Pac-Twelve", "Atlantic Coast",
        "American Athletic", "Mountain West", "Conference USA", "Sun Belt", "Mid-American",
        "Ivy League", "Big Sky", "Big East", "West Coast Conference", "Southland",
        "Big 12", "Big XII", "Big 10", "B1G", "Pac-12", "Pac 12", "Pac-10", "Pac Ten",
        "Pacific 12", "Pacific Twelve", "Atlantic Ten", "Empire Eight",
        "SEC", "ACC", "AAC", "MAC", "MWC", "CUSA", "WAC",
        "Southern Conference", "Frontier Conference", "Summit League", "Horizon League",
        "Patriot League", "Colonial Athletic", "Coastal Athletic", "Missouri Valley",
        "Ohio Valley", "Northeast Conference", "Metro Atlantic", "Western Athletic",
        "Atlantic 10", "America East", "Big West", "Big South",
        "Great Lakes Valley", "Great Lakes Intercollegiate", "Gulf South", "Lone Star",
        "Peach Belt", "Sunshine State Conference", "Mountain East", "Northern Sun",
        "Sooner Athletic", "Great Plains Athletic", "California Collegiate Athletic",
        "Midwest Conference", "Central Intercollegiate Athletic",
        "Southern Intercollegiate Athletic", "Southwestern Athletic", "Mid-Eastern Athletic",
        "Pennsylvania State Athletic", "Old Dominion Athletic", "Centennial Conference",
        "Liberty League", "Landmark Conference", "Empire 8", "Skyline Conference",
        "American Rivers", "College Conference of Illinois", "Prairie College Conference",
        "Heartland Conference",
    ]

    /// Venue and bowl-game marks. Both kinds are here because a bowl's name is routinely also a
    /// stadium's — Rose Bowl, Cotton Bowl and Sun Bowl each name a building — which is what makes
    /// them place-kind, and what makes them the marks most likely to be mistaken for ordinary
    /// nouns. `NameGrammar.venueWords` contains "Bowl", so `<Place> Bowl` is a shape the generator
    /// produces on every save.
    private static let venues = [
        "Rose Bowl", "Cotton Bowl", "Orange Bowl", "Sugar Bowl", "Fiesta Bowl", "Peach Bowl",
        "Horseshoe", "Big House", "Death Valley", "Autzen", "Kinnick", "Camp Randall",
        "Neyland", "Sanford", "Bryant-Denny", "Kyle Field", "Jordan-Hare", "Beaver Stadium",
        "Lambeau", "Soldier Field", "Arrowhead", "Superdome", "Coliseum",
        // Added 2026-08-13.
        "Gator Bowl", "Citrus Bowl", "Sun Bowl", "Alamo Bowl", "Holiday Bowl", "Liberty Bowl",
        "Outback Bowl", "ReliaQuest Bowl", "Music City Bowl", "Independence Bowl",
        "Las Vegas Bowl", "Cactus Bowl", "Pinstripe Bowl", "Fenway Bowl", "Armed Forces Bowl",
        "Gasparilla Bowl", "Birmingham Bowl", "Texas Bowl", "First Responder Bowl",
        "Guaranteed Rate Bowl", "Super Bowl", "Pro Bowl", "Senior Bowl", "Shrine Bowl",
        "East-West Shrine", "Hula Bowl",
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
        // Award namesakes, added 2026-08-13. A trophy named after a person is two marks at once,
        // and the person is the limb that also sweeps place names — so a generated city called
        // Bednarik is refused here, while the award mark itself sits in `marks`.
        "John Heisman", "Walter Camp", "Amos Alonzo Stagg", "Chuck Bednarik", "Dick Butkus",
        "Bronko Nagurski", "Doak Walker", "Davey O'Brien", "Lou Groza", "Ray Guy",
    ]

    /// Marks that are none of the above: leagues, governing bodies, postseason systems, rivalry
    /// trophies, broadcasts and the products of this game's competitors.
    ///
    /// **Added 2026-08-13, and the reason is the review that produced it.** An IP note offered to
    /// this project proposed "safe alternatives" for the marks it named — "Southeastern Conference"
    /// for SEC, "Atlantic Coast" for ACC, "National Collegiate Association" for NCAA, "National Pro
    /// Football" for NFL. Two of those four were already on this list *as real names*, because they
    /// are the marks themselves rather than alternatives to them. That is the failure this limb is
    /// shaped around: the dangerous name is not the one nobody would reach for, it is the one a
    /// careful person reaches for while trying to be safe. So the coinages are here beside the
    /// registrations, and the two are not the same claim — "National Collegiate Association" is
    /// refused because it is a near-miss of a mark, not because anyone registered it.
    ///
    /// Institution-kind only. None of these reads as a place, so `placeEntries` does not take them
    /// and a generated city is not swept against them.
    private static let marks = [
        // Leagues and governing bodies, with the near-miss coinages beside them.
        "National Football League", "National Football Conference", "American Football Conference",
        "American Conference", "National Conference", "American Football League",
        "All-America Football Conference", "United States Football League",
        "United Football League", "Arena Football League", "Canadian Football League",
        "National Collegiate Athletic Association", "Collegiate Athletic Association",
        "National Collegiate Association", "National Pro Football", "Pro Football Hall of Fame",
        "NFL", "NFC", "AFC", "NCAA", "USFL", "XFL", "CFL", "NAIA", "NJCAA",
        // College postseason and governance.
        "College Football Playoff", "Bowl Championship Series", "Football Bowl Subdivision",
        "Football Championship Subdivision", "New Year's Six", "National Signing Day",
        "National Letter of Intent", "Collegiate Licensing Company", "Learfield",
        "CFP", "BCS", "FBS", "FCS", "Scouting Combine", "Hall of Fame Game",
        // Rivalry and trophy marks. The generator emits names of exactly this shape — a rivalry
        // adjective and a trophy noun — and until this limb existed nothing checked them, so the
        // tradition sweep ran against a list with no trophy in it.
        "Iron Bowl", "Egg Bowl", "Apple Cup", "Red River", "Holy War", "Backyard Brawl",
        "Territorial Cup", "Little Brown Jug", "Old Oaken Bucket", "Victory Bell", "Golden Egg",
        "Golden Hat", "Iron Skillet", "Jeweled Shillelagh", "Paul Bunyan's Axe",
        "Floyd of Rosedale", "Commander-in-Chief's Trophy", "Land Grant Trophy", "Bayou Bucket",
        "Governor's Cup", "Keg of Nails", "Illibuck", "Megaphone Trophy", "Sweet Sioux",
        "Platypus Trophy", "Milk Can",
        // Broadcast marks.
        "College GameDay", "Monday Night Football", "Sunday Night Football",
        "Thursday Night Football", "Big Noon Kickoff", "Hard Knocks", "Sunday Ticket", "ESPN",
        // Award marks. The namesakes themselves are in `people`.
        "Heisman", "Maxwell Award", "Bednarik Award", "Butkus Award", "Outland Trophy",
        "Thorpe Award", "Biletnikoff", "Rimington Trophy", "Mackey Award", "Ray Guy Award",
        "Wuerffel Trophy", "Broyles Award", "Lombardi Trophy",
        // Competitor and adjacent products. These reach a player through shipped copy and a store
        // listing rather than through the generator, and the shipped-copy scan is what catches
        // them.
        "Madden", "NCAA Football", "EA Sports College Football", "Football Manager",
        "Out of the Park Baseball", "Front Office Football", "Draft Day Sports",
        "Pro Strategy Football", "Retro Bowl", "Wolverine Studios", "Maximum Football",
        "Axis Football", "Legend Bowl", "Backbreaker", "College Dynasty",
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
        // The professional league's pairs, added 2026-08-13. The list above is a college slice, and
        // the generator dresses both tiers — so every pro team in every save was checked against
        // college trade dress only. Seventeen of these already sat inside a college entry's radius,
        // which is why the omission was survivable rather than harmless; the fifteen that did not
        // were unguarded.
        ("203731", "FFB612"), ("FFB612", "101820"), ("003594", "869397"), ("E31837", "FFB81C"),
        ("002244", "C60C30"), ("0B162A", "C83803"), ("FB4F14", "002244"), ("002244", "69BE28"),
        ("000000", "A5ACAF"), ("008E97", "FC4C02"), ("4F2683", "FFC62F"), ("241773", "000000"),
        ("004C54", "A5ACAF"), ("0B2265", "A71930"), ("125740", "FFFFFF"), ("FB4F14", "000000"),
        ("311D00", "FF3C00"), ("00338D", "C60C30"), ("0076B6", "B0B7BC"), ("0C2340", "4B92DB"),
        ("002C5F", "A2AAAD"), ("006778", "9F792C"), ("03202F", "A71930"), ("0080C6", "FFC20E"),
        ("003594", "FFA300"), ("AA0000", "B3995D"), ("97233F", "000000"), ("A71930", "000000"),
        ("0085CA", "101820"), ("D3BC8D", "101820"), ("D50A0A", "FF7900"), ("5A1414", "FFB612"),
    ]
}
