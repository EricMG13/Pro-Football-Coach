import Foundation

/// Builds names from real U.S. places plus generic football descriptors.
///
/// `docs/PORT-LOG.md` records why. The prior build's name bank took a cross product of ~60 real
/// first names and ~60 real last names and asserted in a comment that no real player was
/// referenced — a claim a cross product of plausible names cannot make. Its "fictional alma maters"
/// list held six real institutions.
///
/// City and town names are sourced from the U.S. Census Gazetteer and paired with state
/// abbreviations. Institution and postseason descriptors remain generic; the `Blocklist` and
/// `LegalTests` still screen the generated output rather than trusting this source list.
public enum NameGrammar {
    // MARK: - Places

    /// A real U.S. city or town, qualified by its state abbreviation.
    public static func placeName(using rng: inout SeededRandom) -> String {
        // Keep the two-draw shape of the former stem/ending grammar so stable IDs remain stable.
        _ = rng.int(in: 0...1)
        return rng.pick(realAmericanPlaces)
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
        rng.shuffled(realAmericanPlaces)
    }

    /// How many distinct place names exist. Callers check they are not asking for more.
    public static var distinctPlaceNameCount: Int { realAmericanPlaces.count }

    /// A college-style institution name: a real place plus a generic descriptor used by real
    /// American college naming patterns. The first draw stays a four-way branch so changing the
    /// vocabulary does not add or remove random draws from world generation.
    public static func institutionName(place: String, using rng: inout SeededRandom) -> String {
        switch rng.int(in: 0...3) {
        case 0: return "\(place) University"
        default: return "\(place) \(rng.pick(institutionWords))"
        }
    }

    /// A bowl-game title that uses a real host place and a generic event descriptor.
    ///
    /// The engine currently stores postseason stage rather than a title; callers that project a
    /// bowl badge should use this instead of a protected legacy bowl name.
    public static func bowlName(place: String, using rng: inout SeededRandom) -> String {
        "\(place) \(rng.pick(bowlDescriptors))"
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

    // Real incorporated U.S. cities and towns, selected from the 2024 Census Gazetteer. State
    // abbreviations keep duplicate place names distinct without inventing a fictional settlement.
    private static let realAmericanPlaces = [
        "Adak, AK",
        "Abbeville, AL",
        "Adona, AR",
        "Apache Junction, AZ",
        "Adelanto, CA",
        "Aguilar, CO",
        "Ansonia, CT",
        "Bellefonte, DE",
        "Alachua, FL",
        "Abbeville, GA",
        "Ackley, IA",
        "Aberdeen, ID",
        "Abingdon, IL",
        "Advance, IN",
        "Abbyville, KS",
        "Adairville, KY",
        "Abbeville, LA",
        "Agawam Town, MA",
        "Aberdeen, MD",
        "Augusta, ME",
        "Adrian, MI",
        "Ada, MN",
        "Adrian, MO",
        "Abbeville, MS",
        "Alberton, MT",
        "Aberdeen, NC",
        "Abercrombie, ND",
        "Ainsworth, NE",
        "Berlin, NH",
        "Absecon, NJ",
        "Alamogordo, NM",
        "Boulder City, NV",
        "Albany, NY",
        "Akron, OH",
        "Achille, OK",
        "Adair Village, OR",
        "Aliquippa, PA",
        "Central Falls, RI",
        "Abbeville, SC",
        "Aberdeen, SD",
        "Adams, TN",
        "Abbott, TX",
        "Alpine, UT",
        "Abingdon, VA",
        "Barre, VT",
        "Aberdeen, WA",
        "Abbotsford, WI",
        "Addison (Webster Springs), WV",
        "Afton, WY",
        "Akhiok, AK",
        "Adamsville, AL",
        "Alexander, AR",
        "Avondale, AZ",
        "Agoura Hills, CA",
        "Akron, CO",
        "Bridgeport, CT",
        "Bethany Beach, DE",
        "Alford, FL",
        "Acworth, GA",
        "Ackworth, IA",
        "Acequia, ID",
        "Albion, IL",
        "Akron, IN",
        "Abilene, KS",
        "Albany, KY",
        "Abita Springs, LA",
        "Amesbury, MA",
        "Accident, MD",
        "Bangor, ME",
        "Albion, MI",
        "Adams, MN",
        "Advance, MO",
        "Aberdeen, MS",
        "Bainville, MT",
        "Ahoskie, NC",
        "Adams, ND",
        "Albion, NE",
        "Claremont, NH",
        "Asbury Park, NJ",
        "Albuquerque, NM",
        "Caliente, NV",
        "Amsterdam, NY",
        "Alliance, OH",
        "Ada, OK",
        "Adams, OR",
        "Allentown, PA",
        "Cranston, RI",
        "Aiken, SC",
        "Agar, SD",
        "Adamsville, TN",
        "Abernathy, TX",
        "Alta, UT",
        "Accomac, VA",
        "Burlington, VT",
        "Airway Heights, WA",
        "Adams, WI",
        "Albright, WV",
        "Albin, WY",
        "Akiak, AK",
        "Addison, AL",
        "Alicia, AR",
        "Benson, AZ",
        "Alameda, CA",
        "Alamosa, CO",
        "Bristol, CT",
        "Bethel, DE",
        "Altamonte Springs, FL",
        "Adairsville, GA",
        "Adair, IA",
        "Albion, ID",
        "Aledo, IL",
        "Alamo, IN",
        "Admire, KS",
        "Alexandria, KY",
        "Addis, LA",
        "Amherst Town, MA",
        "Annapolis, MD",
        "Bath, ME",
        "Algonac, MI",
        "Adrian, MN",
        "Alba, MO",
        "Ackerman, MS",
        "Baker, MT",
        "Albemarle, NC",
        "Alamo, ND",
        "Alliance, NE",
        "Concord, NH",
        "Atlantic City, NJ",
        "Anthony, NM",
        "Carlin, NV",
        "Batavia, NY",
        "Amherst, OH",
        "Adair, OK",
        "Adrian, OR",
        "Altoona, PA",
        "East Providence, RI",
        "Allendale, SC",
        "Akaska, SD",
        "Alamo, TN",
        "Abilene, TX",
        "Altamont, UT",
        "Alberta, VA",
        "Essex Junction, VT",
        "Albion, WA",
        "Algoma, WI",
        "Alderson, WV",
        "Alpine, WY",
        "Akutan, AK",
        "Akron, AL",
        "Allport, AR",
        "Bisbee, AZ",
        "Albany, CA",
        "Alma, CO",
        "Danbury, CT",
        "Blades, DE",
        "Altha, FL",
        "Adel, GA",
        "Adel, IA",
        "American Falls, ID",
        "Altamont, IL",
        "Albany, IN",
        "Agenda, KS",
        "Allen, KY",
        "Albany, LA",
        "Attleboro, MA",
        "Baltimore, MD",
        "Belfast, ME",
        "Allegan, MI",
        "Afton, MN",
        "Albany, MO",
        "Algoma, MS",
        "Bearcreek, MT",
        "Alliance, NC",
        "Alexander, ND",
        "Alma, NE",
        "Dover, NH",
        "Bayonne, NJ",
        "Artesia, NM",
        "Elko, NV",
        "Beacon, NY",
        "Ashland, OH",
        "Addington, OK",
        "Albany, OR",
        "Arnold, PA",
        "Newport, RI",
        "Anderson, SC",
        "Albee, SD",
        "Alcoa, TN",
        "Ackerly, TX",
        "Alton, UT",
        "Alexandria, VA",
        "Montpelier, VT",
        "Algona, WA",
        "Alma, WI",
        "Anawalt, WV",
        "Baggs, WY",
        "Alakanuk, AK",
        "Alabaster, AL",
        "Alma, AR",
        "Buckeye, AZ",
        "Alhambra, CA",
        "Antonito, CO",
        "Derby, CT",
        "Bowers, DE",
        "Anna Maria, FL",
        "Adrian, GA",
        "Afton, IA",
        "Ammon, ID",
        "Alton, IL",
        "Albion, IN",
        "Agra, KS",
        "Anchorage, KY",
        "Alexandria, LA",
        "Barnstable Town, MA",
        "Barclay, MD",
        "Biddeford, ME",
        "Allen Park, MI",
        "Aitkin, MN",
        "Alexandria, MO",
        "Alligator, MS",
        "Belgrade, MT",
        "Andrews, NC",
        "Alice, ND",
        "Arapahoe, NE",
        "Franklin, NH",
        "Belvidere, NJ",
        "Aztec, NM",
        "Ely, NV",
        "Binghamton, NY",
        "Ashtabula, OH",
        "Afton, OK",
        "Amity, OR",
        "Beaver Falls, PA",
        "Pawtucket, RI",
        "Andrews, SC",
        "Alcester, SD",
        "Alexandria, TN",
        "Addison, TX",
        "Amalga, UT",
        "Altavista, VA",
        "Newport, VT",
        "Almira, WA",
        "Altoona, WI",
        "Anmoore, WV",
        "Bairoil, WY",
        "Aleknagik, AK",
        "Albertville, AL",
        "Almyra, AR",
        "Bullhead City, AZ",
        "Aliso Viejo, CA",
        "Arriba, CO",
        "Groton, CT",
        "Bridgeville, DE",
        "Apalachicola, FL",
        "Ailey, GA",
        "Agency, IA",
        "Arco, ID",
        "Amboy, IL",
        "Alexandria, IN",
        "Albert, KS",
        "Arlington, KY",
        "Amite City, LA",
        "Beverly, MA",
        "Barnesville, MD",
        "Brewer, ME",
        "Alma, MI",
        "Akeley, MN",
        "Alma, MO",
        "Amory, MS",
        "Belt, MT",
        "Angier, NC",
        "Almont, ND",
        "Ashland, NE",
        "Keene, NH",
        "Beverly, NJ",
        "Bayard, NM",
        "Fallon, NV",
        "Canandaigua, NY",
        "Athens, OH",
        "Agra, OK",
        "Antelope, OR",
        "Bethlehem, PA",
        "Providence, RI",
        "Arcadia Lakes, SC",
        "Alexandria, SD",
        "Algood, TN",
        "Adrian, TX",
        "American Fork, UT",
        "Amherst, VA",
        "Rutland, VT",
        "Anacortes, WA",
        "Amery, WI",
        "Ansted, WV",
        "Bar Nunn, WY",
        "Allakaket, AK",
        "Alexander City, AL",
        "Alpena, AR",
        "Camp Verde, AZ",
        "Alturas, CA",
        "Arvada, CO",
        "Hartford, CT",
        "Camden, DE",
        "Apopka, FL",
        "Alamo, GA",
        "Ainsworth, IA",
        "Arimo, ID",
        "Anna, IL",
        "Alfordsville, IN",
        "Alden, KS",
        "Ashland, KY",
        "Arcadia, LA",
        "Boston, MA",
        "Barton, MD",
        "Calais, ME",
        "Alpena, MI",
        "Albany, MN",
        "Altenburg, MO",
        "Anguilla, MS",
        "Big Sandy, MT",
        "Ansonville, NC",
        "Alsen, ND",
        "Atkinson, NE",
        "Laconia, NH",
        "Boonton, NJ",
        "Belen, NM",
        "Fernley, NV",
        "Cohoes, NY",
        "Aurora, OH",
        "Albion, OK",
        "Arlington, OR",
        "Bloomsburg, PA",
        "Warwick, RI",
        "Atlantic Beach, SC",
        "Alpena, SD",
        "Allardt, TN",
        "Agua Dulce, TX",
        "Annabella, UT",
        "Appalachia, VA",
        "South Burlington, VT",
        "Arlington, WA",
        "Antigo, WI",
        "Athens, WV",
        "Basin, WY",
        "Ambler, AK",
        "Aliceville, AL",
        "Altheimer, AR",
        "Carefree, AZ",
        "Amador City, CA",
        "Aspen, CO",
        "Meriden, CT",
        "Cheswold, DE",
        "Arcadia, FL",
        "Alapaha, GA",
        "Akron, IA",
        "Ashton, ID",
        "Annawan, IL",
        "Alton, IN",
        "Alexander, KS",
        "Audubon Park, KY",
        "Arnaudville, LA",
        "Braintree Town, MA",
        "Bel Air, MD",
        "Caribou, ME",
        "Ann Arbor, MI",
        "Albert Lea, MN",
        "Alton, MO",
        "Arcola, MS",
        "Big Timber, MT",
        "Apex, NC",
        "Ambrose, ND",
        "Aurora, NE",
        "Lebanon, NH",
        "Bordentown, NJ",
        "Bernalillo, NM",
        "Henderson, NV",
        "Corning, NY",
        "Avon, OH",
        "Alderson, OK",
        "Ashland, OR",
        "Bradford, PA",
        "Woonsocket, RI",
        "Awendaw, SC",
        "Altamont, SD",
        "Altamont, TN",
        "Alamo, TX",
        "Antimony, UT",
        "Appomattox, VA",
        "St. Albans, VT",
        "Asotin, WA",
        "Appleton, WI",
        "Bancroft, WV",
        "Bear River, WY",
        "Anaktuvuk Pass, AK",
        "Allgood, AL",
        "Altus, AR",
        "Casa Grande, AZ",
        "American Canyon, CA",
        "Ault, CO",
        "Middletown, CT",
        "Clayton, DE",
        "Archer, FL",
        "Albany, GA",
        "Albert City, IA",
        "Athol, ID",
        "Arcola, IL",
        "Altona, IN",
        "Allen, KS",
        "Augusta, KY",
        "Baker, LA",
        "Bridgewater Town, MA",
        "Berlin, MD",
        "Eastport, ME",
        "Au Gres, MI",
        "Alberta, MN",
        "Amity, MO",
        "Artesia, MS",
        "Billings, MT",
        "Arapahoe, NC",
        "Amenia, ND",
        "Bassett, NE",
        "Manchester, NH",
        "Bridgeton, NJ",
        "Bloomfield, NM",
        "Las Vegas, NV",
        "Cortland, NY",
        "Avon Lake, OH",
        "Alex, OK",
        "Astoria, OR",
        "Butler, PA",
        "Aynor, SC",
        "Andover, SD",
        "Ardmore, TN",
        "Alamo Heights, TX",
        "Apple Valley, UT",
        "Ashland, VA",
        "Vergennes, VT",
        "Bainbridge Island, WA",
        "Arcadia, WI",
        "Barrackville, WV",
        "Big Piney, WY",
        "Anderson, AK",
        "Altoona, AL",
        "Amagon, AR",
        "Cave Creek, AZ",
        "Anaheim, CA",
        "Aurora, CO",
        "New Britain, CT",
        "Dagsboro, DE",
        "Astatula, FL",
        "Aldora, GA",
        "Albia, IA",
        "Bancroft, ID",
        "Ashley, IL",
        "Ambia, IN",
        "Alma, KS",
        "Bancroft, KY",
        "Baldwin, LA",
        "Brockton, MA",
        "Berwyn Heights, MD",
        "Ellsworth, ME",
        "Bad Axe, MI",
        "Albertville, MN",
        "Amoret, MO",
        "Ashland, MS",
        "Boulder, MT",
        "Archdale, NC",
        "Amidon, ND",
        "Battle Creek, NE",
        "Nashua, NH",
        "Brigantine, NJ",
        "Carlsbad, NM",
        "Lovelock, NV",
        "Dunkirk, NY",
        "Barberton, OH",
        "Aline, OK",
        "Athena, OR",
        "Carbondale, PA",
        "Bamberg, SC",
        "Arlington, SD",
        "Arlington, TN",
        "Alba, TX",
        "Aurora, UT",
        "Bedford, VA",
        "Winooski, VT",
        "Battle Ground, WA",
        "Ashland, WI",
        "Bath (Berkeley Springs), WV",
        "Burlington, WY",
        "Angoon, AK",
        "Andalusia, AL",
        "Amity, AR",
        "Chandler, AZ",
        "Anderson, CA",
        "Avon, CO",
        "New Haven, CT",
        "Delaware City, DE",
        "Atlantic Beach, FL",
        "Allenhurst, GA",
        "Albion, IA",
        "Basalt, ID",
        "Assumption, IL",
        "Amboy, IN",
        "Almena, KS",
        "Barbourmeade, KY",
        "Ball, LA",
        "Cambridge, MA",
        "Betterton, MD",
        "Gardiner, ME",
        "Bangor, MI",
        "Alden, MN",
        "Amsterdam, MO",
        "Baldwyn, MS",
        "Bozeman, MT",
        "Archer Lodge, NC",
        "Anamoose, ND",
        "Bayard, NE",
        "Portsmouth, NH",
        "Burlington, NJ",
        "Carrizozo, NM",
        "Mesquite, NV",
        "Elmira, NY",
        "Bay Village, OH",
        "Allen, OK",
        "Aumsville, OR",
        "Chester, PA",
        "Barnwell, SC",
        "Armour, SD",
        "Ashland City, TN",
        "Albany, TX",
        "Ballard, UT",
        "Belle Haven, VA",
        "Beaux Arts Village, WA",
        "Augusta, WI",
        "Bayard, WV",
        "Burns, WY",
        "Aniak, AK",
        "Anderson, AL",
        "Anthonyville, AR",
        "Chino Valley, AZ",
        "Angels, CA",
        "Basalt, CO",
        "New London, CT",
        "Delmar, DE",
        "Atlantis, FL",
        "Allentown, GA",
        "Alburnett, IA",
        "Bellevue, ID",
        "Astoria, IL",
        "Amo, IN",
        "Alta Vista, KS",
        "Barbourville, KY",
        "Basile, LA",
        "Chelsea, MA",
        "Bladensburg, MD",
        "Hallowell, ME",
        "Battle Creek, MI",
        "Aldrich, MN",
        "Anderson, MO",
        "Bassfield, MS",
        "Bridger, MT",
        "Asheboro, NC",
        "Aneta, ND",
        "Beatrice, NE",
        "Rochester, NH",
        "Camden, NJ",
        "Clayton, NM",
        "North Las Vegas, NV",
        "Fulton, NY",
        "Beachwood, OH",
        "Altus, OK",
    ]
    private static let compassWords = [
        "North", "South", "East", "West", "Upper", "Lower", "Central", "Coastal", "Inland",
    ]
    private static let institutionWords = [
        "State University", "A&M University", "Technical University", "Polytechnic University", "Regional University",
        "Research University", "Agricultural University", "Institute of Technology",
        "Technical Institute", "Polytechnic Institute", "Regional Institute", "Research Institute",
        "Agricultural Institute", "Maritime Institute", "Maritime College", "Normal University",
        "Technical College", "Regional College", "City College", "State College",
    ]
    private static let bowlDescriptors = [
        "Classic", "Showcase", "Championship", "Football Classic",
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
    private static let nicknameAdjectives = [
        "Iron", "Amber", "Granite", "Silver", "Copper", "Slate", "Storm", "Frost", "Ember",
        "Thunder", "River", "Harbor", "Timber", "Cinder", "Verdant", "Sable", "Kindled", "Hollow",
    ]
    // Miners, Lancers, Stags and Pioneers were here and are real Division I nicknames (UTEP,
    // Longwood, Fairfield, Denver). They are replaced one-for-one rather than deleted: the pool is
    // 22 nouns against 166 teams per save, and shrinking it makes the duplicate-nickname problem
    // worse, not better.
    private static let nicknameNouns = [
        "Wardens", "Drovers", "Delvers", "Sentinels", "Bulwarks", "Foresters", "Marauders",
        "Prospectors", "Voyagers", "Reapers", "Anchors", "Wayfarers", "Wreckers", "Harriers",
        "Stalkers", "Herons", "Colliers", "Otters", "Ironsides", "Quarrymen", "Beacons", "Kestrels",
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
        words += realAmericanPlaces.flatMap(splitIntoWords)
        words += compassWords + institutionWords.flatMap(splitIntoWords)
            + regionWords + conferenceWords + divisionWords
        words += venueWords + bowlDescriptors.flatMap(splitIntoWords)
            + nicknameAdjectives + nicknameNouns
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
