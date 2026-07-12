import { describe, expect, test } from 'bun:test';
import { buildManifest, paramGroup } from '../src/manifest.ts';
import { extractShaders } from '../src/extract.ts';

describe('manifest', () => {
  test('simplex-noise entry is preset-driven and JSDoc-enriched', async () => {
    const manifest = await buildManifest(['simplex-noise']);
    expect(manifest.version).toBe(1);
    const entry = manifest.shaders[0];
    expect(entry.id).toBe('simplex-noise');

    const softness = entry.params.find((p) => p.name === 'softness')!;
    expect(softness.uniform).toBe('u_softness');
    expect(softness.kind).toBe('number');
    expect(softness.default).toBe(0);
    expect(softness.min).toBe(0);
    expect(softness.max).toBe(1);
    expect(softness.glslType).toBe('float');

    const colors = entry.params.find((p) => p.name === 'colors')!;
    expect(colors.kind).toBe('colors');
    expect(colors.maxCount).toBe(10);
    expect(Array.isArray(colors.default)).toBe(true);
    expect(colors.glslType).toBe('vec4[]');

    const speed = entry.params.find((p) => p.name === 'speed')!;
    expect(speed.uniform).toBeNull(); // motion param, driven by runtime clock
  });

  test('every shader produces a manifest entry with at least one param', async () => {
    const ids = (await extractShaders()).map((s) => s.id);
    const manifest = await buildManifest(ids);
    expect(manifest.shaders.length).toBe(ids.length);
    for (const s of manifest.shaders) {
      expect(s.params.length).toBeGreaterThan(0);
    }
  }, 60_000);

  test('string params carry options maps; color-strings do not', async () => {
    const manifest = await buildManifest(['warp', 'gem-smoke']);
    const warp = manifest.shaders.find((s) => s.id === 'warp')!;

    const shape = warp.params.find((p) => p.name === 'shape')!;
    expect(shape.options).toEqual({ checks: 0, stripes: 1, edge: 2 });

    const fit = warp.params.find((p) => p.name === 'fit')!;
    expect(fit.options).toEqual({ none: 0, contain: 1, cover: 2 });

    const gemShape = manifest.shaders.find((s) => s.id === 'gem-smoke')!.params.find((p) => p.name === 'shape')!;
    expect(gemShape.options).not.toBeNull();
    expect(gemShape.options!['diamond']).toBeDefined();

    const colorBack = manifest.shaders.find((s) => s.id === 'gem-smoke')!.params.find((p) => p.name === 'colorBack')!;
    expect(colorBack.options).toBeNull(); // '#f0efea' is a color, not an enum
  });

  test('paramGroup locks known assignments (mirrors ParamPanel.swift groupTitle)', () => {
    expect(paramGroup('scale', 'number', null)).toBe('Transform');
    expect(paramGroup('colors', 'colors', null)).toBe('Colors');
    expect(paramGroup('speed', 'number', null)).toBe('Motion');
    expect(paramGroup('softness', 'number', null)).toBe('Effect');
  });

  test('every param in the built manifest carries a group field', async () => {
    const manifest = await buildManifest(['simplex-noise']);
    const params = manifest.shaders[0].params;
    expect(params.find((p) => p.name === 'scale')?.group).toBe('Transform');
    expect(params.find((p) => p.name === 'colors')?.group).toBe('Colors');
    expect(params.find((p) => p.name === 'speed')?.group).toBe('Motion');
    expect(params.find((p) => p.name === 'softness')?.group).toBe('Effect');
  });

  test('every string param is either a hex color or has options', async () => {
    const ids = (await extractShaders()).map((s) => s.id);
    const manifest = await buildManifest(ids);
    for (const s of manifest.shaders) {
      for (const p of s.params) {
        if (p.kind !== 'string') continue;
        if (String(p.default).startsWith('#')) {
          expect(p.options).toBeNull();
        } else {
          expect(p.options, `${s.id}.${p.name} ("${p.default}") has no options map`).not.toBeNull();
        }
      }
    }
  }, 60_000);
});
