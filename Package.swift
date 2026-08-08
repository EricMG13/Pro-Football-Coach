// swift-tools-version: 6.0
import PackageDescription

// One package, two library targets:
//   FootballSimCore    — pure simulation logic, no UI imports, fully unit-tested
//   ProFootballCoachUI — SwiftUI feature layer (type-checks on macOS so it stays verified
//                        even when building without full Xcode; the iOS app target is a
//                        thin @main shell in App/ generated from project.yml)
//
// Tests use swift-testing (bundled with the toolchain) rather than XCTest so the suite
// runs from the command line without a full Xcode install.
let package = Package(
    name: "ProFootballCoach",
    platforms: [.iOS(.v17), .macOS(.v14)],
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
