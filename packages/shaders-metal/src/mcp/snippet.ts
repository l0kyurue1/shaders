import { readFileSync } from 'node:fs';
import { join } from 'node:path';
import type { ShaderEntry } from '../manifest.ts';

const TEMPLATE = readFileSync(join(import.meta.dir, '../../templates/snippet.swift.tmpl'), 'utf8');

function swiftLiteral(v: unknown): string {
  if (typeof v === 'number') return String(v);
  if (typeof v === 'boolean') return String(v);
  if (Array.isArray(v)) return `[${v.map(swiftLiteral).join(', ')}]`;
  return JSON.stringify(String(v)); // quoted Swift string
}

/**
 * A self-contained SwiftUI snippet that renders `shader` with `params` baked in,
 * plus SPM install instructions. Shaped to compile against the real public API:
 * ShaderView's `init(shaderID:params:)`, which loads bundled shaders itself and
 * shows its own error state — no manifest/renderer wiring needed on the call site.
 */
export function buildSnippet(shader: ShaderEntry, params: Record<string, unknown>): string {
  const entries = Object.entries(params);
  const dict = entries.length
    ? entries.map(([k, v]) => `                ${JSON.stringify(k)}: ${swiftLiteral(v)},`).join('\n')
    : '                :'; // empty [String: JSONValue] literal

  const typeName = shader.id
    .split(/[-_]/)
    .map((p) => p.charAt(0).toUpperCase() + p.slice(1))
    .join('');

  return TEMPLATE.replaceAll('__TYPE_NAME__', typeName)
    .replaceAll('__SHADER_ID__', shader.id)
    .replace('__PARAMS__', dict);
}
