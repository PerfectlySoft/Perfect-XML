// swift-tools-version: 6.2
import PackageDescription

// Inline system library wrapping libxml2 — replaces Perfect-libxml2.
//
// No `pkgConfig` on macOS: recent CommandLineTools/Xcode SDKs bundle
// libxml2's headers (and, on some SDK versions, their own libxml-2.0.pc)
// directly, and Clang finds them via its default system search path with
// zero extra flags. If a Homebrew libxml2 is *also* on PKG_CONFIG_PATH,
// asking pkg-config here can resolve to Homebrew's copy instead, mixing
// its headers with the SDK's in the same module build ("conflicting
// types" for symbols like __oldXMLWDcompatibility). See
// Documentation/libxml2-pkgconfig-collision.md.
// Linux has no bundled system copy, so pkg-config + apt stays required there.
#if os(macOS)
let libxml2Target: Target = .systemLibrary(name: "libxml2")
#else
let libxml2Target: Target = .systemLibrary(
    name: "libxml2",
    pkgConfig: "libxml-2.0",
    providers: [
        .apt(["libxml2-dev"]),
    ]
)
#endif

let package = Package(
    name: "PerfectXML",
    platforms: [
        .macOS(.v12),
    ],
    products: [
        .library(name: "PerfectXML", targets: ["PerfectXML"])
    ],
    dependencies: [],
    targets: [
        libxml2Target,
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
