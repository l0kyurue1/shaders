import Metal
import Foundation
import simd

public enum ParamsEncoder {
    public static func encode(layout: BufferLayout, values: [String: UniformValue]) -> Data {
        var data = Data(count: layout.size)
        for member in layout.members {
            let value = values[member.name] ?? derived(member: member, values: values)
            guard let value else { continue }   // absent → stays zero, WebGL parity
            if !write(value, member: member, into: &data) {
                assertionFailure("unhandled uniform: \(member.name) \(member.dataType) ← \(value)")
            }
        }
        return data
    }

    /// Contract check for ShaderRenderer.init: every uniform that will be fed
    /// (manifest default or runtime-injected) must be writable into the reflected
    /// layout. Manifest/MSL drift fails loudly at pipeline build instead of
    /// rendering wrong pixels. Absent values stay allowed (zero-fill parity).
    public static func validate(layout: BufferLayout, values: [String: UniformValue]) -> [String] {
        var scratch = Data(count: layout.size)
        var mismatches: [String] = []
        for member in layout.members {
            guard let value = values[member.name] ?? derived(member: member, values: values) else { continue }
            if !write(value, member: member, into: &scratch) {
                mismatches.append("\(member.name): \(member.dataType) ← \(value)")
            }
        }
        return mismatches
    }

    /// u_colorsCount-style companions: web callers pass the count explicitly;
    /// here it derives from the sibling array's length.
    private static func derived(member: MemberLayout, values: [String: UniformValue]) -> UniformValue? {
        guard member.name.hasSuffix("Count") else { return nil }
        let base = String(member.name.dropLast("Count".count))
        if case .colors(let items)? = values[base] { return .float(Float(items.count)) }
        return nil
    }

    @discardableResult
    private static func write(_ value: UniformValue, member: MemberLayout, into data: inout Data) -> Bool {
        switch (member.dataType, value) {
        case (.float, .float(let f)): store(f, at: member.offset, in: &data)
        case (.float, .bool(let b)): store(Float(b ? 1 : 0), at: member.offset, in: &data)
        case (.float2, .float2(let v)): store(v, at: member.offset, in: &data)
        case (.float3, .color(let c)): store(SIMD3(c.x, c.y, c.z), at: member.offset, in: &data)
        case (.float4, .color(let c)) where member.arrayLength <= 1: store(c, at: member.offset, in: &data)
        case (.float4, .colors(let items)):
            for (i, c) in items.prefix(member.arrayLength).enumerated() {
                store(c, at: member.offset + i * member.arrayStride, in: &data)
            }
        case (.bool, .bool(let b)), (.uint, .bool(let b)), (.int, .bool(let b)):
            store(UInt32(b ? 1 : 0), at: member.offset, in: &data)
        case (.bool, .float(let f)), (.uint, .float(let f)), (.int, .float(let f)):
            store(UInt32(f != 0 ? 1 : 0), at: member.offset, in: &data)
        default:
            return false
        }
        return true
    }

    private static func store<T>(_ value: T, at offset: Int, in data: inout Data) {
        withUnsafeBytes(of: value) { bytes in
            data.replaceSubrange(offset..<offset + bytes.count, with: bytes)
        }
    }
}
