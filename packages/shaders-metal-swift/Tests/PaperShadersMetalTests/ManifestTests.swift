import XCTest
@testable import PaperShadersMetal

final class ManifestTests: XCTestCase {
    func loadManifest() throws -> Manifest {
        let dist = try requireDist()
        let data = try Data(contentsOf: dist.appendingPathComponent("manifest.json"))
        return try JSONDecoder().decode(Manifest.self, from: data)
    }

    func testDecodesAll29Shaders() throws {
        let manifest = try loadManifest()
        XCTAssertEqual(manifest.version, 1)
        XCTAssertEqual(manifest.shaders.count, 29)
    }

    func testWarpEntry() throws {
        let warp = try XCTUnwrap(loadManifest().shaders.first { $0.id == "warp" })
        XCTAssertEqual(warp.params.count, 19)
        let shape = try XCTUnwrap(warp.params.first { $0.name == "shape" })
        XCTAssertEqual(shape.kind, .string)
        XCTAssertEqual(shape.options?["stripes"], 1)
        let colors = try XCTUnwrap(warp.params.first { $0.name == "colors" })
        XCTAssertEqual(colors.kind, .colors)
        XCTAssertEqual(colors.maxCount, 10)
    }

    func testParamGroupDecodes() throws {
        let warp = try XCTUnwrap(loadManifest().shaders.first { $0.id == "warp" })
        XCTAssertEqual(warp.params.first { $0.name == "colors" }?.group, "Colors")
        XCTAssertEqual(warp.params.first { $0.name == "fit" }?.group, "Transform")

        // Absent `group` (pre-schema manifest) decodes nil, not a decode failure.
        let json = """
        {"version":1,"shaders":[
          {"id":"x","params":[
            {"name":"scale","uniform":"u_scale","kind":"number","default":1.0}]}
        ]}
        """
        let e = try XCTUnwrap(JSONDecoder().decode(Manifest.self, from: Data(json.utf8)).shaders.first)
        XCTAssertNil(e.params.first?.group)
    }

    func testHexColorParsing() {
        XCTAssertEqual(SIMD4<Float>(hex: "#9470ff"), SIMD4(0x94 / 255, 0x70 / 255, 1.0, 1.0))
        XCTAssertEqual(SIMD4<Float>(hex: "#fff"), SIMD4(1, 1, 1, 1))
        XCTAssertEqual(SIMD4<Float>(hex: "#12345678")?.w, 0x78 / 255)
        XCTAssertNil(SIMD4<Float>(hex: "red"))
    }

    func testRuntimeOnlyParamConcept() throws {
        let json = """
        {"version":1,"shaders":[
          {"id":"x","params":[
            {"name":"speed","uniform":null,"kind":"number","default":1.5},
            {"name":"frame","uniform":null,"kind":"number","default":0},
            {"name":"scale","uniform":"u_scale","kind":"number","default":1.0}]}
        ]}
        """
        let e = try XCTUnwrap(JSONDecoder().decode(Manifest.self, from: Data(json.utf8)).shaders.first)
        XCTAssertEqual(e.defaultSpeed, 1.5)
        XCTAssertEqual(e.params.filter(\.isRuntimeOnly).map(\.name), ["speed", "frame"])
        XCTAssertFalse(try XCTUnwrap(e.params.last).isRuntimeOnly)
    }

    func testEntryWithoutNewFieldsDecodesWithDefaults() throws {
        let json = """
        {"version":1,"shaders":[
          {"id":"old-shader","params":[{"name":"scale","uniform":"u_scale","kind":"number","default":1.0}]}
        ]}
        """
        let m = try JSONDecoder().decode(Manifest.self, from: Data(json.utf8))
        let e = try XCTUnwrap(m.shaders.first)
        XCTAssertEqual(e.name, "old-shader")     // name → id
        XCTAssertEqual(e.category, "Effects")    // category → Effects
        XCTAssertTrue(e.presets.isEmpty)         // presets → []
    }

    func testEntryWithNewFieldsAndPresetCoercion() throws {
        let json = """
        {"version":1,"shaders":[
          {"id":"fluted-glass","name":"Fluted Glass","category":"Image Filters",
           "params":[{"name":"scale","uniform":"u_scale","kind":"number","default":1.0}],
           "presets":[{"name":"Prism","params":{"scale":2.0,"shape":"lines","fancy":true,"colors":["#fff"]}}]}
        ]}
        """
        let m = try JSONDecoder().decode(Manifest.self, from: Data(json.utf8))
        let e = try XCTUnwrap(m.shaders.first)
        XCTAssertEqual(e.name, "Fluted Glass")
        XCTAssertEqual(e.category, "Image Filters")
        let preset = try XCTUnwrap(e.presets.first)
        XCTAssertEqual(preset.name, "Prism")
        XCTAssertEqual(preset.params["scale"], .number(2.0))
        XCTAssertEqual(preset.params["shape"], .string("lines"))
        XCTAssertEqual(preset.params["fancy"], .bool(true))
        XCTAssertEqual(preset.params["colors"], .stringArray(["#fff"]))
    }

    func testDefaultUniformValues() throws {
        let warp = try XCTUnwrap(loadManifest().shaders.first { $0.id == "warp" })
        let defaults = warp.defaultUniformValues()
        XCTAssertNil(defaults["speed"])          // uniform == nil → excluded
        XCTAssertNil(defaults["u_speed"])
        guard case .colors(let cs)? = defaults["u_colors"] else { return XCTFail("u_colors missing") }
        XCTAssertEqual(cs.count, 4)
        guard case .float(let shape)? = defaults["u_shape"] else { return XCTFail("u_shape missing") }
        XCTAssertEqual(shape, 0)                 // "checks" → 0 via options
        // single-color string params resolve to .color
        let gem = try XCTUnwrap(loadManifest().shaders.first { $0.id == "gem-smoke" })
        guard case .color? = gem.defaultUniformValues()["u_colorBack"] else { return XCTFail("u_colorBack not a color") }
    }
}
