// swift-tools-version: 5.9
import PackageDescription

let package = Package(
    name: "PaperShadersMetal",
    platforms: [.macOS(.v14)],
    targets: [
        .target(name: "PaperShadersMetal", resources: [.process("Resources")]),
        .executableTarget(name: "PaperShadersPreview", dependencies: ["PaperShadersMetal"],
                          resources: [.process("Resources")]),
        .testTarget(name: "PaperShadersMetalTests", dependencies: ["PaperShadersMetal", "PaperShadersPreview"]),
    ]
)
