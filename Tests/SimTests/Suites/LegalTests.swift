import Foundation
import FootballSimCore

// The two Tier A tests from CLAUDE.md's legal guardrail, at the thresholds 02 section 11.3.5 fixes.
//
// These are the only two limbs of the guardrail that are tests. Everything else in it is a review
// checklist item, and CLAUDE.md says so explicitly: "Do not describe prose as if it were a test."
//
// docs/PORT-LOG.md records what these exist to catch, in shipped code: a colleges array commented
// "Fictional alma maters" holding six real institutions, under a file header asserting that no real
// player was referenced. The lesson it draws is the design of these tests:
//
//   "The collision test enumerates the generated output, not the source arrays. Reading a list and
//    judging it fictional is what produced both failures."

/// `02` §11.3.5. One sweep serves both these tests and D6's falsifier.
let LEGAL_SWEEP_LEAGUES = 200

/// The seed for sweep league `index`.
///
/// This was `UInt64(index) &* 0x9E37_79B9_7F4A_7C15` — SplitMix64's own gamma, the exact constant
/// `SeededRandom.next()` adds to its state. So league *i*'s stream was league 0's stream shifted
/// forward by *i* draws, and the sweep was one stream read at 200 offsets. Measured: 795 distinct
/// colour pairs across 33,200 identities instead of 33,200, with leagues 6 through 200 contributing
/// 408 new pairs between them. **The trade-dress sweep was worth about five independent leagues**,
/// and unlike the collision test it has no by-construction limb behind it — the sweep *is* the
/// trade-dress test.
///
/// Running the index through one round of SplitMix64 decorrelates it: verified at 33,200 distinct
/// pairs, matching an independent-FNV baseline. The docstring that used to sit here claimed exactly
/// the property the constant destroyed.
func sweepSeed(_ index: Int) -> UInt64 {
    var generator = SeededRandom(seed: UInt64(index))
    return generator.next()
}

/// The swept worlds, generated once.
///
/// Three tests here plus IdentityDistributionTests all want the same 200 leagues, and generating
/// them per test made the suite four times slower for no extra coverage. Computed lazily so a run
/// that skips these suites does not pay for them.
///
/// **The canonical world is a member, not a spot-check.** `CanonicalTeamBranding` overrides every
/// name, nickname and colour at `worldSeed` and returns early at any other seed, so a sweep of
/// arbitrary seeds reads generator output that the shipped world replaces -- and the one league
/// every tester actually sees was the one league no legal test read. It sits last so the existing
/// per-index failure messages keep meaning what they meant.
let sweptWorlds: [GeneratedWorld] = (0..<LEGAL_SWEEP_LEAGUES).map {
    LeagueGenerator.generate(seed: sweepSeed($0))
} + [LeagueGenerator.generate(seed: CanonicalTeamBranding.worldSeed)]

/// Owner decision 2026-08-23: beta-level implementation is the priority; these canonical teams'
/// colour-guardrail violations are approved exceptions, addressed near the end of development
/// rather than now. Named and pinned by team id, not waved through wholesale --
/// `pendingCanonAmendment`'s pattern in DesignContractTests.swift and "the artwork still owed is
/// counted, not left to a red gate" (STATUS.md) are the same idiom: an owner-approved gap stays
/// visible and exact, so a new violation beyond this dated list still fails. Detail, examples and
/// the two guardrail counts: docs/STATUS.md, "2026-08-23 -- the legal sweep never read the shipped
/// world...". Applies to the canonical world only (`index == LEGAL_SWEEP_LEAGUES` below) -- these
/// are fixed team-id slots reused by every synthetic league too, and a synthetic league landing on
/// one of these ids by chance must still be caught.
///
/// **148 of 166, not a smaller sample.** `collidesWithTradeDress` is a ΔE < 25 CIE76 match against
/// all 71 `Blocklist.tradeDress` pairs in both orderings -- the near-miss standard `02` section
/// 11.3.5 fixes, not exact-hex equality. The 200 synthetic leagues never produce a single offender
/// because `ColourGenerator.next` rejects and retries any pair that collides before returning it;
/// the canonical table is hand-authored and was never run through that filter, so it drew from the
/// same general "bold sports colour" palette real programmes draw from and lands near one of 71
/// real pairs at a very high rate once both colours and both orderings are checked.
let ownerApprovedTradeDressExceptions: Set<UUID> = [
    UUID(uuidString: "0017F958-E7D0-4FFC-9EA8-01A252B40FD6")!,  // Zumbrota Central Lodestars
    UUID(uuidString: "00A6282E-56F8-4971-953D-08DB822B3CC7")!,  // Winnemucca Agricultural Atoms
    UUID(uuidString: "00EBE0C0-2B2B-4988-A450-BB870D6D3881")!,  // Union Maritime Sentinels
    UUID(uuidString: "02D86903-1751-489C-83A9-579368E3BB40")!,  // Binghamton Shrikes
    UUID(uuidString: "0344382F-0BA9-4C30-A1FF-EEF7E9DCE73D")!,  // Carlin A&M Founders
    UUID(uuidString: "07CA9577-9354-4F7D-8ED8-E60A784DB48F")!,  // Milford Coastal Nightwings
    UUID(uuidString: "0D81D2F9-0383-4BD5-A741-76604D277691")!,  // Rexburg A&M Sharks
    UUID(uuidString: "0E106627-801B-485A-A173-B723F51CD305")!,  // Middlebury Coastal Goshawks
    UUID(uuidString: "0E961082-75BA-47B1-A5B4-CAFEF9D9DC93")!,  // Dagsboro Comets
    UUID(uuidString: "0F05F4F3-68CA-4674-B210-9DD7B75E1088")!,  // Edgartown Arbors
    UUID(uuidString: "0FB78D18-D089-4719-B861-DD1E9F9C2082")!,  // Ephraim Maritime Stallions
    UUID(uuidString: "1032E7BD-52E6-4C02-85D4-4DC399B13B7A")!,  // Hood River Maritime Gaffers
    UUID(uuidString: "10AA9D4C-D1C1-4E25-9B8B-86520D782A68")!,  // Zeeland Sabrecats
    UUID(uuidString: "10B39F02-2AE6-489D-964E-3A3AC7C808AC")!,  // Oneonta Bitterns
    UUID(uuidString: "10E07F5C-24A8-414C-83AE-8B54CBE2BCB8")!,  // Hamilton Ursids
    UUID(uuidString: "14A2B6E2-62D4-4F68-B5C8-99DD51B84249")!,  // New London Valley Kestrels
    UUID(uuidString: "1652A3B7-3E69-4E18-88F0-B2E2F0ADBA86")!,  // Kanab Tempests
    UUID(uuidString: "16A673C3-8E4D-4C59-A0EA-2D3047C8D6EA")!,  // Lexington Regional Curlews
    UUID(uuidString: "1982A97F-CD2B-459B-AF23-89D5151A9829")!,  // New Castle Maritime Sentinels
    UUID(uuidString: "1C8CC9B1-F549-4AE4-8CF1-8E4C718D0245")!,  // San Angelo A&M Hoplites
    UUID(uuidString: "218774CA-1F35-4B02-9FAA-54C54191C80F")!,  // Watertown Coastal Reapers
    UUID(uuidString: "234A4A68-7B33-464E-801A-D4A52CD357B5")!,  // Weiser Valley Marlins
    UUID(uuidString: "236E7A67-CFFC-4AD0-A041-DABDD7CB3492")!,  // Danville Curlews
    UUID(uuidString: "26C528C1-BFD0-4048-B126-D9B601B22071")!,  // Laurel Tech Squall
    UUID(uuidString: "29C6A2AE-BFCA-4266-81A5-DF123A3DB00D")!,  // Goshen Prowlers
    UUID(uuidString: "2DBDBC5E-18D2-417B-BC73-C6596576F72B")!,  // Shelbyville Poly Pumas
    UUID(uuidString: "2E2D3637-D977-4D9E-9007-16ACB14ED7C7")!,  // Danbury State Breakers
    UUID(uuidString: "3011BF87-371C-48EA-8A1B-0B2452408AB1")!,  // Waynesboro Poly Quarrymen
    UUID(uuidString: "304B950B-6445-4300-8EEE-13F6F6B0B971")!,  // Wapakoneta Poly Tempests
    UUID(uuidString: "306B310F-484F-48B9-8FC0-4F76DCE0F51F")!,  // Rockland Prowlers
    UUID(uuidString: "320CF43A-6943-4341-BF51-B90853823208")!,  // Kirksville State Navigators
    UUID(uuidString: "343AE8DE-59CC-4017-96B2-46AE69E744BE")!,  // Parkersburg Poly Meteors
    UUID(uuidString: "3A59F5FD-43A8-4418-A103-62D1275E07B4")!,  // Mesquite Comets
    UUID(uuidString: "3E7B8999-7AE8-46D6-91FA-65C4712CBD1C")!,  // Flandreau Maritime Cacti
    UUID(uuidString: "3FEBFCA9-A9F3-4C2B-9740-7F27575C64BB")!,  // Delaware City Marlins
    UUID(uuidString: "4025813E-0EF7-4FBA-A821-87DB4A5D967F")!,  // Carlisle Goshawks
    UUID(uuidString: "40329404-47DB-4AD9-B97B-35BFC6B34854")!,  // Aberdeen Regional Tornadoes
    UUID(uuidString: "40ADB459-3F48-4A55-804E-42FFC987D1BA")!,  // Pella Martens
    UUID(uuidString: "4135CA8D-38DC-4CDE-AC7C-F4951BC6E52E")!,  // Dalhart Nightwings
    UUID(uuidString: "42330E58-BBFC-4870-B3C6-AA4232F6BFF3")!,  // Carbondale Coastal Racers
    UUID(uuidString: "428AF1A5-E2DB-4ADE-AC55-F97D76F94FBF")!,  // Calexico Regional Foremen
    UUID(uuidString: "465D568E-3258-4DFD-BBD0-92640592A749")!,  // Biddeford Central Goshawks
    UUID(uuidString: "49697F49-CF9B-463E-BC2E-E3FD1FB6DC4D")!,  // Zanesville Valley Lynx
    UUID(uuidString: "4C697B3A-741A-4D32-AE66-86A3B92CB4F7")!,  // Warrensburg Kestrels
    UUID(uuidString: "4CACCDE7-340F-4E4F-8869-031E960CD31E")!,  // Sturgis Comets
    UUID(uuidString: "4D2BD12B-F3B7-46FE-8863-CD6973A66EB1")!,  // Red Wing State Meteors
    UUID(uuidString: "4D74C029-1A74-48D9-BF51-CAEDFCCBEFA0")!,  // Siloam Springs State Miners
    UUID(uuidString: "4F61ED93-A823-4F4A-B32D-ABED1B6AA243")!,  // Nampa Kestrels
    UUID(uuidString: "50F026EE-0C7B-45A7-ABDC-48BBB936D396")!,  // Petoskey Regional Raccoons
    UUID(uuidString: "520C4F29-4C68-4D36-B1C8-681CF1869908")!,  // Sedalia Shards
    UUID(uuidString: "545D878F-D881-45B0-A7C2-F1AC3B3E018E")!,  // Ridgway Coastal Prowlers
    UUID(uuidString: "57E1B055-AFBA-4F86-931D-51D9B1769E46")!,  // Glenwood Springs Valley Thunderbolts
    UUID(uuidString: "5964FBBF-088C-4B89-BD17-7C44C4CB1FED")!,  // Skowhegan Valley Lynx
    UUID(uuidString: "5C4CE91F-969D-4A74-8E1A-7E672C9631AB")!,  // Hermann Coastal Lancers
    UUID(uuidString: "5E8574FC-01C2-4A46-86F9-6B7D135139C5")!,  // Saranac Lake Central Torchbearers
    UUID(uuidString: "5EB19F56-8781-43B2-9200-BB201482D59D")!,  // Essex Junction Maritime Orcas
    UUID(uuidString: "5ECE4678-DCAA-4412-981D-396E9EFACE56")!,  // Natchez Maritime Comets
    UUID(uuidString: "606AF674-1C1B-484F-A13F-E6D511734B15")!,  // Titusville Breakers
    UUID(uuidString: "6504837E-4DE4-4C06-8C9A-2E818B668BC5")!,  // Pipestone Breakers
    UUID(uuidString: "65AC24FD-9E0B-4C56-A06A-53A589DAADD4")!,  // Clayton Poly Geckos
    UUID(uuidString: "66F382C0-4B27-4283-89C4-C43B1F75C729")!,  // Gillette Maritime Goshawks
    UUID(uuidString: "6A58BFEC-098E-40C2-94F6-A1B551F098DD")!,  // Lovelock Kestrels
    UUID(uuidString: "6CAF0BE7-40EB-4945-9E4B-DB5ABDD40D8A")!,  // Chanute Ursids
    UUID(uuidString: "7124CE9C-8D5F-4FC9-9D0B-88A78F18BA90")!,  // Beverly Maritime Nightwings
    UUID(uuidString: "729F50FA-DC6F-4122-80E5-EBCCB0E0569E")!,  // Escanaba Coastal Anchors
    UUID(uuidString: "73490D92-65A6-4A96-BAFF-0C67F093918F")!,  // Camas Poly Sharks
    UUID(uuidString: "74CBDAB2-62B0-4A15-B1C5-547E005A7E4F")!,  // Burlington A&M Kestrels
    UUID(uuidString: "74FA7E3F-3395-408F-883C-3CB271E0FA9F")!,  // Davenport Agricultural Tornadoes
    UUID(uuidString: "759E3564-09AA-496B-9037-952E6830FA52")!,  // Rapid City Central Marlins
    UUID(uuidString: "7767AA6A-6FA7-4402-98D6-B02EEA82AF5F")!,  // Ripon Regional Corsairs
    UUID(uuidString: "7A931080-33EA-4761-B5A7-499C7451D9F5")!,  // Effingham Cobras
    UUID(uuidString: "7DCE509D-76EB-4570-9326-49648DD2DDA2")!,  // Pinedale Tech Dragons
    UUID(uuidString: "7DEF46FB-1805-44A3-9484-F2589F1712ED")!,  // Wilber Sharks
    UUID(uuidString: "7E474219-E18A-4091-ADB2-A7C4A3A5A445")!,  // Smithfield Central Firebirds
    UUID(uuidString: "812CEEE7-CE13-45A9-9DC8-C1EB8FA27A6C")!,  // Johnstown Hoplites
    UUID(uuidString: "84233BCF-267B-4311-89BD-5FE567EDDCCB")!,  // Sharon Nightwings
    UUID(uuidString: "886F0CB0-71D2-40A4-AD1E-8D1AF548BE14")!,  // Ely Poly Engineers
    UUID(uuidString: "889EB520-67E7-4878-B29F-4936D9C0715C")!,  // Hillsboro Whirlwinds
    UUID(uuidString: "88C162AB-213F-44EE-AC3D-F217EDFAB616")!,  // Barre Coastal Stonebreakers
    UUID(uuidString: "8AA6D28B-6EBE-454A-B27E-973800B9FE5C")!,  // Jerome Whirlwinds
    UUID(uuidString: "8C11B43C-26AF-44CC-9D1D-313C56292C16")!,  // Claremont Maritime Martens
    UUID(uuidString: "8E5802E1-2E34-4C2E-90F1-4D92567B26BD")!,  // Iron Mountain Orcas
    UUID(uuidString: "8FA882FD-D69C-4228-858D-172434456DA9")!,  // Klamath Falls A&M Shields
    UUID(uuidString: "90CFDB4C-A355-4A5A-8B3D-94B9A73A5AB5")!,  // Grangeville Poly Prowlers
    UUID(uuidString: "91F2A57B-E7C9-4E6E-8217-17490CBB784B")!,  // Adrian Wizards
    UUID(uuidString: "93906BE6-0664-47D6-B43D-818955AE7DC8")!,  // Lihue Thunder
    UUID(uuidString: "94D568ED-1B87-419B-B8E4-005F63171F1F")!,  // Fairbury Cannoneers
    UUID(uuidString: "958DF3C5-5675-44A6-8A80-999F90B172A4")!,  // Cambridge A&M Reapers
    UUID(uuidString: "99FD7E6A-C476-4FA2-97F3-89E767D8D29F")!,  // Spencer Maritime Coopers
    UUID(uuidString: "9BBB69C9-4FBA-4C26-BFDF-8BAEF98A8682")!,  // Lebanon Regional Ursids
    UUID(uuidString: "9ECF043D-3EFC-4A72-9819-CE233D8C7DDA")!,  // Waverly Anchors
    UUID(uuidString: "9F0787A8-3784-407F-BCDA-8A2CDEB855FC")!,  // Cohoes Coastal Tornadoes
    UUID(uuidString: "A11631F5-EF41-4BD0-90A1-34F29549AFBA")!,  // Sulphur Springs A&M Shrikes
    UUID(uuidString: "A23E5915-3CDF-4522-9C22-AA9AD1D72EB9")!,  // Janesville Central Lynx
    UUID(uuidString: "A34541EA-0304-4A47-8CA0-9B3BC0B6DC46")!,  // Bristol Shrikes
    UUID(uuidString: "A3B3903E-148F-481A-8469-00002BEB8BBB")!,  // Dover A&M Captains
    UUID(uuidString: "A3C286C7-47C6-46F6-BCF3-318840C3E6DA")!,  // Lapeer State Aviators
    UUID(uuidString: "A404526F-1958-4108-B555-4027E21DFBDF")!,  // Shamokin Corsairs
    UUID(uuidString: "A490D536-5671-4340-BE18-CD697CEED26A")!,  // Olney Cacti
    UUID(uuidString: "A4A0B0B0-62DB-42A3-B145-67E3DD7C1A04")!,  // Geneseo State Wildcatters
    UUID(uuidString: "A6B3C25F-D8C2-410D-9981-8F260720A790")!,  // Millinocket Coastal Sea Dragons
    UUID(uuidString: "A6E5417A-9D72-4874-AAC3-8CD372E646BB")!,  // Hinton Coastal Sentinels
    UUID(uuidString: "A9B34775-5B86-4716-92FB-62A181590973")!,  // Missoula Conductors
    UUID(uuidString: "ABD2FF25-9964-494B-86E3-4B89E24B5348")!,  // Kerrville Lamplighters
    UUID(uuidString: "AC5D9C75-1059-4B7C-9C98-8B557A5EAE3D")!,  // Cranston Crystals
    UUID(uuidString: "AD2C6F9A-1B65-4766-8FB1-B27E3B03AD5A")!,  // Sandpoint Regional Goshawks
    UUID(uuidString: "ADE3144D-D5B5-4619-B40D-53EDB4C2D1B1")!,  // Texarkana Tech Marlins
    UUID(uuidString: "B0196DF2-F075-4EAB-9A45-E39466DFAF14")!,  // Elmira Prowlers
    UUID(uuidString: "B495A8A8-AAFA-4736-875B-C4ECD8E1C5DF")!,  // Derby Central Fletchers
    UUID(uuidString: "B6783970-BA3D-485C-815D-9A62F25005C9")!,  // Orangeburg A&M Whirlwinds
    UUID(uuidString: "BB6717ED-25E7-4CE3-838D-9292E41AA8C1")!,  // New Haven Shipwrights
    UUID(uuidString: "BC1EBE0F-069B-4BC9-A33B-23A887CA898C")!,  // Redding Gars
    UUID(uuidString: "BCB38CAC-CC60-4EF4-8760-567F2E725486")!,  // Wahpeton Prowlers
    UUID(uuidString: "BF72B120-52D0-42A5-9152-136626721018")!,  // Bridgeport Poly Giraffes
    UUID(uuidString: "C07AC0D1-16CE-4510-B262-83DB4CAD3E38")!,  // Terre Haute A&M Gorillas
    UUID(uuidString: "C0A6908A-FD4D-408A-B0BE-70A2298C0B70")!,  // Moberly Tornadoes
    UUID(uuidString: "C1E1DD21-4DB7-4A9B-B72F-E028B4AAA9C3")!,  // Ellensburg Regional Reapers
    UUID(uuidString: "C1FDC4CC-8A24-47C9-A71A-D1EB2C31DFF4")!,  // Abingdon Stallions
    UUID(uuidString: "C28B0A9D-F937-4F64-BD4A-517AFC174BC1")!,  // Lewisburg Oncas
    UUID(uuidString: "C2A1B50D-C824-46F7-9CFB-BD477BF5ABAD")!,  // Springville Maritime Leopards
    UUID(uuidString: "C3412C59-7F59-4D90-8015-CBD76155AAF6")!,  // Savanna Snow Leopards
    UUID(uuidString: "CB7833BC-70FE-42C0-943A-61D73AADC350")!,  // Waimea Coastal Clouded Leopards
    UUID(uuidString: "CBDF8F99-B7C6-4B27-B545-E5FDC61EB999")!,  // Baggs Cheetahs
    UUID(uuidString: "CF442D44-8E80-4045-8888-B1EC5CC934E4")!,  // Scottsbluff State Servals
    UUID(uuidString: "CF446B37-9C11-417D-ADF8-C4952970D1C9")!,  // New Prague Thunder
    UUID(uuidString: "CFC2D13A-E399-42B8-8450-11D1C91934FD")!,  // McCook Caracals
    UUID(uuidString: "D01A0E13-7818-4053-ABDE-4C27F590D24E")!,  // Lock Haven Regional Ocelots
    UUID(uuidString: "D3563C9A-7703-4E80-A87E-D02C6E12D677")!,  // Rocky Mount A&M Lamplighters
    UUID(uuidString: "D4F46917-036A-4BBC-9FA1-98D66B8F1819")!,  // Ada Margays
    UUID(uuidString: "D851E5D2-C6A4-40CF-8308-5FA0947078EF")!,  // Holly Springs Coastal Pallas Cats
    UUID(uuidString: "DB188E3A-70F3-449E-A094-00D189ECF16B")!,  // New Ulm Halos
    UUID(uuidString: "DEC9D295-AA77-4D57-8CEC-E3E92EFDC219")!,  // Weatherford Prisms
    UUID(uuidString: "E0853162-478C-4A88-8FCC-5720801797FB")!,  // Rangeley Links
    UUID(uuidString: "E175143F-FFD4-41AB-9CB8-7F317FCE2082")!,  // Canandaigua Tech Galaxies
    UUID(uuidString: "E2034539-439C-471E-82C2-4E04DCE73B42")!,  // Penn Yan Spires
    UUID(uuidString: "E287BED9-67CC-4457-8619-9A7BBC9998F3")!,  // Ocean City Agricultural Bolts
    UUID(uuidString: "E2EA9F87-85EC-4B2D-A307-6FAE41E7C490")!,  // Oak Bluffs Tech Shooting Stars
    UUID(uuidString: "E335B640-25F6-4A29-A0C8-EB8A69A0960A")!,  // Eastport Knots
    UUID(uuidString: "E7F41714-0989-41A4-B322-379A36119847")!,  // Gallipolis Poly Shards
    UUID(uuidString: "E8D76C2D-F87A-4503-A1B5-B80193FC4F5B")!,  // Ketchikan Citadels
    UUID(uuidString: "F22A5A2B-A734-4FB1-B57D-1D6424D04E56")!,  // Miles City Vortices
    UUID(uuidString: "F565417A-C5DA-40AC-BEF3-FE5B0EE0B8F7")!,  // Leesburg Deltas
    UUID(uuidString: "FAE94B0E-BD99-4B65-AE37-6DAB8D288CBC")!,  // Holdrege Tech Lamplighters
    UUID(uuidString: "FC2EB19D-2F6C-4658-8473-CE9FCB5D5559")!,  // Elko Sentinels
    UUID(uuidString: "FCC35CCD-6BB6-4320-9190-9239ECE10D62")!,  // Red Lodge State Starbursts
    UUID(uuidString: "FCD34F9B-7C24-472A-B689-0C44A0D33C47")!,  // Carefree Tornadoes
    UUID(uuidString: "FD596501-2D90-49B5-9EDA-275EE0141BA5")!,  // Camden Bolts
    UUID(uuidString: "FF88B667-1155-4033-8E70-AEFC3087A0F0")!,  // Delavan Tech Monoliths
]

let ownerApprovedContrastExceptions: Set<UUID> = [
    UUID(uuidString: "02D86903-1751-489C-83A9-579368E3BB40")!,  // Binghamton Shrikes
    UUID(uuidString: "1032E7BD-52E6-4C02-85D4-4DC399B13B7A")!,  // Hood River Maritime Gaffers
    UUID(uuidString: "10AA9D4C-D1C1-4E25-9B8B-86520D782A68")!,  // Zeeland Sabrecats
    UUID(uuidString: "10E07F5C-24A8-414C-83AE-8B54CBE2BCB8")!,  // Hamilton Ursids
    UUID(uuidString: "1982A97F-CD2B-459B-AF23-89D5151A9829")!,  // New Castle Maritime Sentinels
    UUID(uuidString: "1C8CC9B1-F549-4AE4-8CF1-8E4C718D0245")!,  // San Angelo A&M Hoplites
    UUID(uuidString: "218774CA-1F35-4B02-9FAA-54C54191C80F")!,  // Watertown Coastal Reapers
    UUID(uuidString: "3011BF87-371C-48EA-8A1B-0B2452408AB1")!,  // Waynesboro Poly Quarrymen
    UUID(uuidString: "304B950B-6445-4300-8EEE-13F6F6B0B971")!,  // Wapakoneta Poly Tempests
    UUID(uuidString: "306B310F-484F-48B9-8FC0-4F76DCE0F51F")!,  // Rockland Prowlers
    UUID(uuidString: "320CF43A-6943-4341-BF51-B90853823208")!,  // Kirksville State Navigators
    UUID(uuidString: "3A59F5FD-43A8-4418-A103-62D1275E07B4")!,  // Mesquite Comets
    UUID(uuidString: "3ADF86BC-763D-4996-AA5C-4A847C44EE0E")!,  // Waurika Maritime Palisades
    UUID(uuidString: "428AF1A5-E2DB-4ADE-AC55-F97D76F94FBF")!,  // Calexico Regional Foremen
    UUID(uuidString: "4CACCDE7-340F-4E4F-8869-031E960CD31E")!,  // Sturgis Comets
    UUID(uuidString: "545D878F-D881-45B0-A7C2-F1AC3B3E018E")!,  // Ridgway Coastal Prowlers
    UUID(uuidString: "5F09D018-DCA9-41F7-8ACD-040A07230254")!,  // Yreka Agricultural Surveyors
    UUID(uuidString: "66F382C0-4B27-4283-89C4-C43B1F75C729")!,  // Gillette Maritime Goshawks
    UUID(uuidString: "729F50FA-DC6F-4122-80E5-EBCCB0E0569E")!,  // Escanaba Coastal Anchors
    UUID(uuidString: "74FA7E3F-3395-408F-883C-3CB271E0FA9F")!,  // Davenport Agricultural Tornadoes
    UUID(uuidString: "87497AA4-AED8-4757-B45C-C5EFEBA7EBEC")!,  // Ogallala Coastal Palisades
    UUID(uuidString: "886F0CB0-71D2-40A4-AD1E-8D1AF548BE14")!,  // Ely Poly Engineers
    UUID(uuidString: "892CB41F-7F6E-4692-86FF-64FA39A7E48D")!,  // Nacogdoches Poly Planters
    UUID(uuidString: "900EF64D-9234-456E-AA4E-D488C78B968E")!,  // Payson A&M Sabrecats
    UUID(uuidString: "9ECF043D-3EFC-4A72-9819-CE233D8C7DDA")!,  // Waverly Anchors
    UUID(uuidString: "A34541EA-0304-4A47-8CA0-9B3BC0B6DC46")!,  // Bristol Shrikes
    UUID(uuidString: "A80F1424-2952-443A-8737-7DA109C31124")!,  // Webster City Coastal Tornadoes
    UUID(uuidString: "B6783970-BA3D-485C-815D-9A62F25005C9")!,  // Orangeburg A&M Whirlwinds
    UUID(uuidString: "C0A6908A-FD4D-408A-B0BE-70A2298C0B70")!,  // Moberly Tornadoes
    UUID(uuidString: "C2A1B50D-C824-46F7-9CFB-BD477BF5ABAD")!,  // Springville Maritime Leopards
    UUID(uuidString: "C3412C59-7F59-4D90-8015-CBD76155AAF6")!,  // Savanna Snow Leopards
    UUID(uuidString: "CB7833BC-70FE-42C0-943A-61D73AADC350")!,  // Waimea Coastal Clouded Leopards
    UUID(uuidString: "CFC2D13A-E399-42B8-8450-11D1C91934FD")!,  // McCook Caracals
    UUID(uuidString: "E0853162-478C-4A88-8FCC-5720801797FB")!,  // Rangeley Links
    UUID(uuidString: "EA82FD9D-8540-464A-BF06-EA0374CDBDB3")!,  // Falmouth Maritime Gatekeepers
    UUID(uuidString: "F565417A-C5DA-40AC-BEF3-FE5B0EE0B8F7")!,  // Leesburg Deltas
]

/// The one file exempt from the shipped-copy scan, because it *is* the list of real names.
let blocklistSourcePath = "Generation/Blocklist.swift"

/// Every string literal in `text`, comments discarded.
///
/// The inverse of ContractTests' scanner, which keeps the code and blanks the literals to look for
/// forbidden calls. This one keeps the literals and throws the code away, because the guardrail is
/// about the strings the app shows a player.
///
/// Two deliberate limits, both safe in the direction that matters. An interpolation segment is kept
/// as its raw source text, so `"#\(model.number)"` is swept as `#model.number)` — identifier words,
/// which cannot spell a real programme. And a nested block comment ends at its first `*/`, leaving
/// the rest to be read as code; that can only add literals to the sweep, never hide one.
///
/// The one limit that is *not* safe: a raw string literal (`#"..."#`) would have its backslashes
/// read as escapes, and a swallowed closing quote hides every literal after it in that file. No
/// source file uses one today. There is no assertion against it because the opener `#"` is
/// indistinguishable by substring from an ordinary literal holding a `#`, which `RosterView` has.
func stringLiterals(in text: String) -> [String] {
    enum Mode { case code, lineComment, blockComment, literal, multilineLiteral }
    let characters = Array(text)
    var literals: [String] = []
    var current = ""
    var mode = Mode.code
    var index = 0

    func lookahead(_ offset: Int) -> Character? {
        let position = index + offset
        return position < characters.count ? characters[position] : nil
    }
    func opensMultiline() -> Bool {
        lookahead(0) == "\"" && lookahead(1) == "\"" && lookahead(2) == "\""
    }

    while index < characters.count {
        let character = characters[index]
        switch mode {
        case .code:
            if character == "/", lookahead(1) == "/" {
                mode = .lineComment
                index += 2
                continue
            }
            if character == "/", lookahead(1) == "*" {
                mode = .blockComment
                index += 2
                continue
            }
            if opensMultiline() { mode = .multilineLiteral; current = ""; index += 3; continue }
            if character == "\"" { mode = .literal; current = ""; index += 1; continue }
        case .lineComment:
            if character == "\n" { mode = .code }
        case .blockComment:
            if character == "*", lookahead(1) == "/" {
                mode = .code
                index += 2
                continue
            }
        case .literal:
            if character == "\\" { index += 2; continue }
            if character == "\"" { literals.append(current); mode = .code; index += 1; continue }
            current.append(character)
        case .multilineLiteral:
            if character == "\\" { index += 2; continue }
            if opensMultiline() {
                literals.append(current.trimmingCharacters(in: .whitespacesAndNewlines))
                mode = .code
                index += 3
                continue
            }
            current.append(character)
        }
        index += 1
    }
    return literals
}

func runLegalTests() {
    suite("Legal: name collision") {
        test("no generated institution name in any of the swept leagues is a real one") {
            var offenders: [String] = []
            for (index, world) in sweptWorlds.enumerated() {
                for name in world.everyGeneratedInstitutionName where Blocklist.blocks(name) {
                    offenders.append("seed \(index): \(name)")
                }
            }
            expect(offenders.isEmpty,
                   "generated institution names collide with real ones: "
                       + offenders.prefix(10).joined(separator: ", "))
        }

        test("no place a member can be sited in heads a blocked institution name") {
            // A public name begins with its city, so a city that is also a real programme is a
            // blocked school name the moment a member is put there. Enumerated over the whole
            // pool rather than over swept worlds: 570 places against 166 members means a sample
            // of 200 leagues leaves most of the list untouched, and the one it misses ships.
            var offenders: [String] = []
            for place in NameGrammar.everyPlace {
                let city = NameGrammar.cityWithoutState(place)
                if Blocklist.blocks(city) { offenders.append(place) }
            }
            expect(offenders.isEmpty,
                   "\(offenders.count) places are blocked as institution names: "
                       + offenders.prefix(5).joined(separator: ", "))
        }

        test("no generated place name is a real venue mark or a real person") {
            var offenders: [String] = []
            for (index, world) in sweptWorlds.enumerated() {
                for name in world.everyGeneratedPlaceName where Blocklist.blocksPlaceName(name) {
                    offenders.append("seed \(index): \(name)")
                }
            }
            expect(offenders.isEmpty,
                   "generated place names collide with a mark or a person: "
                       + offenders.prefix(10).joined(separator: ", "))
        }

        test("the place boundary is exactly the names that are both a city and a programme") {
            // Derived from the two lists rather than transcribed, so the count CLAUDE.md and STATUS
            // quote cannot drift away from the lists they describe. Transcribing it by hand gave six,
            // then seven; it is eight. Kansas City is the one both hand counts missed, because it is
            // refused for containing the institution word "Kansas" rather than for being a listed
            // institution itself — which is a thing exact-string comparison cannot see and the word
            // sequence matcher can.
            let dualUse = Blocklist.realCities.filter(Blocklist.blocks).sorted()
            expectEqual(
                dualUse,
                ["Buffalo", "Cincinnati", "Houston", "Kansas City", "Miami", "Pittsburgh", "Tulsa",
                 "Washington"],
                "the set of names that are both a real city and a real programme has moved, so "
                    + "CLAUDE.md's guardrail and STATUS's decision entry are now out of date"
            )
            for city in Blocklist.realCities {
                expect(!Blocklist.blocksPlaceName(city),
                       "\(city) is a real city, and real cities are permitted as places")
            }
        }

        test("a real city is allowed as a place and refused as an institution") {
            // The owner's decision of 2026-08-12, as an assertion rather than a comment. Real
            // location names are permitted, so a city called Columbus is fine. The school is not
            // the real school, so Ohio State is still refused, and the six names that are both a
            // real city and a real programme - Buffalo, Cincinnati, Houston, Miami, Pittsburgh,
            // Tulsa - are refused as a programme name and allowed as the city it plays in.
            for city in ["Columbus", "Nashville", "Baltimore", "Green Bay", "Houston", "Miami"] {
                expect(!Blocklist.blocksPlaceName(city),
                       "\(city) is a real place and real places are permitted")
            }
            for institution in ["Houston", "Miami", "Buffalo", "Cincinnati", "Pittsburgh", "Tulsa"] {
                expect(Blocklist.blocks(institution),
                       "\(institution) is a real programme as well as a real city")
            }
            expect(Blocklist.blocks("Ohio State"))
            expect(!Blocklist.blocks("Columbus Technical"),
                   "a fictional school in a real city is the point of the decision")
            for mark in ["Rose Bowl", "Death Valley", "Lambeau", "Nick Saban"] {
                expect(Blocklist.blocksPlaceName(mark),
                       "\(mark) is a mark or a person, not a location")
            }
        }

        test("generated places and bowl titles use generic naming") {
            var rng = SeededRandom(seed: 20_260_820)
            let places = NameGrammar.distinctPlaceNames(using: &rng)
            expectEqual(places.count, 570)
            expect(places.allSatisfy { $0.contains(", ") },
                   "a generated place is missing its state qualification")
            let bowls = places.prefix(32).map {
                NameGrammar.bowlName(place: $0, using: &rng)
            }
            expect(bowls.allSatisfy { !Blocklist.blocks($0) },
                   "a generic bowl title collided with the protected-name screen")
        }

        test("the sweep actually looks at every kind of generated name") {
            // The guard against the sweep passing because it swept nothing. Named kinds rather
            // than a count, because "there were some strings" would still be satisfied by a world
            // that generated no nicknames at all.
            let world = LeagueGenerator.generate(seed: 7)
            let names = world.everyGeneratedName
            expect(names.count > CollegeRules.programmeCount,
                   "only \(names.count) names swept, which cannot cover 134 programmes")
            for name in [world.programmes[0].name, world.programmes[0].nickname,
                         world.proTeams[0].nickname, world.league.conferences[0].name] {
                expect(world.everyGeneratedInstitutionName.contains(name),
                       "\(name) is an institution name and is not swept as one")
            }
            for name in [world.programmes[0].cityName, world.map.regions[0].name] {
                expect(world.everyGeneratedPlaceName.contains(name),
                       "\(name) is a place name and is not swept as one")
            }
            let identity = world.identities[world.programmes[0].id]!
            expect(world.everyGeneratedInstitutionName.contains(identity.venueName),
                   "a venue name is generated but not swept as an institution name")
            expect(world.everyGeneratedInstitutionName.contains(identity.traditions[0].name),
                   "a tradition name is generated but not swept as an institution name")
            // Neither kind may quietly drop a name: the split has to partition the sweep, not
            // sample it.
            expectEqual(
                Set(names),
                Set(world.everyGeneratedInstitutionName).union(world.everyGeneratedPlaceName),
                "a generated name belongs to neither kind, so nothing checks it"
            )
        }

        test("the collision test catches a planted real name") {
            // A scan that has never failed is not known to be a scan. These are the exact strings
            // that shipped in the prior build's "fictional alma maters" list.
            for planted in ["Delta State", "Pine Bluff", "Western Reserve", "Old Dominion",
                            "Ohio State", "Crimson Tide", "Nick Saban"] {
                expect(Blocklist.blocks(planted), "\(planted) is real and was not blocked")
            }
        }

        test("blocking survives spacing, case and punctuation") {
            // A blocklist compared without normalising is theatre: "Ohio State", "ohio state" and
            // "Ohio-State" are three strings and one entry.
            for spelling in ["ohio state", "OHIO STATE", "Ohio-State", "OhioState", " Ohio  State "] {
                expect(Blocklist.blocks(spelling), "\(spelling) evaded the blocklist")
            }
        }

        test("a real name hidden inside a longer one is still blocked, including multi-word ones") {
            // The previous version of this test was titled for this case and could not see it. Both
            // its examples — "Clemson Valley", "North Alabama Technical" — hit on a single word, so
            // deleting the multi-word capability entirely left it green.
            //
            // The decisive case is the one PORT-LOG.md names: "Old Dominion Tech" is one of the six
            // real institutions the prior build shipped under a comment reading "Fictional alma
            // maters", and blocks() returned false for it while returning true for the bare
            // "Old Dominion" this test used to plant.
            // "Coastal Green Bay" was here and moved out on 2026-08-12: Green Bay is a city, real
            // location names are permitted, and a school in a real city is the point of the owner's
            // decision. "Coastal Boston College" replaces it and keeps the multi-word case, because
            // a school named after a real school is still refused.
            for planted in ["Clemson Valley", "North Alabama Technical",
                            "Old Dominion Tech", "Delta State Tech",
                            "Ohio State Technical", "North Notre Dame", "Upper Boise State",
                            "The Ohio State University", "Nick Saban Field",
                            "Coastal Boston College", "Kyle Field Stadium"] {
                expect(Blocklist.blocks(planted), "\(planted) contains a real name and was not blocked")
            }
        }

        test("every blocklist entry is still blocked with a word attached at either end") {
            // By construction over the whole list rather than over remembered examples. 114 of the
            // entries are multi-word, and every one of them was invisible the moment a word was
            // attached.
            var offenders: [String] = []
            for entry in Blocklist.entries.map({ $0.joined(separator: " ") }) {
                if !Blocklist.blocks(entry + " Technical") { offenders.append("\(entry) + suffix") }
                if !Blocklist.blocks("North " + entry) { offenders.append("prefix + \(entry)") }
            }
            expect(offenders.isEmpty,
                   "these entries stop being blocked once a word is attached: "
                       + offenders.prefix(8).joined(separator: ", "))
        }

        test("no word any generator can emit is itself a blocked name") {
            // By construction, and stronger than the sweep above, which is a sample. CLAUDE.md's
            // guardrail says no generated name matches a real one "at any seed" — that is a claim
            // about the reachable set, and only exhaustion proves it.
            //
            // The first version of this test read one file's pools and missed 505 of the 638
            // reachable words, including all 464 surnames, which reach a stadium name. It also
            // listed surname stems and endings separately while the generator concatenates them
            // into one word, and the concatenation is the unit Blocklist splits on.
            let words = GenerationVocabulary.everyEmittableWord
            expect(words.count > 600,
                   "only \(words.count) emittable words — a pool is not contributing")
            let offenders = words
                .filter { !$0.trimmingCharacters(in: .whitespaces).isEmpty }
                .filter { Blocklist.blocks($0) }
            expect(offenders.isEmpty,
                   "these generator words are real names: "
                       + Array(Set(offenders)).sorted().joined(separator: ", "))
        }

        test("the vocabulary covers the words the sweep actually produced") {
            // The guard on the guard. GenerationVocabulary is contributed to by hand, one pool per
            // type, so a phase that adds a pool and forgets is the remaining hole. This closes it
            // from the other side: every word the generator was observed emitting must be in the
            // declared vocabulary, or the vocabulary is out of date.
            let declared = Set(GenerationVocabulary.everyEmittableWord.map(Blocklist.normalised))
            var missing: Set<String> = []
            for world in sweptWorlds.prefix(25) {
                for name in world.everyGeneratedName {
                    for word in name.split(whereSeparator: { !$0.isLetter && !$0.isNumber }) {
                        let normalised = Blocklist.normalised(String(word))
                        if !normalised.isEmpty, !declared.contains(normalised) {
                            missing.insert(String(word))
                        }
                    }
                }
            }
            expect(missing.isEmpty,
                   "the generator emitted words the vocabulary does not declare, so the "
                       + "by-construction legal check does not cover them: "
                       + missing.sorted().prefix(12).joined(separator: ", "))
        }

        test("the morpheme check would catch a planted real word") {
            // The self-test for the test above: if Blocklist.blocks returned false for everything,
            // the assertion would pass vacuously over a clean-looking pool.
            expect(Blocklist.blocks("Crimson"),
                   "the exact word the sweep caught is not blocked, so the morpheme check is inert")
            expect(Blocklist.blocks("Buckeyes"), "a single-word real nickname is not blocked")
        }

        test("the near-miss forms a careful person reaches for are refused") {
            // These are not inventions of this test. They are the "safe alternatives" an IP note
            // offered to this project proposed in place of the marks it named, and two of the four
            // were already on the blocklist as real names when it proposed them: "Southeastern
            // Conference" *is* the SEC and "Atlantic Coast" *is* the ACC, so the mitigation was the
            // mark. The other two are near-misses of the bodies they stand in for.
            //
            // The failure this guards is not ignorance. It is a careful person reasoning their way
            // to a name that sounds cleared and is not.
            for alternative in ["Southeastern Conference", "Atlantic Coast",
                                "National Collegiate Association", "National Pro Football",
                                "American Conference", "National Conference",
                                "Collegiate Athletic Association"] {
                expect(Blocklist.blocks(alternative),
                       "\(alternative) reads as a safe alternative and is a mark or a near-miss "
                           + "of one")
            }
        }

        test("a conference whose brand is a numeral is blocked in both of its forms") {
            // By construction over the list rather than over remembered examples. "Big Twelve" and
            // "Big 12" normalise to different tokens — `normalised` keeps digits — so an entry for
            // one blocks nothing about the other, and the list held only the spelled form of three
            // conferences whose own logo is the numeral.
            let numerals = ["eight": "8", "ten": "10", "twelve": "12"]
            var offenders: [String] = []
            for entry in Blocklist.entries {
                for (spelled, digits) in numerals {
                    if entry.contains(spelled) {
                        let numeric = entry.map { $0 == spelled ? digits : $0 }
                            .joined(separator: " ")
                        if !Blocklist.blocks(numeric) { offenders.append(numeric) }
                    }
                    if entry.contains(digits) {
                        let written = entry.map { $0 == digits ? spelled : $0 }
                            .joined(separator: " ")
                        if !Blocklist.blocks(written) { offenders.append(written) }
                    }
                }
            }
            expect(offenders.isEmpty,
                   "these conference marks are blocked in one form only: "
                       + offenders.sorted().joined(separator: ", "))
        }

        test("a real rivalry trophy is refused, because the generator names trophies") {
            // TraditionGrammar emits `<rivalry adjective> <trophy noun>` — "Iron Trophy", "Old
            // Bell", "Border Axe". Real rivalry trophies have exactly that shape, and until the
            // marks limb existed the tradition sweep ran against a blocklist containing no trophy
            // at all: it could not have failed.
            for trophy in ["Little Brown Jug", "Old Oaken Bucket", "Victory Bell", "Apple Cup",
                           "Iron Bowl", "Territorial Cup", "Floyd of Rosedale"] {
                expect(Blocklist.blocks(trophy), "\(trophy) is a real rivalry mark")
            }
            expect(Blocklist.blocks("The Old Oaken Bucket Trophy"),
                   "a trophy mark inside a longer name is still the mark")
        }

        test("the words that left the nickname pools are blocked, and are no longer emittable") {
            // Both halves matter. Blocking alone would turn the by-construction morpheme check red;
            // replacing alone would leave the next pool free to reintroduce them. Beacons is the
            // one that says why this class is worth a test: Valparaiso plays Division I.
            let declared = Set(GenerationVocabulary.everyEmittableWord.map(Blocklist.normalised))
            for word in ["Foresters", "Marauders", "Herons", "Otters", "Beacons", "Drovers",
                         "Harriers", "Storm"] {
                expect(Blocklist.blocks(word), "\(word) is a real college nickname")
                expect(!declared.contains(Blocklist.normalised(word)),
                       "\(word) is blocked and still reachable from a generator pool")
            }
        }

        test("the sport's own vocabulary is not blocked") {
            // The counterweight. A denylist that errs generous costs a few nouns until it starts
            // costing the words the game has to say, and then it gets weakened rather than obeyed.
            //
            // "Red zone" is the sharp case and the reason no entry is the bare mark: `normalised`
            // drops the space, so "RedZone" and "red zone" are one token, and blocking the
            // broadcast mark alone would block the sport's own term for the twenty-yard line in.
            // The entries that cover these marks are longer than the descriptive phrase on purpose.
            for permitted in ["Red Zone", "Playoff", "Playoff Picture", "Signing Day", "Combine",
                              "Draft Board", "Draft Room", "Transfer Portal", "Head Coach",
                              "Bowl Game", "Conference Championship", "NIL", "Two-Minute Warning"] {
                expect(!Blocklist.blocks(permitted),
                       "\(permitted) is ordinary football vocabulary and the game has to say it")
            }
        }

        test("an invented name is not blocked, so the test can pass at all") {
            // The other direction. A blocklist that matched everything would make the sweep above
            // meaningless in the way that always-failing gates are meaningless.
            for invented in ["Thornby Ridge", "Ashen Falls Polytechnic", "Iron Kestrels"] {
                expect(!Blocklist.blocks(invented), "\(invented) is invented and was blocked")
            }
        }
    }

    suite("Legal: shipped copy") {
        // The generated-name sweep covers what the generator emits. It cannot see a real name typed
        // straight into a source file, and that is the exact failure this file's header records:
        // "Reading a list and judging it fictional is what produced both failures." The DEBUG screen
        // fixtures were read and judged fictional, and shipped three cities off the blocklist below.
        //
        // Enumerated by walking Sources, not by naming the fixture files, so a screen added tomorrow
        // is swept the day it is added rather than the day someone remembers it.
        //
        // This uses the institution-kind check, because a literal has no kind: the scanner sees a
        // string, not whether it is a hometown or a team name. That is the safe direction — it still
        // catches a real school typed into source, which is what the sweep exists for — at the cost
        // of refusing the eight dual-use names in hand-written copy. If a fixture wants a player
        // from Miami or Kansas City, that is the message it will get, and the fix is to use the
        // read model's typed place field rather than to weaken this to the place-kind check.
        test("no string literal anywhere in Sources is a real name") {
            var offenders: [String] = []
            for file in swiftFiles(under: "Sources") where !file.path.hasSuffix(blocklistSourcePath) {
                for literal in stringLiterals(in: file.text) where Blocklist.blocks(literal) {
                    offenders.append("\(file.path): \(literal)")
                }
            }
            expect(offenders.isEmpty,
                   "shipped copy collides with real names: "
                       + offenders.prefix(10).joined(separator: ", "))
        }

        test("the scan reads literals, ignores comments, and catches a planted real name") {
            // The self-test the other scans in this repository ship: a scan that has never failed is
            // not known to be a scan. Comments are excluded deliberately — canon cites real
            // programmes by name to say what must never be generated.
            let planted = """
            // Ohio State named in a comment is not shipped copy
            let team = "Carson Tech"
            /* Michigan */
            let rival = "Notre Dame"
            """
            let found = stringLiterals(in: planted)
            expectEqual(found, ["Carson Tech", "Notre Dame"])
            expect(found.filter(Blocklist.blocks) == ["Notre Dame"],
                   "the planted real programme was not the one and only literal caught")
        }

        test("the scan reaches the fixtures that carry player-facing copy") {
            // The guard against the sweep passing because it swept nothing.
            let fixtures = swiftFiles(under: "Sources/ProFootballCoachUI")
                .filter { $0.text.contains("CoachWorldSampleData") }
            expect(!fixtures.isEmpty, "no sample-fixture file was scanned")
            let literals = fixtures.flatMap { stringLiterals(in: $0.text) }
            expect(literals.contains("Carson Tech"),
                   "the scan did not reach the fixture team name")
        }
    }

    suite("Legal: trade dress") {
        test("no generated colour pair in any swept league sits within delta E of a real pair, "
            + "beyond the owner-approved exceptions") {
            var offenders: [String] = []
            var approvedCount = 0
            for (index, world) in sweptWorlds.enumerated() {
                for (id, identity) in world.identities
                where ColourGenerator.collidesWithTradeDress(identity.colours.primary,
                                                             identity.colours.secondary) {
                    if index == LEGAL_SWEEP_LEAGUES, ownerApprovedTradeDressExceptions.contains(id) {
                        approvedCount += 1
                        continue
                    }
                    offenders.append("seed \(index): \(identity.colours.primary.hex)/"
                        + identity.colours.secondary.hex)
                }
            }
            expect(offenders.isEmpty,
                   "generated pairs sit inside a real programme's trade dress, beyond the "
                       + "owner-approved exceptions: " + offenders.prefix(10).joined(separator: ", "))
            expect(approvedCount == ownerApprovedTradeDressExceptions.count,
                   "the approved trade-dress exception list no longer matches the canonical "
                       + "world exactly (\(approvedCount) of \(ownerApprovedTradeDressExceptions.count) "
                       + "still collide) -- update the list deliberately rather than leaving it stale")
        }

        test("the trade-dress test catches a planted real pair") {
            let real = Blocklist.tradeDress[0]
            expect(ColourGenerator.collidesWithTradeDress(real.primary, real.secondary),
                   "an exact copy of a real pair was not caught")
            // And a near copy, which is the case a hex-equality check would miss entirely.
            let nudged = Colour(red: real.primary.red + 4,
                                green: real.primary.green + 4,
                                blue: real.primary.blue + 4)
            expect(ColourGenerator.collidesWithTradeDress(nudged, real.secondary),
                   "a nudged copy of a real pair was not caught")
        }

        test("the professional tier's trade dress is on the list too") {
            // The list was a college slice while the generator dressed both tiers, so every pro
            // team in every save was checked against college pairs only. Named by hex rather than
            // by index, because an index moves whenever the list is refreshed and this assertion is
            // about a specific real identity being covered.
            for pair in [(Colour(hex: "203731"), Colour(hex: "FFB612")),
                         (Colour(hex: "4F2683"), Colour(hex: "FFC62F")),
                         (Colour(hex: "0085CA"), Colour(hex: "101820"))] {
                expect(ColourGenerator.collidesWithTradeDress(pair.0, pair.1),
                       "\(pair.0.hex)/\(pair.1.hex) is a real professional pair and is not covered")
            }
        }

        test("a swapped real pair is still a real pair") {
            let real = Blocklist.tradeDress[0]
            expect(ColourGenerator.collidesWithTradeDress(real.secondary, real.primary),
                   "swapping primary and secondary evaded the trade-dress test")
        }

        test("sharing one colour with a real pair is not trade dress") {
            // The threshold has to allow this or the generator has nothing to work with: half the
            // sport wears navy, and a rule that rejected navy would reject most of colour space.
            let real = Blocklist.tradeDress[0]
            let unrelated = Colour(hex: "2E8B57")
            expect(!ColourGenerator.collidesWithTradeDress(real.primary, unrelated),
                   "one shared colour was treated as trade dress")
        }

        test("every generated pair carries legible text, beyond the owner-approved exceptions") {
            // 04 section 2.1 requires the contrast contract to hold AT GENERATION TIME. This is the
            // structural fix for the prior build's whole "white on the team gradient" class: a pair
            // that cannot carry text is never constructed, so no call site has to remember.
            var worstText = Double.infinity
            var worstSecondary = Double.infinity
            var approvedCount = 0
            for (index, world) in sweptWorlds.enumerated() {
                for (id, identity) in world.identities {
                    worstText = Swift.min(worstText, identity.colours.textContrast)
                    if index == LEGAL_SWEEP_LEAGUES, ownerApprovedContrastExceptions.contains(id) {
                        if identity.colours.secondaryContrast < ColourGenerator.secondaryContrastFloor {
                            approvedCount += 1
                        }
                        continue
                    }
                    worstSecondary = Swift.min(worstSecondary, identity.colours.secondaryContrast)
                }
            }
            expect(worstText >= ColourGenerator.textContrastFloor,
                   "the worst generated pair carries text at \(worstText):1, under the "
                       + "\(ColourGenerator.textContrastFloor):1 floor")
            expect(worstSecondary >= ColourGenerator.secondaryContrastFloor,
                   "beyond the owner-approved exceptions, the worst generated secondary reads at "
                       + "\(worstSecondary):1 on its primary, under the "
                       + "\(ColourGenerator.secondaryContrastFloor):1 floor")
            expect(approvedCount == ownerApprovedContrastExceptions.count,
                   "the approved contrast exception list no longer matches the canonical world "
                       + "exactly (\(approvedCount) of \(ownerApprovedContrastExceptions.count) "
                       + "still fail) -- update the list deliberately rather than leaving it stale")
        }

        test("every fallback pair passes both tests, so the escape hatch is not the hole") {
            // ColourGenerator falls back after a bounded number of retries. A fallback that had not
            // been checked would be a way for an unchecked pair to reach a surface precisely when
            // the constraints were hardest to satisfy.
            for index in 0..<ColourGenerator.fallbackCount {
                let pair = ColourGenerator.fallback(index)
                expect(!ColourGenerator.collidesWithTradeDress(pair.primary, pair.secondary),
                       "fallback \(index) collides with real trade dress")
                expect(ColourGenerator.satisfiesContrastContract(pair),
                       "fallback \(index) carries text at \(pair.textContrast):1 and shows its "
                           + "secondary at \(pair.secondaryContrast):1")
                expect(!Blocklist.tradeDress.contains { $0.primary == pair.primary
                           && $0.secondary == pair.secondary },
                       "fallback \(index) is an exact real pair")
            }
        }
    }
}
