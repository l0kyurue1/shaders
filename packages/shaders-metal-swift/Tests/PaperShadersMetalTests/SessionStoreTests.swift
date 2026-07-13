import XCTest
import Foundation
@testable import PaperShadersMetal

final class SessionStoreTests: XCTestCase {
    private func tempDir() throws -> URL {
        let dir = FileManager.default.temporaryDirectory
            .appendingPathComponent("sessionstore-\(UUID().uuidString)")
        try FileManager.default.createDirectory(at: dir, withIntermediateDirectories: true)
        return dir
    }

    /// Regression: switching shaders bounced back because mount read the file via onChange.
    /// currentDocument() must parse WITHOUT firing onChange; readNow() must fire it.
    func testCurrentDocumentDoesNotFireOnChange() throws {
        let dir = try tempDir()
        let store = SessionStore(directory: dir)
        // Write the file directly (not via store.write) so lastWritten stays nil and
        // readNow() is not self-write-suppressed.
        let json = #"{"shader":"warp","params":{"scale":2}}"#
        try json.write(to: dir.appendingPathComponent("params.json"), atomically: true, encoding: .utf8)

        var fired: [String] = []
        store.onChange = { fired.append($0.shader) }

        let doc = store.currentDocument()
        XCTAssertEqual(doc?.shader, "warp")
        XCTAssertEqual(doc?.params["scale"], .number(2))
        XCTAssertTrue(fired.isEmpty, "currentDocument() must not fire onChange (that caused the switch bounce)")

        store.readNow()
        XCTAssertEqual(fired, ["warp"], "readNow() must still notify for genuine external changes")
    }

    func testWriteThenCurrentDocumentRoundTrips() throws {
        let dir = try tempDir()
        let store = SessionStore(directory: dir)
        store.write(SessionDocument(shader: "voronoi", params: ["distance": 0.5, "shape": "cells"]))
        let doc = try XCTUnwrap(store.currentDocument())
        XCTAssertEqual(doc.shader, "voronoi")
        XCTAssertEqual(doc.params["shape"], .string("cells"))
    }

    func testMalformedJSONSetsErrorAndKeepsLastGood() throws {
        let dir = try tempDir()
        let store = SessionStore(directory: dir)
        try "{ not json".write(to: dir.appendingPathComponent("params.json"), atomically: true, encoding: .utf8)
        var fired = 0
        store.onChange = { _ in fired += 1 }
        store.readNow()
        XCTAssertEqual(fired, 0)
        XCTAssertNotNil(store.lastError)
    }
}
