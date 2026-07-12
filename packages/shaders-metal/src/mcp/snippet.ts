import type { ShaderEntry } from '../manifest.ts';

function swiftLiteral(v: unknown): string {
  if (typeof v === 'number') return String(v);
  if (typeof v === 'boolean') return String(v);
  if (Array.isArray(v)) return `[${v.map(swiftLiteral).join(', ')}]`;
  return JSON.stringify(String(v)); // quoted Swift string
}

/**
 * A self-contained SwiftUI snippet that renders `shader` with `params` baked in,
 * plus SPM install instructions. Shaped to compile against the real public API
 * (ShaderView.swift:7 `init(renderer:)`, ShaderRenderer.swift:14
 * `init(device:entry:distURL:)`, SessionCodec.swift:6 `decode(_:entry:)`).
 */
export function buildSnippet(shader: ShaderEntry, params: Record<string, unknown>): string {
  const entries = Object.entries(params);
  const dict = entries.length
    ? entries.map(([k, v]) => `        ${JSON.stringify(k)}: ${swiftLiteral(v)},`).join('\n')
    : '        :'; // empty [String: JSONValue] literal

  const typeName = shader.id
    .split(/[-_]/)
    .map((p) => p.charAt(0).toUpperCase() + p.slice(1))
    .join('');

  return `// swift-tools: add PaperShadersMetal to Package.swift
// dependencies: [
//     .package(url: "https://github.com/paper-design/shaders", from: "0.0.1"),
// ]
// target dependencies: [
//     .product(name: "PaperShadersMetal", package: "shaders"),
// ]

import SwiftUI
import Metal
import PaperShadersMetal

/// "${shader.name}" (id: ${shader.id}) with params baked in.
/// distURL must point at the built \`dist/\` dir shipped with the package.
struct ${typeName}Preview: View {
    let distURL: URL
    @State private var renderer: ShaderRenderer?

    // Session vocabulary: enum params as label strings, colors as hex string literals.
    static let bakedParams: [String: JSONValue] = [
${dict}
    ]

    var body: some View {
        Group {
            if let renderer {
                ShaderView(renderer: renderer)
            } else {
                ProgressView().task { renderer = try? makeRenderer() }
            }
        }
    }

    func makeRenderer() throws -> ShaderRenderer {
        let manifest = try Manifest.load(distURL: distURL)
        guard let entry = manifest.shaders.first(where: { $0.id == "${shader.id}" }) else {
            throw NSError(domain: "PaperShadersMetal", code: 1)
        }
        let r = try ShaderRenderer(device: MTLCreateSystemDefaultDevice()!, entry: entry, distURL: distURL)
        let (values, _) = SessionCodec.decode(Self.bakedParams, entry: entry)
        r.params = values
        return r
    }
}
`;
}
