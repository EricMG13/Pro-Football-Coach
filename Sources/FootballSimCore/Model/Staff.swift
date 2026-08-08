import Foundation

/// The four ways a head coach starts his career. Each opens one skill branch with a free point.
public enum CoachBackground: String, Codable, CaseIterable, Sendable {
    case formerPlayer
    case talentEvaluator
    case playcaller
    case defensiveMind

    public var displayName: String {
        switch self {
        case .formerPlayer: "Former Player"
        case .talentEvaluator: "Talent Evaluator"
        case .playcaller: "Playcaller"
        case .defensiveMind: "Defensive Mind"
        }
    }

    public var detail: String {
        switch self {
        case .formerPlayer: "Unlocks Development skills"
        case .talentEvaluator: "Unlocks Scouting skills"
        case .playcaller: "Unlocks Offense skills"
        case .defensiveMind: "Unlocks Defense skills"
        }
    }

    public var branch: SkillBranch {
        switch self {
        case .formerPlayer: .development
        case .talentEvaluator: .scouting
        case .playcaller: .offense
        case .defensiveMind: .defense
        }
    }
}

public enum SkillBranch: String, Codable, CaseIterable, Sendable, Hashable, CodingKeyRepresentable {
    case scouting, development, offense, defense

    public var displayName: String {
        switch self {
        case .scouting: "Scouting"
        case .development: "Development"
        case .offense: "Offense"
        case .defense: "Defense"
        }
    }
}

/// Which unit a coordinator runs.
public enum StaffRole: String, Codable, CaseIterable, Sendable, Hashable, CodingKeyRepresentable {
    case offensiveCoordinator
    case defensiveCoordinator
    case specialTeamsCoordinator

    public var abbreviation: String {
        switch self {
        case .offensiveCoordinator: "OC"
        case .defensiveCoordinator: "DC"
        case .specialTeamsCoordinator: "STC"
        }
    }

    public var displayName: String {
        switch self {
        case .offensiveCoordinator: "Offensive Coordinator"
        case .defensiveCoordinator: "Defensive Coordinator"
        case .specialTeamsCoordinator: "Special Teams Coordinator"
        }
    }
}

public enum StaffTrait: String, Codable, CaseIterable, Sendable {
    case developer
    case motivator
    case negotiator

    public var displayName: String {
        switch self {
        case .developer: "Developer"
        case .motivator: "Motivator"
        case .negotiator: "Negotiator"
        }
    }

    public var detail: String {
        switch self {
        case .developer: "Squeezes extra growth out of training camp."
        case .motivator: "Keeps the locker room happy."
        case .negotiator: "Signs staff and players for less."
        }
    }
}

/// A hired coordinator. Rating drives unit strength, play-call quality and development.
public struct StaffMember: Codable, Identifiable, Sendable, Equatable {
    public let id: UUID
    public var firstName: String
    public var lastName: String
    public var role: StaffRole
    public var age: Int
    /// 40...99, same scale as players.
    public var rating: Int
    /// Scheme he actually knows. Mismatched with the team's scheme, his bonus is halved.
    public var offensiveScheme: OffensiveScheme?
    public var defensiveScheme: DefensiveScheme?
    public var trait: StaffTrait?
    public var salary: Int
    public var contractYears: Int
    /// Rises with team success; high scores get poached for head-coaching jobs.
    public var headCoachCandidacy: Int

    public init(
        id: UUID = UUID(),
        firstName: String,
        lastName: String,
        role: StaffRole,
        age: Int,
        rating: Int,
        offensiveScheme: OffensiveScheme? = nil,
        defensiveScheme: DefensiveScheme? = nil,
        trait: StaffTrait? = nil,
        salary: Int,
        contractYears: Int,
        headCoachCandidacy: Int = 0
    ) {
        self.id = id
        self.firstName = firstName
        self.lastName = lastName
        self.role = role
        self.age = age
        self.rating = rating.clampedToRating()
        self.offensiveScheme = offensiveScheme
        self.defensiveScheme = defensiveScheme
        self.trait = trait
        self.salary = salary
        self.contractYears = contractYears
        self.headCoachCandidacy = headCoachCandidacy
    }

    public var name: String { "\(firstName) \(lastName)" }

    /// Whether this coordinator's specialty matches what the team runs.
    public func matchesScheme(offense: OffensiveScheme, defense: DefensiveScheme) -> Bool {
        switch role {
        case .offensiveCoordinator: offensiveScheme == offense
        case .defensiveCoordinator: defensiveScheme == defense
        case .specialTeamsCoordinator: true
        }
    }

    /// Unit-rating bonus, 0 at rating 60 and +3 at 95, halved on a scheme mismatch.
    public func unitBonus(offense: OffensiveScheme, defense: DefensiveScheme) -> Double {
        let raw = Swift.max(0, Double(rating - 60)) / 35.0 * 3.0
        return matchesScheme(offense: offense, defense: defense) ? raw : raw / 2
    }

    /// 0...1 quality of this coordinator's suggested play calls.
    public var playCallQuality: Double {
        Swift.min(1.0, Swift.max(0.35, Double(rating - 40) / 55.0))
    }

    /// Extra training-camp development for his side of the ball, up to +15% (+5% with Developer).
    public var developmentBonus: Double {
        let base = Swift.max(0, Double(rating - 60)) / 35.0 * 0.15
        return base + (trait == .developer ? 0.05 : 0)
    }
}

/// The user's own coaching career: identity, progression, contract and job security.
public struct CoachProfile: Codable, Sendable, Equatable {
    public var firstName: String
    public var lastName: String
    public var age: Int
    public var background: CoachBackground
    public var level: Int
    public var experience: Int
    public var skillPoints: Int
    /// Nodes unlocked per branch, keyed by branch, storing node indexes.
    public var unlockedNodes: [SkillBranch: [Int]]
    public var salary: Int
    public var contractYears: Int
    public var contractYearsElapsed: Int
    /// 0...100. Zero means fired at the next carousel.
    public var jobSecurity: Int
    public var careerWins: Int
    public var careerLosses: Int
    public var careerTies: Int
    public var championships: Int
    public var playoffAppearances: Int
    public var teamsCoached: Int
    public var cash: Int

    public init(
        firstName: String,
        lastName: String,
        age: Int,
        background: CoachBackground,
        level: Int = 1,
        experience: Int = 0,
        skillPoints: Int = 1,
        unlockedNodes: [SkillBranch: [Int]] = [:],
        salary: Int = 2_400_000,
        contractYears: Int = 3,
        contractYearsElapsed: Int = 0,
        jobSecurity: Int = 50,
        careerWins: Int = 0,
        careerLosses: Int = 0,
        careerTies: Int = 0,
        championships: Int = 0,
        playoffAppearances: Int = 0,
        teamsCoached: Int = 1,
        cash: Int = 500_000
    ) {
        self.firstName = firstName
        self.lastName = lastName
        self.age = age
        self.background = background
        self.level = level
        self.experience = experience
        self.skillPoints = skillPoints
        self.unlockedNodes = unlockedNodes
        self.salary = salary
        self.contractYears = contractYears
        self.contractYearsElapsed = contractYearsElapsed
        self.jobSecurity = jobSecurity
        self.careerWins = careerWins
        self.careerLosses = careerLosses
        self.careerTies = careerTies
        self.championships = championships
        self.playoffAppearances = playoffAppearances
        self.teamsCoached = teamsCoached
        self.cash = cash
    }

    public var name: String { "\(firstName) \(lastName)" }

    public var contractYearsRemaining: Int { Swift.max(0, contractYears - contractYearsElapsed) }

    public var recordDescription: String {
        careerTies > 0
            ? "\(careerWins)-\(careerLosses)-\(careerTies)"
            : "\(careerWins)-\(careerLosses)"
    }

    /// Experience needed to reach the next level; each level costs 15% more than the last.
    public var experienceForNextLevel: Int {
        Int((100.0 * pow(1.15, Double(level - 1))).rounded())
    }

    public func hasUnlocked(branch: SkillBranch, node: Int) -> Bool {
        unlockedNodes[branch]?.contains(node) ?? false
    }

    public static func stub(
        firstName: String = "Alex",
        lastName: String = "Rivers",
        background: CoachBackground = .playcaller
    ) -> CoachProfile {
        CoachProfile(firstName: firstName, lastName: lastName, age: 40, background: background)
    }
}
