import Foundation

/// Builds names from morphemes rather than from lists of plausible names.
///
/// `docs/PORT-LOG.md` records why. The prior build's name bank took a cross product of ~60 real
/// first names and ~60 real last names and asserted in a comment that no real player was
/// referenced — a claim a cross product of plausible names cannot make. Its "fictional alma maters"
/// list held six real institutions.
///
/// The fix is structural, not a longer list. Place and institution names are assembled from
/// invented stems and endings that do not spell real places; person names are assembled from
/// syllables rather than drawn from a pool of real ones. `Blocklist` then catches whatever slips
/// through, and `LegalTests` sweeps the *generated output* rather than reading the source arrays —
/// which is the specific mistake that produced both of the prior failures.
public enum NameGrammar {
    // MARK: - Places

    /// A city or town name: an invented stem plus a settlement ending.
    public static func placeName(using rng: inout SeededRandom) -> String {
        rng.pick(placeStems) + rng.pick(placeEndings)
    }

    /// Every place name the grammar can produce, shuffled, so a caller can draw **without
    /// replacement**.
    ///
    /// 166 members were being drawn from a 570-name space with replacement, and the birthday
    /// paradox did the rest: every one of 200 swept leagues carried duplicate city names, 145 of
    /// them had two college programmes with the identical full name, and 23 put two identically
    /// named programmes in the *same conference* — two identical rows on a standings table. Worse
    /// for D6: 145 leagues contained a rivalry pointing at a name two programmes shared, and
    /// rivalry is the emotional payload the whole endogenous-identity design rests on.
    ///
    /// Drawing without replacement rather than rejecting and redrawing, deliberately: a
    /// reject-and-redraw loop consumes a data-dependent number of draws, which is exactly the
    /// stream coupling that made archetype sampling non-uniform earlier in this phase.
    public static func distinctPlaceNames(using rng: inout SeededRandom) -> [String] {
        var names: [String] = []
        names.reserveCapacity(placeStems.count * placeEndings.count)
        for stem in placeStems {
            for ending in placeEndings { names.append(stem + ending) }
        }
        return rng.shuffled(names)
    }

    /// How many distinct place names exist. Callers check they are not asking for more.
    public static var distinctPlaceNameCount: Int { placeStems.count * placeEndings.count }

    /// An institution name, in one of four shapes a school's name plausibly takes.
    ///
    /// None of the shapes can produce a bare real place name, because every stem is invented.
    public static func institutionName(place: String, using rng: inout SeededRandom) -> String {
        switch rng.int(in: 0...3) {
        case 0: return place
        case 1: return "\(rng.pick(compassWords)) \(place)"
        case 2: return "\(place) \(rng.pick(institutionWords))"
        default: return "\(place) \(rng.pick(compassWords))"
        }
    }

    /// A team nickname: an adjective and a noun, both from invented or generic pools.
    public static func nickname(using rng: inout SeededRandom) -> String {
        "\(rng.pick(nicknameAdjectives)) \(rng.pick(nicknameNouns))"
    }

    /// A conference name: a regional word and a conference word.
    public static func conferenceName(using rng: inout SeededRandom) -> String {
        "\(rng.pick(regionWords)) \(rng.pick(conferenceWords))"
    }

    /// A division name. Its own noun pool, so a division is never called a conference.
    public static func divisionName(using rng: inout SeededRandom) -> String {
        "\(rng.pick(regionWords)) \(rng.pick(divisionWords))"
    }

    /// A stadium name: a place plus a venue word.
    ///
    /// Unique by construction when `place` is, which the map guarantees — two members never share a
    /// city. The donor-named form is `distinctDonorVenueNames` below, drawn without replacement for
    /// the same reason places are.
    public static func venueName(place: String, using rng: inout SeededRandom) -> String {
        "\(place) \(rng.pick(venueWords))"
    }

    /// Every donor-named venue, shuffled, so a caller can draw without replacement.
    ///
    /// 30 stems by 16 endings by 7 venue words is 3,360 against 166 members. Drawn with
    /// replacement it collided in 178 of 200 leagues — two stadiums with the same name in one
    /// league — because 166 draws from a space that size is squarely inside the birthday paradox.
    public static func distinctDonorVenueNames(using rng: inout SeededRandom) -> [String] {
        var names: [String] = []
        // Deduplicated, because the seam collapse in `join` can map two different (stem, ending)
        // pairs onto one surname. A pool with a duplicate in it is not the size it looks.
        var seen: Set<String> = []
        names.reserveCapacity(surnameStems.count * surnameEndings.count * venueWords.count)
        for stem in surnameStems {
            for ending in surnameEndings {
                for venue in venueWords {
                    let name = "\(join(stem, ending).capitalisedFirst) \(venue)"
                    if !seen.insert(name).inserted { continue }
                    names.append(name)
                }
            }
        }
        return rng.shuffled(names)
    }

    // MARK: - People

    /// A given name, assembled from syllables.
    ///
    /// Syllable assembly can still land on a real name by coincidence — "Marcus" is two ordinary
    /// syllables. That is not a defect the grammar can fix, and it is not the one the guardrail is
    /// about: a common given name identifies nobody. The `Blocklist`'s people list holds *full*
    /// names, which is the identifiable unit, and `LegalTests` checks the full name.
    public static func givenName(using rng: inout SeededRandom) -> String {
        join(rng.pick(givenOnsets), rng.pick(givenCodas)).capitalisedFirst
    }

    /// A surname, assembled from stems and endings.
    public static func surname(using rng: inout SeededRandom) -> String {
        join(rng.pick(surnameStems), rng.pick(surnameEndings)).capitalisedFirst
    }

    /// Joins a stem to an ending, collapsing a doubled letter at the seam.
    ///
    /// "Quill" plus "ley" is "Quillley", which reads as a typo rather than as a name. Cosmetic, but
    /// this is product content on a stadium sign.
    private static func join(_ stem: String, _ ending: String) -> String {
        guard let last = stem.last, let first = ending.first, last == first else {
            return stem + ending
        }
        return stem + ending.dropFirst()
    }

    public static func personName(using rng: inout SeededRandom) -> (given: String, family: String) {
        (givenName(using: &rng), surname(using: &rng))
    }

    // MARK: - The morpheme pools

    // Invented stems. Chosen so that no stem plus ending spells a real US settlement; the legal
    // sweep is what confirms it rather than this comment.
    private static let placeStems = [
        "Ashen", "Brack", "Calder", "Dunmore", "Elmsworth", "Fenmark", "Gallow", "Harrow",
        "Ironvale", "Jessup", "Kestrel", "Larkin", "Marrow", "Northwell", "Orlin", "Pellham",
        "Quarry", "Redmoor", "Stannard", "Thornby", "Umber", "Vantry", "Wexford", "Yarrow",
        "Blackmere", "Coldridge", "Draymoor", "Eastholt", "Fairbank", "Grimshaw", "Hollowbrook",
        "Ivory", "Junip", "Kirkwall", "Lamphier", "Mossgate", "Netherby", "Oakhaven",
    ]
    private static let placeEndings = [
        "", " Falls", " Ridge", " Hollow", " Landing", " Crossing", " Bluff", " Mills",
        " Reach", " Bend", " Springs", " Gate", " Harbor", " Basin", " Heath",
    ]
    private static let compassWords = [
        "North", "South", "East", "West", "Upper", "Lower", "Central", "Coastal", "Inland",
    ]
    private static let institutionWords = [
        "State", "Technical", "Polytechnic", "Institute", "College", "Academy", "University",
        "Mining", "Agricultural", "Maritime", "Normal",
    ]
    // "Southern" and "Frontier" were here and had to go. Crossed with "Conference" they spell the
    // legal names of two real bodies — the Southern Conference (NCAA Division I) and the Frontier
    // Conference (NAIA) — and the generator produced them 63 and 58 times across a 200-league
    // sweep. Neither the morpheme gate nor the sweep could see it, because the blocklist was
    // essentially FBS institutions and FBS/NFL nicknames and neither of those bodies is in that
    // slice. Same shape as "Crimson": caught last time only because Harvard happened to be listed.
    private static let regionWords = [
        "Coastal", "Highland", "Midland", "Northern", "Riverbend", "Lakeshore",
        "Granite", "Prairie", "Ironmoor", "Windward", "Sablecrest", "Fenland",
    ]
    private static let conferenceWords = [
        "Conference", "League", "Association", "Alliance", "Circuit", "Union",
    ]

    /// Divisions get their own noun. Sharing `conferenceWords` produced divisions literally called
    /// "Highland Conference" sitting inside a conference, which reads as a data error on a
    /// standings screen.
    private static let divisionWords = [
        "Division", "Group", "Section", "Bracket", "Pod", "Flight",
    ]
    private static let venueWords = [
        "Field", "Stadium", "Bowl", "Park", "Grounds", "Arena", "Yard",
    ]
    // No word here may appear on the blocklist, and `LegalTests` asserts it directly rather than
    // waiting for the 200-league sweep to stumble across one. "Crimson" sat in this list until the
    // sweep found it: it is Harvard's nickname, so every "Crimson Lancers" the generator produced
    // was a collision. A rare pool word might not surface in 200 leagues at all, which is why the
    // pool is checked as a set and not only through its output.
    // "Storm" was here and is gone. It is the nickname of Simpson College, which plays Division III
    // football, and of Lake Erie College in Division II. An adjective is the hardest place to see
    // this, because the word never appears alone in a generated name — but "Storm Wardens" contains
    // it, and containment is what the blocklist evaluates. Replaced by another mineral, so the
    // pool keeps its register and its count.
    private static let nicknameAdjectives = [
        "Iron", "Amber", "Granite", "Silver", "Copper", "Slate", "Basalt", "Frost", "Ember",
        "Thunder", "River", "Harbor", "Timber", "Cinder", "Verdant", "Sable", "Kindled", "Hollow",
    ]
    // Miners, Lancers, Stags and Pioneers were here and are real Division I nicknames (UTEP,
    // Longwood, Fairfield, Denver). They are replaced one-for-one rather than deleted: the pool is
    // 22 nouns against 166 teams per save, and shrinking it makes the duplicate-nickname problem
    // worse, not better.
    //
    // Seven more went the same way on 2026-08-13, found by reading the pool against every division
    // rather than against the FBS slice the blocklist held: Foresters (Lake Forest, III), Marauders
    // (Mary, II), Herons (William Smith, III), Otters (Cal State Monterey Bay, II), Beacons
    // (Valparaiso, **I**), Drovers (Science and Arts of Oklahoma, NAIA) and Harriers (Miami
    // Hamilton, USCAA). Replaced in place, so the count stays 22 and `rng.pick` draws the same
    // index it drew before — a swap changes the names in a save and nothing else about it.
    private static let nicknameNouns = [
        "Wardens", "Shrikes", "Delvers", "Sentinels", "Bulwarks", "Sawyers", "Draymen",
        "Prospectors", "Voyagers", "Reapers", "Anchors", "Wayfarers", "Wreckers", "Wheelwrights",
        "Stalkers", "Bitterns", "Colliers", "Martens", "Ironsides", "Quarrymen", "Lamplighters",
        "Kestrels",
    ]

    /// Every **word** this grammar can put into a generated name.
    ///
    /// Words, not morphemes, because `Blocklist.blocks` splits on word boundaries and that is the
    /// unit it evaluates. The first version listed `surnameStems` and `surnameEndings` separately —
    /// but `surname()` concatenates them into a single word ("Uxhaven", "Caldwell"), and it was
    /// that concatenation, all 464 of them, that reached a stadium name and that nothing checked.
    /// 211 reachable strings were evaluated by no legal test at all.
    ///
    /// The cross products are built here, next to the pools they come from, rather than in the
    /// test. A test that composed them would be a second copy of the composition rules with nothing
    /// forcing it to stay in step with this file.
    public static var emittableWords: [String] {
        var words: [String] = []
        words += placeStems
        words += placeEndings.flatMap(splitIntoWords)
        words += compassWords + institutionWords + regionWords + conferenceWords + divisionWords
        words += venueWords + nicknameAdjectives + nicknameNouns
        // Given names and surnames are single words assembled from two pieces each. Both cross
        // products are small enough to enumerate outright: 512 and 464.
        // Through `join`, not raw concatenation — the seam collapse means "Alder" plus "ridge" is
        // "Alderidge", and it was that spelling the generator emitted while the vocabulary declared
        // "Alderridge". The two must be built the same way or the by-construction legal check
        // covers strings the generator never produces and misses the ones it does.
        for onset in givenOnsets {
            for coda in givenCodas { words.append(join(onset, coda).capitalisedFirst) }
        }
        for stem in surnameStems {
            for ending in surnameEndings { words.append(join(stem, ending).capitalisedFirst) }
        }
        return words
    }

    private static func splitIntoWords(_ text: String) -> [String] {
        text.split(whereSeparator: { !$0.isLetter && !$0.isNumber }).map(String.init)
    }

    private static let givenOnsets = [
        "dar", "kel", "mar", "ter", "jav", "cor", "bran", "dev", "shan", "tre", "quin", "rash",
        "cal", "dem", "el", "far", "gav", "hal", "isa", "jer", "kris", "lem", "mal", "nash",
        "oren", "prest", "rem", "sol", "tay", "vance", "wes", "zar",
    ]
    private static let givenCodas = [
        "ian", "on", "ius", "ell", "ay", "en", "is", "ard", "ton", "ick", "as", "iel", "or",
        "am", "ec", "yn",
    ]
    // "Bram" was in here twice, which made the surname cross product produce the same name from two
    // different draws and put "Bramson Yard" in two stadiums in the same league. A pool with a
    // duplicate in it is not the size it looks.
    private static let surnameStems = [
        "Alder", "Bram", "Cald", "Dorn", "Eller", "Fal", "Gar", "Hask", "Ives", "Jarr", "Kend",
        "Lath", "Mor", "Nield", "Oster", "Pell", "Quill", "Rask", "Sedge", "Tarr", "Ux", "Vane",
        "Wick", "Yates", "Bly", "Corr", "Dunn", "Ferr", "Grim", "Holt",
    ]
    private static let surnameEndings = [
        "ley", "son", "ford", "wick", "mont", "ridge", "stone", "worth", "by", "ton", "field",
        "haven", "well", "man", "hart", "combe",
    ]
}

private extension String {
    var capitalisedFirst: String {
        guard let first else { return self }
        return first.uppercased() + dropFirst()
    }
}
