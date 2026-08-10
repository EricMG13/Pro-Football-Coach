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

    /// Every blocked *name*, normalised. Institutions, nicknames, conferences, stadiums, cities and
    /// identifiable people, in one set because the test asks one question of every generated
    /// string: is this a real thing's name?
    public static let names: Set<String> = Set(
        (institutions + nicknames + conferences + venues + cities + people).map(normalised)
    )

    /// True if `name`, or any word in it, is a blocked name.
    ///
    /// Whole-string *and* per-word, because "Clemson Valley" is not saved by the extra word. A
    /// generated multi-word name is checked as a whole and then component by component.
    public static func blocks(_ name: String) -> Bool {
        if names.contains(normalised(name)) { return true }
        return name
            .split(whereSeparator: { !$0.isLetter && !$0.isNumber })
            .contains { names.contains(normalised(String($0))) }
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

    private static let cities = [
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
