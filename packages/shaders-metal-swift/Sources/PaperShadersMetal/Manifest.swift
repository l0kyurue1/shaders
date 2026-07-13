import Foundation

public struct Manifest: Decodable {
    public let version: Int
    public let shaders: [ShaderEntry]

    public static func load(distURL: URL) throws -> Manifest {
        let data = try Data(contentsOf: distURL.appendingPathComponent("manifest.json"))
        return try JSONDecoder().decode(Manifest.self, from: data)
    }
}

public struct ShaderEntry: Decodable, Identifiable, Hashable {
    public let id: String
    public let name: String
    public let category: String
    public let params: [ParamEntry]
    public let presets: [Preset]

    private enum CodingKeys: String, CodingKey { case id, name, category, params, presets }

    public init(from decoder: Decoder) throws {
        let c = try decoder.container(keyedBy: CodingKeys.self)
        id = try c.decode(String.self, forKey: .id)
        // New fields default so a pre-schema manifest still loads (spec: name→id, category→Effects, presets→[]).
        name = try c.decodeIfPresent(String.self, forKey: .name) ?? id
        category = try c.decodeIfPresent(String.self, forKey: .category) ?? "Effects"
        params = try c.decode([ParamEntry].self, forKey: .params)
        presets = try c.decodeIfPresent([Preset].self, forKey: .presets) ?? []
    }
}

public struct Preset: Decodable, Hashable {
    public let name: String
    /// Already in the session vocabulary — a preset applies through the same
    /// coercion path (SessionCodec.decode) as session-file params.
    public let params: [String: JSONValue]
}

public struct ParamEntry: Decodable, Hashable {
    public enum Kind: String, Decodable { case number, boolean, colors, string }

    public let name: String
    public let uniform: String?
    public let kind: Kind
    public let `default`: JSONValue
    public let min: Double?
    public let max: Double?
    public let maxCount: Int?
    public let description: String?
    public let glslType: String?
    public let options: [String: Double]?
    /// Manifest-owned param UI group (additive field; nil for a pre-schema manifest).
    public let group: String?
}

public extension ParamEntry {
    /// The one runtime-only param the UI exposes; also the session-file key
    /// SessionCodec reads/writes for the clock.
    static let speedName = "speed"

    /// Host-driven param with no GPU uniform (speed, frame) — drives the
    /// render clock, never reaches the shader.
    var isRuntimeOnly: Bool { uniform == nil }
}

public extension ShaderEntry {
    /// Default clock speed from the manifest's runtime-only speed param.
    var defaultSpeed: Double? {
        if case .number(let s)? = params.first(where: { $0.name == ParamEntry.speedName })?.default { return s }
        return nil
    }
}

/// The session vocabulary: number | bool | string | [string]. Used for manifest
/// `default`s, preset params, and session-file params — the one typed value
/// representation on the JSON side of the codec.
public enum JSONValue: Codable, Hashable {
    case number(Double)
    case bool(Bool)
    case string(String)
    case stringArray([String])

    public init(from decoder: Decoder) throws {
        let c = try decoder.singleValueContainer()
        if let b = try? c.decode(Bool.self) { self = .bool(b) }
        else if let n = try? c.decode(Double.self) { self = .number(n) }
        else if let s = try? c.decode(String.self) { self = .string(s) }
        else if let a = try? c.decode([String].self) { self = .stringArray(a) }
        else { throw DecodingError.dataCorruptedError(in: c, debugDescription: "unsupported default value") }
    }

    public func encode(to encoder: Encoder) throws {
        var c = encoder.singleValueContainer()
        switch self {
        case .number(let d): try c.encode(d)
        case .bool(let b): try c.encode(b)
        case .string(let s): try c.encode(s)
        case .stringArray(let a): try c.encode(a)
        }
    }
}

// Literal conformances keep call sites and generated snippets reading as plain
// JSON-shaped dictionaries: ["scale": 2.0, "shape": "stripes", "colors": ["#fff"]].
extension JSONValue: ExpressibleByFloatLiteral, ExpressibleByIntegerLiteral,
                     ExpressibleByBooleanLiteral, ExpressibleByStringLiteral,
                     ExpressibleByArrayLiteral {
    public init(floatLiteral value: Double) { self = .number(value) }
    public init(integerLiteral value: Int) { self = .number(Double(value)) }
    public init(booleanLiteral value: Bool) { self = .bool(value) }
    public init(stringLiteral value: String) { self = .string(value) }
    public init(arrayLiteral elements: String...) { self = .stringArray(elements) }
}
