import SwiftUI
import MetalKit

public struct ShaderView: NSViewRepresentable {
    private let renderer: ShaderRenderer

    public init(renderer: ShaderRenderer) { self.renderer = renderer }

    public func makeCoordinator() -> Coordinator { Coordinator(renderer: renderer) }

    public func makeNSView(context: Context) -> MTKView {
        let view = MTKView()
        view.device = MTLCreateSystemDefaultDevice()
        view.colorPixelFormat = .bgra8Unorm
        view.clearColor = MTLClearColor(red: 0, green: 0, blue: 0, alpha: 0)
        view.delegate = context.coordinator
        // queue must come from the SAME device the pipeline state was built on
        context.coordinator.queue = view.device?.makeCommandQueue()
        return view
    }

    public func updateNSView(_ view: MTKView, context: Context) {
        context.coordinator.renderer = renderer
    }

    public final class Coordinator: NSObject, MTKViewDelegate {
        var renderer: ShaderRenderer
        var queue: MTLCommandQueue?

        init(renderer: ShaderRenderer) { self.renderer = renderer }

        public func mtkView(_ view: MTKView, drawableSizeWillChange size: CGSize) {}

        public func draw(in view: MTKView) {
            guard let drawable = view.currentDrawable,
                  let pass = view.currentRenderPassDescriptor,
                  let cmd = queue?.makeCommandBuffer(),
                  let encoder = cmd.makeRenderCommandEncoder(descriptor: pass) else { return }
            renderer.clock.tick(now: CACurrentMediaTime())
            let pixelRatio = view.bounds.width > 0 ? Float(view.drawableSize.width / view.bounds.width) : 2
            renderer.draw(encoder: encoder, drawableSize: view.drawableSize, pixelRatio: pixelRatio)
            encoder.endEncoding()
            cmd.present(drawable)
            cmd.commit()
        }
    }
}
