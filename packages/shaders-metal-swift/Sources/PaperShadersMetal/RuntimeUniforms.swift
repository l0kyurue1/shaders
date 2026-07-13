import Foundation

/// Uniforms the host injects at draw time — the runtime side of the contract
/// with the generated .metal sources (web parity: shader-mount.ts). One table
/// so injection sites and contract validation share a single vocabulary.
public enum RuntimeUniforms {
    public static let time = "u_time"
    public static let resolution = "u_resolution"
    public static let pixelRatio = "u_pixelRatio"
    public static let noiseTexture = "u_noiseTexture"
    public static let image = "u_image"

    /// shader-mount.ts:378-382 parity: u_<texture>AspectRatio auto-uniform.
    public static func aspectRatio(forTexture name: String) -> String { "\(name)AspectRatio" }

    /// Placeholder values carrying the same UniformValue cases draw() injects —
    /// lets the encoder contract be validated at pipeline-build time.
    public static func probeValues(textureSlots: [TextureSlot]) -> [String: UniformValue] {
        var values: [String: UniformValue] = [
            time: .float(0),
            resolution: .float2(.zero),
            pixelRatio: .float(1),
        ]
        for slot in textureSlots { values[aspectRatio(forTexture: slot.name)] = .float(1) }
        return values
    }
}
