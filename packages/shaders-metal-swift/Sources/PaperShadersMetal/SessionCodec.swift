import Foundation
import simd

/// Name-keyed JSON (the manifest vocabulary, spec §4.3/§5) ↔ uniform-keyed UniformValues.
public enum SessionCodec {
    public static func decode(_ json: [String: JSONValue], entry: ShaderEntry) -> (values: [String: UniformValue], speed: Double?) {
        var values: [String: UniformValue] = [:]
        for param in entry.params {
            guard let uniform = param.uniform, let raw = json[param.name] else { continue }
            switch (param.kind, raw) {
            case (.number, .number(let n)):
                values[uniform] = .float(Float(n))
            case (.boolean, .bool(let b)):
                values[uniform] = .bool(b)
            case (.string, .string(let s)):
                if let c = SIMD4<Float>(hex: s) { values[uniform] = .color(c) }
                else if let mapped = param.options?[s] { values[uniform] = .float(Float(mapped)) }
            case (.colors, .stringArray(let hexes)):
                values[uniform] = .colors(hexes.compactMap { SIMD4<Float>(hex: $0) })
            default:
                continue   // kind/value shape mismatch — ignored, same as before
            }
        }
        var speed: Double?
        if case .number(let s)? = json[ParamEntry.speedName] { speed = s }
        return (values, speed)
    }

    public static func encode(values: [String: UniformValue], speed: Double, entry: ShaderEntry) -> [String: JSONValue] {
        var json: [String: JSONValue] = [ParamEntry.speedName: .number(speed)]
        for param in entry.params {
            guard let uniform = param.uniform, let value = values[uniform] else { continue }
            switch value {
            case .float(let f):
                if let options = param.options {
                    // enum float → nearest label
                    if let label = options.min(by: { abs($0.value - Double(f)) < abs($1.value - Double(f)) })?.key {
                        json[param.name] = .string(label)
                    }
                } else {
                    json[param.name] = .number(Double(f))
                }
            case .bool(let b): json[param.name] = .bool(b)
            case .color(let c): json[param.name] = .string(hexString(c))
            case .colors(let cs): json[param.name] = .stringArray(cs.map(hexString))
            case .float2: break   // runtime-owned, never a session param
            }
        }
        return json
    }

    private static func hexString(_ c: SIMD4<Float>) -> String {
        let r = Int(round(c.x * 255)), g = Int(round(c.y * 255)), b = Int(round(c.z * 255)), a = Int(round(c.w * 255))
        return a == 255
            ? String(format: "#%02x%02x%02x", r, g, b)
            : String(format: "#%02x%02x%02x%02x", r, g, b, a)
    }
}
