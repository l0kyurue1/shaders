import XCTest
import SwiftUI
@testable import PaperShadersPreview

final class CodeHighlighterTests: XCTestCase {
    private func runColor(containing needle: String, in attr: AttributedString) -> Color? {
        for run in attr.runs where String(attr[run.range].characters).contains(needle) {
            return run.foregroundColor
        }
        return nil
    }

    private func tokenColor(_ token: String, in attr: AttributedString) -> Color? {
        for run in attr.runs where String(attr[run.range].characters) == token {
            return run.foregroundColor
        }
        return nil
    }

    func testMetalTokenClassesAndRoundTrip() {
        let code = """
        #include <metal_stdlib>
        // line comment kernel
        /* block kernel */
        kernel void main0(float2 uv) {
            float x = 1.5f;
            device const char *s = "quoted \\" kernel";
        }
        """
        let attr = CodeHighlighter.highlight(code, language: .metal)
        XCTAssertEqual(String(attr.characters), code)

        let comment = runColor(containing: "line comment", in: attr)
        let keyword = tokenColor("kernel", in: attr)
        let type = tokenColor("float2", in: attr)
        let number = tokenColor("1.5f", in: attr)
        let string = runColor(containing: "quoted", in: attr)
        let preprocessor = runColor(containing: "#include", in: attr)
        for c in [comment, keyword, type, number, string, preprocessor] { XCTAssertNotNil(c) }
        XCTAssertNotEqual(comment, keyword)
        XCTAssertNotEqual(keyword, type)
        XCTAssertNotEqual(string, keyword)
        XCTAssertNotEqual(preprocessor, comment)
        XCTAssertEqual(runColor(containing: "block kernel", in: attr), comment)
        XCTAssertEqual(runColor(containing: "comment kernel", in: attr), comment)
    }

    func testSwiftKeywordVsPlain() {
        let attr = CodeHighlighter.highlight("func render() -> View { nothing }", language: .swift)
        XCTAssertNotEqual(runColor(containing: "func", in: attr), runColor(containing: "nothing", in: attr))
        XCTAssertEqual(runColor(containing: "View", in: attr), runColor(containing: "View", in: attr))
    }
}
