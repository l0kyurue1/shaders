import XCTest
@testable import PaperShadersMetal

final class DistLocatorTests: XCTestCase {
    /// A filePath outside the repo defeats the monorepo walk-up, so this exercises the
    /// bundled PrecompiledShaders resource fallback — the default for a downstream SPM
    /// consumer with no monorepo checkout.
    func testFallsBackToBundledPrecompiledShadersOutsideRepo() throws {
        XCTAssertNil(ProcessInfo.processInfo.environment["PAPER_SHADERS_DIST"],
                     "PAPER_SHADERS_DIST set — would short-circuit the fallback this test targets")
        let distURL = try XCTUnwrap(DistLocator.locate(filePath: "/private/tmp/not-a-repo/DistLocator.swift"))
        let manifest = try Manifest.load(distURL: distURL)
        XCTAssertEqual(manifest.shaders.count, 29)
        XCTAssertTrue(FileManager.default.fileExists(atPath: distURL.appendingPathComponent("vertex.metal").path))
    }
}
