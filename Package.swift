// swift-tools-version:5.9
import PackageDescription

let package = Package(
    name: "FastTranslate",
    platforms: [
        .macOS(.v14)
    ],
    targets: [
        .executableTarget(
            name: "FastTranslate",
            path: "Sources/FastTranslate"
        )
    ]
)
