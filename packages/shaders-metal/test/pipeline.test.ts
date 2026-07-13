import { describe, expect, test } from 'bun:test';
import { mkdtemp } from 'node:fs/promises';
import { tmpdir } from 'node:os';
import { join } from 'node:path';
import { compileToMetal } from '../src/pipeline.ts';
import { extractShaders, extractVertexShader } from '../src/extract.ts';
import { hasMetalToolchain } from './env.ts';

describe.skipIf(!hasMetalToolchain)('pipeline', () => {
  test('simplex-noise compiles to validated Metal', async () => {
    const workDir = await mkdtemp(join(tmpdir(), 'shaders-metal-'));
    const shader = (await extractShaders()).find((s) => s.id === 'simplex-noise')!;
    const result = await compileToMetal(shader.id, shader.source, 'frag', workDir);
    expect(result.errors).toEqual([]);
    expect(result.ok).toBe(true);
    expect(result.metalSource).toContain('fragment');
    expect(result.metalSource).toContain('Params');
  }, 30_000);

  test('vertex shader compiles to validated Metal', async () => {
    const workDir = await mkdtemp(join(tmpdir(), 'shaders-metal-'));
    const result = await compileToMetal('vertex', await extractVertexShader(), 'vert', workDir);
    expect(result.errors).toEqual([]);
    expect(result.ok).toBe(true);
    expect(result.metalSource).toContain('vertex');
  }, 30_000);

  test('broken GLSL reports errors instead of throwing', async () => {
    const workDir = await mkdtemp(join(tmpdir(), 'shaders-metal-'));
    const result = await compileToMetal('bad', '#version 300 es\nvoid main() { nonsense; }', 'frag', workDir);
    expect(result.ok).toBe(false);
    expect(result.errors.length).toBeGreaterThan(0);
    expect(result.metalSource).toBeNull();
  }, 30_000);
});
