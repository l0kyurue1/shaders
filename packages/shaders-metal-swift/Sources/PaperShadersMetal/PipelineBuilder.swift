import Metal
import Foundation

public struct MemberLayout: Equatable {
    public let name: String
    public let offset: Int
    public let dataType: MTLDataType
    public let arrayLength: Int
    public let arrayStride: Int
}

public struct BufferLayout {
    public let size: Int
    public let members: [MemberLayout]
    public func member(_ name: String) -> MemberLayout? { members.first { $0.name == name } }
}

public struct TextureSlot: Equatable { public let name: String; public let index: Int }

public struct ShaderPipeline {
    public let state: MTLRenderPipelineState
    public let vertexParams: BufferLayout?
    public let fragmentParams: BufferLayout?
    public let fragmentTextures: [TextureSlot]
}

public enum PipelineError: Error { case missingEntryPoint(String), noReflection, sourceNotFound(String), uniformMismatch([String]) }

public enum PipelineBuilder {
    /// a_position is float4 [[attribute(0)]] in the generated vertex shader; we feed
    /// float2 data (Metal expands to (x, y, 0, 1)). bufferIndex 1 — the vertex Params
    /// UBO owns buffer(0).
    public static func makeVertexDescriptor() -> MTLVertexDescriptor {
        let vd = MTLVertexDescriptor()
        vd.attributes[0].format = .float2
        vd.attributes[0].offset = 0
        vd.attributes[0].bufferIndex = 1
        vd.layouts[1].stride = MemoryLayout<SIMD2<Float>>.stride
        return vd
    }

    public static func build(device: MTLDevice, shaderID: String, distURL: URL) throws -> ShaderPipeline {
        let vertexURL = distURL.appendingPathComponent("vertex.metal")
        let fragmentURL = distURL.appendingPathComponent("\(shaderID).metal")
        guard let vertexSource = try? String(contentsOf: vertexURL, encoding: .utf8) else { throw PipelineError.sourceNotFound(vertexURL.path) }
        guard let fragmentSource = try? String(contentsOf: fragmentURL, encoding: .utf8) else { throw PipelineError.sourceNotFound(fragmentURL.path) }
        return try build(device: device, vertexSource: vertexSource, fragmentSource: fragmentSource)
    }

    public static func build(device: MTLDevice, vertexSource: String, fragmentSource: String,
                             pixelFormat: MTLPixelFormat = .bgra8Unorm) throws -> ShaderPipeline {
        let vLib = try device.makeLibrary(source: vertexSource, options: nil)
        let fLib = try device.makeLibrary(source: fragmentSource, options: nil)
        guard let vFn = vLib.makeFunction(name: "main0") else { throw PipelineError.missingEntryPoint("vertex main0") }
        guard let fFn = fLib.makeFunction(name: "main0") else { throw PipelineError.missingEntryPoint("fragment main0") }

        let desc = MTLRenderPipelineDescriptor()
        desc.vertexFunction = vFn
        desc.fragmentFunction = fFn
        desc.vertexDescriptor = makeVertexDescriptor()
        desc.colorAttachments[0].pixelFormat = pixelFormat

        // .argumentInfo: deprecated spelling of .bindingInfo — the CI runner's SDK lacks the new name
        let (state, reflection) = try device.makeRenderPipelineState(descriptor: desc, options: [.argumentInfo, .bufferTypeInfo])
        guard let reflection else { throw PipelineError.noReflection }

        return ShaderPipeline(
            state: state,
            vertexParams: paramsLayout(in: reflection.vertexBindings),
            fragmentParams: paramsLayout(in: reflection.fragmentBindings),
            fragmentTextures: reflection.fragmentBindings
                .filter { $0.type == .texture }
                .map { TextureSlot(name: $0.name, index: $0.index) }
                .sorted { $0.index < $1.index }
        )
    }

    private static func paramsLayout(in bindings: [MTLBinding]) -> BufferLayout? {
        guard let buffer = bindings.first(where: { $0.type == .buffer && $0.index == 0 }) as? MTLBufferBinding,
              let structType = buffer.bufferStructType else { return nil }
        let members = structType.members.map { m -> MemberLayout in
            if let array = m.arrayType() {
                return MemberLayout(name: m.name, offset: m.offset, dataType: array.elementType,
                                    arrayLength: array.arrayLength, arrayStride: array.stride)
            }
            return MemberLayout(name: m.name, offset: m.offset, dataType: m.dataType, arrayLength: 1, arrayStride: 0)
        }
        return BufferLayout(size: buffer.bufferDataSize, members: members)
    }
}
