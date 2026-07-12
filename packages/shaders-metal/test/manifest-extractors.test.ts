import { describe, expect, test } from 'bun:test';
import {
  parseDocs,
  findOptionsMap,
  optionsFromDescription,
  parseUniformNameOverrides,
  assertNumberParamsBounded,
  UNBOUNDED_NUMBER_PARAMS,
} from '../src/manifest.ts';
import type { ShaderEntry } from '../src/manifest.ts';

describe('parseDocs', () => {
  test('well-formed JSDoc line yields description/min/max/glslType', () => {
    const docs = parseDocs(`
/**
 * - u_softness (float): Edge softness (0 to 1)
 */
`);
    expect(docs.get('u_softness')).toEqual({
      description: 'Edge softness',
      min: 0,
      max: 1,
      glslType: 'float',
    });
  });

  test('reformatted line (range moved, extra spacing) still matches or cleanly misses', () => {
    const docs = parseDocs(`
/**
 * -    u_scale   (float):   World-space scale   (0.01 to 4)
 */
`);
    expect(docs.get('u_scale')).toEqual({
      description: 'World-space scale',
      min: 0.01,
      max: 4,
      glslType: 'float',
    });
  });

  test('range suffix with prose prefix parses min/max and keeps the prose in the description', () => {
    // Mirrors halftone-cmyk's real u_gainC doc line.
    const docs = parseDocs(`
/**
 * - u_gainC (float): Proportional cyan dot size gain (enhances existing dots, -1 to 1)
 */
`);
    const entry = docs.get('u_gainC')!;
    expect(entry).toBeDefined();
    expect(entry.min).toBe(-1);
    expect(entry.max).toBe(1);
    expect(entry.description).toBe('Proportional cyan dot size gain (enhances existing dots)');
  });

  test('options-style parenthetical "(0 = checks, 1 = stripes)" is NOT mistaken for a range', () => {
    const docs = parseDocs(`
/**
 * - u_shape (float): Pattern shape (0 = checks, 1 = stripes)
 */
`);
    const entry = docs.get('u_shape')!;
    expect(entry.min).toBeNull();
    expect(entry.max).toBeNull();
    expect(entry.description).toContain('0 = checks');
  });

  test('line missing the JSDoc "- u_x (type):" shape entirely is skipped, not partially matched', () => {
    const docs = parseDocs(`
/**
 * u_broken without the leading dash and parens
 */
`);
    expect(docs.size).toBe(0);
  });
});

describe('findOptionsMap', () => {
  test('finds the exported const object matching the default key with all-number values', () => {
    const mod = { WarpPatterns: { checks: 0, stripes: 1, edge: 2 }, unrelated: 'nope' };
    expect(findOptionsMap(mod, 'checks')).toEqual({ checks: 0, stripes: 1, edge: 2 });
  });

  test('returns null when no exported object contains the default as a key', () => {
    const mod = { WarpPatterns: { checks: 0, stripes: 1, edge: 2 } };
    expect(findOptionsMap(mod, 'missing')).toBeNull();
  });

  test('skips objects with non-number values (not an enum map)', () => {
    const mod = { NotAnEnum: { checks: 'zero' } };
    expect(findOptionsMap(mod, 'checks')).toBeNull();
  });
});

describe('optionsFromDescription', () => {
  test('parses "(0 = a, 1 = b)" pairs from a description', () => {
    expect(optionsFromDescription('Pattern shape (0 = checks, 1 = stripes, 2 = edge)')).toEqual({
      checks: 0,
      stripes: 1,
      edge: 2,
    });
  });

  test('returns null for a description with no digit=label pairs', () => {
    expect(optionsFromDescription('Just a plain description')).toBeNull();
  });

  test('returns null for null input', () => {
    expect(optionsFromDescription(null)).toBeNull();
  });
});

describe('parseUniformNameOverrides', () => {
  test('collects only renamed passthroughs from the uniforms block', () => {
    const source = `
const uniforms = {
  u_scale: scale,
  u_pxSize: size,
} satisfies ShaderUniforms;
`;
    const overrides = parseUniformNameOverrides(source);
    expect(overrides.get('size')).toBe('u_pxSize');
    expect(overrides.has('scale')).toBe(false); // u_scale === u_${scale}, not an override
  });

  test('skips non-bare-identifier assignments like u_x: propCall(...)', () => {
    const source = `
const uniforms = {
  u_colorBack: getRGBA(colorBack),
} satisfies ShaderUniforms;
`;
    expect(parseUniformNameOverrides(source).size).toBe(0);
  });

  test('reformatted source missing the "satisfies" keyword yields no overrides', () => {
    const source = `
const uniforms = {
  u_pxSize: size,
};
`;
    expect(parseUniformNameOverrides(source).size).toBe(0);
  });
});

function shaderWithParams(params: Array<Partial<ShaderEntry['params'][number]> & { name: string }>): ShaderEntry {
  return {
    id: 'fixture',
    name: 'Fixture',
    category: 'Effects',
    params: params.map((p) => ({
      uniform: `u_${p.name}`,
      kind: 'number',
      default: 0,
      min: null,
      max: null,
      maxCount: null,
      description: null,
      glslType: 'float',
      options: null,
      group: 'Effect',
      ...p,
    })),
    presets: [],
  };
}

describe('assertNumberParamsBounded', () => {
  test('passes when every number param has min and max', () => {
    const shader = shaderWithParams([{ name: 'scale', min: 0, max: 1 }]);
    expect(() => assertNumberParamsBounded(shader)).not.toThrow();
  });

  test('throws when a non-allowlisted number param is missing min/max', () => {
    const shader = shaderWithParams([{ name: 'totallyNewParam', min: null, max: 1 }]);
    expect(() => assertNumberParamsBounded(shader)).toThrow(/totallyNewParam/);
  });

  test('allowlisted names (e.g. speed) are exempt', () => {
    expect(UNBOUNDED_NUMBER_PARAMS.has('speed')).toBe(true);
    const shader = shaderWithParams([{ name: 'speed', min: null, max: null }]);
    expect(() => assertNumberParamsBounded(shader)).not.toThrow();
  });

  test('non-number kinds are ignored regardless of min/max', () => {
    const shader = shaderWithParams([{ name: 'shape', kind: 'string', default: 'checks', min: null, max: null }]);
    expect(() => assertNumberParamsBounded(shader)).not.toThrow();
  });
});
