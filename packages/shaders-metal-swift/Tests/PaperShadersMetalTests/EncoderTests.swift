import XCTest
import Metal
@testable import PaperShadersMetal

final class EncoderTests: XCTestCase {
    var layout: BufferLayout!

    override func setUpWithError() throws {
        let device = MTLCreateSystemDefaultDevice()
        try XCTSkipIf(device == nil, "no Metal device")
        let dist = try requireDist()
        layout = try XCTUnwrap(PipelineBuilder.build(device: device!, shaderID: "warp", distURL: dist).fragmentParams)
    }

    private func readFloat(_ data: Data, at offset: Int) -> Float {
        data.subdata(in: offset..<offset + 4).withUnsafeBytes { $0.load(as: Float.self) }
    }

    func testEncodesScalarsAtReflectedOffsets() throws {
        let data = ParamsEncoder.encode(layout: layout, values: ["u_scale": .float(2.5), "u_time": .float(7)])
        XCTAssertEqual(data.count, layout.size)
        XCTAssertEqual(readFloat(data, at: layout.member("u_scale")!.offset), 2.5)
        XCTAssertEqual(readFloat(data, at: layout.member("u_time")!.offset), 7)
        XCTAssertEqual(readFloat(data, at: layout.member("u_softness")!.offset), 0)  // missing → zero
    }

    func testEncodesColorArrayAndDerivedCount() throws {
        let red = SIMD4<Float>(1, 0, 0, 1), blue = SIMD4<Float>(0, 0, 1, 1)
        let data = ParamsEncoder.encode(layout: layout, values: ["u_colors": .colors([red, blue])])
        let colors = layout.member("u_colors")!
        XCTAssertEqual(readFloat(data, at: colors.offset), 1)                          // red.r
        XCTAssertEqual(readFloat(data, at: colors.offset + colors.arrayStride + 8), 1) // blue.b
        XCTAssertEqual(readFloat(data, at: colors.offset + 2 * colors.arrayStride), 0) // zero-padded tail
        XCTAssertEqual(readFloat(data, at: layout.member("u_colorsCount")!.offset), 2) // derived
    }

    func testBoolEncoding() throws {
        // warp has no bool member; synthesize a layout to cover bool→uint packing
        let boolLayout = BufferLayout(size: 4, members: [MemberLayout(name: "u_flag", offset: 0, dataType: .bool, arrayLength: 1, arrayStride: 0)])
        let data = ParamsEncoder.encode(layout: boolLayout, values: ["u_flag": .bool(true)])
        XCTAssertEqual(data.withUnsafeBytes { $0.load(as: UInt32.self) }, 1)
    }

    func testValidatePassesForRealShaderWithProbeValues() throws {
        let probe = RuntimeUniforms.probeValues(textureSlots: [TextureSlot(name: "u_noiseTexture", index: 0)])
        XCTAssertEqual(ParamsEncoder.validate(layout: layout, values: probe), [])
    }

    func testValidateReportsTypeMismatch() throws {
        // A float4 uniform fed a plain float = manifest/MSL drift; must be named, not silent.
        let badLayout = BufferLayout(size: 16, members: [MemberLayout(name: "u_tint", offset: 0, dataType: .float4, arrayLength: 1, arrayStride: 0)])
        let mismatches = ParamsEncoder.validate(layout: badLayout, values: ["u_tint": .float(1)])
        XCTAssertEqual(mismatches.count, 1)
        XCTAssertTrue(mismatches[0].contains("u_tint"))
    }
}
