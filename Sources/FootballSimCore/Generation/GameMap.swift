import Foundation

/// A place on the generated map.
///
/// D6: "Geography first. Place is a mechanic, not flavour text." Distance drives recruiting reach,
/// travel fatigue and rivalry candidacy, so coordinates are integers in a fixed grid — a
/// floating-point map would make distance comparisons drift between platforms and take
/// cross-process determinism with them.
public struct MapCity: Codable, Sendable, Equatable, Identifiable {
    public let id: UUID
    public let name: String
    public let regionID: UUID
    /// Grid units. `GameMap.width` by `GameMap.height`.
    public let x: Int
    public let y: Int
    /// Population on the rating scale, so it is comparable with prestige and resources.
    public let marketSize: Rating

    public init(id: UUID, name: String, regionID: UUID, x: Int, y: Int, marketSize: Rating) {
        self.id = id
        self.name = name
        self.regionID = regionID
        self.x = x
        self.y = y
        self.marketSize = marketSize
    }

    /// Squared grid distance. Squared, because every use is a comparison and a square root buys
    /// nothing but a chance to disagree across platforms.
    public func squaredDistance(to other: MapCity) -> Int {
        let dx = x - other.x, dy = y - other.y
        return dx * dx + dy * dy
    }
}

/// A region: a named cluster of cities, and the unit recruiting reach is expressed in.
public struct MapRegion: Codable, Sendable, Equatable, Identifiable {
    public let id: UUID
    public let name: String
    /// Talent produced per class, on the rating scale. The reason a region is worth reaching into.
    public let talentDensity: Rating

    public init(id: UUID, name: String, talentDensity: Rating) {
        self.id = id
        self.name = name
        self.talentDensity = talentDensity
    }
}

/// The generated map.
public struct GameMap: Codable, Sendable, Equatable {
    public static let width = 1000
    public static let height = 700
    public static let regionCount = 8

    public let regions: [MapRegion]
    public let cities: [MapCity]

    public init(regions: [MapRegion], cities: [MapCity]) {
        self.regions = regions
        self.cities = cities
    }

    public func city(_ id: UUID) -> MapCity? { cities.first { $0.id == id } }

    /// Generates regions and one city per member, seeded.
    ///
    /// Cities are placed by region so that geography clusters, which is what makes a
    /// geography-seeded rivalry mean anything: a map of uniformly scattered points produces rivals
    /// that are near each other by accident rather than by place.
    public static func generate(cityCount: Int, using rng: inout SeededRandom) -> GameMap {
        var regions: [MapRegion] = []
        var regionCentres: [(x: Int, y: Int)] = []
        for index in 0..<regionCount {
            regions.append(MapRegion(
                id: rng.uuid(),
                name: "\(NameGrammar.placeName(using: &rng)) \(regionWord(index))",
                talentDensity: Rating(rng.int(in: 45...95))
            ))
            regionCentres.append((
                x: rng.int(in: width / 8...(width - width / 8)),
                y: rng.int(in: height / 8...(height - height / 8))
            ))
        }

        // Drawn without replacement. See `NameGrammar.distinctPlaceNames`: with replacement, every
        // league carried duplicate city names and two-thirds carried two programmes with the
        // identical full name.
        var placeNames = NameGrammar.distinctPlaceNames(using: &rng)
        // Guard rather than trap, because D14's fallback can change the league size and a larger
        // map is a foreseeable change. Falling back to drawing with replacement keeps generation
        // working and is caught by the uniqueness test rather than by a crash.
        if placeNames.count < cityCount {
            while placeNames.count < cityCount {
                placeNames.append(NameGrammar.placeName(using: &rng))
            }
        }

        var cities: [MapCity] = []
        for index in 0..<cityCount {
            let region = index % regionCount
            let centre = regionCentres[region]
            cities.append(MapCity(
                id: rng.uuid(),
                name: placeNames[index],
                regionID: regions[region].id,
                x: clamp(centre.x + rng.int(in: -(width / 8)...(width / 8)), 0, width),
                y: clamp(centre.y + rng.int(in: -(height / 8)...(height / 8)), 0, height),
                marketSize: Rating(rng.int(in: 40...99))
            ))
        }
        return GameMap(regions: regions, cities: cities)
    }

    /// The map's own noun pool, which lands in every region name and which
    /// `NameGrammar.emittableWords` does not know about — hence `GenerationVocabulary`.
    ///
    /// "Delta" was here and is gone: crossed with an institution word it spells Delta State, one of
    /// the six real institutions `docs/PORT-LOG.md` records the prior build shipping under a
    /// comment reading "Fictional alma maters".
    static let regionWords = [
        "Reach", "Basin", "Coast", "Uplands", "Flats", "Divide", "Marches", "Tidelands",
    ]

    static var emittableWords: [String] { regionWords }

    private static func regionWord(_ index: Int) -> String {
        regionWords[index % regionWords.count]
    }

    private static func clamp(_ value: Int, _ low: Int, _ high: Int) -> Int {
        Swift.min(Swift.max(value, low), high)
    }
}
