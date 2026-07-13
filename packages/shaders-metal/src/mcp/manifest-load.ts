import { existsSync, readFileSync } from 'node:fs';
import { join } from 'node:path';
import type { Manifest, ShaderEntry } from '../manifest.ts';

export function loadManifest(distPath?: string): Manifest {
  const path = distPath ?? join(import.meta.dir, '../../dist/manifest.json');
  if (!existsSync(path)) {
    throw new Error(`manifest not found at ${path} — run \`bun run build\` first`);
  }
  return JSON.parse(readFileSync(path, 'utf8')) as Manifest;
}

export function findShader(m: Manifest, id: string): ShaderEntry | undefined {
  return m.shaders.find((s) => s.id === id);
}
