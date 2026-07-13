import Metal
import Foundation

public final class OffscreenRenderer {
    private let device: MTLDevice
    private let queue: MTLCommandQueue

    public init(device: MTLDevice) throws {
        self.device = device
        guard let q = device.makeCommandQueue() else { throw PipelineError.noReflection }
        self.queue = q
    }

    public func render(_ renderer: ShaderRenderer, width: Int, height: Int, pixelRatio: Float = 2) throws -> [UInt8] {
        let td = MTLTextureDescriptor.texture2DDescriptor(pixelFormat: .bgra8Unorm, width: width, height: height, mipmapped: false)
        td.usage = [.renderTarget]
        td.storageMode = .shared
        guard let target = device.makeTexture(descriptor: td),
              let cmd = queue.makeCommandBuffer() else { throw PipelineError.noReflection }

        let pass = MTLRenderPassDescriptor()
        pass.colorAttachments[0].texture = target
        pass.colorAttachments[0].loadAction = .clear
        pass.colorAttachments[0].storeAction = .store
        pass.colorAttachments[0].clearColor = MTLClearColor(red: 0, green: 0, blue: 0, alpha: 0)

        guard let encoder = cmd.makeRenderCommandEncoder(descriptor: pass) else { throw PipelineError.noReflection }
        renderer.draw(encoder: encoder, drawableSize: CGSize(width: width, height: height), pixelRatio: pixelRatio)
        encoder.endEncoding()
        cmd.commit()
        cmd.waitUntilCompleted()

        var bytes = [UInt8](repeating: 0, count: width * height * 4)
        bytes.withUnsafeMutableBytes {
            target.getBytes($0.baseAddress!, bytesPerRow: width * 4, from: MTLRegionMake2D(0, 0, width, height), mipmapLevel: 0)
        }
        return bytes
    }
}
