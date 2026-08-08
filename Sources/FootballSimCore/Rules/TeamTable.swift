import Foundation

/// The 32 fictional franchises. Every name, colour and stadium here is invented — no real
/// league's marks appear anywhere in this project.
public enum TeamTable {

    public struct Entry: Sendable {
        public let city: String
        public let name: String
        public let abbreviation: String
        public let primaryHex: String
        public let secondaryHex: String
        public let conference: Conference
        public let division: Division
        public let stadium: String
    }

    public static let entries: [Entry] = [
        // Liberty — East
        .init(city: "New York", name: "Empire", abbreviation: "NYE", primaryHex: "#14294B", secondaryHex: "#C8A24A", conference: .liberty, division: .east, stadium: "Harbor Field"),
        .init(city: "Boston", name: "Harbormen", abbreviation: "BOS", primaryHex: "#0B3D2E", secondaryHex: "#D9C89E", conference: .liberty, division: .east, stadium: "Bay Yard"),
        .init(city: "Philadelphia", name: "Founders", abbreviation: "PHF", primaryHex: "#4B2E5E", secondaryHex: "#E8D9A0", conference: .liberty, division: .east, stadium: "Liberty Grounds"),
        .init(city: "Washington", name: "Sentinels", abbreviation: "WAS", primaryHex: "#5A1F2B", secondaryHex: "#C9B27C", conference: .liberty, division: .east, stadium: "Monument Park"),

        // Liberty — North
        .init(city: "Chicago", name: "Blizzard", abbreviation: "CHB", primaryHex: "#1D3E63", secondaryHex: "#9FD7F2", conference: .liberty, division: .north, stadium: "Lakefront Dome"),
        .init(city: "Detroit", name: "Motors", abbreviation: "DET", primaryHex: "#2E4A5C", secondaryHex: "#C0C6CC", conference: .liberty, division: .north, stadium: "Assembly Field"),
        .init(city: "Cleveland", name: "Forge", abbreviation: "CLF", primaryHex: "#7A3B18", secondaryHex: "#E0A44C", conference: .liberty, division: .north, stadium: "Foundry Park"),
        .init(city: "Pittsburgh", name: "Ironmen", abbreviation: "PIT", primaryHex: "#2B2B2B", secondaryHex: "#E3B23C", conference: .liberty, division: .north, stadium: "Rivergate"),

        // Liberty — South
        .init(city: "Miami", name: "Tides", abbreviation: "MIA", primaryHex: "#0E7C86", secondaryHex: "#F2A65A", conference: .liberty, division: .south, stadium: "Coral Bowl"),
        .init(city: "Atlanta", name: "Firebirds", abbreviation: "ATL", primaryHex: "#8C1C13", secondaryHex: "#F0A202", conference: .liberty, division: .south, stadium: "Peach Yard"),
        .init(city: "Charlotte", name: "Aviators", abbreviation: "CHA", primaryHex: "#1F5673", secondaryHex: "#C3D3DC", conference: .liberty, division: .south, stadium: "Crown Field"),
        .init(city: "New Orleans", name: "Revelers", abbreviation: "NOR", primaryHex: "#4A2C6B", secondaryHex: "#E5C74F", conference: .liberty, division: .south, stadium: "Crescent Dome"),

        // Liberty — West
        .init(city: "Dallas", name: "Lonestars", abbreviation: "DAL", primaryHex: "#1B3A5C", secondaryHex: "#B0BEC5", conference: .liberty, division: .west, stadium: "Star Field"),
        .init(city: "Houston", name: "Wildcatters", abbreviation: "HOU", primaryHex: "#0F2B33", secondaryHex: "#D97706", conference: .liberty, division: .west, stadium: "Derrick Park"),
        .init(city: "Kansas City", name: "Stampede", abbreviation: "KCS", primaryHex: "#8B1E3F", secondaryHex: "#F2C14E", conference: .liberty, division: .west, stadium: "Stockyard Field"),
        .init(city: "St. Louis", name: "Archers", abbreviation: "STL", primaryHex: "#123B57", secondaryHex: "#D7A249", conference: .liberty, division: .west, stadium: "Gateway Grounds"),

        // Frontier — East
        .init(city: "Baltimore", name: "Admirals", abbreviation: "BAL", primaryHex: "#2C2A6B", secondaryHex: "#C7C9CB", conference: .frontier, division: .east, stadium: "Anchor Field"),
        .init(city: "Cincinnati", name: "Riverhawks", abbreviation: "CIN", primaryHex: "#1E4D3B", secondaryHex: "#E8873C", conference: .frontier, division: .east, stadium: "Queen City Park"),
        .init(city: "Indianapolis", name: "Racers", abbreviation: "IND", primaryHex: "#14304F", secondaryHex: "#E8E8E8", conference: .frontier, division: .east, stadium: "Speedway Dome"),
        .init(city: "Nashville", name: "Rhythm", abbreviation: "NSH", primaryHex: "#3D2C52", secondaryHex: "#E4B363", conference: .frontier, division: .east, stadium: "Music Row Field"),

        // Frontier — North
        .init(city: "Minneapolis", name: "Loons", abbreviation: "MIN", primaryHex: "#2A3D66", secondaryHex: "#9BB7D4", conference: .frontier, division: .north, stadium: "North Star Dome"),
        .init(city: "Milwaukee", name: "Barons", abbreviation: "MIL", primaryHex: "#123D2E", secondaryHex: "#CBA135", conference: .frontier, division: .north, stadium: "Brewhouse Field"),
        .init(city: "Denver", name: "Summit", abbreviation: "DEN", primaryHex: "#1F4E5F", secondaryHex: "#E76F51", conference: .frontier, division: .north, stadium: "Mile High Park"),
        .init(city: "Salt Lake", name: "Peaks", abbreviation: "SLP", primaryHex: "#3E4E88", secondaryHex: "#DCD6C8", conference: .frontier, division: .north, stadium: "Wasatch Field"),

        // Frontier — South
        .init(city: "Phoenix", name: "Scorchers", abbreviation: "PHX", primaryHex: "#A83A24", secondaryHex: "#F4C95D", conference: .frontier, division: .south, stadium: "Sun Bowl"),
        .init(city: "San Antonio", name: "Defenders", abbreviation: "SAD", primaryHex: "#4A4A4A", secondaryHex: "#C0503A", conference: .frontier, division: .south, stadium: "Mission Field"),
        .init(city: "Las Vegas", name: "Highrollers", abbreviation: "LVH", primaryHex: "#1A1A1A", secondaryHex: "#D4AF37", conference: .frontier, division: .south, stadium: "Neon Dome"),
        .init(city: "Oklahoma City", name: "Twisters", abbreviation: "OKC", primaryHex: "#2F4858", secondaryHex: "#E9C46A", conference: .frontier, division: .south, stadium: "Plains Field"),

        // Frontier — West
        .init(city: "Los Angeles", name: "Stars", abbreviation: "LAS", primaryHex: "#123C69", secondaryHex: "#EDC7B7", conference: .frontier, division: .west, stadium: "Coliseum West"),
        .init(city: "San Diego", name: "Armada", abbreviation: "SDA", primaryHex: "#14536B", secondaryHex: "#F2B441", conference: .frontier, division: .west, stadium: "Bayside Park"),
        .init(city: "San Francisco", name: "Fog", abbreviation: "SFF", primaryHex: "#5C6B73", secondaryHex: "#C5283D", conference: .frontier, division: .west, stadium: "Golden Gate Field"),
        .init(city: "Seattle", name: "Evergreens", abbreviation: "SEA", primaryHex: "#14472F", secondaryHex: "#8FBF6A", conference: .frontier, division: .west, stadium: "Rainier Dome"),
    ]

    /// Staff first/last names come from the same banks as players, so this is only the
    /// stadium-neutral list of possible team nicknames used by the custom-league editor later.
    public static func entry(abbreviation: String) -> Entry? {
        entries.first { $0.abbreviation == abbreviation }
    }
}
