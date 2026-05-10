// swift-tools-version: 5.9
import PackageDescription

let package = Package(
    name: "MedATFiguren",
    defaultLocalization: "de",
    platforms: [
        .iOS(.v17),
        .macOS(.v14),
    ],
    products: [
        .library(
            name: "MedATFiguren",
            targets: ["MedATFiguren"]
        ),
    ],
    targets: [
        .target(
            name: "MedATFiguren",
            path: "Sources/MedATFiguren"
        ),
        .testTarget(
            name: "MedATFigurenTests",
            dependencies: ["MedATFiguren"],
            path: "Tests/MedATFigurenTests"
        ),
    ]
)
