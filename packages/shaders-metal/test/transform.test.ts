import { describe, expect, test } from 'bun:test';
import { bumpVersion, wrapUniformsInUbo, prepareForSpirv } from '../src/transform.ts';
import { extractShaders } from '../src/extract.ts';

const SAMPLE = `#version 300 es
precision mediump float;

uniform float u_time;
uniform vec4 u_colors[10];
uniform sampler2D u_image;
uniform bool u_inverted;

out vec4 fragColor;
void main() { fragColor = vec4(u_time); }
`;

describe('transform', () => {
  test('bumps version to 310 es', () => {
    expect(bumpVersion(SAMPLE)).toStartWith('#version 310 es');
  });

  test('wraps loose uniforms into std140 block, keeps samplers outside', () => {
    const out = wrapUniformsInUbo(SAMPLE);
    expect(out).toContain('layout(std140) uniform Params {');
    expect(out).toContain('  float u_time;');
    expect(out).toContain('  vec4 u_colors[10];');
    expect(out).toContain('  bool u_inverted;');
    expect(out).toContain('uniform sampler2D u_image;'); // untouched
    expect(out).not.toMatch(/^uniform float u_time;/m); // loose decl removed
  });

  test('preserves declaration order inside the block', () => {
    const out = wrapUniformsInUbo(SAMPLE);
    const block = out.slice(out.indexOf('Params {'), out.indexOf('};'));
    expect(block.indexOf('u_time')).toBeLessThan(block.indexOf('u_colors'));
    expect(block.indexOf('u_colors')).toBeLessThan(block.indexOf('u_inverted'));
  });

  test('prepareForSpirv works on every real shader', async () => {
    for (const s of await extractShaders()) {
      const out = prepareForSpirv(s.source);
      expect(out).toStartWith('#version 310 es');
      expect(out).toContain('uniform Params {');

      const looseNonSampler = out
        .split('\n')
        .filter((l) => /^\s*uniform\s+/.test(l) && !/^\s*uniform\s+(sampler|texture)/.test(l) && !/uniform Params \{/.test(l));
      expect(looseNonSampler).toEqual([]);
    }
  });
});
