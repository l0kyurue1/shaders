import { describe, expect, test } from 'bun:test';
import { extractShaders, extractVertexShader } from '../src/extract.ts';

describe('extract', () => {
  test('extracts every shader module with resolved GLSL', async () => {
    const shaders = await extractShaders();
    expect(shaders.length).toBeGreaterThanOrEqual(29);
    const ids = shaders.map((s) => s.id);
    expect(ids).toContain('simplex-noise');
    for (const s of shaders) {
      expect(s.source).toStartWith('#version 300 es');
      expect(s.source).toContain('void main');
      expect(s.source).not.toContain('${'); // template interpolation resolved
    }
  });

  test('extracts the shared vertex shader', async () => {
    const vert = await extractVertexShader();
    expect(vert).toStartWith('#version 300 es');
    expect(vert).toContain('a_position');
  });
});
