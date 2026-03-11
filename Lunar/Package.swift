// swift-tools-version:5.9
import PackageDescription

let package = Package(
    name: "LunarSwift",
    platforms: [
        .iOS(.v13),
        .macOS(.v10_15),
        .tvOS(.v13),
        .watchOS(.v6)
    ],
    products: [
        .library(name: "LunarSwift", targets: ["LunarSwift"])
    ],
    targets: [
        .target(name: "LunarSwift", path: "Sources/Lunar"),
        .testTarget(name: "LunarSwiftTests", dependencies: ["LunarSwift"], path: "Tests/LunarTests")
    ]
)
