import { describe, expect, test } from 'bun:test';
import { shortenFloatLiteral, shortenFloatLiterals } from '../src/shorten-floats.ts';

describe('shortenFloatLiteral', () => {
  test('shortens a full-precision float32 expansion to the shortest round-tripping form', () => {
    expect(shortenFloatLiteral('6.283185482025146484375')).toBe('6.2831855');
  });

  test('shortens an exponent-form literal', () => {
    const out = shortenFloatLiteral('9.9999999747524270787835121154785e-07');
    expect(Math.fround(parseFloat(out))).toBe(Math.fround(9.9999999747524270787835121154785e-7));
    expect(out.length).toBeLessThan('9.9999999747524270787835121154785e-07'.length);
  });

  test('leaves short literals untouched', () => {
    expect(shortenFloatLiteral('100.0')).toBe('100.0');
    expect(shortenFloatLiteral('2.0')).toBe('2.0');
    expect(shortenFloatLiteral('0.5')).toBe('0.5');
  });

  test('keeps the original verbatim when no candidate round-trips', () => {
    expect(shortenFloatLiteral('NaN.00000000')).toBe('NaN.00000000');
  });
});

describe('shortenFloatLiterals', () => {
  test('shortens multiple literals inside a float4(...) constructor', () => {
    const src =
      'float4(0.211324870586395263671875, 0.211324870586395263671875, -0.57735025882720947265625, -0.57735025882720947265625)';
    const out = shortenFloatLiterals(src);
    expect(out).toBe('float4(0.21132487, 0.21132487, -0.57735026, -0.57735026)');
  });

  test('does not touch swizzles on a renamed SSA temp', () => {
    const src = '_513.xy - _512';
    expect(shortenFloatLiterals(src)).toBe(src);
  });

  test('does not touch a decimal-looking suffix glued to an identifier', () => {
    const src = '_9999999.5';
    expect(shortenFloatLiterals(src)).toBe(src);
  });

  test('leaves short literals in context untouched', () => {
    const src = 'float2 gap = fast::max(abs(float2(u_gapX, u_gapY)), float2(100.0));';
    expect(shortenFloatLiterals(src)).toBe(src);
  });
});
