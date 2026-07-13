import { join } from 'node:path';

export type ParamEntry = {
  name: string;
  uniform: string | null;
  kind: 'number' | 'boolean' | 'colors' | 'string';
  default: number | boolean | string | string[];
  min: number | null;
  max: number | null;
  maxCount: number | null;
  description: string | null;
  glslType: string | null;
  options: Record<string, number> | null;
  group: string;
};
export type PresetEntry = { name: string; params: Record<string, ParamEntry['default']> };
export type ShaderEntry = { id: string; name: string; category: string; params: ParamEntry[]; presets: PresetEntry[] };
export type Manifest = { version: 1; shaders: ShaderEntry[] };

const CORE_DIR = join(import.meta.dir, '../../shaders/src');
const REACT_DIR = join(import.meta.dir, '../../shaders-react/src/shaders');
const MOTION_PARAMS = new Set(['speed', 'frame']);

// Category membership mirrors docs/src/app/home-thumbnails.ts (three sections).
// Display names are title-cased from the id; anything unlisted falls back to Effects.
export const CATEGORY: Record<string, string> = {
  'paper-texture': 'Image Filters',
  'fluted-glass': 'Image Filters',
  water: 'Image Filters',
  'image-dithering': 'Image Filters',
  'halftone-dots': 'Image Filters',
  'halftone-cmyk': 'Image Filters',
  heatmap: 'Logo Animations',
  'liquid-metal': 'Logo Animations',
  'gem-smoke': 'Logo Animations',
};

function camel(id: string): string {
  return id.replace(/-(\w)/g, (_, c) => c.toUpperCase());
}

function titleCase(id: string): string {
  return id.replace(/(^|-)(\w)/g, (_, sep, c) => (sep ? ' ' : '') + c.toUpperCase()).trim();
}

// Mirrors ParamPanel.swift's (now-deleted) groupTitle heuristic exactly, so the manifest
// becomes the single source of truth for the Swift preview's param grouping. Order matters.
const TRANSFORM_PARAMS = new Set([
  'scale',
  'rotation',
  'fit',
  'originx',
  'originy',
  'offsetx',
  'offsety',
  'worldwidth',
  'worldheight',
]);

export function paramGroup(name: string, kind: ParamEntry['kind'], options: ParamEntry['options']): string {
  const n = name.toLowerCase();
  if (kind === 'colors' || (kind === 'string' && options === null) || n.includes('color')) return 'Colors';
  if (n === 'speed') return 'Motion';
  if (TRANSFORM_PARAMS.has(n)) return 'Transform';
  return 'Effect';
}

/** Parse JSDoc lines: ` * - u_softness (float): description (0 to 1)` */
export type DocEntry = { description: string; min: number | null; max: number | null; glslType: string | null };
const DOC_RE =
  /^\s*\*\s*-\s*(u_\w+)\s*\(([\w[\]]+)\):\s*(.+?)(?:\((?:([^()]*?),\s*)?(-?[\d.]+)\s+to\s+(-?[\d.]+)\))?\s*$/;

/** Strategy (a): scrape uniform doc comments for description/glslType/min/max.
 *  The trailing range parenthetical may be bare `(0 to 1)` or carry a prose
 *  prefix `(enhances existing dots, -1 to 1)` — the prefix stays in the
 *  description, the range becomes min/max (halftone-cmyk's u_gainC/M/Y/K). */
export function parseDocs(source: string): Map<string, DocEntry> {
  const docs = new Map<string, DocEntry>();
  for (const line of source.split('\n')) {
    const m = line.match(DOC_RE);
    if (m) {
      const note = m[4]?.trim();
      const base = m[3].trim().replace(/,$/, '');
      docs.set(m[1], {
        description: note ? `${base} (${note})` : base,
        min: m[5] !== undefined ? Number(m[5]) : null,
        max: m[6] !== undefined ? Number(m[6]) : null,
        glslType: m[2] ?? null,
      });
    }
  }
  return docs;
}

/** Strategy (b): enum-like string params (e.g. shape: 'checks') map to floats via
 *  an exported const object in the core shader module (e.g. WarpPatterns). Find
 *  the map by shape: all-number values and containing the default as a key. */
export function findOptionsMap(mod: Record<string, unknown>, def: string): Record<string, number> | null {
  for (const value of Object.values(mod)) {
    if (!value || typeof value !== 'object' || Array.isArray(value)) continue;
    const entries = Object.entries(value as Record<string, unknown>);
    if (entries.length > 0 && def in (value as object) && entries.every(([, v]) => typeof v === 'number')) {
      return value as Record<string, number>;
    }
  }
  return null;
}

/** Strategy (c): fallback — parse "(0 = checks, 1 = stripes, 2 = edge)" pairs out
 *  of the JSDoc description when the module has no exported options object. */
export function optionsFromDescription(description: string | null): Record<string, number> | null {
  if (!description) return null;
  const pairs = [...description.matchAll(/(\d+)\s*=\s*([\w-]+)/g)];
  if (pairs.length === 0) return null;
  return Object.fromEntries(pairs.map(([, num, label]) => [label, Number(num)]));
}

/** Strategy (d): most props pass straight through as `u_<name>` (e.g. `u_scale: scale`),
 *  but a few components rename the prop for the public API (e.g. image-dithering's
 *  `u_pxSize: size`). Parse the `const uniforms = {...} satisfies ...` block in the
 *  react component and collect only the bare-identifier assignments — `u_x: propCall(...)`
 *  is skipped since the uniform there isn't just a renamed passthrough. */
export function parseUniformNameOverrides(reactSource: string): Map<string, string> {
  const overrides = new Map<string, string>();
  const block = reactSource.match(/const uniforms = \{([\s\S]*?)\}\s*satisfies/)?.[1] ?? '';
  for (const [, uniform, prop] of block.matchAll(/(u_\w+):\s*(\w+),/g)) {
    if (uniform !== `u_${prop}`) overrides.set(prop, uniform);
  }
  return overrides;
}

/** Number params with no bounds today, for reasons that aren't extractor bugs
 *  (see per-name comment). Anything NOT listed here that shows up with a null
 *  min/max fails the build loudly instead of shipping a silently-unbounded
 *  slider — add to this list only after confirming the gap is intentional. */
export const UNBOUNDED_NUMBER_PARAMS = new Set([
  'speed', // motion param: uniform is always null (MOTION_PARAMS), never doc-looked-up
  'frame', // same as speed
  'worldWidth', // sizing internal declared in vertex-shader.ts, never documented with a range
  'worldHeight', // same as worldWidth
  'margin', // fluted-glass: no u_margin uniform exists (only marginLeft/Right/Top/Bottom do)
]);

export function assertNumberParamsBounded(shader: ShaderEntry): void {
  const violations = shader.params
    .filter((p) => p.kind === 'number' && !UNBOUNDED_NUMBER_PARAMS.has(p.name) && (p.min === null || p.max === null))
    .map((p) => p.name);
  if (violations.length > 0) {
    throw new Error(
      `${shader.id}: number param(s) missing min/max — JSDoc range likely reformatted or dropped: ${violations.join(', ')}. ` +
        `If this is intentional, add the name to UNBOUNDED_NUMBER_PARAMS in manifest.ts.`
    );
  }
}

export async function buildManifest(ids: string[]): Promise<Manifest> {
  const vertexSource = await Bun.file(join(CORE_DIR, 'vertex-shader.ts')).text();
  const vertexDocs = parseDocs(vertexSource);
  const sizingMod = await import(join(CORE_DIR, 'shader-sizing.ts'));

  const shaders: ShaderEntry[] = [];
  for (const id of ids.sort()) {
    const coreSource = await Bun.file(join(CORE_DIR, 'shaders', `${id}.ts`)).text();
    const docs = new Map([...vertexDocs, ...parseDocs(coreSource)]);
    const coreMod = await import(join(CORE_DIR, 'shaders', `${id}.ts`));
    const reactSource = await Bun.file(join(REACT_DIR, `${id}.tsx`)).text();
    const reactMod = await import(join(REACT_DIR, `${id}.tsx`));
    const preset = reactMod.defaultPreset;
    if (!preset?.params) throw new Error(`${id}: shaders-react module has no defaultPreset export`);
    const maxColorCount: number | null = coreMod[`${camel(id)}Meta`]?.maxColorCount ?? null;
    const uniformOverrides = parseUniformNameOverrides(reactSource);

    const params: ParamEntry[] = Object.entries(preset.params).map(([name, value]) => {
      const uniform = MOTION_PARAMS.has(name) ? null : (uniformOverrides.get(name) ?? `u_${name}`);
      const doc = uniform ? docs.get(uniform) : undefined;
      const kind: ParamEntry['kind'] = Array.isArray(value)
        ? 'colors'
        : typeof value === 'boolean'
          ? 'boolean'
          : typeof value === 'string'
            ? 'string'
            : 'number';
      const options =
        kind === 'string' && !String(value).startsWith('#')
          ? name === 'fit'
            ? (sizingMod.ShaderFitOptions as Record<string, number>)
            : (findOptionsMap(coreMod, value as string) ?? optionsFromDescription(doc?.description ?? null))
          : null;
      return {
        name,
        uniform,
        kind,
        default: value as ParamEntry['default'],
        min: doc?.min ?? null,
        max: doc?.max ?? null,
        maxCount: kind === 'colors' ? maxColorCount : null,
        description: doc?.description ?? null,
        glslType: doc?.glslType ?? null,
        options,
        group: paramGroup(name, kind, options),
      };
    });

    const paramNames = new Set(params.map((p) => p.name));
    const pickParams = (raw: Record<string, unknown>): PresetEntry['params'] =>
      Object.fromEntries(
        Object.entries(raw).filter(([k]) => paramNames.has(k)) as [string, ParamEntry['default']][]
      );
    const presetArray = reactMod[`${camel(id)}Presets`] as { name: string; params: Record<string, unknown> }[] | undefined;
    const presets: PresetEntry[] = Array.isArray(presetArray)
      ? presetArray.map((p) => ({ name: p.name, params: pickParams(p.params) }))
      : [{ name: 'Default', params: pickParams(preset.params) }];

    const shader: ShaderEntry = {
      id,
      name: titleCase(id),
      category: CATEGORY[id] ?? 'Effects',
      params,
      presets,
    };
    assertNumberParamsBounded(shader);
    shaders.push(shader);
  }
  return { version: 1, shaders };
}
