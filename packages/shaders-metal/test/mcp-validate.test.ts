import { describe, expect, test } from 'bun:test';
import { findShader, loadManifest } from '../src/mcp/manifest-load.ts';
import { defaultParamsFor, validateAndCoerceParams } from '../src/mcp/validate.ts';

const warp = findShader(loadManifest(), 'warp')!;

describe('validateAndCoerceParams', () => {
  test('clamps above max (scale 99 -> 4)', () => {
    const r = validateAndCoerceParams(warp, { scale: 99 });
    expect(r.ok).toBe(true);
    expect(r.clamped).toContainEqual({ key: 'scale', from: 99, to: 4, bound: 'max' });
    expect(r.params.scale).toBe(4);
  });

  test('clamps below min (scale -5 -> 0.01)', () => {
    const r = validateAndCoerceParams(warp, { scale: -5 });
    expect(r.ok).toBe(true);
    expect(r.params.scale).toBe(0.01);
    expect(r.clamped).toContainEqual({ key: 'scale', from: -5, to: 0.01, bound: 'min' });
  });

  test('no clamp when bound null (speed 999)', () => {
    const r = validateAndCoerceParams(warp, { speed: 999 });
    expect(r.ok).toBe(true);
    expect(r.clamped).toHaveLength(0);
    expect(r.params.speed).toBe(999);
  });

  test('unknown key rejected with valid names', () => {
    const r = validateAndCoerceParams(warp, { bogus: 1 });
    expect(r.ok).toBe(false);
    expect(r.errors[0].code).toBe('unknown_key');
    expect(r.errors[0].valid).toContain('scale');
  });

  test('enum ok (shape stripes)', () => {
    const r = validateAndCoerceParams(warp, { shape: 'stripes' });
    expect(r.ok).toBe(true);
    expect(r.params.shape).toBe('stripes');
  });

  test('enum bad (shape zigzag)', () => {
    const r = validateAndCoerceParams(warp, { shape: 'zigzag' });
    expect(r.ok).toBe(false);
    expect(r.errors[0].code).toBe('bad_enum');
    expect(r.errors[0].valid).toContain('checks');
  });

  test('wrong type (scale "big")', () => {
    const r = validateAndCoerceParams(warp, { scale: 'big' });
    expect(r.ok).toBe(false);
    expect(r.errors[0].code).toBe('wrong_type');
  });

  test('colors ok', () => {
    const r = validateAndCoerceParams(warp, { colors: ['#112233', '#00000000'] });
    expect(r.ok).toBe(true);
    expect(r.params.colors).toEqual(['#112233', '#00000000']);
  });

  test('colors bad', () => {
    const r = validateAndCoerceParams(warp, { colors: ['red'] });
    expect(r.ok).toBe(false);
    expect(r.errors[0].code).toBe('bad_color');
  });
});

describe('defaultParamsFor', () => {
  test('returns dict containing scale and shape', () => {
    const d = defaultParamsFor(warp);
    expect(d).toHaveProperty('scale');
    expect(d).toHaveProperty('shape');
  });
});
