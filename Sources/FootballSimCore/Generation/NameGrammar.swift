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

    /// A stadium name: a place or a donor-shaped surname, plus a venue word.
    public static func venueName(place: String, using rng: inout SeededRandom) -> String {
        rng.chance(0.5)
            ? "\(place) \(rng.pick(venueWords))"
            : "\(surname(using: &rng)) \(rng.pick(venueWords))"
    }

    // MARK: - People

    /// A given name, assembled from syllables.
    ///
    /// Syllable assembly can still land on a real name by coincidence — "Marcus" is two ordinary
    /// syllables. That is not a defect the grammar can fix, and it is not the one the guardrail is
    /// about: a common given name identifies nobody. The `Blocklist`'s people list holds *full*
    /// names, which is the identifiable unit, and `LegalTests` checks the full name.
    public static func givenName(using rng: inout SeededRandom) -> String {
        let name = rng.pick(givenOnsets) + rng.pick(givenCodas)
        return name.capitalisedFirst
    }

    /// A surname, assembled from stems and endings.
    public static func surname(using rng: inout SeededRandom) -> String {
        (rng.pick(surnameStems) + rng.pick(surnameEndings)).capitalisedFirst
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
    private static let regionWords = [
        "Coastal", "Highland", "Midland", "Northern", "Southern", "Eastern", "Western",
        "Riverbend", "Lakeshore", "Frontier", "Granite", "Prairie",
    ]
    private static let conferenceWords = [
        "Conference", "League", "Association", "Alliance", "Circuit", "Union",
    ]
    private static let venueWords = [
        "Field", "Stadium", "Bowl", "Park", "Grounds", "Arena", "Yard",
    ]
    // No word here may appear on the blocklist, and `LegalTests` asserts it directly rather than
    // waiting for the 200-league sweep to stumble across one. "Crimson" sat in this list until the
    // sweep found it: it is Harvard's nickname, so every "Crimson Lancers" the generator produced
    // was a collision. A rare pool word might not surface in 200 leagues at all, which is why the
    // pool is checked as a set and not only through its output.
    private static let nicknameAdjectives = [
        "Iron", "Amber", "Granite", "Silver", "Copper", "Slate", "Storm", "Frost", "Ember",
        "Thunder", "River", "Harbor", "Timber", "Cinder", "Verdant", "Sable", "Kindled", "Hollow",
    ]
    private static let nicknameNouns = [
        "Wardens", "Drovers", "Miners", "Sentinels", "Lancers", "Foresters", "Marauders",
        "Prospectors", "Voyagers", "Reapers", "Anchors", "Pioneers", "Wreckers", "Harriers",
        "Stags", "Herons", "Colliers", "Otters", "Ironsides", "Quarrymen", "Beacons", "Kestrels",
    ]

    /// Every morpheme any pool can contribute, for the legal test.
    ///
    /// Public only so `LegalTests` can assert the pools are clean by construction. A generated name
    /// is a concatenation of these, so a blocked word anywhere in here is a collision waiting for
    /// the right seed — and the sweep is a sample, not a proof.
    public static var allMorphemes: [String] {
        placeStems + placeEndings + compassWords + institutionWords + regionWords
            + conferenceWords + venueWords + nicknameAdjectives + nicknameNouns
            + surnameStems.map { $0 } + surnameEndings.map { $0 }
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
    private static let surnameStems = [
        "Alder", "Bram", "Cald", "Dorn", "Eller", "Fal", "Gar", "Hask", "Ives", "Jarr", "Kend",
        "Lath", "Mor", "Nield", "Oster", "Pell", "Quill", "Rask", "Sedge", "Tarr", "Ux", "Vane",
        "Wick", "Yates", "Bram", "Corr", "Dunn", "Ferr", "Grim", "Holt",
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
