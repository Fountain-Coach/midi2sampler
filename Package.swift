
// swift-tools-version: 5.9
import PackageDescription

let package = Package(
    name: "Midi2SamplerDSP",
    defaultLocalization: "en",
    platforms: [
        .iOS(.v15), .macOS(.v12)
    ],
    products: [
        .library(name: "Midi2SamplerDSP", targets: ["Midi2SamplerDSP"]),
    ],
    dependencies: [
        // MIDI 2.0 dependency (GitHub). We pin to branch `main` here;
        // feel free to replace with a version tag once released.
        .package(url: "https://github.com/Fountain-Coach/midi2", branch: "main")
    ],
    targets: [
        .target(
            name: "Midi2SamplerDSP",
            dependencies: [
                // Assuming the product is exported as "MIDI2" from the midi2 package.
                // If the actual product name differs, adjust the string below accordingly.
                .product(name: "MIDI2", package: "midi2")
            ],
            path: "Sources/Midi2SamplerDSP",
            swiftSettings: [
                .define("USE_ACCELERATE", .when(platforms: [.macOS, .iOS]))
            ]
        ),
        .testTarget(
            name: "Midi2SamplerDSPTests",
            dependencies: ["Midi2SamplerDSP"],
            path: "Tests/Midi2SamplerDSPTests"
        ),
    ]
)
