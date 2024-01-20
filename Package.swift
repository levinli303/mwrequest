// swift-tools-version:5.9
import PackageDescription

let package = Package(
    name: "MWRequest",
    platforms: [
        .macOS(.v10_13), .iOS(.v12), .tvOS(.v12), .watchOS(.v4), .visionOS(.v1)
    ],
    products: [
        .library(name: "MWRequest", targets: ["MWRequest"]),
    ],
    targets: [
        .target(name: "MWRequest", dependencies: []),
        .testTarget(name: "MWRequestTests", dependencies: ["MWRequest"]),
    ]
)
