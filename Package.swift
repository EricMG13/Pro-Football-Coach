// swift-tools-version: 6.0
import PackageDescription

// One package, two library targets:
//   FootballSimCore    — pure simulation logic, no UI imports, fully unit-tested
//   ProFootballCoachUI — SwiftUI feature layer (type-checks on macOS so it stays verified
//                        even when building without full Xcode; the iOS app target is a
//                        thin @main shell in App/ generated from project.yml)
//
// Tests run through a hand-rolled harness (Tests/SimTests/TestKit.swift) as an executable
// target: neither XCTest nor swift-testing ships with the Swift Command Line Tools — both
// live inside Xcode — so this is what lets the suite run from the command line.
let package = Package(
    name: "ProFootballCoach",
    platforms: [.iOS("26.0"), .macOS(.v14)],
    products: [
        .library(name: "FootballSimCore", targets: ["FootballSimCore"]),
        .library(name: "ProFootballCoachUI", targets: ["ProFootballCoachUI"]),
    ],
    targets: [
        .target(name: "FootballSimCore", path: "Sources/FootballSimCore"),
        .target(
            name: "ProFootballCoachUI",
            dependencies: ["FootballSimCore"],
            path: "Sources/ProFootballCoachUI"
        ),
        // Hand-rolled harness (see Tests/SimTests/TestKit.swift): XCTest and
        // swift-testing both require full Xcode, so the suite runs as an executable.
        .executableTarget(
            name: "SimTests",
            dependencies: ["FootballSimCore", "ProFootballCoachUI"],
            path: "Tests/SimTests"
        ),
    ],
    swiftLanguageModes: [.v5]
)
