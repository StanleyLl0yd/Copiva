// swift-tools-version: 6.2
import PackageDescription

let package = Package(
    name: "Copiva",
    platforms: [.macOS(.v26)],
    products: [
        .executable(name: "Copiva", targets: ["Copiva"])
    ],
    targets: [
        .target(name: "CopivaCore", path: "Sources/CopivaCore",
                linkerSettings: [.linkedLibrary("sqlite3")]),
        .target(name: "CopivaMac", dependencies: ["CopivaCore"]),
        .executableTarget(name: "Copiva", dependencies: ["CopivaCore", "CopivaMac"], path: "Sources/Copiva"),
        .testTarget(name: "CopivaCoreTests", dependencies: ["CopivaCore"], path: "Tests/CopivaCoreTests"),
        .testTarget(name: "CopivaMacTests", dependencies: ["CopivaMac", "CopivaCore"])
    ]
)
