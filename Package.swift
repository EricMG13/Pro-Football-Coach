// swift-tools-version: 5.10
import PackageDescription

// One package, two library targets:
//   FootballSimCore   — pure simulation logic, no UI imports, fully unit-tested
//   ProFootballCoachUI — SwiftUI feature layer (type-checks on macOS so it stays verified
//                        even when building without full Xcode; the iOS app target is a
//                        thin @main shell in App/ generated from project.yml)
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
        .testTarget(
            name: "FootballSimCoreTests",
            dependencies: ["FootballSimCore"],
            path: "Tests/FootballSimCoreTests"
        ),
    ]
)
