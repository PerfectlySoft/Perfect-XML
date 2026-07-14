// swift-tools-version: 6.2
import PackageDescription

let package = Package(
    name: "PerfectXML",
    platforms: [
        .macOS(.v26),
    ],
    products: [
        .library(name: "PerfectXML", targets: ["PerfectXML"])
    ],
    dependencies: [],
    targets: [
        // Inline system library wrapping libxml2 — replaces Perfect-libxml2
        .systemLibrary(
            name: "libxml2",
            pkgConfig: "libxml-2.0",
            providers: [
                .brew(["libxml2"]),
                .apt(["libxml2-dev"]),
            ]
        ),
        .target(
            name: "PerfectXML",
            dependencies: [
                "libxml2",
            ]
        ),
        .testTarget(
            name: "PerfectXMLTests",
            dependencies: ["PerfectXML"]
        ),
    ]
)
