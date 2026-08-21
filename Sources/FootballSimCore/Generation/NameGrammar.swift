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

    /// Every place, for the legal sweep to enumerate rather than sample.
    public static var everyPlace: [String] { realAmericanPlaces }

    /// The city a place name is qualified by, with the state dropped.
    ///
    /// The stored place stays state-qualified because two members can sit in same-named towns in
    /// different states, and the map needs to tell them apart. A team's *public* name does not
    /// carry a state — no league writes one — so the school and club forms below take this.
    public static func cityWithoutState(_ place: String) -> String {
        let city = place.split(separator: ",").first.map {
            $0.trimmingCharacters(in: .whitespaces)
        } ?? place
        // A handful of Census entries disambiguate with a parenthetical -- "Bath (Berkeley
        // Springs)". That belongs in a gazetteer, not on a scoreboard.
        guard let bracket = city.firstIndex(of: "(") else { return city }
        return String(city[city.startIndex..<bracket]).trimmingCharacters(in: .whitespaces)
    }

    /// The school half of a college team's public name: a real place and, three times in four, a
    /// generic academic qualifier.
    ///
    /// Sports usage drops the head noun. A programme is "Kent State", not "Kent State University",
    /// and the shortened form is what a scoreboard, a bracket and a standings row all carry, so
    /// that is what this emits. The first draw stays a four-way branch and the second stays a
    /// single pick, so changing the vocabulary adds and removes no random draws and stable IDs do
    /// not move.
    public static func institutionName(place: String, using rng: inout SeededRandom) -> String {
        switch rng.int(in: 0...3) {
        case 0: return place
        default:
            let index = rng.int(in: 0...(institutionWords.count - 1))
            return "\(place) \(clearedDescriptor(for: place, startingAt: index))"
        }
    }

    /// The first descriptor from `index` onwards that does not make a blocked name of this place.
    ///
    /// Stepping, not redrawing. A reject-and-redraw loop consumes a data-dependent number of draws,
    /// which is exactly the stream coupling `distinctPlaceNames` above was rewritten to remove;
    /// stepping costs none. Nothing collides today — the whole cross product of places, descriptors,
    /// adjectives and nouns was swept clear — but the blocklist is refreshed per release, and
    /// without this a new entry would turn a legal-list update into a silently different world.
    private static func clearedDescriptor(for place: String, startingAt index: Int) -> String {
        for offset in 0..<institutionWords.count {
            let word = institutionWords[(index + offset) % institutionWords.count]
            if !Blocklist.blocks("\(place) \(word)") { return word }
        }
        return institutionWords[index]
    }

    /// A bowl-game title that uses a real host place and a generic event descriptor.
    ///
    /// The engine currently stores postseason stage rather than a title; callers that project a
    /// bowl badge should use this instead of a protected legacy bowl name.
    public static func bowlName(place: String, using rng: inout SeededRandom) -> String {
        "\(place) \(rng.pick(bowlDescriptors))"
    }

    /// A team nickname: an adjective and a noun, both from invented or generic pools.
    ///
    /// Two draws, as before. The noun steps rather than redraws for the same reason a descriptor
    /// does, so a future blocklist entry cannot move the stream.
    public static func nickname(using rng: inout SeededRandom) -> String {
        let adjective = rng.pick(nicknameAdjectives)
        let index = rng.int(in: 0...(nicknameNouns.count - 1))
        for offset in 0..<nicknameNouns.count {
            let noun = nicknameNouns[(index + offset) % nicknameNouns.count]
            if !Blocklist.blocks("\(adjective) \(noun)") { return "\(adjective) \(noun)" }
        }
        return "\(adjective) \(nicknameNouns[index])"
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
    /// Every place a member can be sited in.
    ///
    /// A public name now begins with its city, so a city that is also a real programme would head a
    /// blocked institution name. `LegalTests` asserts that by construction over the whole pool.
    ///
    /// **Rebuilt 2026-08-21.** The list had been read alphabetically out of a gazetteer and cut at
    /// 570: **375 entries began with A and 109 with B**, so 85 per cent of the pool was A or B and
    /// six letters were absent outright. The sampling was faithful, which was the problem — the 166
    /// members of a world reproduced that distribution exactly, and a league where two thirds of the
    /// teams are named after A-towns reads as generated on sight.
    ///
    /// The count is held at exactly 570 because `distinctPlaceNames` shuffles this array and a
    /// shuffle costs one draw per element. Substituting entries keeps the random stream where it
    /// was and every stable id with it; adding or removing even one would move every id generated
    /// afterwards and de-key the whole logo catalogue.
    private static let realAmericanPlaces = [
        "Adak, AK",
        "Abbeville, AL",
        "Adona, AR",
        "Apache Junction, AZ",
        "Adelanto, CA",
        "Aguilar, CO",
        "Ansonia, CT",
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
        "Bellefonte, DE",
        "Berlin, NH",
        "Boulder City, NV",
        "Barre, VT",
        "Bridgeport, CT",
        "Bethany Beach, DE",
        "Bangor, ME",
        "Bainville, MT",
        "Burlington, VT",
        "Benson, AZ",
        "Bristol, CT",
        "Bethel, DE",
        "Bath, ME",
        "Baker, MT",
        "Batavia, NY",
        "Bisbee, AZ",
        "Blades, DE",
        "Baltimore, MD",
        "Belfast, ME",
        "Bearcreek, MT",
        "Bayonne, NJ",
        "Beacon, NY",
        "Baggs, WY",
        "Buckeye, AZ",
        "Bowers, DE",
        "Barnstable Town, MA",
        "Barclay, MD",
        "Biddeford, ME",
        "Belgrade, MT",
        "Belvidere, NJ",
        "Binghamton, NY",
        "Beaver Falls, PA",
        "Bairoil, WY",
        "Bullhead City, AZ",
        "Bridgeville, DE",
        "Beverly, MA",
        "Barnesville, MD",
        "Brewer, ME",
        "Belt, MT",
        "Beverly, NJ",
        "Bayard, NM",
        "Central Falls, RI",
        "Claremont, NH",
        "Caliente, NV",
        "Cranston, RI",
        "Concord, NH",
        "Carlin, NV",
        "Canandaigua, NY",
        "Camp Verde, AZ",
        "Camden, DE",
        "Calais, ME",
        "Cohoes, NY",
        "Carefree, AZ",
        "Cheswold, DE",
        "Caribou, ME",
        "Corning, NY",
        "Casa Grande, AZ",
        "Clayton, DE",
        "Cortland, NY",
        "Cave Creek, AZ",
        "Carlsbad, NM",
        "Carbondale, PA",
        "Chandler, AZ",
        "Cambridge, MA",
        "Carrizozo, NM",
        "Chester, PA",
        "Chino Valley, AZ",
        "Chelsea, MA",
        "Camden, NJ",
        "Clayton, NM",
        "Cadillac, MI",
        "Calexico, CA",
        "Camas, WA",
        "Cambridge, MD",
        "Canby, OR",
        "Canton, MS",
        "Carbondale, IL",
        "Carlisle, PA",
        "Carthage, MO",
        "Cascade, ID",
        "Casper, WY",
        "Castine, ME",
        "Cedarburg, WI",
        "Celina, OH",
        "Centralia, WA",
        "Chanute, KS",
        "Chappell, NE",
        "Charlevoix, MI",
        "Chatham, MA",
        "Danbury, CT",
        "Dover, NH",
        "Derby, CT",
        "Dagsboro, DE",
        "Dunkirk, NY",
        "Delaware City, DE",
        "Delmar, DE",
        "Dalhart, TX",
        "Dallas, OR",
        "Danville, KY",
        "Darien, CT",
        "Davenport, WA",
        "Dayton, TN",
        "Deadwood, SD",
        "Decorah, IA",
        "Deerfield, IL",
        "Defiance, OH",
        "Delano, CA",
        "Delavan, WI",
        "Deming, NM",
        "Denison, IA",
        "East Providence, RI",
        "Essex Junction, VT",
        "Elko, NV",
        "Ely, NV",
        "Eastport, ME",
        "Ellsworth, ME",
        "Elmira, NY",
        "Eagle River, WI",
        "Eatonton, GA",
        "Edenton, NC",
        "Edgartown, MA",
        "Effingham, IL",
        "Elberton, GA",
        "Eldora, IA",
        "Elkins, WV",
        "Ellensburg, WA",
        "Emporia, KS",
        "Enterprise, AL",
        "Ephraim, UT",
        "Erwin, TN",
        "Escanaba, MI",
        "Franklin, NH",
        "Fallon, NV",
        "Fernley, NV",
        "Fulton, NY",
        "Fairbury, NE",
        "Fairfield, IA",
        "Falmouth, MA",
        "Fargo, ND",
        "Farmington, NM",
        "Fayette, MO",
        "Fennimore, WI",
        "Fergus Falls, MN",
        "Fillmore, UT",
        "Findlay, OH",
        "Flagstaff, AZ",
        "Flandreau, SD",
        "Florence, AL",
        "Fontanelle, IA",
        "Fordyce, AR",
        "Forest City, IA",
        "Fort Benton, MT",
        "Groton, CT",
        "Gardiner, ME",
        "Gaffney, SC",
        "Gainesville, TX",
        "Galena, IL",
        "Gallipolis, OH",
        "Galveston, TX",
        "Garden City, KS",
        "Gaylord, MI",
        "Geneseo, NY",
        "Georgetown, SC",
        "Gettysburg, PA",
        "Gillette, WY",
        "Glasgow, MT",
        "Glenwood Springs, CO",
        "Gloucester, MA",
        "Golden, CO",
        "Goldendale, WA",
        "Gonzales, TX",
        "Goshen, IN",
        "Gothenburg, NE",
        "Grafton, WV",
        "Granbury, TX",
        "Grangeville, ID",
        "Grants Pass, OR",
        "Greeneville, TN",
        "Hartford, CT",
        "Henderson, NV",
        "Hallowell, ME",
        "Hagerstown, MD",
        "Halifax, VA",
        "Hamilton, MT",
        "Hammondsport, NY",
        "Hanover, NH",
        "Harlan, KY",
        "Harrisonburg, VA",
        "Hartsville, SC",
        "Hastings, NE",
        "Havre, MT",
        "Hayward, WI",
        "Healdsburg, CA",
        "Helena, MT",
        "Hendersonville, NC",
        "Hermann, MO",
        "Hibbing, MN",
        "Hillsboro, OR",
        "Hinton, WV",
        "Hobbs, NM",
        "Holdrege, NE",
        "Holly Springs, MS",
        "Homer, AK",
        "Hood River, OR",
        "Hopkinsville, KY",
        "Hot Springs, SD",
        "Houlton, ME",
        "Hudson, NY",
        "Humboldt, IA",
        "Idaho Falls, ID",
        "Independence, KS",
        "Indianola, IA",
        "Inverness, FL",
        "Ionia, MI",
        "Ida Grove, IA",
        "Ipswich, MA",
        "Iron Mountain, MI",
        "Ironwood, MI",
        "Irvington, VA",
        "Jackson, WY",
        "Jacksonville, IL",
        "Jamestown, ND",
        "Janesville, WI",
        "Jasper, IN",
        "Jefferson, TX",
        "Jerome, ID",
        "Jesup, GA",
        "Johnstown, PA",
        "Joliet, IL",
        "Keene, NH",
        "Kalispell, MT",
        "Kanab, UT",
        "Kearney, NE",
        "Kenai, AK",
        "Kennebunk, ME",
        "Keokuk, IA",
        "Kerrville, TX",
        "Ketchikan, AK",
        "Kewanee, IL",
        "Keyser, WV",
        "Kingfisher, OK",
        "Kingsville, TX",
        "Kinsley, KS",
        "Kirksville, MO",
        "Klamath Falls, OR",
        "Laconia, NH",
        "Lebanon, NH",
        "Las Vegas, NV",
        "Lovelock, NV",
        "La Crosse, WI",
        "La Grande, OR",
        "Lafayette, IN",
        "Lakeview, OR",
        "Lamar, CO",
        "Lancaster, PA",
        "Lander, WY",
        "Langdon, ND",
        "Lapeer, MI",
        "Laramie, WY",
        "Laredo, TX",
        "Larned, KS",
        "Laurel, MS",
        "Lawrenceburg, IN",
        "Leadville, CO",
        "Leesburg, VA",
        "Lehi, UT",
        "Lenox, MA",
        "Levelland, TX",
        "Lewisburg, WV",
        "Lexington, VA",
        "Liberal, KS",
        "Lihue, HI",
        "Lincolnton, NC",
        "Litchfield, CT",
        "Livingston, MT",
        "Lock Haven, PA",
        "Montpelier, VT",
        "Meriden, CT",
        "Middletown, CT",
        "Manchester, NH",
        "Mesquite, NV",
        "Mackinaw City, MI",
        "Macomb, IL",
        "Madisonville, KY",
        "Malta, MT",
        "Manchester, VT",
        "Manistee, MI",
        "Mankato, MN",
        "Manti, UT",
        "Marfa, TX",
        "Marietta, OH",
        "Marion, VA",
        "Marlborough, NH",
        "Marshalltown, IA",
        "Martinsburg, WV",
        "Maryville, MO",
        "Mason City, IA",
        "Mattoon, IL",
        "McCall, ID",
        "McCook, NE",
        "McMinnville, OR",
        "Meadville, PA",
        "Medora, ND",
        "Menominee, MI",
        "Merrill, WI",
        "Mexico, MO",
        "Middlebury, VT",
        "Milbank, SD",
        "Miles City, MT",
        "Milford, DE",
        "Millinocket, ME",
        "Mineral Wells, TX",
        "Minot, ND",
        "Missoula, MT",
        "Mitchell, SD",
        "Moab, UT",
        "Moberly, MO",
        "Newport, RI",
        "Newport, VT",
        "New Britain, CT",
        "Nashua, NH",
        "New Haven, CT",
        "New London, CT",
        "North Las Vegas, NV",
        "Nacogdoches, TX",
        "Nampa, ID",
        "Nantucket, MA",
        "Napoleon, OH",
        "Natchez, MS",
        "Neosho, MO",
        "Needles, CA",
        "Nephi, UT",
        "New Prague, MN",
        "New Bern, NC",
        "New Castle, PA",
        "New Iberia, LA",
        "New Ulm, MN",
        "Newberry, SC",
        "Ogallala, NE",
        "Oak Bluffs, MA",
        "Oberlin, KS",
        "Ocean City, NJ",
        "Oconto, WI",
        "Odessa, TX",
        "Oil City, PA",
        "Okmulgee, OK",
        "Olney, IL",
        "Onawa, IA",
        "Oneonta, NY",
        "Ontonagon, MI",
        "Opelika, AL",
        "Orangeburg, SC",
        "Ocean Springs, MS",
        "Orofino, ID",
        "Petoskey, MI",
        "Pawtucket, RI",
        "Providence, RI",
        "Portsmouth, NH",
        "Paducah, KY",
        "Pahrump, NV",
        "Palestine, TX",
        "Paola, KS",
        "Paris, TN",
        "Parkersburg, WV",
        "Pascagoula, MS",
        "Pawhuska, OK",
        "Payson, AZ",
        "Pecos, TX",
        "Pella, IA",
        "Pendleton, OR",
        "Penn Yan, NY",
        "Pensacola, FL",
        "Perry, OK",
        "Petersburg, AK",
        "Philipsburg, MT",
        "Picayune, MS",
        "Pierre, SD",
        "Pinedale, WY",
        "Pipestone, MN",
        "Plainview, TX",
        "Plattsburgh, NY",
        "Pocatello, ID",
        "Ponca City, OK",
        "Poplar Bluff, MO",
        "Port Angeles, WA",
        "Quakertown, PA",
        "Quincy, IL",
        "Quitman, GA",
        "Rutland, VT",
        "Rochester, NH",
        "Radford, VA",
        "Rangeley, ME",
        "Rapid City, SD",
        "Raton, NM",
        "Ravenna, OH",
        "Red Lodge, MT",
        "Red Wing, MN",
        "Redding, CA",
        "Rexburg, ID",
        "Rhinelander, WI",
        "Richfield, UT",
        "Ridgway, CO",
        "Rifle, CO",
        "Ripon, WI",
        "Riverton, WY",
        "Roanoke Rapids, NC",
        "Rock Springs, WY",
        "Rockland, ME",
        "Rocky Mount, NC",
        "Rolla, MO",
        "Roseburg, OR",
        "Roswell, NM",
        "Ruidoso, NM",
        "Rumford, ME",
        "South Burlington, VT",
        "St. Albans, VT",
        "Sturgis, SD",
        "Sabetha, KS",
        "Safford, AZ",
        "Saguache, CO",
        "Salida, CO",
        "Salina, KS",
        "Sallisaw, OK",
        "San Angelo, TX",
        "Sandpoint, ID",
        "Sandusky, OH",
        "Saranac Lake, NY",
        "Savanna, IL",
        "Sayre, PA",
        "Scottsbluff, NE",
        "Sedalia, MO",
        "Selma, AL",
        "Seward, AK",
        "Shamokin, PA",
        "Sharon, PA",
        "Shawano, WI",
        "Shelbyville, KY",
        "Shenandoah, IA",
        "Sheridan, WY",
        "Sidney, MT",
        "Sikeston, MO",
        "Siloam Springs, AR",
        "Silver City, NM",
        "Sitka, AK",
        "Skowhegan, ME",
        "Smithfield, NC",
        "Snohomish, WA",
        "Socorro, NM",
        "Somerset, KY",
        "Sonora, CA",
        "Spearfish, SD",
        "Spencer, IA",
        "Spooner, WI",
        "Springville, UT",
        "St. Ignace, MI",
        "Statesboro, GA",
        "Staunton, VA",
        "Steamboat Springs, CO",
        "Sterling, CO",
        "Stillwater, MN",
        "Sulphur Springs, TX",
        "Sumter, SC",
        "Tillamook, OR",
        "Tahlequah, OK",
        "Talladega, AL",
        "Tallulah, LA",
        "Taos, NM",
        "Tarboro, NC",
        "Taylorville, IL",
        "Tekamah, NE",
        "Telluride, CO",
        "Terre Haute, IN",
        "Texarkana, AR",
        "The Dalles, OR",
        "Thermopolis, WY",
        "Thibodaux, LA",
        "Tiffin, OH",
        "Titusville, PA",
        "Toccoa, GA",
        "Tomah, WI",
        "Tonopah, NV",
        "Torrington, WY",
        "Traverse City, MI",
        "Ukiah, CA",
        "Union, SC",
        "Uniontown, PA",
        "Upper Sandusky, OH",
        "Urbana, IL",
        "Vergennes, VT",
        "Vale, OR",
        "Valdosta, GA",
        "Valentine, NE",
        "Valparaiso, IN",
        "Van Buren, AR",
        "Vandalia, IL",
        "Ventura, CA",
        "Vernal, UT",
        "Vicksburg, MS",
        "Wahpeton, ND",
        "Warwick, RI",
        "Woonsocket, RI",
        "Winooski, VT",
        "Wabash, IN",
        "Wadena, MN",
        "Waimea, HI",
        "Walla Walla, WA",
        "Wallace, ID",
        "Wapakoneta, OH",
        "Warrensburg, MO",
        "Waseca, MN",
        "Watertown, SD",
        "Waupaca, WI",
        "Waurika, OK",
        "Waverly, IA",
        "Waxahachie, TX",
        "Waynesboro, VA",
        "Weatherford, OK",
        "Webster City, IA",
        "Weiser, ID",
        "Wellsboro, PA",
        "Wenatchee, WA",
        "West Point, NE",
        "Weston, WV",
        "Wheeling, WV",
        "Whitefish, MT",
        "Wilber, NE",
        "Williamsport, PA",
        "Williston, ND",
        "Willmar, MN",
        "Wilmington, OH",
        "Winnemucca, NV",
        "Winona, MN",
        "Winterset, IA",
        "Wiscasset, ME",
        "Yreka, CA",
        "Yakima, WA",
        "Yankton, SD",
        "Yazoo City, MS",
        "York, NE",
        "Zanesville, OH",
        "Zebulon, NC",
        "Zeeland, MI",
        "Zion, IL",
        "Zumbrota, MN",
    ]
    private static let compassWords = [
        "North", "South", "East", "West", "Upper", "Lower", "Central", "Coastal", "Inland",
    ]
    // The short forms a college team is actually called by. "Normal", "Research" and "Institute of
    // Technology" were here and are how a registrar writes a school, not how a scoreboard does.
    private static let institutionWords = [
        "State", "A&M", "Tech", "Poly", "Valley", "Coastal", "Maritime", "Agricultural",
        "Regional", "Central",
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
        // Added 2026-08-21 with the nouns below. Every member showed a nickname from that date --
        // college programmes had one all along and never displayed it -- so 18 by 22 was suddenly
        // 166 members drawing from 396 pairs, and the duplicates were on the glass.
        "Basalt", "Flint", "Cobalt", "Tidal", "Bramble", "Cedar", "Gale", "Anvil", "Hearth",
        "Kiln", "Meridian", "Marsh", "Peat", "Shale",
    ]
    // Miners, Lancers, Stags and Pioneers were here and are real Division I nicknames (UTEP,
    // Longwood, Fairfield, Denver). They are replaced one-for-one rather than deleted: the pool is
    // 22 nouns against 166 teams per save, and shrinking it makes the duplicate-nickname problem
    // worse, not better.
    private static let nicknameNouns = [
        "Wardens", "Drovers", "Delvers", "Sentinels", "Bulwarks", "Foresters", "Marauders",
        "Prospectors", "Voyagers", "Reapers", "Anchors", "Wayfarers", "Wreckers", "Harriers",
        "Stalkers", "Herons", "Colliers", "Otters", "Ironsides", "Quarrymen", "Beacons", "Kestrels",
        // Trades, defences and less-claimed wildlife, on the same principle as the originals: a
        // nickname a real programme already owns is refused however good it sounds. The full cross
        // product of 570 places, 11 school forms, 32 adjectives and 40 nouns -- 8,025,600 public
        // names -- was swept against the blocklist before these landed, and none is blocked.
        "Tanners", "Coopers", "Sawyers", "Riggers", "Ferrymen", "Smelters", "Chandlers",
        "Fletchers", "Bastions", "Ramparts", "Palisades", "Cairns", "Lodestars", "Shrikes",
        "Curlews", "Goshawks", "Martens", "Wyverns",
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
