// swift-tools-version:5.5
import PackageDescription

let package = Package(
    name: "MWRequest",
    platforms: [
        .macOS(.v10_13), .iOS(.v11), .tvOS(.v11), .watchOS(.v4)
    ],
    products: [
        .library(name: "MWRequest", targets: ["MWRequest"]),
    ],
    targets: [
        .target(name: "MWRequest", dependencies: []),
        .testTarget(name: "MWRequestTests", dependencies: ["MWRequest"]),
    ]
)
