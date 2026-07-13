import Metal
import MetalKit
import ImageIO

public final class TextureProvider {
    private let loader: MTKTextureLoader
    private let noise: MTLTexture?
    private let fallback: MTLTexture?
    private var userImage: MTLTexture?
    public let sampler: MTLSamplerState

    /// Bundled sample images (webp), for the preview app's image-filter gallery.
    public let sampleImageURLs: [URL]
    /// Currently selected image (sample or uploaded), for UI highlight.
    public private(set) var currentImageURL: URL?

    public init(device: MTLDevice) throws {
        let loader = MTKTextureLoader(device: device)
        // Web parity (shader-mount.ts:349-355): raw bytes, no sRGB decode, no flip, no mips.
        let options: [MTKTextureLoader.Option: Any] = [.SRGB: false, .generateMipmaps: false]
        func loadURL(_ name: String, ext: String) -> MTLTexture? {
            guard let url = Bundle.module.url(forResource: name, withExtension: ext) else { return nil }
            return try? loader.newTexture(URL: url, options: options)
        }
        let urls = (Bundle.module.urls(forResourcesWithExtension: "webp", subdirectory: nil) ?? [])
            .sorted { $0.lastPathComponent < $1.lastPathComponent }

        let sd = MTLSamplerDescriptor()
        sd.sAddressMode = .clampToEdge
        sd.tAddressMode = .clampToEdge
        sd.minFilter = .linear
        sd.magFilter = .linear
        guard let s = device.makeSamplerState(descriptor: sd) else { throw PipelineError.noReflection }

        self.loader = loader
        self.noise = loadURL("shader-noise", ext: "png")
        self.fallback = loadURL("test-image", ext: "png")
        self.sampleImageURLs = urls
        self.sampler = s
        self.userImage = nil
        self.currentImageURL = nil

        // Default to the web's default sample (0018) so image shaders open looking like the web.
        if let def = urls.first(where: { $0.lastPathComponent == "0018.webp" }) ?? urls.first {
            setImage(url: def)
        }
    }

    public func setImage(url: URL) {
        guard let tex = decode(url) else { return }
        userImage = tex
        currentImageURL = url
    }

    /// Decode via ImageIO/CGImage so we accept webp, jpeg, and indexed PNG that
    /// MTKTextureLoader's URL path cannot handle (prior finding).
    private func decode(_ url: URL) -> MTLTexture? {
        guard let src = CGImageSourceCreateWithURL(url as CFURL, nil),
              let cg = CGImageSourceCreateImageAtIndex(src, 0, nil) else { return nil }
        return try? loader.newTexture(cgImage: cg, options: [.SRGB: false, .generateMipmaps: false])
    }

    public func texture(for slot: TextureSlot) -> MTLTexture? {
        if slot.name == RuntimeUniforms.noiseTexture { return noise }
        return userImage ?? fallback
    }
}
