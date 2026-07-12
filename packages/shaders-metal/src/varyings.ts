/** Metal links vertex→fragment varyings by `[[user(locnN)]]` index, not by name.
 *  glslang --auto-map-locations numbers each shader's varyings independently, so a
 *  fragment's locn0 may not be the vertex's locn0. These two helpers renumber every
 *  fragment varying to match the vertex's canonical name→index map. */

const VARYING_RE = /(\w+)\s*\[\[user\(locn(\d+)\)\]\]/g;

/** name → location index, parsed from a metal stage_out/stage_in struct. */
export function parseVaryingLocations(metalSource: string): Map<string, number> {
  const map = new Map<string, number>();
  for (const [, name, idx] of metalSource.matchAll(VARYING_RE)) map.set(name, Number(idx));
  return map;
}

/** Rewrite each `[[user(locnN)]]` in a fragment source to the canonical index for
 *  that varying's name. Fragment inputs must be a subset of vertex outputs. */
export function remapFragmentVaryings(fragSource: string, canonical: Map<string, number>): string {
  return fragSource.replace(VARYING_RE, (_, name: string, idx: string) => {
    const k = canonical.get(name);
    if (k === undefined) throw new Error(`varying ${name} [[user(locn${idx})]] not found in vertex stage_out`);
    return `${name} [[user(locn${k})]]`;
  });
}
