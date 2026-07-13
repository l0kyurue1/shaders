import Foundation

public enum DistLocator {
    /// PAPER_SHADERS_DIST env override, else a `dist` folder bundled in the
    /// app's Resources (distributed .app), else walk up from this source file
    /// (packages/shaders-metal-swift/Sources/...) to the repo root and append
    /// packages/shaders-metal/dist.
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
        return nil
    }
}
