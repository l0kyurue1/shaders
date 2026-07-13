import XCTest
@testable import PaperShadersMetal

final class SessionCodecTests: XCTestCase {
    func warpEntry() throws -> ShaderEntry {
        let dist = try requireDist()
        return try XCTUnwrap(Manifest.load(distURL: dist).shaders.first { $0.id == "warp" })
    }

    func testDecodeNameKeyedJSON() throws {
        let entry = try warpEntry()
        let (values, speed) = SessionCodec.decode(
            ["scale": 2.0, "shape": "stripes", "colors": ["#ff0000"], "speed": 3.0, "unknownKey": 1],
            entry: entry)
        XCTAssertEqual(values["u_scale"], .float(2))
        XCTAssertEqual(values["u_shape"], .float(1))               // "stripes" via options
        XCTAssertEqual(values["u_colors"], .colors([SIMD4(1, 0, 0, 1)]))
        XCTAssertEqual(speed, 3.0)
        XCTAssertNil(values["unknownKey"])                          // ignored, not crashed
    }

    func testEncodeRoundTripsDefaults() throws {
        let entry = try warpEntry()
        let json = SessionCodec.encode(values: entry.defaultUniformValues(), speed: 1, entry: entry)
        XCTAssertEqual(json["shape"], .string("checks"))            // enum float → label, not 0
        guard case .stringArray(let colors)? = json["colors"] else { return XCTFail("colors missing") }
        XCTAssertEqual(colors.first, "#121212")
        XCTAssertEqual(json["speed"], .number(1))
        let (values, _) = SessionCodec.decode(json, entry: entry)
        XCTAssertEqual(values, entry.defaultUniformValues())        // lossless round-trip
    }
}
