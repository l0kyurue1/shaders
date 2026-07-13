import XCTest
@testable import PaperShadersMetal

extension XCTestCase {
    /// One shared dist lookup for every suite — the single test-side DistLocator call site.
    func requireDist() throws -> URL {
        try XCTUnwrap(DistLocator.locate(), "dist not found — run `bun run build` in packages/shaders-metal")
    }
}
