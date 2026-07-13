import { describe, expect, test } from 'bun:test';
import { parseVaryingLocations, remapFragmentVaryings } from '../src/varyings.ts';

const VERTEX = `struct main0_out {
    float2 v_objectUV [[user(locn0)]];
    float2 v_imageUV [[user(locn6)]];
};`;

describe('varyings', () => {
  test('parseVaryingLocations reads name→index from a struct', () => {
    expect(parseVaryingLocations(VERTEX)).toEqual(new Map([['v_objectUV', 0], ['v_imageUV', 6]]));
  });

  test('remapFragmentVaryings renumbers by name to the canonical map', () => {
    const canonical = parseVaryingLocations(VERTEX);
    const frag = `struct main0_in {
    float2 v_imageUV [[user(locn0)]];
    float2 v_objectUV [[user(locn1)]];
};`;
    const out = remapFragmentVaryings(frag, canonical);
    expect(parseVaryingLocations(out)).toEqual(new Map([['v_imageUV', 6], ['v_objectUV', 0]]));
  });

  test('throws when a fragment varying is absent from the vertex map', () => {
    expect(() => remapFragmentVaryings('float2 v_ghost [[user(locn0)]];', parseVaryingLocations(VERTEX))).toThrow(
      /v_ghost/
    );
  });
});
