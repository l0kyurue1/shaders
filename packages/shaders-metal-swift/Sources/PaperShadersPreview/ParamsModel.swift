import SwiftUI
import Observation
import PaperShadersMetal

@Observable
final class ParamsModel {
    let entry: ShaderEntry
    private let renderer: ShaderRenderer

    /// Set by ShaderPane; invoked after every user edit so the session file stays in sync.
    var onEdit: (() -> Void)?

    /// ShaderRenderer is not Observable; this counter is. Param bindings read it in
    /// their getters so views showing param values re-render when params change.
    private(set) var version = 0
    private func touch() { version += 1 }

    /// Currently selected image URL (for gallery highlight); nil for non-image shaders.
    var selectedImageURL: URL?

    init(entry: ShaderEntry, renderer: ShaderRenderer) {
        self.entry = entry
        self.renderer = renderer
        self.selectedImageURL = renderer.currentImageURL
    }


    var usesImage: Bool { renderer.usesImage }
    var sampleImageURLs: [URL] { renderer.sampleImageURLs }

    func setImage(url: URL) {
        renderer.setImage(url: url)
        selectedImageURL = url
    }

    /// Hide manifest params the compiled shader ignores. `speed` is a host-driven
    /// motion param (no uniform) that's always shown; `frame` stays hidden.
    func isVisible(_ p: ParamEntry) -> Bool {
        if p.isRuntimeOnly { return p.name == ParamEntry.speedName }
        return renderer.usedUniforms.contains(p.uniform!)
    }

    func sessionParams() -> [String: JSONValue] {
        SessionCodec.encode(values: renderer.params, speed: speed, entry: entry)
    }

    func apply(sessionParams: [String: JSONValue]) {
        let (values, speed) = SessionCodec.decode(sessionParams, entry: entry)
        renderer.params.merge(values) { _, new in new }
        if let speed { renderer.clock.speed = speed }
        touch()
    }

    func apply(preset: Preset) {
        apply(sessionParams: preset.params)
        onEdit?()
    }

    func reset() {
        renderer.params = entry.defaultUniformValues()
        if let s = entry.defaultSpeed { renderer.clock.speed = s }
        touch()
        onEdit?()
    }

    var speed: Double {
        get { _ = version; return renderer.clock.speed }
        set { renderer.clock.speed = newValue; touch(); onEdit?() }
    }

    func float(_ uniform: String) -> Binding<Double> {
        Binding(
            get: { _ = self.version; if case .float(let f)? = self.renderer.params[uniform] { return Double(f) } else { return 0 } },
            set: { self.renderer.params[uniform] = .float(Float($0)); self.touch(); self.onEdit?() }
        )
    }

    func bool(_ uniform: String) -> Binding<Bool> {
        Binding(
            get: { _ = self.version; if case .bool(let b)? = self.renderer.params[uniform] { return b } else { return false } },
            set: { self.renderer.params[uniform] = .bool($0); self.touch(); self.onEdit?() }
        )
    }

    func color(_ uniform: String) -> Binding<Color> {
        Binding(
            get: { _ = self.version; if case .color(let c)? = self.renderer.params[uniform] { return Color(simd: c) } else { return .black } },
            set: { self.renderer.params[uniform] = .color($0.simd); self.touch(); self.onEdit?() }
        )
    }

    func colorsCount(_ uniform: String) -> Int {
        _ = version
        if case .colors(let cs)? = renderer.params[uniform] { return cs.count }
        return 0
    }

    func colorAt(_ uniform: String, _ index: Int) -> Binding<Color> {
        Binding(
            get: {
                _ = self.version
                if case .colors(let cs)? = self.renderer.params[uniform], cs.indices.contains(index) {
                    return Color(simd: cs[index])
                }
                return .black
            },
            set: {
                guard case .colors(var cs)? = self.renderer.params[uniform], cs.indices.contains(index) else { return }
                cs[index] = $0.simd
                self.renderer.params[uniform] = .colors(cs)
                self.touch()
                self.onEdit?()
            }
        )
    }

    func addColor(_ uniform: String) {
        guard case .colors(var cs)? = renderer.params[uniform] else { return }
        cs.append(cs.last ?? SIMD4(1, 1, 1, 1))
        renderer.params[uniform] = .colors(cs)
        touch()
        onEdit?()
    }

    func removeColor(_ uniform: String) {
        guard case .colors(var cs)? = renderer.params[uniform], cs.count > 1 else { return }
        cs.removeLast()
        renderer.params[uniform] = .colors(cs)
        touch()
        onEdit?()
    }
}

extension Color {
    init(simd c: SIMD4<Float>) {
        self.init(.sRGB, red: Double(c.x), green: Double(c.y), blue: Double(c.z), opacity: Double(c.w))
    }
    var simd: SIMD4<Float> {
        let ns = NSColor(self).usingColorSpace(.sRGB) ?? .black
        return SIMD4(Float(ns.redComponent), Float(ns.greenComponent), Float(ns.blueComponent), Float(ns.alphaComponent))
    }
}
