import Foundation

public enum DistLocator {
    /// Resolution order: PAPER_SHADERS_DIST env override; a `dist` folder bundled in
    /// the app's Resources (distributed .app, see scripts/make-app-bundle.sh); walk up
    /// from this source file (packages/shaders-metal-swift/Sources/...) to the repo
    /// root and append packages/shaders-metal/dist (monorepo dev — freshest during
    /// active shader work); else the PrecompiledShaders resource bundled into the
    /// PaperShadersMetal package itself (the default for a plain SPM consumer with
    /// no monorepo checkout and no custom app bundle — see scripts/sync-dist.sh).
    public static func locate(filePath: String = #filePath) -> URL? {
        if let env = ProcessInfo.processInfo.environment["PAPER_SHADERS_DIST"] {
            let url = URL(fileURLWithPath: env)
            return FileManager.default.fileExists(atPath: url.appendingPathComponent("manifest.json").path) ? url : nil
        }
        if let bundled = Bundle.main.url(forResource: "dist", withExtension: nil),
           FileManager.default.fileExists(atPath: bundled.appendingPathComponent("manifest.json").path) {
            return bundled
        }
        var dir = URL(fileURLWithPath: filePath).deletingLastPathComponent()
        for _ in 0..<10 {
            let candidate = dir.appendingPathComponent("packages/shaders-metal/dist")
            if FileManager.default.fileExists(atPath: candidate.appendingPathComponent("manifest.json").path) {
                return candidate
            }
            dir.deleteLastPathComponent()
        }
        if let manifestURL = Bundle.module.url(forResource: "manifest", withExtension: "json", subdirectory: "PrecompiledShaders") {
            return manifestURL.deletingLastPathComponent()
        }
        return nil
    }
}
