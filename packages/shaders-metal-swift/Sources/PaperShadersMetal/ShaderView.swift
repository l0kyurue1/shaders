import SwiftUI
import MetalKit

public struct ShaderView: View {
    private enum Source {
        case renderer(ShaderRenderer)
        case shader(id: String, params: [String: JSONValue])
    }

    private let source: Source
    @State private var built: ShaderRenderer?
    @State private var loadError: String?

    public init(renderer: ShaderRenderer) {
        source = .renderer(renderer)
    }

    /// Loads the shader from the discovered dist (DistLocator — bundled resource by
    /// default, PAPER_SHADERS_DIST/monorepo overrides still honored) and applies
    /// name-keyed params (manifest vocabulary, same shape as a session file/preset).
    public init(shaderID: String, params: [String: JSONValue] = [:]) {
        source = .shader(id: shaderID, params: params)
    }

    public var body: some View {
        switch source {
        case .renderer(let renderer):
            MetalRenderView(renderer: renderer)
        case .shader(let id, let params):
            if let built {
                MetalRenderView(renderer: built)
            } else if let loadError {
                Text(loadError)
            } else {
                ProgressView()
                    .task { await load(shaderID: id, params: params) }
            }
        }
    }

    @MainActor
    private func load(shaderID: String, params: [String: JSONValue]) async {
        do {
            guard let distURL = DistLocator.locate() else { throw LoadError.distNotFound }
            let manifest = try Manifest.load(distURL: distURL)
            guard let entry = manifest.shaders.first(where: { $0.id == shaderID }) else {
                throw LoadError.unknownShader(shaderID)
            }
            guard let device = MTLCreateSystemDefaultDevice() else { throw LoadError.noMetalDevice }
            let renderer = try ShaderRenderer(device: device, entry: entry, distURL: distURL)
            let (values, speed) = SessionCodec.decode(params, entry: entry)
            renderer.params.merge(values) { _, new in new }
            if let speed { renderer.clock.speed = speed }
            built = renderer
        } catch {
            loadError = String(describing: error)
        }
    }

    private enum LoadError: Error, CustomStringConvertible {
        case distNotFound
        case unknownShader(String)
        case noMetalDevice

        var description: String {
            switch self {
            case .distNotFound: return "Could not locate shader dist (manifest.json + .metal sources)."
            case .unknownShader(let id): return "Unknown shader id: \(id)"
            case .noMetalDevice: return "No Metal device available on this system."
            }
        }
    }
}

private final class MetalRenderCoordinator: NSObject, MTKViewDelegate {
    var renderer: ShaderRenderer
    var queue: MTLCommandQueue?

    init(renderer: ShaderRenderer) { self.renderer = renderer }

    func mtkView(_ view: MTKView, drawableSizeWillChange size: CGSize) {}

    func draw(in view: MTKView) {
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

private func makeMetalKitView(coordinator: MetalRenderCoordinator) -> MTKView {
    let view = MTKView()
    view.device = MTLCreateSystemDefaultDevice()
    view.colorPixelFormat = .bgra8Unorm
    view.clearColor = MTLClearColor(red: 0, green: 0, blue: 0, alpha: 0)
    view.delegate = coordinator
    // queue must come from the SAME device the pipeline state was built on
    coordinator.queue = view.device?.makeCommandQueue()
    return view
}

#if canImport(AppKit)
private struct MetalRenderView: NSViewRepresentable {
    let renderer: ShaderRenderer

    func makeCoordinator() -> MetalRenderCoordinator { MetalRenderCoordinator(renderer: renderer) }

    func makeNSView(context: Context) -> MTKView { makeMetalKitView(coordinator: context.coordinator) }

    func updateNSView(_ view: MTKView, context: Context) {
        context.coordinator.renderer = renderer
    }
}
#elseif canImport(UIKit)
private struct MetalRenderView: UIViewRepresentable {
    let renderer: ShaderRenderer

    func makeCoordinator() -> MetalRenderCoordinator { MetalRenderCoordinator(renderer: renderer) }

    func makeUIView(context: Context) -> MTKView { makeMetalKitView(coordinator: context.coordinator) }

    func updateUIView(_ view: MTKView, context: Context) {
        context.coordinator.renderer = renderer
    }
}
#endif
