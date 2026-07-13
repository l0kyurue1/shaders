import { describe, expect, test } from 'bun:test';
import { renameParamsArg } from '../src/rename-params.ts';

describe('renameParamsArg', () => {
  test('renames the entry arg and its references, leaves interior temps alone', () => {
    const src = `fragment main0_out main0(main0_in in [[stage_in]], constant Params& _249 [[buffer(0)]])
{
    float2 gap = fast::max(abs(float2(_249.u_gapX, _249.u_gapY)), float2(0.0));
    float2 _2490 = gap;
    float2 _510 = floor(gap);
}`;
    const out = renameParamsArg(src);
    expect(out).toContain('constant Params& params [[buffer(0)]]');
    expect(out).toContain('params.u_gapX');
    expect(out).not.toMatch(/\b_249\b/);
    expect(out).toContain('_2490'); // untouched: different identifier, not a word-boundary match
    expect(out).toContain('_510'); // untouched: interior SSA temp
  });

  test('leaves sources with no Params entry arg untouched', () => {
    const src = 'float2 _510 = floor(gap);';
    expect(renameParamsArg(src)).toBe(src);
  });
});
