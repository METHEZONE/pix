// swift-tools-version: 5.9
import PackageDescription

let package = Package(
    name: "Pix",
    platforms: [.macOS(.v14)],
    targets: [
        .executableTarget(
            name: "Pix",
            path: "Pix",
            resources: [
                .copy("Assets.xcassets"),
                .copy("Sounds")
            ]
        )
    ]
)
