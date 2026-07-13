import Foundation
import simd

public enum UniformValue: Equatable {
    case float(Float)
    case float2(SIMD2<Float>)
    case bool(Bool)
    case color(SIMD4<Float>)
    case colors([SIMD4<Float>])
}

public extension SIMD4<Float> {
    /// #rgb, #rrggbb, #rrggbbaa → straight (non-premultiplied) 0–1 RGBA.
    /// Mirrors packages/shaders/src/get-shader-color-from-string.ts hexToRgba: verified
    /// it expands 3→6→8 hex digits the same way and does not premultiply alpha.
    init?(hex: String) {
        var s = hex.trimmingCharacters(in: .whitespaces).lowercased()
        guard s.hasPrefix("#") else { return nil }
        s.removeFirst()
        if s.count == 3 { s = s.map { "\($0)\($0)" }.joined() }
        if s.count == 6 { s += "ff" }
        guard s.count == 8, let v = UInt64(s, radix: 16) else { return nil }
        self.init(
            Float((v >> 24) & 0xff) / 255,
            Float((v >> 16) & 0xff) / 255,
            Float((v >> 8) & 0xff) / 255,
            Float(v & 0xff) / 255
        )
    }
}

public extension ParamEntry {
    var defaultUniformValue: UniformValue? {
        switch (kind, `default`) {
        case (.number, .number(let n)): return .float(Float(n))
        case (.boolean, .bool(let b)): return .bool(b)
        case (.colors, .stringArray(let hexes)): return .colors(hexes.compactMap { SIMD4<Float>(hex: $0) })
        case (.string, .string(let s)):
            if let c = SIMD4<Float>(hex: s) { return .color(c) }
            if let mapped = options?[s] { return .float(Float(mapped)) }
            return nil
        default: return nil
        }
    }
}

public extension ShaderEntry {
    /// Defaults keyed by uniform name (u_*). Runtime-owned params (uniform == nil) excluded.
    func defaultUniformValues() -> [String: UniformValue] {
        var out: [String: UniformValue] = [:]
        for p in params {
            guard let uniform = p.uniform, let value = p.defaultUniformValue else { continue }
            out[uniform] = value
        }
        return out
    }
}
