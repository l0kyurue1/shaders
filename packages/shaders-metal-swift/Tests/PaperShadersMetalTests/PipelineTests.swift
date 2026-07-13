import XCTest
import Metal
@testable import PaperShadersMetal

final class PipelineTests: XCTestCase {
    var device: MTLDevice!
    var dist: URL!

    override func setUpWithError() throws {
        device = MTLCreateSystemDefaultDevice()
        try XCTSkipIf(device == nil, "no Metal device")
        dist = try requireDist()
    }

    func testWarpPipelineReflection() throws {
        let p = try PipelineBuilder.build(device: device, shaderID: "warp", distURL: dist)
        let frag = try XCTUnwrap(p.fragmentParams)
        let names = frag.members.map(\.name)
        XCTAssertTrue(names.contains("u_time"))
        let colors = try XCTUnwrap(frag.members.first { $0.name == "u_colors" })
        XCTAssertEqual(colors.dataType, .float4)
        XCTAssertEqual(colors.arrayLength, 10)
        XCTAssertEqual(colors.arrayStride, 16)   // std140 vec4 array stride
        XCTAssertEqual(p.fragmentTextures, [TextureSlot(name: "u_noiseTexture", index: 0)])
        let vert = try XCTUnwrap(p.vertexParams)
        XCTAssertTrue(vert.members.map(\.name).contains("u_resolution"))
    }

    func testNoStageInFragmentBuilds() throws {
        // image-dithering's fragment has no [[stage_in]]; unconsumed vertex outputs must be legal
        XCTAssertNoThrow(try PipelineBuilder.build(device: device, shaderID: "image-dithering", distURL: dist))
    }

    func testGoldenGateAll29PipelinesBuild() throws {
        let manifest = try Manifest.load(distURL: dist)
        var failures: [String] = []
        for shader in manifest.shaders {
            do { _ = try PipelineBuilder.build(device: device, shaderID: shader.id, distURL: dist) }
            catch { failures.append("\(shader.id): \(error)") }
        }
        XCTAssertEqual(failures, [], "pipelines failed:\n\(failures.joined(separator: "\n"))")
    }

    func testTextureProviderLoadsBundledAssets() throws {
        let provider = try TextureProvider(device: device)
        let noise = try XCTUnwrap(provider.texture(for: TextureSlot(name: "u_noiseTexture", index: 0)))
        XCTAssertEqual(noise.width, 128)
        XCTAssertEqual(noise.height, 128)
        let image = try XCTUnwrap(provider.texture(for: TextureSlot(name: "u_image", index: 0)))
        XCTAssertGreaterThan(image.width, 0)
    }
}
