import { readdir } from 'node:fs/promises';
import { join } from 'node:path';

export type ExtractedShader = { id: string; source: string };

const SHADERS_DIR = join(import.meta.dir, '../../shaders/src/shaders');

/** kebab-case file name -> camelCase export prefix: simplex-noise -> simplexNoise */
function camel(id: string): string {
  return id.replace(/-(\w)/g, (_, c) => c.toUpperCase());
}

export async function extractShaders(): Promise<ExtractedShader[]> {
  const files = (await readdir(SHADERS_DIR)).filter((f) => f.endsWith('.ts'));
  const out: ExtractedShader[] = [];
  for (const file of files.sort()) {
    const id = file.replace(/\.ts$/, '');
    const mod = await import(join(SHADERS_DIR, file));
    const source = mod[`${camel(id)}FragmentShader`];
    if (typeof source !== 'string') {
      throw new Error(`${file}: expected export ${camel(id)}FragmentShader`);
    }
    out.push({ id, source });
  }
  return out;
}

export async function extractVertexShader(): Promise<string> {
  const mod = await import(join(import.meta.dir, '../../shaders/src/vertex-shader.ts'));
  return mod.vertexShaderSource;
}
