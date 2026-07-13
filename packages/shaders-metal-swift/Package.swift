// swift-tools-version: 5.9
import Foundation
import PackageDescription

// PrecompiledShaders holds raw .metal source copied by scripts/sync-dist.sh — it must
// use `.copy` so SwiftPM doesn't treat the files as Metal shaders to compile ahead of
// time (that's `.process`'s special-casing, and every fragment shares a `main0` entry
// point, so ahead-of-time compilation collides). `.process` and `.copy` rules can't
// overlap, so the sibling image/icon resources are enumerated individually here
// instead of via a single directory-wide `.process("Resources")`.
let metalResourcesDir = URL(fileURLWithPath: #filePath)
    .deletingLastPathComponent()
    .appendingPathComponent("Sources/PaperShadersMetal/Resources")
let metalImageResources: [Resource] = ((try? FileManager.default.contentsOfDirectory(atPath: metalResourcesDir.path)) ?? [])
    .filter { $0 != "PrecompiledShaders" }
    .map { .process("Resources/\($0)") }

let package = Package(
    name: "PaperShadersMetal",
    platforms: [.macOS(.v14), .iOS(.v17)],
    products: [
        .library(name: "PaperShadersMetal", targets: ["PaperShadersMetal"]),
    ],
    targets: [
        .target(name: "PaperShadersMetal", resources: metalImageResources + [.copy("Resources/PrecompiledShaders")]),
        .executableTarget(name: "PaperShadersPreview", dependencies: ["PaperShadersMetal"],
                          resources: [.process("Resources")]),
        .testTarget(name: "PaperShadersMetalTests", dependencies: ["PaperShadersMetal", "PaperShadersPreview"]),
    ]
)
