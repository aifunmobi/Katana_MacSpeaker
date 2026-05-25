// swift-tools-version: 5.9
import PackageDescription

let package = Package(
    name: "KatanaMacSpeaker",
    platforms: [
        .macOS(.v11)
    ],
    products: [
        .executable(name: "katana-macspeaker", targets: ["KatanaMacSpeaker"])
    ],
    targets: [
        .executableTarget(
            name: "KatanaMacSpeaker",
            path: "Sources/KatanaMacSpeaker"
        )
    ]
)
