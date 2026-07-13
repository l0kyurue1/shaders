/** spirv-cross emits the exact float32 decimal expansion for constants (e.g.
 *  `6.283185482025146484375`), which is correct but unreadable. Shortens each such
 *  literal to the fewest significant digits that still parses back to the identical
 *  float32 — leaves short, already-terse literals (`100.0`, `2.0`, `0.5`) untouched. */

const FLOAT_LITERAL_RE = /(?<![\w.])-?\d+\.\d+(?:[eE][+-]?\d+)?(?![\w])/g;

function significantDigitCount(literal: string): number {
  const mantissa = literal.replace(/^-/, '').split(/[eE]/)[0].replace('.', '');
  const trimmed = mantissa.replace(/^0+/, '');
  return trimmed.length || 1;
}

export function shortenFloatLiteral(literal: string): string {
  const qualifies = /[eE]/.test(literal) || significantDigitCount(literal) >= 9;
  if (!qualifies) return literal;

  const target = Math.fround(parseFloat(literal));
  for (let precision = 1; precision <= 9; precision++) {
    const candidate = target.toPrecision(precision);
    if (Math.fround(parseFloat(candidate)) === target) {
      return /[.eE]/.test(candidate) ? candidate : `${candidate}.0`;
    }
  }
  return literal;
}

export function shortenFloatLiterals(metalSource: string): string {
  return metalSource.replace(FLOAT_LITERAL_RE, shortenFloatLiteral);
}
