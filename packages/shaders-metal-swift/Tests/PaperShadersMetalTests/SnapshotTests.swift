import XCTest
import Metal
import Foundation
@testable import PaperShadersMetal

final class SnapshotTests: XCTestCase {
    // Fixed capture params — identical for goldens and asserts. Never change one
    // without regenerating every golden.
    let FRAME: Double = 1000
    let SIZE = 128
    let PIXEL_RATIO: Float = 1
    // ponytail: MAX_CHANNEL_DELTA/MAX_DIFF_FRACTION are cross-GPU tolerance ceilings — raise if CI GPU differs from the bless machine; a Y-flip still moves ≫0.5% of pixels
    let MAX_CHANNEL_DELTA = 4
    let MAX_DIFF_FRACTION = 0.005

    var device: MTLDevice!
    var dist: URL!

    override func setUpWithError() throws {
        device = MTLCreateSystemDefaultDevice()
        try XCTSkipIf(device == nil, "no Metal device")
        dist = try requireDist()
    }

    private var snapshotsDir: URL {
        URL(fileURLWithPath: #filePath).deletingLastPathComponent().appendingPathComponent("__Snapshots__")
    }

    /// Fraction of pixels whose max per-channel delta exceeds MAX_CHANNEL_DELTA.
    private func diff(_ a: [UInt8], _ b: [UInt8]) -> Double {
        precondition(a.count == b.count)
        let pixels = a.count / 4
        var differing = 0
        for p in 0..<pixels {
            let o = p * 4
            let dr = abs(Int(a[o+0]) - Int(b[o+0]))
            let dg = abs(Int(a[o+1]) - Int(b[o+1]))
            let db = abs(Int(a[o+2]) - Int(b[o+2]))
            let da = abs(Int(a[o+3]) - Int(b[o+3]))
            if max(max(dr, dg), max(db, da)) > MAX_CHANNEL_DELTA { differing += 1 }
        }
        return pixels == 0 ? 0 : Double(differing) / Double(pixels)
    }

    func testAllShaderSnapshots() throws {
        let manifest = try Manifest.load(distURL: dist)
        let update = ProcessInfo.processInfo.environment["UPDATE_GOLDENS"] != nil
        if update {
            try FileManager.default.createDirectory(at: snapshotsDir, withIntermediateDirectories: true)
        }

        for entry in manifest.shaders {
            let renderer = try ShaderRenderer(device: device, entry: entry, distURL: dist)
            renderer.clock.setFrame(FRAME)
            let bgra = try OffscreenRenderer(device: device).render(renderer, width: SIZE, height: SIZE, pixelRatio: PIXEL_RATIO)
            let actualPNG = try XCTUnwrap(PngCodec.encodePNG(bgra: bgra, width: SIZE, height: SIZE), "\(entry.id): encode failed")
            let goldenURL = snapshotsDir.appendingPathComponent("\(entry.id).png")

            if update {
                try actualPNG.write(to: goldenURL)
                continue
            }

            guard let goldenData = try? Data(contentsOf: goldenURL) else {
                XCTFail("\(entry.id): missing golden — run `UPDATE_GOLDENS=1 swift test --filter Snapshot`")
                continue
            }
            let golden = try XCTUnwrap(PngCodec.decodePNG(goldenData), "\(entry.id): golden decode failed")
            let actual = try XCTUnwrap(PngCodec.decodePNG(actualPNG), "\(entry.id): actual decode failed")
            guard golden.width == actual.width, golden.height == actual.height else {
                XCTFail("\(entry.id): dims \(actual.width)x\(actual.height) != golden \(golden.width)x\(golden.height)")
                continue
            }
            let frac = diff(golden.rgba, actual.rgba)
            if frac > MAX_DIFF_FRACTION {
                let failDir = URL(fileURLWithPath: NSTemporaryDirectory()).appendingPathComponent("snapshot-failures")
                try? FileManager.default.createDirectory(at: failDir, withIntermediateDirectories: true)
                let failURL = failDir.appendingPathComponent("\(entry.id).png")
                try? actualPNG.write(to: failURL)
                XCTFail("\(entry.id): \(frac) exceeds \(MAX_DIFF_FRACTION); actual at \(failURL.path)")
            }
        }
    }
}
