import XCTest
import Foundation
@testable import PaperShadersMetal

final class PngCodecTests: XCTestCase {
    func testEncodeDecodeRoundTrip() throws {
        let w = 4, h = 4
        var bgra = [UInt8](repeating: 0, count: w*h*4)
        for i in 0..<(w*h) { bgra[i*4+0]=UInt8(i*4); bgra[i*4+1]=UInt8(i*8); bgra[i*4+2]=UInt8(i*16); bgra[i*4+3]=255 }
        let png = try XCTUnwrap(PngCodec.encodePNG(bgra: bgra, width: w, height: h))
        XCTAssertEqual(Array(png.prefix(8)), [0x89,0x50,0x4E,0x47,0x0D,0x0A,0x1A,0x0A])
        let dec = try XCTUnwrap(PngCodec.decodePNG(png))
        XCTAssertEqual(dec.width, w); XCTAssertEqual(dec.height, h)
        XCTAssertEqual(dec.rgba.count, w*h*4)
    }
}
