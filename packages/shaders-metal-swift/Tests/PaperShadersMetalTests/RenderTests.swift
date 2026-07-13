import XCTest
import Metal
@testable import PaperShadersMetal

final class RenderTests: XCTestCase {
    var device: MTLDevice!
    var dist: URL!

    override func setUpWithError() throws {
        device = MTLCreateSystemDefaultDevice()
        try XCTSkipIf(device == nil, "no Metal device")
        dist = try requireDist()
    }

    private func makeRenderer(_ id: String) throws -> ShaderRenderer {
        let manifest = try Manifest.load(distURL: dist)
        let entry = try XCTUnwrap(manifest.shaders.first { $0.id == id })
        return try ShaderRenderer(device: device, entry: entry, distURL: dist)
    }

    func testClockMatchesWebSemantics() {
        let clock = RenderClock()
        clock.speed = 2
        clock.tick(now: 10.0)          // first tick establishes baseline
        clock.tick(now: 10.5)          // +500ms × speed 2 = 1000ms
        XCTAssertEqual(clock.frame, 1000, accuracy: 0.001)
        XCTAssertEqual(clock.timeSeconds, 1.0, accuracy: 0.0001)
        clock.setFrame(0)
        XCTAssertEqual(clock.timeSeconds, 0)
    }

    func testWarpRendersNonConstantImage() throws {
        let renderer = try makeRenderer("warp")
        let bytes = try OffscreenRenderer(device: device).render(renderer, width: 256, height: 256)
        XCTAssertEqual(bytes.count, 256 * 256 * 4)
        XCTAssertGreaterThan(Set(bytes).count, 8, "output is (near-)constant — shader likely not executing")
    }

    func testRenderIsDeterministicAtFixedFrame() throws {
        let renderer = try makeRenderer("simplex-noise")
        renderer.clock.setFrame(1234)
        let a = try OffscreenRenderer(device: device).render(renderer, width: 128, height: 128)
        renderer.clock.setFrame(1234)
        let b = try OffscreenRenderer(device: device).render(renderer, width: 128, height: 128)
        XCTAssertEqual(a, b)
    }

    func testTimeChangesOutput() throws {
        let renderer = try makeRenderer("warp")
        renderer.clock.setFrame(0)
        let a = try OffscreenRenderer(device: device).render(renderer, width: 128, height: 128)
        renderer.clock.setFrame(5000)
        let b = try OffscreenRenderer(device: device).render(renderer, width: 128, height: 128)
        XCTAssertNotEqual(a, b)
    }

    func testImageShaderRenders() throws {
        // texture-binding path (u_image) + a gl_FragCoord shader
        let renderer = try makeRenderer("image-dithering")
        let bytes = try OffscreenRenderer(device: device).render(renderer, width: 128, height: 128)
        XCTAssertGreaterThan(Set(bytes).count, 8)
    }
}
