// swift-tools-version: 5.9
import Foundation
import PackageDescription

// Root shim so `.package(url: "https://github.com/paper-design/shaders", from: "0.1.0")`
// resolves — the real target lives in packages/shaders-metal-swift. Mirrors that
// package's PaperShadersMetal resource declaration (see its Package.swift for why
// PrecompiledShaders needs `.copy` while the sibling images stay `.process`).
let metalResourcesDir = URL(fileURLWithPath: #filePath)
    .deletingLastPathComponent()
    .appendingPathComponent("packages/shaders-metal-swift/Sources/PaperShadersMetal/Resources")
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
        .target(name: "PaperShadersMetal",
                path: "packages/shaders-metal-swift/Sources/PaperShadersMetal",
                resources: metalImageResources + [.copy("Resources/PrecompiledShaders")]),
    ]
)
