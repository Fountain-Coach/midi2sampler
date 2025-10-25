
// swift-tools-version: 5.9
import PackageDescription

let package = Package(
    name: "Midi2SamplerDSP",
    defaultLocalization: "en",
    platforms: [
        .iOS(.v15), .macOS(.v14)
    ],
    products: [
        .library(name: "Midi2SamplerDSP", targets: ["Midi2SamplerDSP"]),
    ],
    dependencies: [
        // MIDI 2.0 dependency (GitHub) — use a tagged, stable release
        .package(url: "https://github.com/Fountain-Coach/midi2", from: "0.3.1")
    ],
    targets: [
        .target(
            name: "Midi2SamplerDSP",
            dependencies: [
                .product(name: "MIDI2", package: "midi2")
            ],
            path: "Sources/Midi2SamplerDSP",
            exclude: [
                "Corpus",
                "Persistence",
                "Service",
                "Validation",
                "LoopStitcher.swift",
                "Resampler.swift",
                "SpectralDistance.swift"
            ]
        ),
        .testTarget(
            name: "Midi2SamplerDSPTests",
            dependencies: ["Midi2SamplerDSP"],
            path: "Tests/Midi2SamplerDSPTests"
        ),
    ]
)
