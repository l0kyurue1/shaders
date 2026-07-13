import Metal
import Foundation
import simd

public final class ShaderRenderer {
    public let entry: ShaderEntry
    public let clock = RenderClock()
    public var params: [String: UniformValue]

    private let pipeline: ShaderPipeline
    private let textures: TextureProvider
    private static let quad: [Float] = [-1, -1, 1, -1, -1, 1, -1, 1, 1, -1, 1, 1]

    public init(device: MTLDevice, entry: ShaderEntry, distURL: URL) throws {
        self.entry = entry
        self.pipeline = try PipelineBuilder.build(device: device, shaderID: entry.id, distURL: distURL)
        self.textures = try TextureProvider(device: device)
        self.params = entry.defaultUniformValues()
        if let s = entry.defaultSpeed { clock.speed = s }

        // Contract check: everything draw() will feed (defaults + runtime-injected)
        // must encode into the reflected layout — manifest/MSL drift fails here.
        let probe = params.merging(RuntimeUniforms.probeValues(textureSlots: pipeline.fragmentTextures)) { _, new in new }
        let mismatches = [pipeline.vertexParams, pipeline.fragmentParams]
            .compactMap { $0 }
            .flatMap { ParamsEncoder.validate(layout: $0, values: probe) }
        guard mismatches.isEmpty else { throw PipelineError.uniformMismatch(mismatches) }
    }

    /// Uniform names the compiled shader actually uses (from Metal reflection) —
    /// lets the panel hide manifest params this effect ignores.
    public var usedUniforms: Set<String> {
        Set((pipeline.fragmentParams?.members.map(\.name) ?? [])
          + (pipeline.vertexParams?.members.map(\.name) ?? []))
    }

    /// True if this shader binds a `u_image` texture (the image-filter shaders).
    public var usesImage: Bool { pipeline.fragmentTextures.contains { $0.name == RuntimeUniforms.image } }

    public var sampleImageURLs: [URL] { textures.sampleImageURLs }
    public var currentImageURL: URL? { textures.currentImageURL }
    public func setImage(url: URL) { textures.setImage(url: url) }

    public func draw(encoder: MTLRenderCommandEncoder, drawableSize: CGSize, pixelRatio: Float) {
        var values = params
        values[RuntimeUniforms.time] = .float(clock.timeSeconds)
        values[RuntimeUniforms.resolution] = .float2(SIMD2(Float(drawableSize.width), Float(drawableSize.height)))
        values[RuntimeUniforms.pixelRatio] = .float(pixelRatio)

        var boundTextures: [(TextureSlot, MTLTexture)] = []
        for slot in pipeline.fragmentTextures {
            guard let tex = textures.texture(for: slot) else { continue }
            boundTextures.append((slot, tex))
            values[RuntimeUniforms.aspectRatio(forTexture: slot.name)] = .float(Float(tex.width) / Float(tex.height))
        }

        encoder.setRenderPipelineState(pipeline.state)
        Self.quad.withUnsafeBytes { encoder.setVertexBytes($0.baseAddress!, length: $0.count, index: 1) }
        if let layout = pipeline.vertexParams {
            let data = ParamsEncoder.encode(layout: layout, values: values)
            data.withUnsafeBytes { encoder.setVertexBytes($0.baseAddress!, length: $0.count, index: 0) }
        }
        if let layout = pipeline.fragmentParams {
            let data = ParamsEncoder.encode(layout: layout, values: values)
            data.withUnsafeBytes { encoder.setFragmentBytes($0.baseAddress!, length: $0.count, index: 0) }
        }
        for (slot, tex) in boundTextures {
            encoder.setFragmentTexture(tex, index: slot.index)
            encoder.setFragmentSamplerState(textures.sampler, index: slot.index)
        }
        encoder.drawPrimitives(type: .triangle, vertexStart: 0, vertexCount: 6)
    }
}
