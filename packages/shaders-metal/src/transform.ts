export function bumpVersion(source: string): string {
  return source.replace(/^#version 300 es/, '#version 310 es');
}

/** Matches loose non-opaque uniforms: `uniform [precision] <type> <name>[N];` — not samplers.
 *  Precision qualifiers (lowp/mediump/highp) are consumed and dropped: std140 block members
 *  take the file-level default precision, which is what these shaders rely on anyway. */
const LOOSE_UNIFORM_RE =
  /^\s*uniform\s+(?:(?:lowp|mediump|highp)\s+)?(?!sampler|texture)(\w+)\s+(\w+)(\[\d+\])?\s*;\s*$/;

export function wrapUniformsInUbo(source: string): string {
  const lines = source.split('\n');
  const members: string[] = [];
  const kept: string[] = [];
  let insertAt = -1;

  for (const line of lines) {
    const m = line.match(LOOSE_UNIFORM_RE);
    if (m) {
      members.push(`  ${m[1]} ${m[2]}${m[3] ?? ''};`);
      if (insertAt === -1) insertAt = kept.length;
    } else {
      kept.push(line);
    }
  }

  if (members.length === 0) return source;
  const block = ['layout(std140) uniform Params {', ...members, '};'];
  kept.splice(insertAt, 0, ...block);
  return kept.join('\n');
}

export function prepareForSpirv(source: string): string {
  return wrapUniformsInUbo(bumpVersion(source));
}
