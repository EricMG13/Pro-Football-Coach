import Foundation

/// Name pools for generated players and staff. Everything here is invented or generic —
/// no real player is referenced. The college list doubles as flavour: these are the same
/// kinds of fictional schools the college game in this genre uses.
public enum NameBank {

    public static let firstNames: [String] = [
        "Aaron", "Adrian", "Ahmad", "Alden", "Alonzo", "Amari", "Andre", "Angelo", "Anthony", "Antoine",
        "Arturo", "Ashton", "Aurelio", "Barrett", "Beau", "Bennett", "Blake", "Bo", "Braxton", "Brendan",
        "Brock", "Bryce", "Byron", "Caleb", "Calvin", "Cameron", "Carlos", "Carter", "Cedric", "Chase",
        "Chris", "Clay", "Cole", "Colton", "Connor", "Cordell", "Craig", "Cyrus", "Dallas", "Damian",
        "Damon", "Daniel", "Darius", "Darnell", "Dashawn", "Davion", "Dean", "Demetrius", "Denzel", "Derek",
        "Deshawn", "Desmond", "Devante", "Devin", "Dominic", "Donnell", "Drew", "Duane", "Dylan", "Eddie",
        "Elias", "Elijah", "Emanuel", "Emmett", "Enzo", "Eric", "Ernesto", "Ethan", "Evan", "Ezra",
        "Felix", "Fernando", "Finn", "Franklin", "Gabriel", "Garrett", "Gavin", "Gerald", "Grant", "Gustavo",
        "Hakeem", "Harrison", "Hayden", "Hector", "Hendrick", "Holden", "Hugo", "Ian", "Isaiah", "Ivan",
        "Jabari", "Jace", "Jackson", "Jalen", "Jamal", "Jameson", "Jared", "Jarrett", "Javier", "Jaxon",
        "Jerome", "Jesse", "Joaquin", "Jonah", "Jordan", "Josiah", "Julian", "Julius", "Justice", "Kade",
        "Kai", "Kareem", "Keegan", "Keenan", "Kellen", "Kendrick", "Kenji", "Keon", "Kevin", "Khalil",
        "Kian", "Kobe", "Kwame", "Kyler", "Lamar", "Lance", "Landon", "Lars", "Leon", "Levi",
        "Liam", "Lorenzo", "Lucas", "Luka", "Malachi", "Malik", "Marcus", "Mario", "Mateo", "Maurice",
        "Maverick", "Maxwell", "Micah", "Miguel", "Mitchell", "Mohamed", "Montrell", "Nash", "Nathan", "Nico",
        "Noah", "Nolan", "Omar", "Orlando", "Oscar", "Owen", "Pablo", "Parker", "Patrick", "Paulo",
        "Percy", "Peyton", "Phillip", "Preston", "Quentin", "Quincy", "Rafael", "Raheem", "Ramon", "Rashad",
        "Reggie", "Rene", "Ricardo", "Riley", "Roman", "Ronan", "Rory", "Rowan", "Ruben", "Russell",
        "Ryder", "Samir", "Santiago", "Saul", "Sebastian", "Shane", "Silas", "Simeon", "Solomon", "Spencer",
        "Stefan", "Sterling", "Tariq", "Tate", "Terrance", "Theo", "Thiago", "Tobias", "Trevon", "Tristan",
        "Tyrell", "Tyson", "Ulysses", "Vance", "Vicente", "Victor", "Wade", "Walter", "Wesley", "Weston",
        "Wyatt", "Xavier", "Yusuf", "Zachary", "Zane", "Zion",
    ]

    public static let lastNames: [String] = [
        "Abbott", "Acosta", "Adkins", "Aguilar", "Alcorn", "Alderman", "Alvarado", "Ambrose", "Archer", "Ashford",
        "Atwater", "Bader", "Bagley", "Ballinger", "Bannister", "Barlow", "Barrera", "Bassett", "Beckham", "Bellamy",
        "Benavides", "Bergstrom", "Bettencourt", "Birdsong", "Blackmon", "Blanchard", "Bolden", "Bordeaux", "Bowers", "Bradshaw",
        "Brannon", "Bridgewater", "Brisco", "Brockman", "Buchanan", "Bulloch", "Burkhart", "Byrd", "Cabrera", "Calloway",
        "Camarillo", "Cardoza", "Carrington", "Cartwright", "Castellano", "Cavanaugh", "Chandler", "Chapman", "Chastain", "Childress",
        "Clemons", "Cobbs", "Colburn", "Coleridge", "Colson", "Conyers", "Copeland", "Cortez", "Cousins", "Crawley",
        "Crenshaw", "Crockett", "Cullen", "Dalrymple", "Danforth", "Darby", "Davenport", "Delacroix", "Delgado", "Demarco",
        "Devereaux", "Dillard", "Donovan", "Dorsey", "Doughty", "Driscoll", "Dunlap", "Eastwood", "Eckhart", "Eldridge",
        "Ellington", "Emerson", "Escobar", "Everly", "Fairbanks", "Falcone", "Farrington", "Faulkner", "Ferreira", "Fitzgerald",
        "Fontaine", "Forrester", "Fowler", "Franklin", "Frazier", "Fulcher", "Gallagher", "Galloway", "Garrison", "Gentry",
        "Gillespie", "Goddard", "Goldsmith", "Granger", "Greaves", "Greenlee", "Grimaldi", "Guerrero", "Hadley", "Halloran",
        "Hampton", "Hargrove", "Harmon", "Hartline", "Hawkins", "Hayworth", "Hendricks", "Hollifield", "Holloway", "Hollins",
        "Huntley", "Ingram", "Ironside", "Jamison", "Jansen", "Jarvis", "Jennings", "Kaminski", "Kearney", "Keller",
        "Kendrick", "Kilgore", "Kingsley", "Kirkland", "Knowles", "Ladner", "Lambert", "Landry", "Langford", "Larkin",
        "Lattimore", "Ledbetter", "Leland", "Lennox", "Lightfoot", "Livingston", "Lockhart", "Lombardi", "Longstreet", "Lowery",
        "Lundquist", "Mackey", "Maddox", "Magnussen", "Mallory", "Marchetti", "Marsden", "Mathis", "Maxfield", "McAllister",
        "McCraw", "McKinnon", "Meadows", "Mendoza", "Merriweather", "Milburn", "Monroe", "Montague", "Moreau", "Mulligan",
        "Nakamura", "Navarro", "Nesbitt", "Nightingale", "Norwood", "Oakley", "Okafor", "Oliphant", "Ortega", "Osgood",
        "Pemberton", "Pennington", "Peralta", "Pettigrew", "Pickering", "Pinckney", "Prescott", "Pruitt", "Quarles", "Radcliffe",
        "Rasmussen", "Redmond", "Renfro", "Rhodes", "Ridgeway", "Rinaldi", "Rockwell", "Rothwell", "Rutherford", "Salazar",
        "Sanderson", "Sartori", "Sawyer", "Schaefer", "Sedgwick", "Sheppard", "Sinclair", "Skyler", "Somers", "Southerland",
        "Stackhouse", "Stallworth", "Stanton", "Stillwell", "Stockton", "Strickland", "Sutherland", "Swindell", "Talbot", "Tanaka",
        "Thackeray", "Thibodeaux", "Thornbury", "Tillman", "Torrence", "Trafford", "Trevino", "Underwood", "Valencia", "Vandermeer",
        "Vaughn", "Vega", "Verrett", "Villanueva", "Wainwright", "Wakefield", "Waverly", "Weatherby", "Westbrook", "Wheatley",
        "Whitfield", "Wilkerson", "Winslow", "Witherspoon", "Woodard", "Wyndham", "Yarborough", "Yates", "Zamora", "Zeller",
    ]

    /// Fictional alma maters — a nod to the college game this grew out of.
    public static let colleges: [String] = [
        "Palmetto State", "Port City", "Provo Tech", "Cascade", "Great Basin", "Iron Range",
        "Lakeshore", "Magnolia A&M", "Midland State", "North Bay", "Ozark", "Pine Bluff",
        "Prairie State", "Redrock", "Riverbend", "Sandhills", "Silver Creek", "Southern Ridge",
        "Sun Valley", "Tidewater", "Timberline", "Twin Forks", "Valley Central", "Western Reserve",
        "Whitewater", "Wind River", "Bayou State", "Blue Ridge", "Canyon State", "Copper Hills",
        "Delta State", "Eastport", "Fox River", "Gulf Coast", "Harbor Point", "High Plains",
        "Kettle Creek", "Lone Pine", "Marshland", "Northern Lakes", "Old Dominion Tech", "Quarry Hill",
        "Rockford", "Saltmarsh", "Steel City", "Thunder Bay", "Union Falls", "Vista Ridge",
    ]

    public static func firstName(_ rng: inout SeededRandom) -> String { rng.pick(firstNames) }
    public static func lastName(_ rng: inout SeededRandom) -> String { rng.pick(lastNames) }
    public static func college(_ rng: inout SeededRandom) -> String { rng.pick(colleges) }

    public static func fullName(_ rng: inout SeededRandom) -> (first: String, last: String) {
        (firstName(&rng), lastName(&rng))
    }
}
