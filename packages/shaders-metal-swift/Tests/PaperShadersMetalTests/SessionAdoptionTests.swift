import XCTest
@testable import PaperShadersMetal

final class SessionAdoptionTests: XCTestCase {
    // Regression pin: switching shaders in the sidebar must not bounce back to
    // the stale shader still persisted in the session file.
    func testMountWithStaleDocumentOverwrites() {
        let doc = SessionDocument(shader: "old-shader", params: ["scale": 2.0])
        guard case .overwrite = SessionAdoption.onMount(document: doc, shaderID: "new-shader") else {
            return XCTFail("selection must win over a document targeting another shader")
        }
    }

    func testMountWithMatchingDocumentAdoptsItsParams() {
        let doc = SessionDocument(shader: "same", params: ["scale": 2.0])
        guard case .adopt(let params) = SessionAdoption.onMount(document: doc, shaderID: "same") else {
            return XCTFail("document targeting this shader must be adopted")
        }
        XCTAssertEqual(params["scale"], .number(2.0))
    }

    func testMountWithNoDocumentOverwrites() {
        guard case .overwrite = SessionAdoption.onMount(document: nil, shaderID: "any") else {
            return XCTFail("missing session file: selection becomes the new truth")
        }
    }

    func testChangeTargetingThisShaderApplies() {
        let doc = SessionDocument(shader: "same", params: ["speed": 0.5])
        guard case .apply(let params) = SessionAdoption.onChange(document: doc, shaderID: "same") else {
            return XCTFail("change for this shader must apply params")
        }
        XCTAssertEqual(params["speed"], .number(0.5))
    }

    func testChangeTargetingOtherShaderSwitches() {
        let doc = SessionDocument(shader: "other", params: [:])
        guard case .switchShader("other") = SessionAdoption.onChange(document: doc, shaderID: "same") else {
            return XCTFail("change for another shader must switch, not apply")
        }
    }
}
