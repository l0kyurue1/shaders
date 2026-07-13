/** spirv-cross names the entry's uniform-buffer argument `_NNN` — an arbitrary SSA id
 *  that means nothing to a developer reading or porting the shader. Renamed to `params`
 *  everywhere it's referenced, without touching interior SSA temps that share the same
 *  numeric shape (`_510`, `_2490`, ...). */

const ENTRY_ARG_RE = /constant Params& (_\d+) \[\[buffer\(0\)\]\]/;

export function renameParamsArg(metalSource: string): string {
  const match = metalSource.match(ENTRY_ARG_RE);
  if (!match) return metalSource;
  return metalSource.replace(new RegExp(`\\b${match[1]}\\b`, 'g'), 'params');
}
